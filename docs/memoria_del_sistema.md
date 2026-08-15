# Memoria del sistema — diseño

Fecha: 14 de agosto de 2026. Reemplaza la nota de memoria del
`plan_de_accion_completo.md` del mismo día, que dejaba tres cosas sin resolver
(de dónde sale el contenido, a quién se le inyecta, y quién puede escribir).

**Actualización 15 de agosto de 2026, tarde:** cambia de fondo de dónde sale
el contenido de `system_knowledge` y quién puede escribirlo. Ver sección
"Repo como seed, no como fuente de verdad" más abajo — reemplaza la sección
original "Sincronización repo → tabla", que queda documentada al final como
diseño descartado, para no perder el porqué.

**Actualización 15 de agosto de 2026, noche:** dos correcciones más. (1) Se
corrige el uso de la palabra "estático" en varias secciones — no significa
"inmutable", significa "no cambia dentro de una misma corrida ni mensaje a
mensaje"; `system_knowledge` sí evoluciona con el tiempo, vía Upgrade &
review center. (2) Se incorpora el mecanismo `bots.conocimiento_directo`
(hallado en una nota de visión antigua, desconectada del resto de la
documentación) como la única excepción válida al cuello de botella de
Efadam — ver sección nueva más abajo.

## El problema que resuelve

Un bot que corre en el ejecutor genérico no sabe nada del sistema en el que
vive: no sabe qué tablas hay, qué convenciones aplican, ni qué ya falló antes.
Cada corrida empieza de cero. Sin memoria, Trouble shooter re-diagnostica el
mismo error cada semana y Coder propone soluciones que contradicen decisiones
ya tomadas.

## Dos tablas, porque son dos cosas distintas

### `system_knowledge` — autoconciencia

Qué es el sistema: arquitectura, stack, convenciones, reglas generales. Es
corto a propósito, y **cambia con poca frecuencia** — no en cada mensaje,
como sí cambia el estado de `tasks`/`agent_runs` (ver más abajo), pero eso no
quiere decir que sea fijo: evoluciona con el tiempo conforme el sistema
aprende, mediante el flujo descrito en "Efadam como cuello de botella
intencional" más abajo.

**Fuente de verdad: la tabla misma, no el repo.** Esto es un cambio respecto
al diseño original del 14 de agosto (ver "Diseño descartado" al final). El
repo (`docs/context/*.md`, `reglas_generales.md`) es el **seed inicial** —
el estado día-cero del conocimiento, cargado una sola vez al arrancar el
sistema. Después de ese arranque, la tabla evoluciona sola conforme el
sistema aprende, y el repo puede quedar desactualizado respecto a ella — eso
es esperado, no un bug. El repo documenta de dónde partió el sistema, no
dónde está hoy.

Archivos canónicos del seed inicial:

| slug | archivo | contenido |
|---|---|---|
| `arquitectura` | `docs/context/arquitectura.md` | ramas, bots, aprobaciones |
| `stack_y_convenciones` | `docs/context/stack_y_convenciones.md` | infra, tablas, lean/robusto, gotchas |
| `reglas_generales` | `reglas_generales.md` | las 5 reglas que van dentro de cada system_prompt |

Regla de escritura para estos archivos (aplica igual al seed y a las
actualizaciones que produce Upgrade & review center después): **presente,
hechos, sin historia**. El porqué de cada decisión y su narrativa siguen
viviendo en `arquitectura_general.md`, `plan_de_accion_completo.md` y
`contexto_proyecto_infinite_power_v6.md` — esos son para humanos y NO se
inyectan a ningún bot (son demasiado largos y están llenos de decisiones
revertidas que confundirían al modelo).

### `knowledge_log` — bitácora de casos

Qué le ha pasado al sistema. Crece constantemente. Dos tipos, con dueño distinto:

| tipo | quién redacta | quién dispara | ritmo | juicio requerido |
|---|---|---|---|---|
| `patron_fallo` | el ejecutor, automático, desde `patron_aprendido` de Trouble shooter | automático (ver excepción `conocimiento_directo` abajo) | alto | ninguno — ya viene estructurado |
| `aprendizaje` | Upgrade & review center | Efadam | bajo | mucho |

**Por qué no todo pasa por Efadam para redactar.** Para los patrones de fallo
de Trouble shooter, Efadam no participa: Trouble shooter ya entrega el patrón
en JSON estructurado, no hay nada que curar, y meter a Efadam en medio agrega
tres saltos de latencia y consumo de tokens en el bot de mayor frecuencia del
sistema — que además corre en modelo gratis, o sea el peor juez posible de
qué vale la pena recordar. Esto no contradice el cuello de botella (ver
sección siguiente): es la única excepción documentada, y está acotada a un
solo bot por una razón específica, no es una puerta abierta.

Para `aprendizaje` (y, desde el 15 de agosto, también para cambios a
`system_knowledge`) sí hace falta criterio — pero el criterio no es de
Efadam. Ver la sección siguiente.

## Efadam como cuello de botella intencional, no como autor

Precisión de diseño del 15 de agosto de 2026, hasta ahora no documentada en
ningún archivo (corrige una imprecisión de `efadam.md` y de la tabla anterior
de este mismo documento, que decían "lo escribe Efadam").

**Esto es uno de los rasgos que diferencia a Infinite Power de sistemas
multi-agente parecidos, así que vale la pena repetirlo con todas sus letras
en cada documento donde aplique, no solo aquí:** todo conocimiento que cruza
de una rama a otra tiene que pasar por Efadam, incluso cuando eso se sienta
como fricción o como un paso de más. Esa fricción es intencional — es lo que
hace posible que el sistema aprenda de forma centralizada en vez de que cada
bot acumule su propio conocimiento aislado, sin que nadie más se entere. Si
un bot pudiera hablarle directo a otra rama o escribir directo a las tablas
de conocimiento, Efadam nunca se enteraría, y no habría aprendizaje
compartido ni contexto inyectado a futuro.

Cuando un hallazgo de cualquier rama implica que algo en `system_knowledge` o
`knowledge_log` (tipo `aprendizaje`) debería actualizarse, el flujo es:

1. El hallazgo le llega a **Efadam** (vía el reporte consolidado del center
   correspondiente). Nada llega a Postgres sin pasar primero por Efadam — en
   ese sentido sigue siendo el cuello de botella único, consistente con su
   rol de interfaz central.
2. Efadam **no redacta el contenido**. Le solicita a **Upgrade & review
   center** que lo produzca — es el dueño natural de esto: su misión ya
   documentada es "Observar → Analizar → Mejorar", y su regla ya documentada
   es "no aprobar nada por default", evaluando cada hallazgo contra evidencia
   real antes de dejarlo pasar. Redactar el `aprendizaje` o la actualización
   de `arquitectura`/`stack_y_convenciones`/`reglas_generales` es una
   extensión directa de ese rol, no una responsabilidad nueva.
3. Upgrade & review center entrega el contenido ya evaluado; Efadam lo
   inserta/actualiza en Postgres y confirma. Efadam no re-audita el fondo —
   igual que ya hace con el resto de lo que U&R center le reporta, solo
   revisa que no haya discrepancia con la meta de negocio establecida.

Esto mantiene la simetría del diseño existente (los 3 centers retienen y
auditan su rama; Efadam enruta y no re-audita el detalle) en vez de crear una
excepción especial para el conocimiento del sistema.

## La única excepción al cuello de botella: `bots.conocimiento_directo`

Hallado en una nota de visión antigua (`docs/vision/Efadam/Efadam.md`),
escrita el 14 de agosto y hasta ahora nunca fusionada con el resto de la
documentación — quedaba como un nodo desconectado en el vault de Obsidian.
Se incorpora aquí formalmente, corrigiendo dos cosas que decía esa nota y que
ya no aplican: que Efadam es "dueño por default" de escribir en
`knowledge_log` (ya no — ver sección anterior), y que Efadam "todavía no
existe como bot activo" (ya no — es el primer paso del orden de construcción
vigente).

El principio general es que **no existe una vía alterna al cuello de
botella** — ver sección anterior. Pero hay una única forma válida de que un
bot escriba directo a `knowledge_log` sin pasar por Efadam: que su
conocimiento **no aporte absolutamente nada fuera del campo exacto en el que
ese bot trabaja**. No es una excepción por "tipo" de hallazgo (no es "todos
los errores técnicos se saltan a Efadam") — es una excepción explícita,
opt-in, por bot individual, y se espera que sea rara.

**Mecanismo:** columna `bots.conocimiento_directo boolean default false`.
Cualquier bot nuevo empieza en `false` — pasa por Efadam salvo que se
justifique explícitamente lo contrario, caso por caso.

**Único bot que califica hoy: Trouble shooter.** Sus patrones son errores de
infraestructura (n8n, Postgres, encoding, Docker) — nunca le van a servir a
Legal, a Estrategia, ni a ningún otro dominio del negocio. Por eso, y solo
por eso, sus `patron_fallo` se insertan automáticamente vía el ejecutor, sin
pasar por Efadam (esto es lo que ya describía la tabla de la sección "Dos
tablas, porque son dos cosas distintas" arriba, ahora con el mecanismo
formal que lo respalda).

**Prueba para cualquier candidato futuro a esta excepción:** *¿hay algún
escenario donde otra rama necesitaría saber esto?* Si la respuesta no es un
"no" claro y rotundo, el bot se queda en `conocimiento_directo = false` y
pasa por Efadam.

Este mecanismo es ortogonal al de la sección anterior, no lo contradice: la
sección anterior define **quién redacta** el contenido que sí pasa por
Efadam (U&R center, no Efadam); este mecanismo define **quién puede saltarse
a Efadam por completo**, y hoy esa lista tiene un solo nombre.

## Cómo Efadam conoce el proyecto (dos mecanismos distintos)

Precisión de diseño del 15 de agosto de 2026, tarde — quedaba implícito pero
no estaba escrito en ningún lado, y es la pregunta obvia una vez que Efadam
se construye antes que las ramas.

Efadam necesita dos tipos de conocimiento, y usa un mecanismo distinto para
cada uno — no los mezcla:

1. **Qué es el sistema (no cambia mensaje a mensaje, pero sí evoluciona con
   el tiempo): `system_knowledge` vía `contexto_slugs`.** Igual que
   cualquier otro bot, Efadam declara en `bots.contexto_slugs` qué slugs se
   le inyectan al arrancar cada corrida. Asignación: `{arquitectura,
   stack_y_convenciones}` (ver tabla de asignación abajo). Sin esto, Efadam
   no sabría qué ramas existen, qué hace cada center, ni cómo está armada la
   infraestructura — necesitaría adivinar o preguntar en cada mensaje, lo
   cual es inaceptable para el bot de mayor frecuencia del sistema. Este
   contenido cambia solo cuando Upgrade & review center lo actualiza vía el
   flujo de la sección anterior — no en cada corrida, pero tampoco nunca.
2. **Qué está pasando ahora mismo (cambia todo el tiempo, se lee en vivo):
   lectura directa de `tasks` y `agent_runs`.** Esto NO pasa por
   `contexto_slugs` — sería absurdo tratar de "sincronizar" el estado de las
   tareas de hoy como si fuera conocimiento de baja frecuencia. Efadam tiene
   permiso de lectura directa de estas dos tablas (excepción al principio
   general de que ningún bot lee Postgres directo — ver "Lo que este diseño
   deliberadamente NO hace" más abajo; Efadam es el único caso, porque su
   trabajo de enrutar y resumir requiere visión en vivo de las 3 ramas a la
   vez, cosa que ningún workflow podría curar de antemano sin saber qué va a
   preguntar el usuario).

**Lo que Efadam NO hace para conocer el proyecto:** no lee `docs/context/*.md`
del repo directamente (mecanismo descartado, ver más abajo), no lee el
detalle interno de cada bot individual de una rama, y no re-audita lo que
cada center ya consolidó.

## Cómo se inyecta

Un nodo `Cargar contexto` en el ejecutor genérico, entre "Obtener config del bot"
y "Llamar a OmniRoute", que devuelve dos bloques de texto ya armados.

**No se le inyecta lo mismo a todos.** El diseño anterior decía que
`system_knowledge` se inyecta igual para cada bot. Eso significa que Abogado
Jefe carga el schema de Postgres y los gotchas de n8n en cada dictamen legal:
tokens caros, límite de contexto de los modelos gratis, y ruido que empeora la
respuesta. Se controla con la columna `bots.contexto_slugs text[]`: cada bot
declara qué slugs necesita. Un array vacío es válido y es el default.

Asignación inicial:

| bot | contexto_slugs |
|---|---|
| `efadam` | `{arquitectura, stack_y_convenciones}` — necesita saber qué ramas existen y cómo enrutar; el estado en vivo lo lee directo de `tasks`/`agent_runs`, no de aquí (ver sección anterior) |
| `tecnico_jefe` | `{arquitectura, stack_y_convenciones}` |
| `coder` | `{stack_y_convenciones}` |
| Legal (cuando entren) | `{}` — no necesitan saber cómo está armado el sistema |

Las reglas generales NO van por aquí: viajan dentro del `system_prompt` de cada
bot, compuestas por un trigger de Postgres a partir de `prompt_especifico`.

## Repo como seed, no como fuente de verdad

Reemplaza la sección "Sincronización repo → tabla" original (ver "Diseño
descartado" abajo).

El repo (`docs/context/*.md`, `reglas_generales.md`) se usa **una sola vez**,
al arrancar el sistema, para poblar `system_knowledge` con su estado inicial.
Esto se hace corriendo a mano el mismo upsert que antes disparaba el workflow
de n8n, directo en terminal, en el mismo acto de tener los archivos ya
editados y Postgres a la mano — sin credencial nueva, sin ventana de desfase.

**Nota 15 de agosto:** este upsert se pospone hasta que haya un producto
final real que probar — no es un paso a correr durante la construcción de
Efadam ni de las ramas (ver `plan_de_accion_completo.md`, actualización de la
noche del 15 de agosto).

```sql
insert into system_knowledge (slug, titulo, contenido, source_file)
values ($1, $2, $3, $4)
on conflict (slug) do update
   set titulo = excluded.titulo,
       contenido = excluded.contenido,
       source_file = excluded.source_file,
       updated_at = now();
```

Después de ese seed inicial, **no hay ningún mecanismo automático que vuelva
a leer el repo**. El repo puede quedar desactualizado respecto a la tabla —
es esperado. Si en algún momento se quiere revisar "qué tanto se alejó el
sistema de su estado inicial", se compara la tabla contra el repo manualmente;
no es un proceso que el sistema corra solo.

**Por qué se abandonó la sincronización recurrente por API de GitHub:** el
diseño original (Manual Trigger en n8n, credencial de GitHub con PAT leyendo
el repo privado, upsert a Postgres) tenía dos problemas una vez que el
sistema se piensa para más de un operador:

1. Seguía dependiendo de que un humano se acordara de disparar el sync después
   de cada edición — no ganaba automatización real frente a correr el upsert
   en la misma sesión de terminal donde ya se edita el archivo.
2. El PAT quedaba como credencial persistente en n8n con acceso de lectura a
   todo el repo privado. En un sistema de un solo operador es un riesgo
   aceptable; en un sistema pensado para más gente con acceso a n8n, cualquiera
   con acceso al editor de workflows hereda de facto acceso al repo completo.
   Y de cualquier forma, dado que el conocimiento real ya no vive en el repo
   sino que lo genera Upgrade & review center directo en Postgres, mantener
   viva esa credencial dejó de tener función.

## Lo que este diseño deliberadamente NO hace

- No le da a ningún bot acceso directo de lectura a Postgres, **salvo
  Efadam**, que lee `tasks`/`agent_runs` en vivo por la razón explicada en
  "Cómo Efadam conoce el proyecto" — es la única excepción al principio de
  "el workflow entrega el contexto ya curado". Para el resto de los bots
  sigue aplicando sin excepción.
- No le permite a ningún bot escribir en `knowledge_log`/`system_knowledge`
  saltándose a Efadam, **salvo** el caso acotado de
  `bots.conocimiento_directo` (hoy, solo Trouble shooter) — ver sección
  dedicada arriba. Esto es intencional y es lo que hace posible el
  aprendizaje centralizado: la fricción de pasar por Efadam no es un costo a
  eliminar, es el mecanismo mismo.
- No hay banco de conocimiento por center. Se evaluó y se descartó: sería el
  mismo mecanismo repetido tres veces.
- No hay embeddings ni búsqueda semántica. Con menos de 50 filas en
  `knowledge_log`, un `ORDER BY updated_at DESC LIMIT 15` filtrado por cluster
  es suficiente. Revisar esto cuando la tabla pase de ~200 filas.
- Ya no mantiene una credencial de GitHub viva en n8n para leer el repo en
  cada corrida — ver "Repo como seed, no como fuente de verdad".

## Diseño descartado — sincronización recurrente repo → tabla (14 ago 2026)

Se documenta para no perder el razonamiento, no porque siga vigente.

Workflow de n8n "Sync conocimiento del sistema", disparo manual:

1. Manual Trigger.
2. GitHub → *Get file content* para cada archivo de `docs/context/` y para
   `reglas_generales.md` (requería credencial de GitHub con un PAT, el repo
   es privado).
3. Postgres → *Execute Query*, el mismo upsert que arriba, uno por archivo.

Se decidió correrlo cada vez que se editara un archivo de `docs/context/`. Se
descartó el 15 de agosto de 2026 por las razones en "Repo como seed, no como
fuente de verdad". El workflow en n8n (`Sync conocimiento del sistema`,
desactivado) se borró (confirmado); el patrón de nodos (Leer GitHub → Extraer
texto → Guardar Postgres) queda documentado aquí por si algún día vuelve a
hacer falta releer el repo por algún motivo puntual — no como mecanismo
recurrente.
