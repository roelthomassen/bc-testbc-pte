namespace Attitutor.CustomerExtensions.DocumentLineAttribute;

using Microsoft.Sales.Archive;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Posting;
using Microsoft.Utilities;

/// <summary>
/// Keeps document line attributes in sync with their lines: deletes them when a line is deleted,
/// and copies them when a sales document is archived or posted.
/// </summary>
/// <remarks>
/// The subscribers run for every user who deletes, archives or posts sales lines. They have inherent permissions on the
/// ATT Document Line Attribute table, so those users do not need the ATT CUSTOM permission set.
/// </remarks>
codeunit 50101 "ATT Doc. Line Attr. Subscr."
{
    Access = Internal;

    var
        DocLineAttributeMgt: Codeunit "ATT Doc. Line Attribute Mgt.";

    #region Delete
    // Temporary records are skipped. Because these are global OnAfterDeleteEvent subscribers, DeleteAll on these tables
    // runs row by row instead of as one bulk delete.

    [EventSubscriber(ObjectType::Table, Database::"Sales Line", OnAfterDeleteEvent, '', false, false)]
    [InherentPermissions(PermissionObjectType::TableData, Database::"ATT Document Line Attribute", 'rd')]
    local procedure DeleteAttributesOnAfterDeleteSalesLine(var Rec: Record "Sales Line")
    begin
        if Rec.IsTemporary() then
            exit;

        DocLineAttributeMgt.DeleteAttributesOfDeletedLine(Database::"Sales Line", Rec."Document Type".AsInteger(), Rec."Document No.", 0, 0, Rec."Line No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Line Archive", OnAfterDeleteEvent, '', false, false)]
    [InherentPermissions(PermissionObjectType::TableData, Database::"ATT Document Line Attribute", 'rd')]
    local procedure DeleteAttributesOnAfterDeleteSalesLineArchive(var Rec: Record "Sales Line Archive")
    begin
        if Rec.IsTemporary() then
            exit;

        DocLineAttributeMgt.DeleteAttributesOfDeletedLine(
            Database::"Sales Line Archive", Rec."Document Type".AsInteger(), Rec."Document No.", Rec."Doc. No. Occurrence", Rec."Version No.", Rec."Line No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Shipment Line", OnAfterDeleteEvent, '', false, false)]
    [InherentPermissions(PermissionObjectType::TableData, Database::"ATT Document Line Attribute", 'rd')]
    local procedure DeleteAttributesOnAfterDeleteSalesShipmentLine(var Rec: Record "Sales Shipment Line")
    begin
        if Rec.IsTemporary() then
            exit;

        DocLineAttributeMgt.DeleteAttributesOfDeletedLine(Database::"Sales Shipment Line", 0, Rec."Document No.", 0, 0, Rec."Line No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Invoice Line", OnAfterDeleteEvent, '', false, false)]
    [InherentPermissions(PermissionObjectType::TableData, Database::"ATT Document Line Attribute", 'rd')]
    local procedure DeleteAttributesOnAfterDeleteSalesInvoiceLine(var Rec: Record "Sales Invoice Line")
    begin
        if Rec.IsTemporary() then
            exit;

        DocLineAttributeMgt.DeleteAttributesOfDeletedLine(Database::"Sales Invoice Line", 0, Rec."Document No.", 0, 0, Rec."Line No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Cr.Memo Line", OnAfterDeleteEvent, '', false, false)]
    [InherentPermissions(PermissionObjectType::TableData, Database::"ATT Document Line Attribute", 'rd')]
    local procedure DeleteAttributesOnAfterDeleteSalesCrMemoLine(var Rec: Record "Sales Cr.Memo Line")
    begin
        if Rec.IsTemporary() then
            exit;

        DocLineAttributeMgt.DeleteAttributesOfDeletedLine(Database::"Sales Cr.Memo Line", 0, Rec."Document No.", 0, 0, Rec."Line No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Return Receipt Line", OnAfterDeleteEvent, '', false, false)]
    [InherentPermissions(PermissionObjectType::TableData, Database::"ATT Document Line Attribute", 'rd')]
    local procedure DeleteAttributesOnAfterDeleteReturnReceiptLine(var Rec: Record "Return Receipt Line")
    begin
        if Rec.IsTemporary() then
            exit;

        DocLineAttributeMgt.DeleteAttributesOfDeletedLine(Database::"Return Receipt Line", 0, Rec."Document No.", 0, 0, Rec."Line No.");
    end;
    #endregion

    #region Archive
    // Copies to the archive line with its own Doc. No. Occurrence and Version No., so earlier versions are not changed.
    // The archive line is new, so the target is not cleaned up first.

    [EventSubscriber(ObjectType::Codeunit, Codeunit::ArchiveManagement, OnAfterStoreSalesLineArchive, '', false, false)]
    [InherentPermissions(PermissionObjectType::TableData, Database::"ATT Document Line Attribute", 'ri')]
    local procedure CopyAttributesOnAfterStoreSalesLineArchive(var SalesLine: Record "Sales Line"; var SalesLineArchive: Record "Sales Line Archive")
    begin
        DocLineAttributeMgt.CopyAttributesToNewLine(
            Database::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", 0, 0, SalesLine."Line No.",
            Database::"Sales Line Archive", SalesLineArchive."Document Type".AsInteger(), SalesLineArchive."Document No.",
            SalesLineArchive."Doc. No. Occurrence", SalesLineArchive."Version No.", SalesLineArchive."Line No.");
    end;
    #endregion

    #region Posting
    // The Sales Line passed by Sales-Post can be a temporary copy of the document line. Only its key values are used,
    // so it is not skipped when it is temporary. The posted line is new, so the target is not cleaned up first.

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", OnAfterSalesShptLineInsert, '', false, false)]
    [InherentPermissions(PermissionObjectType::TableData, Database::"ATT Document Line Attribute", 'ri')]
    local procedure CopyAttributesOnAfterSalesShptLineInsert(var SalesShipmentLine: Record "Sales Shipment Line"; SalesLine: Record "Sales Line")
    begin
        CopySalesLineAttributesToPostedLine(SalesLine, Database::"Sales Shipment Line", SalesShipmentLine."Document No.", SalesShipmentLine."Line No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", OnAfterSalesInvLineInsert, '', false, false)]
    [InherentPermissions(PermissionObjectType::TableData, Database::"ATT Document Line Attribute", 'ri')]
    local procedure CopyAttributesOnAfterSalesInvLineInsert(var SalesInvLine: Record "Sales Invoice Line"; SalesLine: Record "Sales Line")
    begin
        CopySalesLineAttributesToPostedLine(SalesLine, Database::"Sales Invoice Line", SalesInvLine."Document No.", SalesInvLine."Line No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", OnAfterSalesCrMemoLineInsert, '', false, false)]
    [InherentPermissions(PermissionObjectType::TableData, Database::"ATT Document Line Attribute", 'ri')]
    local procedure CopyAttributesOnAfterSalesCrMemoLineInsert(var SalesCrMemoLine: Record "Sales Cr.Memo Line"; SalesLine: Record "Sales Line")
    begin
        CopySalesLineAttributesToPostedLine(SalesLine, Database::"Sales Cr.Memo Line", SalesCrMemoLine."Document No.", SalesCrMemoLine."Line No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", OnAfterReturnRcptLineInsert, '', false, false)]
    [InherentPermissions(PermissionObjectType::TableData, Database::"ATT Document Line Attribute", 'ri')]
    local procedure CopyAttributesOnAfterReturnRcptLineInsert(var ReturnRcptLine: Record "Return Receipt Line"; SalesLine: Record "Sales Line")
    begin
        // Sales-Post raises this event even when the insert was handled by another subscriber; then there is no line to copy to.
        if ReturnRcptLine."Document No." = '' then
            exit;

        CopySalesLineAttributesToPostedLine(SalesLine, Database::"Return Receipt Line", ReturnRcptLine."Document No.", ReturnRcptLine."Line No.");
    end;

    local procedure CopySalesLineAttributesToPostedLine(SalesLine: Record "Sales Line"; PostedTableId: Integer; PostedDocumentNo: Code[20]; PostedLineNo: Integer)
    begin
        // Posted lines have no document type, occurrence or version: these key values are 0.
        DocLineAttributeMgt.CopyAttributesToNewLine(
            Database::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", 0, 0, SalesLine."Line No.",
            PostedTableId, 0, PostedDocumentNo, 0, 0, PostedLineNo);
    end;
    #endregion
}
