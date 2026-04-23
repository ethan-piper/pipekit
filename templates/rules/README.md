# Claude Code Rules

Files in this directory are **auto-loaded into every Claude Code session** via the `.claude/rules/` convention. Keep rules short and load-bearing — every line costs input tokens on every turn.

## Hub-and-spoke model

```
CLAUDE.md            — project hub + routing pointers (~200 lines)
  .claude/rules/*    — auto-loaded enforceable constraints (per-topic files)
  method/sop/*       — demand-loaded deep reference (SQL templates, walkthroughs)
```

CLAUDE.md points to rules for "how do I build correctly here?" Rules point to SOPs for "how do I do this specific complex thing?"

## What goes in rules/

- **Enforceable constraints** — "must / must not" guidance the AI should refuse to violate
- **Invariants** — things true across every feature (e.g., "RLS enabled on every table")
- **Cross-cutting patterns** — naming, file structure, package manager, auth flow
- **Domain pitfalls** — counter-intuitive API behaviors that have caused regressions

## What does NOT go in rules/

- Feature-specific documentation — that's SOPs or inline docs
- Historical context or decision logs — that's `method/decisions/` ADRs
- Tutorial-style guides — that's SOPs
- Anything longer than ~100 lines — split by topic

## Canonical rules shipped by Pipekit

| File | Topic | Portable |
|------|-------|----------|
| `discipline.md` | AI coding discipline: Red Flags, Ad-hoc Plan Gate, scope hygiene | ✅ |
| `tooling.md` | Verify installed library APIs, pin package manager, pre-deploy gate | ✅ |
| `security.md` | Secrets, boundary validation, OWASP, auth must be explicit | ✅ |

These are synced by `scripts/sync-method.sh` from Pipekit. They only get overwritten when you run `/pipekit-update`.

## Adding project-specific rules

Create new files directly in this directory — `sync-method.sh` won't touch them. Naming conventions used in real projects:

- `patterns.md` — data-layer patterns, component conventions, state management
- `file-structure.md` — directory layout, import alias rules
- `security.md` — RLS strategy, secrets in edge functions (project-specific additions)
- `{library}-pitfalls.md` — counter-intuitive API behaviors (e.g., `ag-grid-pitfalls.md`, `react-query-pitfalls.md`)

Reference CLAUDE.md's routing table so rules are discoverable.
