-- =====================================================================
-- 005_nivel_importancia.sql — Esfuerzo por tarea
-- (Se conserva el nombre de archivo para no alterar el historial de migraciones.)
--
-- El esfuerzo se calcula para cada tarea concreta: primero por complejidad
-- y después por la preferencia de servicio (velocidad, equilibrio o
-- rendimiento). El riesgo se gestiona por aprobaciones y controles aparte.
-- Efadam recomienda el enfoque de la operación; los centers asignan el
-- esfuerzo de las tareas que descomponen y despachan.
--
-- Reemplaza el uso de `bots.default_model` como fuente del modelo a
-- llamar. `default_model` queda en la tabla sin usarse por el momento
-- (no se elimina la columna: podría servir para casos puntuales donde
-- un bot necesite forzar un modelo específico fuera de niveles, pero
-- eso no está decidido — no se construye hasta que haga falta).
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1) tasks.esfuerzo
-- ---------------------------------------------------------------------
alter table tasks add column if not exists esfuerzo text
    check (esfuerzo in ('bajo','medio','alto','critico'));

comment on column tasks.esfuerzo is
  'Esfuerzo de razonamiento de la tarea concreta. El center lo calcula con complejidad y preferencia de servicio; riesgo y aprobaciones se gestionan aparte. El Ejecutor genérico lo traduce a un modelo real mediante OmniRoute.';

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
