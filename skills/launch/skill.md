---
name: launch
description: Formalized trigger to plan and execute a specced Linear issue through VBW or the batch runner
---

# Launch Skill

You are a launch gate controller. Your job is to transition a human-approved Linear issue from spec to execution. Read `method.config.md` for project context. You validate readiness gates, route by complexity, manage Linear status transitions, and produce a shippable feature or queue it for batch processing.

## Triggers

- `/launch PROJ-XXX`
- `/launch --milestone WP-1`
- `/launch --project "P1. Foundation Fixes"`

## Arguments

| Argument | What it does |
|----------|--------------|
| `PROJ-XXX` | Launch a single issue |
| `--milestone <name>` | Launch all ready issues in a milestone |
| `--project <name>` | Launch all ready issues in a project |
| `--dry-run` | Validate gates and show routing plan without executing |
| `--force` | Skip milestone readiness gate (use with caution) |

---

## Gate Model: Hybrid (Option C)

All issues in the same milestone must be at least **Specced** (agent-reviewed) before any issue in that milestone can be launched. Human approval can happen rolling — you can launch approved issues while siblings are still in human review.

**Rationale:** Ensures no issue is launched blind. A later spec could change assumptions that affect earlier work. The spec gate catches this before execution starts.

---

## Execution Steps

### Step 1 — Fetch and Validate Issue

1. Fetch the issue via `mcp__linear-server__get_issue` with `includeRelations: true`
2. Validate the issue has:
   - A `## Light Spec` or `## Acceptance Criteria` section in the description
   - Status is **Approved** ({Approved state ID from method.config.md}) or **Specced** with human approval noted
3. If no spec/AC found: stop and report `"PROJ-XXX has no spec or AC. Run /light-spec PROJ-XXX first."`
4. If status is before Approved: stop and report `"PROJ-XXX is in {status}. Move to Approved in Linear before launching."`

### Step 2 — Check Dependencies

1. Read `blocked_by` relations from the issue
2. For each blocker, check its status via `mcp__linear-server__get_issue`
3. If any blocker is NOT in **Done** ({Done state ID from method.config.md}): stop and report `"PROJ-XXX is blocked by PROJ-YYY ({status}). Resolve blockers first."`

### Step 3 — Milestone Readiness Gate

1. Identify the issue's milestone (if any) via the issue's milestone field
2. If the issue belongs to a milestone:
   - Fetch all sibling issues in that milestone via `mcp__linear-server__list_issues` filtered by milestone
   - Check that ALL sibling issues are at least in **Specced** ({Specced state ID from method.config.md}) or later state
   - If any sibling is in Needs Spec, On Deck, or earlier: stop and report:
     ```
     Milestone gate failed: {milestone name}
     
     Not yet specced:
       - PROJ-YYY — {title} ({status})
       - PROJ-ZZZ — {title} ({status})
     
     All issues in a milestone must be at least Specced before any can launch.
     Run /light-spec on the above issues, or use --force to bypass.
     ```
3. If `--force` is passed, skip this gate with a warning: `"Milestone gate bypassed. Proceeding at your discretion."`
4. If the issue has no milestone, skip this gate.

### Step 4 — Determine Complexity and Route

1. Read the `## Light Spec` section and extract the `**Complexity:**` field
2. Route based on complexity:

| Complexity | Route | What happens |
|-----------|-------|--------------|
| **Low** (~2-4h) | `/linear-todo-runner` | Issue queued for batch execution. AC is the plan. |
| **Medium** (~6-10h) | VBW Lead → Dev → QA | Full planning cycle with PLAN.md |
| **High** (~12-20h+) | VBW Lead → Dev → QA | Full planning cycle, likely multi-task |

3. If no complexity field found, ask the user: `"No complexity rating found. Route as Low (batch runner) or Medium/High (VBW planning)?"`

### Step 5 — Rename cmux Workspace

Rename the current cmux workspace to reflect the launched issue:

```bash
bash ~/.claude/scripts/cmux-workspace-name.sh "PROJ-XXX"
```

This sets the workspace title to `{project} - PROJ-XXX` (read project name from `method.config.md`). Skip silently if cmux is unavailable.

### Step 6 — Move to Building

1. Move issue to **Building** ({Building state ID from method.config.md}) via `mcp__linear-server__save_issue`
2. Post a Linear comment via `mcp__linear-server__save_comment`:
   ```
   **Launch:** Execution started.
   - Route: {VBW | Batch Runner}
   - Complexity: {Low | Medium | High}
   - Gates passed: spec ✓, dependencies ✓, milestone ✓
   ```

### Step 7a — Low Complexity: Queue for Batch Runner

1. Confirm the issue has a complete `## Acceptance Criteria` section
2. Inform the user: `"PROJ-XXX queued for batch execution. Run /linear-todo-runner to process, or it will be picked up on next runner invocation."`
3. **Done.** The `/linear-todo-runner` skill handles execution from here.

### Step 7b — Medium/High Complexity: VBW Planning

1. Read the full issue description (spec + AC)
2. Spin up the **VBW Lead Agent** (`vbw:vbw-lead`) via the Agent tool:
   ```
   Agent(
     subagent_type: "vbw:vbw-lead",
     description: "Plan PROJ-XXX: {title}",
     prompt: "Create a PLAN.md for PROJ-XXX based on the following approved spec from Linear:
     
     {full issue description}
     
     Read CLAUDE.md for project conventions. If the spec involves UI work, read Strategy/DesignDirection.md for visual design guidance. Place the plan in .vbw-planning/phases/{phase-slug}/
     The spec has been human-approved — do not change scope or decisions.
     Decompose into atomic tasks with verify/done criteria derived from the AC."
   )
   ```
3. After the lead agent returns, run the **plan-reviewer** agent:
   ```
   Agent(
     subagent_type: "plan-reviewer",
     description: "Review plan for PROJ-XXX",
     prompt: "Review the PLAN.md just created for PROJ-XXX. 
     Stress-test scope, dependencies, success criteria, and risks.
     The spec is: {brief spec summary}"
   )
   ```
4. Present the plan and review to the user for approval
5. If user approves, proceed to Step 8
6. If user requests changes, iterate on the plan

### Step 8 — VBW Execution

1. Spin up the **VBW Dev Agent** (`vbw:vbw-dev`) for each task in the approved plan:
   ```
   Agent(
     subagent_type: "vbw:vbw-dev",
     description: "PROJ-XXX task N: {task title}",
     prompt: "Execute task N from the plan at {plan path}.
     Read CLAUDE.md for conventions. Atomic commit per task.
     Include PROJ-XXX in all commit messages."
   )
   ```
2. After each task completes, post a Linear comment with progress:
   ```
   **Build progress:** Task {N}/{total} complete — {task title}
   ```

### Step 9 — VBW QA

1. After all tasks complete, spin up the **VBW QA Agent** (`vbw:vbw-qa`):
   ```
   Agent(
     subagent_type: "vbw:vbw-qa",
     description: "Verify PROJ-XXX: {title}",
     prompt: "Verify PROJ-XXX against the acceptance criteria in the spec.
     Use goal-backward methodology. Check each AC item.
     Run the pre-deploy gate: pnpm turbo run check-types && pnpm turbo run lint && pnpm turbo run test"
   )
   ```
2. If QA passes: proceed to Step 10
3. If QA fails: return to Step 8 for the failing tasks, with QA feedback

### Step 10 — Move to UAT

1. Move issue to **UAT** ({UAT state ID from method.config.md}) via `mcp__linear-server__save_issue`
2. Post a Linear comment:
   ```
   **Build complete.** Moved to UAT.
   - All {N} tasks complete
   - QA: passed
   - Pre-deploy gate: ✓ types, ✓ lint, ✓ test
   - Branch: {branch name}
   
   Ready for human acceptance testing.
   ```
3. Inform the user:
   ```
   PROJ-XXX is ready for UAT.
   
   Test with: /g-test-vercel (pushes branch, returns preview URL)
   Accept with: move to Done in Linear, then /g-promote-dev
   Reject with: describe what's wrong and I'll re-enter execution
   ```

---

## Milestone/Project Batch Mode

When invoked with `--milestone` or `--project`:

1. Fetch all issues in the milestone/project
2. Filter to **Approved** status only
3. Sort by priority (P1 first), then by dependency order
4. Run Steps 1-3 for each issue, collecting gate results
5. Present a launch plan:
   ```
   ## Launch Plan: WP-1 Foundation Fixes
   
   Ready to launch (3 issues):
     1. PROJ-200 — Design tokens [Low] → Batch Runner
     2. PROJ-201 — Supabase types [Low] → Batch Runner
     3. PROJ-202 — Calculation tests [Medium] → VBW
   
   Blocked (1 issue):
     - PROJ-203 — Realtime strategy (blocked by PROJ-200)
   
   Not approved (2 issues):
     - PROJ-204 — AI cost monitoring (Specced, awaiting approval)
     - PROJ-205 — Cache strategy (Needs Spec)
   
   Proceed? (y/n)
   ```
6. On confirmation, launch each ready issue sequentially (VBW) or queue all Low issues for the runner

---

## Linear Status Transitions

The `/launch` skill owns these transitions:

| Event | Status Change | Linear State ID |
|-------|--------------|-----------------|
| Launch starts | Approved → Building | {Building state ID from method.config.md} |
| Build + QA complete | Building → UAT | {UAT state ID from method.config.md} |
| QA fails | Stays in Building | — |
| Gate fails | Stays in Approved | — |

Downstream transitions (not owned by `/launch`):
- UAT → Done: `/g-promote-main` (after human acceptance + production release)
- UAT → Building: user rejects in UAT, re-enters execution

---

## Error Handling

- **No spec:** Stop. Direct to `/light-spec`.
- **Dependencies not met:** Stop. List blockers and their statuses.
- **Milestone gate fails:** Stop. List unspecced siblings. Offer `--force`.
- **VBW agent timeout:** Flag as stalled in Linear comment. Do not auto-kill.
- **Pre-deploy gate failure:** QA agent attempts fix. If unfixable after one retry, report failure and keep in Building.
- **Linear MCP unavailable:** Stop with clear error. Do not execute without status tracking.

---

## Common Drifts to Avoid

When you encounter these situations, take the safer path:

- **Launching without a passing gate** → Specs that don't pass the gate go back to `/light-spec`, not forward to execution.
- **Skipping the milestone gate** → The gate exists because later specs can change assumptions that affect earlier work. Only bypass with `--force` when the user explicitly requests it.
- **Low complexity without AC** → The batch runner needs acceptance criteria to execute. Every issue needs verifiable criteria regardless of complexity.
- **Launching despite unresolved blockers** → Blockers should be Done before launching. If a blocker looks ready but isn't marked Done, flag it for the user rather than proceeding.
- **Estimating complexity from the title** → Read the spec to determine complexity. Title-based estimates are unreliable.

---

## Relationship to Other Skills

| Skill | Relationship |
|-------|-------------|
| `/light-spec` | Produces the spec that `/launch` consumes. Run before `/launch`. |
| `/linear-todo-runner` | `/launch` queues Low-complexity issues for the runner. |
| `/branch` | VBW agents use `isolation: "worktree"` internally, not `/branch`. |
| `/g-test-vercel` | Used after `/launch` completes to test the built feature. |
| `/g-promote-dev` | Next step after UAT passes. |
| `/roadmap-review` | Run before `/launch` to validate the big picture. |

---

## Example Session

```
User: /launch PROJ-200

## Gate Check: PROJ-200 — Apply Design Tokens

  Spec: ✓ Light spec with AC (7 criteria)
  Dependencies: ✓ No blockers
  Milestone: ✓ WP-1 Foundation Fixes — all 5 siblings specced
  Complexity: Low (~2-4h)
  Route: Batch Runner

Moving to Building...
PROJ-200 queued for batch execution.
Run /linear-todo-runner to process.

---

User: /launch PROJ-88

## Gate Check: PROJ-88 — AG Grid Enterprise Migration

  Spec: ✓ Light spec with AC (12 criteria)
  Dependencies: ✓ PROJ-200 (Done), PROJ-201 (Done)
  Milestone: ✓ WP-2 AG Grid Migration — all 4 siblings specced
  Complexity: High (~16h)
  Route: VBW (Lead → Plan → Dev → QA)

Moving to Building...
Spinning up VBW Lead Agent...

[Plan created, reviewed, approved, executed, QA passed]

## PROJ-88 Build Complete — Moved to UAT

  Tasks: 8/8 complete
  QA: passed
  Pre-deploy: ✓ types, ✓ lint, ✓ test
  Branch: feature/wit-88-ag-grid

  Test with: /g-test-vercel
  Accept: move to Done → /g-promote-dev

---

User: /launch --milestone "WP-1: Foundation Fixes"

## Launch Plan: WP-1 Foundation Fixes

Ready to launch (4 issues):
  1. PROJ-200 — Design tokens [Low] → Batch Runner
  2. PROJ-201 — Supabase types [Low] → Batch Runner
  3. PROJ-202 — Calculation tests [Low] → Batch Runner
  4. PROJ-203 — Realtime strategy [Medium] → VBW

Not approved (1 issue):
  - PROJ-204 — AI cost monitoring (Specced)

Proceed? (y/n)
```
