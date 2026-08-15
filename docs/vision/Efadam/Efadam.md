# Efadam

Bot cabeza del sistema. Único punto de enrutamiento entre Setup (Proyect center), los jefes de cada rama (Técnico jefe, Abogado Jefe, etc.) y la memoria del sistema.

Responsabilidades:
- Recibe el resultado del Setup (meta + lista de pasos) y decide a qué jefe(s) le corresponde cada parte.
- Inyecta en cada jefe el contexto y las instrucciones específicas que necesita para esa tarea.
- Dueño **por default** de la escritura en `knowledge_log` — detecta patrones (a evitar o replicar) y los guarda.
- Compara cada tarea nueva contra su base de conocimiento antes de despachar, para no repetir errores ya identificados.

## Excepción angosta a "Efadam escribe todo" (decidido 14/ago/2026, noche)

La prioridad sigue siendo que todo pase por Efadam, **incluso cuando se sienta como cuello de botella o complicado de más** — esa fricción es intencional, es la razón por la que el sistema aprende de forma centralizada.

Existe una única forma válida de que un bot escriba directo a `knowledge_log`, sin pasar por Efadam: que su conocimiento **no aporte absolutamente nada fuera del campo exacto en el que ese bot trabaja**. No es una excepción por "tipo" de hallazgo (no es "todos los errores técnicos se saltan a Efadam") — es una excepción explícita, opt-in, por bot individual, y se espera que sea rara.

Mecanismo: columna `bots.conocimiento_directo` (default `false`). Cualquier bot nuevo empieza en `false` — pasa por Efadam salvo que se justifique explícitamente lo contrario, caso por caso.

**Único bot que califica hoy: Trouble shooter.** Sus patrones son errores de infraestructura (n8n, Postgres, encoding, Docker) — nunca le van a servir a Legal, a Estrategia, ni a ningún otro dominio del negocio. Por eso, y solo por eso, sus `patron_fallo` se insertan automáticamente vía el ejecutor, sin pasar por Efadam.

Cualquier bot futuro que parezca candidato a esta excepción debe justificarse con la misma pregunta: *¿hay algún escenario donde otra rama necesitaría saber esto?* Si la respuesta no es un "no" claro y rotundo, pasa por Efadam.

**Principio de jerarquía:** ningún otro bot puede saltarse a Efadam para hablarle directo a otra rama. No es una limitación técnica, es la razón por la que el sistema aprende — si un bot dispara a otro directamente, Efadam nunca se entera y no hay aprendizaje ni contexto inyectado.

Nota de estado (14/ago/2026): Efadam todavía no existe como bot activo en la tabla `bots` — solo están `tecnico_jefe`, `coder` y `trouble_shooter`, probando el patrón dentro de una sola rama (Dev/Tech). Mientras Efadam no exista, Técnico jefe recibe tareas directo, no vía Efadam. Esto es temporal y aceptado para la fase de prueba — no es el diseño final.

Pendiente: definir la cadencia/trigger exacto con el que Efadam revisa proyectos activos (ver Infinite power.md > Método > Multiproyecto).
