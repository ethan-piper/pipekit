---
name: define
description: Distill a validated concept into a full project definition — phases, roles, workflows, success criteria
---

# Define Skill

Take a validated concept brief and produce a complete project definition. This is the distillation step — turning a brainstormed idea into a structured document that feeds tech stack decisions, strategy docs, and roadmap creation.

## Triggers

- `/define`
- `/define --docs path/to/additional/docs/`
- "define the project"
- "create project definition"

## Arguments

| Argument | What it does |
|----------|--------------|
| (none) | Read `concept-brief.md` and build from it |
| `--docs <path>` | Read additional documents alongside the concept brief |

## Prerequisites

- `concept-brief.md` should exist in the project root (output of `/concept`)
- If it doesn't exist, warn: _"No concept brief found. Run `/concept` first, or provide the idea and I'll work from scratch."_

## Purpose

Produce a `project-definition.md` that is complete enough to:
1. Make tech stack decisions
2. Write strategy docs
3. Create a phased roadmap
4. Set up Linear with the right structure

The concept brief says "should I build this?" The project definition says "what exactly am I building?"

## Execution Steps

### Phase 1 — Gather Context

1. Read `concept-brief.md` from the project root
2. If `--docs` provided: use an Explore agent to read additional documents and extract:
   - Detailed requirements, user stories, wireframes
   - Technical constraints or preferences
   - Business rules, compliance requirements
   - Existing system documentation
3. Read any existing `project-definition.md` (if re-running to refine)

### Phase 2 — Project Identity

Extract or confirm from the concept brief:

| Field | Source |
|-------|--------|
| Project name | Ask user (may differ from concept brief title) |
| One-liner | Distill from concept brief's Problem + Solution |
| Target users | From concept brief's Target Users |
| Problem solved | From concept brief's Problem |
| Success looks like | Derive from concept brief + user input |

Present for confirmation: _"Here's the project identity I extracted. Correct?"_

### Phase 3 — Phase Breakdown

This is the core of the definition — splitting the product into independently deployable phases.

1. Read the concept brief's full scope
2. Propose a phase breakdown:
   - **Phase 1 (MVP):** The smallest version that proves value
   - **Phase 2 (Growth):** Features that make it sticky
   - **Future Phases:** Everything else — documented but not planned
3. For each phase, define:
   - **Goal** — one sentence
   - **In scope** — concrete deliverables
   - **Out of scope** — explicitly excluded (prevents scope creep)
   - **Exit criteria** — how do you know this phase is done? (measurable)

Present each phase for approval. The user may move features between phases.

**Key principle:** Phase 1 must be independently valuable. If Phase 1 only makes sense with Phase 2, the split is wrong.

### Phase 4 — User Roles

1. Extract roles from the concept brief (Target Users section)
2. For each role, define:
   - Description (what this role does)
   - Key permissions (what they can access/modify)
3. Ask: _"Are there any admin or system roles beyond the primary users?"_

### Phase 5 — Key Workflows

Identify the 3-5 critical user journeys that define the product.

1. For each phase, ask: _"What are the most important things a user does?"_
2. For each workflow, capture:
   - **Actor** — which role
   - **Trigger** — what starts this workflow
   - **Steps** — the key actions (3-7 steps, not exhaustive)
   - **Outcome** — what's true when it's done

These workflows seed the Strategy docs (Workflow Examples) and help identify data requirements.

### Phase 6 — Integration Requirements

1. From the concept brief's Constraints section, extract external system dependencies
2. For each integration:
   - System name
   - Purpose (what data flows and why)
   - Direction (in, out, or both)
   - Priority (MVP or later phase)

### Phase 7 — Success Criteria

Define measurable outcomes per phase. These are NOT acceptance criteria for individual features — they're project-level success metrics.

Examples:
- Phase 1: "10 users complete the core workflow without support intervention"
- Phase 1: "Data migration from Excel completes for 3 pilot customers"
- Phase 2: "Monthly active users > 30"

### Phase 8 — Non-Functional Requirements

Capture NFRs that affect tech stack and architecture decisions:

| Category | What to ask |
|----------|-------------|
| Performance | Response time requirements? Data volume? |
| Security | Auth model? Data sensitivity? Compliance? |
| Availability | Uptime requirements? Disaster recovery? |
| Compliance | GDPR, SOC2, HIPAA, industry-specific? |
| Accessibility | WCAG level? Screen reader support? |

Only capture what's relevant — skip categories that don't apply.

### Phase 9 — Draft and Review

1. Compile everything into `project-definition.md` using the template from `templates/project-definition.md`
2. Fill in the `## Source Documents` table
3. Present the complete definition to the user

Ask: _"Is this definition complete enough to choose a tech stack and write strategy docs?"_

If no: identify which sections need more detail and iterate.

### Phase 10 — Save

1. Write `project-definition.md` to the project root
2. Set Status to `Approved` if the user confirms completeness
3. Report next steps:

```
## Project Definition Created

File: project-definition.md
Status: {Approved | Draft}
Phases: {N} defined
Roles: {N} identified
Workflows: {N} captured

Next steps:
  - Tech stack decisions (via /startup Phase 3)
  - /strategy-create — generate strategy docs from this definition
  - /roadmap-create — turn phases into a structured roadmap
```

## Rules

- **Distill, don't invent.** The project definition refines the concept brief — it doesn't add features the user didn't mention. If you think something is missing, ask, don't assume.
- **Phase 1 must stand alone.** If MVP only works with Phase 2 features, push back on the split.
- **Measurable exit criteria.** "Users like it" is not an exit criterion. "10 users complete the core workflow" is.
- **WHAT, not HOW.** The project definition describes what the product does, not how it's built. Tech stack, architecture, and implementation patterns come later.
- **Human decides scope.** Present trade-offs, but the user decides what's in Phase 1 vs. Phase 2.

## Red Flags

If you catch yourself thinking any of these, follow the process more strictly:

- **"Phase 1 needs Feature X to be useful"** → If Phase 1 can't stand alone, the phase split is wrong. Push back.
- **"I'll add that to Phase 1, it's small"** → Scope creep starts here. If it wasn't in the concept brief, question why it's in Phase 1.
- **"Success criteria can be vague for now"** → No. "Users like it" is not measurable. Define the number.
- **"I know what workflows they need"** → Ask. Your assumptions about user behavior are almost certainly wrong.

## Related

- `/concept` — previous step: validate the idea is worth defining
- `/strategy-create` — next step: generate strategy docs from this definition
- `/startup` — orchestrates the full flow (concept → define → setup → ...)
- `/roadmap-create` — turns this definition's phases into a structured roadmap
