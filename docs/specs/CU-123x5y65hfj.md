# CU-123x5y65hfj: Afdrukinstellingen op Artikelkenmerk (Print settings on Item Attribute)

- ClickUp: https://app.clickup.com/t/123x5y65hfj
- Type: Feature
- Estimate: 2 h
- Branch: `feature/CU-123x5y65hfj-Afdrukinstellingen-op-Artikelkenmerk`
- Develop in AL. Translations nl-BE and en-US via XLIFF.

## Business need

As an administrator at Kreamat, I want to mark per item attribute (kenmerk)
whether it is shown on customer documents and on production documents. Internal
attributes (for example Familie) must not reach the customer, and the workshop
must get all the information it needs.

### Scope (from the task)

- Table extension on Item Attribute (7500) with two fields:
  - Show on Customer Documents (Tonen op klantdocumenten), default Yes
  - Show on Production Documents (Tonen op productiedocumenten), default Yes
- Both fields visible on the Item Attributes page (Artikelkenmerken).

## Acceptance criteria

1. **Default value (AC1).** Given a new item attribute, when the administrator
   creates it, then Show on Customer Documents and Show on Production Documents
   are both Yes.
2. **Inherited on the line (AC2).** Given item attribute Familie with Show on
   Customer Documents = No, when Attribute ID Familie is assigned to a line
   attribute (`ATT Document Line Attribute`) of a sales line for item M00001,
   then that line attribute has Show on Customer Documents = No (and Show on
   Production Documents follows the Item Attribute in the same way). Creating
   the line attributes automatically when the sales line is created belongs to
   another task, which tests AC2 end-to-end. *(Q1)*
3. **Snapshot.** Given a line attribute that already has the flags copied, when
   the flags on the Item Attribute are changed, then the line attribute keeps its
   original values. *(Q2)*
4. **Existing attributes on upgrade.** Given Item Attribute records that exist
   before this version is installed, when the app is upgraded, then both fields
   are Yes on all of them. The upgrade runs only once (upgrade tag). *(Q3)*
5. **Visible on the page.** Both fields are visible and editable on the Item
   Attributes page.
6. **Translations.** All captions and tooltips are available in en-US and nl-BE
   through XLIFF.

## Open questions

1. **Who creates the line attributes in AC2?** Today no code creates
   `ATT Document Line Attribute` records when a sales line is created or the item
   no. is validated; CU-123x5y65gje only stores, copies and deletes them. AC2
   needs that. Options:
   - (a) This task also creates the line attributes from the item's attributes
     (`Item Attribute Value Mapping`) when a sales line's No. is validated, and
     copies both flags from the Item Attribute. Bigger than the 2 h estimate.
   - (b) Another task creates the line attributes. This task only provides the
     flags on Item Attribute plus a helper that copies them onto a line
     attribute (e.g. in `Attribute ID` OnValidate); AC2 is tested at that level
     and fully end-to-end in the other task.

   **Answer:** (b). This task adds the flags on Item Attribute and copies them
   onto the line attribute when its Attribute ID is assigned. Creating the line
   attributes from the item's attributes is another task.
2. **Snapshot or live?** Like Value and Unit of Measure, the flags are copied to
   the line attribute at assignment, and later changes on the Item Attribute do
   not change existing lines. Confirm.

   **Answer:** Yes, snapshot.
3. **Existing attributes.** The default Yes is set through `InitValue` for new
   attributes. Existing Item Attribute records in LIVE will read No for the new
   fields unless an upgrade codeunit sets them to Yes. Should existing attributes
   be set to Yes on upgrade (and install)?

   **Answer:** Yes. An upgrade codeunit with an upgrade tag sets both fields to
   Yes on all existing Item Attribute records.
4. **Variant and other sources.** If line attributes also come from variants or
   the order (Source = Variant/Order/Parent Line), do they take the flags from
   the same Item Attribute? (Assumption: yes, the flags always come from the
   Item Attribute.)

   **Answer:** Not answered yet. Working assumption: yes. The copy happens
   when Attribute ID is assigned, whatever the Source.
5. **Manual changes on the line.** May a user change the flags on a single line
   attribute (and does that set Manually Modified)? There is no line UI yet.

   **Answer:** Not answered yet. Not relevant to this task because there is no
   line UI. It is decided in the task that adds the line page.

## Plan

Approved 2026-10-19.

### Main app (`Customer Extensions/`, IDs 50100–50149)
| Object | ID / name | Purpose |
|---|---|---|
| Table extension | 50100 `ATT Item Attribute` → `Item Attribute` (7500) | Two new fields |
| Page extension | 50100 `ATT Item Attributes` → `Item Attributes` (7500) | Shows both fields |
| Page extension | 50101 `ATT Item Attribute Card` → `Item Attribute` (7503) | Shows both fields, editable |
| Table (change) | 50100 `ATT Document Line Attribute` | `Attribute ID` OnValidate copies both flags from the Item Attribute |
| Codeunit | 50102 `ATT Install` (Subtype Install) | `OnInstallAppPerCompany` runs the set-to-Yes routine |
| Codeunit | 50103 `ATT Upgrade` (Subtype Upgrade) | `OnUpgradePerCompany` runs the set-to-Yes routine |
| Codeunit | 50104 `ATT Upgrade Mgt.` | Set-to-Yes routine, upgrade tag `ATT-CU-123x5y65hfj-ItemAttrPrintSettings-20261019`, registered via `OnGetPerCompanyUpgradeTags` |
| Permission set | 50100 `ATT CUSTOM` | X on the new codeunits |
| XLIFF | en-US / nl-BE | Captions and tooltips |

**Fields on Item Attribute**
- 50100 `ATT Show on Customer Docs` Boolean, `InitValue = true`, caption
  'Show on Customer Documents' (nl-BE 'Tonen op klantdocumenten').
- 50101 `ATT Show on Production Docs` Boolean, `InitValue = true`, caption
  'Show on Production Documents' (nl-BE 'Tonen op productiedocumenten').
- DataClassification CustomerContent. (Names shortened because of the
  30-character limit.)

**Behaviour**
- When Attribute ID is validated on a line attribute to a new value, both flags
  are copied from the Item Attribute. Attribute ID 0 sets both flags to No.
- Archive, posting and `CopyAttributes` copy records without validating
  Attribute ID, so they keep the line's own values (snapshot, AC3).
- Set-to-Yes routine: exits if the upgrade tag exists; otherwise `ModifyAll`
  both fields to Yes on every Item Attribute, then sets the tag. Runs on install
  and on upgrade.

### Tests (`Customer Extensions Test/`, IDs 50150–50179)
- Codeunit 50155 `ATT Item Attr. Print Test`:
  - AC1: a new Item Attribute has both fields Yes.
  - AC2: item M00001 with attribute Familie (Customer No, Production Yes):
    validating Attribute ID on a line attribute of a sales line gives Customer
    No and Production Yes. A second case checks the reverse values.
  - AC3: changing the Item Attribute afterwards leaves the line unchanged;
    re-validating to another Attribute ID takes the new attribute's flags.
  - AC4: the routine sets existing attributes from No to Yes and sets the tag;
    a second run with the tag present does not change data.
  - AC5: TestPage checks that both fields are visible on the list and the card,
    and editable on the card.
- AC6 is checked by the XLIFF content.
- Codeunit 50153 (permission definition test) is extended with the new
  codeunits.

### Out of scope
- Creating line attributes automatically when a sales line is created (another
  task).
- Line UI.
