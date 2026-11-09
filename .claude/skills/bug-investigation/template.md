# CU-<id>: <short bug title>

- ClickUp: [<task name>](https://app.clickup.com/t/<id>)
- Spec: [docs/specs/CU-<id>.md](../specs/CU-<id>.md)
- Branch: `fix/CU-<id>-<short-name>`
- Related feature: [<feature doc>](../features/<file>.md) (CU-<feature id>)
- Status: Awaiting information | Awaiting approval | Approved YYYY-MM-DD — option <n> | Fixed YYYY-MM-DD

## Reported symptom

<What the user sees, in their words, plus the exact error text if any.>

| | |
|---|---|
| Environment / company | |
| App version | |
| User / permission sets | |
| Frequency | Always / sometimes (conditions) |
| Since | |
| Example records | |

### Steps to reproduce
1.
2.

**Expected:** 
**Actual:** 

## Q&A log

| Date | Question | Answer | Source |
|---|---|---|---|
| | | | user / ClickUp comment / data check |

Open questions (if any):
- 

## Root cause

**Classification:** Code bug | Data/setup issue | Works as designed | Standard BC behaviour
**Confidence:** High | Medium | Low

<Explanation of the cause with `file_path:line` references. Explain why the
code produces the wrong result, not only where.>

**Introduced by:** <commit / CU task, or "original implementation">

### Hypotheses ruled out
- <hypothesis> — <evidence that rules it out>

## Proposed fix

### Option 1 (recommended): <name>
- Change: <objects/procedures and what changes>
- Pros / cons:

### Option 2: <name>
- Change:
- Pros / cons:

## Regression test

- Test codeunit: `<name>` (`Customer Extensions Test/src/...`)
- `[Test] <ProcedureName>`: Given … When … Then …

## Impact

- **Affected objects:** 
- **Other callers / features relying on current behaviour:** 
- **Schema impact:** none | <fields; ObsoleteState + upgrade codeunit needed>
- **Existing wrong data:** none | <what, how many, correction approach>
- **Docs to update:** feature doc / UAT script / CHANGELOG

## Resolution

<Filled by /bug-implement: what was changed (files), tests added and whether
they ran, guidelines review outcome, deviations from the approved option.>
