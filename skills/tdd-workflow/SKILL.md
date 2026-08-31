---
name: tdd-workflow
description: Test-driven development procedure. Red-green-refactor with a single failing test driving each change. Use when implementing new behavior, fixing a bug, or refactoring. Includes guidance on when TDD is the wrong tool.
when_to_use: |
  Use when the user is writing new code, fixing a bug, or refactoring
  and asks for tests-first / TDD / red-green-refactor. Trigger phrases:
  "write a failing test first", "let's TDD this", "red-green-refactor",
  "do this test-first", "implement X with TDD". Do NOT auto-load for
  general code edits, exploration, or tasks that don't involve writing
  tests.
allowed-tools: Read Edit Write Grep Glob Bash(npm test*) Bash(npm run*) Bash(npx *) Bash(pytest*) Bash(python -m pytest*) Bash(yarn *) Bash(pnpm *) Bash(bun *) Bash(cargo test*) Bash(go test*) Bash(make test*)
metadata:
  origin: claude-dotfiles
---

# TDD Workflow

When implementing new behavior, follow red-green-refactor. The test is
not a check at the end — it's the design tool that drives every step.

## The loop

1. **Red** — write a single failing test for the smallest piece of
   the new behavior. The test must fail for the right reason (the
   behavior is missing), not for an unrelated reason (compile error,
   missing fixture).
2. **Green** — write the *minimum* code that makes the test pass.
   This often feels uncomfortably trivial. Resist the urge to write
   more.
3. **Refactor** — now that you have a passing test, clean up. Rename
   for clarity, extract duplication, simplify the structure. The
   test stays green throughout.
4. **Repeat** — pick the next behavior and go.

## What "smallest piece" means

- One new branch, not the whole function.
- One new case, not the full table.
- One new error path, not every error path at once.

If your red step touches more than ~20 lines of test code, you're
writing tests for things that don't exist yet. Split it.

## What "minimum" means

Green is the *least* code that makes the test pass. Common
temptations to resist:

- Adding tests for cases the current red didn't ask for
- Implementing the next behavior "while you're here"
- Adding input validation before it's tested
- Optimizing before there's a profiler

Each of these is a separate red-green-refactor cycle.

## Bug fixes

The same loop, but the red step writes a test that **reproduces the
bug**:

1. **Red** — write a test that fails because the bug is present.
   Run it, watch it fail. If it passes, you're not testing the bug
   you're fixing.
2. **Green** — fix the bug. Test passes.
3. **Refactor** — clean up the fix if needed.
4. **Commit** — the test goes in with the fix. Future regressions
   of this bug fail loudly.

## Refactoring

Refactoring has a special shape: the test is the **safety net**, not
the driver.

1. Confirm the test suite is green before you start.
2. Make structural changes in small steps. After each step, the
   suite stays green.
3. If a step breaks the suite, undo it. Either split it smaller, or
   the test is telling you the change is more than cosmetic.
4. Commit each green step as a separate commit. Easier to review,
   easier to revert.

## When TDD is the wrong tool

Don't force TDD into situations where it doesn't fit:

- **Exploratory work** — you don't know what shape the code should
  take. Spike first, throw away the spike, then TDD the real thing.
- **Trivial changes** — typo fixes, doc updates, formatting.
  Write the change, eyeball it, commit.
- **UI / visual work** — tests can verify behavior but not
  aesthetics. Use the test for behavior, eyeball the visuals.
- **Generated code** — schema migrations, protobuf stubs. Review
  the generator output, don't write tests for what the generator
  already guarantees.
- **One-line fix obvious from the error message** — just fix it.
  A test is overhead if the failure mode is the test name.

In all of these, a test *might* still be valuable as a regression
guard. That's a separate decision from the development workflow.

## Common mistakes

- **Skipping red** — writing code first, then tests. You end up with
  tests that exercise the code you wrote, not the behavior you wanted.
- **Testing implementation, not behavior** — `expect(mock).toHaveBeenCalledWith(x)`
  is brittle. Test what the function returns, not how it gets there.
- **Big-bang tests** — one test that covers 12 cases. When it fails,
  you don't know which case broke. Split it.
- **Test code as second-class** — copy-pasted setup, magic
  numbers, no names. Test code is code. Treat it well.
- **Refusing to refactor** — green is the *minimum*, not the
  destination. Always spend the third step.

## Why

TDD is faster than "code then test" in the long run because:

- The test forces you to design the interface before implementing
  it. Bad designs fail loudly at the test, not in production.
- The suite is regression-safe from line one. You can refactor with
  confidence.
- The cost of finding a bug is "while you're writing it" instead
  of "during integration / in production".
- The tests become documentation that never lies, because they
  fail when the documentation is wrong.
