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
