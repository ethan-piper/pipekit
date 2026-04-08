# Git & Deployment

> For the full development pipeline, see [method.md](../method.md).

**Last updated:** 2026-04-08
**Source of truth:** Your project's CLAUDE.md defines the authoritative branch strategy, release flow, and deployment mapping. This SOP provides the day-to-day procedures.

---

## Environments

Define your project's environments in `method.config.md`. Standard pattern:

| Environment | Branch | Purpose |
|---|---|---|
| **Production** | `main` | Live, public |
| **Beta** | `beta` | Pre-release, password-protected |
| **Dev** | `dev` | Active development, team-only |
| **Preview** | PR branches | Per-PR preview URLs |

---

## Branch Structure

```
main (production)
beta (pre-release)
dev  (active development)
  └── feature/*, fix/*   → Preview URLs
```

### Branch Naming

| Prefix | Base Branch | Purpose |
|--------|-------------|---------|
| `feature/` | `dev` | New functionality |
| `fix/` | `dev` | Bug fixes |
| `hotfix/` | `main` | Urgent production fixes |

### Branch Protection

| Branch | Rules |
|---|---|
| `main` | Protected. Requires PR, CI passing. No direct pushes. |
| `beta` | Protected. Requires PR + CI passing. No direct merges. |
| `dev` | Default branch for PRs. CI runs on all PRs targeting dev. |

---

## Release Flow

**Core principle: every step forward is a PR. No direct merges between long-lived branches.** (Exception: hotfix cherry-picks back to dev and beta are direct pushes.)

**Normal flow:** `feature/*` → PR to `dev` → PR to `beta` → PR to `main`

Each project defines its own promotion skills. After merge, issues transition in Linear:
- Merge to beta → issues move to **UAT**
- Merge to main → issues move to **Done**

**Hotfix flow:** `hotfix/*` → PR to `main` → cherry-pick back to `dev` and `beta`

**Bug found in beta:** Fix on `fix/*` from `dev`, PR to `dev`, re-promote `dev` → `beta`. Do not fix directly on `beta`.

---

## Worktrees

All feature/fix/hotfix work uses git worktrees, not branch switching in the main repo. The worktree prefix is defined in `method.config.md`.

```
~/Projects/
├── {project}/                          <- Main repo (stays on dev or main)
├── {project}-feature-ai-budget/        <- Worktree for feature work
├── {project}-fix-auth-redirect/        <- Worktree for a bug fix
└── {project}-hotfix-typo/              <- Worktree for a hotfix
```

All worktrees share the same git history, remotes, and object store — they're lightweight, not full clones.

### Creating a Worktree

Use the `/branch` skill for the full workflow (creates worktree + branch + optional Linear link):

```
/branch feature-name
/branch --fix bug-name
/branch --hotfix urgent-fix
```

### Managing Worktrees

```bash
git worktree list                             # List active worktrees
git worktree remove ../project-feature-name   # Remove after merge
```

### Rules

- Each branch can only be checked out in **one** worktree at a time
- Main worktree stays on `dev` or `main`, not feature branches
- Run dependency install in each new worktree
- Clean up worktrees after branches are merged

---

## Workflow: Feature Development to Production

### Step 1: Create Feature Branch

```
/branch feature-name
```

### Step 2: Develop

Write code on the feature branch. Include database migrations if needed.

### Step 3: Test on Preview

Push branch to get a preview URL. Every push updates the preview automatically.

### Step 4: Open PR to Dev

Run pre-deploy gate, then create PR:
```
/g-promote-dev   (or your project's equivalent)
```

### Step 5: Merge to Dev

PR is reviewed, approved, and merged. Feature available on dev.

Clean up: `/branch finish` from within the worktree.

### Step 6: Promote to Beta

PR from `dev` → `beta`. After merge, referenced Linear issues move to **UAT**.

### Step 7: Deploy to Production

PR from `beta` → `main`. After merge, referenced Linear issues move to **Done**.

### Verification

After any promotion, verify the deployment (smoke tests, health check).

---

## Hotfix Procedure

```bash
# 1. Create hotfix
/branch --hotfix describe-the-fix

# 2. Fix, commit, push, PR to main

# 3. After merge, cherry-pick back to dev and beta immediately
git checkout dev && git pull && git cherry-pick <hash> && git push origin dev
git checkout beta && git pull && git cherry-pick <hash> && git push origin beta

# 4. Clean up
/branch finish
```

---

## Commit Messages

```
{type}({scope}): {description}
```

| Type | When |
|------|------|
| `feat` | New feature |
| `fix` | Bug fix |
| `style` | CSS/visual changes |
| `refactor` | Code restructuring |
| `perf` | Performance improvement |
| `chore` | Maintenance, config |
| `docs` | Documentation |
| `test` | Tests |

Include issue IDs in commit messages: `feat(grid): add column definitions ({PREFIX}-42)`

---

## Rollback

### App Rollback

Use your hosting platform's rollback feature (e.g., `vercel rollback [deployment-url]`).

### Database Rollback

Migrations are forward-only. To undo: create a new migration that reverses the changes and deploy through the normal flow.

---

## Golden Rules

1. **Every step forward is a PR.** No direct merges between long-lived branches.
2. **Main is always deployable.** Only merge tested, validated code.
3. **All PRs target dev** (except hotfixes, which target main).
4. **Use the promotion skills.** They automate pre-deploy gates and Linear transitions.
5. **Test on preview before opening a PR.**
6. **Commit often, push when stable.** Small commits are easier to debug.
7. **Never force push to main.** Use `--force-with-lease` on feature branches only.
8. **Write meaningful commit messages.** Follow the type(scope) format.
9. **Cherry-pick hotfixes back immediately.** Both dev and beta, verified clean.
