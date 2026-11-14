namespace MiguelCarvalho.EquipmentManagement;

/// <summary>
/// Subscribes to the business events and writes one integration event entry for each, when integration events are
/// enabled. Runs in the caller's transaction: no UI, no Commit.
/// </summary>
codeunit 50121 "EQM Integration Event Subscr."
{
    Access = Internal;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"EQM Business Events", OnEquipmentCreated, '', false, false)]
    local procedure RecordEquipmentCreated(Equipment: Record "EQM Equipment")
    var
        IntegrationEventMgt: Codeunit "EQM Integration Event Mgt.";
    begin
        if not IntegrationEventMgt.IsEnabled() then
            exit;
        IntegrationEventMgt.RecordEvent(Enum::"EQM Integration Event Type"::"Equipment Created", Equipment."No.", Equipment.Status, 0, '');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"EQM Business Events", OnEquipmentAssigned, '', false, false)]
    local procedure RecordEquipmentAssigned(Equipment: Record "EQM Equipment"; EquipmentAssignment: Record "EQM Equipment Assignment")
    var
        IntegrationEventMgt: Codeunit "EQM Integration Event Mgt.";
    begin
        if not IntegrationEventMgt.IsEnabled() then
            exit;
        IntegrationEventMgt.RecordEvent(Enum::"EQM Integration Event Type"::"Equipment Assigned", Equipment."No.", Equipment.Status, EquipmentAssignment."Entry No.", '');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"EQM Business Events", OnEquipmentReturned, '', false, false)]
    local procedure RecordEquipmentReturned(Equipment: Record "EQM Equipment"; EquipmentAssignment: Record "EQM Equipment Assignment")
    var
        IntegrationEventMgt: Codeunit "EQM Integration Event Mgt.";
    begin
        if not IntegrationEventMgt.IsEnabled() then
            exit;
        IntegrationEventMgt.RecordEvent(Enum::"EQM Integration Event Type"::"Equipment Returned", Equipment."No.", Equipment.Status, EquipmentAssignment."Entry No.", '');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"EQM Business Events", OnMaintenanceCreated, '', false, false)]
    local procedure RecordMaintenanceCreated(MaintenanceRecord: Record "EQM Maintenance Record")
    var
        Equipment: Record "EQM Equipment";
        IntegrationEventMgt: Codeunit "EQM Integration Event Mgt.";
        EquipmentStatus: Enum "EQM Equipment Status";
    begin
        if not IntegrationEventMgt.IsEnabled() then
            exit;
        Equipment.SetLoadFields(Status);
        if Equipment.Get(MaintenanceRecord."Equipment No.") then
            EquipmentStatus := Equipment.Status
        else
            EquipmentStatus := EquipmentStatus::Available;
        IntegrationEventMgt.RecordEvent(Enum::"EQM Integration Event Type"::"Maintenance Created", MaintenanceRecord."Equipment No.", EquipmentStatus, 0, MaintenanceRecord."No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"EQM Business Events", OnWarrantyExpired, '', false, false)]
    local procedure RecordWarrantyExpired(Equipment: Record "EQM Equipment")
    var
        IntegrationEventMgt: Codeunit "EQM Integration Event Mgt.";
    begin
        if not IntegrationEventMgt.IsEnabled() then
            exit;
        IntegrationEventMgt.RecordEvent(Enum::"EQM Integration Event Type"::"Warranty Expired", Equipment."No.", Equipment.Status, 0, '');
    end;
}
