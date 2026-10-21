namespace Attitutor.CustomerExtensions.OrderAttributeSetting;

using Microsoft.Inventory.Item;

/// <summary>
/// Adds the "Orderkenmerken" action to the Item Category Card, to edit the order attribute settings of the category.
/// </summary>
pageextension 50102 "ATT Item Category Card" extends "Item Category Card"
{
    actions
    {
        addlast(processing)
        {
            action("ATT Order Attribute Settings")
            {
                ApplicationArea = All;
                Caption = 'Orderkenmerken';
                Image = Setup;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                ToolTip = 'View or edit the order attribute settings (mandatory, sequence, not applicable, print settings) of this item category.';

                trigger OnAction()
                var
                    OrderAttributeSettings: Page "ATT Order Attribute Settings";
                begin
                    OrderAttributeSettings.SetFilters(Database::"Item Category", Rec.Code);
                    OrderAttributeSettings.RunModal();
                end;
            }
        }
    }
}
