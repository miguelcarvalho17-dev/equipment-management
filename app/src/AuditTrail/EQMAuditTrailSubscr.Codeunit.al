namespace MiguelCarvalho.EquipmentManagement;

/// <summary>
/// Writes audit trail entries when equipment is created, assigned or returned, by subscribing to the business events.
/// </summary>
codeunit 50136 "EQM Audit Trail Subscr."
{
    Access = Internal;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"EQM Business Events", OnEquipmentCreated, '', false, false)]
    local procedure LogCreated(Equipment: Record "EQM Equipment")
    var
        AuditTrailMgt: Codeunit "EQM Audit Trail Mgt.";
    begin
        if Equipment.IsTemporary() then
            exit;
        AuditTrailMgt.LogCreated(Equipment);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"EQM Business Events", OnEquipmentAssigned, '', false, false)]
    local procedure LogAssigned(Equipment: Record "EQM Equipment"; EquipmentAssignment: Record "EQM Equipment Assignment")
    var
        AuditTrailMgt: Codeunit "EQM Audit Trail Mgt.";
    begin
        if Equipment.IsTemporary() then
            exit;
        AuditTrailMgt.LogAssignment("EQM Audit Event Type"::Assigned, Equipment, EquipmentAssignment);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"EQM Business Events", OnEquipmentReturned, '', false, false)]
    local procedure LogReturned(Equipment: Record "EQM Equipment"; EquipmentAssignment: Record "EQM Equipment Assignment")
    var
        AuditTrailMgt: Codeunit "EQM Audit Trail Mgt.";
    begin
        if Equipment.IsTemporary() then
            exit;
        AuditTrailMgt.LogAssignment("EQM Audit Event Type"::Returned, Equipment, EquipmentAssignment);
    end;
}
