---
name: startup
description: Orchestrate full project bootstrap — concept through first wave, with infrastructure setup
---

# Startup Skill

Orchestrator for bootstrapping a new project using the Piper Dev Method. Chains pre-pipeline skills with infrastructure setup, creating a complete project from idea to first wave ready for speccing.

## Triggers

- `/startup`
- "start the project setup"
- "bootstrap this project"

## Execution

Each phase checks if its output already exists and offers to skip — making `/startup` resumable. If you stop after Phase 4, re-running picks up at Phase 5.

### Phase 1 — Concept

**Check:** Does `concept-brief.md` exist?
- If yes: _"Concept brief exists. Review it, skip, or redo?"_
- If no: Run `/concept` (or `/concept --docs <path>` if the user has existing documents)

**Output:** `concept-brief.md` — validated project concept

### Phase 2 — Define

**Check:** Does `project-definition.md` exist?
- If yes: _"Project definition exists. Review it, skip, or redo?"_
- If no: Run `/define`

**Output:** `project-definition.md` — phases, roles, workflows, success criteria

### Phase 3 — Tech Stack

**Check:** Does `CLAUDE.md` have a Stack section? Does the project have a `package.json` or equivalent?
- If yes: _"Tech stack appears configured. Skip or review?"_
- If no: Present the decision matrix interactively

Walk through tech stack decisions from `STARTUP.md` Phase 2:
- Framework, language, database, auth, deployment, CSS/UI, testing
- Make recommendations based on project definition (from Phase 2)
- **Do not decide for the user** — present options with trade-offs, wait for their call
- Record decisions for CLAUDE.md and `method.config.md`

**Git architecture decision** — present the branching model options:

| Model | When to Use |
|-------|-------------|
| **Two-tier** (`dev` → `main`) | Solo dev, small teams, preview URLs suffice for UAT |
| **Three-tier** (`dev` → `beta` → `main`) | Teams with QA, need stable UAT environment, regulated industries |

Record the choice in `method.config.md` under `## Git Architecture`. This decision determines:
- Which environments to configure in Phase 4
- Which promotion skills to create in Phase 9 (no `/g-promote-beta` needed for two-tier)
- How Linear status transitions work on merge (see `sop/Git_and_Deployment.md`)

**Output:** Tech stack + git architecture decisions recorded

### Phase 4 — Infrastructure Setup

Walk through setup checklist from `STARTUP.md` Phase 3, in order. Skip steps already done.

1. **Repository** — create GitHub repo, initialize framework, TypeScript strict, .gitignore, .env.example
2. **Monorepo** (if applicable) — Turborepo, workspaces, shared config
3. **Database** — create project(s), initial schema, auth setup
4. **Deployment** — link to Vercel/equivalent, env vars, custom domains, preview deploys
5. **Tooling** — ESLint, Vitest, Playwright, pre-deploy gate
6. **MCP Servers** — configure `.mcp.json` (Linear, GitHub, DB, browser, etc.)

**Linear setup:**
- Automate via MCP/CLI what's possible:
  - Create issues, set relations, apply labels
- Give explicit manual instructions for what requires the UI:
  - Workflow state configuration (13 standard states from `sop/Linear_SOP.md`)
  - Initiative and project creation
- After manual setup: fetch state IDs and populate `method.config.md`

**Output:** Working infrastructure — repo builds, deploys, pre-deploy gate passes

### Phase 5 — Strategy Docs

**Check:** Does `Strategy/` directory exist with docs?
- If yes: _"Strategy docs exist. Skip or review?"_
- If no: Run `/strategy-create`

**Output:** `Strategy/` directory with docs, `method.config.md` updated with doc manifest

### Phase 6 — Method Sync

**Check:** Does `method/` directory exist? Are skills in `.claude/skills/`?
- If yes: _"Method already synced. Re-sync or skip?"_
- If no: Copy and run sync script

```bash
cp ~/Projects/piper-dev-method/scripts/sync-method.sh scripts/sync-method.sh
./scripts/sync-method.sh
```

Fill in `method.config.md` with any remaining project-specific values.

**Output:** Method synced, config complete

### Phase 7 — VBW Init

**Check:** Does `.vbw-planning/` exist?
- If yes: _"VBW already initialized. Skip or reinit?"_
- If no: Run `/vbw:init`

**Output:** `.vbw-planning/` scaffolded

### Phase 8 — Roadmap

**Check:** Does `.vbw-planning/ROADMAP.md` have content?
- If yes: _"Roadmap exists. Skip or redo?"_
- If no: Run `/roadmap-create`

**Output:** ROADMAP.md populated, Linear board seeded

### Phase 9 — Project-Specific Skills

Based on the tech stack chosen in Phase 3, identify which project-specific skills are needed (see `STARTUP.md` Phase 4 for the mapping).

| If you use... | You need... |
|---------------|-------------|
| Vercel | `g-test-vercel`, `g-deploy` |
| Supabase/Postgres | `migrate` |
| Any DB | `reset-user` or equivalent |
| Monorepo with shared UI | `component` |
| Multiple environments | `g-promote-dev`, `g-promote-beta`, `g-promote-main` |

Create each skill with the user's input. Test after creation.

**Output:** Project-specific skills created and working

### Phase 10 — CLAUDE.md & Rules

Update or create CLAUDE.md with all decisions made:
- Stack, conventions, structure, environments, common commands

Create `.claude/rules/` files based on the stack:
- `security.md` — auth patterns, env var rules
- `naming.md` — file naming, code naming, DB naming
- `patterns.md` — data layer, API routes, mutations
- `file-structure.md` — directory layout
- `tooling.md` — commands, CI, pre-deploy gate

**Final `method.config.md` review:** Read back to the user, confirm all fields populated, flag TBD values.

**Output:** CLAUDE.md and rules configured

### Phase 11 — Wave Plan

**Check:** Does `.vbw-planning/WAVES.md` exist?
- If yes: _"Wave already planned. Skip or replan?"_
- If no: Run `/wave-plan`

**Output:** First wave defined, issues in "Needs Spec"

### Phase 12 — Validate

Run `/roadmap-review` to validate the full setup:
- Concept brief exists
- Project definition exists
- Strategy docs match config
- ROADMAP.md populated
- Linear board seeded
- Current wave defined
- All checks pass

If any check fails, diagnose and fix before declaring setup complete.

**Output:** All validation checks pass — pipeline is ready

```
## Setup Complete

All phases passed. Your project is ready for the development pipeline.

Next steps:
  - /light-spec {PREFIX}-1 — start speccing the first issue
  - /wave-plan --status — check wave progress
  - /roadmap-review — full health check anytime
```

## Rules

- **One phase at a time.** Don't rush ahead. Confirm the user is ready before moving to the next phase.
- **Show progress.** At each phase transition, show what's been completed and what's next.
- **Decisions are the user's.** Present analysis, make recommendations, but never lock in a choice without explicit approval.
- **Skip what's done.** If a phase's output already exists, acknowledge and offer to skip.
- **Save as you go.** Update CLAUDE.md, method.config.md, and Strategy docs as decisions are made — don't batch to the end.
- **Resumable.** Each phase checks for existing output. Re-running `/startup` picks up where you left off.
