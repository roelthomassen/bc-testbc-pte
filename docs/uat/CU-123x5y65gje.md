# Acceptance test: document line attributes

- ClickUp: [Tabel Documentregelkenmerk](https://app.clickup.com/t/123x5y65gje) (CU-123x5y65gje)

| | |
|---|---|
| Environment / company | |
| Tester | |
| Attitutor consultant | |
| Date | |

## What changed

Business Central can now keep **attributes** (for example size or colour) on
each individual sales document line, not only on the item. Each attribute on a
line stores:

- the attribute and its value, for example *Size = Medium*;
- the unit, for example *cm*;
- where it came from (item, variant, order or parent line);
- whether it is mandatory, its order on the line, and whether it should be shown
  on customer documents and on production documents.

The attributes follow the line through the sales process:

- **The value is frozen on the line.** When an attribute is put on a line, its
  value and unit are stored on that line. If the attribute or its value is later
  renamed or changed on the item attributes, existing lines keep what they had.
- **Archiving** a sales order copies the attributes to the archived version. Each
  archived version keeps its own attributes.
- **Posting** copies the attributes to the posted shipment, invoice, credit memo
  and return receipt lines.
- **Deleting** a line, a document or an archived version also deletes its
  attributes.

You do not need any extra permissions for this: a normal sales user can post,
archive and delete as before.

### What is not in this release

- There is **no screen yet** to enter or edit attributes on a sales line, and
  attributes are not yet filled in automatically from the item. That comes in a
  later task. For this test, Attitutor puts the attributes on the lines for you
  and gives you a link to a read-only list where you can see them.
- Attributes are **not** kept in these cases (they will be lost):
  - copying a document with **Copy Document** or **Get Shipment Lines**;
  - making an order from a quote or from a blanket order;
  - restoring a sales document from the archive;
  - changing the customer, currency or VAT business posting group on a document
    that already has lines (Business Central re-creates the lines);
  - prepayment invoices and prepayment credit memos.
- Production orders are not covered yet.

## Before you start

Attitutor prepares the following together with you.

| Step | Who | Action | Expected result | OK? |
|---|---|---|---|---|
| P1 | Tester | Check that you work with your normal sales user, without extra permissions. | | |
| P2 | Attitutor | Create three item attributes: **UAT SIZE** (unit *cm*) with the values *Medium* and *Large*, **UAT COLOUR** (no unit) with the value *Red*, and **UAT FINISH** (no unit) with the value *Matt*. | All three appear on the **Item Attributes** page. | |
| P3 | Tester | Choose an item that you can sell (with stock, or negative stock allowed) and an existing customer. Create these documents, each with one line for that item, unless stated otherwise: | Numbers noted below. | |
| | | – sales order **A** | A: ______ | |
| | | – sales order **B** with **two** lines | B: ______ | |
| | | – sales order **C** | C: ______ | |
| | | – sales credit memo **E** | E: ______ | |
| | | – sales return order **F** | F: ______ | |
| P4 | Attitutor | Put two attributes on every line of A, B, C, E and F: UAT SIZE = *Medium* (first, mandatory, shown on customer documents, source *Item*) and UAT COLOUR = *Red* (second, source *Item*). | | |
| P5 | Attitutor | Give the tester the link to the **Document Line Attribute** list. | The tester can open the list. | |

**How to check the attributes:** open the **Document Line Attribute** list with
the link, open the filter pane and filter **Document No.** on the number you want
to check. Each row is one attribute on one line. The columns you need are
**Line No.**, **Version No.** (only filled for archived versions), **Value**,
**Unit of Measure**, **Source**, **Mandatory**, **Sequence** and **Show on
Customer Documents**.

## Tests per acceptance criterion

### 1. A changed attribute value does not change existing lines

| Step | Action | Expected result | OK? |
|---|---|---|---|
| 1.1 | Open the list and filter on order **A**. | Two rows: *Medium* with unit *cm*, Source *Item*, Mandatory and Show on Customer Documents on, Sequence 1; and *Red* with no unit, Sequence 2. | |
| 1.2 | Search for **Item Attributes**, open **UAT SIZE**, choose **Values** and change *Medium* into *Mid*. | Saved. | |
| 1.3 | Open the list again and filter on order **A**. | The value is still **Medium**. | |

### 2. Value and unit are stored when the attribute is put on a line

| Step | Action | Expected result | OK? |
|---|---|---|---|
| 2.1 | On **Item Attributes**, change the unit of **UAT SIZE** from *cm* to *mm*. | Saved. | |
| 2.2 | Open the list and filter on order **A**. | The unit is still **cm**. | |
| 2.3 | Change the value back to *Medium* and the unit back to *cm*. | Saved. | |
| 2.4 | Attitutor shows putting UAT COLOUR on a line with the value *Medium* (a value of UAT SIZE). | An error says that this value does not belong to this attribute. Nothing is saved. | |

### 3. Copying attributes from one line to another

There is no action for this in Business Central yet: it is a building block for
later tasks. Attitutor checks it with automated tests. You see the result of the
copy in tests 10 and 11 (archiving and posting).

### 4. Each archived version keeps its own attributes

| Step | Action | Expected result | OK? |
|---|---|---|---|
| 4.1 | Open order **C** and choose **Archive Document**. | The order is archived. | |
| 4.2 | Archive order **C** a second time. | A second version is archived. | |
| 4.3 | Open the list and filter on order **C**. | Six rows: two with no Version No. (the order itself), two with Version No. **1** and two with Version No. **2**. | |

### 5. Removing all attributes of a line

Like test 3, this is a building block without its own action. Attitutor checks it
with automated tests. You see the result in test 9 (deleting).

### 6. Attributes can be kept on all sales line types

| Step | Action | Expected result | OK? |
|---|---|---|---|
| 6.1 | Check the results of tests 4, 10 and 11. | Attributes are visible for order lines, archived order lines, posted shipment lines, posted invoice lines, posted credit memo lines and posted return receipt lines. | |
| 6.2 | Attitutor shows putting an attribute on another kind of record, for example a sales header. | An error says that document line attributes cannot be stored for that record. | |

### 7. Order lines and posted lines are kept apart

| Step | Action | Expected result | OK? |
|---|---|---|---|
| 7.1 | In the list, look at the **Document Type** column for order **C** and for the posted invoice of test 11. | Order and archived order lines show **1** (= order). Posted lines show **0**. | |

### 8. A new attribute has no source until it is set

| Step | Action | Expected result | OK? |
|---|---|---|---|
| 8.1 | Attitutor puts UAT FINISH = *Matt* on the first line of order **B**, without filling in the source. | | |
| 8.2 | Open the list and filter on order **B**. | Five rows. The row with *Matt* has an empty **Source**. | |

### 9. Deleting a line, a document or an archived version deletes its attributes

| Step | Action | Expected result | OK? |
|---|---|---|---|
| 9.1 | Open order **B** and delete the first line. | The line is deleted. | |
| 9.2 | Open the list and filter on order **B**. | Only the two rows of the second line are left. | |
| 9.3 | Delete order **B**. | The order is deleted. | |
| 9.4 | Filter on order **B** again. | No rows. | |
| 9.5 | Search for **Sales Order Archives** and delete version 1 of order **C**. | The version is deleted. | |
| 9.6 | Filter on order **C**. | No rows with Version No. 1. The rows of version 2 and of the order itself are still there. | |

### 10. Archiving copies the attributes

| Step | Action | Expected result | OK? |
|---|---|---|---|
| 10.1 | Filter on order **C** (after test 4). | The archived rows have the same Value, Unit of Measure, Source, Mandatory, Sequence and Show on Customer Documents as the rows of the order itself. | |
| 10.2 | Compare version 1 and version 2. | Archiving the second time did not change version 1. | |
| 10.3 | Check that the rows of the order itself are still there. | Archiving does not remove the attributes from the order. | |

If **Archive Orders** is on in **Sales & Receivables Setup**, posting order A in
test 11 also archives it automatically. The archived version of order A then has
the same attributes as well.

### 11. Posting copies the attributes

| Step | Action | Expected result | OK? |
|---|---|---|---|
| 11.1 | Open order **A** and choose **Post**, **Ship and Invoice**. | The order is posted. Shipment no.: ______ Invoice no.: ______ | |
| 11.2 | Filter the list on the **posted shipment** number. | Two rows, with the same values and settings as order A in test 1.1. | |
| 11.3 | Filter on the **posted invoice** number. | Two rows, the same as above. | |
| 11.4 | Filter on order **A**. | No rows for the order itself: it is fully posted and no longer exists. (Rows with a Version No. are archived versions, see test 10.) | |
| 11.5 | Post credit memo **E**. If your setup requires it, first apply it to the invoice of step 11.1. | Posted. Posted credit memo no.: ______ | |
| 11.6 | Filter on the **posted credit memo** number. | Two rows, with the same values and settings as on credit memo E. | |
| 11.7 | Open return order **F** and choose **Post**, **Receive**. | Posted. Return receipt no.: ______ | |
| 11.8 | Filter on the **return receipt** number. | Two rows, with the same values and settings as on return order F. | |

### 12. Dutch and English captions

| Step | Action | Expected result | OK? |
|---|---|---|---|
| 12.1 | In **My Settings**, set the language to **Dutch (Belgium)** and open the list. | The list is called **Documentregelkenmerk**; the columns are in Dutch, for example *Documentnr.*, *Regelnr.*, *Waarde*, *Eenheid*, *Bron*, *Verplicht*, *Volgorde*. | |
| 12.2 | Set the language to **English** and open the list. | The list and columns are in English. | |
| 12.3 | Set the language back to what you normally use. | | |

## Clean-up

The documents posted in this test stay in the company. Run the test in a test
environment if they must not end up in your live company. Attitutor removes the
test attributes UAT SIZE, UAT COLOUR and UAT FINISH afterwards, if you want.

## Sign-off

| Role | Name | Date | Accepted? |
|---|---|---|---|
| Tester | | | |
| Attitutor | | | |
