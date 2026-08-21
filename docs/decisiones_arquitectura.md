# Decisiones de arquitectura

## 19 de agosto de 2026 — Ejecución y aprendizaje asíncrono por operación

Cada operación abierta por Efadam se separa en dos responsabilidades
independientes:

1. **Tarea concreta.** Es la ruta crítica de la operación: ejecuta el trabajo
   solicitado, conserva el `operation_id`, actualiza su estado y produce el
   entregable o la aclaración que necesita el usuario.
2. **Síntesis de aprendizaje.** Se dispara de manera asíncrona al terminar o
   alcanzar un hito de la tarea concreta. Consolida evidencia, resultados,
   decisiones, errores y patrones en una propuesta de aprendizaje vinculada
   al mismo `operation_id`.

Efadam debe poder confirmar al usuario que la operación fue registrada y que
la tarea fue despachada sin esperar a que termine la síntesis. La síntesis no
puede retrasar, modificar ni bloquear la respuesta inmediata ni la ejecución
de la tarea concreta.

La síntesis trabaja de forma aislada: no escribe directamente en
`knowledge_log`, no cambia `system_knowledge` y no abre tareas de ejecución.
Su salida es una propuesta con evidencia y trazabilidad. Cuando corresponde
convertirla en conocimiento compartido, conserva el gobierno actual:
Upgrade & review center redacta y evalúa; Efadam inserta el resultado
aprobado.

Flujo esperado:

`solicitud → Efadam abre operación + recomienda al center → confirmación al cliente`

`cierre o hito de tarea concreta → síntesis asíncrona → propuesta revisable → aprobación → memoria compartida`

Esto mantiene baja latencia de respuesta y evita que el registro de
aprendizajes se convierta en un punto bloqueante de la operación.

## 20 de agosto de 2026 — Efadam como enlace cliente ↔ especialistas

Efadam recibe exclusivamente por Jarvis mensajes, fotos, archivos y
documentos de oficina. Razona sobre la intención del cliente y conserva el
contexto de la operación, pero no entrega órdenes directas a los especialistas
ni expone la arquitectura interna al cliente.

Para cada solicitud, Efadam envía una recomendación al center adecuado con la
leyenda obligatoria: **"Estas son recomendaciones, no órdenes directas del
cliente"**. El center decide cómo proceder y despacha las tareas de su propio
departamento.

Las dudas se resuelven primero entre Efadam y los centers. Solo se consulta al
cliente cuando puede aportar la respuesta; la pregunta se formula sobre su
objetivo, prioridad o preferencia, nunca sobre el funcionamiento del sistema.
Las respuestas de seguimiento se expresan como un asistente que consulta a su
equipo de especialistas, sin mencionar bots, clusters, tareas, modelos ni
tablas.

## 20 de agosto de 2026 — Esfuerzo por complejidad y preferencia de servicio

El esfuerzo ya no se determina principalmente por el riesgo o el
departamento. Primero mide la complejidad de la tarea; después elige si el
cliente necesita velocidad, equilibrio o máximo rendimiento. Riesgo, datos
sensibles, gasto, publicación y contratos conservan sus gates de aprobación,
pero no convierten por sí solos una tarea sencilla en `critico`.

Cada tarea concreta recibe su propio esfuerzo. El esfuerzo de la operación es
solo la recomendación inicial y no obliga a que todas sus tareas hijas usen el
mismo modelo. Efadam devuelve al cliente el esfuerzo elegido junto con la
confirmación de que está trabajando en la solicitud, sin exponer el modelo ni
el mecanismo interno.

## 20 de agosto de 2026 — Esfuerzo visible y ajustable por operación

La interfaz debe listar las operaciones activas con título, estado, esfuerzo
vigente, recomendación inicial y última actualización. El usuario puede cambiar
el esfuerzo y, opcionalmente, explicar el motivo. El cambio se registra en un
historial auditable; conserva el valor recomendado y solo orienta trabajo
pendiente o nuevo. Nunca altera una tarea que ya se esté ejecutando.
La interfaz lee `operaciones_activas` y aplica los cambios mediante
`ajustar_esfuerzo_operacion`, para que la bitácora no dependa de la pantalla.

## 20 de agosto de 2026 — Gobernanza de auto-expansión de bots (ficha + ciclo)

A partir de una propuesta de Mateo (originada en una conversación con
ChatGPT), se formalizó el ciclo completo de la Fase 8 ("Auto-expansión") que
el Paso 6.2 de `plan_de_accion_completo.md` solo cubría parcialmente.
Detalle completo y plantilla de ficha en `gobernanza_auto_expansion_bots.md`.

Decisiones concretas:

1. **Quién propone un bot nuevo no es Efadam** — es Council/Planner/Nuevos
   departamentos (departamento Estrategia), que ya tenían ese rol asignado
   en la arquitectura. Efadam solo señala patrones/huecos que observa por su
   visibilidad cruzada de `tasks`/`agent_runs`, nunca redacta la propuesta —
   mismo principio que ya rige para `system_knowledge` (Efadam solicita,
   Upgrade & review center redacta, Efadam inserta).
2. Se agrega un paso de **validación por el center del departamento
   destino** entre la propuesta y el ensamblado por Agent builder — no
   existía explícito en el Paso 6.2 original.
3. Se agrega una etapa de **prueba aislada** (volumen mínimo de tareas
   reales, no tiempo calendario — mismo criterio que
   `autonomia_progresiva.md`) entre la activación en modo desactivado y la
   graduación a "activo pleno".
4. Se agrega **condición de salida explícita** (mantener / fusionar /
   retirar) como parte obligatoria de la ficha de cada bot propuesto — antes
   solo existía el corolario general de "posponer o desactivar un bot que no
   aporta" (`arquitectura_general.md`), sin estar atado a cada bot desde su
   creación.
5. Un bot propuesto que no cabe en ninguno de los 3 departamentos existentes
   deja de ser "un bot" y se convierte en "un departamento nuevo" — ese caso
   siempre sube directo a Mateo, ningún center puede autoaprobarlo.

**Estado: diseño completo, construcción sin empezar.** Sigue el orden
vigente — va después de Efadam, los 3 centers, y autonomía progresiva. Ver
"Pendiente" en `gobernanza_auto_expansion_bots.md`.

## 20 de agosto de 2026 — Cierre de detalles para insertar a Efadam

Tres respuestas de Mateo sobre `prompts/_core/efadam.md`, ya aplicadas:

1. **Aviso "Pendiente, 18/ago, cuarta ronda" sobre el prompt de sistema:**
   confirmado que ya no existe en el archivo — Mateo lo borró al reescribir
   el bloque él mismo. No hizo falta ninguna edición.
2. **Cluster de Efadam:** propio, `Efadam` — no el genérico `core` que se
   había propuesto. Nota de convención: el único valor de `cluster` que
   existe hoy en la tabla `bots` es `tech-center` (minúsculas, guion); el
   valor `Efadam` rompe esa convención de casing a propósito, porque Mateo
   lo pidió así explícitamente y Efadam no es un bot de un departamento —
   ya está documentado como cross-cluster.
3. **Esfuerzo fijo de Efadam: `bajo`, permanente, sin la excepción de
   `medio` para síntesis que tenía la versión anterior del documento.**
   Razón de Mateo: el único trabajo de Efadam es enrutar; si en la práctica
   `bajo` no alcanza para responder "¿cómo va todo?", la solución es
   proponer un bot aparte para esa función, no romper el principio subiendo
   el esfuerzo fijo de Efadam. Aplicado en `efadam.md`, sección "Modelo
   sugerido".

**Hallazgo al revisar antes de insertar — migración de esfuerzo lista pero
sin aplicar.** `schema/009_renombrar_esfuerzo.sql` (escrito hoy por Mateo)
renombra `tasks.nivel_importancia`→`esfuerzo`, `operations.nivel_importancia`
→`esfuerzo`, y `bot_niveles_fijos`→`bot_esfuerzos_fijos`
(`nivel_fijo`→`esfuerzo_fijo` + columna `razon`), además de añadir
`esfuerzo_recomendado`/`operation_effort_adjustments`/
`ajustar_esfuerzo_operacion()`/vista `operaciones_activas` para la interfaz
de ajuste manual (ver entrada "Esfuerzo visible y ajustable por operación"
arriba). Es idempotente y no toca datos existentes. **Se verificó en vivo
que la base de datos todavía tiene los nombres viejos** (`\d bots`,
`\d tasks`, `\d operations` — sin aplicar). El intento de correrla desde
esta sesión vía Desktop Commander fue bloqueado por el clasificador de modo
automático (cambios de esquema en la base de producción requieren
confirmación explícita) — queda pendiente que Mateo la corra
(`docker cp` + `psql -f`, misma convención de siempre) o autorice
explícitamente cómo proceder. Como son puros `RENAME`, el orden entre
correr la migración e insertar a Efadam no arriesga datos: una fila
insertada hoy con los nombres viejos sobrevive intacta al renombrar.

**Aplicado (21/ago):** Mateo autorizó explícitamente correr la migración
desde esta sesión — corrida contra producción, verificada en vivo
(`tasks.esfuerzo`, `operations.esfuerzo`, `bot_esfuerzos_fijos.esfuerzo_fijo`,
fila de Efadam intacta). Todo commiteado y pusheado a `correcciones`
(commit `7926105`).

**Corrección el mismo día: `dispatches_tasks` de Efadam.** Se había puesto
`false` con el razonamiento de que "Herramientas que puede usar" en
`efadam.md` no listaba escritura en `tasks`. Mateo corrigió: si Efadam no
despacha ninguna tarea, los centers no tienen forma mecánica de enterarse
de la recomendación (`ejecutor_generico` solo levanta trabajo desde
`tasks`, vía "Reclamar tarea pendiente"). Se corrigió a `dispatches_tasks =
true`, con una restricción explícita que no aplica a los demás bots que
despachan: el único destino válido de la tarea que Efadam crea es el bot
`center` del departamento (nunca un especialista) — esa tarea es la
recomendación misma. Aplicado en `bots` y documentado en `efadam.md`,
sección "Herramientas que puede usar".

## 21 de agosto de 2026 — Pendientes y "qué sigue" se mueven de Obsidian a ClickUp

Decisión de Mateo: Obsidian deja de ser un tracker de pendientes activos.
Se eliminaron de este vault los checklists que funcionaban como lista viva
de tareas — el checklist maestro numerado (45 puntos) y la tabla "Orden de
construcción vigente" de `plan_de_accion_completo.md`, "Deuda documentada"
y "Pendientes abiertos de diseño" de `estado_del_proyecto.md`, y el
checklist de `gobernanza_auto_expansion_bots.md` — y se migró su contenido
a tareas reales en ClickUp (board **Infinite Power**, `901411740278`),
verificando primero que cada ítem abierto ya tuviera su tarea (la mayoría
ya existían de rondas anteriores; se creó una nueva — "Definir herramienta
de pentesting concreta del Hacker ético" — y se actualizaron descripciones
y estados de varias existentes para reflejar el progreso real).

**Lo que NO se tocó:** la bitácora histórica de decisiones y construcción
(las actualizaciones fechadas de `plan_de_accion_completo.md`, y la
narrativa de estado/arquitectura de `estado_del_proyecto.md`) — eso sigue
siendo trazabilidad, no un tracker vivo, y se conserva completo. Regla de
ahora en adelante: **ClickUp es la fuente de verdad de qué falta hacer;
Obsidian narra qué se decidió y por qué, no qué sigue pendiente.**
