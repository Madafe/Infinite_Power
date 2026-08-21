# Arquitectura de Efadam (canónico)

> Seed inicial de `system_knowledge.slug = 'arquitectura'` — se usa una sola
> vez para poblar la tabla al arrancar el sistema (ver
> `memoria_del_sistema.md`, sección "Repo como seed, no como fuente de
> verdad"); no hay sync automático. Una vez seedeada, la tabla es la fuente
> de verdad viva que se inyecta en el contexto de los bots que la necesitan
> — este archivo puede quedar desactualizado respecto a ella. Escribir corto
> y en presente: solo lo que es cierto HOY, sin historia ni justificaciones.
> La narrativa y el porqué de cada decisión viven en `arquitectura_general.md`.

## Propósito operativo

Efadam mejora continuamente los proyectos que se le asignan. Organiza
una red de trabajo especializado mediante departamentos, aprende de los
resultados y opera dentro de los límites de autonomía, aprobación y
presupuesto que define el usuario. Está diseñado para sumar especialistas
cuando un proyecto necesita una capacidad nueva; no sustituye el control humano
sobre decisiones importantes.

## Forma general

Jarvis (endpoint humano) → Efadam (cerebro de orquestación) en el centro + 3
departamentos. Cada departamento tiene un bot "center" que consolida, audita
y retiene lo que produce antes de reportar a Efadam.

- **Jarvis** — endpoint de interacción humana. Recibe del cliente mensajes,
  fotos, archivos y documentos de oficina; los entrega a Efadam con sus
  referencias y metadatos, y muestra su respuesta. No se configura una
  entrada conversacional directa por Telegram.
- **Efadam** — cerebro de orquestación central y capa de razonamiento entre el
  cliente y el sistema. No ejecuta trabajo de ninguna rama ni despacha tareas
  directamente a los bots. Envía recomendaciones contextualizadas a los
  centers; cada recomendación declara: **"Estas son recomendaciones, no
  órdenes directas del cliente"**. No se salta las aprobaciones de la rama
  destino.
  Es el **cuello de botella intencional** único de entrada a `knowledge_log`
  (tipo `aprendizaje`) y a `system_knowledge`: todo conocimiento que cruza de
  una rama a otra pasa por él, incluso cuando eso implica fricción — es la
  razón por la que el sistema aprende de forma centralizada, y es uno de los
  rasgos que distingue a Efadam de sistemas multi-agente parecidos.
  Efadam no redacta ese contenido — se lo solicita a Upgrade & review center
  e inserta lo que este produce. La única excepción documentada es
  `bots.conocimiento_directo` (hoy, solo Trouble shooter — ver
  `memoria_del_sistema.md`). Al abrir una operación, confirma al cliente que
  está trabajando en ello sin esperar la síntesis de aprendizaje, que ocurre
  después de un cierre o hito y conserva el mismo `operation_id`. Conoce el
  sistema por dos vías: `system_knowledge`
  inyectado vía `contexto_slugs` (qué es el sistema; no cambia mensaje a
  mensaje, pero sí evoluciona con el tiempo) y
  lectura directa de `tasks`/`agent_runs` de cualquier rama (qué está pasando
  ahora, cambia todo el tiempo).
  **Actualizado 19/ago:** la excepción de lectura directa a Postgres ya no es
  solo de Efadam — los 3 centers (Tech center, Upgrade & review center,
  Proyect center) también leen `tasks`/`operations` directo, pero acotado a
  su propia rama (`WHERE cluster = su rama`) — así conocen el estado de sus
  propias sesiones activas sin depender de que Efadam se los inyecte, sin
  visibilidad cruzada entre ramas. Si un center necesita información fuera de
  su propia rama, le pregunta a Efadam en vez de leerla directo — Efadam
  sigue siendo el único con visibilidad de todo el sistema (confirmado por
  Mateo, 19/ago). La excepción sigue siendo solo de
  **lectura**: Efadam abre `operations` y controla la entrada a las tablas de
  conocimiento; cada center despacha las tareas de su propio departamento.
- **Tech center** — hub del departamento Dev/Tech. Recibe recomendaciones de
  Efadam, decide el plan de trabajo y despacha las tareas internas; mantiene
  el gate de aprobación final antes de producción.
- **Upgrade & review center** — hub del departamento Estrategia. Recibe
  recomendaciones de Efadam y despacha el trabajo de su departamento.
  Misión: Observar → Analizar → Mejorar. Libera hacia Planner / Establecer metas.
  Redacta y evalúa las actualizaciones de `system_knowledge` y `knowledge_log`
  que Efadam le solicita.
- **Proyect center** — hub del departamento Proyectos. Recibe recomendaciones
  de Efadam y despacha el trabajo de su departamento.

Los 3 centers son simétricos: reciben recomendaciones, deciden cómo actuar,
despachan el trabajo de su rama y retienen lo que requiere auditoría. Efadam
no re-audita ni dirige el detalle de ejecución; coordina con el cliente como
si contactara a un equipo de especialistas, sin exponer la arquitectura.

## Orden de construcción (vigente desde el 15 de agosto de 2026)

Vertical, un componente completo (construido, probado, activo) antes de pasar
al siguiente — ya no por fase horizontal ("escribir los 40 prompts primero"):

1. **Efadam** — se construye primero, para que cuando las ramas empiecen a
   producir output ya exista a dónde mandarlo. Evita el problema de ramas
   terminadas sin un destino que las reciba.
2. **Tech center** (departamento Dev/Tech completo) — `tech_center` insertado
   y activo el 21/ago; prueba end-to-end (webhook temporal) confirmó que
   decide correctamente pero destapó un bug real de parseo de JSON en el
   ejecutor genérico (ver `decisiones_arquitectura.md`, 21/ago) — no se puede
   dar por confirmado en producción hasta resolverlo. 12 de 12 bots del
   roster con prompt escrito y conforme a plantilla.
3. **Upgrade & review center** (departamento Estrategia completo).
4. **Proyect center** (departamento Proyectos completo).
5. **Jarvis** — al final. No tiene nada útil que enrutar ni con qué conversar
   hasta que Efadam y las 3 ramas ya existen y producen resultado real.
   Mientras tanto, Telegram (ya construido en la Fase 0 de infraestructura)
   sirve como canal de prueba puntual, sin uso operativo diario.

## Bots activos hoy en la tabla `bots`

**Corrección del 21 de agosto — verificado directo contra Postgres, esta
sección estaba desactualizada desde el 16/ago (le faltaban `efadam` y
`tech_center`).** Activos hoy: `efadam` (despacha, cluster `Efadam`),
`tech_center` (despacha, cluster `tech-center`, insertado el 21/ago),
`tecnico_jefe` (despacha), `coder` (no despacha), `trouble_shooter`
(despacha, `conocimiento_directo = true` — ver `memoria_del_sistema.md`).
Cinco bots activos en total.
Todo lo demás del roster está escrito pero **no activo**. Un bot que no está
en `bots` con `active = true` no existe para el sistema.

## Cómo cada bot conoce el sistema — `contexto_slugs`

Cada bot declara en `bots.contexto_slugs text[]` qué slugs de
`system_knowledge` se le inyectan al arrancar cada corrida. Array vacío es
válido y es el default — evita cargar contexto irrelevante (ej. Abogado Jefe
no necesita el schema de Postgres para un dictamen legal).

| bot | contexto_slugs |
|---|---|
| `efadam` | `{arquitectura, stack_y_convenciones}` — el estado en vivo del sistema (tareas pendientes, qué reportó cada center) lo lee directo de `tasks`/`agent_runs`, no de aquí |
| `tecnico_jefe` | `{arquitectura, stack_y_convenciones}` |
| `coder` | `{stack_y_convenciones}` |
| `trouble_shooter` | `{}` — no necesita saber cómo está armado el sistema, solo el diagnóstico de la tarea fallida que recibe |
| Legal (cuando entren) | `{}` — no necesitan saber cómo está armado el sistema |

Detalle completo de este mecanismo (incluyendo por qué Efadam es la única
excepción con lectura directa de Postgres) en `memoria_del_sistema.md`.

## Quién decide el modelo — esfuerzo

Ningún bot, incluido Efadam, referencia un modelo específico en su prompt.
Efadam recomienda el **esfuerzo inicial** de una operación (valores de
sistema: `bajo`, `medio`, `alto`, `critico`), usando complejidad y preferencia
de servicio. Los centers calculan el esfuerzo de cada tarea concreta que
descomponen; una operación no obliga el mismo valor a todas sus tareas.

La interfaz muestra las operaciones activas con su estado, esfuerzo actual y
recomendado, y permite ajustar el esfuerzo manualmente. El ajuste queda
auditado, afecta el trabajo pendiente o futuro y no reescribe una tarea que ya
está en ejecución. OmniRoute traduce `tasks.esfuerzo` al modelo configurado;
riesgo y aprobaciones son controles separados. El mecanismo completo está en
`stack_y_convenciones.md`, sección "Esfuerzo y BYOK".

## Departamento Dev/Tech (prompts escritos)

Prompt perfection, Entrenador Agentes, Coder, Agent builder, Trouble shooter,
Ciber seguridad scouter, Hacker ético, Ciber seguridad, Técnico jefe, Tech center.
Diseñados pero no activados: Consultor de arquitectura, Trouble scouter.

Flujo: Técnico jefe asigna → Coder / Agent builder / Trouble shooter ejecutan →
Tech center consolida y aprueba → Efadam.
Ciberseguridad: Ciber seguridad scouter → Hacker ético → Ciber seguridad → Técnico jefe.

## Rama Upgrade & review center (prompts pendientes)

Estrategia: Establecer metas, Planner, Nuevos departamentos, Especialista en
organización y métodos, Buscador de áreas de oportunidad, Out of the box thinker,
Optimizador, Council, Cross department, Automatizador.
Investigación: Investigador, Skill finder, Observador de patrones replicables.
Legal: Abogado Scouter → Abogado Jefe → Abogado verificador.

Cross department es el agregador interno de esta rama; entrega a Upgrade & review center.

## Rama Proyect center (prompts pendientes)

Proyectos, Tracker de clientes, Front end, Consultor negocios, Task manager,
Ventas ideas, Expansión ideas, Mentor, Establecer Metas, Planner — estos dos
últimos son instancia propia de esta rama, **no compartida** con Upgrade &
review center: cada rama tiene su propio bot duplicado (ver
`arquitectura_general.md`, corrección 14/ago/2026).
Negocios propios (TalentIA, Bintix, Back end/Front end páginas web, Consultor SEO)
cuelgan de Proyectos.

## Reglas de aprobación humana

Checkpoint obligatorio, sin excepción, en: gasto de dinero, publicación de
contenido público, temas legales, cambios de configuración de seguridad, y
cualquier acción fuera del sandbox de un bot con autonomía ampliada.
Cada center es además el gate final de su propia rama.

## Autonomía ampliada

**Out of the box thinker** es el único bot con autonomía total sobre sí mismo
(prompt auto-modificable versionado en git, presupuesto propio acotado).
Aprobación humana obligatoria para todo lo que salga de su sandbox.

**Hacker ético**: nunca decide su propio alcance; pruebas activas solo en
staging y con aprobación previa; nunca toca infraestructura de terceros.
