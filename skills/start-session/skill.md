---
name: start-session
description: Begin a work session by reviewing past progress and capturing intentions
---

# Start Session Skill

You help the user begin a new work session by reviewing past progress and capturing their intentions for the current session.

## Triggers

This skill is invoked when the user says:
- `/start-session`
- "start session"
- "what did we do last time"
- "review previous sessions"

## Purpose

1. Review recent session logs to provide context
2. Ask the user for their goals and intentions for this session
3. Capture their mindset to build a personal work diary over time

## Execution Steps

### 1. Note the Start Time

Record the current timestamp for duration tracking.

### 2. Review Recent Sessions

List and read recent session logs from `Logs/Sessions/`.

### 3. Query Linear Status

Use `mcp__linear-server__list_issues` with:
- `team`: `"{team from method.config.md}"`
- `state`: `"Building"` — then repeat for `"In Progress"`, `"UAT"`, and `"Approved"`

Also pull the current phase's WIT issues from `.vbw-planning/STATE.md` to show what's queued for the active phase.

Display as a **Linear Status** block:

```markdown
## Linear Status

**Building:**
- WIT-42 — Feature title (priority, project)
- ...

**In Progress:**
- WIT-38 — Feature title (ad-hoc/manual)
- ...

**UAT:**
- WIT-39 — Feature title
- ...

**Current Phase (from STATE.md):**
- Phase 1 — Piper Repo Setup: WIT-160, WIT-161, WIT-162
  - WIT-160: [status]
  - WIT-161: [status]
  - WIT-162: [status]
```

If no issues are in progress or review, note that — it means the queue is clear.

### 4. Present Recent Activity

Show the user a concise summary combining: last session log + board status + Linear status.

### 5. Rename cmux Workspace

After the user states their intentions, rename the cmux workspace to reflect the current work context:

```bash
bash ~/.claude/scripts/cmux-workspace-name.sh
```

If the user mentioned a specific Linear issue or task, pass it as an argument:

```bash
bash ~/.claude/scripts/cmux-workspace-name.sh "WIT-XXX"
```

Skip silently if cmux is unavailable.

### 6. Ask for Session Intentions

Prompt the user:
1. What are you hoping to accomplish this session?
2. How are you feeling about the project right now?
3. Anything on your mind that might affect today's work?

### 7. Record Their Response

Acknowledge their intentions and store for end-of-session reflection.

## Related

- End Session skill (`/end-session`) - captures reflections at session end
- Session logs: `Logs/Sessions/YYYY-MM-DD_HHMM.md`
