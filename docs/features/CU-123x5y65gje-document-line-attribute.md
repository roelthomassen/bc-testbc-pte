# Document Line Attribute

- ClickUp: [Tabel Documentregelkenmerk](https://app.clickup.com/t/123x5y65gje) (CU-123x5y65gje)
- Spec: [docs/specs/CU-123x5y65gje.md](../specs/CU-123x5y65gje.md)
- UAT script: [docs/uat/CU-123x5y65gje-document-line-attribute.md](../uat/CU-123x5y65gje-document-line-attribute.md)
- App: `Customer Extensions`

## Purpose

One central table stores the attributes (kenmerken) of document lines in the same
way for every line type: sales lines, archived sales lines and posted sales lines.
Production order lines will follow in a later task. The attributes follow the line
automatically: they are deleted with the line, and copied when a sales document is
archived or posted. This task adds no UI; a page comes in a later task.

## Objects

| Object | ID | Name | Role |
|---|---|---|---|
| Enum | 50100 | `ATT Line Attribute Source` | Where an attribute comes from. |
| Table | 50100 | `ATT Document Line Attribute` | Stores the attributes per document line. |
| Codeunit | 50100 | `ATT Doc. Line Attribute Mgt.` | Public helpers: `CopyAttributes`, `DeleteAttributes`, `IsSupportedTable`. |
| Codeunit | 50101 | `ATT Doc. Line Attr. Subscr.` | Internal. Event subscribers for automatic delete, archive copy and posting copy. |
| Permission set | 50100 | `ATT CUSTOM` | RIMD on the table, X on the table and codeunits. |

The table calls `IsSupportedTable` on insert and rename. The subscriber codeunit
calls the management codeunit for all its work.

## Data model

Primary key (fields 1–7): `Table ID`, `Document Type`, `Document No.`,
`Doc. No. Occurrence`, `Version No.`, `Line No.`, `Attribute ID`. Fields 1–6
identify the line; `Attribute ID` identifies the attribute on that line. A second
key `LineSequence` (fields 1–6 + `Sequence`) gives the attributes of a line in
display order.

| No. | Field | Type | Notes |
|---|---|---|---|
| 1 | Table ID | Integer | ID of the line table, see [Supported tables](#supported-tables). |
| 2 | Document Type | Integer | See [Document Type encoding](#document-type-encoding). |
| 3 | Document No. | Code[20] | |
| 4 | Doc. No. Occurrence | Integer | Only for Sales Line Archive, otherwise 0. |
| 5 | Version No. | Integer | Only for Sales Line Archive, otherwise 0. |
| 6 | Line No. | Integer | |
| 7 | Attribute ID | Integer | Relation to `Item Attribute` (7500). Changing it clears Attribute Value ID, Value and Unit of Measure, and copies fields 17 and 18 from the Item Attribute (CU-123x5y65hfj). |
| 10 | Attribute Value ID | Integer | Relation to `Item Attribute Value` (7501), filtered on Attribute ID. |
| 11 | Value | Text[250] | Snapshot, see below. |
| 12 | Unit of Measure | Text[30] | Snapshot, see below. |
| 13 | Source | Enum `ATT Line Attribute Source` | `" "` (0, default), Item, Variant, Order, Parent Line. |
| 14 | Manually Modified | Boolean | |
| 15 | Mandatory | Boolean | |
| 16 | Sequence | Integer | Display order on the line. |
| 17 | Show on Customer Documents | Boolean | Copied from the Item Attribute when Attribute ID is validated (snapshot). See [Item Attribute Print Settings](CU-123x5y65hfj-item-attribute-print-settings.md#copy-to-the-document-line-attribute). |
| 18 | Show on Production Documents | Boolean | Same as field 17. |

DataClassification is `CustomerContent`.

### Snapshot of Value and Unit of Measure

When `Attribute Value ID` is validated, `Value` is copied from
`Item Attribute Value.Value` and `Unit of Measure` from
`Item Attribute."Unit of Measure"`. Later changes to the item attribute or its
value do not change lines that already have the attribute. Validating
`Attribute Value ID` to 0 clears both `Value` and `Unit of Measure`.

Validation raises an error when:

- the Attribute Value ID does not belong to the line's Attribute ID;
- the Item Attribute is blocked;
- the Item Attribute Value is blocked.

Only validation triggers the snapshot and these checks. Code that assigns
`Attribute Value ID` without `Validate` must fill `Value` and `Unit of Measure`
itself. `CopyAttributes`, archiving and posting do not validate again. They copy
the stored values even if the attribute or value has been blocked since then.

### Document Type encoding

`Document Type` is an Integer, and only has a meaning together with `Table ID`:

- Sales Line (37) and Sales Line Archive (5108): the ordinal of the line's
  `Sales Document Type` (for example 1 = Order).
- Posted lines (111, 113, 115, 6661): always 0.
- Prod. Order Line (5406), when added: the ordinal of `Production Order Status`.

## Supported tables

| Table ID | Table |
|---|---|
| 37 | Sales Line |
| 5108 | Sales Line Archive |
| 111 | Sales Shipment Line |
| 113 | Sales Invoice Line |
| 115 | Sales Cr.Memo Line |
| 6661 | Return Receipt Line |

Inserting or renaming a record with any other Table ID raises an error.

Prod. Order Line (5406) is prepared but not supported yet. The primary key
already fits it (Document Type = status, Document No. = order no., Line No.), so
adding it means extending `IsSupportedTable` and the table cases in the
management codeunit, not changing the key.

## Helper API

Codeunit `ATT Doc. Line Attribute Mgt.` (50100):

- `CopyAttributes(FromLine: Variant; ToLine: Variant)` copies all attributes from
  one line to another. The target's existing attributes are deleted first, so it
  ends up identical to the source. All fields are copied (Value, Unit of
  Measure, Source, flags, Sequence). Nothing happens if source and target are the
  same line.
- `DeleteAttributes(Line: Variant)` deletes all attributes of one line. Other
  lines, versions and occurrences of the same document are not touched.
- `IsSupportedTable(TableId: Integer): Boolean`.

The Variant overloads take a record of one of the supported tables and read the
key from it. Only the key values are used, so temporary records work. Anything
else raises an error. Both procedures also have an overload with explicit key
values (table ID, document type, document no., occurrence, version no., line
no.) for tables that the Variant overload does not handle yet.

Example: copy attributes from a sales line to another sales line.

```al
var
    FromSalesLine, ToSalesLine: Record "Sales Line";
    DocLineAttributeMgt: Codeunit "ATT Doc. Line Attribute Mgt.";
begin
    DocLineAttributeMgt.CopyAttributes(FromSalesLine, ToSalesLine);
end;
```

Example: delete the attributes of a line by key values.

```al
DocLineAttributeMgt.DeleteAttributes(
    Database::"Sales Line", "Sales Document Type"::Order.AsInteger(), 'SO-1001', 0, 0, 10000);
```

## Automatic behaviour

Codeunit `ATT Doc. Line Attr. Subscr.` (50101):

- **Delete.** `OnAfterDeleteEvent` on 37, 5108, 111, 113, 115 and 6661 deletes
  the attributes of the deleted line. This also covers deleting a whole document,
  because the header deletes its lines. Temporary records are skipped. When an
  order is fully posted, the attributes of its lines are removed this way after
  they were copied to the posted lines.
- **Archive.** `ArchiveManagement.OnAfterStoreSalesLineArchive` copies the
  attributes of each Sales Line to its Sales Line Archive line, under that line's
  Doc. No. Occurrence and Version No. This applies to manual and automatic
  archiving. A new archive version gets its own copy; earlier versions are not
  changed.
- **Posting.** The `Sales-Post` events `OnAfterSalesShptLineInsert`,
  `OnAfterSalesInvLineInsert`, `OnAfterSalesCrMemoLineInsert` and
  `OnAfterReturnRcptLineInsert` copy the attributes of the source Sales Line to
  the new posted line. The Sales Line in these events can be a temporary copy;
  only its key is used. For return receipts, nothing is copied when the posted
  line was not actually inserted (empty Document No.).

## Setup and permissions

There is no setup. Users do not need `ATT CUSTOM` to delete, archive or post
sales documents. The subscriber procedures have `[InherentPermissions]` on table
`ATT Document Line Attribute`:

- read and delete (`rd`) for the delete subscribers;
- read and insert (`ri`) for the archive and posting subscribers. The target line
  is new and has no attributes yet, so nothing has to be deleted before the copy.

`ATT CUSTOM` is only needed for direct access to the table, for example by
administrators or support staff.

## Known trade-offs

The `OnAfterDeleteEvent` subscribers are global, so `DeleteAll` on Sales Line,
Sales Line Archive, Sales Shipment Line, Sales Invoice Line, Sales Cr.Memo Line
and Return Receipt Line runs row by row instead of as one bulk delete. This makes
large deletes on these tables slower (for example deleting old archives or posted
documents in bulk).

## Out of scope and known limitations

- Copying attributes through Copy Document or Get Shipment Lines.
- Standard flows that delete and re-create sales lines. The delete subscriber
  removes the attributes of the old lines and nothing copies them to the new
  lines, so the attributes are lost:
  - `RecreateSalesLines`: changing for example the customer, currency or VAT
    Bus. Posting Group on a document that already has lines;
  - converting a Quote to an Order;
  - creating an Order from a Blanket Order;
  - restoring a sales document from the archive.
- Prepayment invoice and credit memo lines. They are posted by Sales-Post
  Prepayments, not Sales-Post, so they get no attributes.
- Prod. Order Line (5406) and production orders in general.
- UI: there are no pages for this table yet.

## Translations

The app uses the `TranslationFile` feature. The compiler generates
`Customer Extensions/Translations/Customer Extensions.g.xlf` (en-US source); this
file is gitignored. `Customer Extensions.nl-BE.xlf` is checked in and contains
the Dutch (Belgium) translations of the captions, tooltips and labels. When you
add or change a caption, tooltip or label, rebuild to refresh the g.xlf and
update the nl-BE file from it.

## Tests

There are two test apps and a manual UAT script:

| App | Folder | IDs | Runs in |
|---|---|---|---|
| `Customer Extensions Test` | `Customer Extensions Test/` | 50150–50179 | BC 28 BE online sandbox, and the AL-Go pipeline container |
| `Customer Extensions Permission Test` | `Customer Extensions Permission Test/` | 50180–50199 | AL-Go pipeline container only |

`Customer Extensions Test` must compile and run in the BC 28 BE online sandbox.
AL-Go also runs it in the pipeline container: `appFolders` and `testFolders` are
empty in `.AL-Go/settings.json`, so AL-Go detects both test apps by itself.

UAT script: [docs/uat/CU-123x5y65gje-document-line-attribute.md](../uat/CU-123x5y65gje-document-line-attribute.md).

> **Run the sandbox tests with test runner 130450 "Test Runner - Isol. Codeunit"
> in a dedicated test company.** This applies to codeunits 50150, 50151 and
> 50153. Only codeunit isolation rolls back their changes when the codeunit ends.
> With another runner, or in a company that is used for anything else, these
> changes stay in the database.
>
> - 50150: `Initialize` changes nothing, but the tests write item attributes,
>   item attribute values and line attribute rows to the real tables.
> - 50151: `Initialize` changes setup (stockout and credit warnings, Exact Cost
>   Reversing Mandatory, and the posting setup of `ATT Test Library`) and commits
>   it; the tests also post documents.
> - 50153: only reads metadata, but runs with the same runner so that all
>   codeunits of the app are run the same way.

### Sandbox test app

`Customer Extensions Test` does not depend on `Tests-TestLibraries`; its only
test dependencies are `Library Assert`, `Any` and `Test Runner`.

- `ATT Doc. Line Attr. Unit Test` (50150): AC1–AC6, AC8.
- `ATT Doc. Line Attr. Int. Test` (50151): AC7, AC9–AC11, and the archive parts
  of AC3 (archiving an order twice).
- `ATT Doc. Line Attr. Test Lib.` (50152): shared helpers for the attribute tests.
- `ATT Doc. Line Attr. Perm. Test` (50153): checks the definition of `ATT CUSTOM`,
  see [Permission tests](#permission-tests).
- `ATT Test Library` (50154): creates the test data. See
  [Test data](#test-data).

All test codeunits of this app run with `TestPermissions = Disabled`.

### Test data

`ATT Test Library` replaces the `Library - Sales`, `Library - Inventory` and
`Library - Utility` codeunits, which are not available in an online sandbox. It
creates items, customers, sales headers and sales lines, posts sales documents
with `Sales-Post`, creates item attributes and values, sets the Sales &
Receivables Setup toggles the tests need (stockout warning, credit warnings,
Exact Cost Reversing Mandatory), and generates unique codes
(`GenerateUniqueCode`). Random values come from the `Any` codeunit.

The library creates its own posting setup and does not use the setup of the
company. `InitializePostingSetup` does this the first time it is needed in a
transaction; `CreateItem`, `CreateCustomer` and `CreateSalesHeader` call it, and
the integration tests also call it from `Initialize` before the `Commit`. It
creates:

- G/L accounts for sales, cost, interim, inventory, receivables and VAT;
- a VAT Business and VAT Product Posting Group with a VAT Posting Setup (Normal
  VAT, 21 %);
- a Gen. Business and Gen. Product Posting Group with a General Posting Setup;
- a Customer Posting Group and an Inventory Posting Group with Inventory Posting
  Setup;
- a separate G/L account for invoice rounding, with the library's Gen. and VAT
  Prod. Posting Groups, set as Invoice Rounding Account on the Customer Posting
  Group, so that invoice rounding lines post with the library's posting setup;
- a Unit of Measure, used as base unit of measure of the items it creates;
- a Location without warehouse handling or bins, only when Location Mandatory is
  on in the Inventory Setup or the Warehouse Setup requires shipment, receipt,
  pick or put-away. Sales headers get this location.

It also makes sure the work date can be posted on:

- when the work date is outside Allow Posting From/To in the General Ledger
  Setup or the current user's User Setup, those fields (and their date formulas)
  are cleared;
- the same for Allow VAT Date From/To in the User Setup and the VAT Setup.

Each setup record is only modified when one of its date windows had to be
cleared. The library changes nothing else in the User Setup.

When `Journal Templ. Name Mandatory` is on in the General Ledger Setup (BE), the
posted invoice and credit memo numbers come from the sales journal templates in
the Sales & Receivables Setup (`S. Invoice Template Name`, `S. Cr. Memo Template
Name`). If a template is blank or does not exist, the library creates a Sales
journal template with the Posted Invoice Nos. or Posted Credit Memo Nos. series
of the setup and links it; the Sales & Receivables Setup is only modified in
that case. It also clears the template's allowed posting date window when the
work date is outside it.

Document numbers still come from the number series of the company.
`CreateSalesHeader` checks the number series it needs for the document type
(for example Order Nos., Posted Shipment Nos. and Posted Invoice Nos. for an
order) and raises an error that names the setup field when one is blank or does
not exist. For invoices it also checks Posted Shipment Nos. when **Shipment on
Invoice** is on, and for credit memos Posted Return Receipt Nos. when **Return
Receipt on Credit Memo** is on.

Before you run the tests, make sure the test company has:

- the number series above filled in in the Sales & Receivables Setup (and on the
  sales journal templates, when `Journal Templ. Name Mandatory` is on);
- a number series line that is open on the work date for each of these series;
- automatic numbering (**Default Nos.**) on the posted-document series,
  otherwise the Posting No. Series on the document stays blank;
- no default dimensions with **Code Mandatory** on the G/L Account, Customer or
  Item tables (the library does not create dimensions).

### Permission tests

`Library - Lower Permissions` is not available in an online sandbox, so
`ATT Doc. Line Attr. Perm. Test` (50153) does not run code with lowered
permissions. It reads the `ATT CUSTOM` definition from system tables. Its 6 tests
check that:

1. `ATT CUSTOM` is assignable (`Metadata Permission Set`);
2. it grants RIMD on tabledata `ATT Document Line Attribute`;
3. it grants X on table `ATT Document Line Attribute`;
4. it grants X on codeunit `ATT Doc. Line Attribute Mgt.`;
5. it grants X on codeunit `ATT Doc. Line Attr. Subscr.`;
6. every table, page, report, codeunit, XMLport and query of
   `Customer Extensions` (from `AllObj`) has full permissions in `ATT CUSTOM`.

CU-123x5y65hfj added 3 more tests (X on `ATT Install`, `ATT Upgrade` and
`ATT Upgrade Mgt.`), see
[Item Attribute Print Settings](CU-123x5y65hfj-item-attribute-print-settings.md#permission-tests).

Tests 2–5 read `Metadata Permission`, so they only see permissions that are
written directly in `ATT CUSTOM`. Test 6 reads `Expanded Permission`, so it also
counts permissions that `ATT CUSTOM` gets from the permission sets it includes
(minus the ones it excludes), and a permission on object ID 0 (all objects of the
type).

The runtime behaviour for users without `ATT CUSTOM` is tested in the container
app, see the next section.

### Container-only permission test app

`Customer Extensions Permission Test` (app ID
`4e251cbe-799a-4e50-baad-7d34e78cfac9`) depends on `Tests-TestLibraries` and
`Permissions Mock` (`40860557-a18d-42ad-aecb-22b7dd80dc80`), besides
`Customer Extensions`, `Library Assert` and `Any`. `Tests-TestLibraries` is only
available in a container. The app runs in the AL-Go pipeline container and is
never published to the online sandbox.

- `ATT DLA Lowered Perm. Test` (50180), `TestPermissions = Restrictive`, 5 tests.
  Each test creates the data with full permissions, then lowers the permissions
  with `Library - Lower Permissions` to the standard sales permission sets
  (without `ATT CUSTOM`) for the action:
  - post a sales order (ship and invoice) with `SetSalesDocsPost`: the attributes
    are copied to the posted invoice line;
  - the same posting: the attributes of the order line are removed;
  - delete a sales line with `SetSalesDocsCreate`: its attributes are deleted;
  - archive a sales order with `SetSalesDocsCreate`: the attributes are copied to
    the archived line, under the archive's Doc. No. Occurrence and Version No.;
  - delete an archived sales order with `SetSalesDocsCreate`
    (`DeleteSalesOrderArchiveAsSalesUser_DeletesArchivedAttributes`): the
    attributes of the archived line are deleted.

  The posted and archived attributes are compared field by field with the
  original ones (Attribute Value ID, Value, Unit of Measure, Source, flags,
  Sequence).

  Right after lowering the permissions, each test asserts that the permissions
  mock (`Permissions Mock`) is running. Without a running mock the test would run
  with full permissions and pass without testing anything; now it fails with a
  message instead.
- `ATT DLA Perm. Test Lib.` (50181): helpers to create, count and compare line
  attributes. According to its code remark it is a trimmed copy of the helpers in
  `ATT Doc. Line Attr. Test Lib.` (50152), so that this app does not depend on the
  sandbox test app. When you change the shared helpers in 50152, make the same
  change in 50181.

These tests prove that the `[InherentPermissions]` on the subscribers (see
[Setup and permissions](#setup-and-permissions)) work at runtime with the
permission sets of the test libraries. They do not run against the real online
environment or the customer's own permission sets and security groups. The
[UAT script](../uat/CU-123x5y65gje-document-line-attribute.md) covers that: run
it with a real user that does not have `ATT CUSTOM`.

### Workspace and symbols

- `al.code-workspace` has a folder entry for `Customer Extensions Permission
  Test`, next to `Customer Extensions` and `Customer Extensions Test`, so that the
  AL extension loads it.
- Download the symbols for both test apps before you compile them locally
  (`AL: Download Symbols`):
  - `Customer Extensions Test`: from the sandbox. This gives the `Test Runner`
    symbols.
  - `Customer Extensions Permission Test`: from a container. `Tests-TestLibraries`
    is only available in a container, not in an online sandbox, so this app does
    not compile against the sandbox.
