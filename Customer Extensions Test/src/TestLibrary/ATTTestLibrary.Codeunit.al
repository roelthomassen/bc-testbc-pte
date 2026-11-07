namespace Attitutor.CustomerExtensions.Test.TestLibrary;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Attribute;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Setup;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.Posting;
using Microsoft.Sales.Setup;
using Microsoft.Warehouse.Setup;
using System.Security.User;
using System.TestLibraries.Utilities;

/// <summary>
/// Creates the master data and sales documents the tests of this app need, and posts sales documents.
/// Replaces the Library - Sales, Library - Inventory and Library - Utility codeunits of Tests-TestLibraries,
/// which are not available in an online sandbox.
/// </summary>
/// <remarks>
/// The library creates its own posting setup (G/L accounts, posting groups, posting setups, unit of measure and, when needed,
/// a location) the first time it is needed, and makes sure the work date can be posted on. All of this happens in the test
/// transaction, so the test runner must roll it back: use runner 130450 "Test Runner - Isol. Codeunit" in a dedicated test company.
/// Document numbers still come from the number series of the company; a clear error is raised when a required one is missing.
/// </remarks>
codeunit 50154 "ATT Test Library"
{
    var
        Any: Codeunit Any;
        GenBusPostingGroupCode: Code[20];
        GenProdPostingGroupCode: Code[20];
        VATBusPostingGroupCode: Code[20];
        VATProdPostingGroupCode: Code[20];
        CustomerPostingGroupCode: Code[20];
        InventoryPostingGroupCode: Code[20];
        UnitOfMeasureCode: Code[10];
        PostingLocationCode: Code[10];
        PostingSetupCreated: Boolean;
        NoSeriesMissingErr: Label '%1 must be filled in with an existing number series in %2 to run the tests.', Comment = '%1 = field caption, %2 = table caption';
        TemplateNoSeriesMissingErr: Label '%1 must be filled in with an existing number series in %2 %3 to run the tests.', Comment = '%1 = field caption, %2 = table caption, %3 = journal template name';
        PostedDocumentNoNotFoundErr: Label 'Posting %1 %2 did not return a posted document number.', Comment = '%1 = document type, %2 = document number';
        StandardVATTaxCategoryTxt: Label 'S', Locked = true;

    /// <summary>
    /// Creates the posting setup the library owns, unless it already exists in the current transaction, and makes sure the work date can be posted on.
    /// Call it from the Initialize procedure of a test codeunit, before its Commit.
    /// </summary>
    procedure InitializePostingSetup()
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        if PostingSetupCreated then
            if GeneralPostingSetup.Get(GenBusPostingGroupCode, GenProdPostingGroupCode) then
                exit;

        CreatePostingSetup();
        AllowPostingOnWorkDate();
        EnsureSalesJournalTemplates();
        PostingSetupCreated := true;
    end;

    /// <summary>
    /// Returns a new code of 20 characters that is unique for all practical purposes. Use it for primary keys that must not collide with existing data.
    /// </summary>
    /// <returns>A unique code of 20 characters.</returns>
    procedure GenerateUniqueCode(): Code[20]
    begin
        exit(CopyStr(GetGuidCharacters(), 1, 20));
    end;

    /// <summary>
    /// Creates an item that can be sold and posted, with the library's unit of measure and posting groups, a random unit price and a random unit cost.
    /// </summary>
    /// <param name="Item">Returns the created item.</param>
    procedure CreateItem(var Item: Record Item)
    begin
        InitializePostingSetup();

        Item.Init();
        Item."No." := GenerateUniqueCode();
        Item.Insert(true);

        CreateItemUnitOfMeasure(Item."No.");
        Item.Validate(Description, Item."No.");
        Item.Validate("Base Unit of Measure", UnitOfMeasureCode);
        Item.Validate("Gen. Prod. Posting Group", GenProdPostingGroupCode);
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroupCode);
        Item.Validate("Inventory Posting Group", InventoryPostingGroupCode);
        Item.Validate("Unit Price", Any.DecimalInRange(1, 1000, 2));
        Item.Validate("Unit Cost", Any.DecimalInRange(1, 1000, 2));
        Item.Validate("Prevent Negative Inventory", Item."Prevent Negative Inventory"::No);
        Item.Modify(true);
    end;

    /// <summary>
    /// Creates an item that can be sold and posted and returns its number.
    /// </summary>
    /// <returns>The number of the created item.</returns>
    procedure CreateItemNo(): Code[20]
    var
        Item: Record Item;
    begin
        CreateItem(Item);
        exit(Item."No.");
    end;

    /// <summary>
    /// Creates an item category with a unique code.
    /// </summary>
    /// <param name="ItemCategory">Returns the created item category.</param>
    procedure CreateItemCategory(var ItemCategory: Record "Item Category")
    begin
        ItemCategory.Init();
        ItemCategory.Validate(Code, GenerateUniqueCode());
        ItemCategory.Insert(true);
    end;

    /// <summary>
    /// Sets the item category of an item.
    /// </summary>
    /// <param name="Item">The item to set the category on. Returns the item as it was after the change.</param>
    /// <param name="CategoryCode">The code of the item category.</param>
    procedure SetItemCategory(var Item: Record Item; CategoryCode: Code[20])
    begin
        Item.Validate("Item Category Code", CategoryCode);
        Item.Modify(true);
    end;

    /// <summary>
    /// Creates a customer that can be invoiced, with the library's posting groups.
    /// </summary>
    /// <param name="Customer">Returns the created customer.</param>
    procedure CreateCustomer(var Customer: Record Customer)
    begin
        InitializePostingSetup();

        Customer.Init();
        Customer."No." := GenerateUniqueCode();
        Customer.Insert(true);

        Customer.Validate(Name, Customer."No.");
        Customer.Validate("Gen. Bus. Posting Group", GenBusPostingGroupCode);
        Customer.Validate("VAT Bus. Posting Group", VATBusPostingGroupCode);
        Customer.Validate("Customer Posting Group", CustomerPostingGroupCode);
        Customer.Modify(true);
    end;

    /// <summary>
    /// Creates a customer that can be invoiced and returns its number.
    /// </summary>
    /// <returns>The number of the created customer.</returns>
    procedure CreateCustomerNo(): Code[20]
    var
        Customer: Record Customer;
    begin
        CreateCustomer(Customer);
        exit(Customer."No.");
    end;

    /// <summary>
    /// Creates a sales document header of the given type for the given customer. The document number comes from the number series in the Sales &amp; Receivables Setup.
    /// </summary>
    /// <param name="SalesHeader">Returns the created sales header.</param>
    /// <param name="DocumentType">The type of the sales document.</param>
    /// <param name="CustomerNo">The number of the sell-to customer.</param>
    procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20])
    begin
        InitializePostingSetup();
        CheckSalesNoSeries(DocumentType);

        SalesHeader.Init();
        SalesHeader.Validate("Document Type", DocumentType);
        SalesHeader.Insert(true);

        SalesHeader.Validate("Sell-to Customer No.", CustomerNo);
        SalesHeader.Validate("External Document No.", GenerateUniqueCode());
        if SalesHeader."Location Code" <> PostingLocationCode then
            SalesHeader.Validate("Location Code", PostingLocationCode);
        SalesHeader.Modify(true);
    end;

    /// <summary>
    /// Creates a sales line at the end of the given sales document.
    /// </summary>
    /// <param name="SalesLine">Returns the created sales line.</param>
    /// <param name="SalesHeader">The sales document to add the line to.</param>
    /// <param name="LineType">The type of the line.</param>
    /// <param name="No">The number of the item, resource, account or other entity on the line.</param>
    /// <param name="Quantity">The quantity of the line.</param>
    procedure CreateSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; LineType: Enum "Sales Line Type"; No: Code[20]; Quantity: Decimal)
    begin
        SalesLine.Init();
        SalesLine.Validate("Document Type", SalesHeader."Document Type");
        SalesLine.Validate("Document No.", SalesHeader."No.");
        SalesLine."Line No." := GetNextSalesLineNo(SalesHeader);
        SalesLine.Insert(true);

        SalesLine.Validate(Type, LineType);
        SalesLine.Validate("No.", No);
        SalesLine.Validate(Quantity, Quantity);
        SalesLine.Modify(true);
    end;

    /// <summary>
    /// Creates a sales document of the given type for a new customer, with one line for a new item and a random quantity.
    /// </summary>
    /// <param name="SalesHeader">Returns the created sales header.</param>
    /// <param name="SalesLine">Returns the created sales line.</param>
    /// <param name="DocumentType">The type of the sales document.</param>
    procedure CreateSalesDocumentWithItem(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type")
    begin
        CreateSalesHeader(SalesHeader, DocumentType, CreateCustomerNo());
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItemNo(), Any.IntegerInRange(1, 10));
    end;

    /// <summary>
    /// Posts a sales document with the Sales-Post codeunit and returns the number of the posted document.
    /// </summary>
    /// <param name="SalesHeader">The sales document to post. Returns the header as it was after posting.</param>
    /// <param name="ShipReceive">Ship (orders) or receive (return orders) the document.</param>
    /// <param name="Invoice">Invoice the document.</param>
    /// <returns>The number of the posted invoice or credit memo when the document is invoiced; otherwise the number of the posted shipment or return receipt.</returns>
    procedure PostSalesDocument(var SalesHeader: Record "Sales Header"; ShipReceive: Boolean; Invoice: Boolean): Code[20]
    var
        SalesPost: Codeunit "Sales-Post";
        DocumentType: Enum "Sales Document Type";
        DocumentNo: Code[20];
        PostedDocumentNo: Code[20];
    begin
        DocumentType := SalesHeader."Document Type";
        DocumentNo := SalesHeader."No.";

        SalesHeader.Ship := ShipReceive;
        SalesHeader.Receive := ShipReceive;
        SalesHeader.Invoice := Invoice;
        SalesPost.Run(SalesHeader);

        PostedDocumentNo := GetLastPostedDocumentNo(SalesHeader, ShipReceive, Invoice);
        if PostedDocumentNo = '' then
            Error(PostedDocumentNoNotFoundErr, DocumentType, DocumentNo);
        exit(PostedDocumentNo);
    end;

    /// <summary>
    /// Creates an item attribute of type Option with a unique name and the given unit of measure.
    /// </summary>
    /// <param name="ItemAttribute">Returns the created item attribute.</param>
    /// <param name="UnitOfMeasure">The unit of measure of the item attribute.</param>
    procedure CreateItemAttribute(var ItemAttribute: Record "Item Attribute"; UnitOfMeasure: Text[30])
    begin
        ItemAttribute.Init();
        ItemAttribute.Validate(Name, GenerateUniqueCode());
        ItemAttribute.Validate(Type, ItemAttribute.Type::Option);
        ItemAttribute.Validate("Unit of Measure", UnitOfMeasure);
        ItemAttribute.Insert(true);
    end;

    /// <summary>
    /// Creates a value for the given item attribute.
    /// </summary>
    /// <param name="ItemAttributeValue">Returns the created item attribute value.</param>
    /// <param name="AttributeId">The ID of the item attribute.</param>
    /// <param name="ValueText">The text of the value.</param>
    procedure CreateItemAttributeValue(var ItemAttributeValue: Record "Item Attribute Value"; AttributeId: Integer; ValueText: Text[250])
    begin
        Clear(ItemAttributeValue);
        ItemAttributeValue.Validate("Attribute ID", AttributeId);
        ItemAttributeValue.Validate(Value, ValueText);
        ItemAttributeValue.Insert(true);
    end;

    /// <summary>
    /// Turns the stockout warning in the Sales &amp; Receivables Setup on or off.
    /// </summary>
    /// <param name="StockoutWarning">The new value of Stockout Warning.</param>
    procedure SetStockoutWarning(StockoutWarning: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        if SalesReceivablesSetup."Stockout Warning" = StockoutWarning then
            exit;

        SalesReceivablesSetup.Validate("Stockout Warning", StockoutWarning);
        SalesReceivablesSetup.Modify(true);
    end;

    /// <summary>
    /// Turns off the credit limit and overdue balance warnings in the Sales &amp; Receivables Setup.
    /// </summary>
    procedure SetCreditWarningsToNoWarnings()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        if SalesReceivablesSetup."Credit Warnings" = SalesReceivablesSetup."Credit Warnings"::"No Warning" then
            exit;

        SalesReceivablesSetup.Validate("Credit Warnings", SalesReceivablesSetup."Credit Warnings"::"No Warning");
        SalesReceivablesSetup.Modify(true);
    end;

    /// <summary>
    /// Turns Exact Cost Reversing Mandatory in the Sales &amp; Receivables Setup on or off.
    /// </summary>
    /// <param name="ExactCostReversingMandatory">The new value of Exact Cost Reversing Mandatory.</param>
    procedure SetExactCostReversingMandatory(ExactCostReversingMandatory: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        if SalesReceivablesSetup."Exact Cost Reversing Mandatory" = ExactCostReversingMandatory then
            exit;

        SalesReceivablesSetup.Validate("Exact Cost Reversing Mandatory", ExactCostReversingMandatory);
        SalesReceivablesSetup.Modify(true);
    end;

    #region Posting setup

    local procedure CreatePostingSetup()
    var
        IncomeAccountNo: Code[20];
        CostAccountNo: Code[20];
        InterimAccountNo: Code[20];
        InventoryAccountNo: Code[20];
        ReceivablesAccountNo: Code[20];
        VATAccountNo: Code[20];
    begin
        IncomeAccountNo := CreateGLAccount(false, true);
        CostAccountNo := CreateGLAccount(false, true);
        InterimAccountNo := CreateGLAccount(true, false);
        InventoryAccountNo := CreateGLAccount(true, false);
        ReceivablesAccountNo := CreateGLAccount(true, false);
        VATAccountNo := CreateGLAccount(true, false);

        CreateVATPostingSetup(VATAccountNo);
        CreateGeneralPostingSetup(IncomeAccountNo, CostAccountNo, InterimAccountNo);
        // Customer Posting Group requires a Gen. Prod. Posting Group on the Invoice Rounding Account, so it gets its own account
        // with the library's posting groups; invoice rounding lines then post with the library's General and VAT Posting Setup.
        CreateCustomerPostingGroup(ReceivablesAccountNo, CreateGLAccountWithPostingGroups());
        PostingLocationCode := CreatePostingLocationIfNeeded();
        CreateInventoryPostingSetup(InventoryAccountNo, InterimAccountNo);
        CreateUnitOfMeasure();
    end;

    local procedure CreateGLAccount(IsBalanceSheet: Boolean; DirectPosting: Boolean): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        InsertGLAccount(GLAccount, IsBalanceSheet, DirectPosting);
        exit(GLAccount."No.");
    end;

    local procedure CreateGLAccountWithPostingGroups(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        InsertGLAccount(GLAccount, false, false);
        GLAccount.Validate("Gen. Prod. Posting Group", GenProdPostingGroupCode);
        GLAccount.Validate("VAT Prod. Posting Group", VATProdPostingGroupCode);
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure InsertGLAccount(var GLAccount: Record "G/L Account"; IsBalanceSheet: Boolean; DirectPosting: Boolean)
    begin
        GLAccount.Init();
        GLAccount."No." := GenerateUniqueCode();
        GLAccount.Insert(true);

        GLAccount.Validate(Name, GLAccount."No.");
        GLAccount.Validate("Account Type", GLAccount."Account Type"::Posting);
        if IsBalanceSheet then
            GLAccount.Validate("Income/Balance", GLAccount."Income/Balance"::"Balance Sheet")
        else
            GLAccount.Validate("Income/Balance", GLAccount."Income/Balance"::"Income Statement");
        GLAccount.Validate("Direct Posting", DirectPosting);
        GLAccount.Validate(Blocked, false);
        GLAccount.Modify(true);
    end;

    local procedure CreateVATPostingSetup(VATAccountNo: Code[20])
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATBusinessPostingGroup.Init();
        VATBusinessPostingGroup.Code := GenerateUniqueCode();
        VATBusinessPostingGroup.Description := VATBusinessPostingGroup.Code;
        VATBusinessPostingGroup.Insert(true);
        VATBusPostingGroupCode := VATBusinessPostingGroup.Code;

        VATProductPostingGroup.Init();
        VATProductPostingGroup.Code := GenerateUniqueCode();
        VATProductPostingGroup.Description := VATProductPostingGroup.Code;
        VATProductPostingGroup.Insert(true);
        VATProdPostingGroupCode := VATProductPostingGroup.Code;

        VATPostingSetup.Init();
        VATPostingSetup.Validate("VAT Bus. Posting Group", VATBusPostingGroupCode);
        VATPostingSetup.Validate("VAT Prod. Posting Group", VATProdPostingGroupCode);
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.Validate("VAT %", 21);
        VATPostingSetup.Validate("VAT Identifier", GenerateUniqueCode());
        VATPostingSetup.Validate("Tax Category", StandardVATTaxCategoryTxt);
        VATPostingSetup.Validate("Sales VAT Account", VATAccountNo);
        VATPostingSetup.Validate("Purchase VAT Account", VATAccountNo);
        VATPostingSetup.Insert(true);
    end;

    local procedure CreateGeneralPostingSetup(IncomeAccountNo: Code[20]; CostAccountNo: Code[20]; InterimAccountNo: Code[20])
    var
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GenBusinessPostingGroup.Init();
        GenBusinessPostingGroup.Code := GenerateUniqueCode();
        GenBusinessPostingGroup.Description := GenBusinessPostingGroup.Code;
        GenBusinessPostingGroup."Def. VAT Bus. Posting Group" := VATBusPostingGroupCode;
        GenBusinessPostingGroup."Auto Insert Default" := true;
        GenBusinessPostingGroup.Insert(true);
        GenBusPostingGroupCode := GenBusinessPostingGroup.Code;

        GenProductPostingGroup.Init();
        GenProductPostingGroup.Code := GenerateUniqueCode();
        GenProductPostingGroup.Description := GenProductPostingGroup.Code;
        GenProductPostingGroup."Def. VAT Prod. Posting Group" := VATProdPostingGroupCode;
        GenProductPostingGroup."Auto Insert Default" := true;
        GenProductPostingGroup.Insert(true);
        GenProdPostingGroupCode := GenProductPostingGroup.Code;

        GeneralPostingSetup.Init();
        GeneralPostingSetup.Validate("Gen. Bus. Posting Group", GenBusPostingGroupCode);
        GeneralPostingSetup.Validate("Gen. Prod. Posting Group", GenProdPostingGroupCode);
        GeneralPostingSetup.Validate("Sales Account", IncomeAccountNo);
        GeneralPostingSetup.Validate("Sales Credit Memo Account", IncomeAccountNo);
        GeneralPostingSetup.Validate("Sales Line Disc. Account", IncomeAccountNo);
        GeneralPostingSetup.Validate("Sales Inv. Disc. Account", IncomeAccountNo);
        GeneralPostingSetup.Validate("Purch. Account", CostAccountNo);
        GeneralPostingSetup.Validate("Purch. Credit Memo Account", CostAccountNo);
        GeneralPostingSetup.Validate("COGS Account", CostAccountNo);
        GeneralPostingSetup.Validate("COGS Account (Interim)", InterimAccountNo);
        GeneralPostingSetup.Validate("Inventory Adjmt. Account", CostAccountNo);
        GeneralPostingSetup.Validate("Direct Cost Applied Account", CostAccountNo);
        GeneralPostingSetup.Insert(true);
    end;

    local procedure CreateCustomerPostingGroup(ReceivablesAccountNo: Code[20]; InvoiceRoundingAccountNo: Code[20])
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        CustomerPostingGroup.Init();
        CustomerPostingGroup.Code := GenerateUniqueCode();
        CustomerPostingGroup.Description := CustomerPostingGroup.Code;
        CustomerPostingGroup.Validate("Receivables Account", ReceivablesAccountNo);
        CustomerPostingGroup.Validate("Invoice Rounding Account", InvoiceRoundingAccountNo);
        CustomerPostingGroup.Insert(true);
        CustomerPostingGroupCode := CustomerPostingGroup.Code;
    end;

    local procedure CreatePostingLocationIfNeeded(): Code[10]
    var
        Location: Record Location;
    begin
        if not IsPostingLocationNeeded() then
            exit('');

        // A new location has no warehouse handling and no bins, so sales documents can be posted on it directly.
        Location.Init();
        Location.Code := GenerateShortCode();
        Location.Name := Location.Code;
        Location.Insert(true);
        exit(Location.Code);
    end;

    local procedure IsPostingLocationNeeded(): Boolean
    var
        InventorySetup: Record "Inventory Setup";
        WarehouseSetup: Record "Warehouse Setup";
    begin
        InventorySetup.Get();
        if InventorySetup."Location Mandatory" then
            exit(true);

        // The blank location takes its warehouse handling from the Warehouse Setup.
        if not WarehouseSetup.Get() then
            exit(false);
        exit(WarehouseSetup."Require Shipment" or WarehouseSetup."Require Receive" or WarehouseSetup."Require Pick" or WarehouseSetup."Require Put-away");
    end;

    local procedure CreateInventoryPostingSetup(InventoryAccountNo: Code[20]; InterimAccountNo: Code[20])
    var
        InventoryPostingGroup: Record "Inventory Posting Group";
    begin
        InventoryPostingGroup.Init();
        InventoryPostingGroup.Code := GenerateUniqueCode();
        InventoryPostingGroup.Description := InventoryPostingGroup.Code;
        InventoryPostingGroup.Insert(true);
        InventoryPostingGroupCode := InventoryPostingGroup.Code;

        InsertInventoryPostingSetup('', InventoryAccountNo, InterimAccountNo);
        if PostingLocationCode <> '' then
            InsertInventoryPostingSetup(PostingLocationCode, InventoryAccountNo, InterimAccountNo);
    end;

    local procedure InsertInventoryPostingSetup(LocationCode: Code[10]; InventoryAccountNo: Code[20]; InterimAccountNo: Code[20])
    var
        InventoryPostingSetup: Record "Inventory Posting Setup";
    begin
        InventoryPostingSetup.Init();
        InventoryPostingSetup.Validate("Location Code", LocationCode);
        InventoryPostingSetup.Validate("Invt. Posting Group Code", InventoryPostingGroupCode);
        InventoryPostingSetup.Validate("Inventory Account", InventoryAccountNo);
        InventoryPostingSetup.Validate("Inventory Account (Interim)", InterimAccountNo);
        InventoryPostingSetup.Insert(true);
    end;

    local procedure CreateUnitOfMeasure()
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        UnitOfMeasure.Init();
        UnitOfMeasure.Code := GenerateShortCode();
        UnitOfMeasure.Description := UnitOfMeasure.Code;
        UnitOfMeasure.Insert(true);
        UnitOfMeasureCode := UnitOfMeasure.Code;
    end;

    local procedure CreateItemUnitOfMeasure(ItemNo: Code[20])
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        ItemUnitOfMeasure.Init();
        ItemUnitOfMeasure.Validate("Item No.", ItemNo);
        ItemUnitOfMeasure.Validate(Code, UnitOfMeasureCode);
        ItemUnitOfMeasure.Validate("Qty. per Unit of Measure", 1);
        ItemUnitOfMeasure.Insert(true);
    end;

    #endregion

    #region Posting date

    local procedure AllowPostingOnWorkDate()
    begin
        AllowPostingInGeneralLedgerSetup();
        AllowPostingInUserSetup();
        AllowVATDateInVATSetup();
    end;

    local procedure AllowPostingInGeneralLedgerSetup()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        BlankDateFormula: DateFormula;
    begin
        GeneralLedgerSetup.Get();
        if IsWorkDateInRange(GeneralLedgerSetup."Allow Posting From", GeneralLedgerSetup."Allow Posting To") then
            exit;

        GeneralLedgerSetup."Allow Posting From" := 0D;
        GeneralLedgerSetup."Allow Posting To" := 0D;
        GeneralLedgerSetup."Allow Posting From DateFormula" := BlankDateFormula;
        GeneralLedgerSetup."Allow Posting To DateFormula" := BlankDateFormula;
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure AllowPostingInUserSetup()
    var
        UserSetup: Record "User Setup";
        BlankDateFormula: DateFormula;
        Changed: Boolean;
    begin
        if not UserSetup.Get(UserId()) then
            exit;

        if not IsWorkDateInRange(UserSetup."Allow Posting From", UserSetup."Allow Posting To") then begin
            UserSetup."Allow Posting From" := 0D;
            UserSetup."Allow Posting To" := 0D;
            UserSetup."Allow Posting From DateFormula" := BlankDateFormula;
            UserSetup."Allow Posting To DateFormula" := BlankDateFormula;
            Changed := true;
        end;
        if not IsWorkDateInRange(UserSetup."Allow VAT Date From", UserSetup."Allow VAT Date To") then begin
            UserSetup."Allow VAT Date From" := 0D;
            UserSetup."Allow VAT Date To" := 0D;
            Changed := true;
        end;
        if Changed then
            UserSetup.Modify(true);
    end;

    local procedure AllowVATDateInVATSetup()
    var
        VATSetup: Record "VAT Setup";
    begin
        if not VATSetup.Get() then
            exit;
        if IsWorkDateInRange(VATSetup."Allow VAT Date From", VATSetup."Allow VAT Date To") then
            exit;

        VATSetup."Allow VAT Date From" := 0D;
        VATSetup."Allow VAT Date To" := 0D;
        VATSetup.Modify(true);
    end;

    local procedure IsWorkDateInRange(FromDate: Date; ToDate: Date): Boolean
    begin
        if (FromDate <> 0D) and (WorkDate() < FromDate) then
            exit(false);
        if (ToDate <> 0D) and (WorkDate() > ToDate) then
            exit(false);
        exit(true);
    end;

    #endregion

    #region Journal templates and number series

    local procedure EnsureSalesJournalTemplates()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SetupChanged: Boolean;
    begin
        // With Journal Templ. Name Mandatory (BE), sales posting takes the posted document numbers from the sales journal templates.
        GeneralLedgerSetup.Get();
        if not GeneralLedgerSetup."Journal Templ. Name Mandatory" then
            exit;

        SalesReceivablesSetup.Get();
        if EnsureSalesJournalTemplate(
            SalesReceivablesSetup."S. Invoice Template Name", SalesReceivablesSetup."Posted Invoice Nos.",
            SalesReceivablesSetup.FieldCaption("Posted Invoice Nos."))
        then
            SetupChanged := true;
        if EnsureSalesJournalTemplate(
            SalesReceivablesSetup."S. Cr. Memo Template Name", SalesReceivablesSetup."Posted Credit Memo Nos.",
            SalesReceivablesSetup.FieldCaption("Posted Credit Memo Nos."))
        then
            SetupChanged := true;
        if SetupChanged then
            SalesReceivablesSetup.Modify(true);
    end;

    /// <returns>True when a new template was created and TemplateName was changed.</returns>
    local procedure EnsureSalesJournalTemplate(var TemplateName: Code[10]; PostedNoSeriesCode: Code[20]; PostedNoSeriesCaption: Text) TemplateCreated: Boolean
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        if (TemplateName = '') or not GenJournalTemplate.Get(TemplateName) then begin
            TemplateCreated := true;
            CheckNoSeries(PostedNoSeriesCode, PostedNoSeriesCaption, SalesReceivablesSetup.TableCaption());
            GenJournalTemplate.Init();
            GenJournalTemplate.Name := GenerateShortCode();
            GenJournalTemplate.Validate(Type, GenJournalTemplate.Type::Sales);
            GenJournalTemplate.Validate("Posting No. Series", PostedNoSeriesCode);
            GenJournalTemplate.Insert(true);
            TemplateName := GenJournalTemplate.Name;
        end;

        if not ExistingNoSeries(GenJournalTemplate."Posting No. Series") then
            Error(
                TemplateNoSeriesMissingErr, GenJournalTemplate.FieldCaption("Posting No. Series"), GenJournalTemplate.TableCaption(),
                GenJournalTemplate.Name);

        if IsWorkDateInRange(GenJournalTemplate."Allow Posting Date From", GenJournalTemplate."Allow Posting Date To") then
            exit;
        GenJournalTemplate."Allow Posting Date From" := 0D;
        GenJournalTemplate."Allow Posting Date To" := 0D;
        GenJournalTemplate.Modify(true);
    end;

    local procedure CheckSalesNoSeries(DocumentType: Enum "Sales Document Type")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        PostedNoSeriesFromSetup: Boolean;
    begin
        GeneralLedgerSetup.Get();
        SalesReceivablesSetup.Get();
        // With Journal Templ. Name Mandatory, the posted invoice and credit memo numbers come from the journal templates instead.
        PostedNoSeriesFromSetup := not GeneralLedgerSetup."Journal Templ. Name Mandatory";

        case DocumentType of
            DocumentType::Order:
                begin
                    CheckSalesSetupNoSeries(SalesReceivablesSetup."Order Nos.", SalesReceivablesSetup.FieldCaption("Order Nos."));
                    CheckSalesSetupNoSeries(SalesReceivablesSetup."Posted Shipment Nos.", SalesReceivablesSetup.FieldCaption("Posted Shipment Nos."));
                    if PostedNoSeriesFromSetup then
                        CheckSalesSetupNoSeries(SalesReceivablesSetup."Posted Invoice Nos.", SalesReceivablesSetup.FieldCaption("Posted Invoice Nos."));
                end;
            DocumentType::Invoice:
                begin
                    CheckSalesSetupNoSeries(SalesReceivablesSetup."Invoice Nos.", SalesReceivablesSetup.FieldCaption("Invoice Nos."));
                    if SalesReceivablesSetup."Shipment on Invoice" then
                        CheckSalesSetupNoSeries(SalesReceivablesSetup."Posted Shipment Nos.", SalesReceivablesSetup.FieldCaption("Posted Shipment Nos."));
                    if PostedNoSeriesFromSetup then
                        CheckSalesSetupNoSeries(SalesReceivablesSetup."Posted Invoice Nos.", SalesReceivablesSetup.FieldCaption("Posted Invoice Nos."));
                end;
            DocumentType::"Credit Memo":
                begin
                    CheckSalesSetupNoSeries(SalesReceivablesSetup."Credit Memo Nos.", SalesReceivablesSetup.FieldCaption("Credit Memo Nos."));
                    if SalesReceivablesSetup."Return Receipt on Credit Memo" then
                        CheckSalesSetupNoSeries(SalesReceivablesSetup."Posted Return Receipt Nos.", SalesReceivablesSetup.FieldCaption("Posted Return Receipt Nos."));
                    if PostedNoSeriesFromSetup then
                        CheckSalesSetupNoSeries(SalesReceivablesSetup."Posted Credit Memo Nos.", SalesReceivablesSetup.FieldCaption("Posted Credit Memo Nos."));
                end;
            DocumentType::"Return Order":
                begin
                    CheckSalesSetupNoSeries(SalesReceivablesSetup."Return Order Nos.", SalesReceivablesSetup.FieldCaption("Return Order Nos."));
                    CheckSalesSetupNoSeries(SalesReceivablesSetup."Posted Return Receipt Nos.", SalesReceivablesSetup.FieldCaption("Posted Return Receipt Nos."));
                    if PostedNoSeriesFromSetup then
                        CheckSalesSetupNoSeries(SalesReceivablesSetup."Posted Credit Memo Nos.", SalesReceivablesSetup.FieldCaption("Posted Credit Memo Nos."));
                end;
        end;
    end;

    local procedure CheckSalesSetupNoSeries(NoSeriesCode: Code[20]; FieldCaption: Text)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        CheckNoSeries(NoSeriesCode, FieldCaption, SalesReceivablesSetup.TableCaption());
    end;

    local procedure CheckNoSeries(NoSeriesCode: Code[20]; FieldCaption: Text; TableCaption: Text)
    begin
        if not ExistingNoSeries(NoSeriesCode) then
            Error(NoSeriesMissingErr, FieldCaption, TableCaption);
    end;

    local procedure ExistingNoSeries(NoSeriesCode: Code[20]): Boolean
    var
        NoSeries: Record "No. Series";
    begin
        if NoSeriesCode = '' then
            exit(false);
        exit(NoSeries.Get(NoSeriesCode));
    end;

    #endregion

    local procedure GetNextSalesLineNo(SalesHeader: Record "Sales Header"): Integer
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetLoadFields("Line No.");
        if SalesLine.FindLast() then
            exit(SalesLine."Line No." + 10000);
        exit(10000);
    end;

    local procedure GetLastPostedDocumentNo(SalesHeader: Record "Sales Header"; ShipReceive: Boolean; Invoice: Boolean): Code[20]
    begin
        if Invoice then
            exit(SalesHeader."Last Posting No.");

        if not ShipReceive then
            exit('');

        case SalesHeader."Document Type" of
            SalesHeader."Document Type"::Order:
                exit(SalesHeader."Last Shipping No.");
            SalesHeader."Document Type"::"Return Order":
                exit(SalesHeader."Last Return Receipt No.");
        end;
        exit('');
    end;

    local procedure GenerateShortCode(): Code[10]
    begin
        exit(CopyStr(GetGuidCharacters(), 1, 10));
    end;

    local procedure GetGuidCharacters(): Text
    begin
        exit(DelChr(Format(CreateGuid()), '=', '{}-'));
    end;
}
