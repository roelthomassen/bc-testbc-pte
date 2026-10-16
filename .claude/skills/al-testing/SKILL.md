---
name: al-testing
description: Use when writing or reviewing AL test codeunits for Business Central (unit or integration tests) — test codeunit structure, naming, isolation, and use of Library/Assert helper codeunits.
---

# AL testing conventions

## Structure

- Tests live in codeunits with `Subtype = Test;`. Microsoft's own recommendation
  (and this framework's default) is a **separate test app** per extension
  (`<YourApp>.Test`), depending on the app under test, rather than mixing test
  and production objects in one app — keeps test-only dependencies out of what
  ships. If the project already mixes them, follow the existing convention rather
  than restructuring mid-feature.
- One test codeunit per feature/scenario area, not one giant catch-all codeunit.
  Name it after what it tests, e.g. `"MyPrefix Sales Line Validation Tests"`.
- Each test procedure has the `[Test]` attribute and a name that states the
  scenario and expectation, e.g.
  `SettingQuantityAboveStock_ThrowsError()` or
  `PostingSalesInvoice_CreatesGLEntries()` — a failing test name alone should tell
  you what broke.

## The Initialize / Given-When-Then shape

- Use an `Initialize` procedure (often with a `IsInitialized` boolean guard, or
  a library "clean database" call) to set up common preconditions once, called at
  the start of each test.
- Structure the body of each test in three clear parts, even without literal
  comments: **Given** (arrange test data — prefer `Temporary` records or library
  helper codeunits over hand-rolled setup), **When** (the single action under
  test), **Then** (assertions via the `Assert` codeunit — `Assert.AreEqual`,
  `Assert.IsTrue`, `Assert.ExpectedError`, etc., with a descriptive message as the
  last argument).
- Keep one logical behavior per test procedure. A test that asserts five unrelated
  things is five tests wearing a trenchcoat — split it so a failure points at one
  cause.

## Isolation

- Tests must not depend on execution order or leftover data from another test.
  Prefer temporary/in-memory records where the logic under test allows it;
  otherwise use the project's transaction-rollback or clean-database convention
  consistently.
- Mock user interaction with `ConfirmHandler`, `MessageHandler`, `StrMenuHandler`,
  etc. (`[ConfirmHandler]` on a handler procedure, `HandlerFunctions` attribute on
  the test) instead of relying on default UI responses — an untested confirm
  dialog is a common source of tests that pass locally and fail in CI.
- Use the standard Library codeunits (`Library - Sales`, `Library - Inventory`,
  `Library - Random`, etc.) for creating realistic test data instead of
  hand-building records field by field, when a suitable library exists in the app
  graph.

## What to cover for a change

At minimum, for any new or changed logic:

1. The main success path.
2. At least one validation/error path, asserted with `Assert.ExpectedError`
   (or equivalent) — not just "it doesn't crash."
3. Edge cases explicitly called out in the plan (empty/zero input, boundary
   values, pre-existing data that conflicts with the new logic).

## Applying this skill

When writing tests: follow the naming and Given/When/Then shape above so the next
person (or subagent) can read a failing test name and know what to check first.
When reviewing tests: check that the success path, at least one failure path, and
any plan-specified edge cases are actually covered — a test file that only
exercises the happy path is incomplete coverage, not "should be fine."
