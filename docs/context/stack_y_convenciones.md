# Stack y convenciones de Infinite Power (canónico)

> Fuente de verdad. Se sincroniza a `system_knowledge.slug = 'stack_y_convenciones'`.
> Solo hechos vigentes, en presente, sin historia.

## Stack

- **Orquestador:** n8n self-hosted (Docker), `localhost:5678`.
- **Base de datos:** Postgres 16 self-hosted (Docker). Es la memoria y la cola.
- **Router de modelos:** OmniRoute self-hosted, `localhost:20128`. Gateway
  multi-proveedor (90+ proveedores con capa gratis, fallback automático de 4
  niveles) — baja el riesgo de que una cadencia alta se corte por rate limit
  de un solo proveedor.
  Desde adentro de la red de Docker se llama `http://omniroute:20128`, nunca `localhost`.
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
  system_prompt (derivado), default_model, contexto_slugs, requires_approval,
  dispatches_tasks, active`.
- `approvals`, `agent_runs` — aprobaciones y logs (agent_runs se llena en Fase 4).
- `system_knowledge` — autoconciencia, sincronizada desde `docs/context/*.md`.
- `knowledge_log` — bitácora de casos. Efadam es dueño por default (`aprendizaje`);
  excepción angosta por bot vía `bots.conocimiento_directo` (hoy solo `trouble_shooter`, `patron_fallo`).

## Ejecución

Un solo workflow, el **Ejecutor genérico**, corre a cualquier bot leyendo su
fila de `bots`. Agregar un bot = un `INSERT`, no un workflow nuevo.
Un bot con `dispatches_tasks = true` no entrega un resultado final: entrega
asignaciones en JSON estricto que el ejecutor convierte en tareas hijas.

**Cadencia:** cada rama/proyecto corre por Schedule Trigger propio en n8n, con
su propia frecuencia — pendiente definir el número exacto por rama. No es un
loop continuo; se siente indefinido porque las colas de cada rama son
independientes entre sí, no porque nada nunca se detenga.

Sistema de aclaración/reanudación construido: cuando un bot responde
`NECESITA_ACLARACION:` y la tarea tiene `parent_task_id`, se crea
automáticamente una tarea de vuelta al bot padre y la original se marca
`blocked`; el workflow **Reanudador de bloqueados** reactiva la tarea padre
cuando la tarea hija de aclaración queda `done`.

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

## Presupuesto

Capas gratis (Gemini, Groq) por default vía OmniRoute. El presupuesto pagado
(~$350 MXN total) se reserva para: Council, Abogado Jefe, Consultor de negocios,
Ciber seguridad, Hacker ético, Out of the box thinker.
**Efadam NO usa modelo de pago** para ruteo: es el bot de mayor frecuencia del
sistema y agotaría el presupuesto solo en decidir a quién mandar las cosas.

## Gotchas de n8n ya documentados (no repetirlos)

- Nodo Postgres en modo Update/Insert con **mapeo de columnas**: cachea tipos y
  mete `id = 0` en los inserts. Usar siempre *Execute Query* con `$1`/`$2`.
- Body JSON del nodo HTTP: armarlo con `JSON.stringify({...})` en modo expresión,
  nunca como texto JSON con expresiones incrustadas (los prompts traen comillas).
- Referenciar nodos por nombre (`$('Nombre').item.json`) en vez de `$json` cuando
  hay nodos intermedios; `$json` cambia al insertar un nodo nuevo en medio.
- Cancelar una ejecución a mano deja la tarea en `running` para siempre; hay que
  resetearla con `UPDATE tasks SET status='pending' WHERE id = <id>;`.
- **Docker Desktop puede caerse solo en Windows.** Si `docker ps` falla con
  `failed to connect to the docker API at npipe:...`, revisar si el proceso
  sigue vivo (`Get-Process "com.docker*"`) y relanzarlo con
  `Start-Process "shell:AppsFolder\Docker.DockerForWindows.Settings"` — no
  siempre está en `C:\Program Files\Docker\Docker\Docker Desktop.exe`.
- **`Get-Content | docker exec -i psql` corrompe acentos/ñ en PowerShell.**
  Usar siempre `docker cp archivo.sql <contenedor>:/tmp/ && docker exec -i
  <contenedor> psql ... -f /tmp/archivo.sql` para cualquier SQL con texto en
  español.
