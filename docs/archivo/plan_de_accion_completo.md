# Plan de acción completo — "Infinite power"
### Sistema de agentes autogestionado para el negocio

Para: Mateo · 7 de agosto de 2026 (proyecto individual — ver nota del 17 de agosto, noche, sobre la baja del cofundador)

---

## Actualización — 17 de agosto de 2026, noche (conexión de proveedores en OmniRoute, hallazgos de riesgo, backup de datos, y Mateo confirma que el proyecto es individual) — VIGENTE, léase primero

Continuación de la sesión de la tarde (ver actualización inmediatamente
abajo, ahora marcada "vigente" sin ser la más reciente). Mateo dio 3
instrucciones: (1) conectar Pollinations, Cloudflare AI y Qwen en
OmniRoute; (2) borrar toda referencia al amigo/cofundador en los
documentos del proyecto — es un proyecto individual, no hay cofundador;
(3) seguir con los siguientes pasos hasta necesitar una decisión real de
Mateo.

### Sobre el amigo/cofundador

Se eliminaron las referencias activas/futuras: checklist de Fase 0, tabla
de reparto de responsabilidades, el pendiente "agregar al amigo como
colaborador del repo", `estado_del_proyecto.md`, y el prompt de Efadam en
`prompts/_core/efadam.md` (este último importa porque es contenido que
Efadam lee en producción, no solo un documento humano). **No se tocaron**
`docs/archivo/plan_de_accion.md` ni
`docs/archivo/contexto_proyecto_infinite_power_v5.md` — son versiones
archivadas y superadas (por este documento y por
`contexto_proyecto_infinite_power_v6.md` respectivamente); reescribir un
documento archivado para que diga algo distinto de lo que decía en su
momento sería falsificar el registro histórico, no corregirlo. Si Mateo
prefiere que también se borren ahí, se hace — por ahora se trató como
fuera del alcance de "el plan" vigente.

### Investigación de los 3 proveedores pedidos

**Pollinations — sin objeciones, listo para conectar.** El código
(`open-sse/executors/pollinations.ts`) apunta a un endpoint oficial,
formato OpenAI estándar (`https://gen.pollinations.ai/v1/chat/completions`),
sin ninguna bandera de riesgo.

**Cloudflare AI — contradicción real entre la guía de OmniRoute y el
código, sin resolver todavía.** `FREE-TIERS-GUIDE.md` lo lista como Tier 1
("no auth needed"), pero el ejecutor real
(`open-sse/executors/cloudflare-ai.ts`) exige un Bearer API Token y un
Account ID reales, obtenidos desde una cuenta de Cloudflare
(`dash.cloudflare.com/profile/api-tokens`). Es gratis, pero no es "cero
fricción" como decía la guía — hace falta que Mateo tenga o cree una
cuenta de Cloudflare y genere un token. **Pendiente de decisión de
Mateo:** ¿crea la cuenta/token para conectarlo ahora, o se pospone
Cloudflare y se avanza solo con Pollinations por el momento?

**Qwen — hallazgo de riesgo real, no se conectó, necesita decisión
explícita de Mateo antes de tocarlo.** El ejecutor
(`open-sse/executors/qwen-web.ts`) no usa una API oficial de Alibaba: hace
scraping del chat de consumidor `chat.qwen.ai`, replicando una cookie jar
completa de una sesión real logueada más un bearer token, para evadir el
WAF anti-bot de Alibaba ("baxia"). El propio comentario del código lo
compara explícitamente con `gpt4free` y `Chat2API` — proyectos conocidos
de ingeniería inversa no oficial, en zona gris de los términos de
servicio. OmniRoute tiene incluso un sistema dedicado de detección de
baneo (`docs/security/BAN_DETECTION.md`) con un estado terminal "banned"
(1 año de enfriamiento, sin recuperación automática) — evidencia de que el
riesgo de baneo de cuenta es real y conocido por los propios
desarrolladores de OmniRoute, no una posibilidad remota. Esto no es lo que
"conectar Qwen" sonaba que era (un proveedor gratis más del catálogo): es
replay de sesión de un producto de consumo real, con riesgo real de que
esa cuenta quede baneada permanentemente. No se conectó. Queda pendiente
que Mateo confirme, con esta información en mano, si de todos modos
quiere proceder — y con qué cuenta de Qwen, dado que el riesgo de baneo
recae sobre esa cuenta específica.

### Hallazgo adicional: OmniRoute no tiene contraseña configurada, y no es "CHANGEME"

El plan anterior (ver "Pendientes de Bloque 2" más abajo) asumía que la
contraseña default del dashboard era literalmente `CHANGEME`, según un log
de bootstrap. Verificado en vivo: `POST /api/auth/login` con `CHANGEME`
devuelve `{"error":"No password configured. Complete onboarding
first.","needsSetup":true}` — no hay ninguna contraseña utilizable
todavía. OmniRoute exige completar un asistente de onboarding en
`/dashboard/onboarding` (confirmado leyendo `login/page.tsx` y
`login/route.ts`) antes de poder loguearse por primera vez; ese asistente
es la única vía real para fijar la contraseña inicial, no hay endpoint de
API documentado ni valor por defecto real que sirva. Además
`login/route.ts` falla directo (500) si `process.env.JWT_SECRET` no está
seteado como variable de entorno real del proceso (distinto del
`server.env` que OmniRoute ya generó solo dentro de `/app/data`) — fijar
`JWT_SECRET` en `docker-compose.yml`/`.env` sigue siendo necesario aparte
del onboarding.

### Backup de `/app/data` ya hecho, antes de tocar nada

Antes de arreglar el volumen mal montado (`/app/config` en vez de
`/app/data`, ver hallazgo de la tarde más abajo), se respaldó en frío el
contenido real del contenedor (`storage.sqlite`, `server.env` con los
secretos ya generados, logs de llamadas del 11 al 17 de agosto) a
`data/omniroute_data_backup_17ago2026.tar.gz` (638 KB comprimido) dentro
del repo local. **No comiteado a propósito** — son datos/secretos reales,
no deben subirse a git; queda en el filesystem local, o se mueve a un
backup fuera del repo si Mateo prefiere. Esto es puramente preventivo:
todavía no se tocó `docker-compose.yml` ni se recreó el contenedor.

### Qué falta, sin necesitar más decisiones de Mateo (técnico)

1. Arreglar `docker-compose.yml`: volumen de OmniRoute de `/app/config` a
   `/app/data`, y agregar `JWT_SECRET`/`API_KEY_SECRET`/
   `STORAGE_ENCRYPTION_KEY` como variables de entorno explícitas
   (reusando los valores que OmniRoute ya generó solo en
   `/app/data/server.env`, mismo patrón de "reusar en vez de rotar" que
   `N8N_ENCRYPTION_KEY` en Bloque 0).
2. Recrear el contenedor y confirmar que los datos sobreviven una segunda
   recreación (la prueba real de que el volumen quedó bien montado).
3. Conectar Pollinations una vez el dashboard sea accesible.

### Qué necesita decisión de Mateo antes de seguir

- **Contraseña del dashboard de OmniRoute:** el asistente de onboarding la
  va a pedir — ¿la define Mateo, o autoriza que se genere una segura y se
  le entregue?
- **Cloudflare AI:** ¿cuenta/token propio ahora, o se pospone?
- **Qwen:** ¿proceder de todos modos con el riesgo de baneo explicado
  arriba, con qué cuenta, o se descarta?

---

## Actualización — 17 de agosto de 2026, tarde (revisión de la auditoría técnica y de visión, vía Cowork) — vigente

Mateo compartió una auditoría externa nueva, independiente de la del 16 de
agosto (`docs/auditoria_tecnica_y_vision_17ago2026.md`), con hallazgos
técnicos (C1–C4 críticos, A1–A4 altos, M1–M4 medios) y una sección
estructural/de visión. Por instrucción de Mateo esta ronda se enfocó solo
en la parte estructural/visión — los hallazgos técnicos quedan pendientes
de revisión aparte, no descartados.

**Verificación, no aceptación a ciegas.** Antes de aceptar nada de la
auditoría se verificó contra el estado real del repo (git real, vía
Desktop Commander):

- La afirmación de la auditoría de que "el roster XLSX actualizado refleja
  Jarvis + Efadam + tres ramas" **es correcta** — confirmado con `git log`
  y lectura directa del Excel: se corrigió y se commiteó por primera vez
  el 17 de agosto (commit `49b89fd`). Eso dejó desactualizado un pendiente
  de `estado_del_proyecto.md` que seguía diciendo lo contrario — corregido
  ahí también en esta ronda.
- La "Decisión recomendada" de la auditoría — congelar el roster **y el
  trabajo de distribución para terceros** hasta cerrar sus Bloques 0–1 —
  se reformuló: la parte de "congelar distribución para terceros" chocaba
  con la decisión explícita de Mateo del 16 de agosto de no congelar el
  alcance de producto distribuible (ver actualización de esa fecha, más
  abajo). En la práctica no hay trabajo activo de empaquetado que congelar
  (pendiente #11 de la lista de abajo sigue en diseño, sin implementar).
  Se descarta la palabra "congelar"; queda como lo que ya es de por sí: el
  pendiente #11 no empieza a implementarse hasta que cierren los hallazgos
  críticos de seguridad/confiabilidad, sin que eso implique pausar el
  diseño de producto distribuible.
- Mateo asumía que los Bloques 0, 1 y 2 de la auditoría del 16 de agosto
  (la que se viene remediando en este mismo documento, no la nueva) ya
  estaban cerrados. Se verificó con `git log`: **Bloque 0 y Bloque 1, sí.
  Bloque 2, no** — arrancó hoy mismo (ver la actualización de Bloque 2
  inmediatamente abajo) y está bloqueado en un hallazgo real de
  infraestructura, con una pregunta sin responder de Mateo (qué
  proveedor/llave conectar primero en OmniRoute). Corregido en
  `estado_del_proyecto.md`.
- Los 3 hallazgos críticos de la auditoría del 17 de agosto que hoy **no**
  están cubiertos por la secuencia de Bloque 2 — contraseña de Postgres
  expuesta en el historial de git (C1), inyección SQL en el nodo "Obtener
  config del bot" (C2), y el flujo de aprobación humana que hoy es solo
  una notificación saliente sin ruta de respuesta (C4) — se agregan a
  "Pendientes de Bloque 2, en secuencia" más abajo, antes del punto que
  inserta a Efadam: no tiene sentido activar el cerebro de orquestación
  encima de esos tres huecos. `nivel_importancia` (C3) ya estaba cubierto
  por el punto 8 existente.
- Se descarta el gate de "validar 2 semanas" que proponía la auditoría
  antes de construir la siguiente rama. Decisión de Mateo: el tiempo
  transcurrido no es la unidad correcta para validar un cluster — dos
  semanas con 3 tareas reales no dicen nada y dos semanas con 300 sí. Se
  corrigió el mismo patrón de criterio-por-tiempo en
  `docs/autonomia_progresiva.md` (el checklist de graduación de autonomía
  por cluster, que también usaba "2 semanas") y en la Fase 5 de este mismo
  documento (que duplicaba ese checklist) — reemplazado por un criterio de
  volumen de tareas reales, todavía sin número exacto: se calibra cuando
  haya datos reales de cuánto trabajo mueve cada cluster.
- **Aclaración de visión:** la frase de la auditoría "sistema operativo de
  trabajo para dueños de pequeños negocios" no fija un segmento de mercado
  nuevo — Mateo la confirma como forma de decir que el sistema no está
  pensado para operaciones grandes que necesiten mucha más capacidad de
  análisis o logística, sino para uso personal o negocios pequeños.
  Reflejado en `estado_del_proyecto.md`, sección "Qué es".

---

## Actualización — 17 de agosto de 2026 (Bloque 2, primer hallazgo real: schema de combos confirmado + 4 problemas de infraestructura en OmniRoute sin resolver) — vigente

Empezó Bloque 2 ("pasamos con el bloque 2", instrucción de Mateo). Primer
resultado: se confirmó, contra el código fuente real del contenedor
(no contra documentación ni supuestos), el schema exacto de
`POST /api/combos` — el pendiente que quedaba abierto desde el 16 de agosto.
Pero al investigar el contenedor de OmniRoute para llegar a ese schema,
salieron **4 problemas de infraestructura sin resolver**, ninguno cosmético,
que se documentan aquí antes de tocar nada — no se avanzó a configurar los 4
combos todavía, porque configurarlos encima de una base rota/insegura no
tiene caso.

### Confirmado: schema de `POST /api/combos` (createComboSchema)

Extraído directo del chunk compilado
`src_shared_validation_1p53ez_._.js` dentro del contenedor
(`infinite-power-omniroute-1`), no adivinado ni tomado de documentación que
podría estar desactualizada:

```
{
  name: string, requerido, 1-100 chars, regex [a-zA-Z0-9_/.\-\[\] ] (letras,
        números, espacios, - _ / . [ ])
  description?: string, máx 2000
  models?: array de "model entries" (default []) — cada entry es una de tres formas:
    - string plano (id de modelo, shorthand)
    - objeto { provider?, providerId?, model (requerido), connectionId?, tags?[],
               prompt?, id?, weight? (0-100, default 0), label? }
    - objeto { kind: "combo-ref" (requerido), comboName (requerido) } — permite
      que un combo referencie a otro combo como si fuera un "modelo" más
  strategy?: enum, default "priority" (lista completa de valores del enum
             ROUTING_STRATEGY_VALUES todavía no extraída — no crítico para el
             diseño de 4 combos simples, que no necesita cambiar el default)
  config?: objeto grande (~50 campos opcionales) — para el diseño actual
           (4 combos por nivel, fallback simple) solo hace falta dejar el
           default o, como mucho, tocar maxRetries/fallbackDelayMs
  allowedProviders?, allowedModelFamilies?, system_message?, tool_filter_regex?,
  context_cache_protection?, context_length?, dimensions?
}
```

También confirmados (mismo archivo): `updateComboSchema` (PATCH),
`reorderCombosSchema`, `testComboSchema` (`POST /api/combos/test`, body
`{comboName}` — sirve para probar un combo ya creado sin pasar por el
Ejecutor genérico), `updateComboDefaultsSchema`.

**Pendiente del 16 de agosto (`stack_y_convenciones.md`, `estado_del_proyecto.md`)
queda resuelto**: el schema de creación de combos ya no es una incógnita.

### 4 hallazgos de infraestructura — sin resolver, bloquean crear combos con confianza

1. **Bug real de persistencia: el volumen de OmniRoute apunta a la carpeta
   equivocada.** `docker-compose.yml` monta `./data/omniroute:/app/config`,
   pero los logs del contenedor (`DATA_DIR=/app/data`,
   `SQLite database ready: /app/data/storage.sqlite`) confirman que la ruta
   real donde OmniRoute guarda su base de datos (combos, credenciales,
   providers) es `/app/data`, no `/app/config`. Esto significa que **hoy
   nada de lo que se configure en OmniRoute vía dashboard o API sobrevive a
   una recreación del contenedor** (`docker compose up -d` con cambios, o
   cualquier `docker compose down`) — se perdería en silencio. Mismo tipo de
   bug que ya se encontró y corrigió en Bloque 0 con `N8N_ENCRYPTION_KEY`,
   pero este es peor porque no hay ningún síntoma visible hasta que se
   recrea el contenedor y de repente los combos ya no están.

2. **Faltan `JWT_SECRET` y `API_KEY_SECRET`.** Confirmado con
   `docker exec ... printenv` que el contenedor solo tiene `DATA_DIR`
   explícito entre las variables relevantes — `JWT_SECRET`, `API_KEY_SECRET`
   (y opcionalmente `STORAGE_ENCRYPTION_KEY`) no están seteadas. OmniRoute
   las documenta como requeridas para producción; sin ellas, probablemente
   está generando un valor de respaldo efímero por su cuenta, lo que en la
   práctica significa que **cualquier sesión/token/credencial guardada podría
   invalidarse en cualquier recreación del contenedor** — mismo problema que
   el punto 1 mirado desde el ángulo de seguridad, no solo de persistencia.

3. **No hay ninguna contraseña de dashboard configurada todavía** (el log
   de bootstrap sugería un default `CHANGEME`, pero **verificado en vivo
   que ese login no funciona** — devuelve `needsSetup: true`; ver
   actualización del 17 de agosto, noche, arriba). El API de
   administración (`/api/combos`, etc.) requiere login (`POST
   /api/auth/login`) o un API key con scope "manage" — hasta completar el
   asistente de onboarding, nadie (ni Mateo) puede entrar al dashboard.

4. **No hay ningún proveedor de modelos conectado todavía.** Evidencia en
   logs: `[AUTO] auto/*:pro matched no connected models`,
   `[ModelSync] No connections with autoSync enabled`. Aunque se creen los
   4 combos con el schema ya confirmado, **no van a rutear nada real** hasta
   que al menos un proveedor esté conectado dentro de OmniRoute — ver la
   actualización del 17 de agosto, noche (arriba) para los 3 proveedores
   que Mateo pidió (Pollinations, Cloudflare AI, Qwen) y el estado de cada
   uno.

### Decisión pendiente de Mateo — no se asumió, se pregunta

> **Superado por la actualización del 17 de agosto, noche (arriba).**
> Mateo ya contestó qué proveedores conectar (Pollinations, Cloudflare AI,
> Qwen), y ya no hay "Gemini del amigo" como opción — el proyecto es
> individual. El punto (c) de abajo también quedó corregido: no existe un
> login con `CHANGEME`, hace falta completar el asistente de onboarding de
> OmniRoute. Se deja el contenido original por trazabilidad de qué se
> pensaba en ese momento.

Por la instrucción vigente de preguntar en vez de asumir ante duda real: el
orden lógico antes de crear los 4 combos es (a) arreglar el volumen
`/app/config` → `/app/data` en `docker-compose.yml`, (b) generar y fijar
`JWT_SECRET`/`API_KEY_SECRET` en `.env` (mismo patrón que
`N8N_ENCRYPTION_KEY` en Bloque 0: si se puede rescatar un valor ya en uso,
reusarlo; si no, generar uno nuevo seguro), (c) loguearse con `CHANGEME` y
cambiar la contraseña, y solo entonces (d) decidir qué proveedor(es)
conectar primero — para (d) hace falta que Mateo confirme qué llave(s) usar
(la de Gemini del amigo, Groq, alguna otra ya mencionada en el plan, o algo
distinto) antes de tocar nada del lado de OmniRoute con esa llave.
**No se ha tocado `docker-compose.yml` ni `.env` todavía** — se documenta
aquí primero, se ejecuta después de la confirmación.

### Pendientes de Bloque 2, en secuencia (para retomar en otra conversación sin depender de memoria)

1. ~~**Pregunta abierta a Mateo, sin responder todavía:** qué proveedor/llave
   conectar primero en OmniRoute (Gemini del amigo, Groq, otra ya mencionada
   en el plan, o decidirlo después).~~ — **contestada (17/ago, noche):**
   Pollinations, Cloudflare AI, Qwen. Ver actualización del 17 de agosto,
   noche, arriba para las 3 decisiones nuevas que salieron de esa
   respuesta (contraseña de onboarding, cuenta de Cloudflare, riesgo de
   baneo de Qwen).
2. Arreglar `docker-compose.yml`: volumen de OmniRoute de `/app/config` a
   `/app/data`.
3. Generar y fijar `JWT_SECRET`/`API_KEY_SECRET` en `.env` (mismo patrón que
   `N8N_ENCRYPTION_KEY` de Bloque 0: reusar valor existente si se puede
   rescatar, si no generar uno nuevo seguro).
4. Loguearse a OmniRoute con la contraseña default `CHANGEME` y cambiarla.
5. Conectar el/los proveedor(es) que Mateo confirme en el punto 1.
6. Crear los 4 combos (`bajo`/`medio`/`alto`/`critico`) con el
   `createComboSchema` ya confirmado arriba.
7. Confirmar empíricamente si el campo `model` del request puede referenciar
   el combo directo por nombre, o si hace falta además
   `/api/model-combo-mappings` — no asumir, probar con una llamada real.
8. Propagar `nivel_importancia` a las tareas hijas en los nodos "Parsear
   asignaciones"/"Crear tareas hijas" del Ejecutor genérico en n8n.
9. Construir el workflow de ingesta Telegram → `tasks`.
10. Prueba end-to-end en vivo de todo el flujo de Bloque 2.
11. **Nuevo (17/ago, de `auditoria_tecnica_y_vision_17ago2026.md`, hallazgo
    C1):** rotar la contraseña de Postgres (`ALTER USER`) — la actual quedó
    expuesta en el historial de git (commits `a14ed39`, `e87fe0a`,
    alcanzable desde todas las ramas remotas) — y planificar la limpieza de
    ese historial.
12. **Nuevo (17/ago, hallazgo C2):** parametrizar la consulta SQL del nodo
    "Obtener config del bot" del Ejecutor genérico — hoy interpola el
    campo `bot` directo en `WHERE slug = '{{ $json.bot }}'`, y ese valor
    puede venir de una tarea hija generada por un modelo. Reemplazar por
    `slug = $1` vía `queryReplacement`.
13. **Nuevo (17/ago, hallazgo C4):** completar el flujo de decisión humana
    — hoy `needs_approval` solo manda un mensaje a Telegram sin ruta de
    respuesta real (ni fila en `approvals`, ni transición de estado
    atómica). Sin esto, una tarea sensible queda detenida indefinidamente y
    "aprobación humana" es una notificación saliente, no un control
    operativo.
14. Bloque 3: insertar y activar Efadam en `bots`, activar Tech center de
    punta a punta contra un Efadam real. **No antes de que cierren los
    puntos 11–13** — no tiene sentido activar el cerebro de orquestación
    encima de una contraseña filtrada, una inyección SQL abierta y
    aprobaciones que no se pueden resolver.
15. **Aparcado, no tocar sin instrucción nueva de Mateo:** licencia de n8n
    (Sustainable Use License, riesgo de distribución) — deferred a la fase
    de "setup" al final, por instrucción explícita de Mateo del 17 de agosto.

---

## Actualización — 16 de agosto de 2026 (mecanismo concreto nivel → modelo, `schema/005_nivel_importancia.sql`) — histórica, ver corrección y auditoría más arriba/abajo

Quedaba un hueco real señalado por Mateo: se documentaba "OmniRoute traduce
nivel → modelo" como principio, sin especificar nunca el mecanismo. Resuelto:

- **`nivel_importancia` vive en `tasks`, no en `bots`** — coherente con que
  Efadam asigna el nivel por tarea, no por bot fijo. Migración nueva:
  `schema/005_nivel_importancia.sql` (columna + check constraint). Reemplaza
  a `bots.default_model` como fuente del modelo a llamar (esa columna queda
  sin uso activo, no se elimina por ahora).
- ~~**OmniRoute es LiteLLM self-hosted.**~~ — **Falso, corregido el 16 de
  agosto por la tarde (ver actualización de arriba). Esto se escribió sin
  verificarlo contra el contenedor real y era un error.** OmniRoute es un
  proyecto open-source distinto y no relacionado (`diegosouzapw/OmniRoute`),
  no LiteLLM. El mecanismo real de nivel → modelo es via **"combos"
  nombrados** de OmniRoute, referenciables directo por nombre en el campo
  `model` del request, más el endpoint `/api/model-combo-mappings` para
  mapear un patrón de modelo a un combo. El esquema exacto de creación de un
  combo (`POST /api/combos`) todavía no está confirmado — pendiente de
  verificar via la UI del dashboard antes de configurarlo. Detalle completo
  en `stack_y_convenciones.md`.
- **Corrección de encoding:** los 4 valores literales del sistema
  (`tasks.nivel_importancia`, el nombre del combo de OmniRoute, lo que Efadam
  escribe en el JSON de la tarea) son `bajo`/`medio`/`alto`/`critico` —
  **sin tilde en "critico"**, porque son identificadores de sistema, no
  texto para leer.
  El prompt de Efadam (`efadam.md`) tenía "crítico" con tilde, lo cual
  habría roto el `INSERT` en cuanto Efadam generara una tarea crítica de
  verdad — corregido antes de activarlo, no después. La prosa de los
  documentos sigue usando tilde donde es solo lectura humana.

**Ejecutado el mismo 16 de agosto:** la migración ya corrió contra Postgres
(`ALTER TABLE`/`COMMENT` confirmados, `tasks.nivel_importancia` existe con
su check constraint) y el nodo "Llamar a omniroute" del Ejecutor genérico
(workflow `aVORciBJl52lTxTU` en n8n) ya se editó vía la API de n8n: el
campo `model` del request ahora lee
`$('Reclamar tarea pendiente').first().json.nivel_importancia` en vez de
`$('Obtener config del bot').first().json.default_model` — verificado con
un `GET` posterior al `PUT`. El pendiente #16 de abajo queda completo.

**Todavía falta, no incluido en este cambio:** configurar los 4 combos de
OmniRoute (uno por nivel) y sus `model-combo-mappings`, e insertar a Efadam
en la tabla `bots` — el nodo ya está listo para recibir `nivel_importancia`,
pero hoy ninguna tarea trae ese campo poblado porque nada lo está asignando
todavía (Efadam no existe como bot activo). Sin esos dos pasos, cualquier
tarea nueva llegaría a OmniRoute con `model: null`.

---

## Actualización — 16 de agosto de 2026, tarde/noche (auditoría externa, corrección OmniRoute/LiteLLM, rama `correcciones`, reconstrucción de `schema/001_init.sql`) — VIGENTE, léase primero

Mateo subió una auditoría completa del estado del vault/repo/schema
(`auditoria_infinite_power_16ago2026.md`), con 31 hallazgos numerados y un
plan de remediación en 4 bloques. Se verificaron independientemente los
hallazgos más graves (no se aceptó la auditoría de fe) — todos los
verificables resultaron correctos, y uno resultó **peor** de lo que la
propia auditoría sospechaba:

**1. Corrección: OmniRoute NO es LiteLLM.** La actualización del 16 de
agosto de arriba (y `stack_y_convenciones.md`, `efadam.md`, `arquitectura.md`,
los tres ya corregidos) afirmaban que OmniRoute era LiteLLM self-hosted, con
un `config.yaml` de alias de modelo. Eso se escribió sin verificarlo contra
el contenedor real y era falso. Verificado directo dentro del contenedor
(`docker exec infinite-power-omniroute-1 ...`): OmniRoute es un proyecto
open-source real y distinto, `diegosouzapw/OmniRoute`. El mecanismo real:
providers conectados vía su propio dashboard (`http://localhost:20128`),
ruteo nativo `auto/<categoria>:<tier>`, y **"combos" nombrados**
(`GET/POST /api/combos*`) referenciables directo por nombre en el campo
`model` del request, más `/api/model-combo-mappings` para mapear un patrón
de modelo id a un combo. **No confirmado todavía:** el schema exacto de
`POST /api/combos` (crear un combo) — pendiente verificar via la UI del
dashboard antes de configurar los 4 combos por nivel, no adivinar.

**2. Decisión de Mateo — nunca borrar ni mergear ramas.** Sobre cómo
ejecutar el Bloque 0 de la auditoría (que incluía mergear `efadam` → `main`
y borrar ramas viejas): Mateo corrigió — "todo el punto de github es un
control de versiones" — nunca se borran ni mergean ramas sin instrucción
explícita futura. En su lugar, se creó una rama nueva **`correcciones`**
desde `efadam` (commit `80b7391`), y ahí vive todo el trabajo de respuesta
a la auditoría. `main`, `alphav0.1`, `alphav0.2`, `efadam` quedan intactas.

**3. Decisión de Mateo — NO congelar el alcance de "producto distribuible".**
La auditoría (sección G) sugería congelar temporalmente el trabajo de
empaquetado/distribución (Revert, Multiproyecto, empaquetado de OmniRoute)
para enfocar el esfuerzo en la operación de un solo operador. Mateo lo
rechazó explícitamente: hacerlo arriesga construir una mala base, porque
producto distribuible **es el objetivo final** y tiene que seguir en la
vista aunque no sea el foco inmediato — no se pausa ningún punto 17/18/19
de la lista de pendientes de abajo por esto.

**4. Bloque 0 — ejecutado hasta ahora (en la rama `correcciones`):**
reconstruido `schema/001_init.sql` — **nunca se había commiteado** (hallazgo
central e independientemente confirmado de la auditoría: `git log` muestra
que `schema/*.sql` en git solo tuvo migraciones `ALTER TABLE` desde el
002, nunca un `CREATE TABLE` — un clon nuevo del repo no podía levantar la
base de datos). Se reconstruyó via `pg_dump --schema-only` contra la base
real, restando lo que 002-005 agregan encima, y se **verificó de verdad**
corriendo 001→006 en orden contra una base Postgres vacía de prueba
(`test_repro`, borrada después) — sin errores, misma estructura que la base
real. De paso se encontró y corrigió un bug real, no solo de documentación:
dos `COMMENT ON COLUMN` (`bots.conocimiento_directo`,
`tasks.nivel_importancia`) habían quedado con mojibake **dentro de la base
de datos real** porque se aplicaron anteriormente vía `psql`/PowerShell sin
forzar UTF-8 en el pipe — nueva migración `schema/006_fix_encoding_comments.sql`,
ya corrida contra la base real y verificada byte por byte. Todo commiteado
y pusheado a `origin/correcciones` (commit `f09880b`).

**Nota de proceso, para no repetir el mismo bug:** escribir archivos con
acentos/caracteres especiales al vault vía el puente a la máquina de Mateo
resultó intermitentemente poco confiable durante esta sesión (el mismo
archivo `006_fix_encoding_comments.sql` salió corrupto dos veces antes de
salir limpio, sin cambiar el método). Regla adoptada: verificar siempre con
un chequeo de codepoints (`[int[]][char[]]$string`) antes de aplicar
cualquier texto en español contra Postgres, y preferir `docker cp` +
`psql -f` dentro del contenedor en vez de pipes de PowerShell para
cualquier contenido no-ASCII.

**Bloque 0 — completo (16 de agosto, noche).** Los 6 puntos, todos
verificados de verdad, no solo aplicados a ciegas:

- Workflows de n8n exportados a `n8n-workflows/*.json` (Ejecutor genérico,
  Reanudador de bloqueados) — revisados, sin secretos embebidos.
- `scripts/backup_postgres.ps1` — probado, generó un respaldo real de 3MB;
  retiene los últimos 8, uso manual o programable via Windows Task
  Scheduler (semanal recomendado).
- `.gitattributes` (`* text=auto eol=lf`) para el ruido de line-endings que
  señalaba la auditoría; de paso se gitignoró `.obsidian/graph.json`
  (mismo tipo de estado local que `workspace.json`, no contenido real).
- Password de Postgres y `N8N_ENCRYPTION_KEY` sacados de `docker-compose.yml`
  en texto plano, movidos a `.env` (gitignored) + `.env.example` como
  plantilla para instalaciones nuevas. La `N8N_ENCRYPTION_KEY` puesta es la
  **misma** que n8n ya tenía auto-generada — no se rotó, solo se hizo
  explícita, para no invalidar credenciales existentes.
- `GENERIC_TIMEZONE`/`TZ=America/Mexico_City` agregado a n8n.
- Aplicado con `docker compose up -d`: recreó el contenedor de n8n, se
  verificó que subió limpio (migraciones corridas, mismo `encryptionKey`
  confirmado dentro del contenedor) y que los 3 workflows existentes siguen
  ahí y responden vía API sin haber perdido nada.

**Bloque 1 — completo en su mayoría (16-17 de agosto).** Las 5 contradicciones
de "fuente de verdad" corregidas, los 2 wikilinks rotos de `INICIO.md`
desligados, y `docs/estado_del_proyecto.md` reescrito de cero. Todo
committeado en `correcciones` y **pusheado a GitHub** (commits `e97b5fc`,
`220d04b`, `b94af50` — confirmado con `git log origin/correcciones`).
Decisiones que se le preguntaron a Mateo en vez de asumirse: `estado_del_proyecto.md`
se reescribe (no se archiva); los wikilinks rotos se desligan (no se repuntan
a una nota adivinada, porque ninguna de las dos notas fusionadas tiene un
reemplazo 1:1 real).

**Sigue pendiente de Bloque 1:** limpiar duplicados en el Claude Project
(`trouble-shooter.md`, `tecnico-jefe.md`, `plan_de_accion_completo.md`,
`ejecutor_generico.md` — cada uno x2) — identificados, no eliminados
todavía.

**Bloqueo de infraestructura — resuelto (17 de agosto).** Las herramientas
`Desktop_Commander` (acceso a PowerShell/Docker/git reales en Windows) se
habían desconectado a media sesión el 16 de agosto y no volvían a aparecer
ni en el registro de herramientas; mientras tanto se trabajó con el bridge
estándar (`device_bash`), que corre en una VM Linux aislada sin
Docker/n8n/Postgres y sin acceso de red — eso dejó el commit `e97b5fc` local,
sin poder pushear. El 17 de agosto `Desktop_Commander` volvió a conectar.
Con acceso real se limpiaron los archivos `.lock`/`tmp_obj` que la VM aislada
había dejado sueltos en `.git/` (no podía borrarlos, solo moverlos) y se
pusheó `correcciones` sin problema — confirmado contra `origin/correcciones`.
**Bloque 2 (combos de OmniRoute, Postgres, n8n) ya es viable** con
`Desktop_Commander` disponible — no depende de correr la tarea "en tu
computadora" salvo que `Desktop_Commander` se vuelva a desconectar.

**Limpieza de duplicados en el Claude Project — hecho (17 de agosto).**
`trouble-shooter.md`, `tecnico-jefe.md`, `plan_de_accion_completo.md` y
`ejecutor_generico.md` tenían dos copias cada uno (una vieja del 14/15 de
agosto, una nueva). `project_delete` por path borró primero la copia más
reciente en vez de la vieja (comportamiento no documentado de la
herramienta) — se detectó de inmediato al verificar y se corrigió
re-escribiendo el contenido correcto antes de tocar los otros tres archivos.
Confirmado: 30 docs únicos en el Project, uno por path, contenido correcto
en los 4 verificado por lectura directa.

**Archivos faltantes subidos al Project — hecho (17 de agosto):**
`docker-compose.yml`, `003_trouble_shooter_v2.sql`, `004_conocimiento_directo.sql`.

**Hallazgo al subirlos:** `004_conocimiento_directo.sql` tiene un
encabezado de comentario que dice `003_conocimiento_directo.sql` — quedó mal
renumerado en algún punto anterior (el archivo en disco es el 004, el
comentario adentro sigue diciendo 003). No corregido todavía — es cosmético
(el nombre de archivo real en el filesystem es el que manda), se deja
anotado para no perder el rastro.

**`roster_agentes_v4.xlsx` — confirmado NO commiteado, y ni siquiera existe
en el vault.** Búsqueda completa en `C:\Users\2\Documents` (vía
`Desktop_Commander`, recursiva) no encontró ningún archivo con "roster" en
el nombre. El único lugar donde existe es como blob subido directo al
Claude Project el 14 de agosto — nunca llegó al repo. Además, ya está
marcado como desactualizado en la sección "Deuda documentada" de
`estado_del_proyecto.md` (organización por los 6 clusters planos viejos,
"Project center" en vez de "Proyect center", faltan bots). **No lo subí al
vault/git sin preguntar** porque no es obvio que tenga sentido versionar un
archivo que ya se sabe que está mal — la duda real es si (a) se actualiza
primero y luego se sube, o (b) se sube tal cual con una nota de que está
desactualizado, o (c) se descarta y el roster vive solo en `arquitectura.md`
de aquí en adelante.

---

## Actualización — 15 de agosto de 2026, noche, cuarta ronda (Setup, Revert, Multiproyecto — fusionados desde nota de visión aislada) — histórica, ver actualización de arriba para lo más reciente

Se fusionó a este documento el contenido que no estaba cubierto en ningún
otro lado de una nota de visión antigua y aislada (`docs/vision/Infinite
power.md`, ahora eliminada — el resto de su contenido, Cadencia/Memoria/
Comunicación entre bots, ya estaba cubierto en `ejecutor_generico.md`,
`memoria_del_sistema.md` y `stack_y_convenciones.md`, así que no se repite
aquí). Tres piezas de diseño nuevas, sin implementar todavía:

**Setup (vive en Proyect center).** Es una entrevista de objetivo que
produce: la meta, la lista de pasos necesarios para llegar a ella, y un
criterio de "listo" (para que el proyecto pueda pasar a modo mantenimiento
de baja frecuencia en vez de generar ideas indefinidamente sobre algo ya
cumplido). El Setup **no dispara nada directamente** a otras ramas — mismo
principio de cuello de botella ya documentado en `efadam.md`: Setup
(Proyect center) → el resultado vuelve a Efadam → Efadam decide qué
jefe(s) le corresponde cada parte y les inyecta el contexto específico →
el jefe correspondiente decide dentro de su propio dominio si hace falta
construir algo nuevo vía Agent builder.

**Revert.** No se borra nada — se archiva. Tres capas, cada una con su
propio mecanismo (no una sola): (1) prompts/config de bots → git, reversible
de verdad; (2) `knowledge_log` (decisiones/hallazgos) → histórico
append-only, no se revierte, se archiva (`archived_at` + `archived_reason`,
disparado por una tabla `reverts (fecha_objetivo, disparado_por, motivo)`;
Efadam solo lee lo vigente por default, lo archivado queda disponible para
Trouble scouter y revisión manual); (3) acciones que ya salieron al mundo
real (correo enviado, pago hecho) → no reversibles, punto — no es lo que
nadie esperaría de esta función. Se dispara solo por Mateo vía Telegram →
Efadam, nunca automático.

**Multiproyecto (visión, no construir todavía — post Fase 2 del recorrido
vertical actual).** Un proyecto nuevo = un schema nuevo en el mismo
Postgres, no una base de datos ni un stack completo nuevo. Se comparte:
n8n, OmniRoute, y los prompts del kernel (versionados en git). Se aísla por
proyecto: solo los datos, vía schema. Una tabla de control
`proyectos (id, nombre, schema_name, estado, fecha_creación)` le permite a
Efadam saber qué proyectos existen; los nodos de Postgres en n8n deben
apuntar al schema de forma dinámica (parámetro, no hardcodeado) — requisito
de diseño desde ahora, no algo que se pueda parchar después sin refactor.
Los proyectos corren en paralelo, cada uno con su propia cadencia — el
Schedule Trigger consulta `proyectos WHERE estado = 'activo'` y despacha una
ejecución por cada uno. **Pendiente técnico antes de construir esto:**
confirmar que los workflows actuales de n8n no tienen el schema
hardcodeado — si lo tienen, hace falta migrarlos primero.

---

## Actualización — 15 de agosto de 2026, noche, tercera ronda (reglas explícitas de nivel — pendiente #15 resuelto) — VIGENTE, léase primero

Se resolvió el pendiente de diseño de la actualización inmediata de abajo:
Efadam **no** clasifica el nivel de importancia con criterio libre — aplica
una tabla de reglas fijas por dominio/tema, ya escrita en
`stack_y_convenciones.md` ("Niveles de importancia y BYOK" → "Reglas de
asignación"):

- Gasto de dinero, tema legal/contractual, publicación pública, cambio de
  seguridad → mínimo `crítico`.
- Decisión de precio, contratación/despido, compromiso frente a terceros →
  mínimo `alto`.
- Trabajo especializado normal (código, investigación, redacción, análisis)
  sin lo anterior → `medio`.
- Ruteo, resumen de estado, tareas mecánicas → `bajo`.

Si una tarea coincide con varias reglas, gana la más alta; si no encaja
claramente en ninguna, sube por default al nivel superior más cercano, y si
la ambigüedad es real, Efadam pregunta en vez de asumir. Las reglas viven en
`system_knowledge`, no hardcodeadas en el prompt — pueden ajustarse por el
mismo mecanismo de cuello de botella (Efadam solicita, U&R center evalúa y
redacta, Efadam inserta), no son una excepción nueva. Detalle completo en
`stack_y_convenciones.md` y `efadam.md` (prompt de sistema y casos de
prueba actualizados).

---

## Actualización — 15 de agosto de 2026, noche, segunda ronda (corrección: Efadam asigna el nivel, no cada bot) — histórica, ver corrección de arriba

Corrige un error en la actualización inmediata de abajo: decía "cada bot
declara su nivel de importancia", lo cual contradice el resto del diseño de
Efadam (un bot individual no tiene visión de negocio para juzgar su propia
importancia; esa visión es justamente lo que hace Efadam). Corregido: es
**Efadam** quien asigna el `nivel_importancia` de cada tarea al despacharla
— el bot destino lo hereda, no lo decide. Detalle en `efadam.md` y
`stack_y_convenciones.md`.

**Este documento dejó abierto, en su momento, si esa clasificación debía ser
criterio libre de Efadam o reglas fijas — resuelto en la actualización de
arriba: reglas fijas.**

---

## Actualización — 15 de agosto de 2026, noche (niveles de importancia + BYOK + empaquetado de OmniRoute/n8n) — VIGENTE, léase primero

Se rediseña de fondo cómo el sistema decide qué modelo usa cada bot, y cómo
se distribuye OmniRoute como parte del producto. Reemplaza el contenido del
Paso 0.5 más abajo (que describía OmniRoute configurado a mano con las
llaves de Mateo) y la sección "Presupuesto" que tenía `stack_y_convenciones.md`.
Detalle completo del diseño en `stack_y_convenciones.md`, sección "Niveles de
importancia y BYOK" — resumen aquí:

- 4 niveles fijos del sistema (`bajo`, `medio`, `alto`, `crítico`). **Efadam**
  asigna a cada tarea el nivel que le corresponde (columna `nivel_importancia`
  en `tasks`, heredada por el bot que la ejecuta) — ningún bot decide el
  suyo propio, y nunca se declara un modelo específico. OmniRoute es el
  único que traduce nivel → modelo real. Ver corrección de la actualización
  inmediata de arriba.
- OmniRoute (y n8n, con el Ejecutor genérico ya importado) se distribuyen
  empaquetados — mismo `docker-compose.yml` del sistema — con un modelo
  gratis ya asignado por default a cada nivel. El setup deja de requerir
  cablear una llave API por bot a mano.
- En el setup, el usuario ve los 4 niveles con su default gratis y un
  disclaimer recomendando subir de nivel `alto`/`crítico`; puede añadir sus
  propias llaves por nivel en cualquier momento, no es bloqueante.
- Es una característica **por instalación**: cada quien que instale Infinite
  Power tiene su propio OmniRoute con sus propias llaves, no comparte el de
  Mateo. Esto reencuadra el Paso 0.4/0.5 de más abajo: ya no son "cómo
  configuro mi OmniRoute", son "cómo se empaqueta OmniRoute para cualquier
  instalador futuro".

**Consecuencia práctica:** el Paso 0.5 original (abajo, en Fase 0) queda
marcado como histórico — se corrigió su contenido en línea con nota, en vez
de borrarlo, para no perder el registro de qué se intentó primero.

---

## Actualización — 15 de agosto de 2026, noche (refuerzo de documentación: cuello de botella + `conocimiento_directo`)

Se fusionó al resto de la documentación un mecanismo que vivía aislado en una
nota de visión antigua (`docs/vision/Efadam/Efadam.md`, nunca conectada al
resto del vault): la columna `bots.conocimiento_directo`, única excepción
válida a que todo conocimiento cruzado entre ramas pase por Efadam. Detalle
completo, ya integrado, en `memoria_del_sistema.md` y `efadam.md`. Además se
corrigió en varios documentos el uso de la palabra "estático" al describir
`system_knowledge` — no es inmutable, evoluciona con el tiempo vía Upgrade &
review center; lo que no hace es cambiar mensaje a mensaje, a diferencia de
la lectura en vivo de `tasks`/`agent_runs`.

**Nota explícita, porque es un rasgo diferenciador del proyecto:** el cuello
de botella de Efadam es intencional, no un descuido de diseño — la fricción
de que todo pase por un único punto es lo que permite que el sistema
aprenda de forma centralizada. Este principio se repite en varios documentos
a propósito (`arquitectura.md`, `efadam.md`, `memoria_del_sistema.md`), no
solo aquí.

---

## Actualización — 15 de agosto de 2026, noche (orden de construcción pasa de horizontal a vertical) — VIGENTE, léase primero

Cambia de raíz cómo se secuencia todo lo que sigue en este documento. Las
Fases 1, 2 y 3 originales (abajo) describían un modelo horizontal: primero
escribir los 40 prompts (Fase 1), después probar una rebanada vertical con
Legal (Fase 2), después replicar a todos los clusters (Fase 3). Ese modelo
queda **reemplazado**, no complementado — se deja como referencia histórica
más abajo, pero ya no es el plan de ejecución.

**Nuevo orden, vertical, un componente completo (construido + probado +
activo) antes de pasar al siguiente:**

1. **Efadam** — primero. Es el destino al que todo lo demás reporta; construir
   una rama completa sin que exista Efadam significa terminarla sin tener a
   dónde mandar el resultado. Se construye y prueba con las ramas todavía
   vacías/parciales — su enrutamiento no depende de que los 40 bots existan.
2. **Tech center** (rama Dev/Tech completa) — ya tiene 10 de 12 bots con
   prompt escrito (ver `arquitectura.md`); falta activarla end-to-end contra
   un Efadam real.
3. **Upgrade & review center** (rama Estrategia/Crecimiento + Legal +
   Investigación completa).
4. **Proyect center** (rama Operación/Proyectos + negocios propios completa).
5. **Jarvis** — al final. Es el endpoint de interacción humana por texto y
   voz — **no es lo mismo que Efadam** (corrección de diseño del 15 de agosto:
   antes se usaban como sinónimos; ver `efadam.md`). No tiene nada útil que
   enrutar ni con qué conversar hasta que Efadam y las 3 ramas ya produzcan
   resultado real. Mientras tanto, Telegram (ya construido en la Fase 0) sigue
   ahí como canal de prueba puntual — sin que se espere usarlo de forma
   funcional/diaria antes de que el bot esté terminado.

**Consecuencia sobre "escribir todos los prompts primero":** ya no aplica
como regla general. Se escribe el prompt de un bot cuando toca construir y
activar el componente al que pertenece, no en bloque adelantado. Los prompts
de Dev/Tech que ya existen se aprovechan tal cual cuando llegue su turno
(paso 2 de la lista de arriba); los de Upgrade & review center y Proyect
center se escriben en su propio paso, no antes.

**Consecuencia sobre el upsert de seed inicial a `system_knowledge`:** se
pospone. No tiene caso poblar la tabla mientras el sistema sigue en
construcción y el contenido de `arquitectura.md`/`stack_y_convenciones.md`/
`reglas_generales.md` puede seguir cambiando — se corre hasta que haya un
producto final real que probar, no ahora (corrige lo que se había anotado
como pendiente inmediato en la actualización anterior del 15 de agosto).

Las Fases 4 (monitoreo/costos), 5 (autonomía progresiva) y 6 (auto-expansión)
originales, abajo, siguen aplicando conceptualmente después de que las 5
piezas de arriba existan — no cambiaron de contenido, solo de orden relativo
(vienen después del recorrido vertical completo, no entrelazadas con "Fase 3
multi-cluster" como estaba antes).

---

## Actualización — 11 de agosto de 2026 (leer antes que el resto del documento)

Dos cosas cambiaron respecto a la versión original de este plan, abajo:

1. **La Fase 0 ya está completa, pero en local, no en VPS.** Se decidió construir y probar todo primero en la máquina de Mateo (n8n + Postgres + OmniRoute + bot de Telegram, todo vía Docker Compose) antes de pagar un servidor y configurar un dominio — el VPS + dominio se agrega hasta que el sistema esté probado y quieran dejarlo corriendo 24/7. Los pasos de VPS/dominio que siguen abajo (0.1 a 0.8) quedan como referencia para cuando llegue ese momento, **no son el siguiente paso ahora**. El repo de GitHub ya existe: `https://github.com/Madafe/Infinite_Power`.

2. **La arquitectura no es una lista plana de 6 clusters — es Efadam en el centro + 3 ramas.** Cada rama tiene su propio bot "center" que consolida y aprueba antes de reportar a Efadam: **Tech center** (rama Dev/Tech), **Upgrade & review center** (rama Estrategia/Crecimiento + Legal + Investigación), **Proyect center** (rama Operación/Proyectos + negocios propios). El detalle completo vive en `arquitectura_general.md`.

**Mandato de diseño vigente:** durante la construcción, Claude tiene autorización para proponer bots nuevos, dividir uno existente en varios más específicos, o fusionar responsabilidades para evitar redundancia, sin pedir permiso cada vez — documentando el cambio en el roster y en `arquitectura_general.md`.

---

## Actualización — 14 de agosto de 2026 (memoria/autoconciencia del sistema) — SUPERSEDIDA por la actualización del 15 de agosto (mañana), abajo

Se definió cómo funciona la "memoria" de los bots. El diseño completo, con el
porqué de cada decisión, vive ahora en **`docs/memoria_del_sistema.md`**; el DDL
en **`schema/002_conocimiento.sql`**. Resumen de lo que quedó (histórico — ver
corrección del 15 de agosto inmediatamente abajo antes de usar esto):

- **`system_knowledge`** — autoconciencia del sistema (arquitectura, stack,
  convenciones, reglas generales). **La fuente de verdad son los archivos
  `docs/context/*.md` del repo, no la tabla**: un workflow de sync los sube. Sin
  eso, la arquitectura quedaría documentada en dos lugares que se contradirían.
- **`knowledge_log`** — bitácora de casos, con columna `tipo`:
  - `patron_fallo` → lo escribe el ejecutor **automáticamente** desde el campo
    `patron_aprendido` de Trouble shooter. Efadam no participa: el dato ya viene
    estructurado, no hay nada que curar, y meterlo en medio agregaba latencia y
    tokens en el bot de mayor frecuencia del sistema (que además corre en modelo
    gratis, o sea el peor juez posible de qué recordar).
  - `aprendizaje` → lo escribe **Efadam**, tras el reporte de un center. Ahí sí
    hace falta criterio y visión de las 3 ramas.
  - Índice único parcial sobre `lower(titulo)` para los patrones: un patrón
    repetido incrementa `veces_visto` en vez de duplicarse. Eso reemplaza la
    regla del prompt "si ya pasó 3+ veces márcalo como recurrente", que dependía
    de que el modelo recordara algo que no tiene forma de saber.
- **No se inyecta lo mismo a todos los bots.** Columna `bots.contexto_slugs
  text[]`: cada bot declara qué necesita. Abogado Jefe no carga el schema de
  Postgres para dar un dictamen legal.
- Se descartó (otra vez, y ahora explícitamente) que Trouble shooter tenga un
  banco propio. Un solo mecanismo, permisos de escritura distintos por tipo.
- Las **reglas generales** siguen viviendo dentro del `system_prompt` de cada
  bot, pero ya no se prependen a mano: se agrega la columna `prompt_especifico`
  y un trigger compone `system_prompt = reglas + '---' + prompt_especifico`.
  Los dos bots ya insertados (`tecnico_jefe`, `coder`) **nunca las tuvieron** —
  se insertaron antes de que existiera la regla. El backfill está en el `.sql`.

Aclaración de roles de los 3 centers (sigue vigente): su función principal es
**retener** (gatekeeping y auditoría activa de su rama), no solo enrutar. Efadam
solo revisa que no haya discrepancia entre lo entregado y la meta establecida;
si la hay, regresa comentarios, no re-audita el detalle de ejecución.

`prompts_dev_tech/upgrade-review-center.md` sigue restaurado y vigente: es cabeza
de su propio departamento, al mismo nivel que Tech center y Proyect center.

---

## Actualización — 15 de agosto de 2026, mañana (repo pasa a ser seed, no fuente de verdad; Efadam deja de redactar) — VIGENTE

Corrige de fondo dos puntos de la actualización del 14 de agosto de arriba —
esa sección se deja como está por trazabilidad, pero ya no aplica en esto:

**1. `system_knowledge` ya NO se sincroniza desde el repo de forma recurrente.**
El repo (`docs/context/*.md`, `reglas_generales.md`) pasa a ser el **seed
inicial** — se carga una sola vez, a mano, con el mismo upsert que usaba el
workflow, **cuando haya un producto final real que probar** (ver actualización
de la noche del 15 de agosto arriba — no es un paso a correr ahora). Después
de ese arranque, **la tabla es la fuente de verdad viva**; el repo puede
quedar desactualizado y es esperado, no un bug. Razón del cambio: el sistema
está pensado para más de un operador, y mantener una credencial de GitHub con
lectura de todo el repo privado, viva en n8n, para un trigger que de todas
formas era manual, dejó de tener sentido — cualquiera con acceso al editor de
workflows heredaba de facto acceso al repo. El workflow **"Sync conocimiento
del sistema" se borró en n8n** (confirmado) y **el PAT de GitHub que usaba se
revocó** (confirmado, 15 de agosto). Detalle completo del razonamiento en
`memoria_del_sistema.md`.

**2. `aprendizaje` (y ahora también `system_knowledge`) ya NO lo redacta
Efadam.** Precisión que faltaba documentar: Efadam sigue siendo el cuello de
botella único de entrada (nada llega a Postgres sin pasar por él), pero
**quien redacta y evalúa el contenido es Upgrade & review center** — es su rol
ya definido ("Observar → Analizar → Mejorar", no aprobar por default) aplicado
también al conocimiento del sistema, no solo a hallazgos de investigación.
Efadam solicita, U&R center produce, Efadam inserta sin re-auditar el fondo —
mismo patrón que ya tenía con el resto de lo que U&R center le reporta.
Corregido en `efadam.md` y `upgrade-review-center.md`.

**Consecuencia práctica para lo que sigue pendiente:** cuando se construya la
lógica real en n8n de "Efadam inserta lo que U&R center redactó" (ver
checklist maestro), ya no hay que diseñar ningún nodo que lea GitHub — solo
Postgres de un lado (leer contexto) y Postgres del otro (insertar lo que U&R
center entrega).

---

## Actualización — 14 de agosto de 2026, tarde (secuencia y alcance) — parcialmente histórica, ver nota

Revisión de la lista de pendientes. Tres correcciones de fondo:

**1. La lista de pendientes estaba desactualizada respecto a la decisión de
memoria de esa misma mañana.** Seguía diciendo "crear tabla `project_knowledge`"
(renombrada `system_knowledge`) y "Trouble shooter: banco de conocimiento propio"
(descartado). Los prompts de `consultor-de-arquitectura.md` y `trouble-scouter.md`
todavía referencian `project_knowledge` y `trouble_shooter_knowledge`, que ya no
existen — hay que corregirlos antes de activarlos.

**2. Todo lo pendiente era el sistema construyéndose a sí mismo.** De los 10
pendientes, 9 eran infraestructura meta: memoria, bots que auditan bots, bots que
revisan la arquitectura. Cero valor de negocio entregado. **Nota del 15 de
agosto:** la referencia a "Legal" como siguiente paso aquí abajo queda
superada por la actualización de esa misma noche (ver más abajo) y, sobre
todo, por el nuevo orden vertical de la noche del 15 de agosto (arriba) — hoy
lo siguiente no es un cluster de negocio, es Efadam.

**3. Se posponen dos bots ya diseñados, con criterio explícito de activación:**

| Bot | Se activa cuando |
|---|---|
| Consultor de arquitectura | El output de Coder deje de ser leído línea por línea por Mateo antes de mergear |
| Trouble scouter | Haya 12+ bots activos, o 2+ ramas corriendo a diario |

Los prompts ya escritos se quedan en el repo — no se pierde el trabajo. Lo que se
pospone es el `INSERT INTO bots`, que es lo que cuesta tokens y latencia. Hoy hay
2 bots activos y Mateo revisa cada corrida a mano: ambos bots estarían auditando
lo que un humano ya audita.

**Consecuencia inmediata:** el bloque "PROTOCOLO OBLIGATORIO" del prompt de
Técnico jefe (que manda consultar a `consultor_arquitectura`) **no se carga** en
la tabla `bots`. Si se cargara, Técnico jefe asignaría tareas a un slug que no
existe: el nodo "Obtener config del bot" devuelve vacío, la ejecución revienta, y
la tarea queda `failed` sin que nadie entienda por qué.

**Sistema de aclaración — se simplifica a dos piezas** (ver `ejecutor_generico.md`
sección 5): un `CASE` en el UPDATE de "Guardar resultado" que marca `blocked`, y
un IF + Telegram que le manda la pregunta a Mateo. El workflow "Reanudador de
bloqueados" se pospone hasta tener evidencia de que los bots se bloquean seguido
y cadenas de más de 2 niveles donde el humano sea el cuello de botella real.

**`tasks_status_check`:** `init.sql` nunca creó ese constraint, así que `blocked`
funcionaba por accidente (cualquier string era válido). Se agrega explícito en
`002_conocimiento.sql` con los 6 estados válidos.

---

## Actualización — 14 de agosto de 2026, noche (orden real de construcción) — histórica, ver nota del 15 de agosto arriba

Corrección de Mateo, con razón: Legal se venía arrastrando como "el siguiente
paso" solo porque el plan original de 7/ago lo eligió como candidato de bajo
riesgo para probar el patrón — no porque el negocio lo necesite. No hay
justificación de negocio para priorizarlo hoy.

**Orden de construcción confirmado ese día (superado por el orden vertical
del 15 de agosto, arriba — se deja por trazabilidad):**
**Dev/Tech → Estrategia/Crecimiento → Operación/Proyectos.**
Legal (y el resto de Negocios propios) queda pospuesto sin fecha — se retoma
si/cuando el negocio lo necesite, no por calendario del proyecto.

El loop Técnico jefe → Coder, probado de punta a punta con memoria, manejo de
errores y aprobación, sigue siendo la prueba real de que el patrón del
ejecutor genérico funciona — eso no cambió con la actualización del 15 de
agosto, solo cambió qué se construye a continuación (Efadam, no un cluster de
negocio más).

---

## 0. Antes de empezar

**Checklist de cuentas/recursos a tener listos:**

> **Nota del 17 de agosto, noche:** este checklist y la tabla de abajo se
> escribieron cuando el proyecto era de Mateo + un amigo/cofundador. Mateo
> confirmó que el proyecto es individual — se corrigió el checklist y se
> quitó la tabla de reparto (ya no aplica, un solo dueño para las 3 ramas).

- [ ] Dominio (ya lo tienen) — acceso al panel DNS
- [ ] Tarjeta para pagar el VPS (~$5–6 USD/mes)
- [ ] Cuenta de GitHub de Mateo con el repo
- [ ] Claves de API: la que compre Mateo con sus $150 MXN, Groq, y cualquier otra que ya tengan de OmniRoute
- [ ] Teléfono para crear el bot de Telegram
- [ ] Contraseña del VPS guardada en un gestor tipo Bitwarden

**Dueño de las 3 ramas:** Mateo. (La rama Tech center ya tiene sus 10 prompts escritos — ver `arquitectura.md`.)

---

## FASE 0 — Infraestructura base

**Objetivo de la fase:** tener un servidor propio corriendo n8n + Postgres + OmniRoute, accesible por su dominio, con HTTPS, con un repo de GitHub y un bot de Telegram listos para usarse en las fases siguientes.

**Tiempo estimado:** un fin de semana (4–8 horas repartidas).

### Paso 0.1 — Levantar el VPS

1. Crear cuenta en Hetzner Cloud (o DigitalOcean si prefieren, la mecánica es igual).
2. Crear un servidor tipo **CX22** (o equivalente ~4GB RAM / 2 vCPU), imagen **Ubuntu 24.04**, en la región más cercana a México (US-East si no hay opción en LATAM).
3. Al crearlo, agreguen su llave SSH pública (si no tienen una, generarla con `ssh-keygen -t ed25519`).
4. Anoten la IP pública del servidor.

### Paso 0.2 — Apuntar el dominio

1. En el panel DNS de su dominio, crear un registro **A** apuntando un subdominio (ej. `n8n.sudominio.com`) a la IP del VPS.
2. Si quieren exponer OmniRoute también, otro registro A: `router.sudominio.com` → misma IP.
3. Esperar a que propague (puede tardar de minutos a un par de horas).

### Paso 0.3 — Preparar el servidor

Conectarse por SSH (`ssh root@IP`) y correr:

```bash
apt update && apt upgrade -y
apt install -y docker.io docker-compose-plugin ufw fail2ban
ufw allow OpenSSH
ufw allow 80/tcp
ufw allow 443/tcp
ufw enable
systemctl enable docker --now
```

Crear un usuario no-root para trabajar (buena práctica de seguridad):

```bash
adduser deploy
usermod -aG docker deploy
```

### Paso 0.4 — Estructura de carpetas y docker-compose

```bash
mkdir -p /opt/infinite-power/{n8n_data,postgres_data,omniroute,caddy_data}
cd /opt/infinite-power
```

Crear `docker-compose.yml`:

```yaml
version: "3.8"

services:
  postgres:
    image: postgres:16
    restart: unless-stopped
    environment:
      POSTGRES_USER: infpower
      POSTGRES_PASSWORD: CAMBIA_ESTA_CLAVE
      POSTGRES_DB: infinite_power
    volumes:
      - ./postgres_data:/var/lib/postgresql/data
    networks:
      - infpower

  n8n:
    image: n8nio/n8n:latest
    restart: unless-stopped
    environment:
      - N8N_HOST=n8n.sudominio.com
      - N8N_PROTOCOL=https
      - WEBHOOK_URL=https://n8n.sudominio.com/
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_HOST=postgres
      - DB_POSTGRESDB_DATABASE=infinite_power
      - DB_POSTGRESDB_USER=infpower
      - DB_POSTGRESDB_PASSWORD=CAMBIA_ESTA_CLAVE
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=admin
      - N8N_BASIC_AUTH_PASSWORD=CAMBIA_ESTA_CLAVE_TAMBIEN
    volumes:
      - ./n8n_data:/home/node/.n8n
    depends_on:
      - postgres
    networks:
      - infpower

  omniroute:
    image: ghcr.io/diegosouzapw/omniroute:latest
    restart: unless-stopped
    ports:
      - "4000:4000"
    volumes:
      - ./omniroute:/app/config
    networks:
      - infpower

  caddy:
    image: caddy:2
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile
      - ./caddy_data:/data
    networks:
      - infpower

networks:
  infpower:
```

> Verifica el nombre exacto de la imagen Docker de OmniRoute en su repo de GitHub antes de levantar el contenedor — puede cambiar. Si no publican imagen oficial, se clona el repo y se construye localmente con su propio Dockerfile.
>
> **Nota 15 de agosto de 2026 (histórica — ver actualización de niveles/BYOK arriba):** este `docker-compose.yml` sigue siendo la base técnica vigente (Postgres + n8n + OmniRoute + Caddy en un solo stack), pero el paso 0.5 de abajo (configurar OmniRoute a mano con llaves propias) queda superado: para un producto distribuible, el compose debe traer OmniRoute preconfigurado con defaults gratis por nivel de importancia desde el primer arranque, no como paso manual posterior.

Crear `Caddyfile` (esto da HTTPS automático gratis):

```
n8n.sudominio.com {
    reverse_proxy n8n:5678
}

router.sudominio.com {
    reverse_proxy omniroute:4000
}
```

Levantar todo:

```bash
docker compose up -d
docker compose ps
```

Entrar a `https://n8n.sudominio.com` y confirmar que carga el login de n8n.

### Paso 0.5 — Configurar OmniRoute (histórico — ver "Niveles de importancia y BYOK" arriba para el diseño vigente)

> **Superado por la actualización del 15 de agosto, noche (arriba).** Este
> paso describía cargar las llaves de Mateo/su amigo a mano y definir un
> orden de fallback fijo. El diseño vigente es: OmniRoute llega preconfigurado
> con un modelo gratis por nivel de importancia (`bajo`/`medio`/`alto`/`crítico`)
> desde el arranque; añadir llaves propias por nivel es un paso posterior y
> opcional del usuario, no un requisito de instalación. Se deja el contenido
> original por trazabilidad de qué se intentó primero.

1. Entrar al panel de OmniRoute (`https://router.sudominio.com` o el puerto que exponga).
2. Cargar las API keys: Gemini (amigo), la nueva que compre Mateo, Groq, y cualquier otra gratuita que ya tengan.
3. Definir el orden de fallback: gratis primero (Gemini, Groq), pagado al final (para los bots que sí lo necesiten según el roster).
4. Probar con una llamada de prueba (`curl` a `https://router.sudominio.com/v1/chat/completions`) para confirmar que responde y que hace fallback si un proveedor falla.

### Paso 0.6 — Repositorio de GitHub

Estructura sugerida:

```
infinite-power/
├── docker-compose.yml
├── Caddyfile
├── prompts/
│   ├── _core/            (Efadam, Jarvis — cross-cluster)
│   ├── dev-tech/
│   ├── operacion-proyectos/
│   ├── estrategia-crecimiento/
│   ├── investigacion-skills/
│   ├── legal/
│   └── negocios-propios/
├── schema/
│   └── init.sql
├── n8n-workflows/        (exports .json de cada workflow, como respaldo versionado)
└── docs/
    └── roster_agentes.xlsx
```

Mateo con acceso de escritura. Cada bot tendrá su propio `.md` dentro de `prompts/<cluster>/<bot>.md`.

### Paso 0.7 — Bot de Telegram para aprobaciones

1. Hablarle a `@BotFather` en Telegram, `/newbot`, ponerle nombre (ej. `InfinitePowerBot`).
2. Guardar el token que da BotFather.
3. Crear un grupo de Telegram con Mateo, agregar el bot al grupo.
4. Obtener el `chat_id` del grupo (se puede con `https://api.telegram.org/bot<token>/getUpdates` después de mandar un mensaje al grupo).
5. Guardar token y chat_id como credencial en n8n (Settings → Credentials → nueva credencial tipo HTTP/Telegram).

**Nota 15 de agosto:** este bot de Telegram sigue siendo el canal de prueba
provisional mientras Jarvis no existe (ver actualización del 15 de agosto,
noche, arriba). No se espera uso funcional/diario de este canal antes de que
Jarvis esté construido.

### Paso 0.8 — Backups mínimos

Cron simple en el VPS para respaldar la base de datos diario:

```bash
crontab -e
# agregar:
0 4 * * * docker exec $(docker ps -qf "name=postgres") pg_dump -U infpower infinite_power > /opt/infinite-power/backups/$(date +\%F).sql
```

**✅ Fin de Fase 0 cuando:**
- n8n carga en su dominio con HTTPS
- Postgres responde y n8n guarda sus datos ahí
- OmniRoute responde a una llamada de prueba con al menos 2 proveedores
- El bot de Telegram manda un mensaje de prueba al grupo
- El repo de GitHub existe con la estructura de carpetas

---

## FASE 1 (histórica) — Definir instrucciones de cada bot, en bloque por cluster

> **Superada por el orden vertical de la actualización del 15 de agosto,
> noche (arriba).** Ya no se escriben los 40 prompts por adelantado ni por
> cluster completo antes de construir — cada prompt se escribe cuando toca
> activar el componente al que pertenece. Se deja este contenido como
> referencia de la plantilla de prompt (Paso 1.2 sigue siendo la plantilla
> vigente para cualquier bot nuevo) y del trabajo ya hecho en Dev/Tech.

**Objetivo original de la fase:** que cada una de las ~40 cajas del diagrama tenga un prompt de sistema real, probado, y guardado en el repo.

### Paso 1.1 — Repartir el roster

Abrir `roster_agentes.xlsx`, llenar la columna "Dueño" con quién de los dos se encarga de cada bot, siguiendo el reparto por cluster sugerido arriba (o el que decidan). Aclarar primero las filas marcadas "Pendiente - aclarar" (Efadam, TalentIA, Bintix) antes de repartir el resto.

### Paso 1.2 — Plantilla de prompt (**vigente** — usar para cualquier bot nuevo)

Cada archivo `prompts/<cluster>/<bot>.md` debe tener esta estructura:

```markdown
# [Nombre del bot]

## Rol
(una frase: qué es este bot dentro del sistema)

## Objetivo
(qué tiene que lograr cada vez que corre)

## Input que recibe
(de qué bot o de qué tabla en Postgres saca su información)

## Output que entrega
(a qué bot o tabla en Postgres escribe su resultado, y en qué formato — texto, JSON, etc.)

## Herramientas que puede usar
(qué nodos/APIs tiene disponibles: ClickUp, web search, GitHub, etc.)

## Reglas y límites
(qué NO debe hacer nunca sin aprobación humana, tono, restricciones de presupuesto/tiempo)

## Cuándo debe pedir aprobación humana
(criterio claro: "si la acción implica gastar dinero", "si es contenido público", etc.)

## Prompt de sistema (versión final para pegar en n8n)
"""
(aquí va el texto literal que se pega en el nodo AI Agent de n8n)
"""

## Casos de prueba
1. Caso de entrada de ejemplo → salida esperada
2. Caso límite/borde → salida esperada
3. Caso que debería fallar/escalar → salida esperada
```

### Paso 1.3 — Escribir los prompts, cluster por cluster (histórico)

Orden original (ya no vigente — ver actualización del 15 de agosto arriba
para el orden real: Efadam → Tech center → Upgrade & review center → Proyect
center → Jarvis):

1. Cluster **Legal** (3 bots)
2. Cluster **Investigación/Skills** (4 bots)
3. Cluster **Dev/Tech** (11 bots)
4. Cluster **Operación/Proyectos** (10 bots)
5. Cluster **Estrategia/Crecimiento** (9 bots)
6. Cluster **Negocios propios** (5 bots)

### Paso 1.4 — Revisión cruzada (sigue siendo buena práctica al cerrar cada componente vertical)

Antes de dar por cerrado cada componente (Efadam, cada center): cada quien revisa lo que escribió el otro (no lo propio) y valida que el input/output realmente conecte con el bot de al lado — este es el paso donde se detectan huecos de lógica antes de programarlo.

---

## FASE 2 (histórica) — Rebanada vertical (cluster Legal)

> **Superada.** El concepto de "probar el patrón de punta a punta antes de
> escalar" sigue siendo válido y ya se cumplió — pero con Dev/Tech
> (Técnico jefe → Coder), no con Legal, y el ejecutor genérico resultante es
> justo lo que ahora se reutiliza para construir Efadam y cada center. Se deja
> este contenido porque el schema de Postgres y el patrón de nodos siguen
> siendo la base técnica vigente.

### Paso 2.1 — Schema de Postgres (vigente)

`schema/init.sql`:

```sql
create table tasks (
    id serial primary key,
    cluster text not null,
    bot text not null,
    status text not null default 'pending', -- pending, running, done, failed, needs_approval
    input jsonb,
    output text, -- text, NO jsonb: la salida de casi todos los bots es texto libre (código, explicaciones).
                 -- El único que devuelve JSON es Técnico jefe, y sus asignaciones se parsean directo
                 -- desde la respuesta HTTP, no desde esta columna.
                 -- Si ya la creaste como jsonb: ALTER TABLE tasks ALTER COLUMN output TYPE text USING output::text;
    created_at timestamptz default now(),
    updated_at timestamptz default now()
);

create table approvals (
    id serial primary key,
    task_id int references tasks(id),
    requested_at timestamptz default now(),
    resolved_at timestamptz,
    approved boolean,
    approver text
);

create table agent_runs (
    id serial primary key,
    task_id int references tasks(id),
    bot text not null,
    model_used text,
    tokens_input int,
    tokens_output int,
    cost_estimate numeric,
    duration_ms int,
    created_at timestamptz default now()
);
```

Correrlo dentro del contenedor de Postgres:

```bash
docker exec -i $(docker ps -qf "name=postgres") psql -U infpower -d infinite_power < schema/init.sql
```

### Nota — cómo se construyó realmente el patrón (vigente)

En vez de un workflow separado por cluster, se construyó **un solo "ejecutor
genérico"** que lee la configuración de cada bot (prompt, modelo, si requiere
aprobación, si despacha tareas) de una tabla `bots` en Postgres. Un bot nuevo
se agrega con un `INSERT` a esa tabla, no con un workflow nuevo. Ver
`ejecutor_generico.md` para el diseño completo.

Piloto probado de punta a punta: **Técnico jefe → Coder**, incluyendo manejo
de errores (nodo "Marcar como fallida": cualquier fallo en un nodo marca la
tarea como `failed` con el error guardado en `output`, en vez de dejarla
colgada).

**Limitación conocida:** si detienes una ejecución manualmente desde n8n
(botón de cancelar) mientras está corriendo, la tarea que estaba reclamando se
queda en `running` para siempre. Hay que resetearla a mano
(`UPDATE tasks SET status = 'pending' WHERE id = <id>;`).

### Piezas de arquitectura del ejecutor genérico (vigente, aplican a Efadam y a cada center)

1. **Inyección de contexto/memoria:** un nodo Postgres antes de "Llamar a OmniRoute" que jale contexto relevante y lo agregue al prompt. Los bots no tienen acceso directo a la base de datos — el workflow les da el contexto ya curado.
2. **Sistema de aclaración:** columna `parent_task_id` en `tasks`, status `blocked`, regla en los prompts (responder `{"necesita_aclaracion": true, "pregunta": "..."}` cuando falte info esencial), y un nodo que cree la tarea de aclaración de vuelta al bot/humano correspondiente.

---

## FASE 3 (histórica) — Orquestación multi-cluster

> **Superada como "fase separada".** La idea de conectar clusters vía la
> tabla `tasks` sigue siendo el mecanismo vigente — pero ya no es un paso que
> viene "después de escribir todos los prompts", es parte natural de
> construir cada center en el orden vertical (arriba). Se deja el mecanismo
> técnico por referencia.

### Conectar los clusters entre sí (mecanismo vigente)

En vez de que un workflow llame directamente a otro, se usa la tabla `tasks`
como bandeja de entrada compartida: un cluster termina su trabajo → inserta
una fila nueva en `tasks` con `cluster` = el cluster destino; ese cluster, en
su propio schedule, hace `SELECT` de sus tareas pendientes y las procesa. Para
conexiones que sí necesitan ser inmediatas, usar el nodo **Execute Workflow**
de n8n en vez de pasar por la cola.

---

## FASE 4 — Monitoreo y control de costos

**Objetivo de la fase:** saber en todo momento qué está corriendo, cuánto cuesta, y que nada se salga de control. Viene después del recorrido vertical completo (Efadam → Tech center → Upgrade & review center → Proyect center → Jarvis), no entrelazada con él.

**Tiempo estimado:** 3–4 días.

### Paso 4.1 — Workflow de resumen diario

Nuevo workflow `Monitoreo - Resumen diario`:

1. Schedule Trigger (todas las mañanas)
2. Postgres: `SELECT` de `agent_runs` del día anterior — total de corridas, costo estimado, bots que fallaron
3. Telegram (o Jarvis, si ya existe): manda el resumen

### Paso 4.2 — Alertas de límite

Workflow separado que corre cada hora:

1. Postgres: suma el `cost_estimate` acumulado del día
2. IF: si supera un límite que definan (ej. equivalente a $50 MXN/día)
3. Telegram/Jarvis: alerta inmediata + opción de pausar el cluster que más gastó

### Paso 4.3 — (Opcional) Dashboard

Si quieren algo visual, un workflow que expone los datos de `agent_runs` a una hoja de Google Sheets o a un dashboard simple en n8n (o Grafana). No es indispensable para arrancar.

**✅ Fin de Fase 4 cuando:**
- Reciben el resumen diario
- Las alertas de gasto se disparan de verdad al superar el límite de prueba

---

## FASE 5 — Autonomía progresiva

**Objetivo de la fase:** ir quitando los checkpoints de aprobación humana solo donde ya se ganó la confianza.

**Cadencia:** continua, sin plazo fijo — se revisa cuando haya evidencia real que evaluar, no por calendario (corregido el 17 de agosto: la versión original de esta sección usaba "revisar cada 2 semanas" como cadencia y "2 semanas corriendo sin error" como umbral de graduación; Mateo lo descartó — el tiempo transcurrido no es la unidad correcta para validar un cluster).

### Criterio de "graduación" por cluster

Checklist completo en [[autonomia_progresiva]] (extraído de aquí, se mantiene ahí para no duplicarlo). Resumen: volumen suficiente de tareas reales sin error no manejado (no tiempo transcurrido), costo dentro de rango, ningún caso no aprobado, y acuerdo explícito de los dos — cluster por cluster, nunca todos a la vez.

**✅ Fin de Fase 5:** es continua, no tiene un final fijo — es el estado de mantenimiento del sistema.

---

## FASE 6 — Auto-expansión ("Nuevos departamentos")

**Objetivo de la fase:** que el Council pueda proponer y crear un nuevo agente/cluster automáticamente.

**Tiempo estimado:** dejar para cuando todo lo anterior lleve al menos un mes estable.

### Paso 6.1 — Generar la API key de n8n

Settings → API → crear una API key. Guardarla como credencial.

**Nota 15 de agosto de 2026:** esta API key ya existe y está en uso (es la
misma que permite conectarse a n8n local desde una terminal con acceso directo
a la máquina — ver `memoria_del_sistema.md` y el patrón de conexión guardado
en memoria de Claude). El usuario decidió mantenerla activa de forma indefinida
en vez de rotarla — vive fuera de sistemas digitales cuando no está en uso.

### Paso 6.2 — Workflow "Nuevos departamentos"

1. Recibe la propuesta del Council (vía la tabla `tasks`)
2. AI Agent **Agent builder**: genera el prompt del nuevo bot siguiendo la plantilla del Paso 1.2
3. **Siempre** pasa por aprobación humana — este paso nunca se automatiza del todo
4. Si se aprueba: llamada HTTP a la API de n8n (`POST /workflows`) para crear el workflow nuevo en modo desactivado
5. Ustedes lo revisan manualmente y lo activan a mano la primera vez

**✅ Fin de Fase 6 cuando:**
- El sistema puede proponer un departamento nuevo con su prompt ya escrito
- Nunca se activa solo sin que alguno de los dos lo revise primero

---

## Orden de construcción vigente y checklist

**Reemplaza el timeline y checklist anteriores, que asumían el modelo
horizontal de Fases 1–3.** Ver actualización del 15 de agosto, noche, arriba
para el razonamiento completo.

| Paso | Qué es | Estado |
|---|---|---|
| 0 — Infraestructura | VPS/local + n8n + Postgres + OmniRoute + Telegram + repo | ✅ Completo en local; VPS pendiente sin fecha; empaquetado de OmniRoute/n8n para distribución pendiente de implementar (diseño ya definido) |
| 1 — Efadam | Cerebro de orquestación central, cuello de botella de entrada a Postgres | ⬜ Siguiente paso |
| 2 — Tech center | Rama Dev/Tech completa y activa end-to-end contra Efadam | 🟡 Prompts casi listos (10/12); falta activar contra Efadam real |
| 3 — Upgrade & review center | Rama Estrategia/Crecimiento + Legal + Investigación completa | ⬜ Prompts pendientes |
| 4 — Proyect center | Rama Operación/Proyectos + negocios propios completa | ⬜ Prompts pendientes |
| 5 — Jarvis | Endpoint de interacción humana (texto + voz), separado de Efadam | ⬜ No empezado — al final |
| 6 — Monitoreo/costos | Resumen diario + alertas de gasto (Fase 4 original) | ⬜ Después del recorrido vertical |
| 7 — Autonomía progresiva | Quitar checkpoints de aprobación cluster por cluster (Fase 5 original) | ⬜ Continuo, después de que cada cluster esté estable |
| 8 — Auto-expansión | "Nuevos departamentos" vía Council (Fase 6 original) | ⬜ Cuando todo lleve 1 mes estable — API key de n8n ya generada y en uso desde el 15 de agosto |

### Pendientes activos (actualizado 15 de agosto de 2026, noche)

1. **Construir Efadam** — es el paso inmediato. Prompt ya escrito en `efadam.md`; falta activarlo en la tabla `bots` y probar su enrutamiento con las 3 ramas todavía vacías/parciales.
2. Activar **Tech center** end-to-end contra el Efadam real (hoy el piloto Técnico jefe → Coder corre sin un Efadam que lo reciba).
3. Escribir los prompts completos de **Upgrade & review center** y **Proyect center** (se escriben en su turno, no antes).
4. Escribir el prompt de **Jarvis** — al final, cuando el resto ya produzca contenido real que valga la pena exponer por voz/texto.
5. Construir en n8n la lógica concreta de "Efadam solicita a U&R center, U&R center redacta, Efadam inserta" — hoy solo existe el diseño en prosa (`efadam.md`, `upgrade-review-center.md`).
6. El upsert de seed inicial a `system_knowledge` **se pospone** hasta que haya un producto final que probar — no es un pendiente inmediato.
7. Definir si `knowledge_log`/`system_knowledge` necesitan columna de versión/historial (mejora futura, no implementado).
8. ~~Agregar al amigo/cofundador como colaborador del repo de GitHub~~ — **ya no aplica (17 de agosto, noche):** Mateo confirmó que el proyecto es individual, no hay cofundador que agregar.
9. Activar más bots en la tabla `bots` conforme cada componente vertical lo requiera — hoy solo `tecnico_jefe` y `coder` están activos; Consultor de arquitectura y Trouble scouter siguen pospuestos con criterio explícito (ver actualización del 14 de agosto, tarde).
10. Corregir `consultor-de-arquitectura.md` y `trouble-scouter.md`, que aún referencian `project_knowledge`/`trouble_shooter_knowledge` (nombres ya descartados) — corregir antes de activarlos.
11. **Implementar el empaquetado de OmniRoute + n8n para distribución** (diseño ya definido, ver actualización del 15 de agosto, noche, arriba y `stack_y_convenciones.md`): agregar la columna `bots.nivel_importancia` al schema, definir los defaults gratis por nivel dentro de la config de OmniRoute, y diseñar la pantalla/paso de setup donde el usuario ve los 4 niveles y puede añadir sus llaves. No es bloqueante para construir Efadam — se puede implementar en paralelo o después, cuando el paquete se piense para distribuirse a un tercero.
12. ~~Eliminar o resolver la duplicación de la nota `docs/vision/Efadam/Efadam.md` en Obsidian~~ — **hecho (15 de agosto, noche):** su contenido ya estaba fusionado en `memoria_del_sistema.md` y `efadam.md`; el archivo original se eliminó del repo (revisado y aprobado por Mateo).
13. ~~Localizar y leer "Infinite power.md > Método > Multiproyecto"~~ — **hecho (15 de agosto, noche, cuarta ronda):** localizada en `docs/vision/Infinite power.md`, fusionada a este documento (ver actualización correspondiente arriba) y la nota original eliminada.
14. ~~Decidir qué hacer con dos archivos sueltos sin commitear~~ — **hecho (15 de agosto, noche):** `schema/_tmp_diag_github.ps1` (apuntaba al workflow "Sync conocimiento del sistema" ya borrado) y `schema/_tmp_inspect_schedule.js` (exploración puntual de internals de `ScheduleTrigger`, ya resuelta) se revisaron — sin secretos en texto plano — y se borraron del disco. Nunca estuvieron trackeados en git, así que no generaron commit.
15. ~~Decidir cómo Efadam clasifica el nivel de importancia con confiabilidad~~ — **hecho (15 de agosto, noche, tercera ronda):** reglas explícitas por dominio/tema, no criterio libre — ver `stack_y_convenciones.md`, "Reglas de asignación", y actualización correspondiente arriba.
16. ~~Implementar en n8n la lógica real de aplicar la tabla de reglas de nivel~~ — **hecho (16 de agosto):** migración `schema/005_nivel_importancia.sql` corrida contra Postgres; nodo "Llamar a omniroute" del Ejecutor genérico editado vía API de n8n para leer `tasks.nivel_importancia` en vez de `bots.default_model`. Lo que queda (no cubierto por este punto): configurar los 4 combos de OmniRoute (uno por nivel) y activar Efadam para que empiece a poblar `nivel_importancia` de verdad — ver punto 1.
20. ~~Completar Bloque 0 de la auditoría externa~~ — **hecho (16 de agosto, noche):** workflows de n8n exportados, script de backup probado, `.gitattributes`, password de Postgres y `N8N_ENCRYPTION_KEY` fuera de `docker-compose.yml` en texto plano (movidos a `.env`, misma key que ya existía — no se rotó), `GENERIC_TIMEZONE`. Todo en la rama `correcciones`, verificado (docker compose up -d recreó n8n sin perder workflows). Ver detalle en la actualización del 16 de agosto, tarde/noche, arriba.
21. ~~Bloque 1 de la auditoría externa~~ — **hecho (16-17 de agosto):** 5 contradicciones de "fuente de verdad" corregidas, wikilinks rotos de `INICIO.md` desligados, `estado_del_proyecto.md` reescrito de cero — todo committeado y pusheado a `correcciones` (commits `e97b5fc`, `220d04b`, `b94af50`). **Sigue pendiente, no cubierto por este punto:** limpiar duplicados en el Claude Project.
22. ~~Desktop_Commander desconectado~~ — **resuelto (17 de agosto):** volvió a conectar. Se usó para limpiar los `.lock`/`tmp_obj` que la VM aislada del bridge estándar había dejado sueltos en `.git/` y para pushear el commit de Bloque 1 que había quedado local. Bloque 2 (Postgres/n8n/OmniRoute) ya es viable con esta herramienta disponible.
17. **Nuevo (post Fase 2, no ahora):** construir Multiproyecto — schema por proyecto en Postgres, tabla `proyectos`, nodos Postgres con schema dinámico. Antes: confirmar que los workflows actuales de n8n no tienen el schema hardcodeado.
18. **Nuevo:** construir el mecanismo de Revert (tabla `reverts`, `archived_at`/`archived_reason` en `knowledge_log` y demás tablas relevantes) — sin fecha fija, pero vale la pena tenerlo antes de que el sistema empiece a tomar decisiones con consecuencia real que alguien quiera poder revisar/archivar.
19. **Nuevo:** escribir el prompt de Setup en Proyect center (entrevista de objetivo → meta + pasos + criterio de "listo") — se escribe en su turno, cuando toque construir Proyect center (paso 4 del orden vertical).
