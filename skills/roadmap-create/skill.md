---
name: roadmap-create
description: Create a phased roadmap from strategy docs and populate Linear with issues, projects, and milestones
---

# Roadmap Create Skill

Extract requirements from strategy docs and the project definition, create a structured ROADMAP.md, and populate Linear with the initial issue hierarchy.

## Triggers

- `/roadmap-create`
- "create the roadmap"
- "set up the roadmap"

## Prerequisites

- `project-definition.md` must exist (output of `/define`)
- `Strategy/` docs should exist (output of `/strategy-create`)
- `.vbw-planning/` directory should be scaffolded (run `/vbw:init` first)
- `method.config.md` should exist with Linear configuration
- Linear MCP server must be connected (`mcp__linear-server__*` tools available)

If `.vbw-planning/` doesn't exist, warn: _"Run `/vbw:init` first to scaffold the planning directory."_

## Purpose

Bridge the gap between "here's what the product does" (strategy docs) and "here are the work items" (Linear board). Every requirement in the roadmap traces back to a strategy doc section. Every Linear issue traces to a roadmap requirement.

## Execution Steps

### Phase 1 — Extract Requirements

1. Read `project-definition.md` for phase breakdown, exit criteria, and workflows
2. Read all Strategy docs listed in `method.config.md`'s Strategy Docs table
3. For each phase defined in the project definition:
   - Extract features, capabilities, and requirements from the strategy docs
   - Each requirement should be:
     - **Concrete** — "User can search properties by criteria" not "search functionality"
     - **Independent** — can be specced and built as a single Linear issue
     - **Traceable** — references the strategy doc section it comes from
   - Identify dependencies between requirements

4. Group requirements into **feature clusters** — logical groupings that will become Linear Projects:
   - e.g., "Data Foundation", "Search & CRUD", "Auth & Permissions", "Reports"
   - Each cluster should be cohesive (related features) and focused (not a catch-all)

### Phase 2 — Draft ROADMAP.md

Write `.vbw-planning/ROADMAP.md` with this structure:

```markdown
# Roadmap

**Project:** {project name}
**Created:** {date}
**Source:** project-definition.md, Strategy/ docs

## Phase 1: {Phase Name} (MVP)

**Goal:** {from project definition}
**Exit Criteria:** {from project definition}

### {Feature Cluster 1}
- REQ-001: {requirement} — ref: {Strategy doc §section}
- REQ-002: {requirement} — ref: {Strategy doc §section}

### {Feature Cluster 2}
- REQ-003: {requirement} — ref: {Strategy doc §section}
- REQ-004: {requirement} — ref: {Strategy doc §section}

### Dependencies
- REQ-003 blocked by REQ-001 (needs data model before CRUD)

## Phase 2: {Phase Name}

**Goal:** {from project definition}
**Exit Criteria:** {from project definition}

### {Feature Cluster 3}
- REQ-010: {requirement} — ref: {Strategy doc §section}

## Future (Parking Lot)
- REQ-100: {deferred item} — target: Phase 3+
```

Present the draft roadmap to the user: _"Here's the requirements breakdown. Review the groupings, dependencies, and phasing?"_

Iterate until approved.

### Phase 3 — Linear Setup

Determine what can be automated vs. what needs manual setup.

**Automate via MCP (do these):**

1. **Create Issues** — for each requirement, via `mcp__linear-server__save_issue`:
   - `team`: from `method.config.md`
   - `title`: requirement title
   - `description`: requirement detail + strategy doc reference
   - `state`: Phase 1 → "On Deck" | Phase 2+ → "Future Waves" | Parking lot → "Ideas"
   - `priority`: 0 (None) — triage sets real priority

2. **Set Dependency Relations** — for each dependency in the roadmap:
   - Use `mcp__linear-server__save_issue` to set `blocked_by` relations

3. **Apply Labels** — for each issue:
   - Type label (Feature, Improvement, Research, etc.)
   - Domain label (project-specific, based on feature cluster)

4. **Create Milestones (Work Packages)** — for each feature cluster that has >3 issues:
   - Group issues into work packages of 3-8 issues
   - Assign issues to their milestone

**Instruct manually (tell the user to do these):**

Some Linear operations may not be available via MCP. For each, give explicit instructions:

```
## Manual Linear Setup Required

The following must be done in the Linear UI:

1. **Create Initiatives** (Settings → Initiatives):
   - "{Phase 1 Name}" — maps to Phase 1
   - "{Phase 2 Name}" — maps to Phase 2

2. **Create Projects** (within each Initiative):
   Phase 1:
     - "{Feature Cluster 1}" — contains: {issue list}
     - "{Feature Cluster 2}" — contains: {issue list}
   Phase 2:
     - "{Feature Cluster 3}" — contains: {issue list}

3. **Verify Workflow States** match method.config.md:
   - If states are not yet configured, follow sop/Linear_SOP.md

After completing manual setup, run `/roadmap-create --verify` to check everything.
```

### Phase 4 — Write linear-map.json

Create `.vbw-planning/linear-map.json` mapping roadmap IDs to Linear IDs:

```json
{
  "phases": {
    "phase-1": {
      "name": "Phase 1: MVP",
      "initiative_id": null,
      "clusters": {
        "data-foundation": {
          "project_id": null,
          "issues": {
            "REQ-001": { "linear_id": "XXX-1", "title": "..." },
            "REQ-002": { "linear_id": "XXX-2", "title": "..." }
          }
        }
      }
    }
  }
}
```

Fields with `null` are populated after manual Linear setup or on subsequent runs.

### Phase 5 — Verify (also available as `--verify`)

Run a completeness check:

1. Every roadmap requirement has a Linear issue
2. Every Linear issue has the correct state for its phase
3. Dependency relations are set in Linear
4. Labels are applied
5. Milestones are assigned
6. `linear-map.json` has no null IDs (if manual setup is done)

Report:

```
## Roadmap Verification

Requirements: {N} total
Linear issues created: {N}
Dependencies set: {N}
Milestones created: {N}

Gaps:
  - {N} Initiative IDs missing (manual setup needed)
  - {N} Project assignments missing (manual setup needed)

Run /roadmap-review for a full health check.
```

### Phase 6 — Summary

```
## Roadmap Created

File: .vbw-planning/ROADMAP.md
Issues created: {N} across {M} feature clusters

Phase 1: {N} requirements → {M} issues (On Deck)
Phase 2: {N} requirements → {M} issues (Future Waves)
Parking lot: {N} items (Ideas)

Dependencies: {N} relations set
Milestones: {N} work packages created

Manual setup needed: {list of manual steps}

Next steps:
  - Complete manual Linear setup (see instructions above)
  - /wave-plan — select the first execution wave
  - /roadmap-review — validate everything before speccing
```

## Arguments

| Argument | What it does |
|----------|--------------|
| (none) | Full roadmap creation flow |
| `--verify` | Run verification only (Phase 5) — useful after manual Linear setup |
| `--dry-run` | Draft the roadmap without creating Linear issues |

## Rules

- **Requirements, not tasks.** Each roadmap item is a feature or capability (WHAT), not an implementation step (HOW). Implementation decomposition happens in `/light-spec` and VBW planning.
- **Trace everything.** Every requirement references a strategy doc section. Untraced requirements are orphans — they need a strategy doc home or they shouldn't be in the roadmap.
- **Automate what you can.** Create issues, set relations, apply labels via MCP. Give clear manual instructions for the rest.
- **Human approves the roadmap before Linear population.** Don't create issues until the roadmap structure is approved.
- **Phase 1 issues go to On Deck.** Not "Needs Spec" — that happens when `/wave-plan` selects them for the first wave.

## Red Flags

If you catch yourself thinking any of these, follow the process more strictly:

- **"This requirement is too vague to be an issue"** → Then it's too vague for the roadmap. Push it back to strategy docs or split it into concrete deliverables.
- **"I'll create the issues and sort out dependencies later"** → Dependencies set after the fact are always wrong. Map them during roadmap creation.
- **"This doesn't trace to a strategy doc section"** → Then either the strategy docs are incomplete or the requirement is an orphan. Fix the source, don't create untraceable work.
- **"I'll skip the Linear hierarchy, just create issues"** → Issues without Initiatives/Projects/Milestones become an unsortable mess within a week.

## Related

- `/define` — previous step: creates the project definition
- `/strategy-create` — creates the strategy docs this skill reads
- `/vbw:init` — scaffolds `.vbw-planning/` (run before this skill)
- `/wave-plan` — next step: select issues for the first execution wave
- `/roadmap-review` — validates the roadmap after creation
- This skill IS the Linear seeding step (no separate seed skill needed)
