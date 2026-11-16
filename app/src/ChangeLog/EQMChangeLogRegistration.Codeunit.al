namespace MiguelCarvalho.EquipmentManagement;

using System.Diagnostics;
using System.Upgrade;

codeunit 50133 "EQM Change Log Registration"
{
    Access = Internal;
    Permissions = tabledata "Change Log Setup (Table)" = ri,
                  tabledata "Change Log Setup (Field)" = ri;

    var
        // The tag is intentionally NOT registered via OnGetPerCompanyUpgradeTags, so companies created after install get the rows at the next upgrade (plan risk R2).
        ChangeLogUpgradeTagLbl: Label 'MC-EQM-FR034-ChangeLogSetup-20261116', Locked = true;

    /// <summary>
    /// Registers the equipment change log setup once per company. The upgrade tag makes sure rows that a customer
    /// deleted on purpose are not added again by a later upgrade.
    /// </summary>
    internal procedure RegisterChangeLogSetupOnce()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(GetChangeLogUpgradeTag()) then
            exit;

        RegisterEquipmentChangeLogSetup();
        UpgradeTag.SetUpgradeTag(GetChangeLogUpgradeTag());
    end;

    /// <summary>
    /// Adds the Change Log setup rows for the tracked fields of the equipment table (modifications only).
    /// Does nothing when the customer already has a setup row for the table, in any state.
    /// </summary>
    internal procedure RegisterEquipmentChangeLogSetup()
    var
        ChangeLogSetupTable: Record "Change Log Setup (Table)";
        Equipment: Record "EQM Equipment";
    begin
        if ChangeLogSetupTable.Get(Database::"EQM Equipment") then
            exit;

        ChangeLogSetupTable.Init();
        ChangeLogSetupTable."Table No." := Database::"EQM Equipment";
        ChangeLogSetupTable."Log Modification" := ChangeLogSetupTable."Log Modification"::"Some Fields";
        ChangeLogSetupTable.Insert(true);

        InsertFieldSetupIfMissing(Equipment.FieldNo("Category Code"));
        InsertFieldSetupIfMissing(Equipment.FieldNo(Status));
        InsertFieldSetupIfMissing(Equipment.FieldNo("Assigned Employee No."));
        InsertFieldSetupIfMissing(Equipment.FieldNo("Warranty Start Date"));
        InsertFieldSetupIfMissing(Equipment.FieldNo("Warranty End Date"));
        InsertFieldSetupIfMissing(Equipment.FieldNo("Warranty Provider"));
        InsertFieldSetupIfMissing(Equipment.FieldNo("Warranty Reference No."));
    end;

    /// <summary>
    /// Returns the upgrade tag that marks the change log registration as done for a company.
    /// </summary>
    /// <returns>The upgrade tag.</returns>
    internal procedure GetChangeLogUpgradeTag(): Code[250]
    begin
        exit(ChangeLogUpgradeTagLbl);
    end;

    local procedure InsertFieldSetupIfMissing(EquipmentFieldNo: Integer)
    var
        ChangeLogSetupField: Record "Change Log Setup (Field)";
    begin
        if ChangeLogSetupField.Get(Database::"EQM Equipment", EquipmentFieldNo) then
            exit;

        ChangeLogSetupField.Init();
        ChangeLogSetupField."Table No." := Database::"EQM Equipment";
        ChangeLogSetupField."Field No." := EquipmentFieldNo;
        ChangeLogSetupField."Log Modification" := true;
        ChangeLogSetupField.Insert(true);
    end;
}
