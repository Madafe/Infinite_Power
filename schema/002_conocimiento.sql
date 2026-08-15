-- =====================================================================
-- 002_conocimiento.sql — Memoria del sistema Infinite Power
-- Corre DESPUÉS de init.sql (tablas tasks / approvals / agent_runs)
-- y DESPUÉS de que exista la tabla `bots` (ver ejecutor_generico.md).
--
-- Es idempotente: se puede correr varias veces sin romper nada.
-- =====================================================================


-- ---------------------------------------------------------------------
-- 1) system_knowledge — autoconciencia del sistema
--    NO se escribe a mano aquí. La fuente de verdad son los archivos
--    docs/context/*.md del repo; esta tabla es una copia sincronizada
--    para que los bots la lean sin salir a GitHub en cada corrida.
-- ---------------------------------------------------------------------
create table if not exists system_knowledge (
    slug        text primary key,              -- 'arquitectura', 'stack_y_convenciones', 'reglas_generales'
    titulo      text        not null,
    contenido   text        not null,
    source_file text,                          -- ruta en el repo de donde salió
    updated_at  timestamptz not null default now()
);


-- ---------------------------------------------------------------------
-- 2) knowledge_log — bitácora de casos y hallazgos
--    Dos tipos, con dueño y ritmo distintos (ver docs/memoria_del_sistema.md):
--      'patron_fallo'  → lo escribe el ejecutor automáticamente desde
--                        el campo patron_aprendido de Trouble shooter.
--      'aprendizaje'   → lo escribe Efadam, tras el reporte de un center.
-- ---------------------------------------------------------------------
create table if not exists knowledge_log (
    id               serial primary key,
    tipo             text        not null check (tipo in ('patron_fallo','aprendizaje')),
    titulo           text        not null,
    resumen_corto    text        not null,
    detalle_completo text,
    cluster          text,                     -- null = aplica a todo el sistema
    origen_bot       text,
    task_id          int references tasks(id),
    veces_visto      int         not null default 1,
    activo           boolean     not null default true,
    created_at       timestamptz not null default now(),
    updated_at       timestamptz not null default now()
);

-- Deduplicación automática de patrones de fallo: si Trouble shooter reporta
-- un patrón con el mismo título, en vez de crear una fila nueva se incrementa
-- veces_visto. Esto reemplaza la regla "si lo viste 3+ veces márcalo como
-- recurrente" que hoy depende de que el LLM se acuerde — ahora lo cuenta la BD.
create unique index if not exists knowledge_log_patron_uniq
    on knowledge_log (lower(titulo))
    where tipo = 'patron_fallo';

create index if not exists knowledge_log_lookup
    on knowledge_log (tipo, cluster, activo, updated_at desc);


-- ---------------------------------------------------------------------
-- 3) tasks — linaje
--    parent_task_id sirve para trazabilidad hoy (¿quién pidió esto?) y es
--    prerrequisito del sistema de aclaración/reanudación más adelante.
-- ---------------------------------------------------------------------
alter table tasks add column if not exists parent_task_id int references tasks(id);
create index if not exists tasks_parent_idx on tasks (parent_task_id);

-- Estados válidos, explícitos. Evita que un typo en un nodo deje una tarea
-- en un status que ningún query vuelve a mirar.
alter table tasks drop constraint if exists tasks_status_check;
alter table tasks add constraint tasks_status_check
    check (status in ('pending','running','done','failed','blocked','needs_approval'));


-- ---------------------------------------------------------------------
-- 4) bots — qué contexto recibe cada bot, y composición del prompt
-- ---------------------------------------------------------------------

-- Qué slugs de system_knowledge se le inyectan a este bot. Vacío = ninguno.
-- Sin esto, todos los bots cargarían toda la arquitectura en cada llamada:
-- caro, lento, y ruido puro para bots como Abogado Jefe.
alter table bots add column if not exists contexto_slugs text[] not null default '{}';

-- El prompt específico del bot, SIN las reglas generales.
-- system_prompt pasa a ser un campo derivado (ver trigger abajo).
alter table bots add column if not exists prompt_especifico text;


-- Semilla obligatoria: las reglas generales, antes del trigger.
insert into system_knowledge (slug, titulo, contenido, source_file) values
('reglas_generales', 'Reglas generales de Infinite Power', $REGLAS$## Reglas generales — aplican a todos los bots de Infinite Power

### 1. Piensa antes de actuar
No asumas, no escondas confusión, expón los tradeoffs. Ante la duda, siempre pregunta — nunca declares un supuesto y sigas adelante en su lugar. No hay un humano viendo en tiempo real que corrija una suposición equivocada; para cuando alguien la revise, ya se ejecutó. Usa el mecanismo de aclaración (`NECESITA_ACLARACION:`) en cuanto identifiques algo que no sabes con certeza y que cambiaría el resultado. Si existen varias interpretaciones válidas, pregunta cuál aplica — no elijas una en silencio. Si hay una forma más simple, dilo.

### 2. Simplicidad primero
El mínimo trabajo que resuelve el problema. Nada especulativo: sin features de más, sin abstracciones para uso único, sin manejo de errores para escenarios imposibles.

### 3. Cambios quirúrgicos
Toca solo lo que debes tocar. No "mejores" código o texto adyacente que no te pidieron cambiar. Si notas algo roto sin relación, menciónalo — no lo arregles sin que te lo pidan.

### 4. Ejecución orientada a metas
Define criterios de éxito verificables antes de dar por terminada una tarea. Para tareas de código: escribe primero una prueba que reproduzca el problema o valide el requisito, luego resuélvelo.

### 5. Cuándo pedir aclaración
Si te falta información esencial y no puedes proceder sin asumir algo importante, no lo inventes: responde ÚNICAMENTE con `NECESITA_ACLARACION: ` seguido de tu pregunta específica, sin nada más antes ni después. Úsalo solo cuando de verdad no puedas continuar — no lo abuses para evitar decisiones menores que sí puedes resolver razonablemente.$REGLAS$,
 'reglas_generales.md')
on conflict (slug) do update
   set titulo = excluded.titulo,
       contenido = excluded.contenido,
       source_file = excluded.source_file,
       updated_at = now();


-- Trigger: system_prompt = reglas_generales + '---' + prompt_especifico.
-- Motivo: la regla del proyecto es que las reglas generales viajen DENTRO del
-- system_prompt del bot (no inyectadas por n8n), pero hacerlo a mano garantiza
-- que tarde o temprano alguien las prepende dos veces o se le olvide. Con esto,
-- editar un prompt = editar prompt_especifico y ya.
create or replace function componer_system_prompt() returns trigger as $FN$
declare reglas text;
begin
  select contenido into reglas from system_knowledge where slug = 'reglas_generales';
  if reglas is null then
    raise exception 'Falta system_knowledge.slug = ''reglas_generales''; corre la semilla antes.';
  end if;
  new.system_prompt := reglas || E'\n\n---\n\n' || new.prompt_especifico;
  return new;
end;
$FN$ language plpgsql;

drop trigger if exists trg_componer_system_prompt on bots;
create trigger trg_componer_system_prompt
before insert or update of prompt_especifico on bots
for each row when (new.prompt_especifico is not null)
execute function componer_system_prompt();


-- Backfill: los bots ya insertados (tecnico_jefe, coder) nunca recibieron las
-- reglas generales — se insertaron antes de que existiera esa regla.
-- Este UPDATE dispara el trigger y las agrega.
update bots
   set prompt_especifico = system_prompt
 where prompt_especifico is null;


-- ---------------------------------------------------------------------
-- 5) Contexto asignado a los bots que ya existen
-- ---------------------------------------------------------------------
update bots set contexto_slugs = '{arquitectura,stack_y_convenciones}' where slug = 'tecnico_jefe';
update bots set contexto_slugs = '{stack_y_convenciones}'              where slug = 'coder';


-- ---------------------------------------------------------------------
-- 6) Verificaciones — corre esto después y revisa la salida
-- ---------------------------------------------------------------------
-- select slug, contexto_slugs, left(system_prompt, 60) as inicio_prompt from bots;
-- select conname, pg_get_constraintdef(oid) from pg_constraint where conrelid = 'tasks'::regclass;
-- select slug, titulo, length(contenido) from system_knowledge;
