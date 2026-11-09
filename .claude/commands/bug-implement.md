---
description: Implement the approved fix for a Business Central bug from docs/bugs/CU-<id>.md — regression test first, minimal fix, documentation and guidelines review. Requires a completed /bug-investigate.
argument-hint: [CU-<id> or docs/bugs/CU-<id>.md]
---

You are implementing the approved fix for: **$ARGUMENTS**

The bug document `docs/bugs/CU-<id>.md` is the source of truth: implement the
approved option, nothing more. Delegate as in `/new-feature`; keep your own
output between phases to a couple of lines.

## 0. Preconditions
- Read `docs/bugs/CU-<id>.md`. If it does not exist, or its Status is not
  `Approved ...`, stop and tell the user to run `/bug-investigate CU-<id>`
  first. Never implement an unapproved fix.
- The branch must not be main and should be `fix/CU-<id>-...` or
  `hotfix/CU-<id>-...`. If not, stop and ask the user.
- Check whether the code the root cause points to (`file:line` references)
  changed since the investigation (`git log` since the document's date). If it
  did in a way that affects the root cause, have `al-investigator` re-verify
  before continuing and tell the user.

## 1. Regression test + fix

Dispatch to `al-base-coding` with the bug document (root cause, approved
option, regression test, impact). Ask it to:
1. Write the regression test from the bug document first, so it reproduces the
   bug (if a runner is reachable, confirm it fails before the fix).
2. Implement the approved option with the smallest change that fixes the root
   cause — no refactoring or unrelated clean-up. Respect the schema rules
   (ObsoleteState + upgrade codeunit with upgrade tag; never delete/rename/
   retype fields). If the document calls for a data correction, implement it
   as described there (e.g. upgrade codeunit with an upgrade tag).
3. Run the regression test and the existing tests of the affected app, if a
   runner is reachable, and report results honestly.
4. Report any deviation from the approved option, and why.

If the fix turns out to need more than the approved option (a different root
cause, a schema change not in the document, wider blast radius): stop, explain
to the user, update the bug document, and get approval again before
continuing.

## 2. Documentation

Dispatch to `al-documentation` with the changed files and the bug document.
Ask it to:
- add a CHANGELOG.md entry under "Fixed", written from the user's perspective;
- update the related feature doc in `docs/features/` only if it described the
  wrong behaviour or a limitation that is now gone, and add a line to its
  "## Change history" section (date, CU-<id>, link to the bug document);
- add a retest scenario for the bug to the related UAT script in `docs/uat/`
  (the repro steps, now with the expected result);
- update XML doc comments on any changed public procedure/event.

## 3. Guidelines review

Dispatch to `al-guidelines` with the full list of changed files. Ask for
findings by severity, and explicitly whether the regression test actually
exercises the root cause described in the bug document (not just the symptom),
and whether the fix stays within the approved option.

## 4. Close the loop

As in `/new-feature`: send blocker/major findings back to the owning subagent,
re-review the re-touched files, repeat until none remain or a finding needs the
user's judgment.

## 5. Close the bug document and summarize

- Fill the "Resolution" section of `docs/bugs/CU-<id>.md` (files changed,
  tests added and whether they ran, review outcome, deviations) and set Status
  to `Fixed <date>`.
- Give the user a concise close-out: the fix (objects + file paths), the
  regression test and test results, docs updated, review outcome.
- Do not commit, push, merge or publish. Suggest the commit message
  "CU-<id>: Fix <summary>" and remind the user to retest the repro steps on DEV.
