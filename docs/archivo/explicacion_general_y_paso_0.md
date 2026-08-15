> **ARCHIVADO — 14 de agosto de 2026.** Explicación introductoria del 7/ago
> sobre el Paso 0. Superada: la infraestructura se construyó en local, no en
> VPS con subdominio como describe este documento — ver [[estado_del_proyecto]]
> y [[stack_y_convenciones]] para el stack real. Se conserva por trazabilidad
> (y porque confirma que `bintix.mx` es un dominio real ya en su poder).

---

# Infinite Power — explicación general y qué levantar en el Paso 0

## El plan en corto

Estamos construyendo un sistema de agentes de IA (~40 "bots" especializados, organizados en clusters: técnico/desarrollo, ciberseguridad, operación de proyectos, estrategia/crecimiento, investigación, legal, y negocios propios) que ayude a operar y hacer crecer los negocios con la menor intervención humana posible. Los bots se retroalimentan entre sí en varios loops que terminan en un "Council" que decide qué se ejecuta — incluyendo, más adelante, proponer departamentos/agentes nuevos cuando el sistema detecta una oportunidad.

Todo corre en un servidor propio, no en la nube de un tercero, para tener control total, no depender de una suscripción que se pueda caer, y no tener que pagar por asiento cada vez que se agrega un bot.

No se construyen los 40 bots de golpe: primero se levanta la infraestructura base (Paso 0), después se escribe el prompt/instrucciones de cada bot, y luego se arma un primer loop completo y funcionando (empezando por el cluster de Legal) antes de replicar el patrón al resto.

## Qué hay que levantar en el Paso 0

### 1. Un servidor (VPS)
Una máquina propia donde va a vivir todo el sistema. Algo pequeño (tipo 4GB RAM) alcanza para empezar, cuesta unos $5–6 USD al mes.

### 2. Un subdominio apuntando a ese servidor
Usamos el dominio que ya tenemos (bintix.mx), agregando un subdominio nuevo (ej. `n8n.bintix.mx`) que apunte a la IP del servidor. No se toca nada del sitio actual — solo se agregan registros DNS nuevos.

### 3. n8n
El orquestador: aquí se arma cada workflow (la secuencia de pasos que sigue cada bot, a quién le pasa su resultado, cuándo pide aprobación humana). Corre dentro del servidor, con Docker.

### 4. Una base de datos (Postgres)
La memoria compartida del sistema: guarda las tareas pendientes, qué corrió cada bot, los resultados, y las aprobaciones. Sin esto, cada corrida del sistema empezaría de cero y no habría verdadero "loop" de mejora continua.

### 5. Un router de modelos de IA (OmniRoute)
Una capa intermedia entre los bots y los distintos proveedores de IA (Gemini, Groq, y demás que ya tenemos gratis). En vez de cablear cada API por separado en cada bot, todos hablan con un solo punto, y este decide automáticamente qué modelo usar según disponibilidad/costo — usando primero las opciones gratis y dejando el presupuesto pagado para los bots que sí lo necesitan (los de mayor riesgo o razonamiento, como el Council o el Hacker ético).

### 6. HTTPS (certificado de seguridad)
Para que el panel de n8n y el router no queden expuestos sin cifrar. Se resuelve automáticamente con Caddy, un servicio que corre junto a todo lo demás.

### 7. Un repositorio de GitHub
Ahí se guardan versionados el archivo de configuración del servidor, y — lo más importante — el prompt/instrucciones de cada uno de los ~40 bots, en vez de tenerlos solo dentro de n8n.

### 8. Un bot de Telegram
El canal de aprobación humana: cuando un bot necesita luz verde antes de gastar dinero, publicar algo, o tocar un tema legal o de seguridad, manda el aviso ahí.

### 9. Backups básicos
Una copia diaria automática de la base de datos, para no perder todo el historial si algo falla en el servidor.

## Al terminar el Paso 0, el sistema debe poder:

- Abrir el panel de n8n desde el subdominio, con HTTPS.
- Guardar y leer datos en la base de datos propia.
- Hacer una llamada de prueba a un modelo de IA a través del router y recibir respuesta.
- Mandar un mensaje de prueba al grupo de Telegram.
- Tener el repositorio de GitHub creado con la estructura de carpetas lista para empezar a llenar los prompts de cada bot (siguiente paso).
