namespace MiguelCarvalho.EquipmentManagement;

using System.DataAdministration;
using System.Upgrade;

/// <summary>
/// Upgrade steps of the app. Each data change is one step, guarded by its own upgrade tag, so it runs once per company
/// however often the upgrade or install is repeated. Called from "EQM Install" and "EQM Upgrade". New companies get the
/// registered tags through OnGetPerCompanyUpgradeTags; not every tag is pre-registered (see the retention policy step). Each step must be safe on fresh-install data, because the install runs it too.
/// </summary>
codeunit 50139 "EQM Upgrade Mgt."
{
    Access = Internal;
    Permissions = tabledata "EQM Equipment Setup" = rm;

    var
        DefaultWarrantyAlertDaysTagTok: Label 'MC-EQM-FR044-DefaultWarrantyAlertDays-20261118', Locked = true;
        RetentionPolicyTablesTagTok: Label 'MC-EQM-FR054-RetentionPolicyTables-20261120', Locked = true;

    /// <summary>
    /// Runs every per-company upgrade step. Steps whose tag is already set are skipped.
    /// </summary>
    internal procedure UpgradePerCompany()
    begin
        UpgradeDefaultWarrantyAlertDays();
        UpgradeRetentionPolicyTables();
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

    /// <summary>
    /// Adds the equipment log tables to the allowed tables of retention policies once per company, then sets the upgrade tag.
    /// </summary>
    internal procedure UpgradeRetentionPolicyTables()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(GetRetentionPolicyTablesTag()) then
            exit;

        AddRetentionPolicyAllowedTables();
        UpgradeTag.SetUpgradeTag(GetRetentionPolicyTablesTag());
    end;

    /// <summary>
    /// Adds the equipment log tables to the allowed tables of retention policies. Open warranty alerts and unprocessed integration
    /// event entries are protected by locked filters. Audit, history and maintenance log tables are never added.
    /// </summary>
    internal procedure AddRetentionPolicyAllowedTables()
    var
        ErrorLogEntry: Record "EQM Error Log Entry";
        WarrantyAlert: Record "EQM Warranty Alert";
        IntegrationEventEntry: Record "EQM Integration Event Entry";
        RetenPolAllowedTables: Codeunit "Reten. Pol. Allowed Tables";
        RecRef: RecordRef;
        AlertFilters: JsonArray;
        EntryFilters: JsonArray;
    begin
        RetenPolAllowedTables.AddAllowedTable(Database::"EQM Error Log Entry", ErrorLogEntry.FieldNo("Logged At"));

        WarrantyAlert.SetFilter(Status, '%1|%2', WarrantyAlert.Status::Acknowledged, WarrantyAlert.Status::Cancelled);
        RecRef.GetTable(WarrantyAlert);
        RetenPolAllowedTables.AddTableFilterToJsonArray(AlertFilters, "Retention Period Enum"::"1 Year", WarrantyAlert.FieldNo(SystemModifiedAt), true, true, RecRef);
        RetenPolAllowedTables.AddAllowedTable(Database::"EQM Warranty Alert", WarrantyAlert.FieldNo(SystemModifiedAt), AlertFilters);

        IntegrationEventEntry.SetRange(Processed, true);
        RecRef.Close();
        RecRef.GetTable(IntegrationEventEntry);
        RetenPolAllowedTables.AddTableFilterToJsonArray(EntryFilters, "Retention Period Enum"::"3 Months", IntegrationEventEntry.FieldNo("Processed At"), true, true, RecRef);
        RetenPolAllowedTables.AddAllowedTable(Database::"EQM Integration Event Entry", IntegrationEventEntry.FieldNo("Processed At"), EntryFilters);
    end;

    /// <summary>
    /// Returns the upgrade tag of the retention policy tables step. Never change a shipped tag.
    /// </summary>
    /// <returns>The upgrade tag.</returns>
    internal procedure GetRetentionPolicyTablesTag(): Code[250]
    begin
        exit(RetentionPolicyTablesTagTok);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerCompanyUpgradeTags', '', false, false)]
    local procedure RegisterPerCompanyUpgradeTags(var PerCompanyUpgradeTags: List of [Code[250]])
    begin
        PerCompanyUpgradeTags.Add(GetDefaultWarrantyAlertDaysTag());
        // The retention policy tag is deliberately not added: pre-registering it would mark new companies as done, and they
        // would never register the tables. New companies get the tables at the next install or upgrade.
    end;
}
