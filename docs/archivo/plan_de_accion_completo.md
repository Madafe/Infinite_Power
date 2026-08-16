# Plan de acción completo — "Infinite power"
### Sistema de agentes autogestionado para el negocio

Para: Mateo + amigo · 7 de agosto de 2026

---

## Actualización — 16 de agosto de 2026 (mecanismo concreto nivel → modelo, `schema/005_nivel_importancia.sql`) — VIGENTE, léase primero

Quedaba un hueco real señalado por Mateo: se documentaba "OmniRoute traduce
nivel → modelo" como principio, sin especificar nunca el mecanismo. Resuelto:

- **`nivel_importancia` vive en `tasks`, no en `bots`** — coherente con que
  Efadam asigna el nivel por tarea, no por bot fijo. Migración nueva:
  `schema/005_nivel_importancia.sql` (columna + check constraint). Reemplaza
  a `bots.default_model` como fuente del modelo a llamar (esa columna queda
  sin uso activo, no se elimina por ahora).
- **OmniRoute es LiteLLM self-hosted.** El nodo "Llamar a OmniRoute" del
  Ejecutor manda el nivel tal cual en el campo `model` del request (ej.
  `model: "alto"`); LiteLLM resuelve ese valor vía **alias de modelo**
  (feature nativa, `model_name` = nivel en su `config.yaml`) al modelo real
  configurado para esa instalación. No hay tabla de lookup nueva ni lógica
  de ruteo propia que construir. Ejemplo completo de `config.yaml` en
  `stack_y_convenciones.md`.
- **Corrección de encoding:** los 4 valores literales del sistema
  (`tasks.nivel_importancia`, alias de LiteLLM, lo que Efadam escribe en el
  JSON de la tarea) son `bajo`/`medio`/`alto`/`critico` — **sin tilde en
  "critico"**, porque son identificadores de sistema, no texto para leer.
  El prompt de Efadam (`efadam.md`) tenía "crítico" con tilde, lo cual
  habría roto el `INSERT` en cuanto Efadam generara una tarea crítica de
  verdad — corregido antes de activarlo, no después. La prosa de los
  documentos sigue usando tilde donde es solo lectura humana.

**Consecuencia práctica:** el pendiente #16 de abajo queda parcialmente
resuelto (el mecanismo de traducción ya está diseñado y accionable); lo que
falta ahí es solo correr la migración y ajustar el nodo 5 del Ejecutor en
n8n — se hace junto con el punto 1 (activar Efadam).

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

**Multiproyecto (visión, no construir todavía — post Fase 2 del recorrido
vertical actual).** Un proyecto nuevo = un schema nuevo en el mismo
Postgres, no una base de datos ni un stack completo nuevo. Se comparte:
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

- [ ] Dominio (ya lo tienen) — acceso al panel DNS
- [ ] Tarjeta para pagar el VPS (~$5–6 USD/mes, se puede repartir entre los 2)
- [ ] Cuenta de GitHub compartida u organización con ambos como miembros
- [ ] Claves de API: Gemini (amigo), la que compre Mateo con sus $150 MXN, Groq, y cualquier otra que ya tengan de OmniRoute
- [ ] Teléfono para crear el bot de Telegram
- [ ] Decidir quién paga/administra el VPS (recomendado: uno solo lo administra para no duplicar accesos, pero ambos tienen la contraseña guardada en un gestor compartido tipo Bitwarden)

**Reparto de responsabilidades sugerido:**

| Persona | Se enfoca en |
|---|---|
| Mateo | Infra local, rama Upgrade & review center (Estrategia/Legal/Investigación) |
| Amigo | OmniRoute + routing de modelos, rama Tech center (Dev/Tech), rama Proyect center (Operación/Proyectos + negocios propios) |

Ajusten según quién se sienta más cómodo con qué parte — lo importante es que **cada rama tenga un dueño claro**. (La rama Tech center ya tiene sus 10 prompts escritos — ver `arquitectura.md`.)

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

Ambos con acceso de escritura. Cada bot tendrá su propio `.md` dentro de `prompts/<cluster>/<bot>.md`.

### Paso 0.7 — Bot de Telegram para aprobaciones

1. Hablarle a `@BotFather` en Telegram, `/newbot`, ponerle nombre (ej. `InfinitePowerBot`).
2. Guardar el token que da BotFather.
3. Crear un grupo de Telegram con Mateo + amigo, agregar el bot al grupo.
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

**Tiempo estimado:** continuo, revisar cada 2 semanas.

### Criterio de "graduación" por cluster (checklist a cumplir antes de quitar una aprobación)

- [ ] 2 semanas corriendo sin un error no manejado
- [ ] Costo dentro del rango esperado las 2 semanas
- [ ] Ningún caso donde el bot haya hecho algo que ustedes no hubieran aprobado
- [ ] Los dos están de acuerdo en quitar el checkpoint (no solo uno)

Ir cluster por cluster, nunca todos a la vez.

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
8. Agregar al amigo/cofundador como colaborador del repo de GitHub (pendiente desde la Fase 0).
9. Activar más bots en la tabla `bots` conforme cada componente vertical lo requiera — hoy solo `tecnico_jefe` y `coder` están activos; Consultor de arquitectura y Trouble scouter siguen pospuestos con criterio explícito (ver actualización del 14 de agosto, tarde).
10. Corregir `consultor-de-arquitectura.md` y `trouble-scouter.md`, que aún referencian `project_knowledge`/`trouble_shooter_knowledge` (nombres ya descartados) — corregir antes de activarlos.
11. **Implementar el empaquetado de OmniRoute + n8n para distribución** (diseño ya definido, ver actualización del 15 de agosto, noche, arriba y `stack_y_convenciones.md`): agregar la columna `bots.nivel_importancia` al schema, definir los defaults gratis por nivel dentro de la config de OmniRoute, y diseñar la pantalla/paso de setup donde el usuario ve los 4 niveles y puede añadir sus llaves. No es bloqueante para construir Efadam — se puede implementar en paralelo o después, cuando el paquete se piense para distribuirse a un tercero.
12. ~~Eliminar o resolver la duplicación de la nota `docs/vision/Efadam/Efadam.md` en Obsidian~~ — **hecho (15 de agosto, noche):** su contenido ya estaba fusionado en `memoria_del_sistema.md` y `efadam.md`; el archivo original se eliminó del repo (revisado y aprobado por Mateo).
13. ~~Localizar y leer "Infinite power.md > Método > Multiproyecto"~~ — **hecho (15 de agosto, noche, cuarta ronda):** localizada en `docs/vision/Infinite power.md`, fusionada a este documento (ver actualización correspondiente arriba) y la nota original eliminada.
14. ~~Decidir qué hacer con dos archivos sueltos sin commitear~~ — **hecho (15 de agosto, noche):** `schema/_tmp_diag_github.ps1` (apuntaba al workflow "Sync conocimiento del sistema" ya borrado) y `schema/_tmp_inspect_schedule.js` (exploración puntual de internals de `ScheduleTrigger`, ya resuelta) se revisaron — sin secretos en texto plano — y se borraron del disco. Nunca estuvieron trackeados en git, así que no generaron commit.
15. ~~Decidir cómo Efadam clasifica el nivel de importancia con confiabilidad~~ — **hecho (15 de agosto, noche, tercera ronda):** reglas explícitas por dominio/tema, no criterio libre — ver `stack_y_convenciones.md`, "Reglas de asignación", y actualización correspondiente arriba.
16. ~~Implementar en n8n la lógica real de aplicar la tabla de reglas de nivel~~ — **parcialmente hecho (16 de agosto):** el mecanismo nivel → modelo ya está diseñado y accionable (`schema/005_nivel_importancia.sql`, alias de LiteLLM, ver actualización de arriba). Falta: correr la migración contra Postgres, y ajustar el nodo 5 ("Llamar a OmniRoute") del Ejecutor genérico en n8n para que mande `tasks.nivel_importancia` en vez de `bots.default_model`. Se hace junto con el punto 1 (activar Efadam).
17. **Nuevo (post Fase 2, no ahora):** construir Multiproyecto — schema por proyecto en Postgres, tabla `proyectos`, nodos Postgres con schema dinámico. Antes: confirmar que los workflows actuales de n8n no tienen el schema hardcodeado.
18. **Nuevo:** construir el mecanismo de Revert (tabla `reverts`, `archived_at`/`archived_reason` en `knowledge_log` y demás tablas relevantes) — sin fecha fija, pero vale la pena tenerlo antes de que el sistema empiece a tomar decisiones con consecuencia real que alguien quiera poder revisar/archivar.
19. **Nuevo:** escribir el prompt de Setup en Proyect center (entrevista de objetivo → meta + pasos + criterio de "listo") — se escribe en su turno, cuando toque construir Proyect center (paso 4 del orden vertical).
