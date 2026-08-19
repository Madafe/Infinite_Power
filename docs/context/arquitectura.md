# Arquitectura de Infinite Power (canónico)

> Seed inicial de `system_knowledge.slug = 'arquitectura'` — se usa una sola
> vez para poblar la tabla al arrancar el sistema (ver
> `memoria_del_sistema.md`, sección "Repo como seed, no como fuente de
> verdad"); no hay sync automático. Una vez seedeada, la tabla es la fuente
> de verdad viva que se inyecta en el contexto de los bots que la necesitan
> — este archivo puede quedar desactualizado respecto a ella. Escribir corto
> y en presente: solo lo que es cierto HOY, sin historia ni justificaciones.
> La narrativa y el porqué de cada decisión viven en `arquitectura_general.md`.

## Forma general

Jarvis (endpoint humano) → Efadam (cerebro de orquestación) en el centro + 3 ramas.
Cada rama tiene un bot "center" que consolida, audita y retiene lo que produce
su rama antes de reportar a Efadam.

- **Jarvis** — endpoint de interacción humana, por texto y por voz. Es la
  superficie de conversación (hoy Telegram cumple ese rol de forma provisional
  mientras Jarvis no existe). Recibe el mensaje/voz del usuario y se lo pasa a
  Efadam; regresa la respuesta de Efadam al usuario. No tiene lógica de
  enrutamiento ni de negocio propia — es la capa de entrada/salida.
- **Efadam** — cerebro de orquestación central. Enruta y resume. No ejecuta
  trabajo de ninguna rama. No se salta las aprobaciones de la rama destino.
  Es el **cuello de botella intencional** único de entrada a `knowledge_log`
  (tipo `aprendizaje`) y a `system_knowledge`: todo conocimiento que cruza de
  una rama a otra pasa por él, incluso cuando eso implica fricción — es la
  razón por la que el sistema aprende de forma centralizada, y es uno de los
  rasgos que distingue a Infinite Power de sistemas multi-agente parecidos.
  Efadam no redacta ese contenido — se lo solicita a Upgrade & review center
  e inserta lo que este produce. La única excepción documentada es
  `bots.conocimiento_directo` (hoy, solo Trouble shooter — ver
  `memoria_del_sistema.md`). Es también quien asigna el nivel de importancia
  de cada tarea que despacha (ver "Quién decide el modelo" más abajo) — los
  bots destino no deciden su propio nivel. Al abrir una operación, confirma
  su registro y despacha la tarea concreta sin esperar la síntesis de
  aprendizaje, que ocurre después de un cierre o hito y conserva el mismo
  `operation_id`. Conoce el sistema por dos vías: `system_knowledge`
  inyectado vía `contexto_slugs` (qué es el sistema; no cambia mensaje a
  mensaje, pero sí evoluciona con el tiempo) y
  lectura directa de `tasks`/`agent_runs` (qué está pasando ahora, cambia
  todo el tiempo) — única excepción del sistema al principio de que ningún
  bot lee Postgres directo.
- **Tech center** — hub de la rama Dev/Tech. Gate de aprobación final antes de
  producción en su rama.
- **Upgrade & review center** — hub de la rama Estrategia + Legal + Investigación.
  Misión: Observar → Analizar → Mejorar. Libera hacia Planner / Establecer metas.
  Redacta y evalúa las actualizaciones de `system_knowledge` y `knowledge_log`
  que Efadam le solicita.
- **Proyect center** — hub de la rama Operación/Proyectos y negocios propios.

Los 3 centers son simétricos: su función principal es **retener** (auditoría
activa de su rama), no solo enrutar. Efadam no re-audita el detalle de
ejecución; solo verifica que lo entregado no se contradiga con la meta.

## Orden de construcción (vigente desde el 15 de agosto de 2026)

Vertical, un componente completo (construido, probado, activo) antes de pasar
al siguiente — ya no por fase horizontal ("escribir los 40 prompts primero"):

1. **Efadam** — se construye primero, para que cuando las ramas empiecen a
   producir output ya exista a dónde mandarlo. Evita el problema de ramas
   terminadas sin un destino que las reciba.
2. **Tech center** (rama Dev/Tech completa) — ya tiene 10 de 12 bots con
   prompt escrito; falta activarlo end-to-end contra un Efadam real.
3. **Upgrade & review center** (rama Estrategia/Crecimiento + Legal +
   Investigación completa).
4. **Proyect center** (rama Operación/Proyectos + negocios propios completa).
5. **Jarvis** — al final. No tiene nada útil que enrutar ni con qué conversar
   hasta que Efadam y las 3 ramas ya existen y producen resultado real.
   Mientras tanto, Telegram (ya construido en la Fase 0 de infraestructura)
   sirve como canal de prueba puntual, sin uso operativo diario.

## Bots activos hoy en la tabla `bots`

**Corrección del 16 de agosto, tarde — verificado directo contra Postgres,
esta sección tenía un bot de menos.** `tecnico_jefe` (despacha), `coder`,
`trouble_shooter` (despacha, `conocimiento_directo = true` — ver
`memoria_del_sistema.md`).
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

## Quién decide el modelo — niveles de importancia

Ningún bot, incluido Efadam, referencia un modelo específico en su prompt.
**Efadam es quien asigna el nivel de importancia** (valores de sistema:
`bajo`, `medio`, `alto`, `critico` — sin tilde, son identificadores, no
texto para leer) a cada tarea que despacha — un bot individual no decide el
suyo propio, porque solo ve su tarea aislada y no tiene la visión de
negocio que sí tiene Efadam. El bot que ejecuta hereda el nivel ya
asignado, guardado en `tasks.nivel_importancia`. OmniRoute (LiteLLM
self-hosted) traduce ese nivel al modelo real vía alias de modelo
configurados en su `config.yaml` — mecanismo concreto y ejemplo completo en
`stack_y_convenciones.md`, sección "Niveles de importancia y BYOK".

## Rama Dev/Tech (prompts escritos)

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
