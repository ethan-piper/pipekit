# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

This is the **Piper Dev Method** — a portable, structured AI-assisted software delivery system. It is NOT a software project itself. It contains methodology docs, SOPs, templates, and Claude Code skills that get synced into consuming projects via `scripts/sync-method.sh`.

Origin: extracted from the [Piper](https://github.com/ethan-piper/piper) production finance platform.

## Core Principle

**No stage may introduce guesswork into the next stage.** Specs must be planning-safe. Plans must be execution-safe. When ambiguity is detected, work goes backward, not forward.

## Pipeline

```
Stage 0: Foundation (once per project)
  /concept → /define → /strategy-create → /startup → /vbw:init → /roadmap-create → /phase-plan

Stages 1-5: Development (repeats per phase)
  [Roadmap Review] → Light Spec → Agent Review → Human Review → Launch →
  VBW Plan → Plan Review → Execution → QA → UAT → Ship → [Strategy Sync]
```

Stage 0 takes a project from idea to first phase. Stages 1-5 repeat per phase/feature. Feedback loops send work backward when ambiguity is detected.

## Repo Structure

- `method.md` — The full methodology (Stage 0 + 12-step pipeline, principles, tooling)
- `method.config.template.md` — Template for project-specific config (Linear IDs, strategy docs, environments, pre-deploy gate)
- `STARTUP.md` — Reference guide for project bootstrap (use `/startup` for the interactive flow)
- `sop/` — Standard operating procedures (Git, Code Quality, Linear, Skills, VBW)
- `templates/` — Concept brief, project definition, strategy doc, and spec templates
- `templates/strategy/` — Templates for each strategy doc type (conceptual overview, technical architecture, etc.)
- `skills/` — Portable Claude Code skills (synced into consuming projects as `.claude/skills/`)
- `scripts/sync-method.sh` — The sync script that pulls this repo's content into consuming projects

## How Consuming Projects Work

Projects pull from this repo using `sync-method.sh`. The sync copies `skills/`, `sop/`, `templates/`, and `method.md` into the project. It never touches project-specific files (`method.config.md`, `.claude/rules/`, `.vbw-planning/`, project-specific skills).

## Editing Skills

Skills live in `skills/{name}/skill.md` with YAML frontmatter (`name`, `description`). Portable skills must read `method.config.md` for project-specific values — never hardcode Linear IDs, team names, or paths. Skills that reference `skill.json` use it for metadata only.

## Three-Layer Enforcement Model

| Layer | Purpose |
|-------|---------|
| `CLAUDE.md` (in consuming project) | Conventions for VBW agents |
| CI / Hooks | Hard enforcement — blocks merges |
| Skills (this repo) | Interactive shortcuts for hands-on sessions |

VBW agents don't call skills — they read the consuming project's CLAUDE.md directly.

## Key Skills

**Stage 0 (Foundation):**

| Skill | Purpose |
|-------|---------|
| `/concept` | Project-level ideation — concept brief from ideas + existing docs |
| `/define` | Distill concept into project definition (phases, roles, workflows) |
| `/strategy-create` | Bootstrap strategy docs from project definition |
| `/startup` | Full bootstrap orchestrator — chains all Stage 0 + setup steps |
| `/roadmap-create` | Create ROADMAP.md and populate Linear |
| `/phase-plan` | Select execution phases, track progress |

**Development Pipeline:**

| Skill | Purpose |
|-------|---------|
| `/launch` | Validates gates, routes by complexity, triggers execution |
| `/light-spec` | Generates structured specs as AI-to-AI contracts |
| `/strategy-sync` | Updates Strategy docs post-ship to match what was actually built |
| `/update-method` | Sync latest method into a consuming project (supports `--push`) |

Full skill list in `sop/Skills_SOP.md`.
