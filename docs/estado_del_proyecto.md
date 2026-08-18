# Estado del proyecto — Infinite Power

> Actualizado: 18 de agosto de 2026, noche (pausa, `correcciones` mergeada a `main`). Este archivo es para humanos: estado real,
> decisiones y por qué. **No se inyecta a ningún bot.** Lo que los bots leen son
> los archivos cortos de `docs/context/`, poblados una sola vez (seed) desde
> este repo al arrancar el sistema — después del seed, `system_knowledge` (la
> tabla) es la fuente de verdad viva, y este repo puede quedar desactualizado
> respecto a ella (ver `memoria_del_sistema.md`, sección "Repo como seed, no
> como fuente de verdad").

## Qué es

Sistema de agentes de IA para gestionar y hacer crecer negocios de forma cada vez más autónoma, con la menor intervención humana posible. Pensado para uso personal o negocios pequeños — no para operaciones grandes que necesiten mucha más capacidad de análisis o logística (aclarado por Mateo el 17/ago, en respuesta a una auditoría externa que proponía "sistema operativo de trabajo para dueños de pequeños negocios" como redacción de visión). Nace de una pizarra en ClickUp (whiteboard "Infinite power"). Visión y Método fusionados en `docs/archivo/plan_de_accion_completo.md` (la nota suelta original se eliminó el 15/ago).

## Quién lo construye

- **Mateo** — fundador, Claude Pro, $150 MXN para una API de pago. Proyecto individual (confirmado el 17/ago: no hay cofundador).

## Arquitectura

Jarvis (endpoint humano, hoy Telegram lo cumple provisionalmente) → Efadam en el centro + 3 ramas, cada una con su bot "center" que consolida, audita y aprueba antes de reportar a Efadam. Narrativa completa en [[arquitectura_general]]; versión corta que leen los bots en [[arquitectura]].

```
                       JARVIS (Telegram, provisional)
                              |
                           EFADAM
                    (cerebro de orquestación)
                              |
        ----------------------|----------------------
        |                     |                      |
   Tech center      Upgrade & review center     Proyect center
```

## Orden de construcción (vertical, vigente desde el 15 de agosto de 2026)

Ya no es por fase horizontal ("escribir los 40 prompts primero"). Es un componente completo (construido, probado, activo) antes de pasar al siguiente:

1. **Efadam** — primero, para que las ramas tengan a dónde reportar en cuanto produzcan algo.
2. **Tech center** — 10 de 12 bots con prompt escrito; falta activarlo end-to-end contra un Efadam real.
3. **Upgrade & review center**.
4. **Proyect center**.
5. **Jarvis** — al final, cuando ya haya algo real que enrutar.

## Estado real (no lo planeado — lo que existe)

### Infraestructura — Paso 0 completo ✅

n8n + Postgres 16 + OmniRoute en Docker, en `C:\Users\2\Documents\infinite-power`. Bot de Telegram creado y probado (canal provisional de Jarvis). Repo privado `github.com/Madafe/Infinite_Power`, rama de trabajo activa: `correcciones`.

### Ejecutor genérico — probado ✅ (26 nodos)

Un solo workflow que corre a cualquier bot leyendo su fila de `bots`. Incluye, funcionando: contexto de linaje, sistema de aclaración completo con reanudación bot-a-bot, extracción de patrones de fallo (`conocimiento_directo`), lectura de `tasks.nivel_importancia` para elegir modelo, y **propagación de `nivel_importancia` a tareas hijas** (18/ago — antes se perdía; ahora Técnico jefe y Trouble shooter heredan su propio nivel hacia lo que despachan, tal como lo define `efadam.md`).

**Manejo de errores — corregido de fondo el 18/ago, en dos rondas (la segunda corrige a la primera).** Primera ronda (tarde-noche): se descubrió que `"Marcar como fallida"` **jamás se había disparado en la historia de este workflow**, y se arregló solo para `"Llamar a omniroute"` (IF explícito que revisa `$json.error`), dejando documentados otros 13 nodos como supuestamente rotos por el mismo motivo ("hallazgo C5"). **Segunda ronda (noche): ese diagnóstico de los 13 nodos era incorrecto** — probado en vivo, nodo por nodo, Postgres/Code/Telegram enrutan sus errores bien de fábrica, sin necesitar ningún arreglo. El bug real era otro: cada tipo de nodo entrega el error con una forma de JSON distinta que "Marcar como fallida" no sabía normalizar, más un bug de n8n no documentado (`$('Reclamar tarea pendiente').first()` truena cuando el nodo llamador se alcanza por una ruta de error rescatada; `.item` sí funciona). Arreglo real: se generalizó el Code node `"Preparar fallo"` y se re-cablearon 17 conexiones para pasar por él — **cero nodos nuevos**, workflow se mantiene en 26 nodos. Probado en vivo de punta a punta dos veces (vía Postgres y vía omniroute) más una confirmación extra del guard anti-loop de Trouble shooter. **Dos gaps nuevos, sin resolver, encontrados en el proceso:** (1) si `"Reclamar tarea pendiente"` falla en sí mismo (ej. Postgres caído) no hay `task_id` todavía, así que ese modo de falla —el más grave— queda completamente sin registrar ni alertar; (2) el comportamiento real de los 4 nodos IF ante un error genuino nunca se pudo confirmar en vivo (dos intentos de forzarlo fallaron). Detalle completo en `ejecutor_generico.md`. Además se cerró el **hallazgo C2** (inyección SQL en `"Obtener config del bot"`, ahora parametrizada con `$1`).

**Operaciones — concepto nuevo, construido y probado en vivo el 18/ago, noche.** Tabla `operations` (el hilo de trabajo completo detrás de una tarea o grupo de tareas: una petición de usuario, una investigación, una ronda de autoexpansión) y `tasks.operation_id`, propagado por subquery SQL. Centralizado en Efadam (solo él abre una operación, a diferencia de `tasks`, que cualquier cluster sigue despachando directo) — hoy nada la usa de verdad porque Efadam no existe como bot activo, pero el schema y la propagación ya están listos. De paso se corrigieron 2 bugs reales: las tareas de aclaración y las de auto-dispatch a Trouble shooter nacían sin `nivel_importancia`, condenadas a fallar. Detalle completo en `ejecutor_generico.md`.

**Disparo automático a Trouble shooter — construido y probado en vivo el 18/ago.** En cuanto `"Marcar como fallida"` marca cualquier tarea como `failed`, se crea automáticamente una tarea nueva `pending` para `trouble_shooter` con el error como input y el mismo `cluster`, con guarda para que un fallo del propio Trouble shooter no se auto-despache en loop. Detalle en `ejecutor_generico.md`, nodos 19-20, y `trouble-shooter.md`.

Como parte de probar todo esto en vivo se encontraron y repararon 2 tareas reales atoradas en el backlog (ids 4 y 7, desde el 13-14/ago) — les faltaba `nivel_importancia`, quedaban atoradas en `running` por el mismo bug de arriba. Ya corrieron y quedaron `done` con salida real de modelo.

Ver [[ejecutor_generico]] para el detalle nodo por nodo.

### Bots realmente activos: 3

`tecnico_jefe` (despacha), `coder`, `trouble_shooter` (despacha,
`conocimiento_directo = true`). **Corrección 18/ago — anula la corrección del
17/ago, noche, quinta ronda, que había bajado esto a "2" y estaba mal:** esa
ronda concluyó que `trouble_shooter` nunca se insertó en `bots`, basándose en
que los únicos scripts commiteados que lo tocan (`003_trouble_shooter_v2.sql`,
`004_conocimiento_directo.sql`) son `UPDATE`. El razonamiento no consideró que
tampoco existe ningún script commiteado de `INSERT` para `tecnico_jefe` ni
`coder` — los 3 bots se insertaron a mano, fuera de git, y esa ronda no pudo
verificarlo porque Postgres estaba apagado. Confirmado el 18/ago directo
contra la base real. Detalle completo en `plan_de_accion_completo.md`,
actualización del 18 de agosto, y en `ejecutor_generico.md`/`trouble-shooter.md`.
**Todo lo demás existe solo como archivo `.md`.** Un bot que no está en `bots`
con `active = true` no existe para el sistema. Efadam **todavía no está
insertado en `bots`** — es el bloqueante actual para que el sistema funcione
de punta a punta con orquestación real.

### Prompts escritos (no activos)

Rama Dev/Tech: Prompt perfection, Entrenador Agentes, Coder, Agent builder, Trouble shooter, Ciber seguridad scouter, Hacker ético, Ciber seguridad, Técnico jefe, Tech center. Efadam (cross-rama, en `prompts/_core/`).
Diseñados pero no activados: Consultor de arquitectura, Trouble scouter.

Ramas Upgrade & review center y Proyect center: **cero prompts escritos.**

## Decisiones de arquitectura técnica

- **Orquestador:** n8n self-hosted (Docker), `localhost:5678`.
- **Memoria/estado:** Postgres 16 self-hosted (Docker).
- **Router de modelos:** OmniRoute self-hosted (proyecto independiente, no LiteLLM), `localhost:20128` (`http://omniroute:20128` desde dentro de Docker). Traduce nivel de importancia → modelo real vía "combos"; esquema exacto de creación de combos (`POST /api/combos`) **confirmado el 17 de agosto** contra el código fuente real del contenedor (ver `plan_de_accion_completo.md`). Pendiente antes de crear los 4 combos: 4 problemas de infraestructura sin resolver (volumen mal montado, secrets faltantes, password default, cero proveedores conectados) — ver misma actualización.
- **Infraestructura:** todo local. VPS + dominio después.
- **Aprobaciones humanas:** bot de Telegram. Checkpoints obligatorios en gasto, publicación, temas legales, seguridad, y acciones fuera del sandbox de un bot con autonomía ampliada.
- **Modelo de niveles de importancia (reemplaza el viejo modelo de "Presupuesto pagado" de una lista fija de bots, 15/ago noche):** ningún bot declara su propio modelo ni decide su propio nivel. Efadam asigna `bajo`/`medio`/`alto`/`critico` aplicando reglas fijas por dominio/tema (no criterio libre) al despachar cada tarea; el bot que ejecuta hereda ese nivel en `tasks.nivel_importancia`. OmniRoute resuelve el nivel al modelo real — el mecanismo pensado para que cada instalación (BYOK) traiga sus propias llaves, sin depender de una sola instancia compartida cargada con las de Mateo. Detalle completo en `stack_y_convenciones.md`, sección "Niveles de importancia y BYOK".
- **Convención de código:** Ponytail, modo `lean`/`robusto` decidido por Técnico jefe.
- **Andamiaje:** GitHub Spec Kit para tareas de varios pasos.

### Memoria del sistema

Dos tablas: `system_knowledge` (autoconciencia — poblada una sola vez, seed, desde `docs/context/*.md` y `reglas_generales.md` del repo; después del seed la tabla manda, no el repo) y `knowledge_log` (bitácora, dos tipos: `patron_fallo` lo escribe el ejecutor automáticamente, `aprendizaje` lo redacta Upgrade & review center a pedido de Efadam — Efadam nunca redacta, solo inserta). La única excepción al cuello de botella de Efadam es angosta y explícita por bot (`bots.conocimiento_directo`, hoy solo `trouble_shooter`). Diseño completo en [[memoria_del_sistema]].

Las reglas generales viajan dentro del `system_prompt`, compuestas por un trigger a partir de `bots.prompt_especifico`. **Nunca se escribe `system_prompt` a mano.**

## Plan de fases (histórico — reemplazado por el orden vertical de arriba)

La tabla de fases horizontales de versiones anteriores de este documento quedó superseded por el orden de construcción vertical del 15 de agosto (ver arriba). El avance real hoy es: Fase 0 (infraestructura) completa; dentro del componente "Tech center", el ejecutor genérico y el piloto Técnico jefe → Coder / Trouble shooter están probados de punta a punta; Efadam, el resto de Tech center, y las otras 2 ramas siguen sin construir.

**Riesgo vigente:** el proyecto lleva días construyendo el sistema que construye el sistema. El criterio de "suficiente" para la plomería: escribir y activar solo los bots que de verdad se usarían esta semana, no el roster completo de golpe.

## Auditoría externa del 16 de agosto de 2026 — en remediación

Una auditoría externa (`auditoria_infinite_power_16ago2026.md`) encontró contradicciones de documentación y deuda de infraestructura. Remediación organizada en 3 bloques, trabajada en la rama `correcciones` y **mergeada a `main` el 18 de agosto, noche** (fast-forward, sin conflictos, por instrucción explícita de Mateo — `correcciones` sigue viva, no se borró, ver `plan_de_accion_completo.md` para la política completa de ramas):

- **Bloque 0 (infraestructura) — completo.** Workflows de n8n exportados, backup de Postgres probado, `.gitattributes`, secrets movidos a `.env`, timezone explícito.
- **Bloque 1 (contradicciones de documentación) — completo.** Las 5 contradicciones de "fuente de verdad" corregidas y los duplicados del Claude Project limpiados (17/ago).
- **Bloque 2 (OmniRoute/n8n en vivo) — infraestructura arreglada y verificada; el bloqueo de "ningún proveedor rutea tráfico real" se cerró el 18 de agosto con NVIDIA (ver bullet más abajo).** Lo que sigue bloqueado dentro de Bloque 2 es solo lo que necesita n8n (ver bullet de la cuarta ronda, abajo). Los 4 problemas de infraestructura (volumen mal montado, faltaban `JWT_SECRET`/`API_KEY_SECRET`, sin contraseña de dashboard, cero proveedores) están resueltos: `docker-compose.yml` corregido y verificado (el volumen ahora sí persiste), contraseña del dashboard generada por Claude y fijada (en `.env`, gitignored), 4 combos creados (`bajo`/`medio`/`alto`/`critico`). **Cloudflare AI se descartó** (decisión de Mateo). **Pollinations resultó no ser realmente "sin auth" para uso real** — la conexión se creó pero los 3 modelos probados devuelven 401 "API key required" (`enter.pollinations.ai/keys`, no confirmado si es gratis o de pago) — corrección a la evaluación anterior, que solo había verificado el código, no una llamada real. **Qwen — Mateo autorizó proceder, pero el último paso (loguearse en `chat.qwen.ai` y extraer un token de sesión real desde DevTools) solo lo puede hacer él** — no es algo que se pueda generar o adivinar. Resultado: **los 4 combos existen pero hoy no rutean nada real** — sigue pendiente que al menos un proveedor funcione de verdad. Ver `plan_de_accion_completo.md`, actualización del 17 de agosto, noche, segunda ronda, para el detalle completo.
- **Bloque 3 (activar Efadam) — no empezado**, depende de que cierre Bloque 2. Además, la auditoría técnica y de visión del 17 de agosto (`auditoria_tecnica_y_vision_17ago2026.md`) encontró 3 hallazgos críticos que hoy no están cubiertos por la secuencia de Bloque 2 y se agregaron antes de este punto: contraseña de Postgres expuesta en el historial de git (~~sin rotar~~ — **rotada el 18/ago, noche**, ver bullet más abajo), inyección SQL en el nodo "Obtener config del bot" (**cerrada el 18/ago**, ver bullet de la cuarta ronda más abajo), y un flujo de aprobación humana que hoy es solo una notificación saliente sin ruta de respuesta (sigue pendiente). Ver `plan_de_accion_completo.md`, "Pendientes de Bloque 2, en secuencia", para el detalle.
- **Bloqueo (17/ago, noche, cuarta ronda) — cerrado el 18/ago: Mateo pasó la API key de n8n en el chat.** Con eso, esta sesión ya puede escribir en n8n en vivo directamente (Mateo pidió explícitamente no editar n8n él mismo — "no quiero editar yo n8n, me lleva mucho tiempo"). La key vive temporalmente en `.env` (`N8N_API_KEY_TEMP`), marcada como pendiente de eliminar (revocar en n8n + borrar la línea) una vez que se termine el trabajo pendiente de n8n de esta ronda (ver "Pendientes" abajo). Con este acceso ya se resolvieron: propagar `nivel_importancia` a tareas hijas, parametrizar el SQL vulnerable de `"Obtener config del bot"` (hallazgo C2), y construir el disparo automático a Trouble shooter (ver sección "Ejecutor genérico" arriba). Lo que sigue bloqueado o pendiente dentro de n8n: hallazgo C5 (~~13 nodos con el mismo bug de manejo de errores~~ — **cerrado el 18/ago, noche, con corrección: ver "Manejo de errores" arriba**), rotar la contraseña de Postgres (~~ver nota abajo — resultó más riesgoso de lo asumido~~ — **cerrada, ver bullet de hallazgo C1 abajo**), la ingesta Telegram → `tasks`, y la aprobación humana bidireccional. Lo que sí se había resuelto sin necesitar n8n, ronda anterior: el fallback en cascada entre niveles en los 4 combos de OmniRoute (`critico → alto → medio → bajo`), y que Pollinations es gratis de verdad (aunque en la práctica se terminó usando NVIDIA, ver bullet siguiente). Ver `plan_de_accion_completo.md`, actualizaciones del 17 y 18 de agosto.
- **Hallazgo C1 (contraseña de Postgres) cerrado (18/ago, noche).** La ronda anterior la había pospuesto por prudencia al descubrir que la base de datos propia de n8n (workflows, ejecuciones, login) usa el **mismo usuario y base** (`infpower`/`infinite_power`) que las tablas de negocio (`tasks`, `bots`, etc.). Con autorización explícita de Mateo se ejecutaron los 4 pasos coordinados (`ALTER USER` en Postgres, actualizar `.env`, actualizar la credencial "Postgres account" de n8n vía API, y `docker compose up -d n8n` para que releyera la variable de entorno) y se verificó con una prueba en vivo real — no solo que n8n arrancó bien, sino que los nodos Postgres del workflow (probado con la técnica de webhook temporal) conectan de verdad con la contraseña nueva, sin tocar datos. La contraseña vieja sigue en commits antiguos de git, pero ya no es válida contra el Postgres real — la exposición pasada dejó de ser un riesgo vivo. Detalle completo en `plan_de_accion_completo.md`, actualización del 18 de agosto, noche.
- **Bloqueo (17/ago, noche, quinta ronda), resuelto el 18/ago: el stack entero (n8n, Postgres, OmniRoute) estaba apagado** — Docker Desktop no estaba corriendo en la máquina de Mateo. Al intentar levantarlo se encontró que la máquina tenía solo 0.8 GB de RAM libre de 15.7 GB, Docker Desktop se quedó atorado consumiendo 7.7 GB sin terminar de iniciar, y se decidió no seguir insistiendo a ciegas sobre una máquina en uso activo — se liberó la RAM y se dejó para que Mateo lo levante él mismo. **Mateo levantó Docker Desktop el 18/ago** — los 3 contenedores corriendo y saludables. Sobre la RAM: Mateo reporta que es un problema recurrente de esa máquina específica, ya descartó malware (varios formateos), sin causa identificada — no se investigó más a fondo, fuera del alcance de este proyecto.
- **Bloqueo de Bloque 2 cerrado (18/ago): NVIDIA NIM conectado y probado de punta a punta.** Mateo pasó una API key gratuita de NVIDIA; se conectó como proveedor en OmniRoute, se probó (`valid: true`, respuesta real de un modelo), y los 4 combos (`bajo`/`medio`/`alto`/`critico`) se reconfiguraron para usar modelos NVIDIA en vez de los de Pollinations (que nunca sirvieron tráfico real, ver corrección del 17 de agosto) — confirmado con llamadas reales a `/v1/chat/completions` por nombre de combo, con `x-omniroute-provider: nvidia` en la respuesta. Detalle completo, incluido un hallazgo importante (el catálogo de modelos que trae la imagen de OmniRoute tiene entradas dadas de baja/`410 Gone` que hay que verificar en vivo, nunca confiar en el archivo), en `plan_de_accion_completo.md`, actualización del 18 de agosto. **Corrección aparte, misma fecha: el diagnóstico del 17/ago sobre por qué Trouble shooter "no estaba activo" tenía un error en su parte (a)** — sí estaba insertado en `bots` desde antes; ver "Bots realmente activos" arriba y el detalle en `plan_de_accion_completo.md`.

Ver `plan_de_accion_completo.md` para el estado completo y actualizado de cada bloque — esta sección es un resumen, no la fuente de detalle.

## Deuda documentada

- ~~`roster_agentes_v4.xlsx` desactualizado y no commiteado~~ — **resuelto el 17 de agosto.** Se corrigió a la estructura real (Jarvis + Efadam separados, "Proyect center" sin typo, cada center reporta solo a Efadam, se agregaron Consultor de arquitectura y Trouble scouter, estado de activación real) y se commiteó por primera vez al repo (commit `49b89fd`).
- **Licencia de n8n — riesgo real para el plan de distribución, sin resolver.** n8n corre bajo la Sustainable Use License (fair-code, no OSI): uso gratuito solo para "fines de negocio internos" propios, y solo se puede distribuir "de forma gratuita, para fines no comerciales". Si "Infinite Power" se llega a vender empaquetado con n8n embebido en el instalador, eso probablemente cruza la línea de "distribuir el software" en un contexto comercial. La forma más segura: que cada cliente descargue su propio n8n Community (gratis) para su propio uso interno, en vez de que el instalador lo redistribuya embebido. OmniRoute (MIT) no tiene este problema. No resuelto — requiere revisión legal antes de vender la primera instalación. Ver fuentes en la conversación del 17 de agosto.
- **Nombre del departamento de la rama 2.** [[arquitectura_general]] la llama "Estrategia + Legal + Investigación"; [[Upgrade & Review center]] la llama "departamento de Investigación" pero le cuelga estrategia y legal.
- **TalentIA / Bintix / negocios propios** sin confirmar si cuelgan de Proyect center o son su propia agrupación.
- **Sistema de Revert** diseñado (git + `archived_at`/`archived_reason` + tabla `reverts`) pero **nada construido** en el schema.
- **Multiproyecto:** pendiente confirmar que ningún workflow de n8n tiene el schema de Postgres hardcodeado.

## Pendientes abiertos de diseño

- Herramienta de pentesting concreta del Hacker ético.
- Tamaño exacto del presupuesto propio de Out of the box thinker.
- Cadencia exacta (Schedule Trigger) por rama.
- ~~Confirmar esquema exacto de creación de combos en OmniRoute~~ — hecho el 17/ago. Falta configurar los 4 niveles, bloqueado por los hallazgos de infraestructura de Bloque 2 (ver arriba) y por 3 decisiones de Mateo (contraseña de onboarding de OmniRoute, cuenta de Cloudflare, riesgo de baneo de Qwen).
- **Automatizar la generación de credenciales de OmniRoute en el startup, desde la interfaz propia de Infinite Power** — confirmado factible el 17/ago (ver `plan_de_accion_completo.md`, actualización de esa noche, tercera ronda): un script/workflow de arranque puede generar los 4 secretos y la contraseña del dashboard, y crear los 4 combos, sin fricción para el usuario. Lo que nunca se puede automatizar es que el usuario consiga su propia API key de un proveedor real (eso siempre depende del proveedor externo). No construido — a resolver junto con el diseño general de startup/onboarding, no ahora.
