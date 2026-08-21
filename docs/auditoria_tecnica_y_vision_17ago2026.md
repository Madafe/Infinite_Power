# Auditoría técnica y de visión — Efadam

> **Fecha:** 17 de agosto de 2026  
> **Alcance:** repositorio, workflows exportados de n8n, esquema SQL, Docker Compose, documentación, prompts y roster.  
> **Límite:** auditoría estática. Docker, Postgres y n8n en vivo no pudieron verificarse desde este entorno.

## Resumen ejecutivo

Efadam tiene una visión diferenciada: convertir una petición del dueño en trabajo ejecutado, revisado, trazable y mejorable. El ejecutor genérico, la memoria compartida, los esfuerzo y la autonomía gradual son una base razonable.

Hoy sigue siendo un **prototipo manual**, no un sistema autónomo listo para operar tareas reales de manera sostenida. El riesgo principal no es la falta de más agentes: son los huecos entre decisión, ejecución, aprobación, reanudación y aprendizaje.

**Dictamen:** cerrar los hallazgos críticos antes de ampliar el roster o activar Efadam. Después, validar el núcleo mínimo durante dos semanas de uso real.

## Lo que ya está bien

- Un único workflow despacha por configuración de bots; agregar un bot no exige duplicar workflows.
- La cola usa FOR UPDATE SKIP LOCKED, que evita que dos ejecuciones reclamen la misma tarea.
- La documentación distingue contexto canónico, narrativa y archivo.
- .env está ignorado, existe una plantilla de variables y los workflows están versionados.
- Los dos workflows son JSON válido, el script de backup tiene sintaxis válida, los textos versionados son UTF-8 y no hay wikilinks rotos.
- El roster XLSX actualizado refleja Jarvis + Efadam + tres ramas y el estado de activación actual.

## Hallazgos críticos

### C1. La contraseña actual de Postgres está expuesta en el historial Git

La contraseña actual aparece en los commits a14ed39 y e87fe0a. El commit original sigue siendo alcanzable desde todas las ramas remotas: main, efadam, correcciones, alphav0.1 y alphav0.2. Mover el valor a .env evitó nuevas filtraciones, pero no elimina las anteriores.

**Impacto:** cualquier persona con acceso presente o pasado al repositorio, o a un clon anterior, puede acceder a la base si el servicio está expuesto.

**Acción inmediata:**

1. Generar una contraseña nueva y cambiarla en Postgres con ALTER USER.
2. Actualizar el .env local con la misma contraseña nueva.
3. Reiniciar los servicios que usan esa conexión y verificar acceso.
4. Coordinar reescritura del historial remoto. Rotar primero; limpiar historial después.

> Cambiar solo POSTGRES_PASSWORD en .env no modifica automáticamente un usuario ya inicializado en el volumen de Postgres.

### C2. Inyección SQL desde el campo bot

Obtener config del bot construye una consulta con interpolación directa:

~~~sql
SELECT * FROM bots WHERE slug = '{{ $json.bot }}' AND active = true LIMIT 1;
~~~

El valor puede venir de una tarea hija generada por un modelo. Un valor con comillas puede alterar la consulta.

**Acción:** reemplazar por slug = $1 y enviar el valor mediante queryReplacement. Ningún dato de tarea o salida de modelo debe formar parte literal de SQL.

### C3. Se pierde el esfuerzo en las tareas hijas

Efadam debe decidir bajo, medio, alto o critico al despachar. Sin embargo, Parsear asignaciones no conserva esfuerzo y Crear tareas hijas no lo inserta. La siguiente llamada a OmniRoute recibe null como modelo.

**Impacto:** se rompe el control de coste/calidad y una tarea legal, pública o de seguridad puede no usar el nivel exigido.

**Acción:** incluir, validar e insertar esfuerzo en toda asignación. Agregar NOT NULL para tareas nuevas o un respaldo que nunca rebaje una tarea ambigua.

### C4. No se completa una aprobación ni una aclaración humana

El ejecutor está inactivo y parte de un disparador manual. Cuando un bot requiere aprobación, se guarda needs_approval y se manda un mensaje a Telegram, pero no existe un flujo versionado que registre aprobar/rechazar, cree una fila en approvals o continúe/rechace la tarea. Las aclaraciones de tareas de primer nivel también terminan en Telegram sin una ruta de respuesta.

**Impacto:** una tarea sensible queda detenida indefinidamente. Las aprobaciones humanas son una notificación saliente, no un control operativo.

**Acción:** crear un flujo de decisiones humanas con identificador de tarea, opciones explícitas, validación del remitente, registro en approvals y transición de estado atómica. Activar el ejecutor solo cuando este circuito esté probado de punta a punta.

## Hallazgos altos

### A1. Prompt injection entre agentes

El input.text de una tarea padre se inserta como mensaje system en la tarea hija. Texto creado por un usuario o por otro modelo recibe así privilegio de instrucción del sistema.

**Acción:** pasar el contexto heredado como contenido de usuario o datos delimitados y explícitamente no confiables. Separar reglas del bot, contexto confiable y texto de trabajo no confiable.

### A2. Reanudador de bloqueados defectuoso y ambiguo

El manejador de error de Reanudador de bloqueados referencia el nodo Reclamar tarea pendiente, inexistente en ese workflow. Además, su consulta puede empatar varias aclaraciones hijas terminadas para un mismo padre; no se garantiza cuál se aplicará.

**Acción:** eliminar la referencia cruzada, seleccionar solo la aclaración más reciente pendiente de consumir y marcarla como consumida dentro de una transacción. Probar dos rondas de aclaración sobre la misma tarea.

### A3. Fan-out sin límites ni transacciones

Un dispatcher puede crear cualquier número de tareas, sin límite de profundidad, presupuesto, tasa ni validación del destino. El padre se guarda como terminado antes de que todas las hijas se creen. Un error posterior puede dejar hijas ejecutables de un padre fallido.

**Acción:** definir límites de profundidad, cantidad de hijos y coste; validar destinos permitidos/activos; crear hijas y cerrar al padre en una unidad atómica o con compensación explícita.

### A4. Servicios expuestos y versiones no reproducibles

Docker Compose publica Postgres, n8n y OmniRoute sin restringir la interfaz, y usa imágenes latest.

**Acción:** enlazar puertos a 127.0.0.1 mientras sea una instalación local, fijar versiones o digest, añadir healthchecks y esperar a que Postgres esté saludable antes de iniciar n8n.

## Hallazgos medios

### M1. Reproducibilidad incompleta

El esquema se aplica manualmente y no hay inicialización automatizada de un clon nuevo. Las migraciones tampoco usan transacciones, por lo que un fallo puede dejar una base parcialmente modificada.

**Acción:** establecer bootstrap reproducible, registro de migraciones y transacciones cuando sea posible.

### M2. Backup útil, pero insuficiente para recuperación real

El backup permanece en el mismo disco, depende de un nombre fijo de contenedor y no hay una prueba automática de restauración.

**Acción:** copiar cifradamente fuera de la máquina, usar docker compose exec y probar restauración mensual.

### M3. Documentación con deriva

INICIO.md todavía menciona 19 nodos aunque el workflow tiene 22. estado_del_proyecto.md afirma que el roster no está versionado, pero el archivo actualizado sí está en el repositorio.

**Acción:** generar o comprobar datos de activación, versiones de workflows y roster desde fuentes verificables.

### M4. Sin pruebas ni integración continua

Los cambios en JSON de n8n y SQL se detectan hasta la operación manual.

**Acción:** incorporar pruebas de contrato, validación de JSON/SQL/Compose y un escenario end-to-end sobre una base desechable.

## Visión: de 8/10 a 10/10

La visión debe definirse por el resultado del dueño, no por la cantidad de bots:

> **Efadam es un sistema operativo de trabajo para dueños de pequeños negocios. Convierte objetivos expresados en lenguaje natural en resultados ejecutados, revisados y trazables mediante equipos de agentes especializados. Aprende de cada tarea sin modificar sus reglas de forma silenciosa y aumenta su autonomía únicamente cuando demuestra que puede actuar dentro de límites claros, reversibles y medibles.**

Promesa operativa:

> **Tú defines el resultado. Efadam organiza el trabajo, lo ejecuta y te pide atención únicamente cuando tu decisión realmente importa.**

Para completar esa visión, hay que fijar:

1. **Usuario inicial:** primero Mateo y sus negocios; terceros después de demostrar valor repetible.
2. **Unidad de valor:** resultado terminado, no bot creado.
3. **Diferenciador:** trazabilidad, memoria operativa aprobada, controles humanos y aprendizaje de fallos.
4. **Autonomía observable:** recomienda → prepara → ejecuta con aprobación → ejecuta y notifica → opera solo dentro de límites reversibles.
5. **Límites no negociables:** no gastar, publicar, firmar, borrar datos ni modificar seguridad sin autorización explícita.
6. **Aprendizaje gobernado:** incidente → revisión → aprendizaje propuesto → aprobación → regla versionada → prueba de regresión.
7. **Métrica principal:** porcentaje de resultados aceptados sin retrabajo por hora humana invertida.

## Núcleo mínimo a validar

Durante las próximas dos semanas, reducir la arquitectura a:

~~~text
Tú / Telegram
      ↓
    Efadam
      ↓
Técnico jefe
   ↙      ↘
Coder   Trouble shooter
      ↓
Revisión humana
~~~

No añadir otro agente hasta que este circuito complete trabajo real de forma confiable.

### Métricas

- Porcentaje de tareas finalizadas sin intervención manual.
- Porcentaje de resultados aceptados sin retrabajo.
- Tiempo humano ahorrado frente al proceso manual.
- Coste por tarea aceptada.
- Tareas bloqueadas, mal enrutadas o reintentadas.
- Patrones de fallo que evitaron una repetición posterior.

### Criterios de salida

El núcleo puede ampliarse cuando, durante dos semanas de uso real:

- las tareas sensibles siempre se detienen en una aprobación funcional;
- no hay tareas perdidas, duplicadas ni bloqueadas sin ruta de salida;
- cada despacho conserva esfuerzo, padre e historial;
- cada fallo deja diagnóstico o ruta de corrección verificable;
- el resultado aceptado sin retrabajo mejora frente a la línea base manual;
- coste y latencia quedan dentro de un límite acordado.

## Plan de remediación

### Bloque 0 — Contención inmediata

1. Rotar la contraseña de Postgres y planificar limpieza de historial.
2. Parametrizar todas las consultas que consumen datos de tareas/modelos.
3. Limitar servicios a localhost y fijar imágenes Docker.

### Bloque 1 — Corregir el flujo crítico

1. Propagar y validar esfuerzo.
2. Implementar decisión humana bidireccional y reanudación de tareas.
3. Corregir el reanudador y cubrir aclaraciones repetidas.
4. Separar instrucciones de sistema de contenido no confiable.
5. Añadir límites de profundidad, fan-out y coste.

### Bloque 2 — Operación verificable

1. Añadir bootstrap y migraciones reproducibles.
2. Crear pruebas de contrato y un escenario end-to-end desechable.
3. Activar un disparador programado solo tras completar pruebas.
4. Ensayar restauración de un backup.

### Bloque 3 — Validación de producto

1. Operar el núcleo mínimo con trabajo real durante dos semanas.
2. Registrar las métricas anteriores.
3. Eliminar, fusionar o posponer bots que no mejoren una métrica.
4. Expandir a la siguiente rama únicamente cuando el núcleo demuestre valor.

## Decisión recomendada

Congelar la expansión del roster y el trabajo de distribución para terceros hasta cerrar los Bloques 0 y 1. La siguiente victoria no es activar muchos agentes: es demostrar que una solicitud real llega a un resultado aceptado, con coste controlado, aprobación funcional, trazabilidad y recuperación segura.

