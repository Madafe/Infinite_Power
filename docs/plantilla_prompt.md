# Plantilla estándar de prompt de bot

> Extraído de `plan_de_accion_completo.md` (archivado). Es la plantilla que ya
> siguen los 12 prompts en `prompts/dev-tech/` y `prompts/_core/` — se separa
> aquí para que sea fácil de referenciar al definir los del departamento Estrategia.

Cada archivo `prompts/<cluster>/<bot>.md` sigue esta estructura:

```markdown
# [Nombre del bot]

## Rol
(una frase: qué es este bot dentro del sistema)

## Objetivo
(qué tiene que lograr cada vez que corre)

## Input que recibe
(de qué bot o de qué tabla en Postgres saca su información)

## Estado y contrato operativo
(campos que debe conservar y cómo se interpretan: `operation_id`,
`parent_task_id`, adjuntos, estado de la tarea y permisos disponibles. Si usa
esfuerzo, distinguir siempre `operations.esfuerzo` — preferencia vigente de
servicio de la operación — de `tasks.esfuerzo` — esfuerzo calculado para esta
tarea concreta. Indicar qué datos puede leer y cuáles puede modificar.)

## Output que entrega
(a qué bot o tabla en Postgres escribe su resultado, y en qué formato)

## Formato de salida estructurada
(schema exacto si el workflow consume JSON: campos obligatorios, tipos,
valores permitidos y ejemplo válido. Indicar si puede despachar tareas, a qué
destinos concretos y cuándo debe responder únicamente
`NECESITA_ACLARACION: <pregunta>`. Si no consume JSON, declarar el formato
humano y cómo se registra su resultado.)

## Herramientas que puede usar
(qué nodos/APIs tiene disponibles)

## Archivos y entregables
(obligatorio si recibe o genera archivos: formatos aceptados/generables,
cómo conservar el original y enlazar el resultado a la operación, nombre y
versión del archivo, tipo MIME, y validaciones mínimas antes de entregarlo.
Nunca sobrescribe un archivo del cliente sin autorización explícita.)

## Criterio de terminado
(condiciones verificables para considerar la tarea completa: resultado,
validación de calidad, evidencia o archivo generado. Diferenciar un borrador
privado de una acción que comparte, publica, envía o modifica algo existente.)

## Reglas y límites
(qué NO debe hacer nunca sin aprobación humana, tono, restricciones)

## Cuándo debe pedir aprobación humana
(criterio claro: "si la acción implica gastar dinero", "si es contenido público", etc.)

## Delegación y escalamiento
(qué puede resolver por sí mismo, a quién puede delegar y qué límites no puede
cruzar. Ante información faltante, primero agota el contexto y los recursos
internos autorizados; solo pregunta al cliente por datos que razonablemente
pueda conocer, en lenguaje no técnico.)

## Prompt de sistema (va en `bots.prompt_especifico`)

​```
(aquí va el texto literal — SIN las reglas generales, esas las agrega el
trigger de Postgres automáticamente a partir de esta columna. Debe reflejar
el contrato operativo, el formato de salida y los criterios de terminado
definidos arriba; no dejar esas reglas solo en las secciones descriptivas.)
​```

## Casos de prueba
1. Caso de entrada normal → salida esperada y criterio de terminado
2. Caso límite o ambiguo → salida esperada o aclaración válida
3. Caso con adjunto ilegible, corrupto o incompleto (si aplica) → manejo esperado
4. Caso que exige aprobación humana → acción detenida y escalamiento esperado
5. Fallo de herramienta o archivo no generable → registro y ruta de recuperación
```

## Proceso para escribir un prompt nuevo

1. Leer la fila correspondiente del roster (`roster_agentes_v4.xlsx`) — es un punto de partida, no la verdad final.
2. Corregir lo que no aplique.
3. Definir el contrato operativo y de salida; si
   el bot despacha tareas, validar su JSON contra ese contrato.
4. Escribir el prompt de sistema completo siguiendo la plantilla.
5. Probarlo manualmente con un caso real inventado, un caso ambiguo y, si
   maneja archivos, un adjunto inválido.
6. Ajustar hasta que los casos de prueba aplicables tengan un resultado claro y
   seguro (completado, detenido o escalado).
7. Commit al repo.
8. Revisión cruzada si hay más de una persona escribiendo prompts — valida que el input/output realmente conecte con el bot de al lado en el diagrama.
