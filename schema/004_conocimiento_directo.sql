-- =====================================================================
-- 003_conocimiento_directo.sql — Excepción angosta al principio de
-- "todo pasa por Efadam" en knowledge_log.
--
-- Decisión de Mateo (14/ago/2026, noche): Efadam sigue siendo el dueño
-- por default de knowledge_log. La única forma de que un bot escriba
-- directo, sin pasar por Efadam, es que su conocimiento NO aporte nada
-- fuera del campo exacto en el que ese bot trabaja — no es una regla por
-- "tipo" de hallazgo, es una excepción explícita por bot, opt-in, y se
-- espera que sea rara.
-- =====================================================================

alter table bots add column if not exists conocimiento_directo boolean not null default false;

comment on column bots.conocimiento_directo is
  'Excepción angosta: true SOLO si lo que este bot aprende nunca tiene valor fuera de su propio campo (ej. Trouble shooter con errores de infraestructura). Default false: cualquier bot nuevo pasa por Efadam salvo que se justifique explícitamente lo contrario.';

-- Único bot que hoy califica: sus patrones son errores de n8n/Postgres/infra,
-- irrelevantes para Legal, Estrategia o cualquier otra rama.
update bots set conocimiento_directo = true where slug = 'trouble_shooter';

-- Verificación
-- select slug, conocimiento_directo from bots order by slug;
