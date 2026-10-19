namespace Attitutor.CustomerExtensions.ItemAttribute;

using Microsoft.Inventory.Item.Attribute;

/// <summary>
/// Shows the print settings of item attributes on the Item Attributes list.
/// </summary>
pageextension 50100 "ATT Item Attributes" extends "Item Attributes"
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
