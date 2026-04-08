# Piper Dev Method

A structured AI-assisted software delivery system. Provides a deterministic pipeline from idea to production with quality gates at every stage.

## Core Principle

**No stage may introduce guesswork into the next stage.**

## The Pipeline

```
Phase 0: Foundation (once per project)
  /concept → /define → /strategy-create → /startup → /vbw:init → /roadmap-create → /wave-plan

Phase 1-5: Development (repeats per wave)
  [Roadmap Review] → Light Spec → Agent Review → Human Review → Launch →
  VBW Plan → Plan Review → Execution → QA → UAT → Ship → [Strategy Sync]
```

Phase 0 takes a project from raw idea to first wave ready for speccing. Phases 1-5 repeat for each wave of features.

## What's Included

```
piper-dev-method/
  GUIDE.md                         # Complete instruction manual
  method.md                        # The methodology — pipeline, principles, tooling
  method.config.template.md        # Project config template (copy per project)
  STARTUP.md                       # Reference guide for project bootstrap
  METHOD_IMPROVEMENTS.md           # Planned improvements
  sop/                             # Standard operating procedures
    Code_Quality.md                #   Quality standards and pre-deploy gates
    Git_and_Deployment.md          #   Branch strategy, release flow, worktrees
    Linear_SOP.md                  #   Linear workspace model and workflow states
    Skills_SOP.md                  #   Skill inventory and enforcement model
    VBW_Help.md                    #   VBW planning engine reference
  templates/                       # Templates used by skills
    concept-brief.md               #   Project concept brief
    project-definition.md          #   Full project definition
    light_spec_template.md         #   Light spec structure
    linear_guidance.md             #   Linear agent configuration
    spec_review_skill.md           #   Spec review rubric
    strategy/                      #   Strategy doc templates
      conceptual-overview.md
      technical-architecture.md
      permissions.md
      data-model.md
      workflow-examples.md
      ux-reference.md
    rules/                         #   Portable rule templates for .claude/rules/
      verify-library-api.md        #     Check installed versions before using APIs
      ad-hoc-plan-gate.md          #     Lightweight plan gate for interactive sessions
  skills/                          # Portable Claude Code skills
    concept/                       #   Phase 0: project-level ideation
    define/                        #   Phase 0: distill concept into definition
    strategy-create/               #   Phase 0: bootstrap strategy docs
    roadmap-create/                #   Phase 0: create roadmap + populate Linear
    wave-plan/                     #   Phase 0: select execution waves
    startup/                       #   Phase 0: full bootstrap orchestrator
    update-method/                 #   Sync method into consuming projects
    00-roadmap-review/             #   Phase 0 gate + health check
    01-light-spec/                 #   Phase 1: structured spec generation
    brainstorm/                    #   Feature-level ideation
    brainstorm-review/             #   Triage untriaged issues
    launch/                        #   Phase 2: validate gates, route, execute
    06-linear-todo-runner/         #   Phase 3: batch execution
    task-processor/                #   Process Linear tasks
    linear/                        #   Linear issue workflow
    linear-status/                 #   Quick board triage view
    sync-linear/                   #   Bidirectional VBW ↔ Linear sync
    branch/                        #   Create worktree + branch + Linear link
    start-session/                 #   Session start: review progress
    end-session/                   #   Session end: changelog, updates
    10-strategy-sync/              #   Phase 5: update docs post-ship
    pr-fix/                        #   PR review + fix workflow
    security-review/               #   Security review
    spec-validator/                #   Validate spec completeness
    skill-index/                   #   Sync skill index
  scripts/
    sync-method.sh                 # Pull method into a consuming project
    drift-check.sh                 # Detect stale references in documentation
```

## Quick Start

### New project (from scratch)

```bash
# 1. In your new project directory, run the startup orchestrator:
/startup

# It chains everything:
#   /concept → /define → tech stack → infra setup → /strategy-create →
#   method sync → /vbw:init → /roadmap-create → skills → CLAUDE.md → /wave-plan →
#   /roadmap-review (validation)
```

### Existing project (adopt the method)

```bash
# 1. Clone the method repo
git clone git@github.com:ethan-piper/piper-dev-method.git ~/Projects/piper-dev-method

# 2. Copy the sync script into your project
cp ~/Projects/piper-dev-method/scripts/sync-method.sh your-project/scripts/

# 3. Run it
cd your-project
./scripts/sync-method.sh

# 4. Configure
cp method.config.template.md method.config.md
# Fill in your project-specific values (Linear IDs, environments, etc.)

# 5. If starting fresh, run /startup to scaffold everything
# If mid-project, run /roadmap-review to see what's missing
```

### Update to latest method

```bash
./scripts/sync-method.sh          # From main
./scripts/sync-method.sh v1.0     # Pin to a version
./scripts/sync-method.sh --dry-run  # Preview changes
```

## What Stays in Your Project

- `concept-brief.md` — project concept
- `project-definition.md` — project definition
- `Strategy/` — project strategy docs
- `method.config.md` — project configuration
- `method/decisions/` — project-specific ADRs
- `.claude/rules/` — project coding conventions
- `.claude/skills/{project-specific}/` — skills tied to your stack
- `.vbw-planning/` — all project state (ROADMAP, WAVES, phases, plans)

## Documentation

- **[GUIDE.md](GUIDE.md)** — Complete instruction manual (start here)
- **[method.md](method.md)** — The methodology: pipeline, principles, tooling
- **[STARTUP.md](STARTUP.md)** — Reference guide for project bootstrap
- **[sop/](sop/)** — Standard operating procedures

## Versioning

Tag releases when stable: `git tag v1.0`. Projects can pin to a version:

```bash
./scripts/sync-method.sh v1.0
```

## Origin

Extracted from the [Piper](https://github.com/ethan-piper/piper) production finance platform. See `method.md` for the full methodology and `GUIDE.md` for the complete instruction manual.
