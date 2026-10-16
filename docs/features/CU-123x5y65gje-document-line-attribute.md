# Document Line Attribute

- ClickUp: [Tabel Documentregelkenmerk](https://app.clickup.com/t/123x5y65gje) (CU-123x5y65gje)
- Spec: [docs/specs/CU-123x5y65gje.md](../specs/CU-123x5y65gje.md)
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
| 7 | Attribute ID | Integer | Relation to `Item Attribute` (7500). Changing it clears Attribute Value ID, Value and Unit of Measure. |
| 10 | Attribute Value ID | Integer | Relation to `Item Attribute Value` (7501), filtered on Attribute ID. |
| 11 | Value | Text[250] | Snapshot, see below. |
| 12 | Unit of Measure | Text[30] | Snapshot, see below. |
| 13 | Source | Enum `ATT Line Attribute Source` | `" "` (0, default), Item, Variant, Order, Parent Line. |
| 14 | Manually Modified | Boolean | |
| 15 | Mandatory | Boolean | |
| 16 | Sequence | Integer | Display order on the line. |
| 17 | Show on Customer Documents | Boolean | |
| 18 | Show on Production Documents | Boolean | |

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

In the test app (`Customer Extensions Test`):

- `ATT Doc. Line Attr. Unit Test` (50150): AC1–AC6, AC8.
- `ATT Doc. Line Attr. Int. Test` (50151): AC7, AC9–AC11.
- `ATT Doc. Line Attr. Test Lib.` (50152): shared helpers.
- `ATT Doc. Line Attr. Perm. Test` (50153): runs with `TestPermissions =
  Restrictive` and uses `Library - Lower Permissions` (`SetSalesDocsPost`,
  `SetSalesDocsCreate`) without `ATT CUSTOM`. It covers posting a sales document
  and deleting a sales line that has attributes. Archiving under lowered
  permissions is not covered yet.
