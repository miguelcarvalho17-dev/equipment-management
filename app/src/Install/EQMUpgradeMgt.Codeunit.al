namespace MiguelCarvalho.EquipmentManagement;

using System.Upgrade;

/// <summary>
/// Upgrade steps of the app. Each data change is one step, guarded by its own upgrade tag, so it runs once per company
/// however often the upgrade or install is repeated. Called from "EQM Install" and "EQM Upgrade". New companies get every
/// registered tag through OnGetPerCompanyUpgradeTags. Each step must be safe on fresh-install data, because the install runs it too.
/// </summary>
codeunit 50139 "EQM Upgrade Mgt."
{
    Access = Internal;
    Permissions = tabledata "EQM Equipment Setup" = rm;

    var
        DefaultWarrantyAlertDaysTagTok: Label 'MC-EQM-FR044-DefaultWarrantyAlertDays-20261118', Locked = true;

    /// <summary>
    /// Runs every per-company upgrade step. Steps whose tag is already set are skipped.
    /// </summary>
    internal procedure UpgradePerCompany()
    begin
        UpgradeDefaultWarrantyAlertDays();
    end;

    /// <summary>
    /// Fills Default Warranty Alert Days (FR-043) on the existing setup row once per company, then sets the upgrade tag.
    /// </summary>
    internal procedure UpgradeDefaultWarrantyAlertDays()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(GetDefaultWarrantyAlertDaysTag()) then
            exit;

        InitDefaultWarrantyAlertDays();
        UpgradeTag.SetUpgradeTag(GetDefaultWarrantyAlertDaysTag());
    end;

    /// <summary>
    /// Sets Default Warranty Alert Days to the longest alert interval (90) when the setup row exists and the field is blank (0).
    /// Rows created before the field existed read 0. Any other value, every other field, and a missing setup row are left alone.
    /// </summary>
    internal procedure InitDefaultWarrantyAlertDays()
    var
        EquipmentSetup: Record "EQM Equipment Setup";
        WarrantyAlertMgt: Codeunit "EQM Warranty Alert Mgt.";
    begin
        if not EquipmentSetup.Get() then
            exit;
        if EquipmentSetup."Default Warranty Alert Days" <> 0 then
            exit;

        EquipmentSetup."Default Warranty Alert Days" := WarrantyAlertMgt.GetLongestIntervalDays();
        EquipmentSetup.Modify(false);
    end;

    /// <summary>
    /// Returns the upgrade tag of the Default Warranty Alert Days step. Never change a shipped tag.
    /// </summary>
    /// <returns>The upgrade tag.</returns>
    internal procedure GetDefaultWarrantyAlertDaysTag(): Code[250]
    begin
        exit(DefaultWarrantyAlertDaysTagTok);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerCompanyUpgradeTags', '', false, false)]
    local procedure RegisterPerCompanyUpgradeTags(var PerCompanyUpgradeTags: List of [Code[250]])
    begin
        PerCompanyUpgradeTags.Add(GetDefaultWarrantyAlertDaysTag());
    end;
}
