# System Knowledge — índice y fuente de verdad

## Qué es

`system_knowledge` es el conocimiento operativo estable de Infinite Power:
arquitectura, stack, convenciones y reglas que los bots necesitan para
entender el sistema antes de trabajar.

No es la memoria de una conversación ni el historial de tareas. Tampoco es
inmutable: cambia con poca frecuencia y de forma deliberada cuando el sistema
aprende algo que aplica más allá de un caso puntual.

## Dónde vive

Hay dos capas con propósitos distintos:

| Capa | Ubicación | Función |
|---|---|---|
| Fuente de verdad viva | tabla `system_knowledge` en Postgres | Contexto que se inyecta a los bots durante la operación del sistema. |
| Seed inicial legible | este vault de Obsidian | Punto de partida versionado para poblar la tabla y referencia humana de diseño. |

El repositorio **no se sincroniza automáticamente** con la tabla. Después del
seed inicial, la tabla puede evolucionar y el vault puede representar una
fotografía histórica. Esto es intencional. El diseño completo está en
[[memoria_del_sistema]].

## Qué no es

- [[memoria_del_sistema]] describe el mecanismo completo y también distingue
  `system_knowledge` de `knowledge_log`.
- `knowledge_log` es la bitácora de casos, fallos y aprendizajes; crece con el
  tiempo.
- `tasks`, `agent_runs` y `operations` son estado operativo en vivo; no son
  conocimiento estable.
- Los prompts son instrucciones específicas de cada bot; pueden consumir
  conocimiento del sistema, pero no lo sustituyen.

## Seed inicial

Estos son los slugs que forman el conocimiento inicial que se carga en la
tabla:

| slug | Nota de Obsidian | Contenido |
|---|---|---|
| `arquitectura` | [Arquitectura](context/arquitectura.md) | Ramas, centros, bots y aprobaciones. |
| `stack_y_convenciones` | [Stack y convenciones](context/stack_y_convenciones.md) | Infraestructura, tablas, convenciones y decisiones técnicas. |
| `reglas_generales` | [[reglas_generales]] | Reglas que aplican a todos los bots. |

## Cómo llega a los bots

El Ejecutor genérico carga solo los slugs declarados por cada bot en
`bots.contexto_slugs`. No todos reciben el mismo contexto.

Asignación inicial:

| Bot | Contexto |
|---|---|
| Efadam | `arquitectura`, `stack_y_convenciones` |
| Técnico jefe | `arquitectura`, `stack_y_convenciones` |
| Coder | `stack_y_convenciones` |
| Bots legales futuros | Ninguno por defecto |

Efadam además puede leer el estado actual de `tasks` y `agent_runs`; eso es
estado vivo, no `system_knowledge`.

## Gobierno de cambios

1. Un hallazgo que puede aplicar al sistema completo llega a Efadam.
2. Efadam pide a Upgrade & Review Center evaluar y redactar la actualización.
3. Efadam inserta o actualiza el contenido aprobado en Postgres.
4. El vault se actualiza cuando sea útil conservar o revisar el cambio de
   diseño; no existe sincronización automática.

La excepción actual es Trouble Shooter: puede registrar directamente patrones
de fallo técnicos en `knowledge_log` cuando `bots.conocimiento_directo` está
habilitado. No puede actualizar `system_knowledge` por esa vía.

## Lectura recomendada

- [[memoria_del_sistema]] — definición, modelo de datos, carga y gobierno.
- [[context/arquitectura|Arquitectura]] — estructura que alimenta el slug
  `arquitectura`.
- [[context/stack_y_convenciones|Stack y convenciones]] — decisiones de
  infraestructura y operación.
- [[reglas_generales]] — reglas universales de comportamiento.
- [[../prompts/_core/efadam|Efadam]] — rol de quien centraliza el acceso y
  mantenimiento del conocimiento.
- [[arquitectura_general]] — explicación humana y narrativa; no se inyecta a
  bots.

## Regla práctica

Si responde a **“¿qué debe saber el sistema para operar coherentemente?”**,
probablemente pertenece a `system_knowledge`.

Si responde a **“¿qué pasó, qué se intentó o qué se aprendió en un caso?”**,
pertenece a `knowledge_log` o al estado de tareas.
