# Pipekit Help — State Rules

> Ordered list of state matchers. First match wins. Each rule pairs a matcher with a recommendation and a one-line why.

Rules are evaluated top-to-bottom. Early rules handle blocking conditions and post-pipeline actions; later rules handle in-pipeline progression.

## 1. Stage 0 not complete

**Match:** `.vbw-planning/PHASES.md` does not exist OR `Strategy/` directory is empty.

**Recommend:** `/startup`
**Why:** Stage 0 (foundation) hasn't run; pipeline can't operate without it.

## 2. Pending strategy sync

**Match:** `.pipekit/pending-strategy-sync` file exists.

**Recommend:** `/strategy-sync`
**Why:** Post-archive hook flagged a milestone close; strategy docs are out of date with shipped reality.

## 3. Verification done, ready to close

**Match:** Latest phase has `VERIFICATION.md` AND no Linear `--close` has been recorded for the matching issue (heuristic: branch name contains a `PROJ-XXX` token AND most recent commit on this branch is post-VERIFICATION.md timestamp).

**Recommend:** `/launch <issue> --close`
**Why:** QA passed; the only remaining step is the Pipekit close transition to UAT.

## 4. Plan reviewed but not executed

**Match:** Latest phase has `PLAN.md` AND `REVIEW.md` AND `REVIEW.md` indicates "Pass" or equivalent AND no execution-state evidence (no commits since the review on the current branch).

**Recommend:** `/vbw:vibe --execute`
**Why:** Plan is reviewed and approved; ready for atomic execution.

## 5. Plan exists but not reviewed

**Match:** Latest phase has `PLAN.md` AND no `REVIEW.md` (or REVIEW.md older than PLAN.md).

**Recommend:** `/review-plan`
**Why:** Plan must pass independent review before execution (Pipekit's value-add over raw VBW).

## 6. Issue Building, no plan yet

**Match:** Branch is project-prefixed (`PROJ-XXX`) AND no `PLAN.md` exists for any phase referencing this issue AND Linear issue status (if checked) is "Building" AND inferred tier is Standard or Heavy.

**Recommend:** `/vbw:vibe --plan`
**Why:** Issue is in Building but no plan has been generated yet. Start a fresh chat first (see method.md § Fresh-Chat Discipline).

## 6b. Quick tier — direct to batch runner

**Match:** Issue label includes `tier:quick` AND Linear status is "Building" AND no batch run has fired (no batch-runner output for this issue in recent transcripts).

**Recommend:** `/linear-todo-runner`
**Why:** Quick tier skips planning; AC is the plan.

## 7. Spec exists but not approved

**Match:** Linear issue status is "Specced" (not yet Approved) AND latest spec-review-agent comment exists.

**Recommend:** Read the spec-review comment in Linear. If revision needed → `/light-spec-revise PROJ-XXX`. If clean → human approval in Linear.
**Why:** Spec passed agent review but human approval is required before launch.

## 8. Spec drafted but not reviewed

**Match:** Linear issue has a `## Light Spec` section AND no spec-review-agent comment exists (or comment predates last spec edit).

**Recommend:** Trigger Linear's Spec Review Agent on the issue.
**Why:** Spec must be agent-reviewed before human approval and launch.

## 9. Approved issue waiting to launch

**Match:** Linear issue status is "Approved" AND no current branch matches the issue prefix.

**Recommend:** `/launch PROJ-XXX`
**Why:** Issue is human-approved and ready to enter Building.

## 10. Phase in flight, multiple candidates

**Match:** Multiple Linear issues are in "Building" or "In Progress" simultaneously.

**Recommend:** `/linear-status`
**Why:** Multiple in-flight issues — pick the one to work on from the board view.

## 11. Fallback

**Match:** No prior rule matched.

**Recommend:** `/linear-status`
**Why:** State didn't match any known rule — start from the board view.

---

## Adding rules

When adding a new rule:

1. Decide insertion order. Earlier = higher priority. Blocking conditions go first; ambiguous state goes last.
2. Make the matcher cheap. File presence > git log > Linear API call. Don't add a rule that requires expensive checks unless it's the only signal.
3. Keep the "why" to one line. If you can't, the rule is too complex — split it.
4. If the rule is project-specific, put it in `.claude/overrides/skills/pipekit-help/state-rules.md` instead of the upstream file.
