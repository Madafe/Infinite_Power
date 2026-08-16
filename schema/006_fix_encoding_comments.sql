-- Corrige el mojibake introducido en dos COMMENT ON COLUMN aplicados
-- anteriormente via psql/PowerShell sin forzar UTF-8 en el pipe.
-- No cambia estructura ni datos de negocio, solo re-declara los comentarios
-- con el texto correcto.

comment on column bots.conocimiento_directo is
  'Excepcion angosta: true SOLO si lo que este bot aprende nunca tiene valor fuera de su propio campo (ej. Trouble shooter con errores de infraestructura). Default false: cualquier bot nuevo pasa por Efadam salvo que se justifique explicitamente lo contrario.';

comment on column tasks.nivel_importancia is
  E'Asignado por Efadam al despachar la tarea, aplicando las reglas fijas de stack_y_convenciones.md. El bot que ejecuta la tarea lo hereda — nunca lo decide ni lo cambia. El nivel se manda tal cual en el campo `model` del request al nodo "Llamar a omniroute" del Ejecutor genérico; OmniRoute resuelve ese valor a un modelo real via sus "combos" nombrados (ver stack_y_convenciones.md — mecanismo exacto de creación de combos aún no confirmado al 16 de agosto de 2026).';
