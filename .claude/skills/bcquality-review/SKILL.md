---
name: bcquality-review
description: Use when reviewing AL/Business Central code for quality issues by consulting the BCQuality knowledge base (github.com/microsoft/BCQuality) — performance, security, privacy, events, error handling, breaking changes, telemetry, upgrade, and AppSource guidance. Use before finalizing any AL feature, not just when explicitly asked for a "quality review".
---

# Consulting BCQuality

[BCQuality](https://github.com/microsoft/BCQuality) is Microsoft's curated,
machine-readable knowledge base of BC/AL-specific gotchas — the things a
general-purpose model would get wrong or miss without it (CodeCop rule numbers,
platform API quirks, non-obvious ordering rules, footgun defaults). It is **not**
a style guide (that's `al-coding-standards`) — it's a set of narrow, single-concern
knowledge files, each citable by path, organized in three layers:

- `microsoft/knowledge/<domain>/` — Microsoft-endorsed, highest trust.
- `community/knowledge/<domain>/` — community-contributed.
- `custom/knowledge/<domain>/` — an organization's own overrides (only exists if
  the project forked BCQuality; usually absent).

Domains include (non-exhaustive): `performance`, `security`, `privacy`, `events`,
`error-handling`, `interfaces`, `breaking-changes`, `telemetry`, `upgrade`,
`appsource`, `ui`. Each layer, when present, is checked in precedence order
`custom` > `community` > `microsoft` — a higher layer can override a lower one's
normative guidance for the same concern.

Each knowledge file is short (under ~100 lines), has YAML frontmatter (`domain`,
`keywords`, `technologies`, `bc-version`, ...), a `## Description` section, and
optional `## Best Practice` / `## Anti Pattern` sections. Code samples, when they
exist, live in sibling `<slug>.good.al` / `<slug>.bad.al` files, not inline.

## Getting access to it

**Prefer a local copy** — much faster and works without network access mid-review:

```
git submodule add https://github.com/microsoft/BCQuality.git .bcquality
```

(or a plain `git clone` if the project doesn't use submodules). If `.bcquality/`
exists in the repo, use `Grep`/`Glob`/`Read` directly against
`.bcquality/microsoft/knowledge/`, `.bcquality/community/knowledge/`, and
`.bcquality/custom/knowledge/`.

**Fallback**: if there's no local copy, fetch individual files with `WebFetch`
from `https://raw.githubusercontent.com/microsoft/BCQuality/main/<repo-relative-path>`.
Don't try to browse the GitHub web UI (`github.com/.../tree/...`) — it's blocked
for automated fetching; use `raw.githubusercontent.com` paths, and note in your
report that the review ran against the live repo rather than a pinned local copy
(the knowledge base can change under you between reviews).

## How to use it for a review (Source → Relevance → Worklist → Action)

This mirrors BCQuality's own consumption contract, simplified for use inside this
framework:

1. **Source** — from the AL constructs actually touched by the change (which
   objects, which statements — e.g. a new `Record.SetRange`/loop, a new published
   event, a new API page, a new integration with an external service), pick the
   1-3 domains that plausibly apply. Don't scan every domain for every change; a
   one-field validation tweak has no `appsource` or `telemetry` relevance.
2. **Relevance** — within the chosen domain folders, grep for keywords that match
   what the code does (e.g. `SetLoadFields`, `DeleteAll`, `FlowField`, event names,
   `TryFunction`, `Codeunit.Run`). Open the frontmatter of candidates to confirm
   `bc-version`/`technologies` actually match this project before reading further.
3. **Worklist** — of the candidates whose frontmatter matches, keep the ones whose
   `## Description` is actually about a pattern present in the diff. Discard the
   rest rather than forcing a connection.
4. **Action** — read `## Best Practice` and `## Anti Pattern` for each file on the
   worklist and check the actual code against them. When the anti-pattern is
   present, that's a finding; when the code already follows the best practice,
   there's nothing to report for that file — don't manufacture a finding just
   because a file was relevant.

## Citing findings

Every BCQuality-backed finding must cite the knowledge file by repo-relative path,
e.g. `microsoft/knowledge/performance/apply-filters-before-loop.md` (exact paths
vary — use whatever you actually opened, not a guessed name). If you reasoned about
BC quality from general knowledge rather than a specific file you opened this
session, say so explicitly instead of attaching a citation — an invented-sounding
path is worse than no citation.

## Boundaries

- This knowledge base is additive to judgment, not a replacement for it — a clean
  BCQuality pass does not mean the code is otherwise correct or well-tested.
- Don't pull `/custom/` content into a review unless the project has actually
  forked/vendored BCQuality with its own custom layer — most projects only have
  `microsoft/` and `community/`.
- If BCQuality is unreachable (no local copy and no network), say so plainly in
  the review output rather than silently skipping this check.
