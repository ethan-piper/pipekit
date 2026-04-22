---
name: end-session
description: End a work session by capturing reflections, committing work, and creating a session log
---

# End Session Skill

You are a session closer. Your job is to help the user close out a work session by capturing their reflections and creating a comprehensive session log. Read `method.config.md` for project context.

## Triggers

This skill is invoked when the user says:
- `/end-session`
- "end session"
- "handoff"
- "summarize session"
- "close session"

## Purpose

1. Automatically review and summarize what happened this session
2. Log session changes to `Strategy/Doc4_Changelog.md` as a running record
3. Offer a cumulative version bump (covering all work since the last version)
4. Capture the user's reflections
5. Commit and create a session log

---

## Execution Steps

### Step 0 — Branch Preflight

Session logs and `NEXT.md` are project-wide artifacts. If `/end-session` runs on a feature branch that later gets squash-merged and deleted, those artifacts get orphaned. Verify the branch state before doing anything else.

1. Detect the current branch and the project's default branch:
   ```bash
   CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
   MAIN_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo main)
   ```

2. If `CURRENT_BRANCH == MAIN_BRANCH`, skip to Step 1.

3. Otherwise, check PR state for the current branch:
   ```bash
   gh pr view --json state,mergedAt,url 2>/dev/null
   ```

   Three cases — present them as an AskUserQuestion-style choice:

   | PR state | Message | Choices |
   |----------|---------|---------|
   | **Merged** | "Your PR for `{branch}` is merged. The shutdown sequence normally switches to `{main}` before `/end-session` so session artifacts land there instead of orphaning on this branch." | `switch` (recommended) / `hold` |
   | **Open** | "PR for `{branch}` is still open: `{url}`. Merge it first, or hold to end the session on this branch anyway." | `hold` / `cancel` |
   | **No PR found** | "You're on `{branch}` but there's no PR for it. If this branch gets deleted later, your session log and NEXT.md will go with it." | `switch` / `hold` / `cancel` |

4. Handle the response:

   - **`switch`**: run
     ```bash
     git checkout "$MAIN_BRANCH"
     git pull --ff-only
     # Only delete the branch if the PR was merged
     if [ "$PR_STATE" = "MERGED" ]; then
       git branch -d "$CURRENT_BRANCH" 2>/dev/null || git branch -D "$CURRENT_BRANCH"
       git fetch --prune
     fi
     ```
     Then proceed to Step 1 on `main`.

   - **`hold`**: warn the user:
     > Ending session on `{branch}`. Session log and `NEXT.md` will live on this branch only. Cherry-pick them to `{main}` before deleting the branch to avoid orphans:
     > `git checkout {main} && git checkout {branch} -- Logs/Sessions/ NEXT.md && git commit -m "chore(log): preserve session artifacts"`
     
     Then proceed to Step 1.

   - **`cancel`**: stop here. The user handles the PR or branch state themselves and reruns `/end-session`.

---

### Step 1 — Auto-Review Session Work

Without asking the user anything yet, automatically:

1. Run `git log --oneline` and compare against the last session log in `Logs/Sessions/` to identify commits made this session
2. Summarize what was built/fixed/changed in plain language
3. Present a concise session summary to the user:

```markdown
## Here's what we did this session:

**Features / Changes:**
- [item]
- [item]

**Fixes:**
- [item]

**Other:**
- [item]

---
```

This summary is used for the changelog entry and session log. Confirm with the user or let them correct anything before proceeding.

---

### Step 2 — Log Session to Doc4_Changelog.md

Read `Strategy/Doc4_Changelog.md`. Append the session's work as an **unlocked / pending entry** under a `## Pending (Not Yet Versioned)` section at the top of the file (or add to it if it already exists):

```markdown
## Pending (Not Yet Versioned)

### Session: YYYY-MM-DD
- [change 1]
- [change 2]
- [change 3]
```

This creates a running log of all work since the last version bump. Do not create a new version number — just log the session work.

---

### Step 3 — Offer Cumulative Version Bump

Read `src/app/assets/changelog.json` to get the current version. Read the `## Pending` section of Doc4 to see all accumulated work since the last version.

Ask the user:

```markdown
**Want to publish a version update?**

Current version: vX.X.X
Work accumulated since last version:
- [session 1 items]
- [session 2 items]
- [this session's items]

Say **yes** to publish v X.X.Y — I'll draft the entry and update both changelogs.
Say **no** to keep accumulating (you can publish any time by saying "bump version").
```

**If yes:** Draft the version entry:
- Suggest a version number (patch bump by default, e.g. 2.6.3 → 2.6.4)
- Suggest a release name based on the theme of accumulated changes
- Draft a summary sentence and 3-6 highlights
- Show the draft and ask for approval / edits
- On approval:
  - Update `src/app/assets/changelog.json`: set new `currentVersion`, prepend new version object
  - Update `Strategy/Doc4_Changelog.md`: move `## Pending` items into a proper versioned section, clear the Pending section
  - **Deploy:** Changelog is deployed automatically when the next promotion to main merges. No manual deploy needed.

**If no:** Skip. The pending items remain in Doc4 for next time.

---

### Step 4 — Ask for Reflections

```markdown
## Session Wrap-Up

Before we log everything, a few quick questions:

1. **What are you most pleased about from this session?**
2. **What's still on your mind or unfinished?**
3. **How are you feeling about the project?**
4. **Any insights or lessons?**

(Say "skip" to just create the technical log.)
```

---

### Step 5 — Calculate Session Duration

Get current time, recall start time, calculate difference.
Format: "Xh XXm" (e.g., "2h 15m")

---

### Step 6 — Update Linear Issues

Scan the conversation for `PROJ-{N}` references and work completed. For each referenced issue:

1. **Completed this session** → move to Done using `mcp__linear-server__save_issue` with the Done state ID from `method.config.md`
2. **Worked on but not finished** → ensure In Progress using `mcp__linear-server__save_issue` with the In Progress state ID from `method.config.md`
3. **Post a session comment** via `mcp__linear-server__save_comment` with content: `"**Session {YYYY-MM-DD}:** {brief summary of what was done, decisions made, and any next steps}"`

Read all state IDs from your project's `method.config.md` under "Workflow State IDs". The table maps state names (Done, UAT, Building, In Progress, etc.) to Linear state UUIDs specific to your workspace.

**For each WIT issue touched this session, also consider:**
- If the issue description is stale or missing detail based on what was discussed, update it via `mcp__linear-server__save_issue` with an updated `description`
- If priority changed based on session decisions, update `priority` accordingly
- Always post a comment — even if status didn't change — so there's a running session history on the issue

---

### Step 7 — Create Session Log

Create file: `Logs/Sessions/YYYY-MM-DD_HHMM.md` with personal reflections and technical summary. Include a **Linear Updates** section listing any issues updated.

---

### Step 8 — Git Commit & Push

Check for uncommitted changes and confirm with the user before committing.

---

### Step 9 — Post to Slack

Post a brief summary to the project's Slack channel (configure channel ID in `method.config.md`):

```
mcp__slack__conversations_add_message(
  channel_id: "{slack_channel_id from method.config.md}",
  content_type: "text/markdown",
  payload: "
**Session Ended** — [duration]

*Accomplishments:*
- [key things completed this session]

*Next Steps:*
- [what's queued for next session]

_Log: `Logs/Sessions/YYYY-MM-DD_HHMM.md`_
"
)
```

---

### Step 10 — Confirm Session End

Show: duration, tasks completed, files modified, commits pushed, Slack status.

If version was bumped, confirm that `changelog.json` was deployed (it should have been deployed in Step 3).

---

## Related

- Start Session skill (`/start-session`) - captures intentions at session start
- Session logs: `Logs/Sessions/YYYY-MM-DD_HHMM.md`
- In-app changelog: `src/app/assets/changelog.json`
- Strategy changelog: `Strategy/Doc4_Changelog.md`
