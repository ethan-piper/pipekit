---
name: pipekit-update
description: Pull the latest Pipekit skills, SOPs, and templates from GitHub into the current project
---

# Pipekit Update Skill

You are a method sync coordinator. Your job is to pull the latest Pipekit content from GitHub into the current project — skills, SOPs, and templates — without touching project-specific files.

## Triggers

- `/pipekit-update`
- `/update-method`
- "update pipekit"
- "sync pipekit"
- "pull method updates"

## Arguments

| Argument | What it does |
|----------|--------------|
| (none) | Sync from main |
| `v1.0` | Sync from a specific tag |
| `--dry-run` | Show what would change without applying |
| `--push` | Push improvements back to the method repo (requires local clone — see Phase 4) |

## Execution Steps

### Phase 1 — Ensure Sync Script Exists

Check if `scripts/sync-method.sh` exists in the current project.

- **If it exists:** proceed to Phase 2.
- **If not:** fetch it from GitHub:

```bash
mkdir -p scripts
curl -fsSL https://raw.githubusercontent.com/ethan-piper/pipekit/main/scripts/sync-method.sh -o scripts/sync-method.sh
chmod +x scripts/sync-method.sh
```

No local clone of Pipekit is needed — the sync script pulls directly from GitHub.

### Phase 2 — Pull Updates

Run the sync script:

```bash
./scripts/sync-method.sh ${tag_or_branch}
```

The sync script clones the Pipekit repo from GitHub to a temp directory, copies content into the project, and cleans up automatically.

Show what changed:
- New skills added
- Skills updated
- SOPs updated
- Templates updated

If `method.config.md` doesn't exist, warn: _"No method.config.md found. Run `/startup` to configure."_

### Phase 3 — Verify

1. Check that all portable skills are present in `.claude/skills/`
2. Check that `method.config.md` exists and has Linear state IDs filled in
3. Report any skills that reference `method.config.md` values that are still TBD
4. Show summary:

```
## Pipekit Update Complete

Updated from: pipekit @ {ref}

Skills: {N} synced, {M} unchanged
SOPs: {N} synced
Templates: {N} synced

Warnings:
  - method.config.md: Linear state IDs not yet configured
  - Skill X references {value} which is TBD

Restart Claude Code to load updated skills.
```

**Important:** Remind the user to restart Claude Code after syncing so updated skills are loaded.

### Phase 4 — Push Improvements Back (--push only)

When invoked with `--push`, this mode captures improvements made to portable skills *in the current project* and pushes them back to the method repo.

**Requires a local clone** at `~/Projects/pipekit/` (or wherever `METHOD_REPO_LOCAL` points). If no local clone exists, explain:

_"The `--push` flag requires a local clone of Pipekit to stage changes. Run:"_
```bash
git clone https://github.com/ethan-piper/pipekit.git ~/Projects/pipekit
```

If a local clone exists:

1. Compare each portable skill in `.claude/skills/` against the method repo version at `~/Projects/pipekit/skills/`
2. For each skill that differs:
   - Show the diff
   - Ask: _"Push this change back to pipekit? (y/n/edit)"_
3. For approved changes:
   - Copy the updated skill to `~/Projects/pipekit/skills/`
   - Stage the changes in the method repo
4. Also check for changes to:
   - `method/sop/` → `~/Projects/pipekit/sop/`
   - `method/templates/` → `~/Projects/pipekit/templates/`
   - `method/method.md` → `~/Projects/pipekit/method.md`
   - `method/STARTUP.md` → `~/Projects/pipekit/STARTUP.md`
5. After all changes are staged, offer to commit and push:
   ```
   {N} files updated in pipekit.

   Commit and push? (y/n)
   ```
6. If yes: commit with message `feat(method): sync improvements from {project name}` and push to origin main

**Never push project-specific content** (method.config.md, .claude/rules/, project-specific skills) to the method repo.

## What Gets Synced (Pull)

| Source (GitHub) | Destination (this project) | Notes |
|-----------------|---------------------------|-------|
| `skills/*/` | `.claude/skills/*/` | Only portable skills — won't delete project-specific skills |
| `sop/` | `method/sop/` | Full replace |
| `templates/` | `method/templates/` | Full replace |
| `method.md` | `method/method.md` | Full replace |
| `GUIDE.md` | `method/GUIDE.md` | Full replace |
| `STARTUP.md` | `method/STARTUP.md` | Full replace |

## What Never Gets Synced

| File | Why |
|------|-----|
| `method.config.md` | Project-specific — your Linear IDs, team name, etc. |
| `.claude/rules/` | Project coding conventions |
| `.claude/skills/{project-specific}/` | Stack-specific skills |
| `.vbw-planning/` | Project state |
| `CLAUDE.md` | Project-specific |

## Related

- `/startup` — initial project bootstrap (runs sync as part of setup)
- `scripts/sync-method.sh` — the underlying sync script
- Pipekit repo: [github.com/ethan-piper/pipekit](https://github.com/ethan-piper/pipekit)
