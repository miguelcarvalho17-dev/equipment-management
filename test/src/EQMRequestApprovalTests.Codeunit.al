namespace MiguelCarvalho.EquipmentManagement.Tests;

using Microsoft.Foundation.NoSeries;
using Microsoft.HumanResources.Employee;
using MiguelCarvalho.EquipmentManagement;
using System.TestLibraries.Utilities;

/// <summary>
/// Tests for FR-033 Approval Workflow (codeunit 50132, page 50135, fields 9-13 of table 50111, actions on pages
/// 50133/50134). Every test builds its own data in the test transaction (AutoRollback); there is no Commit.
/// To simulate a different sender, a test sets "Sent for Approval By" to another user name with Modify(false).
/// Scenario 17 of the plan (two managers, Reader permissions, views) is a manual sandbox check.
/// </summary>
codeunit 50189 "EQM Request Approval Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        ActiveEmployeeTok: Label 'EQMAPR-E1', Locked = true;
        CategoryTok: Label 'EQMAPR-C1', Locked = true;
        OtherCategoryTok: Label 'EQMAPR-C2', Locked = true;
        EmptyCategoryTok: Label 'EQMAPR-C3', Locked = true;
        TestSeriesTok: Label 'EQMAPRT', Locked = true;
        TestSeriesStartTok: Label 'TAPR0001', Locked = true;
        RequestNoTok: Label 'EQMAPR-R1', Locked = true;
        EquipmentNoTok: Label 'EQMAPR-Q1', Locked = true;
        EquipmentNo2Tok: Label 'EQMAPR-Q2', Locked = true;
        OtherEquipmentNoTok: Label 'EQMAPR-Q3', Locked = true;
        OtherUserTok: Label 'EQMAPR-OTHER', Locked = true;
        JustificationTok: Label 'Needs a laptop for the new project', Locked = true;
        CommentTok: Label 'Approved for the new project', Locked = true;
        RejectCommentTok: Label 'Budget is exhausted', Locked = true;
        // Copies of the labels in codeunit 50132, table 50111 and table 50100; labels of another app are not accessible.
        RequestRejectedErr: Label 'Equipment request %1 was rejected. A rejected request cannot be reopened; raise a new request instead.', Comment = '%1 = request number';
        NotOpenErr: Label 'You can only send equipment request %1 for approval when its status is Open. The current status is %2.', Comment = '%1 = request number, %2 = status';
        NotPendingErr: Label 'You can only approve or reject equipment request %1 when its status is Pending Approval. The current status is %2.', Comment = '%1 = request number, %2 = status';
        SelfApprovalErr: Label 'You cannot approve equipment request %1 because you sent it for approval. Another manager must approve it.', Comment = '%1 = request number';
        RejectionCommentRequiredErr: Label 'You must enter a comment to reject equipment request %1.', Comment = '%1 = request number';
        NotApprovedErr: Label 'You cannot assign equipment for request %1 because its status is %2. The request must be approved first.', Comment = '%1 = request number, %2 = status';
        EquipmentTypeMismatchErr: Label 'You cannot assign equipment %1 for request %2 because its category %3 is not the requested equipment type %4.', Comment = '%1 = equipment number, %2 = request number, %3 = equipment category code, %4 = requested equipment type';
        NoAvailableEquipmentMsg: Label 'There is no available equipment of type %1.', Comment = '%1 = requested equipment type';
        EmployeeNotActiveErr: Label 'You cannot raise an equipment request for employee %1 because the employee status is %2.', Comment = '%1 = employee number, %2 = employee status';
        RequestNotOpenErr: Label 'You cannot change equipment request %1 because its status is %2. Only open requests can be changed.', Comment = '%1 = request number, %2 = status';
        DeleteNotOpenErr: Label 'You cannot delete equipment request %1 because its status is %2. Only open requests can be deleted.', Comment = '%1 = request number, %2 = status';
        AlreadyAssignedErr: Label 'Equipment %1 is already assigned to employee %2. Return the equipment first, and then assign it again.', Comment = '%1 = equipment number, %2 = employee number';
        HandlerComment: Text[250];
        HandlerCommentSeen: Text;
        HandlerEquipmentNo: Code[20];
        HandlerAction: Action;
        ExpectedMessage: Text;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SendForApprovalMakesRequestPending()
    var
        Request: Record "EQM Equipment Request";
        RequestApprovalMgt: Codeunit "EQM Request Approval Mgt.";
    begin
        // [SCENARIO 1] Sending an Open request for approval makes it Pending Approval and records the sender
        Initialize();

        // [GIVEN] An Open valid request
        CreateRequest(Request, RequestNoTok, Request.Status::Open, '');

        // [WHEN] The request is sent for approval
        RequestApprovalMgt.SendForApproval(Request);

        // [THEN] Status is Pending Approval and the sender is the current user, in the variable and in the database
        Assert.AreEqual(Request.Status::"Pending Approval", Request.Status, 'The variable should be Pending Approval');
        Request.Get(RequestNoTok);
        Assert.AreEqual(Request.Status::"Pending Approval", Request.Status, 'The stored request should be Pending Approval');
        Assert.AreEqual(CopyStr(UserId(), 1, MaxStrLen(Request."Sent for Approval By")), Request."Sent for Approval By", 'The sender should be the current user');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SendForApprovalFailsForInactiveEmployee()
    var
        Request: Record "EQM Equipment Request";
        Employee: Record Employee;
        RequestApprovalMgt: Codeunit "EQM Request Approval Mgt.";
    begin
        // [SCENARIO 2] An Open request whose employee became Inactive cannot be sent for approval
        Initialize();

        // [GIVEN] An Open request whose employee is now Inactive
        CreateRequest(Request, RequestNoTok, Request.Status::Open, '');
        Employee.Get(ActiveEmployeeTok);
        Employee.Status := Employee.Status::Inactive;
        Employee.Modify(false);

        // [WHEN] The request is sent for approval
        asserterror RequestApprovalMgt.SendForApproval(Request);

        // [THEN] EmployeeNotActiveErr is raised. An error rolls back the test transaction, so the stored request is not read afterwards.
        Assert.ExpectedError(StrSubstNo(EmployeeNotActiveErr, ActiveEmployeeTok, Format(Employee.Status::Inactive)));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SendForApprovalFailsWhenPending()
    begin
        // [SCENARIO 3a] A Pending Approval request cannot be sent for approval
        // [GIVEN] / [WHEN] / [THEN] A Pending Approval request is sent for approval and the matching error is raised
        VerifySendFails(Enum::"EQM Request Status"::"Pending Approval", StrSubstNo(NotOpenErr, RequestNoTok, Format(Enum::"EQM Request Status"::"Pending Approval")));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SendForApprovalFailsWhenApproved()
    begin
        // [SCENARIO 3b] A Approved request cannot be sent for approval
        // [GIVEN] / [WHEN] / [THEN] A Approved request is sent for approval and the matching error is raised
        VerifySendFails(Enum::"EQM Request Status"::"Approved", StrSubstNo(NotOpenErr, RequestNoTok, Format(Enum::"EQM Request Status"::"Approved")));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SendForApprovalFailsWhenCompleted()
    begin
        // [SCENARIO 3c] A Completed request cannot be sent for approval
        // [GIVEN] / [WHEN] / [THEN] A Completed request is sent for approval and the matching error is raised
        VerifySendFails(Enum::"EQM Request Status"::"Completed", StrSubstNo(NotOpenErr, RequestNoTok, Format(Enum::"EQM Request Status"::"Completed")));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SendForApprovalFailsWhenRejected()
    begin
        // [SCENARIO 3d] A Rejected request cannot be sent for approval
        // [GIVEN] / [WHEN] / [THEN] A Rejected request is sent for approval and the matching error is raised
        VerifySendFails(Enum::"EQM Request Status"::"Rejected", StrSubstNo(RequestRejectedErr, RequestNoTok));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ApproveRecordsDecision()
    var
        Request: Record "EQM Equipment Request";
        RequestApprovalMgt: Codeunit "EQM Request Approval Mgt.";
    begin
        // [SCENARIO 4] Another manager approves a Pending request with a comment
        Initialize();

        // [GIVEN] A Pending request sent by another user
        CreateRequest(Request, RequestNoTok, Request.Status::"Pending Approval", OtherUserTok);

        // [WHEN] The request is approved with a comment
        RequestApprovalMgt.Approve(Request, CommentTok);

        // [THEN] Status, decider, decision date and comment are stored
        Request.Get(RequestNoTok);
        Assert.AreEqual(Request.Status::Approved, Request.Status, 'The request should be Approved');
        Assert.AreEqual(CopyStr(UserId(), 1, MaxStrLen(Request."Decided By")), Request."Decided By", 'Decided By should be the current user');
        Assert.AreEqual(WorkDate(), Request."Decision Date", 'Decision Date should be the work date');
        Assert.AreEqual(CommentTok, Request."Decision Comment", 'The comment should be stored');
        Assert.AreEqual(OtherUserTok, Request."Sent for Approval By", 'The sender should be unchanged');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ApproveAcceptsBlankComment()
    var
        Request: Record "EQM Equipment Request";
        RequestApprovalMgt: Codeunit "EQM Request Approval Mgt.";
    begin
        // [SCENARIO 4b] Boundary: an approval needs no comment
        Initialize();

        // [GIVEN] A Pending request sent by another user
        CreateRequest(Request, RequestNoTok, Request.Status::"Pending Approval", OtherUserTok);

        // [WHEN] The request is approved with a blank comment
        RequestApprovalMgt.Approve(Request, '');

        // [THEN] The request is Approved with an empty comment
        Request.Get(RequestNoTok);
        Assert.AreEqual(Request.Status::Approved, Request.Status, 'The request should be Approved');
        Assert.AreEqual('', Request."Decision Comment", 'The comment should be empty');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SelfApprovalIsRejected()
    var
        Request: Record "EQM Equipment Request";
        RequestApprovalMgt: Codeunit "EQM Request Approval Mgt.";
    begin
        // [SCENARIO 5] The user who sent the request cannot approve it
        Initialize();

        // [GIVEN] A Pending request sent by the current user
        CreateRequest(Request, RequestNoTok, Request.Status::"Pending Approval", CopyStr(UserId(), 1, MaxStrLen(Request."Sent for Approval By")));

        // [WHEN] The same user approves it
        asserterror RequestApprovalMgt.Approve(Request, CommentTok);

        // [THEN] SelfApprovalErr is raised (the rollback after the error makes a stored-state check meaningless)
        Assert.ExpectedError(StrSubstNo(SelfApprovalErr, RequestNoTok));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SelfApprovalCanBeHandledBySubscriber()
    var
        Request: Record "EQM Equipment Request";
        Subscriber: Codeunit "EQM Request Appr. Test Subscr";
        RequestApprovalMgt: Codeunit "EQM Request Approval Mgt.";
    begin
        // [SCENARIO 6] A subscriber that sets IsHandled on OnBeforeCheckApproverAllowed allows self-approval
        Initialize();

        // [GIVEN] A Pending request sent by the current user and a bound subscriber that handles the check
        CreateRequest(Request, RequestNoTok, Request.Status::"Pending Approval", CopyStr(UserId(), 1, MaxStrLen(Request."Sent for Approval By")));
        Subscriber.SetHandleApproverCheck(true);
        BindSubscription(Subscriber);

        // [WHEN] The same user approves it
        RequestApprovalMgt.Approve(Request, CommentTok);

        // [THEN] The approval succeeds and the event was raised once
        Request.Get(RequestNoTok);
        Assert.AreEqual(Request.Status::Approved, Request.Status, 'The request should be Approved');
        Assert.AreEqual(1, Subscriber.GetApproverCheckCount(), 'The approver check event should be raised once');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SenderCanRejectOwnRequest()
    var
        Request: Record "EQM Equipment Request";
        RequestApprovalMgt: Codeunit "EQM Request Approval Mgt.";
    begin
        // [SCENARIO 7] Rejecting records the decision; the sender may reject their own request
        Initialize();

        // [GIVEN] A Pending request sent by the current user
        CreateRequest(Request, RequestNoTok, Request.Status::"Pending Approval", CopyStr(UserId(), 1, MaxStrLen(Request."Sent for Approval By")));

        // [WHEN] The request is rejected with a comment
        RequestApprovalMgt.Reject(Request, RejectCommentTok);

        // [THEN] Status is Rejected and the decision fields are filled
        Request.Get(RequestNoTok);
        Assert.AreEqual(Request.Status::Rejected, Request.Status, 'The request should be Rejected');
        Assert.AreEqual(CopyStr(UserId(), 1, MaxStrLen(Request."Decided By")), Request."Decided By", 'Decided By should be the current user');
        Assert.AreEqual(WorkDate(), Request."Decision Date", 'Decision Date should be the work date');
        Assert.AreEqual(RejectCommentTok, Request."Decision Comment", 'The comment should be stored');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RejectRequiresCommentWhenEmpty()
    var
        Request: Record "EQM Equipment Request";
        RequestApprovalMgt: Codeunit "EQM Request Approval Mgt.";
    begin
        // [SCENARIO 8a] An empty comment cannot reject a request
        Initialize();

        // [GIVEN] A Pending request
        CreateRequest(Request, RequestNoTok, Request.Status::"Pending Approval", OtherUserTok);

        // [WHEN] Reject runs with an empty comment
        asserterror RequestApprovalMgt.Reject(Request, '');

        // [THEN] RejectionCommentRequiredErr
        Assert.ExpectedError(StrSubstNo(RejectionCommentRequiredErr, RequestNoTok));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RejectRequiresCommentWhenSpaces()
    var
        Request: Record "EQM Equipment Request";
        RequestApprovalMgt: Codeunit "EQM Request Approval Mgt.";
    begin
        // [SCENARIO 8b] A spaces-only comment cannot reject a request
        Initialize();

        // [GIVEN] A Pending request
        CreateRequest(Request, RequestNoTok, Request.Status::"Pending Approval", OtherUserTok);

        // [WHEN] Reject runs with spaces only
        asserterror RequestApprovalMgt.Reject(Request, '    ');

        // [THEN] RejectionCommentRequiredErr
        Assert.ExpectedError(StrSubstNo(RejectionCommentRequiredErr, RequestNoTok));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ApproveFailsWhenOpen()
    var
        Request: Record "EQM Equipment Request";
        RequestApprovalMgt: Codeunit "EQM Request Approval Mgt.";
    begin
        // [SCENARIO 9] Approve needs a Pending request (Open is refused)
        Initialize();

        // [GIVEN] A Open request
        CreateRequest(Request, RequestNoTok, Request.Status::"Open", OtherUserTok);

        // [WHEN] Approve runs
        asserterror RequestApprovalMgt.Approve(Request, CommentTok);

        // [THEN] The matching error is raised
        Assert.ExpectedError(StrSubstNo(NotPendingErr, RequestNoTok, Format(Enum::"EQM Request Status"::"Open")));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RejectFailsWhenOpen()
    var
        Request: Record "EQM Equipment Request";
        RequestApprovalMgt: Codeunit "EQM Request Approval Mgt.";
    begin
        // [SCENARIO 9] Reject needs a Pending request (Open is refused)
        Initialize();

        // [GIVEN] A Open request
        CreateRequest(Request, RequestNoTok, Request.Status::"Open", OtherUserTok);

        // [WHEN] Reject runs
        asserterror RequestApprovalMgt.Reject(Request, RejectCommentTok);

        // [THEN] The matching error is raised
        Assert.ExpectedError(StrSubstNo(NotPendingErr, RequestNoTok, Format(Enum::"EQM Request Status"::"Open")));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ApproveFailsWhenApproved()
    var
        Request: Record "EQM Equipment Request";
        RequestApprovalMgt: Codeunit "EQM Request Approval Mgt.";
    begin
        // [SCENARIO 9] Approve needs a Pending request (Approved is refused)
        Initialize();

        // [GIVEN] A Approved request
        CreateRequest(Request, RequestNoTok, Request.Status::"Approved", OtherUserTok);

        // [WHEN] Approve runs
        asserterror RequestApprovalMgt.Approve(Request, CommentTok);

        // [THEN] The matching error is raised
        Assert.ExpectedError(StrSubstNo(NotPendingErr, RequestNoTok, Format(Enum::"EQM Request Status"::"Approved")));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RejectFailsWhenApproved()
    var
        Request: Record "EQM Equipment Request";
        RequestApprovalMgt: Codeunit "EQM Request Approval Mgt.";
    begin
        // [SCENARIO 9] Reject needs a Pending request (Approved is refused)
        Initialize();

        // [GIVEN] A Approved request
        CreateRequest(Request, RequestNoTok, Request.Status::"Approved", OtherUserTok);

        // [WHEN] Reject runs
        asserterror RequestApprovalMgt.Reject(Request, RejectCommentTok);

        // [THEN] The matching error is raised
        Assert.ExpectedError(StrSubstNo(NotPendingErr, RequestNoTok, Format(Enum::"EQM Request Status"::"Approved")));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ApproveFailsWhenCompleted()
    var
        Request: Record "EQM Equipment Request";
        RequestApprovalMgt: Codeunit "EQM Request Approval Mgt.";
    begin
        // [SCENARIO 9] Approve needs a Pending request (Completed is refused)
        Initialize();

        // [GIVEN] A Completed request
        CreateRequest(Request, RequestNoTok, Request.Status::"Completed", OtherUserTok);

        // [WHEN] Approve runs
        asserterror RequestApprovalMgt.Approve(Request, CommentTok);

        // [THEN] The matching error is raised
        Assert.ExpectedError(StrSubstNo(NotPendingErr, RequestNoTok, Format(Enum::"EQM Request Status"::"Completed")));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RejectFailsWhenCompleted()
    var
        Request: Record "EQM Equipment Request";
        RequestApprovalMgt: Codeunit "EQM Request Approval Mgt.";
    begin
        // [SCENARIO 9] Reject needs a Pending request (Completed is refused)
        Initialize();

        // [GIVEN] A Completed request
        CreateRequest(Request, RequestNoTok, Request.Status::"Completed", OtherUserTok);

        // [WHEN] Reject runs
        asserterror RequestApprovalMgt.Reject(Request, RejectCommentTok);

        // [THEN] The matching error is raised
        Assert.ExpectedError(StrSubstNo(NotPendingErr, RequestNoTok, Format(Enum::"EQM Request Status"::"Completed")));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ApproveFailsWhenRejected()
    var
        Request: Record "EQM Equipment Request";
        RequestApprovalMgt: Codeunit "EQM Request Approval Mgt.";
    begin
        // [SCENARIO 9] Approve needs a Pending request (Rejected is refused)
        Initialize();

        // [GIVEN] A Rejected request
        CreateRequest(Request, RequestNoTok, Request.Status::"Rejected", OtherUserTok);

        // [WHEN] Approve runs
        asserterror RequestApprovalMgt.Approve(Request, CommentTok);

        // [THEN] The matching error is raised
        Assert.ExpectedError(StrSubstNo(RequestRejectedErr, RequestNoTok));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RejectFailsWhenRejected()
    var
        Request: Record "EQM Equipment Request";
        RequestApprovalMgt: Codeunit "EQM Request Approval Mgt.";
    begin
        // [SCENARIO 9] Reject needs a Pending request (Rejected is refused)
        Initialize();

        // [GIVEN] A Rejected request
        CreateRequest(Request, RequestNoTok, Request.Status::"Rejected", OtherUserTok);

        // [WHEN] Reject runs
        asserterror RequestApprovalMgt.Reject(Request, RejectCommentTok);

        // [THEN] The matching error is raised
        Assert.ExpectedError(StrSubstNo(RequestRejectedErr, RequestNoTok));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RejectedRequestCannotSendForApproval()
    var
        Request: Record "EQM Equipment Request";
        RequestApprovalMgt: Codeunit "EQM Request Approval Mgt.";
    begin
        // [SCENARIO 10] A Rejected request is final: SendForApproval is refused
        Initialize();
        CreateEquipment(EquipmentNoTok, CategoryTok);

        // [GIVEN] A Rejected request
        CreateRequest(Request, RequestNoTok, Request.Status::Rejected, OtherUserTok);

        // [WHEN] SendForApproval runs
        asserterror RequestApprovalMgt.SendForApproval(Request);

        // [THEN] RequestRejectedErr
        Assert.ExpectedError(StrSubstNo(RequestRejectedErr, RequestNoTok));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RejectedRequestCannotApprove()
    var
        Request: Record "EQM Equipment Request";
        RequestApprovalMgt: Codeunit "EQM Request Approval Mgt.";
    begin
        // [SCENARIO 10] A Rejected request is final: Approve is refused
        Initialize();
        CreateEquipment(EquipmentNoTok, CategoryTok);

        // [GIVEN] A Rejected request
        CreateRequest(Request, RequestNoTok, Request.Status::Rejected, OtherUserTok);

        // [WHEN] Approve runs
        asserterror RequestApprovalMgt.Approve(Request, CommentTok);

        // [THEN] RequestRejectedErr
        Assert.ExpectedError(StrSubstNo(RequestRejectedErr, RequestNoTok));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RejectedRequestCannotReject()
    var
        Request: Record "EQM Equipment Request";
        RequestApprovalMgt: Codeunit "EQM Request Approval Mgt.";
    begin
        // [SCENARIO 10] A Rejected request is final: Reject is refused
        Initialize();
        CreateEquipment(EquipmentNoTok, CategoryTok);

        // [GIVEN] A Rejected request
        CreateRequest(Request, RequestNoTok, Request.Status::Rejected, OtherUserTok);

        // [WHEN] Reject runs
        asserterror RequestApprovalMgt.Reject(Request, RejectCommentTok);

        // [THEN] RequestRejectedErr
        Assert.ExpectedError(StrSubstNo(RequestRejectedErr, RequestNoTok));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RejectedRequestCannotAssignEquipment()
    var
        Request: Record "EQM Equipment Request";
        RequestApprovalMgt: Codeunit "EQM Request Approval Mgt.";
    begin
        // [SCENARIO 10] A Rejected request is final: AssignEquipment is refused
        Initialize();
        CreateEquipment(EquipmentNoTok, CategoryTok);

        // [GIVEN] A Rejected request
        CreateRequest(Request, RequestNoTok, Request.Status::Rejected, OtherUserTok);

        // [WHEN] AssignEquipment runs
        asserterror RequestApprovalMgt.AssignEquipment(Request, EquipmentNoTok);

        // [THEN] RequestRejectedErr
        Assert.ExpectedError(StrSubstNo(RequestRejectedErr, RequestNoTok));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RejectedRequestCannotBeModified()
    var
        Request: Record "EQM Equipment Request";
    begin
        // [SCENARIO 10] A Rejected request cannot modified with triggers (lock of the request table)
        Initialize();

        // [GIVEN] A Rejected request
        CreateRequest(Request, RequestNoTok, Request.Status::Rejected, OtherUserTok);

        // [WHEN] The request is changed with triggers
        Request.Justification := 'Changed';
        asserterror Request.Modify(true);

        // [THEN] RequestNotOpenErr
        Assert.ExpectedError(StrSubstNo(RequestNotOpenErr, RequestNoTok, Format(Request.Status::Rejected)));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RejectedRequestCannotBeDeleted()
    var
        Request: Record "EQM Equipment Request";
    begin
        // [SCENARIO 10] A Rejected request cannot deleted with triggers (lock of the request table)
        Initialize();

        // [GIVEN] A Rejected request
        CreateRequest(Request, RequestNoTok, Request.Status::Rejected, OtherUserTok);

        // [WHEN] The request is changed with triggers
        asserterror Request.Delete(true);

        // [THEN] DeleteNotOpenErr
        Assert.ExpectedError(StrSubstNo(DeleteNotOpenErr, RequestNoTok, Format(Request.Status::Rejected)));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AssignEquipmentCompletesApprovedRequest()
    var
        Request: Record "EQM Equipment Request";
        Equipment: Record "EQM Equipment";
        Assignment: Record "EQM Equipment Assignment";
        RequestApprovalMgt: Codeunit "EQM Request Approval Mgt.";
    begin
        // [SCENARIO 11] Assigning available equipment of the requested type completes an Approved request
        Initialize();

        // [GIVEN] An Approved request and Available equipment of the requested type
        CreateRequest(Request, RequestNoTok, Request.Status::Approved, OtherUserTok);
        CreateEquipment(EquipmentNoTok, CategoryTok);

        // [WHEN] The equipment is assigned from the request
        RequestApprovalMgt.AssignEquipment(Request, EquipmentNoTok);

        // [THEN] The equipment is Assigned to the employee, an active assignment entry exists and the request is Completed
        Equipment.Get(EquipmentNoTok);
        Assert.AreEqual(Equipment.Status::Assigned, Equipment.Status, 'The equipment should be Assigned');
        Assert.AreEqual(ActiveEmployeeTok, Equipment."Assigned Employee No.", 'The equipment should be assigned to the request employee');
        Assignment.SetRange("Equipment No.", EquipmentNoTok);
        Assignment.SetRange("Employee No.", ActiveEmployeeTok);
        Assignment.SetRange(Status, Assignment.Status::Active);
        Assert.RecordCount(Assignment, 1);
        Request.Get(RequestNoTok);
        Assert.AreEqual(Request.Status::Completed, Request.Status, 'The request should be Completed');
        Assert.AreEqual(EquipmentNoTok, Request."Assigned Equipment No.", 'The assigned equipment should be recorded');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AssignEquipmentFailsWhenOpen()
    var
        Request: Record "EQM Equipment Request";
        RequestApprovalMgt: Codeunit "EQM Request Approval Mgt.";
    begin
        // [SCENARIO 12] Equipment cannot be assigned for a Open request
        Initialize();
        CreateEquipment(EquipmentNoTok, CategoryTok);

        // [GIVEN] A Open request
        CreateRequest(Request, RequestNoTok, Request.Status::"Open", OtherUserTok);

        // [WHEN] AssignEquipment runs
        asserterror RequestApprovalMgt.AssignEquipment(Request, EquipmentNoTok);

        // [THEN] NotApprovedErr
        Assert.ExpectedError(StrSubstNo(NotApprovedErr, RequestNoTok, Format(Enum::"EQM Request Status"::"Open")));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AssignEquipmentFailsWhenPendingApproval()
    var
        Request: Record "EQM Equipment Request";
        RequestApprovalMgt: Codeunit "EQM Request Approval Mgt.";
    begin
        // [SCENARIO 12] Equipment cannot be assigned for a Pending Approval request
        Initialize();
        CreateEquipment(EquipmentNoTok, CategoryTok);

        // [GIVEN] A Pending Approval request
        CreateRequest(Request, RequestNoTok, Request.Status::"Pending Approval", OtherUserTok);

        // [WHEN] AssignEquipment runs
        asserterror RequestApprovalMgt.AssignEquipment(Request, EquipmentNoTok);

        // [THEN] NotApprovedErr
        Assert.ExpectedError(StrSubstNo(NotApprovedErr, RequestNoTok, Format(Enum::"EQM Request Status"::"Pending Approval")));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AssignEquipmentRejectsWrongCategory()
    var
        Request: Record "EQM Equipment Request";
        RequestApprovalMgt: Codeunit "EQM Request Approval Mgt.";
    begin
        // [SCENARIO 13a] Equipment of another category is refused
        Initialize();

        // [GIVEN] An Approved request and Available equipment of another category
        CreateRequest(Request, RequestNoTok, Request.Status::Approved, OtherUserTok);
        CreateEquipment(OtherEquipmentNoTok, OtherCategoryTok);

        // [WHEN] The equipment of another category is assigned
        asserterror RequestApprovalMgt.AssignEquipment(Request, OtherEquipmentNoTok);

        // [THEN] EquipmentTypeMismatchErr
        Assert.ExpectedError(StrSubstNo(EquipmentTypeMismatchErr, OtherEquipmentNoTok, RequestNoTok, OtherCategoryTok, CategoryTok));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AssignEquipmentRejectsAlreadyAssignedEquipment()
    var
        Request: Record "EQM Equipment Request";
        Equipment: Record "EQM Equipment";
        RequestApprovalMgt: Codeunit "EQM Request Approval Mgt.";
    begin
        // [SCENARIO 13b] Equipment of the right category that is already assigned is refused
        Initialize();

        // [GIVEN] An Approved request and equipment of the right category that is already assigned
        CreateRequest(Request, RequestNoTok, Request.Status::Approved, OtherUserTok);
        CreateEquipment(EquipmentNo2Tok, CategoryTok);
        Equipment.Get(EquipmentNo2Tok);
        Equipment.AssignEmployee(ActiveEmployeeTok);

        // [WHEN] The already assigned equipment is assigned
        asserterror RequestApprovalMgt.AssignEquipment(Request, EquipmentNo2Tok);

        // [THEN] AlreadyAssignedErr (FR-004)
        Assert.ExpectedError(StrSubstNo(AlreadyAssignedErr, EquipmentNo2Tok, ActiveEmployeeTok));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AssignEquipmentFailsForInactiveEmployee()
    var
        Request: Record "EQM Equipment Request";
        Employee: Record Employee;
        RequestApprovalMgt: Codeunit "EQM Request Approval Mgt.";
    begin
        // [SCENARIO 14] An employee who became Inactive blocks the assignment, and nothing is changed
        Initialize();

        // [GIVEN] An Approved request, Available equipment and an employee who is now Inactive
        CreateRequest(Request, RequestNoTok, Request.Status::Approved, OtherUserTok);
        CreateEquipment(EquipmentNoTok, CategoryTok);
        Employee.Get(ActiveEmployeeTok);
        Employee.Status := Employee.Status::Inactive;
        Employee.Modify(false);

        // [WHEN] The equipment is assigned from the request
        asserterror RequestApprovalMgt.AssignEquipment(Request, EquipmentNoTok);

        // [THEN] An error is raised (FR-004 employee check); the rollback after the error makes a stored-state check meaningless
        Assert.ExpectedError(ActiveEmployeeTok);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure StatusChangedEventIsNotRaisedAfterFailedAction()
    var
        Request: Record "EQM Equipment Request";
        Subscriber: Codeunit "EQM Request Appr. Test Subscr";
        RequestApprovalMgt: Codeunit "EQM Request Approval Mgt.";
    begin
        // [SCENARIO 15a] OnAfterRequestStatusChanged is not raised after a failure
        Initialize();

        // [GIVEN] An Open request and a bound subscriber
        CreateRequest(Request, RequestNoTok, Request.Status::Open, '');
        BindSubscription(Subscriber);

        // [WHEN] A failing action runs (Approve on an Open request)
        asserterror RequestApprovalMgt.Approve(Request, CommentTok);

        // [THEN] The event was not raised (the subscriber keeps its in-memory state)
        Assert.AreEqual(0, Subscriber.GetStatusChangeCount(), 'No status change event should be raised after a failed action');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure StatusChangedEventIsRaisedPerTransition()
    var
        Request: Record "EQM Equipment Request";
        Subscriber: Codeunit "EQM Request Appr. Test Subscr";
        RequestApprovalMgt: Codeunit "EQM Request Approval Mgt.";
    begin
        // [SCENARIO 15] OnAfterRequestStatusChanged is raised after each successful transition
        Initialize();

        // [GIVEN] An Open request, Available equipment and a bound subscriber that also handles the approver check
        CreateRequest(Request, RequestNoTok, Request.Status::Open, '');
        CreateEquipment(EquipmentNoTok, CategoryTok);
        Subscriber.SetHandleApproverCheck(true);
        BindSubscription(Subscriber);

        // [WHEN] The request goes Open > Pending > Approved > Completed
        RequestApprovalMgt.SendForApproval(Request);
        RequestApprovalMgt.Approve(Request, CommentTok);
        RequestApprovalMgt.AssignEquipment(Request, EquipmentNoTok);

        // [THEN] The event was raised 3 times with the correct previous and new status
        Assert.AreEqual(3, Subscriber.GetStatusChangeCount(), 'The event should be raised once per transition');
        Assert.AreEqual(Request.Status::Open.AsInteger(), Subscriber.GetPreviousStatus(1), 'Previous status 1');
        Assert.AreEqual(Request.Status::"Pending Approval".AsInteger(), Subscriber.GetNewStatus(1), 'New status 1');
        Assert.AreEqual(Request.Status::"Pending Approval".AsInteger(), Subscriber.GetPreviousStatus(2), 'Previous status 2');
        Assert.AreEqual(Request.Status::Approved.AsInteger(), Subscriber.GetNewStatus(2), 'New status 2');
        Assert.AreEqual(Request.Status::Approved.AsInteger(), Subscriber.GetPreviousStatus(3), 'Previous status 3');
        Assert.AreEqual(Request.Status::Completed.AsInteger(), Subscriber.GetNewStatus(3), 'New status 3');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure StatusChangedEventIsRaisedForRejection()
    var
        Request: Record "EQM Equipment Request";
        Subscriber: Codeunit "EQM Request Appr. Test Subscr";
        RequestApprovalMgt: Codeunit "EQM Request Approval Mgt.";
    begin
        // [SCENARIO 15b] A rejection raises the event with Pending Approval as previous status
        Initialize();

        // [GIVEN] A Pending request and a bound subscriber
        CreateRequest(Request, RequestNoTok, Request.Status::"Pending Approval", OtherUserTok);
        BindSubscription(Subscriber);

        // [WHEN] The request is rejected
        RequestApprovalMgt.Reject(Request, RejectCommentTok);

        // [THEN] The event is raised once, Pending Approval to Rejected
        Assert.AreEqual(1, Subscriber.GetStatusChangeCount(), 'The event should be raised once');
        Assert.AreEqual(Request.Status::"Pending Approval".AsInteger(), Subscriber.GetPreviousStatus(1), 'Previous status');
        Assert.AreEqual(Request.Status::Rejected.AsInteger(), Subscriber.GetNewStatus(1), 'New status');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CardEnablesOnlyActionsOfTheStatus()
    var
        Request: Record "EQM Equipment Request";
        RequestCard: TestPage "EQM Equipment Request Card";
    begin
        // [SCENARIO 16a] The card enables the approval actions that fit the status
        Initialize();

        // [GIVEN] An Open request [WHEN] the card opens [THEN] only Send for Approval is enabled
        CreateRequest(Request, 'EQMAPR-P1', Request.Status::Open, '');
        RequestCard.OpenEdit();
        RequestCard.GoToKey('EQMAPR-P1');
        Assert.IsTrue(RequestCard.SendForApproval.Enabled(), 'Open: Send for Approval should be enabled');
        Assert.IsFalse(RequestCard.Approve.Enabled(), 'Open: Approve should be disabled');
        Assert.IsFalse(RequestCard.Reject.Enabled(), 'Open: Reject should be disabled');
        Assert.IsFalse(RequestCard.AssignEquipment.Enabled(), 'Open: Assign Equipment should be disabled');
        RequestCard.Close();

        // [GIVEN] A Pending request [THEN] only Approve and Reject are enabled
        CreateRequest(Request, 'EQMAPR-P2', Request.Status::"Pending Approval", OtherUserTok);
        RequestCard.OpenEdit();
        RequestCard.GoToKey('EQMAPR-P2');
        Assert.IsFalse(RequestCard.SendForApproval.Enabled(), 'Pending: Send for Approval should be disabled');
        Assert.IsTrue(RequestCard.Approve.Enabled(), 'Pending: Approve should be enabled');
        Assert.IsTrue(RequestCard.Reject.Enabled(), 'Pending: Reject should be enabled');
        Assert.IsFalse(RequestCard.AssignEquipment.Enabled(), 'Pending: Assign Equipment should be disabled');
        RequestCard.Close();

        // [GIVEN] An Approved request [THEN] only Assign Equipment is enabled
        CreateRequest(Request, 'EQMAPR-P3', Request.Status::Approved, OtherUserTok);
        RequestCard.OpenEdit();
        RequestCard.GoToKey('EQMAPR-P3');
        Assert.IsFalse(RequestCard.SendForApproval.Enabled(), 'Approved: Send for Approval should be disabled');
        Assert.IsFalse(RequestCard.Approve.Enabled(), 'Approved: Approve should be disabled');
        Assert.IsFalse(RequestCard.Reject.Enabled(), 'Approved: Reject should be disabled');
        Assert.IsTrue(RequestCard.AssignEquipment.Enabled(), 'Approved: Assign Equipment should be enabled');
        RequestCard.Close();

        // [GIVEN] A Completed request [THEN] no action is enabled
        CreateRequest(Request, 'EQMAPR-P4', Request.Status::Completed, OtherUserTok);
        RequestCard.OpenEdit();
        RequestCard.GoToKey('EQMAPR-P4');
        Assert.IsFalse(RequestCard.SendForApproval.Enabled(), 'Completed: Send for Approval should be disabled');
        Assert.IsFalse(RequestCard.Approve.Enabled(), 'Completed: Approve should be disabled');
        Assert.IsFalse(RequestCard.Reject.Enabled(), 'Completed: Reject should be disabled');
        Assert.IsFalse(RequestCard.AssignEquipment.Enabled(), 'Completed: Assign Equipment should be disabled');
        RequestCard.Close();

        // [GIVEN] A Rejected request [THEN] no action is enabled
        CreateRequest(Request, 'EQMAPR-P5', Request.Status::Rejected, OtherUserTok);
        RequestCard.OpenEdit();
        RequestCard.GoToKey('EQMAPR-P5');
        Assert.IsFalse(RequestCard.SendForApproval.Enabled(), 'Rejected: Send for Approval should be disabled');
        Assert.IsFalse(RequestCard.Approve.Enabled(), 'Rejected: Approve should be disabled');
        Assert.IsFalse(RequestCard.Reject.Enabled(), 'Rejected: Reject should be disabled');
        Assert.IsFalse(RequestCard.AssignEquipment.Enabled(), 'Rejected: Assign Equipment should be disabled');
        RequestCard.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('DecisionDialogHandler')]
    procedure RejectActionUsesDialogComment()
    var
        Request: Record "EQM Equipment Request";
        RequestCard: TestPage "EQM Equipment Request Card";
    begin
        // [SCENARIO 16b] The Reject action collects the comment in the dialog and rejects the request
        Initialize();

        // [GIVEN] A Pending request on the card and a dialog handler that enters a comment and clicks OK
        CreateRequest(Request, RequestNoTok, Request.Status::"Pending Approval", OtherUserTok);
        HandlerComment := RejectCommentTok;
        HandlerAction := Action::OK;
        RequestCard.OpenEdit();
        RequestCard.GoToKey(RequestNoTok);

        // [WHEN] Reject is invoked
        RequestCard.Reject.Invoke();

        // [THEN] The request is Rejected with the dialog comment
        Request.Get(RequestNoTok);
        Assert.AreEqual(Request.Status::Rejected, Request.Status, 'The request should be Rejected');
        Assert.AreEqual(RejectCommentTok, Request."Decision Comment", 'The dialog comment should be stored');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('DecisionDialogHandler')]
    procedure CancellingDecisionDialogChangesNothing()
    var
        Request: Record "EQM Equipment Request";
        RequestApprovalMgt: Codeunit "EQM Request Approval Mgt.";
    begin
        // [SCENARIO 16c] Cancelling the decision dialog leaves the request Pending
        Initialize();

        // [GIVEN] A Pending request sent by another user and a dialog handler that clicks Cancel
        CreateRequest(Request, RequestNoTok, Request.Status::"Pending Approval", OtherUserTok);
        HandlerComment := CommentTok;
        HandlerAction := Action::Cancel;

        // [WHEN] The request is approved with the dialog
        RequestApprovalMgt.ApproveWithDialog(Request);

        // [THEN] The request stays Pending Approval without a decision
        Request.Get(RequestNoTok);
        Assert.AreEqual(Request.Status::"Pending Approval", Request.Status, 'The request should stay Pending Approval');
        Assert.AreEqual('', Request."Decided By", 'No decider should be recorded');
        Assert.IsTrue(HandlerCommentSeen <> '', 'The dialog should have been shown (the handler records the instruction)');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('LookupMessageHandler')]
    procedure LookupShowsMessageWhenNoEquipmentAvailable()
    var
        Request: Record "EQM Equipment Request";
        RequestApprovalMgt: Codeunit "EQM Request Approval Mgt.";
    begin
        // [SCENARIO 16d] Without available equipment of the type, a message is shown and the request stays Approved
        Initialize();

        // [GIVEN] An Approved request for a type without any equipment
        CreateRequest(Request, RequestNoTok, Request.Status::Approved, OtherUserTok);
        Request."Requested Equipment Type" := EmptyCategoryTok;
        Request.Modify(false);
        ExpectedMessage := StrSubstNo(NoAvailableEquipmentMsg, EmptyCategoryTok);

        // [WHEN] Assign Equipment with lookup runs
        RequestApprovalMgt.AssignEquipmentWithLookup(Request);

        // [THEN] The message handler verified NoAvailableEquipmentMsg and the request stays Approved
        Request.Get(RequestNoTok);
        Assert.AreEqual(Request.Status::Approved, Request.Status, 'The request should stay Approved');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('EquipmentLookupHandler')]
    procedure LookupAssignsChosenEquipment()
    var
        Request: Record "EQM Equipment Request";
        Equipment: Record "EQM Equipment";
        RequestApprovalMgt: Codeunit "EQM Request Approval Mgt.";
    begin
        // [SCENARIO 16e] The lookup lists available equipment of the type; the chosen one is assigned
        Initialize();

        // [GIVEN] An Approved request and available equipment of the type
        CreateRequest(Request, RequestNoTok, Request.Status::Approved, OtherUserTok);
        CreateEquipment(EquipmentNoTok, CategoryTok);
        HandlerEquipmentNo := EquipmentNoTok;

        // [WHEN] Assign Equipment with lookup runs and the user picks the equipment
        RequestApprovalMgt.AssignEquipmentWithLookup(Request);

        // [THEN] The request is Completed with that equipment, which is Assigned
        Request.Get(RequestNoTok);
        Assert.AreEqual(Request.Status::Completed, Request.Status, 'The request should be Completed');
        Assert.AreEqual(EquipmentNoTok, Request."Assigned Equipment No.", 'The chosen equipment should be recorded');
        Equipment.Get(EquipmentNoTok);
        Assert.AreEqual(Equipment.Status::Assigned, Equipment.Status, 'The equipment should be Assigned');
    end;

    local procedure VerifySendFails(NewStatus: Enum "EQM Request Status"; ExpectedError: Text)
    var
        Request: Record "EQM Equipment Request";
        RequestApprovalMgt: Codeunit "EQM Request Approval Mgt.";
    begin
        Initialize();
        CreateRequest(Request, RequestNoTok, NewStatus, OtherUserTok);
        asserterror RequestApprovalMgt.SendForApproval(Request);
        Assert.ExpectedError(ExpectedError);
    end;

    local procedure CreateRequest(var Request: Record "EQM Equipment Request"; RequestNo: Code[20]; NewStatus: Enum "EQM Request Status"; SentBy: Code[50])
    begin
        // Requests are always inserted as Open (OnInsert); other statuses are set without triggers.
        Request.Init();
        Request."No." := RequestNo;
        Request."Employee No." := ActiveEmployeeTok;
        Request."Requested Equipment Type" := CategoryTok;
        Request.Justification := JustificationTok;
        Request.Insert(true);
        if NewStatus <> Request.Status::Open then begin
            Request.Status := NewStatus;
            Request."Sent for Approval By" := SentBy;
            Request.Modify(false);
        end;
    end;

    local procedure CreateEquipment(EquipmentNo: Code[20]; CategoryCode: Code[20])
    var
        Equipment: Record "EQM Equipment";
    begin
        Equipment.Init();
        Equipment."No." := EquipmentNo;
        Equipment.Description := 'EQMAPR test equipment';
        Equipment."Category Code" := CategoryCode;
        Equipment.Insert(true);
    end;

    local procedure Initialize()
    var
        EquipmentSetup: Record "EQM Equipment Setup";
    begin
        // Everything runs in the test transaction, which is rolled back (AutoRollback), so nothing is committed or cleaned up.
        WorkDate(Today());

        CreateCategory(CategoryTok);
        CreateCategory(OtherCategoryTok);
        CreateCategory(EmptyCategoryTok);
        CreateEmployee(ActiveEmployeeTok);
        CreateNoSeries(TestSeriesTok, TestSeriesStartTok);

        if not EquipmentSetup.Get() then begin
            EquipmentSetup.Init();
            EquipmentSetup.Insert();
        end;
        EquipmentSetup."Request Nos." := TestSeriesTok;
        EquipmentSetup.Modify();
    end;

    local procedure CreateCategory(CategoryCode: Code[20])
    var
        Category: Record "EQM Equipment Category";
    begin
        if Category.Get(CategoryCode) then
            Category.Delete();
        Category.Init();
        Category.Code := CategoryCode;
        Category.Description := 'EQMAPR category';
        Category.Active := true;
        Category.Insert();
    end;

    local procedure CreateEmployee(EmployeeNo: Code[20])
    var
        Employee: Record Employee;
    begin
        Employee.Init();
        Employee."No." := EmployeeNo;
        Employee."First Name" := 'EQMAPR';
        Employee."Last Name" := EmployeeNo;
        Employee.Status := Employee.Status::Active;
        Employee."Privacy Blocked" := false;
        Employee.Insert(false);
    end;

    local procedure CreateNoSeries(SeriesCode: Code[20]; StartingNo: Code[20])
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        NoSeries.Init();
        NoSeries.Code := SeriesCode;
        NoSeries.Description := 'EQMAPR test series';
        NoSeries."Default Nos." := true;
        NoSeries."Manual Nos." := true;
        NoSeries.Insert();

        NoSeriesLine.Init();
        NoSeriesLine."Series Code" := SeriesCode;
        NoSeriesLine."Line No." := 10000;
        NoSeriesLine.Validate("Starting No.", StartingNo);
        NoSeriesLine.Validate("Increment-by No.", 1);
        NoSeriesLine.Insert(true);
    end;

    [ModalPageHandler]
    procedure DecisionDialogHandler(var RequestDecision: TestPage "EQM Request Decision")
    begin
        HandlerCommentSeen := RequestDecision.InstructionText.Value();
        RequestDecision.CommentText.SetValue(HandlerComment);
        if HandlerAction = Action::OK then
            RequestDecision.OK().Invoke()
        else
            RequestDecision.Cancel().Invoke();
    end;

    [MessageHandler]
    procedure LookupMessageHandler(Message: Text[1024])
    begin
        Assert.AreEqual(ExpectedMessage, Message, 'The no-equipment message should match');
    end;

    [ModalPageHandler]
    procedure EquipmentLookupHandler(var EquipmentList: TestPage "EQM Equipment List")
    begin
        EquipmentList.GoToKey(HandlerEquipmentNo);
        EquipmentList.OK().Invoke();
    end;
}
