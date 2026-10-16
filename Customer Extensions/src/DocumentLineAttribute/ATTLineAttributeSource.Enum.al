namespace Attitutor.CustomerExtensions.DocumentLineAttribute;

/// <summary>
/// Specifies where a document line attribute originates from.
/// </summary>
enum 50100 "ATT Line Attribute Source"
{
    Caption = 'Line Attribute Source';
    Extensible = true;

    value(0; " ")
    {
        Caption = ' ', Locked = true;
    }
    value(1; Item)
    {
        Caption = 'Item';
    }
    value(2; Variant)
    {
        Caption = 'Variant';
    }
    value(3; Order)
    {
        Caption = 'Order';
    }
    value(4; "Parent Line")
    {
        Caption = 'Parent Line';
    }
}
