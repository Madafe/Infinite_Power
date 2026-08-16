-- =====================================================================
-- 001_init.sql -- Esquema base de Infinite Power (tasks / bots / approvals
-- / agent_runs). Reconstruido el 16 de agosto de 2026 a partir de un
-- pg_dump --schema-only contra la base real, restando lo que 002-005
-- agregan (ver detalle abajo) -- nunca se habia commiteado y por eso un
-- clon nuevo del repo no podia levantar la base de datos (hallazgo del
-- audit del 16/ago/2026, item de reproducibilidad).
--
-- Corre PRIMERO, contra una base Postgres vacia. Despues, en orden:
-- 002_conocimiento.sql, 003_trouble_shooter_v2.sql,
-- 004_conocimiento_directo.sql, 005_nivel_importancia.sql,
-- 006_fix_encoding_comments.sql.
--
-- Que agrega cada migracion posterior (para que quede claro que NO debe
-- estar aqui):
--   002 -> tasks.parent_task_id, tasks_parent_idx, tasks_status_check,
--         bots.contexto_slugs, bots.prompt_especifico,
--         funcion + trigger componer_system_prompt(), tablas
--         system_knowledge y knowledge_log, semilla de reglas_generales.
--   003 -> solo datos (prompt de trouble_shooter), sin cambios de schema.
--   004 -> bots.conocimiento_directo.
--   005 -> tasks.nivel_importancia.
--   006 -> corrige encoding de dos comentarios de columna (sin cambios
--         de estructura).
-- =====================================================================

CREATE TABLE public.agent_runs (
    id integer NOT NULL,
    task_id integer,
    bot text NOT NULL,
    model_used text,
    tokens_input integer,
    tokens_output integer,
    cost_estimate numeric,
    duration_ms integer,
    created_at timestamp with time zone DEFAULT now()
);

CREATE SEQUENCE public.agent_runs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.agent_runs_id_seq OWNED BY public.agent_runs.id;

ALTER TABLE ONLY public.agent_runs
    ALTER COLUMN id SET DEFAULT nextval('public.agent_runs_id_seq'::regclass);

ALTER TABLE ONLY public.agent_runs
    ADD CONSTRAINT agent_runs_pkey PRIMARY KEY (id);


CREATE TABLE public.approvals (
    id integer NOT NULL,
    task_id integer,
    requested_at timestamp with time zone DEFAULT now(),
    resolved_at timestamp with time zone,
    approved boolean,
    approver text
);

CREATE SEQUENCE public.approvals_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.approvals_id_seq OWNED BY public.approvals.id;

ALTER TABLE ONLY public.approvals
    ALTER COLUMN id SET DEFAULT nextval('public.approvals_id_seq'::regclass);

ALTER TABLE ONLY public.approvals
    ADD CONSTRAINT approvals_pkey PRIMARY KEY (id);


CREATE TABLE public.bots (
    id integer NOT NULL,
    slug text NOT NULL,
    cluster text NOT NULL,
    system_prompt text NOT NULL,
    default_model text DEFAULT 'auto'::text NOT NULL,
    requires_approval boolean DEFAULT false NOT NULL,
    dispatches_tasks boolean DEFAULT false NOT NULL,
    active boolean DEFAULT true NOT NULL
);

CREATE SEQUENCE public.bots_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.bots_id_seq OWNED BY public.bots.id;

ALTER TABLE ONLY public.bots
    ALTER COLUMN id SET DEFAULT nextval('public.bots_id_seq'::regclass);

ALTER TABLE ONLY public.bots
    ADD CONSTRAINT bots_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.bots
    ADD CONSTRAINT bots_slug_key UNIQUE (slug);


CREATE TABLE public.tasks (
    id integer NOT NULL,
    cluster text NOT NULL,
    bot text NOT NULL,
    status text DEFAULT 'pending'::text NOT NULL,
    input jsonb,
    output text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

CREATE SEQUENCE public.tasks_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.tasks_id_seq OWNED BY public.tasks.id;

ALTER TABLE ONLY public.tasks
    ALTER COLUMN id SET DEFAULT nextval('public.tasks_id_seq'::regclass);

ALTER TABLE ONLY public.tasks
    ADD CONSTRAINT tasks_pkey PRIMARY KEY (id);


ALTER TABLE ONLY public.agent_runs
    ADD CONSTRAINT agent_runs_task_id_fkey FOREIGN KEY (task_id) REFERENCES public.tasks(id);

ALTER TABLE ONLY public.approvals
    ADD CONSTRAINT approvals_task_id_fkey FOREIGN KEY (task_id) REFERENCES public.tasks(id);
