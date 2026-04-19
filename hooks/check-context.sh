#!/bin/bash
# Hook: Warn at 60% context, stronger warning at 80% (no hard block)
# Triggered by: UserPromptSubmit
#
# Context window detection priority (first match wins):
#   1. $CLAUDE_MAX_CONTEXT env var (manual override — set this when using Opus 1M)
#   2. .context_window.context_window_size from hook input (harness-supplied)
#   3. Default fallback: 200000 (standard Sonnet/Opus)
#
# To debug what the harness is passing, set CLAUDE_HOOK_DEBUG=1 and check /tmp/claude-hook-input.log.

set -e

input=$(cat)

if [[ "${CLAUDE_HOOK_DEBUG:-0}" == "1" ]]; then
    echo "$input" > /tmp/claude-hook-input.log
fi

transcript_path=$(echo "$input" | jq -r '.transcript_path // empty')

# Priority 1: explicit env override
max_context="${CLAUDE_MAX_CONTEXT:-}"

# Priority 2: harness-supplied context window
if [[ -z "$max_context" ]]; then
    max_context=$(echo "$input" | jq -r '.context_window.context_window_size // empty')
fi

# Priority 3: default fallback
if [[ -z "$max_context" || "$max_context" == "null" ]]; then
    max_context=200000
fi

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
fi

exit 0
