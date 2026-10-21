# CU-123x5y65qpa: Instelling orderkenmerken per artikelcategorie of artikel (Order attribute settings per item category or item)

- ClickUp: https://app.clickup.com/t/123x5y65qpa
- Type: Feature
- Estimate: 4 h
- Branch: `feature/CU-123x5y65qpa-Instelling-orderkenmerken-per-artikelcategorie-of-artikel`
- Develop in AL. Translations nl-BE and en-US via XLIFF.

## Business need

As an administrator at Kreamat, I want to configure myself which additional
attributes (kenmerken) are asked per product family or item on the sales line,
and which of those are mandatory, so that I can roll out new families or
changes without development work.

### Scope (from the task)

- New table and page "Orderkenmerken – instelling" (Order attribute settings):
  Soort (Type), Code, Kenmerk (Attribute), Volgorde (Sequence), Verplicht
  (Mandatory), Standaardwaarde (Default value), Niet van toepassing (Not
  applicable), Tonen op klantdocumenten (Show on Customer Documents), Tonen op
  productiedocumenten (Show on Production Documents).
- Inheritance via Parent Category (Bovenliggende categorie); the most specific
  level wins (item > category > parent category).
- Action "Orderkenmerken" on the item category card and the item card.
- Action "Resulterende instelling tonen" (Show resulting setting) on the item
  card.

## Acceptance criteria

1. **AC1 – Category inheritance.** Given Hardheid is set as a mandatory order
   attribute on category MATRAS, and item M00001 has category N18 with parent
   category MATRAS, when the administrator opens "Resulterende instelling
   tonen" for M00001, then Hardheid appears in the list as mandatory, with
   level "Item category MATRAS".
2. **AC2 – Most specific level wins.** Given Hardheid is not mandatory on
   MATRAS, and Hardheid is mandatory on item M00001, when the resulting
   setting for M00001 is determined, then Hardheid is mandatory.
3. **AC3 – Not applicable.** Given Hardheid is set on MATRAS, and on TOPPER
   Hardheid has Not applicable = Yes, when the resulting setting for an item
   in TOPPER is determined, then Hardheid does not appear.
4. **AC4 – Invalid default value.** Given attribute Hardheid of type Option,
   when the administrator enters "Super" as the default value (not an
   existing value), then they get an error and the value is not saved.
   Extended per Open Question 3: the same kind of validation applies to every
   Item Attribute type — a Decimal/Integer default value that does not parse
   as a number, and a Date/Time default value that does not parse as a
   date/time, are rejected the same way; Text accepts any value.
5. **AC5 – No retroactive effect.** Given an open order with a line for
   M00001 without Productienotitie, when Productienotitie is added to the
   setting of MATRAS, then the existing line stays unchanged, and a new line
   for M00001 does get Productienotitie.

## Open questions

1. **Does this task create/update line attributes on the order, or only the
   master-data setting?** AC5 describes a *new sales line* for M00001 ending
   up with the Productienotitie attribute. Today nothing creates
   `ATT Document Line Attribute` records when a sales line is added — that was
   explicitly deferred to "another task" in CU-123x5y65hfj (Q1). This task's
   scope therefore seems to include: computing the resulting setting for an
   item and creating/populating the line's attributes from it when a sales
   line is inserted (and/or when the item no. is validated). That is
   substantially more than the 4 h estimate suggests (the comparable
   CU-123x5y65gje line-attribute table alone was 12 h). Please confirm whether:
   - (a) this task is master data only (the setting table, inheritance
     computation, and the two actions), and a separate task wires it into
     sales line creation — in which case AC5 would need to be re-scoped or
     tested only at the "resulting setting" level, not via an actual order
     line; or
   - (b) this task also creates/refreshes line attributes when a sales line's
     item no. is validated, matching AC5 as written — in which case the
     estimate needs to go up.

   **Answer:** (a). This task is master data only: the setting table, the
   inheritance computation, and the two actions. AC5 is tested at the
   "resulting setting" level (the computed effective setting for an item
   before and after a change to a parent category's setting), not through an
   actual sales line. Wiring the resulting setting into automatic line
   attribute creation on a sales line is a separate task.
2. **Relation to the Item Attribute print flags.** `Item Attribute` (7500)
   already has "Show on Customer Documents" / "Show on Production Documents"
   (CU-123x5y65hfj), which are snapshotted onto a line attribute when its
   Attribute ID is assigned. This new setting table has the same two fields
   per category/item. Are these:
   - an override of the Item Attribute's flags for that category/item (most
     specific level wins, like Mandatory), falling back to the Item
     Attribute's own flags if not set here; or
   - independent of the Item Attribute flags, meaning a line attribute could
     end up with two different "show" decisions depending on which layer is
     consulted?

   **Answer:** Override, most-specific wins. Same rule as Mandatory: a flag
   set at item or category level on this setting table overrides the Item
   Attribute's own flag for that item/category; if not set here, the
   resulting setting falls back to the Item Attribute's flag.
3. **Default value validation for non-Option types.** AC4 only covers
   attributes of type Option. Should Standaardwaarde also be validated against
   the attribute's type for Decimal, Integer, Date/Time and Text (e.g. a
   numeric/date format check), or is validation only required for Option type
   in this task?

   **Answer:** Validate all types. Decimal/Integer/Date/Time default values
   must parse as that type and are rejected the same way AC4 rejects an
   invalid Option value. Text accepts any value. See the extended AC4.
4. **"Soort" values.** Is Soort limited to "Item Category" and "Item", or is
   there a third kind (e.g. an explicit "Parent Category" entry distinct from
   a regular category)? And is "Code" the Item Category Code or Item No.
   depending on Soort, i.e. is the table keyed on (Soort, Code, Kenmerk) only?

   **Answer:** Soort has exactly two values: Item Category and Item. Code is
   the Item Category Code when Soort = Item Category, or the Item No. when
   Soort = Item. The table is keyed on (Soort, Code, Kenmerk).
5. **Parent category hierarchy depth.** AC1 uses one level (N18 → MATRAS). Can
   a parent category itself have a parent (multi-level inheritance), and if
   so, does the most-specific-wins rule apply across all levels, not just two?

   **Answer:** Multi-level, most-specific wins. The resulting-setting
   computation walks the full Parent Category chain as far as it goes (not
   just one level) and picks the nearest level — the item itself, then the
   closest ancestor category with an explicit entry — that has one.

## Plan

Approved 2026-10-21.

**Architecture decision.** Extend standard BC's `Item Attribute Value Mapping`
(table 7502) rather than building a new table from scratch. Standard mapping
inheritance works at the row level: the closest level (item, then its
category, then each ancestor category via Parent Category) that has an
explicit row for an attribute wins outright, with all its fields — this is
AC1/AC2. The two print-flag fields need a three-state value (blank/Yes/No) so
a row can choose not to override and fall back to `Item Attribute`'s own flag
(Open Question 2); Mandatory/Sequence/Not Applicable don't need that, they
default to No/0 when unset.

Caveat: the exact field names/numbers on `Item Attribute Value Mapping` (7502)
must be verified against the actual BC 28 symbols before coding; the names
below are provisional and should be adjusted if they differ.

### New objects (`Customer Extensions/`, IDs 50100–50149)

| Object | ID / name | Purpose |
|---|---|---|
| Enum | 50101 `ATT Override Option` | `" "` (inherit from Item Attribute), Yes, No — for the two print-flag fields |
| Table extension | 50101 `ATT Item Attribute Value Mapping` → `Item Attribute Value Mapping` (7502) | Adds Mandatory, Sequence, Not Applicable, Show on Customer/Production Documents (override) |
| Table | 50101 `ATT Resulting Order Attr. Setting` | Temporary buffer: one row per attribute in the computed resulting setting for an item (Attribute ID, Mandatory, Sequence, Default Value, resolved Show flags, Level/source text) |
| Codeunit | 50105 `ATT Order Attr. Setting Mgt.` | `GetResultingSetting(ItemNo; var TempResult)`: walks item → its category → Parent Category chain, picks the closest row per attribute, drops attributes marked Not Applicable at a more specific level, resolves the print flags against `Item Attribute` when unset, validates Default Value against the attribute's Type (AC4, extended to all types) |
| Page | 50100 `ATT Order Attribute Settings` | List on `Item Attribute Value Mapping`, filtered to one Table ID/No.; shows standard + new fields; editable |
| Page | 50101 `ATT Resulting Order Attr. Settings` | List on the temporary buffer table; read-only, shows Attribute, Mandatory, Sequence, Default Value, print flags, Level |
| Page extension | 50102 `ATT Item Category Card` → `Item Category Card` | Action "Orderkenmerken" opens page 50100 filtered to Table ID = Item Category, No. = current category |
| Page extension | 50103 `ATT Item Card` → `Item Card` | Actions "Orderkenmerken" (page 50100, Table ID = Item) and "Resulterende instelling tonen" (runs the mgt. codeunit, opens page 50101) |
| Permission set | 50100 `ATT CUSTOM` | RIMD/X added for everything above |

### Acceptance criteria coverage
- AC1/AC2 (inheritance, most-specific wins): `GetResultingSetting` walks the
  full Parent Category chain (multi-level, per Open Question 5).
- AC3 (Not Applicable): a Not Applicable=Yes row at a closer level removes the
  attribute from the result entirely.
- AC4 (invalid default value, all types): validated in the table extension's
  `OnInsert`/`OnModify` trigger when Default Value changes.
- AC5 (no retroactive effect): tested as "the resulting setting for an item
  changes immediately when a category's row changes" — there is no order line
  in this task's scope (Open Question 1), so there is nothing to leave
  unchanged beyond that.

### Tests (`Customer Extensions Test/`)
A unit-test codeunit covering AC1–AC5 against the mgt. codeunit and the new
table extension, plus the standard permission-set test codeunit extended for
the new objects.

### Out of scope (follow-ups)
- Creating/refreshing `ATT Document Line Attribute` records on a sales line
  from the resulting setting (Open Question 1) — a separate task.
