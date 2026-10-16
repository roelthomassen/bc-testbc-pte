# CU-123x5y65gje: Tabel Documentregelkenmerk (Document Line Attribute table)

- ClickUp: https://app.clickup.com/t/123x5y65gje
- Type: Feature
- Estimate: 12 h (raised from 5 h because automatic delete, archive copy and
  posting copy are now in scope, see Q7)
- Branch: `feature/CU-123x5y65gje-Tabel-Documentregelkenmerk`
- Develop in AL. Translations nl-BE and en-US via XLIFF.

## Business need

We need one central table that stores the attributes (kenmerken) of every kind of
document line in the same way: sales lines, archived sales lines, posted lines and,
later, production order lines.

### Scope (from the task)

- New table with the primary key:
  Table ID (Tabel-id), Document Type (Documentsoort), Document No. (Documentnr.),
  Doc. No. Occurrence (Doc.-nr. voorkomen), Version No. (Versienr.),
  Line No. (Regelnr.), Attribute ID (Kenmerk-id).
- Fields:
  - Attribute Value ID (Kenmerkwaarde-id)
  - Value (Waarde), Text[250]: snapshot (Q2)
  - Unit of Measure (Eenheid), Text[30]: snapshot (Q3)
  - Source (Bron): " " / Item / Variant / Order / Parent Line (Artikel/Variant/Order/Hoofdregel) (Q4)
  - Manually Modified (Manueel gewijzigd)
  - Mandatory (Verplicht)
  - Sequence (Volgorde)
  - Show on Customer Documents (Tonen op klantdocumenten)
  - Show on Production Documents (Tonen op productiedocumenten)
- Supported Table IDs: 37 (Sales Line), 5108 (Sales Line Archive),
  111 (Sales Shipment Line), 113 (Sales Invoice Line), 115 (Sales Cr.Memo Line),
  6661 (Return Receipt Line). Prepared for 5406 (Prod. Order Line).
- Helper functions to:
  - copy all attributes of a source line to a target line;
  - delete all attributes of a line.
- Added after clarification (Q7): automatic delete on line deletion, and
  automatic copy on archive and on posting.
- Not in scope (Q8): pages/UI.

## Acceptance criteria

1. **Stored value (AC1).** Given a line attribute whose attribute value is
   "Medium", when the text of that attribute value is changed to "Mid" in table
   7501 (Item Attribute Value), then the line attribute still shows "Medium" in
   the Value field.
2. **Snapshot on assignment.** Given an Item Attribute with Unit of Measure "cm"
   and a value "Medium", when Attribute Value ID is validated on a line attribute,
   then Value = "Medium" and Unit of Measure = "cm". A later change to the unit on
   the Item Attribute does not change the line attribute. An Attribute Value ID
   that belongs to a different Attribute ID is rejected. *(Q2, Q3)*
3. **Copy (AC2).** Given a sales line with 8 line attributes, when the copy
   function is run towards another document line, then the target line has
   exactly the same 8 attributes, with the same Value, Unit of Measure, Source,
   flags (Manually Modified, Mandatory, Show on Customer Documents, Show on
   Production Documents) and Sequence. If the target line already had
   attributes, they are removed first, so the target has exactly 8 afterwards,
   including when one of its earlier attributes is not on the source. *(Q5)*
4. **Archive key (AC3).** Given an archived sales line with Version No. 2, when
   attributes are stored for that line, then they are unique per version and do
   not collide with the attributes of Version No. 1 of the same line.
5. **Delete function.** Given a line with attributes, when the delete function
   is run for that line, then all of its attributes are removed and attributes of
   other lines (including other versions/occurrences of the same document) remain.
6. **Supported tables.** Attributes can be stored for each of the Table IDs 37,
   5108, 111, 113, 115 and 6661, and the design allows 5406 to be added without
   changing the primary key. Inserting a record with any other Table ID raises an
   error. *(Q6)*
7. **Document Type.** For 37 and 5108, Document Type holds the ordinal of the
   line's `Sales Document Type`. For 111, 113, 115 and 6661 it is 0. *(Q1)*
8. **Default Source.** A new line attribute has Source " " (blank) until it is
   set. *(Q4)*
9. **Automatic delete.** Given a line with attributes in any supported table,
   when that line is deleted (including through deletion of its document), then
   its attributes are deleted. Attributes of other lines remain. *(Q7)*
10. **Automatic copy on archive.** Given a sales order whose lines have
    attributes, when the order is archived (manually or automatically), then each
    Sales Line Archive line has the same attributes as its source sales line,
    under the archive's Doc. No. Occurrence and Version No. Archiving the same
    order again creates a new version without changing the attributes of the
    previous version. *(Q7)*
11. **Automatic copy on posting.** Given sales documents whose lines have
    attributes, when they are posted, then the resulting Sales Shipment Line,
    Sales Invoice Line, Sales Cr.Memo Line and Return Receipt Line records each
    have the same attributes as their source sales line. *(Q7)*
12. **Translations.** All captions and labels are available in en-US and nl-BE
    through XLIFF.

## Open questions

1. **Document Type field type.** Table 37/5108 use the `Sales Document Type` enum,
   posted lines (111/113/115/6661) have no document type, and 5406 uses
   `Production Order Status`. Use a dedicated ATT enum, or an Integer storing the
   ordinal of the source enum (0 for posted lines)?

   **Answer:** Integer that stores the ordinal of the source table's own enum
   (Sales Document Type for 37/5108, Production Order Status for 5406), and 0 for
   posted lines (111/113/115/6661). The value is only meaningful together with
   Table ID.
2. **Attribute ID / Attribute Value ID.** Confirm these refer to the standard
   Item Attribute (7500) and Item Attribute Value (7501) tables, with a
   TableRelation on both (value filtered on the attribute).

   **Answer:** Yes. Attribute ID has a TableRelation to `Item Attribute`.ID, and
   Attribute Value ID has a TableRelation to `Item Attribute Value`.ID filtered on
   Attribute ID. Validating Attribute Value ID copies the value text into Value as
   a snapshot.
3. **Unit of Measure.** Snapshot of `Item Attribute."Unit of Measure"` (Text[30])
   at the moment the attribute is assigned, like Value — or a live lookup?

   **Answer:** Snapshot, like Value. Text[30], copied from
   `Item Attribute."Unit of Measure"` when the attribute is assigned. Later
   changes to the master attribute do not change stored lines.
4. **Source enum.** Is a blank/" " value needed as default, besides Item, Variant,
   Order and Parent Line?

   **Answer:** Yes. The values are " " (0, the default), Item, Variant, Order and
   Parent Line.
5. **Copy behaviour on an existing target.** If the target line already has
   attributes: replace all, merge (overwrite matching Attribute IDs), or error?

   **Answer:** Replace all. The copy function first deletes every attribute of the
   target line and then copies the source attributes, so the target ends up
   identical to the source.
6. **Unsupported Table IDs.** Should inserting a record with a Table ID outside
   the supported list raise an error?

   **Answer:** Yes. Inserting a record with a Table ID other than 37, 5108, 111,
   113, 115 or 6661 raises a clear error. 5406 is added to the list in the task
   that implements production order lines.
7. **Automatic cleanup/propagation.** Out of scope for this task: deleting
   attributes automatically when a line is deleted, and copying them on
   archive/post. Confirm these are follow-up tasks.

   **Answer:** Both are in scope for this task.
   - **Delete:** when a record in a supported line table (37, 5108, 111, 113,
     115, 6661) is deleted, its attributes are deleted as well.
   - **Archive:** when a sales document is archived, the attributes of each
     Sales Line (37) are copied to the matching Sales Line Archive (5108) line,
     with its Doc. No. Occurrence and Version No.
   - **Post:** when a sales document is posted, the attributes of each Sales
     Line (37) are copied to the posted line it creates: Sales Shipment Line
     (111), Sales Invoice Line (113), Sales Cr.Memo Line (115) or Return Receipt
     Line (6661).
   - Note: this makes the task bigger than the 5 h estimate.
8. **UI.** No page is mentioned. Is a (read-only) list page needed now, e.g. for
   support/troubleshooting, or does UI come in a later task?

   **Answer:** No UI in this task, only the table and the logic. A page comes in a
   later task.

## Plan

Approved 2026-10-16.

### Housekeeping
- The template `Customer Extensions/HelloWorld.al` (pageextension 50100) and
  `Customer Extensions Test/HelloWorld.Test.al` (codeunit 50150) are removed.

### Main app (`Customer Extensions/`, IDs 50100–50149)
| Object | ID / name | Purpose |
|---|---|---|
| Enum | 50100 `ATT Line Attribute Source` | `" "` (0), Item, Variant, Order, Parent Line |
| Table | 50100 `ATT Document Line Attribute` | Central table for line attributes |
| Codeunit | 50100 `ATT Doc. Line Attribute Mgt.` | Public helpers: `CopyAttributes`, `DeleteAttributes`, `IsSupportedTable` |
| Codeunit | 50101 `ATT Doc. Line Attr. Subscr.` | Event subscribers: automatic delete, archive copy, posting copy |
| Permission set | 50100 `ATT CUSTOM` | Assignable. RIMD on the table, X on the codeunits. Every new object goes here. |
| app.json | `"TranslationFile"` feature | `Translations/Customer Extensions.g.xlf` (en-US source, generated) + `Customer Extensions.nl-BE.xlf` |

**Table fields.** The primary key is fields 1–7.
- 1 `Table ID` Integer
- 2 `Document Type` Integer: the source enum value (Sales Document Type for 37/5108), 0 for posted lines
- 3 `Document No.` Code[20]
- 4 `Doc. No. Occurrence` Integer
- 5 `Version No.` Integer
- 6 `Line No.` Integer
- 7 `Attribute ID` Integer, TableRelation `Item Attribute`
- 10 `Attribute Value ID` Integer, TableRelation `Item Attribute Value` where
  `Attribute ID` = field(`Attribute ID`). OnValidate copies `Value` (from the
  attribute value) and `Unit of Measure` (from the attribute).
- 11 `Value` Text[250]
- 12 `Unit of Measure` Text[30]
- 13 `Source` Enum `ATT Line Attribute Source`
- 14 `Manually Modified` Boolean
- 15 `Mandatory` Boolean
- 16 `Sequence` Integer
- 17 `Show on Customer Documents` Boolean
- 18 `Show on Production Documents` Boolean
- Second key: line key fields 1–6 + `Sequence`.
- `OnInsert` raises an error if the Table ID is not 37, 5108, 111, 113, 115 or 6661.
- DataClassification is CustomerContent.

**Management codeunit**
- `CopyAttributes(FromLine: Variant; ToLine: Variant)` and
  `DeleteAttributes(Line: Variant)` take a record of a supported line table. The
  key is read from typed records, one case per table, not from field numbers.
- Each has a low-level overload with explicit key values (used to add 5406 later
  without changing the key).
- Copy first deletes all attributes of the target line, then copies every field.

**Subscribers**
- **Delete:** `OnAfterDeleteEvent` on 37, 5108, 111, 113, 115 and 6661. Temporary
  records are skipped. Known trade-off: global delete subscribers make `DeleteAll`
  on these tables run row by row.
- **Archive:** `ArchiveManagement.OnAfterStoreSalesLineArchive` copies 37 → 5108,
  using the archive line's Doc. No. Occurrence and Version No.
- **Post:** `Sales-Post` events `OnAfterSalesShptLineInsert`,
  `OnAfterSalesInvLineInsert`, `OnAfterSalesCrMemoLineInsert` and
  `OnAfterReturnRcptLineInsert` copy 37 → 111/113/115/6661. The source Sales Line
  in these events can be temporary: only its key values are used. The order
  line's own attributes are removed by the delete subscriber when posting
  deletes the line.

**UI/API:** none.

### Tests

Details (test data, permission checks, workspace setup) are in the
[Tests section of the feature doc](../features/CU-123x5y65gje-document-line-attribute.md#tests).

**Sandbox test app (`Customer Extensions Test/`, IDs 50150–50179)**
- Must compile and run in a BC 28 BE online sandbox.
- app.json: dependencies on `Customer Extensions` and the Microsoft test apps
  `Library Assert`, `Any` and `Test Runner` only. `Library Variable Storage` is
  allowed but not used. No dependency on `Tests-TestLibraries`.
- Codeunit 50150 `ATT Doc. Line Attr. Unit Test` covers AC1–AC6 and AC8.
- Codeunit 50151 `ATT Doc. Line Attr. Int. Test` covers AC7 and AC9–AC11:
  delete line/header, archive twice, post order (ship + invoice), credit memo,
  return order receive. (Shortened from "Integr." because AL object names are
  limited to 30 characters.)
- Codeunit 50152 `ATT Doc. Line Attr. Test Lib.`: attribute test helpers shared
  by the test codeunits.
- Codeunit 50153 `ATT Doc. Line Attr. Perm. Test`: checks the definition of
  `ATT CUSTOM` through `Metadata Permission Set`, `Metadata Permission` and
  `Expanded Permission`. It does not run code with lowered permissions.
- Codeunit 50154 `ATT Test Library`: creates its own posting setup and the test
  data (items, customers, sales documents, item attributes).
- Run with test runner 130450 "Test Runner - Isol. Codeunit" in a dedicated test
  company.
- AC12 is checked by the presence and contents of the XLIFF files.

**Container-only permission test app (`Customer Extensions Permission Test/`, IDs 50180–50199)**
- App ID `4e251cbe-799a-4e50-baad-7d34e78cfac9`. Depends on
  `Tests-TestLibraries` and `Permissions Mock`, and runs only in the AL-Go
  pipeline container, never in the online sandbox.
- Codeunit 50180 `ATT DLA Lowered Perm. Test`: 5 tests that run the action under
  `Library - Lower Permissions`, without `ATT CUSTOM`:
  - posting a sales order copies the attributes to the invoice line;
  - posting removes the attributes of the order line;
  - deleting a sales line deletes its attributes;
  - archiving a sales order copies the attributes to the archived line;
  - deleting an archived sales order deletes the attributes of its archived
    lines.
- Codeunit 50181 `ATT DLA Perm. Test Lib.`: helpers for these tests.

**Manual UAT**
- [docs/uat/CU-123x5y65gje-document-line-attribute.md](../uat/CU-123x5y65gje-document-line-attribute.md),
  including the check with a user who does not have `ATT CUSTOM`.

### Out of scope (follow-ups)
- Copying attributes through Copy Document or Get Shipment Lines.
- Standard flows that delete and re-create sales lines, where attributes are
  lost (decided after the guidelines review): `RecreateSalesLines` (changing
  customer, currency, etc. on a document with lines), Quote → Order,
  Blanket Order → Order, and restoring a document from the archive.
- Prepayment invoice/credit memo lines (posted by Sales-Post Prepayments).
- 5406 / production orders.
- Pages.

### Decisions after the guidelines review
- Permissions: the subscribers get `[InherentPermissions]` on the attribute
  table, so users without `ATT CUSTOM` can delete, archive and post. `ATT CUSTOM`
  is only needed for direct access to the table.
- Validating Attribute Value ID rejects a blocked Item Attribute or Item
  Attribute Value. Copies (archive, posting, `CopyAttributes`) are not affected.
- The nl-BE caption for Doc. No. Occurrence stays "Doc.-nr. voorkomen" (spec
  wording).
