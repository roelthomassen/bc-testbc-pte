namespace Attitutor.CustomerExtensions.OrderAttributeSetting;

using Microsoft.Inventory.Item;

/// <summary>
/// Adds the "Orderkenmerken" and "Resulterende instelling tonen" actions to the Item Card, to edit the order attribute
/// settings of the item and to show the resulting setting computed from the item and its item category chain.
/// </summary>
pageextension 50103 "ATT Item Card" extends "Item Card"
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
                ToolTip = 'View or edit the order attribute settings (mandatory, sequence, not applicable, print settings) of this item.';

                trigger OnAction()
                var
                    OrderAttributeSettings: Page "ATT Order Attribute Settings";
                begin
                    OrderAttributeSettings.SetFilters(Database::Item, Rec."No.");
                    OrderAttributeSettings.RunModal();
                end;
            }
            action("ATT Show Resulting Setting")
            {
                ApplicationArea = All;
                Caption = 'Resulterende instelling tonen';
                Image = ViewDetails;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                ToolTip = 'Show the resulting order attribute setting of this item: the attributes from the item and its item category chain, with the setting of the closest level.';

                trigger OnAction()
                var
                    OrderAttrSettingMgt: Codeunit "ATT Order Attr. Setting Mgt.";
                    ResultingOrderAttrSettings: Page "ATT Res. Order Attr. Settings";
                    TempResult: Record "ATT Res. Order Attr. Setting" temporary;
                begin
                    OrderAttrSettingMgt.GetResultingSetting(Rec."No.", TempResult);
                    ResultingOrderAttrSettings.SetTempRecord(TempResult);
                    ResultingOrderAttrSettings.RunModal();
                end;
            }
        }
    }
}
