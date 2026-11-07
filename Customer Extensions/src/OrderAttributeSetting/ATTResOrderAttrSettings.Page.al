namespace Attitutor.CustomerExtensions.OrderAttributeSetting;

/// <summary>
/// Shows the resulting order attribute setting computed by codeunit "ATT Order Attr. Setting Mgt." for one item: read-only,
/// one row per attribute, with the level (item or item category) that the winning setting came from.
/// </summary>
/// <remarks>
/// The caller fills the page's temporary record through SetTempRecord before calling Run or RunModal.
/// </remarks>
page 50101 "ATT Res. Order Attr. Settings"
{
    ApplicationArea = All;
    Caption = 'Resulting Order Attribute Settings';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "ATT Res. Order Attr. Setting";
    SourceTableTemporary = true;
    UsageCategory = None;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                field("Attribute Name"; Rec."Attribute Name")
                {
                    ApplicationArea = All;
                }
                field(Mandatory; Rec.Mandatory)
                {
                    ApplicationArea = All;
                }
                field(Sequence; Rec.Sequence)
                {
                    ApplicationArea = All;
                }
                field("Default Value"; Rec."Default Value")
                {
                    ApplicationArea = All;
                }
                field("Show on Customer Documents"; Rec."Show on Customer Documents")
                {
                    ApplicationArea = All;
                }
                field("Show on Production Documents"; Rec."Show on Production Documents")
                {
                    ApplicationArea = All;
                }
                field(Level; Rec.Level)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    /// <summary>
    /// Copies rows into the page's temporary record. Call before Run or RunModal.
    /// </summary>
    /// <param name="NewTempResult">The resulting order attribute setting to show, as returned by
    /// codeunit "ATT Order Attr. Setting Mgt.".GetResultingSetting.</param>
    procedure SetTempRecord(var NewTempResult: Record "ATT Res. Order Attr. Setting" temporary)
    begin
        Rec.Reset();
        Rec.DeleteAll();
        if NewTempResult.FindSet() then
            repeat
                Rec := NewTempResult;
                Rec.Insert();
            until NewTempResult.Next() = 0;
    end;
}
