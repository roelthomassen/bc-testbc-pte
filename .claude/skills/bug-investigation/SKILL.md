---
name: bug-investigation
description: Use when investigating a reported bug in AL/Business Central code — reproducing it on paper, tracing the root cause, and writing the bug document docs/bugs/CU-<id>.md that /bug-implement works from. Used by /bug-investigate and by the al-investigator subagent.
---
# Bug investigation

The goal is a root cause backed by evidence and an approved fix proposal, not
a fix. No AL code, test or feature doc changes during investigation — the only
file written is the bug document, and only by the main agent.

## 1. Pin down the symptom

Before reading code, make sure these are known (from the spec, the ClickUp task
and its comments, or by asking the user):

| Item | Why |
|---|---|
| Steps to reproduce | Without them you're guessing which code path runs. |
| Expected vs. actual result | Distinguishes a bug from a misunderstood feature. |
| Error message text, exactly | Searchable in code (`Error(`, labels, XLIFF). |
| Environment, company, app version | LIVE vs. TEST, BC 28.5 BE, which build of the app. |
| Since when / always or sometimes | Points to a recent change, or to data/setup dependence. |
| Affected records (document no., item no.) | Lets the user check data, and helps spot data-dependent paths. |
| User / permission set | Permission errors look like bugs. |

Anything missing that changes the outcome is a question for the user.

## 2. Trace the root cause

1. **Locate the entry point** — the page action, field validation, posting
   routine or report that the repro steps exercise. Search for the error
   message label, the field name, the action caption (also in the XLIFF files
   under `Customer Extensions/Translations/` — users report Dutch captions).
2. **Follow the execution path** through triggers, procedures and event
   subscribers. List every subscriber on the events involved.
3. **Check standard BC behaviour** where the path enters the base app; confirm
   with Microsoft Learn rather than memory.
4. **Check history** — `git log`/`git blame` on the suspect lines. Which CU task
   introduced it? Does its spec say the behaviour is intended?
5. **Form hypotheses**, ranked, each with evidence (`file:line`), a confidence
   level, and what would confirm/refute it. Stop at the root cause, not the
   first symptom: "variable is blank" is a symptom; "SetLoadFields omits the
   field, so it is never read" is a cause.
6. **Classify**: code bug / data or setup issue / works as designed (spec says
   so) / standard BC behaviour. Only a code bug leads to a code fix; the others
   lead to a recommendation (data correction, setup change, a Change task).

## 3. Assess the fix

- **Options** — usually a minimal fix and, if relevant, a more structural one.
  Recommend one and say why.
- **Regression test** — the AL test that fails today and passes after the fix
  (name, given/when/then). Follow the `al-testing` skill conventions.
- **Data impact** — has the bug already written wrong data? If yes, does that
  need a correction (upgrade codeunit with upgrade tag, or a one-off report),
  and who decides?
- **Blast radius** — other callers of the changed code, other features that
  rely on the current (wrong) behaviour, schema impact (never delete/rename
  fields or change types: ObsoleteState + upgrade codeunit).

## 4. The bug document

Write `docs/bugs/CU-<id>.md` using [template.md](template.md). Keep it factual
and short; the Q&A log records every question asked and the answer received
(with the date), so the implementer never has to ask again.

The `Status` line drives the workflow:
- `Awaiting information` — open questions block the root cause.
- `Awaiting approval` — root cause and fix proposal ready for the user.
- `Approved YYYY-MM-DD — option <n>` — set only after explicit user approval;
  `/bug-implement` refuses to run without it.
- `Fixed YYYY-MM-DD` — set by `/bug-implement` after implementation.
