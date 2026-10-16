namespace Attitutor.CustomerExtensions.PermissionTest.DocumentLineAttribute;

using Attitutor.CustomerExtensions.DocumentLineAttribute;
using Microsoft.Sales.Archive;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Utilities;
using System.TestLibraries.Security.AccessControl;
using System.TestLibraries.Utilities;

/// <summary>
/// Tests that users with only the standard sales permission sets, without ATT CUSTOM, can post, delete and archive sales documents
/// that have document line attributes (CU-123x5y65gje, inherent permissions on the subscribers).
/// </summary>
/// <remarks>
/// Container only: uses Library - Lower Permissions and the other libraries of Tests-TestLibraries, which are not available in an
/// online sandbox. The sandbox test app (Customer Extensions Test) only checks the ATT CUSTOM permission set metadata.
/// </remarks>
codeunit 50180 "ATT DLA Lowered Perm. Test"
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
        TestLib: Codeunit "ATT DLA Perm. Test Lib.";
        PermissionsMock: Codeunit "Permissions Mock";
        IsInitialized: Boolean;
        AttributeCountMsg: Label 'Number of attributes on the line.';
        PermissionsMockNotStartedMsg: Label 'The permissions mock is not running, so the permissions cannot be lowered. Run these tests in a container with a test runner that supports TestPermissions.';

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
        LowerPermissionsToSalesDocsPost();
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
        LowerPermissionsToSalesDocsPost();
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
        LowerPermissionsToSalesDocsCreate();
        SalesLine.Delete(true);

        // [THEN] The line has no attributes
        LibraryLowerPermissions.SetOutsideO365Scope();
        Assert.AreEqual(0, TestLib.CountSalesLineAttributes(SalesLine), AttributeCountMsg);
    end;

    [Test]
    procedure ArchiveSalesOrderAsSalesUser_CopiesAttributesToArchivedLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesHeaderArchive: Record "Sales Header Archive";
        TempExpectedDocLineAttribute: Record "ATT Document Line Attribute" temporary;
        ArchiveManagement: Codeunit ArchiveManagement;
    begin
        // [SCENARIO B1] A sales user without ATT CUSTOM archives an order; the attributes are copied to the archived line.
        Initialize();

        // [GIVEN] A sales order line with 3 attributes
        LibraryLowerPermissions.SetOutsideO365Scope();
        CreateSalesOrderWithAttributes(SalesHeader, SalesLine, 3);
        TestLib.GetSalesLineAttributes(SalesLine, TempExpectedDocLineAttribute);

        // [WHEN] A user with only the sales document permission sets archives the order
        LowerPermissionsToSalesDocsCreate();
        ArchiveManagement.StoreSalesDocument(SalesHeader, false);

        // [THEN] The archived line has the same attributes, under the archive's occurrence and version
        LibraryLowerPermissions.SetOutsideO365Scope();
        FindSalesHeaderArchive(SalesHeaderArchive, SalesHeader);
        TestLib.AssertLineAttributesMatch(
            TempExpectedDocLineAttribute, Database::"Sales Line Archive", SalesHeaderArchive."Document Type".AsInteger(), SalesHeaderArchive."No.",
            SalesHeaderArchive."Doc. No. Occurrence", SalesHeaderArchive."Version No.", SalesLine."Line No.");
    end;

    [Test]
    procedure DeleteSalesOrderArchiveAsSalesUser_DeletesArchivedAttributes()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesHeaderArchive: Record "Sales Header Archive";
        ArchiveManagement: Codeunit ArchiveManagement;
    begin
        // [SCENARIO B1] A sales user without ATT CUSTOM deletes an archived order; the attributes of its archived lines are deleted.
        Initialize();

        // [GIVEN] An archived sales order whose line has 3 attributes
        LibraryLowerPermissions.SetOutsideO365Scope();
        CreateSalesOrderWithAttributes(SalesHeader, SalesLine, 3);
        ArchiveManagement.StoreSalesDocument(SalesHeader, false);
        FindSalesHeaderArchive(SalesHeaderArchive, SalesHeader);

        // [WHEN] A user with only the sales document permission sets deletes the archived order
        LowerPermissionsToSalesDocsCreate();
        SalesHeaderArchive.Delete(true);

        // [THEN] The archived line has no attributes
        LibraryLowerPermissions.SetOutsideO365Scope();
        Assert.AreEqual(
            0,
            TestLib.CountLineAttributes(
                Database::"Sales Line Archive", SalesHeaderArchive."Document Type".AsInteger(), SalesHeaderArchive."No.",
                SalesHeaderArchive."Doc. No. Occurrence", SalesHeaderArchive."Version No.", SalesLine."Line No."),
            AttributeCountMsg);
    end;

    local procedure LowerPermissionsToSalesDocsPost()
    begin
        LibraryLowerPermissions.SetSalesDocsPost();
        AssertPermissionsMockIsStarted();
    end;

    local procedure LowerPermissionsToSalesDocsCreate()
    begin
        LibraryLowerPermissions.SetSalesDocsCreate();
        AssertPermissionsMockIsStarted();
    end;

    local procedure AssertPermissionsMockIsStarted()
    begin
        // Without a running permissions mock the test would run with full permissions and pass without testing anything.
        Assert.IsTrue(PermissionsMock.IsStarted(), PermissionsMockNotStartedMsg);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"ATT DLA Lowered Perm. Test");
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"ATT DLA Lowered Perm. Test");
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibrarySales.SetStockoutWarning(false);
        LibrarySales.SetCreditWarningsToNoWarnings();

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"ATT DLA Lowered Perm. Test");
    end;

    local procedure CreateSalesOrderWithAttributes(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; NumberOfAttributes: Integer)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(
            SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandIntInRange(1, 10));
        TestLib.CreateSalesLineAttributes(SalesLine, NumberOfAttributes);
    end;

    local procedure FindSalesHeaderArchive(var SalesHeaderArchive: Record "Sales Header Archive"; SalesHeader: Record "Sales Header")
    begin
        SalesHeaderArchive.SetRange("Document Type", SalesHeader."Document Type");
        SalesHeaderArchive.SetRange("No.", SalesHeader."No.");
        SalesHeaderArchive.SetRange("Doc. No. Occurrence", SalesHeader."Doc. No. Occurrence");
        SalesHeaderArchive.FindLast();
    end;
}
