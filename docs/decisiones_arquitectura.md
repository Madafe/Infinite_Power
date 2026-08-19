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
