# Method Configuration

Project-specific values that portable skills read at runtime. Copy this file to your project root as `method.config.md` and fill in your values.

## Project

| Key | Value |
|-----|-------|
| **Project name** | `your-project` |
| **Project display name** | `Your Project` |
| **Worktree prefix** | `~/Projects/your-project-` |
| **Session logs path** | `Logs/Sessions/` |
| **Strategy docs path** | `Strategy/` |
| **Changelog path** | _(optional: path to in-app changelog JSON)_ |

## Linear

| Key | Value |
|-----|-------|
| **Workspace slug** | `your-workspace` |
| **Team name** | `YourTeam` |
| **Team ID** | `00000000-0000-0000-0000-000000000000` |
| **Issue prefix** | `XXX` |

### Workflow State IDs

Skills use these IDs to transition issues. Get them from Linear API or the Linear UI (Settings > Workflow).

| State | ID |
|-------|-----|
| Triage | `` |
| Ideas | `` |
| Future Phases | `` |
| On Deck | `` |
| Needs Spec | `` |
| Specced | `` |
| Approved | `` |
| Building | `` |
| In Progress | `` |
| UAT | `` |
| Done | `` |
| Canceled | `` |
| Duplicate | `` |

## Slack (optional)

| Key | Value |
|-----|-------|
| **Session channel ID** | _(channel for end-session posts)_ |

## Git Architecture

Choose a branching model during `/startup`. This decision determines your environments, promotion skills, and release flow.

**Model:** `two-tier` | `three-tier`

### Two-Tier (dev → main)

Best for: solo dev, small teams, projects where preview URLs replace a staging environment.

| Environment | Branch | Purpose |
|-------------|--------|---------|
| Production | `main` | Live |
| Dev | `dev` | Active development |
| Preview | PR branches | Per-PR preview URLs |

**Release flow:** `feature/*` → PR to `dev` → PR to `main`
**Promotion skills needed:** `/g-promote-dev`, `/g-promote-main`
**Linear transitions:** merge to `main` → issues move to Done

### Three-Tier (dev → beta → main)

Best for: teams with QA, projects needing a stable UAT environment, regulated industries.

| Environment | Branch | Purpose |
|-------------|--------|---------|
| Production | `main` | Live |
| Beta | `beta` | Pre-release UAT, password-protected |
| Dev | `dev` | Active development |
| Preview | PR branches | Per-PR preview URLs |

**Release flow:** `feature/*` → PR to `dev` → PR to `beta` → PR to `main`
**Promotion skills needed:** `/g-promote-dev`, `/g-promote-beta`, `/g-promote-main`
**Linear transitions:** merge to `beta` → issues move to UAT; merge to `main` → issues move to Done

### Environments

Fill in URLs after deployment setup.

| Environment | URL | Branch |
|-------------|-----|--------|
| Production | | `main` |
| | | |

## Strategy Docs

Define which strategy docs this project maintains. `/strategy-create` generates initial versions; `/strategy-sync` keeps them current after features ship.

| Doc | File | Purpose | Audience |
|-----|------|---------|----------|
| Conceptual Overview | `Strategy/ConceptualOverview.md` | What the product does in plain language | Stakeholders |
| Technical Architecture | `Strategy/TechnicalArchitecture.md` | System design, schema, APIs, patterns | Developers |

Add rows as needed. Common additions:

| Doc | File | Purpose | Audience |
|-----|------|---------|----------|
| Permissions | `Strategy/Permissions.md` | Auth, roles, RLS, access control | Developers, Admins |
| UX Reference | `Strategy/UXReference.md` | UI patterns, shortcuts, onboarding | Developers, Support |
| Workflow Examples | `Strategy/WorkflowExamples.md` | Step-by-step user scenarios | All |
| Data Model | `Strategy/DataModel.md` | Schema, relationships, calculations | Developers |

## Pre-Deploy Gate

Commands that must pass before any deployment. Adjust per project stack.

```bash
pnpm turbo run check-types
pnpm turbo run lint
pnpm turbo run test
```
