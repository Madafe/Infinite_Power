# Auditoría spec-driven — 22 de agosto de 2026

> Documento de auditoría, para humanos. **No se inyecta a ningún bot.**
> Escrito contra el estado REAL medido el 22/ago/2026: Postgres en vivo, la API
> de n8n en vivo, `git log`, y las 47 tareas reales de ClickUp — no contra los
> documentos del repo. Eso es deliberado: tres de los errores de diagnóstico más
> caros de este proyecto (los "13 nodos rotos", "trouble_shooter no insertado",
> y la auditoría externa del 21/ago) vinieron de leer un documento en vez de la
> fuente real.

## 0. El diagnóstico en una frase

El proyecto no se te fue de las manos por falta de documentación — tienes más
documentación que sistema. Se te fue porque **no existe ni un solo artefacto que
diga "esto es lo que el sistema debe hacer, y así se comprueba"**. Todo lo que
tienes es crónica (qué pasó en cada ronda), estado (qué existe hoy) y pendientes
(qué falta). Nada de eso es un contrato verificable, así que nada de eso puede
fallar. Y lo que no puede fallar, no te avisa cuando la dirección se torció.

## 1. Evidencia dura (medida el 22/ago/2026, no citada de un doc)

| Qué | Medición real | Cómo se midió |
|---|---|---|
| `Ejecutor genérico` en n8n | **`active = false`**, único trigger `manualTrigger` | `GET /api/v1/workflows` en vivo |
| Workflows activos en n8n | **1 de 3**: solo `Reanudador de bloqueados` (`scheduleTrigger`) | idem |
| `tasks` | 21 filas en 9 días (17 done, 3 failed, **1 pending desde el 22/ago 02:47**) | `psql` |
| `operations` | **0 filas. Nunca se creó ninguna.** | `psql` |
| `agent_runs` | **0 filas** | `psql` |
| `approvals` | **0 filas** | `psql` |
| `knowledge_log` | **0 filas** | `psql` |
| `system_knowledge` | 3 slugs, sembrados el 14–15/ago, **sin un solo `UPDATE` desde entonces** | `psql` |
| `arquitectura` / `stack_y_convenciones` sembrados | **no contienen la palabra `esfuerzo` ni `operations`** | `psql` |
| Regla 6 (`autoexpansión`) | **ausente de los 5 `bots.system_prompt`** | `psql` |
| Prompts escritos | 31 archivos `.md` | repo |
| Bots activos | 5 | `psql` |
| Capacidades que corren solas | **0** | consecuencia de la fila 1 |

## 2. Los 4 hallazgos estructurales

### E1 — El motor está apagado y nunca tuvo forma de encenderse solo

`Ejecutor genérico` está en `active = false` con un `manualTrigger` como única
entrada. Además: `Reclamar tarea pendiente` toma **una** tarea (`LIMIT 1`) y
`Crear tareas hijas` **no está conectado a nada** — no hay vuelta al inicio. Es
decir: cada tarea del sistema cuesta un clic humano, y un despacho que genera 5
hijas cuesta 5 clics más.

Consecuencia sobre todo lo que se dio por probado: **ninguna de las pruebas
"end-to-end" de las rondas 12–18 probó el sistema.** Probaron una secuencia de
clics. La prueba de la ronda 17 (tarea 40 → 41, declarada "OK end-to-end") dejó
la tarea 41 en `pending` desde el 22/ago a las 02:47 — sigue ahí hoy. Eso *es*
el resultado real de esa prueba, y nadie lo vio porque nadie lo mide.

La tarea que arregla esto ya existe en ClickUp: `86bbhazua` ("pasar de Manual a
Schedule Trigger"), en estado `to do`. Mientras tanto se escribieron 31 prompts.

### E2 — Lo único que corre 24/7 alimenta una cola que nadie consume

`Reanudador de bloqueados` está activo con `scheduleTrigger` y su trabajo es
devolver tareas padre a `pending`. Con el ejecutor apagado, es un productor sin
consumidor. Hoy es inofensivo porque hay poco volumen; el día que se encienda el
ejecutor va a entrar trabajo viejo de golpe sin que nadie lo haya decidido.

### E3 — `operations` es una tabla fantasma, y arrastra 4 mecanismos con ella

Ningún nodo de n8n hace `INSERT INTO operations`, y el contrato JSON de Efadam
(`prompts/_core/efadam.md`) no tiene ningún campo para abrir una. O sea: **no
existe forma física de crear una operación.** Efectos en cascada, todos activos
hoy:

1. El tope global de fan-out está escrito como `if (operationId && totalOperacion >= cap.porOperacion)` — con `operation_id` siempre nulo, **hoy no existe ningún límite global de explosión de tareas.** El tope por despacho (5/10/15/20) sí funciona; el global nunca se evalúa.
2. `Marcar operacion bloqueada` nunca acierta una fila.
3. `Contar tareas de operacion` siempre devuelve 0.
4. La síntesis de aprendizaje asíncrona por operación no se puede disparar nunca.

Esto es el caso de manual de "se diseñó un mecanismo completo, se cableó en 4
nodos, y nunca se construyó su punto de entrada" — y nadie lo notó porque no hay
nada que verifique el contrato.

### E4 — Efadam tiene 2 de sus 3 capacidades declaradas sin implementar

`prompts/_core/efadam.md` declara como herramientas:

- *"Lectura de las tablas `tasks` y `agent_runs`"* → **no existe.** `Cargar
  contexto` solo trae `system_knowledge` + `knowledge_log`. Efadam recibe cero
  estado en vivo del sistema. Y su propia regla dice *"no inventa estado: si no
  tiene información reciente de un cluster, lo dice"* — se le pide no suponer y
  no se le da con qué. Aunque se construyera el nodo, `agent_runs` está vacío
  porque **ningún workflow escribe ahí**.
- *"Escritura en `operations` — único bot que puede insertar una fila nueva"* →
  **no existe** (ver E3).
- *"Escritura en `tasks`"* → esta sí existe y funciona.

Corolario que importa para tu pregunta original: **no hay telemetría de ninguna
clase.** Cero registro de modelo usado, tokens, costo o duración por corrida. Es
literalmente imposible "asegurarte de que todo funciona como te gustaría" sin
eso, no porque falte disciplina, sino porque no hay dato que mirar.

## 3. Hallazgos técnicos concretos (verificados nodo por nodo)

- **H1 — La aprobación pierde el trabajo.** Cuando una asignación sale
  `requiere_aprobacion`, el switch la manda a `Marcar operacion bloqueada` y a un
  aviso JSON para Efadam. **La tarea hija nunca se crea.** El contenido sobrevive
  solo como texto dentro del `input` de un aviso. No hay fila en `approvals`, no
  hay `approval_id`, no hay ruta de aprobación ni de rechazo. Aprobar hoy
  significa volver a escribir la tarea a mano. La tabla `approvals` existe desde
  `001_init.sql` y tiene 0 filas — es esquema muerto.
- **H2 — Un despacho que requiere aprobación bloquea la operación entera**, no
  la asignación. Es un martillo demasiado grande para el clavo (hoy inofensivo
  solo porque `operations` está vacía, ver E3).
- **H3 — El endurecimiento del parseo (ronda 14) dejó un quinto consumidor sin
  migrar.** `Extraer patron` sigue haciendo `JSON.parse()` crudo sobre
  `choices[0].message.content` dentro de un `try/catch` que devuelve `[]` en
  silencio, en vez de leer `json_extraido` del nodo `Normalizar salida del
  modelo`. Se migraron 4 consumidores; este quedó. **Nota de precisión:** este
  *no* es el motivo de que `knowledge_log` esté vacío — se verificó la tarea 34 y
  trouble_shooter devolvió `"patron_aprendido": null`, o sea el nodo se comportó
  bien. Pero es la misma lógica frágil que se suponía eliminada, y su modo de
  falla es silencioso.
- **H4 — Fallo silencioso indistinguible.** `Extraer patron` devuelve `[]` sin
  registrar nada tanto si el bot no produjo patrón como si el patrón se perdió.
  Después de 9 días y 3 fallos reales, `knowledge_log` tiene 0 filas y no existe
  ninguna señal que distinga "el sistema no aprendió nada porque no había nada
  que aprender" de "el sistema está tirando lo que aprende".
- **H5 — La lista de modelos está hardcodeada dentro del workflow.** El nodo
  `Detectar degradacion de modelo` mantiene un diccionario literal de los 8
  nombres de modelo de NVIDIA. Esto **contradice directamente** un principio de
  diseño escrito en `stack_y_convenciones.md`: *"cambiar qué modelo resuelve
  `alto` es una configuración de OmniRoute, nunca una edición al prompt del bot
  ni al workflow de n8n"*. Es el ejemplo más limpio de lo que pediste buscar: una
  solución local (detectar degradación) que rompe la foto grande (OmniRoute como
  único traductor esfuerzo→modelo). En un producto distribuible, cada instalación
  con proveedor propio rompe este nodo.
- **H6 — El fallo más grave sigue sin registro.** Si `Reclamar tarea pendiente`
  falla (Postgres caído), no hay `task_id` todavía; `Preparar fallo` construye
  `taskId = undefined` y `Marcar como fallida` corre un `UPDATE ... WHERE id =
  undefined` que no toca nada. Ya está documentado y en ClickUp (`86bbhawtv`) —
  lo repito aquí porque es el único modo de falla que se traga el propio
  mecanismo de registro de fallos.
- **H7 — Sin índice para la consulta más caliente.** `Reclamar tarea pendiente`
  hace `WHERE status='pending' ORDER BY created_at ... FOR UPDATE SKIP LOCKED` y
  no existe índice sobre `(status, created_at)`. Irrelevante con 21 filas;
  importante el día que el ejecutor corra en loop.

## 4. El contexto con el que trabaja la IA — medido

Esta es la parte que más te afecta y la que tiene la evidencia más dura.

**4.1 — Los bots leen una foto congelada del 15 de agosto.** `system_knowledge`
se sembró el 14–15/ago y no se ha actualizado nunca. Desde entonces
`docs/context/arquitectura.md` se corrigió al menos tres veces (19/ago: los
centers leen Postgres de su rama; 21/ago: la lista de bots activos estaba mal
desde el 16/ago; 21/ago: `tech_center` insertado). **Ninguna de esas correcciones
llegó a los bots.** Peor: el texto que hoy se les inyecta **no menciona
`esfuerzo` ni `operations`** — los dos mecanismos centrales del diseño vigente.
Se les pide razonar sobre esfuerzo y `operation_id` con un contexto que no sabe
que existen.

**4.2 — La regla 6 no existe para ningún bot.** `reglas_generales.md` tiene 6
reglas desde el 19/ago. La semilla en la tabla tiene 5, y los 5
`bots.system_prompt` compuestos tienen 5. La respuesta a la tarea `86bbjhdn9`
("¿un cambio en reglas_generales actualiza el system_prompt ya compuesto?") es
**no**, y además la tabla nunca recibió el cambio en primer lugar.

**4.3 — Hay ocho fuentes de verdad y ningún árbitro.** Postgres, n8n en vivo,
`n8n-workflows/*.json`, `docs/context/*.md`, la tabla `system_knowledge`, la
narrativa (`estado_del_proyecto.md` + `decisiones_arquitectura.md` +
`archivo/plan_de_accion_completo.md`), ClickUp, y el Project de Claude. Cada
incidente de drift de tu historial es un par de esta lista desalineado: la
auditoría externa del 21/ago (export vs. n8n vivo), los "13 nodos rotos"
(razonamiento sobre el doc vs. comportamiento real), "trouble_shooter no
insertado" (scripts commiteados vs. base real), la reconciliación del
`reanudador` (ClickUp vs. doc del Project). No es mala suerte, es una propiedad
estructural.

**4.4 — La unidad de trabajo está mal.** Tu historial está organizado en
"rondas" — 18 hasta ahora. Una ronda es una sesión de chat, o sea que **el límite
del trabajo lo define la ventana de contexto de una herramienta, no una capacidad
del sistema.** Por eso cada sesión nueva tiene que leer una crónica de 18 rondas
para saber dónde está parada, y por eso las conclusiones se re-derivan (y a veces
se re-derivan mal).

**4.5 — La advertencia ya estaba escrita y se violó igual.**
`estado_del_proyecto.md` dice, escrito por una sesión anterior: *"el proyecto
lleva días construyendo el sistema que construye el sistema. El criterio de
'suficiente' para la plomería: escribir y activar solo los bots que de verdad se
usarían esta semana, no el roster completo de golpe."* Después de eso se
escribieron 31 prompts y no se activó ninguno. **Esa es la prueba de que
documentar una decisión no la hace cumplir.** Es exactamente el hueco que un
spec-driven development bien hecho tapa — y el motivo por el que la parte
importante de una spec no es el texto, es el criterio de aceptación ejecutable.

## 5. Auditoría de la idea y de la división en pasos

**La idea es sólida y no es lo que está roto.** Un orquestador central con
departamentos, cola en Postgres, un ejecutor genérico parametrizado por fila de
`bots` y un router de modelos por nivel de esfuerzo es una arquitectura correcta
y sorprendentemente barata de mantener. Agregar un bot = un `INSERT` es una
decisión de diseño buena. No la cambies.

**Lo que está roto es el orden y la unidad de avance.** El orden declarado es
vertical ("un componente completo antes del siguiente"), pero lo ejecutado es
horizontal: 31 prompts escritos, 0 capacidades corriendo solas. La razón es que
"componente" se definió como **bot**, y un bot no es una unidad verificable — no
puedes probar que "Coder funciona", solo puedes probar que una capacidad
end-to-end se cumple.

**Riesgo de alcance vigente:** el producto distribuible (multiproyecto,
empaquetado, BYOK, pantalla de setup) ya consumió decisiones de diseño y sigue
generando tareas, mientras el sistema para un solo operador nunca ha completado
una corrida autónoma. Esa tensión ya está documentada dos veces en el repo, y las
dos veces se resolvió a favor de mantenerla viva. Es una decisión legítima — pero
hoy paga interés: `bot_esfuerzos_fijos`, la matriz de esfuerzo y el fallback en
cascada existen en un sistema que todavía se ejecuta a mano.

## 6. Qué es Spec-Driven Development y cómo se aplica aquí

SDD no es "escribir más documentación antes de programar". Es cambiar **qué
documento manda**: en vez de que la fuente de verdad sea el código (y los docs lo
persigan), la fuente de verdad es una spec verificable, y el código existe para
satisfacerla. Lo que lo hace funcionar no es el formato del documento, es que
**cada spec trae un criterio de aceptación que se puede volver a correr mañana.**

Aquí tienes ya la mitad: contratos escritos con muchísimo detalle. Lo que falta
es la otra mitad — que sean comprobables. Sin eso, "probado end-to-end" significa
"un humano vio que funcionó una vez", que es exactamente lo que te tiene sin
poder asegurarte de que las cosas funcionan.

### Los 4 niveles, aterrizados a Infinite Power

**Nivel 0 — Constitución** (`specs/00_constitucion.md`, ~1 página, casi
inmutable). Qué es el sistema, para quién, qué NO es, y 5–8 invariantes que
ninguna ronda puede violar sin una decisión explícita registrada. Candidatos
directos de tu diseño actual: "ningún bot lee Postgres directo salvo excepción
declarada por bot"; "Efadam es el único cuello de botella de conocimiento"; "un
bot que no está en `bots` con `active = true` no existe"; "OmniRoute es el único
traductor esfuerzo→modelo"; "toda corrida deja registro en `agent_runs`". Fíjate
que el invariante 4 lo viola hoy el propio workflow (H5) y el 5 no se cumple
nunca. Eso es precisamente lo que un nivel 0 sirve para hacer visible.

**Nivel 1 — Specs de capacidad** (`specs/CAP-xx-*.md`). **Este es el cambio más
importante: la unidad deja de ser un bot y pasa a ser una capacidad end-to-end
observable.** Cinco secciones fijas y cortas:

1. **Objetivo** — una frase, en comportamiento observable desde afuera.
2. **Contrato** — qué tabla/columna/campo JSON, quién escribe y quién lee.
3. **Criterio de aceptación** — *un comando o consulta que devuelve OK o FALLA.*
4. **Fuera de alcance** — explícito, para que no crezca.
5. **Estado** — `no construido` / `construido` / `verificado <fecha> <evidencia>`.

Las capacidades que tu sistema necesita, en el orden en que se sostienen unas a
otras:

| id | capacidad | criterio de aceptación (ejemplo) |
|---|---|---|
| CAP-01 | La cola se drena sola | Inserto 3 tareas `pending`; sin tocar n8n, en ≤5 min las 3 están `done`/`failed` |
| CAP-02 | Toda corrida es auditable | Después de CAP-01, `select count(*) from agent_runs` = 3, con modelo y duración |
| CAP-03 | Una petición del cliente entra y sale | Mensaje por Telegram → tarea de `efadam` → `respuesta_cliente` de vuelta al mismo chat |
| CAP-04 | Una operación agrupa el trabajo | La petición de CAP-03 crea 1 fila en `operations` y todas sus tareas la referencian |
| CAP-05 | El sistema recuerda | Un fallo diagnosticado deja fila en `knowledge_log` y aparece inyectado en la siguiente corrida del mismo cluster |
| CAP-06 | Aprobación con ida y vuelta | Asignación con `requiere_aprobacion` crea fila en `approvals`; aprobar la convierte en tarea real; rechazar la cierra con motivo |
| CAP-07 | El contexto que leen los bots refleja la arquitectura vigente | `system_knowledge.updated_at` ≥ fecha del último commit que tocó `docs/context/` |

**Nivel 2 — Plan** (los pasos técnicos de cada spec). Caduca rápido: vive en
ClickUp como tarea, no como `.md`.

**Nivel 3 — Implementación.** Workflow, SQL, prompt.

### Las 3 reglas que hacen que esto no se vuelva más papel

1. **Ningún prompt de bot se escribe antes de que exista la spec de la capacidad
   que ese bot sirve.** Escribir un prompt es barato; escribir 31 sin una
   capacidad viva es lo que te trajo aquí.
2. **Ninguna spec se cierra sin correr su criterio de aceptación en verde**, y el
   estado de la spec guarda el comando y la fecha, no una frase.
3. **Cada sesión de trabajo empieza leyendo el nivel 0 + las specs abiertas, y
   termina cambiando el estado de exactamente una spec.** No termina
   "actualizando la narrativa".

### La poda que hace falta para que la spec no compita con 8 fuentes de verdad

- La crónica (`decisiones_arquitectura.md`, `archivo/plan_de_accion_completo.md`)
  se congela en `docs/archivo/` y deja de leerse para saber el estado. Sirve para
  saber *por qué*, nunca *qué*.
- `estado_del_proyecto.md` deja de escribirse a mano: se **genera** con un script
  contra Postgres + la API de n8n. Un estado escrito a mano vuelve a mentir en
  una semana; uno generado no puede.
- `docs/context/*.md` deja de ser "seed que puede quedar viejo" y pasa a tener un
  criterio de aceptación (CAP-07). O se sincroniza, o falla visiblemente.
- El doc del Project de Claude deja de ser un espejo narrativo y pasa a ser un
  índice de las specs.

## 7. Decisiones tomadas (22/ago/2026)

- **Los 31 prompts escritos quedan congelados, sin revisar y sin activar.**
  Decisión de Mateo, 22/ago: *"el proyecto ha cambiado mucho y la mayoría ya no
  se alinean con la visión actual"*. Se revisan más adelante, cuando exista la
  spec de la capacidad a la que cada uno sirve — no antes.

  Esto refuerza el hallazgo de la sección 5: los prompts se escribieron contra
  un blanco móvil. No es un problema de calidad de los prompts, es que se
  escribieron sin un contrato estable al cual conformarse. La consecuencia
  práctica es que la relectura crítica pendiente de los 18 de Upgrade & Review
  Center (`86bbhawuq`) **no debe hacerse todavía**: revisarlos contra una visión
  que sigue moviéndose es trabajo que se vuelve a perder.

- Pendiente de decisión (no cerrado en esta ronda): si se congela la
  construcción de bots nuevos, cuál capacidad se cierra primero, y dónde viven
  las specs.
