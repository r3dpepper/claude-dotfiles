# Coding Style Baseline

Universal defaults. Language-specific files (e.g.
`rules/typescript/coding-style.md`) override these where idioms differ.

## Naming

- **Variables/functions**: descriptive, no abbreviations
  (`marketSearchQuery` not `q`).
- **Booleans**: read like a question (`isReady`, `hasPermission`,
  `shouldRetry`).
- **Constants**: `SCREAMING_SNAKE_CASE` only for true compile-time
  constants; otherwise use `const` with normal casing.
- **Files**: match the project's existing convention
  (kebab-case for web, snake_case for Python, PascalCase for React
  components, etc.). Don't mix.

## Structure

- **One responsibility per function**. If you need "and" to describe it,
  split it.
- **Small files** — under ~300 lines is a soft target. Over 800 is
  almost always a sign to extract.
- **No deep nesting** — 3 levels max. Use early returns or extract
  helpers.
- **Immutability by default** — don't mutate inputs; return new values.
  *Why:* mutation is the root cause of most state-related bugs and
  makes reasoning about code expensive.

## Errors

- **Don't swallow errors**. Empty `catch {}` blocks are bugs waiting
  to happen.
- **Throw with context** — include what was being attempted and what
  input caused the failure.
  `throw new Error(\`fetchUser(${id}): ${err.message}\`)`
- **Handle errors at the boundary**, not at every call site. Internal
  helpers can let errors bubble; HTTP handlers, event handlers, and
  top-level `main()` should catch and translate.

## Comments

- **Self-documenting code first**. A comment is a smell that the code
  could be clearer. Try renaming first.
- **Comment the why, not the what**. `// clamp to int32 max` is fine;
  `// increment i` is noise.
- **TODOs need tickets**. `// TODO: handle this` is unfinished
  business. Either file a ticket and reference it, or fix it now.

## Anti-patterns to flag in review

- Mutation of function arguments.
- `any` / untyped JSON / `as unknown as T` casts.
- Hardcoded magic numbers — name them or make them constants.
- Copy-pasted blocks > 5 lines — extract a helper.
- `console.log` left in non-debug code.
- Long parameter lists (> 4 args) — group into an options object.

## Why

Style rules aren't about taste — they're about making the next person
faster. Self-describing code and small functions reduce the time between
"what does this do?" and "I trust this code."
