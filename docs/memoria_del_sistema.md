# Memoria del sistema — diseño

Fecha: 14 de agosto de 2026. Reemplaza la nota de memoria del
`plan_de_accion_completo.md` del mismo día, que dejaba tres cosas sin resolver
(de dónde sale el contenido, a quién se le inyecta, y quién puede escribir).

## El problema que resuelve

Un bot que corre en el ejecutor genérico no sabe nada del sistema en el que
vive: no sabe qué tablas hay, qué convenciones aplican, ni qué ya falló antes.
Cada corrida empieza de cero. Sin memoria, Trouble shooter re-diagnostica el
mismo error cada semana y Coder propone soluciones que contradicen decisiones
ya tomadas.

## Dos tablas, porque son dos cosas distintas

### `system_knowledge` — autoconciencia

Qué es el sistema: arquitectura, stack, convenciones, reglas generales.
Cambia poco. Es corto a propósito.

**Fuente de verdad: los archivos `docs/context/*.md` del repo, no la tabla.**
La tabla es una copia sincronizada. Esto importa: si se escribiera directo en
Postgres, tendríamos la arquitectura documentada en dos lugares (los `.md` del
repo y la BD) y garantizado que se van a contradecir. Un humano edita markdown,
un workflow lo sube. Nunca al revés.

Archivos canónicos:

| slug | archivo | contenido |
|---|---|---|
| `arquitectura` | `docs/context/arquitectura.md` | ramas, bots, aprobaciones |
| `stack_y_convenciones` | `docs/context/stack_y_convenciones.md` | infra, tablas, lean/robusto, gotchas |
| `reglas_generales` | `reglas_generales.md` | las 5 reglas que van dentro de cada system_prompt |

Regla de escritura para estos archivos: **presente, hechos, sin historia**.
El porqué de cada decisión y su narrativa siguen viviendo en
`arquitectura_general.md`, `plan_de_accion_completo.md` y
`contexto_proyecto_infinite_power_v6.md` — esos son para humanos y NO se
inyectan a ningún bot (son demasiado largos y están llenos de decisiones
revertidas que confundirían al modelo).

### `knowledge_log` — bitácora de casos

Qué le ha pasado al sistema. Crece constantemente. **Efadam es el dueño por
default de la escritura**, sin excepción, aunque se sienta como cuello de
botella — es intencional, es la razón por la que el sistema aprende de forma
centralizada en vez de que cada bot acumule su propio silo aislado.

| tipo | quién escribe | condición |
|---|---|---|
| `aprendizaje` | Efadam, tras el reporte de un center | **default para todo bot nuevo** |
| `patron_fallo` | el ejecutor, automático, desde `patron_aprendido` | solo si `bots.conocimiento_directo = true` |

La única excepción válida a "todo pasa por Efadam" es angosta y explícita, no
por tipo de hallazgo: un bot cuyo conocimiento **no aporta absolutamente nada
fuera del campo exacto en el que ese bot trabaja**. Se controla con la columna
`bots.conocimiento_directo` (default `false` — cualquier bot nuevo pasa por
Efadam salvo que se justifique explícitamente lo contrario, caso por caso).

Hoy solo `trouble_shooter` califica: sus patrones son errores de
infraestructura (n8n, Postgres, Docker, encoding) que nunca le van a importar
a Legal ni a Estrategia. La pregunta para justificar cualquier futura
excepción: *"¿hay algún escenario donde otra rama necesitaría saber esto?"* —
si la respuesta no es un "no" rotundo, pasa por Efadam.

Ver `Efadam.md` (Obsidian) para el principio completo, incluida la nota de que
esta corrige una versión anterior de este mismo documento que trataba la
excepción como una regla general por tipo — estaba mal planteada.

### Deduplicación automática

Índice único parcial sobre `lower(titulo)` para `tipo = 'patron_fallo'`.
Si Trouble shooter reporta un patrón con el mismo título, en vez de duplicar se
incrementa `veces_visto`. Esto reemplaza la regla que hoy vive en su prompt
("si el mismo error ya ocurrió 3 o más veces, márcalo como recurrente"), que
depende de que el modelo se acuerde de algo que no tiene forma de saber. Ahora
lo cuenta Postgres y el contador le llega a Trouble shooter en su contexto.

## Cómo se inyecta

Un nodo `Cargar contexto` en el ejecutor genérico, entre "Obtener config del bot"
y "Llamar a OmniRoute", que devuelve dos bloques de texto ya armados.

**No se le inyecta lo mismo a todos.** El diseño anterior decía que
`system_knowledge` se inyecta igual para cada bot. Eso significa que Abogado
Jefe carga el schema de Postgres y los gotchas de n8n en cada dictamen legal:
tokens caros, límite de contexto de los modelos gratis, y ruido que empeora la
respuesta. Se controla con la columna `bots.contexto_slugs text[]`: cada bot
declara qué slugs necesita. Un array vacío es válido y es el default.

Asignación inicial:

| bot | contexto_slugs |
|---|---|
| `tecnico_jefe` | `{arquitectura, stack_y_convenciones}` |
| `coder` | `{stack_y_convenciones}` |
| Legal (cuando entren) | `{}` — no necesitan saber cómo está armado el sistema |

Las reglas generales NO van por aquí: viajan dentro del `system_prompt` de cada
bot, compuestas por un trigger de Postgres a partir de `prompt_especifico`.

## Sincronización repo → tabla

Workflow de n8n **"Sync conocimiento del sistema"**, disparo manual:

1. Manual Trigger.
2. GitHub → *Get file content* para cada archivo de `docs/context/` y para
   `reglas_generales.md` (requiere credencial de GitHub con un PAT, el repo es privado).
3. Postgres → *Execute Query*, un upsert por archivo:

```sql
insert into system_knowledge (slug, titulo, contenido, source_file)
values ($1, $2, $3, $4)
on conflict (slug) do update
   set titulo = excluded.titulo,
       contenido = excluded.contenido,
       source_file = excluded.source_file,
       updated_at = now();
```

Correrlo cada vez que se edite un archivo de `docs/context/`. Si al editar el
prompt de un bot cambia `reglas_generales`, hay que además tocar
`prompt_especifico` de cada bot para que el trigger recomponga:
`update bots set prompt_especifico = prompt_especifico;`

## Lo que este diseño deliberadamente NO hace

- No le da a ningún bot acceso directo de lectura a Postgres. El workflow les
  entrega el contexto ya curado. (Costo y control.)
- No hay banco de conocimiento por center. Se evaluó y se descartó: sería el
  mismo mecanismo repetido tres veces.
- No hay embeddings ni búsqueda semántica. Con menos de 50 filas en
  `knowledge_log`, un `ORDER BY updated_at DESC LIMIT 15` filtrado por cluster
  es suficiente. Revisar esto cuando la tabla pase de ~200 filas.
