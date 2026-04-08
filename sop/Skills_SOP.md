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

| Skill | Purpose |
|-------|---------|
| `/roadmap-review` | Pre-pipeline health check |
| `/brainstorm` | Feasibility exploration, create Linear issue |
| `/brainstorm-review` | Triage untriaged Linear issues |
| `/light-spec` | Structured spec generation with agent review |
| `/launch` | Formalized trigger: gates → routing → execution |
| `/linear-todo-runner` | Batch execution of specced issues |
| `/linear` | Linear issue workflow |
| `/linear-status` | Quick triage view of board status |
| `/sync-linear` | Bidirectional VBW ↔ Linear sync |
| `/branch` | Create worktree + branch + optional Linear link |
| `/start-session` | Review past progress, capture intentions |
| `/end-session` | Session wrap-up: changelog, Linear updates |
| `/strategy-sync` | Update Strategy docs after shipping |
| `/pr-fix` | Precision PR review + fix workflow |
| `/security-review` | Security review |
| `/spec-validator` | Validate spec completeness |
| `/skill-index` | Sync skill index after changes |
| `/task-processor` | Process Linear tasks systematically |

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
