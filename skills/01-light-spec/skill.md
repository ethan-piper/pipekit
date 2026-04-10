---
# name: light-spec
Description: Draft a structured light spec for a Linear issue, optionally with Linear agent refinement, ready for VBW planning ingestion

---

# Light Spec Skill

Draft a structured, VBW-ingestible specification for a Linear issue. Bridges the gap between raw brainstorms and full VBW PLAN.md files.

## Triggers

- `/light-spec` — start from scratch or provide an issue ID
- `/light-spec WIT-123` — spec an existing issue

## Purpose

Create a **light spec** — enough structure for VBW to generate a plan, but fast enough to draft in one pass. Optionally delegate to Linear's agent for refinement before pulling into planning mode.

## Core Principle

A light spec is an **AI→AI contract**: Generator → Reviewer → Planner. You are not guiding a human — you are constraining an AI. Every rule in this spec must be:

- **Explicit** — no implied behavior
- **Unambiguous** — one interpretation only
- **Enforceable** — a downstream agent can validate compliance

**Controlled incompleteness is allowed.** Light specs are intentionally lightweight. Brevity, `[TBD]` markers, and limited context are fine. Hidden assumptions and implicit behavior are not. The line is: _can the planner work without guessing?_

## Inputs

| Input | Source | Required |
|-------|--------|----------|
| Issue ID (e.g., `WIT-123`) | Argument or prompt | No — creates new issue if omitted |
| Idea description | User prompt | Yes, if no issue ID |

## Execution Steps

### Phase 1 — Capture

1. **If issue ID provided**: Fetch via `mcp__linear-server__get_issue` (with `includeRelations: true`). Extract title, description, existing labels, project, and any sub-issues.
2. **If raw idea**: Ask the user for a 1-2 sentence description of what they want and why.

### Phase 2 — Technical Context

Explore the codebase to understand what exists and what's needed:

1. Use the `Explore` agent (subagent_type: Explore, thoroughness: medium) to answer:
   - What existing code/infrastructure is relevant?
   - What patterns does the codebase already use for similar features?
   - What database tables, APIs, or UI components are involved?
   - Are there any obvious constraints or blockers?
2. Read `.vbw-planning/linear-map.json` to identify which VBW phase and Linear project this work aligns with.
3. Check `.vbw-planning/.execution-state.json` for current phase context.

### Phase 3 — Draft Light Spec

Write the spec using the **Light Spec Template** below. Fill in every section.

**Decision discipline:** All behavior-affecting decisions MUST be either defined or marked `[TBD]`. A decision left implicit (not mentioned at all) makes the spec invalid — the planner will guess, and guesses compound. `[TBD]` is only valid if it does **not** block task decomposition. If a `[TBD]` would force the planner to guess at task boundaries, the decision must be resolved before the spec is ready.

**Scope discipline:** Specs define WHAT, not HOW. Apply this litmus test: if a statement can be rewritten as "change X line" or "use Y syntax," it is implementation detail and must be removed. Do not include file paths to create, function signatures, or implementation patterns — VBW planning agents own the HOW.

### Phase 3.5 — Planning Readiness Check

Before presenting to the user, audit every section:

1. **Identify every point where VBW would need to guess** — scan for implicit assumptions, undefined behaviors, and missing decision points
2. **For each guessing point**, do one of:
   - Convert it into a **Decision** (defined or `[TBD]`)
   - Clarify the **Scope** to eliminate the ambiguity
   - Move it to **Risks & Open Questions** if it can't be resolved now
3. **Validate:** the spec is only ready when no guessing is required for task decomposition. `[TBD]` is acceptable; implicit assumptions are not.

### Phase 4 — Present and Iterate

1. Show the draft spec to the user.
2. Ask: _"Want to refine anything before I push this to Linear?"_
3. Iterate until the user approves.

### Phase 5 — Publish to Linear

1. **Update or create** the Linear issue via `mcp__linear-server__save_issue`:
   - `team`: `{team from method.config.md}`
   - `title`: concise spec title (prefix with domain if useful, e.g., "Budget: Multi-currency support")
   - `description`: the full light spec (markdown)
   - `state`: `Specced` (light spec applied, awaiting human review)
   - `priority`: ask user (default 0/None if unsure)
   - `project`: suggest based on Phase 2 findings, confirm with user
   - `labels`: add `spec` label
2. Store the issue ID for reference.

### Phase 6 — Optional: Linear Agent Review

Ask the user: _"Want Linear's Spec Review Agent to review this before planning?"_

If yes, post a comment via `mcp__linear-server__save_comment` that triggers the agent with `@linear`:

   ```
   @linear review this spec using Spec Review Agent (v5).

   Assess whether it is safe and ready for VBW planning. Focus on planning readiness, scope clarity, authority/source of truth, edge cases, financial correctness if relevant, and decomposition readiness.

   Return:

   Verdict: Pass or Revise
   Recommended Flag: Blocked, Quick Win, Spec: Needed, Spec: Pass, or Spec: Revise
   Readiness Score out of 10
   Blocking Issues
   Non-Blocking Improvements
   Fast Path to Pass
   Decomposition Readiness: Yes or No
   Final Recommendation

   Then update the issue description by replacing the existing ## Agent Review section with the new review.
   ```

Tell the user: _"Linear's agent is reviewing. Once it updates the description, run `/light-spec WIT-XXX` again to pull in its feedback, or go straight to planning mode."_

### Phase 7 — VBW Ingestion Pointer

Tell the user how to proceed:

> **Next steps:**
> - To flesh this out into a full VBW plan: enter planning mode and reference this issue
> - To batch-process with other specced issues: `/linear-todo-runner` (requires Acceptance Criteria section)
> - To refine further: `/light-spec WIT-XXX` to iterate

---

## Light Spec Template

Read the canonical template from `templates/light_spec_template.md` in the method repo (or `method/templates/light_spec_template.md` in consuming projects). Use that template structure for all specs.

---

## How This Connects to VBW

The light spec is designed so VBW's planning agents can consume it directly:

| Light Spec Section | VBW Plan Section |
|--------------------|-----------------|
| Problem + Goal | `<objective>` |
| Proposed Solution | `<objective>` approach description |
| Scope | Plan scope boundaries + `forbidden_commands` |
| Decisions | `must_haves.truths` (defined) or research tasks (TBD) |
| Requirements | `must_haves.truths` |
| Acceptance Criteria | `<verify>` + `<done>` per task, `<success_criteria>` |
| Technical Context + Authority | `<context>` + `files_modified` |
| Risks & Open Questions | Research tasks (`type: research`) in the plan |
| Complexity | `effort_override` (Low→expedited, Med→standard, High→thorough) |

When entering planning mode, reference the issue:
> "Plan WIT-XXX using the light spec in its description. Resolve open questions, break into tasks, and generate a PLAN.md."

The VBW lead agent will read the Linear issue, extract the spec, and use it as the foundation for task decomposition.

---

## Complexity Guidelines

Same as `/brainstorm`, but with planning implications:

- **Low (~2-4h):** Can skip full VBW planning — spec is sufficient for `/linear-todo-runner` to pick up directly if AC section is complete.
- **Medium (~6-10h):** Benefits from a single VBW plan (1 PLAN.md). The light spec provides enough for the lead agent to generate tasks.
- **High (~12-20h+):** Likely needs multiple VBW plans across a phase. The light spec seeds the architect agent's phase decomposition.

## Red Flags

If you catch yourself thinking any of these, follow the process more strictly:

- **"This feature is simple, I don't need to explore the codebase"** → Run the Explore agent. Your assumptions about what exists are wrong more often than they're right.
- **"The authority is obvious"** → Define it explicitly anyway. Ambiguous authority is the #1 cause of spec revision.
- **"These acceptance criteria are fine as-is"** → Apply the litmus test: can the planner verify each one without guessing? "Works correctly" always fails.
- **"I'll leave this decision implicit, it's clear from context"** → If it's not in the Decisions section (defined or `[TBD]`), the spec is invalid. Context is not a contract.
- **"I know this API"** → Check the installed version. Your training data is stale.

## Related Skills

- `/brainstorm` — lighter: feasibility-only, no structured spec
- `/sync-linear` — syncs VBW ↔ Linear after plans exist
- `/linear-todo-runner` — executes specced issues in parallel (requires AC section)
- `/spec-validator` — validates full Strategy docs (heavier than light specs)
