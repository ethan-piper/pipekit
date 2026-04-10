---
name: branch
description: Start any unit of work — creates worktree + branch + optional Linear link
---

# Branch Skill

Create a worktree-based branch for the project. Handles features, fixes, and hotfixes. Read `method.config.md` for the worktree prefix and project name.

## Triggers

- `/branch`
- "start a branch"
- "new branch"
- "start a feature"
- "start a fix"
- "start a hotfix"

## Command Options

```
/branch <name>              -> feature/ branch from dev
/branch --fix <name>        -> fix/ branch from dev
/branch --hotfix <name>     -> hotfix/ branch from main
/branch --linear PROJ-XX     -> link to Linear issue
/branch finish              -> clean up current worktree + branch
/branch list                -> show active worktrees
```

## Branch Type and Base Branch Logic

| Flag | Branch Prefix | Base Branch | Use Case |
|------|---------------|-------------|----------|
| (default) | `feature/` | `dev` | New features |
| `--fix` | `fix/` | `dev` | Bug fixes |
| `--hotfix` | `hotfix/` | `main` | Production hotfixes (skip dev/beta) |

## Steps

### 1. Parse Input

- Determine branch type from flags (default: feature)
- Extract name from remaining arguments
- Convert to kebab-case: lowercase, spaces to hyphens, strip special characters
- Check for `--linear PROJ-XX` flag

Example parsing:
- `/branch smart-add-panel` -> `feature/smart-add-panel` from `dev`
- `/branch --fix login-redirect` -> `fix/login-redirect` from `dev`
- `/branch --hotfix auth-crash` -> `hotfix/auth-crash` from `main`

### 2. Ensure Base Branch Is Current

```bash
# Determine base branch
BASE_BRANCH="dev"  # or "main" for --hotfix

git checkout "$BASE_BRANCH" 2>/dev/null || true
git pull origin "$BASE_BRANCH"
```

### 3. Create Worktree

```bash
WORKTREE_PATH="{worktree prefix from method.config.md}{kebab-name}"

# Create worktree with new branch
git worktree add "$WORKTREE_PATH" -b {prefix}{kebab-name}
```

### 4. Symlink Shared Config Files

Only symlink files that actually exist -- skip any that are missing without error.

```bash
MAIN_REPO="$(git rev-parse --show-toplevel)"

# MCP servers
ln -sf "$MAIN_REPO/.mcp.json" "$WORKTREE_PATH/.mcp.json"

# Environment variables
ln -sf "$MAIN_REPO/.env" "$WORKTREE_PATH/.env"

# App-specific env
[ -f "$MAIN_REPO/apps/web/.env.local" ] && \
  mkdir -p "$WORKTREE_PATH/apps/web" && \
  ln -sf "$MAIN_REPO/apps/web/.env.local" "$WORKTREE_PATH/apps/web/.env.local"

# Sentry CLI config
[ -f "$MAIN_REPO/.sentryclirc" ] && \
  ln -sf "$MAIN_REPO/.sentryclirc" "$WORKTREE_PATH/.sentryclirc"

# Claude Code local settings
[ -f "$MAIN_REPO/.claude/settings.local.json" ] && \
  ln -sf "$MAIN_REPO/.claude/settings.local.json" "$WORKTREE_PATH/.claude/settings.local.json"
```

### 5. Optional Linear Link

If `--linear PROJ-XX` was specified, update the Linear issue status to "In Progress".

### 6. Rename cmux Workspace

Rename the current cmux workspace so it reflects the new work context:

```bash
bash ~/.claude/scripts/cmux-workspace-name.sh "{kebab-name}"
```

This sets the workspace title to `{project} - {kebab-name}` (read project name from `method.config.md`). Skip silently if cmux is unavailable.

### 7. Confirm

```
Branch: {prefix}{kebab-name}
Worktree: {worktree prefix from method.config.md}{kebab-name}
Base: dev (or main for hotfix)

To start working:
  cd {worktree prefix from method.config.md}{kebab-name} && claude

When done:
  /branch finish
```

## Finish Subcommand

`/branch finish` cleans up the current worktree and branch.

### Steps

1. Detect current worktree context
2. Check branch status:
   - Uncommitted changes -> warn and ask to commit or stash
   - Unpushed commits -> warn and ask to push
   - Open PR -> show PR status
   - Merged -> safe to clean up
3. Offer cleanup options:
   - Delete worktree + local branch + remote branch (if merged)
   - Keep branch but remove worktree
   - Cancel
4. Execute cleanup:
   ```bash
   # From main repo (not the worktree being deleted)
   git worktree remove "$WORKTREE_PATH"
   git branch -d {branch-name}  # only if merged
   git push origin --delete {branch-name}  # only if merged and remote exists
   ```

## List Subcommand

`/branch list` shows all active worktrees:

```bash
git worktree list
```

## Error Handling

- Branch already exists: offer to check it out in a new worktree
- Worktree path already exists: warn and suggest a different name
- Not on expected base branch: warn but proceed
