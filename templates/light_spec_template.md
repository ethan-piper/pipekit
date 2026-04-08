# Light Spec Template

> Canonical template for structured specs. Used by `/light-spec` and the Spec Review Agent.
> This is an AI→AI contract: Generator → Reviewer → Planner. Every rule must be explicit, unambiguous, and enforceable.

## Light Spec

**Status:** Draft | Agent-Reviewed | Planning-Ready
**Complexity:** Low (~2-4h) | Medium (~6-10h) | High (~12-20h+)
**VBW Phase:** [phase name or TBD]
**Linear Project:** [project name or TBD]

### Problem
[What's broken, missing, or suboptimal? Why does this matter? 2-3 sentences max.]

### Goal
[What is true after this is done? Define the end-state, not the work. 1-2 sentences.]

### Proposed Solution
[What are we building? High-level approach in 3-5 bullets. Describe outcomes, not implementation steps.]

### Scope

**In scope:**
- [concrete deliverable 1 — describe the outcome, not the method]
- [concrete deliverable 2]

**Out of scope:**
- [explicitly excluded item — prevents scope creep during planning]

### Decisions
[Key behavioral decisions that affect implementation. Each must be DEFINED or marked [TBD].]

- **[Decision area]:** [chosen approach] | [TBD — needs input from ___]

### Requirements
- [ ] [functional requirement 1]
- [ ] [functional requirement 2]
- [ ] [functional requirement N]

### Acceptance Criteria
[Each criterion MUST define an **input or state** and an **observable output**. For UI criteria, reference the specific surface (page, component, modal). A criterion the planner cannot verify is not a criterion.]

- [ ] [Given <state/input>, when <action>, then <observable output on specific surface>]
- [ ] [criterion N]

**Invalid patterns (spec fails review if these appear):**
- "All tests pass" — test counts are not acceptance criteria
- "Works correctly" — define what correct means
- "UI is updated" — specify which page/component and what changes
- Any criterion without a concrete expected behavior

### Technical Context
[What exists today that's relevant? Keep it brief — VBW agents will do deep exploration during planning.]

- **Existing code:** [relevant paths or "greenfield"]
- **Database:** [relevant tables or "new tables needed"]
- **Dependencies:** [external libs, APIs, other features]
- **Patterns to follow:** [existing patterns in the codebase to match]
- **Authority:** [For data/calculations: where is the source of truth? DB | utils | POC | API. If multiple layers, explicitly define precedence — e.g., "DB is authoritative; utils must match DB behavior." Never leave authority ambiguous when two layers could disagree.]

### Risks & Open Questions
- [risk or unknown 1 — e.g., "Unclear if RLS policy covers this case"]
- [risk or unknown 2]
- [question for planning to resolve]

### Notes
[Anything else: related issues, prior art, user feedback, design links, etc.]
