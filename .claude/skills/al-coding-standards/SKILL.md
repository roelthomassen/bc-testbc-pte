---
name: al-coding-standards
description: Use when writing, editing, or reviewing AL code for Business Central, to apply Microsoft's official AL coding conventions and the community AL design-pattern guidelines (naming, file layout, formatting, and common performance/maintainability patterns).
---

# AL coding standards

Distilled from Microsoft's official "Best practices for AL code" / "Rules and
guidelines for AL code" documentation (Microsoft Learn) and the community AL
Guidelines site (alguidelines.dev). This is a working checklist, not a copy of
those sources — when in doubt, or for anything not covered here, check
https://learn.microsoft.com/dynamics365/business-central/dev-itpro/compliance/apptest-overview
and https://alguidelines.dev/docs/.

## Naming

- **Objects** (tables, pages, reports, codeunits, enums, ...): PascalCase, prefixed
  with your registered affix/prefix, descriptive name kept under ~26 characters so
  there's room for the prefix (e.g. `"MyPrefix Sales Header Ext"`, not something
  that only fits unprefixed).
- **Interfaces**: prefix with `I` (e.g. `ICustomerService`); **implementation
  codeunits** for an interface use an `Impl` suffix (e.g. `"Customer Service Impl"`).
- **Variables, fields, parameters**: PascalCase, descriptive, no abbreviations
  unless they're well-known BC/business terms (e.g. `GLEntry` is fine). Avoid
  generic names like `Rec`, `Var1` — especially in event subscriber parameters,
  where the next developer has no other context.
- **Temporary variables**: prefix with `Temp` (e.g. `TempCustomer: Record Customer
  temporary;`).
- Object/variable names: English, no wildcard symbols (`%`, `&`).
- **File naming**: `<ObjectName>.<FullTypeName>.al` (extensions add `Ext`), e.g.
  `SalesHeader.Table.al`, `PostSalesInvoice.Codeunit.al`,
  `CustomerCard.PageExt.al`. Use the standard type abbreviations (Page, PageExt,
  Codeunit, Table, TableExt, Xmlport, Report, RequestPage, Query, Enum, EnumExt,
  ControlAddIn, Interface, PermissionSet, PermissionSetExt).
- **UI text**: sentence case for labels/actions that read as a verb phrase or
  sentence ("Calculate total", "Post and print"); title case for names that are
  nouns, not sentences ("Customer Card", "General Ledger").
- Never leave trailing whitespace in action/control names — it's silently trimmed
  and breaks exact-name lookups (including Copilot suggestions).

## File & object structure

- One extension per folder; use `/src` for source, `/test` (or a dedicated test
  app) for tests, `/res` for resources.
- Within an object, order: properties → object-specific constructs (fields,
  layout, actions, triggers) → global variables/labels → methods.
- Reference other objects **by name, not by ID** (`Page.RunModal(Page::"Customer
  Card", ...)`, not the numeric ID) — names survive renumbering and are readable.

## Formatting

- 4-space indentation; lowercase for reserved keywords (not for built-in
  method/type names); opening curly brace on its own new line.
- One statement per line; binary operators at the start of the continuation line
  when a condition wraps.
- Blank line between method declarations; space after `:` in
  variable/parameter type declarations (`Number: Integer;`); space after each
  comma between parameters (`MyProcedure(1, 2)`); always call with parentheses
  even for zero-arg calls (`Init()`, not `Init`).
- Remove unnecessary `else` after a branch that already exits/returns, and
  unnecessary explicit `= true` / `= false` comparisons on booleans.
- Use `if not X then exit;` (early-exit / guard-clause style) for validation
  instead of wrapping the rest of the procedure in a big `if X then`.

## Performance & maintainability patterns to actively check for

- **`SetLoadFields`** on any `Record` read path where only a subset of fields is
  needed — especially in loops and background/report processing.
- **`DeleteAll`** (and `ModifyAll`) — verify filters are correct and narrow before
  calling; an unfiltered or under-filtered bulk operation is a common source of
  real incidents. Check `IsTemporary` where relevant before assuming safety.
- Prefer events (business/integration events) over direct cross-extension
  procedure calls when the codebase already uses an event-driven integration
  style; keep event subscriber parameter names specific, not generic.
- Consistent, deliberate error handling: raise errors with `Error()` and format
  placeholders (not string concatenation), don't swallow exceptions silently, and
  keep validation logic close to the data it validates rather than scattered.
- Keep procedures single-purpose — a procedure mixing data access, validation and
  UI concerns is a sign it should be split.

## Applying this skill

When writing code: apply these rules as you go, don't defer them to a later pass.
When reviewing code: check the naming, formatting, and performance/maintainability
sections above explicitly, and only raise a finding when a rule is actually
violated — don't pad a review with restated rules that were already followed.
