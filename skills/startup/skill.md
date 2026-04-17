---
name: startup
description: Orchestrate full project bootstrap — concept through first phase, with infrastructure setup
---

# Startup Skill

You are a project bootstrap orchestrator. Your job is to chain pre-pipeline skills with infrastructure setup, creating a complete project from idea to first phase ready for speccing.

## Triggers

- `/startup`
- "start the project setup"
- "bootstrap this project"

## Startup Tracker

The first thing `/startup` does is create (or read) a **`{folder-name}-startup.md`** file in the project root. This file persists across sessions — it's how `/startup` knows where you left off, what decisions were made, and what's still open.

**On first run:** Create the file using the template below. Derive `{folder-name}` from the project directory name (e.g., `~/Projects/the-vault/` → `the-vault-startup.md`).

**On subsequent runs:** Read the file first. Use it to restore context — current step, decisions made, blockers, project summary. Skip re-asking questions that are already answered in the tracker.

**After every step:** Update the tracker immediately — mark the step complete, record any decisions or notes, update the "Current step" field. Do not batch updates.

### Tracker Template

```markdown
# {Project Name} — Startup Tracker

**Started:** {date}
**Last updated:** {date}
**Current step:** {step number — name}

## Progress

| # | Step | Status | Completed |
|---|------|--------|-----------|
| 1 | Concept | ⬜ Not started | — |
| 2 | Define | ⬜ Not started | — |
| 3 | Tech Stack | ⬜ Not started | — |
| 4 | Infrastructure | ⬜ Not started | — |
| 5 | Strategy Docs | ⬜ Not started | — |
| 5.5 | Design Direction | ⬜ Not started | — |
| 6 | Method Sync | ⬜ Not started | — |
| 7 | VBW Init | ⬜ Not started | — |
| 8 | Roadmap | ⬜ Not started | — |
| 9 | Project Skills | ⬜ Not started | — |
| 10 | CLAUDE.md & Rules | ⬜ Not started | — |
| 11 | Phase Plan | ⬜ Not started | — |
| 12 | Validate | ⬜ Not started | — |

## Project Summary

{Filled in after Step 1 — brief description of the project}

## Decisions

### Tech Stack (Step 3)
| Decision | Choice |
|----------|--------|
| Framework | |
| Language | |
| Database | |
| Auth | |
| Deployment | |
| CSS/UI | |
| Testing | |
| Git model | |

### Linear (Step 4)
| Key | Value |
|-----|-------|
| Workspace | |
| Team | |
| States configured | No |
| State IDs populated | No |

### Infrastructure (Step 4)
| Key | Value |
|-----|-------|
| Repo | |
| Database | |
| Deployment | |

## Step Notes

{After each step, record what happened — context, decisions, anything
the next session needs to know. This is the "memory" that makes
/startup resumable across sessions.}

## Blockers & Open Questions

{Anything unresolved that needs attention before proceeding.}
```

### Status Values

Use these in the Progress table:
- `⬜ Not started` — hasn't begun
- `🔄 In progress` — started but not complete (session ended mid-step)
- `⏭️ Skipped` — output already existed, user chose to skip
- `✅ Done` — complete, with date

---

## Execution

Each step checks if its output already exists and offers to skip — making `/startup` resumable. If you stop after Step 4, re-running picks up at Step 5.

**Before any step:** Read `{folder-name}-startup.md` to restore context.
**After every step:** Update `{folder-name}-startup.md` with status, decisions, and notes.

### Step 1 — Concept

**Check:** Does `concept-brief.md` exist?
- If yes: _"Concept brief exists. Review it, skip, or redo?"_
- If no: Run `/concept` (or `/concept --docs <path>` if the user has existing documents)

**Output:** `concept-brief.md` — validated project concept

### Step 2 — Define

**Check:** Does `project-definition.md` exist?
- If yes: _"Project definition exists. Review it, skip, or redo?"_
- If no: Run `/define`

**After this step, populate the Project section of `method.config.md`:**

```
| **Project name** | `{folder-name}` |
| **Project display name** | `{from project definition}` |
| **Worktree prefix** | `~/Projects/{folder-name}-` |
| **Session logs path** | `Logs/Sessions/` |
| **Strategy docs path** | `Strategy/` |
```

These values are now known from the concept brief and project definition. Write them immediately.

**Output:** `project-definition.md` — phases, roles, workflows, success criteria

### Step 3 — Tech Stack

**Check:** Does `CLAUDE.md` have a Stack section? Does the project have a `package.json` or equivalent?
- If yes: _"Tech stack appears configured. Skip or review?"_
- If no: Present the decision matrix interactively

Walk through tech stack decisions from `STARTUP.md` Step 2:
- Framework, language, database, auth, deployment, CSS/UI, testing
- Make recommendations based on project definition (from Step 2)
- **Do not decide for the user** — present options with trade-offs, wait for their call
- Record decisions for CLAUDE.md and `method.config.md`

**Git architecture decision** — present the branching model options:

| Model | When to Use |
|-------|-------------|
| **Two-tier** (`dev` → `main`) | Solo dev, small teams, preview URLs suffice for UAT |
| **Three-tier** (`dev` → `beta` → `main`) | Teams with QA, need stable UAT environment, regulated industries |

**Update `method.config.md` immediately:**
- Set `## Git Architecture` → **Model** to `two-tier` or `three-tier`
- Fill in the Environments table with the branches (URLs come in Step 4)

This decision determines:
- Which environments to configure in Step 4
- Which promotion skills to create in Step 9 (no `/g-promote-beta` needed for two-tier)
- How Linear status transitions work on merge (see `sop/Git_and_Deployment.md`)

**Output:** Tech stack + git architecture decisions recorded in `method.config.md`

### Step 4 — Infrastructure Setup

Walk through setup checklist from `STARTUP.md` Step 3, in order. Skip steps already done.

1. **Repository** — create GitHub repo, initialize framework in `src/`, TypeScript strict, .gitignore, .env.example
2. **Monorepo** (if applicable) — Turborepo, workspaces, shared config
3. **Database** — create project(s), initial schema, auth setup
4. **Deployment** — link to Vercel/equivalent, env vars, custom domains, preview deploys. Update the Environments table in `method.config.md` with URLs once deployed.
5. **Tooling** — ESLint, Vitest, Playwright, pre-deploy gate. Update the `## Pre-Deploy Gate` section of `method.config.md` with the actual commands for this project's stack.
6. **MCP Servers** — configure `.mcp.json` (Linear, GitHub, DB, browser, etc.)

**Tool and integration wiring:**

For **every service chosen in the tech stack** (database, deployment, auth, etc.), don't just set up the service — wire up the full development toolchain around it. For each service:

1. **Look up current setup instructions.** Use Context7 (`/mcp__Context7__resolve-library-id` → `/mcp__Context7__get-library-docs`) to check for the service's CLI, SDK, and MCP server documentation. If Context7 doesn't have it, check the service's official documentation via web search/fetch.

2. **Install the CLI** if one exists. Examples:
   - Supabase → `npx supabase init`, `supabase login`, `supabase link`
   - Vercel → `npx vercel link`
   - Stripe → `stripe login`
   - Prisma → `npx prisma init`

3. **Connect an MCP server** if one exists. Check:
   - The official MCP registry (`mcp__mcp-registry__search_mcp_registry` if available)
   - The service's own docs (many now ship MCP servers — Supabase, GitHub, Stripe, etc.)
   - For each MCP server found, install it:
     ```
     claude mcp add --transport {type} --scope {user|project} {server-name} {url-or-command}
     ```
   - Use `--scope user` for services shared across projects (GitHub, Supabase account-level)
   - Use `--scope project` for project-specific connections (project-specific DB, etc.)
   - Verify the connection works by calling a basic tool from the server

4. **Install SDK packages** the project will need:
   - Database client libraries (`@supabase/supabase-js`, `@prisma/client`, etc.)
   - Auth libraries (`@supabase/auth-helpers-nextjs`, `next-auth`, etc.)
   - Deployment SDKs if needed

5. **Configure environment variables:**
   - Add required env vars to `.env` (with actual values)
   - Add placeholder versions to `.env.example` (no secrets)
   - Document them in CLAUDE.md

6. **Verify the connection works** — run a basic test (fetch a table list, ping the API, etc.)

Record everything in the startup tracker under Step Notes — which CLIs were installed, which MCP servers were connected, which packages were added. This is the context a future session needs to understand the tooling landscape.

**Linear workspace setup:**

This is the most important infrastructure step — every downstream skill depends on Linear being correctly configured. Walk through it carefully.

**4a. Verify MCP connection**

Test that the Linear MCP server is connected by calling `mcp__linear-server__list_issues` (or any list tool). If it fails:
- _"Linear MCP isn't connected. Run this in your terminal and restart Claude Code:"_
  ```
  claude mcp add --transport http --scope user linear-server https://mcp.linear.app/mcp
  ```
- Then run `/mcp` in Claude Code to complete OAuth authorization.

**4b. Workspace and Team**

Ask: _"Do you already have a Linear workspace, or should we start fresh?"_

- **Existing workspace:** Ask for the workspace slug and team name. Verify by fetching issues.
- **New workspace:** Direct the user to [linear.app](https://linear.app/) to create one (free tier is fine). Then:
  - Ask them to create a team (e.g., the project name). Linear creates one by default during onboarding.
  - Record the workspace slug, team name, and team ID.

Fetch team details and populate `method.config.md`:
```
| **Workspace slug** | `{slug}` |
| **Team name** | `{team}` |
| **Team ID** | `{uuid}` |
| **Issue prefix** | `{PREFIX}` |
```

**4c. Workflow States**

Pipekit requires 12 workflow states plus Triage enabled. Linear workspaces start with defaults (Backlog, Todo, In Progress, Done, Canceled) that need to be replaced.

**Important:** Triage is NOT a workflow state — it's a setting. It must be enabled separately in Linear's team settings. The 12 workflow states below are what you create/configure in the Workflow section.

Colors are yours to choose. Pipekit defines the required state names and types — pick whatever colors work for your team.

Present the target configuration:

```
Pipekit requires Triage enabled + these 12 workflow states:

  ENABLE TRIAGE (Settings → Team → General):
    • Turn on "Triage" — this adds a Triage inbox, not a workflow state

  Backlog states:
    • Ideas                     (type: backlog)
    • Future Phases             (type: backlog)
    • On Deck                   (type: backlog)
    • Needs Spec                (type: backlog)

  Unstarted states:
    • Specced                   (type: unstarted)
    • Approved                  (type: unstarted)

  Started states:
    • In Progress               (type: started)
    • Building                  (type: started)
    • UAT                       (type: started)

  Completed states:
    • Done                      (type: completed)

  Canceled states:
    • Canceled                  (type: canceled)
    • Duplicate                 (type: canceled)
```

**Attempt to configure via MCP first.** Try creating workflow states programmatically. If the MCP tools support state creation/management, automate the full setup. If not, give the user step-by-step manual instructions:

_"Linear's workflow states need to be configured in the UI. Here's exactly what to do:"_

```
1. Enable Triage:
   Open Linear → Settings → Team Settings → {Team} → General
   Turn on "Triage" (this adds a Triage inbox for incoming issues)

2. Configure Issue Statuses:
   Open Linear → Settings → Team Settings → {Team} → Workflow → Issue Statuses

3. Remove default states that Pipekit doesn't use:
   - Remove "Backlog" (Pipekit uses Ideas/Future Phases/On Deck/Needs Spec instead)
   - Remove "Todo" (Pipekit uses Specced/Approved instead)
   - You can't delete states with issues — move any existing issues first

4. Create these states (in order, with these types):
   Choose whatever colors you like for each.

   BACKLOG section:
     + Ideas
     + Future Phases
     + On Deck
     + Needs Spec

   UNSTARTED section:
     + Specced
     + Approved

   STARTED section:
     + In Progress (usually exists by default)
     + Building
     + UAT

   COMPLETED section:
     ✓ Done (usually exists by default)

   CANCELED section:
     ✓ Canceled (usually exists by default)
     + Duplicate

5. Drag to reorder so they appear in the order listed above.
```

Ask the user to confirm when done: _"Let me know when the workflow states are configured and I'll fetch the IDs."_

**4d. Fetch State IDs**

After states are configured, fetch all workflow state IDs. Use the Linear MCP tools to list workflow states for the team, or guide the user to get them from Settings → Workflow (each state has a UUID visible in the URL when clicked).

Populate the Workflow State IDs table in `method.config.md`:

```
| State | ID |
|-------|-----|
| Triage | `{uuid}` |
| Ideas | `{uuid}` |
| Future Phases | `{uuid}` |
| On Deck | `{uuid}` |
| Needs Spec | `{uuid}` |
| Specced | `{uuid}` |
| Approved | `{uuid}` |
| Building | `{uuid}` |
| In Progress | `{uuid}` |
| UAT | `{uuid}` |
| Done | `{uuid}` |
| Canceled | `{uuid}` |
| Duplicate | `{uuid}` |
```

**Do not proceed past this step with empty state IDs.** Every downstream skill depends on these values.

**4e. Standard Labels**

Create the standard label taxonomy via `mcp__linear-server__save_issue` or equivalent label tools. If MCP doesn't support label creation, instruct manually:

```
Create these labels in Linear (Settings → Labels):

Type labels:
  Feature, Improvement, Bug, Research, Tech Debt, Chore

Flag labels:
  Quick Win, Blocked, Hotfix, Breaking Change

Audience labels:
  Client Request
```

Domain and Tier labels are project-specific — these get created during `/roadmap-create` based on the project's feature clusters and stages.

**4f. Verify Linear Setup**

Run a quick verification:
1. Fetch issues for the team — confirms MCP connection and team ID
2. Count workflow states — should be exactly 13
3. List labels — should include all Type and Flag labels
4. Confirm `method.config.md` has no empty state IDs

If anything is missing, loop back to the relevant sub-step.

**Output:** Working infrastructure — repo builds, deploys, pre-deploy gate passes, Linear workspace fully configured

### Step 5 — Strategy Docs

**Check:** Does `Strategy/` directory exist with docs?
- If yes: _"Strategy docs exist. Skip or review?"_
- If no: Run `/strategy-create`

**Output:** `Strategy/` directory with docs, `method.config.md` updated with doc manifest

### Step 5.5 — Design Direction

**Check:** Does `Strategy/DesignDirection.md` exist?
- If yes: _"Design direction exists. Skip or review?"_
- If no and project has a UI: walk through design preferences interactively

If the project has a user interface (web, mobile, desktop), capture design intent now — before any features are built. This ensures consistent aesthetics from the first UI work.

Walk through the template at `templates/strategy/design-direction.md`:

1. **Aesthetic direction** — ask: _"What feeling should this product convey? (e.g., clean and professional, playful and bold, minimal and refined)"_
2. **Inspiration** — ask: _"Any sites, apps, or screenshots that capture the look you want? Even rough direction helps."_
3. **Typography** — ask: _"Any font preferences? Or adjectives — geometric, rounded, editorial?"_
4. **Color & theme** — ask: _"Any colors in mind? Light or dark theme? Both?"_
5. **Motion** — ask: _"How much animation? Subtle transitions, or more expressive?"_
6. **Anti-patterns** — ask: _"Anything you specifically don't want? Generic dashboards, specific styles to avoid?"_

Write `Strategy/DesignDirection.md` with their answers. This doc is read by development agents and the `/frontend-design` skill during execution.

**If the project has no UI** (CLI tool, API-only, library): skip this step.

**Output:** `Strategy/DesignDirection.md` — design intent captured for build agents

### Step 6 — Method Sync

**Check:** Does `method/` directory exist? Are skills in `.claude/skills/`?
- If yes: _"Method already synced. Re-sync or skip?"_
- If no: Copy and run sync script

```bash
# Fetch sync script if it doesn't exist
if [ ! -f scripts/sync-method.sh ]; then
  mkdir -p scripts
  curl -fsSL https://raw.githubusercontent.com/ethan-piper/pipekit/main/scripts/sync-method.sh -o scripts/sync-method.sh
  chmod +x scripts/sync-method.sh
fi
./scripts/sync-method.sh
```

Fill in `method.config.md` with any remaining project-specific values.

**Output:** Method synced, config complete

### Step 7 — VBW Init

**Check:** Does `.vbw-planning/` exist?
- If yes: _"VBW already initialized. Skip or reinit?"_
- If no: Run `/vbw:init`

**Output:** `.vbw-planning/` scaffolded

### Step 8 — Roadmap

**Check:** Does `.vbw-planning/ROADMAP.md` have content?
- If it exists and was generated by **VBW** (`/vbw:init` creates one from codebase analysis): Run `/roadmap-create` anyway — it will **merge** strategy-derived requirements into VBW's phase structure rather than overwrite. This is expected and correct.
- If it exists and was already populated by `/roadmap-create`: _"Roadmap exists. Skip or redo?"_
- If no: Run `/roadmap-create`

**Important:** Do NOT run `/vbw:vibe` as an alternative to `/roadmap-create`. `/vbw:vibe` bypasses Linear, which is the whole point of Pipekit wrapping VBW. Pipekit's path is `/roadmap-create` → populates Linear → future VBW execution happens on Linear-tracked issues.

**Output:** ROADMAP.md populated (merged with VBW structure if present), Linear board seeded

### Step 9 — Project-Specific Skills

Based on the tech stack chosen in Step 3, identify which project-specific skills are needed (see `STARTUP.md` Step 4 for the mapping).

| If you use... | You need... |
|---------------|-------------|
| Vercel | `g-test-vercel`, `g-deploy` |
| Supabase/Postgres | `migrate` |
| Any DB | `reset-user` or equivalent |
| Monorepo with shared UI | `component` |
| Multiple environments | `g-promote-dev`, `g-promote-beta`, `g-promote-main` |

Create each skill with the user's input. Test after creation.

**Output:** Project-specific skills created and working

### Step 10 — CLAUDE.md & Rules

Update or create CLAUDE.md with all decisions made:
- Stack, conventions, structure, environments, common commands

Create `.claude/rules/` files based on the stack:
- `security.md` — auth patterns, env var rules
- `naming.md` — file naming, code naming, DB naming
- `patterns.md` — data layer, API routes, mutations
- `file-structure.md` — directory layout
- `tooling.md` — commands, CI, pre-deploy gate

**Final `method.config.md` review:** Read back to the user, confirm all fields populated, flag TBD values.

**Output:** CLAUDE.md and rules configured

### Step 11 — Phase Plan

**Check:** Does `.vbw-planning/PHASES.md` exist?
- If yes: _"Phase already planned. Skip or replan?"_
- If no: Run `/phase-plan`

**Output:** First phase defined, issues in "Needs Spec"

### Step 12 — Validate

Run `/roadmap-review` to validate the full setup:
- Concept brief exists
- Project definition exists
- Strategy docs match config
- ROADMAP.md populated
- Linear board seeded
- Current phase defined
- All checks pass

If any check fails, diagnose and fix before declaring setup complete.

**Output:** All validation checks pass — pipeline is ready

```
## Setup Complete

All steps passed. Your project is ready for the development pipeline.

Next steps:
  - /light-spec {PREFIX}-1 — start speccing the first issue
  - /phase-plan --status — check phase progress
  - /roadmap-review — full health check anytime
```

## Rules

- **Tracker first.** Create or read `{folder-name}-startup.md` before doing anything else. Update it after every step. This file IS the state of the startup process.
- **Documents, not terminal walls.** When a step produces a document (concept brief, project definition, strategy docs, etc.):
  1. **Write the file to disk first.** Don't dump the full content in the terminal.
  2. **Tell the user where it is:** _"Written to `concept-brief.md` — open it in your editor and review. Let me know what to change, or say 'approved' to continue."_
  3. **Give a brief summary** in the terminal (3-5 bullet points of what the document covers — enough to orient, not enough to substitute for reading it).
  4. **Wait for feedback.** The user may edit the file directly, give verbal instructions, or approve as-is.
  5. **If the user requests changes:** read the file, apply the edits, write it back, and point them to it again.
  This applies to every document-producing step. The terminal is for conversation and status updates. Documents live in files.
- **One step at a time.** Don't rush ahead. Confirm the user is ready before moving to the next step.
- **Show progress.** At each step transition, show what's been completed and what's next.
- **Decisions are the user's.** Present analysis, make recommendations, but never lock in a choice without explicit approval.
- **Skip what's done.** If a step's output already exists, acknowledge and offer to skip. Mark it `⏭️ Skipped` in the tracker.
- **Save as you go.** Update CLAUDE.md, method.config.md, Strategy docs, AND the tracker as decisions are made — don't batch to the end.
- **Clean up after decisions.** When the user chooses between alternatives (two-tier vs. three-tier, framework A vs. B, etc.), **remove or collapse the unchosen option** from the document. The chosen path should be clean and unambiguous. Specifically:
  1. Keep the chosen option's full detail in place.
  2. Remove the unchosen option's configuration blocks (environment tables, promotion skills, workflow details, etc.) so they don't look active.
  3. If the unchosen option has reference value, move it to a collapsed section at the bottom: `<!-- Not chosen: three-tier --> ... <!-- /Not chosen -->` — but only if it adds value. When in doubt, remove it entirely.
  This applies to `method.config.md`, `CLAUDE.md`, strategy docs, and any file where alternatives were presented. A document should never look like two conflicting decisions are both active.
- **App code lives in `src/`.** All application code (framework, components, API routes, etc.) goes in a `src/` subdirectory. The project root is reserved for Pipekit files (`method.config.md`, `concept-brief.md`, `project-definition.md`, `Strategy/`, `.vbw-planning/`, `method/`, `.claude/`), config files (`.gitignore`, `.env`, `package.json`, `tsconfig.json`), and scripts. This keeps Pipekit's methodology layer cleanly separated from the application. When initializing a framework (Next.js, Remix, etc.), configure it to use `src/` as the source directory.
- **Resumable.** The tracker + artifact checks make `/startup` fully resumable across sessions. A new session reads the tracker and picks up exactly where the last one stopped.
