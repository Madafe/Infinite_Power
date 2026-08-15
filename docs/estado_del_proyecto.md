# Estado del proyecto — Infinite Power

> Actualizado: 14 de agosto de 2026. Este archivo es para humanos: estado real,
> decisiones y por qué. **No se inyecta a ningún bot.** Lo que los bots leen son
> los archivos cortos de `docs/context/`, sincronizados a `system_knowledge`.

## Qué es

Sistema de agentes de IA para gestionar y hacer crecer negocios de forma cada vez más autónoma, con la menor intervención humana posible. Nace de una pizarra en ClickUp (whiteboard "Infinite power"). Ver [[Infinite power]] para la visión y el Método.

## Quién lo construye

- **Mateo** — fundador, Claude Pro, $150 MXN para una API de pago.
- **Su amigo** — cofundador, API de Gemini con $200 MXN de saldo. **Todavía no es colaborador del repo** — pendiente desde el Paso 0.

## Arquitectura

Efadam en el centro + 3 ramas, cada una con su bot "center" que consolida, audita y aprueba antes de reportar a Efadam. Narrativa completa en [[arquitectura_general]]; versión corta que leen los bots en [[arquitectura]].

```
                        EFADAM
                 (interfaz central con el usuario)
                          |
        -----------------|-----------------
        |                |                |
   Tech center   Upgrade & review    Proyect center
```

## Orden de construcción (confirmado por Mateo, 14/ago noche)

**Dev/Tech → Estrategia/Crecimiento → Operación/Proyectos.** Legal y el resto de Negocios propios quedan pospuestos sin fecha — no hay necesidad de negocio hoy, se retoman cuando la haya. La versión anterior traía a Legal como siguiente paso porque el plan original del 7/ago lo eligió como candidato de bajo riesgo para probar el patrón — no por prioridad real de negocio. Corregido.

## Estado real (no lo planeado — lo que existe)

### Infraestructura — Paso 0 completo ✅

n8n + Postgres 16 + OmniRoute en Docker, en `C:\Users\2\Documents\infinite-power`. Bot de Telegram creado y probado. Repo privado `github.com/Madafe/Infinite_Power`.

### Ejecutor genérico — probado ✅ (19 nodos)

Un solo workflow que corre a cualquier bot leyendo su fila de `bots`. Incluye, funcionando: contexto de linaje (le dice al bot quién le asignó la tarea y a partir de qué), sistema de aclaración completo con reanudación bot-a-bot, y manejo de errores. Ver [[ejecutor_generico]].

### Bots realmente activos: 3

`tecnico_jefe`, `coder`, `trouble_shooter`. **Todo lo demás existe solo como archivo `.md`.** Un bot que no está en `bots` con `active = true` no existe para el sistema.

### Prompts escritos (no activos)

Rama Dev/Tech: Prompt perfection, Entrenador Agentes, Agent builder, Ciber seguridad scouter, Hacker ético, Ciber seguridad, Tech center. Efadam (cross-rama, en `prompts/_core/`).
Pospuestos con criterio explícito: Consultor de arquitectura, Trouble scouter.

Ramas Upgrade & review center y Proyect center: **cero prompts escritos**.

## Decisiones de arquitectura técnica

- **Orquestador:** n8n self-hosted (Docker).
- **Memoria/estado:** Postgres self-hosted (Docker).
- **Router de modelos:** OmniRoute self-hosted (90+ proveedores, fallback de 4 niveles).
- **Infraestructura:** todo local. VPS + dominio después.
- **Aprobaciones humanas:** bot de Telegram. Checkpoints obligatorios en gasto, publicación, temas legales, seguridad, y acciones fuera del sandbox de un bot con autonomía ampliada.
- **Presupuesto pagado:** reservado para Council, Abogado Jefe, Consultor de negocios, Ciberseguridad, Hacker ético, Out of the box thinker. **Efadam NO** — es el bot de mayor frecuencia.
- **Convención de código:** Ponytail, modo `lean`/`robusto` decidido por Técnico jefe.
- **Andamiaje:** GitHub Spec Kit para tareas de varios pasos.

### Memoria del sistema (definida 14/ago)

Dos tablas: `system_knowledge` (autoconciencia, sincronizada desde `docs/context/*.md` — el repo es la fuente de verdad, no la BD) y `knowledge_log` (bitácora). **Efadam es dueño por default de `knowledge_log`**; la única excepción es angosta y explícita por bot (`bots.conocimiento_directo`, hoy solo `trouble_shooter`). Diseño completo en [[memoria_del_sistema]].

Las reglas generales viajan dentro del `system_prompt`, compuestas por un trigger a partir de `bots.prompt_especifico`. **A partir de ahora nunca se escribe `system_prompt` a mano.**

## Plan de fases

| Fase | Estado |
|---|---|
| 0 — Infraestructura local | ✅ completo |
| 1 — Prompts de cada bot | 🟡 Dev/Tech escrita; sigue Estrategia/Crecimiento |
| 2 — Rebanada vertical | ✅ **satisfecha por Dev/Tech** — Técnico jefe → Coder probado de punta a punta |
| 3 — Orquestación multi-rama | ⬜ empieza al extender a Estrategia/Crecimiento |
| 4 — Monitoreo y costos | ⬜ (`agent_runs` no se llena todavía) |
| 5 — Autonomía progresiva | ⬜ |
| 6 — Auto-expansión | ⬜ |

**Riesgo vigente:** el proyecto lleva días construyendo el sistema que construye el sistema. El criterio de "suficiente" para la plomería: escribir y activar solo los bots de Estrategia/Crecimiento que de verdad usarías esta semana, no los 10 del roster de golpe.

## Deuda documentada

- **`roster_agentes_v4.xlsx` desactualizado.** Sigue organizado por los 6 clusters planos originales, lista "Upgrade & review center" dentro de Dev/Tech, dice que Tech center entrega a Upgrade & review center (entrega a Efadam), usa "Project center", y no incluye a Consultor de arquitectura ni Trouble scouter.
- **Nombre del departamento de la rama 2.** [[arquitectura_general]] la llama "Estrategia + Legal + Investigación"; [[Upgrade & Review center]] la llama "departamento de Investigación" pero le cuelga estrategia y legal.
- **TalentIA / Bintix / negocios propios** sin confirmar si cuelgan de Proyect center o son su propia agrupación.
- **Sistema de Revert** diseñado en [[Infinite power]] (git + `archived_at`/`archived_reason` + tabla `reverts`) pero **nada construido** en el schema.
- **Multiproyecto:** pendiente confirmar que ningún workflow de n8n tiene el schema de Postgres hardcodeado.

## Pendientes abiertos de diseño

- Herramienta de pentesting concreta del Hacker ético.
- Tamaño exacto del presupuesto propio de Out of the box thinker.
- Cadencia exacta (Schedule Trigger) por rama.
- Agregar al amigo como colaborador del repo.
- Backups automáticos de Postgres.
