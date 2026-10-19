namespace Attitutor.CustomerExtensions.Upgrade;

using Microsoft.Inventory.Item.Attribute;
using System.Upgrade;

/// <summary>
/// Contains the data upgrade routines of the Customer Extensions app, run by the ATT Install and ATT Upgrade codeunits.
/// Each routine runs only once per company, guarded by its upgrade tag.
/// </summary>
codeunit 50104 "ATT Upgrade Mgt."
{
    Access = Internal;

    var
        ItemAttrPrintSettingsTagTok: Label 'ATT-CU-123x5y65hfj-ItemAttrPrintSettings-20261019', Locked = true;

    /// <summary>
    /// Sets Show on Customer Documents and Show on Production Documents to Yes on all existing item attributes,
    /// unless this was already done in the current company.
    /// </summary>
    /// <remarks>
    /// Item attributes that existed before the fields were added read No; this routine gives them the same default as new item attributes.
    /// Runs on install and on upgrade. Does nothing when the upgrade tag returned by GetItemAttrPrintSettingsUpgradeTag exists.
    /// </remarks>
    procedure SetItemAttrPrintSettingsToYesOnce()
    begin
        SetItemAttrPrintSettingsToYesOnce(GetItemAttrPrintSettingsUpgradeTag());
    end;

    /// <summary>
    /// Sets Show on Customer Documents and Show on Production Documents to Yes on all existing item attributes,
    /// unless the given upgrade tag exists in the current company, and then sets the tag.
    /// </summary>
    /// <param name="UpgradeTagCode">The upgrade tag that guards the routine. Production code uses the tag returned by GetItemAttrPrintSettingsUpgradeTag.</param>
    /// <remarks>
    /// The tag is a parameter so that tests can run the routine with a tag that does not exist yet:
    /// the tag of this app is already set in any company where the app is installed, and upgrade tags cannot be removed.
    /// The test app reaches it through internalsVisibleTo in app.json.
    /// </remarks>
    internal procedure SetItemAttrPrintSettingsToYesOnce(UpgradeTagCode: Code[250])
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagCode) then
            exit;

        SetItemAttrPrintSettingsToYes();

        UpgradeTag.SetUpgradeTag(UpgradeTagCode);
    end;

    /// <summary>
    /// Returns the upgrade tag that marks that the print settings of the existing item attributes were set to Yes.
    /// </summary>
    /// <returns>The upgrade tag.</returns>
    procedure GetItemAttrPrintSettingsUpgradeTag(): Code[250]
    begin
        exit(ItemAttrPrintSettingsTagTok);
    end;

    local procedure SetItemAttrPrintSettingsToYes()
    var
        ItemAttribute: Record "Item Attribute";
    begin
        // All item attributes are in scope; the filters only skip records that already have the value.
        ItemAttribute.SetRange("ATT Show on Customer Docs", false);
        ItemAttribute.ModifyAll("ATT Show on Customer Docs", true, false);

        ItemAttribute.Reset();
        ItemAttribute.SetRange("ATT Show on Production Docs", false);
        ItemAttribute.ModifyAll("ATT Show on Production Docs", true, false);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", OnGetPerCompanyUpgradeTags, '', false, false)]
    local procedure RegisterPerCompanyTagsOnGetPerCompanyUpgradeTags(var PerCompanyUpgradeTags: List of [Code[250]])
    begin
        // New companies get the tag when they are created, so the routine does not run for them; their item attributes get the InitValue.
        PerCompanyUpgradeTags.Add(GetItemAttrPrintSettingsUpgradeTag());
    end;
}
