# Correctness & Compliance

**Dimension:** Always loaded
**Purpose:** Detect bugs, verify project pattern compliance, enforce naming and structure rules.

---

## Bug Detection

### Null/Undefined Handling

- Optional chaining (`?.`) used where the value MUST exist (masking a real bug)
- Missing null checks before `.map()`, `.filter()`, `.length` on potentially undefined arrays
- Destructuring without defaults on nullable objects

**Severity:** Critical if data corruption possible, High otherwise

### Async/Await

- Missing `await` on async function calls (promise returned but not resolved)
- `async` function in `useEffect` callback (must wrap in inner function)
- Missing error handling on awaited calls in non-try/catch context

**Severity:** Critical if mutation/write, High if read

### Race Conditions

- `useEffect` without cleanup that sets state after unmount
- Missing `cancelled` flag on async setup in useEffect (see hooks-realtime.md pattern)
- Stale closure over state variable in callback registered once

**Severity:** High

### Type Safety

- `as` type assertions that bypass narrowing (hiding potential runtime errors)
- `any` type used where a concrete type exists
- `!` non-null assertion on values that could genuinely be null

**Severity:** High if in financial/auth code, Medium otherwise

### Off-by-One / Logic

- Array index bounds (`.at(-1)` vs `[length - 1]` on empty arrays)
- Fence-post errors in pagination or slicing
- `>` vs `>=` in boundary comparisons

**Severity:** Critical if financial, High otherwise

---

## React Query Compliance

### Server State Belongs in React Query

- Flag any Zustand store (`useStore`, `create(`) that holds data fetched from Supabase or an API
- Server data must use `useQuery` / `useMutation` from `@tanstack/react-query`

**Severity:** High
**Detection:** imports from `zustand` in files that also import from `@supabase/*` or fetch data

### Query Key Factories

- Never manually construct query keys like `['budget', id]`
- Must use the domain's exported key factory: `budgetKeys`, `lineItemKeys`, `commentKeys`, `entityKeys`, `clientKeys`, `projectKeys`
- Located in `lib/queries/{domain}.ts`

**Severity:** Critical (cache invalidation bugs)
**Detection:** `useQuery({ queryKey: [` with a string literal instead of a keys factory call

### Query Hook Patterns

- `enabled: !!id` (or equivalent) when hook has required params — prevents queries with undefined IDs
- `createClient()` called inside `queryFn`, not at module scope
- Named `use{Domain}` wrapping `useQuery`

**Severity:** High

### Optimistic Update Pattern

When optimistic updates are used (currently `useUpdateLineItem` and `useDeleteLineItem`):
1. `onMutate`: cancel queries, snapshot previous, set optimistic data
2. `onError`: revert to snapshot (NEVER skip this)
3. `onSettled`: always invalidate to refetch server truth

- Never patch computed financial fields (`subtotal`, `tax`, `total`, `out_cost`, `out_subtotal`, `out_tax`, `out_total`) in optimistic updates — leave stale, let server refresh
- Use shared helpers from `lib/cache/budget-cache.ts` (`updateLineItemInHierarchy`, `removeLineItemFromHierarchy`)

**Severity:** Critical (missing onError = stale data on failure)

### Mutations

- `useMutation` must invalidate relevant queries on `onSuccess` or `onSettled`
- Must use query key factory for invalidation target

**Severity:** High

---

## Supabase Client Layer

Three files, never mix them:

| File | Context | Import from |
|---|---|---|
| `client.ts` | Client components (`"use client"`) | `@/lib/supabase/client` |
| `server.ts` | API routes, RSC, server components | `@/lib/supabase/server` |
| `middleware.ts` | Next.js middleware only | `@/lib/supabase/middleware` |

- API route using `client.ts` instead of `server.ts` = **Critical**
- Client component using `server.ts` = **Critical**
- `createClient()` at module level (outside function body) = **High**

---

## Migration Compliance

Every SQL migration must be idempotent:

| Operation | Required pattern |
|---|---|
| Add column | `ADD COLUMN IF NOT EXISTS` |
| Create table | `CREATE TABLE IF NOT EXISTS` |
| Create index | `CREATE INDEX IF NOT EXISTS` |
| Create function | `CREATE OR REPLACE FUNCTION` |
| Drop anything | `DROP ... IF EXISTS` |
| Add constraint | DO block with `pg_constraint` check |
| Create policy | DO block with `pg_policies` check |
| Alter publication | DO block with `EXCEPTION WHEN duplicate_object` |

RPC functions must use:
- `p_` prefix on all parameters (`p_project_id`, not `project_id`)
- `SECURITY INVOKER` (not DEFINER)
- `SET search_path = 'public'` (never empty string)

**Severity:** Critical (non-idempotent migration breaks CI/CD pipeline)
**Detection:** SQL files missing `IF NOT EXISTS`, `IF EXISTS`, `OR REPLACE`, or DO block guards

Additional:
- Never edit existing migration files — always fix forward with new migrations
- No migrations pushed directly without PR review

---

## AI Layer

- Prompts fetched from Langfuse via `fetchChatPrompt()` / `fetchTextPrompt()` from `lib/ai/langfuse.ts` — never hardcoded strings
- Structured output parsed with Zod schemas from `lib/ai/schemas.ts`
- Langfuse telemetry on every LLM call via `getLangfuseTelemetryConfig()`
- `maxDuration` export set on AI routes (30s standard, 60s for smart-import)

**Severity:** High (hardcoded prompts), Medium (missing telemetry)

---

## Naming Conventions

| Rule | Pattern | Severity |
|---|---|---|
| Files | kebab-case: `use-realtime-budget.ts` | Medium |
| Functions/hooks | camelCase: `useWorkingDraft` | Medium |
| Constants | UPPER_SNAKE_CASE: `MAX_FILE_SIZE` | Medium |
| Booleans | Prefix with `is`/`has`/`can`/`should` | Medium |
| Exports | Named only — no `export default` | Medium |
| Workspace imports | `@acme/ui`, `@acme/utils` | Medium |
| TypeScript check task | `check-types` (not `typecheck`) | Medium |
| DB tables | snake_case, plural | Medium |
| RPC params | `p_` prefix | Critical (causes function-not-found) |

---

## Structure & Imports

- No imports from `src_poc/` — frozen, never reference it from new code
- `packages/utils/` must be pure: no UI, no database, no API calls, no `@supabase/*` imports
- Components in correct domain directory under `apps/web/src/components/{domain}/`
- shadcn primitives from `@/components/ui/` (not `packages/ui/`)
- Shared components in `packages/ui/src/{kebab-name}/` with three files: `.tsx`, `.test.tsx`, `index.ts`

**Severity:** High (package purity violation), Medium (wrong directory)
