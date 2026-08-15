> **ARCHIVADO — 14 de agosto de 2026.** Este documento es la bitácora de
> decisiones original del proyecto (empezó 7/ago). Se conserva por
> trazabilidad — el porqué de varias decisiones vigentes está aquí. **No es
> fuente de verdad de nada actual.** Contiene capas de autocorrección, y al
> menos una recomendación que ya no aplica (dice en varios lugares que "Legal"
> es el siguiente paso — corregido: es Estrategia/Crecimiento, ver
> [[estado_del_proyecto]]).
>
> Para el estado real, ir a:
> - [[estado_del_proyecto]] — qué existe hoy
> - [[arquitectura_general]] — arquitectura vigente y su porqué
> - [[memoria_del_sistema]] — diseño de memoria vigente
> - [[plantilla_prompt]] — plantilla de prompt (extraída de aquí)
> - [[autonomia_progresiva]] — criterio de graduación (extraído de aquí)

---

# Plan de acción completo — "Infinite power"
### Sistema de agentes autogestionado para el negocio

Para: Mateo + amigo · 7 de agosto de 2026

---

## Actualización — 11 de agosto de 2026 (leer antes que el resto del documento)

Dos cosas cambiaron respecto a la versión original de este plan, abajo:

1. **La Fase 0 ya está completa, pero en local, no en VPS.** Se decidió construir y probar todo primero en la máquina de Mateo (n8n + Postgres + OmniRoute + bot de Telegram, todo vía Docker Compose) antes de pagar un servidor y configurar un dominio — el VPS + dominio se agrega hasta que la Fase 2 (rebanada vertical) esté probada y quieran dejarlo corriendo 24/7. Los pasos de VPS/dominio que siguen abajo (0.1 a 0.8) quedan como referencia para cuando llegue ese momento, **no son el siguiente paso ahora**. El repo de GitHub ya existe: `https://github.com/Madafe/Infinite_Power`.

2. **La arquitectura no es una lista plana de 6 clusters — es Efadam en el centro + 3 ramas.** Cada rama tiene su propio bot "center" que consolida y aprueba antes de reportar a Efadam: **Tech center** (rama Dev/Tech), **Upgrade & review center** (rama Estrategia/Crecimiento + Legal + Investigación), **Proyect center** (rama Operación/Proyectos + negocios propios). El detalle completo vive en `arquitectura_general.md` — la Fase 1 (abajo) debe leerse con esta estructura en mente, no con los 6 clusters sueltos originales.

**Mandato de diseño vigente:** durante la construcción, Claude tiene autorización para proponer bots nuevos, dividir uno existente en varios más específicos, o fusionar responsabilidades para evitar redundancia, sin pedir permiso cada vez — documentando el cambio en el roster y en `arquitectura_general.md`.

---

## Actualización — 14 de agosto de 2026 (memoria/autoconciencia del sistema) — CERRADA

Se definió cómo funciona la "memoria" de los bots. El diseño completo, con el
porqué de cada decisión, vive ahora en **`docs/memoria_del_sistema.md`**; el DDL
en **`schema/002_conocimiento.sql`**. Resumen de lo que quedó:

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

## Actualización — 14 de agosto de 2026, tarde (secuencia y alcance)

Revisión de la lista de pendientes. Tres correcciones de fondo:

**1. La lista de pendientes estaba desactualizada respecto a la decisión de
memoria de esa misma mañana.** Seguía diciendo "crear tabla `project_knowledge`"
(renombrada `system_knowledge`) y "Trouble shooter: banco de conocimiento propio"
(descartado). Los prompts de `consultor-de-arquitectura.md` y `trouble-scouter.md`
todavía referencian `project_knowledge` y `trouble_shooter_knowledge`, que ya no
existen — hay que corregirlos antes de activarlos.

**2. Todo lo pendiente era el sistema construyéndose a sí mismo.** De los 10
pendientes, 9 eran infraestructura meta: memoria, bots que auditan bots, bots que
revisan la arquitectura. Cero valor de negocio entregado. La Fase 2 existía para
probar la rebanada vertical de **Legal**, y los 3 prompts de Legal siguen sin
escribirse. Regla nueva: **después de cerrar la memoria mínima, lo siguiente es
Legal, no más plomería.**

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

## Actualización — 14 de agosto de 2026, noche (orden real de construcción)

Corrección de Mateo, con razón: Legal se venía arrastrando como "el siguiente
paso" solo porque el plan original de 7/ago lo eligió como candidato de bajo
riesgo para probar el patrón — no porque el negocio lo necesite. No hay
justificación de negocio para priorizarlo hoy.

**Orden de construcción real, confirmado por Mateo:**
**Dev/Tech → Estrategia/Crecimiento → Operación/Proyectos.**
Legal (y el resto de Negocios propios) queda pospuesto sin fecha — se retoma
si/cuando el negocio lo necesite, no por calendario del proyecto.

**La Fase 2 (rebanada vertical) ya está satisfecha, con Dev/Tech.** El loop
Técnico jefe → Coder, probado de punta a punta con memoria, manejo de errores y
aprobación, es la prueba del patrón que la Fase 2 pedía. No hace falta un
cluster adicional solo para "probar que funciona" — lo que sigue es extender el
mismo patrón a la rama de Estrategia/Crecimiento, que es Fase 1 continuando, no
una Fase 2 nueva.

**Fase 1 desde aquí:** con Dev/Tech ya escrito (salvo los 2 bots pospuestos),
lo que sigue es escribir los prompts de la rama **Estrategia/Crecimiento**.

---

## 0. Antes de empezar

**Checklist de cuentas/recursos a tener listos:**

- [ ] Dominio (ya lo tienen) — acceso al panel DNS
- [ ] Tarjeta para pagar el VPS (~$5–6 USD/mes, se puede repartir entre los 2)
- [ ] Cuenta de GitHub compartida u organización con ambos como miembros
- [ ] Claves de API: Gemini (amigo), la que compre Mateo con sus $150 MXN, Groq, y cualquier otra que ya tengan de OmniRoute
- [ ] Teléfono para crear el bot de Telegram
- [ ] Decidir quién paga/administra el VPS (recomendado: uno solo lo administra para no duplicar accesos, pero ambos tienen la contraseña guardada en un gestor compartido tipo Bitwarden)

**Reparto de responsabilidades sugerido para toda esta fase:**

| Persona | Se enfoca en |
|---|---|
| Mateo | Infra local, rama Upgrade & review center (Estrategia/Legal/Investigación) |
| Amigo | OmniRoute + routing de modelos, rama Tech center (Dev/Tech), rama Proyect center (Operación/Proyectos + negocios propios) |

Ajusten según quién se sienta más cómodo con qué parte — lo importante es que **cada rama tenga un dueño claro** para la Fase 1. (La rama Tech center ya tiene sus 11 prompts escritos — ver `prompts_dev_tech/` y `arquitectura_general.md`.)

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

### Paso 0.5 — Configurar OmniRoute con sus API keys

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

Ambos con acceso de escritura. Cada bot tendrá su propio `.md` dentro de `prompts/<cluster>/<bot>.md` — eso es lo que van a llenar en la Fase 1.

### Paso 0.7 — Bot de Telegram para aprobaciones

1. Hablarle a `@BotFather` en Telegram, `/newbot`, ponerle nombre (ej. `InfinitePowerBot`).
2. Guardar el token que da BotFather.
3. Crear un grupo de Telegram con Mateo + amigo, agregar el bot al grupo.
4. Obtener el `chat_id` del grupo (se puede con `https://api.telegram.org/bot<token>/getUpdates` después de mandar un mensaje al grupo).
5. Guardar token y chat_id como credencial en n8n (Settings → Credentials → nueva credencial tipo HTTP/Telegram).

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

## FASE 1 — Definir instrucciones de cada bot

**Objetivo de la fase:** que cada una de las ~40 cajas del diagrama tenga un prompt de sistema real, probado, y guardado en el repo.

**Tiempo estimado:** 1–2 semanas, en paralelo entre los dos.

### Paso 1.1 — Repartir el roster

Abrir `roster_agentes.xlsx`, llenar la columna "Dueño" con quién de los dos se encarga de cada bot, siguiendo el reparto por cluster sugerido arriba (o el que decidan). Aclarar primero las filas marcadas "Pendiente - aclarar" (Efadam, TalentIA, Bintix) antes de repartir el resto.

### Paso 1.2 — Plantilla de prompt (usar la misma para los 40)

Ver [[plantilla_prompt]] — se movió a su propio archivo.

### Paso 1.3 — Escribir los prompts, cluster por cluster

Para cada bot:

1. Leer la fila correspondiente del roster (ya tiene un borrador de objetivo/input/output).
2. Corregir lo que no aplique — el roster es un punto de partida, no la verdad final.
3. Escribir el prompt de sistema completo siguiendo la plantilla.
4. Probarlo manualmente: pegarlo en el playground de Gemini/Groq (o en Claude/ChatGPT) con un caso real inventado y ver si responde como esperan.
5. Ajustar hasta que 2 de 3 casos de prueba salgan bien.
6. Hacer commit del archivo al repo.

**Orden recomendado por prioridad — SUPERADO, ver [[estado_del_proyecto]] para el orden real (Dev/Tech → Estrategia/Crecimiento → Operación/Proyectos):**

1. ~~Cluster **Legal** (3 bots) — es el que se usa en la Fase 2~~
2. ~~Cluster **Investigación/Skills** (4 bots)~~
3. Cluster **Dev/Tech** (11 bots)
4. ~~Cluster **Operación/Proyectos** (10 bots)~~
5. ~~Cluster **Estrategia/Crecimiento** (9 bots)~~
6. ~~Cluster **Negocios propios** (5 bots)~~

### Paso 1.4 — Revisión cruzada

Antes de dar por cerrada la fase: cada quien revisa los prompts que escribió el otro (no los propios) y valida que el input/output realmente conecte con el bot de al lado en el diagrama — este es el paso donde se detectan huecos de lógica en el loop antes de programarlo.

**✅ Fin de Fase 1 cuando:**
- Los 40 archivos `.md` existen en el repo con la plantilla completa
- Cada uno tiene al menos 2 casos de prueba validados manualmente
- Ambos revisaron los prompts del otro

---

## FASE 2 — Rebanada vertical (cluster Legal)

**Objetivo de la fase:** un loop completo y real funcionando de punta a punta: memoria en Postgres, ejecución en n8n, aprobación humana en Telegram, logging.

**Tiempo estimado:** 1 semana.

### Paso 2.1 — Diseñar el schema de Postgres

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

> Nota (14/ago): esto es correcto conceptualmente pero desactualizado en el
> comando exacto — usar `docker cp` + `psql -f`, nunca `<` redirigido desde
> PowerShell (corrompe acentos). Ver [[stack_y_convenciones]].

### Paso 2.2 — Construir el workflow en n8n

1. Crear credencial en n8n apuntando a OmniRoute (`https://router.sudominio.com`, tipo "OpenAI compatible").
2. Crear credencial de Postgres (host `postgres`, usuario/clave del docker-compose).
3. Crear credencial de Telegram con el token del bot.
4. Nuevo workflow: `Legal - Loop`.
5. Nodo **Trigger manual** (para pruebas) y luego un **Schedule Trigger** (ej. diario) cuando ya funcione.
6. Nodo **Postgres (SELECT)**: trae tareas pendientes con `cluster = 'legal'`.
7. Nodo **AI Agent — Abogado Scouter**: system prompt pegado del archivo `prompts/legal/abogado-scouter.md`, modelo vía OmniRoute (Gemini gratis).
8. Nodo **Postgres (INSERT)**: guarda el output del Scouter en `agent_runs` y actualiza `tasks`.
9. Nodo **AI Agent — Abogado Jefe**: recibe el output del Scouter, modelo pagado vía OmniRoute.
10. Nodo **IF**: ¿el dictamen del Jefe requiere aprobación? (según su regla del prompt)
    - Si no: nodo Postgres marca `status = done`.
    - Si sí: sigue al paso 11.
11. Nodo **Telegram (Send Message)**: manda el dictamen al grupo con botones "Aprobar / Rechazar" (usar `sendMessage` con `inline_keyboard`).
12. Nodo **Telegram Trigger (Webhook)**: escucha la respuesta del botón.
13. Nodo **AI Agent — Abogado Verificador**: solo corre si se aprobó, hace el check final.
14. Nodo **Postgres (UPDATE)**: guarda resultado final en `tasks` y `approvals`.

### Paso 2.3 — Probar con 5 casos reales

Metan 5 tareas de prueba directo en la tabla `tasks` (vía `INSERT` manual) simulando situaciones legales reales de su negocio, corran el workflow manualmente y revisen que:

- El Scouter realmente investiga
- El Jefe da un dictamen coherente
- El mensaje de Telegram llega y los botones funcionan
- El Verificador solo corre si se aprobó
- Todo quedó guardado en Postgres

### Paso 2.4 — Ajustar y dejar corriendo

Corregir prompts o lógica según lo que falló en las pruebas. Activar el Schedule Trigger (ej. una vez al día) y dejarlo correr una semana en paralelo a su operación normal, sin depender de él todavía para nada real.

**✅ Fin de Fase 2 cuando:**
- El loop de Legal corre solo, pide aprobación cuando debe, y guarda todo en Postgres
- Una semana sin errores no manejados

### Nota — cómo se construyó realmente (corrección aplicada)

En la práctica, Fase 2 se construyó distinto a lo escrito arriba: en vez de un workflow separado por cluster (`Legal - Loop`, `Dev/Tech - Loop`, etc.), se construyó **un solo "ejecutor genérico"** que lee la configuración de cada bot (prompt, modelo, si requiere aprobación, si despacha tareas) de una tabla `bots` en Postgres. Un bot nuevo se agrega con un `INSERT` a esa tabla, no con un workflow nuevo. Ver [[ejecutor_generico]] para el diseño real (19 nodos, más completo que lo descrito abajo). Esto reemplaza el Paso 2.2 tal como estaba escrito.

Piloto probado de punta a punta: **Técnico jefe → Coder → Trouble shooter**, incluyendo manejo de errores, contexto de linaje, y sistema completo de aclaración/reanudación bot-a-bot.

**Limitación conocida:** si detienes una ejecución manualmente desde n8n (botón de cancelar) mientras está corriendo, la tarea que estaba reclamando se queda en `running` para siempre. Hay que resetearla a mano (`UPDATE tasks SET status = 'pending' WHERE id = <id>;`).

### Paso 2.5 — Próximos pasos inmediatos sobre el ejecutor genérico — COMPLETADO

Las dos piezas descritas aquí (inyección de contexto de linaje, sistema de aclaración) **ya están construidas**, y de forma más completa de lo que se planeaba en esta versión del documento. Ver [[ejecutor_generico]] y [[memoria_del_sistema]].

---

## FASE 3 — Orquestación multi-cluster

**Objetivo de la fase:** replicar el patrón de Legal en los demás clusters, conectados entre sí como en el diagrama.

**Tiempo estimado:** 3–4 semanas (una por cada 1–2 clusters).

### Paso 3.1 — Repetir el patrón de la Fase 2 por cluster

Mismo esquema (Postgres + AI Agents + aprobación cuando aplique) para: Investigación/Skills → Dev/Tech → Operación/Proyectos → Estrategia/Crecimiento → Negocios propios. Cada uno como su propio workflow de n8n, nombrado igual que el cluster.

### Paso 3.2 — Conectar los clusters entre sí

En vez de que un workflow llame directamente a otro, usar la tabla `tasks` como bandeja de entrada compartida:

- Un cluster termina su trabajo → inserta una fila nueva en `tasks` con `cluster` = el cluster destino
- Ese cluster, en su propio schedule, hace `SELECT` de sus tareas pendientes y las procesa

Esto reproduce las flechas del diagrama sin tener que amarrar todos los workflows en uno solo gigante e inmanejable. Para conexiones que sí necesitan ser inmediatas (ej. Council → Nuevos departamentos), usar el nodo **Execute Workflow** de n8n en vez de pasar por la cola.

### Paso 3.3 — Documentar el mapa de conexiones real

Mantener actualizado un diagrama (puede ser el mismo de ClickUp) marcando qué está ya construido vs. qué sigue en el diagrama original, para no perder de vista el objetivo completo.

**✅ Fin de Fase 3 cuando:**
- Todos los clusters del roster tienen su workflow en n8n
- Se pasan tareas entre sí vía la tabla `tasks`
- El mapa de conexiones documentado coincide con lo construido

---

## FASE 4 — Monitoreo y control de costos

**Objetivo de la fase:** saber en todo momento qué está corriendo, cuánto cuesta, y que nada se salga de control.

**Tiempo estimado:** 3–4 días.

### Paso 4.1 — Workflow de resumen diario

Nuevo workflow `Monitoreo - Resumen diario`:

1. Schedule Trigger (todas las mañanas)
2. Postgres: `SELECT` de `agent_runs` del día anterior — total de corridas, costo estimado, bots que fallaron
3. Telegram: manda el resumen al grupo

### Paso 4.2 — Alertas de límite

Workflow separado que corre cada hora:

1. Postgres: suma el `cost_estimate` acumulado del día
2. IF: si supera un límite que definan (ej. equivalente a $50 MXN/día)
3. Telegram: alerta inmediata + opción de pausar el cluster que más gastó

### Paso 4.3 — (Opcional) Dashboard

Si quieren algo visual, un workflow que expone los datos de `agent_runs` a una hoja de Google Sheets o a un dashboard simple en n8n (o Grafana si ya tienen ganas de meterle más infra). No es indispensable para arrancar.

**✅ Fin de Fase 4 cuando:**
- Reciben el resumen diario en Telegram
- Las alertas de gasto se disparan de verdad al superar el límite de prueba

---

## FASE 5 — Autonomía progresiva

Ver [[autonomia_progresiva]] — se movió a su propio archivo.

---

## FASE 6 — Auto-expansión ("Nuevos departamentos")

**Objetivo de la fase:** que el Council pueda proponer y crear un nuevo agente/cluster automáticamente.

**Tiempo estimado:** dejar para cuando todo lo anterior lleve al menos un mes estable.

### Paso 6.1 — Generar la API key de n8n

Settings → API → crear una API key. Guardarla como credencial.

> Nota (14/ago): ya se hizo esto — hay un API key de n8n en uso para que Claude
> pueda leer/escribir workflows directo durante la construcción. Ver
> [[estado_del_proyecto]].

### Paso 6.2 — Workflow "Nuevos departamentos"

1. Recibe la propuesta del Council (vía la tabla `tasks`)
2. AI Agent **Agent builder**: genera el prompt del nuevo bot siguiendo la plantilla de la Fase 1
3. **Siempre** pasa por aprobación humana en Telegram — este paso nunca se automatiza del todo
4. Si se aprueba: llamada HTTP a la API de n8n (`POST /workflows`) para crear el workflow nuevo en modo desactivado
5. Ustedes lo revisan manualmente y lo activan a mano la primera vez

**✅ Fin de Fase 6 cuando:**
- El sistema puede proponer un departamento nuevo con su prompt ya escrito
- Nunca se activa solo sin que alguno de los dos lo revise primero

---

## Timeline resumen

| Fase | Duración estimada | Se puede empezar cuando |
|---|---|---|
| 0 — Infraestructura | 1 fin de semana | Ya |
| 1 — Instrucciones de cada bot | 1–2 semanas | Fase 0 lista |
| 2 — Rebanada vertical (Legal) | 1 semana | Prompts de Legal listos |
| 3 — Multi-cluster | 3–4 semanas | Fase 2 estable |
| 4 — Monitoreo/costos | 3–4 días | En paralelo a la Fase 3 |
| 5 — Autonomía progresiva | Continuo | Cada cluster listo en Fase 3 |
| 6 — Auto-expansión | Cuando todo lleve 1 mes estable | Fases 3–5 maduras |

---

## Checklist maestro

- [ ] Fase 0: VPS + n8n + Postgres + OmniRoute + dominio + Telegram + repo listos
- [ ] Fase 1: 40 prompts escritos, probados y en el repo
- [ ] Fase 2: loop de Legal corriendo solo una semana sin errores
- [ ] Fase 3: todos los clusters como workflows conectados vía la tabla `tasks`
- [ ] Fase 4: resumen diario y alertas de costo funcionando
- [ ] Fase 5: al menos un cluster graduado a autonomía sin aprobación
- [ ] Fase 6: primer "nuevo departamento" propuesto y revisado manualmente
