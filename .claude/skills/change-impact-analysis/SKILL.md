---
name: change-impact-analysis
description: Use when a ClickUp task of type Change modifies an existing AL/Business Central feature — to find the original feature, map what the change touches (objects, schema, tests, docs, UAT scripts, translations) and flag breaking-change and upgrade risks before planning. Used by /new-change and by the al-investigator subagent.
---
# Change impact analysis

A Change alters behaviour that already exists, was tested, documented and
possibly accepted by the customer. The risk is not in the new code but in what
the change silently breaks. Produce an impact map before any plan.

## 1. Find the baseline

- The original feature: the change spec usually names it (a CU id, a feature
  name, a ClickUp link). Otherwise search `docs/features/` and `docs/specs/` by
  object names and terms from the change request. If it is ambiguous, ask —
  don't pick one.
- Read the original spec (acceptance criteria, answered open questions, plan)
  and feature doc (including any "Deviations from the approved plan" and
  "Change history" sections). The answered open questions are earlier customer
  decisions; flag any the change contradicts.
- Use `git log --oneline -- <paths>` to see every task that touched those
  objects since; later Changes or bug fixes may have altered the baseline.

## 2. Map the impact

For each item, give file paths and a one-line description of what changes:

| Area | What to check |
|---|---|
| AL objects | Tables, table extensions, pages, codeunits, reports, enums, events touched by the change. Include callers and event subscribers of changed procedures. |
| Schema | Field additions are safe. Field removal, rename, type or length reduction, primary-key change, or enum value removal are **not allowed**: use `ObsoleteState` (Pending → Removed in a later version) and an upgrade codeunit with an upgrade tag. Note any data that must be migrated. |
| Public contract | Changed signatures of public procedures or published events break subscribers and other apps. Prefer adding an overload / new event and obsoleting the old one. |
| Existing data | Records created under the old behaviour: do they stay valid, need migration, or need a one-off correction? AC like "no retroactive effect" matter here. |
| Tests | Existing test procedures whose expectations change (update), become irrelevant (remove or rewrite, and say why), or stay valid (keep — they are the regression net). New tests needed for the new acceptance criteria. Permission tests if new objects are added. |
| Permissions | New objects → `ATT CUSTOM` permission set. |
| Translations | New/changed captions and labels → XLIFF (nl-BE, en-US). |
| Docs | Feature doc sections that become wrong, UAT script scenarios to update/add, CHANGELOG entry. |
| Reports/layouts | Changed fields used in report datasets or layouts. |

## 3. Risks and questions

- List concrete risks (e.g. "existing setups with Mandatory = Yes will start
  blocking order release").
- List questions where the change request is silent on existing behaviour,
  existing data, or a contradiction with an earlier answered open question.

## Report structure

1. Baseline (original CU, spec, feature doc, later tasks that touched it)
2. Impact map (table above, only rows that apply)
3. Tests: keep / update / remove / add
4. Risks
5. Questions for the user
