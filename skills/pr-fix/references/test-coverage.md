# Test Coverage

**Dimension:** Conditional
**Load when:** Any non-test source file is changed in the diff
**Approach:** Behavioral coverage analysis, not line counting. Focus on tests that prevent real bugs.

---

## Financial Calculation Tests (NON-NEGOTIABLE)

Piper is a finance platform. Any code that produces, transforms, or displays monetary values MUST have tests. No financial number may reach a user without verified test coverage.

### Mandatory Coverage Targets

Any function in `packages/utils/src/` that calculates money:

| Module | Functions | Required edge cases |
|---|---|---|
| `calculations.ts` | Line item totals, GP/NP margins, budget variance | Zero values, null/undefined inputs, negative numbers, floating-point precision, very large numbers |
| `markup.ts` | Markup parsing, application, validation, formatting | Percentage (`20%`), addition (`+50`), null/missing, invalid strings, negative markup |
| `formatting.ts` | Currency formatting, percentage formatting | Zero, negative, large numbers, different locales |

### Specific Edge Cases Required

- **Tax calculations:** tax on marked-up values, zero tax rate, tax on negative subtotals
- **Margin calculations:** zero revenue, zero cost, negative margins, 100% margin
- **Markup parsing:** `"20%"` (percentage), `"+50"` (addition), `""` (empty), `null`, `"abc"` (invalid), `"-10%"` (negative)
- **Floating-point:** `0.1 + 0.2` style precision issues, rounding to 2 decimal places
- **Negative values:** negative qty, unit_cost, multiplier are valid discounts — do not guard against them

**Severity:** Critical (missing tests for financial functions)
**Detection:** modification to `packages/utils/src/calculations.ts`, `markup.ts`, or `formatting.ts` without corresponding changes in `.test.ts` file

---

## UI Numeric Component Tests

Components in `packages/ui/src/` that handle numeric input or display must have co-located tests:

| Component | Test file | Status |
|---|---|---|
| `amount-input` | `amount-input.test.tsx` | Required |
| `markup-input` | `markup-input.test.tsx` | Required |
| `gauge` | `gauge.test.tsx` | Required |
| `version-badge` | `version-badge.test.tsx` | Missing (flag if component is modified) |

Tests should cover:
- Numeric input/output accuracy
- Formatting on blur
- Edge cases (empty, zero, negative, very large)
- User interaction (typing, pasting, clearing)

**Severity:** High (missing tests for numeric UI components)
**Detection:** modification to `packages/ui/src/{name}/{name}.tsx` without corresponding `.test.tsx`

---

## App-Level Pure Functions

Pure functions in `apps/web/src/lib/` that perform calculations or transformations should have co-located tests:

- `lib/cache/budget-cache.ts` has `budget-cache.test.ts` — test cache manipulation helpers
- Any new pure function in `lib/` that computes values (not just passes through to Supabase) should have tests

**Severity:** High (new calculation functions), Medium (modifications to existing tested functions)

---

## Test File Location Rules

| Source location | Test location |
|---|---|
| `packages/utils/src/*.ts` | `packages/utils/src/*.test.ts` (co-located) |
| `packages/ui/src/{name}/{name}.tsx` | `packages/ui/src/{name}/{name}.test.tsx` (co-located) |
| `apps/web/src/lib/**/*.ts` | `apps/web/src/lib/**/*.test.ts` (co-located) |
| `apps/web/src/app/` (pages) | Future Playwright E2E (not unit tests) |

---

## Test Quality Checks

### Tests Should Verify Behavior, Not Implementation

- Flag tests that assert on internal state or private methods
- Flag tests that break when implementation changes but behavior stays the same
- Flag tests that mock what they're testing

**Severity:** Medium
**Detection:** test files with excessive mocking of the module under test, or assertions on internal variables

### Never Suggest Snapshot Tests

Snapshot tests are explicitly prohibited in this project. Do not suggest them, do not flag their absence as a gap.

### DAMP Principles

Tests should be Descriptive and Meaningful:
- Test names describe the behavior being tested, not the method name
- Each test is self-contained and readable without context
- Prefer explicit setup over shared fixtures when it aids readability

**Severity:** suggestion-only (do not report as findings)

---

## What NOT to Flag

- **Pure layout components** with no calculation logic — no tests needed
- **Page-level components** — covered by E2E, not unit tests
- **Snapshot test absence** — never suggest snapshots
- **Trivial getters/setters** — unless they contain logic
- **Test files only changed** — if the PR is entirely test modifications, suppress this dimension

---

## Detection Logic

When analyzing the diff:

1. **New function in financial module?** Check if test file was also modified to add covering test cases
2. **Modified function in financial module?** Check if existing tests still cover the modified behavior, or if new edge cases need tests
3. **New pure function in `lib/`?** Check if a `.test.ts` was created alongside it
4. **New UI component handling numbers?** Check if `.test.tsx` was created with the component
5. **Modified existing tested code?** Verify tests were updated to reflect behavior changes (stale tests are worse than no tests)

### Criticality Rating

| Rating | Criteria | Example |
|---|---|---|
| 9-10 | Data loss, financial error, security | Untested margin calculation |
| 7-8 | User-facing error in business logic | Untested markup parsing |
| 5-6 | Edge case causing confusion | Empty input not handled in test |
| 3-4 | Nice-to-have completeness | Redundant enum variant |
| 1-2 | Trivial (do not report) | Getter without logic |

Only report gaps rated >= 5.
