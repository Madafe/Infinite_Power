# Estado del proyecto — Infinite Power

> Actualizado: 17 de agosto de 2026. Este archivo es para humanos: estado real,
> decisiones y por qué. **No se inyecta a ningún bot.** Lo que los bots leen son
> los archivos cortos de `docs/context/`, poblados una sola vez (seed) desde
> este repo al arrancar el sistema — después del seed, `system_knowledge` (la
> tabla) es la fuente de verdad viva, y este repo puede quedar desactualizado
> respecto a ella (ver `memoria_del_sistema.md`, sección "Repo como seed, no
> como fuente de verdad").

## Qué es

Sistema de agentes de IA para gestionar y hacer crecer negocios de forma cada vez más autónoma, con la menor intervención humana posible. Nace de una pizarra en ClickUp (whiteboard "Infinite power"). Visión y Método fusionados en `docs/archivo/plan_de_accion_completo.md` (la nota suelta original se eliminó el 15/ago).

## Quién lo construye

- **Mateo** — fundador, Claude Pro, $150 MXN para una API de pago.
- **Su amigo** — cofundador, API de Gemini con $200 MXN de saldo. **Todavía no es colaborador del repo** — sigue pendiente.

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
- **Bloque 1 (contradicciones de documentación) — en progreso.** 5 de los lugares con "fuente de verdad" contradictoria corregidos (este archivo incluido); pendiente limpiar duplicados en el Claude Project.
- **Bloque 2 (OmniRoute/n8n en vivo)** y **Bloque 3 (activar Efadam)** — no empezados; requieren acceso real a Docker/Postgres/n8n, actualmente bloqueado por una limitación del entorno remoto (ver `plan_de_accion_completo.md`, actualización del 16 de agosto, tarde/noche, para el detalle).

Ver `plan_de_accion_completo.md` para el estado completo y actualizado de cada bloque — esta sección es un resumen, no la fuente de detalle.

## Deuda documentada

- **`roster_agentes_v4.xlsx` desactualizado, y confirmado que no está en el repo.** Sigue organizado por los 6 clusters planos originales, lista "Upgrade & review center" dentro de Dev/Tech, dice que Tech center entrega a Upgrade & review center (entrega a Efadam), usa "Project center", y no incluye a Consultor de arquitectura ni Trouble scouter. Búsqueda completa en el vault (17/ago) confirma que **no existe en ningún lado de `C:\Users\2\Documents` ni está commiteado** — el único lugar donde vive es como archivo subido directo al Claude Project. Pendiente decidir: actualizarlo y subirlo al repo, subirlo tal cual con nota de que está desactualizado, o descartarlo y dejar que `arquitectura.md` sea la única fuente del roster.
- **Licencia de n8n — riesgo real para el plan de distribución, sin resolver.** n8n corre bajo la Sustainable Use License (fair-code, no OSI): uso gratuito solo para "fines de negocio internos" propios, y solo se puede distribuir "de forma gratuita, para fines no comerciales". Si "Infinite Power" se llega a vender empaquetado con n8n embebido en el instalador, eso probablemente cruza la línea de "distribuir el software" en un contexto comercial. La forma más segura: que cada cliente descargue su propio n8n Community (gratis) para su propio uso interno, en vez de que el instalador lo redistribuya embebido. OmniRoute (MIT) no tiene este problema. No resuelto — requiere revisión legal antes de vender la primera instalación. Ver fuentes en la conversación del 17 de agosto.
- **Nombre del departamento de la rama 2.** [[arquitectura_general]] la llama "Estrategia + Legal + Investigación"; [[Upgrade & Review center]] la llama "departamento de Investigación" pero le cuelga estrategia y legal.
- **TalentIA / Bintix / negocios propios** sin confirmar si cuelgan de Proyect center o son su propia agrupación.
- **Sistema de Revert** diseñado (git + `archived_at`/`archived_reason` + tabla `reverts`) pero **nada construido** en el schema.
- **Multiproyecto:** pendiente confirmar que ningún workflow de n8n tiene el schema de Postgres hardcodeado.

## Pendientes abiertos de diseño

- Herramienta de pentesting concreta del Hacker ético.
- Tamaño exacto del presupuesto propio de Out of the box thinker.
- Cadencia exacta (Schedule Trigger) por rama.
- Agregar al amigo como colaborador del repo.
- ~~Confirmar esquema exacto de creación de combos en OmniRoute~~ — hecho el 17/ago. Falta configurar los 4 niveles, bloqueado por 4 hallazgos de infraestructura sin resolver (ver `plan_de_accion_completo.md`, actualización del 17 de agosto): volumen `/app/config`→`/app/data` mal montado (nada persiste), faltan `JWT_SECRET`/`API_KEY_SECRET`, password del dashboard sigue en default (`CHANGEME`), y cero proveedores de modelos conectados (necesita que Mateo confirme qué llave(s) usar primero).
