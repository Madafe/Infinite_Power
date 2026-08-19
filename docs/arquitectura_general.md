# Arquitectura general — "Infinite Power"

> Documento **narrativo**, para humanos. Explica el porqué de cada decisión.
> No se inyecta a ningún bot. La versión corta y canónica que sí leen los bots
> es [[arquitectura]] (`docs/context/arquitectura.md`).

## Propuesta de valor

Infinite Power busca comportarse como una empresa digital adaptable para el
proyecto que se le asigne: observar su estado, sugerir oportunidades,
coordinar especialidades, ejecutar mejoras y aprender de los resultados. El
usuario conserva el control de la autonomía, las aprobaciones y el presupuesto;
el sistema puede usar herramientas gratuitas o escalar el gasto solo cuando el
proyecto lo justifique.

La diferencia no es responder una petición aislada, sino mantener un ciclo de
mejora continua sin requerir que el usuario forme, capacite ni coordine un
equipo humano para cada especialidad.

## La estructura real (corregida)

El diagrama no es una lista plana de 6 clusters independientes. Es una estructura de **Efadam en el centro + 3 departamentos**, cada uno con su propio bot "center" que consolida y filtra todo lo que pasa en su departamento antes de que le llegue a Efadam. Los tres "center" son estructuralmente simétricos: cada uno hace para su departamento lo mismo que los otros dos hacen para el suyo.

```
                        EFADAM
                    (interfaz central)
                          |
        -----------------|-----------------
        |                |                |
   Tech center   Upgrade & review    Proyect center
 (departamento Dev/Tech) center (departamento   (departamento Proyectos)
                           Estrategia)
```

## Los 3 departamentos

### Departamento Dev/Tech — [[Tech center]]

Hub: **Tech center**. Consolida el trabajo técnico y ahora también actúa como el filtro de aprobación final antes de que algo se considere terminado en esta rama (se fusionó con lo que antes tenía mal ubicado como "Upgrade & review center" dentro de Dev/Tech — ver nota de corrección abajo).

Miembros: Prompt perfection, Entrenador Agentes, Coder, Agent builder, Trouble shooter, Ciber seguridad scouter, Hacker ético, Ciber seguridad, Técnico jefe, Tech center.

Flujo interno: Prompt perfection ↔ Entrenador Agentes, Coder → Agent builder, ambos pares alimentan a Técnico jefe junto con Trouble shooter; Ciber seguridad scouter → Hacker ético → Ciber seguridad → Técnico jefe; Técnico jefe → Tech center → Efadam.

### Departamento Estrategia — [[Upgrade & Review center]]

Hub: **Upgrade & review center**. Es el bot que revisa y "sube de nivel" (upgrade) lo que produce toda esta rama — ideas, hallazgos de investigación, dictámenes legales — antes de que llegue a Efadam. Recibe directamente de **Cross department**, que es el agregador interno de esta rama (junta lo que producen Legal, Investigación/Skills y parte de Estrategia antes de pasarlo hacia arriba).

Miembros:
- **Estrategia:** Establecer metas, Planner, Nuevos departamentos, Especialista en organización y métodos, Buscador de áreas de oportunidad, Out of the box thinker, Optimizador, Council (Counsil), Cross department, Automatizador.
- **Investigación/Skills:** Investigador, Skill finder (Youtube/Github/Reddit/Instagram), Observador de patrones replicables, Skill finder (genérico).
- **Legal:** Abogado Scouter, Abogado Jefe, Abogado verificador.

Flujo interno (aproximado): Investigador ↔ Skill finder ↔ Observador de patrones replicables ↔ Skill finder (genérico) → Automatizador; Abogado Scouter ↔ Abogado Jefe ↔ Abogado verificador → Investigador; todo esto converge en **Cross department**, que también recibe de Out of the box thinker; Cross department ↔ Especialista en organización y métodos ↔ Buscador de áreas de oportunidad ↔ Optimizador → Council; Establecer metas → Planner → Nuevos departamentos (con Planner también retroalimentando hacia Upgrade & review center); Cross department → **Upgrade & review center** → Efadam.

### Departamento Proyectos — [[Proyect center]]

Hub: **Proyect center**. Consolida el estado operativo de los proyectos/negocios y lo sube a Efadam.

Miembros: Proyectos, Tracker de clientes, Front end, Consultor negocios, Task manager, Ventas ideas, Expansión ideas, Mentor, Establecer Metas, Planner.

Flujo interno: Proyectos → Tracker de clientes → Proyect center (y Front end también alimenta a Proyect center); Expansión ideas → Ventas ideas → Task manager ↔ Consultor negocios ↔ Mentor → Proyect center.

> **Corrección 14/ago/2026:** este documento decía antes que Establecer Metas y
> Planner eran "nodos compartidos con el departamento Estrategia". Es incorrecto — cada
> departamento tiene **su propia instancia duplicada**, no comparte bot. Ver
> [[Proyect center]] y [[Upgrade & Review center]].

Nota: **TalentIA, Bintix, Back end/Front end páginas web, Consultor SEO** (negocios propios) no aparecieron en estas 4 capturas — por contexto de capturas anteriores, viven colgando de "Proyectos", así que se asumen parte de esta rama hasta confirmar.

## Corrección aplicada (uso del mandato de diseño)

Mateo dio mandato explícito: si durante la construcción se detecta que un bot nuevo ayudaría, o que uno existente rendiría mejor dividido en varios más específicos, aplicarlo sin necesidad de pedir permiso cada vez — documentando el cambio.

Primer uso de ese mandato: los prompts que ya se habían escrito para el cluster Dev/Tech incluían un bot **"Upgrade & review center"** como si fuera el gate de aprobación final *dentro* de Dev/Tech — error, basado en el mapeo incorrecto de clusters antes de esta corrección. Con la arquitectura real, ese nombre pertenece al hub de la Rama 2. En vez de inventar un tercer nombre para la función de "aprobar antes de producción" dentro de Dev/Tech, se fusionó esa responsabilidad directamente en **Tech center** — ya era el punto de consolidación de la rama, y añadirle el gate de aprobación humana antes de reportar a Efadam es una extensión natural de su rol, no una sobrecarga. Evita crear un bot redundante y mantiene la simetría de las 3 ramas (cada una con un solo "center" que consolida y aprueba).

## Mandato de diseño (para dejar registrado)

Durante la Fase 1 (y en general durante la construcción), Claude tiene autorización para:
- Proponer un bot nuevo con una tarea específica si detecta un hueco funcional.
- Dividir un bot existente en varios más específicos si eso mejoraría el rendimiento/claridad.
- Fusionar responsabilidades de bots distintos si evita redundancia (como el caso de Tech center arriba).

**Corolario (14/ago/2026):** el mandato aplica también en sentido inverso —
posponer o desactivar un bot ya diseñado si a la escala actual no aporta.
Escribir un prompt es barato; tener un bot activo cuesta tokens, latencia y
superficie de fallo en cada corrida.

Condición: todo cambio de este tipo se documenta (en el roster y en este archivo de arquitectura), explicando el porqué — no se aplica en silencio.


## Multiproyecto — rediseño (18/ago/2026)

**Reemplaza el diseño anterior** ("un proyecto nuevo = un schema nuevo en
el mismo Postgres, compartiendo n8n/OmniRoute/kernel", documentado en
`docs/archivo/plan_de_accion_completo.md` y ya marcado ahí como superado).

**Decisión:** un "proyecto" es un **despliegue completo e independiente**:
su propio n8n, su propia base de Postgres, su propio Efadam, su propio
OmniRoute. No hay un Efadam ni una base de datos compartida entre
proyectos distintos.

**Por qué (razón dada por Mateo, 18/ago/2026):** el sistema se piensa desde
ahora con la imagen completa — que terceros puedan instalarlo cada uno para
su propio negocio — y porque mezclar el aprendizaje de negocios sin relación
bajo un mismo Efadam/`knowledge_log` lo revuelve. Negocios afines y con
operación parecida (ej. Bintix + TalentIA) sí pueden vivir en el mismo
despliegue si compartir aprendizaje ayuda; un negocio sin relación (ej. uno
de música) va en un despliegue aparte.

**Por qué esto no revive el problema de "replicar cada cambio a mano"**
(objeción inicial de Claude, resuelta en la conversación): una vez que el
producto está empaquetado, cada instalación se actualiza jalando la
versión más nueva del repo/template (git tag + `docker compose pull` +
migraciones), como cualquier software self-hosted — no hace falta un
mecanismo de sincronización en vivo entre instalaciones ni reconstruir
workflows a mano por instancia. Esto es exactamente lo que ya se descartó
una vez (ver "Por qué se abandonó la sincronización recurrente por API de
GitHub" en `memoria_del_sistema.md`) y no hay que repetirlo: la unidad de
actualización es "instalar la versión N", no "sincronizar en vivo".

**Lo que este rediseño simplifica:** ya no hace falta la tabla `proyectos`
ni el parámetro de schema dinámico en cada nodo de Postgres del ejecutor —
cada instalación tiene un solo schema fijo. El riesgo técnico que el diseño
anterior sí tenía ("confirmar que los workflows no tienen el schema
hardcodeado, o migrarlos") desaparece.

**Lo que queda pendiente de definir (no ahora, anotado para cuando toque):**
1. Estrategia de versionado/actualización del template (tags, changelog,
   convención de migraciones — ya existe el patrón numerado en `schema/*.sql`,
   falta decidir si son idempotentes y cómo se aplican en una instalación
   nueva vs. una que actualiza).
2. Si OmniRoute también va per-instancia (probable, coherente con "cada
   quien trae sus propias llaves de proveedor" ya documentado en
   `memoria_del_sistema.md`) o si Mateo lo sigue centralizando para sus
   propios despliegues.
3. El proceso de instalación real (script + `.env.example` ya existe como
   semilla, falta el resto).

**Estado:** sigue siendo visión, no se construye todavía (post Fase 1).

**Advertencia de secuencia (importante):** la auditoría técnica del
17/ago/2026 (`docs/auditoria_tecnica_y_vision_17ago2026.md`) recomienda
explícitamente **congelar el trabajo de distribución a terceros hasta
cerrar los Hallazgos críticos y altos** (contraseña de Postgres expuesta en
el historial de git, inyección SQL en el ejecutor, pérdida de
`nivel_importancia` en tareas hijas, aprobaciones humanas sin flujo de
respuesta, Reanudador de bloqueados con referencia rota). Esta sección deja
registrada la decisión de diseño para no perderla, pero construirla en
serio compite directamente con esa recomendación de orden. Confirmar con
Mateo si se mantiene ese orden (cerrar Bloques 0 y 1 primero) antes de
invertir tiempo real en empaquetado.
