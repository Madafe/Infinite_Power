select jsonb_array_elements(nodes::jsonb) ->> 'name' as nombre_nodo
from workflow_entity
where id = 'aVORciBJl52lTxTU'
order by 1;
