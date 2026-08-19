# Stack y convenciones de Infinite Power (canónico)

> Seed inicial de `system_knowledge.slug = 'stack_y_convenciones'` — se usa
> una sola vez para poblar la tabla al arrancar el sistema (ver
> `memoria_del_sistema.md`, sección "Repo como seed, no como fuente de
> verdad"); no hay sync automático. Una vez seedeada, la tabla es la fuente
> de verdad viva. Solo hechos vigentes, en presente, sin historia.

## Stack

- **Orquestador:** n8n self-hosted (Docker), `localhost:5678`.
- **Base de datos:** Postgres 16 self-hosted (Docker). Es la memoria y la cola.
- **Router de modelos:** OmniRoute self-hosted, `localhost:20128`.
  Desde adentro de la red de Docker se llama `http://omniroute:20128`, nunca `localhost`.
  Ver "Niveles de importancia y BYOK" abajo para cómo se configura y quién lo usa.
- **Canal humano:** bot de Telegram (aprobaciones y alertas).
- **Repo:** `https://github.com/Madafe/Infinite_Power` (privado).
- **Ubicación local:** `C:\Users\2\Documents\infinite-power`.
- **Sin VPS ni dominio todavía.** Todo corre en la máquina de Mateo.

## Tablas

- `tasks` — cola compartida. `id, cluster, bot, status, input jsonb, output text,
  parent_task_id, nivel_importancia, operation_id, created_at, updated_at`.
  Estados: `pending, running, done, failed, blocked, needs_approval`.
  `output` es **text**, no jsonb. `nivel_importancia` (`bajo`/`medio`/`alto`/`critico`,
  sin tilde) — **resuelto el 19 de agosto de 2026 (pendiente 35 de
  `plan_de_accion_completo.md`):** el nivel de cada tarea es el más alto
  entre el nivel fijo de la `operation` a la que pertenece y el que le
  corresponda por su propio contenido según las "Reglas de asignación" de
  abajo (`max(nivel de la operación, nivel por reglas de asignación de esa
  tarea)`) — así una operación abierta en `bajo` (ej. investigación) no se
  convierte en la forma de que una tarea hija que sí implica gasto de
  dinero/legal/publicación termine corriendo sin aprobación. **Importante:**
  esto se calcula y se guarda solo en `tasks.nivel_importancia` de esa tarea
  específica — nunca se escribe de vuelta a `operations.nivel_importancia`.
  Una tarea hija crítica no vuelve crítica a toda la operación ni a las
  demás tareas hermanas; el nivel de la operación se queda fijo tal como se
  abrió (decisión explícita de Mateo: "no puedes transformar toda la
  operación en crítica basado en la decisión de 1 solo agente"). Ver
  "Niveles de importancia y BYOK" y `operations` abajo.
  `operation_id` (nullable) referencia a `operations` — se propaga de padre a
  hijo automáticamente al crear tareas nuevas. Las tareas de síntesis de
  aprendizaje se identifican en `input.tipo = "sintesis_aprendizaje"`; no
  ejecutan trabajo de negocio ni escriben conocimiento directamente.
- `operations` — el hilo de trabajo completo detrás de una tarea o grupo de
  tareas relacionadas (una petición de usuario, una investigación, una ronda
  de autoexpansión). `id, tipo, titulo, descripcion, nivel_importancia,
  status, created_at, updated_at, closed_at`. Estados: `abierta, en_progreso,
  completada, fallida, bloqueada`. **Solo Efadam inserta filas nuevas aquí**
  — a diferencia de `tasks`, que cualquier cluster puede seguir despachando
  directo a otro sin pasar por Efadam. Un cluster que necesita arrancar un
  hilo de trabajo nuevo le pregunta a Efadam primero.
  `nivel_importancia` se fija una sola vez al abrir la operación y **nunca
  se actualiza después** — ni siquiera si una tarea hija individual termina
  en un nivel más alto (ver corrección de `tasks.nivel_importancia` arriba).
  Al completar o alcanzar un hito de una tarea concreta, la operación puede
  generar una tarea asíncrona de síntesis de aprendizaje con el mismo
  `operation_id`; no bloquea la respuesta ni el avance de la tarea concreta.
- `bots` — configuración de cada bot: `slug, cluster, prompt_especifico,
  system_prompt (derivado), contexto_slugs, conocimiento_directo,
  requires_approval, dispatches_tasks, active`. `default_model` sigue en la
  tabla pero sin uso activo desde que `nivel_importancia` pasó a `tasks`.
- `bot_niveles_fijos` (nueva, 19/ago) — `bot_slug` (FK a `bots.slug`, único),
  `nivel_fijo`, `razon`. Un bot con fila aquí corre **siempre** en ese nivel,
  sin importar el dominio de la tarea que coordina — pensado para bots
  orquestadores (Efadam, Técnico jefe, Consultor de arquitectura, los 3
  centers), que no deben pagar un modelo caro solo por coordinar. Deliberadamente
  separada de `bots.dispatches_tasks` — son dos conceptos distintos que hoy
  coinciden pero no tienen por qué seguir coincidiendo (ver
  `reglas_generales.md`, punto 6). Solo afecta qué modelo ejecuta al bot,
  nunca el `tasks.nivel_importancia` de la tarea que está coordinando — esos
  dos ejes son independientes a propósito. `schema/008_bot_roles.sql`.
- `approvals`, `agent_runs` — aprobaciones y logs (agent_runs se llena en Fase 4).

- `system_knowledge` — autoconciencia del sistema: arquitectura, stack, reglas.
  No cambia mensaje a mensaje, pero sí evoluciona con el tiempo — la fuente
  de verdad es la tabla misma (el repo es solo el seed inicial, cargado una
  vez). La escribe Upgrade & review center, a solicitud de Efadam, que actúa
  como cuello de botella único de entrada — nunca redacta el contenido él
  mismo. Ver `memoria_del_sistema.md` para el diseño completo.
- `knowledge_log` — bitácora de casos: `patron_fallo` (automático, salvo la
  excepción `conocimiento_directo`) y `aprendizaje` (redactado por Upgrade &
  review center, insertado por Efadam).

## Ejecución

Un solo workflow, el **Ejecutor genérico**, corre a cualquier bot leyendo su
fila de `bots`. Agregar un bot = un `INSERT`, no un workflow nuevo.
Un bot con `dispatches_tasks = true` no entrega un resultado final: entrega
asignaciones en JSON estricto que el ejecutor convierte en tareas hijas.

## Convenciones de código

- **Ponytail / modo `lean`** — default para automatización interna, scripts y
  prototipos: el mínimo código que resuelve el problema, revisar antes si ya
  existe en el repo o lo resuelve la librería estándar. Nunca se recorta en
  validación de entradas, manejo de errores que prevenga pérdida de datos,
  seguridad ni accesibilidad.
- **Modo `robusto`** — obligatorio para código de seguridad, pagos, o cara al
  cliente: validación exhaustiva y manejo de errores aunque cueste más líneas.
- El modo lo decide **Técnico jefe**, no el bot que ejecuta.
- **Spec Kit** (`specify → plan → tasks → implement`) para cualquier cambio de
  varios pasos. La fase `specify` es en sí un checkpoint humano.
- Todo prompt de bot sigue la plantilla estándar: rol, objetivo, input, output,
  herramientas, reglas y límites, cuándo pedir aprobación humana, prompt de
  sistema final, casos de prueba.

## Niveles de importancia y BYOK (rediseño del 15 de agosto de 2026, noche; mecanismo concreto añadido el 16 de agosto)

**Reemplaza el modelo anterior de "Presupuesto"** (una sola instancia de
OmniRoute cargada a mano con las llaves de Mateo, capas gratis por default,
presupuesto pagado reservado a una lista fija de bots). Ese modelo no
escala: (1) obliga a cablear una llave API por bot a mano durante el setup,
lo cual es fricción real para cualquier instalador nuevo, y (2) asume una
sola instancia de OmniRoute compartida, lo cual no aplica a un producto
distribuible — cada instalación necesita su propio OmniRoute, con sus
propias llaves, no la de Mateo.

**Principio central: los bots nunca declaran un modelo, y no deciden su
propio nivel — Efadam lo asigna aplicando reglas fijas, no criterio libre.**
Ningún prompt de ningún bot (ni Efadam) menciona el nombre de un modelo. Y,
a diferencia de dos versiones anteriores de este documento, **el nivel no lo
decide cada bot por sí mismo, ni lo juzga Efadam caso por caso**: Efadam
corre en nivel `bajo` (modelo barato/rápido) para no agotar presupuesto en
ruteo, y pedirle que además juzgue con criterio libre qué tan importante es
cada tarea lo convertiría en el peor juez posible para esa decisión — mismo
problema ya documentado para `patron_fallo` ("el peor juez posible de qué
vale la pena recordar"), aquí con más consecuencia real (elegir modelo caro
vs. gratis en algo potencialmente legal o financiero). Por eso el nivel se
fija con **reglas explícitas por dominio/tema**, que Efadam solo aplica —
clasificar, no juzgar.

### Reglas de asignación (por dominio/tema, no por cluster destino)

Efadam evalúa la tarea contra estas reglas, en orden — si una tarea coincide
con varias, **gana la de nivel más alto**. Los 4 nombres en prosa
(`bajo`/`medio`/`alto`/`crítico`) son para lectura humana; el **valor
literal** que Efadam escribe en `tasks.nivel_importancia` y que
`bots.default_model` deja de usar es, siempre, sin tilde y en minúsculas —
`bajo` / `medio` / `alto` / `critico` — porque es un identificador de
sistema (check constraint de Postgres + alias de modelo en OmniRoute), no
texto que un humano lee. Ver "Cómo se traduce nivel → modelo real" abajo.

| si la tarea implica... | nivel mínimo | valor literal |
|---|---|---|
| gasto de dinero (cualquier monto), tema legal/contractual, publicación de contenido público, cambio de configuración de seguridad | crítico | `critico` |
| decisión de precio, contratación/despido, dictamen que compromete al negocio frente a un tercero (cliente, proveedor, autoridad) | alto | `alto` |
| trabajo especializado de un bot dentro de su dominio normal (código, investigación, redacción interna, análisis) sin las condiciones de arriba | medio | `medio` |
| ruteo, resumen de estado, tareas mecánicas de alta frecuencia (el modo normal de Efadam mismo) | bajo | `bajo` |

Estas reglas viven en `system_knowledge` (no hardcodeadas en el prompt de
Efadam) para que Upgrade & review center pueda proponer ajustes con el
mismo flujo de "cuello de botella" ya documentado (Efadam solicita, U&R
center evalúa y redacta, Efadam inserta) — igual que cualquier otra pieza de
`system_knowledge`, no una excepción nueva al mecanismo. Cualquier caso que
no encaje claramente en ninguna fila **sube por default al nivel superior
más cercano** (nunca se redondea hacia abajo en caso de duda) y, si la
ambigüedad es real, Efadam pregunta al usuario en vez de asumir — mismo
principio que ya aplica para enrutar a un cluster ambiguo.

OmniRoute es el **único** traductor de nivel → modelo real. Esto mantiene los
prompts de los bots estables aunque el usuario cambie de proveedor: cambiar
qué modelo resuelve `alto` es una configuración de OmniRoute, nunca una
edición al prompt del bot ni a las reglas de asignación.

### Cómo se traduce nivel → modelo real (mecanismo concreto)

**Corrección del 16 de agosto de 2026, tarde — la versión anterior de esta
sección estaba mal.** Decía "OmniRoute es LiteLLM self-hosted" y describía
un `config.yaml` con alias de modelo al estilo LiteLLM. Eso se escribió sin
verificarlo contra lo que corre en la máquina de Mateo, y es falso: se
verificó entrando al contenedor `infinite-power-omniroute-1` y leyendo su
documentación interna (`/app/docs`). **OmniRoute no es LiteLLM — es un
proyecto de código abierto distinto y genuino**, literalmente llamado
OmniRoute (`diegosouzapw/OmniRoute`, "The Free AI Gateway": ~290
proveedores, 90+ capas gratis, dashboard propio en `:20128`). El
`config.yaml`/`litellm_params` documentado antes no existe en esta
instalación — es una fabricación, hay que descartarlo por completo.

**Lo que sí está confirmado (leído directo de `/app/docs/reference/API_REFERENCE.md`
dentro del contenedor):**

- Los proveedores (Groq, Gemini, etc.) se conectan vía el dashboard de
  OmniRoute (`http://localhost:20128`), no vía un archivo de config editado
  a mano — algunos ni siquiera piden API key (Kiro, OpenCode Free,
  Pollinations).
- OmniRoute soporta **combos con nombre**: `GET/POST /api/combos*` para
  administrarlos, y una petición de chat puede referenciar un combo
  directamente por su nombre en el campo `model` (coincide primero por
  nombre, luego por id — documentado en `API_REFERENCE.md` línea ~99).
- Existe además `/api/model-combo-mappings` (`POST` con body
  `{pattern, comboId, priority?, enabled?, description?}`) para redirigir
  un id de modelo estilo OpenAI hacia un combo — un segundo camino para
  lograr lo mismo.
- El sistema también trae ruteo automático nativo por prefijo
  (`auto`, `auto/coding`, `auto/cheap`, `auto/fast`, etc. — ver
  `/app/docs/routing/AUTO-COMBO.md`), que no es lo que este proyecto
  necesita (no deja nombrar 4 niveles fijos con sus propios modelos), pero
  confirma que el concepto de "nombre → modelo real" sí es nativo aquí,
  solo que con otro nombre (combo) y otra API.

**Esquema de combo — confirmado el 17 de agosto de 2026** (extraído del
código fuente real dentro del contenedor, no adivinado): `POST/PUT
/api/combos/{id}` acepta `name`, `description?`, `models[]` (cada entrada
es un modelo real `{provider, model, weight, ...}` o una referencia a otro
combo `{kind: "combo-ref", comboName}`), `strategy` (default `"priority"`),
y un `config` opcional. **Nota de API real:** el endpoint de edición
responde `405` a `PATCH` — hay que usar `PUT` con el objeto completo de
`models`, no un parche parcial. Detalle completo y el body exacto usado en
`plan_de_accion_completo.md`, actualización del 17 de agosto.

Los 4 combos (`bajo`/`medio`/`alto`/`critico`) ya existen en la instalación
de Mateo, creados con esta forma. **Fallback entre niveles, no solo dentro
de un nivel:** cada combo, además de sus modelos reales, incluye como
última entrada una referencia (`combo-ref`) al combo del nivel
inmediatamente inferior — `critico → alto → medio → bajo` — así que si
todos los modelos reales de un nivel fallan, la tarea cae al nivel de
abajo en vez de fallar sin servir nada. Decisión de Mateo, 17 de agosto
("si no hay un modelo seleccionado... se iría al de abajo"). **Pendiente,
no construido todavía:** un aviso visible para Mateo cuando una tarea de
nivel `alto`/`crítico` termina sirviéndose por un modelo de nivel inferior
vía este fallback — bajar de modelo en algo legal/financiero en silencio
no es aceptable, aunque el sistema no se caiga. La columna
`agent_runs.model_used` ya existe y es el lugar natural para detectar el
desajuste (comparar contra `tasks.nivel_importancia`); falta la lógica en
el Ejecutor genérico que la lea y dispare la alerta — bloqueado, por ahora,
en tener acceso de escritura a los workflows de n8n. Ver
`plan_de_accion_completo.md` para el detalle completo.

**Lo que no cambia con esta corrección (el principio de diseño sigue
vigente, solo cambió la herramienta que lo implementa):**

- El nodo "Llamar a OmniRoute" del Ejecutor genérico manda el valor de
  `tasks.nivel_importancia` tal cual en el campo `model` del request (ej.
  `model: "alto"`) — eso no depende de si el receptor es LiteLLM o
  OmniRoute, cualquier proxy compatible con el formato OpenAI puede recibir
  ese campo igual.
- `tasks.nivel_importancia` sigue reemplazando a `bots.default_model` como
  fuente del modelo a usar. Ver `schema/005_nivel_importancia.sql`.
- Cambiar qué modelo resuelve un nivel sigue siendo, en principio, una
  edición del lado del router (ahora: reconfigurar el combo `alto` en
  OmniRoute), nunca un cambio a un prompt de bot ni al workflow de n8n —
  eso se mantiene una vez que se confirme el esquema real de combos.

> **Nota del 16 de agosto, tarde — decidido, ya no pendiente.** Todo lo que
> sigue de aquí hasta "Decidido... reglas explícitas" describe el escenario
> de producto distribuible (empaquetado, setup con BYOK, "un OmniRoute por
> instalación"). La auditoría del mismo día señaló que ese scope se coló en
> decisiones de diseño antes de que el sistema completara una sola corrida
> autónoma real, y preguntó si esta sección debía congelarse hasta que el
> sistema para un solo operador funcione una semana seguida. **Mateo
> respondió que no** — congelarlo arriesga construir una mala base, porque
> producto distribuible es el objetivo final del proyecto y tiene que
> seguir en la vista aunque no sea el foco de trabajo inmediato. La sección
> sigue vigente como diseño, sin fecha de implementación forzada — ver
> actualización del 16 de agosto, tarde/noche, en `plan_de_accion_completo.md`.

**OmniRoute viene empaquetado, no configurado a mano.** OmniRoute (y n8n,
junto con el workflow del Ejecutor genérico ya importado) se distribuyen
como parte del mismo paquete instalable — hoy, contenedores Docker dentro
del mismo `docker-compose.yml` del sistema. Al instalar, los 4 niveles ya
tienen un modelo gratis asignado por default (ej. Groq/Gemini free tier) sin
que el usuario tenga que tocar nada. Esto es distinto de n8n: n8n no
requiere una llave por instalación (es un solo operador por instancia), lo
que cambia es que deja de requerir configuración manual post-instalación —
llega con la credencial de OmniRoute y el workflow del ejecutor ya cargados.

**Setup: qué ve el usuario.** Durante el setup inicial, el usuario ve los 4
niveles listados con su modelo gratis default ya asignado, y un disclaimer
recomendando subir de nivel (agregar una llave de pago) al menos en `alto` y
`crítico`, donde un modelo gratis puede no ser suficiente. Añadir una llave
propia por nivel es opcional en el setup y se puede hacer en cualquier
momento después — no es un bloqueo para empezar a usar el sistema.

**Es una característica por instalación, no compartida.** "Es un OmniRoute
diferente para cada quien, no el mío" (Mateo, 15 de agosto de 2026): cada
instalador de Infinite Power obtiene su propia instancia de OmniRoute, con
sus propias llaves, aislada de cualquier otra instalación — incluida la de
Mateo. Esto es lo que hace posible que el producto se distribuya a terceros
sin que cada quien dependa de las credenciales de otra persona.

**Decidido (15 de agosto de 2026, noche): reglas explícitas, no criterio
libre.** Quedaba abierto si la clasificación de nivel debía ser criterio
libre de Efadam o reglas fijas — se resolvió a favor de reglas fijas por
dominio/tema (ver tabla arriba), justo por el riesgo de que un modelo barato
juzgue con criterio libre algo con consecuencia real. Esto no elimina el
riesgo por completo (las reglas mismas podrían tener huecos, y el "sube por
default" es la mitigación para ese caso), pero sí lo acota a algo auditable
y corregible vía el mecanismo normal de `system_knowledge`, en vez de
depender del juicio momento a momento de un modelo gratuito.

## Gotchas de n8n ya documentados (no repetirlos)

- Nodo Postgres en modo Update/Insert con **mapeo de columnas**: cachea tipos y
  mete `id = 0` en los inserts. Usar siempre *Execute Query* con `$1`/`$2`.
- Body JSON del nodo HTTP: armarlo con `JSON.stringify({...})` en modo expresión,
  nunca como texto JSON con expresiones incrustadas (los prompts traen comillas).
- Referenciar nodos por nombre (`$('Nombre').item.json`) en vez de `$json` cuando
  hay nodos intermedios; `$json` cambia al insertar un nodo nuevo en medio.
- Cancelar una ejecución a mano deja la tarea en `running` para siempre; hay que
  resetearla con `UPDATE tasks SET status='pending' WHERE id = <id>;`.
