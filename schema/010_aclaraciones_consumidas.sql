-- =====================================================================
-- 010_aclaraciones_consumidas.sql — Consumo determinístico de aclaraciones
--
-- El Reanudador de bloqueados reanuda una tarea padre bloqueada cuando su
-- tarea hija de aclaracion queda en status = 'done'. Si un padre llega a
-- tener mas de una hija de aclaracion resuelta (dos rondas de aclaracion,
-- o una condicion de carrera), el UPDATE ... FROM original no tenia forma
-- de elegir una sola de manera determinista ni de marcarla como usada:
-- Postgres podia tomar cualquiera de las filas candidatas, y el resto
-- quedaba huerfano sin registro de que nunca se proceso.
--
-- Este cambio agrega una columna generica de consumo (mismo patron que
-- created_at/updated_at) para que el reanudador pueda seleccionar
-- exactamente una aclaracion elegible por padre, en un orden estable, y
-- marcarla consumida en la misma transaccion que reanuda al padre.
-- Es idempotente y no toca datos existentes (todas las filas actuales
-- quedan con consumed_at = null, es decir, "todavia no procesadas" segun
-- la nueva convencion, sin efecto retroactivo).
-- =====================================================================

begin;

alter table public.tasks
  add column if not exists consumed_at timestamptz;

comment on column public.tasks.consumed_at is
  'Marca cuando esta tarea (tipicamente una aclaracion) ya fue usada para reanudar a su padre. Null = todavia no consumida. Evita que el Reanudador de bloqueados reutilice o pierda una aclaracion cuando un padre tiene mas de una hija resuelta.';

commit;
