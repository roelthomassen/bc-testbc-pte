namespace Attitutor.CustomerExtensions.Upgrade;

/// <summary>
/// Runs the data routines of the Customer Extensions app when the app is installed in a company.
/// </summary>
codeunit 50102 "ATT Install"
{
    Subtype = Install;
    Access = Internal;

    trigger OnInstallAppPerCompany()
    var
        UpgradeMgt: Codeunit "ATT Upgrade Mgt.";
    begin
        UpgradeMgt.SetItemAttrPrintSettingsToYesOnce();
    end;
}
