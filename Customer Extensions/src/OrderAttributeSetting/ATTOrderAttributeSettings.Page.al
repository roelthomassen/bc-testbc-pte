namespace Attitutor.CustomerExtensions.OrderAttributeSetting;

using Microsoft.Inventory.Item.Attribute;

/// <summary>
/// Edits the order attribute settings (Mandatory, Sequence, Not Applicable, default value, print setting overrides) of
/// one item or item category, identified by the Table ID and No. the caller filters the page to.
/// </summary>
/// <remarks>
/// Open it through SetFilters, which sets a non-removable filter on Table ID and No. and makes new rows default to them.
/// </remarks>
page 50100 "ATT Order Attribute Settings"
{
    ApplicationArea = All;
    Caption = 'Order Attribute Settings';
    PageType = List;
    SourceTable = "Item Attribute Value Mapping";
    UsageCategory = None;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                field("Item Attribute ID"; Rec."Item Attribute ID")
                {
                    ApplicationArea = All;
                    Caption = 'Attribute';
                }
                field("ATT Mandatory"; Rec."ATT Mandatory")
                {
                    ApplicationArea = All;
                }
                field("ATT Sequence"; Rec."ATT Sequence")
                {
                    ApplicationArea = All;
                }
                field("ATT Not Applicable"; Rec."ATT Not Applicable")
                {
                    ApplicationArea = All;
                }
                field("ATT Default Value"; Rec."ATT Default Value")
                {
                    ApplicationArea = All;
                }
                field("ATT Cust. Docs Override"; Rec."ATT Cust. Docs Override")
                {
                    ApplicationArea = All;
                }
                field("ATT Prod. Docs Override"; Rec."ATT Prod. Docs Override")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.FilterGroup(2);
        Rec.SetRange("Table ID", TableIdFilter);
        Rec.SetRange("No.", NoFilter);
        Rec.FilterGroup(0);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec."Table ID" := TableIdFilter;
        Rec."No." := NoFilter;
    end;

    var
        TableIdFilter: Integer;
        NoFilter: Code[20];

    /// <summary>
    /// Sets the Table ID and No. that the page is filtered to. Call before Run or RunModal.
    /// </summary>
    /// <param name="NewTableId">The table ID of the item or item category (Database::Item or Database::"Item Category").</param>
    /// <param name="NewNo">The number of the item or the code of the item category.</param>
    procedure SetFilters(NewTableId: Integer; NewNo: Code[20])
    begin
        TableIdFilter := NewTableId;
        NoFilter := NewNo;
    end;
}
