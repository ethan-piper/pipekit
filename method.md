# Pipekit

**Last updated:** 2026-04-08

## Overview

A structured AI-assisted delivery system designed to produce high-quality software through controlled stages of generation, review, planning, and execution.

It operates as a pipeline with explicit quality gates to eliminate ambiguity and reduce execution risk. Each gate enforces a contract: the output of one stage must be consumable by the next without guessing.

---

## Core Principle

**No stage may introduce guesswork into the next stage.**

- Specs must not require planning guesses
- Plans must not require execution guesses
- Execution must not require interpretation

When ambiguity is detected, the pipeline sends work backward — not forward. A spec that forces the planner to guess is returned for revision, not passed through with caveats.

---

## Pipeline

```
Stage 0: Foundation (runs once per project)
  /concept → /define → /strategy-create → /startup → /vbw:init → /roadmap-create → /phase-plan

Stages 1-5: Development Pipeline (repeats per phase/feature)
  [Roadmap Review] → Light Spec → Agent Review → Human Review → Launch →
  VBW Plan → Plan Review → Execution → QA → UAT → Ship → [Strategy Sync]
```

**Stage 0** takes a project from idea to first phase ready for speccing. **Stages 1-5** repeat for each phase of features.

**Bookends:** `/roadmap-review` validates Stage 0 outputs and plan health before entering the pipeline. `/strategy-sync` updates Strategy docs after features ship — closing the documentation loop.

### Step-by-Step

#### Stage 0: Foundation

| # | Step | Tool | Input | Output | Gate |
|---|------|------|-------|--------|------|
| 0.1 | **Concept** | `/concept` | Raw idea + existing docs | `concept-brief.md` | Idea is specific enough to define |
| 0.2 | **Define** | `/define` | Concept brief | `project-definition.md` | Definition supports tech stack + strategy decisions |
| 0.3 | **Strategy Create** | `/strategy-create` | Project definition | `Strategy/` docs (incl. Design Direction) | Docs describe a coherent product |
| 0.4 | **Infra Setup** | `/startup` (Steps 3-6) | Tech stack decisions | Working repo, DB, deploy, MCP | Pre-deploy gate passes |
| 0.5 | **VBW Init** | `/vbw:init` | — | `.vbw-planning/` scaffold | Directory exists |
| 0.6 | **Roadmap** | `/roadmap-create` | Strategy docs + definition | `ROADMAP.md` + populated Linear | Every requirement has an issue |
| 0.7 | **Phase Plan** | `/phase-plan` | Populated Linear board | First phase in "Needs Spec" | Dependencies clear, phase sized |

Stage 0 runs once per project. `/startup` orchestrates the full flow.

#### Stages 1-5: Development Pipeline

| # | Step | Tool | Input | Output | Gate |
|---|------|------|-------|--------|------|
| 0 | **Roadmap Review** | `/roadmap-review` | ROADMAP, Linear state, PHASES.md | Health report: Stage 0 check, gaps, ordering, spec coverage, doc freshness | Stage 0 complete, plan coherent |
| 1 | **Light Spec** | `/light-spec` + Linear | Feature idea or issue | Structured spec exploring codebase and Strategy docs | — |
| 2 | **Agent Review** | Linear Spec Review Agent | Light spec | Pass/Revise verdict with readiness score | Spec must be unambiguous and decomposable without guessing |
| 3 | **Human Review** | You in Linear | Agent-reviewed spec | Approved spec with product decisions locked | Human signs off on scope, decisions, and priority |
| 4 | **Launch (open)** | `/launch {ISSUE}` | Approved spec | Gates validated, complexity routed, issue → Building, handoff text written | Spec exists, deps met, milestone siblings all specced |
| 5 | **VBW Plan** | `/vbw:vibe --plan {phase-slug}` (user-triggered) | Approved spec from Linear | `PLAN.md` with task decomposition, verify/done criteria | — (Low complexity skips to batch runner) |
| 6 | **Plan Review** | `/review-plan {phase-slug}` (Pipekit skill, calls `plan-reviewer` agent) | PLAN.md | Validated plan or revision requests | Plan must be executable step-by-step without ambiguity |
| 7 | **Execution** | `/vbw:vibe --execute` (user-triggered) or `/linear-todo-runner` (for Low complexity) | Approved plan or AC | Atomic commits per task | Each task passes its own verify/done criteria |
| 8 | **QA** | `/vbw:vibe --verify` (user-triggered, VBW-native layouts only) or project-precedent self-verification | Completed tasks | Verification report (or precedent equivalent) | All tasks verified against goals |
| 9 | **Launch (close)** | `/launch {ISSUE} --close` | Verify-passed signal | Linear status → UAT, Linear comment posted | User confirmed verify passed |
| 10 | **UAT** | You | Built feature | Accepted or rejected | Feature matches spec AC under real usage |
| 11 | **Ship** | Promotion skills | Accepted feature | Production release | CI gates pass, smoke tests pass |
| 12 | **Strategy Sync** | `/strategy-sync` | Shipped features, current Strategy docs | Updated docs reflecting reality | Code is truth; diffs approved before apply |

**Feedback loops:** Steps 2, 6, 8, and 9 can send work backward. Agent review returns specs for revision. Plan review returns plans for rework. QA returns tasks to dev. UAT returns features to execution. The pipeline is linear by default, corrective when needed.

**Between phases:** `/phase-plan --next` selects the next batch of issues and promotes them to "Needs Spec." `/roadmap-review` validates before speccing begins.

> **Optional pre-step:** `/brainstorm` — for exploring feature-level ideas within an existing project. For project-level ideation, use `/concept`.

---

## Stage 0: Foundation

**Steps:** 0.1–0.7 (Concept → Define → Strategy → Setup → VBW Init → Roadmap → Phase Plan)

**Tools:** `/concept`, `/define`, `/strategy-create`, `/startup`, `/vbw:init`, `/roadmap-create`, `/phase-plan`

Runs once per project. Takes a raw idea through structured definition, strategy documentation, infrastructure setup, and roadmap creation to produce a populated Linear board with the first phase ready for speccing.

- `/concept` captures the idea and assesses viability — supports ingesting existing documents (proposals, research, notes)
- `/define` distills the concept into stages, roles, workflows, and success criteria
- `/strategy-create` generates configurable strategy docs (doc set defined in `method.config.md`)
- `/startup` orchestrates the full flow and handles infrastructure (repo, DB, deploy, MCP, Linear)
- `/vbw:init` scaffolds `.vbw-planning/` for the planning engine
- `/roadmap-create` extracts requirements from strategy docs and populates both ROADMAP.md and Linear
- `/phase-plan` selects 3-8 issues for the first execution phase

**Output:** `concept-brief.md`, `project-definition.md`, `Strategy/` docs, working infrastructure, `.vbw-planning/ROADMAP.md`, populated Linear board, `.vbw-planning/PHASES.md` with first phase defined.

**Gate:** `/roadmap-review` validates all Stage 0 outputs before the spec pipeline begins.

---

## Pre-Condition: Roadmap Review

**Step:** 0

**Tools:** `/roadmap-review`

Run before entering the spec pipeline to validate that Stage 0 is complete and the roadmap is coherent: concept and definition exist, strategy docs match config, all requirements have Linear issues, dependencies are set, workflow states are consistent, current phase is defined, and spec coverage is adequate. Also flags Strategy doc staleness (recommends `/strategy-sync` if needed).

**Output:** Health report with action items. Resolve blockers before speccing.

---

## Stage 1: Definition (Spec Quality Gate)

**Steps:** 1–3 (Light Spec → Agent Review → Human Review)
**Pre-condition:** Roadmap Review (Step 0) must pass

**Tools:** `/light-spec`, Spec Review Agent, Human

- `/light-spec` explores the codebase, reads reference material and Strategy docs, and generates a structured spec as an AI→AI contract
- Spec Review Agent enforces planning readiness (Pass/Revise with blocking issues identified)
- Human validates product decisions, scope, and priority
- Iteration continues until Agent passes AND Human approves

**Output:** Planning-safe spec (stored as Linear issue description)

**Gate:** Spec must be unambiguous and decomposable without guessing. All decisions defined or explicitly marked [TBD] (where TBD does not block task decomposition).

---

## Stage 2: Launch & Planning (Execution Quality Gate)

**Steps:** 4–6 (Launch → VBW Plan → Plan Review)


**Tools:** `/launch`, VBW Lead Agent, `plan-reviewer` agent

- `/launch {ISSUE}` validates three gates: spec exists, dependencies met, milestone siblings all specced (Gate C)
- Routes by complexity: Low → batch runner (AC is the plan), Medium/High → VBW planning
- Moves issue to Building and posts a Linear comment with gate results
- Lead agent reads the approved spec from Linear, decomposes into tasks, generates `PLAN.md`
- Each task has verify and done criteria derived from the spec's Acceptance Criteria
- Plan reviewer stress-tests scope, dependencies, success criteria, and risks

**Output:** Execution-safe plan (`.vbw-planning/phases/*/PLAN.md`), or batch-runner queue for Low complexity

**Gate:** Plan must be executable step-by-step without ambiguity or rework. No task should require the dev agent to make product decisions.

---

## Stage 3: Execution (Build Quality Gate)

**Steps:** 7–9 (Execution → QA → UAT)

**Tools:** VBW Dev Agent, `/linear-todo-runner`, VBW QA Agent, Human

- Dev agent executes atomic tasks with one commit per task
- `/linear-todo-runner` can batch-process multiple specced issues in parallel (requires AC section)
- QA agent verifies completed work using goal-backward methodology
- Human performs acceptance testing against the spec's AC

**Output:** Shippable feature

**Gate:** Feature must match spec behaviour and pass real usage. All AC checkboxes satisfied.

---

## Stage 4: Release

**Steps:** 10 (Ship)

Every step forward is a PR. No direct merges between long-lived branches. Each project defines its own promotion skills (e.g., `/g-promote-dev`, `/g-promote-beta`, `/g-promote-main`).

- CI enforces pre-deploy gate at each PR
- Post-deploy smoke tests confirm the release

**Output:** Production release

**Gate:** CI passes, pre-deploy gate passes, smoke tests pass.

---

## Stage 5: Documentation Loop

**Step:** 11

**Tools:** `/strategy-sync`

After features ship and UAT passes, run `/strategy-sync` to update Strategy docs to reflect what was actually built. Code is truth — if the implementation differs from the spec, docs match the code.

```
Strategy Docs (vision) → Light Specs → Plans → Code → Strategy Docs (reality)
                  ↑                                              |
                  └──────────── /strategy-sync ─────────────────┘
```

**Output:** Updated Strategy docs with version bump. All changes presented as diffs for human approval before applying.

**Cadence:** After UAT passes for a phase, before stakeholder presentations, before onboarding new team members.

---

## Key Principles

### AI → AI Contracts
Light specs are structured contracts between generator, reviewer, and planner. Every rule must be explicit, unambiguous, and enforceable by a downstream agent.

### WHAT vs HOW
Specs define WHAT. Plans define HOW. If a spec statement can be rewritten as "change X line" or "use Y syntax," it is implementation detail and must be removed.

### Explicit Decisions
All behaviour-affecting decisions must be defined or marked [TBD]. A decision left implicit (not mentioned at all) makes the spec invalid. [TBD] is only valid if it does not block task decomposition.

### Authority
Source of truth must be explicit (DB, utils, API, etc.). When multiple layers could disagree, define precedence. Ambiguous authority is the #1 cause of spec revision.

### No Hidden Assumptions
Controlled incompleteness is allowed — brevity, [TBD], limited context are fine. Hidden assumptions and implicit behaviour are not. The line: _can the next stage work without guessing?_

### Human Ownership
AI proposes, reviews, and executes. Humans decide. AI never locks in a product decision — it presents analysis and waits for the call.

---

## Three-Layer Enforcement Model

| Layer | Purpose | Who it serves |
|---|---|---|
| **CLAUDE.md** | Documents conventions so VBW agents follow them automatically | VBW dev agents during plan execution |
| **CI / Hooks** | Hard enforcement — blocks merges that violate conventions | Everyone (agents and humans) |
| **Skills** | Interactive shortcuts for hands-on sessions | You, when working with Claude directly |

Skills are convenience wrappers. They automate the same conventions documented in CLAUDE.md. VBW agents don't call skills — they read CLAUDE.md and write code directly.

---

## VBW / Pipekit Ownership Model

Pipekit wraps VBW — it does not replace VBW's planning layer. The two systems must not compete for the same source of truth, or you'll spend more time reconciling than building. The boundaries below make ownership explicit.

### Ownership Table

| File / System | Owned by | Writers | Readers |
|---|---|---|---|
| `.vbw-planning/ROADMAP.md` | VBW | `/vbw:init` creates it; `/roadmap-create` merges strategy-derived requirements **into** it (never overwrites) | All Pipekit skills, VBW agents |
| `.vbw-planning/phases/*/PLAN.md` | VBW | VBW Lead Agent (spawned by `/launch`) | `/launch`, `/phase-plan --status`, VBW Dev/QA agents |
| `.vbw-planning/.execution-state.json` | VBW | VBW Dev/QA agents | `/phase-plan --status` |
| `.vbw-planning/linear-map.json` | Pipekit | `/roadmap-create`, `/sync-linear` | All Pipekit skills |
| `.vbw-planning/PHASES.md` | Pipekit | `/phase-plan` | All Pipekit skills |
| `NEXT.md` (project root) | Pipekit | Every skill that emits `➜ Next:` | `/start-session`, humans |
| Linear issues | Pipekit | `/light-spec`, `/launch`, `/roadmap-create`, `/phase-plan` | Everyone |
| `concept-brief.md`, `project-definition.md`, `Strategy/` | Pipekit | `/concept`, `/define`, `/strategy-create`, `/strategy-sync` | `/light-spec`, VBW Lead |
| `method.config.md` | Pipekit | `/startup` (populates); human (edits) | All Pipekit skills |

### Rules of Engagement

1. **VBW owns the planning layer.** `.vbw-planning/ROADMAP.md`, `PLAN.md` files, and execution state are VBW's. Pipekit reads them but does not overwrite them.
2. **Pipekit owns the visibility layer.** Linear issues, `linear-map.json`, `PHASES.md`, `NEXT.md`, strategy docs, and project config are Pipekit's. VBW does not write to these.
3. **Initial merge happens once** — at `/roadmap-create`. Strategy-derived requirements are added **into** VBW's existing phase structure. VBW's phases, goals, and success criteria are preserved verbatim.
4. **After the merge, the split is one-way.** Pipekit reads VBW state (plan progress, execution state) to update Linear. VBW does not read Linear — its source of truth is its own files.
5. **Pipekit owns gates; VBW owns build.** `/launch` (open) validates Linear gates and hands off; `/launch --close` transitions Linear to UAT. Between those, the user runs `/vbw:vibe --plan` → `/review-plan` → `/vbw:vibe --execute` → `/vbw:vibe --verify`. Pipekit does not spawn any VBW agents directly from `/launch`. The plan-review gate (Pipekit's value-add over raw VBW) lives in the standalone `/review-plan` skill, which spawns the `plan-reviewer` agent at `model: opus`.

   **Pipekit's VBW-steering surface (Tier 1 / Option 3 architecture, 2026-04-25):**
   1. **One direct agent spawn** — `plan-reviewer` in `/review-plan`. Not a VBW agent; Pipekit-shipped.
   2. **Read-only state observation** — `.vbw-planning/{ROADMAP,STATE,PHASES,linear-map}.md` reads from `/sync-linear`, `/phase-plan`, `/00-roadmap-review`, `/01-light-spec`, `/10-strategy-sync`, `/end-session`.
   3. **One lifecycle hook** — `scripts/pipekit-post-archive.sh` fires on `/vbw:vibe --archive`, writes `.pipekit/pending-strategy-sync` marker.

   No direct VBW-agent spawns. No execution-flow wrapping. VBW upgrades touch zero Pipekit code.
6. **When drift is suspected, stop and reconcile.** Symptoms: Linear status doesn't match VBW execution state; a PLAN.md references a Linear issue that doesn't exist; a Linear issue has no corresponding plan. Resolve the mismatch before continuing — drift compounds.

### Known Drift Risks

| Risk | Trigger | Mitigation |
|---|---|---|
| Plan state ≠ Linear state | Running VBW agents directly, not via `/launch` | Use `/launch`. Route all execution through Pipekit. |
| Spec in Linear updated after plan generated | Someone edits issue description post-plan | Re-run `/light-spec PROJ-XXX --rebase` (regenerates plan from current spec) |
| Orphan plans | Plan generated for an issue that's since been deleted | Detected via future `/drift-check` skill |
| Orphan Linear issues | Issue created in Linear UI, no corresponding roadmap entry | Caught at `/roadmap-review` |

If drift becomes a recurring pattern in practice, add a `/drift-check` skill for on-demand detection. Don't build it speculatively — measure first. Full spec tracked in [pipekit#1](https://github.com/ethan-piper/pipekit/issues/1).

### Event Hook: Post-Archive → Strategy Sync

VBW v1.35.0 added a post-archive lifecycle hook (PR #481) that fires after `/vbw:vibe --archive` completes. Pipekit ships `scripts/pipekit-post-archive.sh` to wire this into the strategy-sync loop — when a milestone is archived, the hook writes a `.pipekit/pending-strategy-sync` marker that `/start-session` surfaces on the next session, nudging the user to run `/strategy-sync`.

This is the first concrete instance of the event-based wrapping discussed in Rule 5 above. It replaces the previous convention ("remember to run /strategy-sync after shipping") with a hook that fires deterministically without Pipekit re-implementing VBW's archive flow.

**Registration.** Add the hook to `.vbw-planning/config.json`:

```json
{
  "hooks": {
    "post_archive": "scripts/pipekit-post-archive.sh"
  }
}
```

VBW resolves the path relative to the project root. The hook is fail-open — if it errors, VBW continues the archive.

**Why a marker instead of auto-running /strategy-sync?** Strategy sync requires human-in-the-loop diff approval (see `/strategy-sync` Phase 5). A hook cannot own human approval, so it nudges rather than acts. The marker is cleared by `/strategy-sync` once updates are applied.

---

## Tooling

### Interactive Skills (for hands-on sessions)

**Stage 0: Foundation**

| Skill | Purpose |
|-------|---------|
| `/concept` | Project-level ideation — produce a concept brief from ideas + existing docs |
| `/define` | Distill concept into full project definition (phases, roles, workflows) |
| `/strategy-create` | Bootstrap strategy docs from project definition |
| `/startup` | Full project bootstrap orchestrator (chains all Stage 0 + setup skills) |
| `/roadmap-create` | Create ROADMAP.md and populate Linear with issues |
| `/phase-plan` | Select execution phases, track progress, manage phase transitions |

**Development Pipeline**

| Skill | Purpose |
|-------|---------|
| `/roadmap-review` | Stage 0 gate + health check: completeness, dependencies, spec coverage |
| `/brainstorm` | Feature-level feasibility exploration (within an existing project) |
| `/light-spec` | Structured spec generation with agent review |
| `/launch {ISSUE}` | Open: validate Linear gates, route by complexity, transition to Building, hand off to VBW |
| `/launch {ISSUE} --close` | Close: transition Linear to UAT after VBW pipeline complete + verify passed |
| `/launch --milestone {WP}` | Launch all ready issues in a milestone |
| `/review-plan {phase-slug}` | Run plan-reviewer agent against VBW-generated PLAN.md. Run between `/vbw:vibe --plan` and `/vbw:vibe --execute`. |
| `/linear-todo-runner` | Batch execution of specced issues (called by `/launch` for Low complexity) |
| `/sync-linear` | Bidirectional VBW ↔ Linear sync |
| `/branch` | Create worktree + branch + optional Linear link |
| `/start-session` | Review past progress, capture session intentions |
| `/end-session` | Session wrap-up: changelog, Linear updates |
| `/strategy-sync` | Post-pipeline: update Strategy docs to reflect shipped features |

Project-specific promotion and deploy skills are defined per project (not in this repo).

### VBW Agent Roster (for automated execution)

| Agent | Role |
|-------|------|
| Architect | Requirements → roadmap, stage decomposition |
| Lead | Research, task decomposition, plan generation |
| Dev | Plan execution with atomic commits |
| QA | Goal-backward verification |
| Debugger | Scientific method bug diagnosis |
| Docs | Documentation generation |
| Scout | Research and codebase scanning |

### Pipekit Agent Roster (for pipeline review)

Agents shipped by Pipekit (synced to consumer projects via `sync-method.sh` → `.claude/agents/`):

| Agent | Role | Invoked by |
|-------|------|------------|
| `plan-reviewer` | Independent review of VBW Lead's `PLAN.md` before Dev execution. Fills the gap VBW Lead's Stage 3 self-review can't cover: scope drift, framing errors, atomicity failures, test meaningfulness, risk/trap coverage. Read-only. | `/review-plan` (standalone skill — runs between `/vbw:vibe --plan` and `/vbw:vibe --execute`) |

### External Systems

| System | Role in Pipeline |
|--------|-----------------|
| Linear | Issue tracking, spec storage, agent review |
| VBW | Planning engine (PLAN.md, execution state) |
| Vercel | Deployment, CI/CD, preview URLs |

Additional integrations (Supabase, Sentry, Langfuse, etc.) are project-specific.

---

## SOPs

Detailed standard operating procedures for each discipline:

| SOP | Covers |
|-----|--------|
| [Git & Deployment](sop/Git_and_Deployment.md) | Branch strategy, worktrees, release flow |
| [Code Quality](sop/Code_Quality.md) | Pre-deploy gates, quality standards |
| [Linear Configuration](sop/Linear_SOP.md) | Issue tracking, labels, workflow states |
| [Skills](sop/Skills_SOP.md) | Skill authoring, triggers, conventions |
| [VBW Help](sop/VBW_Help.md) | VBW plugin reference |

## Templates

| Template | Purpose |
|----------|---------|
| [Light Spec Template](templates/light_spec_template.md) | Standard light spec structure (used by `/light-spec`) |
| [Spec Review Skill](templates/spec_review_skill.md) | Agent review prompt and rubric |
| [Linear Guidance](templates/linear_guidance.md) | Linear agent configuration |

---

## Project Configuration

Each consuming project maintains a `method.config.md` at its root with project-specific values (Linear workspace, issue prefix, state IDs, environment URLs, pre-deploy commands). Portable skills read this file at runtime. See `method.config.template.md` for the template.

---

## Outcome

This method creates a deterministic, low-ambiguity system for software delivery where:

- AI accelerates output without sacrificing quality
- Agents enforce quality gates at every stage
- Humans retain control over all product decisions
- Ambiguity is caught and resolved before it compounds
