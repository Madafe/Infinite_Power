# Autonomía progresiva — criterio de graduación

> Extraído de `plan_de_accion_completo.md` (archivado). Define cuándo se le
> puede quitar un checkpoint de aprobación humana a un cluster — todavía no
> aplica a nada (ningún cluster ha llegado a este punto), pero el criterio
> importa dejarlo claro desde ahora.

## Checklist a cumplir antes de quitar una aprobación, por cluster

> **Corregido el 17 de agosto de 2026:** la versión original de este
> checklist usaba tiempo transcurrido ("2 semanas corriendo sin error")
> como criterio. Mateo lo descartó explícitamente — el calendario no es la
> unidad correcta para validar un cluster: dos semanas con 3 tareas reales
> no dicen nada, y dos semanas con 300 sí. El criterio pasa a ser volumen
> de trabajo real.

- [ ] Un volumen suficiente de tareas reales completadas sin un error no manejado (número exacto por definir cuando haya datos reales de cuántas tareas mueve cada cluster — no es lo mismo Tech center que Legal; no es una decisión de Mateo todavía, solo un criterio pendiente de calibrar)
- [ ] Costo dentro del rango esperado durante ese volumen de tareas
- [ ] Ningún caso donde el bot haya hecho algo que Mateo no hubiera aprobado
- [ ] Acuerdo explícito de quitar el checkpoint (no una omisión)

Ir cluster por cluster, nunca todos a la vez. Empezar por los de menor riesgo — Investigación/Skills, al ser de solo lectura, es probablemente el primer candidato cuando exista.

**Precondición de fondo (ver `userMemories` / conversación con Claude):** antes de aumentar autonomía en cualquier cluster, hay que tener mapeadas qué acciones de ese cluster son irreversibles — eso es lo que determina dónde el checkpoint humano debe quedarse sí o sí, incluso después de "graduarse". No es un checklist más: es la razón de ser del checklist.

## Estado

Ningún cluster ha llegado a este punto. Es continuo, no tiene fecha — es el estado de mantenimiento del sistema una vez maduro.
