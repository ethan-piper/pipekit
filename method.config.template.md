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
| Ideas | `` |
| Future Waves | `` |
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

## Environments (optional)

| Environment | URL | Branch |
|-------------|-----|--------|
| Production | | `main` |
| Beta | | `beta` |
| Dev | | `dev` |

## Pre-Deploy Gate

Commands that must pass before any deployment. Adjust per project stack.

```bash
pnpm turbo run check-types
pnpm turbo run lint
pnpm turbo run test
```
