namespace Attitutor.CustomerExtensions.OrderAttributeSetting;

using Microsoft.Inventory.Item.Attribute;

/// <summary>
/// Buffer of one row per item attribute in the computed resulting order attribute setting of an item: the winning
/// Mandatory, Sequence, Default Value and print settings, and a human-readable description of the level they came from.
/// </summary>
/// <remarks>
/// Always used as a temporary record; filled by codeunit "ATT Order Attr. Setting Mgt." and never written to the database.
/// </remarks>
table 50101 "ATT Res. Order Attr. Setting"
{
    Caption = 'Resulting Order Attribute Setting';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Attribute ID"; Integer)
        {
            Caption = 'Attribute ID';
            ToolTip = 'Specifies the item attribute.';
            TableRelation = "Item Attribute".ID;
        }
        field(2; "Attribute Name"; Text[250])
        {
            Caption = 'Attribute';
            ToolTip = 'Specifies the name of the item attribute.';
        }
        field(3; Mandatory; Boolean)
        {
            Caption = 'Mandatory';
            ToolTip = 'Specifies if the attribute must have a value on the sales line.';
        }
        field(4; Sequence; Integer)
        {
            Caption = 'Sequence';
            ToolTip = 'Specifies the order in which the attribute is shown on the sales line.';
        }
        field(5; "Default Value"; Text[250])
        {
            Caption = 'Default Value';
            ToolTip = 'Specifies the default value of the attribute.';
        }
        field(6; "Show on Customer Documents"; Boolean)
        {
            Caption = 'Show on Customer Documents';
            ToolTip = 'Specifies if the attribute is shown on documents for the customer.';
        }
        field(7; "Show on Production Documents"; Boolean)
        {
            Caption = 'Show on Production Documents';
            ToolTip = 'Specifies if the attribute is shown on production documents.';
        }
        field(8; Level; Text[100])
        {
            Caption = 'Level';
            ToolTip = 'Specifies the item or item category that this attribute''s setting comes from.';
        }
    }

    keys
    {
        key(PK; "Attribute ID")
        {
            Clustered = true;
        }
    }
}
