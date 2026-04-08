# Piper Method — Planned Improvements

Improvements identified from reviewing [kmigdol/claude-config](https://github.com/kmigdol/claude-config), [theDakshJaitly/mex](https://github.com/theDakshJaitly/mex), and gaps in the current pipeline.

**Related issue:** [WIT-162](https://linear.app/withpiper/issue/WIT-162) — CLAUDE.md Audit, Restructure & Rules Extraction (shipped 2026-04-06). Delivered #5 and created the rules/ infrastructure that #2, #3, and #6 plug into.

---

## 1. Red Flags in Skills

**Source:** kmigdol pattern — every skill ends with self-sabotage statements Claude should recognize as danger signals.

**What:** Add a `## Red Flags` section to key skills. When Claude catches itself thinking these thoughts, it should follow the workflow *more* strictly, not less.

**Example flags:**
- "This is simple, I don't need a plan" → You definitely need a plan
- "I'll write tests after" → Write them first or at minimum concurrently
- "I know this API" → Check the installed version first

**Target skills:** `/launch`, `/light-spec`, `/brainstorm`, `/migrate`, `/g-promote-*`

---

## 2. Verify Library API

**Source:** kmigdol `verify-library-api` skill.

**What:** Before using any library API, check the *installed version* and read `node_modules` source as ground truth. Not docs, not training data.

**Why:** Next.js 15, AG Grid, shadcn, Supabase SDK — all fast-moving. Claude's training data is reliably wrong on recent API changes.

**Implementation:** Either a standalone skill or a global CLAUDE.md rule. Lean toward global rule since it applies everywhere. **WIT-162 creates the rules/ infrastructure** where this rule would live (likely `rules/tooling.md` or `rules/patterns.md`).

---

## 3. Ad-hoc Plan Gate

**Source:** kmigdol mandatory pre-implementation plan.

**What:** For non-VBW interactive work, require a 3-5 bullet plan with user approval before writing code. Covers: what changes, what doesn't change, tools/patterns, key design decisions.

**Why:** VBW handles planned work well, but quick fixes and exploratory changes in interactive sessions have no lightweight gate. This fills the gap without the overhead of a full PLAN.md.

**Implementation:** Add to CLAUDE.md's Decision-Making Protocol section (created by WIT-162) or as a global rule in `rules/tooling.md`.

---

## 4. Brainstorm Disposition System (EXPAND/HOLD/REDUCE)

**Source:** kmigdol EXPAND/HOLD/REDUCE framework, adapted for Piper's brainstorm backlog problem.

**Problem:** `/brainstorm` creates well-analyzed Linear issues that then sit in "Ideas" with no structured next step. They accumulate, create noise, and get forgotten. Example: WIT-349 (Gmail Agent) — thorough analysis, clear dependencies, but no disposition.

**What:** Evolve `/brainstorm-review` into a three-phase disposition workflow:

1. **EXPAND** — already handled by `/brainstorm` (full vision, options, adjacencies)
2. **HOLD** — force a disposition decision:
   - **Now** → route to pipeline (assign wave/phase, status → Needs Spec)
   - **Later** → park with explicit **trigger condition** + target wave
   - **Kill** → archive with rationale
3. **REDUCE** — for "Now" items, cut to v1 scope before entering spec pipeline

**Parking rules for "Later" items:**
- Must have a trigger condition (e.g., "revisit when WIT-56 ships")
- Must have a target wave/phase (e.g., "Wave 4+")
- Tagged with `Parked` label in Linear
- Surfaced during `/roadmap-review` when trigger conditions are met

**Integration points:**
- `/brainstorm` → immediate disposition prompt after issue creation
- `/brainstorm-review` → batch disposition for untriaged backlog
- `/roadmap-review` → surface parked items whose triggers have fired

---

## 5. CLAUDE.md Thinning via Routing Architecture

**Source:** mex (theDakshJaitly/mex) — demand-loaded context routing pattern.

**Problem:** CLAUDE.md is 363 lines loaded every session. WIT-162 was originally going to grow it to 400-500 lines by adding app architecture sections. That's the monolith pattern mex was built to solve.

**What:** Restructure into three tiers:
1. **CLAUDE.md (~200 lines)** — project hub + routing pointers. "What is this project and where do I find everything?"
2. **`.claude/rules/` (auto-loaded)** — enforceable constraints + app patterns. "How do I build correctly?" Loaded every session by Claude Code.
3. **`method/sop/` (demand-loaded)** — deep reference. SQL templates, extended examples, walkthroughs. Loaded via routing pointers when relevant.

CLAUDE.md shrinks, total knowledge increases, per-session token load decreases.

**Status:** Done — shipped via WIT-162 on 2026-04-06. Deployed to production.

**What shipped:**
- CLAUDE.md thinned from 363 → 183 lines (50% reduction, two UAT review rounds)
- 6 `.claude/rules/` files (481 lines auto-loaded): security, naming, patterns, file-structure, tooling, hooks-realtime
- Routing pointers table in CLAUDE.md (6 auto-loaded rules + 5 on-demand SOPs)
- Decision-Making Protocol encoding 8 feedback memories
- `<important>` tags on all 6 Phase 2 bug-informed invariants
- Mandatory financial calculation testing rules
- Three-tier Source of Truth hierarchy (hub → rules → SOPs)
- All 50+ factual claims audited against codebase, zero corrections needed

---

## 6. Automated Drift Detection

**Source:** mex CLI drift checkers — 8 validators that catch stale docs without burning tokens.

**Problem:** CLAUDE.md and rules/ reference file paths, commands, dependencies, and stack versions that change over time. Currently drift is caught manually during audits (if at all). WIT-162's restructure makes this worse — more files to maintain across CLAUDE.md + 6-7 rules/ files + method/sop/.

**What:** A lightweight automated check (post-commit hook or CI) that validates:
- File paths referenced in CLAUDE.md and rules/ still exist on disk
- Commands listed in common commands section still work (scripts exist in package.json)
- Dependencies claimed are present in manifests
- Files not updated in 50+ commits are flagged as potentially stale

**Implementation:** Start simple — a shell script or Node script run as a post-commit hook. Doesn't need mex's full AST parsing. Even checking inline code paths against the filesystem catches 80% of drift.

**Dependency:** Ships after WIT-162 (which creates the rules/ files that need drift protection). Could become a Linear issue in WP-1: Foundation Fixes alongside WIT-162.

---

## Execution Sequencing

WIT-162 shipped (2026-04-06). The remaining items have no blockers:

```
✅ WIT-162 (CLAUDE.md restructure + rules/) — DONE
  ├── Unblocked #2 (Verify Library API → add rule to rules/tooling.md)
  ├── Unblocked #3 (Ad-hoc Plan Gate → add rule to Decision-Making Protocol)
  └── Unblocked #6 (Drift Detection → validates the new file topology)

All remaining items are independent — can be done in any order:
  ├── #1 (Red Flags in Skills → skill file edits)
  ├── #2 (Verify Library API → one rule addition)
  ├── #3 (Ad-hoc Plan Gate → one rule addition)
  ├── #4 (Brainstorm Disposition → skill + Linear workflow changes)
  └── #6 (Drift Detection → new script/hook)
```

**Recommended next session:**
- **#2 + #3** are quick wins (~5 min each, just adding rules to existing files)
- **#1 + #4** are medium effort (skill file edits, workflow design)
- **#6** is the largest remaining item (new script, hook wiring)

---

## Status

| # | Improvement | Status | Dependency |
|---|------------|--------|------------|
| 1 | Red Flags in Skills | **Done** — added to concept, define, strategy-create, roadmap-create, wave-plan, launch, light-spec, brainstorm | None |
| 2 | Verify Library API | **Done** — rule template at `templates/rules/verify-library-api.md` | WIT-162 ✓ |
| 3 | Ad-hoc Plan Gate | **Done** — rule template at `templates/rules/ad-hoc-plan-gate.md` | WIT-162 ✓ |
| 4 | Brainstorm Disposition | **Done** — EXPAND/HOLD/REDUCE integrated into `/brainstorm` and `/brainstorm-review`, parked items surfaced by `/roadmap-review` | None |
| 5 | CLAUDE.md Thinning | **Done** (WIT-162 shipped 2026-04-06) | — |
| 6 | Automated Drift Detection | **Done** — `scripts/drift-check.sh` checks file paths, skill cross-refs, doc staleness, script refs, config completeness | WIT-162 ✓ |
