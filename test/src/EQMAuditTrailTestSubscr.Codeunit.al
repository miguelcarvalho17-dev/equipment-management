namespace MiguelCarvalho.EquipmentManagement.Tests;

using MiguelCarvalho.EquipmentManagement;

/// <summary>
/// Manual subscriber for FR-035 scenario 13. It fails on OnMaintenanceCreated, which is raised after the equipment was
/// sent to maintenance (and the audit entry written), so the test can prove that the entry is rolled back with the
/// failed operation. The counter lives in the codeunit instance, so it survives the rolled back asserterror.
/// </summary>
codeunit 50193 "EQM Audit Trail Test Subscr"
{
    EventSubscriberInstance = Manual;

    var
        SentToMaintenanceEntriesAtFailure: Integer;
        ForcedFailureErr: Label 'EQMAUD forced failure after the audit entry was written.', Locked = true;

    internal procedure GetSentToMaintenanceEntriesAtFailure(): Integer
    begin
        exit(SentToMaintenanceEntriesAtFailure);
    end;

    internal procedure GetForcedFailureText(): Text
    begin
        exit(ForcedFailureErr);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"EQM Business Events", OnMaintenanceCreated, '', false, false)]
    local procedure FailAfterAuditEntry(MaintenanceRecord: Record "EQM Maintenance Record")
    var
        AuditEntry: Record "EQM Equipment Audit Entry";
    begin
        AuditEntry.SetRange("Equipment No.", MaintenanceRecord."Equipment No.");
        AuditEntry.SetRange("Event Type", AuditEntry."Event Type"::"Sent to Maintenance");
        SentToMaintenanceEntriesAtFailure := AuditEntry.Count();
        Error(ForcedFailureErr);
    end;
}
