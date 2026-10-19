namespace Attitutor.CustomerExtensions.DocumentLineAttribute;

using Microsoft.Inventory.Item.Attribute;

/// <summary>
/// Central store for the attributes of document lines (sales lines, archived sales lines and posted sales lines).
/// A line is identified by Table ID, Document Type, Document No., Doc. No. Occurrence, Version No. and Line No.
/// </summary>
table 50100 "ATT Document Line Attribute"
{
    Caption = 'Document Line Attribute';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            ToolTip = 'Specifies the ID of the table that contains the document line.';
        }
        field(2; "Document Type"; Integer)
        {
            Caption = 'Document Type';
            ToolTip = 'Specifies the document type of the line, as the value of the document type of the source table. For posted lines, this is 0.';
        }
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            ToolTip = 'Specifies the number of the document that contains the line.';
        }
        field(4; "Doc. No. Occurrence"; Integer)
        {
            Caption = 'Doc. No. Occurrence';
            ToolTip = 'Specifies the occurrence of the document number. This is used for archived documents.';
        }
        field(5; "Version No."; Integer)
        {
            Caption = 'Version No.';
            ToolTip = 'Specifies the version of the archived document.';
        }
        field(6; "Line No."; Integer)
        {
            Caption = 'Line No.';
            ToolTip = 'Specifies the number of the document line.';
        }
        field(7; "Attribute ID"; Integer)
        {
            Caption = 'Attribute ID';
            ToolTip = 'Specifies the item attribute.';
            TableRelation = "Item Attribute".ID;

            trigger OnValidate()
            begin
                // Re-validating the same attribute keeps the line's values, including the print settings (snapshot).
                // Callers must use Validate("Attribute ID", Value): after a direct assignment, xRec already has the new value and nothing is copied.
                if "Attribute ID" = xRec."Attribute ID" then
                    exit;

                "Attribute Value ID" := 0;
                Value := '';
                "Unit of Measure" := '';
                CopyPrintSettingsFromItemAttribute();
            end;
        }
        field(10; "Attribute Value ID"; Integer)
        {
            Caption = 'Attribute Value ID';
            ToolTip = 'Specifies the value of the item attribute. When you select a value, its text and the unit of measure of the attribute are stored on the line.';
            TableRelation = "Item Attribute Value".ID where("Attribute ID" = field("Attribute ID"));
            // The relation is checked in OnValidate to give a specific error when the value belongs to another attribute.
            // Rename propagation is intentionally not needed: Item Attribute Value ID is AutoIncrement and Value is a snapshot.
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                SnapshotAttributeValue();
            end;
        }
        field(11; Value; Text[250])
        {
            Caption = 'Value';
            ToolTip = 'Specifies the value of the attribute at the moment it was assigned to the line. Later changes to the item attribute value do not change this value.';
        }
        field(12; "Unit of Measure"; Text[30])
        {
            Caption = 'Unit of Measure';
            ToolTip = 'Specifies the unit of measure of the attribute at the moment it was assigned to the line. Later changes to the item attribute do not change this value.';
        }
        field(13; Source; Enum "ATT Line Attribute Source")
        {
            Caption = 'Source';
            ToolTip = 'Specifies where the attribute comes from: the item, the variant, the order or the parent line.';
        }
        field(14; "Manually Modified"; Boolean)
        {
            Caption = 'Manually Modified';
            ToolTip = 'Specifies if the attribute was changed manually on the line.';
        }
        field(15; Mandatory; Boolean)
        {
            Caption = 'Mandatory';
            ToolTip = 'Specifies if the attribute must have a value.';
        }
        field(16; Sequence; Integer)
        {
            Caption = 'Sequence';
            ToolTip = 'Specifies the order in which the attributes of the line are shown.';
        }
        field(17; "Show on Customer Documents"; Boolean)
        {
            Caption = 'Show on Customer Documents';
            ToolTip = 'Specifies if the attribute is shown on documents for the customer.';
        }
        field(18; "Show on Production Documents"; Boolean)
        {
            Caption = 'Show on Production Documents';
            ToolTip = 'Specifies if the attribute is shown on production documents.';
        }
    }

    keys
    {
        key(PK; "Table ID", "Document Type", "Document No.", "Doc. No. Occurrence", "Version No.", "Line No.", "Attribute ID")
        {
            Clustered = true;
        }
        key(LineSequence; "Table ID", "Document Type", "Document No.", "Doc. No. Occurrence", "Version No.", "Line No.", Sequence)
        {
        }
    }

    trigger OnInsert()
    begin
        CheckSupportedTable();
    end;

    trigger OnRename()
    begin
        CheckSupportedTable();
    end;

    var
        UnsupportedTableErr: Label 'Document line attributes cannot be stored for table %1.', Comment = '%1 = table ID';
        AttributeValueNotFoundErr: Label 'Attribute value %1 does not exist for attribute %2.', Comment = '%1 = attribute value ID, %2 = attribute ID';
        ItemAttributeBlockedErr: Label 'Item attribute %1 is blocked and cannot be assigned to a document line.', Comment = '%1 = item attribute name';
        ItemAttributeValueBlockedErr: Label 'Value %1 of item attribute %2 is blocked and cannot be assigned to a document line.', Comment = '%1 = item attribute value, %2 = item attribute name';

    local procedure CheckSupportedTable()
    var
        DocLineAttributeMgt: Codeunit "ATT Doc. Line Attribute Mgt.";
    begin
        if DocLineAttributeMgt.IsSupportedTable("Table ID") then
            exit;

        Error(UnsupportedTableErr, "Table ID");
    end;

    local procedure CopyPrintSettingsFromItemAttribute()
    var
        ItemAttribute: Record "Item Attribute";
    begin
        // The settings are a snapshot: later changes on the item attribute do not change the line attribute.
        if "Attribute ID" = 0 then begin
            "Show on Customer Documents" := false;
            "Show on Production Documents" := false;
            exit;
        end;

        ItemAttribute.SetLoadFields("ATT Show on Customer Docs", "ATT Show on Production Docs");
        ItemAttribute.Get("Attribute ID");
        "Show on Customer Documents" := ItemAttribute."ATT Show on Customer Docs";
        "Show on Production Documents" := ItemAttribute."ATT Show on Production Docs";
    end;

    local procedure SnapshotAttributeValue()
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
    begin
        if "Attribute Value ID" = 0 then begin
            Value := '';
            "Unit of Measure" := '';
            exit;
        end;

        ItemAttributeValue.SetLoadFields(Value, Blocked);
        if not ItemAttributeValue.Get("Attribute ID", "Attribute Value ID") then
            Error(AttributeValueNotFoundErr, "Attribute Value ID", "Attribute ID");

        ItemAttribute.SetLoadFields(Name, "Unit of Measure", Blocked);
        ItemAttribute.Get("Attribute ID");

        // Only new assignments are checked; copies of existing line attributes (archive, posting, CopyAttributes) do not validate this field.
        if ItemAttribute.Blocked then
            Error(ItemAttributeBlockedErr, ItemAttribute.Name);
        if ItemAttributeValue.Blocked then
            Error(ItemAttributeValueBlockedErr, ItemAttributeValue.Value, ItemAttribute.Name);

        Value := ItemAttributeValue.Value;
        "Unit of Measure" := ItemAttribute."Unit of Measure";
    end;
}
