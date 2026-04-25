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

- Cross-agent coordination via SendMessage
- /launch-native deprecation (keep as spike reference)
- Auto-merge on green CI (piper-side experiment first — see `followup_pipeline_skill.md` memory)

---

## Tier 4 — Post-RS-8 findings (discovered 2026-04-24)

Shipped RS-8 in rs-vault end-to-end surfaced a set of issues in how Pipekit currently interacts with VBW, promotes work, and paces the human. All deferred for a dedicated session.

| # | Item | Effort | Why |
|---|------|--------|-----|
| 4.1 | `/launch` Step 9 VBW-readiness probe | ~30 min | Tier 3 refactor assumed every consumer has VBW's verify flow wired. rs-vault has a Linear-per-issue nested phase layout; `phase-detect.sh` returns `phase_count=0` and `/vbw:vibe --verify` fails at its guard ("no SUMMARY.md"). Fix: Step 9 probes the flow state before delegating, falls back to a precedent path (skip-to-UAT, rely on Dev self-verification + /g-test-vercel + manual UAT) when not wired. Document both paths. |
| 4.2 | `/launch` Step 10 batch-promote messaging | ~20 min | Current text implies per-issue chain ("Accept with: move to Done, then /g-promote-dev"). Users feel pushed to promote-now when they want to accumulate 2-5 dev-landed issues and batch-promote to main. Update messaging to offer explicit options: ship now / accumulate / hold in UAT. Note batch is the default for feature-heavy phases. |
| 4.3 | Batch-promote SOP | ~30 min | New section in `sop/Git_and_Deployment.md` (or a new `sop/Promotion_SOP.md`). Cover: when to batch vs per-issue, how DB migrations apply during accumulation, when to cut the batch, three-tier adaptation for projects with beta. |
| 4.4 | ~~VBW upstream tracking — issue #506~~ — **DONE** | — | Shipped in VBW v1.35.1 (PR #517, merged 2026-04-24). `ensure_transient_ignore` now fires across all three tracking modes per the original issue. `sop/VBW_Help.md` updated with the resolution note; flip-flip workaround retired. Pipekit pinning bumped to v1.35.1. |
| 4.5 | `/pipeline` skill (tier 4 proper) | ~2-3 hours | Higher-level orchestrator that wraps /launch's gate layer and auto-progresses through courier-role pauses (execute → verify → UAT move). Preserves judgment-role pauses: plan-reviewer verdict, verify failure classification, PR description writing. Falls back to explicit pause-and-prompt on any non-success signal. Rationale: RS-8 hit three courier pauses ("proceed with /vbw:vibe --verify?" etc.); each is mechanical click-to-continue with no judgment involved. Should only pause where human eyes add irreplaceable value. |

**Risk:** Low-medium per item. 4.1 is the most load-bearing (blocks the current Tier 3 refactor on non-VBW-wired consumers). 4.5 is the biggest scope.

### Suggested execution order

1. **4.4 first** — trivial when fix ships, and unblocks removing the quirk workaround from consumer SOPs.
2. **4.1 next** — fixes the concrete RS-8 friction. No consumer can reliably /vbw:vibe --verify today.
3. **4.2 + 4.3 together** — messaging change pairs naturally with the SOP write-up.
4. **4.5 last** — biggest design; wants a full session.

---

## Status

| Tier | Status |
|------|--------|
| Session 0 (gaps closed earlier) | ✅ Done (plan-reviewer, end-session, sync self-update, post-archive hook, VBW 1.35 docs) |
| Tier 1 — Rules Infrastructure | ✅ Done (commits `f31a2ff`, `96c3b1e`, `dcacaa4`, `7b7454c`) |
| Tier 2 — Skill Enhancements | ✅ Done (commits `474f296`, `635a1ee`, `dc43b95`) |
| Tier 3 — /launch Refactor | ✅ Done (commits `f0db16d`, `ac8a3ed`, `5b468dc`) |
| Canonical rule rename | ✅ Done (commits `93e14c8`, `174f446`) |
| Tier 4 — Post-RS-8 findings | ⏳ Pending (5 items, see above) |
| Session 4 — Piper backport | ⏳ Pending (runbook in `PIPER_BACKPORT.md`) |

### Tier 3 recap

- **Steps 8 and 9 refactored** from direct `vbw:vbw-dev` / `vbw:vbw-qa` spawns to handoff-and-resume against `/vbw:vibe --execute` and `/vbw:vibe --verify`. Eliminates the contract-drift risk that hit hard on VBW v1.35 (plan_ref, plans_verified, write-verification.sh).
- **Step 7b preserved** — `vbw:vbw-lead` + `plan-reviewer` remain Pipekit-spawned because the plan-gate is Pipekit's value-add, not a VBW feature.
- **Failure paths** in Step 9 classify verify failures as fixable-in-execute (route back to `/vbw:vibe --execute`) vs plan-level (route back to `/vbw:vibe --plan` or `/light-spec-revise`). Linear issue stays in Building on failure.
- **NEXT.md schedule** — `/launch` now pauses at handoffs, so `NEXT.md` is written at each pause point (handoff to execute, handoff to verify, UAT transition) so the user's next action survives session close.
- **Model Selection table** trimmed to the two agents `/launch` still pins (`vbw-lead`, `plan-reviewer`). `--deep` flag preserved as a no-op with a warning directing users to `/vbw:vibe --execute --effort=max`.
- **method.md** pipeline table + Rule 5 updated to reflect `/launch` as the entry-point-and-resume-point, `/vbw:vibe` as the handoff target.

### Tier 2 recap

- **Red Flags sections** added to `/launch`, `/light-spec`, `/brainstorm` — five skill-specific thought-pattern flags each, paired with the portable `discipline.md` set.
- **Brainstorm disposition** formalized: unified parseable trigger grammar (`{ISSUE-ID} ships` | `Stage N UAT passes` | `Phase N ships` | `date:YYYY-MM-DD` | `manual`), auto-creation of the `Parked` label across both `/brainstorm` and `/brainstorm-review`, and real trigger-evaluation logic in `/roadmap-review` with four output buckets (triggered / not-yet / manual-review / parse errors).
- **Drift-check hook installer** via `--install-hook` / `--uninstall-hook`, with coexistence handling for pre-existing user hooks. New `--quick` mode skips the staleness check so hook runs fast.

### Tier 1 recap

- `templates/rules/` now ships three canonical topic files: `discipline.md` (Red Flags, Ad-hoc Plan Gate, scope hygiene), `tooling.md` (Verify Library API, package manager, pre-deploy gate), `security.md` (secrets, boundary validation, OWASP baseline) + a `README.md` explaining the hub-and-spoke model.
- `templates/CLAUDE.md.template` — portable hub-and-spoke template with placeholders, Routing Pointers table, Source of Truth hierarchy, VBW Rules block. ~120 lines, well under piper's pre-thinning 363.
- `/startup` Step 10 rewritten as 10a/10b/10c — verify canonical rules landed, fill CLAUDE.md template, add project-specific rules, final review.
- `sync-method.sh` now installs canonical rules to `.claude/rules/` on every sync using per-file `sync_file` (not `sync_dir --delete`), so project-specific additions like `patterns.md` / `naming.md` / `{library}-pitfalls.md` survive untouched. Verified in sandbox.
- Self-update re-exec pattern (from earlier) continues to work cleanly in combination with the new rules block.
