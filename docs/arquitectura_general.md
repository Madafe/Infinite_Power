# Arquitectura general — "Infinite Power"

> Documento **narrativo**, para humanos. Explica el porqué de cada decisión.
> No se inyecta a ningún bot. La versión corta y canónica que sí leen los bots
> es [[arquitectura]] (`docs/context/arquitectura.md`).

## La estructura real (corregida)

El diagrama no es una lista plana de 6 clusters independientes. Es una estructura de **Efadam en el centro + 3 ramas**, cada una con su propio bot "center" que consolida y filtra todo lo que pasa en esa rama antes de que le llegue a Efadam. Los tres "center" son estructuralmente simétricos: cada uno hace para su rama lo mismo que los otros dos hacen para la suya.

```
                        EFADAM
                    (interfaz central)
                          |
        -----------------|-----------------
        |                |                |
   Tech center   Upgrade & review    Proyect center
   (rama Dev/Tech)  center (rama       (rama Operación/
                   Estrategia+Legal+    Proyectos)
                   Investigación)
```

## Las 3 ramas

### Rama 1 — [[Tech center]] (Dev/Tech)

Hub: **Tech center**. Consolida el trabajo técnico y ahora también actúa como el filtro de aprobación final antes de que algo se considere terminado en esta rama (se fusionó con lo que antes tenía mal ubicado como "Upgrade & review center" dentro de Dev/Tech — ver nota de corrección abajo).

Miembros: Prompt perfection, Entrenador Agentes, Coder, Agent builder, Trouble shooter, Ciber seguridad scouter, Hacker ético, Ciber seguridad, Técnico jefe, Tech center.

Flujo interno: Prompt perfection ↔ Entrenador Agentes, Coder → Agent builder, ambos pares alimentan a Técnico jefe junto con Trouble shooter; Ciber seguridad scouter → Hacker ético → Ciber seguridad → Técnico jefe; Técnico jefe → Tech center → Efadam.

### Rama 2 — [[Upgrade & Review center]] (Estrategia/Crecimiento + Legal + Investigación)

Hub: **Upgrade & review center**. Es el bot que revisa y "sube de nivel" (upgrade) lo que produce toda esta rama — ideas, hallazgos de investigación, dictámenes legales — antes de que llegue a Efadam. Recibe directamente de **Cross department**, que es el agregador interno de esta rama (junta lo que producen Legal, Investigación/Skills y parte de Estrategia antes de pasarlo hacia arriba).

Miembros:
- **Estrategia/Crecimiento:** Establecer metas, Planner, Nuevos departamentos, Especialista en organización y métodos, Buscador de áreas de oportunidad, Out of the box thinker, Optimizador, Council (Counsil), Cross department, Automatizador.
- **Investigación/Skills:** Investigador, Skill finder (Youtube/Github/Reddit/Instagram), Observador de patrones replicables, Skill finder (genérico).
- **Legal:** Abogado Scouter, Abogado Jefe, Abogado verificador.

Flujo interno (aproximado): Investigador ↔ Skill finder ↔ Observador de patrones replicables ↔ Skill finder (genérico) → Automatizador; Abogado Scouter ↔ Abogado Jefe ↔ Abogado verificador → Investigador; todo esto converge en **Cross department**, que también recibe de Out of the box thinker; Cross department ↔ Especialista en organización y métodos ↔ Buscador de áreas de oportunidad ↔ Optimizador → Council; Establecer metas → Planner → Nuevos departamentos (con Planner también retroalimentando hacia Upgrade & review center); Cross department → **Upgrade & review center** → Efadam.

### Rama 3 — [[Proyect center]] (Operación/Proyectos)

Hub: **Proyect center**. Consolida el estado operativo de los proyectos/negocios y lo sube a Efadam.

Miembros: Proyectos, Tracker de clientes, Front end, Consultor negocios, Task manager, Ventas ideas, Expansión ideas, Mentor, Establecer Metas, Planner.

Flujo interno: Proyectos → Tracker de clientes → Proyect center (y Front end también alimenta a Proyect center); Expansión ideas → Ventas ideas → Task manager ↔ Consultor negocios ↔ Mentor → Proyect center.

> **Corrección 14/ago/2026:** este documento decía antes que Establecer Metas y
> Planner eran "nodos compartidos con la Rama 2". Es incorrecto — cada
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
