---
name: brainstorm
description: Analyze a feature idea, assess feasibility, and create a Linear issue
---

# Brainstorm Skill

You are a brainstorm processor. Read `method.config.md` for project context. When the user shares an idea, you analyze it, assess its feasibility, and create a Linear issue.

## Triggers

This skill is invoked when the user says:
- `/brainstorm`
- "brainstorm"
- "new brainstorm"
- "I have an idea"

## Purpose

Take a rough idea from the user, explore the codebase to understand feasibility, create a structured analysis, and capture it as a Linear issue.

## Execution Steps

### Phase 1 — EXPAND (Brainstorm)

1. **Capture** the idea from the user
2. **Explore** the codebase to assess feasibility
3. **Create structured analysis** with complexity, requirements, implementation approach
4. **Present** to user for approval
5. **Create Linear issue** via `mcp__linear-server__save_issue`:
   - `team`: `{team from method.config.md}`
   - `title`: concise feature title
   - `description`: full brainstorm analysis (feasibility, complexity, approach, requirements)
   - `priority`: 0 (None) — triage sets real priority later
   - Ask user which project to assign (or leave unassigned)
   - `state`: Triage
6. If complexity is **High** → suggest creating a detailed spec via `/light-spec`
7. **Output**: issue identifier and Linear URL

### Phase 2 — HOLD (Disposition)

Immediately after creating the issue, force a disposition decision:

> **What should happen with this idea?**
>
> 1. **Now** → Route to pipeline. Assign to a phase/stage, move to Needs Spec.
> 2. **Later** → Park with a trigger condition and target phase.
> 3. **Kill** → Archive with rationale.

**If Now:**
- Ask which stage/phase this belongs to
- Move issue to "Needs Spec" via `mcp__linear-server__save_issue`
- Inform: _"Ready for `/light-spec {issue}` when you start the phase."_

**If Later:**
- Ask for a **trigger condition** — what must be true before revisiting? (e.g., "revisit when RSV-56 ships", "revisit after Stage 1 UAT")
- Ask for a **target phase/stage** (e.g., "Phase 4+", "Stage 2")
- Move issue to "Ideas" or "Future Phases" based on target
- Add a `Parked` label if available
- Post a Linear comment with the trigger condition:
  ```
  **Parked:** Revisit when {trigger condition}. Target: {phase/stage}.
  ```
- These are surfaced by `/roadmap-review` when trigger conditions are met.

**If Kill:**
- Ask for rationale (one sentence)
- Move issue to "Canceled"
- Post a Linear comment: `"Killed: {rationale}"`

### Phase 3 — REDUCE (for "Now" items only)

If the disposition is **Now** and the brainstorm is broad, cut to v1 scope:

1. Review the brainstorm analysis
2. Ask: _"What's the smallest useful version of this? What can wait for v2?"_
3. Update the issue description with a `## v1 Scope` section that trims to essentials
4. This reduced scope is what `/light-spec` will work from

## Complexity Guidelines

- **Low (~2-4 hours):** UI-only, simple CRUD, existing infrastructure
- **Medium (~6-10 hours):** New API endpoint, combines existing systems
- **High (~12-20+ hours):** New infrastructure, complex logic, multiple integrations → suggest `/speckit`

## Description Template

Format the Linear issue description as:

```markdown
## Brainstorm Analysis

**Complexity:** Low / Medium / High
**Estimated Effort:** X-Y hours

### Summary
[1-2 sentence description]

### Feasibility Assessment
[What exists in the codebase, what's needed, any blockers]

### Implementation Approach
[High-level steps]

### Requirements
- [requirement 1]
- [requirement 2]

### Notes
[Any caveats, dependencies, or open questions]
```

## Red Flags

If you catch yourself thinking any of these, follow the process more strictly:

- **"This idea is obviously feasible"** → Explore the codebase. "Obviously feasible" ideas that skip exploration become surprisingly complex specs.
- **"I'll estimate Low complexity"** → Low means 2-4 hours of implementation. If you haven't explored the codebase, you can't estimate. Explore first.
- **"We can figure out the dependencies later"** → Capture them now. Dependencies discovered during execution are 10x more expensive than dependencies discovered during brainstorming.
- **"This doesn't need a Linear issue, it's just an idea"** → Every idea gets an issue. Ideas without issues get forgotten. Issues without ideas get built blindly.

## Related

- `/brainstorm-review` — triage untriaged Linear issues with disposition
- `/concept` — project-level ideation (for new projects, not features)
- `/light-spec` — next step for ideas that move forward
- `/phase-plan` — "Now" dispositions feed into phase planning
