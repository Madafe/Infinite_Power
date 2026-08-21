-- =====================================================================
-- 009_renombrar_esfuerzo.sql — Esfuerzo por operación y tarea
--
-- Reemplaza el nombre histórico `nivel_importancia` por `esfuerzo`.
-- El esfuerzo describe la intensidad de razonamiento solicitada
-- (bajo/medio/alto/critico), no el riesgo ni el permiso para ejecutar.
-- Es idempotente y conserva los valores existentes.
-- =====================================================================

begin;

do $$
begin
  if to_regclass('public.bot_niveles_fijos') is not null
     and to_regclass('public.bot_esfuerzos_fijos') is null then
    alter table public.bot_niveles_fijos rename to bot_esfuerzos_fijos;
  end if;

  if to_regclass('public.bot_niveles_fijos_id_seq') is not null
     and to_regclass('public.bot_esfuerzos_fijos_id_seq') is null then
    alter sequence public.bot_niveles_fijos_id_seq rename to bot_esfuerzos_fijos_id_seq;
  end if;

  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'tasks'
      and column_name = 'nivel_importancia'
  ) then
    alter table public.tasks rename column nivel_importancia to esfuerzo;
  elsif not exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'tasks'
      and column_name = 'esfuerzo'
  ) then
    alter table public.tasks add column esfuerzo text
      check (esfuerzo in ('bajo','medio','alto','critico'));
  end if;

  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'operations'
      and column_name = 'nivel_importancia'
  ) then
    alter table public.operations rename column nivel_importancia to esfuerzo;
  elsif not exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'operations'
      and column_name = 'esfuerzo'
  ) then
    alter table public.operations add column esfuerzo text
      check (esfuerzo in ('bajo','medio','alto','critico'));
  end if;

  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'bot_esfuerzos_fijos'
      and column_name = 'nivel_fijo'
  ) then
    alter table public.bot_esfuerzos_fijos rename column nivel_fijo to esfuerzo_fijo;
  elsif not exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'bot_esfuerzos_fijos'
      and column_name = 'esfuerzo_fijo'
  ) then
    alter table public.bot_esfuerzos_fijos add column esfuerzo_fijo text
      check (esfuerzo_fijo in ('bajo','medio','alto','critico'));
  end if;
end $$;

-- PostgreSQL conserva el nombre de una constraint cuando se renombra una
-- columna. También lo actualizamos para que no queden identificadores viejos.
do $$
declare
  c record;
begin
  for c in
    select conrelid::regclass as relation_name, conname,
           replace(replace(conname, 'nivel_importancia', 'esfuerzo'),
                   'bot_niveles_fijos', 'bot_esfuerzos_fijos') as new_name
    from pg_constraint
    where connamespace = 'public'::regnamespace
      and (conname like '%nivel_importancia%' or conname like '%bot_niveles_fijos%')
  loop
    execute format('alter table %s rename constraint %I to %I',
      c.relation_name, c.conname, c.new_name);
  end loop;
end $$;

alter table public.operations
  add column if not exists esfuerzo_recomendado text
    check (esfuerzo_recomendado in ('bajo','medio','alto','critico')),
  add column if not exists esfuerzo_ajustado_at timestamptz,
  add column if not exists esfuerzo_ajustado_por text;

update public.operations
set esfuerzo_recomendado = esfuerzo
where esfuerzo_recomendado is null;

create table if not exists public.operation_effort_adjustments (
  id serial primary key,
  operation_id int not null references public.operations(id),
  esfuerzo_anterior text not null check (esfuerzo_anterior in ('bajo','medio','alto','critico')),
  esfuerzo_nuevo text not null check (esfuerzo_nuevo in ('bajo','medio','alto','critico')),
  ajustado_por text not null,
  motivo text,
  created_at timestamptz not null default now()
);

create or replace function public.ajustar_esfuerzo_operacion(
  p_operation_id int,
  p_esfuerzo text,
  p_ajustado_por text,
  p_motivo text default null
) returns void
language plpgsql
as $$
declare
  v_anterior text;
begin
  if p_esfuerzo is null or p_esfuerzo not in ('bajo','medio','alto','critico') then
    raise exception 'Esfuerzo inválido: %', p_esfuerzo;
  end if;

  if p_ajustado_por is null or btrim(p_ajustado_por) = '' then
    raise exception 'El ajuste debe identificar a quien lo realizó';
  end if;

  select esfuerzo into v_anterior
  from public.operations
  where id = p_operation_id
  for update;

  if not found then
    raise exception 'Operación % no existe', p_operation_id;
  end if;

  if v_anterior = p_esfuerzo then
    return;
  end if;

  update public.operations
  set esfuerzo = p_esfuerzo,
      esfuerzo_ajustado_at = now(),
      esfuerzo_ajustado_por = p_ajustado_por,
      updated_at = now()
  where id = p_operation_id;

  insert into public.operation_effort_adjustments (
    operation_id, esfuerzo_anterior, esfuerzo_nuevo, ajustado_por, motivo
  ) values (
    p_operation_id, v_anterior, p_esfuerzo, p_ajustado_por, p_motivo
  );
end;
$$;

create or replace view public.operaciones_activas as
select
  o.id,
  o.titulo,
  o.status,
  o.esfuerzo,
  o.esfuerzo_recomendado,
  o.esfuerzo_ajustado_at,
  o.esfuerzo_ajustado_por,
  o.updated_at,
  count(t.id) filter (where t.status = 'running') as tareas_en_ejecucion,
  count(t.id) filter (where t.status = 'pending') as tareas_pendientes
from public.operations o
left join public.tasks t on t.operation_id = o.id
where o.status in ('abierta', 'en_progreso', 'bloqueada')
group by o.id;

comment on column public.tasks.esfuerzo is
  'Esfuerzo de razonamiento de esta tarea concreta. Se calcula por complejidad y preferencia de servicio; no expresa riesgo ni sustituye aprobaciones.';
comment on column public.operations.esfuerzo is
  'Esfuerzo actual preferido para la operacion. El usuario puede ajustarlo desde la interfaz; las tareas concretas conservan su propio esfuerzo.';
comment on column public.operations.esfuerzo_recomendado is
  'Recomendacion inicial calculada por Efadam antes de cualquier ajuste manual.';
comment on table public.operation_effort_adjustments is
  'Historial auditable de ajustes manuales de esfuerzo desde la interfaz de operaciones.';
comment on view public.operaciones_activas is
  'Vista de lectura para la interfaz: operaciones activas, esfuerzo vigente, recomendación, último ajuste y progreso básico.';

commit;

-- Contrato de interfaz para una operacion activa:
-- 1) leer operaciones_activas para mostrar titulo, status, esfuerzo,
--    esfuerzo_recomendado, último ajuste y progreso básico;
-- 2) al ajustar esfuerzo, llamar ajustar_esfuerzo_operacion(...), que actualiza
--    solo operations.esfuerzo y registra el cambio en operation_effort_adjustments;
-- 3) no reescribir tareas running; el center reevalua las pending al crear
--    o replanear trabajo posterior.
