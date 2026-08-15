# Stack y convenciones de Infinite Power (canónico)

> Fuente de verdad. Se sincroniza a `system_knowledge.slug = 'stack_y_convenciones'`.
> Solo hechos vigentes, en presente, sin historia.

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
  parent_task_id, created_at, updated_at`.
  Estados: `pending, running, done, failed, blocked, needs_approval`.
  `output` es **text**, no jsonb.
- `bots` — configuración de cada bot: `slug, cluster, prompt_especifico,
  system_prompt (derivado), nivel_importancia, contexto_slugs,
  conocimiento_directo, requires_approval, dispatches_tasks, active`.
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

## Niveles de importancia y BYOK (rediseño del 15 de agosto de 2026, noche)

**Reemplaza el modelo anterior de "Presupuesto"** (una sola instancia de
OmniRoute cargada a mano con las llaves de Mateo, capas gratis por default,
presupuesto pagado reservado a una lista fija de bots). Ese modelo no
escala: (1) obliga a cablear una llave API por bot a mano durante el setup,
lo cual es fricción real para cualquier instalador nuevo, y (2) asume una
sola instancia de OmniRoute compartida, lo cual no aplica a un producto
distribuible — cada instalación necesita su propio OmniRoute, con sus
propias llaves, no la de Mateo.

**Principio central: los bots nunca declaran un modelo, declaran un nivel.**
Ningún prompt de ningún bot (ni Efadam) menciona el nombre de un modelo. Cada
bot tiene una columna `bots.nivel_importancia` con uno de 4 valores fijos del
sistema — no configurables en cantidad ni nombre, solo en qué modelo resuelve
cada uno:

| nivel | uso típico |
|---|---|
| `bajo` | ruteo de alta frecuencia, tareas mecánicas (ej. Efadam en su modo normal) |
| `medio` | trabajo estándar de un bot especializado (ej. Coder, Trouble shooter) |
| `alto` | decisiones con impacto de negocio real (ej. Consultor de negocios, Abogado Jefe) |
| `crítico` | máximo riesgo o síntesis compleja (ej. Council, Out of the box thinker) |

OmniRoute es el **único** traductor de nivel → modelo real. Esto mantiene los
prompts de los bots estables aunque el usuario cambie de proveedor: cambiar
qué modelo resuelve `alto` es una configuración de OmniRoute, nunca una
edición al prompt del bot.

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

## Gotchas de n8n ya documentados (no repetirlos)

- Nodo Postgres en modo Update/Insert con **mapeo de columnas**: cachea tipos y
  mete `id = 0` en los inserts. Usar siempre *Execute Query* con `$1`/`$2`.
- Body JSON del nodo HTTP: armarlo con `JSON.stringify({...})` en modo expresión,
  nunca como texto JSON con expresiones incrustadas (los prompts traen comillas).
- Referenciar nodos por nombre (`$('Nombre').item.json`) en vez de `$json` cuando
  hay nodos intermedios; `$json` cambia al insertar un nodo nuevo en medio.
- Cancelar una ejecución a mano deja la tarea en `running` para siempre; hay que
  resetearla con `UPDATE tasks SET status='pending' WHERE id = <id>;`.
