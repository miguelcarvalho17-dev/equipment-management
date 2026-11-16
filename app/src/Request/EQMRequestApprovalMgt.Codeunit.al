namespace MiguelCarvalho.EquipmentManagement;

/// <summary>
/// Approval process for equipment requests: Open, then Pending Approval, then Approved or Rejected; Approved requests
/// become Completed when equipment is assigned. Rejected and Completed are final. Status changes are saved without
/// triggers (Modify(false)), because the request table locks every change to a request that is not Open.
/// </summary>
codeunit 50132 "EQM Request Approval Mgt."
{
    Access = Public;

    var
        RequestRejectedErr: Label 'Equipment request %1 was rejected. A rejected request cannot be reopened; raise a new request instead.', Comment = '%1 = request number';
        NotOpenErr: Label 'You can only send equipment request %1 for approval when its status is Open. The current status is %2.', Comment = '%1 = request number, %2 = status';
        NotPendingErr: Label 'You can only approve or reject equipment request %1 when its status is Pending Approval. The current status is %2.', Comment = '%1 = request number, %2 = status';
        SelfApprovalErr: Label 'You cannot approve equipment request %1 because you sent it for approval. Another manager must approve it.', Comment = '%1 = request number';
        RejectionCommentRequiredErr: Label 'You must enter a comment to reject equipment request %1.', Comment = '%1 = request number';
        NotApprovedErr: Label 'You cannot assign equipment for request %1 because its status is %2. The request must be approved first.', Comment = '%1 = request number, %2 = status';
        EquipmentNotFoundErr: Label 'Equipment %1 does not exist.', Comment = '%1 = equipment number';
        EquipmentTypeMismatchErr: Label 'You cannot assign equipment %1 for request %2 because its category %3 is not the requested equipment type %4.', Comment = '%1 = equipment number, %2 = request number, %3 = equipment category code, %4 = requested equipment type';
        NoAvailableEquipmentMsg: Label 'There is no available equipment of type %1.', Comment = '%1 = requested equipment type';
        ApproveInstructionTxt: Label 'Enter an optional comment for the approval.';
        RejectInstructionTxt: Label 'Enter the reason for the rejection.';

    /// <summary>
    /// Sends an Open request for approval. Checks again that the employee and the equipment type are active, records
    /// the current user as sender and sets the status to Pending Approval. Raises OnAfterRequestStatusChanged.
    /// </summary>
    /// <param name="EquipmentRequest">The request to send. Must be Open.</param>
    internal procedure SendForApproval(var EquipmentRequest: Record "EQM Equipment Request")
    var
        PreviousStatus: Enum "EQM Request Status";
    begin
        CheckNotRejected(EquipmentRequest);
        if EquipmentRequest.Status <> EquipmentRequest.Status::Open then
            Error(NotOpenErr, EquipmentRequest."No.", Format(EquipmentRequest.Status));
        EquipmentRequest.CheckRequestConsistency(true);

        PreviousStatus := EquipmentRequest.Status;
        EquipmentRequest."Sent for Approval By" := CopyStr(UserId(), 1, MaxStrLen(EquipmentRequest."Sent for Approval By"));
        EquipmentRequest.Status := EquipmentRequest.Status::"Pending Approval";
        SaveStatusChange(EquipmentRequest, PreviousStatus);
    end;

    /// <summary>
    /// Approves a request that is Pending Approval. The user who sent the request cannot approve it, unless a
    /// subscriber of OnBeforeCheckApproverAllowed handles the check. Records the decider, date and comment.
    /// Raises OnAfterRequestStatusChanged.
    /// </summary>
    /// <param name="EquipmentRequest">The request to approve. Must be Pending Approval.</param>
    /// <param name="Comment">An optional comment on the approval.</param>
    internal procedure Approve(var EquipmentRequest: Record "EQM Equipment Request"; Comment: Text[250])
    var
        PreviousStatus: Enum "EQM Request Status";
    begin
        CheckNotRejected(EquipmentRequest);
        CheckPending(EquipmentRequest);
        CheckApproverAllowed(EquipmentRequest);

        PreviousStatus := EquipmentRequest.Status;
        SetDecision(EquipmentRequest, Comment);
        EquipmentRequest.Status := EquipmentRequest.Status::Approved;
        SaveStatusChange(EquipmentRequest, PreviousStatus);
    end;

    /// <summary>
    /// Rejects a request that is Pending Approval. A comment is required. Rejected requests are final.
    /// Raises OnAfterRequestStatusChanged.
    /// </summary>
    /// <param name="EquipmentRequest">The request to reject. Must be Pending Approval.</param>
    /// <param name="Comment">The reason for the rejection. Must not be blank.</param>
    internal procedure Reject(var EquipmentRequest: Record "EQM Equipment Request"; Comment: Text[250])
    var
        PreviousStatus: Enum "EQM Request Status";
    begin
        CheckNotRejected(EquipmentRequest);
        CheckPending(EquipmentRequest);
        if IsBlank(Comment) then
            Error(RejectionCommentRequiredErr, EquipmentRequest."No.");

        PreviousStatus := EquipmentRequest.Status;
        SetDecision(EquipmentRequest, Comment);
        EquipmentRequest.Status := EquipmentRequest.Status::Rejected;
        SaveStatusChange(EquipmentRequest, PreviousStatus);
    end;

    /// <summary>
    /// Assigns equipment to the employee of an Approved request and completes the request. The equipment must be of the
    /// requested type; the equipment assignment checks (available, no open maintenance, active employee) apply.
    /// Everything runs in one transaction. Raises OnAfterRequestStatusChanged.
    /// </summary>
    /// <param name="EquipmentRequest">The request to complete. Must be Approved.</param>
    /// <param name="EquipmentNo">The equipment to assign.</param>
    internal procedure AssignEquipment(var EquipmentRequest: Record "EQM Equipment Request"; EquipmentNo: Code[20])
    var
        Equipment: Record "EQM Equipment";
        PreviousStatus: Enum "EQM Request Status";
    begin
        CheckNotRejected(EquipmentRequest);
        CheckApproved(EquipmentRequest);
        if not Equipment.Get(EquipmentNo) then
            Error(EquipmentNotFoundErr, EquipmentNo);
        if Equipment."Category Code" <> EquipmentRequest."Requested Equipment Type" then
            Error(EquipmentTypeMismatchErr, Equipment."No.", EquipmentRequest."No.", Equipment."Category Code", EquipmentRequest."Requested Equipment Type");

        Equipment.AssignEmployee(EquipmentRequest."Employee No.");

        PreviousStatus := EquipmentRequest.Status;
        EquipmentRequest."Assigned Equipment No." := Equipment."No.";
        EquipmentRequest.Status := EquipmentRequest.Status::Completed;
        SaveStatusChange(EquipmentRequest, PreviousStatus);
    end;

    /// <summary>
    /// Asks the user for an optional comment and approves the request. Does nothing when the user cancels the dialog.
    /// </summary>
    /// <param name="EquipmentRequest">The request to approve.</param>
    internal procedure ApproveWithDialog(var EquipmentRequest: Record "EQM Equipment Request")
    var
        Comment: Text[250];
    begin
        if not RunDecisionDialog(ApproveInstructionTxt, Comment) then
            exit;
        Approve(EquipmentRequest, Comment);
    end;

    /// <summary>
    /// Asks the user for the reason and rejects the request. Does nothing when the user cancels the dialog.
    /// </summary>
    /// <param name="EquipmentRequest">The request to reject.</param>
    internal procedure RejectWithDialog(var EquipmentRequest: Record "EQM Equipment Request")
    var
        Comment: Text[250];
    begin
        if not RunDecisionDialog(RejectInstructionTxt, Comment) then
            exit;
        Reject(EquipmentRequest, Comment);
    end;

    /// <summary>
    /// Lets the user choose available equipment of the requested type and assigns it to complete the request.
    /// Shows a message and exits when no such equipment is available or the user cancels the lookup.
    /// </summary>
    /// <param name="EquipmentRequest">The Approved request to complete.</param>
    internal procedure AssignEquipmentWithLookup(var EquipmentRequest: Record "EQM Equipment Request")
    var
        Equipment: Record "EQM Equipment";
        EquipmentList: Page "EQM Equipment List";
    begin
        CheckNotRejected(EquipmentRequest);
        CheckApproved(EquipmentRequest);

        Equipment.SetRange("Category Code", EquipmentRequest."Requested Equipment Type");
        Equipment.SetRange(Status, Equipment.Status::Available);
        if Equipment.IsEmpty() then begin
            Message(NoAvailableEquipmentMsg, EquipmentRequest."Requested Equipment Type");
            exit;
        end;

        EquipmentList.SetTableView(Equipment);
        EquipmentList.LookupMode(true);
        if EquipmentList.RunModal() <> Action::LookupOK then
            exit;

        EquipmentList.GetRecord(Equipment);
        AssignEquipment(EquipmentRequest, Equipment."No.");
    end;

    local procedure RunDecisionDialog(Instruction: Text; var Comment: Text[250]): Boolean
    var
        RequestDecision: Page "EQM Request Decision";
    begin
        RequestDecision.SetInstruction(Instruction);
        if RequestDecision.RunModal() <> Action::OK then
            exit(false);
        Comment := RequestDecision.GetComment();
        exit(true);
    end;

    local procedure CheckNotRejected(EquipmentRequest: Record "EQM Equipment Request")
    begin
        if EquipmentRequest.Status = EquipmentRequest.Status::Rejected then
            Error(RequestRejectedErr, EquipmentRequest."No.");
    end;

    local procedure CheckPending(EquipmentRequest: Record "EQM Equipment Request")
    begin
        if EquipmentRequest.Status <> EquipmentRequest.Status::"Pending Approval" then
            Error(NotPendingErr, EquipmentRequest."No.", Format(EquipmentRequest.Status));
    end;

    local procedure CheckApproved(EquipmentRequest: Record "EQM Equipment Request")
    begin
        if EquipmentRequest.Status <> EquipmentRequest.Status::Approved then
            Error(NotApprovedErr, EquipmentRequest."No.", Format(EquipmentRequest.Status));
    end;

    local procedure IsBlank(Comment: Text[250]): Boolean
    var
        Whitespace: Text;
        CarriageReturn: Char;
        LineFeed: Char;
        Tab: Char;
    begin
        CarriageReturn := 13;
        LineFeed := 10;
        Tab := 9;
        Whitespace := ' ' + Format(CarriageReturn) + Format(LineFeed) + Format(Tab);
        exit(DelChr(Comment, '=', Whitespace) = '');
    end;

    local procedure CheckApproverAllowed(EquipmentRequest: Record "EQM Equipment Request")
    var
        IsHandled: Boolean;
    begin
        OnBeforeCheckApproverAllowed(EquipmentRequest, IsHandled);
        if IsHandled then
            exit;
        if EquipmentRequest."Sent for Approval By" = CopyStr(UserId(), 1, MaxStrLen(EquipmentRequest."Sent for Approval By")) then
            Error(SelfApprovalErr, EquipmentRequest."No.");
    end;

    local procedure SetDecision(var EquipmentRequest: Record "EQM Equipment Request"; Comment: Text[250])
    begin
        EquipmentRequest."Decided By" := CopyStr(UserId(), 1, MaxStrLen(EquipmentRequest."Decided By"));
        EquipmentRequest."Decision Date" := WorkDate();
        EquipmentRequest."Decision Comment" := Comment;
    end;

    local procedure SaveStatusChange(var EquipmentRequest: Record "EQM Equipment Request"; PreviousStatus: Enum "EQM Request Status")
    begin
        EquipmentRequest.Modify(false);
        OnAfterRequestStatusChanged(EquipmentRequest, PreviousStatus);
    end;

    /// <summary>
    /// Raised before the check that the approver is not the user who sent the request for approval.
    /// </summary>
    /// <param name="EquipmentRequest">The request being approved (passed by value).</param>
    /// <param name="IsHandled">Set to true to skip the self-approval check. Raise an error to deny the approval. The status rules cannot be bypassed.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckApproverAllowed(EquipmentRequest: Record "EQM Equipment Request"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised after a request status change was saved. Notification only: do not show UI or commit.
    /// </summary>
    /// <param name="EquipmentRequest">The request with its new status (passed by value).</param>
    /// <param name="PreviousStatus">The status before the change.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterRequestStatusChanged(EquipmentRequest: Record "EQM Equipment Request"; PreviousStatus: Enum "EQM Request Status")
    begin
    end;
}
