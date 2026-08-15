> **ARCHIVADO — 14 de agosto de 2026.** Versión v5 (antecesora directa), 100%
> superada por [[estado_del_proyecto]]. Se conserva por trazabilidad.

---

# Contexto del proyecto — "Infinite Power"

## Qué es

Sistema de agentes de IA para gestionar y hacer crecer negocios de forma cada vez más autónoma, con la menor intervención humana posible, cubriendo la mayor cantidad de áreas del negocio. Nace de una pizarra/diagrama en ClickUp (whiteboard "Infinite power").

## Quién lo construye

- **Mateo** — fundador, Claude Pro (tiempo incierto), $150 MXN para una API de pago.
- **Su amigo** — cofundador, API de Gemini con $200 MXN de saldo.
- Ambos tienen: opencode instalado, Codex, y acceso a varias APIs gratis (Gemini, Groq, y otras vía OmniRoute).
- Tienen un dominio propio disponible para hostear infraestructura más adelante (no se usa en la etapa local actual).

## Arquitectura general (corregida) — ver `arquitectura_general.md` para el detalle completo

El sistema NO es una lista plana de clusters independientes. Es **Efadam en el centro + 3 ramas**, cada una con su propio bot "center" que consolida y aprueba todo lo que pasa en su rama antes de reportar a Efadam:

```
                        EFADAM
                 (interfaz central con el usuario)
                          |
        -----------------|-----------------
        |                |                |
   Tech center   Upgrade & review    Proyect center
   (rama Dev/Tech)  center (rama       (rama Operación/
                   Estrategia+Legal+    Proyectos +
                   Investigación)       negocios propios)
```

- **Efadam** — el "Jarvis" del sistema. Único punto de contacto conversacional con el usuario (Telegram por ahora, app con front end propio después). No ejecuta trabajo, enruta peticiones al hub correcto y resume estado. No se salta las aprobaciones que ya tiene cada rama.
- **Tech center** — hub de la rama Dev/Tech (12 bots: Prompt perfection, Entrenador Agentes, Coder, Agent builder, Trouble shooter, Ciber seguridad scouter, Hacker ético, Ciber seguridad, Técnico jefe, Tech center). Absorbe también el rol de aprobación final antes de producción (fusión aplicada — ver nota de corrección abajo).
- **Upgrade & review center** — hub de la rama Estrategia/Crecimiento + Legal + Investigación (~17 bots): Establecer metas, Planner, Nuevos departamentos, Especialista en organización y métodos, Buscador de áreas de oportunidad, Out of the box thinker, Optimizador, Council, Cross department (agregador interno de esta rama), Automatizador, Investigador, Skill finder x2, Observador de patrones replicables, Abogado Scouter, Abogado Jefe, Abogado verificador.
- **Proyect center** — hub de la rama Operación/Proyectos (Proyectos, Tracker de clientes, Front end, Consultor negocios, Task manager, Ventas ideas, Expansión ideas, Mentor, Establecer Metas y Planner como nodos compartidos con la rama 2 — **corregido después: son duplicados, no compartidos, ver [[Proyect center]]**). Probablemente incluye también los negocios propios (TalentIA, Bintix, Back end/Front end páginas web, Consultor SEO) — sin confirmar todavía.

El roster completo con objetivo/input/output/modelo/autonomía de cada bot vive en `roster_agentes_v3.xlsx` (pendiente reorganizar visualmente por rama, el contenido ya es válido).

### Corrección aplicada (primer uso del mandato de diseño)

Los prompts de Dev/Tech ya escritos tenían un bot "Upgrade & review center" mal ubicado (ese nombre pertenece al hub de la rama 2, no a Dev/Tech). Se fusionó esa responsabilidad de aprobación final en **Tech center**, y se borró el archivo mal ubicado. Detalle completo en `arquitectura_general.md`.

### Mandato de diseño (vigente para todo el proyecto)

Mateo autorizó explícitamente que, durante la construcción, se proponga un bot nuevo si se detecta un hueco funcional, se divida un bot existente en varios más específicos si mejora el rendimiento, o se fusionen responsabilidades para evitar redundancia — sin pedir permiso cada vez. Condición: todo cambio de este tipo se documenta (roster + `arquitectura_general.md`), explicando el porqué.

### Nota sobre el cluster de ciberseguridad (dentro de Tech center)

**Hacker ético**: pentesting interno con reglas no-negociables — alcance autorizado explícito (nunca lo decide él mismo), pruebas activas solo en staging con aprobación previa por Telegram, nunca prueba infraestructura de terceros, todo registrado en `agent_runs`.

### Nota sobre "Out of the box thinker" (dentro de la rama Upgrade & review center)

Bot con más autonomía del sistema por diseño. Autonomía total sobre sí mismo (prompt auto-modificable versionado en git, presupuesto propio acotado — si se rompe o se agota, se revierte/reinicia sin drama); aprobación humana obligatoria solo para lo que sale de su sandbox.

## Decisiones de arquitectura técnica ya tomadas

- **Orquestador:** n8n, self-hosted vía Docker.
- **Memoria/estado compartido:** Postgres self-hosted vía Docker.
- **Router de modelos:** OmniRoute self-hosted vía Docker.
- **Infraestructura:** todo en local primero (n8n + Postgres + OmniRoute + Telegram en la máquina de Mateo). VPS + dominio se agregan después, cuando la Fase 2 esté probada.
- **Aprobaciones humanas:** bot de Telegram — checkpoints obligatorios en gasto, publicación, temas legales, seguridad, o acciones fuera del sandbox de un bot con autonomía ampliada. Cada uno de los 3 "center" es, además, el gate de aprobación final de su propia rama.
- **Código y prompts:** repo de GitHub — `https://github.com/Madafe/Infinite_Power` (privado, ya creado, con el primer commit).
- **Presupuesto pagado:** reservado para los bots de mayor razonamiento/riesgo (Council, Abogado Jefe, Consultor de negocios, Ciberseguridad, Hacker ético, Out of the box thinker, Efadam); el resto corre en capas gratis.
- **Andamiaje de desarrollo asistido por agentes de código:** GitHub Spec Kit (para tareas de varios pasos dentro de Tech center).
- **Convención de código:** Ponytail — Técnico jefe decide por tarea el modo "lean" o "robusto" (campo `input` jsonb en la tabla `tasks`).

## Infraestructura local — estado: Paso 0 completo ✅

- n8n corriendo en Docker sobre Postgres (`localhost:5678`).
- Postgres conectado.
- OmniRoute funcionando (`localhost:20128`, probado con 200 OK).
- Repo de GitHub creado, primer commit hecho, estructura de carpetas lista.
- Bot de Telegram creado, credencial conectada en n8n, probado enviando mensajes.
- Todo corre en `C:\Users\2\Documents\infinite-power`.
- Pendiente: VPS + dominio (después de Fase 2), backups automáticos, agregar al amigo como colaborador del repo.

## Plan de fases (resumen)

0. **Infraestructura local — COMPLETO ✅**
1. **Definir instrucciones de cada bot — EN PROGRESO.** Organizado por rama, no por los 6 clusters planos originales. Rama Tech center: **12 prompts escritos** (Efadam, Técnico jefe, Coder, Agent builder, Trouble shooter, Ciber seguridad scouter, Hacker ético, Ciber seguridad, Tech center, Prompt perfection, Entrenador Agentes; el archivo "upgrade-review-center" de esta carpeta se descartó, no aplica). Faltan las ramas Upgrade & review center y Proyect center.
2. **Rebanada vertical** — loop completo de punta a punta empezando por el sub-cluster Legal (dentro de la rama Upgrade & review center). — **corregido después: satisfecha por Dev/Tech, ver [[estado_del_proyecto]]**
3. **Orquestación multi-rama** — vía tabla `tasks` en Postgres.
4. **Monitoreo y costos.**
5. **Autonomía progresiva** — rama por rama, tras 2 semanas sin errores.
6. **Auto-expansión** — Council propone, humano aprueba y activa.

## Pendientes/dudas abiertas

- Confirmar si TalentIA/Bintix/negocios propios cuelgan de Proyect center o son su propia agrupación.
- Definir la herramienta de pentesting concreta del Hacker ético.
- Definir el tamaño exacto del presupuesto propio de Out of the box thinker.
- Reorganizar `roster_agentes_v3.xlsx` visualmente por rama (contenido ya válido, falta la columna/agrupación).
- Agregar al amigo como colaborador del repo de GitHub.
- Escribir los prompts de las ramas Upgrade & review center y Proyect center.

## Archivos de referencia de este proyecto

- `arquitectura_general.md` — la estructura completa de las 3 ramas + Efadam, con el mandato de diseño documentado.
- `plan_de_accion_completo.md` — plan paso a paso (infra + fases).
- `roster_agentes_v3.xlsx` — hoja con los ~43 bots.
- `caso_prueba_1_cluster_investigacion.md` — caso de prueba real, aplicable a la rama Upgrade & review center.
- `prompts_dev_tech/` — los 11 prompts vigentes de la rama Tech center (Efadam incluido, aunque su ubicación real en el repo es `prompts/_core/`, no `prompts/dev-tech/`).
- Repo de GitHub: `https://github.com/Madafe/Infinite_Power`.
