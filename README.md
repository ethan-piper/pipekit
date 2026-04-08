# Method

A structured AI-assisted software delivery system. Provides a deterministic pipeline from idea to production with quality gates at every stage.

## Core Principle

**No stage may introduce guesswork into the next stage.**

## What's Included

```
method/
  method.md                     # The methodology — 12-step pipeline overview
  method.config.template.md     # Project config template (copy per project)
  METHOD_IMPROVEMENTS.md        # Planned improvements
  sop/                          # Standard operating procedures
    Code_Quality.md             # Quality standards and pre-deploy gates
    Git_and_Deployment.md       # Branch strategy, release flow, worktrees
    Linear_SOP.md               # Linear workspace model and workflow states
    Skills_SOP.md               # Three-layer enforcement model
    VBW_Help.md                 # VBW planning engine reference
  templates/                    # Spec and review templates
    light_spec_template.md
    linear_guidance.md
    spec_review_skill.md
  skills/                       # Portable Claude Code skills
    00-roadmap-review/
    01-light-spec/
    06-linear-todo-runner/
    10-strategy-sync/
    brainstorm/
    brainstorm-review/
    branch/
    end-session/
    launch/
    linear/
    linear-status/
    pr-fix/
    security-review/
    skill-index/
    spec-validator/
    start-session/
    sync-linear/
    task-processor/
  scripts/
    sync-method.sh              # Pull method into a consuming project
```

## Setup

### 1. Clone this repo

```bash
git clone git@github.com:ethan-piper/method.git ~/Projects/method
```

### 2. In your project, create the config

Copy `method.config.template.md` to your project root as `method.config.md` and fill in your project-specific values (Linear workspace, issue prefix, state IDs, etc.).

### 3. Sync method into your project

```bash
# First time — copy the sync script
cp ~/Projects/method/scripts/sync-method.sh your-project/scripts/sync-method.sh

# Run it
./scripts/sync-method.sh
```

### 4. What stays in your project

- `method/decisions/` — project-specific ADRs
- `.claude/rules/` — project coding conventions
- `.claude/skills/{project-specific}/` — skills tied to your stack/infra
- `.vbw-planning/` — all project state (ROADMAP, ISSUES, phases, etc.)
- `method.config.md` — your project's method configuration

## Versioning

Tag releases when stable: `git tag v1.0`. Projects can pin to a version:

```bash
./scripts/sync-method.sh v1.0
```

## Origin

Extracted from the [Piper](https://github.com/ethan-piper/piper) production finance platform. See `method.md` for the full methodology.
