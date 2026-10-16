---
description: Plan, implement, test, document, and review a new Business Central AL feature end-to-end using the al-base-coding, al-documentation, and al-guidelines subagents.
argument-hint: [feature description]
---

You are orchestrating the full lifecycle of an AL feature for: **$ARGUMENTS**

Follow this sequence. Do not skip a phase, and do not let a subagent do another
subagent's job (e.g. don't let `al-base-coding` write the feature doc, and don't
write the AL code yourself instead of delegating). Keep your own output between
phases short — a couple of lines saying what phase just finished and what's next,
not a full restatement of what the subagent said.

## 0. Preconditions
- If $ARGUMENTS points to a file in docs/specs/, read it: its acceptance
 criteria are the acceptance criteria for this feature.
- Check the current branch: it must not be main and should contain the
  CU-<id> of the spec. If not, stop and ask the user.

## 1. Plan

Produce a short implementation plan before any code is written:
- The AL objects to create or change (tables, pages, codeunits, reports, enums,
  permission sets, events) with proposed names consistent with this project's
  existing prefix/affix and ID range (check `app.json` and neighboring objects).
- The data model / fields involved, and how they relate to existing objects.
- The UI or API surface, if any.
- Explicit acceptance criteria / edge cases to cover in tests.

If the request is genuinely ambiguous about scope or behavior, ask the user before
proceeding rather than guessing at something that changes the data model. If it's
a small, unambiguous change, keep the plan to a few lines and move on.
 
- Present the plan and STOP. Continue only after the user approves it.
Then append the approved plan to the spec file.

## 2. Code + tests

Dispatch to the `al-base-coding` subagent with the plan and any relevant existing
file paths. Ask it explicitly to both implement the objects **and** write the
accompanying AL test codeunit(s) for the acceptance criteria from the plan — these
are not two separate dispatches, but make sure its response actually covers both;
if it only did the implementation, send it back for the tests before moving on.

## 3. Documentation

Dispatch to the `al-documentation` subagent with the list of files/objects
`al-base-coding` created or changed. Ask for XML doc comments on new public
procedures/events, a feature doc under `/docs`, and a `CHANGELOG.md` entry.

## 4. Guidelines review

Dispatch to the `al-guidelines` subagent with the full list of files changed across
steps 2 and 3 (not the whole repo). Ask for a findings report by severity
(blocker/major/minor/info), each with a BCQuality citation where applicable.

## 5. Close the loop

- If there are **blocker** or **major** findings: send the specific findings back
  to whichever subagent owns that file (`al-base-coding` for code/tests,
  `al-documentation` for docs) to fix, then re-run step 4 on just the re-touched
  files. Repeat until no blocker/major findings remain, or until it's clear a
  finding is a judgment call the user should weigh in on — in that case, surface
  it instead of looping indefinitely.
- Minor/info findings don't need to block completion — mention them in your final
  summary as optional follow-ups.

## 6. Summarize

Give the user a concise close-out: what was built (objects + file paths), what
tests were added and whether they were run, what was documented, and the outcome
of the guidelines review (including anything left unresolved and why). Do not
repeat each subagent's full report verbatim — synthesize.

- Do not commit, push, merge or publish. Suggest the commit message
  "CU-<id>: <summary>" and remind the user of the DEV test (step 8).