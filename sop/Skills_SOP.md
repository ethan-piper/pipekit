# Skills SOP

> For the full development pipeline, see [method.md](../method.md).

**Last updated:** 2026-04-08

---

## How Skills Work

This method uses three layers to enforce development conventions:

| Layer | Purpose | Who it serves |
|---|---|---|
| **CLAUDE.md** | Documents conventions so VBW agents follow them automatically | VBW dev agents during plan execution |
| **CI / Hooks** | Hard enforcement — blocks merges that violate conventions | Everyone (agents and humans) |
| **Skills** | Interactive shortcuts for hands-on sessions | You, when working with Claude directly |

Skills are convenience wrappers. They automate the same conventions documented in CLAUDE.md. VBW agents don't call skills — they read CLAUDE.md and write code directly.

---

## Portable vs Project-Specific Skills

### Portable Skills (from method repo)

These skills work across any project that follows the method. They read `method.config.md` for project-specific values.

| Skill | Purpose | Pipeline Stage |
|-------|---------|---------------|
| `/concept` | Project-level ideation — produce a concept brief | Stage 0: Foundation |
| `/define` | Distill concept into full project definition | Stage 0: Foundation |
| `/strategy-create` | Bootstrap strategy docs from project definition | Stage 0: Foundation |
| `/roadmap-create` | Create ROADMAP.md and populate Linear | Stage 0: Foundation |
| `/wave-plan` | Select and manage execution waves | Stage 0: Foundation / Ongoing |
| `/roadmap-review` | Pre-pipeline health check (Stage 0 gate) | Stage 0 → Stage 1 gate |
| `/brainstorm` | Feature-level feasibility exploration | Stage 1: Definition |
| `/brainstorm-review` | Triage untriaged Linear issues | Stage 1: Definition |
| `/light-spec` | Structured spec generation with agent review | Stage 1: Definition |
| `/launch` | Formalized trigger: gates → routing → execution | Stage 2: Launch & Planning |
| `/linear-todo-runner` | Batch execution of specced issues | Stage 3: Execution |
| `/linear` | Linear issue workflow | Anytime |
| `/linear-status` | Quick triage view of board status | Anytime |
| `/sync-linear` | Bidirectional VBW ↔ Linear sync | Anytime |
| `/branch` | Create worktree + branch + optional Linear link | Anytime |
| `/start-session` | Review past progress, capture intentions | Anytime |
| `/end-session` | Session wrap-up: changelog, Linear updates | Anytime |
| `/strategy-sync` | Update Strategy docs after shipping | Stage 5: Documentation |
| `/pr-fix` | Precision PR review + fix workflow | Anytime |
| `/security-review` | Security review | Anytime |
| `/spec-validator` | Validate spec completeness | Stage 1: Definition |
| `/skill-index` | Sync skill index after changes | Anytime |
| `/task-processor` | Process Linear tasks systematically | Stage 3: Execution |
| `/startup` | Full project bootstrap orchestrator | Stage 0 (all steps) |
| `/update-method` | Sync method repo into project | Anytime |

### Project-Specific Skills (stay in each project)

These are tied to your stack, infrastructure, or deployment pipeline:

- Promotion skills (`/g-promote-dev`, `/g-promote-beta`, `/g-promote-main`)
- Deploy/verify skills (`/g-deploy`, `/g-test-vercel`)
- Migration skills (`/migrate`)
- Scaffold skills (`/component`)
- Data management skills (`/reset-user`)

---

## Skill Anatomy

Every skill lives in `.claude/skills/{name}/skill.md` with frontmatter:

```markdown
---
name: skill-name
description: One-line description of what the skill does
---

# Skill Name

[Full skill instructions...]
```

### Key Conventions

1. **Read `method.config.md`** for project-specific values (Linear team, issue prefix, state IDs)
2. **Read `CLAUDE.md`** for project coding conventions
3. **Use Linear MCP tools** for issue management (`mcp__linear-server__*`)
4. **Use VBW agents** for planning and execution (`vbw:vbw-lead`, `vbw:vbw-dev`, `vbw:vbw-qa`)

---

## Syncing Portable Skills

Portable skills are maintained in the method repo and synced into projects via `scripts/sync-method.sh`. After syncing, the skills appear in `.claude/skills/` alongside project-specific skills.

To update: `./scripts/sync-method.sh [tag]`
