# Ejecutor genérico — estado real

> **Actualizado 18/ago/2026, tarde-noche.** 26 nodos (venía de 22). Se
> construyó el auto-dispatch a Trouble shooter que faltaba, se corrigió una
> inyección SQL real, se propagó `nivel_importancia` a las tareas hijas, y —
> el hallazgo más grande de la sesión — se descubrió y corrigió un bug
> sistémico en el manejo de errores: **"Marcar como fallida" nunca se había
> ejecutado ni una sola vez en la vida de este workflow**, porque el
> mecanismo `onError: continueErrorOutput` no rutea los errores a la salida
> de error en esta instalación de n8n para nodos Postgres/Code/HTTP Request
> de salida única. Ver la sección "Hallazgo grande" más abajo — es la lectura
> más importante de esta actualización.

Un solo workflow ejecuta a cualquier bot leyendo su fila de la tabla `bots`.
Un bot nuevo = un `INSERT`, no un workflow nuevo. Piloto probado de punta a
punta: `tecnico_jefe` → `coder`. **Corrección 18/ago — anula la corrección
del 17/ago, noche, quinta ronda, que estaba mal:** esa ronda dijo que
`trouble_shooter` "nunca se insertó como fila activa en `bots`", basado en
que los únicos scripts commiteados que lo tocan (`003_trouble_shooter_v2.sql`,
`004_conocimiento_directo.sql`) son ambos `UPDATE`. El razonamiento tenía un
hueco: tampoco existe ningún script commiteado de `INSERT` para
`tecnico_jefe` ni `coder` (`schema/001_init.sql` es puro `CREATE TABLE`, sin
datos) — los 3 bots que existen hoy se insertaron a mano, fuera de cualquier
script versionado, y ese patrón no se pudo verificar la ronda pasada porque
Postgres estaba apagado. Confirmado el 18/ago directo contra la base real:
`trouble_shooter` SÍ está insertado y activo (`active = true`,
`dispatches_tasks = true`, `conocimiento_directo = true`), con el
`prompt_especifico` exacto de `003_trouble_shooter_v2.sql`.

## Hallazgo grande del 18/ago — `continueErrorOutput` no funciona como se creía

Cada nodo de este workflow con `onError: continueErrorOutput` fue diseñado
asumiendo que, al fallar, n8n manda el item de error a una **segunda salida**
dedicada (la que está conectada a "Marcar como fallida" en el diagrama de
abajo). Probando en vivo el 18/ago (forzando un fallo real: una tarea con
`nivel_importancia = null`, que hace que OmniRoute responda `400 Missing
model`), se confirmó que **eso no es lo que pasa**: el item de error se queda
en la salida normal/éxito (salida 0), y la segunda salida (salida 1, la
"salida de error") se queda vacía. El resultado práctico: cuando
"Llamar a omniroute" fallaba, el error se colaba como si fuera una respuesta
válida hacia "¿Necesita aclaración?" → "Guardar resultado", que a su vez
también fallaba (por la misma razón) y dejaba la tarea trabada en
`status = 'running'` para siempre, sin error registrado y sin que
"Marcar como fallida" se enterara nunca.

Se revisó el código fuente de n8n dentro del contenedor
(`n8n-core/dist/execution-engine/workflow-execute.js`,
`handleNodeErrorOutput`) para confirmar que no era un malentendido de
configuración: la función que debería mover los items de error a la segunda
salida sí existe y sí se llama, pero en la práctica, para nodos Postgres/Code
y para el HTTP Request node usado aquí, el item de error terminó quedándose
en la salida 0 de todos modos. No se llegó a la causa raíz exacta dentro de
n8n (no vale la pena seguir esa madriguera hoy) — lo que importa es el
comportamiento real, confirmado con evidencia directa de 4 ejecuciones
distintas.

**Consecuencia importante:** esto significa que "Marcar como fallida" (nodo
16 de la versión anterior de este documento) **nunca se había disparado ni
una sola vez desde que existe este workflow** — no solo faltaba el
auto-dispatch a Trouble shooter (eso ya se sabía), sino que el nodo que
debía dispararlo tampoco corría nunca. Cualquier fallo real en producción
hasta hoy se quedó silenciosamente como una tarea trabada en `running`, sin
diagnóstico, sin registro de error. Se encontraron y repararon dos tareas
reales así trabadas desde el 13 y el 14 de agosto (ids 4 y 7, del piloto
`tecnico_jefe → coder`) — les faltaba `nivel_importancia` (columna agregada
después, nunca retro-poblada) y por eso quedaron colgadas exactamente por
esta razón. Se les asignó `nivel_importancia = 'medio'` y se corrieron de
verdad: ambas terminaron `done` con resultado real.

**Arreglo aplicado (solo en el punto que hoy importa — "Llamar a
omniroute"):**

En vez de confiar en la segunda salida de `continueErrorOutput`, se agregó
una verificación explícita del contenido del item, y se evita depender de
referencias cruzadas (`$('Nombre del nodo')`) dentro del campo
`queryReplacement` de un nodo Postgres cuando ese nodo se alcanza por una
ruta que pasó por una salida de error — esa combinación específica también
falló en las pruebas (ver detalle en el nodo "Marcar como fallida" más
abajo). El patrón que sí funcionó de forma confiable: un nodo Code justo
antes de "Marcar como fallida" que resuelve las referencias cruzadas él
mismo y deja los valores listos en `$json`, para que "Marcar como fallida"
solo necesite acceso local (`$json.algo`, sin `$('Nombre')`).

**Pendiente real, no resuelto hoy:** el mismo problema de fondo sigue latente
en **todos los demás nodos** de este workflow que tienen
`onError: continueErrorOutput` configurado y de tipo Postgres o Code (salida
nativa única) — no se tocaron hoy porque el foco era desbloquear el
auto-dispatch a Trouble shooter, no reparar el manejo de errores completo.
Lista de nodos que hoy siguen con esta misma falla latente (su "salida de
error" nunca recibe nada de verdad):

- Reclamar tarea pendiente
- Obtener config del bot
- Guardar resultado
- Parsear asignaciones
- Crear tareas hijas
- Send a text message
- Obtener bot que asignó
- Crear tarea de aclaración
- Bloquear tarea original
- Obtener contexto de tarea padre
- Cargar contexto
- Extraer patron
- Guardar patron

Los nodos `¿Necesita aclaración?`, `¿Requiere aprobación?`, `¿Requiere
aprobación?1`, `¿Tiene padre?`, `¿Hay tarea?` (todos IF) probablemente **no**
tienen este problema — un nodo IF tiene 2 salidas nativas (SÍ/NO) y, según el
código fuente revisado, cuando se le agrega `continueErrorOutput` pasa a
tener 3, y la lógica de clasificación sí alcanza a correr con más de una
salida nativa. No se probó en vivo, es una inferencia del código, no un
hecho confirmado — anotarlo así, no como certeza.

**Este es un hallazgo nuevo, hoy sin nombre asignado en la numeración de
hallazgos de `stack_y_convenciones.md`/`trouble-shooter.md` — llamarlo
"hallazgo C5" en cualquier documento futuro que lo retome**, para no
chocar con C1-C4 que ya existen. Arreglarlo bien (los 13 nodos de la lista)
es un trabajo aparte, no trivial — cada uno necesita decidir qué datos debe
capturar el nodo Code intermedio y a qué debería apuntar la tarea de
Trouble shooter cuando ese nodo específico es el que falla. No se intentó
hoy por prudencia, no por falta de tiempo: tocar 13 nodos más sin poder
probar cada uno con calma al final de una sesión ya larga es más riesgo que
beneficio.

## Mapa completo (26 nodos)

```
Manual Trigger
  → Reclamar tarea pendiente (Postgres)
  → ¿Hay tarea? (IF)
      → Obtener config del bot (Postgres)
          → Obtener contexto de tarea padre (Postgres)
              → Cargar contexto (Postgres)
                  → Llamar a omniroute (HTTP)
                      → ¿Falló la llamada a omniroute? (IF)            [nuevo, 18/ago]
                          [SÍ] → Preparar fallo (Code)                  [nuevo, 18/ago]
                                   → Marcar como fallida (Postgres)
                          [NO] → ¿Necesita aclaración? (IF)
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
                                           → Extraer patron (Code)
                                               → Guardar patron (Postgres) → fin

Marcar como fallida (Postgres)
  → ¿Bot que falló no es trouble_shooter? (IF)                          [nuevo, 18/ago]
      [SÍ] → Despachar a trouble_shooter (Postgres) → fin               [nuevo, 18/ago]
      [NO] → fin (evita que un fallo de trouble_shooter se auto-despache a sí mismo)

Cualquier otro nodo con onError configurado → declarado hacia Marcar como
fallida, pero ver "Hallazgo grande" arriba: hoy esa conexión no funciona de
verdad para esos nodos, solo para "Llamar a omniroute".
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
`onError: continueErrorOutput` configurado, pero ver "Hallazgo grande" — no
funciona de verdad hoy.

### 2. ¿Hay tarea? — IF
`{{ $json.id }}` no vacío. Si no hay tarea pendiente, el workflow termina ahí.

### 3. Obtener config del bot
```sql
SELECT * FROM bots WHERE slug = $1 AND active = true LIMIT 1;
```
`queryReplacement: [$json.bot]`. **Corregido 18/ago — hallazgo C2 (inyección
SQL) cerrado.** Antes interpolaba `$json.bot` directo dentro del string SQL
(`WHERE slug = '{{ $json.bot }}'`) — como ese valor puede venir del JSON de
salida de un bot dispatcher (un LLM), era una inyección SQL real, no
teórica. Ahora usa parámetro `$1` parametrizado, igual que el resto de las
queries del workflow.

**Hallazgo nuevo, no corregido hoy:** si `bot` no corresponde a ningún slug
activo, esta query regresa 0 filas — y como 0 filas no es un error, la tarea
se queda trabada en `running` para siempre, sin pasar por "Marcar como
fallida" y sin que Trouble shooter se entere. Esto es justo el caso que
`trouble-shooter.md` anticipa explícitamente ("si no reconoce el bot que
falló... nunca inventa un destino"), pero hoy ese caso ni siquiera le llega
— el workflow simplemente no continúa, sin error visible. Necesita su propio
IF explícito (`¿Existe el bot?`) para no depender de que 0 filas se comporte
como un error, que no es el caso.

### 4. Obtener contexto de tarea padre
```sql
SELECT p.input->>'text' AS parent_input, p.bot AS parent_bot
FROM tasks t
LEFT JOIN tasks p ON p.id = t.parent_task_id
WHERE t.id = $1;
```
Le da al bot un segundo mensaje de sistema con quién le asignó la tarea y a
partir de qué texto — o le avisa que es la primera de su cadena si no tiene padre.

### 5. Cargar contexto

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
  "model": <tasks.nivel_importancia de la tarea — bajo/medio/alto/critico>,
  "messages": [
    { "role": "system", "content": <system_prompt del bot> },
    { "role": "system", "content": <contexto de linaje, o "primera de su cadena"> },
    { "role": "system", "content": <system_knowledge, solo si no está vacío> },
    { "role": "system", "content": <knowledge_log, solo si no está vacío> },
    { "role": "user", "content": <input.text de la tarea> }
  ]
}
```
Efadam asigna `nivel_importancia` al despachar la tarea; el bot que la
ejecuta lo hereda, nunca lo decide. OmniRoute resuelve ese valor al modelo
real vía sus "combos" (ver `stack_y_convenciones.md`, sección "Niveles de
importancia y BYOK"). Si `nivel_importancia` es `null` (tareas viejas, de
antes de que existiera la columna), OmniRoute responde `400 Missing model` —
así se confirmó en vivo el hallazgo grande de arriba.

`retryOnFail: true`.

### 7. ¿Falló la llamada a omniroute? — nuevo, 18/ago (IF)
`{{ $json.error !== undefined }}`. Chequeo explícito, no depende de la
segunda salida de `continueErrorOutput` (ver "Hallazgo grande"). Si SÍ →
"Preparar fallo". Si NO → "¿Necesita aclaración?" (el flujo de siempre).

### 8. Preparar fallo — nuevo, 18/ago (Code)
```javascript
const taskId = $('Reclamar tarea pendiente').first().json.id;
const errMsg = $json.error ? $json.error.message : JSON.stringify($json);
return [{ json: { taskId, errMsg } }];
```
**Por qué existe este nodo intermedio:** en las pruebas del 18/ago,
`$('Reclamar tarea pendiente').first().json.id` **falló** cuando se
referenciaba directo dentro del campo `queryReplacement` de "Marcar como
fallida" — tiraba `Query Parameters must be a string of comma-separated
values or an array of values`, un error genérico de n8n que no dice la
causa real. Se aisló el problema probando variantes una por una: la misma
referencia cruzada a `$('Reclamar tarea pendiente')`, puesta dentro de un
nodo **Code**, sí funciona sin problema. La diferencia está en cómo el
parser interno de `queryReplacement` de los nodos Postgres (el que separa
"resolvables" del string `={{ }}`) resuelve referencias cruzadas cuando el
item llegó por una rama que pasó por una salida de error — no se identificó
la causa exacta dentro del código de n8n, pero el patrón de solución quedó
claro y confirmado con 3 ejecuciones reales: **resolver las referencias
cruzadas en un nodo Code antes, dejar solo acceso local (`$json.algo`) en
el `queryReplacement` del nodo Postgres siguiente.**

### 9. ¿Necesita aclaración? — IF
`{{ $json.choices[0].message.content.startsWith('NECESITA_ACLARACION:') }}`

**Nota de calidad de prompt, no de n8n:** en una prueba real del 18/ago (tarea
7, del piloto viejo), el modelo devolvió la aclaración envuelta en prosa
("Basándome en la aclaración recibida, mi respuesta es: **NECESITA_ACLARACION:**
...") en vez de poner el prefijo exacto al inicio del string. Este IF hace
`startsWith`, así que evaluó falso y la tarea se guardó como `done` cuando en
realidad el modelo quería pedir aclaración. No es un bug de n8n — es
disciplina de prompt del bot ejecutor; no se tocó hoy, queda anotado por si
se repite.

### 10a. Rama SÍ — Obtener bot que asignó
```sql
SELECT p.bot AS bot_padre, p.cluster AS cluster_padre
FROM tasks t
LEFT JOIN tasks p ON p.id = t.parent_task_id
WHERE t.id = $1;
```

### 10b. ¿Tiene padre? — IF
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

### 11. Rama NO — Guardar resultado
```sql
UPDATE tasks SET status = $1, output = $2, updated_at = now() WHERE id = $3;
```
con `$1 = 'needs_approval' si el bot lo requiere, si no 'done'`, `$2 = la
respuesta del modelo`, `$3 = id de la tarea`.

Desde aquí salen **dos** ramas en paralelo: `¿Este bot despacha tareas?` y
`Extraer patron`.

### 12. ¿Este bot despacha tareas? — IF
`{{ dispatches_tasks del bot }}`.

- **SÍ (dispatcher)** → **¿Requiere aprobación?** → si sí, Telegram → Bloquear
  tarea original. Si no, → **Parsear asignaciones**.
- **NO (ejecutor simple, ej. Coder)** → **¿Requiere aprobación?1** → si sí,
  Telegram → Bloquear tarea original. Si no, el workflow simplemente termina —
  el resultado ya quedó guardado en el paso 11.

### 13. Parsear asignaciones (Code)
```javascript
const salida = JSON.parse($('Llamar a omniroute').first().json.choices[0].message.content);
const parentId = $('Reclamar tarea pendiente').first().json.id;
const clusterPropio = $('Obtener config del bot').first().json.cluster;
const nivelPropio = $('Reclamar tarea pendiente').first().json.nivel_importancia;
return salida.asignaciones.map(a => ({
  json: {
    cluster: a.cluster || clusterPropio,
    bot: a.bot,
    status: "pending",
    input: { text: a.input, modo: a.modo },
    parent_task_id: parentId,
    nivel_importancia: a.nivel_importancia || nivelPropio
  }
}));
```
**Corregido 18/ago — propagación de `nivel_importancia` a tareas hijas.**
Antes las tareas hijas se creaban sin `nivel_importancia`, así que quedaban
`null` y fallaban en "Llamar a omniroute" con `400 Missing model` (el mismo
bug que dejó trabadas las tareas 4 y 7, ver "Hallazgo grande"). La regla,
según `efadam.md`: solo Efadam decide el nivel de una tarea nueva por tabla
de reglas de dominio/tema — ningún otro bot dispatcher (Técnico jefe,
Trouble shooter) debería decidirlo por su cuenta. Por eso la lógica es:
si el propio dispatcher lo trae en su JSON de salida (`a.nivel_importancia`
— hoy solo lo haría Efadam, cuando exista), se usa ese; si no lo trae
(el caso de todos los bots dispatcher de hoy, cuyo formato de salida no
incluye ese campo), la tarea hija **hereda el nivel de la tarea que la está
despachando** (`nivelPropio`) — nunca queda sin nivel.

### 14. Crear tareas hijas
```sql
INSERT INTO tasks (cluster, bot, status, input, parent_task_id, nivel_importancia)
VALUES ($1, $2, $3, $4, $5, $6);
```
`queryReplacement`: `[$json.cluster, $json.bot, $json.status,
JSON.stringify($json.input), $json.parent_task_id, $json.nivel_importancia]`.
Corre una vez por cada asignación (n8n itera automáticamente sobre los items).

### 15. Extraer patron (Code)
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

### 16. Guardar patron
```sql
insert into knowledge_log (tipo, titulo, resumen_corto, detalle_completo, cluster, origen_bot, task_id)
values ('patron_fallo', $1, $2, $3, $4, $5, $6)
on conflict (lower(titulo)) where tipo = 'patron_fallo'
do update set veces_visto = knowledge_log.veces_visto + 1, updated_at = now();
```
El `on conflict` incrementa `veces_visto` en vez de duplicar — ese contador es
lo que Trouble shooter recibe la próxima vez, vía `Cargar contexto`.

### 17. Send a text message (Telegram)
Chat fijo (`chatId: "-5436560130"`, el grupo de Mateo). Manda literal el
contenido de la respuesta del modelo — mismo nodo compartido para "necesita
aclaración sin padre" y para "necesita aprobación humana".

### 18. Marcar como fallida
```sql
UPDATE tasks SET status = 'failed', output = $1, updated_at = now() WHERE id = $2
RETURNING *;
```
`queryReplacement: [$json.errMsg, $json.taskId]` — acceso local únicamente
(ver nodo "Preparar fallo" para por qué). Se agregó `RETURNING *` para que
el nodo siguiente (`¿Bot que falló no es trouble_shooter?`) tenga `cluster`,
`bot` y `output` de la tarea que falló sin tener que volver a consultarlos.

### 19. ¿Bot que falló no es trouble_shooter? — nuevo, 18/ago (IF)
Dos condiciones con AND: `{{ $json.bot }}` no vacío, y `{{ $json.bot }}` !=
`'trouble_shooter'`. **Por qué existe esta guarda:** sin ella, si alguna vez
falla una tarea que le pertenece al propio Trouble shooter, se despacharía
otra tarea de Trouble shooter para diagnosticar ese fallo — y si ese
diagnóstico también fallara, otra, y otra — un loop infinito de
auto-diagnóstico. Con la guarda, un fallo de Trouble shooter simplemente
queda marcado `failed` sin auto-despacho (alguien tiene que mirarlo a mano,
que es razonable: es el propio diagnosticador el que falló).

### 20. Despachar a trouble_shooter — nuevo, 18/ago
```sql
INSERT INTO tasks (cluster, bot, status, input)
VALUES ($1, 'trouble_shooter', 'pending', jsonb_build_object('text', $2));
```
`queryReplacement: [$json.cluster, $json.output]` — ambos vienen del
`RETURNING *` de "Marcar como fallida" (nodo local, sin referencia cruzada).
Con esto, `trouble-shooter.md` deja de documentar un diseño pretendido: el
disparo automático **ya existe de verdad**, probado en vivo el 18/ago con un
fallo real (tarea 12, `400 Missing model`) — confirmado que la tarea de
Trouble shooter se creó con el cluster y el error correctos.

## Hallazgos de rondas anteriores — ya corregidos

1. ~~`cluster` hardcodeado en "Parsear asignaciones"~~ → corregido 15/ago.
2. ~~`Reclamar tarea pendiente` y `Obtener contexto de tarea padre` sin `onError`~~
   → tienen `continueErrorOutput` configurado desde el 15/ago (ver "Hallazgo
   grande" del 18/ago sobre por qué esa configuración no basta por sí sola).
3. ~~Sin inyección de memoria (`system_knowledge`/`knowledge_log`)~~ →
   corregido 15/ago, nodo "Cargar contexto".
4. ~~Sin escritura automática de patrones~~ → corregido 15/ago, nodos
   "Extraer patron" / "Guardar patron".
5. ~~`trouble_shooter` nunca se insertó en `bots`~~ → esto fue un error de
   diagnóstico del 17/ago, corregido el 18/ago (sí estaba insertado).
6. ~~Auto-dispatch a `trouble_shooter` tras un fallo no existía~~ →
   corregido 18/ago, nodos 19-20 de arriba.
7. ~~Inyección SQL en "Obtener config del bot" (hallazgo C2)~~ → corregido
   18/ago, nodo 3 de arriba.
8. ~~`nivel_importancia` no se propagaba a tareas hijas~~ → corregido 18/ago,
   nodo 13 de arriba.

## Lo que falta (pendientes reales)

1. **Hallazgo C5 (nuevo, 18/ago) — el bug de `continueErrorOutput` sigue sin
   corregirse en 13 nodos.** Ver la sección "Hallazgo grande" arriba para la
   lista completa y el patrón de arreglo (nodo Code intermedio + acceso
   local). Es el pendiente más importante que deja esta ronda.
2. **`Obtener config del bot` no distingue "bot no existe" de "bot existe"
   (nuevo, 18/ago).** 0 filas no es un error en Postgres, así que una tarea
   con un `bot` que no existe o no está activo se queda trabada en `running`
   para siempre, sin pasar por "Marcar como fallida". Necesita un IF
   explícito después de esta query.
3. **`Reanudador de bloqueados`** (workflow separado, `3fKEODc6f6jH9VCJ`): el
   query central ya está completo y correcto — solo le falta cambiar el
   trigger de **Manual a Schedule** para que corra solo.
4. El workflow completo sigue en `active: false` en n8n — correrlo hoy
   requiere disparar el Manual Trigger a mano (o, como se hizo hoy para
   probar, un Webhook Trigger temporal). Pasarlo a Schedule Trigger es parte
   de sacarlo de modo prueba.
5. Prueba end-to-end en vivo del loop completo (memoria + aclaración +
   reanudador) — construido y verificado en estructura, falta correrlo con
   una tarea real de principio a fin y confirmar el resultado.

## Cómo probarlo hoy

**Con el Manual Trigger (como siempre):**
1. Insertar una tarea de prueba:
   ```sql
   INSERT INTO tasks (cluster, bot, status, input, nivel_importancia) VALUES
   ('tech-center', 'tecnico_jefe', 'pending', '{"text": "..."}', 'medio');
   ```
   (no olvidar `nivel_importancia` — sin él, "Llamar a omniroute" falla con
   `400 Missing model`, ver "Hallazgo grande").
2. Correr el Manual Trigger del "Ejecutor genérico" desde la UI de n8n.
   Revisar que la tarea de Técnico jefe quede `done` y que haya tareas hijas
   nuevas para `coder`/`trouble_shooter`.
3. Correr el trigger otra vez para que reclame la tarea hija.

**Sin acceso a la UI de n8n (técnica usada el 18/ago para probar por API):**
agregar temporalmente un nodo Webhook conectado al mismo punto que el Manual
Trigger, activar el workflow (`POST /workflows/{id}/activate`), disparar con
`curl http://localhost:5678/webhook/<path>`, y al terminar quitar el nodo
Webhook y volver a desactivar el workflow. Sirve para probar por API sin
necesitar acceso interactivo a n8n — así se probó todo lo de esta ronda.

4. Para probar aclaración: mandar una tarea cuyo prompt fuerce
   `NECESITA_ACLARACION:` y confirmar que, si tiene padre, se crea la tarea de
   vuelta y la original queda `blocked`; si no tiene padre, llega el mensaje a
   Telegram.
5. Para probar memoria: confirmar en `output` de una tarea de `tecnico_jefe`
   que la respuesta refleja contenido de `system_knowledge` (ej. que mencione
   la arquitectura real de 3 ramas).
6. Para probar el auto-dispatch a Trouble shooter: insertar una tarea con
   `nivel_importancia = null` para forzar el `400 Missing model` de
   OmniRoute, correr el trigger, y confirmar que la tarea original queda
   `failed` y aparece una tarea nueva `pending` para `trouble_shooter` con el
   mismo cluster y el mismo mensaje de error en `input.text`.
