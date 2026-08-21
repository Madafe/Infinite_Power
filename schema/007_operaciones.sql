-- =====================================================================
-- 007_operaciones.sql — Operaciones: hilo de trabajo completo
--
-- Implementa lo pedido por Mateo el 18/ago, noche, tercera y cuarta ronda:
-- trackear "cada cosa que el programa completo debe hacer" (investigaciones,
-- autoexpansión, tareas de usuario) como una unidad, sin depender de
-- recorrer parent_task_id a mano. CENTRALIZADO: solo Efadam abre una
-- operación nueva (decisión explícita de Mateo, cuarta ronda — "si no se
-- elimina el cuello de botella"). Las tareas (`tasks`) siguen pudiendo
-- despacharse cluster a cluster sin pasar por Efadam, como siempre — lo
-- que se centraliza es el ORIGEN del hilo (la operación), no cada tarea
-- dentro de ella.
--
-- operations.esfuerzo es la preferencia actual de la operación, recomendada
-- inicialmente por Efadam y ajustable por el usuario desde la interfaz.
-- Cada center calcula por separado el esfuerzo de sus tareas concretas;
-- una operación no obliga el mismo esfuerzo a toda su cadena de trabajo.
--
-- Es idempotente: se puede correr varias veces sin romper nada.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1) operations — el hilo completo de trabajo
-- ---------------------------------------------------------------------
create table if not exists operations (
    id                 serial primary key,
    tipo               text        not null,  -- 'usuario' | 'investigacion' | 'autoexpansion' | ... (sin CHECK: se espera que la lista crezca, igual que tasks.cluster)
    titulo             text        not null,
    descripcion        text,
    esfuerzo  text        not null check (esfuerzo in ('bajo','medio','alto','critico')),
    status             text        not null default 'abierta',  -- abierta | en_progreso | completada | fallida | bloqueada
    created_at         timestamptz not null default now(),
    updated_at         timestamptz not null default now(),
    closed_at          timestamptz
);

comment on table operations is
  'El hilo completo de trabajo ("cada cosa que el programa completo debe hacer" - Mateo, 18/ago). CENTRALIZADO: solo Efadam inserta filas nuevas aqui (a diferencia de tasks, que cualquier cluster puede despachar). Una operacion puede cruzar varios clusters/tasks en su vida.';

comment on column operations.esfuerzo is
  'Preferencia de esfuerzo vigente para la operacion. Efadam propone el valor inicial y el usuario puede ajustarlo desde la interfaz. Cada center calcula el esfuerzo de las tareas concretas sin obligarlas a heredar este valor.';

-- ---------------------------------------------------------------------
-- 2) tasks.operation_id — a qué operación pertenece esta tarea
-- ---------------------------------------------------------------------
alter table tasks add column if not exists operation_id int references operations(id);

comment on column tasks.operation_id is
  'A que operacion pertenece esta tarea. Nullable por ahora (transicion: tareas manuales/de prueba, o creadas antes de que Efadam exista como bot activo, pueden no tener una). Se propaga de padre a hijo via subquery SQL (SELECT operation_id FROM tasks WHERE id = parent_task_id) en los nodos que crean tareas.';

-- ---------------------------------------------------------------------
-- 3) Verificación — corre esto después
-- ---------------------------------------------------------------------
-- select column_name, data_type from information_schema.columns where table_name = 'operations' order by ordinal_position;
-- select column_name, data_type from information_schema.columns where table_name = 'tasks' and column_name = 'operation_id';
