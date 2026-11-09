---
description: Investigate a reported Business Central bug without changing code — gather details, ask questions, find the root cause, and write docs/bugs/CU-<id>.md with a fix proposal for the user to approve. Run /bug-implement afterwards.
argument-hint: [CU-<id> or docs/specs/CU-<id>.md]
---

You are investigating a bug for: **$ARGUMENTS**

## Hard rule: no code changes

This command changes **no** AL code, tests, feature docs, UAT scripts, app.json
or CHANGELOG. The only files you may write are `docs/bugs/CU-<id>.md` and the
answers section of `docs/specs/CU-<id>.md`. Do not dispatch `al-base-coding`
or `al-documentation`. If the user asks to fix it during this command, finish
the bug document, get approval, and point them to `/bug-implement CU-<id>`.

## 0. Preconditions
- Resolve the CU id. Read `docs/specs/CU-<id>.md`; if it does not exist,
  suggest `/clickup-task start <id>` first (or fetch the task and its comments
  via the ClickUp MCP server if the user prefers to skip the spec).
- The branch must not be main and should be `fix/CU-<id>-...` or
  `hotfix/CU-<id>-...`. If not, stop and ask the user.
- If `docs/bugs/CU-<id>.md` already exists, continue from it (read the Q&A
  log and status) instead of starting over.

## 1. Pin down the symptom

Load the `bug-investigation` skill. Check which items of its step 1 table are
known from the spec, the ClickUp task and its comments. Ask the user for the
missing ones that matter (AskUserQuestion, at most 4 questions per round; free
text via "Other" is fine for repro steps and error texts). Do not ask for what
is already in the spec or task.

## 2. Root-cause analysis

Dispatch to the `al-investigator` subagent with the symptom details, the Q&A so
far, and the related feature doc/spec if known. Ask for a root-cause analysis
per the `bug-investigation` skill: entry point, execution path, ranked
hypotheses with `file:line` evidence and confidence, classification, fix
options, regression test, data impact, and questions for the user.

## 3. Follow-up questions

If the result has questions, or several hypotheses remain plausible, ask the
user the questions that decide between them (AskUserQuestion). For questions
only the customer can answer, offer to post them on the ClickUp task via
`/clickup-task comment <id> <text>` — only with the user's consent — and set the
bug document's status to `Awaiting information`.

With new answers, send them back to `al-investigator` to confirm or rule out
hypotheses (SendMessage to the same agent keeps its context). Repeat until the
root cause has high confidence, or until it's clear only data/reproduction in
an environment can settle it — then say so plainly.

## 4. Write the bug document

Write `docs/bugs/CU-<id>.md` from `.claude/skills/bug-investigation/template.md`:
symptom, repro steps, the full Q&A log (every question and answer, dated),
root cause with evidence, ruled-out hypotheses, fix options with a
recommendation, regression test, impact. Status `Awaiting approval` (or
`Awaiting information` if blocked). Add a link to it in the spec.

## 5. Approval — STOP

Present a short summary to the user: root cause (2–3 sentences), the
recommended option and alternatives, data impact, and the link to the bug
document. Ask which option to approve (AskUserQuestion), or for corrections.

- On approval: set Status to `Approved <date> — option <n>` and note any
  conditions the user added. Then tell the user to run
  `/bug-implement CU-<id>`. Do not start implementing.
- On corrections: update the document (and re-run step 2/3 if the root cause
  is challenged), then ask again.
- If the classification is not a code bug (data/setup, works as designed,
  standard BC): no implementation follows. Record the recommendation (data
  correction, setup change, or a new Change task) and offer to post it as a
  ClickUp comment.

Do not commit. Suggest the commit message "CU-<id>: Bug investigation" if the
user wants the document in version control.
