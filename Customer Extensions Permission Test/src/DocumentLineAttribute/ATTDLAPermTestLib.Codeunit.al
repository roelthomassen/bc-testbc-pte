namespace Attitutor.CustomerExtensions.PermissionTest.DocumentLineAttribute;

using Attitutor.CustomerExtensions.DocumentLineAttribute;
using Microsoft.Inventory.Item.Attribute;
using Microsoft.Sales.Document;
using System.TestLibraries.Utilities;

/// <summary>
/// Helpers for the runtime permission tests of document line attributes: create, count and compare the attributes of a line.
/// </summary>
/// <remarks>
/// A trimmed copy of the helpers in ATT Doc. Line Attr. Test Lib. (Customer Extensions Test), so that this container-only app
/// does not depend on the sandbox test app.
/// </remarks>
codeunit 50181 "ATT DLA Perm. Test Lib."
{
    var
        Assert: Codeunit "Library Assert";
        Any: Codeunit Any;
        LibraryInventory: Codeunit "Library - Inventory";
        CountMismatchMsg: Label 'Number of attributes on the line.';
        FieldMismatchMsg: Label 'Field %1 of attribute %2.', Comment = '%1 = field caption, %2 = attribute ID';

    /// <summary>
    /// Creates the given number of attributes for a sales line, each with a new item attribute and value.
    /// </summary>
    /// <param name="SalesLine">The sales line to create the attributes for.</param>
    /// <param name="NumberOfAttributes">The number of attributes to create.</param>
    procedure CreateSalesLineAttributes(SalesLine: Record "Sales Line"; NumberOfAttributes: Integer)
    var
        Counter: Integer;
    begin
        for Counter := 1 to NumberOfAttributes do
            CreateSalesLineAttribute(SalesLine);
    end;

    /// <summary>
    /// Returns the number of attributes stored for the given line key.
    /// </summary>
    /// <returns>The number of attributes.</returns>
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
    /// <returns>The number of attributes.</returns>
    procedure CountSalesLineAttributes(SalesLine: Record "Sales Line"): Integer
    begin
        exit(CountLineAttributes(Database::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", 0, 0, SalesLine."Line No."));
    end;

    /// <summary>
    /// Copies the attributes of a sales line into a temporary buffer, so they can be compared after the line is gone.
    /// </summary>
    procedure GetSalesLineAttributes(SalesLine: Record "Sales Line"; var TempDocLineAttribute: Record "ATT Document Line Attribute" temporary)
    var
        DocLineAttribute: Record "ATT Document Line Attribute";
    begin
        TempDocLineAttribute.Reset();
        TempDocLineAttribute.DeleteAll();
        SetLineFilter(
            DocLineAttribute, Database::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", 0, 0, SalesLine."Line No.");
        if DocLineAttribute.FindSet() then
            repeat
                TempDocLineAttribute := DocLineAttribute;
                TempDocLineAttribute.Insert();
            until DocLineAttribute.Next() = 0;
    end;

    /// <summary>
    /// Asserts that the given line key has exactly the expected attributes, with the same value, unit of measure, source, flags and sequence.
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

    local procedure CreateSalesLineAttribute(SalesLine: Record "Sales Line")
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        DocLineAttribute: Record "ATT Document Line Attribute";
    begin
        LibraryInventory.CreateItemAttribute(ItemAttribute, ItemAttribute.Type::Option, CopyStr(Any.AlphanumericText(10), 1, 30));
        LibraryInventory.CreateItemAttributeValue(ItemAttributeValue, ItemAttribute.ID, CopyStr(Any.AlphanumericText(30), 1, 250));

        DocLineAttribute.Init();
        DocLineAttribute."Table ID" := Database::"Sales Line";
        DocLineAttribute."Document Type" := SalesLine."Document Type".AsInteger();
        DocLineAttribute."Document No." := SalesLine."Document No.";
        DocLineAttribute."Line No." := SalesLine."Line No.";
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
