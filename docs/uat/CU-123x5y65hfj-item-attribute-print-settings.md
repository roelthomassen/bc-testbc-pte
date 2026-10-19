# UAT: CU-123x5y65hfj Item Attribute Print Settings

- ClickUp: [Afdrukinstellingen op Artikelkenmerk](https://app.clickup.com/t/123x5y65hfj) (CU-123x5y65hfj)
- Spec: [docs/specs/CU-123x5y65hfj.md](../specs/CU-123x5y65hfj.md)
- Feature doc: [docs/features/CU-123x5y65hfj-item-attribute-print-settings.md](../features/CU-123x5y65hfj-item-attribute-print-settings.md)

| | |
|---|---|
| Environment | |
| Company | |
| App version before upgrade (`Customer Extensions`) | |
| App version after upgrade | |
| Key user | |
| Date | |

## Purpose

Check in the real online environment that item attributes that already exist
get Yes for both print settings when the app is upgraded, that new item
attributes get Yes by default, and that an administrator can see and change both
settings on the Item Attributes list and card, in English and in Dutch
(Belgium).

The upgrade can only be checked once per company: the upgrade routine sets an
upgrade tag and does not run again. Run the script in a sandbox or test company
that still has the previous version of `Customer Extensions` (without this
task), and do the preconditions **before** the new version is deployed.

## Preconditions

| Step | Action | Expected result | Pass/Fail |
|---|---|---|---|
| P1 | Key user: make sure the user can create and modify item attributes (for example `D365 BUS FULL ACCESS` or `SUPER`). On **Extension Management**, note the installed version of `Customer Extensions`. | The previous version is installed. On **Item Attributes**, there are no columns Show on Customer Documents and Show on Production Documents. Version: ______ | |
| P2 | Key user: on **Item Attributes**, create attribute `UAT FAMILIE` (Type Text) and attribute `UAT MAAT` (Type Option, with value `Groot`). Note how many item attributes exist in total. | Both attributes exist. Total number of item attributes: ______ | |
| P3 | Deploy the new version of `Customer Extensions` to the environment through the AL-Go pipeline. On **Extension Management**, note the version. | The new version is installed with no errors. Version: ______ | |

## Scenarios

### 1. Existing item attributes after the upgrade (AC4)

| Step | Action | Expected result | Pass/Fail |
|---|---|---|---|
| 1.1 | Key user: open **Item Attributes**. | Columns **Show on Customer Documents** and **Show on Production Documents** are shown. `UAT FAMILIE`, `UAT MAAT` and the attributes that existed before have both fields set to Yes. | |
| 1.2 | Key user: open the table by adding `&table=7500` to the URL of the environment and company. With the filter pane, filter **Show on Customer Documents** on No. Then remove that filter and filter **Show on Production Documents** on No. | Both filters give no records. The number of records without filter is the total of step P2. | |
| 1.3 | Key user: on **Item Attributes**, set **Show on Customer Documents** of `UAT FAMILIE` to No. | The change is saved. | |
| 1.4 | *Optional, only when a later version of `Customer Extensions` is deployed to this company during the UAT.* After that deployment, open **Item Attributes**. | `UAT FAMILIE` still has Show on Customer Documents = No: the upgrade routine does not run a second time. | |

### 2. New item attribute and the pages (AC1, AC5)

| Step | Action | Expected result | Pass/Fail |
|---|---|---|---|
| 2.1 | Key user: on **Item Attributes**, choose **New** and create attribute `UAT NIEUW` (Type Text). | On the new attribute, Show on Customer Documents and Show on Production Documents are both Yes. | |
| 2.2 | Key user: on **Item Attributes**, change **Show on Production Documents** of `UAT NIEUW` to No in the list. Close and reopen the page. | The field can be edited in the list. After reopening, `UAT NIEUW` has Show on Production Documents = No. | |
| 2.3 | Key user: open the **Item Attribute** card of `UAT NIEUW` (page 7503). | Both fields are shown on the card, after **Blocked**. | |
| 2.4 | Key user: on the card, set **Show on Customer Documents** to No and **Show on Production Documents** to Yes. Close the card and open it again. | Both fields can be edited. After reopening, Show on Customer Documents is No and Show on Production Documents is Yes. | |

### 3. Copy to document line attributes (AC2, AC3)

This release has no page for `ATT Document Line Attribute`, and nothing creates
line attributes from an item's attributes yet (that is another task). A
configuration package cannot be used to check the copy either: `Attribute ID` is
part of the primary key, and configuration packages fill key fields without
validating them, so the settings are not copied. AC2 and AC3 are therefore
checked by the automated tests only.

| Step | Action | Expected result | Pass/Fail |
|---|---|---|---|
| 3.1 | Key user or developer: open the test results of the AL-Go pipeline run that built the deployed version, and look up codeunit 50155 `ATT Item Attr. Print Test`. | All 15 tests pass, including the AC2 tests (`ValidateAttributeId...`, `ValidateNonExistingAttributeId_ThrowsError`) and the AC3 tests (`ChangeItemAttributePrintSettings_LineAttributeKeepsCopiedValues`, `RevalidateSameAttributeId_KeepsCopiedPrintSettings`, `ValidateOtherAttributeId_TakesPrintSettingsOfNewAttribute`). | |

### 4. Translations (AC6)

| Step | Action | Expected result | Pass/Fail |
|---|---|---|---|
| 4.1 | Key user: in **My Settings**, set the language to Dutch (Belgium). Open **Artikelkenmerken** (Item Attributes). | The columns are **Tonen op klantdocumenten** and **Tonen op productiedocumenten**. | |
| 4.2 | Key user: hover over the column caption **Tonen op klantdocumenten**, then over **Tonen op productiedocumenten**. | The tooltips are Dutch: "Hiermee wordt opgegeven of het kenmerk wordt getoond op documenten voor de klant. ..." and "Hiermee wordt opgegeven of het kenmerk wordt getoond op productiedocumenten. ...". | |
| 4.3 | Key user: open the **Artikelkenmerk** card of `UAT NIEUW`. | The fields are **Tonen op klantdocumenten** and **Tonen op productiedocumenten**, with the same Dutch tooltips. | |
| 4.4 | Key user: set the language back to English and open **Item Attributes**. | The columns are **Show on Customer Documents** and **Show on Production Documents**, with English tooltips. | |

## Not covered by this script

These are covered by the automated tests in `Customer Extensions Test`, or have
no UI in this release:

- the copy of both settings to a line attribute when `Attribute ID` is validated,
  validating `Attribute ID` to 0, and the snapshot behaviour (AC2, AC3; see
  scenario 3);
- the install routine in a company where the app is installed for the first
  time (same routine as the upgrade, called from `ATT Install`);
- a company created after the app is installed: it gets the upgrade tag at
  creation, and its item attributes get Yes through the default value.

## Clean-up

Key user: delete item attributes `UAT FAMILIE`, `UAT MAAT` and `UAT NIEUW`. They
are not assigned to items, so they can be deleted. The upgrade tag stays in the
company; the upgrade cannot be tested again in the same company.

## Sign-off

| Role | Name | Date | Result |
|---|---|---|---|
| Key user | | | |
