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

## 21 de agosto de 2026 — Workflow vivo sincronizado + gap real de contrato JSON en Efadam, encontrados al preparar la primera prueba

Antes de poder probar a Efadam en vivo se encontraron y corrigieron dos
problemas reales, no solo documentación:

1. **El workflow vivo de n8n estaba desincronizado del schema ya migrado.**
   El nodo `"Obtener nivel fijo del bot"` seguía consultando
   `bot_niveles_fijos`/`nivel_fijo` — tabla y columna que la migración 009
   ya había renombrado. Habría fallado en cuanto corriera. Se aplicó el
   `n8n-workflows/ejecutor_generico.json` ya commiteado (38 nodos: incluye
   el rename a `esfuerzo`/`bot_esfuerzos_fijos` y los 2 nodos nuevos de
   detección/alerta de degradación de modelo) vía `PUT` a la API de n8n —
   confirmado sin referencias viejas colgantes.
2. **`efadam.md` nunca especificaba el formato de salida obligatorio.**
   `dispatches_tasks = true` hace que el ejecutor intente `JSON.parse()`
   sobre la respuesta cruda del LLM (nodo `"Parsear asignaciones"`) — el
   prompt de Efadam seguía escrito para responder en prosa libre. Se agregó
   el contrato JSON obligatorio, mismo patrón que ya usan Técnico
   jefe/Trouble shooter, con dos campos que ellos no necesitan porque
   Efadam además le responde al cliente: `respuesta_cliente` y `esfuerzo`
   a nivel raíz, más `asignaciones` (máximo 1 entrada, siempre dirigida a
   un center — `tech_center`/`upgrade_review_center`/`proyect_center` — 
   nunca a un especialista). Se definieron también los slugs de `cluster`
   propuestos para los 2 centers que todavía no existen
   (`upgrade-review-center`, `proyect-center`, kebab-case como
   `tech-center`) — a confirmar cuando esos centers se inserten de verdad.
   Aplicado en `bots.prompt_especifico`.

**Prueba en vivo (técnica de webhook temporal, tarea 30):** confirmó que
Efadam se dispara correctamente contra la config real y que el manejo de
fallos sigue funcionando (tarea marcada `failed` con el error real,
disparo automático a `trouble_shooter` sin loop). **No se pudo confirmar
el JSON de salida en la práctica** porque la llamada al modelo real falló
— OmniRoute devolvió `503 ALL_ACCOUNTS_INACTIVE` para `bajo`, y una prueba
directa a los 4 combos mostró que ninguno sirve tráfico ahora mismo (3
devuelven error, 1 se cuelga sin responder) — regresión respecto al 18/ago,
cuando NVIDIA NIM sí estaba conectado y probado. Ver tarea ClickUp
`86bbj0xgz`: necesita que Mateo entre al dashboard de OmniRoute
(`localhost:20128/dashboard/providers`) a reconectar un proveedor — no se
puede diagnosticar más sin esa sesión. **Bloquea la confirmación final de
Efadam y, en general, cualquier tarea real del sistema hasta que se
resuelva.**

## 21 de agosto de 2026 — Resuelto: NVIDIA reconectado, diagnóstico previo
corregido, y Efadam confirmado end-to-end con el contrato JSON real

**Diagnóstico corregido.** La "caída total de los 4 combos" reportada
horas antes (ver entrada anterior) resultó ser, en su mayor parte, un
artefacto del lado cliente, no una caída real de OmniRoute. Al revisar
`docker logs infinite-power-omniroute-1` se vio que las mismas llamadas
que `Invoke-RestMethod`/`Invoke-WebRequest` reportaban como fallidas o
colgadas en realidad se habían completado del lado del servidor (`bajo` y
`critico` en ~1s, `alto` en ~25s tras un ciclo de cola por rate-limit).
Confirmado después con una prueba limpia usando `curl.exe` en vez de los
cmdlets de PowerShell: los 4 combos responden con normalidad. **Lección
de infraestructura, no de arquitectura:** en esta máquina, `Invoke-RestMethod`
/ `Invoke-WebRequest` de PowerShell son poco confiables para llamadas HTTP
locales — se cuelgan sin arrojar error incluso con `-TimeoutSec` explícito,
tanto contra n8n (`localhost:5678`) como contra OmniRoute (`localhost:20128`).
`curl.exe` (incluido en Windows) no tuvo ese problema en ninguna prueba de
esta sesión. **Regla nueva para todo trabajo futuro vía Desktop Commander:
usar `curl.exe` para llamadas HTTP, nunca `Invoke-RestMethod`/`Invoke-WebRequest`.**
Ver también la nota de PowerShell en `stack_y_convenciones.md` si se agrega
una sección de convenciones de shell — pendiente evaluarlo.

Dicho esto, sí había un problema real y separado: la tarea 30 falló con
`503 ALL_ACCOUNTS_INACTIVE`, un error genuino de que la cuenta NVIDIA
conectada no estaba activa en ese momento — no relacionado con el
artefacto de diagnóstico de arriba.

**Resuelto con la llave nueva de Mateo.** Con la llave NVIDIA nueva que
Mateo pegó en el chat (`nvapi-zeOt...FVA2YlVp8`, reemplaza la del
18/ago): se hizo login al dashboard de OmniRoute vía API
(`POST /api/auth/login`), se actualizó la conexión NVIDIA existente
(`PUT /api/providers/{id}`, id `c6488003-...`) con la llave nueva, y se
confirmó con `POST /api/providers/{id}/test` → `{"valid": true}`. La
llave nueva también quedó guardada en `.env` (mismo tratamiento que la
anterior, ver comentario ahí). Los 4 combos se volvieron a probar uno por
uno con `curl.exe` y los 4 responden con normalidad.

**Efadam confirmado end-to-end.** Con OmniRoute funcionando, se repitió
la prueba de webhook temporal (tarea 32, mismo procedimiento que la
sesión anterior). Resultado: la tarea se completó (`status = done`) con
esta salida exacta de Efadam —

```json
{"respuesta_cliente": "El proyecto sigue avanzando, pero todavía hay
algunos desafíos técnicos...", "esfuerzo": "alto",
"asignaciones": [{"bot": "tech_center", "cluster": "tech-center",
"esfuerzo": "alto", "requiere_aprobacion": true,
"input": "Estas son recomendaciones, no órdenes directas del
cliente..."}], "notas": "..."}
```

— es decir, el contrato JSON obligatorio (`respuesta_cliente` / `esfuerzo`
/ `asignaciones` / `notas`) funciona en la práctica, no solo en el prompt.
Además, como la asignación traía `requiere_aprobacion: true`, el flujo
tomó correctamente la rama de aprobación (bloqueo de operación + alerta)
en vez de crear una tarea hija automáticamente — el comportamiento
diseñado. **La prueba de Efadam queda cerrada y confirmada.**

**Nota aparte, no bloqueante:** la tarea 31 (`trouble_shooter`,
auto-despachada por el fallo de la tarea 30 en la sesión anterior) fue
reclamada primero por el motor (es más antigua que la 32) y falló con
`400 - Missing model`, porque nunca se le asignó `esfuerzo` al crearla
(la tarea 30 tampoco lo tenía). Quedó en `status = failed`, no se
reintentará sola — no requiere acción, pero es una pista de que las
tareas de prueba insertadas a mano deberían siempre traer `esfuerzo`
explícito para no dejar huecos así en la cola.

## 21 de agosto de 2026 — Los 13 prompts existentes migrados a la plantilla nueva

Mateo pidió reescribir los prompts que ya existen (`prompts/dev-tech/*.md` y
`prompts/_core/efadam.md`, 13 archivos) con `docs/plantilla_prompt.md` — la
plantilla ya tenía secciones que ningún archivo real seguía todavía
("Estado y contrato operativo", "Formato de salida estructurada", "Archivos
y entregables", "Criterio de terminado", "Delegación y escalamiento"), pese
a que la nota al pie de la plantilla decía lo contrario. Se corrigió: los 13
archivos quedaron reescritos con esas 5 secciones agregadas, sin perder
ningún contrato ya probado (JSON de asignaciones de Técnico
jefe/Trouble shooter, veredicto de Consultor de arquitectura, workflow
separado de Trouble scouter, notas de corrección históricas de cada uno).

**Decisiones de diseño tomadas al rellenar los huecos** (no estaban escritas
en ningún lado antes de esta pasada):

- **`ciber_seguridad_scouter` y `ciber_seguridad` pasan a `dispatches_tasks
  = true`.** Sus prompts ya decían "dirigido al Hacker ético" / "dirigido a
  Coder", pero no existía ningún mecanismo real para que ese hallazgo se
  convirtiera en una tarea — se formalizaron con el mismo contrato JSON de
  `asignaciones` que ya usan Técnico jefe/Trouble shooter. Mismo criterio
  para `hacker_etico` (dirigido a `ciber_seguridad`).
- **`tech_center` recibe su primer contrato JSON formal**, con un campo
  nuevo (`resumen_consolidado`) para el paquete que Efadam lee directo de
  Postgres — se documentó explícito que ese resumen NO es un despacho hacia
  `efadam` (Efadam no tiene mecanismo de recepción de tareas, solo lee
  `tasks`/`agent_runs` en vivo).
- **La convención `NECESITA_ACLARACION: <pregunta>`** (ya existente en el
  ejecutor, nodo "¿Necesita aclaración?", pero no explicada en ningún
  prompt) se documentó en la sección "Formato de salida estructurada" de
  los 13 archivos: es la única salida válida en texto plano incluso para
  bots con `dispatches_tasks = true` — sustituye al JSON completo cuando
  aplica, nunca convive con él.
- **Trouble scouter** es el único de los 13 al que varias secciones de la
  plantilla no le aplican de forma literal (no corre por `tasks` ni por el
  ejecutor genérico, tiene su propio workflow) — se dejó explícito "no
  aplica" en vez de forzar contenido que no describe la realidad.

**No se tocó:** `tech_center` sigue sin insertarse en la tabla `bots` — este
cambio fue solo de documentación/prompt, no de activación. `coder`,
`tecnico_jefe`, `trouble_shooter` y `efadam` ya estaban `active = true`; su
`bots.prompt_especifico` se sincronizó en vivo con el bloque "Prompt de
sistema" de cada archivo reescrito (extraído por script y aplicado con
`UPDATE ... $PROMPT$...$PROMPT$`, mismo mecanismo de dollar-quoting ya usado
para Efadam el 21/ago). Verificado por longitud de `prompt_especifico`
después del `UPDATE`, coincide con lo extraído de cada `.md`.

## 21 de agosto de 2026 — tech_center insertado en `bots`; prueba end-to-end revela un hueco real en el parseo de JSON

Mateo pidió insertar `tech_center` en producción y probarlo ("dale, inserta
y prueba"). Se hizo lo primero sin problema; lo segundo destapó un bug real,
no un simple "todo funciona".

**Inserción.** `tech_center` insertado en `bots` con `active = true`,
`dispatches_tasks = true`, `requires_approval = false`,
`conocimiento_directo = false`, `contexto_slugs = {arquitectura,
stack_y_convenciones}` (mismo contexto que `tecnico_jefe`/`efadam`).
`prompt_especifico` tomado literal del bloque "Prompt de sistema" de
`tech-center.md` (1661 caracteres); el trigger `trg_componer_system_prompt`
compuso `system_prompt` automáticamente (3310 caracteres) — mismo mecanismo
que ya usan los otros 4 bots activos, sin intervención manual.

**Prueba en vivo (técnica de webhook temporal, tarea 33).** Se insertó una
tarea sintética para `tech_center` simulando una recomendación de Efadam de
bajo riesgo ("reforzar validación de inputs en el módulo de autenticación,
sin incidentes reportados"). Se agregó un nodo webhook temporal al workflow
`ejecutor_generico` (mismo procedimiento que las pruebas anteriores de
Efadam/Técnico jefe: nodo `n8n-nodes-base.webhook` cableado igual que
"When clicking 'Execute workflow'" → "Reclamar tarea pendiente", vía
`PUT /api/v1/workflows/{id}` con payload construido en Python — no
PowerShell, para evitar el bug conocido de aplanado de arrays anidados de
`ConvertTo-Json`), se activó, se disparó con `curl.exe`, se observó el
resultado en Postgres y en el historial de ejecuciones de n8n, y se
revirtió el workflow a su estado original (38 nodos, inactivo) al terminar.
Verificado con una segunda lectura del workflow que quedó idéntico al
original.

**Resultado: la tarea 33 terminó en `status = 'failed'`** con el error
`Unexpected token '#', "## Conocim"... is not valid JSON`. El contenido
crudo que devolvió el modelo no quedó accesible en `tasks.output` (se
sobrescribió con el mensaje de error) — hubo que recuperarlo desde la API
de ejecuciones de n8n (`GET /api/v1/executions/{id}?includeData=true`,
nodo "Llamar a omniroute"). **Nota aparte para el futuro:** cuando una
tarea falla, la única forma de ver la respuesta cruda del modelo es el
historial de ejecuciones de n8n, no la tabla `tasks` — vale la pena
evaluar si conviene guardar el crudo en algún lado antes de intentar el
parseo, para no depender de eso.

**Lo que el contenido crudo mostró:** el modelo sí tomó la decisión
correcta — el JSON embebido al final era exactamente el esperado:
`{"asignaciones": [{"bot": "tecnico_jefe", "cluster": "tech-center",
"esfuerzo": "bajo", "requiere_aprobacion": false, "input": "reforzar
validación de inputs en modulo de autenticación"}], "resumen_consolidado":
null, "notas": "..."}`. El problema no es la decisión ni el contrato — es
que el modelo lo envolvió en ~30 líneas de un ensayo en markdown
("## Conocimiento del sistema", con secciones, viñetas, etc.) antes del
bloque JSON, a pesar de la instrucción explícita "responde ÚNICAMENTE con
un objeto JSON válido, sin texto antes ni después". El nodo "Parsear
asignaciones" hace `JSON.parse` directo sobre el contenido completo, sin
ningún intento de extraer el JSON embebido — cualquier prosa antes del
bloque rompe el parseo aunque la decisión del modelo sea correcta.

**El mecanismo de fallo sí funcionó como está diseñado:** la tarea 33 se
marcó `failed` y se auto-despachó una tarea nueva a `trouble_shooter`
(tarea 34) con el mensaje de error, sin loop ni intervención manual — ese
circuito ya estaba probado con Efadam (18/ago) y esta prueba confirma que
también cubre a `tech_center` sin cambios adicionales.

**Esto no es un problema aislado de `tech_center` ni del esfuerzo `medio`
específicamente — es un hueco estructural.** El parseo de JSON en "Parsear
asignaciones" (y, por el mismo motivo de fondo, el
`startsWith('NECESITA_ACLARACION:')` en "¿Necesita aclaración?") asume que
el modelo obedece "solo JSON" al pie de la letra, sin ninguna capa de
tolerancia. Ya había una nota de pendiente sobre esto limitada al caso de
NECESITA_ACLARACION envuelto en markdown; esta prueba muestra que el
alcance real es más amplio — afecta a cualquier bot con
`dispatches_tasks = true` (hoy: `efadam`, `tecnico_jefe`, `trouble_shooter`,
`tech_center`; a futuro: `ciber_seguridad`, `ciber_seguridad_scouter`,
`hacker_etico`).

**No se modificó el nodo "Parsear asignaciones" en esta pasada.** Es un
cambio que toca el workflow compartido por todos los bots despachadores, así
que se deja para decidir con Mateo el criterio de extracción antes de
tocarlo en producción. Opciones a evaluar (no decidido):
1. Extraer el último bloque `\`\`\`json ... \`\`\`` del string con regex
   antes de parsear.
2. Buscar el primer `{` y el último `}` del string completo y parsear solo
   ese fragmento.
3. Reforzar el prompt (repetir la instrucción, o pedir explícitamente que
   el JSON sea la primera línea) y aceptar que puede seguir fallando
   ocasionalmente con modelos más débiles.
4. Combinar 1+2 como fallback tolerante, y solo si ambas fallan, tratarlo
   como error real (el comportamiento actual).

Pendiente elevado a prioridad alta en ClickUp — bloquea dar por
"confirmado en producción" el despacho de cualquier bot, no solo de
`tech_center`.

**`tech_center` queda insertado y activo en `bots`.** El contrato de
despacho es correcto en el contenido (confirmado por esta prueba), pero la
robustez del parseo del lado del ejecutor sigue siendo el cuello de botella
real antes de poder decir que el flujo Efadam → Tech center → Técnico jefe
funciona de punta a punta sin intervención.

## 21 de agosto de 2026 — Corrección: "requiere aprobación" pasaba por Telegram directo, saltándose a Efadam

Mateo detectó, revisando el ejecutor, un problema de diseño real: cuando una
asignación quedaba bloqueada esperando aprobación humana (o una operación
tocaba su tope de fan-out, o el output completo de un bot con
`requires_approval = true` necesitaba revisión), el workflow le mandaba un
mensaje de Telegram armado a mano, directo al chat de admin — saltándose a
Efadam por completo. Instrucción de corrección: "tiene que pasar por Efadam
[...] que solo pase json".

**Diagnóstico.** Violación directa del principio ya documentado en
`efadam.md`: "Efadam es, ante todo, un cuello de botella intencional". Dos
nodos de Telegram del `ejecutor_generico` construían el mensaje directo:
- **"Send a text message"** — se disparaba en dos casos distintos que
  compartían el mismo nodo: (a) el propio output de un bot con
  `bots.requires_approval = true` (mecanismo reservado, ningún bot activo lo
  usa hoy), y (b) un bot responde `NECESITA_ACLARACION` pero su tarea no
  tiene `parent_task_id` a quien escalarle la pregunta (nodo "¿Tiene
  padre?", rama falsa) — este segundo caso no estaba en el pedido original de
  Mateo pero es la misma violación exacta, así que se corrigió también.
- **"Alerta de aprobacion pendiente"** — se disparaba cuando una asignación
  individual traía `requiere_aprobacion: true`, cuando el bot destino
  estaba en la lista `bots.requires_approval = true`, o cuando la operación
  tocaba su tope de fan-out (`_tipo = 'tope_operacion'`).

**Diseño de la corrección.** En vez de Telegram directo, el motor ahora le
crea a Efadam una tarea real (`bot = 'efadam'`, mismo `operation_id` y
`parent_task_id` que la tarea bloqueada, para que el contexto automático
"esta tarea fue asignada por X a partir de: Y" llegue gratis vía el mecanismo
ya existente de "Obtener contexto de tarea padre"). El contenido que Efadam
recibe en `input.text` es **un objeto JSON serializado como string** (no
prosa) con un campo `tipo_evento` — decisión tomada porque "Llamar a
omniroute" solo lee `tasks.input.text` como el mensaje del usuario; cualquier
otro campo del `input` nunca llega al modelo, así que la única forma de que
"solo pase JSON" es que el propio `text` sea el JSON.

Cuatro valores de `tipo_evento`, los primeros tres correspondientes 1 a 1 a
los casos que antes iban a Telegram, más uno nuevo (mismo mecanismo, caso
que se corrigió de paso):
- `requiere_aprobacion` — una asignación individual necesita aprobación.
- `tope_operacion` — la operación alcanzó su tope de fan-out.
- `aprobacion_bot_completo` — el output completo de un bot con
  `requires_approval = true` necesita revisión (reservado, sin uso activo
  hoy).
- `aclaracion_sin_padre` — un bot respondió `NECESITA_ACLARACION` sin tarea
  padre a quien escalarle la pregunta.

**Cambios concretos:**
1. `prompts/_core/efadam.md` — nueva sección de "Input que recibe" (avisos
   internos), nueva subsección de "Formato de salida estructurada" con la
   regla dura **`asignaciones` siempre vacío ante un aviso, sin excepción**
   (evita que Efadam reintente despachar algo que ya está bloqueado y cause
   un loop), nueva regla en "Reglas y límites", nuevo caso de prueba (#7), y
   el párrafo correspondiente agregado al bloque "Prompt de sistema" real.
   Sincronizado en vivo a `bots.prompt_especifico`/`system_prompt` de
   `efadam` (verificado por longitud: 4425/6074 caracteres).
2. `ejecutor_generico` (n8n, `aVORciBJl52lTxTU`) — cambio estructural,
   aplicado en producción tras dos intentos fallidos (ver "Errores"
   abajo), ahora en 39 nodos (38 originales − 2 nodos de Telegram
   removidos + 3 nodos nuevos):
   - **"Preparar aviso - aprobacion bot completo"** (Code) — alimentado por
     ambas ramas verdaderas de "¿Requiere aprobación?"/"¿Requiere
     aprobación?1" y por la rama falsa de "¿Tiene padre?"; detecta si el
     contenido crudo empieza con `NECESITA_ACLARACION:` para elegir entre
     `aprobacion_bot_completo` y `aclaracion_sin_padre`.
   - **"Preparar aviso - aprobacion pendiente"** (Code) — alimentado por
     "Marcar operacion bloqueada" (cubre `requiere_aprobacion` y
     `tope_operacion`, que ya compartían ese nodo antes de esta corrección).
   - **"Crear aviso para Efadam"** (Postgres, `INSERT INTO tasks`) — nodo
     compartido, recibe de los dos Code nodes de arriba.
   - **"Parsear asignaciones"** — cambio aditivo únicamente (no se tocó
     ningún comportamiento existente): se agregó `bot_origen` a los items
     normales, y `bot_origen` + `parent_task_id` a las ramas
     `tope_operacion`/`fanout_truncado` (antes no llevaban esos campos,
     hacían falta para poder trazar el aviso hasta la tarea que lo originó).
   - Se removieron los nodos "Send a text message" y "Alerta de aprobacion
     pendiente".
   - **No se tocó** "Alerta fan-out truncado" (alerta de infraestructura
     directa, no es un caso de "aprobación" y Mateo no lo mencionó) ni
     "Alerta de degradacion de modelo"/"Alerta critica Postgres" (alertas de
     salud del sistema, no de decisión del cliente).

**Errores encontrados y corregidos antes de llegar a producción:**
- Primer intento de `PUT`: el clasificador de seguridad de Auto Mode
  bloqueó la acción (modificar + activar un workflow de producción vía
  API). Mateo confirmó "vuélvelo a intentar" y el segundo intento sí pasó el
  clasificador.
- Segundo intento: n8n rechazó el `PUT` — `connections.¿Tiene padre?.main[1]
  [0].node: Connection target "Send a text message" does not reference an
  existing node`. Se había pasado por alto que "¿Tiene padre?" (rama falsa,
  el caso de aclaración sin padre) también apuntaba al nodo removido — no
  solo las dos ramas de "¿Requiere aprobación?". Corregido rewireando esa
  conexión al mismo nodo nuevo, y aprovechado para formalizar
  `aclaracion_sin_padre` como cuarto `tipo_evento` en vez de dejarlo roto o
  ignorarlo.
- Tercer intento: n8n rechazó publicar — `Node "Crear aviso para Efadam":
  Missing required credential: postgres`. El nodo Postgres nuevo no traía el
  bloque `credentials` que sí tienen los demás nodos Postgres del workflow.
  Corregido copiando el mismo `credentials.postgres` que usa "Crear tareas
  hijas".
- Antes de cada intento se verificó con un script en Python que ninguna
  conexión del payload apuntara a un nombre de nodo inexistente
  (`tmp_verify_no_dangling.py`), para no depender solo de que n8n lo
  rechazara en producción.

**Prueba en vivo, dos partes:**
1. **Aislada y determinística** (webhook temporal directo a "Preparar aviso
   - aprobacion pendiente", sin pasar por el modelo): payload manual con
   `_tipo: 'requiere_aprobacion'`, `parent_task_id: 33`. Resultado: tarea 35
   creada correctamente — `bot='efadam'`, `parent_task_id=33`,
   `esfuerzo='bajo'`, `input.text` con el JSON exacto esperado
   (`tipo_evento`, `bot_origen`, `bot_destino`, `cluster`,
   `esfuerzo_solicitado`, `input_asignacion`, `total_actual`, `tope`).
2. **End-to-end real** (mismo webhook temporal de siempre, wireado como
   Manual Trigger): se disparó el motor y Efadam procesó la tarea 35.
   Resultado exacto:
   ```json
   {"respuesta_cliente": "El equipo de producción necesita aprobación para
   desplegar el fix de autenticación a producción", "esfuerzo": "bajo",
   "asignaciones": [], "notas": "Estas son recomendaciones, no órdenes
   directas del cliente"}
   ```
   Confirma las tres cosas que había que confirmar: Efadam reconoció el
   aviso como tal (no como petición del cliente), no volvió a despachar
   (`asignaciones: []`, evita el loop), y tradujo el bloqueo a lenguaje
   llano sin exponer bots ni tablas. **La corrección queda confirmada en
   producción**, no solo en el diseño.

**Efecto secundario observado, sin relación con esta corrección:** durante
la prueba, la tarea 34 (`trouble_shooter`, auto-despachada por el fallo de
JSON-envuelto-en-Markdown de la tarea 33, ver entrada anterior) se procesó
sola en el camino y terminó bien, con una salida JSON limpia (sin envolver
en Markdown esta vez) despachando un fix a `coder` (tarea 36, quedó
`pending`, no se procesó más en esta ronda).

**Limitación conocida que esta corrección NO resuelve, documentada también
en `efadam.md`:** el aviso ahora llega correctamente a Efadam y Efadam lo
traduce bien, pero nada reenvía automáticamente esa `respuesta_cliente` a un
canal real todavía — Jarvis no existe, y el "reanudador" (procesamiento
automático de la cola) sigue siendo un pendiente aparte, ya rastreado en
ClickUp (`86bbhazu5`). Hoy, ese `respuesta_cliente` solo es visible leyendo
`tasks.output` a mano.

**Estado final del workflow tras esta ronda:** 39 nodos, inactivo, sin
webhooks temporales de prueba — verificado con una lectura final vía la API.

## 21 de agosto de 2026 — Endurecimiento del parseo de salida del modelo (ClickUp `86bbhbdry`)

**Problema que resuelve.** La prueba end-to-end de `tech_center` (entrada
anterior) destapó que el motor asumía que el modelo siempre devuelve JSON
crudo, sin envoltorio. En la práctica el modelo a veces envuelve su
respuesta en prosa y/o bloques Markdown (` ```json ... ``` `), y eso rompía
dos lugares distintos del `ejecutor_generico` al mismo tiempo:
- `"Parsear asignaciones"` — hacía `JSON.parse()` directo sobre
  `choices[0].message.content`; cualquier texto antes/después del JSON (o
  el JSON envuelto en \`\`\`json) tiraba la excepción cruda, sin distinguir
  "el modelo se equivocó de verdad" de "el modelo acertó pero lo envolvió
  raro".
- `"¿Necesita aclaración?"` — comparaba con
  `content.startsWith('NECESITA_ACLARACION:')`, un match exacto de string;
  si el modelo lo escribía en negritas (`**NECESITA_ACLARACION:**`) o con
  cualquier prefijo Markdown, la condición nunca se cumplía y la aclaración
  se trataba como una asignación normal (y fallaba el parseo de asignaciones
  también, en cascada).
- `"Crear tarea de aclaración"` — construía el texto de la tarea hija
  quitando el prefijo con `.replace('NECESITA_ACLARACION: ', '')`, el mismo
  problema de match exacto, ahora en la extracción del contenido en vez de
  en la detección.
- `"Preparar aviso - aprobacion bot completo"` (agregado en la corrección
  anterior) — tenía su propia copia del mismo `startsWith` frágil para
  decidir entre `aprobacion_bot_completo` y `aclaracion_sin_padre`.

Cuatro copias de la misma lógica frágil, en cuatro nodos distintos.

**Diseño elegido.** En vez de parchear cada copia por separado, se
centralizó la extracción tolerante en un único nodo nuevo,
`"Normalizar salida del modelo"` (Code, `onError: continueErrorOutput`),
insertado entre `"¿Falló la llamada a omniroute?"` (rama de éxito, antes
iba directo a `"¿Necesita aclaración?"`) y el resto de la cadena. Calcula
una sola vez:
- `es_aclaracion` (booleano): ya no exige que el string empiece
  exactamente con `NECESITA_ACLARACION:` — primero limpia caracteres
  Markdown iniciales (`*_\`#>~-` y espacios) del arranque del texto y recién
  ahí compara.
- `aclaracion_pregunta` (string o `null`): el texto de la pregunta ya
  limpio de marcado (negritas, backticks) al inicio y al final.
- `json_extraido` (objeto o `null`) / `json_extraido_ok` (booleano): intenta
  `JSON.parse()` directo primero; si falla, busca el **último** bloque
  \`\`\`json ... \`\`\` (o \`\`\` a secas) del texto y lo parsea; si tampoco
  hay bloques, cae a tomar desde la primera `{` hasta la última `}` del
  texto completo y lo intenta parsear. Si las tres estrategias fallan,
  `json_extraido_ok = false` en vez de tirar una excepción no controlada.

Los cuatro nodos consumidores se actualizaron para leer estos campos ya
calculados en vez de repetir la lógica:
- `"¿Necesita aclaración?"` ahora compara `{{ $json.es_aclaracion }}` en vez
  del `startsWith` crudo.
- `"Crear tarea de aclaración"` arma el `input` de la tarea hija con
  `$('Normalizar salida del modelo').first().json.aclaracion_pregunta` en
  vez de la extracción manual con `.replace`.
- `"Parsear asignaciones"` usa
  `$('Normalizar salida del modelo').first().json.json_extraido` como
  fuente; si `json_extraido_ok` es `false`, tira explícitamente
  `new Error('No se pudo extraer un JSON válido...')` — un fallo claro y
  diagnosticable en vez de la excepción críptica de `JSON.parse` sobre
  texto arbitrario. Ese error sigue cayendo en el camino normal de fallos
  del motor (`"Preparar fallo"` → `"Marcar como fallida"` →
  auto-despacho a `trouble_shooter` si el bot que falló no era ya
  `trouble_shooter`), así que el comportamiento de recuperación ya probado
  en la ronda anterior se mantiene intacto.
- `"Preparar aviso - aprobacion bot completo"` usa el mismo
  `es_aclaracion` calculado en vez de su copia propia del `startsWith`.

Ningún nodo existente cambió de comportamiento fuera de estos cuatro
puntos; el resto del grafo (37 nodos previos) quedó intacto.

**Verificación antes de desplegar.** Antes de cada intento de `PUT` se
corrió un verificador en Python que recorre `connections` y confirma que
todo nodo destino existe en `nodes` (mismo hábito adoptado en la corrección
anterior) — sin problemas esta vez, el `PUT` se aceptó al primer intento.

**Prueba en vivo, aislada y determinística.** Se agregó temporalmente un
webhook → nodo adaptador (`return [{ json: $json.body }]`) → conectado
**directamente** a `"Normalizar salida del modelo"` (sin pasar por el resto
del motor), y se dispararon 4 casos manualmente:

| Caso | Entrada | Resultado obtenido |
|---|---|---|
| JSON envuelto en \`\`\`json con prosa alrededor | `"Aqui esta el analisis:\n\n\`\`\`json\n{...}\n\`\`\`\n\nEspero que ayude."` | `es_aclaracion=false`, `json_extraido_ok=true`, extrajo el objeto correcto — **el caso exacto que rompía la tarea 33** |
| `NECESITA_ACLARACION:` envuelto en negritas | `"**NECESITA_ACLARACION:** ¿Cual es el objetivo exacto del despliegue?"` | `es_aclaracion=true`, `aclaracion_pregunta="¿Cual es el objetivo exacto del despliegue?"` (limpio, sin `**`) |
| JSON plano sin envoltorio (caso base, sin regresión) | `"{\"asignaciones\": []}"` | `es_aclaracion=false`, `json_extraido_ok=true`, `json_extraido={"asignaciones":[]}` |
| Texto sin JSON extraíble de ningún tipo | `"Lo siento, no puedo continuar..."` | `es_aclaracion=false`, `json_extraido_ok=false`, `json_extraido=null` — el caso que ahora dispara el error explícito y controlado en `"Parsear asignaciones"` en vez de una excepción cruda |

Los 4 resultados coincidieron exactamente con lo esperado por diseño. Nota
metodológica: la respuesta HTTP del webhook de prueba no sirvió para leer
el resultado (el grafo real sigue después de `"Normalizar..."` hacia nodos
que dependen de `"Reclamar tarea pendiente"` / `"Obtener config del bot"`,
que no corrieron en esta prueba aislada, así que el webhook devolvía
`{"message":"Error in workflow"}` por el fallo aguas abajo) — la
verificación real se hizo leyendo el `runData` del nodo
`"Normalizar salida del modelo"` directamente vía
`GET /api/v1/executions/{id}?includeData=true`, no la respuesta del
webhook.

No se repitió la prueba end-to-end real de `tech_center` en esta ronda —
la prueba aislada ya reproduce exactamente el patrón de falla observado
originalmente (JSON envuelto en \`\`\`json con prosa alrededor) contra el
nodo real que lo consume, así que se considera evidencia suficiente. Queda
como pendiente opcional repetir el flujo completo Efadam → Tech center →
Técnico jefe si se quiere una confirmación end-to-end adicional.

**Estado final del workflow:** 40 nodos (39 + 1 nuevo `"Normalizar salida
del modelo"`), inactivo, sin webhooks temporales de prueba — verificado con
una lectura final vía la API (sin conexiones colgantes, sin nodos
duplicados).

**ClickUp `86bbhbdry`:** se marca resuelto — ver actualización en la tarea.

## 21 de agosto de 2026 — Revisión crítica de una auditoría externa; se descarta la mitad, se rescata el resto en ClickUp

Mateo pidió contrastar un informe de auditoría externo (`docs/Informe_de_Auditoria_Integral_Efadam_2026-08-21.docx`) contra las decisiones de diseño ya tomadas, en vez de aceptarlo tal cual.

**Hallazgo clave: la auditoría trabajó sobre una versión desactualizada.** `n8n-workflows/ejecutor_generico.json` no se había vuelto a exportar desde el 20/ago (commit `c455035`, 38 nodos), mientras el workflow real en n8n ya llevaba dos rondas de cambios ese mismo día (39 nodos tras el routing de aprobación, 40 tras el endurecimiento del parseo). Los dos hallazgos más graves del informe (F-02: aprobación sin control real; F-03: Telegram con destinatario fijo y payload completo) describían el mecanismo de Telegram directo que ya se había corregido — la auditoría no podía verlo porque nunca se re-exportó el workflow después de editarlo por API.

**Recomendaciones descartadas por chocar con decisiones de diseño ya tomadas:**
- F-01 proponía una matriz versionada rígida `bot_origen → bot_destino → tipo_de_accion` que rechace cualquier despacho no autorizado explícitamente. Choca con el diseño de que Efadam y los centers decidan dinámicamente a quién despachar y sumen especialistas nuevos de forma orgánica — una tabla de permisos cerrada anularía esa flexibilidad a propósito.
- F-03 trataba toda alerta por Telegram como el mismo problema, sin distinguir avisos al cliente (ya corregidos para pasar por Efadam) de alertas operativas al propio Mateo (Postgres caído, degradación de modelo, fan-out truncado) — esas últimas fueron una decisión deliberada de una ronda anterior (pendiente 28) y no tienen "cliente" en la conversación.

**Rescatado en ClickUp, con contexto suficiente para no depender del documento original (que se borró — ver abajo):**
- `86bbhaztz` (reabierta): el export de `n8n-workflows/*.json` quedó desactualizado dos veces seguidas; se vuelve hábito obligatorio re-exportar después de cada edición por API.
- `86bbhawp5` (actualizada): el caso de `operation_id` nulo que se salta el tope global de fan-out (F-06, confirmado en el código de "Parsear asignaciones") se agregó como caso a cubrir en la prueba de fan-out ya pendiente.
- `86bbjhdmd` (nueva, alta prioridad): bug confirmado en `reanudador_de_bloqueados` — referencia a un nodo inexistente en el manejador de error, y consumo no determinístico cuando hay más de una aclaración resuelta (F-05).
- `86bbjhdmj` y `86bbjhdmp` (nuevas, en Diseño pendiente): la separación de contenido confiable/no confiable en las llamadas al modelo (versión más liviana que la matriz rígida del auditor) y el flujo transaccional real de aprobaciones con tabla `approvals` — ambas explícitamente marcadas para revisar recién cuando Jarvis traiga entrada externa real, no antes.
- `86bbjhdmu`, `86bbjhdn0`, `86bbjhdn3`, `86bbjhdn9` (nuevas, en Deuda técnica y legal, prioridad baja): separación de roles de Postgres, plantilla de `.env.example` incompleta, respaldo sin regla 3-2-1 ni prueba de restauración, y verificar si un cambio en `reglas_generales` propaga a los `system_prompt` ya compuestos.

El resto del informe (hallazgos ya cubiertos por tareas existentes como el pin de versión de imágenes Docker o la falta de CI) no generó tareas nuevas por ser redundante.

**Decisión sobre el archivo:** el `.docx` original se borró del repo — todo lo que aportaba algo real ya quedó preservado en las tareas de ClickUp de arriba, con el contexto necesario para no depender del documento.

## 22 de agosto de 2026 — Arreglado el bug confirmado de `reanudador_de_bloqueados` (ClickUp `86bbjhdmd`); re-exportados ambos workflows

Mateo confirmó la opción A (re-exportar siempre como hábito) para el pendiente del punto 3 de la ronda anterior, y pidió continuar de forma autónoma con la lista de pendientes.

**Problema 1 — referencia a un nodo inexistente.** El manejador de error de `"Marcar como fallido"` referenciaba `$('Reclamar tarea pendiente')`, un nodo que solo existe en `ejecutor_generico`, no en este workflow. Al pensarlo mejor (no alcanzaba con corregir la referencia, como sugería el ticket original): la query principal de `"Reanudador de bloqueados"` es un `UPDATE ... FROM` masivo sobre potencialmente varias filas a la vez — no hay una sola tarea responsable a la que marcarle `status = 'failed'` si la query falla. "Marcar una tarea como fallida" nunca tuvo sentido para un fallo de este tipo. Se reemplazó el nodo completo por `"Alerta critica reanudador"` (Telegram), replicando exactamente el patrón ya usado y probado en `"Alerta critica Postgres"` de `ejecutor_generico` (mismo `chatId`, mismas credenciales) — un fallo de este workflow es un problema de infraestructura, no de una tarea puntual.

**Problema 2 — consumo no determinístico de aclaraciones múltiples.** Se agregó la migración `schema/010_aclaraciones_consumidas.sql`: columna `tasks.consumed_at timestamptz`, nullable, mismo patrón que `created_at`/`updated_at`. La query principal se reescribió con un CTE `aclaracion_elegida` que usa `SELECT DISTINCT ON (child.parent_task_id) ... ORDER BY child.parent_task_id, child.updated_at ASC, child.id ASC` para elegir exactamente una aclaración resuelta por padre bloqueado (la más vieja primero), y un segundo CTE marca esa fila con `consumed_at = now()` en la misma transacción antes de reanudar al padre. Las aclaraciones resueltas que no se usan quedan con `consumed_at = null` — visibles y no perdidas, pero nunca reutilizadas ni vueltas a evaluar.

**Aplicada la migración a la base real** (`docker cp` + `psql -f`, evita el bug de encoding del pipe de PowerShell). Confirmado con `\d tasks`: la columna existe.

**Nota de proceso — un error real que la propia prueba destapó:** la primera versión de la query usaba `FOR UPDATE OF child` junto con `SELECT DISTINCT ON`, algo que Postgres no permite (`FOR UPDATE is not allowed with DISTINCT clause`). Se descubrió porque el mecanismo de alerta recién construido (Problema 1) capturó el error y mandó la alerta real a Telegram con el mensaje exacto de Postgres — es decir, la corrección del Problema 1 sirvió para diagnosticar en el momento un bug real de la corrección del Problema 2. Se quitó el `FOR UPDATE` (el riesgo de condición de carrera es despreciable para un cron de un solo worker cada 5 minutos) y se corrigió.

**Probado en vivo con datos reales de prueba** (webhook temporal conectado directo a `"Reanudador de bloqueados"`, mismo patrón ya usado en rondas anteriores): tarea 37 (`blocked`), dos hijas de aclaración ya `done` — tarea 38 (más vieja, 10 minutos antes) y tarea 39 (más nueva). Resultado exacto:
- Tarea 37 pasó a `pending`, con el texto de la tarea 38 (la más vieja) correctamente anexado a `input.text`.
- Tarea 38 quedó con `consumed_at` seteado.
- Tarea 39 quedó sin tocar (`consumed_at = null`), disponible pero no perdida.
- Segunda ejecución del mismo webhook: no modificó nada (`{"success":true}` sin `id` — la query ya no encuentra filas elegibles). Confirma idempotencia.

Datos de prueba borrados, webhook temporal removido, workflow verificado sin conexiones colgantes y reactivado (`active: true`, como corresponde a un cron de producción).

**Re-exportados ambos workflows** a `n8n-workflows/ejecutor_generico.json` (40 nodos) y `n8n-workflows/reanudador_de_bloqueados.json` (3 nodos) vía GET fresco con Python y UTF-8 explícito. Verificado sin caracteres de reemplazo (`�`) — el archivo es correcto aunque la consola de PowerShell muestre los acentos mal al imprimirlos.

**ClickUp:** `86bbjhdmd` se marca resuelto. `86bbhaztz` se marca resuelto (re-export hecho); queda como hábito a seguir en cada ronda futura que edite un workflow por API, no como tarea puntual.

## 22 de agosto de 2026 (continuación) — Confirmación end-to-end del fix de `tech_center`; corrupción real de datos introducida y corregida en la misma ronda

**Confirmación end-to-end pendiente, ahora cerrada.** Se insertó una tarea de prueba (id 40, `bot: tech_center`, mismo input que originalmente fallaba en la tarea 33) y se conectó un webhook temporal directo a `"Reclamar tarea pendiente"` en `ejecutor_generico`. El primer disparo del webhook coincidió con un tick real del cron de `"Reanudador de bloqueados"` (recién reactivado) que había vuelto a poner en `pending` una tarea real más vieja (id 36) — como `"Reclamar tarea pendiente"` siempre toma la más vieja por `created_at`, esa fue la que se procesó primero (correctamente, es una tarea real). Un segundo disparo del mismo webhook sí tomó la tarea 40: resultado `status = done`, con `output` conteniendo JSON válido (`asignaciones` con un único bloque bien formado para `tecnico_jefe`), y la tarea hija 41 creada correctamente en `pending`. Confirma en producción, con el flujo real (no aislado), que el fix de `"Normalizar salida del modelo"` funciona de punta a punta.

**Incidente descubierto en el proceso de limpieza: corrupción real de acentos en el workflow en vivo, introducida por esta misma sesión.** Al remover el webhook temporal y volver a desplegar la versión limpia de `ejecutor_generico`, la verificación de rutina (contar caracteres de reemplazo `�` en el archivo re-exportado) encontró **49 ocurrencias reales** — no un artefacto de consola de PowerShell como en la ronda anterior, sino corrupción real ya guardada en la base de datos de n8n. Nombres de nodos completos quedaron rotos: `"¿Hay tarea?"`, `"¿Requiere aprobación?"`, `"¿Necesita aclaración?"`, `"Obtener bot que asignó"`, `"¿Tiene padre?"`, `"Crear tarea de aclaración"`, `"¿Bot que falló no es trouble_shooter?"`, `"¿Falló la llamada a omniroute?"`, además del nombre del workflow (`"Ejecutor genérico"`) y un comentario dentro del código del nodo de manejo de `modelo_desconocido`.

**Causa raíz identificada:** el paso de obtener el workflow actual desde n8n se hizo con `Invoke-RestMethod` de PowerShell seguido de `ConvertTo-Json` — ese roundtrip decodifica mal los caracteres no-ASCII de la respuesta (probablemente por no reconocer el charset UTF-8 del content-type). El archivo resultante ya tenía los 49 caracteres de reemplazo. Ese archivo, ya corrupto, se usó como base para armar el payload "limpio" (sin el webhook temporal) y ese payload se subió de vuelta a n8n con un PUT — es decir, la corrupción de un simple fetch de lectura terminó escrita permanentemente en la base de datos de producción. Se verificó que esto no afectó a `reanudador_de_bloqueados` (0 caracteres de reemplazo, tanto en vivo como en el archivo commiteado): ese workflow se re-exportó la ronda anterior directamente con Python, nunca pasó por PowerShell.

**Nota aparte, no accionable:** al comparar contra el último commit (`daabc86`) para intentar reconstruir los nombres correctos, se encontró que ese archivo commiteado ya tenía **una corrupción distinta y más vieja** en los mismos campos — no un `�` suelto sino la secuencia de 3 caracteres `"ï¿½"` (el resultado de tomar los bytes UTF-8 de un `�` y decodificarlos por error como Latin-1/CP1252 en algún punto anterior, probablemente de una sesión previa). Esa corrupción vieja nunca llegó a afectar el workflow en vivo — solo estaba en el snapshot commiteado — y quedó resuelta como efecto colateral al reemplazar el archivo por el nuevo export verificado.

**Corrección aplicada:** dado que las palabras en español eran inequívocas por contexto (`"genérico"`, `"¿Requiere aprobación?"`, `"asignó"`, `"falló"`, etc. — todas ya usadas literalmente en la documentación de este mismo proyecto), se reconstruyeron a mano y se aplicaron con reemplazo de texto exacto sobre el JSON en memoria (Python puro, sin PowerShell), verificando después de cada paso: JSON sigue siendo válido, conteo de `�` baja de 49 a 0. El payload corregido se subió a n8n vía `urllib` de Python (sin pasar por `Invoke-RestMethod`/`ConvertTo-Json` en ningún punto del camino), y se verificó con un fetch fresco (también en Python) que el estado en vivo quedó en 0 caracteres de reemplazo, 40 nodos, `active: false`.

**Convención reforzada (amplía la decisión "Opción A" de la ronda anterior):** no alcanza con re-exportar siempre después de editar por API — el re-export en sí mismo debe hacerse con Python (`urllib`/`requests` + `json`, UTF-8 explícito), nunca con `Invoke-RestMethod`/`ConvertTo-Json` de PowerShell, en ningún paso de la cadena (ni para leer el estado actual antes de armar un payload, ni para el PUT final, ni para el export a git). PowerShell puede seguir usándose para invocar al script de Python y para operaciones que no toquen el cuerpo JSON de la API de n8n (activar/desactivar, `docker cp`, etc.).

**Estado final de `ejecutor_generico`:** 40 nodos, `active: false`, sin webhooks temporales, nombres de nodos y comentario de código verificados correctos, re-exportado a `n8n-workflows/ejecutor_generico.json` con Python y UTF-8 explícito, 0 caracteres de reemplazo confirmados con lectura binaria del archivo.
