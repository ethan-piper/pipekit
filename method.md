# The Method

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

[Roadmap Review] → Light Spec → Agent Review → Human Review → **Launch** → VBW Plan → Plan Review → Execution → QA → UAT → Ship → [Strategy Sync]

**Bookends:** `/roadmap-review` validates the plan before entering the pipeline. `/strategy-sync` updates Strategy docs after features ship — closing the documentation loop.

### Step-by-Step

| # | Step | Tool | Input | Output | Gate |
|---|------|------|-------|--------|------|
| 0 | **Roadmap Review** | `/roadmap-review` | ROADMAP, Linear state | Health report: gaps, ordering, spec coverage, doc freshness | Plan must be coherent before speccing |
| 1 | **Light Spec** | `/light-spec` + Linear | Feature idea or issue | Structured spec exploring codebase and Strategy docs | — |
| 2 | **Agent Review** | Linear Spec Review Agent | Light spec | Pass/Revise verdict with readiness score | Spec must be unambiguous and decomposable without guessing |
| 3 | **Human Review** | You in Linear | Agent-reviewed spec | Approved spec with product decisions locked | Human signs off on scope, decisions, and priority |
| 4 | **Launch** | `/launch {ISSUE}` | Approved spec | Gates validated, complexity routed, issue → Building | Spec exists, deps met, milestone siblings all specced |
| 5 | **VBW Plan** | VBW Lead Agent (via `/launch`) | Approved spec from Linear | `PLAN.md` with task decomposition, verify/done criteria | — (Low complexity skips to batch runner) |
| 6 | **Plan Review** | `plan-reviewer` agent (via `/launch`) | PLAN.md | Validated plan or revision requests | Plan must be executable step-by-step without ambiguity |
| 7 | **Execution** | VBW Dev Agent or `/linear-todo-runner` (via `/launch`) | Approved plan or AC | Atomic commits per task | Each task passes its own verify/done criteria |
| 8 | **QA** | VBW QA Agent (via `/launch`) | Completed tasks | Verification report, issue → UAT | All tasks verified against goals |
| 9 | **UAT** | You | Built feature | Accepted or rejected | Feature matches spec AC under real usage |
| 10 | **Ship** | Promotion skills | Accepted feature | Production release | CI gates pass, smoke tests pass |
| 11 | **Strategy Sync** | `/strategy-sync` | Shipped features, current Strategy docs | Updated docs reflecting reality | Code is truth; diffs approved before apply |

**Feedback loops:** Steps 2, 6, 8, and 9 can send work backward. Agent review returns specs for revision. Plan review returns plans for rework. QA returns tasks to dev. UAT returns features to execution. The pipeline is linear by default, corrective when needed.

> **Optional pre-step:** `/brainstorm` — for exploring raw ideas, assessing feasibility, and estimating complexity before committing to a spec. Not part of the core pipeline.

---

## Pre-Condition: Roadmap Review

**Step:** 0

**Tools:** `/roadmap-review`

Run before entering the pipeline to validate that the roadmap is coherent: all requirements have Linear issues, dependencies are set, workflow states are consistent, and spec coverage is adequate for the next wave. Also flags Strategy doc staleness (recommends `/strategy-sync` if needed).

**Output:** Health report with action items. Resolve blockers before speccing.

---

## Phase 1: Definition (Spec Quality Gate)

**Steps:** 1–3 (Light Spec → Agent Review → Human Review)

**Tools:** `/light-spec`, Spec Review Agent, Human

- `/light-spec` explores the codebase, reads reference material and Strategy docs, and generates a structured spec as an AI→AI contract
- Spec Review Agent enforces planning readiness (Pass/Revise with blocking issues identified)
- Human validates product decisions, scope, and priority
- Iteration continues until Agent passes AND Human approves

**Output:** Planning-safe spec (stored as Linear issue description)

**Gate:** Spec must be unambiguous and decomposable without guessing. All decisions defined or explicitly marked [TBD] (where TBD does not block task decomposition).

---

## Phase 2: Launch & Planning (Execution Quality Gate)

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

## Phase 3: Execution (Build Quality Gate)

**Steps:** 7–9 (Execution → QA → UAT)

**Tools:** VBW Dev Agent, `/linear-todo-runner`, VBW QA Agent, Human

- Dev agent executes atomic tasks with one commit per task
- `/linear-todo-runner` can batch-process multiple specced issues in parallel (requires AC section)
- QA agent verifies completed work using goal-backward methodology
- Human performs acceptance testing against the spec's AC

**Output:** Shippable feature

**Gate:** Feature must match spec behaviour and pass real usage. All AC checkboxes satisfied.

---

## Phase 4: Release

**Steps:** 10 (Ship)

Every step forward is a PR. No direct merges between long-lived branches. Each project defines its own promotion skills (e.g., `/g-promote-dev`, `/g-promote-beta`, `/g-promote-main`).

- CI enforces pre-deploy gate at each PR
- Post-deploy smoke tests confirm the release

**Output:** Production release

**Gate:** CI passes, pre-deploy gate passes, smoke tests pass.

---

## Phase 5: Documentation Loop

**Step:** 11

**Tools:** `/strategy-sync`

After features ship and UAT passes, run `/strategy-sync` to update Strategy docs to reflect what was actually built. Code is truth — if the implementation differs from the spec, docs match the code.

```
Strategy Docs (vision) → Light Specs → Plans → Code → Strategy Docs (reality)
                  ↑                                              |
                  └──────────── /strategy-sync ─────────────────┘
```

**Output:** Updated Strategy docs with version bump. All changes presented as diffs for human approval before applying.

**Cadence:** After UAT passes for a wave/phase, before stakeholder presentations, before onboarding new team members.

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

## Tooling

### Interactive Skills (for hands-on sessions)

| Skill | Purpose |
|-------|---------|
| `/roadmap-review` | Pre-pipeline health check: completeness, dependencies, spec coverage |
| `/brainstorm` | Feasibility exploration (lighter than spec) |
| `/light-spec` | Structured spec generation with agent review |
| `/launch {ISSUE}` | Formalized trigger: validates gates, routes by complexity, manages status |
| `/launch --milestone {WP}` | Launch all ready issues in a milestone |
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
| Architect | Requirements → roadmap, phase decomposition |
| Lead | Research, task decomposition, plan generation |
| Dev | Plan execution with atomic commits |
| QA | Goal-backward verification |
| Debugger | Scientific method bug diagnosis |
| Docs | Documentation generation |
| Scout | Research and codebase scanning |

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
