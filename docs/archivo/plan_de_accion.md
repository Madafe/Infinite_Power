> **ARCHIVADO — 14 de agosto de 2026.** Borrador original del 7/ago, superado
> por `docs/archivo/plan_de_accion_completo.md` (que a su vez ya no es fuente
> de verdad de nada — ver [[estado_del_proyecto]]). Se conserva solo por
> trazabilidad de las decisiones de infraestructura iniciales.

---

# Plan de acción — "Infinite power" (sistema de agentes autogestionado)

Para: Mateo + amigo
Fecha: 7 de agosto de 2026

## Recursos con los que ya cuentan

- 2 personas construyendo
- APIs gratis: Gemini, Groq, y otras vía **OmniRoute** (gateway gratuito y open source que pone un solo endpoint tipo OpenAI enfrente de 290+ proveedores y 500+ modelos, con fallback automático cuando se acaba una cuota gratis — [github.com/diegosouzapw/OmniRoute](https://github.com/diegosouzapw/OmniRoute))
- opencode instalado (los 2)
- Codex (los 2)
- Claude Pro (Mateo, tiempo incierto)
- Presupuesto pagado: amigo $200 MXN en API de Gemini, Mateo $150 MXN para otra API
- Un dominio propio

## Decisiones de infraestructura (antes de tocar los prompts)

1. **Servidor:** un VPS pequeño (Hetzner CX22, ~$4.50–6 USD/mes, 4GB RAM) alcanza sobrado para correr n8n + base de datos vía Docker Compose. Con su dominio apuntando (registro DNS tipo A) a la IP de ese servidor, ya tienen "hosting" propio — el dominio por sí solo no aloja nada, necesita un servidor detrás. Si quieren evitar el costo mensual, pueden intentar la capa "Always Free" de Oracle Cloud (4 OCPU / 24GB ARM gratis de por vida), aunque la disponibilidad de esas instancias es irregular. Empezar con Hetzner es más simple y cabe en el presupuesto de uno de los dos.
2. **Base de datos / memoria compartida:** Postgres corriendo en el mismo VPS (Docker), no Supabase. Supabase free pausa el proyecto tras 7 días sin actividad, y este sistema necesita estar disponible siempre que corra el loop. Postgres propio no tiene ese límite y es gratis mientras tengan el VPS.
3. **Orquestador:** n8n self-hosted (gratis, sin límite de workflows) en el mismo VPS.
4. **Router de modelos:** OmniRoute también self-hosted en el VPS, como capa intermedia entre n8n y los modelos. Así cada agente solo llama "un" endpoint, y OmniRoute decide si usa Gemini, Groq, u otro según cuota disponible — evita tener que cablear credenciales distintas en cada nodo de n8n.
5. **Repositorio:** GitHub privado para guardar los prompts de cada bot como archivos de texto (no solo dentro de n8n), scripts de opencode/Codex, y el docker-compose. Así los dos pueden versionar cambios y opencode/Codex pueden leer/editar directamente.
6. **Canal de aprobación humana:** un bot de Telegram (gratis) para que el sistema pida luz verde antes de acciones que gastan dinero, publican algo, o tocan temas legales.
7. **Gestión de gastos:** ya que ambos aportan presupuesto pagado, resérvenlo para el modelo de mayor razonamiento (Council, Abogado Jefe, Consultor de negocios) — todo lo demás corre en las capas gratis vía OmniRoute.

## Fases

### Fase 0 — Infraestructura base (1 fin de semana)
Levantar VPS, Docker Compose con n8n + Postgres + OmniRoute, apuntar el dominio, dar de alta el repo de GitHub, crear el bot de Telegram.

### Fase 1 — Definir instrucciones de cada bot ⬅️ **siguiente paso, ahora**
Ver hoja de cálculo adjunta. Por cada bot del diagrama: objetivo en una línea, qué recibe, qué entrega, qué herramientas necesita, qué modelo le conviene, y si puede actuar solo o necesita aprobación humana. Se divide el trabajo por cluster entre los dos.

### Fase 2 — Rebanada vertical completa
No construir las 40 cajas a la vez. Elegir **un loop pequeño y de bajo riesgo** para probar el patrón completo (memoria en Postgres + ejecución en n8n + aprobación humana + logging). El cluster de **Legal** (Abogado Scouter → Abogado Jefe → Abogado verificador) es buen candidato: son solo 3 agentes, con un checkpoint humano natural. El cluster de **Investigación/Skill finder** también sirve porque es de solo lectura (sin riesgo).

### Fase 3 — Orquestación multi-cluster
Una vez que un cluster funciona solo de forma confiable, replicar el patrón: cada cluster del diagrama como un sub-workflow de n8n, conectado por `Execute Workflow` y por una tabla de "tareas pendientes" en Postgres que actúa como bandeja de entrada entre clusters (así se parece al diagrama real, en vez de un solo workflow gigante).

### Fase 4 — Monitoreo y control de costos
Tabla de logs en Postgres (qué bot corrió, qué modelo usó, costo estimado, resultado). Alertas por Telegram si un cluster se pasa de un límite diario de llamadas o gasto.

### Fase 5 — Autonomía progresiva
Empezar disparando el loop maestro por horario (ej. una vez al día) en vez de continuo. Ir quitando checkpoints humanos cluster por cluster solo cuando lleve 1–2 semanas sin errores.

### Fase 6 — Auto-expansión ("Nuevos departamentos")
Dejar para el final: que el Council pueda crear un nuevo sub-workflow/agente automáticamente vía la API de n8n. Es la parte más avanzada y frágil del diagrama — no vale la pena antes de que el resto esté sólido.

## Próximo paso concreto

Abran la hoja `roster_agentes.xlsx`: tiene ya cada bot del diagrama con un borrador de objetivo, modelo sugerido y nivel de autonomía. Repártanse las filas por cluster, corrijan lo que no aplique, y completen la columna de "Prompt del sistema" con la instrucción real de cada bot — esa columna es lo que después se pega directamente en el nodo AI Agent de n8n.
