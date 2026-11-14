namespace MiguelCarvalho.EquipmentManagement.Tests;

using MiguelCarvalho.EquipmentManagement;

/// <summary>
/// Manual subscriber for the two external business events of codeunit 50130 (FR-031). A test binds it with
/// BindSubscription, so only that test sees the events. It counts each event and keeps the parameters of the last
/// raise. The counters live in the codeunit instance, so they survive a rolled back asserterror.
/// </summary>
codeunit 50188 "EQM Power Automate Test Subscr"
{
    EventSubscriberInstance = Manual;

    var
        AssignedCount: Integer;
        LastAssignedEquipmentId: Guid;
        LastAssignedEquipmentNo: Code[20];
        LastAssignedDescription: Text[100];
        LastAssignedEmployeeNo: Code[20];
        LastAssignedAssignmentId: Guid;
        LastAssignedDate: Date;
        ExpiringCount: Integer;
        LastExpiringEquipmentId: Guid;
        LastExpiringEquipmentNo: Code[20];
        LastExpiringDescription: Text[100];
        LastExpiringProvider: Text[100];
        LastExpiringEndDate: Date;
        LastExpiringDaysRemaining: Integer;
        LastExpiringIntervalDays: Integer;

    internal procedure GetAssignedCount(): Integer
    begin
        exit(AssignedCount);
    end;

    internal procedure GetLastAssignedEquipmentId(): Guid
    begin
        exit(LastAssignedEquipmentId);
    end;

    internal procedure GetLastAssignedEquipmentNo(): Code[20]
    begin
        exit(LastAssignedEquipmentNo);
    end;

    internal procedure GetLastAssignedDescription(): Text[100]
    begin
        exit(LastAssignedDescription);
    end;

    internal procedure GetLastAssignedEmployeeNo(): Code[20]
    begin
        exit(LastAssignedEmployeeNo);
    end;

    internal procedure GetLastAssignedAssignmentId(): Guid
    begin
        exit(LastAssignedAssignmentId);
    end;

    internal procedure GetLastAssignedDate(): Date
    begin
        exit(LastAssignedDate);
    end;

    internal procedure GetExpiringCount(): Integer
    begin
        exit(ExpiringCount);
    end;

    internal procedure GetLastExpiringEquipmentId(): Guid
    begin
        exit(LastExpiringEquipmentId);
    end;

    internal procedure GetLastExpiringEquipmentNo(): Code[20]
    begin
        exit(LastExpiringEquipmentNo);
    end;

    internal procedure GetLastExpiringDescription(): Text[100]
    begin
        exit(LastExpiringDescription);
    end;

    internal procedure GetLastExpiringProvider(): Text[100]
    begin
        exit(LastExpiringProvider);
    end;

    internal procedure GetLastExpiringEndDate(): Date
    begin
        exit(LastExpiringEndDate);
    end;

    internal procedure GetLastExpiringDaysRemaining(): Integer
    begin
        exit(LastExpiringDaysRemaining);
    end;

    internal procedure GetLastExpiringIntervalDays(): Integer
    begin
        exit(LastExpiringIntervalDays);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"EQM Power Automate Events", EquipmentAssigned, '', false, false)]
    local procedure HandleEquipmentAssigned(EquipmentId: Guid; EquipmentNo: Code[20]; EquipmentDescription: Text[100]; EmployeeNo: Code[20]; AssignmentId: Guid; AssignmentDate: Date)
    begin
        AssignedCount += 1;
        LastAssignedEquipmentId := EquipmentId;
        LastAssignedEquipmentNo := EquipmentNo;
        LastAssignedDescription := EquipmentDescription;
        LastAssignedEmployeeNo := EmployeeNo;
        LastAssignedAssignmentId := AssignmentId;
        LastAssignedDate := AssignmentDate;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"EQM Power Automate Events", WarrantyExpiring, '', false, false)]
    local procedure HandleWarrantyExpiring(EquipmentId: Guid; EquipmentNo: Code[20]; EquipmentDescription: Text[100]; WarrantyProvider: Text[100]; WarrantyEndDate: Date; DaysRemaining: Integer; AlertIntervalDays: Integer)
    begin
        ExpiringCount += 1;
        LastExpiringEquipmentId := EquipmentId;
        LastExpiringEquipmentNo := EquipmentNo;
        LastExpiringDescription := EquipmentDescription;
        LastExpiringProvider := WarrantyProvider;
        LastExpiringEndDate := WarrantyEndDate;
        LastExpiringDaysRemaining := DaysRemaining;
        LastExpiringIntervalDays := AlertIntervalDays;
    end;
}
