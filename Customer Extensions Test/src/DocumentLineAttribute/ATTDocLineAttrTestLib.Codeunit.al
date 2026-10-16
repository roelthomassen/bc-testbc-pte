namespace Attitutor.CustomerExtensions.Test.DocumentLineAttribute;

using Attitutor.CustomerExtensions.DocumentLineAttribute;
using Attitutor.CustomerExtensions.Test.TestLibrary;
using Microsoft.Inventory.Item.Attribute;
using Microsoft.Sales.Document;
using System.TestLibraries.Utilities;

/// <summary>
/// Shared helpers for the document line attribute tests.
/// </summary>
/// <remarks>
/// Customer Extensions Permission Test has a trimmed copy of these helpers in codeunit 50181 "ATT DLA Perm. Test Lib."; keep the two in sync.
/// Use the ATT Test Library instance in this codeunit only for item attributes, never for CreateItem, CreateCustomer or sales documents:
/// each ATT Test Library instance creates its own posting groups, so mixing instances mixes posting setups.
/// </remarks>
codeunit 50152 "ATT Doc. Line Attr. Test Lib."
{
    var
        Assert: Codeunit "Library Assert";
        Any: Codeunit Any;
        ATTTestLibrary: Codeunit "ATT Test Library";
        CountMismatchMsg: Label 'Number of attributes on the line.';
        FieldMismatchMsg: Label 'Field %1 of attribute %2.', Comment = '%1 = field caption, %2 = attribute ID';

    /// <summary>
    /// Creates an item attribute with the given unit of measure and one value with the given text.
    /// </summary>
    procedure CreateItemAttributeWithValue(UnitOfMeasure: Text[30]; ValueText: Text[250]; var ItemAttribute: Record "Item Attribute"; var ItemAttributeValue: Record "Item Attribute Value")
    begin
        ATTTestLibrary.CreateItemAttribute(ItemAttribute, UnitOfMeasure);
        ATTTestLibrary.CreateItemAttributeValue(ItemAttributeValue, ItemAttribute.ID, ValueText);
    end;

    /// <summary>
    /// Creates and inserts a line attribute for the given line key, with a new item attribute and value and random flags, source and sequence.
    /// </summary>
    procedure CreateLineAttribute(var DocLineAttribute: Record "ATT Document Line Attribute"; TableId: Integer; DocumentType: Integer; DocumentNo: Code[20]; DocNoOccurrence: Integer; VersionNo: Integer; LineNo: Integer)
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
    begin
        CreateItemAttributeWithValue(
            CopyStr(Any.AlphanumericText(10), 1, 30), CopyStr(Any.AlphanumericText(30), 1, 250), ItemAttribute, ItemAttributeValue);

        DocLineAttribute.Init();
        DocLineAttribute."Table ID" := TableId;
        DocLineAttribute."Document Type" := DocumentType;
        DocLineAttribute."Document No." := DocumentNo;
        DocLineAttribute."Doc. No. Occurrence" := DocNoOccurrence;
        DocLineAttribute."Version No." := VersionNo;
        DocLineAttribute."Line No." := LineNo;
        DocLineAttribute.Validate("Attribute ID", ItemAttribute.ID);
        DocLineAttribute.Validate("Attribute Value ID", ItemAttributeValue.ID);
        DocLineAttribute.Source := Enum::"ATT Line Attribute Source".FromInteger(Any.IntegerInRange(1, 4));
        DocLineAttribute."Manually Modified" := Any.Boolean();
        DocLineAttribute.Mandatory := Any.Boolean();
        DocLineAttribute.Sequence := Any.IntegerInRange(1, 1000);
        DocLineAttribute."Show on Customer Documents" := Any.Boolean();
        DocLineAttribute."Show on Production Documents" := Any.Boolean();
        DocLineAttribute.Insert(true);
    end;

    /// <summary>
    /// Creates the given number of line attributes for the given line key.
    /// </summary>
    procedure CreateLineAttributes(TableId: Integer; DocumentType: Integer; DocumentNo: Code[20]; DocNoOccurrence: Integer; VersionNo: Integer; LineNo: Integer; NumberOfAttributes: Integer)
    var
        DocLineAttribute: Record "ATT Document Line Attribute";
        Counter: Integer;
    begin
        for Counter := 1 to NumberOfAttributes do
            CreateLineAttribute(DocLineAttribute, TableId, DocumentType, DocumentNo, DocNoOccurrence, VersionNo, LineNo);
    end;

    /// <summary>
    /// Creates the given number of line attributes for a sales line.
    /// </summary>
    procedure CreateSalesLineAttributes(SalesLine: Record "Sales Line"; NumberOfAttributes: Integer)
    begin
        CreateLineAttributes(
            Database::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", 0, 0, SalesLine."Line No.", NumberOfAttributes);
    end;

    /// <summary>
    /// Returns the number of attributes stored for the given line key.
    /// </summary>
    procedure CountLineAttributes(TableId: Integer; DocumentType: Integer; DocumentNo: Code[20]; DocNoOccurrence: Integer; VersionNo: Integer; LineNo: Integer): Integer
    var
        DocLineAttribute: Record "ATT Document Line Attribute";
    begin
        SetLineFilter(DocLineAttribute, TableId, DocumentType, DocumentNo, DocNoOccurrence, VersionNo, LineNo);
        exit(DocLineAttribute.Count());
    end;

    /// <summary>
    /// Returns the number of attributes stored for a sales line.
    /// </summary>
    procedure CountSalesLineAttributes(SalesLine: Record "Sales Line"): Integer
    begin
        exit(CountLineAttributes(Database::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", 0, 0, SalesLine."Line No."));
    end;

    /// <summary>
    /// Copies the attributes of the given line key into a temporary buffer, so they can be compared after the source line is gone.
    /// </summary>
    procedure GetLineAttributes(TableId: Integer; DocumentType: Integer; DocumentNo: Code[20]; DocNoOccurrence: Integer; VersionNo: Integer; LineNo: Integer; var TempDocLineAttribute: Record "ATT Document Line Attribute" temporary)
    var
        DocLineAttribute: Record "ATT Document Line Attribute";
    begin
        TempDocLineAttribute.Reset();
        TempDocLineAttribute.DeleteAll();
        SetLineFilter(DocLineAttribute, TableId, DocumentType, DocumentNo, DocNoOccurrence, VersionNo, LineNo);
        if DocLineAttribute.FindSet() then
            repeat
                TempDocLineAttribute := DocLineAttribute;
                TempDocLineAttribute.Insert();
            until DocLineAttribute.Next() = 0;
    end;

    /// <summary>
    /// Copies the attributes of a sales line into a temporary buffer.
    /// </summary>
    procedure GetSalesLineAttributes(SalesLine: Record "Sales Line"; var TempDocLineAttribute: Record "ATT Document Line Attribute" temporary)
    begin
        GetLineAttributes(
            Database::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", 0, 0, SalesLine."Line No.", TempDocLineAttribute);
    end;

    /// <summary>
    /// Asserts that the given line key has exactly the expected attributes, with the same values, unit of measure, source, flags and sequence.
    /// </summary>
    procedure AssertLineAttributesMatch(var TempExpectedDocLineAttribute: Record "ATT Document Line Attribute" temporary; TableId: Integer; DocumentType: Integer; DocumentNo: Code[20]; DocNoOccurrence: Integer; VersionNo: Integer; LineNo: Integer)
    var
        DocLineAttribute: Record "ATT Document Line Attribute";
    begin
        TempExpectedDocLineAttribute.Reset();
        Assert.AreEqual(
            TempExpectedDocLineAttribute.Count(),
            CountLineAttributes(TableId, DocumentType, DocumentNo, DocNoOccurrence, VersionNo, LineNo),
            CountMismatchMsg);

        if not TempExpectedDocLineAttribute.FindSet() then
            exit;

        repeat
            DocLineAttribute.Get(TableId, DocumentType, DocumentNo, DocNoOccurrence, VersionNo, LineNo, TempExpectedDocLineAttribute."Attribute ID");
            AssertAttributeFieldsMatch(TempExpectedDocLineAttribute, DocLineAttribute);
        until TempExpectedDocLineAttribute.Next() = 0;
    end;

    local procedure AssertAttributeFieldsMatch(ExpectedDocLineAttribute: Record "ATT Document Line Attribute"; ActualDocLineAttribute: Record "ATT Document Line Attribute")
    var
        AttributeId: Integer;
    begin
        AttributeId := ExpectedDocLineAttribute."Attribute ID";
        Assert.AreEqual(
            ExpectedDocLineAttribute."Attribute Value ID", ActualDocLineAttribute."Attribute Value ID",
            StrSubstNo(FieldMismatchMsg, ActualDocLineAttribute.FieldCaption("Attribute Value ID"), AttributeId));
        Assert.AreEqual(
            ExpectedDocLineAttribute.Value, ActualDocLineAttribute.Value,
            StrSubstNo(FieldMismatchMsg, ActualDocLineAttribute.FieldCaption(Value), AttributeId));
        Assert.AreEqual(
            ExpectedDocLineAttribute."Unit of Measure", ActualDocLineAttribute."Unit of Measure",
            StrSubstNo(FieldMismatchMsg, ActualDocLineAttribute.FieldCaption("Unit of Measure"), AttributeId));
        Assert.AreEqual(
            ExpectedDocLineAttribute.Source, ActualDocLineAttribute.Source,
            StrSubstNo(FieldMismatchMsg, ActualDocLineAttribute.FieldCaption(Source), AttributeId));
        Assert.AreEqual(
            ExpectedDocLineAttribute."Manually Modified", ActualDocLineAttribute."Manually Modified",
            StrSubstNo(FieldMismatchMsg, ActualDocLineAttribute.FieldCaption("Manually Modified"), AttributeId));
        Assert.AreEqual(
            ExpectedDocLineAttribute.Mandatory, ActualDocLineAttribute.Mandatory,
            StrSubstNo(FieldMismatchMsg, ActualDocLineAttribute.FieldCaption(Mandatory), AttributeId));
        Assert.AreEqual(
            ExpectedDocLineAttribute.Sequence, ActualDocLineAttribute.Sequence,
            StrSubstNo(FieldMismatchMsg, ActualDocLineAttribute.FieldCaption(Sequence), AttributeId));
        Assert.AreEqual(
            ExpectedDocLineAttribute."Show on Customer Documents", ActualDocLineAttribute."Show on Customer Documents",
            StrSubstNo(FieldMismatchMsg, ActualDocLineAttribute.FieldCaption("Show on Customer Documents"), AttributeId));
        Assert.AreEqual(
            ExpectedDocLineAttribute."Show on Production Documents", ActualDocLineAttribute."Show on Production Documents",
            StrSubstNo(FieldMismatchMsg, ActualDocLineAttribute.FieldCaption("Show on Production Documents"), AttributeId));
    end;

    local procedure SetLineFilter(var DocLineAttribute: Record "ATT Document Line Attribute"; TableId: Integer; DocumentType: Integer; DocumentNo: Code[20]; DocNoOccurrence: Integer; VersionNo: Integer; LineNo: Integer)
    begin
        DocLineAttribute.SetRange("Table ID", TableId);
        DocLineAttribute.SetRange("Document Type", DocumentType);
        DocLineAttribute.SetRange("Document No.", DocumentNo);
        DocLineAttribute.SetRange("Doc. No. Occurrence", DocNoOccurrence);
        DocLineAttribute.SetRange("Version No.", VersionNo);
        DocLineAttribute.SetRange("Line No.", LineNo);
    end;
}
