# Arquitectura de Infinite Power (canónico)

> Este archivo es la **fuente de verdad** de los hechos de arquitectura y se
> sincroniza a `system_knowledge.slug = 'arquitectura'`. Se inyecta en el
> contexto de los bots que lo necesitan. Escribir corto y en presente: solo
> lo que es cierto HOY, sin historia ni justificaciones. La narrativa y el
> porqué de cada decisión viven en `arquitectura_general.md`.

## Forma general

Efadam en el centro + 3 ramas. Cada rama tiene un bot "center" que consolida,
audita y retiene lo que produce su rama antes de reportar a Efadam.

- **Efadam** — única interfaz conversacional con el humano (Telegram hoy).
  Enruta y resume. No ejecuta trabajo de ninguna rama. No se salta las
  aprobaciones de la rama destino. Dueño **por default** de `knowledge_log` —
  todo bot nuevo pasa por Efadam para registrar lo que aprende, salvo una
  excepción angosta y explícita por bot (`bots.conocimiento_directo`, hoy solo
  `trouble_shooter`) cuando su conocimiento no cruza a ningún otro dominio.
- **Tech center** — hub de la rama Dev/Tech. Gate de aprobación final antes de
  producción en su rama.
- **Upgrade & review center** — hub de la rama Estrategia + Legal + Investigación.
  Misión: Observar → Analizar → Mejorar. Libera hacia Planner / Establecer metas.
- **Proyect center** — hub de la rama Operación/Proyectos y negocios propios.

Los 3 centers son simétricos: su función principal es **retener** (auditoría
activa de su rama), no solo enrutar. Efadam no re-audita el detalle de
ejecución; solo verifica que lo entregado no se contradiga con la meta.

## Bots activos hoy en la tabla `bots`

`tecnico_jefe` (despacha), `coder`, `trouble_shooter` (despacha, único con
`conocimiento_directo = true`).
Todo lo demás del roster está escrito pero **no activo**. Un bot que no está
en `bots` con `active = true` no existe para el sistema.

## Rama Dev/Tech (prompts escritos)

Prompt perfection, Entrenador Agentes, Coder, Agent builder, Trouble shooter,
Ciber seguridad scouter, Hacker ético, Ciber seguridad, Técnico jefe, Tech center.
Diseñados pero no activados: Consultor de arquitectura, Trouble scouter.

Flujo: Técnico jefe asigna → Coder / Agent builder / Trouble shooter ejecutan →
Tech center consolida y aprueba → Efadam.
Ciberseguridad: Ciber seguridad scouter → Hacker ético → Ciber seguridad → Técnico jefe.

## Rama Upgrade & review center (prompts pendientes)

Investigación (pipeline con orden definido): Investigador → Skill finder →
Observador de patrones replicables → Automatizador → Cross department → Council.
Corre en su propia cola — una tarea bloqueada en otra rama no la detiene; es
el mecanismo real detrás de "el sistema sigue pensando en el fondo".
No aprueba nada por default: si falta evidencia, rechaza y pide más data.

Estrategia: Nuevos departamentos, Especialista en organización y métodos,
Buscador de áreas de oportunidad, Out of the box thinker, Optimizador.
Legal: Abogado Scouter → Abogado Jefe → Abogado verificador.

Tiene su propia instancia de **Establecer metas / Planner**, para sus propias
metas internas. No comparte bot con Proyect center — cada departamento tiene
el suyo, duplicado a propósito (ver Proyect center más abajo).

Cross department es el agregador interno de esta rama; entrega a Upgrade & review center.

## Rama Proyect center (prompts pendientes)

Dueño del **Setup**: cuando arranca un proyecto nuevo (o Mateo pide reajustar
el actual), corre la entrevista de objetivo — meta, lista de pasos (vía su
propia instancia de Establecer metas → Planner, **duplicada** de la de Upgrade
& review center, no compartida), y criterio de "listo" para pasar a
mantenimiento de baja frecuencia. El resultado del Setup no se despacha
directo a otras ramas — vuelve a Efadam, quien decide qué jefe(s) le
corresponde cada parte.

Tracker de clientes, Front end, Consultor negocios, Task manager, Ventas
ideas, Expansión ideas, Mentor. Negocios propios (TalentIA, Bintix, Back
end/Front end páginas web, Consultor SEO) cuelgan de Proyectos.

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
