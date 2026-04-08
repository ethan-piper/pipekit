---
name: strategy-sync
description: Update Strategy docs (Doc1-6) to reflect shipped features — close the documentation loop
---

# Strategy Sync Skill

Updates Strategy docs to reflect what was actually built. Closes the documentation loop so that anyone reading Doc1-6 understands the app as it exists today — not just as it was originally envisioned.

## Triggers

- `/strategy-sync`
- "sync strategy docs"
- "update strategy docs"

## Purpose

Strategy docs (Doc1-5) are the human-readable explanation of the product. They serve two audiences:

1. **Stakeholders** (Doc1, Doc3) — understand what the app does in simple terms
2. **Developers** (Doc2, Doc5) — understand the technical model and permissions

After features ship, these docs must be updated to reflect reality. Without this, the docs drift and become unreliable — a new reader gets a picture that doesn't match the actual app.

## The Documentation Loop

```
Strategy Docs (vision) → Light Specs → Plans → Code → Strategy Docs (reality)
                  ↑                                              |
                  └──────────── /strategy-sync ─────────────────┘
```

This skill closes the right side of that loop.

## Document Map

| Doc | Purpose | Audience | Key Content |
|-----|---------|----------|-------------|
| Doc1 | Conceptual Overview | CFO, Stakeholders | How the app works in simple terms |
| Doc2 | Technical Spec | Developers | Schema, APIs, data model, calculations |
| Doc3 | Workflow Examples | All | Step-by-step scenarios showing how features work |
| Doc4 | Changelog | All | Version history (updated by `/end-session`, not this skill) |
| Doc5 | Permissions | Developers, Admins | RLS, roles, access control model |
| Doc6 | UX Reference | Producers, Support | Keyboard shortcuts, onboarding, help system, UI patterns |

**Doc4 content is excluded** from this skill — it's maintained by `/end-session` as a running log. However, this skill updates Doc4's header/formatting for cross-doc consistency (e.g., "Document 4 of 6") and adds a single changelog entry recording what was synced.

## Execution Steps

### Phase 1 — Identify Shipped Work

1. Read `Strategy/Doc1_ConceptualOverview.md` version header to get the last update date
2. Read `.vbw-planning/STATE.md` for recently completed phases/waves
3. Query Linear for issues in Done state since the last Strategy doc update date:
   - Use `mcp__linear-server__list_issues` filtered by state = Done
   - Filter to issues completed after the last doc update
4. For each Done issue: check if it has a light spec (look for `## Light Spec` in description)
5. Group shipped features by complexity:
   - **Has light spec:** Full spec available — primary source for doc updates
   - **No spec (bug/fix):** Check if it changed user-visible behavior
   - **Internal only:** Skip (no doc impact)

### Phase 2 — Map to Strategy Sections

For each shipped feature with doc impact:

1. Read the light spec's Technical Context section for § references (e.g., "Doc1 §3.4")
2. If no explicit reference, match by keyword:
   - Feature touches budgets → Doc1 §3 (Budget Management), Doc2 §5 (Budget Schema)
   - Feature touches auth → Doc1 §6 (User Management), Doc5 (Permissions)
   - Feature touches AI → Doc1 §4 (AI Features), Doc2 §7 (AI Architecture)
   - Feature touches vendors → Doc1 §5 (Vendor Management), Doc2 §6 (Vendor Schema)
   - Feature touches UX/help/shortcuts → Doc6 (UX Reference)
3. Build a mapping table:

```
| Feature (WIT-#) | Doc1 Sections | Doc2 Sections | Doc3 Impact | Doc5 Impact | Doc6 Impact |
|-----------------|---------------|---------------|-------------|-------------|-------------|
| WIT-7 Rate Cards | §3.4 | §5.x (new) | New workflow | New RLS | — |
| WIT-8 Block Types | §3.3 | §5.x (new) | — | — | — |
```

### Phase 3 — Compare and Draft

For each affected section, use an Explore agent to:

1. **Read the current Strategy doc text** for that section
2. **Read the shipped light spec** for the feature
3. **Read the actual implementation** (key schema, API routes, components) to catch any spec-to-code drift
4. **Draft an updated section** that:
   - Reflects what was ACTUALLY built (code is truth, not the spec)
   - Maintains the doc's tone and audience level:
     - Doc1: Simple, conceptual, no code. A CFO should understand it.
     - Doc2: Technical, schema-level detail, code patterns.
     - Doc3: Step-by-step scenarios with concrete examples.
     - Doc5: Permission model, RLS policies, role definitions.
     - Doc6: UX-facing, practical. A producer or support agent should understand it.
   - Preserves descriptions of future-phase features that weren't built yet
   - Clearly distinguishes "what exists today" from "what's planned"

### Phase 4 — New Sections

For features that are entirely new (no existing Strategy doc section):

1. Determine the appropriate location in the doc structure
2. Draft a new section following the existing numbering convention
3. Add cross-references to related sections
4. For Doc3: draft a new workflow example if the feature has a distinct user flow

### Phase 5 — Present Diffs

Show each proposed change as a before/after comparison:

```markdown
## Doc1 § 3.4 — Rate Cards

**Current (v2.6.1, Feb 2026):**
> Rate cards provide standard pricing templates at the entity level.
> A producer selects a rate card when creating a budget, and standard
> rates pre-populate for common line items.

**Proposed (reflects WIT-7 + WIT-8 implementation):**
> Rate cards provide standard pricing at Entity, Client, or Project
> scope with optional lineage inheritance (Entity → Client → Project).
> Each subsection in a budget can have one rate card assigned, matched
> by block type. Producers select entries from the rate card to
> pre-populate line item rates, markup, units, and multipliers.
> A dedicated Rate Card Management system allows creating and
> organizing cards across scopes.

**What changed:** Cascade model with optional lineage replaced
simple entity-level cards. Subsection-level assignment (not
budget-level). Dedicated management UI. See WIT-7 light spec.
```

For each diff, ask: _"Approve this update? [yes / edit / skip]"_

### Phase 6 — Apply and Version

1. Apply all approved updates to Strategy docs
2. Bump the doc version using semver logic:
   - New features added → minor bump (e.g., v2.6.1 → v2.7.0)
   - Corrections/clarifications only → patch bump (e.g., v2.6.1 → v2.6.2)
3. Update the version header and date in each modified doc
4. Add a Doc4 changelog entry summarizing all Strategy doc updates

### Phase 7 — Cross-Sync

After updating primary docs, check consistency across all docs:

1. **Terminology:** Do Doc1 and Doc2 use the same terms for the same concepts?
2. **Workflow examples:** Do Doc3 scenarios still match the updated Doc1 concepts?
3. **Permissions:** Does Doc5 reflect any new tables, RLS policies, or role changes from shipped features?
4. **UX consistency:** Do Doc6 keyboard shortcuts, tour steps, and UI patterns match what Doc1 describes conceptually and Doc3 shows in workflows?
5. **Cross-references:** Are all § references between docs still valid? Do all docs reference "Document X of 6"?
6. Flag inconsistencies for manual review — do NOT auto-fix cross-doc issues without approval

### Phase 8 — Summary

```markdown
## Strategy Sync Complete — YYYY-MM-DD

### Updates Applied
| Doc | Sections Updated | New Sections | Version |
|-----|-----------------|--------------|---------|
| Doc1 | §3.4, §4.2 | §3.8 | v2.7.0 |
| Doc2 | §5.1 | §5.9 | v2.7.0 |
| Doc3 | — | Workflow 12 | v2.7.0 |
| Doc5 | §2.3 | — | v2.7.0 |
| Doc6 | §2.1 | — | v1.1.0 |

### Features Synced
- WIT-7: Rate Cards → Doc1 §3.4, Doc2 §5.x
- WIT-8: Block Types → Doc1 §3.3, Doc2 §5.x

### Skipped (no Strategy doc impact)
- WIT-261: Foundation fix (internal only)

### Cross-Sync
- 0 terminology mismatches
- 1 Doc3 workflow needs update (flagged)

### Doc Freshness
Strategy docs now reflect all shipped features through YYYY-MM-DD.
Next sync recommended after: [next wave ships]
```

## Cadence

Run at these moments:
- **After UAT passes** for a wave or phase — the primary trigger
- **Before stakeholder presentations** — ensure docs are current
- **Before onboarding a new team member** — they'll read these docs first
- **When `/roadmap-review` flags doc staleness**

## Rules

- **Code is truth.** If the code differs from the light spec, the Strategy doc should match the code — not the spec.
- **Preserve future-phase content.** Don't remove descriptions of features that haven't been built yet. Mark them clearly as planned.
- **Maintain audience level.** Doc1 stays simple even when the feature is complex. Save technical detail for Doc2.
- **Never auto-apply.** Always present diffs for human approval before writing.
- **Version discipline.** Every sync bumps the version. No silent edits.

## Related

- [The Piper Method](../../../method/Piper_Method.md) — this skill is the post-pipeline documentation step
- `/roadmap-review` — flags doc staleness; run this skill to resolve it
- `/end-session` — maintains Doc4 (Changelog); this skill handles Doc1, 2, 3, 5, 6
- `/light-spec` — the specs that feed into this skill's comparison logic
