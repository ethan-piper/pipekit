# Security

**Dimension:** Conditional
**Load when:** Diff touches `supabase/migrations/**`, `**/api/**/*.ts`, `lib/supabase/**`, `**/auth/**`, `middleware.ts`, any `*.sql` file, or any file importing from `@/lib/supabase/*`
**Default severity:** Most findings here are Critical or High. This is a finance platform.

---

## Row Level Security (RLS)

### New Tables Must Have RLS

Every `CREATE TABLE` in a migration must be followed by:
1. `ALTER TABLE {name} ENABLE ROW LEVEL SECURITY;`
2. At least one SELECT policy
3. At least one INSERT or UPDATE policy (unless table is read-only)

Policy creation must be wrapped in a DO block:
```sql
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='my_table' AND policyname='My Policy') THEN
    CREATE POLICY "My Policy" ON my_table FOR SELECT USING (...);
  END IF;
END $$;
```

**Severity:** Critical
**Detection:** `CREATE TABLE` in SQL diff without corresponding `ENABLE ROW LEVEL SECURITY` in same migration

### Existing Tables

If a migration alters an existing table (adds columns, changes constraints), verify RLS is already enabled. Flag if the table is referenced without RLS.

**Severity:** High (flag for manual verification)

---

## User ID Invariant

The auth user ID (`supabase.auth.getUser().data.user.id`) is NOT the same as the internal user ID (`public.users.id`). Tables with `created_by` columns reference `public.users.id`. Using the auth UID directly causes FK violations.

### Required Pattern

```ts
// 1. Get auth user
const { data: { user } } = await supabase.auth.getUser();
// 2. Look up internal ID
const { data: internalUser } = await supabase
  .from("users")
  .select("id")
  .eq("auth_user_id", user.id)
  .single();
// 3. Use internalUser.id for created_by
```

### Anti-Patterns to Flag

- Using `user.id` (from `auth.getUser()`) directly in an `.insert()` or `.update()` that sets `created_by`
- Passing `user.id` to an RPC parameter that maps to a `created_by` column
- Any assignment like `created_by: user.id` where `user` comes from `auth.getUser()`

**Severity:** Critical
**Detection:** `.insert({` or `.update({` containing `created_by` near `auth.getUser()` without an intermediate `from("users").select("id").eq("auth_user_id"` lookup

---

## API Route Authentication

Every API route handler must:
1. Create Supabase client from `@/lib/supabase/server` (never `client.ts`)
2. Call `supabase.auth.getUser()`
3. Return `Response.json({ error }, { status: 401 })` if no user

### Anti-Patterns to Flag

- Route handler with no `auth.getUser()` call
- Route using `createClient()` from `@/lib/supabase/client`
- Auth check present but no early return on failure (code continues with potentially null user)

**Severity:** Critical (missing auth), High (wrong client)

---

## RPC Security

All RPC functions must use:

| Requirement | Correct | Wrong |
|---|---|---|
| Security context | `SECURITY INVOKER` | `SECURITY DEFINER` (bypasses RLS) |
| Search path | `SET search_path = 'public'` | `SET search_path = ''` (breaks RLS policy resolution) |
| Parameters | `p_` prefix on all params | No prefix (causes "function does not exist") |

**Severity:** High (SECURITY DEFINER without justification), Critical (empty search_path)
**Detection:** `CREATE OR REPLACE FUNCTION` in SQL diff — check for INVOKER, search_path, and `p_` prefix

---

## Environment Secrets

### Client-Side Exposure

Only these variables may appear in client-side code:
- `NEXT_PUBLIC_SUPABASE_URL`
- `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY`

Flag any other `process.env.*` (non-`NEXT_PUBLIC_`) in files with `"use client"` or in `components/` directories.

**Severity:** Critical

### Service Role Key

The Supabase service role key must NEVER appear in client code. It bypasses RLS entirely.

**Severity:** Critical
**Detection:** `SUPABASE_SERVICE_ROLE` or `service_role` in any non-server file

### .env Files

- No `.env` files should appear in the diff (they must be in `.gitignore`)
- No secrets (API keys, tokens, passwords) in any committed file

**Severity:** Critical

---

## Realtime Channel Safety

### Channel Error Handlers

All realtime subscriptions must pass a status callback to `.subscribe()`:
```ts
.subscribe((status) => {
  if (status === "CHANNEL_ERROR" || status === "TIMED_OUT") {
    captureException(new Error("Realtime channel error"), {
      extra: { channel: channelName, status, id },
    });
  }
});
```

Missing error handler = channel failures are invisible.

**Severity:** Medium
**Detection:** `.subscribe()` call with no callback argument, or callback that doesn't check for error statuses

### Presence Channel Key

Presence channels must use the authenticated user's ID as the presence key:
```ts
supabase.channel(`presence-${feature}-${id}`, {
  config: { presence: { key: user.id } }
})
```

**Severity:** Medium
