# Item Attribute Print Settings

- ClickUp: [Afdrukinstellingen op Artikelkenmerk](https://app.clickup.com/t/123x5y65hfj) (CU-123x5y65hfj)
- Spec: [docs/specs/CU-123x5y65hfj.md](../specs/CU-123x5y65hfj.md)
- UAT script: [docs/uat/CU-123x5y65hfj-item-attribute-print-settings.md](../uat/CU-123x5y65hfj-item-attribute-print-settings.md)
- App: `Customer Extensions`
- Builds on: [Document Line Attribute](CU-123x5y65gje-document-line-attribute.md) (CU-123x5y65gje)

## Purpose

An administrator marks per item attribute (kenmerk) whether it is shown on
customer documents and on production documents. Internal attributes (for example
Familie) must not reach the customer, while the workshop gets all the information
it needs. The settings are copied to a document line attribute when its Attribute
ID is assigned. No report or document layout uses the settings yet.

## Objects

| Object | ID | Name | Role |
|---|---|---|---|
| Table extension | 50100 | `ATT Item Attribute` → `Item Attribute` (7500) | Adds the two print settings. |
| Page extension | 50100 | `ATT Item Attributes` → `Item Attributes` (7500) | Shows both fields on the list. |
| Page extension | 50101 | `ATT Item Attribute Card` → `Item Attribute` (7503) | Shows both fields on the card. |
| Table (changed) | 50100 | `ATT Document Line Attribute` | `Attribute ID` OnValidate copies both settings from the Item Attribute. |
| Codeunit | 50102 | `ATT Install` | Internal. Subtype Install; `OnInstallAppPerCompany` runs the set-to-Yes routine. |
| Codeunit | 50103 | `ATT Upgrade` | Internal. Subtype Upgrade; `OnUpgradePerCompany` runs the set-to-Yes routine. |
| Codeunit | 50104 | `ATT Upgrade Mgt.` | Internal. Set-to-Yes routine and its upgrade tag. |
| Permission set | 50100 | `ATT CUSTOM` | X on the three new codeunits. |

`ATT Install` and `ATT Upgrade` only call `ATT Upgrade Mgt.`. New data upgrade
routines of the app go in `ATT Upgrade Mgt.` with their own upgrade tag.

## Fields on Item Attribute

| No. | Field | Caption (en-US / nl-BE) | Type | Default |
|---|---|---|---|---|
| 50100 | `ATT Show on Customer Docs` | Show on Customer Documents / Tonen op klantdocumenten | Boolean | Yes (`InitValue`) |
| 50101 | `ATT Show on Production Docs` | Show on Production Documents / Tonen op productiedocumenten | Boolean | Yes (`InitValue`) |

The field names are shorter than the captions because of the 30-character limit.
DataClassification is `CustomerContent`.

## Copy to the document line attribute

When `Attribute ID` on `ATT Document Line Attribute` is validated to a new value,
fields 17 `Show on Customer Documents` and 18 `Show on Production Documents` are
copied from the Item Attribute (local procedure
`CopyPrintSettingsFromItemAttribute`). This happens whatever the `Source` of the
line attribute is.

- Validating `Attribute ID` to 0 sets both fields to No.
- Validating `Attribute ID` to the value it already has does nothing, so the line
  keeps the values it copied before (snapshot), even if the Item Attribute has
  changed since then.
- An `Attribute ID` that does not exist is rejected by the table relation.

The copy is a snapshot, like Value and Unit of Measure: later changes to the
Item Attribute do not change line attributes that already exist. Archiving,
posting and `CopyAttributes` copy the stored values without validating
`Attribute ID`, so archived and posted lines keep the line's own values.

Only validation triggers the copy. Code that assigns `Attribute ID` without
`Validate` (or inserts a line attribute with the key already filled in) must set
fields 17 and 18 itself.

### Handover for the task that creates line attributes

Nothing creates line attributes from an item's attributes yet; that is another
task. That code must set `Attribute ID` with the two-argument
`Validate("Attribute ID", Value)` on a record whose `Attribute ID` is still 0.
If it first assigns `Attribute ID` directly and then calls
`Validate("Attribute ID")`, the value has not changed, so nothing is copied and
both fields stay No.

## Existing item attributes on install and upgrade

`InitValue` only applies to new records. Item attributes that existed before
this version read No for both fields. Codeunit `ATT Upgrade Mgt.` (50104,
`Access = Internal`) fixes that. Other extensions cannot call it.

- `SetItemAttrPrintSettingsToYesOnce()` exits when the upgrade tag
  `ATT-CU-123x5y65hfj-ItemAttrPrintSettings-20261019` exists in the company.
  Otherwise it sets both fields to Yes on every Item Attribute (`ModifyAll`
  without triggers) and then sets the tag. `ATT Install` and `ATT Upgrade` call
  it per company.
- `SetItemAttrPrintSettingsToYesOnce(UpgradeTagCode: Code[250])` is an internal
  procedure that does the same with a tag that the caller passes. It exists for
  the tests: the app's own tag is already set in every company where the app is
  installed, and upgrade tags cannot be removed. Production code uses the
  overload without parameters.
- `GetItemAttrPrintSettingsUpgradeTag(): Code[250]` returns the tag.

The test app `Customer Extensions Test` reaches the internal codeunit through an
`internalsVisibleTo` entry in `Customer Extensions/app.json`. The compiler gives
warning PTE0012 for that entry; this warning is accepted.

The tag is registered through `OnGetPerCompanyUpgradeTags`. A company that is
created after the app is installed gets the tag at creation, so the routine does
not run there; its item attributes get Yes through `InitValue`.

Because the routine runs only once per company, an administrator can set an
attribute to No after the upgrade and later upgrades will not reset it.

Reinstall: if the app is uninstalled without clearing its data, item attributes
created in the meantime read No for both fields after the reinstall. The routine
does not run again, because the upgrade tag is still there. Check these
attributes and set the fields manually.

## Usage

On **Item Attributes** (page 7500) or the **Item Attribute** card (page 7503),
set **Show on Customer Documents** and **Show on Production Documents**. Both
fields are editable on the list and on the card. The setting applies to line
attributes that are assigned after the change.

## Setup and permissions

There is no setup. Users who maintain item attributes need the normal
permissions on `Item Attribute`; the new fields are part of that table. The
install and upgrade codeunits run during app deployment. `ATT CUSTOM` grants X
on the three new codeunits, so that every object of the app is in it.

## Out of scope and open questions

- Creating line attributes automatically when a sales line is created (another
  task). That task tests the copy end to end.
- Line UI: there is still no page for `ATT Document Line Attribute`.
- Reports and document layouts that use the settings.
- Open question (spec Q4): do line attributes from a variant, the order or a
  parent line also take the settings from the Item Attribute? Working
  assumption, and current behaviour: yes.
- Open question (spec Q5): may a user change the settings on a single line
  attribute, and does that set `Manually Modified`? Decided in the task that
  adds the line page.

## Translations

The nl-BE captions and tooltips of both fields are in
`Customer Extensions/Translations/Customer Extensions.nl-BE.xlf`. See
[Translations](CU-123x5y65gje-document-line-attribute.md#translations) in the
Document Line Attribute doc for how the XLIFF files are maintained.

## Tests

UAT script: [docs/uat/CU-123x5y65hfj-item-attribute-print-settings.md](../uat/CU-123x5y65hfj-item-attribute-print-settings.md).

> **Run codeunit 50155 with test runner 130450 "Test Runner - Isol. Codeunit"
> in a dedicated test company.** `Initialize` changes setup (stockout and credit
> warnings, the posting setup of `ATT Test Library`) and commits it. The tests
> create item attributes, items and sales documents, and set upgrade tags. Upgrade
> tags cannot be removed, so with another runner the test tags (`ATT-TEST-...`)
> stay in the company.

### `ATT Item Attr. Print Test` (50155)

In `Customer Extensions Test`, `TestPermissions = Disabled`, 15 tests:

| AC | Tests |
|---|---|
| AC1 | A new item attribute has Show on Customer Documents = Yes; the same for Show on Production Documents. |
| AC2 | Validating `Attribute ID` on a line attribute of a sales line copies Customer No / Production Yes, and the reverse; validating to 0 sets both to No; an `Attribute ID` that does not exist is rejected (checked with `Assert.AssertPrimRecordNotFound()`). |
| AC3 | Changing the Item Attribute after the line attribute is inserted leaves the line unchanged; validating the same `Attribute ID` again keeps the copied settings (`RevalidateSameAttributeId_KeepsCopiedPrintSettings`); validating another `Attribute ID` takes the new attribute's settings. |
| AC4 | The routine sets No to Yes on existing attributes; it sets the tag; with the tag present a second run changes nothing; the app's tag is registered per company. |
| AC5 | Both fields are visible and editable on the Item Attributes list and on the Item Attribute card (TestPage). |

The AC4 tests call the internal overload with a unique test tag (through
`internalsVisibleTo`). They do not run the
install or upgrade codeunit itself; the UAT script covers the real upgrade.

AC6 (translations) is checked by the XLIFF content and in the UAT script.

### Permission tests

`ATT Doc. Line Attr. Perm. Test` (50153) has 3 new tests: `ATT CUSTOM` grants X
on `ATT Install`, `ATT Upgrade` and `ATT Upgrade Mgt.`. Like the other
codeunit tests in 50153, they refer to the codeunits directly
(`Codeunit::"ATT Install"` and so on). The existing test that
every object of the app is in `ATT CUSTOM` also covers the new codeunits. Table
and page extensions are not objects that need a permission.
