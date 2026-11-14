namespace MiguelCarvalho.EquipmentManagement.Tests;

using MiguelCarvalho.EquipmentManagement;

/// <summary>
/// Manual subscriber for the five business events of codeunit 50119 (FR-029). A test binds it with BindSubscription,
/// so only that test sees the events. It counts each event and keeps the parameters of the last raise, plus whether the
/// stored record was found in the database at the moment the event was raised. The counters live in the codeunit
/// instance, so they survive a rolled back asserterror.
/// </summary>
codeunit 50185 "EQM Business Event Test Subscr"
{
    EventSubscriberInstance = Manual;

    var
        CreatedCount: Integer;
        AssignedCount: Integer;
        ReturnedCount: Integer;
        MaintenanceCreatedCount: Integer;
        WarrantyExpiredCount: Integer;
        LastCreatedNo: Code[20];
        CreatedFoundInDb: Boolean;
        LastAssignedEquipmentNo: Code[20];
        LastAssignedStatus: Enum "EQM Equipment Status";
        LastAssignedEmployeeNo: Code[20];
        LastAssignedEntryNo: Integer;
        AssignedEntryActiveInDb: Boolean;
        LastReturnedEquipmentNo: Code[20];
        LastReturnedStatus: Enum "EQM Equipment Status";
        LastReturnedEntryNo: Integer;
        LastReturnedEntryStatus: Enum "EQM Assignment Status";
        LastMaintenanceNo: Code[20];
        MaintenanceFoundInDb: Boolean;
        WarrantyExpiredNos: List of [Code[20]];

    internal procedure GetCreatedCount(): Integer
    begin
        exit(CreatedCount);
    end;

    internal procedure GetAssignedCount(): Integer
    begin
        exit(AssignedCount);
    end;

    internal procedure GetReturnedCount(): Integer
    begin
        exit(ReturnedCount);
    end;

    internal procedure GetMaintenanceCreatedCount(): Integer
    begin
        exit(MaintenanceCreatedCount);
    end;

    internal procedure GetWarrantyExpiredCount(): Integer
    begin
        exit(WarrantyExpiredCount);
    end;

    internal procedure GetLastCreatedNo(): Code[20]
    begin
        exit(LastCreatedNo);
    end;

    internal procedure GetCreatedFoundInDb(): Boolean
    begin
        exit(CreatedFoundInDb);
    end;

    internal procedure GetLastAssignedEquipmentNo(): Code[20]
    begin
        exit(LastAssignedEquipmentNo);
    end;

    internal procedure GetLastAssignedStatus(): Enum "EQM Equipment Status"
    begin
        exit(LastAssignedStatus);
    end;

    internal procedure GetLastAssignedEmployeeNo(): Code[20]
    begin
        exit(LastAssignedEmployeeNo);
    end;

    internal procedure GetLastAssignedEntryNo(): Integer
    begin
        exit(LastAssignedEntryNo);
    end;

    internal procedure GetAssignedEntryActiveInDb(): Boolean
    begin
        exit(AssignedEntryActiveInDb);
    end;

    internal procedure GetLastReturnedEquipmentNo(): Code[20]
    begin
        exit(LastReturnedEquipmentNo);
    end;

    internal procedure GetLastReturnedStatus(): Enum "EQM Equipment Status"
    begin
        exit(LastReturnedStatus);
    end;

    internal procedure GetLastReturnedEntryNo(): Integer
    begin
        exit(LastReturnedEntryNo);
    end;

    internal procedure GetLastReturnedEntryStatus(): Enum "EQM Assignment Status"
    begin
        exit(LastReturnedEntryStatus);
    end;

    internal procedure GetLastMaintenanceNo(): Code[20]
    begin
        exit(LastMaintenanceNo);
    end;

    internal procedure GetMaintenanceFoundInDb(): Boolean
    begin
        exit(MaintenanceFoundInDb);
    end;

    internal procedure WarrantyExpiredWasRaisedFor(EquipmentNo: Code[20]): Boolean
    begin
        exit(WarrantyExpiredNos.Contains(EquipmentNo));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"EQM Business Events", OnEquipmentCreated, '', false, false)]
    local procedure HandleEquipmentCreated(Equipment: Record "EQM Equipment")
    var
        StoredEquipment: Record "EQM Equipment";
    begin
        CreatedCount += 1;
        LastCreatedNo := Equipment."No.";
        CreatedFoundInDb := StoredEquipment.Get(Equipment."No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"EQM Business Events", OnEquipmentAssigned, '', false, false)]
    local procedure HandleEquipmentAssigned(Equipment: Record "EQM Equipment"; EquipmentAssignment: Record "EQM Equipment Assignment")
    var
        StoredAssignment: Record "EQM Equipment Assignment";
    begin
        AssignedCount += 1;
        LastAssignedEquipmentNo := Equipment."No.";
        LastAssignedStatus := Equipment.Status;
        LastAssignedEmployeeNo := Equipment."Assigned Employee No.";
        LastAssignedEntryNo := EquipmentAssignment."Entry No.";
        AssignedEntryActiveInDb := StoredAssignment.Get(EquipmentAssignment."Entry No.") and
            (StoredAssignment.Status = StoredAssignment.Status::Active) and
            (StoredAssignment."Equipment No." = Equipment."No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"EQM Business Events", OnEquipmentReturned, '', false, false)]
    local procedure HandleEquipmentReturned(Equipment: Record "EQM Equipment"; EquipmentAssignment: Record "EQM Equipment Assignment")
    begin
        ReturnedCount += 1;
        LastReturnedEquipmentNo := Equipment."No.";
        LastReturnedStatus := Equipment.Status;
        LastReturnedEntryNo := EquipmentAssignment."Entry No.";
        LastReturnedEntryStatus := EquipmentAssignment.Status;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"EQM Business Events", OnMaintenanceCreated, '', false, false)]
    local procedure HandleMaintenanceCreated(MaintenanceRecord: Record "EQM Maintenance Record")
    var
        StoredRecord: Record "EQM Maintenance Record";
    begin
        MaintenanceCreatedCount += 1;
        LastMaintenanceNo := MaintenanceRecord."No.";
        MaintenanceFoundInDb := StoredRecord.Get(MaintenanceRecord."No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"EQM Business Events", OnWarrantyExpired, '', false, false)]
    local procedure HandleWarrantyExpired(Equipment: Record "EQM Equipment")
    begin
        WarrantyExpiredCount += 1;
        WarrantyExpiredNos.Add(Equipment."No.");
    end;
}
