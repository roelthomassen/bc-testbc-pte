namespace Attitutor.CustomerExtensions.OrderAttributeSetting;

using Microsoft.Inventory.Item.Attribute;

/// <summary>
/// Adds the order attribute settings to an item or item category's attribute mapping: whether the attribute is mandatory
/// on the sales line, its sequence, whether it does not apply at this level, and overrides of the item attribute's print settings.
/// </summary>
/// <remarks>
/// "ATT Default Value" is a free-text entry point for the default value of the attribute at this level: typing into it
/// validates against the item attribute's type and resolves "Item Attribute Value ID" (the base table's own pointer to an
/// existing "Item Attribute Value"), which stays the authoritative value. Validation only runs through this field's
/// OnValidate trigger (not OnInsert/OnModify, whose xRec is not a reliable before-image for code-driven writes that assign
/// fields directly instead of calling Validate - see BCQuality microsoft/knowledge/data-modeling/xrec-is-a-before-image-only-in-some-triggers.md).
/// Consequently, codeunit "ATT Order Attr. Setting Mgt." always reads the default value from "Item Attribute Value ID" first
/// when it is set, falling back to "ATT Default Value" only when no value has been resolved yet; this way, rows whose
/// "Item Attribute Value ID" is changed directly by the standard Microsoft pages are never masked by a stale entry here.
/// </remarks>
tableextension 50101 "ATT Item Attr. Value Mapping" extends "Item Attribute Value Mapping"
{
    fields
    {
        field(50100; "ATT Mandatory"; Boolean)
        {
            Caption = 'Mandatory';
            ToolTip = 'Specifies if the attribute must have a value on the sales line.';
            DataClassification = CustomerContent;
        }
        field(50101; "ATT Sequence"; Integer)
        {
            Caption = 'Sequence';
            ToolTip = 'Specifies the order in which the attribute is shown on the sales line.';
            DataClassification = CustomerContent;
        }
        field(50102; "ATT Not Applicable"; Boolean)
        {
            Caption = 'Not Applicable';
            ToolTip = 'Specifies that the attribute does not apply at this level, even if it is set on a less specific level.';
            DataClassification = CustomerContent;
        }
        field(50103; "ATT Default Value"; Text[250])
        {
            Caption = 'Default Value';
            ToolTip = 'Specifies the default value of the attribute at this level. The value must match the type of the item attribute.';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                ResolveDefaultValue();
            end;
        }
        field(50104; "ATT Cust. Docs Override"; Enum "ATT Override Option")
        {
            Caption = 'Show on Customer Documents (Override)';
            ToolTip = 'Specifies if the attribute is shown on documents for the customer. Leave blank to use the item attribute''s own setting.';
            DataClassification = CustomerContent;
        }
        field(50105; "ATT Prod. Docs Override"; Enum "ATT Override Option")
        {
            Caption = 'Show on Production Documents (Override)';
            ToolTip = 'Specifies if the attribute is shown on production documents. Leave blank to use the item attribute''s own setting.';
            DataClassification = CustomerContent;
        }
    }

    var
        InvalidOptionDefaultValueErr: Label 'contains the value %1, which is not an existing value of Option attribute %2.', Comment = '%1 = entered value, %2 = item attribute name';
        InvalidDecimalDefaultValueErr: Label 'contains the value %1, which is not a valid decimal value for attribute %2.', Comment = '%1 = entered value, %2 = item attribute name';
        InvalidIntegerDefaultValueErr: Label 'contains the value %1, which is not a valid integer value for attribute %2.', Comment = '%1 = entered value, %2 = item attribute name';
        InvalidDateDefaultValueErr: Label 'contains the value %1, which is not a valid date value for attribute %2.', Comment = '%1 = entered value, %2 = item attribute name';

    local procedure ResolveDefaultValue()
    begin
        // Only OnValidate is used for this: xRec is a reliable before-image here, unlike in OnInsert/OnModify, where it would
        // make change detection silently skip validation for any code-driven write that assigns fields directly.
        if "ATT Default Value" = xRec."ATT Default Value" then
            exit;

        if "ATT Default Value" = '' then begin
            "Item Attribute Value ID" := 0;
            exit;
        end;

        "Item Attribute Value ID" := ResolveAttributeValueId();
    end;

    local procedure ResolveAttributeValueId(): Integer
    var
        ItemAttribute: Record "Item Attribute";
        DecimalValue: Decimal;
        IntegerValue: Integer;
        DateValue: Date;
    begin
        ItemAttribute.SetLoadFields(Type, Name);
        ItemAttribute.Get("Item Attribute ID");

        case ItemAttribute.Type of
            ItemAttribute.Type::Option:
                exit(FindExistingAttributeValueId(ItemAttribute));
            ItemAttribute.Type::Decimal:
                begin
                    if not Evaluate(DecimalValue, "ATT Default Value") then
                        FieldError("ATT Default Value", StrSubstNo(InvalidDecimalDefaultValueErr, "ATT Default Value", ItemAttribute.Name));
                    exit(FindOrCreateAttributeValueId(ItemAttribute, Format(DecimalValue)));
                end;
            ItemAttribute.Type::Integer:
                begin
                    if not Evaluate(IntegerValue, "ATT Default Value") then
                        FieldError("ATT Default Value", StrSubstNo(InvalidIntegerDefaultValueErr, "ATT Default Value", ItemAttribute.Name));
                    exit(FindOrCreateAttributeValueId(ItemAttribute, Format(IntegerValue)));
                end;
            ItemAttribute.Type::Date:
                begin
                    if not Evaluate(DateValue, "ATT Default Value") then
                        FieldError("ATT Default Value", StrSubstNo(InvalidDateDefaultValueErr, "ATT Default Value", ItemAttribute.Name));
                    exit(FindOrCreateAttributeValueId(ItemAttribute, Format(DateValue)));
                end;
            else // Text accepts any value.
                exit(FindOrCreateAttributeValueId(ItemAttribute, "ATT Default Value"));
        end;
    end;

    local procedure FindExistingAttributeValueId(ItemAttribute: Record "Item Attribute"): Integer
    var
        ItemAttributeValue: Record "Item Attribute Value";
    begin
        ItemAttributeValue.SetRange("Attribute ID", ItemAttribute.ID);
        ItemAttributeValue.SetRange(Value, "ATT Default Value");
        ItemAttributeValue.SetLoadFields(ID);
        if not ItemAttributeValue.FindFirst() then
            FieldError("ATT Default Value", StrSubstNo(InvalidOptionDefaultValueErr, "ATT Default Value", ItemAttribute.Name));
        exit(ItemAttributeValue.ID);
    end;

    local procedure FindOrCreateAttributeValueId(ItemAttribute: Record "Item Attribute"; ValueText: Text[250]): Integer
    var
        ItemAttributeValue: Record "Item Attribute Value";
    begin
        ItemAttributeValue.SetRange("Attribute ID", ItemAttribute.ID);
        ItemAttributeValue.SetRange(Value, ValueText);
        ItemAttributeValue.SetLoadFields(ID);
        if ItemAttributeValue.FindFirst() then
            exit(ItemAttributeValue.ID);

        ItemAttributeValue.Init();
        ItemAttributeValue.Validate("Attribute ID", ItemAttribute.ID);
        ItemAttributeValue.Validate(Value, ValueText);
        ItemAttributeValue.Insert(true);
        exit(ItemAttributeValue.ID);
    end;
}
