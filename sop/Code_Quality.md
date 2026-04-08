# Code Quality SOP

> For the full development pipeline, see [method.md](../method.md).

**Last updated:** 2026-04-08
**Source of truth:** Your project's CLAUDE.md defines authoritative coding conventions. This SOP provides the day-to-day procedures.

---

## Pre-Deploy Gate

Every PR must pass all checks before merge. The exact commands are defined in your project's `method.config.md` under "Pre-Deploy Gate". Typical example:

```bash
pnpm turbo run check-types   # TypeScript strict mode
pnpm turbo run lint           # ESLint
pnpm turbo run test           # Unit + integration tests
```

CI runs these automatically on every PR. If any fail, the merge is blocked.

---

## Daily Workflow

### Before Opening a PR

Run the full pre-deploy gate locally. Fix all errors before pushing. Warnings should be addressed but won't block.

### After Writing New Code

Run the type checker and linter to catch issues early. Filter to the relevant package for speed.

---

## General Conventions

- **Strict mode** TypeScript everywhere (`strict: true` in tsconfig)
- Named exports only — no default exports
- **kebab-case** for all filenames
- **camelCase** for function names
- **UPPER_SNAKE_CASE** for constants
- **PascalCase** for React components and TypeScript types/interfaces
- Prefix booleans with `is`/`has`/`can`/`should`

---

## Shared Component Structure

If your project uses a shared component library, follow this pattern:

```
packages/ui/src/{kebab-name}/
├── {kebab-name}.tsx           <- Component with TypeScript props interface
├── {kebab-name}.test.tsx      <- Co-located test file
└── index.ts                   <- Barrel export
```

Use `/component` to scaffold new components (if available in your project).

---

## Troubleshooting

### Type errors after pulling changes

Re-run with cache bypass:
```bash
pnpm turbo run check-types --force
```

### Tests failing locally but passing in CI

Ensure you're running from the repo root (not a worktree with stale deps):
```bash
pnpm install
pnpm turbo run test --force
```
