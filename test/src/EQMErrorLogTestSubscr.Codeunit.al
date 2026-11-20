namespace MiguelCarvalho.EquipmentManagement.Tests;

using MiguelCarvalho.EquipmentManagement;

/// <summary>
/// Manual subscriber for the test seam of codeunit 50143 (FR-051). A test binds it with BindSubscription, so only that
/// test sees the event. It counts every job run and raises a configured error before one job body. The state lives in
/// the codeunit instance, so it survives a rolled back asserterror.
/// </summary>
codeunit 50160 "EQM Error Log Test Subscr"
{
    EventSubscriberInstance = Manual;

    var
        FailJobCodeunitId: Integer;
        FailText: Text;
        RaisedCount: Integer;
        FailTok: Label '%1', Locked = true;

    internal procedure SetFailure(JobCodeunitId: Integer; ErrorText: Text)
    begin
        FailJobCodeunitId := JobCodeunitId;
        FailText := ErrorText;
    end;

    internal procedure GetRaisedCount(): Integer
    begin
        exit(RaisedCount);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"EQM Monitoring Job Runner", OnBeforeRunMonitoringJob, '', false, false)]
    local procedure FailConfiguredJob(JobCodeunitIdToRun: Integer)
    begin
        RaisedCount += 1;
        if (FailJobCodeunitId <> 0) and (FailJobCodeunitId = JobCodeunitIdToRun) then
            Error(FailTok, FailText);
    end;
}
