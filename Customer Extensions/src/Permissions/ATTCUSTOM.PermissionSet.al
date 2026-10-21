namespace Attitutor.CustomerExtensions.Permissions;

using Attitutor.CustomerExtensions.DocumentLineAttribute;
using Attitutor.CustomerExtensions.OrderAttributeSetting;
using Attitutor.CustomerExtensions.Upgrade;
using Microsoft.Inventory.Item.Attribute;

/// <summary>
/// Gives full access to all objects of the Customer Extensions app. Every new object of the app is added here.
/// </summary>
permissionset 50100 "ATT CUSTOM"
{
    Assignable = true;
    Caption = 'ATT Custom - All';

    Permissions =
        tabledata "ATT Document Line Attribute" = RIMD,
        table "ATT Document Line Attribute" = X,
        codeunit "ATT Doc. Line Attribute Mgt." = X,
        codeunit "ATT Doc. Line Attr. Subscr." = X,
        codeunit "ATT Install" = X,
        codeunit "ATT Upgrade" = X,
        codeunit "ATT Upgrade Mgt." = X,
        tabledata "ATT Res. Order Attr. Setting" = RIMD,
        table "ATT Res. Order Attr. Setting" = X,
        codeunit "ATT Order Attr. Setting Mgt." = X,
        page "ATT Order Attribute Settings" = X,
        page "ATT Res. Order Attr. Settings" = X,
        tabledata "Item Attribute Value" = RI;
}
