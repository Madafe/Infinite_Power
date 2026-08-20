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

`solicitud → Efadam abre operación + despacha tarea concreta → confirmación al usuario`

`cierre o hito de tarea concreta → síntesis asíncrona → propuesta revisable → aprobación → memoria compartida`

Esto mantiene baja latencia de respuesta y evita que el registro de
aprendizajes se convierta en un punto bloqueante de la operación.

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
