namespace MiguelCarvalho.EquipmentManagement.Tests;

using MiguelCarvalho.EquipmentManagement;

/// <summary>
/// Manual subscriber for the two events of codeunit 50132 (FR-033). A test binds it with BindSubscription, so only
/// that test sees the events. It counts the status changes, keeps the previous and new status of each raise and can
/// handle OnBeforeCheckApproverAllowed. The counters live in the codeunit instance, so they survive a rolled back
/// asserterror.
/// </summary>
codeunit 50190 "EQM Request Appr. Test Subscr"
{
    EventSubscriberInstance = Manual;

    var
        PreviousStatuses: List of [Integer];
        NewStatuses: List of [Integer];
        HandleApproverCheck: Boolean;
        ApproverCheckCount: Integer;

    internal procedure SetHandleApproverCheck(NewValue: Boolean)
    begin
        HandleApproverCheck := NewValue;
    end;

    internal procedure GetApproverCheckCount(): Integer
    begin
        exit(ApproverCheckCount);
    end;

    internal procedure GetStatusChangeCount(): Integer
    begin
        exit(PreviousStatuses.Count());
    end;

    internal procedure GetPreviousStatus(Index: Integer): Integer
    begin
        exit(PreviousStatuses.Get(Index));
    end;

    internal procedure GetNewStatus(Index: Integer): Integer
    begin
        exit(NewStatuses.Get(Index));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"EQM Request Approval Mgt.", OnBeforeCheckApproverAllowed, '', false, false)]
    local procedure HandleBeforeCheckApproverAllowed(EquipmentRequest: Record "EQM Equipment Request"; var IsHandled: Boolean)
    begin
        ApproverCheckCount += 1;
        if HandleApproverCheck then
            IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"EQM Request Approval Mgt.", OnAfterRequestStatusChanged, '', false, false)]
    local procedure HandleAfterRequestStatusChanged(EquipmentRequest: Record "EQM Equipment Request"; PreviousStatus: Enum "EQM Request Status")
    begin
        PreviousStatuses.Add(PreviousStatus.AsInteger());
        NewStatuses.Add(EquipmentRequest.Status.AsInteger());
    end;
}
