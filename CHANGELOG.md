# Changelog

All notable Pipekit releases. Versioning follows semver-ish — minor bumps for new capability, patch for fixes/docs only.

Pin to a specific version: `./scripts/sync-method.sh v1.2.0`.

---

## v1.2.0 — 2026-04-26

### What's New

**BMAD-inspired upgrade pack.** Four discrete steals from [BMAD-METHOD](https://github.com/bmad-code-org/BMAD-METHOD) that strengthen Pipekit without touching the parts that already work — Linear stays the visibility layer, the strategy-sync loop stays the apex, the spec-as-contract principle stays load-bearing. Lands as four sequential commits (P4 → P3 → P1 → P2) that ship value alone if you stop after any of them.

#### Sync-Safe Overrides (`.claude/overrides/`)
Projects can now customize synced skills, SOPs, and `method.md` without forking and without losing upstream improvements. The sync script applies overrides on top of the upstream copy and surfaces a **drift warning** when upstream changes a file you override.

- `.claude/overrides/skills/<name>/skill.md` — full-file replacement
- `.claude/overrides/sop/<file>.md` — full-file replacement
- `.claude/overrides/method.md.patch` — unified diff
- `.claude/overrides/MANIFEST.md` — human-curated index (what + why)

Failed patches dry-run first — they don't half-apply. See `method.md` § Sync-Safe Overrides.

#### First-class scale tiers in `/launch` (Quick / Standard / Heavy)
`/launch` now resolves a **tier** for every issue. Tiers shape *which gates apply*; complexity (Low/Medium/High) shapes *how execution is routed*. The two are orthogonal.

- **Quick** — 1–3 stories, AC-as-plan. Skips spec review, milestone-readiness, plan review, QA agent. Routes to batch runner.
- **Standard** (default) — Existing pipeline.
- **Heavy** — Adds security review + mandatory `/strategy-sync` before close. Always full VBW planning, batch runner disallowed.

Tier inference is **always confirmed with the human** — auto escalation/de-escalation is disallowed by design. Per-tier templates live at `templates/tier-{quick,standard,heavy}.md`. Per-project tier configuration in `method.config.md` § Tiers.

#### `/pipekit-help` skill + opt-in next-step nudge
Push-based replacement for "what skill do I run now?" — replaces pull-based skill discovery in a 12-step pipeline.

- `/pipekit-help` reads project state (branch, recent commits, presence of `PLAN.md` / `REVIEW.md` / `VERIFICATION.md`, `.pipekit/pending-strategy-sync` marker, Linear status) and recommends exactly one next step with a one-line why.
- Rules live in `skills/pipekit-help/state-rules.md` — first match wins; customizable via the override system.
- `scripts/pipekit-next-step-nudge.sh` is an **opt-in** Stop hook that suggests `/pipekit-help` after pipeline-relevant skills finish. Scoped by transcript inspection (silent unless the previous turn invoked a pipeline skill).

#### Fresh-chat discipline (documented enforcement)
The spec-as-contract principle ("no stage may introduce guesswork into the next stage") only holds if downstream agents read prior stage output as documents, not as recalled conversation.

- New `method.md` § Fresh-Chat Discipline section lists which transitions require a new conversation and why.
- Preamble nudges added to skills that cross stage boundaries: `/launch`, `/light-spec-revise`, `/review-plan`, `/strategy-sync`.

### Other Changes Since v1.1.0

This release also bundles the Tier 1 / Tier 2 / Tier 3 `/launch` refactor that landed prior to the BMAD upgrade pack:

- `/launch` split into open + close phases; Pipekit owns Linear status transitions, VBW owns plan/execute/verify
- `/review-plan` standalone skill spawning the `plan-reviewer` agent at `model: opus`
- Post-archive hook (`scripts/pipekit-post-archive.sh`) → `/strategy-sync` nudge via `.pipekit/pending-strategy-sync` marker
- Batch-promote SOP and `/launch --close` messaging
- Canonical `.claude/rules/` hub-and-spoke template (`pipekit-discipline`, `pipekit-tooling`, `pipekit-security`)
- `sync-method.sh` self-update guard + re-exec for single-invocation upgrades

### Deprecations

- `/launch --deep` — no-op since Tier 1; emits a one-line warning. Use `/vbw:vibe --execute --effort=max` instead.

### Migration

For consuming projects on v1.1.0:

1. `./scripts/sync-method.sh v1.2.0` — pulls everything.
2. (Optional) Add `## Tiers` section to `method.config.md` if you want to disable a tier or document tier policy. Default is all three available with **Standard** as fallback.
3. (Optional) Wire the next-step nudge by adding the snippet from `sop/Skills_SOP.md` § Next-Step Nudges to `.claude/settings.local.json`.
4. (Optional) Migrate any pre-v1.2.0 forked skills into `.claude/overrides/skills/<name>/skill.md` so they stop getting clobbered on sync.

No breaking changes. Existing pipelines run unchanged with **Standard** tier as the default.

---

## v1.1.0-opus4.7 — 2026-04-17

Adapted methodology to Claude Opus 4.7 behavioral changes:

- DesignDirection template counters Opus 4.7's default cream/serif/terracotta aesthetic; requires 4 distinct directions before building.
- Literal-scope authoring guidelines added to skills.
- Explicit subagent guidance for Opus 4.7.
- `Session_Management_SOP.md` for Claude Code + Opus 4.7 context handling.

---

## Earlier

See `git log` and `PIPEKIT_IMPROVEMENTS.md` for pre-v1.1.0 history.
