# Piper Backport Plan — 2026-04-23

Scope: what to pull from this session's Pipekit work into piper. Piper has diverged substantially (app-specific agents, app-specific rules, older `/launch` and `/brainstorm`), so backport is not a wholesale rsync — it's surgical.

## Piper current state

**Already has** (don't clobber):
- 9 app-specific agents: `budget-logic`, `code-reviewer`, `code-simplifier`, `comment-analyzer`, `pr-test-analyzer`, `silent-failure-hunter`, `supabase-reviewer`, `type-design-analyzer`, `plan-reviewer` (piper's own 58-line version)
- 7 app-specific rules: `ag-grid-pitfalls`, `file-structure`, `hooks-realtime`, `naming`, `patterns`, `security`, `tooling` — all piper-tuned content
- Simpler `/brainstorm` without EXPAND/HOLD/REDUCE Phase 2
- Older `/end-session` without shutdown preflight
- `/launch` from before Tier 3 refactor

**Doesn't have**:
- 9 Stage 0 / admin skills (`concept`, `define`, `strategy-create`, `startup`, `roadmap-create`, `phase-plan`, `pipekit-update`, `02-light-spec-revise`, `launch-native`)
- `scripts/pipekit-post-archive.sh`
- Canonical `discipline.md` rule
- Drift-check hook installer

## Backport categories

### A — Port wholesale (no conflict)

Safe to install as-is. These are net-new in piper.

| # | Item | Source | Dest in piper | Notes |
|---|------|--------|---------------|-------|
| A1 | `scripts/pipekit-post-archive.sh` | `scripts/` | `scripts/` | Plus register in `.vbw-planning/config.json` → `hooks.post_archive` |
| A2 | `templates/rules/discipline.md` → consumer rules | `templates/rules/discipline.md` | `.claude/rules/discipline.md` | Adds Red Flags + Ad-hoc Plan Gate + scope hygiene; no overlap with piper's existing rules |
| A3 | `pipekit-update` skill | `skills/pipekit-update/` | `.claude/skills/pipekit-update/` | Piper currently has no pipekit-sync automation |
| A4 | Drift-check hook installer | `scripts/drift-check.sh` changes | `scripts/drift-check.sh` | Append `--install-hook` / `--uninstall-hook` / `--quick` flags to piper's existing drift-check |

### B — Upgrade existing files (careful merge)

Piper has these but they're older than pipekit's current version. Port with review.

| # | Item | Piper has | Pipekit has | Recommendation |
|---|------|-----------|-------------|----------------|
| B1 | `/end-session` Step 0 preflight | Skips straight to Step 1 | Holistic shutdown (branch switch, worktree prune, NEXT.md refresh) | **Port** — piper's `/end-session` is where session artifacts orphan today. High value. |
| B2 | `/brainstorm` Phase 2 HOLD + trigger grammar | Phase 1 only, no disposition | Full EXPAND/HOLD/REDUCE with parseable grammar | **Port** — piper hit exactly this backlog-rot problem (the WIT-349 example in METHOD_IMPROVEMENTS.md #4) |
| B3 | `/brainstorm-review` trigger grammar | Older version | Unified grammar with `/roadmap-review` | **Port** if piper has `/brainstorm-review` (verify) |
| B4 | `plan-reviewer` agent | 58 lines, color-coded, simpler | 242 lines, structured Input Contract, Review Protocol, Severity Classification, parseable output | **Port** — piper's version won't produce structured output the `/launch` refactor expects. Back up piper's as `plan-reviewer-legacy.md` if keeping the simpler one as fallback. |
| B5 | `/launch` Tier 3 refactor | Orchestrates vbw-dev/vbw-qa directly | Delegates to `/vbw:vibe --execute` and `--verify` | **Port** — piper already hit the contract-drift problem from VBW v1.35. Highest value of the bunch. |
| B6 | Red Flags sections in `/launch`, `/light-spec`, `/brainstorm` | Absent | Five skill-specific flags each | **Port with adaptation** — piper uses `/speckit` not `/light-spec`; port the `/light-spec` Red Flags into `/speckit` if piper maintains that skill |

### C — Piper's content wins (port carefully)

Piper has app-specific content that beats pipekit's portable baseline. Don't clobber.

| # | Item | Decision |
|---|------|----------|
| C1 | `templates/rules/tooling.md` → `.claude/rules/tooling.md` | **Skip.** Piper's `tooling.md` is richer (monorepo filters, concrete turbo commands). Instead, port *specific sections* piper lacks: "Verify Library API" sequence, "never-assume" list. Add as a new section at the bottom of piper's existing `tooling.md`. |
| C2 | `templates/rules/security.md` → `.claude/rules/security.md` | **Skip.** Piper's `security.md` has domain-specific invariants (User ID invariant, RLS-for-finance). Port only: OWASP Top 10 checklist as a new section. |

### D — Don't port

| # | Item | Why not |
|---|------|---------|
| D1 | `concept`, `define`, `strategy-create`, `startup` | Piper is past Stage 0. These skills scaffold new projects from an idea; piper has a working project. |
| D2 | `roadmap-create`, `phase-plan` | Piper's roadmap + phases exist; no need for scaffolding skills. Phase-plan specifically could still be useful for tracking, but low priority. |
| D3 | `launch-native` | Spike skill that skips VBW; piper's `/launch` refactor supersedes the use case. |
| D4 | `02-light-spec-revise` | Piper uses `/speckit`, not `/light-spec`. Skill doesn't map cleanly. |
| D5 | `templates/CLAUDE.md.template` | Piper's CLAUDE.md is bespoke and well-tuned. Template would be a downgrade. |

### E — Bilateral gaps (neither has — future Pipekit work)

From `METHOD_IMPROVEMENTS.md` — piper identified these but never shipped:

| # | Item | Status |
|---|------|--------|
| E1 | Brainstorm Disposition (EXPAND/HOLD/REDUCE) | ✅ Shipped in pipekit Tier 2.2 (port via B2) |
| E2 | Ad-hoc Plan Gate | ✅ Shipped in pipekit Tier 1 `discipline.md` (port via A2) |
| E3 | Verify Library API | ✅ Shipped in pipekit Tier 1 `tooling.md` (port via C1 merge) |
| E4 | Red Flags in Skills | ✅ Shipped in pipekit Tier 2.1 (port via B6) |
| E5 | Automated Drift Detection | ✅ Partially shipped — pipekit has drift-check + hook installer (port via A4) |
| E6 | CLAUDE.md Thinning via Routing Architecture | ✅ Piper already shipped this (WIT-162 2026-04-06); no backport needed |

**Five of six METHOD_IMPROVEMENTS items now addressable via this backport.** Item E6 already done in piper.

## Execution Plan

### Priority 1 — High-value, low-risk

1. **A1 — post-archive hook** — 5 min. Install script + register in config.
2. **A2 — discipline.md rule** — 5 min. Copy to `.claude/rules/`.
3. **B1 — `/end-session` preflight** — 15 min. Replace Step 0; preserve piper's Steps 1-10 customizations.
4. **B4 — plan-reviewer agent** — 10 min. Back up piper's, install pipekit's.

### Priority 2 — High-value, medium-risk (requires piper-side adaptation)

5. **B5 — `/launch` Tier 3 refactor** — 30 min. Delete Steps 8-9 orchestration; add handoff text. Preserve piper's Linear IDs, branch/promote skill refs.
6. **B2 — `/brainstorm` Phase 2 HOLD + grammar** — 20 min. Port Phase 2 and update MCP calls to piper's current tool names (piper uses `mcp__linear__linear_create_issue`, pipekit uses `mcp__linear-server__save_issue`).
7. **C1, C2 — Selective rule merges** — 15 min. Append Verify Library API to piper's `tooling.md`; append OWASP checklist to piper's `security.md`.

### Priority 3 — Low-value or low-urgency

8. **A3 — `pipekit-update` skill** — 10 min if we want automated sync.
9. **A4 — drift-check hook installer** — 5 min if drift-check runs cleanly on piper.
10. **B3 — `/brainstorm-review` grammar** — 10 min.
11. **B6 — Red Flags in piper skills** — 15 min; `/speckit` adaptation needed.

### Deferred

- Session 4+ work (auto-merge, /pipeline skill, coordinator agent) stays piper-local per the `followup_pipeline_skill.md` memory.

## Recommendation

**Do Priority 1 + 2 now** (roughly 1.5 hours). That captures the full value of this session's Pipekit work for piper with controlled risk. Priority 3 can land in a follow-up session once Priority 1+2 have soaked in real use.

Ready when you are.
