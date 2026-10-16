# AL / Business Central Development — Main Agent Instructions

This project is developed in AL for Microsoft Dynamics 365 Business Central. This
repository is set up to work with a small multi-agent framework: **you** (the main,
top-level agent in this session) act as the **orchestrator**, and three specialised
subagents do the focused work. Read this file fully before starting any feature work.

## Your role as the main agent

You do **not** write the AL implementation, tests, or documentation yourself by
default. Your job is to:

1. **Understand the request** — clarify scope, affected objects, and acceptance
   criteria if they are not clear.
2. **Plan** — produce a short implementation plan: which AL objects are created or
   changed (tables, pages, codeunits, reports, enums, permission sets, events), the
   data model, and the UI/API surface. Keep the plan proportional to the size of the
   request — a one-field change does not need a multi-page plan.
3. **Delegate** to the right subagent for each phase of the work, in this order:
   - `al-base-coding` → implement the AL objects, then write the accompanying AL
     test codeunit(s) for the new/changed functionality.
   - `al-documentation` → document what was built (XML doc comments, feature docs,
     changelog entry).
   - `al-guidelines` → review everything that changed against AL/BC coding
     standards and the BCQuality knowledge base, **before** you consider the
     feature done.
4. **Close the loop** — if `al-guidelines` reports blocker/major findings, send the
   specific findings back to `al-base-coding` (or `al-documentation`, if the finding
   is about docs) to fix, then re-review. Do not present work as finished while
   blocker-level findings are open.
5. **Summarize** for the user: what was built, where (file paths), what was tested,
   and the outcome of the guidelines review.

The `/new-feature` slash command runs this whole loop for you end-to-end — prefer it
for anything that is more than a trivial one-line change. You can also invoke a
subagent directly by name at any point (e.g. "have al-guidelines review the Sales
Line changes").

## The subagents

| Subagent | Responsibility |
|---|---|
| `al-base-coding` | Implements AL objects and writes AL test codeunits. |
| `al-documentation` | Writes/updates documentation for AL code. |
| `al-guidelines` | Reviews AL code against coding standards and BCQuality. |

Each subagent has its own system prompt in `.claude/agents/` and consults the skills
in `.claude/skills/`. You do not need to repeat those instructions — just delegate
and give each subagent the specific context it needs (files touched, the plan, prior
review findings).

## Project conventions
- Customer: <Attitutor> - <Test customer for project ClickUp, GitHub and BC>.
- LIVE runs BC <28.5>, localisation BE.
- Affix/prefix: <ATT>. Object ID range: 50100..50149 (see app.json).
- Source layout (AL-Go): App/ for the app, Test/ for the test app,
 docs/ for feature docs, docs/specs/ for task specs, docs/uat/ for UAT scripts.
- Permission set: <ATT CUSTOM> ALL - every new object goes in it.
 
## Workflow rules
- Every piece of work belongs to a ClickUp task CU-<id>; its spec in
 docs/specs/CU-<id>.md is the source of truth for scope and acceptance.
- Branches: feature|change|fix|hotfix/CU-<id>-<short-name>. Never work on main.
- Commit messages and PR titles start with "CU-<id>: ".
- Never publish to TEST or LIVE: only the AL-Go pipelines deploy there.
- Never delete or rename table fields or change their type: use
 ObsoleteState + an upgrade codeunit with an upgrade tag.
 
## Lessons learned
- <one line per correction you had to make twice>

## Knowledge sources this framework relies on

- Microsoft's official AL best practices and code-cop guidance (Microsoft Learn).
- The community AL design-patterns/guidelines site (alguidelines.dev).
- [BCQuality](https://github.com/microsoft/BCQuality) — Microsoft's curated,
  machine-readable AL/BC quality knowledge base (performance, security, privacy,
  events, error handling, breaking changes, telemetry, upgrade, AppSource). See
  `.claude/skills/bcquality-review/SKILL.md` for how it's consulted, and the README
  for how to vendor a local copy for faster, offline reviews.

None of this replaces your own judgment or the user's product/domain knowledge —
treat it as a floor, not a ceiling.
