# Ejecutor genérico — estado real

> **Actualizado 18/ago/2026, noche (cuarta ronda).** 26 nodos, más la tabla
> nueva `operations` y la columna `tasks.operation_id`, ya construidas y
> probadas en vivo (no solo un pendiente en el papel — ver "Operaciones:
> hilo de trabajo completo" más abajo). Se construyó el auto-dispatch a
> Trouble shooter, se corrigió una inyección SQL real, se propagó
> `nivel_importancia` a las tareas hijas, y se cerró de fondo el manejo de
> errores de **todo** el workflow (no solo un nodo) — pero el diagnóstico
> cambió de forma importante entre la tarde y la noche del mismo día. La
> ronda de la tarde concluyó que 13 nodos más tenían el mismo bug que
> "Llamar a omniroute" y lo dejó pendiente sin tocar. Al ponerse a arreglarlos
> de verdad (segunda ronda de la noche), **se probó en vivo, nodo por tipo, y
> esa conclusión resultó ser incorrecta**: Postgres, Code y Telegram sí
> rutean los errores a su salida correcta — el problema real era otro, más
> angosto, y ya está corregido en los 17 puntos donde aplicaba. Ver
> "Hallazgo grande, corregido" más abajo para esa historia. Más tarde esa
> misma noche (cuarta ronda) se agregó el concepto de "operación" — ver
> sección dedicada más abajo, incluye un bug real encontrado y corregido de
> paso (`trouble_shooter` se auto-despachaba siempre con
> `nivel_importancia = null`, garantizando su propio fallo).

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

## Hallazgo grande del 18/ago — corregido en dos rondas, la segunda desmiente parte de la primera

### Ronda de la tarde: qué se creyó, y por qué solo una parte era cierta

Probando en vivo (forzando un fallo real de "Llamar a omniroute": una tarea
con `nivel_importancia = null`, que hace que OmniRoute responda `400 Missing
model`), se confirmó que el item de error se quedaba en la salida
normal/éxito (salida 0) de ese nodo en vez de ir a su segunda salida (la
"salida de error", conectada a "Marcar como fallida"). Correcto — eso sí
pasaba, y pasa. El error: de ahí se **generalizó**, sin probarlo, a que los
otros 13 nodos del workflow con `onError: continueErrorOutput` (todos
Postgres o Code, más "Send a text message" de Telegram) tenían el mismo
problema, y se dejó ese arreglo pendiente como "hallazgo C5" sin tocarlo.

### Ronda de la noche: se probó en vivo, tipo por tipo, y la generalización estaba mal

Antes de tocar 13 nodos con el mismo parche, se probó cada tipo de nodo por
separado — forzando un fallo real (query rota, código que hace `throw`,
`chatId` inválido) y mirando en cuál salida cae el item, vía
`GET /executions/{id}?includeData=true`. Resultado, con evidencia directa:

- **Postgres** (nodo "Obtener config del bot", query rota a propósito): el
  error cayó limpio en la salida 1 (la de error). Salida 0 vacía.
- **Code** (nodo "Parsear asignaciones", `throw new Error(...)` forzado): lo
  mismo — error en salida 1, salida 0 vacía.
- **Telegram** (nodo "Send a text message", con un error de evaluación de
  expresión forzado): lo mismo otra vez.

Los tres tipos de nodo que forman los 13 de la lista de la tarde **rutean el
error correctamente, de fábrica, sin necesitar ningún arreglo**. El
diagnóstico de la tarde estaba mal — no por mala fe, sino por generalizar un
comportamiento confirmado en un nodo (HTTP Request) a tipos de nodo que
nunca se probaron.

**¿Por qué "Llamar a omniroute" (HTTP Request) sí falla y los demás no?**
Revisando el código fuente de n8n dentro del contenedor
(`n8n-core/dist/execution-engine/workflow-execute.js`,
`handleNodeErrorOutput`), la función que reubica items de error a la salida
correcta se dispara siempre que `onError === 'continueErrorOutput'` — no es
que esté rota. La explicación más probable (no confirmada al 100%, pero
consistente con toda la evidencia): el nodo HTTP Request, por configuración
por defecto, **no lanza una excepción real** cuando OmniRoute responde
`400` — trata esa respuesta como una llamada HTTP "exitosa" y pasa el cuerpo
del error como si fuera contenido normal. Como nunca hay una excepción real,
`continueErrorOutput` nunca llega a activarse para ese nodo — el arreglo
correcto ahí nunca fue "confiar en la segunda salida", es exactamente el que
ya se había construido: un IF explícito (`¿Falló la llamada a omniroute?`)
que revisa el contenido de la respuesta.

### El bug real (distinto del que se creía) — resolución de `$('Nombre del nodo')` con `.first()`

Con las 3 salidas de error ya confirmadas correctas, faltaba conectar cada
una a "Marcar como fallida" — pero **ya estaban conectadas** (esa parte del
workflow se había construido bien desde antes; el diagrama siempre apuntó
la salida de error de cada nodo hacia "Marcar como fallida", solo que nunca
recibía nada porque la salida de error nunca se activaba de verdad para
"Llamar a omniroute", el único nodo que realmente fallaba en producción).
El problema real, encontrado recién al probar el flujo completo de punta a
punta con una tarea real: **"Marcar como fallida" necesita `$json.errMsg` y
`$json.taskId`, pero el item que le llega directo desde cada nodo tiene una
forma completamente distinta según el tipo** — un objeto anidado para
Postgres, un string simple para Code, otra forma distinta para Telegram.
Conectar esas 17 salidas de error directo a "Marcar como fallida" sin
transformar el dato hace que la actualización corra con parámetros vacíos
(`NULL, NULL`) — no falla, pero tampoco actualiza ninguna fila real.

La solución (la misma que ya existía para "Llamar a omniroute", generalizada
para servir a las 17 rutas): todas pasan ahora por el nodo Code "Preparar
fallo", que normaliza cualquier forma de error a `{ taskId, errMsg }` antes
de llegar a "Marcar como fallida". Al conectar las 17 rutas nuevas se
encontró un segundo problema, más sutil: `$('Reclamar tarea pendiente')
.first().json.id` — que llevaba semanas funcionando para la ruta de
omniroute — **falla** (`Cannot read properties of undefined (reading
'json')`) cuando el nodo Code se alcanza a través de una de estas otras
rutas rescatadas por `continueErrorOutput`. Se probaron 4 formas distintas
de leer el mismo dato en el mismo Code node, en la misma ejecución real:
`.first()` y `.all()[0]` fallaron las dos; `.item` y `.itemMatching(0)`
funcionaron las dos, devolviendo el `id` correcto. **Se cambió "Preparar
fallo" para usar `.item` en vez de `.first()`** — no se investigó por qué
`.first()` específicamente rompe en esta situación (otra madriguera de
internals de n8n que no vale la pena perseguir hoy), pero el arreglo está
confirmado con evidencia directa, no es una corazonada.

### Arreglo final aplicado, probado en vivo de punta a punta

Las 17 salidas de error que antes iban directo a "Marcar como fallida" (los
13 nodos de la lista de la tarde, más las 4 salidas de error de los IF con
`continueErrorOutput` — ver nota de los IF más abajo) ahora pasan todas por
"Preparar fallo", que:

```javascript
const taskId = $('Reclamar tarea pendiente').item.json.id;

let errMsg;
if (typeof $json.error === 'string') {
  errMsg = $json.error;
} else if ($json.error && typeof $json.error === 'object') {
  errMsg = $json.error.message || $json.error.description || JSON.stringify($json.error);
} else if ($json.message) {
  errMsg = $json.message;
} else {
  errMsg = JSON.stringify($json);
}

return [{ json: { taskId, errMsg } }];
```

La rama `errMsg` cubre las 4 formas de error observadas en vivo: objeto con
`.message` (HTTP Request), objeto con `.description` sin `.message`
(Postgres), string directo (Code), y string dentro de un objeto con más
campos (Telegram/genérico) — con un `JSON.stringify` de respaldo si aparece
una quinta forma no vista todavía.

**Probado en vivo de punta a punta, dos rutas distintas, con datos reales:**

1. **Ruta Postgres** (query rota a propósito en "Obtener config del bot",
   tarea real insertada, disparada desde el trigger real —
   "Reclamar tarea pendiente"): la tarea terminó `status = 'failed'` con el
   mensaje de error real de Postgres en `output`, y se disparó
   automáticamente una tarea nueva para `trouble_shooter` con el mismo
   `cluster`.
2. **Ruta HTTP Request** (tarea real con `nivel_importancia = null`, mismo
   disparo desde el trigger real): mismo resultado — `failed` con el error
   real de OmniRoute, tarea nueva para `trouble_shooter` despachada.
3. **Bonus, no buscado a propósito:** la tarea de `trouble_shooter`
   despachada en la prueba 1 también falló (heredó `nivel_importancia =
   null` de su tarea padre) — y la guarda `¿Bot que falló no es
   trouble_shooter?` funcionó exactamente como se diseñó: no se auto-
   despachó una tercera tarea. Confirma en vivo que el freno contra el loop
   infinito de auto-diagnóstico funciona de verdad, no solo en el papel.

Los 4 nodos IF con `onError: continueErrorOutput` (`¿Este bot despacha
tareas?`, `¿Requiere aprobación?`, `¿Requiere aprobación?1`, `¿Tiene
padre?`) se conectaron también a través de "Preparar fallo" por
consistencia y porque no cuesta nada extra, pero **su comportamiento real
ante un error de verdad no se confirmó en vivo** — dos intentos de forzar
un error genuino en la evaluación de un IF (referenciar un nodo inexistente,
forzar un choque de tipos con validación estricta) terminaron los dos
evaluando la condición como falsa en vez de lanzar un error real, así que
no hay evidencia directa todavía de en qué salida cae un error real de un
IF. Queda anotado como algo sin confirmar, no como corregido con certeza —
si algún día un IF de estos falla de verdad en producción, vale la pena
revisar la ejecución real para confirmar que efectivamente llegó a
"Preparar fallo" y no se perdió en otro lado.

**Corrección de nombres para no perder el hilo en futuros documentos —
actualizada 19/ago tras corrección de Mateo:** lo que la tarde llamó
"hallazgo C5" (13 nodos con el mismo bug que omniroute) **no era correcto
como se planteó** — el bug real era más angosto (la transformación de dato
+ `.first()` vs `.item()`) y ya está cerrado. Además: "C5" **nunca fue un
hallazgo de la auditoría del 17 de agosto** — esa auditoría solo enumera
C1-C4 (confirmado 19/ago, `grep "C[1-9]"` sobre
`auditoria_tecnica_y_vision_17ago2026.md` completo). El nombre "hallazgo
C5" se dejó de usar — este arreglo se nombra sin el prefijo "C" (ej. "bug
de normalización de errores, 18/ago") para no seguir insinuando que viene
de esa auditoría.

**Aviso 19/ago — este arreglo, y todos los demás de esta semana hechos vía
API de n8n, no están reflejados en `n8n-workflows/ejecutor_generico.json`.**
El único commit que toca esa carpeta es del 16 de agosto, anterior a todo
esto. Ver actualización del 19 de agosto en `plan_de_accion_completo.md`
para el detalle completo — reexportar es ahora el pendiente más urgente,
antes de activar Efadam.

## Operaciones: hilo de trabajo completo — nuevo, 18/ago, cuarta ronda

Mateo pidió un concepto nuevo, "operación": "cada cosa que el programa
completo debe hacer" (investigaciones, autoexpansión, tareas de usuario),
para que Efadam tenga mejor registro y para que el orden/instrucciones de un
hilo de trabajo no se mezclen entre sí. Diseño confirmado por Mateo en dos
puntos clave (ver `plan_de_accion_completo.md`, actualización del 18 de
agosto, noche, tercera y cuarta ronda, para la discusión completa):

1. **Centralizado en Efadam** — a diferencia de `tasks` (que cualquier
   cluster puede seguir despachando directo a otro sin pasar por Efadam,
   sin cambios), **solo Efadam abre una operación nueva**. Si un cluster
   detecta que necesita arrancar un hilo de trabajo nuevo (no solo una
   tarea más dentro del que ya tiene), tiene que volver a preguntarle a
   Efadam — el mismo principio de cuello de botella que ya existe para
   `knowledge_log`/`system_knowledge`, extendido a operaciones. Efadam
   todavía no existe como bot activo, así que hoy nada abre operaciones de
   verdad — la tabla y la propagación están listas para cuando exista
   (Bloque 3).
2. **`nivel_importancia` no se movió de tabla, no se tocó su código** —
   Mateo pidió explícitamente no "borrar uno y crear otro de cero".
   `operations.nivel_importancia` es la fuente de verdad conceptual
   (Efadam la fija una sola vez, al abrir la operación); la tarea raíz
   copia ese mismo valor a `tasks.nivel_importancia` — y desde ahí la
   cadena de herencia que ya existía en "Parsear asignaciones" (construida
   y probada la ronda anterior) sigue funcionando exactamente igual, sin
   ningún cambio de código. Es un cambio de dónde nace el valor, no de
   cómo viaja.

### Schema (`schema/007_operaciones.sql`, ya corrido contra Postgres real)

```sql
create table operations (
    id                 serial primary key,
    tipo               text        not null,  -- 'usuario' | 'investigacion' | 'autoexpansion' | ...
    titulo             text        not null,
    descripcion        text,
    nivel_importancia  text        not null check (nivel_importancia in ('bajo','medio','alto','critico')),
    status             text        not null default 'abierta',  -- abierta | en_progreso | completada | fallida | bloqueada
    created_at         timestamptz not null default now(),
    updated_at         timestamptz not null default now(),
    closed_at          timestamptz
);

alter table tasks add column operation_id int references operations(id);
```

`tasks.operation_id` es nullable por ahora (transición: tareas manuales/de
prueba, o cualquier tarea creada antes de que Efadam exista, pueden no
tener una).

### Cómo se propaga (decisión de diseño: subquery SQL, no referencia cruzada de n8n)

A diferencia de `nivel_importancia` (que viaja vía `$('Reclamar tarea
pendiente').first()` dentro de un Code node — el mecanismo que causó el bug
de `.first()` vs `.item()` de la ronda anterior), `operation_id` se propaga
con un **subquery SQL dentro del mismo INSERT**, usando un parámetro que la
query ya recibía de todos modos (`parent_task_id`). Cero referencias
cruzadas nuevas de n8n, cero superficie nueva para ese tipo de bug:

- **Crear tareas hijas** (nodo 14): `(SELECT operation_id FROM tasks WHERE id = $5)`.
- **Crear tarea de aclaración** (nodo 10b): igual, sobre `$4`. De paso se
  encontró y corrigió un gap real que no tenía que ver con operaciones:
  este INSERT nunca había puesto `nivel_importancia` a la tarea de
  aclaración — si esa tarea llegaba a procesarse, iba a fallar en "Llamar
  a omniroute" con `400 Missing model`, el mismo bug ya visto dos veces
  antes. Ahora también se copia por subquery: `(SELECT nivel_importancia
  FROM tasks WHERE id = $4)`.
- **Despachar a trouble_shooter** (nodo 20): no necesita subquery — ambos
  valores ya vienen locales en el `RETURNING *` de "Marcar como fallida"
  (`$json.nivel_importancia`, `$json.operation_id`). **Bug real encontrado
  y corregido aquí:** este INSERT tampoco ponía nunca `nivel_importancia` —
  la "confirmación bonus" de la ronda anterior (la tarea de
  `trouble_shooter` auto-despachada también falló) no era solo una
  coincidencia útil para probar el guard anti-loop, era la evidencia de
  que **todas** las tareas de `trouble_shooter` auto-despachadas estaban
  condenadas a fallar por esto — el mecanismo creaba la tarea correcta,
  pero esa tarea nunca podía completarse. Corregido.

### Probado en vivo, dos veces, con datos reales (misma técnica de webhook temporal)

1. Se creó una operación de prueba (`tipo: usuario`, `nivel_importancia:
   medio`) y una tarea raíz para `tecnico_jefe` con ese `operation_id`. Se
   disparó dos veces: la tarea hija que "Crear tareas hijas" generó para
   `coder` salió con `operation_id` y `nivel_importancia` correctos — la
   propagación por subquery funciona.
2. Se forzó un fallo real en "Obtener config del bot" (mismo query roto que
   la ronda anterior) sobre una tarea con `nivel_importancia = medio` y
   `operation_id` puesto. La tarea de `trouble_shooter` auto-despachada
   salió con **`nivel_importancia = medio`** (antes habría salido `null`,
   condenada a fallar) y `operation_id` correcto — confirma en vivo los
   dos arreglos de la sección anterior, no solo en el papel.

Datos de prueba borrados después, workflow devuelto a 26 nodos/`active:
false` — mismo protocolo de limpieza de siempre.

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

Cualquier otro nodo con onError configurado → su salida de error va a
"Preparar fallo" (no directo a "Marcar como fallida" — ver "Hallazgo
grande" arriba para por qué). Los 17 puntos que hoy alimentan "Preparar
fallo": Reclamar tarea pendiente, Obtener config del bot, Guardar
resultado, ¿Este bot despacha tareas?, Parsear asignaciones, Crear tareas
hijas, ¿Requiere aprobación?, Send a text message, ¿Requiere aprobación?1,
Obtener bot que asignó, ¿Tiene padre?, Crear tarea de aclaración, Bloquear
tarea original, Obtener contexto de tarea padre, Cargar contexto, Extraer
patron, Guardar patron, y ¿Falló la llamada a omniroute? (el original).
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
`onError: continueErrorOutput` configurado y confirmado en vivo que rutea
bien a "Preparar fallo" si esta query falla — con una salvedad: si falla
aquí mismo, todavía no hay ningún `task_id` que reclamar (la tarea nunca
llegó a marcarse `running`), así que "Marcar como fallida" corre con
`taskId` vacío y no actualiza ninguna fila real — un fallo de conexión a
Postgres en este punto específico no queda registrado en `tasks` ni genera
una tarea de Trouble shooter, porque no hay una tarea de la cual partir.
Gap real, sin resolver: no existe hoy ningún canal de alerta para este caso
particular (el más grave de todos — significa que Postgres mismo no
responde). Ver "Lo que falta" al final.

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

### 8. Preparar fallo — nuevo, 18/ago, generalizado esa misma noche (Code)
```javascript
const taskId = $('Reclamar tarea pendiente').item.json.id;

let errMsg;
if (typeof $json.error === 'string') {
  errMsg = $json.error;
} else if ($json.error && typeof $json.error === 'object') {
  errMsg = $json.error.message || $json.error.description || JSON.stringify($json.error);
} else if ($json.message) {
  errMsg = $json.message;
} else {
  errMsg = JSON.stringify($json);
}

return [{ json: { taskId, errMsg } }];
```
**Por qué existe este nodo intermedio y por qué es compartido por 18
rutas distintas:** ver "Hallazgo grande" arriba para la historia completa.
En corto: cada tipo de nodo (Postgres, Code, HTTP Request, Telegram) da su
error en una forma distinta, y "Marcar como fallida" necesita siempre la
misma forma (`{taskId, errMsg}`) — este nodo normaliza. Además,
`$('Reclamar tarea pendiente').first()` (la versión original, de la tarde)
falla con `Cannot read properties of undefined (reading 'json')` cuando
este Code node se alcanza a través de una salida de error rescatada por
`continueErrorOutput` — confirmado en vivo probando 4 formas de acceso en
la misma ejecución real; `.item` y `.itemMatching(0)` sí funcionan,
`.first()` y `.all()[0]` no. Se usa `.item`.

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
  INSERT INTO tasks (cluster, bot, status, input, parent_task_id, nivel_importancia, operation_id)
  VALUES ($1, $2, 'pending', $3, $4,
    (SELECT nivel_importancia FROM tasks WHERE id = $4),
    (SELECT operation_id FROM tasks WHERE id = $4));
  ```
  con `$3 = { text: <pregunta, sin el prefijo "NECESITA_ACLARACION: "> }` y
  `$4 = id de la tarea original` — reanudación bot-a-bot, sin humano en medio.
  **Actualizado 18/ago, cuarta ronda:** se agregaron `nivel_importancia` y
  `operation_id`, ambos copiados por subquery de la tarea original (`$4`).
  `nivel_importancia` era un gap real sin corregir hasta ahora — esta tarea
  nunca lo había tenido, y si llegaba a procesarse habría fallado en
  "Llamar a omniroute" con `400 Missing model`. Ver "Operaciones" arriba.
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
INSERT INTO tasks (cluster, bot, status, input, parent_task_id, nivel_importancia, operation_id)
VALUES ($1, $2, $3, $4, $5, $6, (SELECT operation_id FROM tasks WHERE id = $5));
```
`queryReplacement`: `[$json.cluster, $json.bot, $json.status,
JSON.stringify($json.input), $json.parent_task_id, $json.nivel_importancia]`
(sin cambios — `operation_id` no necesita parámetro nuevo, sale del
subquery sobre `$5`). Corre una vez por cada asignación (n8n itera
automáticamente sobre los items). **Actualizado 18/ago, cuarta ronda:**
`operation_id` agregado, probado en vivo — ver "Operaciones" arriba.

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
Ahora recibe items desde **18 rutas distintas** (todas vía "Preparar
fallo", nunca directo) — probado en vivo con 2 de esas rutas de punta a
punta (ver "Hallazgo grande").

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
INSERT INTO tasks (cluster, bot, status, input, nivel_importancia, operation_id)
VALUES ($1, 'trouble_shooter', 'pending', jsonb_build_object('text', $2), $3, $4);
```
`queryReplacement: [$json.cluster, $json.output, $json.nivel_importancia,
$json.operation_id]` — los 4 vienen del `RETURNING *` de "Marcar como
fallida" (nodo local, sin referencia cruzada). Con esto, `trouble-shooter.md`
deja de documentar un diseño pretendido: el disparo automático **ya existe
de verdad**, probado en vivo el 18/ago con un fallo real (tarea 12, `400
Missing model`) — confirmado que la tarea de Trouble shooter se creó con el
cluster y el error correctos.

**Bug real encontrado y corregido, 18/ago, cuarta ronda:** este INSERT
nunca había puesto `nivel_importancia` — cada tarea de `trouble_shooter`
auto-despachada nacía con `nivel_importancia = null` y estaba condenada a
fallar en "Llamar a omniroute" (`400 Missing model`), sin excepción. Lo que
la ronda anterior documentó como "bonus, no buscado a propósito: la tarea
de trouble_shooter despachada también falló" no era una coincidencia — era
este bug, atrapado en el momento pero sin identificar la causa. Corregido
junto con `operation_id`; probado en vivo (ver "Operaciones" arriba): la
tarea de `trouble_shooter` auto-despachada ahora sale con el
`nivel_importancia` real de la tarea que falló, no `null`.

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
9. ~~Hallazgo C5, tal como se planteó en la ronda de la tarde del 18/ago (13
   nodos con el mismo bug que "Llamar a omniroute")~~ → **desmentido y
   cerrado la misma noche del 18/ago.** El diagnóstico original estaba mal;
   el bug real (normalización de forma de error + `.first()` vs `.item()`)
   ya está corregido en las 18 rutas. Ver "Hallazgo grande" arriba para la
   historia completa, incluida la corrección sobre la corrección.
10. ~~Tareas de `trouble_shooter` auto-despachadas y tareas de aclaración
    nacían sin `nivel_importancia`~~ → corregido 18/ago, cuarta ronda, al
    construir la propagación de `operation_id` — ver "Operaciones: hilo de
    trabajo completo" y los nodos 10b y 20 arriba.

## Lo que falta (pendientes reales)

1. **Fallo en "Reclamar tarea pendiente" mismo — sin canal de alerta
   (nuevo, 18/ago, noche).** Si Postgres no responde justo en el primer
   paso (antes de que exista ningún `task_id`), "Marcar como fallida" corre
   sin nada que actualizar — el fallo no queda registrado en `tasks` ni
   genera una tarea de Trouble shooter. Es el caso más grave (Postgres
   caído) y hoy el menos cubierto. Necesitaría un canal de alerta aparte
   (ej. Telegram directo a Mateo) para este caso específico, no una fila en
   `tasks`.
2. **Comportamiento de error real de los 4 nodos IF con
   `continueErrorOutput` — sin confirmar en vivo (nuevo, 18/ago, noche).**
   Se conectaron a "Preparar fallo" por consistencia, pero dos intentos de
   forzar un error genuino en un IF no lo lograron (la condición evaluó
   falso en vez de lanzar error). No es urgente — los IF de este workflow
   rara vez deberían fallar — pero si alguno falla de verdad algún día, vale
   la pena confirmar en la ejecución real que llegó a donde debía.
3. **`Obtener config del bot` no distingue "bot no existe" de "bot existe"
   (18/ago).** 0 filas no es un error en Postgres, así que una tarea con un
   `bot` que no existe o no está activo se queda trabada en `running` para
   siempre, sin pasar por "Marcar como fallida". Necesita un IF explícito
   después de esta query.
4. ~~`Reanudador de bloqueados` necesita cambiar el trigger de Manual a
   Schedule~~ — **esto estaba mal, corregido 19/ago:** el export
   (`n8n-workflows/reanudador_de_bloqueados.json`) muestra `"active": true`
   con un nodo `n8n-nodes-base.scheduleTrigger` ("Cada 5 minutos",
   `minutesInterval: 5`), `updatedAt: 2026-08-15` — ya estaba resuelto
   desde antes del 16 de agosto y este punto se venía repitiendo sin
   volver a verificarse. Este es el caso inverso al resto de este
   documento: aquí el export sí está al día, era la lista la que estaba
   vieja.
5. El workflow completo sigue en `active: false` en n8n — correrlo hoy
   requiere disparar el Manual Trigger a mano (o, como se hizo hoy para
   probar, un Webhook Trigger temporal). Pasarlo a Schedule Trigger es parte
   de sacarlo de modo prueba.
6. Prueba end-to-end en vivo del loop completo (memoria + aclaración +
   reanudador) — construido y verificado en estructura, falta correrlo con
   una tarea real de principio a fin y confirmar el resultado.
7. **Nada abre una `operations` de verdad todavía (18/ago, cuarta ronda).**
   La tabla, la columna y la propagación están construidas y probadas, pero
   como el diseño quedó centralizado en Efadam (decisión de Mateo) y Efadam
   no existe como bot activo, hoy no hay ningún punto real del sistema que
   inserte una fila nueva en `operations` — solo se puede probar insertando
   una a mano, como se hizo para las pruebas de esta ronda. Se destraba
   junto con Bloque 3 (activar Efadam).
8. **El más urgente de todos, agregado 19/ago tras corrección de Mateo:
   reexportar este workflow a `n8n-workflows/ejecutor_generico.json`.**
   Todas las correcciones de C2, C3, el bug de manejo de errores y la
   construcción completa de operaciones se hicieron vía API directo contra
   la instancia de n8n — el export en el repo sigue siendo el del 16 de
   agosto, previo a todo esto. Confirmado con `grep`: el export actual
   todavía tiene la SQL vulnerable de C2 en "Obtener config del bot"
   (línea 87) y no tiene ni un solo `operation_id`. Sin esto, nada de lo
   que dice este documento es verificable desde el repo. Ver actualización
   del 19 de agosto en `plan_de_accion_completo.md`.

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
