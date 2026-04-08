---
name: brainstorm
description: Analyze a feature idea, assess feasibility, and create a Linear issue
---

# Brainstorm Skill

You are a brainstorm processor. Read `method.config.md` for project context. When the user shares an idea, you analyze it, assess its feasibility, and create a Linear issue.

## Triggers

This skill is invoked when the user says:
- `/brainstorm`
- "brainstorm"
- "new brainstorm"
- "I have an idea"

## Purpose

Take a rough idea from the user, explore the codebase to understand feasibility, create a structured analysis, and capture it as a Linear issue.

## Execution Steps

1. **Capture** the idea from the user
2. **Explore** the codebase to assess feasibility
3. **Create structured analysis** with complexity, requirements, implementation approach
4. **Present** to user for approval
5. **Create Linear issue** via `mcp__linear__linear_create_issue`:
   - `teamId`: `{team ID from method.config.md}`
   - `title`: concise feature title
   - `description`: full brainstorm analysis (feasibility, complexity, approach, requirements)
   - `priority`: 0 (None) — triage sets real priority later
   - Ask user which project to assign (or leave unassigned)
6. If complexity is **High** → suggest creating a detailed spec via `/speckit`
7. **Output**: issue identifier (SIT-XX) and Linear URL

## Complexity Guidelines

- **Low (~2-4 hours):** UI-only, simple CRUD, existing infrastructure
- **Medium (~6-10 hours):** New API endpoint, combines existing systems
- **High (~12-20+ hours):** New infrastructure, complex logic, multiple integrations → suggest `/speckit`

## Description Template

Format the Linear issue description as:

```markdown
## Brainstorm Analysis

**Complexity:** Low / Medium / High
**Estimated Effort:** X-Y hours

### Summary
[1-2 sentence description]

### Feasibility Assessment
[What exists in the codebase, what's needed, any blockers]

### Implementation Approach
[High-level steps]

### Requirements
- [requirement 1]
- [requirement 2]

### Notes
[Any caveats, dependencies, or open questions]
```

## Related

- brainstorm-review skill — triage untriaged Linear issues
- task-processor skill — execute tasks from Linear
- speckit skill — create detailed specs for complex features
