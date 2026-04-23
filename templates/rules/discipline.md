# AI Coding Discipline

Cross-cutting discipline rules for AI-assisted coding. These apply regardless of stack.

## Red Flags — thoughts that mean "go slower, not faster"

If you catch yourself thinking one of these, follow the full workflow *more* strictly, not less.

| Flag | What it actually means |
|------|------------------------|
| "This is simple, I don't need a plan" | You definitely need a plan. Simple-feeling changes are where silent regressions live. |
| "I know this API" | Training data lies on fast-moving libs. Read installed source first (see `tooling.md`). |
| "I'll write tests after" | Write them first, or at minimum concurrently. After-the-fact tests test the bug, not the spec. |
| "The user said to just do it" | They still need to see what changed before you commit. One-sentence confirmation is not a blocker. |
| "This error is probably fine to catch and ignore" | You're about to create a silent failure. Fail loudly or fix the cause. |
| "The existing code does X so I'll mirror it" | The existing code may be wrong. Verify X is correct before replicating. |

Add project-specific red flags below this line — situations where your past sessions went sideways.

## Ad-hoc Plan Gate

For any non-trivial change outside a full VBW planning flow, produce a 3-5 bullet plan and pause for approval before writing code. Even for "quick fixes."

**Plan format:**

```
## Plan: {what you're doing}

1. **What changes:** {files/areas affected}
2. **What doesn't change:** {explicitly preserved to scope the blast radius}
3. **Approach:** {tools, patterns, strategy}
4. **Key decisions:** {any trade-offs you made that the user might want to redirect}
5. **Verify:** {how to confirm it worked}

Proceed? (y/n)
```

**When this applies:** any code change in an interactive session that isn't part of a VBW plan — bug fixes, hotfixes, refactors, quick features.

**Does NOT apply to:** reading files, exploring code, running tests, git operations.

VBW handles planned work well — tasks have verify/done criteria and atomic commits. But interactive sessions have no gate. This lightweight plan prevents scope creep ("while I'm here, let me also..."), wrong-direction work (building before confirming approach), and silent assumption errors (you assumed X, user meant Y).

## Scope Hygiene

- **Don't add features, refactors, or abstractions beyond the task.** A bug fix doesn't need surrounding cleanup. A one-shot operation doesn't need a helper. Three similar lines is better than a premature abstraction.
- **Don't add error handling for scenarios that can't happen.** Trust internal code and framework guarantees. Validate only at system boundaries (user input, external APIs).
- **Don't add backwards-compatibility shims when you can change the code.** Feature flags, deprecation comments, `_unusedVar` renames — all drift.
- **Don't leave half-finished implementations.** If you stop mid-task, leave a clear marker (TODO with a reason, or a clean revert).

## Comments and documentation

- **Default to no comments.** Only add one when the *why* is non-obvious.
- **Never write multi-paragraph docstrings.** One short line, max.
- **Don't reference the current task, fix, or PR.** That belongs in the commit message, not the code.
- **Don't explain what the code does.** Well-named identifiers already do that.

## Commit discipline

- **One atomic change per commit.** If you can't describe it in one sentence, split it.
- **Commit messages say why, not what.** The diff says what.
- **Don't amend published commits.** Create new commits instead.
- **Don't skip hooks.** `--no-verify` means you're bypassing a gate someone put there for a reason.

## Before taking destructive actions

Stop and confirm for: deleting files or branches, force-push, `git reset --hard`, dropping tables, removing dependencies, modifying CI/CD pipelines. The cost of pausing is low; the cost of an unwanted action is high.

Routine edits, running tests, creating files — no confirmation needed.
