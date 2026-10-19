namespace Attitutor.CustomerExtensions.Upgrade;

/// <summary>
/// Runs the data upgrade routines of the Customer Extensions app when a new version of the app is installed in a company.
/// </summary>
codeunit 50103 "ATT Upgrade"
{
    Subtype = Upgrade;
    Access = Internal;

    trigger OnUpgradePerCompany()
    var
        UpgradeMgt: Codeunit "ATT Upgrade Mgt.";
    begin
        UpgradeMgt.SetItemAttrPrintSettingsToYesOnce();
    end;
}
