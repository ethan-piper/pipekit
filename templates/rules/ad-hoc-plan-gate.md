# Rule: Ad-hoc Plan Gate

For non-VBW interactive work (quick fixes, exploratory changes, bug fixes outside a wave), present a 3-5 bullet plan and get user approval **before writing any code**.

## Plan Format

```
## Plan: {what you're doing}

1. **What changes:** {files/areas affected}
2. **What doesn't change:** {explicitly preserved}
3. **Approach:** {tools, patterns, strategy}
4. **Key decisions:** {any trade-offs or choices}
5. **Verify:** {how to confirm it worked}

Proceed? (y/n)
```

## When This Applies

- Any code change in an interactive session that isn't part of a VBW plan
- Bug fixes, hotfixes, refactors, quick features
- Does NOT apply to: reading files, exploring code, running tests, git operations

## Why

VBW handles planned work well — tasks have verify/done criteria and atomic commits. But interactive sessions have no gate. This lightweight plan prevents:
- Scope creep ("while I'm here, let me also...")
- Wrong-direction work (building before confirming approach)
- Silent assumption errors (you assumed X, user meant Y)

## Red Flag

If you catch yourself thinking "This is simple, I don't need a plan" — you definitely need a plan. Simple changes that go wrong are the hardest to debug because nobody documented what was supposed to happen.
