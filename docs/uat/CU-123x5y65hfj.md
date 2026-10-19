# Acceptance test: print settings on item attributes

- ClickUp: [Afdrukinstellingen op Artikelkenmerk](https://app.clickup.com/t/123x5y65hfj) (CU-123x5y65hfj)

| | |
|---|---|
| Environment / company | |
| Tester | |
| Attitutor consultant | |
| Date | |

## What changed

You can now mark for each **item attribute** (kenmerk) whether it may be shown
on documents:

- **Show on Customer Documents** (*Tonen op klantdocumenten*): whether the
  attribute may appear on documents for the customer, such as quotes, order
  confirmations and invoices. Turn it off for internal attributes, for example
  *Familie*.
- **Show on Production Documents** (*Tonen op productiedocumenten*): whether the
  attribute may appear on documents for the workshop.

Both settings are on the **Item Attributes** list and on the **Item Attribute**
card, and you can change them in both places.

- **New attributes** have both settings on.
- **Attributes that already exist** have both settings switched on once, when
  this update is installed. If you turn a setting off afterwards, later updates
  do not switch it back on.
- **The settings are frozen on the line.** When an attribute is put on a sales
  line, its two settings are stored on that line, just like its value and unit.
  If you change the settings on the item attribute later, lines that already
  have the attribute keep what they had. Archived and posted lines keep the
  settings of the line too.

### What is not in this release

- **No document uses the settings yet.** Turning a setting off does not yet
  change any printed or e-mailed document. The documents follow in a later task.
- Attributes are **not yet put on sales lines automatically** from the item, and
  there is no screen yet to see the attributes on a sales line. That also comes
  in a later task. Until then, you cannot check yourself in Business Central how
  the settings reach a sales line; Attitutor checks that for you (see tests 2
  and 3).

## Before you start

Test 4 checks what happens to attributes that already exist when the update is
installed. That can be checked only once per company, so do steps P1 to P3
**before** Attitutor installs the new version in the test environment.

| Step | Who | Action | Expected result | OK? |
|---|---|---|---|---|
| P1 | Tester | Check that you work with a user who can create and change item attributes. | | |
| P2 | Tester | Search for **Item Attributes**. | The columns **Show on Customer Documents** and **Show on Production Documents** are not there yet. | |
| P3 | Tester | Choose **New** and create two item attributes: **UAT FAMILIE** (type *Text*) and **UAT MAAT** (type *Option*, with the value *Groot*). Count how many item attributes there are in total. | Both attributes are on the list. Total number of item attributes: ______ | |
| P4 | Attitutor | Install the new version in the test environment and let the tester know. | The update is installed without errors. | |

## Tests per acceptance criterion

### 1. A new item attribute shows on all documents by default

| Step | Action | Expected result | OK? |
|---|---|---|---|
| 1.1 | Search for **Item Attributes**, choose **New** and create the item attribute **UAT NIEUW** (type *Text*). | On UAT NIEUW, **Show on Customer Documents** and **Show on Production Documents** are both on. | |

### 2. The settings are copied to the sales line

Because attributes are not yet put on sales lines (see *What is not in this
release*), you cannot do this test in Business Central yet. Attitutor shows you
the result of the automated checks, which prove that:

- an attribute with **Show on Customer Documents** off, such as *Familie*, gets
  that setting off on the sales line for item M00001, while **Show on Production
  Documents** stays on;
- the other way round works the same.

| Step | Action | Expected result | OK? |
|---|---|---|---|
| 2.1 | Attitutor shows the results of the automated checks for this update. | All checks have passed. | |

You test this yourself in Business Central in the later task that puts the
attributes on sales lines automatically.

### 3. Changing the settings later does not change existing lines

Like test 2, this cannot be done in Business Central yet. The automated checks
prove that:

- after an attribute is on a sales line, changing its settings on the item
  attribute does not change that line;
- when a line gets another attribute, it takes the settings of that other
  attribute.

| Step | Action | Expected result | OK? |
|---|---|---|---|
| 3.1 | Attitutor shows the results of the automated checks (same run as test 2). | All checks have passed. | |

### 4. Existing attributes show on all documents after the update

| Step | Action | Expected result | OK? |
|---|---|---|---|
| 4.1 | Search for **Item Attributes**. | The columns **Show on Customer Documents** and **Show on Production Documents** are there. | |
| 4.2 | Look at **UAT FAMILIE**, **UAT MAAT** and the other attributes that existed before the update. | Both settings are on for every attribute. The number of item attributes is the same as in step P3. | |
| 4.3 | Turn **Show on Customer Documents** off for **UAT FAMILIE**. | Saved. | |
| 4.4 | *Only if Attitutor installs another update during this test:* afterwards, open **Item Attributes** again. | UAT FAMILIE still has **Show on Customer Documents** off: the update did not switch it back on. | |

### 5. The settings are visible and can be changed

| Step | Action | Expected result | OK? |
|---|---|---|---|
| 5.1 | On **Item Attributes**, turn **Show on Production Documents** off for **UAT NIEUW**, directly in the list. Close the page and open it again. | You can change the setting in the list. After opening the page again, UAT NIEUW has **Show on Production Documents** off. | |
| 5.2 | Open the card of **UAT NIEUW** from the list. | Both settings are on the card, below **Blocked**. | |
| 5.3 | On the card, turn **Show on Customer Documents** off and **Show on Production Documents** on. Close the card and open it again. | You can change both settings. After opening the card again, **Show on Customer Documents** is off and **Show on Production Documents** is on. | |

### 6. Dutch and English captions

| Step | Action | Expected result | OK? |
|---|---|---|---|
| 6.1 | In **My Settings**, set the language to **Dutch (Belgium)** and search for **Artikelkenmerken**. | The columns are **Tonen op klantdocumenten** and **Tonen op productiedocumenten**. | |
| 6.2 | Point at each of the two column headers. | The explanation that appears is in Dutch. | |
| 6.3 | Open the card of **UAT NIEUW**. | The two settings have the same Dutch captions and Dutch explanations. | |
| 6.4 | Set the language to **English** and open **Item Attributes**. | The columns are **Show on Customer Documents** and **Show on Production Documents**, with English explanations. | |
| 6.5 | Set the language back to what you normally use. | | |

## Clean-up

Delete the item attributes **UAT FAMILIE**, **UAT MAAT** and **UAT NIEUW**. They
are not used on items, so you can delete them. Test 4 cannot be repeated in the
same company.

## Sign-off

| Role | Name | Date | Accepted? |
|---|---|---|---|
| Tester | | | |
| Attitutor | | | |
