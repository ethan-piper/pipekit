# Hooks SOP

> Claude Code hooks are shell commands the harness runs on lifecycle events (prompt submit, tool use, session start, etc.). They belong in the **CI / Hooks** layer of Pipekit's [three-layer enforcement model](Skills_SOP.md#how-skills-work) — hard enforcement that runs without Claude's cooperation.

**Last updated:** 2026-04-21

---

## Where hooks live

Hooks are per-machine, not per-project. Pipekit ships reference hooks in `hooks/` but does **not** sync them via `sync-method.sh` — each developer installs the ones they want into `~/.claude/hooks/` and registers them in `~/.claude/settings.json`.

Keeping hooks out of the sync avoids fighting developers who don't want a given hook, and avoids committing machine-specific paths.

---

## Available hooks

### `check-context.sh` — Context window warnings

**What it does:** On every `UserPromptSubmit`, reads the transcript's latest token usage, compares to the model's context window, and warns at 60% / 80% to run `/compact`. No hard block.

**Context window detection** (first match wins):

1. `$CLAUDE_MAX_CONTEXT` env var — manual override.
2. `.context_window.context_window_size` from the hook input — forward-compat; empty today.
3. `/tmp/claude-ctx-window-${session_id}` cache populated by `statusline-wrapper.sh` (see below). Install the wrapper to auto-detect 1M vs 200K per session.
4. Observed usage > 180K → assumed 1M. Catch-all when the wrapper is not installed; a session that has sustained >180K usage is necessarily on a >200K window.
5. Default fallback: `200000`.

**Install:**

1. Copy the script: `cp hooks/check-context.sh ~/.claude/hooks/check-context.sh && chmod +x ~/.claude/hooks/check-context.sh`
2. Register in `~/.claude/settings.json` under `hooks.UserPromptSubmit`:
   ```json
   { "type": "command", "command": "/Users/<you>/.claude/hooks/check-context.sh", "timeout": 5 }
   ```
3. **Recommended**: install `statusline-wrapper.sh` (below) to auto-detect 1M context. This removes the need for the `CLAUDE_MAX_CONTEXT` env var and handles the case where you toggle between 200K and 1M sessions.
4. **Alternative** (if you don't want the wrapper): export `CLAUDE_MAX_CONTEXT=1000000` in `~/.zshrc` for Opus 1M. You'll need to unset it when using 200K models.

**Debug:**

```bash
export CLAUDE_HOOK_DEBUG=1
```

Then submit a prompt. The hook dumps its stdin to `/tmp/claude-hook-input.log` — inspect it to confirm what the harness is passing.

---

### `statusline-wrapper.sh` — Context window tap for `check-context.sh`

**What it does:** Wraps your real statusline script. On every statusline refresh, reads `.context_window.context_window_size` from the StatusLine hook payload (which does include it, unlike UserPromptSubmit) and writes it to `/tmp/claude-ctx-window-${session_id}`. Then execs the real statusline with the original payload, so the status bar renders normally.

**Why**: the Claude Code harness exposes the actual context window size only to the StatusLine hook, not to UserPromptSubmit. Without this wrapper, `check-context.sh` can't distinguish between a 200K and 1M session and falls back to the default 200K — producing wrong percentages whenever you're on the 1M Opus variant.

**Install:**

1. Copy the wrapper: `cp hooks/statusline-wrapper.sh ~/.claude/hooks/statusline-wrapper.sh && chmod +x ~/.claude/hooks/statusline-wrapper.sh`
2. Update `~/.claude/settings.json` `statusLine.command` to call the wrapper:
   ```json
   "statusLine": {
     "type": "command",
     "command": "bash /Users/<you>/.claude/hooks/statusline-wrapper.sh"
   }
   ```
3. By default, the wrapper looks for `vbw-statusline.sh` under `~/.claude/plugins/cache/vbw-marketplace/`. To use a different statusline, set `CLAUDE_STATUSLINE_TARGET=/path/to/your-statusline.sh` in your shell env.

**Verify:**

After one prompt in a new session:

```bash
cat "/tmp/claude-ctx-window-$(echo "$CLAUDE_SESSION_ID" 2>/dev/null || ls -t /tmp/claude-ctx-window-* | head -1 | sed 's|.*claude-ctx-window-||')"
```

Should print `1000000` (or `200000`, depending on your model). If the file doesn't exist, the wrapper hasn't run yet — send another prompt and re-check.

**First-turn caveat:** on turn 1 of a new session, the StatusLine may render after UserPromptSubmit fires, so `check-context.sh` falls through to priority 4 (observed-usage catch-all) or priority 5 (default 200K) for that single turn. Self-corrects on turn 2.

---

## Writing new hooks

If you add a new hook to `hooks/`, also:

1. Add a section to this SOP matching the format above: **What it does**, **Install**, **Debug**.
2. Decide if it should be per-machine (most hooks) or per-project (rare — would need a project-local `.claude/hooks/` and a `settings.json` entry). Default to per-machine.
3. Do not modify `scripts/sync-method.sh` to auto-sync hooks unless there's a clear reason. Reference hooks are discoverable via this SOP.
