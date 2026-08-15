> **ARCHIVADO — 15 de agosto de 2026.** Diseño original propuesto (v2, 14/ago),
> antes de descubrir que ya se había construido una versión más completa en la
> conversación anterior. Se conserva por trazabilidad: explica el razonamiento
> original de cada pieza (por qué SKIP LOCKED, por qué no usar el modo Update
> con mapeo de columnas, etc.), pero **la implementación real diverge** en
> varios puntos — sobre todo el sistema de aclaración, que aquí se proponía
> "mínimo, sin reanudador automático" y en la realidad ya incluye reanudación
> bot-a-bot completa. Para el estado real, ver [[ejecutor_generico]].

---

# Ejecutor genérico — diseño y construcción (v2, propuesto)

> **v2 — 14 de agosto de 2026.** Agrega: inyección de contexto/memoria, escritura
> automática de patrones de fallo, `parent_task_id` en las tareas hijas, y la
> versión mínima del sistema de aclaración. Reemplaza la v1 completa.

Reemplaza la idea de "un workflow de n8n por bot" por **un solo workflow que
ejecuta cualquier bot**, leyendo su configuración de una tabla en Postgres. Los
40 bots del roster se vuelven filas de config, no 40 workflows.

Piloto probado de punta a punta: **Técnico jefe** (despacha tareas) + **Coder**
(ejecuta y entrega texto).

---

## 1. Schema

### 1.1 Tabla `bots` (v1, ya creada)

```sql
create table bots (
    id serial primary key,
    slug text unique not null,
    cluster text not null,
    system_prompt text not null,
    default_model text not null default 'auto',
    requires_approval boolean not null default false,
    dispatches_tasks boolean not null default false,
    active boolean not null default true
);
```

- `default_model = 'auto'` deja que OmniRoute elija el mejor modelo gratis disponible.
- `requires_approval` = necesita luz verde por Telegram antes de darse por terminado.
- `dispatches_tasks` = no entrega un resultado final, entrega instrucciones para otros bots.

### 1.2 Memoria y linaje (v2 — correr `schema/002_conocimiento.sql`)

Ese archivo agrega: las tablas `system_knowledge` y `knowledge_log`, las columnas
`bots.contexto_slugs` y `bots.prompt_especifico`, `tasks.parent_task_id`, el
constraint de estados válidos de `tasks`, y el trigger que compone
`system_prompt = reglas_generales + prompt_especifico`.

El diseño y el porqué de cada pieza están en `docs/memoria_del_sistema.md`.

**Consecuencia práctica para todo `INSERT`/`UPDATE` de un bot a partir de ahora:**
se escribe `prompt_especifico`, **nunca** `system_prompt` directamente. El trigger
le prepende las reglas generales solo. Escribir `system_prompt` a mano vuelve a
abrir el problema de duplicar o perder las reglas.

## 2. Cargar los bots de prueba

```sql
INSERT INTO bots (slug, cluster, prompt_especifico, default_model, requires_approval, dispatches_tasks, contexto_slugs) VALUES
('tecnico_jefe', 'tech-center', $$...prompt de tecnico-jefe.md...$$, 'auto', false, true, '{arquitectura,stack_y_convenciones}'),
('coder',        'tech-center', $$...prompt de coder.md...$$,        'auto', false, false, '{stack_y_convenciones}');
```

(El texto exacto de cada prompt vive en `prompts_dev_tech/<bot>.md`, sección
"Prompt de sistema". La tabla es una copia; el repo es la fuente de verdad.)

## 3. Una tarea de prueba para arrancar el loop

```sql
INSERT INTO tasks (cluster, bot, status, input) VALUES
('tech-center', 'tecnico_jefe', 'pending',
 '{"text": "Ticket: agrega un endpoint que reciba un webhook de WhatsApp y guarde el mensaje en una tabla whatsapp_messages. Modo sugerido por el usuario: lean."}');
```

## 4. Construir el workflow en n8n (nodo por nodo)

Nombra el workflow **"Ejecutor genérico"**.

**Nodo 1 — Manual Trigger** (para probar; luego Schedule Trigger cada 1 minuto).

**Nodo 2 — Postgres → "Reclamar tarea pendiente"**
Operación: *Execute Query*.
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
(El `SKIP LOCKED` evita que dos ejecuciones tomen la misma tarea a la vez.)

**Nodo 3 — IF → "¿Hay tarea?"**
Condición: `{{$json.id}}` — *is not empty*. Rama falsa → sin más nodos.

**Nodo 4 — Postgres → "Obtener config del bot"**
```sql
SELECT * FROM bots WHERE slug = '{{ $json.bot }}' AND active = true LIMIT 1;
```

**Nodo 4b — Postgres → "Cargar contexto"** *(nuevo en v2)*
Operación: *Execute Query*. Devuelve una sola fila con dos columnas de texto ya
armadas, para no tener que concatenar nada en el nodo HTTP.
```sql
with sk as (
  select coalesce(string_agg(titulo || E'\n' || contenido, E'\n\n---\n\n' order by slug), '') as txt
  from system_knowledge
  where slug = any(string_to_array($1, ','))
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
      '- [' || tipo || ' · visto ' || veces_visto || 'x] ' || titulo || ' → ' || resumen_corto
      || coalesce(E'\n  Fix conocido: ' || detalle_completo, ''),
      E'\n' order by updated_at desc), '') as txt
  from kl_rows
)
select sk.txt as system_knowledge, kl.txt as knowledge_log from sk, kl;
```
- Options → Query Parameters (modo expresión):
```
{{ [ ($('Obtener config del bot').item.json.contexto_slugs || []).join(','), $('Reclamar tarea pendiente').item.json.cluster ] }}
```
Si el bot tiene `contexto_slugs = '{}'`, `system_knowledge` sale vacío y no se
inyecta nada — que es exactamente lo que queremos para bots que no necesitan
saber cómo está armado el sistema.

**Nodo 5 — HTTP Request → "Llamar a OmniRoute"**
- Method: `POST`
- URL: `http://omniroute:20128/v1/chat/completions`
  (nombre del servicio de Docker, no `localhost`)
- Body Content Type: JSON
- Body en modo expresión, armado con `JSON.stringify` (nunca como texto JSON con
  expresiones incrustadas — los prompts traen comillas y llaves propias):
```
={{ JSON.stringify({
  model: $('Obtener config del bot').item.json.default_model,
  messages: [
    { role: "system", content: [
        $('Obtener config del bot').item.json.system_prompt,
        $json.system_knowledge ? "## Conocimiento del sistema\n\n" + $json.system_knowledge : null,
        $json.knowledge_log ? "## Casos y patrones ya conocidos — úsalos, no los re-investigues\n\n" + $json.knowledge_log : null
      ].filter(Boolean).join("\n\n---\n\n") },
    { role: "user", content: $('Reclamar tarea pendiente').item.json.input.text }
  ]
}) }}
```
> Ojo: en v1 este nodo usaba `$json.system_prompt` porque venía directo del nodo 4.
> Al meter el nodo 4b en medio, `$json` ya es el contexto — por eso ahora se
> referencia la config **por nombre de nodo**. Todo el contexto va en un solo
> mensaje `system`; varios mensajes `system` no los aceptan todos los proveedores
> gratis de OmniRoute.

**Nodo 6 — Postgres → "Guardar resultado"**
Operación: *Execute Query* con parámetros. **No uses el modo Update con mapeo de
columnas** — cachea el tipo de cada columna de cuando configuraste el nodo.
```sql
UPDATE tasks SET
  status = case when $1 like 'NECESITA_ACLARACION:%' then 'blocked' else 'done' end,
  output = $1,
  updated_at = now()
WHERE id = $2;
```
- Options → Query Parameters (modo expresión):
```
{{ [$json.choices[0].message.content, $('Reclamar tarea pendiente').item.json.id] }}
```
Esa línea del `case` **es** el sistema de aclaración completo del lado de
guardado — ver sección 5.

**Nodo 7 — IF → "¿Pidió aclaración?"** *(nuevo en v2)*
Condición (expresión, *is true*):
```
{{ $('Llamar a OmniRoute').item.json.choices[0].message.content.startsWith('NECESITA_ACLARACION:') }}
```
- **Rama verdadera → Nodo 7b — Telegram "Send a text message"**, con:
```
={{ "🔶 Tarea " + $('Reclamar tarea pendiente').item.json.id + " (" + $('Reclamar tarea pendiente').item.json.bot + ") está BLOQUEADA.\n\n" + $('Llamar a OmniRoute').item.json.choices[0].message.content }}
```
  Ahí termina esa rama. La tarea queda en `blocked` hasta que un humano la
  desbloquee (sección 5).
- **Rama falsa → sigue al Nodo 8.**

**Nodo 8 — IF → "¿Este bot despacha tareas?"**
Condición: `{{ $('Obtener config del bot').item.json.dispatches_tasks }}` — *is true*.

**Rama verdadera — Nodo 9 — Code (JavaScript) → "Parsear asignaciones"**
```javascript
const tarea = $('Reclamar tarea pendiente').item.json;
const salida = JSON.parse($('Llamar a OmniRoute').item.json.choices[0].message.content);
return (salida.asignaciones || []).map(a => ({
  json: {
    cluster: a.cluster || tarea.cluster,
    bot: a.bot,
    status: "pending",
    input: { text: a.input, modo: a.modo },
    parent_task_id: tarea.id
  }
}));
```
> Cambios respecto a v1: el `cluster` ya no está hardcodeado a `"tech-center"`
> (Trouble shooter puede dirigir un fix a cualquier rama), y se propaga
> `parent_task_id` para tener linaje.

**Nodo 10 — Postgres → "Crear tareas hijas"**
Operación: *Execute Query* con parámetros. **No uses el modo Insert con mapeo de
columnas**: incluye `id` con valor `0` y la segunda corrida revienta con
`duplicate key`.
```sql
INSERT INTO tasks (cluster, bot, status, input, parent_task_id) VALUES ($1, $2, $3, $4, $5);
```
- Options → Query Parameters (modo expresión):
```
{{ [$json.cluster, $json.bot, $json.status, JSON.stringify($json.input), $json.parent_task_id] }}
```
n8n corre este nodo una vez por item, así que 2 asignaciones = 2 filas.

**Rama falsa del Nodo 8 (bot que no despacha, como Coder):** su resultado ya
quedó guardado en el Nodo 6, no necesita nada más.

**Nodo 11 — Code (JavaScript) → "Extraer patrón aprendido"** *(nuevo en v2)*
Va enganchado después del Nodo 9 (o después del Nodo 6, en paralelo — da igual,
mientras corra después de tener la respuesta). Devolver un array vacío hace que
el nodo siguiente simplemente no corra, así que no hace falta un IF.
```javascript
let out;
try { out = JSON.parse($('Llamar a OmniRoute').item.json.choices[0].message.content); }
catch (e) { return []; }
const p = out.patron_aprendido;
if (!p || !p.patron) return [];
const tarea = $('Reclamar tarea pendiente').item.json;
return [{ json: {
  titulo: String(p.patron).slice(0, 200),
  resumen_corto: p.causa_raiz || '',
  detalle_completo: p.fix || '',
  cluster: tarea.cluster,
  origen_bot: tarea.bot,
  task_id: tarea.id
}}];
```

**Nodo 12 — Postgres → "Guardar patrón"** *(nuevo en v2)*
```sql
insert into knowledge_log (tipo, titulo, resumen_corto, detalle_completo, cluster, origen_bot, task_id)
values ('patron_fallo', $1, $2, $3, $4, $5, $6)
on conflict (lower(titulo)) where tipo = 'patron_fallo'
do update set veces_visto = knowledge_log.veces_visto + 1,
              updated_at = now();
```
- Options → Query Parameters (modo expresión):
```
{{ [$json.titulo, $json.resumen_corto, $json.detalle_completo, $json.cluster, $json.origen_bot, $json.task_id] }}
```
El `on conflict` es lo que hace que un patrón repetido incremente `veces_visto`
en vez de duplicarse — y ese contador es lo que le llega a Trouble shooter la
próxima vez en su contexto, en lugar de pedirle que recuerde cuántas veces vio
un error.

**Nodo 13 (opcional) — IF → "¿Requiere aprobación?"**
Condición: `{{ $('Obtener config del bot').item.json.requires_approval }}` — *is true*.
Rama verdadera → Telegram con el contenido de `output`.

**Nodo 14 — Postgres → "Marcar como fallida"** (manejo de errores — no es opcional)

Sin esto, cualquier fallo a mitad del flujo deja la tarea atascada en `running`
para siempre.
```sql
UPDATE tasks SET status = 'failed', output = $1, updated_at = now() WHERE id = $2;
```
- Query Parameters:
```
{{ [$json.error?.message ?? JSON.stringify($json), $('Reclamar tarea pendiente').item.json.id] }}
```

En cada nodo que puede fallar (Obtener config del bot, Cargar contexto, Llamar a
OmniRoute, Guardar resultado, Parsear asignaciones, Crear tareas hijas, Extraer
patrón, Guardar patrón): **Settings → On Error → `Continue (using error output)`**,
y conectar todas las salidas rojas a este nodo.

En "Llamar a OmniRoute" activa además **Retry On Fail** (3 intentos, 1000ms).

Reintentar una tarea fallida: `UPDATE tasks SET status = 'pending' WHERE id = <id>;`

## 5. Sistema de aclaración — versión mínima

Las reglas generales le dicen a todo bot que, si le falta información esencial,
responda `NECESITA_ACLARACION: <pregunta>` y nada más. Del lado del ejecutor eso
son exactamente dos cosas:

1. El `case` del Nodo 6, que marca la tarea `blocked` en vez de `done`.
2. El IF del Nodo 7 + Telegram, que le manda la pregunta a Mateo.

**No hay reanudador automático todavía, a propósito.** Mateo desbloquea a mano:

```sql
UPDATE tasks
   SET input = jsonb_set(input, '{text}',
                to_jsonb((input->>'text') || E'\n\nACLARACIÓN DEL HUMANO: ' || 'aquí la respuesta')),
       status = 'pending',
       output = null
 WHERE id = <id>;
```

El workflow "Reanudador de bloqueados" (que un bot padre conteste a un bot hijo
sin humano en medio) solo vale la pena cuando (a) haya evidencia de que los bots
efectivamente se bloquean seguido, y (b) haya cadenas de más de 2 niveles donde
el humano sea el cuello de botella real. Hoy no se cumple ninguna de las dos:
hay 2 bots activos y Mateo está mirando cada corrida.

> **Nota de la versión archivada:** esta sección quedó totalmente superada. La
> conversación anterior ya había construido el reanudador completo, con
> reanudación bot-a-bot automática, antes de que se escribiera este documento.
> Ver [[ejecutor_generico]].

## 6. Probarlo

1. Corre el Nodo 1 manualmente.
2. Revisa `tasks` — debería haber una fila nueva con `bot = 'coder'`,
   `status = 'pending'`, `parent_task_id` apuntando a la tarea del Técnico jefe.
3. Corre el workflow otra vez (reclama la tarea del Coder).
4. Esa fila debería quedar `done` con el código en `output`.

Verificación extra de v2:
```sql
select slug, contexto_slugs, left(system_prompt, 80) from bots;   -- ¿traen reglas generales?
select * from knowledge_log order by updated_at desc;             -- ¿se escriben patrones?
```

## 7. Lo que queda pendiente, a propósito, para después

- **`agent_runs` (logs de costo/modelo/tiempo):** se llena en la Fase 4.
- **Telegram con botones de aprobar/rechazar:** necesita webhook público (VPS o `--tunnel`).
- **Reanudador de bloqueados:** ver sección 5, criterio de activación explícito.
- **Limpieza de tareas colgadas en `running`:** cancelar una ejecución a mano las
  deja ahí. Cuando pase 3+ veces, agregar un workflow que resetee las que lleven
  más de X minutos en `running`.
- **Auto-modificación de "Out of the box thinker":** en pausa hasta que la
  rebanada vertical de Legal esté probada.
