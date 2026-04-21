#!/bin/bash
# Hook: Warn at 60% context, stronger warning at 80% (no hard block)
# Triggered by: UserPromptSubmit
#
# Context window detection priority (first match wins, all others fall through):
#   1. $CLAUDE_MAX_CONTEXT env var (manual override)
#   2. .context_window.context_window_size from hook input (harness-supplied — empty
#      for UserPromptSubmit today; kept for forward-compat if the schema changes)
#   3. /tmp/claude-ctx-window-${session_id} cache populated by statusline-wrapper.sh
#      (the StatusLine hook receives .context_window.context_window_size, so the
#      wrapper taps it into a per-session cache that this hook can read). Install
#      the wrapper per Hooks_SOP.md to enable this priority.
#   4. Observed usage > 180K → 1M (catch-all for 1M-capable models when the wrapper
#      is not installed; sustained >180K usage implies a >200K window, and 1M is
#      today's only non-200K option)
#   5. Default fallback: 200000 (standard 200K context)
#
# Debug: set CLAUDE_HOOK_DEBUG=1 and check /tmp/claude-hook-input.log.

set -e

input=$(cat)

if [[ "${CLAUDE_HOOK_DEBUG:-0}" == "1" ]]; then
    echo "$input" > /tmp/claude-hook-input.log
fi

transcript_path=$(echo "$input" | jq -r '.transcript_path // empty')
session_id=$(echo "$input" | jq -r '.session_id // empty')

# Read observed context length from transcript (used for percentage AND priority 4)
context_length=0
if [[ -n "$transcript_path" && -f "$transcript_path" ]]; then
    context_length=$(jq -s '
        map(select(.message.usage and .isSidechain != true and .isApiErrorMessage != true)) |
        last |
        if . then
            (.message.usage.input_tokens // 0) +
            (.message.usage.cache_read_input_tokens // 0) +
            (.message.usage.cache_creation_input_tokens // 0)
        else 0 end
    ' < "$transcript_path")
fi

# Priority 1: explicit env override
max_context="${CLAUDE_MAX_CONTEXT:-}"

# Priority 2: harness-supplied context window (forward-compat)
if [[ -z "$max_context" ]]; then
    max_context=$(echo "$input" | jq -r '.context_window.context_window_size // empty')
fi

# Priority 3: per-session cache populated by statusline-wrapper.sh
if [[ -z "$max_context" || "$max_context" == "null" ]]; then
    if [[ -n "$session_id" && -f "/tmp/claude-ctx-window-${session_id}" ]]; then
        cached=$(cat "/tmp/claude-ctx-window-${session_id}" 2>/dev/null)
        if [[ "$cached" =~ ^[0-9]+$ && "$cached" -gt 0 ]]; then
            max_context="$cached"
        fi
    fi
fi

# Priority 4: observed usage > 180K → 1M (catch-all when wrapper not installed)
if [[ -z "$max_context" || "$max_context" == "null" ]]; then
    if [[ "$context_length" -gt 180000 ]]; then
        max_context=1000000
    fi
fi

# Priority 5: default 200K
if [[ -z "$max_context" || "$max_context" == "null" ]]; then
    max_context=200000
fi

if [[ "$context_length" -gt 0 ]]; then
    pct=$((context_length * 100 / max_context))

    if [[ $pct -gt 80 ]]; then
        echo "<user-prompt-submit-hook>Context at ${pct}% (${context_length}/${max_context}). Strongly recommend running /compact now to avoid losing context.</user-prompt-submit-hook>"
        exit 0
    elif [[ $pct -gt 60 ]]; then
        echo "<user-prompt-submit-hook>Context at ${pct}% (${context_length}/${max_context}). Please run /compact soon to avoid losing context.</user-prompt-submit-hook>"
        exit 0
    fi
fi

exit 0
