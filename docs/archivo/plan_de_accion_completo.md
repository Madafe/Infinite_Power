# Plan de acción completo — "Infinite power"
### Sistema de agentes autogestionado para el negocio

Para: Mateo · 7 de agosto de 2026 (proyecto individual — ver nota del 17 de agosto, noche, sobre la baja del cofundador)

---

## Actualización — 19 de agosto de 2026, segunda ronda (repo público confirmado; reexport a Git; primer pendiente técnico real cerrado post-pausa) — VIGENTE, léase primero

Mateo preguntó si C1 sigue importando ya que la contraseña vieja del
historial "ya no es esa" (la actual, rotada) — pregunta legítima sobre
severidad práctica, no algo a descartar de plano ni a sobre-defender.
Verificando esa pregunta salió un dato nuevo que cambia el análisis:
**el repositorio es público** (confirmado con `WebFetch` sobre
`github.com/Madafe/Infinite_Power` — etiqueta "Public" visible, contenido
accesible sin login). Esto no estaba considerado en la actualización
anterior. Luego Mateo dio luz verde para avanzar solo con el resto de
pendientes ("avanza con el resto de pendientes hasta que me ocupes") —
esta sección documenta ese trabajo.

### Respuesta a la pregunta de Mateo sobre C1

Tiene razón en la parte concreta: la contraseña vieja (`infpower154`) ya
no sirve para entrar a Postgres — eso quedó neutralizado al rotarla. Pero
eso no hace que el punto 33 (reescribir vs. aceptar el riesgo) sea
irrelevante, por el dato nuevo: al ser el repo **público**, la exposición
nunca fue "solo quien tenga acceso al repo" (que hubiera sido nomás Mateo,
tratándose de un proyecto individual) — fue **internet entero, desde el
momento del push**, incluyendo escáneres automáticos de secretos que
GitHub y terceros corren rutinariamente sobre repos públicos. Eso importa
por dos razones que sí sobreviven a la rotación: (1) si `infpower154` o un
patrón parecido se reutilizó en algún otro lado (otra cuenta, otro
servicio), ese dato ya es público y utilizable ahí; (2) es probable que ya
haya sido cosechado por algún escáner o archivo (GH Archive, Software
Heritage, etc.) desde antes de rotar — lo cual significa que reescribir el
historial del propio repo **no necesariamente deshace la exposición ya
ocurrida**, solo evita que siga siendo cosechable desde ahora en adelante.
Dado esto, mi recomendación concreta (no decisión unilateral, sigue
pendiente confirmación de Mateo en el punto 33): si `infpower154` nunca se
reutilizó en ningún otro lado, **no vale la pena el esfuerzo de
`git filter-repo` + force-push a 5 ramas** — el beneficio marginal es bajo
porque el daño principal (cosecha automática) probablemente ya está hecho
y es irreversible de todos modos; lo que sí vale la pena es (a) confirmar
que la contraseña nueva es única, fuerte, y no reutilizada en ningún otro
lado, y (b) revisar si algo más quedó expuesto en texto plano en algún
otro punto del historial, ya que el repo sí es público y probablemente
seguirá siéndolo.

### Reexport a Git — pendiente 32 cerrado

Se reexportaron `n8n-workflows/ejecutor_generico.json` y
`n8n-workflows/reanudador_de_bloqueados.json` desde la instancia viva de
n8n vía API (mismo mecanismo `Invoke-RestMethod` + `ConvertTo-Json -Depth
100` + `Out-File -Encoding utf8` que ya usaba el export original del 16 de
agosto, para mantener el mismo estilo de archivo y diffs limpios).
Confirmado con `grep` antes de commitear: la SQL de "Obtener config del
bot" ya sale parametrizada (`slug = $1`) y `operation_id` aparece varias
veces en el archivo — el repo ahora sí refleja lo que corre en producción.
El Reanudador de bloqueados no tuvo cambios reales (ya estaba al día desde
antes del 16/ago, ver actualización anterior).

### Primer pendiente técnico real, cerrado post-pausa: "Obtener config del bot" no distinguía bot inexistente de bot existente

Con luz verde de Mateo para avanzar, se atacó el pendiente 39 (antes
documentado en `ejecutor_generico.md` como punto 3 de "Lo que falta"). El
diagnóstico original decía "necesita un IF explícito" — construirlo así,
tal cual, **no hubiera funcionado**: se confirmó en vivo (`includeData=true`
sobre la ejecución de prueba) que el nodo Postgres con 0 filas en
`executeQuery` emite **cero items en ambas salidas**
(`"data":{"main":[[],[]]}`), ni siquiera activa la rama de error — así que
cualquier IF conectado después simplemente nunca se evalúa, la ejecución
muere en silencio en esa rama exactamente como describía el bug original.
El fix real necesitó dos piezas, no una: (1) `alwaysOutputData: true` en
el nodo "Obtener config del bot", para forzarlo a emitir un item vacío
cuando no hay fila; (2) un nodo IF nuevo, "Bot encontrado"
(`{{ $json.id }}` notEmpty, mismo patrón que el ya usado en "¿Hay tarea?"),
más un Code node nuevo, "Preparar error bot no encontrado", que arma un
mensaje claro (`Bot no encontrado o inactivo: <slug>`) y lo enruta a
"Preparar fallo" igual que cualquier otro error real. Probado en vivo dos
veces con la técnica ya establecida (webhook temporal + activar +
disparar + revisar ejecución + limpiar): (1) tarea con
`bot = 'bot_que_no_existe'` → terminó `failed` con el mensaje correcto,
disparó correctamente una tarea de Trouble shooter con
`nivel_importancia` heredado, que a su vez diagnosticó el problema real
sin ayuda ("No se encontró el bot 'bot_que_no_existe' en el sistema...");
(2) tarea con un bot válido (`tecnico_jefe`) → terminó `done` sin ninguna
regresión. 28 nodos en el workflow ahora (eran 26). Todos los datos y
archivos de prueba se limpiaron, workflow reexportado y desactivado de
nuevo al terminar.

---

## Actualización — 19 de agosto de 2026 (corrección de Mateo: "cerrado en n8n vivo" ≠ "cerrado en el proyecto versionado" — C1-C5 reevaluados con evidencia) — vigente

Le pedí a Mateo que anotara como pendiente "revisar los C en general" (ver
punto 31 del checklist), y en vez de esperar a que yo lo hiciera le
respondí con un resumen del estado de C1-C5. Mateo corrigió ese resumen
con seis puntos concretos, cada uno con evidencia (número de línea de
archivo, o el hecho de que la auditoría original solo llega a C4). Antes
de escribir esta actualización verifiqué cada uno de los seis contra la
fuente primaria (git log, contenido real de los archivos, texto original
de `auditoria_tecnica_y_vision_17ago2026.md`) — no los di por buenos solo
porque venían de Mateo, igual que él me pide no dar nada por bueno solo
porque lo dice un documento. Los seis se confirmaron exactos.

### El error de fondo en mi resumen anterior

Confundí dos cosas distintas: "el bug ya no existe si le mando una tarea
de prueba a la instancia de n8n corriendo ahorita" y "el proyecto, tal
como está versionado en Git, ya no tiene el bug". Casi todas las
correcciones de C1-C5 esta semana se hicieron editando el JSON del
workflow **directo en la instancia de n8n vía su API REST** (GET → editar
`parameters.query` en memoria → PUT) — nunca se volvió a exportar ese
workflow a `n8n-workflows/*.json` después. Confirmado con
`git log --oneline -- n8n-workflows/`: el único commit que toca esa
carpeta es `0fe3d88`, del 16 de agosto ("Bloque 0: exporta workflows...") —
anterior a **todas** las correcciones de C2, C3, el bug de manejo de
errores, y la construcción completa de operaciones. El repositorio, si
alguien lo clona hoy y lo importa a un n8n limpio, reproduce los bugs
originales — no lo que corre ahorita en la instancia de Mateo.

### Los seis puntos, verificados uno por uno

**1. C1 (contraseña de Postgres) — mitigado, no cerrado.** Confirmado con
`git log --all -p -- docker-compose.yml`: la contraseña vieja
(`infpower154`) sigue en el historial y es alcanzable desde las 5 ramas
remotas (`main`, `alphav0.1`, `alphav0.2`, `efadam`, `correcciones`). Más
importante: el texto original de C1 en la auditoría ya incluía un paso 4
explícito — "Coordinar reescritura del historial remoto. Rotar primero;
limpiar historial después" — que nunca se ejecutó. Rotar la contraseña en
Postgres (hecho, probado en vivo) cierra el riesgo *hacia adelante*, pero
no borra la exposición *hacia atrás*: cualquiera con acceso al repo, a un
clon viejo, o a un fork, puede sacar `infpower154` del historial con
`git log -p`. Queda como pendiente real (ver checklist): reescribir el
historial (`git filter-repo` + force-push a las 5 ramas, asumiendo que
cualquier clon/fork previo sigue teniendo el secreto expuesto de todos
modos) o aceptar el riesgo residual explícitamente y documentarlo como tal
— es una decisión de Mateo, no algo que se resuelva solo.

**2 y 3. C2 (inyección SQL) y C3 (`nivel_importancia` perdido en tareas
hijas) — corregidos en n8n vivo, no reflejados en Git.** Confirmado
leyendo `n8n-workflows/ejecutor_generico.json` línea por línea ahora
mismo: la línea 87 todavía dice
`"query": "SELECT * FROM bots WHERE slug = '{{ $json.bot }}' AND active = true LIMIT 1;"`
— exactamente la inyección que describía C2, sin parametrizar. Un
`grep -n "operation_id|nivel_importancia"` sobre el archivo completo
encuentra un solo resultado (`nivel_importancia` dentro del `jsonBody` de
"Llamar a omniroute") — "Crear tareas hijas" en el export no inserta
`nivel_importancia`, tal como describía el C3 original, y `operation_id`
no aparece ni una sola vez: el concepto completo construido ayer no existe
en el archivo versionado. Estado correcto: **corregidos en la instancia de
n8n, pendientes de exportación/versionado** — no "cerrados".

**Corrección adicional sobre C3 específicamente:** dije que "no era un
hallazgo nuevo, ya estaba cubierto por el pendiente #8" — eso fue un
error. El texto original de la auditoría (`auditoria_tecnica_y_vision_17ago2026.md`,
línea 53) es explícito: *"Parsear asignaciones no conserva
nivel_importancia y Crear tareas hijas no lo inserta"* — era un hallazgo
real sobre el estado que se auditó. Que la corrección ya estuviera
planeada o parcialmente construida antes de esa auditoría no cambia que el
export auditado tenía el bug. Lo correcto: **resuelto en vivo, pendiente
de sincronización** — igual que C2, no un caso aparte.

**4. C4 (aprobación humana bidireccional) — sigue abierto, pero corrijo un
error mío: la tabla `approvals` sí existe.** Confirmado en
`schema/001_init.sql`, alrededor de la línea 56-64: `CREATE TABLE
public.approvals (id, task_id, requested_at, resolved_at, approved,
approver)`. Dije que no existía — falso. Lo que sí falta, tal como decía
el texto original de C4, es el workflow que la use: registrar la decisión,
validar quién responde, y hacer que eso dispare una transición de estado
atómica (continuar o cancelar la tarea) — hoy `needs_approval` solo manda
un mensaje de Telegram sin ruta de vuelta. El hueco es de lógica de
workflow, no de schema — más angosto de lo que dije, pero sigue sin
resolverse.

**5. C5 — no es un hallazgo de la auditoría del 17 de agosto.** Confirmado
con una búsqueda de `C[1-9]` sobre `auditoria_tecnica_y_vision_17ago2026.md`
completo: solo aparecen C1, C2, C3, C4 (líneas 26, 41, 53, 61). "C5" es una
etiqueta que empezamos a usar después, el 18 de agosto, para nombrar el
bug real de manejo de errores en el Ejecutor genérico (normalización de
forma de error + `.first()` vs `.item()` en "Preparar fallo") — nunca
estuvo en la auditoría original. La nota de "Corrección de nombres" que
dejé en `ejecutor_generico.md` decía "redefinir el nombre hacia adelante",
lo cual todavía daba a entender que venía de la auditoría — se corrige
abajo para dejar claro que ese bug (ya cerrado, con prueba en vivo) nunca
fue "C5" de nada, es solo un bug con nombre propio.

**6. El pendiente de "Reanudador de bloqueados: convertir Manual a
Schedule" estaba mal, pero al revés del patrón de arriba — aquí el export
sí está al día y mi lista era la desactualizada.** Confirmado leyendo
`n8n-workflows/reanudador_de_bloqueados.json`: `"active": true`, con un
nodo `n8n-nodes-base.scheduleTrigger` ("Cada 5 minutos",
`minutesInterval: 5`), `updatedAt: 2026-08-15`. Ese pendiente (anotado en
`ejecutor_generico.md`, "Lo que falta", punto 4) ya estaba resuelto desde
antes del 16 de agosto y nadie lo volvió a verificar antes de seguir
repitiéndolo en las listas — se corrige ahí también.

### Riesgos que faltaban en mi resumen (agregados al checklist, sin resolver)

Mateo señaló que mi resumen omitía varios riesgos ya identificados en
rondas anteriores o nunca antes puestos en la lista central: **prompt
injection entre agentes** (contenido de una tarea hija, generado por un
modelo, termina interpretado como instrucción de sistema en la siguiente
tarea — ej. `parent_input` inyectado sin sanitizar en el prompt de
"Llamar a omniroute"), **límites de fan-out/costo** (nada impide hoy que
una operación genere una cadena de tareas hijas sin tope, ni existe un
tope de gasto por operación o por ventana de tiempo), **puertos Docker
expuestos** (falta revisar `docker-compose.yml` — qué puertos están
publicados al host/red y si deberían estarlo), **imágenes `latest` sin pin
de versión** en `docker-compose.yml` (un `docker compose pull` puede
romper todo sin aviso, sin forma de volver atrás a una versión conocida),
y **ausencia de pruebas automatizadas / CI**. Se agregan al checklist como
pendientes nuevos, sin fecha de resolución todavía.

### Inconsistencia nueva, encontrada al verificar esto (no buscada a propósito)

`operations.nivel_importancia` se diseñó ayer (18/ago, cuarta ronda) para
fijarse **una sola vez, al abrir la operación, y no cambiar después** —
pero las "Reglas de asignación" de `stack_y_convenciones.md` (15 de
agosto) clasifican **por tarea**, por dominio/tema ("gasto de dinero",
"publicación de contenido público", etc.), y dicen explícitamente que ante
ambigüedad el nivel "sube... nunca se redondea hacia abajo". Con el
mecanismo de operaciones fijado ayer, una tarea hija que caiga
objetivamente en una fila de nivel más alto que su operación (ej. una
operación clasificada `medio` que termina redactando una publicación
pública, que por regla debería ser `critico`) hereda el nivel fijo de la
operación sin poder subir nunca — exactamente el modo de falla que
describía el C3 original ("una tarea legal, pública o de seguridad puede
no usar el nivel exigido"), reintroducido sin querer por el mecanismo que
se construyó ayer mismo para organizar todo esto. No lo resolví — es una
decisión de arquitectura de Mateo, no mía. Mi recomendación inicial, a
confirmar: que el nivel efectivo de una tarea sea
`max(nivel de la operación, nivel que le tocaría por las reglas de
asignación de stack_y_convenciones.md)` — nunca baja del piso fijado por
Efadam al abrir la operación, pero puede subir si una tarea específica
cae en un dominio más sensible; sin ronda de ida y vuelta a Efadam para el
caso común, preservando la garantía de "nunca se redondea hacia abajo" que
ya existía antes de operaciones.

### Siguiente paso más importante, antes de activar Efadam

Reexportar el n8n vivo actual (Ejecutor genérico y Reanudador de
bloqueados) a `n8n-workflows/*.json` y confirmar con revisión línea por
línea (no solo "el JSON es válido") que el export coincide con lo
instalado. Sin esto, ningún hallazgo puede llamarse "cerrado" de forma
auditable desde el repo — y cualquier decisión futura, incluida la de
reescribir el historial de Git por C1, se estaría tomando sobre
información parcial. Se sube al principio del checklist, antes incluso de
activar Efadam.

---

## Actualización — 18 de agosto de 2026, noche (pausa — merge `correcciones` → `main`) — vigente

Mateo pidió pausar y mergear `correcciones` a `main` en GitHub. `main`
estaba en `b41c7e2` (mismo commit que `alphav0.2`) — desde ahí, `main` es
ancestro directo de `correcciones` (confirmado con `git merge-base
--is-ancestor` antes de tocar nada), así que el merge fue **fast-forward
limpio**, sin conflictos y sin commit de merge — `main` ahora apunta al
mismo commit que `correcciones` (`d284a28`), con las 34 commits de esta
rama de trabajo incluidas completas. Pusheado a `origin/main`. La rama
`correcciones` **no se borró** — sigue viva y es donde continúa el trabajo
cuando se retome, según la política de ramas de Mateo (nunca se borran ni
mergean sin instrucción explícita — ver actualización del 16 de agosto,
tarde/noche, punto 2). `alphav0.1`, `alphav0.2`, `efadam` quedan intactas,
sin tocar.

---

## Actualización — 18 de agosto de 2026, noche, cuarta ronda ("operaciones" construido y probado en vivo, con 2 bugs reales de paso corregidos) — vigente

Mateo respondió las dos preguntas abiertas de la ronda anterior en el mismo
mensaje: (1) sí, mezclar `nivel_importancia` con `operations`, pero sin
borrar y reconstruir lo que ya funcionaba; (2) las operaciones tienen que
estar **centralizadas** en Efadam — "si no se elimina el cuello de
botella". Con las dos respuestas, el diseño quedó cerrado y se construyó de
verdad (schema + 3 nodos del Ejecutor genérico + prueba en vivo), no solo
documentado.

### 0. Cómo se resolvieron las dos decisiones juntas

Las dos respuestas de Mateo terminaron encajando mejor de lo que parecía en
la ronda anterior: al ser Efadam el único que abre una operación, la
pregunta que había quedado abierta sobre nivel_importancia ("¿quién le
asigna nivel a una operación autoiniciada que nunca pasa por Efadam?") deja
de existir — toda operación pasa por Efadam, así que Efadam siempre puede
fijar el nivel al abrirla. Y sobre "no borrar uno y crear otro de cero": se
interpretó como que el código de herencia de `nivel_importancia` ya
construido y probado (`Parsear asignaciones`, con `.first()` sobre
`Reclamar tarea pendiente`, que no tiene el problema de `.item()` porque
corre en la rama de éxito, no en una de error rescatado) **no se toca**.
Se agregó `operations.nivel_importancia` como la fuente conceptual del
valor — Efadam la fija una vez al abrir la operación, la copia también a
la tarea raíz, y de ahí la cadena de herencia que ya existía hace el resto
sin ningún cambio de código.

### 1. Schema construido y corrido contra Postgres real

`schema/007_operaciones.sql` — tabla `operations` (`id, tipo, titulo,
descripcion, nivel_importancia, status, created_at, updated_at,
closed_at`) y `tasks.operation_id` (nullable, FK a `operations`). Corrido
vía `docker cp` + `psql -f` dentro del contenedor (no pipe de PowerShell —
regla adoptada el 16 de agosto tras el mojibake de esa ronda, seguida esta
vez desde el principio). Verificado con `\d operations` y sin mojibake en
los comentarios.

### 2. Decisión de diseño: `operation_id` se propaga por subquery SQL, no por referencia cruzada de n8n

A diferencia de `nivel_importancia` (que depende de `$('Nombre del
nodo').first()` dentro de un Code node — el mecanismo exacto que causó el
bug de `.first()` vs `.item()` de la ronda anterior), `operation_id` se
propaga con un subquery dentro del mismo `INSERT` SQL
(`(SELECT operation_id FROM tasks WHERE id = $N)`), usando un parámetro
que la query ya recibía de todos modos (`parent_task_id`). Cero
referencias cruzadas nuevas de n8n para este campo — se aprendió la
lección de la ronda anterior y se aplicó desde el diseño, no después de
que fallara.

### 3. Dos bugs reales encontrados y corregidos de paso, no buscados a propósito

Al tocar las 3 queries que crean tareas (para agregarles `operation_id`),
salieron dos gaps reales de `nivel_importancia` que nunca se habían
corregido:

- **"Crear tarea de aclaración"** nunca había puesto `nivel_importancia` a
  la tarea que crea — si esa tarea llegaba a procesarse, iba a fallar en
  "Llamar a omniroute" con `400 Missing model` (el mismo bug ya visto dos
  veces antes en otros puntos). Corregido con el mismo patrón de subquery.
- **"Despachar a trouble_shooter"** tampoco lo hacía — **cada tarea de
  Trouble shooter auto-despachada nacía con `nivel_importancia = null` y
  estaba condenada a fallar**, sin excepción. Lo que la ronda anterior
  documentó como "bonus, no buscado a propósito: la tarea de
  trouble_shooter despachada también falló" no era una coincidencia útil
  para probar el guard anti-loop — era este bug, atrapado en el momento
  pero sin identificar la causa real. El mecanismo de auto-dispatch creaba
  la tarea correcta, pero esa tarea nunca podía completarse. Corregido.

### 4. Probado en vivo, dos veces, misma técnica de webhook temporal

1. Operación de prueba (`nivel_importancia: medio`) + tarea raíz para
   `tecnico_jefe` con ese `operation_id` → la tarea hija que "Crear tareas
   hijas" generó para `coder` salió con `operation_id` y
   `nivel_importancia` correctos.
2. Fallo forzado en "Obtener config del bot" (mismo query roto que la
   ronda anterior) sobre una tarea con `nivel_importancia = medio` y
   `operation_id` puesto → la tarea de `trouble_shooter` auto-despachada
   salió con **`nivel_importancia = medio`** (antes habría salido `null`)
   y `operation_id` correcto — confirma en vivo los dos arreglos del punto
   3, no solo en el papel.

Datos de prueba borrados después, workflow devuelto a 26 nodos/`active:
false`. Detalle nodo por nodo completo, con el SQL final de cada uno, en
`ejecutor_generico.md`.

### 5. Qué queda pendiente de esto

**Nada abre una `operations` de verdad todavía** — el diseño quedó
centralizado en Efadam y Efadam no existe como bot activo, así que hoy no
hay ningún punto real del sistema que inserte una fila nueva ahí (solo se
puede probar a mano, como se hizo). Se destraba junto con Bloque 3
(activar Efadam). El "Prompt de sistema" de `efadam.md` (el bloque final
para pegar en n8n) **no se tocó a propósito** — Mateo dijo que lo va a
ajustar él mismo; se dejó una nota en el archivo señalando qué le falta
mencionar (`operations`, la regla de "vuelve a preguntar si necesitas
abrir un hilo nuevo") para que su edición no tenga que redescubrirlo.

---

## Actualización — 18 de agosto de 2026, noche, tercera ronda (decisión sobre Pollinations/Qwen, y propuesta de un concepto nuevo: "operaciones") — vigente

### 0. Pendiente #24 cerrado (por ahora): no seguir con Pollinations/Cloudflare/Qwen mientras se construye

Mateo, textual: "No, al menos para la construcción no, después ya veremos."
Se cierra el pendiente #24 con esta decisión — NVIDIA sigue siendo el único
proveedor real de OmniRoute mientras dure la fase de construcción. Se
retoma la pregunta de si vale la pena sumar más proveedores cuando el
sistema ya esté operando, no antes. No se tocó ninguna conexión existente.

### 1. Propuesta de Mateo: un concepto nuevo, "operación"

Mateo, textual: "Vamos a crear un nuevo sistema: para poder trackear de una
mejor manera las tareas y que no se mezclen las instrucciones ni el orden
en el que debe ir progresando una tarea, por cada cosa que el programa
completo debe hacer vamos a llamarlo una operación, ya sea cosas automáticas
e independientes como las investigaciones o la autoexpansión o tareas
específicas que vienen del usuario, así Efadam también puede llevar un
mejor registro."

**Evaluación (no es solo "sí, dale" — el hueco es real).** Hoy `tasks` solo
tiene `parent_task_id`: una tarea puede saber quién la creó directamente,
pero no hay ninguna columna que diga "esto es parte del mismo hilo de
trabajo más grande" sin recorrer la cadena de padres a mano (una consulta
recursiva, propensa a error, y que no sirve para nada que todavía no tenga
ninguna tarea creada — ej. una operación de investigación que Upgrade &
review center apenas está por arrancar). Tampoco hay ningún lugar para
guardar metadata a nivel de "todo este esfuerzo" — título, objetivo, tipo
(usuario vs. automática), estado agregado — sin inventarlo cada vez a mano.
Es un hueco real, no cosmético, y la relación con `cluster` es distinta a
lo que parecía a primera vista: `cluster` es el departamento que ejecuta un
paso puntual (`tech-center`, `legal`), no el hilo completo — una misma
operación puede cruzar varios clusters en su vida (ej. una operación abre
en Legal, después pasa por Proyect center). No es redundante con nada que
ya exista.

**Conexión con un pendiente ya documentado, para no duplicar:** el
"Setup en Proyect center" (pendiente #19 original, "entrevista de objetivo →
meta + pasos + criterio de listo") es un concepto relacionado pero distinto
— Setup es la entrevista que define la meta de un **proyecto** de negocio
completo (nivel más alto, vive solo en Proyect center). Una "operación" es
la unidad de ejecución/trackeo (nivel más bajo, vive en todo el sistema) —
un proyecto probablemente termina generando varias operaciones a lo largo
del tiempo, pero no son lo mismo. No se conflate uno con otro.

**Diseño propuesto (para confirmar antes de construirlo):**

Tabla nueva `operations` (nombre en inglés — consistencia con el resto del
schema: `tasks`, `bots`, `approvals`, `agent_runs`; la prosa y el nombre
conversacional siguen siendo "operación" en español):

```sql
create table if not exists operations (
    id                 serial primary key,
    tipo               text not null,   -- 'usuario' | 'investigacion' | 'autoexpansion' | ... (sin CHECK: se espera que la lista crezca, igual que `cluster`)
    titulo             text not null,
    descripcion        text,
    origen_cluster     text,            -- qué cluster/bot la abrió — referencia, no autoridad
    status             text not null default 'abierta',  -- abierta | en_progreso | completada | fallida | bloqueada
    created_at         timestamptz not null default now(),
    updated_at         timestamptz not null default now(),
    closed_at          timestamptz
);

alter table tasks add column if not exists operation_id int references operations(id);
```

`operation_id` se propaga de padre a hijo exactamente con el mismo patrón
que ya existe para `nivel_importancia` (heredado en "Crear tareas hijas" /
"Parsear asignaciones"), y también en "Crear tarea de aclaración" y en el
disparo automático a Trouble shooter (la tarea de troubleshooting pertenece
a la MISMA operación que la tarea que falló — no abre una nueva). Una tarea
de primer nivel (sin padre) es la que crea la fila nueva en `operations`.

**Lo que decidí no meter en esta propuesta, a propósito, para no
sobrecargarla:** mover `nivel_importancia` de `tasks` a `operations`
(asignado una sola vez por operación en vez de heredado tarea por tarea)
sería una simplificación real — de hecho el bug de esta misma noche
(herencia rota por `.first()` vs `.item()`) fue justo en la cadena de
herencia de `nivel_importancia`. Pero tocar esa regla ahora mismo — que hoy
vive en `efadam.md` como "Efadam es la única fuente de ese valor" — es un
cambio aparte con su propia complicación (¿quién le asigna nivel a una
operación de investigación autoiniciada que nunca pasa por Efadam?). Lo
dejo anotado como mejora futura posible, no incluida en esta ronda a menos
que Mateo prefiera resolver las dos juntas.

**Pregunta abierta real — la única parte del diseño que no es un default
obvio:** ¿quién puede abrir una operación nueva? Dos opciones:

- (a) **Descentralizado, igual que `tasks` hoy** — cualquier cluster/bot que
  arranca un hilo de trabajo nuevo (no solo Efadam) inserta la fila en
  `operations`, mismo patrón que ya existe para crear tareas de cualquier
  cluster hacia cualquier otro sin pasar por Efadam. Esto es lo que
  recomiendo por default — es consistente con cómo ya funciona el
  despacho de tareas, y no le agrega fricción a que Upgrade & review center
  arranque una investigación por su cuenta.
- (b) **Centralizado en Efadam** — ninguna operación existe sin que Efadam
  la registre primero, igual que el cuello de botella que ya existe para
  `knowledge_log`/`system_knowledge`. Más consistente con "Efadam lleva el
  registro", pero le agrega un round-trip a todo trabajo autoiniciado que
  hoy no lo necesita, y ese cuello de botella hoy solo aplica a
  conocimiento, no a tareas.

Recomiendo (a) y sigo con ese default salvo que Mateo diga lo contrario —
ninguna otra parte del diseño depende de mi criterio, así que no se bloqueó
nada más esperando esta respuesta.

**No se construyó nada todavía** — ni el schema, ni los cambios a los nodos
de `ejecutor_generico.md` que tendrían que propagar `operation_id`. Se
espera confirmación de Mateo (sobre todo del punto de "quién abre una
operación") antes de tocar Postgres o n8n en vivo.

---

## Actualización — 18 de agosto de 2026, noche, segunda ronda (hallazgo C5 corregido de verdad — y la corrección desmiente parte de la corrección anterior) — vigente

Mateo pidió dos cosas en el mismo mensaje: la contraseña nueva de Postgres
(ya generada la ronda anterior, se la pasó directo) y "arregla los nodos" —
el pendiente #1 que había quedado documentado como "hallazgo C5" (13 nodos
con, supuestamente, el mismo bug de manejo de errores que "Llamar a
omniroute"). Antes de tocar 13 nodos con el mismo parche a ciegas, se probó
en vivo si de verdad tenían el mismo problema — **y no lo tenían.** El
diagnóstico de la ronda de la tarde estaba mal en su parte central.

### 0. Lo que se creía vs. lo que se probó

La ronda de la tarde había confirmado (correctamente) que "Llamar a
omniroute" (HTTP Request) no rutea sus errores a la salida de error que
`onError: continueErrorOutput` debería usar. De ahí generalizó, sin
probarlo, a que los otros 13 nodos (todos Postgres o Code, más un Telegram)
tenían el mismo problema. Esta ronda se probó cada tipo por separado,
forzando un fallo real y mirando la ejecución real: **Postgres, Code y
Telegram rutean el error correctamente, de fábrica** — sin necesitar ningún
arreglo tipo el de omniroute. La explicación más probable de por qué
omniroute es distinto: el nodo HTTP Request no lanza una excepción real
ante un `400` de OmniRoute (lo trata como respuesta HTTP válida), así que
`continueErrorOutput` nunca llega a activarse para ese nodo en particular —
no es que el mecanismo esté roto en general.

### 1. El bug real, encontrado al conectar el flujo completo con una tarea real

Con las salidas de error confirmadas correctas, apareció el problema
genuino: **"Marcar como fallida" necesita `{taskId, errMsg}`, pero cada
tipo de nodo entrega su error en una forma distinta** (objeto anidado en
Postgres, string simple en Code, etc.) — conectar esas salidas directo a
"Marcar como fallida" sin transformar el dato hace que la actualización
corra con parámetros vacíos, sin fallar pero sin actualizar nada tampoco.
Y al generalizar el nodo Code que ya existía para normalizar esto
("Preparar fallo") a las 17 rutas nuevas, se encontró un segundo problema:
`$('Reclamar tarea pendiente').first().json.id` — que llevaba semanas
funcionando para la ruta de omniroute — falla cuando ese Code node se
alcanza a través de una salida de error rescatada por `continueErrorOutput`
de otro nodo. Probado en vivo: `.first()` y `.all()[0]` fallan, `.item` y
`.itemMatching(0)` funcionan. Se cambió a `.item`.

### 2. Arreglo aplicado

Las 17 salidas de error que antes iban directo a "Marcar como fallida"
ahora pasan todas por "Preparar fallo" (generalizado para normalizar
cualquier forma de error, y corregido para usar `.item`). Cero nodos
nuevos — solo se re-conectaron 17 conexiones existentes y se reescribió la
lógica de un nodo Code que ya existía. Detalle exacto (código, lista
completa de las 17 rutas, y por qué) en `ejecutor_generico.md`, sección
"Hallazgo grande del 18/ago", que quedó reescrita para reflejar esta
corrección.

**Probado en vivo de punta a punta, con datos reales, dos rutas
distintas** (no solo un nodo aislado): se insertó una tarea real, se
disparó desde el trigger real (no un webhook conectado directo al nodo
roto), y se confirmó que la tarea terminó `failed` con el error real y que
se despachó automáticamente una tarea nueva para `trouble_shooter` — una
vez forzando el fallo en un nodo Postgres ("Obtener config del bot"), otra
vez forzando el fallo de OmniRoute como en la ronda original. **Bonus no
buscado:** la tarea de Trouble shooter despachada en la primera prueba
también falló (heredó el mismo problema de su tarea padre), y la guarda
contra auto-despacho en loop (`¿Bot que falló no es trouble_shooter?`)
funcionó exactamente como se diseñó — confirmado en vivo, no solo en
teoría.

### 3. Lo que queda sin confirmar

Los 4 nodos IF con `onError: continueErrorOutput` (`¿Este bot despacha
tareas?`, `¿Requiere aprobación?`, `¿Requiere aprobación?1`, `¿Tiene
padre?`) se conectaron a "Preparar fallo" por consistencia, pero no se
logró forzar un error genuino en un IF para confirmar en qué salida cae de
verdad (dos intentos distintos evaluaron la condición como falsa en vez de
lanzar error). Sin urgencia — los IF de este workflow rara vez deberían
fallar — pero queda anotado como no confirmado, no como corregido con
certeza.

También quedó expuesto un gap nuevo, no resuelto: si "Reclamar tarea
pendiente" mismo falla (Postgres no responde desde el principio), no hay
ningún `task_id` todavía, así que "Marcar como fallida" no tiene nada que
actualizar — ese caso (el más grave: Postgres caído) hoy no queda
registrado en ningún lado. Necesitaría un canal de alerta aparte, no una
fila en `tasks`. Ver `ejecutor_generico.md`, "Lo que falta", punto 1.

### 4. Nota sobre el proceso, no solo el resultado

Vale la pena dejar anotado el patrón, no solo el resultado: la ronda de la
tarde generalizó un hallazgo confirmado en un nodo a otros 13 sin probarlos,
y esa generalización no se sostuvo. La forma de evitarlo — probar cada tipo
antes de aplicar el mismo parche a todos — es la que se usó esta ronda, y
es la que vale la pena mantener de aquí en adelante para hallazgos de este
tipo (comportamiento de una herramienta de terceros, no lógica propia).

---

## Actualización — 18 de agosto de 2026, noche (rotación de la contraseña de Postgres — hallazgo C1 cerrado, probado en vivo de punta a punta) — vigente

Mateo dijo "dale con la contraseña de postgres" — autorización explícita
para proceder con la rotación que la ronda anterior había pospuesto por
prudencia. Se hizo con el mismo cuidado que se había planeado: los 4 pasos
coordinados (Postgres, `.env`, credencial de n8n, reinicio), verificando
cada uno antes de seguir al siguiente, y una prueba en vivo real al final
en vez de asumir que quedó bien.

### 0. Contraseña nueva

Generada con `secrets.choice` de Python, 32 caracteres alfanuméricos (sin
símbolos, para evitar problemas de escapado en SQL/PowerShell/JSON al
manipularla). Reemplaza a `infpower154` — la contraseña anterior, que
coincidía casi literalmente con el nombre de usuario (`infpower`) y estaba
expuesta en el historial de git, el motivo original del hallazgo C1.

### 1. Los 4 pasos, en orden

1. **`ALTER USER infpower WITH PASSWORD '...'`** ejecutado directo contra
   Postgres (`docker exec -i ... psql`, con la contraseña vieja todavía
   activa hasta este punto). Confirmado con `ALTER ROLE` en la respuesta.
2. **`.env` actualizado** (`POSTGRES_PASSWORD=`) inmediatamente después,
   para minimizar la ventana en la que Postgres ya tiene la contraseña
   nueva pero el archivo de config todavía dice la vieja.
3. **Credencial "Postgres account" de n8n actualizada** vía
   `PATCH /api/v1/credentials/{id}` con los mismos datos de conexión
   (`host: postgres`, `database: infinite_power`, `user: infpower`,
   `port: 5432`, `ssl: disable`) y la contraseña nueva. El primer intento
   dio `500 Internal Server Error` sin explicación clara en el cuerpo de
   la respuesta; reintentar el mismo request funcionó (`200 OK`) — no se
   investigó la causa del primer fallo, parece transitorio del lado de
   n8n, no algo que dependiera de los datos enviados.
4. **`docker compose up -d n8n`** para que n8n releyera
   `DB_POSTGRESDB_PASSWORD` desde el nuevo `.env` (esa variable solo se
   lee al arrancar el proceso, no se puede "recargar en caliente"). Nota
   técnica: aunque el comando pidió solo el servicio `n8n`, Docker Compose
   también recreó `infinite-power-postgres-1`, porque su bloque de
   `environment` en `docker-compose.yml` también referencia
   `${POSTGRES_PASSWORD}` y Compose considera que su configuración
   resuelta cambió. Esto no fue un problema: la imagen de Postgres solo
   usa `POSTGRES_PASSWORD` para inicializar un directorio de datos vacío
   la primera vez — como el volumen (`./data/postgres`) ya tenía datos, la
   recreación no tocó la contraseña real (esa la puso el `ALTER USER` del
   paso 1) ni ningún dato. Ambos contenedores confirmados `Up` después,
   sin errores de conexión en los logs de n8n (arrancó limpio, reactivó
   `"Reanudador de bloqueados"` solo, sin fallos de autenticación contra
   su propia base).

### 2. Prueba en vivo — no solo "n8n arrancó bien", sino que los nodos del workflow conectan de verdad

Arrancar sin errores demuestra que la conexión *interna* de n8n (workflows,
ejecuciones, login) quedó bien, pero esa es una conexión distinta de la
credencial `"Postgres account"` que usan los nodos Postgres de los
workflows (`"Reclamar tarea pendiente"`, etc.) — quedarse solo con la
primera prueba habría sido conformarse con una verificación parcial. Se
usó la técnica ya documentada de webhook temporal: se agregó un nodo
Webhook conectado directo a `"Reclamar tarea pendiente"`, se activó el
workflow, se disparó con un `curl` real, y se revisó la ejecución
resultante (`id 682`) vía `GET /executions/{id}?includeData=true`:
`status: success`, sin `error`, y el nodo Postgres devolvió un resultado
limpio (no había tareas `pending` reales en ese momento, así que no
reclamó ninguna — pero la conexión y la query corrieron sin fallo de
autenticación, que es lo que se estaba probando). Después se quitó el
nodo Webhook y se desactivó el workflow, dejándolo exactamente como
estaba antes (26 nodos, `active: false`). Se confirmó además que la tabla
`tasks` sigue con las mismas 10 filas de antes, todas `done` — la prueba
no modificó ni creó datos.

### 3. Qué queda de esto

**Hallazgo C1 cerrado.** La contraseña vieja (`infpower154`) sigue técnicamente
visible en commits antiguos del historial de git — rotarla no borra el
historial — pero como ya no es válida contra el Postgres real, esa
exposición pasada dejó de ser un riesgo vivo (nadie puede usarla para
entrar a nada hoy). No se reescribió el historial de git para eliminarla
(`git filter-repo`/BFG) porque el riesgo ya está neutralizado y reescribir
historial en un repo con más commits trae su propio riesgo de romper
referencias — se deja fuera de alcance salvo que Mateo pida limpiarlo de
todos modos por higiene.

No se tocó `N8N_ENCRYPTION_KEY` ni ningún otro secret en esta ronda — solo
la contraseña de Postgres, que era el pendiente puntual que Mateo
autorizó.

---

## Actualización — 18 de agosto de 2026, tarde-noche (Mateo pasó la API key de n8n; se construyó y probó en vivo el disparo automático a Trouble shooter; se encontró y corrigió un bug grande de manejo de errores que llevaba desde el inicio; SQL injection cerrada; nivel_importancia ya se propaga a tareas hijas; 2 tareas reales del backlog se repararon; rotar password de Postgres resultó más riesgoso de lo asumido y se pospuso a propósito) — vigente

Mateo mandó la API key de n8n directo en el chat, con tres instrucciones
explícitas: anotarla en algún lado, dejarla anotada también como pendiente
de eliminar "al final", y que de aquí en adelante Claude sea quien edite
n8n — "no quiero editar yo n8n, me lleva mucho tiempo". Pidió agregar el
nodo de disparo automático a Trouble shooter y seguir con el resto de
pendientes sin detenerse a preguntar en cada paso. Esta ronda: (1) se
guardó la key, (2) se construyó y probó en vivo el disparo automático, (3)
en el camino se encontró un bug de fondo en el manejo de errores de todo
el workflow que hacía que la corrección del punto 2 no pudiera funcionar
sin arreglarlo primero, (4) se cerraron dos hallazgos de la auditoría
técnica (SQL injection, propagación de `nivel_importancia`), (5) se
repararon 2 tareas reales atoradas en el backlog como parte de las
pruebas, y (6) se investigó rotar la contraseña de Postgres y se decidió
posponerlo por un riesgo nuevo que no estaba contemplado.

### 0. La API key de n8n — guardada, marcada para borrar al final

Se guardó en `.env` como `N8N_API_KEY_TEMP`, con un comentario explícito
de que a diferencia de la de NVIDIA, esta sí es sensible (da acceso de
gestión completo a esta instancia de n8n: leer/crear/editar/borrar
workflows, credenciales, ejecuciones) y de que es temporal — pendiente
**eliminarla** (revocar en n8n + borrar la línea de `.env`) en cuanto se
termine el trabajo pendiente de n8n de esta ronda, tal como pidió Mateo.
No se elimina todavía porque quedan pendientes reales que la necesitan
(hallazgo C5, ingesta Telegram, aprobación bidireccional — ver "Qué
queda" al final de esta sección).

### 1. El bug de fondo: `onError: continueErrorOutput` nunca funcionó como se creía

Al construir el disparo automático (que depende de que `"Marcar como
fallida"` se dispare de verdad), se encontró que **ese nodo nunca se había
ejecutado ni una sola vez en la historia de este workflow** — no en ninguna
de las rondas anteriores que documentaron el manejo de errores como
"funcionando". La causa: n8n tiene un comportamiento no documentado donde,
para nodos de un solo output nativo (Postgres, Code, y — confirmado con
evidencia directa esta ronda — también HTTP Request tal como está
configurado aquí), cuando el nodo falla con `onError: continueErrorOutput`,
el item con forma de error cae en el output 0 (el de éxito normal) en vez
del output 1 (el "output de error" al que apunta el diagrama de
conexiones del workflow). Verificado de dos formas: leyendo directo el
código fuente de n8n dentro del contenedor
(`n8n-core/dist/execution-engine/workflow-execute.js`, función
`handleNodeErrorOutput`), y con múltiples ejecuciones reales que mostraban
el item de error en `main[0]` y `main[1]` vacío. No se investigó la causa
raíz dentro de los internals de n8n más allá de eso — no valía la pena esa
madriguera hoy.

**Consecuencia práctica, antes de esta ronda:** cualquier fallo real de
`"Llamar a omniroute"` (el nodo que llama a OmniRoute/al modelo) nunca
llegaba a `"Marcar como fallida"`. La tarea se quedaba atorada en
`status='running'` para siempre, sin error registrado y sin diagnóstico
disparado — en silencio.

**Arreglo aplicado, solo donde importaba para el entregable de hoy:** se
agregó un nodo IF explícito (`"¿Falló la llamada a omniroute?"`, condición
`{{ $json.error !== undefined }}`) inmediatamente después de `"Llamar a
omniroute"`, revisando el contenido real del item en vez de confiar en el
output al que n8n lo mandó. Si es error, va a un nodo Code nuevo
(`"Preparar fallo"`) que arma `{taskId, errMsg}` y de ahí a `"Marcar como
fallida"`.

**Quedan 13 nodos más con el mismo problema latente**, sin tocar esta
ronda a propósito (no por falta de tiempo): Reclamar tarea pendiente,
Obtener config del bot, Guardar resultado, Parsear asignaciones, Crear
tareas hijas, Send a text message, Obtener bot que asignó, Crear tarea de
aclaración, Bloquear tarea original, Obtener contexto de tarea padre,
Cargar contexto, Extraer patron, Guardar patron. Documentado como
**hallazgo C5** en `ejecutor_generico.md` para una ronda dedicada — tocar
los 13 de golpe al final de una sesión ya larga era más riesgo del que
valía la pena.

**Segundo bug relacionado, encontrado al depurar el arreglo de arriba:**
referenciar `$('Reclamar tarea pendiente').first().json.id` directo dentro
del campo `queryReplacement` de un nodo Postgres (sintaxis
`={{ [...] }}`), cuando ese nodo se alcanza pasando por una rama de
continuación de error, tira `Query Parameters must be a string of
comma-separated values or an array of values` — pero la misma referencia
cruzada funciona bien dentro de un nodo Code. No se identificó la causa
raíz dentro de los internals de n8n (se aisló empíricamente: arrays
estáticos funcionan, `$json.error.message` solo funciona, pero
`$('Reclamar tarea pendiente').first()` específicamente falla al pasar
por el mini-parser de `queryReplacement` después de esta rama en
particular). **Patrón de arreglo, ya aplicado y confirmado:** resolver
toda referencia cruzada entre nodos (`$('NodeName')`) dentro de un nodo
Code dedicado, justo antes de cualquier nodo Postgres que la necesite,
dejando el `queryReplacement` del nodo Postgres con solo acceso local
(`$json.campo`).

### 2. Disparo automático a Trouble shooter — construido y probado en vivo

Dos nodos nuevos: `"¿Bot que falló no es trouble_shooter?"` (IF — revisa
que el bot que falló exista y no sea `trouble_shooter`, para que un fallo
del propio Trouble shooter no se auto-despache en loop) →
`"Despachar a trouble_shooter"` (Postgres — inserta una tarea `pending`
nueva para `trouble_shooter` con el mismo `cluster` de la tarea que falló
y el mensaje de error como `input.text`).

**Probado en vivo de punta a punta:** se forzó un error real (tarea con
`nivel_importancia` nula, que OmniRoute rechaza con `400 Missing model`).
La tarea terminó `status='failed'` con el error real guardado en `output`,
y automáticamente se creó una tarea nueva para `trouble_shooter` con el
`cluster` y el error correctos. Datos de prueba limpiados después.

### 3. Dos hallazgos de la auditoría técnica, cerrados

- **Hallazgo C2 (inyección SQL):** `"Obtener config del bot"` usaba
  interpolación de string directa (`WHERE slug = '{{ $json.bot }}'`) sobre
  un valor que puede venir del JSON de salida de un LLM (el array
  "asignaciones" de un bot despachador) — vector real, no teórico. Query
  parametrizada con `$1` y `queryReplacement`.
- **Propagación de `nivel_importancia` a tareas hijas:** según el diseño
  de `efadam.md`, solo Efadam (todavía no construido) debe asignar
  `nivel_importancia` explícitamente; el resto de bots despachadores
  (Técnico jefe, Trouble shooter) deben heredarlo de la tarea que están
  ejecutando. El nodo `"Parsear asignaciones"` ahora hace
  `nivel_importancia: a.nivel_importancia || nivelPropio`.

### 4. Bonus: 2 tareas reales del backlog, reparadas

Al probar todo lo anterior se encontraron 2 tareas reales atoradas desde
el 13-14 de agosto (ids 4 y 7, ambas `coder`, del piloto original
`tecnico_jefe → coder`) — atoradas en `running` por el mismo bug del punto
1: les faltaba `nivel_importancia`, OmniRoute las rechazaba, y el error
nunca llegaba a `"Marcar como fallida"`. Se les asignó
`nivel_importancia = 'medio'` y se volvieron a correr — ambas terminaron
`status='done'` con salida real de modelo.

### 5. Rotar la contraseña de Postgres (hallazgo C1) — investigado, pospuesto a propósito

Al preparar la rotación (pendiente desde la auditoría del 17 de agosto:
contraseña expuesta en el historial de git) se encontró que
`claude/docker-compose.yml` usa el **mismo usuario y base de Postgres**
(`infpower`/`infinite_power`) para la base interna de n8n (workflows,
ejecuciones, login) que para las tablas de negocio (`tasks`, `bots`,
`knowledge_log`). Rotar la contraseña bien hecho exige coordinar 4 pasos
en orden (`ALTER USER` en Postgres, actualizar `.env`, actualizar la
credencial guardada en n8n vía `PATCH /credentials/{id}`, y reiniciar
ambos contenedores para que n8n relea `DB_POSTGRESDB_PASSWORD`, que solo
se lee al arrancar) — un paso mal hecho o fuera de orden puede dejar a n8n
sin poder arrancar. **Decisión propia, no revisada todavía por Mateo:** no
intentarlo al final de una sesión ya larga y técnicamente densa — dejarlo
para una ronda dedicada, con más margen para verificar cada paso con
calma.

### 6. Qué queda de esto

Cierra, de la lista de pendientes de la actualización del 18/ago (Docker
arriba), todo lo que dependía de acceso a n8n excepto: hallazgo C5 (13
nodos), rotar password de Postgres (pospuesto a propósito, ver punto 5),
la ingesta Telegram → `tasks`, y la aprobación humana bidireccional. La
API key de n8n sigue en `.env`, pendiente de eliminar cuando estos
terminen. Detalle nodo por nodo completo en `ejecutor_generico.md`;
`trouble-shooter.md` y `estado_del_proyecto.md` también actualizados.

---

## Actualización — 18 de agosto de 2026 (Docker arriba; NVIDIA conectado y probado de punta a punta en OmniRoute, los 4 combos ya rutean tráfico real; corrección importante: el diagnóstico de la ronda anterior sobre Trouble shooter estaba mal en una parte) — vigente

Mateo confirmó que ya levantó Docker Desktop él mismo, y pasó una API key
gratuita de NVIDIA ("es gratis da igual que esté expuesta"). Esta ronda: (1)
se corrige un error de diagnóstico de la ronda anterior sobre Trouble
shooter, (2) se conecta NVIDIA en OmniRoute y se prueba de punta a punta,
cerrando el bloqueo central de Bloque 2, y (3) se deja nota sobre la RAM de
la máquina.

### 0. Docker arriba

`docker ps` confirma los 3 contenedores (`n8n`, `postgres`, `omniroute`)
corriendo y saludables. Sobre la RAM (0.8 GB libres de 15.7 GB reportado la
ronda anterior): Mateo dice que es un problema recurrente de esa máquina
específica, ya descartó malware (la formateó varias veces), sin causa
identificada — se deja anotado como hecho conocido de la máquina, sin
investigación adicional de este lado (fuera del alcance de este proyecto).

### 1. Corrección importante: el diagnóstico del 17/ago sobre Trouble shooter tenía un error en su parte (a)

Al intentar ejecutar el `INSERT INTO bots` para `trouble_shooter` que la
ronda anterior había dejado como pendiente #23, Postgres devolvió
`duplicate key value violates unique constraint "bots_slug_key"` — la fila
**ya existía**. Verificado con una consulta directa: `trouble_shooter` está
insertado y activo (`active = true`, `dispatches_tasks = true`,
`requires_approval = false`, `conocimiento_directo = true`,
`contexto_slugs = {}`), con el `prompt_especifico` exacto de
`003_trouble_shooter_v2.sql`.

**Qué salió mal en el diagnóstico del 17/ago:** esa ronda razonó que, como
los únicos scripts commiteados que tocan `trouble_shooter`
(`003_trouble_shooter_v2.sql`, `004_conocimiento_directo.sql`) son ambos
`UPDATE ... WHERE slug = 'trouble_shooter'`, y un `UPDATE` sobre una fila
que no existe no da error, la fila nunca se había insertado. El
razonamiento tenía un hueco que no se verificó en su momento: **tampoco
existe ningún script commiteado de `INSERT` para `tecnico_jefe` ni
`coder`** — revisando `schema/001_init.sql` (que es puro `CREATE TABLE`,
reconstruido de un `pg_dump --schema-only`, sin ningún dato), los 3 bots
que existen hoy se insertaron a mano, fuera de cualquier script versionado
en git. La ronda del 17/ago no pudo confirmar esto contra la base real
porque Postgres estaba apagado — infirió el estado de la tabla a partir de
la ausencia de un script, en vez de consultarla directamente, y esa
inferencia resultó incorrecta.

**Consecuencia:** la frase original de `ejecutor_generico.md` ("Piloto
probado de punta a punta: `tecnico_jefe` → `coder` / `trouble_shooter`"),
que la ronda del 17/ago había "corregido" quitándole la referencia a
`trouble_shooter`, probablemente tenía razón desde el principio — o al
menos, el hecho concreto que esa corrección alegaba (que el bot no existía
en `bots`) era falso. Se revirtió esa corrección en `ejecutor_generico.md`,
`trouble-shooter.md` y `estado_del_proyecto.md`, dejando en cada uno una
nota explícita de que la nota del 17/ago quedó anulada por esta.

**Lo que NO cambia:** la parte (b) del diagnóstico anterior — que el nodo
"Marcar como fallida" del Ejecutor genérico no dispara automáticamente una
tarea para `trouble_shooter` — sigue sin verificarse ni tocarse esta ronda
(no hubo acceso a n8n). Esa parte se basó en leer el mapa de nodos que
`ejecutor_generico.md` ya documentaba como verificado contra n8n real el
15 de agosto, no en una inferencia por ausencia de evidencia — así que no
tiene el mismo defecto de razonamiento que la parte (a). Sigue siendo un
pendiente real, bloqueado por acceso a n8n.

No se corrigió nada del `bots.contexto_slugs = {}` de `trouble_shooter`
(vacío) — es consistente con que `002_conocimiento.sql` nunca le asignó
ninguno (solo se lo asignó a `tecnico_jefe`/`coder`), así que no parece un
error, es como se dejó desde el inicio. No se tocó.

### 2. NVIDIA conectado en OmniRoute y probado de punta a punta

NVIDIA ya es un proveedor de primera clase, integrado de fábrica en
OmniRoute (`open-sse/config/providers/registry/nvidia/index.ts`) — sin
scraping de sesión como Qwen, sin sorpresas de paywall como Pollinations,
sin necesitar una cuenta nueva como Cloudflare. Pasos ejecutados:

1. Login al dashboard vía `POST /api/auth/login` con la contraseña ya
   guardada en `.env` (`OMNIROUTE_DASHBOARD_PASSWORD`).
2. Conexión creada vía `POST /api/providers` (`provider: "nvidia"`, la API
   key de Mateo). Test de conexión (`POST /api/providers/{id}/test`) →
   `valid: true`.
3. Prueba real de un modelo individual (`meta/llama-3.1-8b-instruct`) vía
   `/v1/chat/completions` → respuesta real ("ok"), latencia ~116ms, costo
   $0 (nivel gratis de NVIDIA).

**Hallazgo importante: el catálogo de modelos que trae el archivo de
registro de NVIDIA dentro de la imagen de OmniRoute está desactualizado.**
Varios de los modelos más "atractivos" del archivo (`deepseek-ai/deepseek-
v4-flash`, `deepseek-ai/deepseek-v4-pro`, `mistralai/mistral-medium-3.5-
128b`, `mistralai/mistral-large-3-675b-instruct-2512`) devolvieron
`410 Gone` con mensajes explícitos de "reached its end of life" en fechas
de julio/agosto de 2026 — ya no existen del lado de NVIDIA aunque el
archivo bundleado en la imagen todavía los liste. **Regla para el futuro:
cualquier modelo de ese archivo hay que probarlo en vivo antes de usarlo en
un combo — nunca asumir que el archivo está actualizado.**

Modelos confirmados funcionando hoy (probados uno por uno con una llamada
real): `meta/llama-3.1-8b-instruct`, `nvidia/llama-3.3-nemotron-super-49b-
v1.5`, `nvidia/nemotron-3-super-120b-a12b`, `nvidia/nemotron-3-ultra-550b-
a55b` (este último con razonamiento visible en la respuesta, campo
`reasoning_content`).

**Los 4 combos se reconfiguraron** (`PUT /api/combos/{id}` — nota técnica
para quien lo use después: el endpoint real es `PUT`, no `PATCH`, aunque el
schema de Zod que lo valida se llame `updateComboSchema`; probar `PATCH`
primero da `405`) para usar estos modelos NVIDIA en vez de los de
Pollinations (que nunca sirvieron tráfico real, ver corrección del 17 de
agosto):

- `bajo` → `nvidia/meta/llama-3.1-8b-instruct`
- `medio` → `nvidia/nvidia/llama-3.3-nemotron-super-49b-v1.5`, con
  fallback al combo `bajo`
- `alto` → `nvidia/nvidia/nemotron-3-super-120b-a12b`, con fallback al
  combo `medio`
- `critico` → `nvidia/nvidia/nemotron-3-ultra-550b-a55b`, con fallback al
  combo `alto`

(La cascada de fallback entre niveles vía `combo-ref`, ya configurada desde
el 17 de agosto, se conservó igual — solo se reemplazaron los modelos.)

**Prueba end-to-end confirmada:** llamadas reales a `/v1/chat/completions`
con `model: "bajo"` y `model: "critico"` (por nombre de combo, como los
usaría el Ejecutor genérico) devolvieron respuesta real, con header
`x-omniroute-provider: nvidia` confirmando que el tráfico se rutea de
verdad, no solo que el combo existe en la base.

**Criterio de elección de modelo por nivel — juicio propio, no medición,
documentado para que Mateo lo pueda ajustar si no le hace sentido:** `bajo`
= modelo pequeño y rápido (8B) para tareas mecánicas; `medio`/`alto` =
modelos Nemotron medianos/grandes de NVIDIA con buena capacidad general;
`critico` = el modelo más grande que respondió con razonamiento explícito
(550B). No se evaluó calidad real de cada modelo en tareas específicas del
proyecto (código, redacción, etc.) — es una asignación razonable por
tamaño/generación, no un benchmark.

**No se tocó Pollinations, Cloudflare ni Qwen** — siguen en el estado de la
actualización del 17 de agosto (Pollinations conectado pero sin servir
tráfico real por falta de key paga; Cloudflare descartado; Qwen pendiente
de que Mateo decida). Con NVIDIA ya funcionando limpio y sin fricción,
probablemente ya no valga la pena perseguir esos tres — queda como
sugerencia para que Mateo decida, no se cerraron ni eliminaron las
conexiones existentes.

**La API key de NVIDIA se guardó en `.env`** (`NVIDIA_API_KEY`), mismo
tratamiento que el resto de los secrets del proyecto, por consistencia —
aunque Mateo aclaró que no le importa que esté expuesta por ser gratuita.

### 3. Qué queda de esto

Esto cierra el bloqueante central de Bloque 2 ("ningún proveedor rutea
tráfico real") — el punto 3 de "Qué falta ahora, en orden" de la
actualización del 17 de agosto (abajo) queda resuelto vía NVIDIA en vez de
Pollinations/Qwen. Lo que sigue en esa lista (propagar `nivel_importancia`
a tareas hijas, rotar password de Postgres, parametrizar SQL vulnerable,
completar aprobación humana bidireccional, ingesta Telegram → `tasks`)
sigue bloqueado por acceso a n8n, sin cambios esta ronda — la pregunta de
cómo Mateo quiere dar ese acceso sigue sin respuesta.

---

## Actualización — 17 de agosto de 2026, noche, quinta ronda (se intentó conectar a n8n: el stack completo estaba apagado, la máquina se quedó casi sin RAM al intentar levantarlo; diagnóstico real de por qué Trouble shooter "no está") — vigente

Mateo pidió dos cosas: (1) intentar conectarse a n8n, (2) implementar Trouble
shooter al final del Ejecutor genérico, porque le parecía que todavía no
estaba. Se investigó a fondo ambas. Resultado: (1) no se pudo conectar — el
motivo real es más grave que "falta la API key", y (2) Mateo tenía razón,
pero por dos motivos concretos y distintos, ninguno inventado — verificados
contra el código/SQL real, no supuestos.

### 1. Intento de conexión a n8n — el stack entero estaba apagado, no solo bloqueado por credenciales

Antes de llegar siquiera al problema de credenciales (ver ronda anterior),
`docker ps` falló con "failed to connect to the docker API" — **Docker
Desktop no estaba corriendo en la máquina de Mateo**, así que n8n, Postgres
y OmniRoute estaban los tres apagados, no solo inaccesibles por falta de
llave. Se intentó levantar Docker Desktop de forma programática
(`Start-Process`). Después de ~4 minutos sin que el motor terminara de
iniciar, se encontró la causa real: **la máquina tenía solo 0.8 GB de RAM
libre de 15.7 GB totales, desde antes de este intento** — Docker Desktop
entonces se quedó atorado tratando de arrancar su VM (WSL2) encima de eso,
llegó a consumir 7.7 GB él solo sin nunca terminar de inicializar (`wsl -l
-v` seguía mostrando `docker-desktop: Stopped` varios minutos después), y en
un momento hasta el propio `docker.exe` se cayó con "cannot allocate
memory" — no un error de Docker, un síntoma de que la máquina ya no tenía
memoria para casi nada.

**Se decidió no seguir insistiendo a ciegas.** Es la máquina de Mateo, en
uso activo en ese momento (Spotify, Opera y Word abiertos), con muy poca RAM
libre desde antes de que Claude tocara nada — seguir reintentando el arranque
de Docker Desktop sin que él esté mirando podía dejar el equipo inestable en
vez de ayudar. Se terminaron los procesos de Docker Desktop que quedaron
atorados (`Stop-Process`), lo que liberó la RAM de vuelta a 11.2 GB libres —
la máquina queda sana para lo que Mateo esté haciendo, solo que sin el stack
del proyecto corriendo.

**Pendiente real, para cuando Mateo esté en la máquina:** revisar qué se
estaba comiendo casi toda la RAM *antes* de que Docker Desktop intentara
arrancar (0.8 GB libres de entrada ya es poco, independientemente del
proyecto) y, si tiene sentido, cerrar algo o reiniciar; después, abrir Docker
Desktop él mismo. En cuanto el stack esté arriba, se puede retomar de
inmediato tanto la pregunta de acceso a n8n (ver ronda anterior, sigue sin
contestar) como el punto 2 de abajo, que **no depende de n8n en absoluto**.

### 2. Trouble shooter — diagnóstico concreto de qué falta, verificado contra el código real

Mateo tenía razón en que no está, y se pudo confirmar exactamente por qué —
sin necesitar que Postgres/n8n estuvieran corriendo, porque la evidencia ya
estaba en los archivos del repo/vault:

**a) `trouble_shooter` nunca se insertó como fila activa en `bots`.** Los
dos scripts SQL que existen para configurarlo —
`schema/003_trouble_shooter_v2.sql` (carga el `prompt_especifico`) y
`schema/004_conocimiento_directo.sql` (marca `conocimiento_directo = true`)
— son ambos `UPDATE ... WHERE slug = 'trouble_shooter'`. Un `UPDATE` sobre
una fila que no existe no da ningún error, solo no hace nada — así que si
esos scripts se corrieron alguna vez, corrieron en silencio contra cero
filas. Esto coincide exactamente con lo que ya decía "Pendientes activos" #9
de este mismo documento: "hoy solo `tecnico_jefe` y `coder` están activos".
**Falta un `INSERT INTO bots` real** para `trouble_shooter` (slug, cluster,
`active = true`, `dispatches_tasks = true`, y aplicar encima el
`prompt_especifico`/`conocimiento_directo` que ya están escritos en 003/004).
**Esto NO requiere acceso a n8n — es una escritura directa a Postgres**,
lista para ejecutarse en cuanto el stack vuelva a estar arriba.

**b) El disparo automático que describe `trouble-shooter.md` no está
construido en el n8n real.** Ese documento decía "en cuanto el nodo 'Marcar
como fallida' del ejecutor marca cualquier tarea como `failed`, se crea
automáticamente una tarea nueva para Trouble shooter" — pero el mapa de
nodos real de `ejecutor_generico.md` (nodo 16, "Marcar como fallida") solo
hace `UPDATE tasks SET status = 'failed', ...`, sin ningún `INSERT`
conectado que cree esa tarea de diagnóstico. La descripción documentaba el
diseño que se quería, no lo que de verdad se construyó — corregido en ambos
documentos, con nota explícita de que era aspiracional, no un error de
redacción menor. **Esto sí requiere editar el workflow en n8n** (agregar un
nodo Postgres nuevo después de "Marcar como fallida") — mismo bloqueo de
acceso de la ronda anterior.

**En síntesis: de las dos piezas que le faltan a Trouble shooter, una (el
`INSERT` a `bots`) se puede resolver en cuanto vuelva Postgres, sin esperar
la respuesta de Mateo sobre n8n; la otra (el nodo de disparo automático)
sigue atada a esa misma respuesta pendiente.**

Documentado en `docs/ejecutor_generico.md` (corrección del piloto probado, y
nuevo punto 4 en "Lo que falta") y en `prompts/dev-tech/trouble-shooter.md`
(nota de cabecera + corrección en "Input que recibe").

---

## Actualización — 17 de agosto de 2026, noche, cuarta ronda (fallback en cascada entre niveles implementado en OmniRoute, Efadam ya no explica de más, Pollinations resulta gratis de verdad, y bloqueo real: falta acceso a n8n para el resto del backlog) — vigente

Mateo hizo una observación de diseño, dio una corrección de tono para
Efadam, pidió que se elimine el voseo, confirmó que su OmniRoute actual no
se debe tocar más allá de lo ya documentado, y pidió continuar con el resto
de pendientes. Se ejecutó todo lo que era técnicamente posible sin acceso
adicional; se documenta también, sin maquillarlo, lo que quedó bloqueado.

### 1. Fallback en cascada entre niveles — implementado, no solo documentado

Mateo señaló algo correcto y no tan obvio como sonaba: si un nivel de
importancia no tiene modelo disponible, el sistema debería avisar y caer al
nivel de abajo, en cascada. Se verificó que OmniRoute ya trae un mecanismo
nativo para esto (confirmado la ronda pasada en el schema de combos, no
usado todavía): una entrada de `models[]` puede ser `{kind: "combo-ref",
comboName}`, una referencia a otro combo tratada como si fuera un modelo
más de la lista.

**Se aplicó a los 4 combos reales de la instalación de Mateo, vía
`PUT /api/combos/{id}`** (hallazgo de API: el endpoint de edición responde
`405` a `PATCH`, hay que mandar `PUT` con el array `models` completo):

- `medio` → agrega referencia a `bajo`.
- `alto` → agrega referencia a `medio`.
- `critico` → agrega referencia a `alto`.
- `bajo` no cambia — es el piso, no tiene a dónde caer.

Cadena resultante: `critico → alto → medio → bajo`. Si todos los modelos
reales de un nivel fallan, la tarea cae al de abajo en vez de no responder
nada. **Sin verificar en tráfico real todavía** — los 4 combos siguen sin
un proveedor funcional detrás (ver punto 3), así que el fallback existe en
la configuración pero no se ha visto disparar en la práctica.

**Lo que Mateo pidió y que sigue sin construirse: el aviso.** Un fallback
silencioso está bien para `bajo`/`medio`, pero que una tarea `crítico`
(dinero, legal, seguridad) termine sirviéndose con el modelo barato de
`bajo` sin que nadie se entere es un riesgo real, no solo un detalle
técnico. El lugar natural para detectarlo ya existe en el schema
(`agent_runs.model_used`, comparado contra `tasks.nivel_importancia`), pero
la lógica que lo lea y dispare una alerta a Mateo vive en el Ejecutor
genérico de n8n — y ahí es exactamente donde se topa con el bloqueo del
punto 4. Queda anotado como pendiente, no resuelto.

Documentado en `docs/context/stack_y_convenciones.md`, sección "Cómo se
traduce nivel → modelo real", y reflejado en `efadam.md`.

### 2. Efadam: ya no explica de más, y habla en español de México

Dos correcciones de comportamiento, ambas aplicadas directo a
`prompts/_core/efadam.md` (sección "Reglas y límites" y el prompt de
sistema que se pega en n8n):

- **No explica detalles técnicos de cómo resolvió algo, por defecto.** La
  mayoría de quienes usan el sistema no tienen ni necesitan idea de qué bot
  corrió, qué nivel asignó o en qué tabla quedó algo — responde con el
  resultado, en lenguaje llano, y solo entra en detalle si se le pide
  explícitamente.
- **Habla en español de México, nunca voseo** ("vos", "tenés", "revisás")
  ni modismos de otro país hispanohablante, salvo que el usuario lo pida.
  Esto último aplica también a cómo Claude le habla a Mateo en esta
  conversación — corregido ahí también (memoria de Claude, no un archivo
  del proyecto).

Se agregó un caso de prueba nuevo (#11) a `efadam.md` que ejemplifica la
regla de no sobre-explicar.

### 3. Pollinations: sí es gratis, el registro no cuesta nada

Investigado el mecanismo real de `enter.pollinations.ai` (documentación
oficial del repo, `POLLEN_FAQ.md`): **registrarse es gratis** — no pide
tarjeta ni pago. Con cuenta creada, los modelos marcados como gratis cuestan
0 Pollen; solo los modelos de pago consumen el saldo comprado. El 401 que
se vio la ronda pasada no contradice esto: antes cualquiera podía llamar a
los modelos gratis sin ninguna cuenta, ahora Pollinations exige al menos
una API key de una cuenta registrada (gratis) para frenar abuso — el uso
sigue siendo gratuito, cambió el requisito de identificarse.

**Conclusión: no hace falta buscar un proveedor alternativo.** Basta con
que Mateo entre a `enter.pollinations.ai`, cree una cuenta gratis, genere
una API key, y la pegue en el Provider de Pollinations ya creado en
OmniRoute (`http://127.0.0.1:20128`, contraseña en `.env`). A diferencia de
Qwen, esto no es scraping de un producto de consumo ni tiene riesgo de
baneo documentado — es el flujo de registro oficial del proveedor. Aun así
no se creó la cuenta en nombre de Mateo sin que él lo sepa: es su decisión
entrar y hacerlo, o pedir que se investigue una alternativa si prefiere no
registrarse en Pollinations por cualquier motivo.

### 4. Bloqueo real: la mayoría del resto del backlog necesita escribir en n8n, y ese acceso no está disponible esta sesión

Mateo pidió continuar con el resto de pendientes. Al revisarlos uno por
uno, la mayoría requiere modificar workflows de n8n en vivo (agregar/editar
nodos, credenciales, o crear un workflow nuevo) — y eso solo es posible por
dos caminos: la API key de n8n (que, por decisión de Mateo del 15 de
agosto, vive fuera de sistemas digitales cuando no está en uso — no está
disponible en este entorno) o el login de la interfaz web de n8n
(`localhost:5678`), cuyas credenciales tampoco están en `.env` ni en ningún
lugar al que se tenga acceso esta sesión. Se verificó primero que no
hubiera una vía indirecta razonable: `docker-compose.yml` no tiene
`N8N_BASIC_AUTH_*` configurado, así que no hay una contraseña simple que
probar; editar directo las tablas internas de n8n en Postgres (donde vive
el JSON de los workflows) es técnicamente posible pero es cirugía sobre el
almacenamiento interno de una herramienta de terceros sin pasar por su
API — alto riesgo de corromper un workflow que hoy funciona, así que no se
intentó sin preguntar primero.

**Quedan bloqueados por esto**, no por falta de intento:

- Propagar `nivel_importancia` a las tareas hijas (nodos "Parsear
  asignaciones"/"Crear tareas hijas").
- Parametrizar el SQL del nodo "Obtener config del bot" (la inyección SQL,
  hallazgo C2).
- Rotar la contraseña de Postgres de verdad — la mitad de infraestructura
  (`docker-compose.yml`, `.env`) se puede cambiar sin n8n, pero el
  workflow tiene su propia credencial de Postgres guardada adentro de n8n;
  cambiar la contraseña real sin actualizar esa credencial rompe todos los
  workflows.
- Construir el workflow de ingesta Telegram → `tasks` (workflow nuevo).
- Completar el flujo de aprobación humana bidireccional (hallazgo C4).

**Lo que sí se puede seguir haciendo sin este acceso** (y es donde se debe
seguir empujando mientras se resuelve el acceso a n8n): decisiones y
research que no tocan n8n, como este mismo hallazgo de Pollinations, el
fallback de combos en OmniRoute (punto 1), y cualquier documento del
proyecto.

**Pregunta real para Mateo, no cosmética:** ¿prefiere pasar la API key de
n8n para esta sesión (se puede usar y no guardarla en ningún lugar
digital al terminar, igual que él la maneja), dar el login de la interfaz
web, hacer él mismo estos cambios con instrucciones exactas de qué tocar en
cada nodo, o alguna otra opción? Sin uno de estos tres, el resto del
backlog técnico no avanza esta sesión.

---

## Actualización — 17 de agosto de 2026, noche, tercera ronda (factibilidad de automatizar la generación de credenciales de OmniRoute en el startup — hallazgo, no implementación) — vigente

Mateo preguntó si es posible que, en el arranque del sistema, la generación
de la llave/contraseña de OmniRoute se haga desde la propia interfaz de
Infinite Power sin que el usuario tenga que pasar por lo que se hizo a mano
hoy (llamadas directas a la API vía curl). Pidió explícitamente **no
construirlo ahora** — solo verificar si es factible y dejarlo anotado para
resolverse junto con el diseño de "startup"/onboarding más adelante.
Mientras tanto, se sigue usando la instancia de OmniRoute ya configurada
hoy (con la contraseña generada en la ronda anterior), pero exclusivamente
para efectos de construir el sistema — no como el flujo final que vería un
usuario real.

### Factibilidad: sí, y ya quedó demostrada empíricamente hoy mismo

Todo lo que se hizo a mano en la ronda anterior (generar la contraseña,
fijarla, crear los 4 combos) fueron llamadas normales a la API HTTP de
OmniRoute — nada de eso requirió abrir un navegador ni pasar por el
asistente de onboarding de OmniRoute. Eso significa que un script de
arranque (o un workflow de n8n, o un futuro microservicio propio de
Infinite Power) puede hacer exactamente lo mismo de forma automática e
idempotente, sin que el usuario final tenga que tocar la API ni el
dashboard de OmniRoute directamente.

**Lo que sí se puede automatizar sin fricción:**

1. Generar los 4 secretos de OmniRoute (`JWT_SECRET`, `API_KEY_SECRET`,
   `STORAGE_ENCRYPTION_KEY`, `STORAGE_ENCRYPTION_KEY_VERSION`) de forma
   aleatoria **antes** de levantar el contenedor por primera vez, e
   inyectarlos como variables de entorno desde el arranque — más limpio
   que lo que se hizo hoy (que tuvo que reusar los que OmniRoute ya había
   autogenerado, porque el contenedor ya llevaba corriendo desde antes de
   este hallazgo).
2. Generar una contraseña de dashboard aleatoria y fijarla vía
   `POST /api/settings/require-login` en cuanto el contenedor esté
   saludable. `GET /api/settings/require-login` sirve como chequeo de
   idempotencia (`hasPassword`): si ya tiene contraseña, el script no la
   pisa en un reinicio posterior.
3. Crear los 4 combos por defecto (`bajo`/`medio`/`alto`/`critico`)
   automáticamente vía `POST /api/combos`, sin que el usuario tenga que
   entrar nunca al dashboard de OmniRoute para esto.
4. Mostrarle al usuario, una sola vez, la contraseña generada (para que la
   tenga guardada por si alguna vez necesita entrar directo al dashboard
   de OmniRoute) — no esconderla del todo. Una contraseña que nadie conoce
   ni puede recuperar es un problema el día que haga falta usarla.

**Lo que NO se puede automatizar — límite real, no técnico sino de
terceros:** conectar un proveedor de modelos real (una API key de
Pollinations, Anthropic, OpenAI, un token de Qwen, lo que sea) siempre va
a requerir que el usuario tenga o consiga su propia credencial de ese
proveedor externo. Ningún script puede generar una API key válida de un
tercero en nombre del usuario. Lo que sí se puede simplificar es *dónde*
la pega: en vez de que el usuario tenga que aprender a usar el dashboard
de OmniRoute, la interfaz propia de Infinite Power podría ofrecer un paso
simple de "pega tu API key de [proveedor] aquí" que internamente llame a
`POST /api/providers`. Sigue siendo fricción real (conseguir la key en el
sitio del proveedor), pero se elimina la fricción de aprender una
herramienta externa.

### Dónde debería vivir esta lógica de arranque (para cuando se diseñe — no decidido todavía)

Tres opciones a evaluar en su momento, sin decidir ahora:

a) Un script de inicialización de una sola vez, al estilo de un
   contenedor de "migraciones" en `docker-compose.yml` (ya existe ese
   patrón para el esquema de Postgres).
b) Un workflow de n8n disparado una sola vez al arranque — mantiene toda
   la lógica de "arranque del sistema" en un solo lugar, consistente con
   que n8n ya es el orquestador de todo lo demás.
c) Un microservicio propio de Infinite Power, si en algún momento existe
   una interfaz propia más allá de Telegram + los dashboards crudos de
   n8n/OmniRoute — probablemente esto es lo que Mateo tiene en mente con
   "la misma interfaz de mi proyecto", pero esa interfaz todavía no
   existe.

### Advertencia de diseño a futuro (anotada, no urgente)

Si Infinite Power alguna vez deja de ser una instalación de un solo
usuario (self-hosted, como hoy) y pasa a ser multiusuario, este enfoque de
generar secretos y guardarlos en un `.env` compartido deja de alcanzar —
haría falta una bóveda de secretos por usuario/instalación. No es un
problema hoy (Mateo es el único usuario), pero queda anotado para no
repetir el mismo diseño a ciegas si el proyecto llega a empaquetarse para
terceros.

No se construyó nada de esto en esta ronda, por instrucción explícita de
Mateo. Se sigue usando la instancia actual de OmniRoute, ya configurada,
exclusivamente para construir el resto del sistema.

---

## Actualización — 17 de agosto de 2026, noche, segunda ronda (Mateo decide las 3 pendientes: contraseña generada por Claude, Cloudflare descartado, Qwen procede — ejecución real en el contenedor) — vigente

Mateo contestó las 3 decisiones pendientes de la actualización inmediata de
abajo: **(1) contraseña de OmniRoute — "generala tu"; (2) Cloudflare AI —
"Descartalo"; (3) Qwen — "Procede".** Se ejecutó de inmediato sobre el
contenedor real, no solo se documentó.

### Hecho: infraestructura de OmniRoute arreglada y verificada

- `docker-compose.yml`: volumen de OmniRoute corregido de `/app/config` a
  `/app/data`; agregadas `JWT_SECRET`/`API_KEY_SECRET`/
  `STORAGE_ENCRYPTION_KEY`/`STORAGE_ENCRYPTION_KEY_VERSION` como variables
  de entorno explícitas en el servicio, reusando los mismos valores que
  OmniRoute ya había auto-generado (no rotados) — ahora viven en `.env`
  bajo el prefijo `OMNIROUTE_*`.
- Contenedor recreado (`docker compose up -d omniroute`) y verificado: el
  volumen ahora sí persiste en `data/omniroute/` del host
  (`storage.sqlite` confirmado ahí después de la recreación, en vez de
  perderse en la capa efímera del contenedor). La base histórica de antes
  de este cambio no se migró (no tenía nada de valor — cero combos o
  conexiones existían todavía; el respaldo `.tar.gz` de la actualización
  anterior conserva esa foto por si hiciera falta).
- **Contraseña del dashboard generada por Claude** (instrucción de Mateo):
  `W9KaCeUV0KVuohD3ROv99jfsLGjV0Cs` — fijada vía
  `POST /api/settings/require-login` (el mecanismo real detrás del
  asistente de onboarding, confirmado leyendo
  `dashboard/onboarding/page.tsx`; no hizo falta pasar por el navegador).
  Login confirmado funcionando. **Guardada en `.env`
  (`OMNIROUTE_DASHBOARD_PASSWORD`, gitignored) — cámbiala desde Settings →
  Security si prefieres otra.**

### Hecho: Cloudflare AI descartado

Sin cambios técnicos que hacer — simplemente no se conecta. Queda anotado
como decisión tomada, no como pendiente abierto.

### Hecho: 4 combos creados (`bajo`/`medio`/`alto`/`critico`)

Con el `createComboSchema` ya confirmado. Todos apuntan a modelos de
Pollinations por ahora (único proveedor conectado):

- `bajo` → `pol/openai-fast`
- `medio` → `pol/claude`, `pol/openai` (fallback)
- `alto` → `pol/claude-large`, `pol/openai-large` (fallback)
- `critico` → `pol/claude-large`

**Pendiente #7 de la lista de abajo, resuelto empíricamente:** el campo
`model` de un request de chat completions puede referenciar el combo
directo por su `name` (ej. `model: "bajo"`) — no hizo falta
`/api/model-combo-mappings` para este diseño simple de 4 niveles.

### Hallazgo nuevo, no anticipado: Pollinations NO es realmente "sin auth" para uso real

La conexión de Pollinations se creó y el test superficial
(`POST /api/providers/{id}/test`) dio `valid: true` — pero al probar los
combos de verdad (`POST /api/combos/test`), **los 3 modelos probados
(`openai-fast`, `claude`, `openai`) devolvieron 401**: `"A valid API key
is required. Get one at https://enter.pollinations.ai/keys"`. Es decir:
Pollinations dejó de ser gratis-sin-registro para inferencia real, al
menos para estos modelos — contradice tanto la guía de OmniRoute
(`FREE-TIERS-GUIDE.md`, "no auth needed") como mi propia evaluación de la
actualización anterior ("sin objeciones, listo para conectar"). **Esa
evaluación anterior queda corregida aquí: estaba incompleta** — verificaba
que el código apuntara a un endpoint oficial, pero no que la llamada real
funcionara sin credencial. No se investigó todavía si
`enter.pollinations.ai/keys` es un registro gratuito (tipo lista de
espera/Discord) o de pago — **pendiente de que Mateo lo revise si quiere
usar Pollinations de verdad**, o de buscar otro proveedor gratis real como
reemplazo. **Los 4 combos existen pero hoy no rutean tráfico real** — la
conexión que tienen detrás no está sirviendo.

### Qwen: "Procede" — investigado a fondo, pero el último paso solo lo puede dar Mateo

Confirmado en el código (`web-cookie.ts`, definición de `qwen-web`)
exactamente qué hace falta para conectarlo: no es una API key normal, es
"abrir chat.qwen.ai, loguearse, abrir DevTools → Application → Local
Storage → copiar el valor de `token` (o usar la cookie `tongyi_sso_ticket`
como Bearer token)". **Esto solo lo puede hacer Mateo (o alguien con una
cuenta real de Qwen) desde un navegador real logueado** — no es algo que
Claude pueda generar, adivinar, ni completar por su cuenta. Crear una
cuenta nueva de Qwen a nombre de Mateo sin que él lo sepa tampoco es una
decisión que le corresponda tomar a Claude (acepta los términos de
servicio de un tercero en su nombre). **"Procede" se ejecutó hasta donde
es técnicamente posible sin esa acción manual de Mateo** — la conexión en
OmniRoute está lista para recibir el token en cuanto él lo consiga
(Providers → Add Provider → Qwen Web (Free), pegar el token/cookie ahí).
Sigue sin conectar.

### Qué falta ahora, en orden

1. **Necesita a Mateo:** revisar si `enter.pollinations.ai/keys` es
   registro gratis o de pago, y decidir si vale la pena para que los
   combos ruteen de verdad, o buscar un reemplazo gratis real.
2. **Necesita a Mateo:** loguearse en `chat.qwen.ai`, extraer el token
   (instrucciones arriba), y conectarlo en el dashboard de OmniRoute
   (`http://localhost:20128`, contraseña en `.env`) si todavía quiere
   proceder con Qwen sabiendo el riesgo de baneo ya documentado.
3. Una vez que al menos un proveedor rutee de verdad: probar
   `POST /api/chat/completions` con `model: "bajo"` (o el nivel que sea)
   contra el contenedor real, para confirmar extremo a extremo que un
   combo sirve una respuesta real, no solo que existe.
4. Propagar `nivel_importancia` a las tareas hijas en n8n (pendiente #8
   de la lista de abajo) y construir la ingesta Telegram → `tasks`
   (pendiente #9).
5. Rotar contraseña de Postgres (C1), parametrizar SQL de "Obtener config
   del bot" (C2), completar flujo de aprobación humana (C4) — pendientes
   #11-13 de abajo, siguen sin tocar.
6. Insertar y activar Efadam (Bloque 3) — bloqueado hasta que cierren 1-5.

---

## Actualización — 17 de agosto de 2026, noche (conexión de proveedores en OmniRoute, hallazgos de riesgo, backup de datos, y Mateo confirma que el proyecto es individual) — vigente

Continuación de la sesión de la tarde (ver actualización inmediatamente
abajo, ahora marcada "vigente" sin ser la más reciente). Mateo dio 3
instrucciones: (1) conectar Pollinations, Cloudflare AI y Qwen en
OmniRoute; (2) borrar toda referencia al amigo/cofundador en los
documentos del proyecto — es un proyecto individual, no hay cofundador;
(3) seguir con los siguientes pasos hasta necesitar una decisión real de
Mateo.

### Sobre el amigo/cofundador

Se eliminaron las referencias activas/futuras: checklist de Fase 0, tabla
de reparto de responsabilidades, el pendiente "agregar al amigo como
colaborador del repo", `estado_del_proyecto.md`, y el prompt de Efadam en
`prompts/_core/efadam.md` (este último importa porque es contenido que
Efadam lee en producción, no solo un documento humano). **No se tocaron**
`docs/archivo/plan_de_accion.md` ni
`docs/archivo/contexto_proyecto_infinite_power_v5.md` — son versiones
archivadas y superadas (por este documento y por
`contexto_proyecto_infinite_power_v6.md` respectivamente); reescribir un
documento archivado para que diga algo distinto de lo que decía en su
momento sería falsificar el registro histórico, no corregirlo. Si Mateo
prefiere que también se borren ahí, se hace — por ahora se trató como
fuera del alcance de "el plan" vigente.

### Investigación de los 3 proveedores pedidos

**Pollinations — sin objeciones, listo para conectar.** El código
(`open-sse/executors/pollinations.ts`) apunta a un endpoint oficial,
formato OpenAI estándar (`https://gen.pollinations.ai/v1/chat/completions`),
sin ninguna bandera de riesgo.

**Cloudflare AI — contradicción real entre la guía de OmniRoute y el
código, sin resolver todavía.** `FREE-TIERS-GUIDE.md` lo lista como Tier 1
("no auth needed"), pero el ejecutor real
(`open-sse/executors/cloudflare-ai.ts`) exige un Bearer API Token y un
Account ID reales, obtenidos desde una cuenta de Cloudflare
(`dash.cloudflare.com/profile/api-tokens`). Es gratis, pero no es "cero
fricción" como decía la guía — hace falta que Mateo tenga o cree una
cuenta de Cloudflare y genere un token. **Pendiente de decisión de
Mateo:** ¿crea la cuenta/token para conectarlo ahora, o se pospone
Cloudflare y se avanza solo con Pollinations por el momento?

**Qwen — hallazgo de riesgo real, no se conectó, necesita decisión
explícita de Mateo antes de tocarlo.** El ejecutor
(`open-sse/executors/qwen-web.ts`) no usa una API oficial de Alibaba: hace
scraping del chat de consumidor `chat.qwen.ai`, replicando una cookie jar
completa de una sesión real logueada más un bearer token, para evadir el
WAF anti-bot de Alibaba ("baxia"). El propio comentario del código lo
compara explícitamente con `gpt4free` y `Chat2API` — proyectos conocidos
de ingeniería inversa no oficial, en zona gris de los términos de
servicio. OmniRoute tiene incluso un sistema dedicado de detección de
baneo (`docs/security/BAN_DETECTION.md`) con un estado terminal "banned"
(1 año de enfriamiento, sin recuperación automática) — evidencia de que el
riesgo de baneo de cuenta es real y conocido por los propios
desarrolladores de OmniRoute, no una posibilidad remota. Esto no es lo que
"conectar Qwen" sonaba que era (un proveedor gratis más del catálogo): es
replay de sesión de un producto de consumo real, con riesgo real de que
esa cuenta quede baneada permanentemente. No se conectó. Queda pendiente
que Mateo confirme, con esta información en mano, si de todos modos
quiere proceder — y con qué cuenta de Qwen, dado que el riesgo de baneo
recae sobre esa cuenta específica.

### Hallazgo adicional: OmniRoute no tiene contraseña configurada, y no es "CHANGEME"

El plan anterior (ver "Pendientes de Bloque 2" más abajo) asumía que la
contraseña default del dashboard era literalmente `CHANGEME`, según un log
de bootstrap. Verificado en vivo: `POST /api/auth/login` con `CHANGEME`
devuelve `{"error":"No password configured. Complete onboarding
first.","needsSetup":true}` — no hay ninguna contraseña utilizable
todavía. OmniRoute exige completar un asistente de onboarding en
`/dashboard/onboarding` (confirmado leyendo `login/page.tsx` y
`login/route.ts`) antes de poder loguearse por primera vez; ese asistente
es la única vía real para fijar la contraseña inicial, no hay endpoint de
API documentado ni valor por defecto real que sirva. Además
`login/route.ts` falla directo (500) si `process.env.JWT_SECRET` no está
seteado como variable de entorno real del proceso (distinto del
`server.env` que OmniRoute ya generó solo dentro de `/app/data`) — fijar
`JWT_SECRET` en `docker-compose.yml`/`.env` sigue siendo necesario aparte
del onboarding.

### Backup de `/app/data` ya hecho, antes de tocar nada

Antes de arreglar el volumen mal montado (`/app/config` en vez de
`/app/data`, ver hallazgo de la tarde más abajo), se respaldó en frío el
contenido real del contenedor (`storage.sqlite`, `server.env` con los
secretos ya generados, logs de llamadas del 11 al 17 de agosto) a
`data/omniroute_data_backup_17ago2026.tar.gz` (638 KB comprimido) dentro
del repo local. **No comiteado a propósito** — son datos/secretos reales,
no deben subirse a git; queda en el filesystem local, o se mueve a un
backup fuera del repo si Mateo prefiere. Esto es puramente preventivo:
todavía no se tocó `docker-compose.yml` ni se recreó el contenedor.

### Qué falta, sin necesitar más decisiones de Mateo (técnico)

1. Arreglar `docker-compose.yml`: volumen de OmniRoute de `/app/config` a
   `/app/data`, y agregar `JWT_SECRET`/`API_KEY_SECRET`/
   `STORAGE_ENCRYPTION_KEY` como variables de entorno explícitas
   (reusando los valores que OmniRoute ya generó solo en
   `/app/data/server.env`, mismo patrón de "reusar en vez de rotar" que
   `N8N_ENCRYPTION_KEY` en Bloque 0).
2. Recrear el contenedor y confirmar que los datos sobreviven una segunda
   recreación (la prueba real de que el volumen quedó bien montado).
3. Conectar Pollinations una vez el dashboard sea accesible.

### Qué necesita decisión de Mateo antes de seguir

- **Contraseña del dashboard de OmniRoute:** el asistente de onboarding la
  va a pedir — ¿la define Mateo, o autoriza que se genere una segura y se
  le entregue?
- **Cloudflare AI:** ¿cuenta/token propio ahora, o se pospone?
- **Qwen:** ¿proceder de todos modos con el riesgo de baneo explicado
  arriba, con qué cuenta, o se descarta?

---

## Actualización — 17 de agosto de 2026, tarde (revisión de la auditoría técnica y de visión, vía Cowork) — vigente

Mateo compartió una auditoría externa nueva, independiente de la del 16 de
agosto (`docs/auditoria_tecnica_y_vision_17ago2026.md`), con hallazgos
técnicos (C1–C4 críticos, A1–A4 altos, M1–M4 medios) y una sección
estructural/de visión. Por instrucción de Mateo esta ronda se enfocó solo
en la parte estructural/visión — los hallazgos técnicos quedan pendientes
de revisión aparte, no descartados.

**Verificación, no aceptación a ciegas.** Antes de aceptar nada de la
auditoría se verificó contra el estado real del repo (git real, vía
Desktop Commander):

- La afirmación de la auditoría de que "el roster XLSX actualizado refleja
  Jarvis + Efadam + tres ramas" **es correcta** — confirmado con `git log`
  y lectura directa del Excel: se corrigió y se commiteó por primera vez
  el 17 de agosto (commit `49b89fd`). Eso dejó desactualizado un pendiente
  de `estado_del_proyecto.md` que seguía diciendo lo contrario — corregido
  ahí también en esta ronda.
- La "Decisión recomendada" de la auditoría — congelar el roster **y el
  trabajo de distribución para terceros** hasta cerrar sus Bloques 0–1 —
  se reformuló: la parte de "congelar distribución para terceros" chocaba
  con la decisión explícita de Mateo del 16 de agosto de no congelar el
  alcance de producto distribuible (ver actualización de esa fecha, más
  abajo). En la práctica no hay trabajo activo de empaquetado que congelar
  (pendiente #11 de la lista de abajo sigue en diseño, sin implementar).
  Se descarta la palabra "congelar"; queda como lo que ya es de por sí: el
  pendiente #11 no empieza a implementarse hasta que cierren los hallazgos
  críticos de seguridad/confiabilidad, sin que eso implique pausar el
  diseño de producto distribuible.
- Mateo asumía que los Bloques 0, 1 y 2 de la auditoría del 16 de agosto
  (la que se viene remediando en este mismo documento, no la nueva) ya
  estaban cerrados. Se verificó con `git log`: **Bloque 0 y Bloque 1, sí.
  Bloque 2, no** — arrancó hoy mismo (ver la actualización de Bloque 2
  inmediatamente abajo) y está bloqueado en un hallazgo real de
  infraestructura, con una pregunta sin responder de Mateo (qué
  proveedor/llave conectar primero en OmniRoute). Corregido en
  `estado_del_proyecto.md`.
- Los 3 hallazgos críticos de la auditoría del 17 de agosto que hoy **no**
  están cubiertos por la secuencia de Bloque 2 — contraseña de Postgres
  expuesta en el historial de git (C1), inyección SQL en el nodo "Obtener
  config del bot" (C2), y el flujo de aprobación humana que hoy es solo
  una notificación saliente sin ruta de respuesta (C4) — se agregan a
  "Pendientes de Bloque 2, en secuencia" más abajo, antes del punto que
  inserta a Efadam: no tiene sentido activar el cerebro de orquestación
  encima de esos tres huecos. `nivel_importancia` (C3) ya estaba cubierto
  por el punto 8 existente.
- Se descarta el gate de "validar 2 semanas" que proponía la auditoría
  antes de construir la siguiente rama. Decisión de Mateo: el tiempo
  transcurrido no es la unidad correcta para validar un cluster — dos
  semanas con 3 tareas reales no dicen nada y dos semanas con 300 sí. Se
  corrigió el mismo patrón de criterio-por-tiempo en
  `docs/autonomia_progresiva.md` (el checklist de graduación de autonomía
  por cluster, que también usaba "2 semanas") y en la Fase 5 de este mismo
  documento (que duplicaba ese checklist) — reemplazado por un criterio de
  volumen de tareas reales, todavía sin número exacto: se calibra cuando
  haya datos reales de cuánto trabajo mueve cada cluster.
- **Aclaración de visión:** la frase de la auditoría "sistema operativo de
  trabajo para dueños de pequeños negocios" no fija un segmento de mercado
  nuevo — Mateo la confirma como forma de decir que el sistema no está
  pensado para operaciones grandes que necesiten mucha más capacidad de
  análisis o logística, sino para uso personal o negocios pequeños.
  Reflejado en `estado_del_proyecto.md`, sección "Qué es".

---

## Actualización — 17 de agosto de 2026 (Bloque 2, primer hallazgo real: schema de combos confirmado + 4 problemas de infraestructura en OmniRoute sin resolver) — vigente

Empezó Bloque 2 ("pasamos con el bloque 2", instrucción de Mateo). Primer
resultado: se confirmó, contra el código fuente real del contenedor
(no contra documentación ni supuestos), el schema exacto de
`POST /api/combos` — el pendiente que quedaba abierto desde el 16 de agosto.
Pero al investigar el contenedor de OmniRoute para llegar a ese schema,
salieron **4 problemas de infraestructura sin resolver**, ninguno cosmético,
que se documentan aquí antes de tocar nada — no se avanzó a configurar los 4
combos todavía, porque configurarlos encima de una base rota/insegura no
tiene caso.

### Confirmado: schema de `POST /api/combos` (createComboSchema)

Extraído directo del chunk compilado
`src_shared_validation_1p53ez_._.js` dentro del contenedor
(`infinite-power-omniroute-1`), no adivinado ni tomado de documentación que
podría estar desactualizada:

```
{
  name: string, requerido, 1-100 chars, regex [a-zA-Z0-9_/.\-\[\] ] (letras,
        números, espacios, - _ / . [ ])
  description?: string, máx 2000
  models?: array de "model entries" (default []) — cada entry es una de tres formas:
    - string plano (id de modelo, shorthand)
    - objeto { provider?, providerId?, model (requerido), connectionId?, tags?[],
               prompt?, id?, weight? (0-100, default 0), label? }
    - objeto { kind: "combo-ref" (requerido), comboName (requerido) } — permite
      que un combo referencie a otro combo como si fuera un "modelo" más
  strategy?: enum, default "priority" (lista completa de valores del enum
             ROUTING_STRATEGY_VALUES todavía no extraída — no crítico para el
             diseño de 4 combos simples, que no necesita cambiar el default)
  config?: objeto grande (~50 campos opcionales) — para el diseño actual
           (4 combos por nivel, fallback simple) solo hace falta dejar el
           default o, como mucho, tocar maxRetries/fallbackDelayMs
  allowedProviders?, allowedModelFamilies?, system_message?, tool_filter_regex?,
  context_cache_protection?, context_length?, dimensions?
}
```

También confirmados (mismo archivo): `updateComboSchema` (PATCH),
`reorderCombosSchema`, `testComboSchema` (`POST /api/combos/test`, body
`{comboName}` — sirve para probar un combo ya creado sin pasar por el
Ejecutor genérico), `updateComboDefaultsSchema`.

**Pendiente del 16 de agosto (`stack_y_convenciones.md`, `estado_del_proyecto.md`)
queda resuelto**: el schema de creación de combos ya no es una incógnita.

### 4 hallazgos de infraestructura — sin resolver, bloquean crear combos con confianza

1. **Bug real de persistencia: el volumen de OmniRoute apunta a la carpeta
   equivocada.** `docker-compose.yml` monta `./data/omniroute:/app/config`,
   pero los logs del contenedor (`DATA_DIR=/app/data`,
   `SQLite database ready: /app/data/storage.sqlite`) confirman que la ruta
   real donde OmniRoute guarda su base de datos (combos, credenciales,
   providers) es `/app/data`, no `/app/config`. Esto significa que **hoy
   nada de lo que se configure en OmniRoute vía dashboard o API sobrevive a
   una recreación del contenedor** (`docker compose up -d` con cambios, o
   cualquier `docker compose down`) — se perdería en silencio. Mismo tipo de
   bug que ya se encontró y corrigió en Bloque 0 con `N8N_ENCRYPTION_KEY`,
   pero este es peor porque no hay ningún síntoma visible hasta que se
   recrea el contenedor y de repente los combos ya no están.

2. **Faltan `JWT_SECRET` y `API_KEY_SECRET`.** Confirmado con
   `docker exec ... printenv` que el contenedor solo tiene `DATA_DIR`
   explícito entre las variables relevantes — `JWT_SECRET`, `API_KEY_SECRET`
   (y opcionalmente `STORAGE_ENCRYPTION_KEY`) no están seteadas. OmniRoute
   las documenta como requeridas para producción; sin ellas, probablemente
   está generando un valor de respaldo efímero por su cuenta, lo que en la
   práctica significa que **cualquier sesión/token/credencial guardada podría
   invalidarse en cualquier recreación del contenedor** — mismo problema que
   el punto 1 mirado desde el ángulo de seguridad, no solo de persistencia.

3. **No hay ninguna contraseña de dashboard configurada todavía** (el log
   de bootstrap sugería un default `CHANGEME`, pero **verificado en vivo
   que ese login no funciona** — devuelve `needsSetup: true`; ver
   actualización del 17 de agosto, noche, arriba). El API de
   administración (`/api/combos`, etc.) requiere login (`POST
   /api/auth/login`) o un API key con scope "manage" — hasta completar el
   asistente de onboarding, nadie (ni Mateo) puede entrar al dashboard.

4. **No hay ningún proveedor de modelos conectado todavía.** Evidencia en
   logs: `[AUTO] auto/*:pro matched no connected models`,
   `[ModelSync] No connections with autoSync enabled`. Aunque se creen los
   4 combos con el schema ya confirmado, **no van a rutear nada real** hasta
   que al menos un proveedor esté conectado dentro de OmniRoute — ver la
   actualización del 17 de agosto, noche (arriba) para los 3 proveedores
   que Mateo pidió (Pollinations, Cloudflare AI, Qwen) y el estado de cada
   uno.

### Decisión pendiente de Mateo — no se asumió, se pregunta

> **Superado por la actualización del 17 de agosto, noche (arriba).**
> Mateo ya contestó qué proveedores conectar (Pollinations, Cloudflare AI,
> Qwen), y ya no hay "Gemini del amigo" como opción — el proyecto es
> individual. El punto (c) de abajo también quedó corregido: no existe un
> login con `CHANGEME`, hace falta completar el asistente de onboarding de
> OmniRoute. Se deja el contenido original por trazabilidad de qué se
> pensaba en ese momento.

Por la instrucción vigente de preguntar en vez de asumir ante duda real: el
orden lógico antes de crear los 4 combos es (a) arreglar el volumen
`/app/config` → `/app/data` en `docker-compose.yml`, (b) generar y fijar
`JWT_SECRET`/`API_KEY_SECRET` en `.env` (mismo patrón que
`N8N_ENCRYPTION_KEY` en Bloque 0: si se puede rescatar un valor ya en uso,
reusarlo; si no, generar uno nuevo seguro), (c) loguearse con `CHANGEME` y
cambiar la contraseña, y solo entonces (d) decidir qué proveedor(es)
conectar primero — para (d) hace falta que Mateo confirme qué llave(s) usar
(la de Gemini del amigo, Groq, alguna otra ya mencionada en el plan, o algo
distinto) antes de tocar nada del lado de OmniRoute con esa llave.
**No se ha tocado `docker-compose.yml` ni `.env` todavía** — se documenta
aquí primero, se ejecuta después de la confirmación.

### Pendientes de Bloque 2, en secuencia (para retomar en otra conversación sin depender de memoria)

1. ~~**Pregunta abierta a Mateo, sin responder todavía:** qué proveedor/llave
   conectar primero en OmniRoute (Gemini del amigo, Groq, otra ya mencionada
   en el plan, o decidirlo después).~~ — **contestada (17/ago, noche):**
   Pollinations, Cloudflare AI, Qwen. Ver actualización del 17 de agosto,
   noche, arriba para las 3 decisiones nuevas que salieron de esa
   respuesta (contraseña de onboarding, cuenta de Cloudflare, riesgo de
   baneo de Qwen).
2. Arreglar `docker-compose.yml`: volumen de OmniRoute de `/app/config` a
   `/app/data`.
3. Generar y fijar `JWT_SECRET`/`API_KEY_SECRET` en `.env` (mismo patrón que
   `N8N_ENCRYPTION_KEY` de Bloque 0: reusar valor existente si se puede
   rescatar, si no generar uno nuevo seguro).
4. Loguearse a OmniRoute con la contraseña default `CHANGEME` y cambiarla.
5. Conectar el/los proveedor(es) que Mateo confirme en el punto 1.
6. Crear los 4 combos (`bajo`/`medio`/`alto`/`critico`) con el
   `createComboSchema` ya confirmado arriba.
7. Confirmar empíricamente si el campo `model` del request puede referenciar
   el combo directo por nombre, o si hace falta además
   `/api/model-combo-mappings` — no asumir, probar con una llamada real.
8. Propagar `nivel_importancia` a las tareas hijas en los nodos "Parsear
   asignaciones"/"Crear tareas hijas" del Ejecutor genérico en n8n.
9. Construir el workflow de ingesta Telegram → `tasks`.
10. Prueba end-to-end en vivo de todo el flujo de Bloque 2.
11. **Nuevo (17/ago, de `auditoria_tecnica_y_vision_17ago2026.md`, hallazgo
    C1):** rotar la contraseña de Postgres (`ALTER USER`) — la actual quedó
    expuesta en el historial de git (commits `a14ed39`, `e87fe0a`,
    alcanzable desde todas las ramas remotas) — y planificar la limpieza de
    ese historial.
12. **Nuevo (17/ago, hallazgo C2):** parametrizar la consulta SQL del nodo
    "Obtener config del bot" del Ejecutor genérico — hoy interpola el
    campo `bot` directo en `WHERE slug = '{{ $json.bot }}'`, y ese valor
    puede venir de una tarea hija generada por un modelo. Reemplazar por
    `slug = $1` vía `queryReplacement`.
13. **Nuevo (17/ago, hallazgo C4):** completar el flujo de decisión humana
    — hoy `needs_approval` solo manda un mensaje a Telegram sin ruta de
    respuesta real (ni fila en `approvals`, ni transición de estado
    atómica). Sin esto, una tarea sensible queda detenida indefinidamente y
    "aprobación humana" es una notificación saliente, no un control
    operativo.
14. Bloque 3: insertar y activar Efadam en `bots`, activar Tech center de
    punta a punta contra un Efadam real. **No antes de que cierren los
    puntos 11–13** — no tiene sentido activar el cerebro de orquestación
    encima de una contraseña filtrada, una inyección SQL abierta y
    aprobaciones que no se pueden resolver.
15. **Aparcado, no tocar sin instrucción nueva de Mateo:** licencia de n8n
    (Sustainable Use License, riesgo de distribución) — deferred a la fase
    de "setup" al final, por instrucción explícita de Mateo del 17 de agosto.

---

## Actualización — 16 de agosto de 2026 (mecanismo concreto nivel → modelo, `schema/005_nivel_importancia.sql`) — histórica, ver corrección y auditoría más arriba/abajo

Quedaba un hueco real señalado por Mateo: se documentaba "OmniRoute traduce
nivel → modelo" como principio, sin especificar nunca el mecanismo. Resuelto:

- **`nivel_importancia` vive en `tasks`, no en `bots`** — coherente con que
  Efadam asigna el nivel por tarea, no por bot fijo. Migración nueva:
  `schema/005_nivel_importancia.sql` (columna + check constraint). Reemplaza
  a `bots.default_model` como fuente del modelo a llamar (esa columna queda
  sin uso activo, no se elimina por ahora).
- ~~**OmniRoute es LiteLLM self-hosted.**~~ — **Falso, corregido el 16 de
  agosto por la tarde (ver actualización de arriba). Esto se escribió sin
  verificarlo contra el contenedor real y era un error.** OmniRoute es un
  proyecto open-source distinto y no relacionado (`diegosouzapw/OmniRoute`),
  no LiteLLM. El mecanismo real de nivel → modelo es via **"combos"
  nombrados** de OmniRoute, referenciables directo por nombre en el campo
  `model` del request, más el endpoint `/api/model-combo-mappings` para
  mapear un patrón de modelo a un combo. El esquema exacto de creación de un
  combo (`POST /api/combos`) todavía no está confirmado — pendiente de
  verificar via la UI del dashboard antes de configurarlo. Detalle completo
  en `stack_y_convenciones.md`.
- **Corrección de encoding:** los 4 valores literales del sistema
  (`tasks.nivel_importancia`, el nombre del combo de OmniRoute, lo que Efadam
  escribe en el JSON de la tarea) son `bajo`/`medio`/`alto`/`critico` —
  **sin tilde en "critico"**, porque son identificadores de sistema, no
  texto para leer.
  El prompt de Efadam (`efadam.md`) tenía "crítico" con tilde, lo cual
  habría roto el `INSERT` en cuanto Efadam generara una tarea crítica de
  verdad — corregido antes de activarlo, no después. La prosa de los
  documentos sigue usando tilde donde es solo lectura humana.

**Ejecutado el mismo 16 de agosto:** la migración ya corrió contra Postgres
(`ALTER TABLE`/`COMMENT` confirmados, `tasks.nivel_importancia` existe con
su check constraint) y el nodo "Llamar a omniroute" del Ejecutor genérico
(workflow `aVORciBJl52lTxTU` en n8n) ya se editó vía la API de n8n: el
campo `model` del request ahora lee
`$('Reclamar tarea pendiente').first().json.nivel_importancia` en vez de
`$('Obtener config del bot').first().json.default_model` — verificado con
un `GET` posterior al `PUT`. El pendiente #16 de abajo queda completo.

**Todavía falta, no incluido en este cambio:** configurar los 4 combos de
OmniRoute (uno por nivel) y sus `model-combo-mappings`, e insertar a Efadam
en la tabla `bots` — el nodo ya está listo para recibir `nivel_importancia`,
pero hoy ninguna tarea trae ese campo poblado porque nada lo está asignando
todavía (Efadam no existe como bot activo). Sin esos dos pasos, cualquier
tarea nueva llegaría a OmniRoute con `model: null`.

---

## Actualización — 16 de agosto de 2026, tarde/noche (auditoría externa, corrección OmniRoute/LiteLLM, rama `correcciones`, reconstrucción de `schema/001_init.sql`) — VIGENTE, léase primero

Mateo subió una auditoría completa del estado del vault/repo/schema
(`auditoria_infinite_power_16ago2026.md`), con 31 hallazgos numerados y un
plan de remediación en 4 bloques. Se verificaron independientemente los
hallazgos más graves (no se aceptó la auditoría de fe) — todos los
verificables resultaron correctos, y uno resultó **peor** de lo que la
propia auditoría sospechaba:

**1. Corrección: OmniRoute NO es LiteLLM.** La actualización del 16 de
agosto de arriba (y `stack_y_convenciones.md`, `efadam.md`, `arquitectura.md`,
los tres ya corregidos) afirmaban que OmniRoute era LiteLLM self-hosted, con
un `config.yaml` de alias de modelo. Eso se escribió sin verificarlo contra
el contenedor real y era falso. Verificado directo dentro del contenedor
(`docker exec infinite-power-omniroute-1 ...`): OmniRoute es un proyecto
open-source real y distinto, `diegosouzapw/OmniRoute`. El mecanismo real:
providers conectados vía su propio dashboard (`http://localhost:20128`),
ruteo nativo `auto/<categoria>:<tier>`, y **"combos" nombrados**
(`GET/POST /api/combos*`) referenciables directo por nombre en el campo
`model` del request, más `/api/model-combo-mappings` para mapear un patrón
de modelo id a un combo. **No confirmado todavía:** el schema exacto de
`POST /api/combos` (crear un combo) — pendiente verificar via la UI del
dashboard antes de configurar los 4 combos por nivel, no adivinar.

**2. Decisión de Mateo — nunca borrar ni mergear ramas.** Sobre cómo
ejecutar el Bloque 0 de la auditoría (que incluía mergear `efadam` → `main`
y borrar ramas viejas): Mateo corrigió — "todo el punto de github es un
control de versiones" — nunca se borran ni mergean ramas sin instrucción
explícita futura. En su lugar, se creó una rama nueva **`correcciones`**
desde `efadam` (commit `80b7391`), y ahí vive todo el trabajo de respuesta
a la auditoría. `main`, `alphav0.1`, `alphav0.2`, `efadam` quedan intactas.

**3. Decisión de Mateo — NO congelar el alcance de "producto distribuible".**
La auditoría (sección G) sugería congelar temporalmente el trabajo de
empaquetado/distribución (Revert, Multiproyecto, empaquetado de OmniRoute)
para enfocar el esfuerzo en la operación de un solo operador. Mateo lo
rechazó explícitamente: hacerlo arriesga construir una mala base, porque
producto distribuible **es el objetivo final** y tiene que seguir en la
vista aunque no sea el foco inmediato — no se pausa ningún punto 17/18/19
de la lista de pendientes de abajo por esto.

**4. Bloque 0 — ejecutado hasta ahora (en la rama `correcciones`):**
reconstruido `schema/001_init.sql` — **nunca se había commiteado** (hallazgo
central e independientemente confirmado de la auditoría: `git log` muestra
que `schema/*.sql` en git solo tuvo migraciones `ALTER TABLE` desde el
002, nunca un `CREATE TABLE` — un clon nuevo del repo no podía levantar la
base de datos). Se reconstruyó via `pg_dump --schema-only` contra la base
real, restando lo que 002-005 agregan encima, y se **verificó de verdad**
corriendo 001→006 en orden contra una base Postgres vacía de prueba
(`test_repro`, borrada después) — sin errores, misma estructura que la base
real. De paso se encontró y corrigió un bug real, no solo de documentación:
dos `COMMENT ON COLUMN` (`bots.conocimiento_directo`,
`tasks.nivel_importancia`) habían quedado con mojibake **dentro de la base
de datos real** porque se aplicaron anteriormente vía `psql`/PowerShell sin
forzar UTF-8 en el pipe — nueva migración `schema/006_fix_encoding_comments.sql`,
ya corrida contra la base real y verificada byte por byte. Todo commiteado
y pusheado a `origin/correcciones` (commit `f09880b`).

**Nota de proceso, para no repetir el mismo bug:** escribir archivos con
acentos/caracteres especiales al vault vía el puente a la máquina de Mateo
resultó intermitentemente poco confiable durante esta sesión (el mismo
archivo `006_fix_encoding_comments.sql` salió corrupto dos veces antes de
salir limpio, sin cambiar el método). Regla adoptada: verificar siempre con
un chequeo de codepoints (`[int[]][char[]]$string`) antes de aplicar
cualquier texto en español contra Postgres, y preferir `docker cp` +
`psql -f` dentro del contenedor en vez de pipes de PowerShell para
cualquier contenido no-ASCII.

**Bloque 0 — completo (16 de agosto, noche).** Los 6 puntos, todos
verificados de verdad, no solo aplicados a ciegas:

- Workflows de n8n exportados a `n8n-workflows/*.json` (Ejecutor genérico,
  Reanudador de bloqueados) — revisados, sin secretos embebidos.
- `scripts/backup_postgres.ps1` — probado, generó un respaldo real de 3MB;
  retiene los últimos 8, uso manual o programable via Windows Task
  Scheduler (semanal recomendado).
- `.gitattributes` (`* text=auto eol=lf`) para el ruido de line-endings que
  señalaba la auditoría; de paso se gitignoró `.obsidian/graph.json`
  (mismo tipo de estado local que `workspace.json`, no contenido real).
- Password de Postgres y `N8N_ENCRYPTION_KEY` sacados de `docker-compose.yml`
  en texto plano, movidos a `.env` (gitignored) + `.env.example` como
  plantilla para instalaciones nuevas. La `N8N_ENCRYPTION_KEY` puesta es la
  **misma** que n8n ya tenía auto-generada — no se rotó, solo se hizo
  explícita, para no invalidar credenciales existentes.
- `GENERIC_TIMEZONE`/`TZ=America/Mexico_City` agregado a n8n.
- Aplicado con `docker compose up -d`: recreó el contenedor de n8n, se
  verificó que subió limpio (migraciones corridas, mismo `encryptionKey`
  confirmado dentro del contenedor) y que los 3 workflows existentes siguen
  ahí y responden vía API sin haber perdido nada.

**Bloque 1 — completo en su mayoría (16-17 de agosto).** Las 5 contradicciones
de "fuente de verdad" corregidas, los 2 wikilinks rotos de `INICIO.md`
desligados, y `docs/estado_del_proyecto.md` reescrito de cero. Todo
committeado en `correcciones` y **pusheado a GitHub** (commits `e97b5fc`,
`220d04b`, `b94af50` — confirmado con `git log origin/correcciones`).
Decisiones que se le preguntaron a Mateo en vez de asumirse: `estado_del_proyecto.md`
se reescribe (no se archiva); los wikilinks rotos se desligan (no se repuntan
a una nota adivinada, porque ninguna de las dos notas fusionadas tiene un
reemplazo 1:1 real).

**Sigue pendiente de Bloque 1:** limpiar duplicados en el Claude Project
(`trouble-shooter.md`, `tecnico-jefe.md`, `plan_de_accion_completo.md`,
`ejecutor_generico.md` — cada uno x2) — identificados, no eliminados
todavía.

**Bloqueo de infraestructura — resuelto (17 de agosto).** Las herramientas
`Desktop_Commander` (acceso a PowerShell/Docker/git reales en Windows) se
habían desconectado a media sesión el 16 de agosto y no volvían a aparecer
ni en el registro de herramientas; mientras tanto se trabajó con el bridge
estándar (`device_bash`), que corre en una VM Linux aislada sin
Docker/n8n/Postgres y sin acceso de red — eso dejó el commit `e97b5fc` local,
sin poder pushear. El 17 de agosto `Desktop_Commander` volvió a conectar.
Con acceso real se limpiaron los archivos `.lock`/`tmp_obj` que la VM aislada
había dejado sueltos en `.git/` (no podía borrarlos, solo moverlos) y se
pusheó `correcciones` sin problema — confirmado contra `origin/correcciones`.
**Bloque 2 (combos de OmniRoute, Postgres, n8n) ya es viable** con
`Desktop_Commander` disponible — no depende de correr la tarea "en tu
computadora" salvo que `Desktop_Commander` se vuelva a desconectar.

**Limpieza de duplicados en el Claude Project — hecho (17 de agosto).**
`trouble-shooter.md`, `tecnico-jefe.md`, `plan_de_accion_completo.md` y
`ejecutor_generico.md` tenían dos copias cada uno (una vieja del 14/15 de
agosto, una nueva). `project_delete` por path borró primero la copia más
reciente en vez de la vieja (comportamiento no documentado de la
herramienta) — se detectó de inmediato al verificar y se corrigió
re-escribiendo el contenido correcto antes de tocar los otros tres archivos.
Confirmado: 30 docs únicos en el Project, uno por path, contenido correcto
en los 4 verificado por lectura directa.

**Archivos faltantes subidos al Project — hecho (17 de agosto):**
`docker-compose.yml`, `003_trouble_shooter_v2.sql`, `004_conocimiento_directo.sql`.

**Hallazgo al subirlos:** `004_conocimiento_directo.sql` tiene un
encabezado de comentario que dice `003_conocimiento_directo.sql` — quedó mal
renumerado en algún punto anterior (el archivo en disco es el 004, el
comentario adentro sigue diciendo 003). No corregido todavía — es cosmético
(el nombre de archivo real en el filesystem es el que manda), se deja
anotado para no perder el rastro.

**`roster_agentes_v4.xlsx` — confirmado NO commiteado, y ni siquiera existe
en el vault.** Búsqueda completa en `C:\Users\2\Documents` (vía
`Desktop_Commander`, recursiva) no encontró ningún archivo con "roster" en
el nombre. El único lugar donde existe es como blob subido directo al
Claude Project el 14 de agosto — nunca llegó al repo. Además, ya está
marcado como desactualizado en la sección "Deuda documentada" de
`estado_del_proyecto.md` (organización por los 6 clusters planos viejos,
"Project center" en vez de "Proyect center", faltan bots). **No lo subí al
vault/git sin preguntar** porque no es obvio que tenga sentido versionar un
archivo que ya se sabe que está mal — la duda real es si (a) se actualiza
primero y luego se sube, o (b) se sube tal cual con una nota de que está
desactualizado, o (c) se descarta y el roster vive solo en `arquitectura.md`
de aquí en adelante.

---

## Actualización — 15 de agosto de 2026, noche, cuarta ronda (Setup, Revert, Multiproyecto — fusionados desde nota de visión aislada) — histórica, ver actualización de arriba para lo más reciente

Se fusionó a este documento el contenido que no estaba cubierto en ningún
otro lado de una nota de visión antigua y aislada (`docs/vision/Infinite
power.md`, ahora eliminada — el resto de su contenido, Cadencia/Memoria/
Comunicación entre bots, ya estaba cubierto en `ejecutor_generico.md`,
`memoria_del_sistema.md` y `stack_y_convenciones.md`, así que no se repite
aquí). Tres piezas de diseño nuevas, sin implementar todavía:

**Setup (vive en Proyect center).** Es una entrevista de objetivo que
produce: la meta, la lista de pasos necesarios para llegar a ella, y un
criterio de "listo" (para que el proyecto pueda pasar a modo mantenimiento
de baja frecuencia en vez de generar ideas indefinidamente sobre algo ya
cumplido). El Setup **no dispara nada directamente** a otras ramas — mismo
principio de cuello de botella ya documentado en `efadam.md`: Setup
(Proyect center) → el resultado vuelve a Efadam → Efadam decide qué
jefe(s) le corresponde cada parte y les inyecta el contexto específico →
el jefe correspondiente decide dentro de su propio dominio si hace falta
construir algo nuevo vía Agent builder.

**Revert.** No se borra nada — se archiva. Tres capas, cada una con su
propio mecanismo (no una sola): (1) prompts/config de bots → git, reversible
de verdad; (2) `knowledge_log` (decisiones/hallazgos) → histórico
append-only, no se revierte, se archiva (`archived_at` + `archived_reason`,
disparado por una tabla `reverts (fecha_objetivo, disparado_por, motivo)`;
Efadam solo lee lo vigente por default, lo archivado queda disponible para
Trouble scouter y revisión manual); (3) acciones que ya salieron al mundo
real (correo enviado, pago hecho) → no reversibles, punto — no es lo que
nadie esperaría de esta función. Se dispara solo por Mateo vía Telegram →
Efadam, nunca automático.

> **Superado (18/ago/2026):** el diseño de abajo (schema por proyecto,
> n8n/OmniRoute compartidos) fue reemplazado. Ver "Multiproyecto —
> rediseño (18/ago/2026)" en `docs/arquitectura_general.md` para el
> diseño vigente (cada proyecto = despliegue completo independiente).

**Multiproyecto (visión, no construir todavía — post Fase 2 del recorrido
vertical actual).** ~~Un proyecto nuevo = un schema nuevo en el mismo
Postgres, no una base de datos ni un stack completo nuevo.~~ Se comparte:
n8n, OmniRoute, y los prompts del kernel (versionados en git). Se aísla por
proyecto: solo los datos, vía schema. Una tabla de control
`proyectos (id, nombre, schema_name, estado, fecha_creación)` le permite a
Efadam saber qué proyectos existen; los nodos de Postgres en n8n deben
apuntar al schema de forma dinámica (parámetro, no hardcodeado) — requisito
de diseño desde ahora, no algo que se pueda parchar después sin refactor.
Los proyectos corren en paralelo, cada uno con su propia cadencia — el
Schedule Trigger consulta `proyectos WHERE estado = 'activo'` y despacha una
ejecución por cada uno. **Pendiente técnico antes de construir esto:**
confirmar que los workflows actuales de n8n no tienen el schema
hardcodeado — si lo tienen, hace falta migrarlos primero.

---

## Actualización — 15 de agosto de 2026, noche, tercera ronda (reglas explícitas de nivel — pendiente #15 resuelto) — VIGENTE, léase primero

Se resolvió el pendiente de diseño de la actualización inmediata de abajo:
Efadam **no** clasifica el nivel de importancia con criterio libre — aplica
una tabla de reglas fijas por dominio/tema, ya escrita en
`stack_y_convenciones.md` ("Niveles de importancia y BYOK" → "Reglas de
asignación"):

- Gasto de dinero, tema legal/contractual, publicación pública, cambio de
  seguridad → mínimo `crítico`.
- Decisión de precio, contratación/despido, compromiso frente a terceros →
  mínimo `alto`.
- Trabajo especializado normal (código, investigación, redacción, análisis)
  sin lo anterior → `medio`.
- Ruteo, resumen de estado, tareas mecánicas → `bajo`.

Si una tarea coincide con varias reglas, gana la más alta; si no encaja
claramente en ninguna, sube por default al nivel superior más cercano, y si
la ambigüedad es real, Efadam pregunta en vez de asumir. Las reglas viven en
`system_knowledge`, no hardcodeadas en el prompt — pueden ajustarse por el
mismo mecanismo de cuello de botella (Efadam solicita, U&R center evalúa y
redacta, Efadam inserta), no son una excepción nueva. Detalle completo en
`stack_y_convenciones.md` y `efadam.md` (prompt de sistema y casos de
prueba actualizados).

---

## Actualización — 15 de agosto de 2026, noche, segunda ronda (corrección: Efadam asigna el nivel, no cada bot) — histórica, ver corrección de arriba

Corrige un error en la actualización inmediata de abajo: decía "cada bot
declara su nivel de importancia", lo cual contradice el resto del diseño de
Efadam (un bot individual no tiene visión de negocio para juzgar su propia
importancia; esa visión es justamente lo que hace Efadam). Corregido: es
**Efadam** quien asigna el `nivel_importancia` de cada tarea al despacharla
— el bot destino lo hereda, no lo decide. Detalle en `efadam.md` y
`stack_y_convenciones.md`.

**Este documento dejó abierto, en su momento, si esa clasificación debía ser
criterio libre de Efadam o reglas fijas — resuelto en la actualización de
arriba: reglas fijas.**

---

## Actualización — 15 de agosto de 2026, noche (niveles de importancia + BYOK + empaquetado de OmniRoute/n8n) — VIGENTE, léase primero

Se rediseña de fondo cómo el sistema decide qué modelo usa cada bot, y cómo
se distribuye OmniRoute como parte del producto. Reemplaza el contenido del
Paso 0.5 más abajo (que describía OmniRoute configurado a mano con las
llaves de Mateo) y la sección "Presupuesto" que tenía `stack_y_convenciones.md`.
Detalle completo del diseño en `stack_y_convenciones.md`, sección "Niveles de
importancia y BYOK" — resumen aquí:

- 4 niveles fijos del sistema (`bajo`, `medio`, `alto`, `crítico`). **Efadam**
  asigna a cada tarea el nivel que le corresponde (columna `nivel_importancia`
  en `tasks`, heredada por el bot que la ejecuta) — ningún bot decide el
  suyo propio, y nunca se declara un modelo específico. OmniRoute es el
  único que traduce nivel → modelo real. Ver corrección de la actualización
  inmediata de arriba.
- OmniRoute (y n8n, con el Ejecutor genérico ya importado) se distribuyen
  empaquetados — mismo `docker-compose.yml` del sistema — con un modelo
  gratis ya asignado por default a cada nivel. El setup deja de requerir
  cablear una llave API por bot a mano.
- En el setup, el usuario ve los 4 niveles con su default gratis y un
  disclaimer recomendando subir de nivel `alto`/`crítico`; puede añadir sus
  propias llaves por nivel en cualquier momento, no es bloqueante.
- Es una característica **por instalación**: cada quien que instale Infinite
  Power tiene su propio OmniRoute con sus propias llaves, no comparte el de
  Mateo. Esto reencuadra el Paso 0.4/0.5 de más abajo: ya no son "cómo
  configuro mi OmniRoute", son "cómo se empaqueta OmniRoute para cualquier
  instalador futuro".

**Consecuencia práctica:** el Paso 0.5 original (abajo, en Fase 0) queda
marcado como histórico — se corrigió su contenido en línea con nota, en vez
de borrarlo, para no perder el registro de qué se intentó primero.

---

## Actualización — 15 de agosto de 2026, noche (refuerzo de documentación: cuello de botella + `conocimiento_directo`)

Se fusionó al resto de la documentación un mecanismo que vivía aislado en una
nota de visión antigua (`docs/vision/Efadam/Efadam.md`, nunca conectada al
resto del vault): la columna `bots.conocimiento_directo`, única excepción
válida a que todo conocimiento cruzado entre ramas pase por Efadam. Detalle
completo, ya integrado, en `memoria_del_sistema.md` y `efadam.md`. Además se
corrigió en varios documentos el uso de la palabra "estático" al describir
`system_knowledge` — no es inmutable, evoluciona con el tiempo vía Upgrade &
review center; lo que no hace es cambiar mensaje a mensaje, a diferencia de
la lectura en vivo de `tasks`/`agent_runs`.

**Nota explícita, porque es un rasgo diferenciador del proyecto:** el cuello
de botella de Efadam es intencional, no un descuido de diseño — la fricción
de que todo pase por un único punto es lo que permite que el sistema
aprenda de forma centralizada. Este principio se repite en varios documentos
a propósito (`arquitectura.md`, `efadam.md`, `memoria_del_sistema.md`), no
solo aquí.

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
    repetido incrementa `veces_visto` en vez de duplicarse. Eso reemplaza la
    regla del prompt "si ya pasó 3+ veces márcalo como recurrente", que dependía
    de que el modelo recordara algo que no tiene forma de saber.
- **No se inyecta lo mismo a todos los bots.** Columna `bots.contexto_slugs
  text[]`: cada bot declara qué necesita. Abogado Jefe no carga el schema de
  Postgres para dar un dictamen legal.
- Se descartó (otra vez, y ahora explícitamente) que Trouble shooter tenga un
  banco propio. Un solo mecanismo, permisos de escritura distintos por tipo.
- Las **reglas generales** siguen viviendo dentro del `system_prompt` de cada
  bot, pero ya no se prependen a mano: se agrega la columna `prompt_especifico`
  y un trigger compone `system_prompt = reglas + '---' + prompt_especifico`.
  Los dos bots ya insertados (`tecnico_jefe`, `coder`) **nunca las tuvieron** —
  se insertaron antes de que existiera la regla. El backfill está en el `.sql`.

Aclaración de roles de los 3 centers (sigue vigente): su función principal es
**retener** (gatekeeping y auditoría activa de su rama), no solo enrutar. Efadam
solo revisa que no haya discrepancia entre lo entregado y la meta establecida;
si la hay, regresa comentarios, no re-audita el detalle de ejecución.

`prompts_dev_tech/upgrade-review-center.md` sigue restaurado y vigente: es cabeza
de su propio departamento, al mismo nivel que Tech center y Proyect center.

---

## Actualización — 15 de agosto de 2026, mañana (repo pasa a ser seed, no fuente de verdad; Efadam deja de redactar) — VIGENTE

Corrige de fondo dos puntos de la actualización del 14 de agosto de arriba —
esa sección se deja como está por trazabilidad, pero ya no aplica en esto:

**1. `system_knowledge` ya NO se sincroniza desde el repo de forma recurrente.**
El repo (`docs/context/*.md`, `reglas_generales.md`) pasa a ser el **seed
inicial** — se carga una sola vez, a mano, con el mismo upsert que usaba el
workflow, **cuando haya un producto final real que probar** (ver actualización
de la noche del 15 de agosto arriba — no es un paso a correr ahora). Después
de ese arranque, **la tabla es la fuente de verdad viva**; el repo puede
quedar desactualizado y es esperado, no un bug. Razón del cambio: el sistema
está pensado para más de un operador, y mantener una credencial de GitHub con
lectura de todo el repo privado, viva en n8n, para un trigger que de todas
formas era manual, dejó de tener sentido — cualquiera con acceso al editor de
workflows heredaba de facto acceso al repo. El workflow **"Sync conocimiento
del sistema" se borró en n8n** (confirmado) y **el PAT de GitHub que usaba se
revocó** (confirmado, 15 de agosto). Detalle completo del razonamiento en
`memoria_del_sistema.md`.

**2. `aprendizaje` (y ahora también `system_knowledge`) ya NO lo redacta
Efadam.** Precisión que faltaba documentar: Efadam sigue siendo el cuello de
botella único de entrada (nada llega a Postgres sin pasar por él), pero
**quien redacta y evalúa el contenido es Upgrade & review center** — es su rol
ya definido ("Observar → Analizar → Mejorar", no aprobar por default) aplicado
también al conocimiento del sistema, no solo a hallazgos de investigación.
Efadam solicita, U&R center produce, Efadam inserta sin re-auditar el fondo —
mismo patrón que ya tenía con el resto de lo que U&R center le reporta.
Corregido en `efadam.md` y `upgrade-review-center.md`.

**Consecuencia práctica para lo que sigue pendiente:** cuando se construya la
lógica real en n8n de "Efadam inserta lo que U&R center redactó" (ver
checklist maestro), ya no hay que diseñar ningún nodo que lea GitHub — solo
Postgres de un lado (leer contexto) y Postgres del otro (insertar lo que U&R
center entrega).

---

## Actualización — 14 de agosto de 2026, tarde (secuencia y alcance) — parcialmente histórica, ver nota

Revisión de la lista de pendientes. Tres correcciones de fondo:

**1. La lista de pendientes estaba desactualizada respecto a la decisión de
memoria de esa misma mañana.** Seguía diciendo "crear tabla `project_knowledge`"
(renombrada `system_knowledge`) y "Trouble shooter: banco de conocimiento propio"
(descartado). Los prompts de `consultor-de-arquitectura.md` y `trouble-scouter.md`
todavía referencian `project_knowledge` y `trouble_shooter_knowledge`, que ya no
existen — hay que corregirlos antes de activarlos.

**2. Todo lo pendiente era el sistema construyéndose a sí mismo.** De los 10
pendientes, 9 eran infraestructura meta: memoria, bots que auditan bots, bots que
revisan la arquitectura. Cero valor de negocio entregado. **Nota del 15 de
agosto:** la referencia a "Legal" como siguiente paso aquí abajo queda
superada por la actualización de esa misma noche (ver más abajo) y, sobre
todo, por el nuevo orden vertical de la noche del 15 de agosto (arriba) — hoy
lo siguiente no es un cluster de negocio, es Efadam.

**3. Se posponen dos bots ya diseñados, con criterio explícito de activación:**

| Bot | Se activa cuando |
|---|---|
| Consultor de arquitectura | El output de Coder deje de ser leído línea por línea por Mateo antes de mergear |
| Trouble scouter | Haya 12+ bots activos, o 2+ ramas corriendo a diario |

Los prompts ya escritos se quedan en el repo — no se pierde el trabajo. Lo que se
pospone es el `INSERT INTO bots`, que es lo que cuesta tokens y latencia. Hoy hay
2 bots activos y Mateo revisa cada corrida a mano: ambos bots estarían auditando
lo que un humano ya audita.

**Consecuencia inmediata:** el bloque "PROTOCOLO OBLIGATORIO" del prompt de
Técnico jefe (que manda consultar a `consultor_arquitectura`) **no se carga** en
la tabla `bots`. Si se cargara, Técnico jefe asignaría tareas a un slug que no
existe: el nodo "Obtener config del bot" devuelve vacío, la ejecución revienta, y
la tarea queda `failed` sin que nadie entienda por qué.

**Sistema de aclaración — se simplifica a dos piezas** (ver `ejecutor_generico.md`
sección 5): un `CASE` en el UPDATE de "Guardar resultado" que marca `blocked`, y
un IF + Telegram que le manda la pregunta a Mateo. El workflow "Reanudador de
bloqueados" se pospone hasta tener evidencia de que los bots se bloquean seguido
y cadenas de más de 2 niveles donde el humano sea el cuello de botella real.

**`tasks_status_check`:** `init.sql` nunca creó ese constraint, así que `blocked`
funcionaba por accidente (cualquier string era válido). Se agrega explícito en
`002_conocimiento.sql` con los 6 estados válidos.

---

## Actualización — 14 de agosto de 2026, noche (orden real de construcción) — histórica, ver nota del 15 de agosto arriba

Corrección de Mateo, con razón: Legal se venía arrastrando como "el siguiente
paso" solo porque el plan original de 7/ago lo eligió como candidato de bajo
riesgo para probar el patrón — no porque el negocio lo necesite. No hay
justificación de negocio para priorizarlo hoy.

**Orden de construcción confirmado ese día (superado por el orden vertical
del 15 de agosto, arriba — se deja por trazabilidad):**
**Dev/Tech → Estrategia/Crecimiento → Operación/Proyectos.**
Legal (y el resto de Negocios propios) queda pospuesto sin fecha — se retoma
si/cuando el negocio lo necesite, no por calendario del proyecto.

El loop Técnico jefe → Coder, probado de punta a punta con memoria, manejo de
errores y aprobación, sigue siendo la prueba real de que el patrón del
ejecutor genérico funciona — eso no cambió con la actualización del 15 de
agosto, solo cambió qué se construye a continuación (Efadam, no un cluster de
negocio más).

---

## 0. Antes de empezar

**Checklist de cuentas/recursos a tener listos:**

> **Nota del 17 de agosto, noche:** este checklist y la tabla de abajo se
> escribieron cuando el proyecto era de Mateo + un amigo/cofundador. Mateo
> confirmó que el proyecto es individual — se corrigió el checklist y se
> quitó la tabla de reparto (ya no aplica, un solo dueño para las 3 ramas).

- [ ] Dominio (ya lo tienen) — acceso al panel DNS
- [ ] Tarjeta para pagar el VPS (~$5–6 USD/mes)
- [ ] Cuenta de GitHub de Mateo con el repo
- [ ] Claves de API: la que compre Mateo con sus $150 MXN, Groq, y cualquier otra que ya tengan de OmniRoute
- [ ] Teléfono para crear el bot de Telegram
- [ ] Contraseña del VPS guardada en un gestor tipo Bitwarden

**Dueño de las 3 ramas:** Mateo. (La rama Tech center ya tiene sus 10 prompts escritos — ver `arquitectura.md`.)

---

## FASE 0 — Infraestructura base

**Objetivo de la fase:** tener un servidor propio corriendo n8n + Postgres + OmniRoute, accesible por su dominio, con HTTPS, con un repo de GitHub y un bot de Telegram listos para usarse en las fases siguientes.

**Tiempo estimado:** un fin de semana (4–8 horas repartidas).

### Paso 0.1 — Levantar el VPS

1. Crear cuenta en Hetzner Cloud (o DigitalOcean si prefieren, la mecánica es igual).
2. Crear un servidor tipo **CX22** (o equivalente ~4GB RAM / 2 vCPU), imagen **Ubuntu 24.04**, en la región más cercana a México (US-East si no hay opción en LATAM).
3. Al crearlo, agreguen su llave SSH pública (si no tienen una, generarla con `ssh-keygen -t ed25519`).
4. Anoten la IP pública del servidor.

### Paso 0.2 — Apuntar el dominio

1. En el panel DNS de su dominio, crear un registro **A** apuntando un subdominio (ej. `n8n.sudominio.com`) a la IP del VPS.
2. Si quieren exponer OmniRoute también, otro registro A: `router.sudominio.com` → misma IP.
3. Esperar a que propague (puede tardar de minutos a un par de horas).

### Paso 0.3 — Preparar el servidor

Conectarse por SSH (`ssh root@IP`) y correr:

```bash
apt update && apt upgrade -y
apt install -y docker.io docker-compose-plugin ufw fail2ban
ufw allow OpenSSH
ufw allow 80/tcp
ufw allow 443/tcp
ufw enable
systemctl enable docker --now
```

Crear un usuario no-root para trabajar (buena práctica de seguridad):

```bash
adduser deploy
usermod -aG docker deploy
```

### Paso 0.4 — Estructura de carpetas y docker-compose

```bash
mkdir -p /opt/infinite-power/{n8n_data,postgres_data,omniroute,caddy_data}
cd /opt/infinite-power
```

Crear `docker-compose.yml`:

```yaml
version: "3.8"

services:
  postgres:
    image: postgres:16
    restart: unless-stopped
    environment:
      POSTGRES_USER: infpower
      POSTGRES_PASSWORD: CAMBIA_ESTA_CLAVE
      POSTGRES_DB: infinite_power
    volumes:
      - ./postgres_data:/var/lib/postgresql/data
    networks:
      - infpower

  n8n:
    image: n8nio/n8n:latest
    restart: unless-stopped
    environment:
      - N8N_HOST=n8n.sudominio.com
      - N8N_PROTOCOL=https
      - WEBHOOK_URL=https://n8n.sudominio.com/
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_HOST=postgres
      - DB_POSTGRESDB_DATABASE=infinite_power
      - DB_POSTGRESDB_USER=infpower
      - DB_POSTGRESDB_PASSWORD=CAMBIA_ESTA_CLAVE
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=admin
      - N8N_BASIC_AUTH_PASSWORD=CAMBIA_ESTA_CLAVE_TAMBIEN
    volumes:
      - ./n8n_data:/home/node/.n8n
    depends_on:
      - postgres
    networks:
      - infpower

  omniroute:
    image: ghcr.io/diegosouzapw/omniroute:latest
    restart: unless-stopped
    ports:
      - "4000:4000"
    volumes:
      - ./omniroute:/app/config
    networks:
      - infpower

  caddy:
    image: caddy:2
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile
      - ./caddy_data:/data
    networks:
      - infpower

networks:
  infpower:
```

> Verifica el nombre exacto de la imagen Docker de OmniRoute en su repo de GitHub antes de levantar el contenedor — puede cambiar. Si no publican imagen oficial, se clona el repo y se construye localmente con su propio Dockerfile.
>
> **Nota 15 de agosto de 2026 (histórica — ver actualización de niveles/BYOK arriba):** este `docker-compose.yml` sigue siendo la base técnica vigente (Postgres + n8n + OmniRoute + Caddy en un solo stack), pero el paso 0.5 de abajo (configurar OmniRoute a mano con llaves propias) queda superado: para un producto distribuible, el compose debe traer OmniRoute preconfigurado con defaults gratis por nivel de importancia desde el primer arranque, no como paso manual posterior.

Crear `Caddyfile` (esto da HTTPS automático gratis):

```
n8n.sudominio.com {
    reverse_proxy n8n:5678
}

router.sudominio.com {
    reverse_proxy omniroute:4000
}
```

Levantar todo:

```bash
docker compose up -d
docker compose ps
```

Entrar a `https://n8n.sudominio.com` y confirmar que carga el login de n8n.

### Paso 0.5 — Configurar OmniRoute (histórico — ver "Niveles de importancia y BYOK" arriba para el diseño vigente)

> **Superado por la actualización del 15 de agosto, noche (arriba).** Este
> paso describía cargar las llaves de Mateo/su amigo a mano y definir un
> orden de fallback fijo. El diseño vigente es: OmniRoute llega preconfigurado
> con un modelo gratis por nivel de importancia (`bajo`/`medio`/`alto`/`crítico`)
> desde el arranque; añadir llaves propias por nivel es un paso posterior y
> opcional del usuario, no un requisito de instalación. Se deja el contenido
> original por trazabilidad de qué se intentó primero.

1. Entrar al panel de OmniRoute (`https://router.sudominio.com` o el puerto que exponga).
2. Cargar las API keys: Gemini (amigo), la nueva que compre Mateo, Groq, y cualquier otra gratuita que ya tengan.
3. Definir el orden de fallback: gratis primero (Gemini, Groq), pagado al final (para los bots que sí lo necesiten según el roster).
4. Probar con una llamada de prueba (`curl` a `https://router.sudominio.com/v1/chat/completions`) para confirmar que responde y que hace fallback si un proveedor falla.

### Paso 0.6 — Repositorio de GitHub

Estructura sugerida:

```
infinite-power/
├── docker-compose.yml
├── Caddyfile
├── prompts/
│   ├── _core/            (Efadam, Jarvis — cross-cluster)
│   ├── dev-tech/
│   ├── operacion-proyectos/
│   ├── estrategia-crecimiento/
│   ├── investigacion-skills/
│   ├── legal/
│   └── negocios-propios/
├── schema/
│   └── init.sql
├── n8n-workflows/        (exports .json de cada workflow, como respaldo versionado)
└── docs/
    └── roster_agentes.xlsx
```

Mateo con acceso de escritura. Cada bot tendrá su propio `.md` dentro de `prompts/<cluster>/<bot>.md`.

### Paso 0.7 — Bot de Telegram para aprobaciones

1. Hablarle a `@BotFather` en Telegram, `/newbot`, ponerle nombre (ej. `InfinitePowerBot`).
2. Guardar el token que da BotFather.
3. Crear un grupo de Telegram con Mateo, agregar el bot al grupo.
4. Obtener el `chat_id` del grupo (se puede con `https://api.telegram.org/bot<token>/getUpdates` después de mandar un mensaje al grupo).
5. Guardar token y chat_id como credencial en n8n (Settings → Credentials → nueva credencial tipo HTTP/Telegram).

**Nota 15 de agosto:** este bot de Telegram sigue siendo el canal de prueba
provisional mientras Jarvis no existe (ver actualización del 15 de agosto,
noche, arriba). No se espera uso funcional/diario de este canal antes de que
Jarvis esté construido.

### Paso 0.8 — Backups mínimos

Cron simple en el VPS para respaldar la base de datos diario:

```bash
crontab -e
# agregar:
0 4 * * * docker exec $(docker ps -qf "name=postgres") pg_dump -U infpower infinite_power > /opt/infinite-power/backups/$(date +\%F).sql
```

**✅ Fin de Fase 0 cuando:**
- n8n carga en su dominio con HTTPS
- Postgres responde y n8n guarda sus datos ahí
- OmniRoute responde a una llamada de prueba con al menos 2 proveedores
- El bot de Telegram manda un mensaje de prueba al grupo
- El repo de GitHub existe con la estructura de carpetas

---

## FASE 1 (histórica) — Definir instrucciones de cada bot, en bloque por cluster

> **Superada por el orden vertical de la actualización del 15 de agosto,
> noche (arriba).** Ya no se escriben los 40 prompts por adelantado ni por
> cluster completo antes de construir — cada prompt se escribe cuando toca
> activar el componente al que pertenece. Se deja este contenido como
> referencia de la plantilla de prompt (Paso 1.2 sigue siendo la plantilla
> vigente para cualquier bot nuevo) y del trabajo ya hecho en Dev/Tech.

**Objetivo original de la fase:** que cada una de las ~40 cajas del diagrama tenga un prompt de sistema real, probado, y guardado en el repo.

### Paso 1.1 — Repartir el roster

Abrir `roster_agentes.xlsx`, llenar la columna "Dueño" con quién de los dos se encarga de cada bot, siguiendo el reparto por cluster sugerido arriba (o el que decidan). Aclarar primero las filas marcadas "Pendiente - aclarar" (Efadam, TalentIA, Bintix) antes de repartir el resto.

### Paso 1.2 — Plantilla de prompt (**vigente** — usar para cualquier bot nuevo)

Cada archivo `prompts/<cluster>/<bot>.md` debe tener esta estructura:

```markdown
# [Nombre del bot]

## Rol
(una frase: qué es este bot dentro del sistema)

## Objetivo
(qué tiene que lograr cada vez que corre)

## Input que recibe
(de qué bot o de qué tabla en Postgres saca su información)

## Output que entrega
(a qué bot o tabla en Postgres escribe su resultado, y en qué formato — texto, JSON, etc.)

## Herramientas que puede usar
(qué nodos/APIs tiene disponibles: ClickUp, web search, GitHub, etc.)

## Reglas y límites
(qué NO debe hacer nunca sin aprobación humana, tono, restricciones de presupuesto/tiempo)

## Cuándo debe pedir aprobación humana
(criterio claro: "si la acción implica gastar dinero", "si es contenido público", etc.)

## Prompt de sistema (versión final para pegar en n8n)
"""
(aquí va el texto literal que se pega en el nodo AI Agent de n8n)
"""

## Casos de prueba
1. Caso de entrada de ejemplo → salida esperada
2. Caso límite/borde → salida esperada
3. Caso que debería fallar/escalar → salida esperada
```

### Paso 1.3 — Escribir los prompts, cluster por cluster (histórico)

Orden original (ya no vigente — ver actualización del 15 de agosto arriba
para el orden real: Efadam → Tech center → Upgrade & review center → Proyect
center → Jarvis):

1. Cluster **Legal** (3 bots)
2. Cluster **Investigación/Skills** (4 bots)
3. Cluster **Dev/Tech** (11 bots)
4. Cluster **Operación/Proyectos** (10 bots)
5. Cluster **Estrategia/Crecimiento** (9 bots)
6. Cluster **Negocios propios** (5 bots)

### Paso 1.4 — Revisión cruzada (sigue siendo buena práctica al cerrar cada componente vertical)

Antes de dar por cerrado cada componente (Efadam, cada center): cada quien revisa lo que escribió el otro (no lo propio) y valida que el input/output realmente conecte con el bot de al lado — este es el paso donde se detectan huecos de lógica antes de programarlo.

---

## FASE 2 (histórica) — Rebanada vertical (cluster Legal)

> **Superada.** El concepto de "probar el patrón de punta a punta antes de
> escalar" sigue siendo válido y ya se cumplió — pero con Dev/Tech
> (Técnico jefe → Coder), no con Legal, y el ejecutor genérico resultante es
> justo lo que ahora se reutiliza para construir Efadam y cada center. Se deja
> este contenido porque el schema de Postgres y el patrón de nodos siguen
> siendo la base técnica vigente.

### Paso 2.1 — Schema de Postgres (vigente)

`schema/init.sql`:

```sql
create table tasks (
    id serial primary key,
    cluster text not null,
    bot text not null,
    status text not null default 'pending', -- pending, running, done, failed, needs_approval
    input jsonb,
    output text, -- text, NO jsonb: la salida de casi todos los bots es texto libre (código, explicaciones).
                 -- El único que devuelve JSON es Técnico jefe, y sus asignaciones se parsean directo
                 -- desde la respuesta HTTP, no desde esta columna.
                 -- Si ya la creaste como jsonb: ALTER TABLE tasks ALTER COLUMN output TYPE text USING output::text;
    created_at timestamptz default now(),
    updated_at timestamptz default now()
);

create table approvals (
    id serial primary key,
    task_id int references tasks(id),
    requested_at timestamptz default now(),
    resolved_at timestamptz,
    approved boolean,
    approver text
);

create table agent_runs (
    id serial primary key,
    task_id int references tasks(id),
    bot text not null,
    model_used text,
    tokens_input int,
    tokens_output int,
    cost_estimate numeric,
    duration_ms int,
    created_at timestamptz default now()
);
```

Correrlo dentro del contenedor de Postgres:

```bash
docker exec -i $(docker ps -qf "name=postgres") psql -U infpower -d infinite_power < schema/init.sql
```

### Nota — cómo se construyó realmente el patrón (vigente)

En vez de un workflow separado por cluster, se construyó **un solo "ejecutor
genérico"** que lee la configuración de cada bot (prompt, modelo, si requiere
aprobación, si despacha tareas) de una tabla `bots` en Postgres. Un bot nuevo
se agrega con un `INSERT` a esa tabla, no con un workflow nuevo. Ver
`ejecutor_generico.md` para el diseño completo.

Piloto probado de punta a punta: **Técnico jefe → Coder**, incluyendo manejo
de errores (nodo "Marcar como fallida": cualquier fallo en un nodo marca la
tarea como `failed` con el error guardado en `output`, en vez de dejarla
colgada).

**Limitación conocida:** si detienes una ejecución manualmente desde n8n
(botón de cancelar) mientras está corriendo, la tarea que estaba reclamando se
queda en `running` para siempre. Hay que resetearla a mano
(`UPDATE tasks SET status = 'pending' WHERE id = <id>;`).

### Piezas de arquitectura del ejecutor genérico (vigente, aplican a Efadam y a cada center)

1. **Inyección de contexto/memoria:** un nodo Postgres antes de "Llamar a OmniRoute" que jale contexto relevante y lo agregue al prompt. Los bots no tienen acceso directo a la base de datos — el workflow les da el contexto ya curado.
2. **Sistema de aclaración:** columna `parent_task_id` en `tasks`, status `blocked`, regla en los prompts (responder `{"necesita_aclaracion": true, "pregunta": "..."}` cuando falte info esencial), y un nodo que cree la tarea de aclaración de vuelta al bot/humano correspondiente.

---

## FASE 3 (histórica) — Orquestación multi-cluster

> **Superada como "fase separada".** La idea de conectar clusters vía la
> tabla `tasks` sigue siendo el mecanismo vigente — pero ya no es un paso que
> viene "después de escribir todos los prompts", es parte natural de
> construir cada center en el orden vertical (arriba). Se deja el mecanismo
> técnico por referencia.

### Conectar los clusters entre sí (mecanismo vigente)

En vez de que un workflow llame directamente a otro, se usa la tabla `tasks`
como bandeja de entrada compartida: un cluster termina su trabajo → inserta
una fila nueva en `tasks` con `cluster` = el cluster destino; ese cluster, en
su propio schedule, hace `SELECT` de sus tareas pendientes y las procesa. Para
conexiones que sí necesitan ser inmediatas, usar el nodo **Execute Workflow**
de n8n en vez de pasar por la cola.

---

## FASE 4 — Monitoreo y control de costos

**Objetivo de la fase:** saber en todo momento qué está corriendo, cuánto cuesta, y que nada se salga de control. Viene después del recorrido vertical completo (Efadam → Tech center → Upgrade & review center → Proyect center → Jarvis), no entrelazada con él.

**Tiempo estimado:** 3–4 días.

### Paso 4.1 — Workflow de resumen diario

Nuevo workflow `Monitoreo - Resumen diario`:

1. Schedule Trigger (todas las mañanas)
2. Postgres: `SELECT` de `agent_runs` del día anterior — total de corridas, costo estimado, bots que fallaron
3. Telegram (o Jarvis, si ya existe): manda el resumen

### Paso 4.2 — Alertas de límite

Workflow separado que corre cada hora:

1. Postgres: suma el `cost_estimate` acumulado del día
2. IF: si supera un límite que definan (ej. equivalente a $50 MXN/día)
3. Telegram/Jarvis: alerta inmediata + opción de pausar el cluster que más gastó

### Paso 4.3 — (Opcional) Dashboard

Si quieren algo visual, un workflow que expone los datos de `agent_runs` a una hoja de Google Sheets o a un dashboard simple en n8n (o Grafana). No es indispensable para arrancar.

**✅ Fin de Fase 4 cuando:**
- Reciben el resumen diario
- Las alertas de gasto se disparan de verdad al superar el límite de prueba

---

## FASE 5 — Autonomía progresiva

**Objetivo de la fase:** ir quitando los checkpoints de aprobación humana solo donde ya se ganó la confianza.

**Cadencia:** continua, sin plazo fijo — se revisa cuando haya evidencia real que evaluar, no por calendario (corregido el 17 de agosto: la versión original de esta sección usaba "revisar cada 2 semanas" como cadencia y "2 semanas corriendo sin error" como umbral de graduación; Mateo lo descartó — el tiempo transcurrido no es la unidad correcta para validar un cluster).

### Criterio de "graduación" por cluster

Checklist completo en [[autonomia_progresiva]] (extraído de aquí, se mantiene ahí para no duplicarlo). Resumen: volumen suficiente de tareas reales sin error no manejado (no tiempo transcurrido), costo dentro de rango, ningún caso no aprobado, y acuerdo explícito de los dos — cluster por cluster, nunca todos a la vez.

**✅ Fin de Fase 5:** es continua, no tiene un final fijo — es el estado de mantenimiento del sistema.

---

## FASE 6 — Auto-expansión ("Nuevos departamentos")

**Objetivo de la fase:** que el Council pueda proponer y crear un nuevo agente/cluster automáticamente.

**Tiempo estimado:** dejar para cuando todo lo anterior lleve al menos un mes estable.

### Paso 6.1 — Generar la API key de n8n

Settings → API → crear una API key. Guardarla como credencial.

**Nota 15 de agosto de 2026:** esta API key ya existe y está en uso (es la
misma que permite conectarse a n8n local desde una terminal con acceso directo
a la máquina — ver `memoria_del_sistema.md` y el patrón de conexión guardado
en memoria de Claude). El usuario decidió mantenerla activa de forma indefinida
en vez de rotarla — vive fuera de sistemas digitales cuando no está en uso.

### Paso 6.2 — Workflow "Nuevos departamentos"

1. Recibe la propuesta del Council (vía la tabla `tasks`)
2. AI Agent **Agent builder**: genera el prompt del nuevo bot siguiendo la plantilla del Paso 1.2
3. **Siempre** pasa por aprobación humana — este paso nunca se automatiza del todo
4. Si se aprueba: llamada HTTP a la API de n8n (`POST /workflows`) para crear el workflow nuevo en modo desactivado
5. Ustedes lo revisan manualmente y lo activan a mano la primera vez

**✅ Fin de Fase 6 cuando:**
- El sistema puede proponer un departamento nuevo con su prompt ya escrito
- Nunca se activa solo sin que alguno de los dos lo revise primero

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

1. **Construir Efadam** — es el paso inmediato. Prompt ya escrito en `efadam.md`; falta activarlo en la tabla `bots` y probar su enrutamiento con las 3 ramas todavía vacías/parciales.
2. Activar **Tech center** end-to-end contra el Efadam real (hoy el piloto Técnico jefe → Coder corre sin un Efadam que lo reciba).
3. Escribir los prompts completos de **Upgrade & review center** y **Proyect center** (se escriben en su turno, no antes).
4. Escribir el prompt de **Jarvis** — al final, cuando el resto ya produzca contenido real que valga la pena exponer por voz/texto.
5. Construir en n8n la lógica concreta de "Efadam solicita a U&R center, U&R center redacta, Efadam inserta" — hoy solo existe el diseño en prosa (`efadam.md`, `upgrade-review-center.md`).
6. El upsert de seed inicial a `system_knowledge` **se pospone** hasta que haya un producto final que probar — no es un pendiente inmediato.
7. Definir si `knowledge_log`/`system_knowledge` necesitan columna de versión/historial (mejora futura, no implementado).
8. ~~Agregar al amigo/cofundador como colaborador del repo de GitHub~~ — **ya no aplica (17 de agosto, noche):** Mateo confirmó que el proyecto es individual, no hay cofundador que agregar.
9. Activar más bots en la tabla `bots` conforme cada componente vertical lo requiera — hoy `tecnico_jefe`, `coder` y `trouble_shooter` están activos (confirmado el 18 de agosto — ver actualización de esa fecha, arriba, que corrige un error de diagnóstico del 17 de agosto sobre este mismo punto); Consultor de arquitectura y Trouble scouter siguen pospuestos con criterio explícito (ver actualización del 14 de agosto, tarde).
10. Corregir `consultor-de-arquitectura.md` y `trouble-scouter.md`, que aún referencian `project_knowledge`/`trouble_shooter_knowledge` (nombres ya descartados) — corregir antes de activarlos.
11. **Implementar el empaquetado de OmniRoute + n8n para distribución** (diseño ya definido, ver actualización del 15 de agosto, noche, arriba y `stack_y_convenciones.md`): agregar la columna `bots.nivel_importancia` al schema, definir los defaults gratis por nivel dentro de la config de OmniRoute, y diseñar la pantalla/paso de setup donde el usuario ve los 4 niveles y puede añadir sus llaves. No es bloqueante para construir Efadam — se puede implementar en paralelo o después, cuando el paquete se piense para distribuirse a un tercero.
12. ~~Eliminar o resolver la duplicación de la nota `docs/vision/Efadam/Efadam.md` en Obsidian~~ — **hecho (15 de agosto, noche):** su contenido ya estaba fusionado en `memoria_del_sistema.md` y `efadam.md`; el archivo original se eliminó del repo (revisado y aprobado por Mateo).
13. ~~Localizar y leer "Infinite power.md > Método > Multiproyecto"~~ — **hecho (15 de agosto, noche, cuarta ronda):** localizada en `docs/vision/Infinite power.md`, fusionada a este documento (ver actualización correspondiente arriba) y la nota original eliminada.
14. ~~Decidir qué hacer con dos archivos sueltos sin commitear~~ — **hecho (15 de agosto, noche):** `schema/_tmp_diag_github.ps1` (apuntaba al workflow "Sync conocimiento del sistema" ya borrado) y `schema/_tmp_inspect_schedule.js` (exploración puntual de internals de `ScheduleTrigger`, ya resuelta) se revisaron — sin secretos en texto plano — y se borraron del disco. Nunca estuvieron trackeados en git, así que no generaron commit.
15. ~~Decidir cómo Efadam clasifica el nivel de importancia con confiabilidad~~ — **hecho (15 de agosto, noche, tercera ronda):** reglas explícitas por dominio/tema, no criterio libre — ver `stack_y_convenciones.md`, "Reglas de asignación", y actualización correspondiente arriba.
16. ~~Implementar en n8n la lógica real de aplicar la tabla de reglas de nivel~~ — **hecho (16 de agosto):** migración `schema/005_nivel_importancia.sql` corrida contra Postgres; nodo "Llamar a omniroute" del Ejecutor genérico editado vía API de n8n para leer `tasks.nivel_importancia` en vez de `bots.default_model`. Lo que queda (no cubierto por este punto): configurar los 4 combos de OmniRoute (uno por nivel) y activar Efadam para que empiece a poblar `nivel_importancia` de verdad — ver punto 1.
20. ~~Completar Bloque 0 de la auditoría externa~~ — **hecho (16 de agosto, noche):** workflows de n8n exportados, script de backup probado, `.gitattributes`, password de Postgres y `N8N_ENCRYPTION_KEY` fuera de `docker-compose.yml` en texto plano (movidos a `.env`, misma key que ya existía — no se rotó), `GENERIC_TIMEZONE`. Todo en la rama `correcciones`, verificado (docker compose up -d recreó n8n sin perder workflows). Ver detalle en la actualización del 16 de agosto, tarde/noche, arriba.
21. ~~Bloque 1 de la auditoría externa~~ — **hecho (16-17 de agosto):** 5 contradicciones de "fuente de verdad" corregidas, wikilinks rotos de `INICIO.md` desligados, `estado_del_proyecto.md` reescrito de cero — todo committeado y pusheado a `correcciones` (commits `e97b5fc`, `220d04b`, `b94af50`). **Sigue pendiente, no cubierto por este punto:** limpiar duplicados en el Claude Project.
22. ~~Desktop_Commander desconectado~~ — **resuelto (17 de agosto):** volvió a conectar. Se usó para limpiar los `.lock`/`tmp_obj` que la VM aislada del bridge estándar había dejado sueltos en `.git/` y para pushear el commit de Bloque 1 que había quedado local. Bloque 2 (Postgres/n8n/OmniRoute) ya es viable con esta herramienta disponible.
17. **Nuevo (post Fase 2, no ahora):** construir Multiproyecto — schema por proyecto en Postgres, tabla `proyectos`, nodos Postgres con schema dinámico. Antes: confirmar que los workflows actuales de n8n no tienen el schema hardcodeado.
18. **Nuevo:** construir el mecanismo de Revert (tabla `reverts`, `archived_at`/`archived_reason` en `knowledge_log` y demás tablas relevantes) — sin fecha fija, pero vale la pena tenerlo antes de que el sistema empiece a tomar decisiones con consecuencia real que alguien quiera poder revisar/archivar.
19. **Nuevo:** escribir el prompt de Setup en Proyect center (entrevista de objetivo → meta + pasos + criterio de "listo") — se escribe en su turno, cuando toque construir Proyect center (paso 4 del orden vertical).
23. ~~Insertar `trouble_shooter` en `bots`~~ — **ya no aplica (18 de agosto):** al intentar correr el `INSERT`, Postgres devolvió `duplicate key` — la fila ya existía. El diagnóstico del 17 de agosto que daba esto como pendiente estaba mal (ver actualización del 18 de agosto, arriba, sección 1, para la corrección completa). ~~Agregar el nodo Postgres de disparo automático en el Ejecutor genérico después de "Marcar como fallida"~~ — **hecho (18/ago, tarde-noche):** construido y probado en vivo, ver actualización del 18 de agosto, tarde-noche, arriba (sección 2).
24. ~~Decidir si vale la pena seguir con Pollinations/Cloudflare/Qwen~~ — **cerrado por ahora (18/ago, noche, tercera ronda):** Mateo decidió no seguir con eso mientras dure la construcción — se retoma cuando el sistema ya esté operando.
30. ~~Construir el concepto de "operación"~~ — **hecho (18/ago, noche, cuarta ronda):** Mateo confirmó las dos preguntas abiertas (mezclar `nivel_importancia` sin reconstruir; operaciones centralizadas en Efadam). Construido de verdad: `schema/007_operaciones.sql` corrido contra Postgres real, `operation_id` propagado en "Crear tarea de aclaración", "Crear tareas hijas" y "Despachar a trouble_shooter" (por subquery SQL, no referencia cruzada de n8n), probado en vivo dos veces. De paso se encontraron y corrigieron 2 bugs reales de `nivel_importancia` (aclaración y trouble_shooter nacían sin nivel, condenadas a fallar). Ver actualización del 18 de agosto, noche, cuarta ronda, arriba, y `ejecutor_generico.md` para el detalle completo. **Sigue pendiente, no cubierto por este punto:** nada abre una operación de verdad todavía — depende de que Efadam exista como bot activo (Bloque 3).
25. ~~Corregir el manejo de errores en los nodos del Ejecutor genérico~~ — **hecho (18/ago, noche, segunda ronda), con corrección importante:** este punto se venía llamando "hallazgo C5", pero la auditoría del 17/ago solo enumera C1-C4 (confirmado 19/ago) — nunca fue parte de ella, es un bug encontrado y nombrado después; se deja de usar el prefijo "C" para este punto de aquí en adelante. El diagnóstico original (13 nodos rotos por el mismo bug que `"Llamar a omniroute"`) **era incorrecto** — probado en vivo, nodo por nodo: Postgres, Code y Telegram enrutan sus errores correctamente sin ningún arreglo. El bug real era otro: (a) cada tipo de nodo entrega el error con una forma de JSON distinta y "Marcar como fallida" necesitaba una normalización que no existía, y (b) un bug de n8n nunca documentado antes — `$('Reclamar tarea pendiente').first()` truena con `TypeError` cuando el nodo que lo llama se alcanza por una ruta de error rescatada, mientras que `.item` sí funciona. Arreglo aplicado: se generalizó el Code node "Preparar fallo" (normaliza las 4 formas de error observadas, usa `.item` en vez de `.first()`) y se re-cablearon 17 conexiones para pasar por él — cero nodos nuevos. Probado en vivo de punta a punta dos veces (una vía Postgres, la original vía omniroute) más una confirmación extra del guard anti-loop de Trouble shooter. Ver actualización del 18 de agosto, noche, segunda ronda, arriba, y `ejecutor_generico.md` para el detalle completo y el código final.
26. ~~Rotar la contraseña de Postgres (hallazgo C1)~~ — **hecho, pero corrige alcance (19/ago): esto es "mitigado", no "cerrado".** Los 4 pasos de rotación (`ALTER USER`, `.env`, credencial de n8n vía API, reinicio) sí se ejecutaron y probaron en vivo de punta a punta el 18/ago — pero el paso 4 original de C1 ("reescribir/limpiar el historial remoto") nunca se hizo, y la contraseña vieja sigue siendo alcanzable desde las 5 ramas remotas vía `git log -p`. Ver punto 33 de este mismo checklist y la actualización del 19 de agosto, arriba.
27. **Nuevo (18/ago, tarde-noche):** eliminar la API key temporal de n8n (`N8N_API_KEY_TEMP` en `.env`) — revocarla en n8n y borrar la línea — una vez que el pendiente 25, la ingesta Telegram → `tasks` y la aprobación humana bidireccional estén resueltos. Instrucción explícita de Mateo, no automática.
28. ~~Si "Reclamar tarea pendiente" falla en sí mismo (ej. Postgres caído), no hay canal de alerta~~ — **hecho (19/ago), construido y probado en vivo.** Nodo Telegram nuevo "Alerta critica Postgres", cableado en paralelo a la salida de error de "Reclamar tarea pendiente" (no reemplaza la ruta existente a "Preparar fallo", la complementa) — no depende de Postgres para nada, así que sale aunque Postgres esté totalmente inalcanzable. Probado en vivo rompiendo la query contra una tabla inexistente: la alerta llegó a Telegram con el error real de Postgres embebido, confirmado `ok: true`. 29 nodos ahora. Ver `ejecutor_generico.md`, "Lo que falta", punto 1, para el detalle técnico completo.
29. **Nuevo (18/ago, noche, segunda ronda):** los 4 nodos IF del Ejecutor genérico quedaron cableados hacia "Preparar fallo" por consistencia, pero su comportamiento real de enrutamiento de errores nunca se confirmó en vivo — dos intentos de forzar un error genuino en un nodo IF fallaron (el nodo simplemente evaluó la condición como falsa en vez de tronar). Queda como no confirmado, no como arreglado. Ver `ejecutor_generico.md`, sección "Lo que falta".
31. ~~Hacer una pasada de verificación en vivo sobre los 5 hallazgos C~~ — **hecho (19/ago):** verificado contra evidencia primaria (git log, contenido real de archivos, texto original de la auditoría). Resultado, con corrección de 2 errores propios (C4 sí tiene tabla `approvals`; C5 nunca fue parte de la auditoría original) — ver actualización del 19 de agosto, arriba, para el detalle completo con evidencia de cada punto. Esto generó los puntos 32-38 de abajo, que sí quedan pendientes de resolver.
32. ~~Reexportar el n8n vivo actual a `n8n-workflows/*.json`~~ — **hecho (19/ago).** Reexportado vía API (mismo mecanismo que las ediciones — GET, `ConvertTo-Json -Depth 100`, `Out-File`) para Ejecutor genérico y Reanudador de bloqueados. Confirmado con `grep`: la SQL de "Obtener config del bot" ya sale parametrizada (`slug = $1`) y `operation_id` aparece en el archivo. Commits `cb31874` y el de más abajo tras el fix del punto 8 (ver siguiente actualización). El Reanudador no tuvo cambios reales (el export ya estaba al día, confirmado el mismo día).
33. ~~Decidir qué hacer con la exposición histórica de la contraseña vieja de Postgres (`infpower154`) en el historial de Git~~ — **decidido (19/ago): se acepta el riesgo residual, no se reescribe el historial.** Mateo confirmó que la contraseña nueva es distinta (no reutilizada) — con eso, el beneficio marginal de `git filter-repo` + force-push a 5 ramas es bajo (el repo es público, cualquier cosecha automática ya ocurrió y es irreversible de todos modos) frente al costo/riesgo de reescribir historial en 5 ramas de un repo activo. C1 queda formalmente como **mitigado, riesgo residual aceptado** — no como "cerrado" en el sentido de que el string ya no está en el historial (sigue estando), sino en el sentido de que ya no es un pendiente abierto de decisión.
34. **Nuevo (19/ago):** construir el workflow de aprobación humana bidireccional (C4) usando la tabla `approvals` que ya existe en `schema/001_init.sql` (no hace falta crearla) — falta la lógica: registrar la decisión, validar quién responde, y disparar la transición de estado atómica (continuar/cancelar la tarea) para que `needs_approval` deje de ser solo una notificación saliente sin ruta de vuelta.
35. **Nuevo (19/ago):** decidir cómo conviven `operations.nivel_importancia` (fijo una sola vez al abrir la operación, según el diseño del 18/ago) con las "Reglas de asignación" por tarea de `stack_y_convenciones.md` (que dicen que el nivel puede/debe subir según el dominio de cada tarea específica, nunca redondear hacia abajo). Tal como quedó el diseño de operaciones, una tarea hija que caiga en un dominio más sensible que el nivel fijo de su operación no puede subir de nivel — reintroduce el modo de falla que describía el C3 original. Recomendación a confirmar: nivel efectivo de la tarea = `max(nivel de la operación, nivel por reglas de asignación)`. Decisión de arquitectura de Mateo, ver actualización del 19 de agosto, arriba.
36. **Nuevo (19/ago):** revisar prompt injection entre agentes — contenido de una tarea hija (generado por un modelo) que termina interpretado como instrucción de sistema en la siguiente tarea (ej. `parent_input` sin sanitizar en el prompt de "Llamar a omniroute").
37. **Nuevo (19/ago):** definir límites de fan-out/costo — hoy nada impide que una operación genere una cadena de tareas hijas sin tope, ni existe un tope de gasto por operación o por ventana de tiempo.
38. **Nuevo (19/ago):** revisar puertos Docker expuestos en `docker-compose.yml` (cuáles están publicados al host/red y si deberían estarlo) e imágenes `latest` sin pin de versión (un `docker compose pull` puede romper todo sin aviso ni forma de volver a una versión conocida); y evaluar pruebas automatizadas/CI — hoy no existe ninguna.
39. ~~`Obtener config del bot` no distingue "bot no existe" de "bot existe"~~ — **hecho (19/ago).** No bastaba con un IF: confirmado en vivo que el Postgres node con 0 filas emite 0 items en ambas salidas (ni siquiera pasa por la rama de error) — cualquier IF después nunca se evalúa. Fix real: `alwaysOutputData: true` en el nodo + un IF nuevo ("Bot encontrado") + un Code node nuevo que arma el mensaje de error, todo enrutado a "Preparar fallo" igual que cualquier otro fallo. Probado en vivo dos veces (bot inexistente → `failed` + trouble_shooter correcto; bot válido → sin regresión). 28 nodos ahora. Reexportado a `n8n-workflows/ejecutor_generico.json`. Ver `ejecutor_generico.md`, "Lo que falta", punto 3, para el detalle técnico completo.
