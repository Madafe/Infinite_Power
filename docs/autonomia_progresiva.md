# Autonomía progresiva — criterio de graduación

> Extraído de `plan_de_accion_completo.md` (archivado). Define cuándo se le
> puede quitar un checkpoint de aprobación humana a un cluster — todavía no
> aplica a nada (ningún cluster ha llegado a este punto), pero el criterio
> importa dejarlo claro desde ahora.

## Checklist a cumplir antes de quitar una aprobación, por cluster

- [ ] 2 semanas corriendo sin un error no manejado
- [ ] Costo dentro del rango esperado las 2 semanas
- [ ] Ningún caso donde el bot haya hecho algo que Mateo no hubiera aprobado
- [ ] Acuerdo explícito de quitar el checkpoint (no una omisión)

Ir cluster por cluster, nunca todos a la vez. Empezar por los de menor riesgo — Investigación/Skills, al ser de solo lectura, es probablemente el primer candidato cuando exista.

**Precondición de fondo (ver `userMemories` / conversación con Claude):** antes de aumentar autonomía en cualquier cluster, hay que tener mapeadas qué acciones de ese cluster son irreversibles — eso es lo que determina dónde el checkpoint humano debe quedarse sí o sí, incluso después de "graduarse". No es un checklist más: es la razón de ser del checklist.

## Estado

Ningún cluster ha llegado a este punto. Es continuo, no tiene fecha — es el estado de mantenimiento del sistema una vez maduro.
