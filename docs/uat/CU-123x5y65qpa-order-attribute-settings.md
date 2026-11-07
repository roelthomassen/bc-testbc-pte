# UAT: CU-123x5y65qpa Order Attribute Settings per Item Category or Item

- ClickUp: [Instelling orderkenmerken per artikelcategorie of artikel](https://app.clickup.com/t/123x5y65qpa) (CU-123x5y65qpa)
- Spec: [docs/specs/CU-123x5y65qpa.md](../specs/CU-123x5y65qpa.md)
- Feature doc: [docs/features/CU-123x5y65qpa-order-attribute-settings.md](../features/CU-123x5y65qpa-order-attribute-settings.md)

| | |
|---|---|
| Environment | |
| Company | |
| App version (`Customer Extensions`) | |
| Key user (with `ATT CUSTOM`) | |
| Sales/other user (without `ATT CUSTOM`) | |
| Date | |

## Purpose

Check in the real online environment that an administrator can configure order
attribute settings on an item category and on an item through the
**Orderkenmerken** actions, that inheritance and the most-specific-wins rule work
across multiple category levels, that an invalid default value is rejected for
every item attribute type, that a change to a category's setting is reflected
immediately in **Resulterende instelling tonen** without retroactively changing
anything already computed, and what a user without `ATT CUSTOM` can and cannot
do: this task adds no new permission requirement on the standard mapping table
itself, only on the two new pages, the buffer table/codeunit, and on inserting
new `Item Attribute Value` rows, which only `ATT CUSTOM` grants and which can
block entering certain new default values (see scenario 7 for both).

This feature is master data only: there is no sales line yet that automatically
picks up these settings (see the feature doc's "Out of scope" section). AC5 is
checked at the "resulting setting" level, not through an actual sales order line.

## Preconditions

| Step | Action | Expected result | Pass/Fail |
|---|---|---|---|
| P1 | Key user: make sure the user can open Item Categories and Items and has `ATT CUSTOM` (or `SUPER`). | The key user can see the **Orderkenmerken** action on both the Item Category Card and the Item Card. | |
| P2 | Other user: make sure a normal sales/inventory user (for example `D365 BUS FULL ACCESS`) does **not** have `ATT CUSTOM` or `SUPER`, directly or through a security group. | Confirmed on the user's assigned permission sets. | |
| P3 | Key user: on **Item Attributes**, create attribute `UAT HARDHEID` (Type Option) with values `Zacht` and `Hard`. | The attribute and both values exist. | |
| P4 | Key user: on **Item Categories**, create category `UAT MATRAS` (no parent), category `UAT N18` with Parent Category `UAT MATRAS`, and category `UAT TOPPER` with Parent Category `UAT MATRAS`. | The three categories exist with the parent/child relations shown on the category card. | |
| P5 | Key user: on **Items**, create item `UAT M00001` with Item Category Code `UAT N18`, and item `UAT M00002` with Item Category Code `UAT TOPPER`. | Both items exist with the categories set. | |

## Scenarios

### 1. Category inheritance, one level (AC1)

| Step | Action | Expected result | Pass/Fail |
|---|---|---|---|
| 1.1 | Key user: open the **Item Category Card** of `UAT MATRAS`, choose **Orderkenmerken**. Add a row for `UAT HARDHEID` with Mandatory = Yes. Close the page. | The row is saved. | |
| 1.2 | Key user: open the **Item Card** of `UAT M00001`, choose **Resulterende instelling tonen**. | `UAT HARDHEID` appears in the list, Mandatory = Yes, Level = `Item category UAT MATRAS`. | |

### 2. Multi-level inheritance, grandparent category (AC1 / Open Question 5)

| Step | Action | Expected result | Pass/Fail |
|---|---|---|---|
| 2.1 | Key user: on **Item Categories**, create category `UAT N18B` with Parent Category `UAT N18`. On **Items**, create item `UAT M00003` with Item Category Code `UAT N18B`. | The new category and item exist. | |
| 2.2 | Key user: open the **Item Card** of `UAT M00003`, choose **Resulterende instelling tonen**. | `UAT HARDHEID` appears, Mandatory = Yes, Level = `Item category UAT MATRAS` — the setting from `UAT MATRAS` is inherited across two levels (`UAT N18B` → `UAT N18` → `UAT MATRAS`), since neither `UAT N18B` nor `UAT N18` has its own row for the attribute. | |

### 3. Most specific level wins (AC2)

| Step | Action | Expected result | Pass/Fail |
|---|---|---|---|
| 3.1 | Key user: open the **Item Card** of `UAT M00001`, choose **Orderkenmerken**. Add a row for `UAT HARDHEID` with Mandatory = Yes and Default Value `Hard`. | The row is saved. (The category `UAT MATRAS` row from scenario 1 has Mandatory = Yes as well, so this step alone does not yet prove the override; step 3.2 does.) | |
| 3.2 | Key user: open the **Item Category Card** of `UAT MATRAS`, choose **Orderkenmerken**, and set Mandatory = No on the `UAT HARDHEID` row. Reopen **Resulterende instelling tonen** for `UAT M00001`. | `UAT HARDHEID` is still Mandatory = Yes, Level = `Item` — the item-level row wins even though the category row is now No. | |
| 3.3 | Key user: open **Resulterende instelling tonen** for `UAT M00002` (category `UAT TOPPER`, which has no own row and inherits from `UAT MATRAS`). | `UAT HARDHEID` is Mandatory = No, Level = `Item category UAT MATRAS` — confirms the category row from step 3.2 is otherwise still in effect for items that don't override it. | |

### 4. Not applicable (AC3)

| Step | Action | Expected result | Pass/Fail |
|---|---|---|---|
| 4.1 | Key user: open the **Item Category Card** of `UAT TOPPER`, choose **Orderkenmerken**. Add a row for `UAT HARDHEID` with Not Applicable = Yes. | The row is saved. | |
| 4.2 | Key user: open **Resulterende instelling tonen** for `UAT M00002`. | `UAT HARDHEID` does **not** appear in the list, even though `UAT MATRAS` (the parent category) has a row for it. | |

### 5. Invalid default value, every item attribute type (AC4)

| Step | Action | Expected result | Pass/Fail |
|---|---|---|---|
| 5.1 | Key user: on **Item Attributes**, create `UAT DECIMAL` (Decimal), `UAT INTEGER` (Integer), `UAT DATE` (Date) and `UAT TEXT` (Text). | Four attributes exist. | |
| 5.2 | Key user: open the **Item Card** of `UAT M00001`, choose **Orderkenmerken**. Add a row for `UAT HARDHEID` and set Default Value to `Super` (not an existing value). | An error is shown; the value is not saved (the field stays blank or the row is not added). | |
| 5.3 | Key user: on the same page, set Default Value of the `UAT HARDHEID` row to `Hard` (an existing value). | The value is accepted and saved. | |
| 5.4 | Key user: add a row for `UAT DECIMAL` with Default Value `abc`, then `12.5`. | `abc` is rejected with an error and not saved; `12.5` is accepted. | |
| 5.5 | Key user: add a row for `UAT INTEGER` with Default Value `abc`, then `5`. | `abc` is rejected; `5` is accepted. | |
| 5.6 | Key user: add a row for `UAT DATE` with Default Value `not a date`, then today's date in the field's normal input format. | `not a date` is rejected; today's date is accepted. | |
| 5.7 | Key user: add a row for `UAT TEXT` with Default Value `Any text 123!`. | Accepted — Text attributes take any value. | |

### 6. No retroactive effect (AC5)

| Step | Action | Expected result | Pass/Fail |
|---|---|---|---|
| 6.1 | Key user: open **Resulterende instelling tonen** for `UAT M00001` and note whether `UAT TEXT` or any newly added attribute from scenario 5 appears for it (it should not, since those rows were added on `UAT M00001` itself in scenario 5, so they should already appear — note the current list as the "before" state). | List noted. | |
| 6.2 | Key user: open the **Item Category Card** of `UAT MATRAS`, choose **Orderkenmerken**, and add a new row for `UAT INTEGER` with Mandatory = Yes. | The row is saved. | |
| 6.3 | Key user: immediately reopen **Resulterende instelling tonen** for `UAT M00001`. | `UAT INTEGER` now appears as Mandatory = Yes — the change is reflected right away, with no need to reopen the client, restart a session or wait. This is the only form AC5 takes in this release: there is no sales order line to check "stays unchanged, new line gets it", since nothing yet creates line attributes from this setting (see the feature doc). | |

### 7. User without `ATT CUSTOM`

| Step | Action | Expected result | Pass/Fail |
|---|---|---|---|
| 7.1 | Other user (no `ATT CUSTOM`): open the **Item Category Card** of `UAT MATRAS` and the **Item Card** of `UAT M00001`. | The **Orderkenmerken** action is available or not, consistent with what the user's own permission sets grant on table `Item Attribute Value Mapping` (a base-app table) — this feature does not add a tabledata permission for that table. Note what is actually observed, since this depends on the customer's own security setup, not on anything `ATT CUSTOM` controls. | |
| 7.2 | If 7.1 shows the **Orderkenmerken** action available: try to set a new Default Value on `UAT DECIMAL`, `UAT INTEGER` or `UAT DATE` that has no existing matching value yet (for example a decimal the user has not entered before). | If the other user's own permission sets do not separately grant insert on table `Item Attribute Value`, this fails with an insert-permission error — `ATT CUSTOM` is the only permission set in this app that grants it (see the feature doc's [Setup and permissions](../features/CU-123x5y65qpa-order-attribute-settings.md#setup-and-permissions)). Entering an existing Option value, or leaving the field blank, is not affected. | |
| 7.3 | Other user: open the **Item Card** of `UAT M00001` and look for **Resulterende instelling tonen**. | Same as 7.1: availability depends on the user's existing permissions on `Item Attribute Value Mapping`, `Item Attribute` and `Item Attribute Value`, not on `ATT CUSTOM`. This action only reads data, so it never inserts an `Item Attribute Value` row and is unaffected by the `ATT CUSTOM`-only insert permission tested in 7.2. | |

## Not covered by this script

These are covered by the automated tests in `Customer Extensions Test`
(codeunit 50156 `ATT Order Attr. Setting Test`), or have no UI in this release:

- the print-setting override behaviour (Open Question 2): when the two
  "Show on ... Documents" overrides are left blank, the result falls back to the
  item attribute's own flag; when set to Yes/No, they win;
- the cyclic-category defensive check in `GetResultingSetting`;
- creating or refreshing `ATT Document Line Attribute` rows on a sales line —
  out of scope for this task.

## Clean-up

Key user: delete items `UAT M00001`, `UAT M00002`, `UAT M00003`; item categories
`UAT MATRAS`, `UAT N18`, `UAT N18B`, `UAT TOPPER`; and item attributes
`UAT HARDHEID`, `UAT DECIMAL`, `UAT INTEGER`, `UAT DATE`, `UAT TEXT` (and their
values). None of them are assigned to sales documents, so they can be deleted.

## Sign-off

| Role | Name | Date | Result |
|---|---|---|---|
| Key user | | | |
