namespace Attitutor.CustomerExtensions.Test.ItemAttribute;

using Attitutor.CustomerExtensions.DocumentLineAttribute;
using Attitutor.CustomerExtensions.Test.TestLibrary;
using Attitutor.CustomerExtensions.Upgrade;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Attribute;
using Microsoft.Sales.Document;
using System.TestLibraries.Utilities;
using System.Upgrade;

/// <summary>
/// Tests for the print settings on item attributes: the defaults, the copy to document line attributes, the upgrade of
/// existing item attributes and the fields on the Item Attributes pages (CU-123x5y65hfj, acceptance criteria 1-5).
/// </summary>
/// <remarks>
/// Run with test runner 130450 "Test Runner - Isol. Codeunit" (codeunit-level isolation) in a dedicated test company:
/// the tests and their Initialize change setup, item attributes, sales documents and upgrade tags that must be rolled back when the codeunit ends.
/// </remarks>
codeunit 50155 "ATT Item Attr. Print Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // [FEATURE] [Item Attribute] [Document Line Attribute]

    var
        Assert: Codeunit "Library Assert";
        ATTTestLibrary: Codeunit "ATT Test Library";
        UpgradeMgt: Codeunit "ATT Upgrade Mgt.";
        IsInitialized: Boolean;
        FamilieValueTxt: Label 'Familie A', Locked = true;
        TestUpgradeTagTxt: Label 'ATT-TEST-%1', Locked = true, Comment = '%1 = unique code';
        UpgradeTagSetMsg: Label 'The upgrade tag must be set after the routine has run.';
        UpgradeTagRegisteredMsg: Label 'The upgrade tag must be registered for new companies.';
        FieldVisibleMsg: Label 'Field %1 must be visible on page %2.', Comment = '%1 = field caption, %2 = page caption';
        FieldEditableMsg: Label 'Field %1 must be editable on page %2.', Comment = '%1 = field caption, %2 = page caption';

    // AC1 - default value

    [Test]
    procedure NewItemAttribute_ShowOnCustomerDocsIsYes()
    var
        ItemAttribute: Record "Item Attribute";
    begin
        // [SCENARIO AC1] A new item attribute is shown on customer documents.
        Initialize();

        // [GIVEN] No item attribute
        // [WHEN] An item attribute is created
        ATTTestLibrary.CreateItemAttribute(ItemAttribute, '');

        // [THEN] Show on Customer Documents is Yes
        ItemAttribute.Get(ItemAttribute.ID);
        Assert.IsTrue(ItemAttribute."ATT Show on Customer Docs", ItemAttribute.FieldCaption("ATT Show on Customer Docs"));
    end;

    [Test]
    procedure NewItemAttribute_ShowOnProductionDocsIsYes()
    var
        ItemAttribute: Record "Item Attribute";
    begin
        // [SCENARIO AC1] A new item attribute is shown on production documents.
        Initialize();

        // [GIVEN] No item attribute
        // [WHEN] An item attribute is created
        ATTTestLibrary.CreateItemAttribute(ItemAttribute, '');

        // [THEN] Show on Production Documents is Yes
        ItemAttribute.Get(ItemAttribute.ID);
        Assert.IsTrue(ItemAttribute."ATT Show on Production Docs", ItemAttribute.FieldCaption("ATT Show on Production Docs"));
    end;

    // AC2 - inherited on the line

    [Test]
    procedure ValidateAttributeIdHiddenForCustomer_CopiesPrintSettings()
    var
        ItemAttribute: Record "Item Attribute";
        SalesLine: Record "Sales Line";
        DocLineAttribute: Record "ATT Document Line Attribute";
    begin
        // [SCENARIO AC2] Assigning an attribute that is hidden for the customer gives a line attribute that is hidden for the customer.
        Initialize();

        // [GIVEN] Item attribute "Familie" with Show on Customer Documents = No and Show on Production Documents = Yes
        CreateItemAttributeWithPrintSettings(ItemAttribute, false, true);
        // [GIVEN] A sales line for an item with attribute "Familie"
        CreateSalesLineForItemWithAttribute(SalesLine, ItemAttribute);

        // [WHEN] Attribute ID "Familie" is assigned to a line attribute of the sales line
        InitSalesLineAttribute(DocLineAttribute, SalesLine);
        DocLineAttribute.Validate("Attribute ID", ItemAttribute.ID);

        // [THEN] The line attribute has Show on Customer Documents = No and Show on Production Documents = Yes
        AssertLineAttributePrintSettings(DocLineAttribute, false, true);
    end;

    [Test]
    procedure ValidateAttributeIdHiddenForProduction_CopiesPrintSettings()
    var
        ItemAttribute: Record "Item Attribute";
        SalesLine: Record "Sales Line";
        DocLineAttribute: Record "ATT Document Line Attribute";
    begin
        // [SCENARIO AC2] Assigning an attribute that is hidden for production gives a line attribute that is hidden for production.
        Initialize();

        // [GIVEN] An item attribute with Show on Customer Documents = Yes and Show on Production Documents = No
        CreateItemAttributeWithPrintSettings(ItemAttribute, true, false);
        // [GIVEN] A sales line for an item with this attribute
        CreateSalesLineForItemWithAttribute(SalesLine, ItemAttribute);

        // [WHEN] The attribute is assigned to a line attribute of the sales line
        InitSalesLineAttribute(DocLineAttribute, SalesLine);
        DocLineAttribute.Validate("Attribute ID", ItemAttribute.ID);

        // [THEN] The line attribute has Show on Customer Documents = Yes and Show on Production Documents = No
        AssertLineAttributePrintSettings(DocLineAttribute, true, false);
    end;

    [Test]
    procedure ValidateAttributeIdZero_ClearsPrintSettings()
    var
        ItemAttribute: Record "Item Attribute";
        SalesLine: Record "Sales Line";
        DocLineAttribute: Record "ATT Document Line Attribute";
    begin
        // [SCENARIO AC2] Clearing Attribute ID sets both print settings of the line attribute to No.
        Initialize();

        // [GIVEN] A line attribute for an item attribute that is shown on all documents
        CreateItemAttributeWithPrintSettings(ItemAttribute, true, true);
        CreateSalesLineForItemWithAttribute(SalesLine, ItemAttribute);
        InitSalesLineAttribute(DocLineAttribute, SalesLine);
        DocLineAttribute.Validate("Attribute ID", ItemAttribute.ID);

        // [WHEN] Attribute ID is validated to 0
        DocLineAttribute.Validate("Attribute ID", 0);

        // [THEN] Show on Customer Documents and Show on Production Documents are No
        AssertLineAttributePrintSettings(DocLineAttribute, false, false);
    end;

    [Test]
    procedure ValidateNonExistingAttributeId_ThrowsError()
    var
        ItemAttribute: Record "Item Attribute";
        DocLineAttribute: Record "ATT Document Line Attribute";
        NonExistingAttributeId: Integer;
    begin
        // [SCENARIO AC2] An Attribute ID that does not exist is rejected, so no print settings can be copied from it.
        Initialize();

        // [GIVEN] An Attribute ID that no item attribute has
        ItemAttribute.SetLoadFields(ID);
        if ItemAttribute.FindLast() then
            NonExistingAttributeId := ItemAttribute.ID + 1
        else
            NonExistingAttributeId := 1;

        // [WHEN] The Attribute ID is validated on a line attribute
        asserterror DocLineAttribute.Validate("Attribute ID", NonExistingAttributeId);

        // [THEN] An error says the item attribute cannot be found
        Assert.AssertPrimRecordNotFound();
    end;

    // AC3 - snapshot

    [Test]
    procedure ChangeItemAttributePrintSettings_LineAttributeKeepsCopiedValues()
    var
        ItemAttribute: Record "Item Attribute";
        SalesLine: Record "Sales Line";
        DocLineAttribute: Record "ATT Document Line Attribute";
    begin
        // [SCENARIO AC3] Changing the print settings of an item attribute does not change line attributes that already have them.
        Initialize();

        // [GIVEN] A stored line attribute with Show on Customer Documents = No and Show on Production Documents = Yes, copied from its item attribute
        CreateItemAttributeWithPrintSettings(ItemAttribute, false, true);
        CreateSalesLineForItemWithAttribute(SalesLine, ItemAttribute);
        InitSalesLineAttribute(DocLineAttribute, SalesLine);
        DocLineAttribute.Validate("Attribute ID", ItemAttribute.ID);
        DocLineAttribute.Insert(true);

        // [WHEN] The print settings of the item attribute are swapped
        ItemAttribute.Validate("ATT Show on Customer Docs", true);
        ItemAttribute.Validate("ATT Show on Production Docs", false);
        ItemAttribute.Modify(true);

        // [THEN] The line attribute still has Show on Customer Documents = No and Show on Production Documents = Yes
        DocLineAttribute.Find();
        AssertLineAttributePrintSettings(DocLineAttribute, false, true);
    end;

    [Test]
    procedure ValidateOtherAttributeId_TakesPrintSettingsOfNewAttribute()
    var
        ItemAttribute: Record "Item Attribute";
        OtherItemAttribute: Record "Item Attribute";
        SalesLine: Record "Sales Line";
        DocLineAttribute: Record "ATT Document Line Attribute";
    begin
        // [SCENARIO AC3] Changing Attribute ID on a line attribute copies the print settings of the new item attribute.
        Initialize();

        // [GIVEN] A line attribute for an item attribute with Show on Customer Documents = No and Show on Production Documents = Yes
        CreateItemAttributeWithPrintSettings(ItemAttribute, false, true);
        CreateSalesLineForItemWithAttribute(SalesLine, ItemAttribute);
        InitSalesLineAttribute(DocLineAttribute, SalesLine);
        DocLineAttribute.Validate("Attribute ID", ItemAttribute.ID);
        // [GIVEN] Another item attribute with Show on Customer Documents = Yes and Show on Production Documents = No
        CreateItemAttributeWithPrintSettings(OtherItemAttribute, true, false);

        // [WHEN] Attribute ID is changed to the other item attribute
        DocLineAttribute.Validate("Attribute ID", OtherItemAttribute.ID);

        // [THEN] The line attribute has Show on Customer Documents = Yes and Show on Production Documents = No
        AssertLineAttributePrintSettings(DocLineAttribute, true, false);
    end;

    [Test]
    procedure RevalidateSameAttributeId_KeepsCopiedPrintSettings()
    var
        ItemAttribute: Record "Item Attribute";
        SalesLine: Record "Sales Line";
        DocLineAttribute: Record "ATT Document Line Attribute";
    begin
        // [SCENARIO AC3] Validating the same Attribute ID again does not copy the print settings again (snapshot).
        Initialize();

        // [GIVEN] A line attribute with Show on Customer Documents = No and Show on Production Documents = Yes, copied from its item attribute
        CreateItemAttributeWithPrintSettings(ItemAttribute, false, true);
        CreateSalesLineForItemWithAttribute(SalesLine, ItemAttribute);
        InitSalesLineAttribute(DocLineAttribute, SalesLine);
        DocLineAttribute.Validate("Attribute ID", ItemAttribute.ID);
        // [GIVEN] The print settings of the item attribute are swapped afterwards
        ItemAttribute.Validate("ATT Show on Customer Docs", true);
        ItemAttribute.Validate("ATT Show on Production Docs", false);
        ItemAttribute.Modify(true);

        // [WHEN] The same Attribute ID is validated again
        DocLineAttribute.Validate("Attribute ID", ItemAttribute.ID);

        // [THEN] The line attribute still has Show on Customer Documents = No and Show on Production Documents = Yes
        AssertLineAttributePrintSettings(DocLineAttribute, false, true);
    end;

    // AC4 - existing attributes on upgrade

    [Test]
    procedure SetPrintSettingsToYesOnce_SetsExistingAttributesToYes()
    var
        ItemAttribute: Record "Item Attribute";
    begin
        // [SCENARIO AC4] The upgrade routine sets both print settings to Yes on item attributes that have No.
        Initialize();

        // [GIVEN] An existing item attribute with Show on Customer Documents = No and Show on Production Documents = No
        CreateItemAttributeWithPrintSettings(ItemAttribute, false, false);

        // [WHEN] The upgrade routine runs and its upgrade tag does not exist yet
        UpgradeMgt.SetItemAttrPrintSettingsToYesOnce(CreateTestUpgradeTag());

        // [THEN] The item attribute has Show on Customer Documents = Yes and Show on Production Documents = Yes
        ItemAttribute.Get(ItemAttribute.ID);
        AssertItemAttributePrintSettings(ItemAttribute, true, true);
    end;

    [Test]
    procedure SetPrintSettingsToYesOnce_SetsUpgradeTag()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        TestUpgradeTag: Code[250];
    begin
        // [SCENARIO AC4] The upgrade routine sets its upgrade tag, so it runs only once.
        Initialize();

        // [GIVEN] An upgrade tag that does not exist yet
        TestUpgradeTag := CreateTestUpgradeTag();

        // [WHEN] The upgrade routine runs
        UpgradeMgt.SetItemAttrPrintSettingsToYesOnce(TestUpgradeTag);

        // [THEN] The upgrade tag exists
        Assert.IsTrue(UpgradeTag.HasUpgradeTag(TestUpgradeTag), UpgradeTagSetMsg);
    end;

    [Test]
    procedure SetPrintSettingsToYesOnceWithExistingTag_ChangesNothing()
    var
        ItemAttribute: Record "Item Attribute";
        TestUpgradeTag: Code[250];
    begin
        // [SCENARIO AC4] The upgrade routine does not change data when its upgrade tag already exists.
        Initialize();

        // [GIVEN] The upgrade routine has run once, so its upgrade tag exists
        TestUpgradeTag := CreateTestUpgradeTag();
        UpgradeMgt.SetItemAttrPrintSettingsToYesOnce(TestUpgradeTag);
        // [GIVEN] An item attribute with Show on Customer Documents = No and Show on Production Documents = No
        CreateItemAttributeWithPrintSettings(ItemAttribute, false, false);

        // [WHEN] The upgrade routine runs again
        UpgradeMgt.SetItemAttrPrintSettingsToYesOnce(TestUpgradeTag);

        // [THEN] The item attribute still has Show on Customer Documents = No and Show on Production Documents = No
        ItemAttribute.Get(ItemAttribute.ID);
        AssertItemAttributePrintSettings(ItemAttribute, false, false);
    end;

    [Test]
    procedure ItemAttrPrintSettingsUpgradeTag_IsRegisteredPerCompany()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        PerCompanyUpgradeTags: List of [Code[250]];
    begin
        // [SCENARIO AC4] The upgrade tag is registered, so new companies get it and the routine does not run for them.
        Initialize();

        // [GIVEN] The Customer Extensions app is installed
        // [WHEN] The per-company upgrade tags are collected
        UpgradeTag.GetPerCompanyUpgradeTags(PerCompanyUpgradeTags);

        // [THEN] They contain the upgrade tag of the print settings routine
        Assert.IsTrue(PerCompanyUpgradeTags.Contains(UpgradeMgt.GetItemAttrPrintSettingsUpgradeTag()), UpgradeTagRegisteredMsg);
    end;

    // AC5 - visible on the page

    [Test]
    procedure ItemAttributesList_ShowsEditablePrintSettings()
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttributes: TestPage "Item Attributes";
    begin
        // [SCENARIO AC5] Both print settings are visible and editable on the Item Attributes list.
        Initialize();

        // [GIVEN] An item attribute
        ATTTestLibrary.CreateItemAttribute(ItemAttribute, '');

        // [WHEN] The Item Attributes list is opened for editing on the item attribute
        ItemAttributes.OpenEdit();
        ItemAttributes.GoToRecord(ItemAttribute);

        // [THEN] Show on Customer Documents and Show on Production Documents are visible and editable
        Assert.IsTrue(
            ItemAttributes."ATT Show on Customer Docs".Visible(),
            StrSubstNo(FieldVisibleMsg, ItemAttribute.FieldCaption("ATT Show on Customer Docs"), ItemAttributes.Caption()));
        Assert.IsTrue(
            ItemAttributes."ATT Show on Customer Docs".Editable(),
            StrSubstNo(FieldEditableMsg, ItemAttribute.FieldCaption("ATT Show on Customer Docs"), ItemAttributes.Caption()));
        Assert.IsTrue(
            ItemAttributes."ATT Show on Production Docs".Visible(),
            StrSubstNo(FieldVisibleMsg, ItemAttribute.FieldCaption("ATT Show on Production Docs"), ItemAttributes.Caption()));
        Assert.IsTrue(
            ItemAttributes."ATT Show on Production Docs".Editable(),
            StrSubstNo(FieldEditableMsg, ItemAttribute.FieldCaption("ATT Show on Production Docs"), ItemAttributes.Caption()));
        ItemAttributes.Close();
    end;

    [Test]
    procedure ItemAttributeCard_ShowsEditablePrintSettings()
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttributeCard: TestPage "Item Attribute";
    begin
        // [SCENARIO AC5] Both print settings are visible and editable on the Item Attribute card.
        Initialize();

        // [GIVEN] An item attribute
        ATTTestLibrary.CreateItemAttribute(ItemAttribute, '');

        // [WHEN] The Item Attribute card is opened for editing on the item attribute
        ItemAttributeCard.OpenEdit();
        ItemAttributeCard.GoToRecord(ItemAttribute);

        // [THEN] Show on Customer Documents and Show on Production Documents are visible and editable
        Assert.IsTrue(
            ItemAttributeCard."ATT Show on Customer Docs".Visible(),
            StrSubstNo(FieldVisibleMsg, ItemAttribute.FieldCaption("ATT Show on Customer Docs"), ItemAttributeCard.Caption()));
        Assert.IsTrue(
            ItemAttributeCard."ATT Show on Customer Docs".Editable(),
            StrSubstNo(FieldEditableMsg, ItemAttribute.FieldCaption("ATT Show on Customer Docs"), ItemAttributeCard.Caption()));
        Assert.IsTrue(
            ItemAttributeCard."ATT Show on Production Docs".Visible(),
            StrSubstNo(FieldVisibleMsg, ItemAttribute.FieldCaption("ATT Show on Production Docs"), ItemAttributeCard.Caption()));
        Assert.IsTrue(
            ItemAttributeCard."ATT Show on Production Docs".Editable(),
            StrSubstNo(FieldEditableMsg, ItemAttribute.FieldCaption("ATT Show on Production Docs"), ItemAttributeCard.Caption()));
        ItemAttributeCard.Close();
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        ATTTestLibrary.SetStockoutWarning(false);
        ATTTestLibrary.SetCreditWarningsToNoWarnings();
        ATTTestLibrary.InitializePostingSetup();

        IsInitialized := true;
        Commit();
    end;

    local procedure CreateItemAttributeWithPrintSettings(var ItemAttribute: Record "Item Attribute"; ShowOnCustomerDocs: Boolean; ShowOnProductionDocs: Boolean)
    begin
        ATTTestLibrary.CreateItemAttribute(ItemAttribute, '');
        ItemAttribute.Validate("ATT Show on Customer Docs", ShowOnCustomerDocs);
        ItemAttribute.Validate("ATT Show on Production Docs", ShowOnProductionDocs);
        ItemAttribute.Modify(true);
    end;

    local procedure CreateSalesLineForItemWithAttribute(var SalesLine: Record "Sales Line"; ItemAttribute: Record "Item Attribute")
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
    begin
        ATTTestLibrary.CreateItem(Item);
        AssignAttributeToItem(Item."No.", ItemAttribute.ID);
        ATTTestLibrary.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, ATTTestLibrary.CreateCustomerNo());
        ATTTestLibrary.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
    end;

    local procedure AssignAttributeToItem(ItemNo: Code[20]; AttributeId: Integer)
    var
        ItemAttributeValue: Record "Item Attribute Value";
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
    begin
        ATTTestLibrary.CreateItemAttributeValue(ItemAttributeValue, AttributeId, FamilieValueTxt);

        ItemAttributeValueMapping.Init();
        ItemAttributeValueMapping."Table ID" := Database::Item;
        ItemAttributeValueMapping."No." := ItemNo;
        ItemAttributeValueMapping."Item Attribute ID" := AttributeId;
        ItemAttributeValueMapping."Item Attribute Value ID" := ItemAttributeValue.ID;
        ItemAttributeValueMapping.Insert(true);
    end;

    local procedure InitSalesLineAttribute(var DocLineAttribute: Record "ATT Document Line Attribute"; SalesLine: Record "Sales Line")
    begin
        DocLineAttribute.Init();
        DocLineAttribute."Table ID" := Database::"Sales Line";
        DocLineAttribute."Document Type" := SalesLine."Document Type".AsInteger();
        DocLineAttribute."Document No." := SalesLine."Document No.";
        DocLineAttribute."Line No." := SalesLine."Line No.";
        DocLineAttribute.Source := DocLineAttribute.Source::Item;
    end;

    local procedure CreateTestUpgradeTag(): Code[250]
    begin
        exit(CopyStr(StrSubstNo(TestUpgradeTagTxt, ATTTestLibrary.GenerateUniqueCode()), 1, 250));
    end;

    local procedure AssertLineAttributePrintSettings(DocLineAttribute: Record "ATT Document Line Attribute"; ExpectedShowOnCustomerDocs: Boolean; ExpectedShowOnProductionDocs: Boolean)
    begin
        Assert.AreEqual(
            ExpectedShowOnCustomerDocs, DocLineAttribute."Show on Customer Documents", DocLineAttribute.FieldCaption("Show on Customer Documents"));
        Assert.AreEqual(
            ExpectedShowOnProductionDocs, DocLineAttribute."Show on Production Documents", DocLineAttribute.FieldCaption("Show on Production Documents"));
    end;

    local procedure AssertItemAttributePrintSettings(ItemAttribute: Record "Item Attribute"; ExpectedShowOnCustomerDocs: Boolean; ExpectedShowOnProductionDocs: Boolean)
    begin
        Assert.AreEqual(
            ExpectedShowOnCustomerDocs, ItemAttribute."ATT Show on Customer Docs", ItemAttribute.FieldCaption("ATT Show on Customer Docs"));
        Assert.AreEqual(
            ExpectedShowOnProductionDocs, ItemAttribute."ATT Show on Production Docs", ItemAttribute.FieldCaption("ATT Show on Production Docs"));
    end;
}
