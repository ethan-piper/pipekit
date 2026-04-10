---
name: phase-plan
description: Select issues for the next execution phase, track phase state, and promote to "Needs Spec"
---

# Phase Plan Skill

Define, track, and manage execution phases. A phase is a batch of issues selected for the current execution cycle — pulled from the roadmap, validated for dependencies, and promoted to "Needs Spec" so the spec pipeline can begin.

## Triggers

- `/phase-plan`
- `/phase-plan --next`
- `/phase-plan --status`
- `/phase-plan --rebalance`

## Arguments

| Argument | What it does |
|----------|--------------|
| (none) | Plan the next phase (or first phase if none exists) |
| `--next` | Propose the next phase after the current one ships |
| `--status` | Show current phase progress dashboard |
| `--rebalance` | Adjust current phase composition (add/remove issues) |
| `--dry-run` | Show proposed phase without promoting issues |

## Prerequisites

- `.vbw-planning/ROADMAP.md` must exist (output of `/roadmap-create`)
- Linear board must be populated with issues
- `method.config.md` must have Linear state IDs configured

## Phase Model

### How Phases Relate to Milestones and Cycles

| Concept | Purpose | Linear Construct | Relationship to Phases |
|---------|---------|-----------------|----------------------|
| **Milestone (Work Package)** | Feature cluster — groups related issues for gating | Linear Milestone | A phase may pull from multiple milestones. A large milestone may span multiple phases. |
| **Phase** | Execution batch — what we're building right now | Tracked in `.vbw-planning/PHASES.md` | The unit of work between `/phase-plan` and `/phase-plan --next`. |
| **Cycle** (optional) | Time-boxed sprint — capacity planning and velocity tracking | Linear Cycle | Optional overlay. If used, a phase maps to a cycle for time-boxing. Not required. |

**Milestones group by feature. Phases group by execution order.** These are different dimensions — milestones are permanent structure, phases are temporal.

### Phase State

Phases are tracked in `.vbw-planning/PHASES.md`, not in Linear. Linear tracks individual issue status; PHASES.md tracks which issues belong to which phase.

---

## Execution Steps

### Default: Plan a Phase

#### Step 1 — Assess Current State

1. Read `.vbw-planning/PHASES.md` if it exists
2. Read `.vbw-planning/ROADMAP.md` for phase priorities
3. Read `method.config.md` for Linear state IDs
4. Fetch all issues in the current phase from Linear:
   - Issues in On Deck, Needs Spec, Specced, Approved, Building, UAT
   - Group by status to understand pipeline state

If a current phase exists and has unfinished issues, warn:
_"Phase {N} is still in progress ({M} issues not yet Done). Plan the next phase anyway, or check status with `--status`?"_

#### Step 2 — Identify Candidates

1. Fetch issues in "On Deck" status (next phase candidates)
2. If On Deck is empty, check "Future Phases" for promotable issues
3. For each candidate:
   - Check dependencies via `mcp__linear-server__get_issue` with `includeRelations: true`
   - Classify as **ready** (no unresolved blockers) or **blocked** (list blockers)
   - Note milestone membership
   - Note complexity if available from existing description

#### Step 3 — Compose the Phase

Propose a phase following these guidelines:

| Guideline | Target |
|-----------|--------|
| Phase size | 3-8 issues |
| Complexity mix | At least 1 Low for quick wins, no more than 2 High |
| Dependency safety | No issue blocked by another issue outside the phase (unless the blocker is Done) |
| Milestone coverage | Prefer completing milestones over splitting them |
| Phase progress | Prioritize issues that unblock downstream work |

Present the proposal:

```
## Proposed Phase {N}: {Theme or Phase Name}

Issues (6):
  1. RSV-1  — User authentication [Low] (WP-1: Foundation)
  2. RSV-2  — Core data model [Medium] (WP-1: Foundation)
  3. RSV-3  — Basic search [Medium] (WP-2: Search)
  4. RSV-4  — Search filters [Low] (WP-2: Search)
  5. RSV-5  — Property detail view [Medium] (WP-2: Search)
  6. RSV-6  — Admin dashboard [Low] (WP-3: Admin)

Milestones touched: WP-1 (2/4 issues), WP-2 (3/5 issues), WP-3 (1/6 issues)
Complexity: 3 Low, 3 Medium, 0 High
Dependencies: RSV-3 depends on RSV-2 (both in phase — OK)

Not included (blocked):
  - RSV-7 — Advanced search (blocked by RSV-3)
  - RSV-8 — Export reports (blocked by RSV-5)

Remaining On Deck: 4 issues for future phases

Approve this phase? (y/n/edit)
```

#### Step 4 — Promote Issues

On approval:

1. Move selected issues from "On Deck" to "Needs Spec" via `mcp__linear-server__save_issue`:
   - `stateId`: Needs Spec state ID from `method.config.md`
2. If On Deck is now depleted, promote issues from "Future Phases" to "On Deck" for the next phase pipeline
3. Post a Linear comment on each promoted issue: `"Assigned to Phase {N}. Ready for /light-spec."`

#### Step 5 — Write PHASES.md

Create or update `.vbw-planning/PHASES.md`:

```markdown
# Phases

## Current Phase: Phase {N}
- **Started:** {date}
- **Theme:** {theme or phase name}
- **Milestone(s):** {list}
- **Issues:**
  - RSV-1 — User authentication [Needs Spec]
  - RSV-2 — Core data model [Needs Spec]
  - RSV-3 — Basic search [Needs Spec]
  - RSV-4 — Search filters [Needs Spec]
  - RSV-5 — Property detail view [Needs Spec]
  - RSV-6 — Admin dashboard [Needs Spec]

## Next Phase (proposed)
- **Issues (On Deck):** RSV-9, RSV-10, RSV-11, RSV-12
- **Blocked until Phase {N} completes:** RSV-7, RSV-8

## Completed Phases
(none yet)
```

#### Step 6 — Summary

```
## Phase {N} Planned

Issues promoted to "Needs Spec": {N}
On Deck refilled: {N} issues promoted from Future Phases

Next steps:
  - /roadmap-review — validate the phase before speccing
  - /light-spec RSV-1 — start speccing the first issue
  - /phase-plan --status — check progress anytime
```

---

### `--status`: Phase Progress Dashboard

1. Read `.vbw-planning/PHASES.md` for current phase composition
2. Fetch current status of each phase issue from Linear
3. Display:

```
## Phase {N} Status — {date}

| Issue | Title | Status | Days in Status |
|-------|-------|--------|---------------|
| RSV-1 | User authentication | Done | — |
| RSV-2 | Core data model | Building | 2d |
| RSV-3 | Basic search | Specced | 1d |
| RSV-4 | Search filters | Needs Spec | 3d |
| RSV-5 | Property detail view | UAT | 0d |
| RSV-6 | Admin dashboard | Approved | 1d |

Progress: 1/6 Done (17%)
Pipeline: 1 Needs Spec → 1 Specced → 1 Approved → 1 Building → 1 UAT → 1 Done

Alerts:
  - RSV-4 has been in "Needs Spec" for 3 days — run /light-spec RSV-4
  - RSV-2 has been in "Building" for 2 days — check progress

Phase started: {date} ({N} days ago)
```

---

### `--next`: Plan the Next Phase

1. Archive the current phase to "Completed Phases" in PHASES.md
2. Run the default phase planning flow (Steps 1-6)
3. Include a brief retrospective:

```
## Phase {N-1} Retrospective

Completed: {date} ({N} days)
Issues: {done}/{total} completed
  - {failed} failed (returned to Approved)

Complexity accuracy:
  - Low estimates: averaged {X}h (target: 2-4h)
  - Medium estimates: averaged {X}h (target: 6-10h)
```

---

### `--rebalance`: Adjust Current Phase

1. Show current phase composition
2. Options:
   - **Add issues:** Move from On Deck → Needs Spec, add to PHASES.md
   - **Remove issues:** Move from Needs Spec → On Deck (only if not yet started), remove from PHASES.md
   - **Replace:** Remove one, add another
3. Validate dependencies after rebalance
4. Update PHASES.md

---

## Rules

- **3-8 issues per phase.** Fewer is fine for a first phase or complex work. More creates coordination overhead.
- **Dependencies within the phase must be satisfiable.** If RSV-3 depends on RSV-2, both must be in the phase (or RSV-2 must already be Done).
- **Don't split milestones unless necessary.** Prefer completing a WP in one phase. Split only when the WP is too large (>8 issues) or has mixed priorities.
- **On Deck is the staging area.** Issues move: Future Phases → On Deck → Needs Spec. `/phase-plan` manages the On Deck → Needs Spec promotion. Refilling On Deck from Future Phases happens automatically.
- **PHASES.md is the phase registry.** Linear tracks individual issue status. PHASES.md tracks phase composition and history.
- **Human decides phase composition.** Present a recommendation with rationale, but the user approves.

## Red Flags

If you catch yourself thinking any of these, follow the process more strictly:

- **"Let's just put everything in one phase"** → 3-8 issues. More than 8 creates coordination overhead and hides priorities.
- **"This blocked issue will probably be unblocked soon"** → Don't plan on hope. If the blocker isn't Done, the issue isn't ready.
- **"We can split this milestone across 4 phases"** → Prefer completing milestones. If you're splitting that many ways, the milestone is too big — break it up in Linear.
- **"The phase is fine, no need to rebalance"** → If an issue has been in "Needs Spec" for >3 days, something is wrong. Either spec it or swap it out.

## Related

- `/roadmap-create` — previous step: creates the roadmap and populates Linear
- `/roadmap-review` — run after phase planning to validate before speccing
- `/light-spec` — next step: spec the first issue in the phase
- `/launch` — executes specced issues (uses milestones for gating, not phases)
- `/linear-status` — quick board view (complementary to `--status`)
