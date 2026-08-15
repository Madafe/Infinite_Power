Infinite power es un loop de agentes potenciado por diversos modelos de inteligencia artificial el cual tiene el objetivo de mejorar y/o trabajar en el proyecto que se le asigne sea cual sea.
Puede ir desde resolver un proyecto escolar muy simple hasta analizar y gestionar una empresa pequeña

Propuesta de valor:
Al ser un loop, infinite power puede trabajar indefinidamente en la tarea que se le asigne y estar buscando constantemente nuevas perspectivas con las cuales mejorar el proyecto sin intervención humana, en caso de topar con algo que requiera aprobación o que interactue directamente fuera de su entorno detiene esa tarea, pero en el fondo sigue pensando en nuevas ideas

Los agentes conversan entre sí y son capaces de llevar una memoria en la que pueden identificar patrones tanto como para evitarlos como para replicarlos, estos se guardan en una base de datos y al ser detectado por "efadam", el bot cabeza, inyecta el prompt para el siguiente con este contexto

Tiene un control de versiones integrado, por lo que si tu loop termina tomando una dirección que ya no te gusta, puedes regresar a versiones anteriores

Metodo:

Setup: 




---

## Notas de refinamiento (definidas en conversación con Claude)

Estas notas no reemplazan el texto de arriba, lo precisan para que el Método no prometa algo que el mecanismo real no hace:

- **"Indefinidamente" = cadencia, no continuo.** Cada rama/proyecto corre con un Schedule Trigger propio (ver Método > Cadencia), no un proceso que nunca para. Se siente indefinido porque las colas son independientes entre ramas, no porque literalmente nunca se detenga.
- **"Sigue pensando en el fondo" ya existe, no es una feature nueva.** Es el departamento de Investigación (dentro de Upgrade & Review center) corriendo en su propia cola. Que una tarea de Legal esté bloqueada nunca detiene a Investigación, porque son colas separadas en Postgres.
- **"Los agentes conversan entre sí" → no es chat libre.** Es paso de tareas estructurado vía la tabla `tasks`, con cada center como gate de su rama. Se descartó a propósito el patrón de conversación libre entre agentes (el que usan frameworks como AutoGen/CrewAI) porque en 2026 sigue siendo la causa más común de loops que no convergen y gasto descontrolado en ese tipo de sistemas.
- **Versionado real: tres capas, no una.** (1) Prompts/config de bots → git, sí reversible. (2) `knowledge_log` (decisiones/hallazgos) → histórico append-only, no se revierte, se archiva. (3) Acciones que ya salieron al mundo real (correo enviado, pago hecho) → no reversibles, punto. Ver Método > Revert.

## Método (versión trabajada)

### Qué es hoy, en una frase honesta
Sistema interno de agentes para operar y hacer crecer el negocio de Mateo, construido como Efadam + 3 ramas (Tech center, Upgrade & Review center, Proyect center). El patrón (Efadam enruta → jefe de rama aprueba/actúa) está pensado para generalizarse a cualquier proyecto más adelante — ver "Multiproyecto" — pero hoy el roster concreto está modelado para el negocio de Mateo, no para cualquier tarea arbitraria.

### Setup
Vive en Proyect center. Es una entrevista de objetivo que produce: meta, lista de pasos necesarios para llegar a esa meta, y un criterio de "listo" (para que el proyecto pueda pasar a modo mantenimiento de baja frecuencia en vez de generar ideas para siempre sobre algo ya cumplido).

El Setup **no dispara nada directamente** a otras ramas. Flujo correcto:
Setup (Proyect center) → resultado vuelve a Efadam → Efadam decide qué jefe(s) le corresponde cada parte y les inyecta el contexto específico → el jefe correspondiente (ej. Técnico jefe en Tech center) decide dentro de su propio dominio si hace falta construir algo nuevo vía Agent builder.

**Principio de jerarquía (no negociable):** los jefes son la única autoridad dentro de su dominio. Ningún bot puede ser jefe de sí mismo ni de otro departamento. Todo pasa por Efadam porque es el único punto que inyecta contexto correcto y aprende comparando contra su propia base de conocimiento — esto no es un cuello de botella accidental, es la razón de ser del sistema.

### Cadencia (reemplaza "loop indefinido")
Cada rama/proyecto corre por Schedule Trigger en n8n, con su propia frecuencia — **pendiente definir el número exacto por rama**. Usamos OmniRoute como gateway multi-proveedor (90+ proveedores con capa gratis, fallback automático de 4 niveles), lo que baja mucho el riesgo de que una cadencia alta se corte por rate limit de un solo proveedor — pero no elimina el criterio de "vale la pena seguir generando", que sigue siendo una decisión de diseño, no de infraestructura.

### Memoria
`system_knowledge` + `knowledge_log`, Efadam como dueño único del log. Ya definido en `contexto_proyecto_infinite_power_v5.md`, no se reinventa aquí.

### Comunicación entre bots
Paso de tareas estructurado vía tabla `tasks`, no conversación libre entre agentes. Decisión consciente frente al patrón de frameworks como AutoGen/CrewAI, donde la conversación libre entre agentes es la causa más común de loops que no convergen. El patrón de cola con gate por center es más barato de acotar porque cada tarea ya tiene principio y fin natural.

### Revert
No se borra nada — se archiva. `archived_at` + `archived_reason` en las tablas relevantes, disparado por una tabla `reverts (fecha_objetivo, disparado_por, motivo)`. Efadam solo lee lo vigente por default; lo archivado queda disponible para Trouble scouter y para revisión manual — así no se pierde la evidencia de por qué el sistema se fue por un mal camino. Prompts de bots ya tienen su propio revert real vía git. Se dispara solo por Mateo vía Telegram → Efadam, nunca automático. Nunca revierte acciones que ya salieron al mundo real (correos enviados, pagos, entregables a clientes) — eso no es lo que nadie espera de esta función.

### Multiproyecto (visión, no construir todavía — post Fase 2)
Un proyecto nuevo = un schema nuevo en el mismo Postgres, no una base de datos ni un stack completo nuevo. Se comparte: n8n, OmniRoute, y los prompts del kernel (versionados en git). Se aísla por proyecto: solo los datos, vía schema.

Una tabla de control `proyectos (id, nombre, schema_name, estado, fecha_creación)` le permite a Efadam saber qué proyectos existen. Los nodos de Postgres en n8n deben apuntar al schema de forma dinámica (parámetro, no hardcodeado) — requisito de diseño desde ahora, no algo que se pueda parchar después sin refactor.

Los proyectos corren en paralelo, cada uno con su propia cadencia — el Schedule Trigger consulta `proyectos WHERE estado = 'activo'` y despacha una ejecución por cada uno. Cambiar de proyecto en la app no es un switch pesado, es decirle a Efadam a cuál te refieres; los demás siguen corriendo solos.

**Pendiente antes de construir esto:** confirmar que los workflows actuales de n8n no tienen el schema hardcodeado (si lo tienen, hace falta migrarlos primero).

### Alcance actual (para no prometer de más)
Hoy el roster (Legal, negocios propios, TalentIA/Bintix, Proyect center) está modelado para el negocio de Mateo. El patrón es generalizable, el roster concreto todavía no. Se declara explícitamente para que el Método no prometa "cualquier proyecto" cuando lo que existe hoy es un patrón con una sola instancia construida.
