namespace MiguelCarvalho.EquipmentManagement;

/// <summary>
/// Logs a usage telemetry signal for each business event. Runs in the caller's transaction: no UI, no Commit.
/// </summary>
codeunit 50141 "EQM Telemetry Subscr."
{
    Access = Internal;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"EQM Business Events", OnEquipmentCreated, '', false, false)]
    local procedure EmitEquipmentCreated(Equipment: Record "EQM Equipment")
    var
        TelemetryMgt: Codeunit "EQM Telemetry Mgt.";
    begin
        TelemetryMgt.LogEquipmentCreated(Equipment);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"EQM Business Events", OnEquipmentAssigned, '', false, false)]
    local procedure EmitEquipmentAssigned(Equipment: Record "EQM Equipment"; EquipmentAssignment: Record "EQM Equipment Assignment")
    var
        TelemetryMgt: Codeunit "EQM Telemetry Mgt.";
    begin
        TelemetryMgt.LogEquipmentAssigned();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"EQM Business Events", OnEquipmentReturned, '', false, false)]
    local procedure EmitEquipmentReturned(Equipment: Record "EQM Equipment"; EquipmentAssignment: Record "EQM Equipment Assignment")
    var
        TelemetryMgt: Codeunit "EQM Telemetry Mgt.";
    begin
        TelemetryMgt.LogEquipmentReturned(Equipment, EquipmentAssignment);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"EQM Business Events", OnMaintenanceCreated, '', false, false)]
    local procedure EmitMaintenanceRegistered(MaintenanceRecord: Record "EQM Maintenance Record")
    var
        TelemetryMgt: Codeunit "EQM Telemetry Mgt.";
    begin
        TelemetryMgt.LogMaintenanceRegistered(MaintenanceRecord);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"EQM Business Events", OnWarrantyExpired, '', false, false)]
    local procedure EmitWarrantyExpired(Equipment: Record "EQM Equipment")
    var
        TelemetryMgt: Codeunit "EQM Telemetry Mgt.";
    begin
        TelemetryMgt.LogWarrantyExpired(Equipment);
    end;
}
