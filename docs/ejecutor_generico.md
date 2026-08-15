# Ejecutor genérico — estado real

> **Reescrito 15/ago/2026 desde el workflow real de n8n** (`aVORciBJl52lTxTU`,
> 19 nodos, `active: false`, corre por Manual Trigger). La versión anterior de
> este documento describía mi diseño original, más simple que lo que
> terminó construyéndose — quedó archivada, ver [[archivo/ejecutor_generico_v1_diseno]]
> si hace falta compararla. Esto es lo que **existe de verdad hoy**.

Un solo workflow ejecuta a cualquier bot leyendo su fila de la tabla `bots`.
Un bot nuevo = un `INSERT`, no un workflow nuevo. Piloto probado de punta a
punta: `tecnico_jefe` → `coder` / `trouble_shooter`.

## Mapa completo (19 nodos)

```
Manual Trigger
  → Reclamar tarea pendiente (Postgres)
  → ¿Hay tarea? (IF)
      → Obtener config del bot (Postgres)
          → Obtener contexto de tarea padre (Postgres)
              → Llamar a omniroute (HTTP)
                  → ¿Necesita aclaración? (IF)
                      [SÍ] → Obtener bot que asignó (Postgres)
                               → ¿Tiene padre? (IF)
                                   [SÍ] → Crear tarea de aclaración (Postgres)
                                            → Bloquear tarea original (Postgres) → fin
                                   [NO] → Send a text message (Telegram)
                                            → Bloquear tarea original (Postgres) → fin
                      [NO] → Guardar resultado (Postgres)
                               → ¿Este bot despacha tareas? (IF)
                                   [SÍ, dispatcher] → ¿Requiere aprobación? (IF)
                                       [SÍ] → Send a text message → Bloquear tarea original
                                       [NO] → Parsear asignaciones (Code)
                                                → Crear tareas hijas (Postgres) → fin
                                   [NO, ejecutor simple] → ¿Requiere aprobación?1 (IF)
                                       [SÍ] → Send a text message → Bloquear tarea original
                                       [NO] → fin (ya quedó guardado en "Guardar resultado")

Cualquier nodo marcado con manejo de error → Marcar como fallida (Postgres)
```

Nota: hay **dos** nodos `¿Requiere aprobación?` (uno para bots que despachan,
otro para los que no) porque cada rama necesita continuar a un nodo distinto
después — no es un error, es intencional.

## Nodo por nodo

### 1. Reclamar tarea pendiente
```sql
UPDATE tasks
SET status = 'running', updated_at = now()
WHERE id = (
  SELECT id FROM tasks
  WHERE status = 'pending'
  ORDER BY created_at
  LIMIT 1
  FOR UPDATE SKIP LOCKED
)
RETURNING *;
```
`SKIP LOCKED` evita que dos corridas simultáneas tomen la misma tarea.

### 2. ¿Hay tarea? — IF
`{{ $json.id }}` no vacío. Si no hay tarea pendiente, el workflow termina ahí.

### 3. Obtener config del bot
```sql
SELECT * FROM bots WHERE slug = '{{ $json.bot }}' AND active = true LIMIT 1;
```

### 4. Obtener contexto de tarea padre
```sql
SELECT p.input->>'text' AS parent_input, p.bot AS parent_bot
FROM tasks t
LEFT JOIN tasks p ON p.id = t.parent_task_id
WHERE t.id = $1;
```
Le da al bot un segundo mensaje de sistema con quién le asignó la tarea y a
partir de qué texto — o le avisa que es la primera de su cadena si no tiene padre.

### 5. Llamar a omniroute
```
POST http://omniroute:20128/v1/chat/completions
{
  "model": <default_model del bot>,
  "messages": [
    { "role": "system", "content": <system_prompt del bot> },
    { "role": "system", "content": <contexto de linaje, o "primera de su cadena"> },
    { "role": "user", "content": <input.text de la tarea> }
  ]
}
```
`retryOnFail: true`. Esto **no incluye todavía** el contexto de memoria
(`system_knowledge` / `knowledge_log`) — ver sección "Lo que falta" abajo.

### 6. ¿Necesita aclaración? — IF
`{{ $json.choices[0].message.content.startsWith('NECESITA_ACLARACION:') }}`

### 7a. Rama SÍ — Obtener bot que asignó
```sql
SELECT p.bot AS bot_padre, p.cluster AS cluster_padre
FROM tasks t
LEFT JOIN tasks p ON p.id = t.parent_task_id
WHERE t.id = $1;
```

### 7b. ¿Tiene padre? — IF
`{{ $json.bot_padre }}` no vacío.

- **SÍ tiene padre** → **Crear tarea de aclaración**:
  ```sql
  INSERT INTO tasks (cluster, bot, status, input, parent_task_id)
  VALUES ($1, $2, 'pending', $3, $4);
  ```
  con `$3 = { text: <pregunta, sin el prefijo "NECESITA_ACLARACION: "> }` y
  `$4 = id de la tarea original` — reanudación bot-a-bot, sin humano en medio.
- **NO tiene padre** (tarea de primer nivel) → **Send a text message** (Telegram, ver abajo).

Ambas ramas terminan en **Bloquear tarea original**:
```sql
UPDATE tasks SET status = 'blocked', updated_at = now()
WHERE id = $1 AND status <> 'needs_approval';
```
El `AND status <> 'needs_approval'` se agregó el 14/ago para que este mismo
nodo compartido (también usado por el flujo de aprobación, ver abajo) no le
pise el estado a una tarea que ya quedó correctamente en `needs_approval`.

### 8. Rama NO — Guardar resultado
```sql
UPDATE tasks SET status = $1, output = $2, updated_at = now() WHERE id = $3;
```
con `$1 = 'needs_approval' si el bot lo requiere, si no 'done'`, `$2 = la
respuesta del modelo`, `$3 = id de la tarea`.

### 9. ¿Este bot despacha tareas? — IF
`{{ dispatches_tasks del bot }}`.

- **SÍ (dispatcher)** → **¿Requiere aprobación?** → si sí, Telegram → Bloquear
  tarea original (con la protección de arriba). Si no, → **Parsear asignaciones**.
- **NO (ejecutor simple, ej. Coder)** → **¿Requiere aprobación?1** → si sí,
  Telegram → Bloquear tarea original. Si no, el workflow simplemente termina —
  el resultado ya quedó guardado en el paso 8.

### 10. Parsear asignaciones (Code)
```javascript
const salida = JSON.parse($('Llamar a omniroute').first().json.choices[0].message.content);
const parentId = $('Reclamar tarea pendiente').first().json.id;
return salida.asignaciones.map(a => ({
  json: {
    cluster: "tech-center",
    bot: a.bot,
    status: "pending",
    input: { text: a.input, modo: a.modo },
    parent_task_id: parentId
  }
}));
```
> ⚠️ **Hallazgo, sin corregir todavía:** `cluster` está fijo en `"tech-center"`,
> sin importar qué bot dispatcher lo llame. Hoy no rompe nada porque los únicos
> dispatchers activos (`tecnico_jefe`, `trouble_shooter`) sí son de esa rama —
> pero en cuanto haya un dispatcher de Estrategia/Crecimiento, sus hijos
> quedarían mal etiquetados. Arreglo: `cluster: a.cluster || $('Obtener config del bot').first().json.cluster`.

### 11. Crear tareas hijas
```sql
INSERT INTO tasks (cluster, bot, status, input, parent_task_id) VALUES ($1, $2, $3, $4, $5);
```
Corre una vez por cada asignación (n8n itera automáticamente sobre los items).

### 12. Send a text message (Telegram)
Chat fijo (`chatId: "-5436560130"`, el grupo de Mateo). Manda literal el
contenido de la respuesta del modelo — mismo nodo compartido para "necesita
aclaración sin padre" y para "necesita aprobación humana".

### 13. Marcar como fallida
```sql
UPDATE tasks SET status = 'failed', output = $1, updated_at = now() WHERE id = $2;
```
Conectada a la salida de error de casi todos los nodos.

> ⚠️ **Hallazgo, sin corregir todavía:** `Reclamar tarea pendiente` y
> `Obtener contexto de tarea padre` **no tienen `onError` configurado** — a
> diferencia de todos los demás nodos Postgres del flujo. Si cualquiera de los
> dos truena, la ejecución se detiene sin pasar por "Marcar como fallida", y la
> tarea se queda colgada en `running` para siempre (mismo síntoma que cancelar
> una ejecución a mano — ver gotcha en [[stack_y_convenciones]]). Arreglo:
> poner `Settings → On Error → Continue (using error output)` en ambos y
> conectar su salida roja a "Marcar como fallida".

## Lo que falta (pendientes reales, no diseño)

1. **Nodo "Cargar contexto"** entre "Obtener config del bot" y "Obtener
   contexto de tarea padre": inyectar `system_knowledge` (según
   `bots.contexto_slugs`) y los `knowledge_log` recientes del cluster, como un
   tercer/cuarto mensaje de sistema en la llamada a OmniRoute. Diseño completo
   en [[memoria_del_sistema]].
2. **Nodos "Extraer patrón" / "Guardar patrón"**: después de "Guardar
   resultado", si `bots.conocimiento_directo = true` (hoy solo
   `trouble_shooter`), parsear `patron_aprendido` del JSON de salida e
   insertarlo en `knowledge_log` con el `ON CONFLICT` que incrementa
   `veces_visto`. Para el resto de los bots, cualquier posible aprendizaje
   espera a que Efadam exista — no se auto-inserta.
3. **`Reanudador de bloqueados`** (workflow separado, `3fKEODc6f6jH9VCJ`): el
   query central ya está completo y correcto —
   ```sql
   UPDATE tasks AS parent
   SET status = 'pending',
       input = jsonb_set(parent.input, '{text}',
                to_jsonb((parent.input->>'text') || E'\n\nAclaración recibida: ' || child.output)),
       updated_at = now()
   FROM tasks AS child
   WHERE child.parent_task_id = parent.id
     AND parent.status = 'blocked'
     AND child.status = 'done'
   RETURNING parent.id;
   ```
   Solo le falta cambiar el trigger de **Manual a Schedule** para que corra solo.
4. Corregir el `cluster` hardcodeado en "Parsear asignaciones" (hallazgo de arriba).
5. Agregar `onError` a los dos nodos que no lo tienen (hallazgo de arriba).
6. El workflow completo sigue en `active: false` en n8n — correrlo hoy requiere
   disparar el Manual Trigger a mano. Pasarlo a Schedule Trigger es parte de
   sacarlo de modo prueba.

## Cómo probarlo hoy

1. Insertar una tarea de prueba:
   ```sql
   INSERT INTO tasks (cluster, bot, status, input) VALUES
   ('tech-center', 'tecnico_jefe', 'pending', '{"text": "..."}');
   ```
2. Correr el Manual Trigger. Revisar que la tarea de Técnico jefe quede `done`
   y que haya tareas hijas nuevas para `coder`/`trouble_shooter`.
3. Correr el trigger otra vez para que reclame la tarea hija.
4. Para probar aclaración: mandar una tarea cuyo prompt fuerce
   `NECESITA_ACLARACION:` y confirmar que, si tiene padre, se crea la tarea de
   vuelta y la original queda `blocked`; si no tiene padre, llega el mensaje a
   Telegram.
