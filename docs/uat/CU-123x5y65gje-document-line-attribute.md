# UAT: CU-123x5y65gje Document Line Attribute

- ClickUp: [Tabel Documentregelkenmerk](https://app.clickup.com/t/123x5y65gje) (CU-123x5y65gje)
- Spec: [docs/specs/CU-123x5y65gje.md](../specs/CU-123x5y65gje.md)
- Feature doc: [docs/features/CU-123x5y65gje-document-line-attribute.md](../features/CU-123x5y65gje-document-line-attribute.md)

| | |
|---|---|
| Environment | |
| Company | |
| App version (`Customer Extensions`) | |
| Tester (sales user) | |
| Key user (with `ATT CUSTOM`) | |
| Date | |

## Purpose

The main goal is to check, in the real online environment, that a normal sales
user who does **not** have the `ATT CUSTOM` permission set can post, delete and
archive sales lines that have document line attributes, and that the attributes
follow the line. The automated permission tests run in a container with the
permission sets of the test libraries; this script checks the customer's own
permission sets and security groups. The script also covers the main functional
acceptance criteria of the spec.

## How to work with the attribute table

This release has no page for `ATT Document Line Attribute` (table 50100), and
nothing copies an item's attributes to its sales lines yet. Assigning attributes
to the item does **not** create document line attributes. The key user therefore
creates and checks them directly in the table:

- **Create:** with a configuration package on table 50100 (see step P4).
- **Check:** open the table in the web client by adding `&table=50100` to the URL
  of the environment and company, then filter on `Table ID` and `Document No.`
  with the filter pane. The table opens read-only.

Only the key user works in the table. The sales user only uses the normal sales
pages.

Values used in the table:

| Field | Value |
|---|---|
| `Table ID` | 37 Sales Line, 5108 Sales Line Archive, 111 Sales Shipment Line, 113 Sales Invoice Line |
| `Document Type` | 1 for a sales order (on 37 and 5108), 0 on posted lines (111, 113) |
| `Doc. No. Occurrence`, `Version No.` | 0, except on 5108 |

## Preconditions

| Step | Action | Expected result | Pass/Fail |
|---|---|---|---|
| P1 | Sales user: make sure the user has `D365 BUS FULL ACCESS` (or the customer's normal sales role) and does **not** have `ATT CUSTOM` or `SUPER`, directly or through a security group. On the user, open **Effective Permissions** and look up table data 50100 `ATT Document Line Attribute`. | No read, insert, modify or delete permission on table data 50100. | |
| P2 | Key user: make sure the user has `ATT CUSTOM` (or `SUPER`). | The key user can open `&table=50100`. | |
| P3 | Key user: on **Item Attributes**, create attribute `UAT SIZE` (Type Option, Unit of Measure `cm`) with values `Medium` and `Large`, and attribute `UAT COLOUR` (Type Option, no unit) with value `Red`. Look up the IDs of the attributes and values with `&table=7500` and `&table=7501`. | Two attributes and three values exist. IDs noted: ______ | |
| P4 | Key user: on **Configuration Packages**, create package `UAT-DLA` with table 50100. In the fields of the table, include `Table ID`, `Document Type`, `Document No.`, `Doc. No. Occurrence`, `Version No.`, `Line No.`, `Attribute ID`, `Attribute Value ID`, `Source`, `Mandatory`, `Sequence`, `Show on Customer Documents` and `Show on Production Documents`. Exclude `Value` and `Unit of Measure`: they are filled when `Attribute Value ID` is validated. Keep **Validate Field** on for `Attribute Value ID`, and leave **Skip Table Triggers** off on the package table, so the table's checks run. Use **Export to Excel** to get the template. | The package exists and exports an empty template. | |
| P5 | Sales user: pick an item that can be sold and posted, with stock or with negative inventory allowed. Create four sales orders for that item, each for an existing customer: order **A** with 1 line (10000), order **B** with 2 lines (10000, 20000), order **C** with 1 line (10000) and order **D** with 1 line (10000). Order D is only used for the error check in step 1.5. Note the numbers. | Orders A: ______ B: ______ C: ______ D: ______ | |
| P6 | Key user: in the Excel template, add rows with `Table ID` 37, `Document Type` 1, occurrence and version 0: for A line 10000, B lines 10000 and 20000, and C line 10000, each with `UAT SIZE` = `Medium` (Sequence 1, Source Item) and `UAT COLOUR` = `Red` (Sequence 2, Source Item). Set `Mandatory` and `Show on Customer Documents` to Yes on the `UAT SIZE` rows. **Import from Excel**, then **Apply Package**. | The package applies with no errors. 8 rows in table 50100 for table 37. | |

## Scenarios

### 1. Stored value and snapshot (AC1, AC2, AC8)

| Step | Action | Expected result | Pass/Fail |
|---|---|---|---|
| 1.1 | Key user: open `&table=50100`, filter on order A. | `UAT SIZE` row: Value `Medium`, Unit of Measure `cm`, Source Item, Mandatory and Show on Customer Documents Yes, Sequence 1. `UAT COLOUR` row: Value `Red`, Unit of Measure blank, Sequence 2. | |
| 1.2 | Key user: on **Item Attribute Values** of `UAT SIZE`, change `Medium` to `Mid`. On **Item Attributes**, change the unit of `UAT SIZE` from `cm` to `mm`. | The changes are saved. | |
| 1.3 | Key user: open `&table=50100` again for order A. | The line attribute still shows Value `Medium` and Unit of Measure `cm`. | |
| 1.4 | Key user: change the value back to `Medium` and the unit back to `cm`, so later steps match. | Restored. | |
| 1.5 | Key user: in a new Excel import, add one row for order **D** line 10000 (`Table ID` 37, `Document Type` 1) with `Attribute ID` of `UAT COLOUR` and `Attribute Value ID` of `Medium` (a value of `UAT SIZE`), and one row with `Table ID` 36. Import and apply. | Both rows are reported as package errors, for example "Attribute value ... does not exist for attribute ..." and "Document line attributes cannot be stored for table 36." (the package can also report the first one as a table relation error). No row for table 36 in table 50100. For order D, a row with a blank Value may remain: RapidStart can insert the row with its key before the `Attribute Value ID` validation fails. That is accepted; step 1.6 removes it. | |
| 1.6 | Key user: delete the error rows from the package. Sales user: delete order D. Key user: open `&table=50100`, filter `Table ID` 37 and order D. | The package has no open errors. No rows for order D. | |

> Step 1.5 has not been run yet against this release. Confirm the exact package
> behaviour (error texts, and whether a blank-Value row remains for order D) in a
> dry run before the real UAT, and update the expected result if needed.

### 2. Post a sales order as the sales user (AC7, AC9, AC11)

| Step | Action | Expected result | Pass/Fail |
|---|---|---|---|
| 2.1 | Sales user: open order A and choose **Post**, **Ship and Invoice**. | The order posts with no permission error. Posted shipment no.: ______ Posted invoice no.: ______ | |
| 2.2 | Key user: open `&table=50100`, filter `Table ID` 113 and the posted invoice no. | Line 10000 has the same 2 attributes as order A in step 1.1: same Attribute Value ID, Value, Unit of Measure, Source, Mandatory, Sequence and Show on fields. `Document Type` is 0. | |
| 2.3 | Key user: filter `Table ID` 111 and the posted shipment no. | Line 10000 has the same 2 attributes. `Document Type` is 0. | |
| 2.4 | Key user: filter `Table ID` 37 and the number of order A. | No rows: the order was fully posted, so its line and its attributes are gone. | |

If **Archive Orders** is on in the Sales & Receivables Setup, posting also
archives order A. Then table 5108 has rows for order A as well; that is expected.

### 3. Delete a sales line and a sales order as the sales user (AC9)

| Step | Action | Expected result | Pass/Fail |
|---|---|---|---|
| 3.1 | Sales user: open order B and delete line 10000. | The line is deleted with no permission error. | |
| 3.2 | Key user: open `&table=50100`, filter `Table ID` 37 and order B. | No rows for line 10000. The 2 rows of line 20000 are still there. | |
| 3.3 | Sales user: delete order B. | The order is deleted with no permission error. | |
| 3.4 | Key user: filter `Table ID` 37 and order B again. | No rows. | |

### 4. Archive a sales order and delete an archived version as the sales user (AC3, AC9, AC10)

| Step | Action | Expected result | Pass/Fail |
|---|---|---|---|
| 4.1 | Sales user: open order C and choose **Archive Document**. | The order is archived with no permission error. | |
| 4.2 | Key user: open `&table=50100`, filter `Table ID` 5108 and order C. | Line 10000 has the same 2 attributes as the order line, with `Document Type` 1, the `Doc. No. Occurrence` of the order and `Version No.` 1 (or the version number shown on **Sales Order Archives**). | |
| 4.3 | Key user: filter `Table ID` 37 and order C. | The 2 attributes of the order line are still there. Archiving does not remove them. | |
| 4.4 | Sales user: archive order C again. | A new archive version is created with no permission error. | |
| 4.5 | Key user: filter `Table ID` 5108 and order C. | Both versions have their own 2 attributes. The rows of the first version are unchanged. | |
| 4.6 | Sales user: on **Sales Order Archives**, delete the first archived version of order C. | The version is deleted with no permission error. | |
| 4.7 | Key user: filter `Table ID` 5108 and order C. | No rows for the deleted version. The 2 rows of the other version are still there. | |

### 5. Translations (AC12)

| Step | Action | Expected result | Pass/Fail |
|---|---|---|---|
| 5.1 | Key user: in **My Settings**, set the language to Dutch (Belgium). Open `&table=50100`. | The table caption is `Documentregelkenmerk`; column captions are Dutch, for example `Documentsoort`, `Documentnr.`, `Doc.-nr. voorkomen`, `Regelnr.`, `Kenmerk-id`, `Kenmerkwaarde-id`, `Verplicht`. | |
| 5.2 | Key user: set the language back. | | |

## Not covered by this script

These are covered by the automated tests in `Customer Extensions Test`, or have
no UI in this release:

- the `CopyAttributes` and `DeleteAttributes` procedures (AC3 copy, AC5);
- credit memo and return order posting (Sales Cr.Memo Line 115, Return Receipt
  Line 6661);
- a blocked Item Attribute or Item Attribute Value being rejected on assignment.

## Clean-up

Key user: delete configuration package `UAT-DLA`. The posted documents and
archives of the test stay in the company; run the script in a sandbox or test
company if they must not end up in LIVE.

## Sign-off

| Role | Name | Date | Result |
|---|---|---|---|
| Tester | | | |
| Key user | | | |
