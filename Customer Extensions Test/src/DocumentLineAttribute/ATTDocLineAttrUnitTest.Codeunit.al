namespace Attitutor.CustomerExtensions.Test.DocumentLineAttribute;

using Attitutor.CustomerExtensions.DocumentLineAttribute;
using Attitutor.CustomerExtensions.Test.TestLibrary;
using Microsoft.Inventory.Item.Attribute;
using Microsoft.Manufacturing.Document;
using Microsoft.Sales.Archive;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using System.TestLibraries.Utilities;

/// <summary>
/// Unit tests for the ATT Document Line Attribute table and the ATT Doc. Line Attribute Mgt. codeunit
/// (CU-123x5y65gje, acceptance criteria 1-6 and 8).
/// </summary>
/// <remarks>
/// Run with test runner 130450 "Test Runner - Isol. Codeunit" (codeunit-level isolation) in a dedicated test company:
/// the tests insert and modify item attributes, item attribute values and line attribute rows in real tables (Initialize changes
/// nothing), and these must be rolled back when the codeunit ends.
/// </remarks>
codeunit 50150 "ATT Doc. Line Attr. Unit Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // [FEATURE] [Document Line Attribute]

    var
        Assert: Codeunit "Library Assert";
        ATTTestLibrary: Codeunit "ATT Test Library";
        TestLib: Codeunit "ATT Doc. Line Attr. Test Lib.";
        DocLineAttributeMgt: Codeunit "ATT Doc. Line Attribute Mgt.";
        IsInitialized: Boolean;
        AttributeValueNotFoundErr: Label 'Attribute value %1 does not exist for attribute %2.', Comment = '%1 = attribute value ID, %2 = attribute ID';
        ItemAttributeBlockedErr: Label 'Item attribute %1 is blocked and cannot be assigned to a document line.', Comment = '%1 = item attribute name';
        ItemAttributeValueBlockedErr: Label 'Value %1 of item attribute %2 is blocked and cannot be assigned to a document line.', Comment = '%1 = item attribute value, %2 = item attribute name';
        UnsupportedTableErr: Label 'Document line attributes cannot be stored for table %1.', Comment = '%1 = table ID';
        UnsupportedRecordErr: Label 'Document line attributes are not supported for records of table %1.', Comment = '%1 = table ID';
        NotARecordErr: Label 'The document line must be passed as a record.';
        MediumTxt: Label 'Medium', Locked = true;
        MidTxt: Label 'Mid', Locked = true;
        CentimeterTxt: Label 'cm', Locked = true;
        MillimeterTxt: Label 'mm', Locked = true;

    // AC1 - stored value

    [Test]
    procedure ChangeItemAttributeValueText_LineAttributeKeepsStoredValue()
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        DocLineAttribute: Record "ATT Document Line Attribute";
    begin
        // [SCENARIO AC1] Changing the text of an item attribute value does not change the value stored on a line attribute.
        Initialize();

        // [GIVEN] A line attribute with the attribute value "Medium"
        TestLib.CreateItemAttributeWithValue(CentimeterTxt, MediumTxt, ItemAttribute, ItemAttributeValue);
        CreateSalesLineAttribute(DocLineAttribute, ItemAttribute.ID, ItemAttributeValue.ID);

        // [WHEN] The text of the item attribute value is changed to "Mid"
        ItemAttributeValue.Validate(Value, MidTxt);
        ItemAttributeValue.Modify(true);

        // [THEN] The line attribute still shows "Medium"
        DocLineAttribute.Find();
        Assert.AreEqual(MediumTxt, DocLineAttribute.Value, DocLineAttribute.FieldCaption(Value));
    end;

    // AC2 - snapshot on assignment

    [Test]
    procedure ValidateAttributeValueId_StoresValueText()
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        DocLineAttribute: Record "ATT Document Line Attribute";
    begin
        // [SCENARIO AC2] Validating Attribute Value ID copies the text of the attribute value into Value.
        Initialize();

        // [GIVEN] An item attribute with unit "cm" and a value "Medium"
        TestLib.CreateItemAttributeWithValue(CentimeterTxt, MediumTxt, ItemAttribute, ItemAttributeValue);
        DocLineAttribute.Validate("Attribute ID", ItemAttribute.ID);

        // [WHEN] Attribute Value ID is validated
        DocLineAttribute.Validate("Attribute Value ID", ItemAttributeValue.ID);

        // [THEN] Value is "Medium"
        Assert.AreEqual(MediumTxt, DocLineAttribute.Value, DocLineAttribute.FieldCaption(Value));
    end;

    [Test]
    procedure ValidateAttributeValueId_StoresUnitOfMeasure()
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        DocLineAttribute: Record "ATT Document Line Attribute";
    begin
        // [SCENARIO AC2] Validating Attribute Value ID copies the unit of measure of the item attribute.
        Initialize();

        // [GIVEN] An item attribute with unit "cm" and a value "Medium"
        TestLib.CreateItemAttributeWithValue(CentimeterTxt, MediumTxt, ItemAttribute, ItemAttributeValue);
        DocLineAttribute.Validate("Attribute ID", ItemAttribute.ID);

        // [WHEN] Attribute Value ID is validated
        DocLineAttribute.Validate("Attribute Value ID", ItemAttributeValue.ID);

        // [THEN] Unit of Measure is "cm"
        Assert.AreEqual(CentimeterTxt, DocLineAttribute."Unit of Measure", DocLineAttribute.FieldCaption("Unit of Measure"));
    end;

    [Test]
    procedure ChangeItemAttributeUnitOfMeasure_LineAttributeKeepsStoredUnit()
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        DocLineAttribute: Record "ATT Document Line Attribute";
    begin
        // [SCENARIO AC2] A later change of the unit on the item attribute does not change the line attribute.
        Initialize();

        // [GIVEN] A line attribute for an item attribute with unit "cm"
        TestLib.CreateItemAttributeWithValue(CentimeterTxt, MediumTxt, ItemAttribute, ItemAttributeValue);
        CreateSalesLineAttribute(DocLineAttribute, ItemAttribute.ID, ItemAttributeValue.ID);

        // [WHEN] The unit of the item attribute is changed to "mm"
        ItemAttribute.Validate("Unit of Measure", MillimeterTxt);
        ItemAttribute.Modify(true);

        // [THEN] The line attribute still has unit "cm"
        DocLineAttribute.Find();
        Assert.AreEqual(CentimeterTxt, DocLineAttribute."Unit of Measure", DocLineAttribute.FieldCaption("Unit of Measure"));
    end;

    [Test]
    procedure ValidateAttributeValueIdOfOtherAttribute_ThrowsError()
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        OtherItemAttribute: Record "Item Attribute";
        OtherItemAttributeValue: Record "Item Attribute Value";
        DocLineAttribute: Record "ATT Document Line Attribute";
    begin
        // [SCENARIO AC2] An Attribute Value ID that belongs to a different Attribute ID is rejected.
        Initialize();

        // [GIVEN] Two item attributes, each with a value
        TestLib.CreateItemAttributeWithValue(CentimeterTxt, MediumTxt, ItemAttribute, ItemAttributeValue);
        TestLib.CreateItemAttributeWithValue(MillimeterTxt, MidTxt, OtherItemAttribute, OtherItemAttributeValue);
        DocLineAttribute.Validate("Attribute ID", ItemAttribute.ID);

        // [WHEN] The value of the other attribute is validated
        asserterror DocLineAttribute.Validate("Attribute Value ID", OtherItemAttributeValue.ID);

        // [THEN] An error says the value does not exist for the attribute
        Assert.ExpectedError(StrSubstNo(AttributeValueNotFoundErr, OtherItemAttributeValue.ID, ItemAttribute.ID));
    end;

    [Test]
    procedure ValidateAttributeValueIdZero_ClearsValueAndUnit()
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        DocLineAttribute: Record "ATT Document Line Attribute";
    begin
        // [SCENARIO AC2] Clearing Attribute Value ID also clears the stored value and unit of measure.
        Initialize();

        // [GIVEN] A line attribute with value "Medium" and unit "cm"
        TestLib.CreateItemAttributeWithValue(CentimeterTxt, MediumTxt, ItemAttribute, ItemAttributeValue);
        DocLineAttribute.Validate("Attribute ID", ItemAttribute.ID);
        DocLineAttribute.Validate("Attribute Value ID", ItemAttributeValue.ID);

        // [WHEN] Attribute Value ID is validated to 0
        DocLineAttribute.Validate("Attribute Value ID", 0);

        // [THEN] Value and Unit of Measure are empty
        Assert.AreEqual('', DocLineAttribute.Value, DocLineAttribute.FieldCaption(Value));
        Assert.AreEqual('', DocLineAttribute."Unit of Measure", DocLineAttribute.FieldCaption("Unit of Measure"));
    end;

    [Test]
    procedure ValidateOtherAttributeId_ClearsValueAndUnit()
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        OtherItemAttribute: Record "Item Attribute";
        OtherItemAttributeValue: Record "Item Attribute Value";
        DocLineAttribute: Record "ATT Document Line Attribute";
    begin
        // [SCENARIO AC2] Changing Attribute ID clears the attribute value, the stored value and the unit of measure.
        Initialize();

        // [GIVEN] A line attribute with value "Medium" and unit "cm"
        TestLib.CreateItemAttributeWithValue(CentimeterTxt, MediumTxt, ItemAttribute, ItemAttributeValue);
        TestLib.CreateItemAttributeWithValue(MillimeterTxt, MidTxt, OtherItemAttribute, OtherItemAttributeValue);
        DocLineAttribute.Validate("Attribute ID", ItemAttribute.ID);
        DocLineAttribute.Validate("Attribute Value ID", ItemAttributeValue.ID);

        // [WHEN] Attribute ID is validated to another attribute
        DocLineAttribute.Validate("Attribute ID", OtherItemAttribute.ID);

        // [THEN] Attribute Value ID is 0 and Value and Unit of Measure are empty
        Assert.AreEqual(0, DocLineAttribute."Attribute Value ID", DocLineAttribute.FieldCaption("Attribute Value ID"));
        Assert.AreEqual('', DocLineAttribute.Value, DocLineAttribute.FieldCaption(Value));
        Assert.AreEqual('', DocLineAttribute."Unit of Measure", DocLineAttribute.FieldCaption("Unit of Measure"));
    end;

    [Test]
    procedure ValidateAttributeValueIdOfBlockedAttribute_ThrowsError()
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        DocLineAttribute: Record "ATT Document Line Attribute";
    begin
        // [SCENARIO AC2] A value of a blocked item attribute cannot be assigned to a line attribute.
        Initialize();

        // [GIVEN] A blocked item attribute with a value
        TestLib.CreateItemAttributeWithValue(CentimeterTxt, MediumTxt, ItemAttribute, ItemAttributeValue);
        ItemAttribute.Blocked := true;
        ItemAttribute.Modify(true);
        DocLineAttribute.Validate("Attribute ID", ItemAttribute.ID);

        // [WHEN] The value is validated on a line attribute
        asserterror DocLineAttribute.Validate("Attribute Value ID", ItemAttributeValue.ID);

        // [THEN] An error says the item attribute is blocked
        Assert.ExpectedError(StrSubstNo(ItemAttributeBlockedErr, ItemAttribute.Name));
    end;

    [Test]
    procedure ValidateBlockedAttributeValueId_ThrowsError()
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        DocLineAttribute: Record "ATT Document Line Attribute";
    begin
        // [SCENARIO AC2] A blocked item attribute value cannot be assigned to a line attribute.
        Initialize();

        // [GIVEN] An item attribute with a blocked value
        TestLib.CreateItemAttributeWithValue(CentimeterTxt, MediumTxt, ItemAttribute, ItemAttributeValue);
        ItemAttributeValue.Blocked := true;
        ItemAttributeValue.Modify(true);
        DocLineAttribute.Validate("Attribute ID", ItemAttribute.ID);

        // [WHEN] The blocked value is validated on a line attribute
        asserterror DocLineAttribute.Validate("Attribute Value ID", ItemAttributeValue.ID);

        // [THEN] An error says the item attribute value is blocked
        Assert.ExpectedError(StrSubstNo(ItemAttributeValueBlockedErr, ItemAttributeValue.Value, ItemAttribute.Name));
    end;

    // AC3 - copy

    [Test]
    procedure CopyAttributesOfBlockedAttribute_CopiesAttribute()
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        DocLineAttribute: Record "ATT Document Line Attribute";
        TempFromSalesLine: Record "Sales Line" temporary;
        TempToSalesLine: Record "Sales Line" temporary;
        TempExpectedDocLineAttribute: Record "ATT Document Line Attribute" temporary;
    begin
        // [SCENARIO AC3] Copying is not affected when the item attribute and its value were blocked after assignment.
        Initialize();

        // [GIVEN] A sales line with an attribute whose item attribute and value are blocked afterwards
        CreateTempSalesLine(TempFromSalesLine);
        TestLib.CreateItemAttributeWithValue(CentimeterTxt, MediumTxt, ItemAttribute, ItemAttributeValue);
        CreateLineAttribute(
            DocLineAttribute, Database::"Sales Line", TempFromSalesLine."Document Type".AsInteger(), TempFromSalesLine."Document No.", 0, 0,
            TempFromSalesLine."Line No.", ItemAttribute.ID, ItemAttributeValue.ID);
        TestLib.GetSalesLineAttributes(TempFromSalesLine, TempExpectedDocLineAttribute);
        ItemAttribute.Blocked := true;
        ItemAttribute.Modify(true);
        ItemAttributeValue.Blocked := true;
        ItemAttributeValue.Modify(true);

        // [WHEN] The attributes are copied to another sales line
        CreateTempSalesLine(TempToSalesLine);
        DocLineAttributeMgt.CopyAttributes(TempFromSalesLine, TempToSalesLine);

        // [THEN] The target line has the attribute
        TestLib.AssertLineAttributesMatch(
            TempExpectedDocLineAttribute, Database::"Sales Line", TempToSalesLine."Document Type".AsInteger(), TempToSalesLine."Document No.", 0, 0, TempToSalesLine."Line No.");
    end;

    [Test]
    procedure CopyAttributes_TargetGetsSameAttributes()
    var
        TempFromSalesLine: Record "Sales Line" temporary;
        TempToSalesInvoiceLine: Record "Sales Invoice Line" temporary;
        TempExpectedDocLineAttribute: Record "ATT Document Line Attribute" temporary;
    begin
        // [SCENARIO AC2/AC3] Copying the attributes of a sales line gives the target line the same 8 attributes.
        Initialize();

        // [GIVEN] A sales line with 8 attributes
        CreateTempSalesLine(TempFromSalesLine);
        TestLib.CreateSalesLineAttributes(TempFromSalesLine, 8);
        TestLib.GetSalesLineAttributes(TempFromSalesLine, TempExpectedDocLineAttribute);

        // [WHEN] The attributes are copied to a sales invoice line
        CreateTempSalesInvoiceLine(TempToSalesInvoiceLine);
        DocLineAttributeMgt.CopyAttributes(TempFromSalesLine, TempToSalesInvoiceLine);

        // [THEN] The invoice line has the same 8 attributes with the same values, unit, source, flags and sequence
        TestLib.AssertLineAttributesMatch(
            TempExpectedDocLineAttribute, Database::"Sales Invoice Line", 0, TempToSalesInvoiceLine."Document No.", 0, 0, TempToSalesInvoiceLine."Line No.");
    end;

    [Test]
    procedure CopyAttributesToLineWithAttributes_ReplacesTargetAttributes()
    var
        TempFromSalesLine: Record "Sales Line" temporary;
        TempToSalesLine: Record "Sales Line" temporary;
        TempExpectedDocLineAttribute: Record "ATT Document Line Attribute" temporary;
    begin
        // [SCENARIO AC2/AC3] Existing attributes of the target are removed first, including attributes that are not on the source.
        Initialize();

        // [GIVEN] A sales line with 8 attributes
        CreateTempSalesLine(TempFromSalesLine);
        TestLib.CreateSalesLineAttributes(TempFromSalesLine, 8);
        TestLib.GetSalesLineAttributes(TempFromSalesLine, TempExpectedDocLineAttribute);

        // [GIVEN] A target sales line with 3 attributes of its own
        CreateTempSalesLine(TempToSalesLine);
        TestLib.CreateSalesLineAttributes(TempToSalesLine, 3);

        // [WHEN] The attributes are copied to the target line
        DocLineAttributeMgt.CopyAttributes(TempFromSalesLine, TempToSalesLine);

        // [THEN] The target has exactly the 8 attributes of the source
        TestLib.AssertLineAttributesMatch(
            TempExpectedDocLineAttribute, Database::"Sales Line", TempToSalesLine."Document Type".AsInteger(), TempToSalesLine."Document No.", 0, 0, TempToSalesLine."Line No.");
    end;

    [Test]
    procedure CopyAttributesToSameLine_KeepsAttributes()
    var
        TempSalesLine: Record "Sales Line" temporary;
    begin
        // [SCENARIO AC3] Copying a line onto itself does not delete its attributes.
        Initialize();

        // [GIVEN] A sales line with 4 attributes
        CreateTempSalesLine(TempSalesLine);
        TestLib.CreateSalesLineAttributes(TempSalesLine, 4);

        // [WHEN] The attributes are copied to the same line
        DocLineAttributeMgt.CopyAttributes(TempSalesLine, TempSalesLine);

        // [THEN] The line still has its 4 attributes
        Assert.AreEqual(4, TestLib.CountSalesLineAttributes(TempSalesLine), 'Number of attributes on the line.');
    end;

    [Test]
    procedure CopyAttributesFromUnsupportedRecord_ThrowsError()
    var
        TempCustomer: Record Customer temporary;
        TempSalesLine: Record "Sales Line" temporary;
    begin
        // [SCENARIO AC3] The copy function rejects records of tables that are not supported.
        Initialize();

        // [GIVEN] A customer record and a sales line
        TempCustomer."No." := ATTTestLibrary.GenerateUniqueCode();
        CreateTempSalesLine(TempSalesLine);

        // [WHEN] Attributes are copied from the customer record
        asserterror DocLineAttributeMgt.CopyAttributes(TempCustomer, TempSalesLine);

        // [THEN] An error says the table is not supported
        Assert.ExpectedError(StrSubstNo(UnsupportedRecordErr, Database::Customer));
    end;

    [Test]
    procedure DeleteAttributesForNonRecord_ThrowsError()
    begin
        // [SCENARIO AC5] The delete function rejects a value that is not a record.
        Initialize();

        // [GIVEN] A value that is not a record
        // [WHEN] The delete function is run for it
        asserterror DocLineAttributeMgt.DeleteAttributes(ATTTestLibrary.GenerateUniqueCode());

        // [THEN] An error says a record is expected
        Assert.ExpectedError(NotARecordErr);
    end;

    // AC4 - archive key

    [Test]
    procedure InsertAttributeForTwoArchiveVersions_BothVersionsKeepOwnAttribute()
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        DocLineAttribute: Record "ATT Document Line Attribute";
        DocumentNo: Code[20];
    begin
        // [SCENARIO AC3/AC4] The same attribute can be stored for version 1 and version 2 of the same archived line.
        Initialize();

        // [GIVEN] An attribute stored for version 1 of an archived sales line
        TestLib.CreateItemAttributeWithValue(CentimeterTxt, MediumTxt, ItemAttribute, ItemAttributeValue);
        DocumentNo := ATTTestLibrary.GenerateUniqueCode();
        CreateLineAttribute(
            DocLineAttribute, Database::"Sales Line Archive", "Sales Document Type"::Order.AsInteger(), DocumentNo, 1, 1, 10000,
            ItemAttribute.ID, ItemAttributeValue.ID);

        // [WHEN] The same attribute is stored for version 2 of the same line
        CreateLineAttribute(
            DocLineAttribute, Database::"Sales Line Archive", "Sales Document Type"::Order.AsInteger(), DocumentNo, 1, 2, 10000,
            ItemAttribute.ID, ItemAttributeValue.ID);

        // [THEN] Each version has exactly one attribute
        Assert.AreEqual(
            1, TestLib.CountLineAttributes(Database::"Sales Line Archive", "Sales Document Type"::Order.AsInteger(), DocumentNo, 1, 1, 10000),
            'Number of attributes on version 1.');
        Assert.AreEqual(
            1, TestLib.CountLineAttributes(Database::"Sales Line Archive", "Sales Document Type"::Order.AsInteger(), DocumentNo, 1, 2, 10000),
            'Number of attributes on version 2.');
    end;

    // AC5 - delete function

    [Test]
    procedure DeleteAttributes_RemovesAllAttributesOfLine()
    var
        DocumentNo: Code[20];
    begin
        // [SCENARIO AC5] The delete function removes all attributes of the line.
        Initialize();

        // [GIVEN] Version 1 of an archived line with 3 attributes
        DocumentNo := ATTTestLibrary.GenerateUniqueCode();
        TestLib.CreateLineAttributes(Database::"Sales Line Archive", "Sales Document Type"::Order.AsInteger(), DocumentNo, 1, 1, 10000, 3);

        // [WHEN] The delete function is run for the line
        DocLineAttributeMgt.DeleteAttributes(Database::"Sales Line Archive", "Sales Document Type"::Order.AsInteger(), DocumentNo, 1, 1, 10000);

        // [THEN] The line has no attributes
        Assert.AreEqual(
            0, TestLib.CountLineAttributes(Database::"Sales Line Archive", "Sales Document Type"::Order.AsInteger(), DocumentNo, 1, 1, 10000),
            'Number of attributes on the deleted line.');
    end;

    [Test]
    procedure DeleteAttributes_KeepsAttributesOfOtherLines()
    var
        DocumentNo: Code[20];
        DocumentType: Integer;
    begin
        // [SCENARIO AC5] Attributes of other lines, versions and occurrences of the same document remain.
        Initialize();

        // [GIVEN] Version 1 of an archived line with 3 attributes
        DocumentNo := ATTTestLibrary.GenerateUniqueCode();
        DocumentType := "Sales Document Type"::Order.AsInteger();
        TestLib.CreateLineAttributes(Database::"Sales Line Archive", DocumentType, DocumentNo, 1, 1, 10000, 3);

        // [GIVEN] Attributes for version 2, another occurrence and another line of the same document
        TestLib.CreateLineAttributes(Database::"Sales Line Archive", DocumentType, DocumentNo, 1, 2, 10000, 2);
        TestLib.CreateLineAttributes(Database::"Sales Line Archive", DocumentType, DocumentNo, 2, 1, 10000, 2);
        TestLib.CreateLineAttributes(Database::"Sales Line Archive", DocumentType, DocumentNo, 1, 1, 20000, 2);

        // [WHEN] The delete function is run for version 1 of the first line
        DocLineAttributeMgt.DeleteAttributes(Database::"Sales Line Archive", DocumentType, DocumentNo, 1, 1, 10000);

        // [THEN] The other version, occurrence and line keep their attributes
        Assert.AreEqual(2, TestLib.CountLineAttributes(Database::"Sales Line Archive", DocumentType, DocumentNo, 1, 2, 10000), 'Number of attributes on version 2.');
        Assert.AreEqual(2, TestLib.CountLineAttributes(Database::"Sales Line Archive", DocumentType, DocumentNo, 2, 1, 10000), 'Number of attributes on occurrence 2.');
        Assert.AreEqual(2, TestLib.CountLineAttributes(Database::"Sales Line Archive", DocumentType, DocumentNo, 1, 1, 20000), 'Number of attributes on line 20000.');
    end;

    [Test]
    procedure DeleteAttributesForRecord_RemovesAttributesOfLine()
    var
        TempSalesShipmentLine: Record "Sales Shipment Line" temporary;
    begin
        // [SCENARIO AC5] The delete function also works when it is given the line record.
        Initialize();

        // [GIVEN] A sales shipment line with 3 attributes
        TempSalesShipmentLine."Document No." := ATTTestLibrary.GenerateUniqueCode();
        TempSalesShipmentLine."Line No." := 10000;
        TestLib.CreateLineAttributes(Database::"Sales Shipment Line", 0, TempSalesShipmentLine."Document No.", 0, 0, TempSalesShipmentLine."Line No.", 3);

        // [WHEN] The delete function is run for the shipment line record
        DocLineAttributeMgt.DeleteAttributes(TempSalesShipmentLine);

        // [THEN] The shipment line has no attributes
        Assert.AreEqual(
            0, TestLib.CountLineAttributes(Database::"Sales Shipment Line", 0, TempSalesShipmentLine."Document No.", 0, 0, TempSalesShipmentLine."Line No."),
            'Number of attributes on the shipment line.');
    end;

    // AC6 - supported tables

    [Test]
    procedure InsertAttributeForEachSupportedTable_Succeeds()
    var
        DocLineAttribute: Record "ATT Document Line Attribute";
        DocumentNo: Code[20];
    begin
        // [SCENARIO AC6] Attributes can be stored for tables 37, 5108, 111, 113, 115 and 6661.
        Initialize();

        // [GIVEN] A document number
        DocumentNo := ATTTestLibrary.GenerateUniqueCode();

        // [WHEN] An attribute is inserted for each supported table
        TestLib.CreateLineAttribute(DocLineAttribute, Database::"Sales Line", "Sales Document Type"::Order.AsInteger(), DocumentNo, 0, 0, 10000);
        TestLib.CreateLineAttribute(DocLineAttribute, Database::"Sales Line Archive", "Sales Document Type"::Order.AsInteger(), DocumentNo, 1, 1, 10000);
        TestLib.CreateLineAttribute(DocLineAttribute, Database::"Sales Shipment Line", 0, DocumentNo, 0, 0, 10000);
        TestLib.CreateLineAttribute(DocLineAttribute, Database::"Sales Invoice Line", 0, DocumentNo, 0, 0, 10000);
        TestLib.CreateLineAttribute(DocLineAttribute, Database::"Sales Cr.Memo Line", 0, DocumentNo, 0, 0, 10000);
        TestLib.CreateLineAttribute(DocLineAttribute, Database::"Return Receipt Line", 0, DocumentNo, 0, 0, 10000);

        // [THEN] All 6 attributes are stored
        DocLineAttribute.Reset();
        DocLineAttribute.SetRange("Document No.", DocumentNo);
        Assert.RecordCount(DocLineAttribute, 6);
    end;

    [Test]
    procedure InsertAttributeForUnsupportedTable_ThrowsError()
    var
        DocLineAttribute: Record "ATT Document Line Attribute";
    begin
        // [SCENARIO AC6] Inserting an attribute for a table that is not supported raises an error.
        Initialize();

        // [GIVEN] A line attribute for the Sales Header table
        // [WHEN] It is inserted
        asserterror TestLib.CreateLineAttribute(DocLineAttribute, Database::"Sales Header", "Sales Document Type"::Order.AsInteger(), ATTTestLibrary.GenerateUniqueCode(), 0, 0, 10000);

        // [THEN] An error says the table is not supported
        Assert.ExpectedError(StrSubstNo(UnsupportedTableErr, Database::"Sales Header"));
    end;

    [Test]
    procedure IsSupportedTableForProdOrderLine_ReturnsFalse()
    begin
        // [SCENARIO AC6] Prod. Order Line (5406) is prepared for in the key but not supported yet.
        Initialize();

        // [GIVEN] The Prod. Order Line table
        // [WHEN] IsSupportedTable is called for it
        // [THEN] It returns false
        Assert.IsFalse(DocLineAttributeMgt.IsSupportedTable(Database::"Prod. Order Line"), 'Prod. Order Line must not be supported yet.');
    end;

    // AC8 - default source

    [Test]
    procedure NewLineAttribute_HasBlankSource()
    var
        DocLineAttribute: Record "ATT Document Line Attribute";
    begin
        // [SCENARIO AC8] A new line attribute has a blank Source until it is set.
        Initialize();

        // [GIVEN] A new line attribute
        // [WHEN] It is initialized
        DocLineAttribute.Init();

        // [THEN] Source is blank
        Assert.AreEqual("ATT Line Attribute Source"::" ", DocLineAttribute.Source, DocLineAttribute.FieldCaption(Source));
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        IsInitialized := true;
    end;

    local procedure CreateTempSalesLine(var TempSalesLine: Record "Sales Line" temporary)
    begin
        TempSalesLine.Init();
        TempSalesLine."Document Type" := TempSalesLine."Document Type"::Order;
        TempSalesLine."Document No." := ATTTestLibrary.GenerateUniqueCode();
        TempSalesLine."Line No." := 10000;
    end;

    local procedure CreateTempSalesInvoiceLine(var TempSalesInvoiceLine: Record "Sales Invoice Line" temporary)
    begin
        TempSalesInvoiceLine.Init();
        TempSalesInvoiceLine."Document No." := ATTTestLibrary.GenerateUniqueCode();
        TempSalesInvoiceLine."Line No." := 10000;
    end;

    local procedure CreateSalesLineAttribute(var DocLineAttribute: Record "ATT Document Line Attribute"; AttributeId: Integer; AttributeValueId: Integer)
    begin
        CreateLineAttribute(
            DocLineAttribute, Database::"Sales Line", "Sales Document Type"::Order.AsInteger(), ATTTestLibrary.GenerateUniqueCode(), 0, 0, 10000,
            AttributeId, AttributeValueId);
    end;

    local procedure CreateLineAttribute(var DocLineAttribute: Record "ATT Document Line Attribute"; TableId: Integer; DocumentType: Integer; DocumentNo: Code[20]; DocNoOccurrence: Integer; VersionNo: Integer; LineNo: Integer; AttributeId: Integer; AttributeValueId: Integer)
    begin
        DocLineAttribute.Init();
        DocLineAttribute."Table ID" := TableId;
        DocLineAttribute."Document Type" := DocumentType;
        DocLineAttribute."Document No." := DocumentNo;
        DocLineAttribute."Doc. No. Occurrence" := DocNoOccurrence;
        DocLineAttribute."Version No." := VersionNo;
        DocLineAttribute."Line No." := LineNo;
        DocLineAttribute.Validate("Attribute ID", AttributeId);
        DocLineAttribute.Validate("Attribute Value ID", AttributeValueId);
        DocLineAttribute.Insert(true);
    end;
}
