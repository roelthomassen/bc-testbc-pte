namespace Attitutor.CustomerExtensions.Test.OrderAttributeSetting;

using Attitutor.CustomerExtensions.OrderAttributeSetting;
using Attitutor.CustomerExtensions.Test.TestLibrary;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Attribute;
using System.TestLibraries.Utilities;

/// <summary>
/// Tests for the order attribute settings on "Item Attribute Value Mapping" and the resulting setting computed by
/// codeunit "ATT Order Attr. Setting Mgt." (CU-123x5y65qpa, acceptance criteria 1-5).
/// </summary>
/// <remarks>
/// Run with test runner 130450 "Test Runner - Isol. Codeunit" (codeunit-level isolation) in a dedicated test company,
/// like the other test codeunits of this app.
/// </remarks>
codeunit 50156 "ATT Order Attr. Setting Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // [FEATURE] [Order Attribute Setting]

    var
        Assert: Codeunit "Library Assert";
        ATTTestLibrary: Codeunit "ATT Test Library";
        OrderAttrSettingMgt: Codeunit "ATT Order Attr. Setting Mgt.";
        IsInitialized: Boolean;
        ItemLevelTxt: Label 'Item', Locked = true;
        ItemCategoryLevelTxt: Label 'Item category %1', Locked = true, Comment = '%1 = item category code';
        AttributeNotExpectedMsg: Label 'Attribute %1 must not appear in the resulting setting.', Comment = '%1 = attribute ID';
        AttributeExpectedMsg: Label 'Attribute %1 must appear in the resulting setting.', Comment = '%1 = attribute ID';

    // AC1 - category inheritance

    [Test]
    procedure GetResultingSetting_InheritsMandatoryFromParentCategory()
    var
        ParentCategory: Record "Item Category";
        ChildCategory: Record "Item Category";
        Item: Record Item;
        ItemAttribute: Record "Item Attribute";
        TempResult: Record "ATT Res. Order Attr. Setting" temporary;
    begin
        // [SCENARIO AC1] An item in a sub-category inherits a mandatory attribute from the parent category; Level names the parent category.
        Initialize();

        // [GIVEN] Attribute Hardheid is mandatory on category MATRAS
        ATTTestLibrary.CreateItemAttribute(ItemAttribute, '');
        ATTTestLibrary.CreateItemCategory(ParentCategory);
        SetMapping(Database::"Item Category", ParentCategory.Code, ItemAttribute.ID, true, 0, false, '');
        // [GIVEN] Item M00001 has category N18 with parent category MATRAS
        ATTTestLibrary.CreateItemCategory(ChildCategory);
        ChildCategory.Validate("Parent Category", ParentCategory.Code);
        ChildCategory.Modify(true);
        ATTTestLibrary.CreateItem(Item);
        ATTTestLibrary.SetItemCategory(Item, ChildCategory.Code);

        // [WHEN] The resulting setting for the item is determined
        OrderAttrSettingMgt.GetResultingSetting(Item."No.", TempResult);

        // [THEN] The attribute is mandatory, with level naming the parent category
        Assert.IsTrue(TempResult.Get(ItemAttribute.ID), StrSubstNo(AttributeExpectedMsg, ItemAttribute.ID));
        Assert.IsTrue(TempResult.Mandatory, TempResult.FieldCaption(Mandatory));
        Assert.AreEqual(StrSubstNo(ItemCategoryLevelTxt, ParentCategory.Code), TempResult.Level, TempResult.FieldCaption(Level));
    end;

    [Test]
    procedure GetResultingSetting_InheritsFromGrandparentCategory()
    var
        GrandParentCategory: Record "Item Category";
        ParentCategory: Record "Item Category";
        ChildCategory: Record "Item Category";
        Item: Record Item;
        ItemAttribute: Record "Item Attribute";
        TempResult: Record "ATT Res. Order Attr. Setting" temporary;
    begin
        // [SCENARIO AC1/Open Question 5] The parent category chain is walked more than one level: an item inherits a mandatory
        // attribute from its category's grandparent category, with level naming the grandparent category.
        Initialize();

        // [GIVEN] Attribute is mandatory on a grandparent category, two levels above the item's own category
        ATTTestLibrary.CreateItemAttribute(ItemAttribute, '');
        ATTTestLibrary.CreateItemCategory(GrandParentCategory);
        SetMapping(Database::"Item Category", GrandParentCategory.Code, ItemAttribute.ID, true, 0, false, '');
        ATTTestLibrary.CreateItemCategory(ParentCategory);
        ParentCategory.Validate("Parent Category", GrandParentCategory.Code);
        ParentCategory.Modify(true);
        ATTTestLibrary.CreateItemCategory(ChildCategory);
        ChildCategory.Validate("Parent Category", ParentCategory.Code);
        ChildCategory.Modify(true);
        ATTTestLibrary.CreateItem(Item);
        ATTTestLibrary.SetItemCategory(Item, ChildCategory.Code);

        // [WHEN] The resulting setting for the item is determined
        OrderAttrSettingMgt.GetResultingSetting(Item."No.", TempResult);

        // [THEN] The attribute is mandatory, with level naming the grandparent category
        Assert.IsTrue(TempResult.Get(ItemAttribute.ID), StrSubstNo(AttributeExpectedMsg, ItemAttribute.ID));
        Assert.IsTrue(TempResult.Mandatory, TempResult.FieldCaption(Mandatory));
        Assert.AreEqual(StrSubstNo(ItemCategoryLevelTxt, GrandParentCategory.Code), TempResult.Level, TempResult.FieldCaption(Level));
    end;

    // AC2 - most specific level wins

    [Test]
    procedure GetResultingSetting_ItemLevelOverridesCategoryLevel()
    var
        ItemCategory: Record "Item Category";
        Item: Record Item;
        ItemAttribute: Record "Item Attribute";
        TempResult: Record "ATT Res. Order Attr. Setting" temporary;
    begin
        // [SCENARIO AC2] An item-level mapping row overrides a conflicting category-level row for the same attribute.
        Initialize();

        // [GIVEN] Attribute is not mandatory on the item's category
        ATTTestLibrary.CreateItemAttribute(ItemAttribute, '');
        ATTTestLibrary.CreateItemCategory(ItemCategory);
        SetMapping(Database::"Item Category", ItemCategory.Code, ItemAttribute.ID, false, 0, false, '');
        ATTTestLibrary.CreateItem(Item);
        ATTTestLibrary.SetItemCategory(Item, ItemCategory.Code);
        // [GIVEN] Attribute is mandatory on the item itself
        SetMapping(Database::Item, Item."No.", ItemAttribute.ID, true, 0, false, '');

        // [WHEN] The resulting setting for the item is determined
        OrderAttrSettingMgt.GetResultingSetting(Item."No.", TempResult);

        // [THEN] The attribute is mandatory, with level naming the item
        Assert.IsTrue(TempResult.Get(ItemAttribute.ID), StrSubstNo(AttributeExpectedMsg, ItemAttribute.ID));
        Assert.IsTrue(TempResult.Mandatory, TempResult.FieldCaption(Mandatory));
        Assert.AreEqual(ItemLevelTxt, TempResult.Level, TempResult.FieldCaption(Level));
    end;

    // AC3 - not applicable

    [Test]
    procedure GetResultingSetting_NotApplicableAtMoreSpecificLevel_RemovesAttribute()
    var
        ParentCategory: Record "Item Category";
        ChildCategory: Record "Item Category";
        Item: Record Item;
        ItemAttribute: Record "Item Attribute";
        TempResult: Record "ATT Res. Order Attr. Setting" temporary;
    begin
        // [SCENARIO AC3] Not Applicable = Yes at a more specific category removes the attribute from the resulting setting.
        Initialize();

        // [GIVEN] Attribute is set on a parent category
        ATTTestLibrary.CreateItemAttribute(ItemAttribute, '');
        ATTTestLibrary.CreateItemCategory(ParentCategory);
        SetMapping(Database::"Item Category", ParentCategory.Code, ItemAttribute.ID, true, 0, false, '');
        // [GIVEN] On a child category, the attribute is Not Applicable
        ATTTestLibrary.CreateItemCategory(ChildCategory);
        ChildCategory.Validate("Parent Category", ParentCategory.Code);
        ChildCategory.Modify(true);
        SetMapping(Database::"Item Category", ChildCategory.Code, ItemAttribute.ID, false, 0, true, '');
        ATTTestLibrary.CreateItem(Item);
        ATTTestLibrary.SetItemCategory(Item, ChildCategory.Code);

        // [WHEN] The resulting setting for an item in the child category is determined
        OrderAttrSettingMgt.GetResultingSetting(Item."No.", TempResult);

        // [THEN] The attribute does not appear
        Assert.IsFalse(TempResult.Get(ItemAttribute.ID), StrSubstNo(AttributeNotExpectedMsg, ItemAttribute.ID));
    end;

    // AC4 - invalid default value (extended to all types)

    [Test]
    procedure ValidateDefaultValue_InvalidOptionValue_ThrowsErrorAndIsNotSaved()
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        Item: Record Item;
    begin
        // [SCENARIO AC4] A default value that is not an existing value of an Option attribute is rejected and not saved.
        Initialize();

        // [GIVEN] Attribute Hardheid of type Option with an existing value, mapped to an item
        CreateOptionAttribute(ItemAttribute, ItemAttributeValue, 'Hard');
        ATTTestLibrary.CreateItem(Item);
        InitItemMapping(ItemAttributeValueMapping, Item."No.", ItemAttribute.ID);
        ItemAttributeValueMapping.Insert(true);

        // [WHEN] The administrator enters "Super" as the default value
        asserterror ItemAttributeValueMapping.Validate("ATT Default Value", 'Super');

        // [THEN] An error is raised and the value is not saved
        Assert.ExpectedError('Super');
        ItemAttributeValueMapping.Get(Database::Item, Item."No.", ItemAttribute.ID);
        Assert.AreEqual('', ItemAttributeValueMapping."ATT Default Value", ItemAttributeValueMapping.FieldCaption("ATT Default Value"));
    end;

    [Test]
    procedure ValidateDefaultValue_ValidOptionValue_IsSaved()
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        Item: Record Item;
    begin
        // [SCENARIO AC4] An existing value of an Option attribute is accepted as the default value.
        Initialize();

        CreateOptionAttribute(ItemAttribute, ItemAttributeValue, 'Hard');
        ATTTestLibrary.CreateItem(Item);
        InitItemMapping(ItemAttributeValueMapping, Item."No.", ItemAttribute.ID);
        ItemAttributeValueMapping.Insert(true);

        // [WHEN] The administrator enters the existing value as the default value
        ItemAttributeValueMapping.Validate("ATT Default Value", 'Hard');
        ItemAttributeValueMapping.Modify(true);

        // [THEN] The value is saved and resolved to the existing item attribute value
        ItemAttributeValueMapping.Get(Database::Item, Item."No.", ItemAttribute.ID);
        Assert.AreEqual('Hard', ItemAttributeValueMapping."ATT Default Value", ItemAttributeValueMapping.FieldCaption("ATT Default Value"));
        Assert.AreEqual(
            ItemAttributeValue.ID, ItemAttributeValueMapping."Item Attribute Value ID",
            ItemAttributeValueMapping.FieldCaption("Item Attribute Value ID"));
    end;

    [Test]
    procedure ValidateDefaultValue_InvalidDecimalValue_ThrowsErrorAndIsNotSaved()
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        Item: Record Item;
    begin
        // [SCENARIO AC4] A default value that does not parse as a decimal is rejected for a Decimal attribute, and not saved.
        Initialize();

        CreateDecimalAttribute(ItemAttribute);
        ATTTestLibrary.CreateItem(Item);
        InitItemMapping(ItemAttributeValueMapping, Item."No.", ItemAttribute.ID);
        ItemAttributeValueMapping.Insert(true);

        asserterror ItemAttributeValueMapping.Validate("ATT Default Value", 'abc');

        Assert.ExpectedError('abc');
        ItemAttributeValueMapping.Get(Database::Item, Item."No.", ItemAttribute.ID);
        Assert.AreEqual('', ItemAttributeValueMapping."ATT Default Value", ItemAttributeValueMapping.FieldCaption("ATT Default Value"));
    end;

    [Test]
    procedure ValidateDefaultValue_ValidDecimalValue_IsSaved()
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        Item: Record Item;
    begin
        // [SCENARIO AC4] A value that parses as a decimal is accepted as the default value of a Decimal attribute.
        Initialize();

        CreateDecimalAttribute(ItemAttribute);
        ATTTestLibrary.CreateItem(Item);
        InitItemMapping(ItemAttributeValueMapping, Item."No.", ItemAttribute.ID);
        ItemAttributeValueMapping.Insert(true);

        ItemAttributeValueMapping.Validate("ATT Default Value", '12.5');
        ItemAttributeValueMapping.Modify(true);

        ItemAttributeValueMapping.Get(Database::Item, Item."No.", ItemAttribute.ID);
        Assert.AreEqual('12.5', ItemAttributeValueMapping."ATT Default Value", ItemAttributeValueMapping.FieldCaption("ATT Default Value"));
        Assert.AreNotEqual(0, ItemAttributeValueMapping."Item Attribute Value ID", ItemAttributeValueMapping.FieldCaption("Item Attribute Value ID"));
    end;

    [Test]
    procedure ValidateDefaultValue_InvalidIntegerValue_ThrowsErrorAndIsNotSaved()
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        Item: Record Item;
    begin
        // [SCENARIO AC4] A default value that does not parse as an integer is rejected for an Integer attribute, and not saved.
        Initialize();

        CreateIntegerAttribute(ItemAttribute);
        ATTTestLibrary.CreateItem(Item);
        InitItemMapping(ItemAttributeValueMapping, Item."No.", ItemAttribute.ID);
        ItemAttributeValueMapping.Insert(true);

        asserterror ItemAttributeValueMapping.Validate("ATT Default Value", 'abc');

        Assert.ExpectedError('abc');
        ItemAttributeValueMapping.Get(Database::Item, Item."No.", ItemAttribute.ID);
        Assert.AreEqual('', ItemAttributeValueMapping."ATT Default Value", ItemAttributeValueMapping.FieldCaption("ATT Default Value"));
    end;

    [Test]
    procedure ValidateDefaultValue_ValidIntegerValue_IsSaved()
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        Item: Record Item;
    begin
        // [SCENARIO AC4] A value that parses as an integer is accepted as the default value of an Integer attribute.
        Initialize();

        CreateIntegerAttribute(ItemAttribute);
        ATTTestLibrary.CreateItem(Item);
        InitItemMapping(ItemAttributeValueMapping, Item."No.", ItemAttribute.ID);
        ItemAttributeValueMapping.Insert(true);

        ItemAttributeValueMapping.Validate("ATT Default Value", '5');
        ItemAttributeValueMapping.Modify(true);

        ItemAttributeValueMapping.Get(Database::Item, Item."No.", ItemAttribute.ID);
        Assert.AreEqual('5', ItemAttributeValueMapping."ATT Default Value", ItemAttributeValueMapping.FieldCaption("ATT Default Value"));
        Assert.AreNotEqual(0, ItemAttributeValueMapping."Item Attribute Value ID", ItemAttributeValueMapping.FieldCaption("Item Attribute Value ID"));
    end;

    [Test]
    procedure ValidateDefaultValue_InvalidDateValue_ThrowsErrorAndIsNotSaved()
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        Item: Record Item;
    begin
        // [SCENARIO AC4] A default value that does not parse as a date is rejected for a Date attribute, and not saved.
        Initialize();

        CreateDateAttribute(ItemAttribute);
        ATTTestLibrary.CreateItem(Item);
        InitItemMapping(ItemAttributeValueMapping, Item."No.", ItemAttribute.ID);
        ItemAttributeValueMapping.Insert(true);

        asserterror ItemAttributeValueMapping.Validate("ATT Default Value", 'not a date');

        Assert.ExpectedError('not a date');
        ItemAttributeValueMapping.Get(Database::Item, Item."No.", ItemAttribute.ID);
        Assert.AreEqual('', ItemAttributeValueMapping."ATT Default Value", ItemAttributeValueMapping.FieldCaption("ATT Default Value"));
    end;

    [Test]
    procedure ValidateDefaultValue_ValidDateValue_IsSaved()
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        Item: Record Item;
        DateText: Text[250];
    begin
        // [SCENARIO AC4] A value that parses as a date is accepted as the default value of a Date attribute.
        Initialize();

        CreateDateAttribute(ItemAttribute);
        ATTTestLibrary.CreateItem(Item);
        InitItemMapping(ItemAttributeValueMapping, Item."No.", ItemAttribute.ID);
        ItemAttributeValueMapping.Insert(true);
        // The XML date format (Format(Date, 0, 9)) round-trips through Evaluate regardless of the session's regional settings.
        DateText := Format(WorkDate(), 0, 9);

        ItemAttributeValueMapping.Validate("ATT Default Value", DateText);
        ItemAttributeValueMapping.Modify(true);

        ItemAttributeValueMapping.Get(Database::Item, Item."No.", ItemAttribute.ID);
        Assert.AreEqual(DateText, ItemAttributeValueMapping."ATT Default Value", ItemAttributeValueMapping.FieldCaption("ATT Default Value"));
        Assert.AreNotEqual(0, ItemAttributeValueMapping."Item Attribute Value ID", ItemAttributeValueMapping.FieldCaption("Item Attribute Value ID"));
    end;

    [Test]
    procedure ValidateDefaultValue_TextValue_AcceptsAnyValue()
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        Item: Record Item;
    begin
        // [SCENARIO AC4] A Text attribute accepts any default value.
        Initialize();

        CreateTextAttribute(ItemAttribute);
        ATTTestLibrary.CreateItem(Item);
        InitItemMapping(ItemAttributeValueMapping, Item."No.", ItemAttribute.ID);
        ItemAttributeValueMapping.Insert(true);

        ItemAttributeValueMapping.Validate("ATT Default Value", 'Any text at all, 123!');
        ItemAttributeValueMapping.Modify(true);

        ItemAttributeValueMapping.Get(Database::Item, Item."No.", ItemAttribute.ID);
        Assert.AreEqual(
            'Any text at all, 123!', ItemAttributeValueMapping."ATT Default Value", ItemAttributeValueMapping.FieldCaption("ATT Default Value"));
        Assert.AreNotEqual(0, ItemAttributeValueMapping."Item Attribute Value ID", ItemAttributeValueMapping.FieldCaption("Item Attribute Value ID"));
    end;

    // AC5 - no retroactive effect (tested at the resulting-setting level per Open Question 1)

    [Test]
    procedure GetResultingSetting_ChangingCategorySetting_IsReflectedImmediately()
    var
        ItemCategory: Record "Item Category";
        Item: Record Item;
        ItemAttribute: Record "Item Attribute";
        TempResult: Record "ATT Res. Order Attr. Setting" temporary;
    begin
        // [SCENARIO AC5] A change to a category's setting is immediately reflected in GetResultingSetting for an item under it.
        Initialize();

        // [GIVEN] An item in a category, with no order attribute setting yet for an attribute
        ATTTestLibrary.CreateItemAttribute(ItemAttribute, '');
        ATTTestLibrary.CreateItemCategory(ItemCategory);
        ATTTestLibrary.CreateItem(Item);
        ATTTestLibrary.SetItemCategory(Item, ItemCategory.Code);

        OrderAttrSettingMgt.GetResultingSetting(Item."No.", TempResult);
        Assert.IsFalse(TempResult.Get(ItemAttribute.ID), StrSubstNo(AttributeNotExpectedMsg, ItemAttribute.ID));

        // [WHEN] The attribute is added as mandatory to the category's setting
        SetMapping(Database::"Item Category", ItemCategory.Code, ItemAttribute.ID, true, 0, false, '');

        // [THEN] The resulting setting for the item immediately contains the attribute as mandatory
        OrderAttrSettingMgt.GetResultingSetting(Item."No.", TempResult);
        Assert.IsTrue(TempResult.Get(ItemAttribute.ID), StrSubstNo(AttributeExpectedMsg, ItemAttribute.ID));
        Assert.IsTrue(TempResult.Mandatory, TempResult.FieldCaption(Mandatory));
    end;

    // Print setting override (Open Question 2)

    [Test]
    procedure GetResultingSetting_PrintFlagBlank_FallsBackToItemAttribute()
    var
        ItemCategory: Record "Item Category";
        Item: Record Item;
        ItemAttribute: Record "Item Attribute";
        TempResult: Record "ATT Res. Order Attr. Setting" temporary;
    begin
        // [SCENARIO] When the mapping row leaves the print setting blank (inherit), the resulting setting falls back to the item attribute's own flag.
        Initialize();

        ATTTestLibrary.CreateItemAttribute(ItemAttribute, '');
        ItemAttribute.Validate("ATT Show on Customer Docs", false);
        ItemAttribute.Modify(true);
        ATTTestLibrary.CreateItemCategory(ItemCategory);
        SetMapping(Database::"Item Category", ItemCategory.Code, ItemAttribute.ID, false, 0, false, '');
        ATTTestLibrary.CreateItem(Item);
        ATTTestLibrary.SetItemCategory(Item, ItemCategory.Code);

        OrderAttrSettingMgt.GetResultingSetting(Item."No.", TempResult);

        Assert.IsTrue(TempResult.Get(ItemAttribute.ID), StrSubstNo(AttributeExpectedMsg, ItemAttribute.ID));
        Assert.IsFalse(
            TempResult."Show on Customer Documents", TempResult.FieldCaption("Show on Customer Documents"));
    end;

    [Test]
    procedure GetResultingSetting_PrintFlagOverride_UsesOverride()
    var
        ItemCategory: Record "Item Category";
        Item: Record Item;
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        TempResult: Record "ATT Res. Order Attr. Setting" temporary;
    begin
        // [SCENARIO] An explicit Yes/No override of the print setting on the mapping row wins over the item attribute's own flag.
        Initialize();

        ATTTestLibrary.CreateItemAttribute(ItemAttribute, '');
        ItemAttribute.Validate("ATT Show on Customer Docs", true);
        ItemAttribute.Modify(true);
        ATTTestLibrary.CreateItemCategory(ItemCategory);
        ATTTestLibrary.CreateItem(Item);
        ATTTestLibrary.SetItemCategory(Item, ItemCategory.Code);

        InitCategoryMapping(ItemAttributeValueMapping, ItemCategory.Code, ItemAttribute.ID);
        ItemAttributeValueMapping."ATT Cust. Docs Override" := ItemAttributeValueMapping."ATT Cust. Docs Override"::No;
        ItemAttributeValueMapping.Insert(true);

        OrderAttrSettingMgt.GetResultingSetting(Item."No.", TempResult);

        Assert.IsTrue(TempResult.Get(ItemAttribute.ID), StrSubstNo(AttributeExpectedMsg, ItemAttribute.ID));
        Assert.IsFalse(
            TempResult."Show on Customer Documents", TempResult.FieldCaption("Show on Customer Documents"));
    end;

    // Defensive check: cyclic item category chain

    [Test]
    procedure GetResultingSetting_CategoryIsOwnParent_ThrowsError()
    var
        ItemCategory: Record "Item Category";
        Item: Record Item;
        TempResult: Record "ATT Res. Order Attr. Setting" temporary;
    begin
        // [SCENARIO] A category that is its own parent is detected and raises a clear error instead of looping forever. The
        // standard Item Category table already prevents this through Validate("Parent Category"), so the cycle here is
        // created by bypassing that check with direct field assignment, simulating corrupted or directly-edited data.
        Initialize();

        // [GIVEN] An item in a category, assigned while the category structure is still valid
        ATTTestLibrary.CreateItemCategory(ItemCategory);
        ATTTestLibrary.CreateItem(Item);
        ATTTestLibrary.SetItemCategory(Item, ItemCategory.Code);
        // [GIVEN] The category is made its own parent afterwards. Assigning this through Validate would be rejected by the
        // standard cyclic-inheritance check, so it is done by direct field assignment.
        ItemCategory."Parent Category" := ItemCategory.Code;
        ItemCategory.Modify(true);

        // [WHEN] The resulting setting for an item in the category is determined
        asserterror OrderAttrSettingMgt.GetResultingSetting(Item."No.", TempResult);

        // [THEN] A clear error is raised instead of looping forever
        Assert.ExpectedError(ItemCategory.Code);
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        IsInitialized := true;
        Commit();
    end;

    local procedure InitItemMapping(var ItemAttributeValueMapping: Record "Item Attribute Value Mapping"; ItemNo: Code[20]; AttributeId: Integer)
    begin
        ItemAttributeValueMapping.Init();
        ItemAttributeValueMapping."Table ID" := Database::Item;
        ItemAttributeValueMapping."No." := ItemNo;
        ItemAttributeValueMapping."Item Attribute ID" := AttributeId;
    end;

    local procedure InitCategoryMapping(var ItemAttributeValueMapping: Record "Item Attribute Value Mapping"; CategoryCode: Code[20]; AttributeId: Integer)
    begin
        ItemAttributeValueMapping.Init();
        ItemAttributeValueMapping."Table ID" := Database::"Item Category";
        ItemAttributeValueMapping."No." := CategoryCode;
        ItemAttributeValueMapping."Item Attribute ID" := AttributeId;
    end;

    local procedure SetMapping(TableId: Integer; No: Code[20]; AttributeId: Integer; Mandatory: Boolean; SequenceNo: Integer; NotApplicable: Boolean; DefaultValue: Text[250])
    var
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
    begin
        ItemAttributeValueMapping.Init();
        ItemAttributeValueMapping."Table ID" := TableId;
        ItemAttributeValueMapping."No." := No;
        ItemAttributeValueMapping."Item Attribute ID" := AttributeId;
        ItemAttributeValueMapping."ATT Mandatory" := Mandatory;
        ItemAttributeValueMapping."ATT Sequence" := SequenceNo;
        ItemAttributeValueMapping."ATT Not Applicable" := NotApplicable;
        ItemAttributeValueMapping."ATT Default Value" := DefaultValue;
        ItemAttributeValueMapping.Insert(true);
    end;

    local procedure CreateAttribute(var ItemAttribute: Record "Item Attribute")
    begin
        ItemAttribute.Init();
        ItemAttribute.Validate(Name, ATTTestLibrary.GenerateUniqueCode());
        ItemAttribute.Insert(true);
    end;

    local procedure CreateOptionAttribute(var ItemAttribute: Record "Item Attribute"; var ItemAttributeValue: Record "Item Attribute Value"; ValidValueText: Text[250])
    begin
        CreateAttribute(ItemAttribute);
        ItemAttribute.Validate(Type, ItemAttribute.Type::Option);
        ItemAttribute.Modify(true);
        ATTTestLibrary.CreateItemAttributeValue(ItemAttributeValue, ItemAttribute.ID, ValidValueText);
    end;

    local procedure CreateDecimalAttribute(var ItemAttribute: Record "Item Attribute")
    begin
        CreateAttribute(ItemAttribute);
        ItemAttribute.Validate(Type, ItemAttribute.Type::Decimal);
        ItemAttribute.Modify(true);
    end;

    local procedure CreateIntegerAttribute(var ItemAttribute: Record "Item Attribute")
    begin
        CreateAttribute(ItemAttribute);
        ItemAttribute.Validate(Type, ItemAttribute.Type::Integer);
        ItemAttribute.Modify(true);
    end;

    local procedure CreateDateAttribute(var ItemAttribute: Record "Item Attribute")
    begin
        CreateAttribute(ItemAttribute);
        ItemAttribute.Validate(Type, ItemAttribute.Type::Date);
        ItemAttribute.Modify(true);
    end;

    local procedure CreateTextAttribute(var ItemAttribute: Record "Item Attribute")
    begin
        CreateAttribute(ItemAttribute);
        ItemAttribute.Validate(Type, ItemAttribute.Type::Text);
        ItemAttribute.Modify(true);
    end;
}
