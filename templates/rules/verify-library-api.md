# Rule: Verify Library API

Before using any library API — especially fast-moving ones (Next.js, shadcn, Supabase SDK, AG Grid, etc.) — verify against the installed version, not training data.

## Process

1. **Check the installed version:**
   ```bash
   cat node_modules/{package}/package.json | grep version
   ```

2. **Read the actual source** in `node_modules/` for the specific function/component you're about to use. Training data is reliably wrong on recent API changes.

3. **Never assume:**
   - Function signatures haven't changed
   - Config options still exist
   - Import paths are the same
   - Default behaviors haven't flipped

## When This Applies

- Any library call you haven't verified this session
- Especially after upgrading dependencies
- Especially for: Next.js App Router APIs, shadcn/ui components, Supabase client methods, any SDK with major version changes in the last 6 months

## Red Flag

If you catch yourself thinking "I know this API" — that's the signal to check. The more confident you are, the more likely your training data is stale.
