# Hooks SOP

> Claude Code hooks are shell commands the harness runs on lifecycle events (prompt submit, tool use, session start, etc.). They belong in the **CI / Hooks** layer of Pipekit's [three-layer enforcement model](Skills_SOP.md#how-skills-work) — hard enforcement that runs without Claude's cooperation.

**Last updated:** 2026-04-19

---

## Where hooks live

Hooks are per-machine, not per-project. Pipekit ships reference hooks in `hooks/` but does **not** sync them via `sync-method.sh` — each developer installs the ones they want into `~/.claude/hooks/` and registers them in `~/.claude/settings.json`.

Keeping hooks out of the sync avoids fighting developers who don't want a given hook, and avoids committing machine-specific paths.

---

## Available hooks

### `check-context.sh` — Context window warnings

**What it does:** On every `UserPromptSubmit`, reads the transcript's latest token usage, compares to the model's context window, and warns at 60% / 80% to run `/compact`. No hard block.

**Context window detection** (first match wins):

1. `$CLAUDE_MAX_CONTEXT` env var — manual override. Set this when using Opus 1M or any non-default context window.
2. `.context_window.context_window_size` from the hook input — when the harness supplies it.
3. Fallback: `200000` (standard Sonnet/Opus).

**Install:**

1. Copy the script: `cp hooks/check-context.sh ~/.claude/hooks/check-context.sh && chmod +x ~/.claude/hooks/check-context.sh`
2. Register in `~/.claude/settings.json` under `hooks.UserPromptSubmit`:
   ```json
   { "type": "command", "command": "/Users/<you>/.claude/hooks/check-context.sh", "timeout": 5 }
   ```
3. If you use an expanded context window (e.g., Opus 1M), add to `~/.zshrc`:
   ```bash
   export CLAUDE_MAX_CONTEXT=1000000
   ```

**Debug:**

```bash
export CLAUDE_HOOK_DEBUG=1
```

Then submit a prompt. The hook dumps its stdin to `/tmp/claude-hook-input.log` — inspect it to confirm what the harness is passing.

---

## Writing new hooks

If you add a new hook to `hooks/`, also:

1. Add a section to this SOP matching the format above: **What it does**, **Install**, **Debug**.
2. Decide if it should be per-machine (most hooks) or per-project (rare — would need a project-local `.claude/hooks/` and a `settings.json` entry). Default to per-machine.
3. Do not modify `scripts/sync-method.sh` to auto-sync hooks unless there's a clear reason. Reference hooks are discoverable via this SOP.
