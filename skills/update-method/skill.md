---
name: update-method
description: Sync the latest Pipekit method into the current project — pull skills, SOPs, and templates
---

# Update Method Skill

Pull the latest Pipekit method repo content into the current project. Updates portable skills, SOPs, and templates without touching project-specific files.

## Triggers

- `/update-method`
- "sync method"
- "update method"
- "pull method updates"

## Arguments

| Argument | What it does |
|----------|--------------|
| (none) | Sync from main |
| `v1.0` | Sync from a specific tag |
| `--dry-run` | Show what would change without applying |
| `--push` | After syncing, also push improvements back to the method repo (see Phase 3) |

## Execution Steps

### Phase 1 — Pull Updates Into This Project

1. Check if `scripts/sync-method.sh` exists in the current project
   - If not: copy it from `~/Projects/pipekit/scripts/sync-method.sh`
2. Run the sync script:
   ```bash
   ./scripts/sync-method.sh ${tag_or_branch}
   ```
3. Show what changed:
   - New skills added
   - Skills updated
   - SOPs updated
   - Templates updated
4. If `method.config.md` doesn't exist, warn: "No method.config.md found. Run /startup to configure."

### Phase 2 — Verify

1. Check that all portable skills are present in `.claude/skills/`
2. Check that `method.config.md` exists and has Linear state IDs filled in
3. Report any skills that reference `method.config.md` values that are still TBD
4. Show summary:

```
## Method Sync Complete

Updated from: pipekit @ {ref}

Skills: {N} synced, {M} unchanged
SOPs: {N} synced
Templates: {N} synced

Warnings:
  - method.config.md: Linear state IDs not yet configured
  - Skill X references {value} which is TBD
```

### Phase 3 — Push Improvements Back (--push)

When invoked with `--push`, this mode captures improvements made to portable skills *in the current project* and pushes them back to the method repo.

1. Compare each portable skill in `.claude/skills/` against the method repo version at `~/Projects/pipekit/skills/`
2. For each skill that differs:
   - Show the diff
   - Ask: "Push this change back to pipekit? (y/n/edit)"
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

**Important:** Never push project-specific content (method.config.md, .claude/rules/, project-specific skills) to the method repo. Only push changes to files that originated from the method repo.

## What Gets Synced (Pull)

| Source (method repo) | Destination (this project) | Notes |
|---------------------|---------------------------|-------|
| `skills/*/` | `.claude/skills/*/` | Only portable skills — won't delete project-specific skills |
| `sop/` | `method/sop/` | Full replace |
| `templates/` | `method/templates/` | Full replace |
| `method.md` | `method/method.md` | Full replace |
| `STARTUP.md` | `method/STARTUP.md` | Full replace |
| `METHOD_IMPROVEMENTS.md` | `method/METHOD_IMPROVEMENTS.md` | Full replace |

## What Never Gets Synced

| File | Why |
|------|-----|
| `method.config.md` | Project-specific — your Linear IDs, team name, etc. |
| `.claude/rules/` | Project coding conventions |
| `.claude/skills/{project-specific}/` | Stack-specific skills |
| `.vbw-planning/` | Project state |
| `method/decisions/` | Project-specific ADRs |
| `CLAUDE.md` | Project-specific |

## Related

- `/startup` — initial project bootstrap (runs sync as part of Phase 3)
- `scripts/sync-method.sh` — the underlying sync script
- Method repo: `~/Projects/pipekit/` or `github.com/YOUR_ORG/pipekit`
