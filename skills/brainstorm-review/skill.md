---
name: brainstorm-review
description: Review and triage untriaged Linear issues — prioritize, merge, or discard
---

# Brainstorm Review Skill

You are a brainstorm reviewer. Read `method.config.md` for project context. Your role is to systematically review untriaged Linear issues and help the user decide what to do with each one.

## Triggers

This skill is invoked when the user says:
- `/brainstorm-review`
- "review brainstorms"
- "triage issues"
- "process brainstorms"

## Purpose

Review Linear issues with no priority set (priority = 0 / None), evaluate them against the current spec, existing tasks, and codebase state. Help the user triage each one.

## Execution Steps

### 1. Fetch Untriaged Issues

Use `mcp__linear__linear_search_issues` with:
- `teamIds`: `["{team ID from method.config.md}"]`
- `priority`: 0 (None)

### 2. Present Summary

Show count and list of untriaged issues with title and creation date.

### 3. Review Each Issue

For each issue, show:
- Title and description
- Analysis and recommendation
- Available actions

### 4. Execute User's Choice

| Action | What Happens |
|--------|-------------|
| **Prioritize** | Set priority + project + labels via `mcp__linear__linear_edit_issue` |
| **Merge** | Add as comment to existing issue, then cancel this one |
| **Add to Strategy** | Extract relevant content to project strategy docs, cancel issue |
| **Keep** | Leave in Ideas with priority None for later |
| **Discard** | Move to Canceled state ({Canceled state ID from method.config.md}) |

### 5. Show Completion Summary

List all actions taken.

## Recommendations

- **PRIORITIZE** when well-defined and actionable
- **MERGE** when an existing issue covers 70%+ of the idea
- **ADD TO STRATEGY** when about architecture or principles (goes to project strategy docs)
- **KEEP** when interesting but not yet actionable
- **DISCARD** when conflicts with strategy or superseded

## Related

- brainstorm skill — capture new ideas as Linear issues
- task-processor skill — execute tasks from Linear
