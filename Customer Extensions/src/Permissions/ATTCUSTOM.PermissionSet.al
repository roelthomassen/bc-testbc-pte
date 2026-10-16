namespace Attitutor.CustomerExtensions.Permissions;

using Attitutor.CustomerExtensions.DocumentLineAttribute;

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
        codeunit "ATT Doc. Line Attr. Subscr." = X;
}
