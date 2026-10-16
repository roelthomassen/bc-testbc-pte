namespace Attitutor.CustomerExtensions.Test.DocumentLineAttribute;

using Attitutor.CustomerExtensions.DocumentLineAttribute;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using System.TestLibraries.Utilities;

/// <summary>
/// Tests that users with only the standard sales permission sets, without ATT CUSTOM, can post and delete sales lines
/// that have document line attributes (CU-123x5y65gje, inherent permissions on the subscribers).
/// </summary>
codeunit 50153 "ATT Doc. Line Attr. Perm. Test"
{
    Subtype = Test;
    TestPermissions = Restrictive;

    // [FEATURE] [Document Line Attribute] [Permissions]

    var
        Assert: Codeunit "Library Assert";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        TestLib: Codeunit "ATT Doc. Line Attr. Test Lib.";
        IsInitialized: Boolean;
        AttributeCountMsg: Label 'Number of attributes on the line.';

    [Test]
    procedure PostSalesOrderAsSalesUser_CopiesAttributesToInvoiceLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TempExpectedDocLineAttribute: Record "ATT Document Line Attribute" temporary;
        InvoiceNo: Code[20];
    begin
        // [SCENARIO B1] A sales user without ATT CUSTOM posts an order; the attributes are copied to the posted invoice line.
        Initialize();

        // [GIVEN] A sales order line with 3 attributes
        LibraryLowerPermissions.SetOutsideO365Scope();
        CreateSalesOrderWithAttributes(SalesHeader, SalesLine, 3);
        TestLib.GetSalesLineAttributes(SalesLine, TempExpectedDocLineAttribute);

        // [WHEN] A user with only the sales posting permission sets ships and invoices the order
        LibraryLowerPermissions.SetSalesDocsPost();
        InvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] The posted invoice line has the same attributes
        LibraryLowerPermissions.SetOutsideO365Scope();
        TestLib.AssertLineAttributesMatch(TempExpectedDocLineAttribute, Database::"Sales Invoice Line", 0, InvoiceNo, 0, 0, SalesLine."Line No.");
    end;

    [Test]
    procedure PostSalesOrderAsSalesUser_RemovesOrderLineAttributes()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [SCENARIO B1] A sales user without ATT CUSTOM posts an order completely; the attributes of the order line are removed.
        Initialize();

        // [GIVEN] A sales order line with 3 attributes
        LibraryLowerPermissions.SetOutsideO365Scope();
        CreateSalesOrderWithAttributes(SalesHeader, SalesLine, 3);

        // [WHEN] A user with only the sales posting permission sets ships and invoices the order
        LibraryLowerPermissions.SetSalesDocsPost();
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] The order line has no attributes any more
        LibraryLowerPermissions.SetOutsideO365Scope();
        Assert.AreEqual(0, TestLib.CountSalesLineAttributes(SalesLine), AttributeCountMsg);
    end;

    [Test]
    procedure DeleteSalesLineAsSalesUser_DeletesItsAttributes()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [SCENARIO B1] A sales user without ATT CUSTOM deletes a sales line; its attributes are deleted.
        Initialize();

        // [GIVEN] A sales order line with 3 attributes
        LibraryLowerPermissions.SetOutsideO365Scope();
        CreateSalesOrderWithAttributes(SalesHeader, SalesLine, 3);

        // [WHEN] A user with only the sales document permission sets deletes the line
        LibraryLowerPermissions.SetSalesDocsCreate();
        SalesLine.Delete(true);

        // [THEN] The line has no attributes
        LibraryLowerPermissions.SetOutsideO365Scope();
        Assert.AreEqual(0, TestLib.CountSalesLineAttributes(SalesLine), AttributeCountMsg);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"ATT Doc. Line Attr. Perm. Test");
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"ATT Doc. Line Attr. Perm. Test");
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibrarySales.SetStockoutWarning(false);
        LibrarySales.SetCreditWarningsToNoWarnings();

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"ATT Doc. Line Attr. Perm. Test");
    end;

    local procedure CreateSalesOrderWithAttributes(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; NumberOfAttributes: Integer)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(
            SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandIntInRange(1, 10));
        TestLib.CreateSalesLineAttributes(SalesLine, NumberOfAttributes);
    end;
}
