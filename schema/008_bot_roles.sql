-- 008_bot_roles.sql
-- Tabla dedicada para el nivel de modelo fijo de bots orquestadores,
-- separada a propósito de bots.dispatches_tasks (ver
-- plan_de_accion_completo.md, actualización del 19 de agosto, cuarta ronda,
-- y reglas_generales.md punto 6 "Diseña para que el sistema se autoexpanda
-- fácil"). Un bot con fila aquí corre siempre en nivel_fijo sin importar el
-- dominio de la tarea que coordina -- esto solo cambia qué modelo lo ejecuta,
-- nunca el tasks.nivel_importancia de la tarea en sí (esa sigue viniendo de
-- las reglas de asignación normales, y sigue siendo lo que decide si hace
-- falta aprobación humana). Confirmado por Mateo el 19 de agosto de 2026.

CREATE TABLE public.bot_niveles_fijos (
    id serial PRIMARY KEY,
    bot_slug text NOT NULL UNIQUE REFERENCES public.bots(slug),
    nivel_fijo text NOT NULL CHECK (nivel_fijo IN ('bajo','medio','alto','critico')),
    razon text,
    created_at timestamptz DEFAULT now()
);
