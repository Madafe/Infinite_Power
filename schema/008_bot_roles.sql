-- 008_bot_roles.sql
-- Tabla dedicada para el esfuerzo de modelo fijo de bots orquestadores,
-- separada a propósito de bots.dispatches_tasks (ver
-- plan_de_accion_completo.md, actualización del 19 de agosto, cuarta ronda,
-- y reglas_generales.md punto 6 "Diseña para que el sistema se autoexpanda
-- fácil"). Un bot con fila aquí corre siempre en esfuerzo_fijo sin importar el
-- dominio de la tarea que coordina -- esto solo cambia qué modelo lo ejecuta,
-- nunca el tasks.esfuerzo de la tarea en sí (esa la calcula el center según
-- complejidad y preferencia de servicio). Las aprobaciones se definen por
-- sus propios controles, no por el esfuerzo.

CREATE TABLE public.bot_esfuerzos_fijos (
    id serial PRIMARY KEY,
    bot_slug text NOT NULL UNIQUE REFERENCES public.bots(slug),
    esfuerzo_fijo text NOT NULL CHECK (esfuerzo_fijo IN ('bajo','medio','alto','critico')),
    razon text,
    created_at timestamptz DEFAULT now()
);
