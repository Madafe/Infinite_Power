# Ejecutor genérico — estado real

> **Actualizado 15/ago/2026, tras el pase de memoria.** 22 nodos (empezó en
> 19). Los 3 hallazgos que la versión anterior de este documento señalaba como
> "sin corregir" ya están corregidos y verificados contra n8n real. Se
> agregaron 3 nodos: "Cargar contexto", "Extraer patron", "Guardar patron".

Un solo workflow ejecuta a cualquier bot leyendo su fila de la tabla `bots`.
Un bot nuevo = un `INSERT`, no un workflow nuevo. Piloto probado de punta a
punta: `tecnico_jefe` → `coder` / `trouble_shooter`.

## Mapa completo (22 nodos)

```
Manual Trigger
  → Reclamar tarea pendiente (Postgres)
  → ¿Hay tarea? (IF)
      → Obtener config del bot (Postgres)
          → Obtener contexto de tarea padre (Postgres)
              → Cargar contexto (Postgres)              [nuevo]
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
                                           [NO] → fin
                                   → Extraer patron (Code)                          [nuevo, en paralelo]
                                       → Guardar patron (Postgres) → fin

Cualquier nodo con manejo de error → Marcar como fallida (Postgres)
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
`onError: continueErrorOutput` — corregido 15/ago (antes no lo tenía).

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
`onError: continueErrorOutput` — corregido 15/ago (antes no lo tenía).

### 5. Cargar contexto — nuevo, 15/ago

```sql
with sk as (
  select coalesce(string_agg(titulo || E'\n' || contenido, E'\n\n---\n\n' order by slug), '') as txt
  from system_knowledge
  where slug = any($1::text[])
),
kl_rows as (
  select tipo, titulo, resumen_corto, detalle_completo, veces_visto, updated_at
  from knowledge_log
  where activo and (cluster is null or cluster = $2)
  order by updated_at desc
  limit 15
),
kl as (
  select coalesce(string_agg(
      '- [' || tipo || ' - visto ' || veces_visto || 'x] ' || titulo || ' -> ' || resumen_corto
      || coalesce(E'\n  Fix conocido: ' || detalle_completo, ''),
      E'\n' order by updated_at desc), '') as txt
  from kl_rows
)
select sk.txt as system_knowledge, kl.txt as knowledge_log from sk, kl;
```
Parámetros: `[bots.contexto_slugs, tasks.cluster]`. Si `contexto_slugs = '{}'`,
`system_knowledge` sale vacío y no se inyecta nada — correcto para bots que no
necesitan saber cómo está armado el sistema.

### 6. Llamar a omniroute
```
POST http://omniroute:20128/v1/chat/completions
{
  "model": <default_model del bot>,
  "messages": [
    { "role": "system", "content": <system_prompt del bot> },
    { "role": "system", "content": <contexto de linaje, o "primera de su cadena"> },
    { "role": "system", "content": <system_knowledge, solo si no está vacío> },
    { "role": "system", "content": <knowledge_log, solo si no está vacío> },
    { "role": "user", "content": <input.text de la tarea> }
  ]
}
```
`retryOnFail: true`. Todas las referencias son por nombre de nodo
(`$('Obtener config del bot')`, `$('Obtener contexto de tarea padre')`,
`$('Cargar contexto')`, `$('Reclamar tarea pendiente')`), no por `$json` — así
no se rompe si se inserta otro nodo en medio más adelante.

### 7. ¿Necesita aclaración? — IF
`{{ $json.choices[0].message.content.startsWith('NECESITA_ACLARACION:') }}`

### 8a. Rama SÍ — Obtener bot que asignó
```sql
SELECT p.bot AS bot_padre, p.cluster AS cluster_padre
FROM tasks t
LEFT JOIN tasks p ON p.id = t.parent_task_id
WHERE t.id = $1;
```

### 8b. ¿Tiene padre? — IF
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
El `AND status <> 'needs_approval'` evita que este nodo compartido (también
usado por el flujo de aprobación, ver abajo) le pise el estado a una tarea que
ya quedó correctamente en `needs_approval`.

### 9. Rama NO — Guardar resultado
```sql
UPDATE tasks SET status = $1, output = $2, updated_at = now() WHERE id = $3;
```
con `$1 = 'needs_approval' si el bot lo requiere, si no 'done'`, `$2 = la
respuesta del modelo`, `$3 = id de la tarea`.

Desde aquí salen **dos** ramas en paralelo: `¿Este bot despacha tareas?` y
`Extraer patron` (nueva, no bloquea ni depende de la otra).

### 10. ¿Este bot despacha tareas? — IF
`{{ dispatches_tasks del bot }}`.

- **SÍ (dispatcher)** → **¿Requiere aprobación?** → si sí, Telegram → Bloquear
  tarea original. Si no, → **Parsear asignaciones**.
- **NO (ejecutor simple, ej. Coder)** → **¿Requiere aprobación?1** → si sí,
  Telegram → Bloquear tarea original. Si no, el workflow simplemente termina —
  el resultado ya quedó guardado en el paso 9.

### 11. Parsear asignaciones (Code)
```javascript
const salida = JSON.parse($('Llamar a omniroute').first().json.choices[0].message.content);
const parentId = $('Reclamar tarea pendiente').first().json.id;
const clusterPropio = $('Obtener config del bot').first().json.cluster;
return salida.asignaciones.map(a => ({
  json: {
    cluster: a.cluster || clusterPropio,
    bot: a.bot,
    status: "pending",
    input: { text: a.input, modo: a.modo },
    parent_task_id: parentId
  }
}));
```
**Corregido 15/ago:** antes tenía `cluster: "tech-center"` fijo, sin importar
qué bot dispatcher lo llamara. Ahora usa el `cluster` que el propio dispatcher
sugiera en su JSON de salida, y si no lo sugiere, cae al `cluster` del bot que
está despachando (`Obtener config del bot`).

### 12. Crear tareas hijas
```sql
INSERT INTO tasks (cluster, bot, status, input, parent_task_id) VALUES ($1, $2, $3, $4, $5);
```
Corre una vez por cada asignación (n8n itera automáticamente sobre los items).

### 13. Extraer patron — nuevo, 15/ago (Code)

```javascript
const cfg = $('Obtener config del bot').first().json;
if (!cfg.conocimiento_directo) return [];
let out;
try { out = JSON.parse($('Llamar a omniroute').first().json.choices[0].message.content); }
catch (e) { return []; }
const p = out.patron_aprendido;
if (!p || !p.patron) return [];
const tarea = $('Reclamar tarea pendiente').first().json;
return [{ json: {
  titulo: String(p.patron).slice(0, 200),
  resumen_corto: p.causa_raiz || '',
  detalle_completo: p.fix || '',
  cluster: tarea.cluster,
  origen_bot: tarea.bot,
  task_id: tarea.id
}}];
```
Solo produce salida si `bots.conocimiento_directo = true` — hoy únicamente
`trouble_shooter`. Para cualquier otro bot, este nodo devuelve `[]` y la
cadena simplemente no continúa (no hace falta un IF explícito).

### 14. Guardar patron — nuevo, 15/ago
```sql
insert into knowledge_log (tipo, titulo, resumen_corto, detalle_completo, cluster, origen_bot, task_id)
values ('patron_fallo', $1, $2, $3, $4, $5, $6)
on conflict (lower(titulo)) where tipo = 'patron_fallo'
do update set veces_visto = knowledge_log.veces_visto + 1, updated_at = now();
```
El `on conflict` incrementa `veces_visto` en vez de duplicar — ese contador es
lo que Trouble shooter recibe la próxima vez, vía `Cargar contexto`.

### 15. Send a text message (Telegram)
Chat fijo (`chatId: "-5436560130"`, el grupo de Mateo). Manda literal el
contenido de la respuesta del modelo — mismo nodo compartido para "necesita
aclaración sin padre" y para "necesita aprobación humana".

### 16. Marcar como fallida
```sql
UPDATE tasks SET status = 'failed', output = $1, updated_at = now() WHERE id = $2;
```
Conectada a la salida de error de todos los nodos que la tienen configurada —
ya son todos los que pueden fallar de forma relevante (ver hallazgos corregidos abajo).

## Hallazgos de la revisión anterior — ya corregidos (15/ago)

1. ~~`cluster` hardcodeado en "Parsear asignaciones"~~ → corregido (nodo 11).
2. ~~`Reclamar tarea pendiente` y `Obtener contexto de tarea padre` sin `onError`~~
   → ambos tienen `continueErrorOutput` ahora, con salida conectada a "Marcar como fallida".
3. ~~Sin inyección de memoria (`system_knowledge`/`knowledge_log`)~~ → nodo
   "Cargar contexto" construido y conectado.
4. ~~Sin escritura automática de patrones~~ → nodos "Extraer patron" /
   "Guardar patron" construidos, condicionados a `conocimiento_directo`.

## Lo que falta (pendientes reales)

1. **`Reanudador de bloqueados`** (workflow separado, `3fKEODc6f6jH9VCJ`): el
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
2. El workflow completo sigue en `active: false` en n8n — correrlo hoy requiere
   disparar el Manual Trigger a mano. Pasarlo a Schedule Trigger es parte de
   sacarlo de modo prueba.
3. Prueba end-to-end en vivo del loop completo (memoria + aclaración +
   reanudador) — construido y verificado en estructura, falta correrlo con una
   tarea real y confirmar el resultado.

## Workflow "Sync conocimiento del sistema" — nuevo, 15/ago

Ver [[memoria_del_sistema]] sección "Sincronización repo → tabla" para el
diseño completo. Resumen: `docker-compose.yml` monta `./docs` de solo-lectura
en el contenedor de n8n (`/data/docs`), y un workflow separado
(`jWylnrFYalt5vrOB`) lee los 3 archivos canónicos y hace upsert en
`system_knowledge`. Manual Trigger también, mismo criterio que el ejecutor.

## Cómo probarlo hoy

1. Insertar una tarea de prueba:
   ```sql
   INSERT INTO tasks (cluster, bot, status, input) VALUES
   ('tech-center', 'tecnico_jefe', 'pending', '{"text": "..."}');
   ```
2. Correr el Manual Trigger del "Ejecutor genérico". Revisar que la tarea de
   Técnico jefe quede `done` y que haya tareas hijas nuevas para
   `coder`/`trouble_shooter`.
3. Correr el trigger otra vez para que reclame la tarea hija.
4. Para probar aclaración: mandar una tarea cuyo prompt fuerce
   `NECESITA_ACLARACION:` y confirmar que, si tiene padre, se crea la tarea de
   vuelta y la original queda `blocked`; si no tiene padre, llega el mensaje a
   Telegram.
5. Para probar memoria: confirmar en `output` de una tarea de `tecnico_jefe`
   que la respuesta refleja contenido de `system_knowledge` (ej. que mencione
   la arquitectura real de 3 ramas).
