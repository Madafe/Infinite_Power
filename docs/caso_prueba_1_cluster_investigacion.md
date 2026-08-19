# Caso de prueba 1 — Cluster Investigación/Skills

> Vigente — usar como referencia real al escribir los prompts de Investigación,
> Skill finder, Observador de patrones replicables y Automatizador (rama
> Estrategia, siguiente en el orden de construcción).

## Por qué existe este archivo

Al discutir si convenía agregar los proyectos "Automaton" y "Ponytail" al sistema, Mateo notó que ese mismo proceso de discusión —investigar, comparar, detectar patrones, decidir— es exactamente lo que debería hacer el cluster **Investigación/Skills** (Investigador → Skill finder → Observador de patrones replicables → Automatizador) de forma autónoma. Este archivo documenta ese intercambio como el primer caso de prueba real de la plantilla de la Fase 1, para usarlo como referencia al escribir los prompts de ese cluster.

## El caso, paso a paso

1. **Input inicial:** "¿Qué opinarías de agregar el proyecto de Automaton conectado a este sistema?" — sin más contexto, nombre ambiguo.
2. **Investigador:** búsqueda en ClickUp (sin resultado) y luego en la web de "Automaton" + señales de contexto (opencode, Codex, Claude instalados) para encontrar el proyecto correcto: `appautomaton/automaton`.
3. **Skill finder (Github):** revisión directa del repo — README, estrellas, forks, propósito.
4. **Evaluación / Cross department:** conexión de lo encontrado con las reglas ya existentes del sistema (aprobación humana, contención, presupuesto) para dar una recomendación situada, no genérica.
5. **Corrección del usuario:** "Ese no es, es este otro: `Conway-Research/automaton`." — mismo nombre, proyecto completamente distinto.
6. **Investigador (segunda pasada):** researched el repo correcto, encontrando que es una IA autónoma con wallet cripto, auto-replicación y auto-modificación sin aprobación humana.
7. **Observador de patrones replicables:** detectar que el riesgo no estaba en "que decida por sí mismo" sino en los mecanismos concretos (wallet real, autoreplicación con fondeo automático) — y que ese patrón de riesgo se repite independientemente del proyecto puntual.
8. **Discusión/negociación:** el usuario defendió la parte de auto-modificación como aceptable si el radio de daño es reversible (restart/revert). Se llegó a una síntesis: autonomía total sobre sí mismo + aprobación humana solo para acciones externas/irreversibles.
9. **Automatizador (resultado accionable):** la conclusión se formalizó como el diseño de autonomía del bot "Out of the box thinker" en el roster.
10. **Segunda ronda — Skill finder aplicado a "Ponytail":** mismo patrón, esta vez con un skill de estilo de código en vez de un framework de orquestación.
11. **Tercera ronda — pedido explícito de "encuentra algo similar pero más probado":** esto es el Automatizador/Skill finder funcionando en modo "reemplazo": buscar una alternativa madura (GitHub Spec Kit) cuando la primera opción no calificó, comparar señales de madurez (estrellas, quién lo mantiene, adopción real) y entregar una recomendación de reemplazo lista para ejecutar.

## Patrones replicables detectados (para el prompt de "Observador de patrones replicables")

- Cuando un nombre de proyecto es ambiguo, buscar primero en fuentes internas (ClickUp) y luego en la web, usando el contexto del stack propio (qué herramientas ya usan) para desambiguar.
- Señales de madurez a revisar siempre antes de recomendar adoptar un proyecto externo: quién lo mantiene (organización vs. autor único), estrellas/forks, si tuvo que corregir públicamente sus propias afirmaciones (buena señal si lo hizo con transparencia), y compatibilidad real con el stack ya definido.
- Un riesgo detectado en un proyecto rara vez está en "tiene autonomía" en abstracto — casi siempre está en un mecanismo concreto y aislable (ej. una wallet real, escritura fuera de su propio sandbox). Aislar ese mecanismo permite rescatar la idea de fondo sin adoptar el riesgo completo.
- Cuando algo no califica, el siguiente paso natural no es descartar la necesidad, es buscar el equivalente más maduro para la misma necesidad.

## Cómo usarlo

Al escribir el prompt de sistema de Investigador, Skill finder, Observador de patrones replicables y Automatizador, usar este caso como el primer "caso de prueba" de la plantilla estándar (ver [[plantilla_prompt]]), y los "patrones replicables" de arriba como ejemplos concretos de qué debe poder detectar el Observador.
