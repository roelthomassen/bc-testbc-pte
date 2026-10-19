namespace Attitutor.CustomerExtensions.ItemAttribute;

using Microsoft.Inventory.Item.Attribute;

/// <summary>
/// Adds the print settings to item attributes: whether an attribute is shown on customer documents and on production documents.
/// </summary>
/// <remarks>
/// The settings are copied to a document line attribute when its Attribute ID is assigned. Later changes here do not change existing line attributes.
/// </remarks>
tableextension 50100 "ATT Item Attribute" extends "Item Attribute"
{
    fields
    {
        field(50100; "ATT Show on Customer Docs"; Boolean)
        {
            Caption = 'Show on Customer Documents';
            ToolTip = 'Specifies if the attribute is shown on documents for the customer. The setting is copied to a document line when the attribute is assigned to it.';
            DataClassification = CustomerContent;
            InitValue = true;
        }
        field(50101; "ATT Show on Production Docs"; Boolean)
        {
            Caption = 'Show on Production Documents';
            ToolTip = 'Specifies if the attribute is shown on production documents. The setting is copied to a document line when the attribute is assigned to it.';
            DataClassification = CustomerContent;
            InitValue = true;
        }
    }
}
