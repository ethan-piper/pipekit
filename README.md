# Pipekit

A structured AI-assisted software delivery system. Wraps [VBW](https://github.com/dnakov/claude-code-vbw) in a visibility and project management layer — from idea to production with quality gates at every stage.

## What This Is (and Isn't)

Pipekit **does not replace VBW**. VBW handles planning, execution, and QA. Pipekit adds structure around it:

| Layer | What Pipekit does | What VBW does |
|-------|-------------------|---------------|
| **Before** (steps 1-4) | Spec creation, agent review, human sign-off, gate checks | — |
| **During** (steps 5-8) | — | **Plan, execute, QA — all VBW** |
| **After** (steps 9-11) | UAT tracking, shipping, doc sync | — |
| **Around** | Linear integration for cross-issue visibility | Tracks one phase at a time |
| **Stage 0** | Project bootstrap (idea → roadmap) | Starts at "I have a task" |

VBW doesn't need the full project plan — it's designed for bounded scope. Pipekit makes sure the input going into VBW is clean and unambiguous, and tracks what comes out.

## Core Principle

**No stage may introduce guesswork into the next stage.**

## The Pipeline

**Stage 0: Foundation** (runs once per project)

| Step | Skill | Output |
|------|-------|--------|
| Concept | `/concept` | `concept-brief.md` |
| Define | `/define` | `project-definition.md` |
| Strategy | `/strategy-create` | `Strategy/` docs (incl. Design Direction) |
| Setup | `/startup` | Repo, DB, deploy, Linear board |
| VBW Init | `/vbw:init` | `.vbw-planning/` scaffold |
| Roadmap | `/roadmap-create` | `ROADMAP.md` + Linear issues |
| Phase Plan | `/phase-plan` | First phase in "Needs Spec" |

**Development Pipeline** (repeats per feature)

| # | Step | What happens |
|---|------|-------------|
| 1 | Light Spec | Spec the feature (codebase-aware, AI→AI contract) |
| 2 | Agent Review | Linear's agent reviews the spec |
| 3 | Human Review | You sign off in Linear |
| 4 | Launch | Gates checked, complexity routed |
| 5 | **VBW Plan** | **VBW Lead generates PLAN.md from the spec** |
| 6 | **Plan Review** | **Plan validated for executability** |
| 7 | **VBW Execution** | **VBW Dev agents build it** |
| 8 | **VBW QA** | **VBW QA verifies against spec** |
| 9 | UAT | You test the built feature |
| 10 | Ship | Promote to production |
| 11 | Strategy Sync | Update docs to match what was built |

## Prerequisites

- [Claude Code](https://claude.ai/code) (CLI)
- [VBW plugin](https://github.com/dnakov/claude-code-vbw) installed
- [Linear](https://linear.app/) workspace (for issue tracking)
- Linear MCP server configured

## Quick Start

### New project

```bash
# 1. Clone Pipekit
git clone git@github.com:ethan-piper/pipekit.git ~/Projects/pipekit

# 2. In your project directory, copy and run the sync script
mkdir -p scripts
cp ~/Projects/pipekit/scripts/sync-method.sh scripts/
./scripts/sync-method.sh

# 3. Open Claude Code and run the startup orchestrator
/startup

# It chains everything:
#   /concept → /define → /strategy-create → tech stack → infra setup →
#   method sync → /vbw:init → /roadmap-create → /phase-plan → /roadmap-review
```

### Existing project (adopt the method)

```bash
# 1. Clone Pipekit
git clone git@github.com:ethan-piper/pipekit.git ~/Projects/pipekit

# 2. Copy the sync script into your project
cp ~/Projects/pipekit/scripts/sync-method.sh your-project/scripts/

# 3. Run it
cd your-project
./scripts/sync-method.sh

# 4. The sync creates method.config.md — fill in your project values

# 5. Run /startup to scaffold, or /roadmap-review to see what's missing
```

### Existing project with docs

If you already have concept docs, proposals, or research:

```bash
# After syncing, run concept with your existing docs:
/concept --docs docs/ proposal/

# It ingests everything and asks only about gaps
```

### Update to latest method

```bash
./scripts/sync-method.sh          # From main
./scripts/sync-method.sh v1.0     # Pin to a version
./scripts/sync-method.sh --dry-run  # Preview changes
```

## What's Included

```
pipekit/
  GUIDE.md                         # Complete instruction manual (start here)
  method.md                        # The methodology — pipeline, principles, tooling
  method.config.template.md        # Project config template (copied per project)
  STARTUP.md                       # Reference guide for project bootstrap
  VBW_COMMANDS.md                  # VBW command reference
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
      design-direction.md          #     Visual style + inspiration for build agents
      permissions.md
      data-model.md
      workflow-examples.md
      ux-reference.md
    rules/                         #   Portable rule templates for .claude/rules/
      verify-library-api.md        #     Check installed versions before using APIs
      ad-hoc-plan-gate.md          #     Lightweight plan gate for interactive sessions
  skills/                          # Portable Claude Code skills (25 total)
  scripts/
    sync-method.sh                 # Pull method into a consuming project
    drift-check.sh                 # Detect stale references in documentation
```

## What Gets Synced vs. What Stays

**Synced from Pipekit** (updated when you re-run `sync-method.sh`):
- `.claude/skills/` — portable skills
- `method/` — SOPs, templates, methodology docs

**Stays in your project** (never overwritten):
- `concept-brief.md` — project concept
- `project-definition.md` — project definition
- `Strategy/` — project strategy docs (incl. Design Direction)
- `method.config.md` — project configuration (Linear IDs, environments, etc.)
- `.claude/rules/` — project coding conventions
- `.claude/skills/{project-specific}/` — skills tied to your stack
- `.vbw-planning/` — all project state (ROADMAP, PHASES, plans)

## Documentation

- **[GUIDE.md](GUIDE.md)** — Complete instruction manual (start here)
- **[method.md](method.md)** — The methodology: pipeline, principles, tooling
- **[STARTUP.md](STARTUP.md)** — Reference guide for project bootstrap
- **[VBW_COMMANDS.md](VBW_COMMANDS.md)** — VBW command reference
- **[sop/](sop/)** — Standard operating procedures

## Versioning

Tag releases when stable: `git tag v1.0`. Projects can pin to a version:

```bash
./scripts/sync-method.sh v1.0
```

## Origin

Extracted from the Piper production finance platform. See `method.md` for the full methodology and `GUIDE.md` for the complete instruction manual.
