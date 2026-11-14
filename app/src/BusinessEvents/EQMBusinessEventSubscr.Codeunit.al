namespace MiguelCarvalho.EquipmentManagement;

/// <summary>
/// Raises the business events that follow the insert of equipment and maintenance records.
/// </summary>
codeunit 50120 "EQM Business Event Subscr."
{
    Access = Internal;

    [EventSubscriber(ObjectType::Table, Database::"EQM Equipment", OnAfterInsertEvent, '', false, false)]
    local procedure RaiseEquipmentCreated(var Rec: Record "EQM Equipment"; RunTrigger: Boolean)
    var
        BusinessEvents: Codeunit "EQM Business Events";
    begin
        if Rec.IsTemporary() then
            exit;
        if not RunTrigger then
            exit;
        BusinessEvents.OnEquipmentCreated(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"EQM Maintenance Record", OnAfterInsertEvent, '', false, false)]
    local procedure RaiseMaintenanceCreated(var Rec: Record "EQM Maintenance Record"; RunTrigger: Boolean)
    var
        BusinessEvents: Codeunit "EQM Business Events";
    begin
        if Rec.IsTemporary() then
            exit;
        if not RunTrigger then
            exit;
        BusinessEvents.OnMaintenanceCreated(Rec);
    end;
}
