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

## Output que entrega
(a qué bot o tabla en Postgres escribe su resultado, y en qué formato)

## Herramientas que puede usar
(qué nodos/APIs tiene disponibles)

## Reglas y límites
(qué NO debe hacer nunca sin aprobación humana, tono, restricciones)

## Cuándo debe pedir aprobación humana
(criterio claro: "si la acción implica gastar dinero", "si es contenido público", etc.)

## Prompt de sistema (va en `bots.prompt_especifico`)

​```
(aquí va el texto literal — SIN las reglas generales, esas las agrega el
trigger de Postgres automáticamente a partir de esta columna)
​```

## Casos de prueba
1. Caso de entrada de ejemplo → salida esperada
2. Caso límite/borde → salida esperada
3. Caso que debería fallar/escalar → salida esperada
```

## Proceso para escribir un prompt nuevo

1. Leer la fila correspondiente del roster (`roster_agentes_v4.xlsx`) — es un punto de partida, no la verdad final.
2. Corregir lo que no aplique.
3. Escribir el prompt de sistema completo siguiendo la plantilla.
4. Probarlo manualmente con un caso real inventado.
5. Ajustar hasta que 2 de 3 casos de prueba salgan bien.
6. Commit al repo.
7. Revisión cruzada si hay más de una persona escribiendo prompts — valida que el input/output realmente conecte con el bot de al lado en el diagrama.
