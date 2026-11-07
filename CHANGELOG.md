# Changelog

All notable changes to the Customer Extensions app are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Entries are prefixed with the ClickUp task ID.

## [Unreleased]

### Added

- CU-123x5y65qpa: Administrators can now configure order attribute settings
  (mandatory, sequence, default value, not applicable, and overrides of the
  print settings) per item category or per item, through a new
  **Orderkenmerken** action on the Item Category Card and the Item Card. The
  settings are added to the standard `Item Attribute Value Mapping` table
  (table extension 50101 `ATT Item Attr. Value Mapping`) rather than a new
  table. See
  [docs/features/CU-123x5y65qpa-order-attribute-settings.md](docs/features/CU-123x5y65qpa-order-attribute-settings.md).
- CU-123x5y65qpa: A new **Resulterende instelling tonen** action on the Item
  Card computes and shows the resulting order attribute setting of an item:
  for each attribute, the setting of the closest level wins (the item itself,
  then its item category, then each ancestor category, walked as far as the
  Parent Category chain goes); an attribute marked Not Applicable at a closer
  level is dropped entirely. New codeunit 50105
  `ATT Order Attr. Setting Mgt.` with public procedure `GetResultingSetting`.
- CU-123x5y65qpa: A default value entered on an order attribute setting row is
  now validated against the item attribute's type (Option, Decimal, Integer,
  Date, Text) and rejected if it does not match an existing option value or
  does not parse as that type; new field `ATT Default Value` on the mapping
  row. New enum 50101 `ATT Override Option` for the tri-state (blank/Yes/No)
  print-setting overrides.
- CU-123x5y65qpa: This feature is master data only; nothing yet creates or
  refreshes line attributes on a sales line from the resulting setting — that
  is a separate, follow-up task.
- CU-123x5y65hfj: Two new fields on Item Attribute: Show on Customer Documents
  and Show on Production Documents (nl-BE: Tonen op klantdocumenten, Tonen op
  productiedocumenten). New item attributes get Yes for both. The fields can be
  edited on the Item Attributes list and the Item Attribute card. No report or
  document layout uses them yet. See
  [docs/features/CU-123x5y65hfj-item-attribute-print-settings.md](docs/features/CU-123x5y65hfj-item-attribute-print-settings.md).
- CU-123x5y65hfj: On install and upgrade, both fields are set to Yes on all item
  attributes that already exist. This runs once per company (upgrade tag
  `ATT-CU-123x5y65hfj-ItemAttrPrintSettings-20261019`); attributes you set to No
  afterwards are not reset by later upgrades. If you uninstall the app without
  clearing its data and reinstall it, item attributes created in the meantime
  read No for both fields and are not fixed automatically; set them manually.
- CU-123x5y65hfj: Internal codeunits 50102 `ATT Install`, 50103 `ATT Upgrade`
  and 50104 `ATT Upgrade Mgt.`, added to permission set `ATT CUSTOM`. The test
  app `Customer Extensions Test` is added to `internalsVisibleTo` in `app.json`
  (compiler warning PTE0012, accepted).
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

- CU-123x5y65hfj: Validating Attribute ID on a document line attribute now copies
  Show on Customer Documents and Show on Production Documents from the Item
  Attribute; Attribute ID 0 sets both to No. The values are a snapshot: later
  changes on the Item Attribute do not change existing line attributes, and
  archiving, posting and `CopyAttributes` keep the line's own values. Validating
  the same Attribute ID again keeps the copied values. Code that creates line
  attributes must use `Validate("Attribute ID", Value)`; after a direct
  assignment, `Validate("Attribute ID")` copies nothing and both fields stay No.
- CU-123x5y65gje: `DeleteAll` on Sales Line, Sales Line Archive, Sales Shipment
  Line, Sales Invoice Line, Sales Cr.Memo Line and Return Receipt Line now runs
  row by row because of the new delete subscribers. Bulk deletes on these tables
  are slower.

### Removed

- CU-123x5y65gje: The HelloWorld template objects (pageextension 50100 and test
  codeunit 50150) are removed. Object IDs 50100 and 50150 are now used by the
  new table/enum/codeunit/permission set and by the test codeunit
  `ATT Doc. Line Attr. Unit Test`.
