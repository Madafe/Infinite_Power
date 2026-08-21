# Gobernanza de auto-expansión — ficha de bot nuevo y ciclo de aprobación

> Diseñado el 20 de agosto de 2026, a partir de una conversación de Mateo con
> ChatGPT sobre cómo estructurar la Fase 8 ("Auto-expansión") del
> [[plan_de_accion_completo]] (ver ahí, "FASE 6 — Auto-expansión ('Nuevos
> departamentos')", Paso 6.2). **Estado: diseño completo, construcción sin
> empezar.** No confundir con el "mandato de diseño" vigente descrito en
> [[arquitectura_general]] — ese mandato es el que hoy usan Claude/Mateo, a
> mano, durante la construcción manual del sistema; lo que describe este
> documento es el mecanismo *automatizado* por el que el sistema, ya en
> operación, se propondría bots a sí mismo. Todavía no hay ni un solo center
> corriendo en producción sobre el cual ejecutar este ciclo, así que no tiene
> sentido activarlo antes de que exista Efadam + los 3 centers + que al menos
> un departamento pase por [[autonomia_progresiva]]. Ver "Por qué no se
> construye todavía" al final.

## Punto de partida: qué proponía la conversación con ChatGPT, y qué se corrigió

Mateo trajo una propuesta de ChatGPT con un ciclo de 8 pasos (`Necesidad
detectada → propuesta de bot → definición de rol → prueba aislada →
aprobación → activación → medición → mantener/fusionar/retirar`) y una ficha
de 6 campos obligatorios. La idea de fondo es correcta y coincide con lo que
ya estaba anticipado en `reglas_generales.md` (regla 6, "Diseña para que el
sistema se autoexpanda fácil") y en el Paso 6.2 del plan — pero ese paso, tal
como estaba escrito, solo cubría 3 de los 8 pasos del ciclo (propuesta →
ensamblado → aprobación), sin prueba aislada, sin métrica de éxito, sin
condición de salida y sin un paso de validación por el departamento destino.
Vale la pena formalizarlo — eso es lo que hace este documento.

Una corrección a la propuesta original, no solo una aceptación:

**"Yo lo pondría bajo Efadam: él puede detectar el hueco y proponer" — no.**
Efadam está definido en `arquitectura.md` como *cerebro de orquestación,
enruta y resume, no ejecuta trabajo de ninguna rama* — y el patrón que el
propio sistema ya sigue para "conocimiento nuevo" es que Efadam nunca redacta
contenido, solo lo solicita a Upgrade & review center y lo inserta cuando
llega aprobado. Proponer un bot nuevo es ese mismo tipo de trabajo de
síntesis/redacción, no de enrutamiento — y ya tiene dueño: **Council** y
**Nuevos departamentos**, dentro del departamento Estrategia (ver
`arquitectura_general.md`, "Departamento Estrategia"), alimentados por
**Planner** (`Establecer metas → Planner → Nuevos departamentos`) y por el
loop `Cross department ↔ Especialista en organización y métodos ↔ Buscador
de áreas de oportunidad ↔ Optimizador → Council`. Ponerlo bajo Efadam
duplicaría un trabajo que el diseño ya le asignó a otro bot, y sobrecargaría
al único componente que el sistema mantiene deliberadamente como cuello de
botella simple — justo lo que la Regla general 2 ("simplicidad primero")
pide evitar.

Lo que sí es cierto, y vale la pena aprovechar: Efadam es el único bot con
visibilidad de lectura de `tasks`/`agent_runs` de **todas** las ramas al
mismo tiempo (ver `arquitectura.md`, actualización del 19/ago). Eso lo hace
la mejor fuente de **señales** de un hueco funcional (un patrón de tareas
que terminan en `NECESITA_ACLARACION` porque ningún bot existente las cubre,
o un tipo de tarea que un center rechaza repetidamente por falta de
especialización). Su rol correcto en este ciclo es **señalar el patrón hacia
Upgrade & review center**, igual que hoy solicita redacción de conocimiento
— nunca redactar la ficha ni decidir que hace falta un bot nuevo; esa
decisión la construye Council con el resto de su loop.

## El ciclo corregido

```
Señal de un hueco funcional
   (Council/Planner por su propio análisis, un center que rechaza
    tareas repetidas por falta de especialización, o un patrón que
    Efadam observa entre ramas y turna a Upgrade & review center —
    Efadam nunca redacta la propuesta, solo la señala)
        |
        v
Ficha de propuesta de bot nuevo
   (la redacta Council/Nuevos departamentos — ver plantilla abajo)
        |
        v
Validación por el center del departamento destino
   (Tech center / Upgrade & review center / Proyect center — confirma que
    de verdad hace falta un bot nuevo y no basta con ajustar/dividir uno
    existente; si el bot propuesto no cabe en ninguno de los 3
    departamentos existentes, esto ya no es "un bot", es "un departamento
    nuevo" y salta directo a aprobación de Mateo — ningún center puede
    autoaprobar eso)
        |
        v
Agent builder ensambla
   (prompt siguiendo `plantilla_prompt.md` + workflow de n8n — SIEMPRE
    creado con active = false; ya es su regla vigente hoy, sin cambios)
        |
        v
Aprobación humana de Mateo — única, obligatoria, sin excepción
   (sobre la ficha completa + el prompt ensamblado juntos, no por separado)
        |
        v
Activación en modo prueba aislada
   (bajo el mismo center que validó el hueco; volumen mínimo de tareas
    reales definido en la propia ficha — mismo criterio de
    `autonomia_progresiva.md`: volumen real, nunca tiempo calendario)
        |
        v
Medición contra la métrica de éxito de la ficha
        |
        v
Decisión final de Mateo: activo pleno / fusionar con otro bot / retirar
```

Nota práctica: hasta que Upgrade & review center y los otros 2 centers estén
activos de verdad (hoy ninguno lo está — ver `estado_del_proyecto.md`,
"Bots realmente activos: 3"), el paso de "validación por el center" lo hace
Mateo directamente. El ciclo sirve como checklist manual mientras tanto, no
depende de que todo lo demás ya esté construido para ser útil.

## Ficha de propuesta de bot nuevo (plantilla)

Se llena **antes** de invocar a Agent builder — es la decisión de negocio de
por qué construir el bot, separada del diseño técnico del bot en sí (eso
sigue viviendo en `plantilla_prompt.md`, sin cambios). Queda junto al prompt
final una vez aprobada, como parte del historial de por qué existe ese bot.

```markdown
# Ficha de propuesta — [nombre del bot propuesto]

## 1. Identificación
- Departamento/cluster destino: (dev-tech / estrategia-crecimiento /
  investigacion-skills / legal / operacion-proyectos / negocios-propios —
  o "departamento nuevo", que cambia todo el proceso, ver arriba)
- Quién propone: (Council / Planner / un center / Mateo)
- Fecha

## 2. Problema concreto que resuelve
- Qué hueco funcional hay hoy, con evidencia concreta (no una intuición):
  tareas repetidas fallando, patrón de `NECESITA_ACLARACION`, rechazos
  repetidos de un center, cuello de botella observado en `tasks`/`agent_runs`.
- Por qué ningún bot existente lo cubre ya — revisar el roster primero
  (mismo paso que ya hace Agent builder antes de crear nada).
- Por qué no basta con ajustar el prompt de un bot existente (Entrenador
  Agentes) o dividirlo en dos más específicos, en vez de crear uno nuevo.

## 3. Alcance y límites
- Qué SÍ hace, qué NO hace explícitamente — para no solaparse con el bot
  de al lado en el diagrama.
- Con qué bot(s) existentes interactúa (input/output, igual que en
  `plantilla_prompt.md`).

## 4. Departamento y jefe responsable
- Qué center lo audita y aprueba dentro de su rama.
- Si no cabe en ningún departamento existente: esto es un departamento
  nuevo, no un bot — sube directo a Mateo, ver nota arriba.

## 5. Herramientas, permisos y acciones que requieren aprobación
- Qué nodos/APIs/tablas necesita.
- Cuáles de sus acciones quedan marcadas de aprobación obligatoria sin
  excepción — mismas reglas globales ya vigentes en `arquitectura.md`
  ("Reglas de aprobación humana"): dinero, contenido público, legal,
  seguridad, o cualquier acción fuera de su sandbox.

## 6. Esfuerzo máximo esperado
- Usa la escala YA existente de `tasks.esfuerzo`
  (`bajo`/`medio`/`alto`/`critico`) — no es una escala nueva, sirve para
  estimar costo y decidir si necesita fila en `bot_esfuerzos_fijos` antes
  de aprobar.

## 7. Métrica de éxito
- Qué significa "funciona" para este bot en concreto, en términos
  verificables (ej. tasa de aprobación del center > X%, cero escaladas a
  Trouble shooter por falta de capacidad en Y tareas).

## 8. Prueba aislada — condición para graduar a activo pleno
- Número mínimo de tareas reales completadas sin error no manejado, bajo
  supervisión del center, antes de considerarlo graduado — se define caso
  por caso (no hay un número universal, mismo principio que
  `autonomia_progresiva.md`).

## 9. Condición de salida
- Bajo qué evidencia se fusiona con otro bot, se pausa o se retira.
- Quién lo decide: siempre Mateo, nunca automático — mismo principio que
  ya rige el corolario del mandato de diseño en `arquitectura_general.md`
  ("posponer o desactivar un bot ya diseñado si a la escala actual no
  aporta").
```

## Implicación de schema (no construida todavía)

`bots.active` hoy es un booleano simple (`schema/001_init.sql`). El ciclo de
arriba necesita distinguir al menos 3 estados por bot (`en_prueba`, `activo`,
`retirado`/`fusionado`), no solo activo/inactivo — sin esto, "activación en
modo prueba aislada" no tiene dónde vivir en el schema. Dos caminos
posibles, sin decidir todavía: (a) agregar una columna `bots.estado` tipo
texto con CHECK, reemplazando el uso de `active` para este propósito; (b)
una tabla dedicada de historial de ciclo de vida (coherente con el patrón ya
usado en `bot_esfuerzos_fijos`, separada a propósito de `bots` — ver
`schema/008_bot_roles.sql`). Se decide cuando se construya de verdad, no
ahora — anotado aquí para no perderlo.

## Por qué no se construye todavía

Fase 8 (Auto-expansión) va después de Efadam, los 3 centers, y de que al
menos un departamento pase por `autonomia_progresiva.md` — así está ordenado
en el checklist maestro (hoy en ClickUp, ver abajo), y sigue haciendo
sentido: hoy solo 3 bots están
activos (`tecnico_jefe`, `coder`, `trouble_shooter`, `efadam` — insertado
21/ago, todavía no activo de verdad: sin Jarvis, sin workflow de n8n
actualizado), y ninguno de los 3 centers existe en producción. Construir el workflow de auto-expansión antes de eso sería
automatizar la creación de bots sobre un sistema que todavía no tiene quién
los valide (el paso de "validación por el center" del ciclo de arriba no
tendría a quién delegarse). Este documento deja listo el diseño para cuando
le toque su turno — no adelanta la construcción.

## Pendiente — en ClickUp (21/ago/2026)

El checklist de construcción de esta fase vive en ClickUp, tarea `86bbhh48j`
(board Infinite Power, lista "Diseño pendiente") — ya no se duplica aquí.
