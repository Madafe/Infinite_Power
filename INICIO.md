# INICIO — Infinite Power

> Nota índice del vault. Todo el repo es el vault de Obsidian: cada `.md` de
> aquí es una nota, versionada en git. Empieza por acá.

## Qué es esto

Infinite power — la visión, la propuesta de valor y el Método (contenido
fusionado en `docs/archivo/plan_de_accion_completo.md`, 15/ago; la nota
suelta que existía se eliminó).

Sistema de agentes de IA que se adapta y trabaja activamente para mejorar
cualquier proyecto que se le asigne. Efadam está en el centro y coordina tres
departamentos; cada uno consolida, audita y aprueba su propio trabajo antes de
reportar hacia arriba.

## Propuesta de valor

Infinite Power funciona como una empresa digital adaptable para el proyecto
que se le asigne. En vez de limitarse a responder una petición puntual,
evalúa el proyecto de forma continua, identifica oportunidades, propone
mejoras, coordina trabajo especializado y aprende de los resultados para
mejorar su desempeño y su costo.

El usuario conserva el control: define el proyecto, los límites de autonomía,
las aprobaciones y el presupuesto. Puede operar con herramientas gratuitas o
escalar la inversión cuando el proyecto lo justifique, sin tener que formar,
capacitar ni coordinar un equipo humano para cada especialidad.

ChatGPT puede ayudar a resolver algo cuando se le pide; Infinite Power busca
observar, sugerir, construir, corregir y evolucionar de forma constante a
favor de los proyectos asignados.

## Estado actual

- [[estado_del_proyecto]] — qué existe de verdad hoy (no lo planeado)
- **Bots activos:** `tecnico_jefe`, `coder`, `trouble_shooter`. Nada más.
  Un bot que no está en la tabla `bots` con `active = true` no existe.

## Arquitectura (visión)

- Infinite power — método, cadencia, revert, multiproyecto (fusionado en
  `docs/archivo/plan_de_accion_completo.md`, 15/ago)
- Efadam — bot cabeza, enrutamiento y memoria (fusionado en
  `prompts/_core/efadam.md` y [[memoria_del_sistema]], 15/ago)
	- [[Tech center]] — departamento Dev/Tech
	- [[Upgrade & Review center]] — departamento Estrategia
	- [[Proyect center]] — departamento Proyectos
- [[arquitectura_general]] — narrativa completa y el porqué de cada decisión

## Sistema (implementación)

- [[memoria_del_sistema]] — diseño de `system_knowledge` + `knowledge_log`
- [[ejecutor_generico]] — el workflow real, 19 nodos, con hallazgos pendientes de corregir
- [[reglas_generales]] — las 5 reglas dentro de cada `system_prompt`
- [[autonomia_progresiva]] — criterio de graduación (aprobación → autonomía)

## Canónico para bots

Estos son cortos, en presente, solo hechos vigentes. Se sincronizan a la tabla
`system_knowledge` y se inyectan en el contexto de los bots que los necesitan.
**No meter narrativa ni historia aquí** — eso va en los documentos de arriba.

- [[arquitectura]] — `docs/context/arquitectura.md`
- [[stack_y_convenciones]] — `docs/context/stack_y_convenciones.md`
- [[reglas_generales]] — `docs/reglas_generales.md`

## Prompts y definición de departamentos

La definición concreta de los prompts y del alcance interno de cada
departamento está **por definir**. Antes de ampliar o crear prompts nuevos,
definir para cada departamento su misión, responsabilidades, límites,
integrantes y criterios de aprobación.

## Schema

`schema/*.sql`, en orden. Correr con `docker cp` + `psql -f`, **nunca** con
`Get-Content | docker exec` (corrompe acentos en PowerShell).

Antes de instalar Infinite Power fuera de local (VPS o instalación de un
tercero), verificar la portabilidad del schema y documentar el procedimiento
de despliegue, configuración, secretos, migraciones y respaldo.

## Archivo

`docs/archivo/` — documentos superados, conservados por trazabilidad:
`plan_de_accion.md`, `plan_de_accion_completo.md`,
`explicacion_general_y_paso_0.md`, `contexto_proyecto_infinite_power_v5.md`,
`ejecutor_generico_v1_diseno.md`.
No son fuente de verdad de nada. Si algo de ahí contradice a lo de arriba,
gana lo de arriba.

## Orden de construcción

**Efadam → Dev/Tech → Estrategia → Proyectos.**
