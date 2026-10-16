namespace Attitutor.CustomerExtensions.DocumentLineAttribute;

using Microsoft.Sales.Archive;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;

/// <summary>
/// Copies and deletes the attributes of document lines that are stored in the ATT Document Line Attribute table.
/// </summary>
codeunit 50100 "ATT Doc. Line Attribute Mgt."
{
    Permissions = tabledata "ATT Document Line Attribute" = RIMD;

    var
        NotARecordErr: Label 'The document line must be passed as a record.';
        UnsupportedRecordErr: Label 'Document line attributes are not supported for records of table %1.', Comment = '%1 = table ID';

    /// <summary>
    /// Copies all attributes of a source document line to a target document line.
    /// All existing attributes of the target line are deleted first, so the target ends up with exactly the attributes of the source.
    /// </summary>
    /// <param name="FromLine">The source line: a record of Sales Line, Sales Line Archive, Sales Shipment Line, Sales Invoice Line, Sales Cr.Memo Line or Return Receipt Line.</param>
    /// <param name="ToLine">The target line: a record of one of the supported line tables.</param>
    /// <remarks>
    /// Only the key values of the records are used, so the records may be temporary copies of the lines.
    /// Raises an error when a parameter is not a record or is a record of an unsupported table.
    /// Nothing happens when the source and the target are the same line.
    /// </remarks>
    procedure CopyAttributes(FromLine: Variant; ToLine: Variant)
    var
        TempFromLineKey: Record "ATT Document Line Attribute" temporary;
        TempToLineKey: Record "ATT Document Line Attribute" temporary;
    begin
        GetLineKey(FromLine, TempFromLineKey);
        GetLineKey(ToLine, TempToLineKey);
        CopyAttributes(
            TempFromLineKey."Table ID", TempFromLineKey."Document Type", TempFromLineKey."Document No.",
            TempFromLineKey."Doc. No. Occurrence", TempFromLineKey."Version No.", TempFromLineKey."Line No.",
            TempToLineKey."Table ID", TempToLineKey."Document Type", TempToLineKey."Document No.",
            TempToLineKey."Doc. No. Occurrence", TempToLineKey."Version No.", TempToLineKey."Line No.");
    end;

    /// <summary>
    /// Copies all attributes of a source document line to a target document line, identified by their key values.
    /// All existing attributes of the target line are deleted first, so the target ends up with exactly the attributes of the source.
    /// Nothing happens when the source and the target are the same line.
    /// </summary>
    /// <param name="FromTableId">The table ID of the source line.</param>
    /// <param name="FromDocumentType">The document type of the source line, as the value of the source table's document type (0 for posted lines).</param>
    /// <param name="FromDocumentNo">The document number of the source line.</param>
    /// <param name="FromDocNoOccurrence">The document number occurrence of the source line (0 if not applicable).</param>
    /// <param name="FromVersionNo">The version number of the source line (0 if not applicable).</param>
    /// <param name="FromLineNo">The line number of the source line.</param>
    /// <param name="ToTableId">The table ID of the target line.</param>
    /// <param name="ToDocumentType">The document type of the target line, as the value of the target table's document type (0 for posted lines).</param>
    /// <param name="ToDocumentNo">The document number of the target line.</param>
    /// <param name="ToDocNoOccurrence">The document number occurrence of the target line (0 if not applicable).</param>
    /// <param name="ToVersionNo">The version number of the target line (0 if not applicable).</param>
    /// <param name="ToLineNo">The line number of the target line.</param>
    /// <remarks>
    /// Use this overload for line tables that the Variant overload does not handle yet. The key values are not checked
    /// against an existing line. The copied records are inserted with their OnInsert trigger, which raises an error
    /// when the target table ID is not supported.
    /// </remarks>
    procedure CopyAttributes(FromTableId: Integer; FromDocumentType: Integer; FromDocumentNo: Code[20]; FromDocNoOccurrence: Integer; FromVersionNo: Integer; FromLineNo: Integer; ToTableId: Integer; ToDocumentType: Integer; ToDocumentNo: Code[20]; ToDocNoOccurrence: Integer; ToVersionNo: Integer; ToLineNo: Integer)
    begin
        if (FromTableId = ToTableId) and (FromDocumentType = ToDocumentType) and (FromDocumentNo = ToDocumentNo)
           and (FromDocNoOccurrence = ToDocNoOccurrence) and (FromVersionNo = ToVersionNo) and (FromLineNo = ToLineNo)
        then
            exit;

        DeleteLineAttributes(ToTableId, ToDocumentType, ToDocumentNo, ToDocNoOccurrence, ToVersionNo, ToLineNo);
        InsertCopiedAttributes(
            FromTableId, FromDocumentType, FromDocumentNo, FromDocNoOccurrence, FromVersionNo, FromLineNo,
            ToTableId, ToDocumentType, ToDocumentNo, ToDocNoOccurrence, ToVersionNo, ToLineNo);
    end;

    /// <summary>
    /// Copies all attributes of a source line to a line that was just created (an archived or posted line).
    /// Unlike CopyAttributes, the target is not cleaned up first, because a new line has no attributes yet.
    /// Used by the archive and posting subscribers; grants the read and insert permissions they need, so users without
    /// the ATT CUSTOM permission set can archive and post.
    /// </summary>
    [InherentPermissions(PermissionObjectType::TableData, Database::"ATT Document Line Attribute", 'ri')]
    internal procedure CopyAttributesToNewLine(FromTableId: Integer; FromDocumentType: Integer; FromDocumentNo: Code[20]; FromDocNoOccurrence: Integer; FromVersionNo: Integer; FromLineNo: Integer; ToTableId: Integer; ToDocumentType: Integer; ToDocumentNo: Code[20]; ToDocNoOccurrence: Integer; ToVersionNo: Integer; ToLineNo: Integer)
    begin
        InsertCopiedAttributes(
            FromTableId, FromDocumentType, FromDocumentNo, FromDocNoOccurrence, FromVersionNo, FromLineNo,
            ToTableId, ToDocumentType, ToDocumentNo, ToDocNoOccurrence, ToVersionNo, ToLineNo);
    end;

    /// <summary>
    /// Deletes all attributes of a line that is being deleted.
    /// Used by the delete subscribers; grants the read and delete permissions they need, so users without
    /// the ATT CUSTOM permission set can delete document lines.
    /// </summary>
    [InherentPermissions(PermissionObjectType::TableData, Database::"ATT Document Line Attribute", 'rd')]
    internal procedure DeleteAttributesOfDeletedLine(TableId: Integer; DocumentType: Integer; DocumentNo: Code[20]; DocNoOccurrence: Integer; VersionNo: Integer; LineNo: Integer)
    begin
        DeleteLineAttributes(TableId, DocumentType, DocumentNo, DocNoOccurrence, VersionNo, LineNo);
    end;

    /// <summary>
    /// Deletes all attributes of a document line.
    /// </summary>
    /// <param name="Line">The line: a record of Sales Line, Sales Line Archive, Sales Shipment Line, Sales Invoice Line, Sales Cr.Memo Line or Return Receipt Line.</param>
    /// <remarks>
    /// Attributes of other lines, including other versions and occurrences of the same document, are not affected.
    /// Raises an error when the parameter is not a record or is a record of an unsupported table.
    /// </remarks>
    procedure DeleteAttributes(Line: Variant)
    var
        TempLineKey: Record "ATT Document Line Attribute" temporary;
    begin
        GetLineKey(Line, TempLineKey);
        DeleteAttributes(
            TempLineKey."Table ID", TempLineKey."Document Type", TempLineKey."Document No.",
            TempLineKey."Doc. No. Occurrence", TempLineKey."Version No.", TempLineKey."Line No.");
    end;

    /// <summary>
    /// Deletes all attributes of a document line, identified by its key values.
    /// </summary>
    /// <param name="TableId">The table ID of the line.</param>
    /// <param name="DocumentType">The document type of the line, as the value of the table's document type (0 for posted lines).</param>
    /// <param name="DocumentNo">The document number of the line.</param>
    /// <param name="DocNoOccurrence">The document number occurrence of the line (0 if not applicable).</param>
    /// <param name="VersionNo">The version number of the line (0 if not applicable).</param>
    /// <param name="LineNo">The line number of the line.</param>
    /// <remarks>
    /// The table ID is not checked; for a key that has no attributes, nothing happens.
    /// </remarks>
    procedure DeleteAttributes(TableId: Integer; DocumentType: Integer; DocumentNo: Code[20]; DocNoOccurrence: Integer; VersionNo: Integer; LineNo: Integer)
    begin
        DeleteLineAttributes(TableId, DocumentType, DocumentNo, DocNoOccurrence, VersionNo, LineNo);
    end;

    /// <summary>
    /// Returns whether document line attributes can be stored for the specified table.
    /// </summary>
    /// <param name="TableId">The ID of the table to check.</param>
    /// <returns>True for Sales Line, Sales Line Archive, Sales Shipment Line, Sales Invoice Line, Sales Cr.Memo Line and Return Receipt Line; otherwise false.</returns>
    procedure IsSupportedTable(TableId: Integer): Boolean
    begin
        case TableId of
            Database::"Sales Line",
            Database::"Sales Line Archive",
            Database::"Sales Shipment Line",
            Database::"Sales Invoice Line",
            Database::"Sales Cr.Memo Line",
            Database::"Return Receipt Line":
                exit(true);
        end;

        exit(false);
    end;

    local procedure DeleteLineAttributes(TableId: Integer; DocumentType: Integer; DocumentNo: Code[20]; DocNoOccurrence: Integer; VersionNo: Integer; LineNo: Integer)
    var
        DocLineAttribute: Record "ATT Document Line Attribute";
    begin
        SetLineFilter(DocLineAttribute, TableId, DocumentType, DocumentNo, DocNoOccurrence, VersionNo, LineNo);
        if DocLineAttribute.IsEmpty() then
            exit;

        DocLineAttribute.DeleteAll();
    end;

    local procedure InsertCopiedAttributes(FromTableId: Integer; FromDocumentType: Integer; FromDocumentNo: Code[20]; FromDocNoOccurrence: Integer; FromVersionNo: Integer; FromLineNo: Integer; ToTableId: Integer; ToDocumentType: Integer; ToDocumentNo: Code[20]; ToDocNoOccurrence: Integer; ToVersionNo: Integer; ToLineNo: Integer)
    var
        FromDocLineAttribute: Record "ATT Document Line Attribute";
        ToDocLineAttribute: Record "ATT Document Line Attribute";
    begin
        SetLineFilter(FromDocLineAttribute, FromTableId, FromDocumentType, FromDocumentNo, FromDocNoOccurrence, FromVersionNo, FromLineNo);
        if not FromDocLineAttribute.FindSet() then
            exit;

        repeat
            ToDocLineAttribute := FromDocLineAttribute;
            ToDocLineAttribute."Table ID" := ToTableId;
            ToDocLineAttribute."Document Type" := ToDocumentType;
            ToDocLineAttribute."Document No." := ToDocumentNo;
            ToDocLineAttribute."Doc. No. Occurrence" := ToDocNoOccurrence;
            ToDocLineAttribute."Version No." := ToVersionNo;
            ToDocLineAttribute."Line No." := ToLineNo;
            ToDocLineAttribute.Insert(true);
        until FromDocLineAttribute.Next() = 0;
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

    local procedure GetLineKey(Line: Variant; var TempLineKey: Record "ATT Document Line Attribute" temporary)
    var
        SalesLine: Record "Sales Line";
        SalesLineArchive: Record "Sales Line Archive";
        SalesShipmentLine: Record "Sales Shipment Line";
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        ReturnReceiptLine: Record "Return Receipt Line";
        LineRecordRef: RecordRef;
    begin
        if not Line.IsRecord() then
            Error(NotARecordErr);

        LineRecordRef.GetTable(Line);
        case LineRecordRef.Number() of
            Database::"Sales Line":
                begin
                    LineRecordRef.SetTable(SalesLine);
                    SetLineKey(TempLineKey, Database::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", 0, 0, SalesLine."Line No.");
                end;
            Database::"Sales Line Archive":
                begin
                    LineRecordRef.SetTable(SalesLineArchive);
                    SetLineKey(
                        TempLineKey, Database::"Sales Line Archive", SalesLineArchive."Document Type".AsInteger(), SalesLineArchive."Document No.",
                        SalesLineArchive."Doc. No. Occurrence", SalesLineArchive."Version No.", SalesLineArchive."Line No.");
                end;
            Database::"Sales Shipment Line":
                begin
                    LineRecordRef.SetTable(SalesShipmentLine);
                    SetLineKey(TempLineKey, Database::"Sales Shipment Line", 0, SalesShipmentLine."Document No.", 0, 0, SalesShipmentLine."Line No.");
                end;
            Database::"Sales Invoice Line":
                begin
                    LineRecordRef.SetTable(SalesInvoiceLine);
                    SetLineKey(TempLineKey, Database::"Sales Invoice Line", 0, SalesInvoiceLine."Document No.", 0, 0, SalesInvoiceLine."Line No.");
                end;
            Database::"Sales Cr.Memo Line":
                begin
                    LineRecordRef.SetTable(SalesCrMemoLine);
                    SetLineKey(TempLineKey, Database::"Sales Cr.Memo Line", 0, SalesCrMemoLine."Document No.", 0, 0, SalesCrMemoLine."Line No.");
                end;
            Database::"Return Receipt Line":
                begin
                    LineRecordRef.SetTable(ReturnReceiptLine);
                    SetLineKey(TempLineKey, Database::"Return Receipt Line", 0, ReturnReceiptLine."Document No.", 0, 0, ReturnReceiptLine."Line No.");
                end;
            else
                Error(UnsupportedRecordErr, LineRecordRef.Number());
        end;
    end;

    local procedure SetLineKey(var TempLineKey: Record "ATT Document Line Attribute" temporary; TableId: Integer; DocumentType: Integer; DocumentNo: Code[20]; DocNoOccurrence: Integer; VersionNo: Integer; LineNo: Integer)
    begin
        TempLineKey.Init();
        TempLineKey."Table ID" := TableId;
        TempLineKey."Document Type" := DocumentType;
        TempLineKey."Document No." := DocumentNo;
        TempLineKey."Doc. No. Occurrence" := DocNoOccurrence;
        TempLineKey."Version No." := VersionNo;
        TempLineKey."Line No." := LineNo;
    end;
}
