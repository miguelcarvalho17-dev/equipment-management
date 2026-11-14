namespace MiguelCarvalho.EquipmentManagement;

/// <summary>
/// Raises the Power Automate external business events. Runs in the caller's transaction: no UI, no Commit, no Modify.
/// </summary>
codeunit 50131 "EQM Power Automate Subscr."
{
    Access = Internal;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"EQM Business Events", OnEquipmentAssigned, '', false, false)]
    local procedure RaiseEquipmentAssigned(Equipment: Record "EQM Equipment"; EquipmentAssignment: Record "EQM Equipment Assignment")
    var
        PowerAutomateEvents: Codeunit "EQM Power Automate Events";
    begin
        PowerAutomateEvents.EquipmentAssigned(
            Equipment.SystemId, Equipment."No.", Equipment.Description, EquipmentAssignment."Employee No.",
            EquipmentAssignment.SystemId, EquipmentAssignment."Assignment Date");
    end;

    [EventSubscriber(ObjectType::Table, Database::"EQM Warranty Alert", OnAfterInsertEvent, '', false, false)]
    local procedure RaiseWarrantyExpiring(var Rec: Record "EQM Warranty Alert"; RunTrigger: Boolean)
    var
        Equipment: Record "EQM Equipment";
        WarrantyAlertMgt: Codeunit "EQM Warranty Alert Mgt.";
        PowerAutomateEvents: Codeunit "EQM Power Automate Events";
    begin
        if Rec.IsTemporary() then
            exit;
        if not RunTrigger then
            exit;
        Equipment.SetLoadFields(Description, "Warranty Provider");
        if not Equipment.Get(Rec."Equipment No.") then
            exit;
        PowerAutomateEvents.WarrantyExpiring(
            Equipment.SystemId, Rec."Equipment No.", Equipment.Description, Equipment."Warranty Provider",
            Rec."Warranty End Date", Rec."Warranty End Date" - Rec."Alert Date", WarrantyAlertMgt.GetIntervalDays(Rec."Alert Interval"));
    end;
}
