# Piper Backport Runbook — 2026-04-23

Executable plan for bringing Pipekit's 2026-04-22/23 session improvements into piper. Designed to be run from a piper-side Claude Code session.

This doc lives in pipekit. Piper-side Claude should read it from `~/Projects/pipekit/PIPER_BACKPORT.md` (or the committed version on GitHub).

---

## Setup

### Prerequisites

From a piper-side session (`~/Projects/piper/`):

1. Confirm pipekit is available locally:
   ```bash
   test -d ~/Projects/pipekit && echo "pipekit accessible" || echo "pipekit missing — clone it first"
   ```

2. Confirm working tree is clean:
   ```bash
   cd ~/Projects/piper && git status --short
   ```
   If dirty, commit or stash before starting.

3. Create a tracking branch:
   ```bash
   git checkout -b chore/pipekit-backport-2026-04-23
   ```
   Each port lands as its own commit on this branch. PR the whole thing when Priority 1+2 is done.

4. Confirm piper's Linear MCP is the renamed `linear-server` (not the stale `linear`):
   ```bash
   jq -r '.mcpServers | keys[]' .mcp.json | grep -i linear
   # Expected: linear-server
   claude mcp list | grep -i linear
   # Expected: linear-server ✓ Connected (or similar)
   ```
   If instead you see the old `linear` name as a registered server, stop and finish the migration per `~/Projects/piper/temp/MCP-Migration-Plan-2026-04-21.md` Phase 4+5 before doing this backport — the MCP-name fixes in P2-B2 and P3-B3 assume the rename is complete.

5. Read piper's current state snapshot below before touching anything.

### Piper current state (2026-04-23)

**Already has** (don't clobber):
- 9 app-specific agents: `budget-logic`, `code-reviewer`, `code-simplifier`, `comment-analyzer`, `pr-test-analyzer`, `silent-failure-hunter`, `supabase-reviewer`, `type-design-analyzer`, `plan-reviewer` (piper's own 58-line version)
- 7 app-specific rules: `ag-grid-pitfalls`, `file-structure`, `hooks-realtime`, `naming`, `patterns`, `security`, `tooling` — all piper-tuned content
- Simpler `/brainstorm` without EXPAND/HOLD/REDUCE Phase 2
- Older `/end-session` without shutdown preflight
- `/launch` from before Tier 3 refactor
- Uses `/speckit` where pipekit uses `/light-spec`
- Uses older MCP tool names: `mcp__linear__linear_create_issue` where pipekit uses `mcp__linear-server__save_issue`

**Doesn't have**:
- 9 Stage 0 / admin skills (`concept`, `define`, `strategy-create`, `startup`, `roadmap-create`, `phase-plan`, `pipekit-update`, `02-light-spec-revise`, `launch-native`)
- `scripts/pipekit-post-archive.sh`
- Canonical `discipline.md` rule
- Drift-check hook installer

### Stale MCP names in piper — fix during backport

Per `~/Projects/piper/temp/MCP-Migration-Plan-2026-04-21.md`, piper migrated its Linear MCP server name to `linear-server` (as reflected in `.mcp.json`). **Most piper skills already use `mcp__linear-server__*`** — but three call sites still reference the stale `mcp__linear__*` prefix:

```
.claude/skills/brainstorm/skill.md:28:          mcp__linear__linear_create_issue
.claude/skills/brainstorm-review/skill.md:26:  mcp__linear__linear_search_issues
.claude/skills/brainstorm-review/skill.md:45:  mcp__linear__linear_edit_issue
```

These are stale tool names that no longer resolve — currently broken calls. Both files are touched by backport items P2-B2 and P3-B3. **Fix the stale names as part of those ports** — do not "preserve" them. Use the pipekit-style names:

| Stale (broken in piper today) | Correct (piper's current MCP) |
|-------------------------------|-------------------------------|
| `mcp__linear__linear_create_issue` | `mcp__linear-server__save_issue` (note: Linear's new API has save both create + update, no separate create) |
| `mcp__linear__linear_search_issues` | `mcp__linear-server__list_issues` (with query filter) |
| `mcp__linear__linear_edit_issue` | `mcp__linear-server__save_issue` (save handles edits too) |

When porting from pipekit, which uses `mcp__linear-server__*` throughout, you can copy call syntax directly.

Non-Linear MCP servers piper uses (`supabase-dev`, `supabase-prod`, `sentry`, `figma-*`, `langfuse`, `chrome-devtools`) are out of scope for this backport — Pipekit doesn't reference them.

---

## Priority 1 — High-value, low-risk (~35 min total)

### P1-A1. Post-archive hook

**Why:** Wire VBW's post-archive lifecycle (v1.35) into piper's `/strategy-sync` loop. After milestone archive, next session gets a nudge.

**Source:** `~/Projects/pipekit/scripts/pipekit-post-archive.sh`
**Destination:** `~/Projects/piper/scripts/pipekit-post-archive.sh`

**Commands:**
```bash
cp ~/Projects/pipekit/scripts/pipekit-post-archive.sh ~/Projects/piper/scripts/pipekit-post-archive.sh
chmod +x ~/Projects/piper/scripts/pipekit-post-archive.sh
```

Register in `.vbw-planning/config.json`:
```bash
cd ~/Projects/piper
jq '.hooks.post_archive = "scripts/pipekit-post-archive.sh"' .vbw-planning/config.json > .vbw-planning/config.json.tmp && mv .vbw-planning/config.json.tmp .vbw-planning/config.json
```

**Verify:**
```bash
test -x scripts/pipekit-post-archive.sh && jq -r '.hooks.post_archive' .vbw-planning/config.json
# Expected output: scripts/pipekit-post-archive.sh
```

**Commit:**
```
git add scripts/pipekit-post-archive.sh .vbw-planning/config.json
git commit -m "feat(hooks): wire /strategy-sync nudge via VBW post-archive hook

Installs Pipekit's post-archive-hook.sh which writes
.pipekit/pending-strategy-sync on milestone archive. Next session's
/start-session picks up the marker and nudges toward /strategy-sync.

Registered in .vbw-planning/config.json under .hooks.post_archive.
Source: pipekit commit 85988b1."
```

**Rollback:** `git revert <commit>` and `jq 'del(.hooks.post_archive)' .vbw-planning/config.json`.

### P1-A2. Canonical `discipline.md` rule

**Why:** Net-new portable rule file — Red Flags + Ad-hoc Plan Gate + scope hygiene + comment/commit discipline. Piper doesn't have this topic covered anywhere today.

**Source:** `~/Projects/pipekit/templates/rules/discipline.md`
**Destination:** `~/Projects/piper/.claude/rules/discipline.md`

**Commands:**
```bash
cp ~/Projects/pipekit/templates/rules/discipline.md ~/Projects/piper/.claude/rules/discipline.md
```

Add a row to piper's CLAUDE.md Routing Pointers table. Find the routing table (around line 173-188 in piper's CLAUDE.md) and insert:

```markdown
| AI coding discipline (Red Flags, Plan Gate, scope) | Yes                | `.claude/rules/discipline.md` |
```

Place it as the first row since it's the most cross-cutting.

**Verify:**
```bash
test -f .claude/rules/discipline.md && grep -q "discipline.md" CLAUDE.md && echo OK
```

**Commit:**
```
git add .claude/rules/discipline.md CLAUDE.md
git commit -m "feat(rules): add discipline.md (Red Flags, Ad-hoc Plan Gate, scope hygiene)

Ports pipekit's canonical discipline.md rule. Auto-loaded every
session. Adds:
- Red Flags table (thoughts that mean 'go slower')
- Ad-hoc Plan Gate (3-5 bullet plan format for non-VBW interactive work)
- Scope hygiene (no features/abstractions beyond task, boundary-only validation)
- Comment/commit discipline

Addresses METHOD_IMPROVEMENTS.md #1 (Red Flags), #3 (Ad-hoc Plan Gate).
Source: pipekit commit f31a2ff."
```

**Rollback:** `git revert <commit>`.

### P1-B1. `/end-session` holistic preflight

**Why:** Piper's current `/end-session` is where session artifacts get orphaned when the feature branch is squash-merged. The new Step 0 preflight detects non-main branch state, classifies PR, offers switch/hold/cancel. Also detects stale VBW agent worktrees and dangling `worktree-agent-*` branches.

**Source:** `~/Projects/pipekit/skills/end-session/skill.md` — Steps 0a/0b/0c/0d/0e (the preflight block) and Step 7b (NEXT.md refresh).
**Destination:** `~/Projects/piper/.claude/skills/end-session/skill.md`

**Piper adaptations:**
- Piper uses `main/beta/dev` three-tier (per method.config.md). The preflight reads integration branch from config — already handles this.
- Piper's `mcp__linear-server__*` calls in Steps 6 are already correct (pipekit uses the same); no rename needed for end-session.
- Preserve piper's Step 9 (Post to Slack) — pipekit doesn't have Slack integration. Port only Steps 0+7b.

**Approach:** diff-based port. Don't wholesale overwrite.

```bash
# Read both versions to see what to merge
diff ~/Projects/pipekit/skills/end-session/skill.md ~/Projects/piper/.claude/skills/end-session/skill.md
```

Then open piper's `~/Projects/piper/.claude/skills/end-session/skill.md` and:
1. Insert Step 0 block (Step 0a through Step 0e from pipekit) before piper's existing Step 1
2. Insert Step 7b (NEXT.md refresh) between piper's Step 7 and Step 8

**Verify:**
```bash
grep -c "Step 0a\|Step 7b" .claude/skills/end-session/skill.md
# Expected: at least 2
```

**Commit:**
```
git add .claude/skills/end-session/skill.md
git commit -m "feat(end-session): shutdown preflight + NEXT.md refresh (Tier 3 port)

Ports pipekit's Step 0 preflight and Step 7b NEXT.md refresh into
piper's /end-session. Preserves piper's Slack post in Step 9.

Preflight scans for: feature-branch PR state, merged feature branches,
VBW agent worktrees with dead-PID locks, orphan worktree-agent-*
branches, uncommitted changes. Presents a plan with proceed/selective/
skip/cancel before doing anything destructive.

NEXT.md refresh recomputes the next action from Linear state so
NEXT.md never points at a just-shipped issue.

Source: pipekit commit 886b182."
```

**Rollback:** `git revert <commit>`.

### P1-B4. Upgrade `plan-reviewer` agent

**Why:** Piper has a 58-line hand-rolled plan-reviewer. Pipekit shipped a 242-line version with structured Input Contract, Review Protocol, Severity Classification, and a parseable output format. The `/launch` Tier 3 refactor (P2-B5) expects the structured output.

**Source:** `~/Projects/pipekit/agents/plan-reviewer.md`
**Destination:** `~/Projects/piper/.claude/agents/plan-reviewer.md`

**Commands:**
```bash
# Back up piper's existing version — keep it as a fallback for one release
cp ~/Projects/piper/.claude/agents/plan-reviewer.md ~/Projects/piper/.claude/agents/plan-reviewer-legacy.md
cp ~/Projects/pipekit/agents/plan-reviewer.md ~/Projects/piper/.claude/agents/plan-reviewer.md
```

**Verify:**
```bash
head -5 .claude/agents/plan-reviewer.md  # Should start with "name: plan-reviewer" + pipekit description
wc -l .claude/agents/plan-reviewer.md    # Should be ~242 lines
wc -l .claude/agents/plan-reviewer-legacy.md  # Should be ~58 lines
```

**Commit:**
```
git add .claude/agents/plan-reviewer.md .claude/agents/plan-reviewer-legacy.md
git commit -m "feat(agents): upgrade plan-reviewer to pipekit's structured version

Previous piper plan-reviewer (58 lines) is archived as
plan-reviewer-legacy.md. New version (242 lines) adds:
- Explicit Input Contract (plan paths, approved spec, project context)
- Structured Review Protocol (spec fidelity / atomicity / testability /
  risk / strategic fit)
- Severity Classification (Blocking vs Non-blocking with concrete rules)
- Parseable markdown output format: Verdict + Blocking Issues +
  Fast Path to Pass (orchestrator-parsable)

Required by /launch Tier 3 refactor in next commit — that skill's
handoff logic relies on the structured output.

Source: pipekit commit 7c9497e."
```

**Rollback:** `mv .claude/agents/plan-reviewer-legacy.md .claude/agents/plan-reviewer.md`.

---

## Priority 2 — High-value, medium-risk (~65 min total)

### P2-B5. `/launch` Tier 3 refactor

**Why:** Highest-value port. Piper's `/launch` still orchestrates `vbw:vbw-dev` per task and `vbw:vbw-qa` directly. VBW v1.35 tightened QA contracts; hand-orchestration drifts against them every release. Delegating to `/vbw:vibe --execute` and `--verify` eliminates that drift.

**Source:** `~/Projects/pipekit/skills/launch/skill.md` — specifically the rewritten Step 8 + Step 9 + Step 10 + updated Model Selection table.
**Destination:** `~/Projects/piper/.claude/skills/launch/skill.md`

**Piper adaptations:**
- Piper's `/launch` has **three-tier promotion** (`/g-promote-dev`, `/g-promote-beta`, `/g-promote-main`); pipekit's shows two-tier. Preserve piper's `/g-promote-*` references in Step 10's "Accept with" text.
- Piper's `/launch` points to `/speckit` not `/light-spec-revise`. Keep piper's skill references in error paths.
- Piper uses `mcp__linear__linear_save_issue` in some places. The `/launch` skill itself doesn't — both repos use the current `mcp__linear-server__save_issue`. No rename needed.
- Keep piper's Milestone/Project Batch Mode section unchanged.

**Approach:** merge-based. Replace Steps 8, 9, 10 in piper's `/launch` with pipekit's versions, adapting as above. Do not touch Steps 1-7b or the Batch Mode section.

Before starting, back up piper's `/launch`:
```bash
cp ~/Projects/piper/.claude/skills/launch/skill.md ~/Projects/piper/.claude/skills/launch/skill.md.pre-tier3
```

Then open piper's `skill.md` and:
1. Replace Step 8 block (Old: "Spin up VBW Dev Agent per task") with pipekit's Step 8 (handoff to `/vbw:vibe --execute`)
2. Replace Step 9 block (Old: "Spin up VBW QA Agent") with pipekit's Step 9 (handoff to `/vbw:vibe --verify`, including fail classification)
3. Update Step 10 comment and status check text to reference the VBW verify signal instead of the QA agent return
4. Update Model Selection table — keep only `vbw:vbw-lead` and `plan-reviewer` rows; remove `vbw-dev` and `vbw-qa` rows; add the "VBW-side agents (not pinned here)" paragraph
5. Update NEXT.md Output section with the handoff-pause-point schedule

Pipekit source lines (for reference when merging):
- Step 8: skill.md lines 178-214
- Step 9: skill.md lines 216-259
- Step 10: skill.md lines 261-287
- Model Selection update: skill.md lines 29-43
- NEXT.md Output update: skill.md lines 371-383

**Verify:**
```bash
grep -c "vbw:vbw-dev\|vbw:vbw-qa" .claude/skills/launch/skill.md
# Expected: 0 in the spawning context (may still appear in method references)

grep -c "/vbw:vibe --execute\|/vbw:vibe --verify" .claude/skills/launch/skill.md
# Expected: at least 3 (Step 8 handoff, Step 9 handoff, some prose reference)
```

**Commit:**
```
git add .claude/skills/launch/skill.md
git commit -m "refactor(launch): delegate execute and verify to /vbw:vibe (Tier 3)

Steps 8 and 9 no longer spawn vbw-dev per-task or vbw-qa directly.
They hand off to /vbw:vibe --execute {phase} and /vbw:vibe --verify
{phase} with pause-and-resume semantics: /launch waits for the user
to return with a status report, then resumes (UAT transition on
verify pass, re-enter execute on fixable fail, route back to spec
on framing errors).

Why: VBW v1.35 tightened the QA contract (plan_ref, plans_verified,
write-verification.sh). Hand-orchestrating drifts against that
contract every version bump. Delegating is both safer and lower
maintenance — VBW owns execution+QA, piper owns Linear gates and
promote flow.

Step 7b (plan + plan-reviewer gate) unchanged — that is piper's
value-add and does not exist in /vbw:vibe. Preserves piper's
three-tier /g-promote-dev/beta/main flow in Step 10.

Depends on upgraded plan-reviewer agent (previous commit) which
produces the structured output this refactor expects.

Source: pipekit commits f0db16d, ac8a3ed."
```

**Rollback:** `cp .claude/skills/launch/skill.md.pre-tier3 .claude/skills/launch/skill.md && rm .claude/skills/launch/skill.md.pre-tier3`.

Delete the `.pre-tier3` backup after one successful real launch (delete on the same commit where you add the next feature).

### P2-B2. `/brainstorm` Phase 2 HOLD + trigger grammar

**Why:** Closes METHOD_IMPROVEMENTS.md #4 (Brainstorm Disposition). Piper's `/brainstorm` Phase 1 only captures ideas — there's no disposition step, so issues accumulate in Ideas forever (the WIT-349 Gmail Agent example).

**Source:** `~/Projects/pipekit/skills/brainstorm/skill.md` — Phase 2 HOLD and Phase 3 REDUCE sections + the trigger grammar.
**Destination:** `~/Projects/piper/.claude/skills/brainstorm/skill.md`

**Piper adaptations — important:**
- **MCP names: use pipekit's** (`mcp__linear-server__*`). Piper's `/brainstorm` has a stale `mcp__linear__linear_create_issue` at line 28 — that call is broken today (the `linear` server was renamed to `linear-server` per MCP-Migration-Plan-2026-04-21.md). Replace it with `mcp__linear-server__save_issue` as part of this port.
- Piper's Linear workspace values — hardcoded team ID `021f03cd-5661-4fc3-b292-6878b927b8ff` in piper's version. Preserve the team ID; the portable version uses `{team from method.config.md}` which piper doesn't fully use.
- Label creation: use `mcp__linear-server__create_issue_label` (pipekit's, also piper's current correct name).
- Piper uses `/speckit` where pipekit's section references `/light-spec`. Keep `/speckit` in piper's copy.

**Approach:** append Phase 2 and Phase 3 sections to piper's `/brainstorm`. Piper's Phase 1 is different (uses older MCP calls) — do NOT overwrite that. Only add the new phases.

```bash
cp ~/Projects/piper/.claude/skills/brainstorm/skill.md ~/Projects/piper/.claude/skills/brainstorm/skill.md.pre-disposition
```

Open piper's `skill.md` and:
1. After piper's existing "Phase 1 — Brainstorm" section (where the issue is created), insert:
   - A Phase 2 — HOLD section with the Now/Later/Kill prompt
   - The trigger grammar table
   - The Parked-label check (verify piper's label-creation MCP name)
2. After Phase 2, insert Phase 3 — REDUCE for "Now" items
3. Adapt all MCP tool names to piper's current names — grep piper's other skills for the actual MCP namespace in use

**Verify:**
```bash
grep -c "Phase 2 — HOLD\|Phase 3 — REDUCE\|Trigger grammar" .claude/skills/brainstorm/skill.md
# Expected: 3
```

**Commit:**
```
git add .claude/skills/brainstorm/skill.md
git commit -m "feat(brainstorm): add EXPAND/HOLD/REDUCE disposition + fix stale MCP name

Closes METHOD_IMPROVEMENTS.md #4. /brainstorm now forces a Now/Later/Kill
decision immediately after issue creation. 'Later' dispositions take a
parseable trigger from a small grammar:

- {ISSUE-ID} ships
- Stage N UAT passes
- Phase N ships
- date: YYYY-MM-DD
- manual

/roadmap-review (see P3 port, or future work) auto-detects fired
triggers and surfaces them for re-disposition.

Also fixes stale MCP call at line 28 — mcp__linear__linear_create_issue
(stale, broken) → mcp__linear-server__save_issue. Follows the rename
from MCP-Migration-Plan-2026-04-21.md.

Adapted from pipekit commit 635a1ee."
```

**Rollback:** `mv .claude/skills/brainstorm/skill.md.pre-disposition .claude/skills/brainstorm/skill.md`.

### P2-C1. Append Verify Library API to piper's `tooling.md`

**Why:** Piper's `tooling.md` is richer than pipekit's portable baseline (monorepo filters, concrete turbo commands) — don't replace it. But piper doesn't have the Verify Library API / never-assume guidance. Append that section.

**Source section (from pipekit):** `~/Projects/pipekit/templates/rules/tooling.md` — the `## Verify Library API Before Use` section + the "Never assume:" list (roughly lines 5-38 of pipekit's tooling.md).

**Destination:** Append to `~/Projects/piper/.claude/rules/tooling.md`.

**Commands:**

Open piper's `.claude/rules/tooling.md`. Scroll to the end (after the existing content). Append the entire Verify Library API section from pipekit's `tooling.md`. Do not add the Package Manager, Pre-Deploy Gate, or CLI Commands sections — piper already covers those better.

**Verify:**
```bash
grep -c "Verify Library API" .claude/rules/tooling.md
# Expected: at least 1
```

**Commit:**
```
git add .claude/rules/tooling.md
git commit -m "feat(rules): add Verify Library API section to tooling.md

Closes METHOD_IMPROVEMENTS.md #2. Appends the Verify Library API
sequence (check installed version, read node_modules source, use
context7 MCP) + never-assume list (signatures, config options,
import paths, default behaviors) to piper's existing tooling.md.

Piper's existing tooling.md content (monorepo, pre-deploy gate,
CLI commands) unchanged — this is additive only.

Source: pipekit templates/rules/tooling.md, commit f31a2ff."
```

**Rollback:** `git revert <commit>`.

### P2-C2. Append OWASP checklist to piper's `security.md`

**Why:** Same pattern as C1. Piper's `security.md` has specific finance-platform invariants (User ID invariant, RLS pattern). Pipekit's has a portable OWASP Top 10 awareness list. Append, don't replace.

**Source section:** `~/Projects/pipekit/templates/rules/security.md` — the `## OWASP Top 10 Awareness` section (roughly lines 43-57).

**Destination:** Append to `~/Projects/piper/.claude/rules/security.md`.

**Verify:**
```bash
grep -c "OWASP Top 10" .claude/rules/security.md
# Expected: at least 1
```

**Commit:**
```
git add .claude/rules/security.md
git commit -m "feat(rules): add OWASP Top 10 checklist to security.md

Appends pipekit's portable OWASP Top 10 awareness list to piper's
existing security.md. Piper's finance-platform-specific content
(User ID invariant, RLS-on-every-table, service-role prohibition)
unchanged — this is additive only.

Source: pipekit templates/rules/security.md, commit f31a2ff."
```

**Rollback:** `git revert <commit>`.

---

## Priority 3 — Low urgency (do later if ever)

### P3-A3. `pipekit-update` skill

Install `~/Projects/pipekit/skills/pipekit-update/` → `~/Projects/piper/.claude/skills/pipekit-update/`. Straight copy. Piper doesn't need this for the backport itself (you're doing the port manually), but it enables future pulls to be one-command.

```bash
cp -r ~/Projects/pipekit/skills/pipekit-update ~/Projects/piper/.claude/skills/
```

### P3-A4. Drift-check hook installer

Piper doesn't have `scripts/drift-check.sh`. If drift detection would be valuable, copy the full script:
```bash
cp ~/Projects/pipekit/scripts/drift-check.sh ~/Projects/piper/scripts/drift-check.sh
chmod +x ~/Projects/piper/scripts/drift-check.sh
bash ~/Projects/piper/scripts/drift-check.sh --install-hook
```

### P3-B3. `/brainstorm-review` trigger grammar + stale MCP fix

If P2-B2 lands well and piper wants the batch-disposition workflow, port pipekit's `/brainstorm-review/skill.md`. This file also has two stale MCP calls to fix:

- Line 26: `mcp__linear__linear_search_issues` → `mcp__linear-server__list_issues` (use the `query` filter for search semantics)
- Line 45: `mcp__linear__linear_edit_issue` → `mcp__linear-server__save_issue` (save handles creates and edits in Linear's current API)

Bundle the MCP fixes in the same commit as the grammar port.

### P3-B6. Red Flags in piper skills

Add short "Red Flags" sections to piper's `/launch`, `/speckit`, `/brainstorm` per pipekit's pattern. Piper's skills have different failure modes than pipekit's baseline — rewrite the flags to match piper's observed drift (the piper-side Claude session will know what's bit you recently).

### P3-/roadmap-review trigger-eval

If piper has `/roadmap-review` and you ported P2-B2 (brainstorm disposition), also port pipekit's `/00-roadmap-review` Parked Items section — the one that parses triggers and surfaces fired ones. Without this, parked items still rot; they just rot with a nicer comment format.

---

## Rollback Strategy

Each commit above is atomic and `git revert`-able in isolation. If something breaks:

1. Identify the commit: `git log --oneline chore/pipekit-backport-2026-04-23`
2. Revert: `git revert <commit>`
3. Push the revert

If the whole branch goes sideways: `git checkout main && git branch -D chore/pipekit-backport-2026-04-23` (before merging).

For `.pre-*` backup files created during surgical merges (B1, B5, B2):
- Keep them on the branch through PR review
- Delete them in the same commit as the first post-backport feature work (not now — post-mortem-able)

---

## After All Priority 1+2 Commits

1. Run piper's existing smoke tests / pre-deploy gate:
   ```bash
   cd ~/Projects/piper
   pnpm turbo run check-types && pnpm turbo run lint && pnpm turbo run test
   ```

2. If green, PR the branch into `dev`:
   ```bash
   git push -u origin chore/pipekit-backport-2026-04-23
   gh pr create --base dev --title "chore: backport pipekit 2026-04-23 improvements" --body "$(cat <<'EOF'
   ## Summary
   Backports Pipekit Tier 1-3 session work into piper. Seven atomic commits on this branch.

   ## What's in scope
   - Post-archive hook wiring (VBW v1.35 lifecycle)
   - discipline.md canonical rule
   - /end-session shutdown preflight + NEXT.md refresh
   - plan-reviewer agent upgrade (structured output)
   - /launch Tier 3 refactor (delegate to /vbw:vibe)
   - /brainstorm disposition + trigger grammar
   - OWASP + Verify Library API append to existing rules

   ## Test plan
   - [ ] Run /launch on a test issue end-to-end
   - [ ] Run /end-session on a non-main branch, confirm preflight triggers
   - [ ] Archive a milestone via /vbw:vibe --archive, confirm .pipekit/pending-strategy-sync marker lands
   - [ ] Create a test brainstorm, confirm Phase 2 HOLD triggers and parseable Parked comment is written

   See `~/Projects/pipekit/PIPER_BACKPORT.md` for full rationale.
   EOF
   )"
   ```

3. Merge after UAT passes.

---

## Not In Scope — Session 4+ Work

These stay deferred per `~/.claude/projects/-Users-ethanrosch-Projects-pipekit/memory/followup_pipeline_skill.md`:

- Auto-merge on green CI
- Cross-agent coordination via SendMessage
- `/pipeline` skill (higher-level orchestrator)
- Coordinator agent for multi-worktree pipelines

Piper-side experiments first. Pipekit adoption follows.
