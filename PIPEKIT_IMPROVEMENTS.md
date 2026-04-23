# Pipekit Improvements — 2026-04-23 Plan

Scope: get Pipekit as good as it can be before deciding what to backport into piper. rs-vault remains the test consumer.

## Context

This session has already closed several gaps:
- Shipped `plan-reviewer` agent (was phantom dependency)
- Rewrote `/end-session` with holistic preflight + NEXT.md refresh
- Fixed `sync-method.sh` bootstrap via self-update re-exec
- Wired VBW post-archive hook → `/strategy-sync` nudge
- Refreshed VBW docs to v1.35.0, documented manual-mode gitignore quirk

This doc plans the remaining work, tiered by risk.

---

## Tier 1 — Rules Infrastructure (foundation)

The biggest structural gap Pipekit has today. Piper shipped CLAUDE.md thinning via `.claude/rules/` (WIT-162) but Pipekit has no `rules/` templates at all. Every Pipekit consumer either over-loads CLAUDE.md or under-specifies rules. Fix: ship canonical rule templates + update CLAUDE.md template to the hub-and-spoke pattern.

| # | Item | Effort | Output |
|---|------|--------|--------|
| 1.1 | Create `templates/rules/` with 4 canonical rules | ~45 min | `templates/rules/{tooling,patterns,security,discipline}.md` |
| 1.2 | Add Verify Library API (kmigdol pattern) to `tooling.md` | — | Included in 1.1 |
| 1.3 | Add Ad-hoc Plan Gate to `discipline.md` | — | Included in 1.1 |
| 1.4 | Add Red Flags pattern guidance to `discipline.md` | — | Included in 1.1 |
| 1.5 | Update CLAUDE.md template with routing table (hub → rules → SOPs) | ~20 min | New CLAUDE.md template in `templates/` |
| 1.6 | Update `/startup` to scaffold `.claude/rules/` from templates | ~20 min | `skills/startup/skill.md` diff |
| 1.7 | Update `sync-method.sh` to sync rules templates | ~10 min | Adds `templates/rules/` → project `.claude/rules/` on opt-in |

**Risk:** Low. Additive. No existing skill depends on rules existing.

**Verify by:** Run `/startup` in a scratch dir, confirm `.claude/rules/*.md` lands with canonical content.

---

## Tier 2 — Skill Enhancements

| # | Item | Effort | Output |
|---|------|--------|--------|
| 2.1 | Add Red Flags section to `/launch`, `/light-spec`, `/brainstorm` | ~30 min | Skill file diffs |
| 2.2 | Brainstorm Disposition (EXPAND/HOLD/REDUCE) in `/brainstorm` + `/brainstorm-review` | ~60 min | New disposition workflow, trigger-condition parking, `/roadmap-review` surfaces parked items when triggers fire |
| 2.3 | Enhanced drift detection — upgrade `scripts/drift-check.sh` | ~45 min | Adds: path-existence check, command-validity check, commits-since-touched staleness, post-commit hook |

**Risk:** Low-medium. 2.2 redesigns an existing skill workflow but doesn't break anything downstream.

**Verify by:** Run `/brainstorm` on a toy idea, walk through EXPAND → HOLD (Later + trigger) → REDUCE. Confirm Linear parked label + `/roadmap-review` surfaces it.

---

## Tier 3 — `/launch` Refactor (eliminate VBW duplication)

Today `/launch` manually orchestrates `vbw-lead → plan-reviewer → vbw-dev → vbw-qa`. VBW v1.35's `/vbw:vibe --execute` and `/vbw:vibe --verify` are the canonical paths. Pipekit is re-implementing orchestration that VBW already owns, and the 1.35 QA contract tightening (plan_ref, plans_verified, write-verification.sh) shows Pipekit will keep falling behind if we don't delegate.

The refactor makes Pipekit a thin gate layer:

- **Before:** `/launch` validates gates → spawns vbw-lead → spawns plan-reviewer → spawns vbw-dev per task → spawns vbw-qa → moves Linear to UAT
- **After:** `/launch` validates gates → hands off to `/vbw:vibe --execute` with plan-reviewer slot → on return, `/vbw:vibe --verify` → on verify success, moves Linear to UAT

| # | Item | Effort | Output |
|---|------|--------|--------|
| 3.1 | Step 9 QA: delegate to `/vbw:vibe --verify {phase}` instead of direct `vbw:vbw-qa` invocation | ~30 min | skills/launch/skill.md Step 9 rewritten to wait for vibe verify signal |
| 3.2 | Steps 7b-8 execution: delegate to `/vbw:vibe --execute` instead of orchestrating lead+dev manually | ~60 min | skills/launch/skill.md Steps 7b-8 rewritten; plan-reviewer integrates via vibe's plan-review slot |
| 3.3 | Preserve Pipekit's non-VBW responsibilities: Linear status transitions, PR routing, NEXT.md, cmux workspace rename | ~20 min | Keep these in /launch; strip only the VBW orchestration |
| 3.4 | Update method.md to reflect the simpler /launch architecture | ~15 min | Method doc diff |

**Risk:** Medium-high. `/launch` is the most-used skill. A broken refactor blocks execution everywhere. Mitigation:
- Keep current `/launch` intact as `/launch-legacy` for one release
- Test in rs-vault before declaring canonical
- Roll back via git if integration fails

**Verify by:** Run `/launch RS-16` (Medium complexity) in rs-vault with refactored `/launch`, confirm full flow lands on UAT.

---

## Execution Plan

### Session 1 (today): Tier 1 end-to-end
Ship rules infrastructure. Low risk, unblocks everything downstream. Commit per item (1.1, 1.5, 1.6, 1.7 as four atomic commits).

### Session 2: Tier 2
Red Flags (2.1) first — quick additive edits. Then Brainstorm Disposition (2.2) as the larger redesign. Drift detection (2.3) last.

### Session 3: Tier 3
Do 3.1 (QA delegation) first — lower blast radius than full execution refactor. Ship, verify in rs-vault, then 3.2 (execution delegation).

### Session 4: Piper backport decision
Once Pipekit is at target state, audit what to pull into piper. Candidates already known:
- plan-reviewer agent
- `/end-session` holistic preflight
- post-archive hook
- `/02-light-spec-revise`
- `pipekit-update` skill
- Whatever of Tiers 1-3 lands well

---

## Out of Scope (for now)

- Auto-merge / coordinator agent (piper-side experiment first — see `followup_pipeline_skill.md` memory)
- /pipeline skill (higher-level orchestrator)
- Cross-agent coordination via SendMessage
- /launch-native deprecation (keep as spike reference)

---

## Status

| Tier | Status |
|------|--------|
| Session 0 (gaps closed this session) | ✅ Done (plan-reviewer, end-session, sync self-update, post-archive hook, VBW 1.35 docs) |
| Tier 1 — Rules Infrastructure | ⏳ Pending approval |
| Tier 2 — Skill Enhancements | ⏳ Pending Tier 1 |
| Tier 3 — /launch Refactor | ⏳ Pending Tier 2 |
| Session 4 — Piper backport | ⏳ Pending Pipekit completion |
