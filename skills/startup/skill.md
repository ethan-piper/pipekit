---
name: startup
description: Walk through project bootstrap using the Piper Dev Method startup guide
---

# Startup Skill

Interactive walkthrough for bootstrapping a new project using the Piper Dev Method.

## Triggers

- `/startup`
- "start the project setup"
- "bootstrap this project"

## Execution

1. Read `method/method.md` for the overall methodology
2. Read `method/STARTUP.md` for the step-by-step guide — if not found, read from `~/Projects/piper-dev-method/STARTUP.md`
3. Read `CLAUDE.md` for any existing project context
4. Read `method.config.md` to see what's already configured

Walk through STARTUP.md **one phase at a time**, interactively:

### Phase 1 — Define
- Present the project identity questions
- Check if CLAUDE.md already answers some of them
- Ask the user to confirm or fill in gaps
- Help create/update Strategy docs if the user wants

### Phase 2 — Tech Stack
- Present the decision matrix
- Make recommendations based on the project's needs (from Phase 1)
- Record decisions as the user makes them
- **Do not decide for the user** — present options with trade-offs, wait for their call

### Phase 3 — Setup
- Walk through the setup checklist in order
- Execute each step with the user's approval
- Skip steps that are already done
- Verify each step before moving to the next

### Phase 4 — Skills
- Based on the tech stack chosen in Phase 2, identify which project-specific skills are needed
- Create each skill with the user's input
- Test each skill after creation

### Phase 5 — CLAUDE.md
- Update CLAUDE.md with all decisions made
- Create `.claude/rules/` files based on the stack
- Update `method.config.md` with any new values

### Phase 6 — Validate
- Run the end-to-end pipeline test
- Create a test issue in Linear
- Push it through the full cycle
- Confirm everything works

## Rules

- **One phase at a time.** Don't rush ahead. Confirm the user is ready before moving to the next phase.
- **Show progress.** At each phase transition, show what's been completed and what's next.
- **Decisions are the user's.** Present analysis, make recommendations, but never lock in a choice without explicit approval.
- **Skip what's done.** If the project already has a framework, database, or deployment set up, acknowledge it and move on.
- **Save as you go.** Update CLAUDE.md, method.config.md, and Strategy docs as decisions are made — don't batch everything to the end.
