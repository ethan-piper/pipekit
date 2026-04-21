#!/bin/bash
# StatusLine tap: captures .context_window.context_window_size to a per-session cache
# at /tmp/claude-ctx-window-${session_id}, then execs the real statusline.
#
# Why: the UserPromptSubmit hook payload does NOT include context_window.context_window_size,
# so check-context.sh can't tell whether you're on a 200K or 1M window. The StatusLine
# hook payload DOES include it. This wrapper taps that payload into a cache file that
# check-context.sh reads as priority 3 (see Hooks_SOP.md).
#
# Runs on every statusline refresh. Cache writes are best-effort (non-fatal).
#
# Configure the real statusline command via:
#   CLAUDE_STATUSLINE_TARGET=/path/to/your-statusline.sh
# Default: searches for vbw-statusline.sh under ~/.claude/plugins/cache/vbw-marketplace/.

set -e
input=$(cat)

# Capture context window — non-fatal
{
  session_id=$(printf '%s' "$input" | jq -r '.session_id // .sessionId // empty' 2>/dev/null)
  ctx_size=$(printf '%s' "$input" | jq -r '.context_window.context_window_size // empty' 2>/dev/null)
  if [[ -n "$session_id" && -n "$ctx_size" && "$ctx_size" != "null" && "$ctx_size" != "0" ]]; then
    printf '%s' "$ctx_size" > "/tmp/claude-ctx-window-${session_id}" 2>/dev/null || true
  fi
} 2>/dev/null || true

# Exec the real statusline
target="${CLAUDE_STATUSLINE_TARGET:-}"
if [[ -n "$target" && -f "$target" ]]; then
  printf '%s' "$input" | exec bash "$target"
fi

# Default: find vbw-statusline.sh in the plugin cache
for _d in "${CLAUDE_CONFIG_DIR:-}" "$HOME/.config/claude-code" "$HOME/.claude"; do
  [ -z "$_d" ] && continue
  f=$(ls -1 "$_d"/plugins/cache/vbw-marketplace/vbw/*/scripts/vbw-statusline.sh 2>/dev/null | sort -V | tail -1 || true)
  if [ -f "$f" ]; then
    printf '%s' "$input" | exec bash "$f"
  fi
done

# No statusline found — exit silently so the harness doesn't render garbage
exit 0
