namespace Attitutor.CustomerExtensions.OrderAttributeSetting;

/// <summary>
/// Specifies a tri-state override of a Boolean setting of "Item Attribute": inherit the item attribute's own value, or force it to Yes or No.
/// </summary>
enum 50101 "ATT Override Option"
{
    Caption = 'Override Option';
    Extensible = true;

    value(0; " ")
    {
        Caption = ' ', Locked = true;
    }
    value(1; Yes)
    {
        Caption = 'Yes';
    }
    value(2; No)
    {
        Caption = 'No';
    }
}
