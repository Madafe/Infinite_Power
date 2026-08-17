# Estado del proyecto — Infinite Power

> Actualizado: 17 de agosto de 2026. Este archivo es para humanos: estado real,
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

### Ejecutor genérico — probado ✅ (22 nodos)

Un solo workflow que corre a cualquier bot leyendo su fila de `bots`. Incluye, funcionando: contexto de linaje, sistema de aclaración completo con reanudación bot-a-bot, manejo de errores, extracción de patrones de fallo (`conocimiento_directo`), y lectura de `tasks.nivel_importancia` para elegir modelo. Ver [[ejecutor_generico]].

### Bots realmente activos: 3

`tecnico_jefe` (despacha), `coder`, `trouble_shooter` (despacha, `conocimiento_directo = true`). **Todo lo demás existe solo como archivo `.md`.** Un bot que no está en `bots` con `active = true` no existe para el sistema. Efadam **todavía no está insertado en `bots`** — es el bloqueante actual para que el sistema funcione de punta a punta con orquestación real.

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

Una auditoría externa (`auditoria_infinite_power_16ago2026.md`) encontró contradicciones de documentación y deuda de infraestructura. Remediación organizada en 3 bloques, en la rama `correcciones` (nunca mergeada a `main`/`efadam` sin instrucción explícita — ver `plan_de_accion_completo.md` para la política completa de ramas):

- **Bloque 0 (infraestructura) — completo.** Workflows de n8n exportados, backup de Postgres probado, `.gitattributes`, secrets movidos a `.env`, timezone explícito.
- **Bloque 1 (contradicciones de documentación) — completo.** Las 5 contradicciones de "fuente de verdad" corregidas y los duplicados del Claude Project limpiados (17/ago).
- **Bloque 2 (OmniRoute/n8n en vivo) — infraestructura arreglada y verificada; bloqueado en que ningún proveedor rutea tráfico real todavía.** Los 4 problemas de infraestructura (volumen mal montado, faltaban `JWT_SECRET`/`API_KEY_SECRET`, sin contraseña de dashboard, cero proveedores) están resueltos: `docker-compose.yml` corregido y verificado (el volumen ahora sí persiste), contraseña del dashboard generada por Claude y fijada (en `.env`, gitignored), 4 combos creados (`bajo`/`medio`/`alto`/`critico`). **Cloudflare AI se descartó** (decisión de Mateo). **Pollinations resultó no ser realmente "sin auth" para uso real** — la conexión se creó pero los 3 modelos probados devuelven 401 "API key required" (`enter.pollinations.ai/keys`, no confirmado si es gratis o de pago) — corrección a la evaluación anterior, que solo había verificado el código, no una llamada real. **Qwen — Mateo autorizó proceder, pero el último paso (loguearse en `chat.qwen.ai` y extraer un token de sesión real desde DevTools) solo lo puede hacer él** — no es algo que se pueda generar o adivinar. Resultado: **los 4 combos existen pero hoy no rutean nada real** — sigue pendiente que al menos un proveedor funcione de verdad. Ver `plan_de_accion_completo.md`, actualización del 17 de agosto, noche, segunda ronda, para el detalle completo.
- **Bloque 3 (activar Efadam) — no empezado**, depende de que cierre Bloque 2. Además, la auditoría técnica y de visión del 17 de agosto (`auditoria_tecnica_y_vision_17ago2026.md`) encontró 3 hallazgos críticos que hoy no están cubiertos por la secuencia de Bloque 2 y se agregaron antes de este punto: contraseña de Postgres expuesta en el historial de git (sin rotar), inyección SQL en el nodo "Obtener config del bot", y un flujo de aprobación humana que hoy es solo una notificación saliente sin ruta de respuesta. Ver `plan_de_accion_completo.md`, "Pendientes de Bloque 2, en secuencia", para el detalle.

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
