-- Corrige el mojibake introducido en dos COMMENT ON COLUMN aplicados
-- anteriormente via psql/PowerShell sin forzar UTF-8 en el pipe.
-- No cambia estructura ni datos de negocio, solo re-declara los comentarios
-- con el texto correcto.

comment on column bots.conocimiento_directo is
  'Excepcion angosta: true SOLO si lo que este bot aprende nunca tiene valor fuera de su propio campo (ej. Trouble shooter con errores de infraestructura). Default false: cualquier bot nuevo pasa por Efadam salvo que se justifique explicitamente lo contrario.';

comment on column tasks.esfuerzo is
  E'Esfuerzo de razonamiento de la tarea concreta. El center lo calcula por complejidad y preferencia de servicio; riesgo y aprobaciones se gestionan aparte. El esfuerzo se manda al nodo "Llamar a OmniRoute" del Ejecutor genérico, que lo resuelve al modelo configurado.';
