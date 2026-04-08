---
name: roadmap-review
description: Validate roadmap health — issue completeness, dependency ordering, spec coverage, and doc freshness
---

# Roadmap Review Skill

Comprehensive health check of the overall plan. Run before speccing a new wave to ensure the roadmap is coherent and complete.

## Triggers

- `/roadmap-review`
- "review the roadmap"
- "check the plan"
- "roadmap health"

## Purpose

Validate that:
1. **Phase 0 outputs exist** — concept, definition, strategy docs, roadmap, wave
2. Every ROADMAP requirement has corresponding Linear issues
3. Issues are in the correct phase/project
4. Dependencies and blockers are set correctly
5. Workflow states are consistent with dependency ordering
6. Spec coverage is adequate for the next planned wave
7. Strategy docs are flagged if stale

This is the **gate between Phase 0 (Foundation) and Phase 1 (Definition)** in the Piper Method pipeline. Run it before starting a new wave of specs.

## Execution Steps

### Phase 0 — Foundation Check

Validate that pre-pipeline outputs exist. If any are missing, report which skill to run.

| Check | File | If Missing |
|-------|------|-----------|
| Concept brief | `concept-brief.md` | Run `/concept` |
| Project definition | `project-definition.md` | Run `/define` |
| Strategy docs | `Strategy/` matching `method.config.md` manifest | Run `/strategy-create` |
| VBW scaffold | `.vbw-planning/` directory | Run `/vbw:init` |
| Roadmap | `.vbw-planning/ROADMAP.md` with content | Run `/roadmap-create` |
| Linear board | Issues exist for roadmap requirements | Run `/roadmap-create` |
| Wave defined | `.vbw-planning/WAVES.md` with current wave | Run `/wave-plan` |

If any Phase 0 check fails, report it prominently at the top of the health report:

```
## Phase 0: Foundation — INCOMPLETE

Missing:
  - concept-brief.md → run /concept
  - .vbw-planning/WAVES.md → run /wave-plan

Phase 0 must be complete before entering the spec pipeline.
```

If all Phase 0 checks pass, continue to Phase 1.

### Phase 1 — Gather State

1. Read `.vbw-planning/ROADMAP.md` for requirements by phase
2. Read `.vbw-planning/linear-map.json` for ID mappings
3. Read `.vbw-planning/STATE.md` for current progress
4. Read `.vbw-planning/WAVES.md` for current wave composition
5. Fetch all initiatives via `mcp__linear-server__list_initiatives`
6. For each active and next-up initiative, fetch projects via `mcp__linear-server__list_projects`
7. For each project, fetch issues via `mcp__linear-server__list_issues`

### Phase 2 — Completeness Check

For each phase in ROADMAP.md:

1. Extract the requirements list from the phase section
2. Match each requirement to Linear issues by:
   - Title keyword matching
   - Project assignment (requirement area → project cluster)
   - Description cross-references
3. **Gaps:** Requirements with NO matching issue → these need issues created
4. **Orphans:** Issues with NO matching requirement → flag for review (may be valid additions from brainstorming, or may be misassigned)

Output: Completeness table per phase.

### Phase 3 — Assignment Validation

For each issue in the active and upcoming phases:

1. Verify it belongs to the correct initiative (phase)
2. Verify it belongs to a project within that initiative
3. Verify it has a milestone (work package) if applicable
4. Verify labels are consistent (Tier label matches Initiative, Domain label matches Project)
5. Flag misassignments

### Phase 4 — Dependency Validation

1. Read light specs for issues that have them — extract dependency contracts (e.g., "WIT-8 is a hard blocker for WIT-7")
2. Read the WP dependency graph from `method/sop/Linear SOP.md` (Dependency Graph section)
3. For each declared dependency:
   - Fetch the issue via `mcp__linear-server__get_issue` with `includeRelations: true`
   - Check that `blockedBy`/`blocks` relations exist in Linear
4. Flag missing dependency links with the exact relation to add
5. Flag circular dependencies

### Phase 5 — Ordering Validation

For each issue that has blockers:

1. Fetch blocker issue status
2. Apply ordering rules:
   - If blocker is in Ideas/Future Waves/On Deck/Needs Spec → blocked issue should NOT be in Approved/Building/In Progress
   - If blocker is in Done → the blocked issue is free to progress
   - If blocker is in Canceled → flag for review (is the dependency still relevant?)
3. Flag ordering violations with recommended state changes

### Phase 6 — Spec Coverage

For the next planned wave (issues in On Deck/Needs Spec/Specced for the active phase):

1. List all issues that would enter the pipeline
2. For each issue, check spec status:
   - **No spec:** description is bare or uses old template format
   - **Has light spec:** description contains `## Light Spec` header
   - **Agent reviewed:** description contains `## Agent Review` with a verdict
   - **Agent passed:** Agent Review verdict is "Pass"
   - **Human approved:** issue is in Approved (past Specced)
3. Calculate readiness:
   - Total issues in wave
   - Issues with specs
   - Issues with passing agent review
   - Issues ready for planning (specced + approved)
4. List issues needing specs before the wave can start

### Phase 7 — Doc Freshness (Light Check)

1. Read `method.config.md` to get the strategy doc manifest
2. Read version headers from all listed strategy docs to find the oldest update date
3. Query Linear for issues in Done state
4. Count features shipped since the oldest Strategy doc was last updated
5. If significant features shipped (>3) without a doc update, flag as stale
6. List which docs are most affected by shipped features
7. Recommend `/strategy-sync` if stale

### Phase 8 — Report

Present a summary dashboard:

```markdown
## Roadmap Health — YYYY-MM-DD

### Completeness
| Phase | Requirements | Issues | Gaps | Orphans |
|-------|-------------|--------|------|---------|
| 01    | 3           | 3      | 0    | 0       |
| 02    | 18          | 81     | 2    | 5       |
| 03    | 22          | 0      | 22   | 0       |
| ...   |             |        |      |         |

**Gaps (requirements without issues):**
- Phase 02: "Persistent AI Memory (mem0)" — no matching issue
- Phase 02: "Piper Slash Command Palette" — no matching issue

**Orphans (issues without matching requirements):**
- WIT-176: "Entities blocked from 2 budgets with same name" — bug, not in ROADMAP

### Assignment
- X issues verified in correct phase/project
- Y misassignments found (list with corrections)

### Dependencies
- X dependency relations verified
- Y missing relations (list with exact `blockedBy` to add)
- Z ordering violations (list with recommended state changes)

### Spec Coverage (next wave: [wave name])
| Status | Count | % |
|--------|-------|---|
| No spec | X | X% |
| Has spec | X | X% |
| Agent passed | X | X% |
| Planning-ready | X | X% |

**Issues needing specs:**
- WIT-XXX: [title]
- WIT-XXX: [title]

### Parked Items (trigger check)

Parked items are brainstorm dispositions marked "Later" with trigger conditions. Check if any triggers have fired:

| Issue | Trigger Condition | Target | Triggered? |
|-------|------------------|--------|-----------|
| {issue} | "revisit when {X} ships" | Wave {N} | ✓ {X} is Done |
| {issue} | "revisit after Phase 1 UAT" | Phase 2 | ✗ Phase 1 in progress |

**Triggered items need re-disposition** — run `/brainstorm-review` on them or add to the current wave via `/wave-plan --rebalance`.

To find parked items: fetch issues with `Parked` label, read the trigger condition from their Linear comments.

### Strategy Doc Freshness
| Doc | Version | Last Updated | Features Since |
|-----|---------|-------------|----------------|
| {doc name from config} | vX.X.X | YYYY-MM-DD | X |
| {doc name from config} | vX.X.X | YYYY-MM-DD | X |
| ... | | | |
- **Recommendation:** Run `/strategy-sync` if any doc has >3 unsynced features

### Action Items (Priority Order)
1. [Most critical action]
2. [Next action]
...
```

Ask the user: _"Want me to fix any of these issues now? I can create missing issues, set dependency links, or flag items for spec generation."_

## Cadence

Run at these moments:
- **Before speccing a new wave** — ensures the plan is sound before you invest in specs
- **At the start of a new phase** — validates phase setup is complete
- **Monthly** — routine health check
- **After major scope changes** — re-validate after adding/removing features

## Related

- See `method.md` — the overall pipeline this validates
- See `sop/Linear_SOP.md` — dependency graph and workflow states
- `/strategy-sync` — runs after shipping to update Strategy docs (this skill flags staleness)
- `/light-spec` — generates specs for issues flagged as needing them
