namespace Attitutor.CustomerExtensions.ItemAttribute;

using Microsoft.Inventory.Item.Attribute;

/// <summary>
/// Shows the print settings of an item attribute on the Item Attribute card.
/// </summary>
pageextension 50101 "ATT Item Attribute Card" extends "Item Attribute"
{
    layout
    {
        addafter(Blocked)
        {
            field("ATT Show on Customer Docs"; Rec."ATT Show on Customer Docs")
            {
                ApplicationArea = Basic, Suite;
            }
            field("ATT Show on Production Docs"; Rec."ATT Show on Production Docs")
            {
                ApplicationArea = Basic, Suite;
            }
        }
    }
}
