---
name: strategy-create
description: Bootstrap strategy docs from a project definition — configurable doc set tailored to project needs
---

# Strategy Create Skill

Generate initial strategy docs from a project definition. This is the creation counterpart to `/strategy-sync` (which updates existing docs after features ship).

## Triggers

- `/strategy-create`
- "create strategy docs"
- "bootstrap strategy docs"

## Prerequisites

- `project-definition.md` should exist (output of `/define`)
- If it doesn't exist, warn: _"No project definition found. Run `/define` first."_

## Purpose

Strategy docs are the human-readable explanation of the product. They serve two audiences:
1. **Stakeholders** — understand what the product does in plain language
2. **Developers** — understand the technical model, permissions, and patterns

These docs are living documents: `/strategy-create` generates v0.1.0, `/strategy-sync` updates them after features ship. Code is always truth — docs track reality.

## Execution Steps

### Phase 1 — Determine Doc Set

1. Read `project-definition.md`
2. Read `method.config.md` if it exists (may already have a Strategy Docs table)
3. Analyze the project definition to recommend which docs are needed:

**Always create:**
| Doc | Template | When |
|-----|----------|------|
| Conceptual Overview | `templates/strategy/conceptual-overview.md` | Always |
| Technical Architecture | `templates/strategy/technical-architecture.md` | Always |

**Create if applicable:**
| Doc | Template | Trigger |
|-----|----------|---------|
| Permissions | `templates/strategy/permissions.md` | Project has user roles with different access levels |
| Data Model | `templates/strategy/data-model.md` | Project has complex data relationships or calculations |
| Workflow Examples | `templates/strategy/workflow-examples.md` | Project has multi-step user journeys |
| UX Reference | `templates/strategy/ux-reference.md` | Project has complex UI interactions |

4. Present the recommended doc set:

```
## Recommended Strategy Docs for {Project Name}

Required:
  1. Conceptual Overview — what it does (stakeholders)
  2. Technical Architecture — how it works (developers)

Recommended based on your project:
  3. Permissions — you defined {N} user roles with different access
  4. Data Model — your workflows involve {entities}

Optional:
  5. Workflow Examples — would help document {N} key workflows
  6. UX Reference — skip for now, add when UI patterns emerge

Create all recommended? Or adjust the list?
```

5. User approves or adjusts the doc set.

### Phase 2 — Generate Each Doc

For each approved doc, in order:

1. Read the template from `templates/strategy/`
2. Read `project-definition.md` for source material
3. Generate a first draft:
   - Fill in project-specific content from the definition
   - Match the audience level specified in the template header
   - Mark sections as `[TBD]` where the definition doesn't provide enough detail
   - Set version to `v0.1.0` and date to today
4. Present the draft to the user: _"Here's the draft {doc name}. Review and edit?"_
5. Iterate until approved

**Audience discipline:**
- Conceptual Overview: Simple language. A stakeholder with no technical background should understand it completely. No code, no jargon.
- Technical Architecture: Developer-level. Schema detail, API patterns, code conventions.
- Permissions: Technical but clear. Admins need to understand the access model.
- Data Model: Developer-level. Entity relationships, constraints, calculations.
- Workflow Examples: Step-by-step, concrete. All audiences.
- UX Reference: Practical. Developers and support need to understand UI patterns.

### Phase 3 — Write Files

1. Create the `Strategy/` directory if it doesn't exist
2. Write each approved doc to `Strategy/`
3. Use consistent filenames matching the method config format:
   - `Strategy/ConceptualOverview.md`
   - `Strategy/TechnicalArchitecture.md`
   - `Strategy/Permissions.md`
   - `Strategy/DataModel.md`
   - `Strategy/WorkflowExamples.md`
   - `Strategy/UXReference.md`

### Phase 4 — Update Config

1. Read `method.config.md` (create from template if it doesn't exist)
2. Update the `## Strategy Docs` table with the docs just created:

```markdown
## Strategy Docs

| Doc | File | Purpose | Audience |
|-----|------|---------|----------|
| Conceptual Overview | `Strategy/ConceptualOverview.md` | What the product does | Stakeholders |
| Technical Architecture | `Strategy/TechnicalArchitecture.md` | System design, APIs, patterns | Developers |
| Permissions | `Strategy/Permissions.md` | Auth, roles, access control | Developers, Admins |
```

3. This table is read by `/strategy-sync` to know which docs to update after features ship.

### Phase 5 — Summary

```
## Strategy Docs Created

Directory: Strategy/
Docs created: {N}
  - ConceptualOverview.md (v0.1.0)
  - TechnicalArchitecture.md (v0.1.0)
  - Permissions.md (v0.1.0)
  - ...

Config updated: method.config.md — Strategy Docs table

TBD sections: {N} items across {M} docs need detail as the project develops
  - TechnicalArchitecture.md §Data Model: schema not yet defined
  - ...

Next steps:
  - Tech stack decisions (if not yet made): /startup
  - /roadmap-create — turn project phases into a structured roadmap
  - Strategy docs will be updated automatically via /strategy-sync after features ship
```

## Rules

- **v0.1.0 is intentionally incomplete.** Strategy docs grow with the project. It's fine to have `[TBD]` sections — they'll be filled as features are built and `/strategy-sync` runs.
- **Don't invent features.** Strategy docs describe what's in the project definition, not new ideas. If a doc feels thin, that's OK — it'll grow.
- **Match audience.** Conceptual Overview reads like a product pitch. Technical Architecture reads like system design docs. Don't mix the registers.
- **Config is the manifest.** The `method.config.md` Strategy Docs table is the source of truth for which docs exist. Both `/strategy-create` and `/strategy-sync` read it.
- **Human approves each doc.** Present drafts, iterate, write only after approval.

## Red Flags

If you catch yourself thinking any of these, follow the process more strictly:

- **"This project only needs one doc"** → Every project needs at minimum Conceptual Overview + Technical Architecture. No exceptions.
- **"I'll fill in the details later"** → `[TBD]` is fine. But an entire section marked `[TBD]` means the project definition wasn't complete enough. Go back to `/define`.
- **"I know what tone this audience needs"** → Read the template header. Conceptual Overview = no jargon. Technical Architecture = schema detail. Don't mix registers.
- **"This doc is too thin"** → v0.1.0 is supposed to be thin. It grows with the project. Don't invent features to fill pages.

## Related

- `/define` — previous step: creates the project definition that feeds this skill
- `/strategy-sync` — counterpart: updates these docs after features ship
- `/roadmap-create` — next step: uses strategy docs to build the roadmap
- `templates/strategy/` — templates for each doc type
