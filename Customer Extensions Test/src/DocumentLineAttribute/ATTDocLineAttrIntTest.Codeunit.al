namespace Attitutor.CustomerExtensions.Test.DocumentLineAttribute;

using Attitutor.CustomerExtensions.DocumentLineAttribute;
using Attitutor.CustomerExtensions.Test.TestLibrary;
using Microsoft.Sales.Archive;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Utilities;
using System.TestLibraries.Utilities;

/// <summary>
/// Integration tests for the automatic delete, archive copy and posting copy of document line attributes
/// (CU-123x5y65gje, acceptance criteria 7 and 9-11).
/// </summary>
/// <remarks>
/// Run with test runner 130450 "Test Runner - Isol. Codeunit" (codeunit-level isolation) in a dedicated test company:
/// the tests and their Initialize change setup and data that must be rolled back when the codeunit ends.
/// </remarks>
codeunit 50151 "ATT Doc. Line Attr. Int. Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // [FEATURE] [Document Line Attribute]

    var
        Assert: Codeunit "Library Assert";
        Any: Codeunit Any;
        ATTTestLibrary: Codeunit "ATT Test Library";
        TestLib: Codeunit "ATT Doc. Line Attr. Test Lib.";
        ArchiveManagement: Codeunit ArchiveManagement;
        IsInitialized: Boolean;
        AttributeCountMsg: Label 'Number of attributes on the line.';
        DocumentTypeMsg: Label 'Document Type of the line attribute.';

    // AC9 - automatic delete

    [Test]
    procedure DeleteSalesLine_DeletesItsAttributes()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [SCENARIO AC9] Deleting a sales line deletes its attributes.
        Initialize();

        // [GIVEN] A sales order line with 3 attributes
        CreateSalesDocumentWithAttributes(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, 3);

        // [WHEN] The sales line is deleted
        SalesLine.Delete(true);

        // [THEN] The line has no attributes
        Assert.AreEqual(0, TestLib.CountSalesLineAttributes(SalesLine), AttributeCountMsg);
    end;

    [Test]
    procedure DeleteSalesLine_KeepsAttributesOfOtherLines()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OtherSalesLine: Record "Sales Line";
    begin
        // [SCENARIO AC9] Deleting a sales line does not delete the attributes of other lines.
        Initialize();

        // [GIVEN] A sales order with two lines, each with attributes
        CreateSalesDocumentWithAttributes(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, 3);
        CreateSalesLineWithAttributes(OtherSalesLine, SalesHeader, 2);

        // [WHEN] The first sales line is deleted
        SalesLine.Delete(true);

        // [THEN] The other line keeps its 2 attributes
        Assert.AreEqual(2, TestLib.CountSalesLineAttributes(OtherSalesLine), AttributeCountMsg);
    end;

    [Test]
    procedure DeleteSalesHeader_DeletesAttributesOfAllLines()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OtherSalesLine: Record "Sales Line";
    begin
        // [SCENARIO AC9] Deleting a sales document deletes the attributes of all its lines.
        Initialize();

        // [GIVEN] A sales order with two lines, each with attributes
        CreateSalesDocumentWithAttributes(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, 3);
        CreateSalesLineWithAttributes(OtherSalesLine, SalesHeader, 2);

        // [WHEN] The sales order is deleted
        SalesHeader.Delete(true);

        // [THEN] Neither line has attributes
        Assert.AreEqual(0, TestLib.CountSalesLineAttributes(SalesLine), AttributeCountMsg);
        Assert.AreEqual(0, TestLib.CountSalesLineAttributes(OtherSalesLine), AttributeCountMsg);
    end;

    [Test]
    procedure DeleteSalesHeaderArchive_DeletesAttributesOfArchivedLines()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesHeaderArchive: Record "Sales Header Archive";
    begin
        // [SCENARIO AC9] Deleting an archived sales document deletes the attributes of its archived lines.
        Initialize();

        // [GIVEN] An archived sales order whose line has 3 attributes
        CreateSalesDocumentWithAttributes(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, 3);
        ArchiveSalesDocument(SalesHeader, SalesHeaderArchive);

        // [WHEN] The archived sales order is deleted
        SalesHeaderArchive.Delete(true);

        // [THEN] The archived line has no attributes
        Assert.AreEqual(0, CountArchiveLineAttributes(SalesHeaderArchive, SalesLine."Line No."), AttributeCountMsg);
    end;

    [Test]
    procedure DeletePostedSalesInvoiceLine_DeletesItsAttributes()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceLine: Record "Sales Invoice Line";
        InvoiceNo: Code[20];
    begin
        // [SCENARIO AC9] Deleting a posted sales invoice line deletes its attributes.
        Initialize();

        // [GIVEN] A posted sales invoice whose line has 3 attributes
        CreateSalesDocumentWithAttributes(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, 3);
        InvoiceNo := ATTTestLibrary.PostSalesDocument(SalesHeader, true, true);
        SalesInvoiceLine.Get(InvoiceNo, SalesLine."Line No.");

        // [WHEN] The posted invoice line is deleted
        SalesInvoiceLine.Delete();

        // [THEN] The posted invoice line has no attributes
        Assert.AreEqual(0, TestLib.CountLineAttributes(Database::"Sales Invoice Line", 0, InvoiceNo, 0, 0, SalesLine."Line No."), AttributeCountMsg);
    end;

    [Test]
    procedure DeleteTempSalesLine_KeepsAttributesOfRealLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TempSalesLine: Record "Sales Line" temporary;
    begin
        // [SCENARIO AC9] Deleting a temporary copy of a sales line does not delete the attributes of the real line.
        Initialize();

        // [GIVEN] A sales order line with 3 attributes and a temporary copy of it with the same key
        CreateSalesDocumentWithAttributes(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, 3);
        TempSalesLine := SalesLine;
        TempSalesLine.Insert();

        // [WHEN] The temporary copy is deleted
        TempSalesLine.Delete();

        // [THEN] The real line still has its 3 attributes
        Assert.AreEqual(3, TestLib.CountSalesLineAttributes(SalesLine), AttributeCountMsg);
    end;

    [Test]
    procedure DeleteSalesLineArchive_DeletesItsAttributes()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesHeaderArchive: Record "Sales Header Archive";
        SalesLineArchive: Record "Sales Line Archive";
    begin
        // [SCENARIO AC9] Deleting a single archived sales line deletes its attributes.
        Initialize();

        // [GIVEN] An archived sales order whose line has 3 attributes
        CreateSalesDocumentWithAttributes(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, 3);
        ArchiveSalesDocument(SalesHeader, SalesHeaderArchive);
        SalesLineArchive.Get(
            SalesHeaderArchive."Document Type", SalesHeaderArchive."No.", SalesHeaderArchive."Doc. No. Occurrence",
            SalesHeaderArchive."Version No.", SalesLine."Line No.");

        // [WHEN] The archived line is deleted
        SalesLineArchive.Delete(true);

        // [THEN] The archived line has no attributes
        Assert.AreEqual(0, CountArchiveLineAttributes(SalesHeaderArchive, SalesLine."Line No."), AttributeCountMsg);
    end;

    [Test]
    procedure DeletePostedSalesShipmentLine_DeletesItsAttributes()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        // [SCENARIO AC9] Deleting a posted sales shipment line deletes its attributes.
        Initialize();

        // [GIVEN] A shipped sales order whose line has 3 attributes
        CreateSalesDocumentWithAttributes(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, 3);
        ATTTestLibrary.PostSalesDocument(SalesHeader, true, false);
        FindSalesShipmentLine(SalesShipmentLine, SalesLine);

        // [WHEN] The posted shipment line is deleted
        SalesShipmentLine.Delete();

        // [THEN] The posted shipment line has no attributes
        Assert.AreEqual(
            0, TestLib.CountLineAttributes(Database::"Sales Shipment Line", 0, SalesShipmentLine."Document No.", 0, 0, SalesShipmentLine."Line No."),
            AttributeCountMsg);
    end;

    [Test]
    procedure DeletePostedSalesCrMemoLine_DeletesItsAttributes()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        CrMemoNo: Code[20];
    begin
        // [SCENARIO AC9] Deleting a posted sales credit memo line deletes its attributes.
        Initialize();

        // [GIVEN] A posted sales credit memo whose line has 3 attributes
        CreateSalesDocumentWithAttributes(SalesHeader, SalesLine, SalesHeader."Document Type"::"Credit Memo", 3);
        CrMemoNo := ATTTestLibrary.PostSalesDocument(SalesHeader, true, true);
        SalesCrMemoLine.Get(CrMemoNo, SalesLine."Line No.");

        // [WHEN] The posted credit memo line is deleted
        SalesCrMemoLine.Delete();

        // [THEN] The posted credit memo line has no attributes
        Assert.AreEqual(0, TestLib.CountLineAttributes(Database::"Sales Cr.Memo Line", 0, CrMemoNo, 0, 0, SalesLine."Line No."), AttributeCountMsg);
    end;

    [Test]
    procedure DeletePostedReturnReceiptLine_DeletesItsAttributes()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReturnReceiptLine: Record "Return Receipt Line";
    begin
        // [SCENARIO AC9] Deleting a posted return receipt line deletes its attributes.
        Initialize();

        // [GIVEN] A received sales return order whose line has 3 attributes
        CreateSalesDocumentWithAttributes(SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", 3);
        ATTTestLibrary.PostSalesDocument(SalesHeader, true, false);
        FindReturnReceiptLine(ReturnReceiptLine, SalesLine);

        // [WHEN] The posted return receipt line is deleted
        ReturnReceiptLine.Delete();

        // [THEN] The posted return receipt line has no attributes
        Assert.AreEqual(
            0, TestLib.CountLineAttributes(Database::"Return Receipt Line", 0, ReturnReceiptLine."Document No.", 0, 0, ReturnReceiptLine."Line No."),
            AttributeCountMsg);
    end;

    // AC10 - automatic copy on archive

    [Test]
    procedure ArchiveSalesOrder_CopiesAttributesToArchivedLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesHeaderArchive: Record "Sales Header Archive";
        TempExpectedDocLineAttribute: Record "ATT Document Line Attribute" temporary;
    begin
        // [SCENARIO AC10] Archiving a sales order copies the attributes of each line to the archived line.
        Initialize();

        // [GIVEN] A sales order line with 5 attributes
        CreateSalesDocumentWithAttributes(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, 5);
        TestLib.GetSalesLineAttributes(SalesLine, TempExpectedDocLineAttribute);

        // [WHEN] The sales order is archived
        ArchiveSalesDocument(SalesHeader, SalesHeaderArchive);

        // [THEN] The archived line has the same attributes, under the archive's occurrence and version
        AssertArchiveLineAttributesMatch(TempExpectedDocLineAttribute, SalesHeaderArchive, SalesLine."Line No.");
    end;

    [Test]
    procedure ArchiveSalesOrderTwice_SecondVersionGetsCurrentAttributes()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        FirstSalesHeaderArchive: Record "Sales Header Archive";
        SecondSalesHeaderArchive: Record "Sales Header Archive";
        TempExpectedDocLineAttribute: Record "ATT Document Line Attribute" temporary;
    begin
        // [SCENARIO AC3/AC10] Archiving the order again creates version 2 with the attributes the line has at that moment.
        Initialize();

        // [GIVEN] A sales order line with 3 attributes, archived once
        CreateSalesDocumentWithAttributes(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, 3);
        ArchiveSalesDocument(SalesHeader, FirstSalesHeaderArchive);

        // [GIVEN] The line gets 2 more attributes
        TestLib.CreateSalesLineAttributes(SalesLine, 2);
        TestLib.GetSalesLineAttributes(SalesLine, TempExpectedDocLineAttribute);

        // [WHEN] The sales order is archived again
        ArchiveSalesDocument(SalesHeader, SecondSalesHeaderArchive);

        // [THEN] Version 2 has the 5 current attributes
        Assert.AreEqual(FirstSalesHeaderArchive."Version No." + 1, SecondSalesHeaderArchive."Version No.", 'Version No. of the second archive.');
        AssertArchiveLineAttributesMatch(TempExpectedDocLineAttribute, SecondSalesHeaderArchive, SalesLine."Line No.");
    end;

    [Test]
    procedure ArchiveSalesOrderTwice_FirstVersionKeepsItsAttributes()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        FirstSalesHeaderArchive: Record "Sales Header Archive";
        SecondSalesHeaderArchive: Record "Sales Header Archive";
        TempExpectedDocLineAttribute: Record "ATT Document Line Attribute" temporary;
    begin
        // [SCENARIO AC3/AC10] Archiving the order again does not change the attributes of version 1.
        Initialize();

        // [GIVEN] A sales order line with 3 attributes, archived once
        CreateSalesDocumentWithAttributes(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, 3);
        TestLib.GetSalesLineAttributes(SalesLine, TempExpectedDocLineAttribute);
        ArchiveSalesDocument(SalesHeader, FirstSalesHeaderArchive);

        // [GIVEN] The line gets 2 more attributes
        TestLib.CreateSalesLineAttributes(SalesLine, 2);

        // [WHEN] The sales order is archived again
        ArchiveSalesDocument(SalesHeader, SecondSalesHeaderArchive);

        // [THEN] Version 1 still has its original 3 attributes
        AssertArchiveLineAttributesMatch(TempExpectedDocLineAttribute, FirstSalesHeaderArchive, SalesLine."Line No.");
    end;

    // AC11 - automatic copy on posting

    [Test]
    procedure PostSalesOrderShipAndInvoice_CopiesAttributesToShipmentLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesShipmentLine: Record "Sales Shipment Line";
        TempExpectedDocLineAttribute: Record "ATT Document Line Attribute" temporary;
    begin
        // [SCENARIO AC11] Posting a sales order copies the attributes of each line to the sales shipment line.
        Initialize();

        // [GIVEN] A sales order line with 4 attributes
        CreateSalesDocumentWithAttributes(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, 4);
        TestLib.GetSalesLineAttributes(SalesLine, TempExpectedDocLineAttribute);

        // [WHEN] The sales order is shipped and invoiced
        ATTTestLibrary.PostSalesDocument(SalesHeader, true, true);

        // [THEN] The shipment line has the same attributes
        FindSalesShipmentLine(SalesShipmentLine, SalesLine);
        TestLib.AssertLineAttributesMatch(
            TempExpectedDocLineAttribute, Database::"Sales Shipment Line", 0, SalesShipmentLine."Document No.", 0, 0, SalesShipmentLine."Line No.");
    end;

    [Test]
    procedure PostSalesOrderShipAndInvoice_CopiesAttributesToInvoiceLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TempExpectedDocLineAttribute: Record "ATT Document Line Attribute" temporary;
        InvoiceNo: Code[20];
    begin
        // [SCENARIO AC11] Posting a sales order copies the attributes of each line to the sales invoice line.
        Initialize();

        // [GIVEN] A sales order line with 4 attributes
        CreateSalesDocumentWithAttributes(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, 4);
        TestLib.GetSalesLineAttributes(SalesLine, TempExpectedDocLineAttribute);

        // [WHEN] The sales order is shipped and invoiced
        InvoiceNo := ATTTestLibrary.PostSalesDocument(SalesHeader, true, true);

        // [THEN] The invoice line has the same attributes
        TestLib.AssertLineAttributesMatch(TempExpectedDocLineAttribute, Database::"Sales Invoice Line", 0, InvoiceNo, 0, 0, SalesLine."Line No.");
    end;

    [Test]
    procedure PostSalesOrderShipAndInvoice_RemovesOrderLineAttributes()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [SCENARIO AC9/AC11] When a fully posted order is deleted by posting, the attributes of its lines are removed.
        Initialize();

        // [GIVEN] A sales order line with 4 attributes
        CreateSalesDocumentWithAttributes(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, 4);

        // [WHEN] The sales order is shipped and invoiced completely
        ATTTestLibrary.PostSalesDocument(SalesHeader, true, true);

        // [THEN] The order line has no attributes any more
        Assert.AreEqual(0, TestLib.CountSalesLineAttributes(SalesLine), AttributeCountMsg);
    end;

    [Test]
    procedure PostSalesCreditMemo_CopiesAttributesToCrMemoLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TempExpectedDocLineAttribute: Record "ATT Document Line Attribute" temporary;
        CrMemoNo: Code[20];
    begin
        // [SCENARIO AC11] Posting a sales credit memo copies the attributes of each line to the sales credit memo line.
        Initialize();

        // [GIVEN] A sales credit memo line with 4 attributes
        CreateSalesDocumentWithAttributes(SalesHeader, SalesLine, SalesHeader."Document Type"::"Credit Memo", 4);
        TestLib.GetSalesLineAttributes(SalesLine, TempExpectedDocLineAttribute);

        // [WHEN] The credit memo is posted
        CrMemoNo := ATTTestLibrary.PostSalesDocument(SalesHeader, true, true);

        // [THEN] The credit memo line has the same attributes
        TestLib.AssertLineAttributesMatch(TempExpectedDocLineAttribute, Database::"Sales Cr.Memo Line", 0, CrMemoNo, 0, 0, SalesLine."Line No.");
    end;

    [Test]
    procedure ReceiveSalesReturnOrder_CopiesAttributesToReturnReceiptLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReturnReceiptLine: Record "Return Receipt Line";
        TempExpectedDocLineAttribute: Record "ATT Document Line Attribute" temporary;
    begin
        // [SCENARIO AC11] Receiving a sales return order copies the attributes of each line to the return receipt line.
        Initialize();

        // [GIVEN] A sales return order line with 4 attributes
        CreateSalesDocumentWithAttributes(SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", 4);
        TestLib.GetSalesLineAttributes(SalesLine, TempExpectedDocLineAttribute);

        // [WHEN] The return order is received
        ATTTestLibrary.PostSalesDocument(SalesHeader, true, false);

        // [THEN] The return receipt line has the same attributes
        FindReturnReceiptLine(ReturnReceiptLine, SalesLine);
        TestLib.AssertLineAttributesMatch(
            TempExpectedDocLineAttribute, Database::"Return Receipt Line", 0, ReturnReceiptLine."Document No.", 0, 0, ReturnReceiptLine."Line No.");
    end;

    // AC7 - document type

    [Test]
    procedure ArchiveSalesOrder_ArchivedAttributesHaveOrderDocumentType()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesHeaderArchive: Record "Sales Header Archive";
        DocLineAttribute: Record "ATT Document Line Attribute";
    begin
        // [SCENARIO AC7] For Sales Line Archive, Document Type holds the ordinal of the line's Sales Document Type.
        Initialize();

        // [GIVEN] A sales order line with 2 attributes
        CreateSalesDocumentWithAttributes(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, 2);

        // [WHEN] The sales order is archived
        ArchiveSalesDocument(SalesHeader, SalesHeaderArchive);

        // [THEN] The archived attributes have Document Type = Order
        DocLineAttribute.SetRange("Table ID", Database::"Sales Line Archive");
        DocLineAttribute.SetRange("Document No.", SalesHeaderArchive."No.");
        DocLineAttribute.SetRange("Version No.", SalesHeaderArchive."Version No.");
        DocLineAttribute.FindFirst();
        Assert.AreEqual("Sales Document Type"::Order.AsInteger(), DocLineAttribute."Document Type", DocumentTypeMsg);
    end;

    [Test]
    procedure ReceiveSalesReturnOrder_ReturnReceiptAttributesHaveDocumentTypeZero()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReturnReceiptLine: Record "Return Receipt Line";
        DocLineAttribute: Record "ATT Document Line Attribute";
    begin
        // [SCENARIO AC7] For posted lines, Document Type is 0, even when the source line has another document type.
        Initialize();

        // [GIVEN] A sales return order line with 2 attributes
        CreateSalesDocumentWithAttributes(SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", 2);

        // [WHEN] The return order is received
        ATTTestLibrary.PostSalesDocument(SalesHeader, true, false);

        // [THEN] The attributes of the return receipt line have Document Type 0
        FindReturnReceiptLine(ReturnReceiptLine, SalesLine);
        DocLineAttribute.SetRange("Table ID", Database::"Return Receipt Line");
        DocLineAttribute.SetRange("Document No.", ReturnReceiptLine."Document No.");
        DocLineAttribute.FindFirst();
        Assert.AreEqual(0, DocLineAttribute."Document Type", DocumentTypeMsg);
    end;

    [Test]
    procedure CopyAttributesToReturnOrderLine_StoresReturnOrderDocumentType()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReturnSalesHeader: Record "Sales Header";
        ReturnSalesLine: Record "Sales Line";
        DocLineAttributeMgt: Codeunit "ATT Doc. Line Attribute Mgt.";
    begin
        // [SCENARIO AC7] For Sales Line, Document Type holds the ordinal of the line's Sales Document Type.
        Initialize();

        // [GIVEN] A sales order line with 2 attributes and a sales return order line without attributes
        CreateSalesDocumentWithAttributes(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, 2);
        CreateSalesDocumentWithAttributes(ReturnSalesHeader, ReturnSalesLine, ReturnSalesHeader."Document Type"::"Return Order", 0);

        // [WHEN] The attributes are copied to the return order line
        DocLineAttributeMgt.CopyAttributes(SalesLine, ReturnSalesLine);

        // [THEN] The return order line has the 2 attributes stored under Document Type = Return Order
        Assert.AreEqual(
            2,
            TestLib.CountLineAttributes(
                Database::"Sales Line", "Sales Document Type"::"Return Order".AsInteger(), ReturnSalesLine."Document No.", 0, 0, ReturnSalesLine."Line No."),
            AttributeCountMsg);
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        ATTTestLibrary.SetStockoutWarning(false);
        ATTTestLibrary.SetCreditWarningsToNoWarnings();
        ATTTestLibrary.SetExactCostReversingMandatory(false);
        ATTTestLibrary.InitializePostingSetup();

        IsInitialized := true;
        Commit();
    end;

    local procedure CreateSalesDocumentWithAttributes(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; NumberOfAttributes: Integer)
    begin
        ATTTestLibrary.CreateSalesHeader(SalesHeader, DocumentType, ATTTestLibrary.CreateCustomerNo());
        CreateSalesLineWithAttributes(SalesLine, SalesHeader, NumberOfAttributes);
    end;

    local procedure CreateSalesLineWithAttributes(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; NumberOfAttributes: Integer)
    begin
        ATTTestLibrary.CreateSalesLine(
            SalesLine, SalesHeader, SalesLine.Type::Item, ATTTestLibrary.CreateItemNo(), Any.IntegerInRange(1, 10));
        TestLib.CreateSalesLineAttributes(SalesLine, NumberOfAttributes);
    end;

    local procedure ArchiveSalesDocument(var SalesHeader: Record "Sales Header"; var SalesHeaderArchive: Record "Sales Header Archive")
    begin
        ArchiveManagement.StoreSalesDocument(SalesHeader, false);

        SalesHeaderArchive.SetRange("Document Type", SalesHeader."Document Type");
        SalesHeaderArchive.SetRange("No.", SalesHeader."No.");
        SalesHeaderArchive.SetRange("Doc. No. Occurrence", SalesHeader."Doc. No. Occurrence");
        SalesHeaderArchive.FindLast();
    end;

    local procedure CountArchiveLineAttributes(SalesHeaderArchive: Record "Sales Header Archive"; LineNo: Integer): Integer
    begin
        exit(
            TestLib.CountLineAttributes(
                Database::"Sales Line Archive", SalesHeaderArchive."Document Type".AsInteger(), SalesHeaderArchive."No.",
                SalesHeaderArchive."Doc. No. Occurrence", SalesHeaderArchive."Version No.", LineNo));
    end;

    local procedure AssertArchiveLineAttributesMatch(var TempExpectedDocLineAttribute: Record "ATT Document Line Attribute" temporary; SalesHeaderArchive: Record "Sales Header Archive"; LineNo: Integer)
    begin
        TestLib.AssertLineAttributesMatch(
            TempExpectedDocLineAttribute, Database::"Sales Line Archive", SalesHeaderArchive."Document Type".AsInteger(), SalesHeaderArchive."No.",
            SalesHeaderArchive."Doc. No. Occurrence", SalesHeaderArchive."Version No.", LineNo);
    end;

    local procedure FindSalesShipmentLine(var SalesShipmentLine: Record "Sales Shipment Line"; SalesLine: Record "Sales Line")
    begin
        SalesShipmentLine.SetRange("Order No.", SalesLine."Document No.");
        SalesShipmentLine.SetRange("Order Line No.", SalesLine."Line No.");
        SalesShipmentLine.FindFirst();
    end;

    local procedure FindReturnReceiptLine(var ReturnReceiptLine: Record "Return Receipt Line"; SalesLine: Record "Sales Line")
    begin
        ReturnReceiptLine.SetRange("Return Order No.", SalesLine."Document No.");
        ReturnReceiptLine.SetRange("Return Order Line No.", SalesLine."Line No.");
        ReturnReceiptLine.FindFirst();
    end;
}
