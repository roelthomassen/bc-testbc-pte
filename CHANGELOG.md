# Changelog

All notable changes to the Customer Extensions app are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Entries are prefixed with the ClickUp task ID.

## [Unreleased]

### Added

- CU-123x5y65gje: New table 50100 `ATT Document Line Attribute` that stores item
  attributes per document line for Sales Line, Sales Line Archive, Sales Shipment
  Line, Sales Invoice Line, Sales Cr.Memo Line and Return Receipt Line. Value and
  Unit of Measure are stored as a snapshot when the attribute value is assigned.
  There is no page for it yet. See
  [docs/features/CU-123x5y65gje-document-line-attribute.md](docs/features/CU-123x5y65gje-document-line-attribute.md).
- CU-123x5y65gje: New enum 50100 `ATT Line Attribute Source` (blank, Item,
  Variant, Order, Parent Line).
- CU-123x5y65gje: Codeunit 50100 `ATT Doc. Line Attribute Mgt.` with public
  procedures `CopyAttributes`, `DeleteAttributes` and `IsSupportedTable`.
- CU-123x5y65gje: Line attributes are now deleted automatically when their line
  is deleted, and copied automatically when a sales document is archived or
  posted (shipment, invoice, credit memo and return receipt lines). Attributes
  are not carried over by Copy Document, Get Shipment Lines, re-creating sales
  lines (for example after a customer or currency change), Quote to Order,
  Blanket Order to Order, restoring from the archive, or prepayment posting; see
  the feature doc.
- CU-123x5y65gje: Permission set 50100 `ATT CUSTOM` for direct access to the
  attribute table (administrators, support). Users do not need it to delete,
  archive or post sales documents; the automatic delete and copy run with
  inherent permissions.
- CU-123x5y65gje: Validating Attribute Value ID rejects a blocked Item Attribute
  or Item Attribute Value.
- CU-123x5y65gje: nl-BE translations through XLIFF (`TranslationFile` feature).

### Changed

- CU-123x5y65gje: `DeleteAll` on Sales Line, Sales Line Archive, Sales Shipment
  Line, Sales Invoice Line, Sales Cr.Memo Line and Return Receipt Line now runs
  row by row because of the new delete subscribers. Bulk deletes on these tables
  are slower.

### Removed

- CU-123x5y65gje: The HelloWorld template objects (pageextension 50100 and test
  codeunit 50150) are removed. Object IDs 50100 and 50150 are now used by the
  new table/enum/codeunit/permission set and by the test codeunit
  `ATT Doc. Line Attr. Unit Test`.
