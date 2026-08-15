# Plan de acción completo — "Infinite power"
### Sistema de agentes autogestionado para el negocio

Para: Mateo + amigo · 7 de agosto de 2026

---

## Actualización — 15 de agosto de 2026, noche, segunda ronda (corrección: Efadam asigna el nivel, no cada bot) — VIGENTE, léase primero

Corrige un error de la actualización inmediata de abajo: decía "cada bot
declara su nivel de importancia", lo cual contradice el resto del diseño de
Efadam (un bot individual no tiene visión de negocio para juzgar su propia
importancia; esa visión es justamente lo que hace Efadam). Corregido: es
**Efadam** quien asigna el `nivel_importancia` de cada tarea al despacharla
— el bot destino lo hereda, no lo decide. Detalle en `efadam.md` y
`stack_y_convenciones.md`.

**Pendiente de diseño, sin resolver:** Efadam corre en nivel `bajo` (modelo
barato) para no agotar presupuesto en ruteo, pero es él quien tiene que
juzgar si una tarea amerita `alto`/`crítico` — un modelo barato clasificando
qué tan importante es algo es un riesgo real. Falta decidir si esa
clasificación queda a criterio libre de Efadam caso por caso, o si se fija
con reglas explícitas por tipo de tarea/cluster que Efadam solo aplica. Ver
`stack_y_convenciones.md` para el detalle completo.

---

## Actualización — 15 de agosto de 2026, noche (niveles de importancia + BYOK + empaquetado de OmniRoute/n8n) — VIGENTE, léase primero

Se rediseña de fondo cómo el sistema decide qué modelo usa cada bot, y cómo
se distribuye OmniRoute como parte del producto. Detalle completo en
`stack_y_convenciones.md`, sección "Niveles de importancia y BYOK":

- 4 niveles fijos del sistema (`bajo`, `medio`, `alto`, `crítico`). **Efadam**
  asigna a cada tarea el nivel que le corresponde — ningún bot decide el
  suyo propio, y nunca se declara un modelo específico (ver corrección de
  arriba). OmniRoute es el único que traduce nivel → modelo real.
- OmniRoute (y n8n, con el Ejecutor genérico ya importado) se distribuyen
  empaquetados — mismo `docker-compose.yml` del sistema — con un modelo
  gratis ya asignado por default a cada nivel. El setup deja de requerir
  cablear una llave API por bot a mano.
- En el setup, el usuario ve los 4 niveles con su default gratis y un
  disclaimer recomendando subir de nivel `alto`/`crítico`; puede añadir sus
  propias llaves por nivel en cualquier momento, no es bloqueante.
- Es una característica **por instalación**: cada quien que instale Infinite
  Power tiene su propio OmniRoute con sus propias llaves, no comparte el de
  Mateo.

---

## Actualización — 15 de agosto de 2026, noche (refuerzo de documentación: cuello de botella + `conocimiento_directo`)

Se fusionó al resto de la documentación un mecanismo que vivía aislado en una
nota de visión antigua (`docs/vision/Efadam/Efadam.md`, nunca conectada al
resto del vault): la columna `bots.conocimiento_directo`, única excepción
válida a que todo conocimiento cruzado entre ramas pase por Efadam. Detalle
completo, ya integrado, en `memoria_del_sistema.md` y `efadam.md`. Además se
corrigió en varios documentos el uso de la palabra "estático" al describir
`system_knowledge` — no es inmutable, evoluciona con el tiempo vía Upgrade &
review center; lo que no hace es cambiar mensaje a mensaje.

**Nota explícita, porque es un rasgo diferenciador del proyecto:** el cuello
de botella de Efadam es intencional — la fricción de que todo pase por un
único punto es lo que permite que el sistema aprenda de forma centralizada.
Este principio se repite a propósito en varios documentos
(`arquitectura.md`, `efadam.md`, `memoria_del_sistema.md`), no solo aquí.

---

## Actualización — 15 de agosto de 2026, noche (orden de construcción pasa de horizontal a vertical) — VIGENTE, léase primero

Cambia de raíz cómo se secuencia todo lo que sigue en este documento. Las
Fases 1, 2 y 3 originales (abajo) describían un modelo horizontal: primero
escribir los 40 prompts (Fase 1), después probar una rebanada vertical con
Legal (Fase 2), después replicar a todos los clusters (Fase 3). Ese modelo
queda **reemplazado**, no complementado — se deja como referencia histórica
más abajo, pero ya no es el plan de ejecución.

**Nuevo orden, vertical, un componente completo (construido + probado +
activo) antes de pasar al siguiente:**

1. **Efadam** — primero. Es el destino al que todo lo demás reporta; construir
   una rama completa sin que exista Efadam significa terminarla sin tener a
   dónde mandar el resultado. Se construye y prueba con las ramas todavía
   vacías/parciales — su enrutamiento no depende de que los 40 bots existan.
2. **Tech center** (rama Dev/Tech completa) — ya tiene 10 de 12 bots con
   prompt escrito (ver `arquitectura.md`); falta activarla end-to-end contra
   un Efadam real.
3. **Upgrade & review center** (rama Estrategia/Crecimiento + Legal +
   Investigación completa).
4. **Proyect center** (rama Operación/Proyectos + negocios propios completa).
5. **Jarvis** — al final. Es el endpoint de interacción humana por texto y
   voz — **no es lo mismo que Efadam** (corrección de diseño del 15 de agosto:
   antes se usaban como sinónimos; ver `efadam.md`). No tiene nada útil que
   enrutar ni con qué conversar hasta que Efadam y las 3 ramas ya produzcan
   resultado real. Mientras tanto, Telegram (ya construido en la Fase 0) sigue
   ahí como canal de prueba puntual — sin que se espere usarlo de forma
   funcional/diaria antes de que el bot esté terminado.

**Consecuencia sobre "escribir todos los prompts primero":** ya no aplica
como regla general. Se escribe el prompt de un bot cuando toca construir y
activar el componente al que pertenece, no en bloque adelantado. Los prompts
de Dev/Tech que ya existen se aprovechan tal cual cuando llegue su turno
(paso 2 de la lista de arriba); los de Upgrade & review center y Proyect
center se escriben en su propio paso, no antes.

**Consecuencia sobre el upsert de seed inicial a `system_knowledge`:** se
pospone. No tiene caso poblar la tabla mientras el sistema sigue en
construcción y el contenido de `arquitectura.md`/`stack_y_convenciones.md`/
`reglas_generales.md` puede seguir cambiando — se corre hasta que haya un
producto final real que probar, no ahora (corrige lo que se había anotado
como pendiente inmediato en la actualización anterior del 15 de agosto).

Las Fases 4 (monitoreo/costos), 5 (autonomía progresiva) y 6 (auto-expansión)
originales, abajo, siguen aplicando conceptualmente después de que las 5
piezas de arriba existan — no cambiaron de contenido, solo de orden relativo
(vienen después del recorrido vertical completo, no entrelazadas con "Fase 3
multi-cluster" como estaba antes).

---

## Actualización — 11 de agosto de 2026 (leer antes que el resto del documento)

Dos cosas cambiaron respecto a la versión original de este plan, abajo:

1. **La Fase 0 ya está completa, pero en local, no en VPS.** Se decidió construir y probar todo primero en la máquina de Mateo (n8n + Postgres + OmniRoute + bot de Telegram, todo vía Docker Compose) antes de pagar un servidor y configurar un dominio — el VPS + dominio se agrega hasta que el sistema esté probado y quieran dejarlo corriendo 24/7. Los pasos de VPS/dominio que siguen abajo (0.1 a 0.8) quedan como referencia para cuando llegue ese momento, **no son el siguiente paso ahora**. El repo de GitHub ya existe: `https://github.com/Madafe/Infinite_Power`.

2. **La arquitectura no es una lista plana de 6 clusters — es Efadam en el centro + 3 ramas.** Cada rama tiene su propio bot "center" que consolida y aprueba antes de reportar a Efadam: **Tech center** (rama Dev/Tech), **Upgrade & review center** (rama Estrategia/Crecimiento + Legal + Investigación), **Proyect center** (rama Operación/Proyectos + negocios propios). El detalle completo vive en `arquitectura_general.md`.

**Mandato de diseño vigente:** durante la construcción, Claude tiene autorización para proponer bots nuevos, dividir uno existente en varios más específicos, o fusionar responsabilidades para evitar redundancia, sin pedir permiso cada vez — documentando el cambio en el roster y en `arquitectura_general.md`.

---

## Actualización — 14 de agosto de 2026 (memoria/autoconciencia del sistema) — SUPERSEDIDA por la actualización del 15 de agosto (mañana), abajo

Se definió cómo funciona la "memoria" de los bots. El diseño completo, con el
porqué de cada decisión, vive ahora en **`docs/memoria_del_sistema.md`**; el DDL
en **`schema/002_conocimiento.sql`**. Resumen de lo que quedó (histórico — ver
corrección del 15 de agosto inmediatamente abajo antes de usar esto):

- **`system_knowledge`** — autoconciencia del sistema (arquitectura, stack,
  convenciones, reglas generales). **La fuente de verdad son los archivos
  `docs/context/*.md` del repo, no la tabla**: un workflow de sync los sube. Sin
  eso, la arquitectura quedaría documentada en dos lugares que se contradirían.
- **`knowledge_log`** — bitácora de casos, con columna `tipo`:
  - `patron_fallo` → lo escribe el ejecutor **automáticamente** desde el campo
    `patron_aprendido` de Trouble shooter. Efadam no participa: el dato ya viene
    estructurado, no hay nada que curar, y meterlo en medio agregaba latencia y
    tokens en el bot de mayor frecuencia del sistema (que además corre en modelo
    gratis, o sea el peor juez posible de qué recordar).
  - `aprendizaje` → lo escribe **Efadam**, tras el reporte de un center. Ahí sí
    hace falta criterio y visión de las 3 ramas.
  - Índice único parcial sobre `lower(titulo)` para los patrones: un patrón
    repetido incrementa `veces_visto` en vez de duplicarse.
- **No se inyecta lo mismo a todos los bots.** Columna `bots.contexto_slugs
  text[]`: cada bot declara qué necesita.
- Se descartó que Trouble shooter tenga un banco propio. Un solo mecanismo,
  permisos de escritura distintos por tipo.
- Las **reglas generales** viven dentro del `system_prompt` de cada bot,
  compuestas por un trigger de Postgres a partir de `prompt_especifico`.

Aclaración de roles de los 3 centers (sigue vigente): su función principal es
**retener** (gatekeeping y auditoría activa de su rama), no solo enrutar.

---

## Actualización — 15 de agosto de 2026, mañana (repo pasa a ser seed, no fuente de verdad; Efadam deja de redactar) — VIGENTE

Corrige de fondo dos puntos de la actualización del 14 de agosto de arriba:

**1. `system_knowledge` ya NO se sincroniza desde el repo de forma recurrente.**
El repo (`docs/context/*.md`, `reglas_generales.md`) pasa a ser el **seed
inicial** — se carga una sola vez, a mano, con el mismo upsert que usaba el
workflow, **cuando haya un producto final real que probar** (no ahora). Después
de ese arranque, **la tabla es la fuente de verdad viva**; el repo puede
quedar desactualizado y es esperado, no un bug. El workflow **"Sync
conocimiento del sistema" se borró en n8n** (confirmado) y **el PAT de GitHub
que usaba se revocó** (confirmado, 15 de agosto). Detalle completo del
razonamiento en `memoria_del_sistema.md`.

**2. `aprendizaje` (y ahora también `system_knowledge`) ya NO lo redacta
Efadam.** Efadam sigue siendo el cuello de botella único de entrada, pero
**quien redacta y evalúa el contenido es Upgrade & review center** — es su rol
ya definido ("Observar → Analizar → Mejorar", no aprobar por default) aplicado
también al conocimiento del sistema. Efadam solicita, U&R center produce,
Efadam inserta sin re-auditar el fondo. Corregido en `efadam.md` y
`upgrade-review-center.md`.

---

## Actualización — 14 de agosto de 2026, tarde (secuencia y alcance) — parcialmente histórica

Revisión de la lista de pendientes. Se posponen dos bots ya diseñados:

| Bot | Se activa cuando |
|---|---|
| Consultor de arquitectura | El output de Coder deje de ser leído línea por línea por Mateo antes de mergear |
| Trouble scouter | Haya 12+ bots activos, o 2+ ramas corriendo a diario |

Los prompts ya escritos se quedan en el repo — no se pierde el trabajo. Lo que
se pospone es el `INSERT INTO bots`. El bloque "PROTOCOLO OBLIGATORIO" del
prompt de Técnico jefe **no se carga** en la tabla `bots` mientras
`consultor_arquitectura` no exista activo.

**`tasks_status_check`:** se agrega explícito en `002_conocimiento.sql` con
los 6 estados válidos (`init.sql` nunca creó ese constraint).

---

## Actualización — 14 de agosto de 2026, noche (orden real de construcción) — histórica, ver nota del 15 de agosto arriba

Orden de construcción confirmado ese día (superado por el orden vertical del
15 de agosto, arriba — se deja por trazabilidad): **Dev/Tech → Estrategia/
Crecimiento → Operación/Proyectos.** Legal queda pospuesto sin fecha.

El loop Técnico jefe → Coder, probado de punta a punta con memoria, manejo de
errores y aprobación, sigue siendo la prueba real de que el patrón del
ejecutor genérico funciona.

---

## Orden de construcción vigente y checklist

**Reemplaza el timeline y checklist anteriores, que asumían el modelo
horizontal de Fases 1–3.** Ver actualización del 15 de agosto, noche, arriba
para el razonamiento completo.

| Paso | Qué es | Estado |
|---|---|---|
| 0 — Infraestructura | VPS/local + n8n + Postgres + OmniRoute + Telegram + repo | ✅ Completo en local; VPS pendiente sin fecha; empaquetado de OmniRoute/n8n para distribución pendiente de implementar (diseño ya definido) |
| 1 — Efadam | Cerebro de orquestación central, cuello de botella de entrada a Postgres | ⬜ Siguiente paso |
| 2 — Tech center | Rama Dev/Tech completa y activa end-to-end contra Efadam | 🟡 Prompts casi listos (10/12); falta activar contra Efadam real |
| 3 — Upgrade & review center | Rama Estrategia/Crecimiento + Legal + Investigación completa | ⬜ Prompts pendientes |
| 4 — Proyect center | Rama Operación/Proyectos + negocios propios completa | ⬜ Prompts pendientes |
| 5 — Jarvis | Endpoint de interacción humana (texto + voz), separado de Efadam | ⬜ No empezado — al final |
| 6 — Monitoreo/costos | Resumen diario + alertas de gasto (Fase 4 original) | ⬜ Después del recorrido vertical |
| 7 — Autonomía progresiva | Quitar checkpoints de aprobación cluster por cluster (Fase 5 original) | ⬜ Continuo, después de que cada cluster esté estable |
| 8 — Auto-expansión | "Nuevos departamentos" vía Council (Fase 6 original) | ⬜ Cuando todo lleve 1 mes estable — API key de n8n ya generada y en uso desde el 15 de agosto |

### Pendientes activos (actualizado 15 de agosto de 2026, noche)

1. **Construir Efadam** — es el paso inmediato. Prompt ya escrito en `efadam.md`; falta activarlo en la tabla `bots` (con `contexto_slugs = {arquitectura, stack_y_convenciones}`) y probar su enrutamiento con las 3 ramas todavía vacías/parciales.
2. Activar **Tech center** end-to-end contra el Efadam real.
3. Escribir los prompts completos de **Upgrade & review center** y **Proyect center** (se escriben en su turno, no antes).
4. Escribir el prompt de **Jarvis** — al final, cuando el resto ya produzca contenido real que valga la pena exponer por voz/texto.
5. Construir en n8n la lógica concreta de "Efadam solicita a U&R center, U&R center redacta, Efadam inserta" — hoy solo existe el diseño en prosa (`efadam.md`, `upgrade-review-center.md`).
6. El upsert de seed inicial a `system_knowledge` **se pospone** hasta que haya un producto final que probar — no es un pendiente inmediato.
7. Definir si `knowledge_log`/`system_knowledge` necesitan columna de versión/historial (mejora futura, no implementado).
8. Agregar al amigo/cofundador como colaborador del repo de GitHub (pendiente desde la Fase 0).
9. Activar más bots en la tabla `bots` conforme cada componente vertical lo requiera — hoy solo `tecnico_jefe` y `coder` están activos.
10. Corregir `consultor-de-arquitectura.md` y `trouble-scouter.md`, que aún referencian `project_knowledge`/`trouble_shooter_knowledge` (nombres ya descartados) — corregir antes de activarlos.
11. **Implementar el empaquetado de OmniRoute + n8n para distribución** (diseño ya definido, ver actualización del 15 de agosto, noche, arriba y `stack_y_convenciones.md`): agregar la columna `bots.nivel_importancia` al schema, definir los defaults gratis por nivel dentro de la config de OmniRoute, y diseñar la pantalla/paso de setup donde el usuario ve los 4 niveles y puede añadir sus llaves. No es bloqueante para construir Efadam.
12. Eliminar o resolver la duplicación de la nota `docs/vision/Efadam/Efadam.md` en Obsidian — su contenido ya se fusionó a `memoria_del_sistema.md` y `efadam.md`, pero el archivo original sigue existiendo por separado. Pendiente de que Mateo lo revise antes de borrarlo (solicitud explícita suya).
13. Localizar y leer la referencia "Infinite power.md > Método > Multiproyecto", mencionada en la nota antigua de Efadam como pendiente sobre la cadencia con la que Efadam revisa proyectos activos — no localizada todavía.
14. Decidir qué hacer con dos archivos sueltos sin commitear en el repo local (`schema/_tmp_diag_github.ps1`, `schema/_tmp_inspect_schedule.js`), que parecen debris de una sesión anterior.
15. Decidir cómo Efadam clasifica el nivel de importancia con confiabilidad (corre en modelo barato, pero tiene que juzgar decisiones de alto impacto) — criterio libre vs. reglas explícitas por tipo de tarea/cluster. Ver actualización del 15 de agosto, noche, segunda ronda, arriba.

**Nota 15 de agosto:** la API key de n8n del paso 8 (Auto-expansión) ya existe
y está en uso desde hoy (es la misma que permite conectarse a n8n local desde
una terminal con acceso directo a la máquina — ver `memoria_del_sistema.md`).
El usuario decidió mantenerla activa de forma indefinida en vez de rotarla —
vive fuera de sistemas digitales cuando no está en uso.

**Nota de contenido histórico:** las secciones Fase 0 (infraestructura),
Fase 1 (plantilla de prompts, ahora usada solo para bots nuevos según toque su
turno), Fase 2 (schema de Postgres y patrón del ejecutor genérico) y Fase 3
(mecanismo de conexión vía tabla `tasks`) del documento completo en el Project
de claude.ai siguen teniendo contenido técnico vigente (docker-compose, schema
SQL, plantilla de prompt) — se resumen aquí como referencia rápida; el
documento completo con todo el detalle técnico está en el Project "Infinite
power" de claude.ai.
