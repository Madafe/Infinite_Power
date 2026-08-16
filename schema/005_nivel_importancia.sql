-- =====================================================================
-- 005_nivel_importancia.sql — Niveles de importancia por tarea
--
-- Implementa lo decidido en stack_y_convenciones.md ("Niveles de
-- importancia y BYOK") y efadam.md ("Modelo sugerido"): Efadam asigna
-- el nivel al despachar cada tarea, aplicando reglas fijas por
-- dominio/tema — no lo decide el bot que ejecuta, y no es un valor fijo
-- por bot (por eso vive en `tasks`, no en `bots`).
--
-- Reemplaza el uso de `bots.default_model` como fuente del modelo a
-- llamar. `default_model` queda en la tabla sin usarse por el momento
-- (no se elimina la columna: podría servir para casos puntuales donde
-- un bot necesite forzar un modelo específico fuera de niveles, pero
-- eso no está decidido — no se construye hasta que haga falta).
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1) tasks.nivel_importancia
-- ---------------------------------------------------------------------
alter table tasks add column if not exists nivel_importancia text
    check (nivel_importancia in ('bajo','medio','alto','critico'));

comment on column tasks.nivel_importancia is
  'Asignado por Efadam al despachar la tarea, aplicando las reglas fijas de stack_y_convenciones.md. El bot que ejecuta la tarea lo hereda — nunca lo decide ni lo cambia. Se traduce a un modelo real en el nodo "Llamar a OmniRoute" del Ejecutor genérico: se manda tal cual en el campo `model` del request, y el proxy (OmniRoute) resuelve el alias al modelo real configurado para esa instalación.';

-- Nota de encoding: se usa 'critico' sin tilde (no 'crítico') porque es
-- un valor interno de sistema (check constraint, alias del proxy), no
-- texto que un humano lee. Consistencia con el resto de valores en
-- minúsculas sin acento (`bajo`, `medio`, `alto`). La documentación en
-- prosa (docs/, prompts) sigue escribiendo "crítico" con tilde: ese es
-- texto para humanos/LLM, no un identificador de sistema.

-- ---------------------------------------------------------------------
-- 2) Verificación — corre esto después
-- ---------------------------------------------------------------------
-- select conname, pg_get_constraintdef(oid) from pg_constraint where conrelid = 'tasks'::regclass;
