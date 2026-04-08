# Error Handling

**Dimension:** Conditional
**Load when:** Diff contains `try`, `catch`, `.catch(`, `onError`, `throw`, `captureException`, or any API route file (`**/api/**/*.ts`)
**Principle:** Zero tolerance for silent failures. Every error must be surfaced, logged, and actionable.

---

## Silent Failure Detection

### Empty Catch Blocks

Any `catch` block with no body, or only a comment, is a critical defect. The error is swallowed — no logging, no user feedback, no monitoring signal.

```ts
// CRITICAL — never acceptable
catch (e) {}
catch (e) { /* TODO */ }
catch (e) { // ignore }
```

**Severity:** Critical
**Detection:** `catch` followed by `{}` or block containing only comments

### Catch-and-Log Without Tracking

A `catch` block that calls `console.log` or `console.error` but does NOT call `captureException` (Sentry) means the error is visible in local dev but invisible in production monitoring.

```ts
// HIGH — invisible in production
catch (e) { console.error(e); }

// CORRECT — tracked in Sentry
catch (e) {
  captureException(e, { extra: { context: "what was happening" } });
  // + user-facing feedback
}
```

**Severity:** High
**Detection:** `catch` block containing `console.error` or `console.log` without `captureException`

### Silent Return on Error

Returning a default value (null, undefined, empty array, fallback data) from a catch block without any logging means failures are invisible.

```ts
// HIGH — caller has no idea the operation failed
catch (e) { return null; }
catch (e) { return []; }
catch (e) { return defaultValue; }
```

**Severity:** High
**Detection:** `catch` block containing only a `return` statement with no preceding log/capture call

---

## Catch Block Specificity

### Broad Exception Catching

A `catch(e)` that handles all error types equally can suppress unrelated errors. Check: could this catch hide a TypeError, RangeError, or other programming bug?

Questions to ask:
- What specific error types are expected here?
- Could an unrelated programming error be caught and suppressed?
- Should this be multiple catch handlers or a type check inside the catch?

**Severity:** High (if the block swallows the error), Medium (if it logs/rethrows properly)
**Detection:** `catch(e)` or `catch(error)` with no type discrimination inside the block

### Error Type Discrimination

Preferred pattern — check the error type and handle specifically:

```ts
catch (e) {
  if (e instanceof PostgrestError) {
    // Handle Supabase errors specifically
  } else {
    // Unexpected — rethrow or capture
    captureException(e);
    throw e;
  }
}
```

---

## Fallback Behavior

### Fallbacks That Mask Problems

If code falls back to a default value on error without informing the user, the user sees stale or incorrect data with no indication that something went wrong.

```ts
// HIGH — user sees stale data, thinks everything is fine
const data = cachedData ?? await fetchData().catch(() => cachedData);
```

Questions to ask:
- Does the user know they're seeing fallback data?
- Is the fallback explicitly documented and justified?
- Would a visible error be more honest than a silent fallback?

**Severity:** High
**Detection:** `.catch(() =>` returning a non-error value, or `try/catch` returning cached/default data

### Optional Chaining Hiding Failures

`?.` is appropriate for genuinely optional data. But when used on values that SHOULD exist, it silently skips operations that should have executed.

```ts
// Suspicious — if user MUST exist, this hides a bug
const name = user?.profile?.displayName ?? "Unknown";
```

**Severity:** Medium
**Detection:** `?.` chains longer than 2 levels, or `?.` on values that are fetched and should be non-null

---

## Langfuse / AI Error Handling

### Prompt Fetch Failures

If `fetchChatPrompt()` or `fetchTextPrompt()` fails, the error must be surfaced visibly. Never silently fall back to a stale or hardcoded prompt.

```ts
// HIGH — user gets wrong/stale AI behavior with no indication
const prompt = await fetchChatPrompt("review").catch(() => fallbackPrompt);

// CORRECT — surface the failure
const prompt = await fetchChatPrompt("review");
// If this throws, the API route's top-level error handler catches it
// and returns a 500 to the user
```

**Severity:** High
**Detection:** `fetchChatPrompt` or `fetchTextPrompt` wrapped in `.catch` that returns a fallback value

### AI SDK Error Boundaries

`streamText()` and `generateObject()` calls should have error handling that surfaces failures to the user, not swallows them.

**Severity:** Medium

---

## Realtime Error Handling

### Channel Error Handlers

Every `.subscribe()` must include a status callback that checks for `CHANNEL_ERROR` and `TIMED_OUT`:

```ts
.subscribe((status) => {
  if (status === "CHANNEL_ERROR" || status === "TIMED_OUT") {
    captureException(new Error("Realtime channel error"), {
      extra: { channel: channelName, status, id },
    });
  }
});
```

**Severity:** Medium
**Detection:** `.subscribe()` with no callback, or callback that doesn't check error statuses

### Race Condition Guard

Async setup in `useEffect` must use a `cancelled` flag to prevent state updates after unmount:

```ts
let cancelled = false;
async function setup() {
  // ... async work (e.g., supabase.auth.getUser())
  if (cancelled) return;
  // ... channel operations
}
setup();
return () => {
  cancelled = true;
  if (channel) supabase.removeChannel(channel);
};
```

**Severity:** Medium
**Detection:** `useEffect` with async function that calls `supabase.auth.getUser()` or other async API without a cancellation guard

---

## Supabase Error Handling

### Unchecked Query Errors

Supabase client calls return `{ data, error }`. If `error` is not checked, failures are invisible:

```ts
// MEDIUM — error silently ignored
const { data } = await supabase.from("projects").select("*");

// CORRECT
const { data, error } = await supabase.from("projects").select("*");
if (error) throw error; // or handle appropriately
```

**Severity:** Medium (reads), High (writes/mutations)
**Detection:** Supabase `.from()` calls that destructure only `data` without `error`

### RPC Function-Not-Found

Missing `p_` prefix on RPC parameters causes "function does not exist" errors at runtime. If an RPC call is wrapped in a catch that returns a generic error, the root cause (wrong parameter name) is hidden.

**Severity:** Medium (flagged in conjunction with correctness dimension)
