# Order Attribute Settings per Item Category or Item

- ClickUp: [Instelling orderkenmerken per artikelcategorie of artikel](https://app.clickup.com/t/123x5y65qpa) (CU-123x5y65qpa)
- Spec: [docs/specs/CU-123x5y65qpa.md](../specs/CU-123x5y65qpa.md)
- UAT script: [docs/uat/CU-123x5y65qpa-order-attribute-settings.md](../uat/CU-123x5y65qpa-order-attribute-settings.md)
- App: `Customer Extensions`
- Builds on: [Document Line Attribute](CU-123x5y65gje-document-line-attribute.md) (CU-123x5y65gje) and
  [Item Attribute Print Settings](CU-123x5y65hfj-item-attribute-print-settings.md) (CU-123x5y65hfj)

## Purpose

An administrator decides, per item category or per item, which order attributes
(kenmerken) apply, which of them are mandatory, in what order they are shown, what
their default value is, and whether the item attribute's own print settings
(customer/production documents) are overridden. This lets the business roll out
new product families or change existing ones without development work.

This task is **master data only** (Open Question 1, answer (a)): the setting
table, the inheritance computation, and the two "Orderkenmerken" /
"Resulterende instelling tonen" actions. Nothing yet creates or refreshes
`ATT Document Line Attribute` rows on a sales line from this setting; that is a
separate, follow-up task.

## Objects

| Object | ID | Name | Role |
|---|---|---|---|
| Enum | 50101 | `ATT Override Option` | Tri-state override (blank/Yes/No) for the two print-setting fields. |
| Table extension | 50101 | `ATT Item Attr. Value Mapping` → `Item Attribute Value Mapping` (**7505**) | Adds Mandatory, Sequence, Not Applicable, Default Value and the two print-setting overrides to the standard item/category-to-attribute mapping row. |
| Table | 50101 | `ATT Res. Order Attr. Setting` | Temporary buffer: one row per attribute in the computed resulting setting for an item. Never written to the database. |
| Codeunit | 50105 | `ATT Order Attr. Setting Mgt.` | Public procedure `GetResultingSetting(ItemNo; var TempResult)`: computes the resulting setting of an item by walking item → item category → the category's Parent Category chain. |
| Page | 50100 | `ATT Order Attribute Settings` | Editable list on `Item Attribute Value Mapping`, filtered (via `SetFilters`) to one Table ID/No. pair. |
| Page | 50101 | `ATT Res. Order Attr. Settings` | Read-only list on the temporary buffer table, filled via `SetTempRecord`. |
| Page extension | 50102 | `ATT Item Category Card` → `Item Category Card` | Adds action **Orderkenmerken**, opening page 50100 filtered to the category. |
| Page extension | 50103 | `ATT Item Card` → `Item Card` | Adds actions **Orderkenmerken** (page 50100, filtered to the item) and **Resulterende instelling tonen** (runs `GetResultingSetting` and opens page 50101). |
| Permission set | 50100 | `ATT CUSTOM` | RIMD on tabledata `ATT Res. Order Attr. Setting`; X on the new table, codeunit and both pages; RI on tabledata `Item Attribute Value` (see [Setup and permissions](#setup-and-permissions)). (Table/page extensions are not objects that need their own permission entry, matching the existing convention — see [Document Line Attribute: Permission tests](CU-123x5y65gje-document-line-attribute.md#permission-tests).) |

## Deviations from the approved plan

The plan (see [the spec's Plan section](../specs/CU-123x5y65qpa.md#plan)) guessed at
the standard table before the real BC 28 symbols were checked. What was actually
built differs in these ways; read this before relying on the plan text:

- **The base table is `Item Attribute Value Mapping` (ID 7505), not 7502** as the
  plan assumed. Its attribute fields are `Item Attribute ID` and
  `Item Attribute Value ID` (not `Attribute ID` / `Attribute Value ID`).
- **The standard table has no built-in category inheritance.** There is no
  "Inherited From" field or automatic Parent Category lookup on
  `Item Attribute Value Mapping` — each row only ever represents one explicit
  Table ID/No./Item Attribute ID combination. The plan's architecture note ("the
  closest level ... wins outright, with all its fields" as if this were standard
  mapping behaviour) is **not** something the base table does by itself;
  `GetResultingSetting` in `ATT Order Attr. Setting Mgt.` implements the entire
  inheritance walk itself (item → its Item Category → each ancestor category via
  Parent Category, as far as the chain goes), picking the first level that has an
  explicit row for a given attribute.
- **A new field `ATT Default Value` (Text[250]) was added**, which is not in the
  plan's object table. The standard table has no free-text default value field,
  only `Item Attribute Value ID`, a pointer to an existing `Item Attribute Value`
  row. `ATT Default Value` exists so AC4 (reject an invalid default value, for
  every Item Attribute type) can be implemented: it is validated against and
  resolved to the item attribute's type, and keeps `Item Attribute Value ID` in
  sync. See [Default value validation](#default-value-validation-ac4) below.
- **`Item Attribute.Type` has no distinct "Date-Time" value**, only `Date`. AC4's
  extended requirement to validate a "Date/Time" default value is implemented
  against `Date`; there is no separate date-time default value case.
- **Object names were shortened** to fit AL's 30-character limit: the plan's
  `ATT Item Attribute Value Mapping` → `ATT Item Attr. Value Mapping`; the plan's
  `ATT Resulting Order Attr. Setting(s)` → `ATT Res. Order Attr. Setting(s)`.
- **Field prefix convention.** New fields added by the table extension on the
  standard table are prefixed `ATT ` (`ATT Mandatory`, `ATT Sequence`,
  `ATT Not Applicable`, `ATT Default Value`, `ATT Cust. Docs Override`,
  `ATT Prod. Docs Override`), matching how this app already extends standard
  tables (see `ATT Item Attribute.TableExt.al`,
  [Item Attribute Print Settings](CU-123x5y65hfj-item-attribute-print-settings.md)).
  The buffer table's own fields (`Mandatory`, `Sequence`, `Default Value`, `Level`,
  ...) are unprefixed, matching the app's own tables (see
  `ATT Document Line Attribute.Table.al`,
  [Document Line Attribute](CU-123x5y65gje-document-line-attribute.md)).

## Post-review rework

An `al-guidelines` review of the first implementation of this task found a
blocker and several majors, which `al-base-coding` fixed before the task was
closed. If an earlier version of this doc, the ClickUp task's literal field
list, or the spec text used different names for the two print-setting override
fields, that is now stale — this section explains what changed and why:

- **Field rename to resolve a naming collision (blocker).** The two
  print-setting override fields on `ATT Item Attr. Value Mapping` were
  originally named `ATT Show on Customer Docs` / `ATT Show on Production
  Docs` — identical in name and caption to the unrelated Boolean flags
  CU-123x5y65hfj added directly on `Item Attribute`. They are renamed to
  `ATT Cust. Docs Override` / `ATT Prod. Docs Override` (captions "Show on
  Customer Documents (Override)" / "Show on Production Documents
  (Override)") so the two concepts stay visually distinct in code and on
  screen. The tri-state semantics (blank/Yes/No, `Enum "ATT Override
  Option"`) are unchanged; only the name and caption changed. The item
  attribute's own `ATT Show on Customer Docs` / `ATT Show on Production
  Docs` flags are unaffected and keep their original names.
- **`OnInsert`/`OnModify` sync logic removed (xRec anti-pattern).** The table
  extension originally also tried to keep `Item Attribute Value ID` in sync
  with `ATT Default Value` from `OnInsert`/`OnModify` triggers, comparing
  against `xRec`. `xRec` is not a reliable before-image in those triggers for
  code that assigns fields directly instead of calling `Validate` (see
  BCQuality
  `microsoft/knowledge/data-modeling/xrec-is-a-before-image-only-in-some-triggers.md`),
  so the check could silently skip validation. Both triggers were removed;
  sync now runs only from `ATT Default Value`'s own `OnValidate` trigger, see
  [Default value validation](#default-value-validation-ac4). Separately,
  `GetResultingSetting`'s `GetDefaultValueText` now resolves the live
  `Item Attribute Value ID` first and only falls back to the row's stored
  `ATT Default Value` text when no ID has been resolved yet, so a stale text
  can no longer mask a value that was changed through Microsoft's own
  standard item/category attribute-value pages — see
  [The resulting setting](#the-resulting-setting-inheritance-algorithm).
- **New permission grant.** `FindOrCreateAttributeValueId` inserts a new
  `Item Attribute Value` row when an entered Decimal/Integer/Date/Text
  default value does not match an existing one yet — the first time this app
  writes to a standard master-data table rather than only reading it.
  `ATT CUSTOM` now grants `tabledata "Item Attribute Value" = RI` for this;
  see [Setup and permissions](#setup-and-permissions).
- **Error messages now use `FieldError`.** All default-value validation
  errors call `FieldError("ATT Default Value", ...)` instead of a plain
  `Error(...)`, so Business Central attaches the field caption and record
  context to the message automatically.
- **File rename.** The table extension's file was renamed from
  `ATTItemAttributeValueMapping.TableExt.al` to
  `ATTItemAttrValueMapping.TableExt.al` to match the object name
  `ATT Item Attr. Value Mapping` (already shortened for AL's 30-character
  object-name limit — only the file name was out of sync before).
- **New test coverage.**
  `GetResultingSetting_CategoryIsOwnParent_ThrowsError` was added for the
  cyclic-category defensive check in `ResolveCategoryChain`, which had no
  test before; see [Tests](#att-order-attr-setting-test-50156).

## The resulting setting (inheritance algorithm)

`ATT Order Attr. Setting Mgt.GetResultingSetting(ItemNo, var TempResult)` computes,
for one item, the single resulting order attribute setting for every attribute
that applies to it, in plain terms:

1. Look at the item itself: every `Item Attribute Value Mapping` row with
   `Table ID` = Item and `No.` = the item decides that attribute's setting
   outright — all its fields (Mandatory, Sequence, Default Value, Not Applicable,
   the two print overrides) come from that one row. Nothing from a less specific
   level is mixed in for the same attribute.
2. For an attribute that the item itself does not decide, look at the item's
   `Item Category Code`. A row there decides the attribute the same way.
3. If the category itself does not decide it, walk up the category's
   `Parent Category` field, one level at a time, as far as the chain goes
   (Open Question 5: multi-level, most-specific wins). The first ancestor category
   that has a row for the attribute decides it.
4. If a row at any level has `ATT Not Applicable` = Yes for an attribute, that
   attribute is dropped from the result entirely for this item — it does not fall
   through to a less specific level's row, even if one exists (AC3).
5. If the winning row leaves a print-setting override blank (`ATT Override
   Option`::" "), the result falls back to the item attribute's own
   `ATT Show on Customer Docs` / `ATT Show on Production Docs` flag (Open
   Question 2; those flags were added by CU-123x5y65hfj).
6. The result's `Default Value` text is resolved from the winning row's
   `Item Attribute Value ID` first — the `Value` of the `Item Attribute Value`
   it points to, which is also what a sales line would actually get — and only
   falls back to the row's own `ATT Default Value` text when no
   `Item Attribute Value ID` has been resolved yet. This order (rather than the
   reverse) means a row whose value was last changed through a standard
   Microsoft page — which sets `Item Attribute Value ID` directly and never
   touches `ATT Default Value` — is never masked by a stale `ATT Default
   Value` entry; see [Post-review rework](#post-review-rework).
7. Each returned row also carries a human-readable `Level`: `Item`, or
   `Item category <code>` for the category that decided it.

The codeunit also detects a cyclic Parent Category chain (a category that is,
directly or indirectly, its own parent) and raises an error rather than looping
forever. This case is not mentioned in the spec; it is a defensive check, not a
feature the spec asked for.

Because the computation always re-reads `Item Attribute Value Mapping` live, a
change to a category's setting is reflected immediately the next time
`GetResultingSetting` is called — there is nothing cached (AC5, as scoped by Open
Question 1: tested at this "resulting setting" level, not via an actual sales
line).

## Default value validation (AC4)

`ATT Default Value` on `ATT Item Attr. Value Mapping` validates and resolves
only from its own `OnValidate` trigger (not from `OnInsert`/`OnModify` — see
[Post-review rework](#post-review-rework) for why):

- **Option** attributes: the entered text must exactly match an existing
  `Item Attribute Value.Value` for that attribute, or it is rejected.
- **Decimal**, **Integer**, **Date** attributes: the entered text must
  `Evaluate` as that type, or it is rejected; a matching `Item Attribute Value`
  row is found or created and `Item Attribute Value ID` is set to it.
- **Text** attributes (and any other type) accept any value as-is.
- Clearing `ATT Default Value` only clears `Item Attribute Value ID` if this
  field had previously set it, so rows created or edited through the standard
  Microsoft mapping pages (which set `Item Attribute Value ID` directly and never
  touch `ATT Default Value`) are left untouched.

## Usage

- **Item Category Card** → action **Orderkenmerken**: opens page 50100 filtered
  to that category, to add/edit/remove attribute rows for it.
- **Item Card** → action **Orderkenmerken**: the same page, filtered to the item.
- **Item Card** → action **Resulterende instelling tonen**: computes and shows
  the read-only resulting setting (page 50101) for that item — the attributes
  from the item and its item category chain, with the setting of the closest
  level and that level's name.

## Setup and permissions

There is no setup. Maintaining rows on `Item Attribute Value Mapping` (including
the new `ATT ...` fields) needs the normal permissions on that standard table;
`ATT CUSTOM` does not add a tabledata permission for it, because it is a base-app
table and the standard permission sets (for example `D365 BUS FULL ACCESS`)
already grant access, consistent with how the app treats table extensions
elsewhere (see [Item Attribute Print Settings: Setup and permissions](CU-123x5y65hfj-item-attribute-print-settings.md#setup-and-permissions)).
`ATT CUSTOM` grants RIMD on tabledata `ATT Res. Order Attr. Setting` and X on the
new table, codeunit and both pages, so every object of the app is in it.

`ATT CUSTOM` additionally grants RI on tabledata `Item Attribute Value`. Unlike
every other object this permission set grants, this is a write permission on a
standard master-data table the app does not own: entering a Decimal, Integer,
Date or Text default value on an order attribute setting row that does not
already match an existing `Item Attribute Value` inserts one
(`FindOrCreateAttributeValueId`), so insert permission is required — see
[Post-review rework](#post-review-rework). A consequence: a user who can open
the **Orderkenmerken** page (through their own permissions on
`Item Attribute Value Mapping`, not through `ATT CUSTOM`) but does **not** have
`ATT CUSTOM` or another permission set that separately grants insert on
`Item Attribute Value`, will get an insert-permission error when entering a new
Decimal/Integer/Date/Text default value that has no existing match — even
though the same user can enter an Option default value that already exists, or
leave the field blank, without issue. This is expected given how the
permission set is scoped (administrators maintaining these settings are
expected to have `ATT CUSTOM`), not a defect, but it is worth knowing before
assigning only partial access.

## Out of scope and open questions

- Creating or refreshing `ATT Document Line Attribute` rows on a sales line from
  the resulting setting — a separate, follow-up task (Open Question 1).
- No report or document layout reads the two print-setting overrides yet (same
  status as the item attribute's own flags, see
  [Item Attribute Print Settings](CU-123x5y65hfj-item-attribute-print-settings.md)).

## Translations

nl-BE and en-US captions, tooltips and action labels are in
`Customer Extensions/Translations/Customer Extensions.nl-BE.xlf` and
`Customer Extensions/Translations/Customer Extensions.en-US.xlf`. See
[Translations](CU-123x5y65gje-document-line-attribute.md#translations) in the
Document Line Attribute doc for how the XLIFF files are maintained.

## Tests

UAT script: [docs/uat/CU-123x5y65qpa-order-attribute-settings.md](../uat/CU-123x5y65qpa-order-attribute-settings.md).

### `ATT Order Attr. Setting Test` (50156)

In `Customer Extensions Test`, `TestPermissions = Disabled`, run with test runner
130450 "Test Runner - Isol. Codeunit" in a dedicated test company, like the other
test codeunits of this app. 17 tests:

| AC | Tests |
|---|---|
| AC1 | `GetResultingSetting_InheritsMandatoryFromParentCategory` (one level, N18 → MATRAS as in the spec example); `GetResultingSetting_InheritsFromGrandparentCategory` (two levels, Open Question 5). |
| AC2 | `GetResultingSetting_ItemLevelOverridesCategoryLevel`. |
| AC3 | `GetResultingSetting_NotApplicableAtMoreSpecificLevel_RemovesAttribute`. |
| AC4 | One invalid/valid pair per Item Attribute type: `ValidateDefaultValue_Invalid/ValidOptionValue...`, `...Decimal...`, `...Integer...`, `...Date...`, and `ValidateDefaultValue_TextValue_AcceptsAnyValue`. |
| AC5 | `GetResultingSetting_ChangingCategorySetting_IsReflectedImmediately` — tested at the resulting-setting level, not through an actual sales line (Open Question 1). |
| Open Question 2 (print overrides) | `GetResultingSetting_PrintFlagBlank_FallsBackToItemAttribute`; `GetResultingSetting_PrintFlagOverride_UsesOverride`. |
| Cyclic-category defensive check (added in the [post-review rework](#post-review-rework)) | `GetResultingSetting_CategoryIsOwnParent_ThrowsError`. |

The test library (`ATT Test Library`, codeunit 50154) gained two helpers for
this feature: `CreateItemCategory` and `SetItemCategory`.

**Not verified by compilation.** This test codeunit has not been compiled or run
on this dev machine: the Microsoft test-library symbols (`Library Assert` and
the rest of `Customer Extensions Test`'s dependencies) are missing locally.
Compile and run it in the sandbox or AL-Go pipeline before considering the tests
proven.

### Permission tests

No new permission test codeunit was added for this feature. The existing generic
test in `ATT Doc. Line Attr. Perm. Test` (50153) that checks every table, page,
report, codeunit, XMLport and query of `Customer Extensions` against the
`Expanded Permission` view of `ATT CUSTOM` (see
[Document Line Attribute: Permission tests](CU-123x5y65gje-document-line-attribute.md#permission-tests))
already covers the new table, codeunit and pages without needing a
feature-specific addition. That generic test only iterates objects owned by
`Customer Extensions`, so it does not and cannot cover the new
`tabledata "Item Attribute Value" = RI` grant (a base-app table) added in the
[post-review rework](#post-review-rework) — there is no automated test that
asserts this permission exists or is actually needed. This gap is noted here,
not silently fixed, since adding such a test is a coding/guidelines concern.
