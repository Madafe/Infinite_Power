# INICIO — Infinite Power

> Nota índice del vault. Todo el repo es el vault de Obsidian: cada `.md` de
> aquí es una nota, versionada en git. Empieza por acá.

## Qué es esto

[[Infinite power]] — la visión, la propuesta de valor y el Método.

Sistema de agentes de IA para operar y hacer crecer los negocios de Mateo.
Efadam en el centro + 3 ramas, cada una con su bot "center" que consolida,
audita y aprueba antes de reportar hacia arriba.

## Estado actual

- [[estado_del_proyecto]] — qué existe de verdad hoy (no lo planeado)
- **Bots activos:** `tecnico_jefe`, `coder`, `trouble_shooter`. Nada más.
  Un bot que no está en la tabla `bots` con `active = true` no existe.

## Arquitectura (visión)

- [[Infinite power]] — método, cadencia, revert, multiproyecto
- [[Efadam]] — bot cabeza, enrutamiento y memoria
	- [[Tech center]] — rama Dev/Tech
	- [[Upgrade & Review center]] — rama Estrategia + Legal + Investigación
	- [[Proyect center]] — rama Operación/Proyectos, dueño del Setup
- [[arquitectura_general]] — narrativa completa y el porqué de cada decisión

## Sistema (implementación)

- [[memoria_del_sistema]] — diseño de `system_knowledge` + `knowledge_log`
- [[ejecutor_generico]] — el workflow único que corre a cualquier bot *(pendiente: reescribir para reflejar los 19 nodos reales)*
- [[reglas_generales]] — las 5 reglas dentro de cada `system_prompt`
- [[autonomia_progresiva]] — criterio de graduación (aprobación → autonomía)

## Canónico para bots

Estos son cortos, en presente, solo hechos vigentes. Se sincronizan a la tabla
`system_knowledge` y se inyectan en el contexto de los bots que los necesitan.
**No meter narrativa ni historia aquí** — eso va en los documentos de arriba.

- [[arquitectura]] — `docs/context/arquitectura.md`
- [[stack_y_convenciones]] — `docs/context/stack_y_convenciones.md`
- [[reglas_generales]] — `docs/reglas_generales.md`

## Prompts

- [[plantilla_prompt]] — plantilla estándar, usar para cualquier prompt nuevo
- [[caso_prueba_1_cluster_investigacion]] — caso de referencia real, útil para
  escribir los prompts de Investigación (rama Estrategia/Crecimiento)
- `prompts/_core/` — Efadam (cross-rama)
- `prompts/dev-tech/` — rama Dev/Tech (escritos, 12 prompts)
- `prompts/estrategia-crecimiento/` — siguiente rama a escribir
- `prompts/operacion-proyectos/`, `prompts/legal/`, `prompts/negocios-propios/`,
  `prompts/investigacion-skills/` — pendientes

## Schema

`schema/*.sql`, en orden. Correr con `docker cp` + `psql -f`, **nunca** con
`Get-Content | docker exec` (corrompe acentos en PowerShell).

## Archivo

`docs/archivo/` — documentos superados, conservados por trazabilidad:
`plan_de_accion.md`, `plan_de_accion_completo.md`,
`explicacion_general_y_paso_0.md`, `contexto_proyecto_infinite_power_v5.md`.
No son fuente de verdad de nada. Si algo de ahí contradice a lo de arriba,
gana lo de arriba.

## Orden de construcción

**Dev/Tech → Estrategia/Crecimiento → Operación/Proyectos.**
Legal y Negocios propios pospuestos sin fecha (no hay necesidad de negocio hoy).
