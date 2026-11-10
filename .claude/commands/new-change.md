---
description: Change an existing Business Central AL feature end-to-end — impact analysis, approved plan, code and test changes, documentation updates, and guidelines review — for a ClickUp task of type Change.
argument-hint: [docs/specs/CU-<id>.md or change description]
---

You are orchestrating a **Change** to existing AL functionality for: **$ARGUMENTS**

A Change modifies behaviour that is already built, tested, documented and
possibly accepted by the customer. Existing tests and docs are part of the
baseline: update them deliberately, never just to make them pass. Follow the
phases in order; delegate the work as in `/new-feature`. Keep your own output
between phases to a couple of lines.

## 0. Preconditions
- If $ARGUMENTS points to a spec in docs/specs/, read it: its acceptance
  criteria define the change. If there is no spec, suggest
  `/clickup-task start <id>` first.
- If the spec's Type is Feature or Bug, say so and suggest `/new-feature` or
  `/bug-investigate` instead; continue only if the user confirms.
- The current branch must not be main and should be `change/CU-<id>-...`.
  If not, stop and ask the user.

## 1. Impact analysis

Dispatch to the `al-investigator` subagent with the spec and ask for an impact
analysis following the `change-impact-analysis` skill: the original feature
(spec, feature doc, UAT script), the objects, schema, tests, permissions,
translations and docs the change touches, the risks, and questions for the user.

If the original feature cannot be identified, or the investigator returns
questions that affect the design, ask the user (AskUserQuestion, at most 4 per
round) and record the answers in the spec's "Open questions" section, in the
same **Answer:** style as existing specs.

## 2. Plan

Produce a change plan, proportional to the change:
- **Baseline**: original CU / feature doc being changed.
- **Objects to change or add** (with IDs in the app.json range, `ATT` affix),
  and what changes in each.
- **Schema/upgrade**: any field changes; never delete/rename/retype fields —
  ObsoleteState + upgrade codeunit with upgrade tag. Existing data handling.
- **Tests**: which existing test procedures are kept, updated (old → new
  expectation), removed (why), and which are added per acceptance criterion.
- **Docs**: feature doc sections, UAT scenarios, CHANGELOG.
- **Risks** from the impact analysis.

Present the plan and STOP. Continue only after the user approves it. Then
append the approved plan to the spec under "## Plan" with the approval date.

## 3. Code + tests

Dispatch to `al-base-coding` with the approved plan, the impact analysis and
the file paths. Ask it to:
- change the existing objects (prefer modifying in place over duplicating
  logic; respect the schema rules above),
- update the existing test codeunits per the plan's keep/update/remove list
  and add tests for the new acceptance criteria,
- run the full existing test suite of the affected app if a runner is
  reachable, not only the new tests — a Change must not break existing
  behaviour that it does not intend to change.
If it only changed code, send it back for the tests before moving on.

## 4. Documentation

Dispatch to `al-documentation` with the list of changed files and the plan. Ask
it to:
- **update** the existing feature doc in `docs/features/` (do not create a new
  one) so it describes the behaviour after the change, and add an entry to a
  "## Change history" section at the end: date, CU-<id> with ClickUp link, one
  line on what changed and a link to the change spec;
- update the UAT script in `docs/uat/` for the feature: adjust affected
  scenarios and add scenarios for the new acceptance criteria (create
  `docs/uat/CU-<id>-<short-name>.md` only if the feature has no UAT script);
- update XML doc comments on changed public procedures/events;
- add a CHANGELOG.md entry under "Changed".

## 5. Guidelines review

Dispatch to `al-guidelines` with the full list of changed files from steps 3
and 4. Ask for findings by severity, and explicitly for the BCQuality
breaking-changes and upgrade domains, plus whether the test changes match the
plan (no expectations weakened without a reason in the plan).

## 6. Close the loop

As in `/new-feature`: send blocker/major findings back to the owning subagent,
re-review the re-touched files, repeat until none remain or a finding needs the
user's judgment. Minor/info findings go into the summary.

## 7. Summarize

Concise close-out: what changed (objects + file paths), test changes
(kept/updated/removed/added) and whether they ran, docs updated, upgrade/data
impact, and the review outcome.

- Do not commit, push, merge or publish. Suggest the commit message
  "CU-<id>: <summary>" and remind the user to test on DEV.
