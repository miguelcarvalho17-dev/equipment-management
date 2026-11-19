namespace MiguelCarvalho.EquipmentManagement.Tests;

using Microsoft.Foundation.NoSeries;
using Microsoft.HumanResources.Employee;
using MiguelCarvalho.EquipmentManagement;
using System.Environment.Configuration;
using System.TestLibraries.Utilities;

/// <summary>
/// FR-046 Integration Tests. Each test runs a complete business process of the Equipment Management app (Assignment
/// Flow, Maintenance Flow, Approval Flow, Notification Flow) as a chain of real business calls in one transaction and
/// checks the effects across modules: assignment history, audit trail, integration outbox, maintenance history and log,
/// equipment requests and notifications. Every test builds its own data (AutoRollback, no Commit). A failed statement
/// (asserterror) rolls back the whole test transaction, so each negative test has exactly one asserterror, as its last
/// action, and only checks the error text afterwards.
/// </summary>
codeunit 50158 "EQM Process Integration Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        FeatureMgt: Codeunit "EQM Feature Mgt.";
        MaintenanceMgt: Codeunit "EQM Maintenance Mgt.";
        NotificationMgt: Codeunit "EQM Notification Mgt.";
        WarrantyAlertMgt: Codeunit "EQM Warranty Alert Mgt.";
        RequestApprovalMgt: Codeunit "EQM Request Approval Mgt.";
        Counter: Integer;
        SentNotificationIds: List of [Text];
        LastSentMessage: Text;
        EquipmentNoTok: Label 'EQMPIT%1X', Locked = true;
        CategoryCodeTok: Label 'EQMPITC%1', Locked = true;
        EmployeeNoTok: Label 'EQMPITE%1', Locked = true;
        MaintenanceNoTok: Label 'EQMPITM%1', Locked = true;
        FirstNameTok: Label 'EQMPIT', Locked = true;
        CounterFormatTok: Label '<Integer,4><Filler Character,0>', Locked = true;
        SequenceSeparatorTok: Label ',', Locked = true;
        RequestSeriesTok: Label 'EQMPITS%1', Locked = true;
        RequestStartNoTok: Label 'EQMPITR%1', Locked = true;
        OtherUserTok: Label 'EQMPIT-OTHER', Locked = true;
        JustificationTok: Label 'EQMPIT justification', Locked = true;
        CommentTok: Label 'EQMPIT approval comment', Locked = true;
        RejectCommentTok: Label 'EQMPIT rejection comment', Locked = true;
        // Copies of the labels in table 50100, codeunit 50103 and codeunit 50132; labels of another app are not accessible.
        MaintenanceOpenAssignErr: Label 'You cannot assign equipment %1 because it has open maintenance. Post the open maintenance records of the equipment first.', Comment = '%1 = equipment number';
        EmployeeHasAssignedEquipmentErr: Label 'You cannot delete employee %1 because one or more equipment records are assigned to the employee.', Comment = '%1 = employee number';
        RequestRejectedErr: Label 'Equipment request %1 was rejected. A rejected request cannot be reopened; raise a new request instead.', Comment = '%1 = request number';

    // ---------------------------------------------------------------------------------------------------------------
    // Assignment Flow
    // ---------------------------------------------------------------------------------------------------------------

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AssignmentLifecycleKeepsHistoryAuditAndOutboxInStep()
    var
        Employee1: Record Employee;
        Employee2: Record Employee;
        Equipment: Record "EQM Equipment";
        Assignment: Record "EQM Equipment Assignment";
        AuditEntry: Record "EQM Equipment Audit Entry";
        Expected: List of [Text];
        CategoryCode: Code[20];
    begin
        // [SCENARIO] Create, assign, return and reassign as one process keeps history, audit trail and outbox in step
        Initialize();

        // [GIVEN] Two active employees and a new category
        CreateEmployee(Employee1);
        CreateEmployee(Employee2);
        CategoryCode := CreateCategory();

        // [WHEN] Equipment X is created, assigned to the first employee, returned and assigned to the second employee
        CreateEquipment(Equipment, CategoryCode);
        Equipment.AssignEmployee(Employee1."No.");
        Equipment.Get(Equipment."No.");
        Equipment.UnassignEmployee();
        Equipment.Get(Equipment."No.");
        Equipment.AssignEmployee(Employee2."No.");

        // [THEN] X is Assigned to the second employee
        Equipment.Get(Equipment."No.");
        Assert.AreEqual(Equipment.Status::Assigned, Equipment.Status, 'X should be Assigned');
        Assert.AreEqual(Employee2."No.", Equipment."Assigned Employee No.", 'X should be assigned to the second employee');

        // [THEN] There are two assignment entries: Closed for the first employee, Active for the second employee
        Assert.AreEqual(2, CountAssignments(Equipment."No.", Assignment.Status::Active) + CountAssignments(Equipment."No.", Assignment.Status::Closed), 'There should be two assignment entries');
        Assignment.SetRange("Equipment No.", Equipment."No.");
        Assignment.SetRange(Status, Assignment.Status::Closed);
        Assignment.FindFirst();
        Assert.AreEqual(Employee1."No.", Assignment."Employee No.", 'The closed entry should be for the first employee');
        Assert.AreEqual(WorkDate(), Assignment."Closing Date", 'The closed entry should have the work date as closing date');
        Assignment.SetRange(Status, Assignment.Status::Active);
        Assignment.FindFirst();
        Assert.AreEqual(Employee2."No.", Assignment."Employee No.", 'The active entry should be for the second employee');

        // [THEN] The audit sequence is Created, Assigned, Returned, Assigned, and the last Assigned entry points to the active entry
        Expected.Add(Format(Enum::"EQM Audit Event Type"::Created));
        Expected.Add(Format(Enum::"EQM Audit Event Type"::Assigned));
        Expected.Add(Format(Enum::"EQM Audit Event Type"::Returned));
        Expected.Add(Format(Enum::"EQM Audit Event Type"::Assigned));
        Assert.AreEqual(JoinList(Expected), GetAuditSequence(Equipment."No.", 0), 'The audit sequence should match the process');
        AuditEntry.SetRange("Equipment No.", Equipment."No.");
        AuditEntry.SetRange("Event Type", AuditEntry."Event Type"::Assigned);
        AuditEntry.FindLast();
        Assert.AreEqual(GetActiveAssignmentEntryNo(Equipment."No."), AuditEntry."Assignment Entry No.", 'The last Assigned audit entry should have the active assignment entry no.');

        // [THEN] The outbox sequence is Equipment Created, Equipment Assigned, Equipment Returned, Equipment Assigned
        Clear(Expected);
        Expected.Add(Format(Enum::"EQM Integration Event Type"::"Equipment Created"));
        Expected.Add(Format(Enum::"EQM Integration Event Type"::"Equipment Assigned"));
        Expected.Add(Format(Enum::"EQM Integration Event Type"::"Equipment Returned"));
        Expected.Add(Format(Enum::"EQM Integration Event Type"::"Equipment Assigned"));
        Assert.AreEqual(JoinList(Expected), GetOutboxSequence(Equipment."No."), 'The outbox sequence should match the process');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MaintenanceTakesEquipmentBackAndBlocksReassignment()
    var
        Employee: Record Employee;
        Equipment: Record "EQM Equipment";
        MaintenanceRecord: Record "EQM Maintenance Record";
        Assignment: Record "EQM Equipment Assignment";
    begin
        // [SCENARIO] (negative) Maintenance takes assigned equipment back and then blocks assigning it again
        Initialize();

        // [GIVEN] Equipment X assigned to an employee, and a maintenance record registered for X
        CreateEmployee(Employee);
        CreateEquipment(Equipment, CreateCategory());
        Equipment.AssignEmployee(Employee."No.");
        Equipment.Get(Equipment."No.");
        InitMaintenance(MaintenanceRecord, Equipment."No.", Today());
        MaintenanceRecord.Insert(true);

        // [GIVEN] X is In Maintenance with no employee, and the employee's entry is Closed
        Equipment.Get(Equipment."No.");
        Assert.AreEqual(Equipment.Status::"In Maintenance", Equipment.Status, 'X should be In Maintenance');
        Assert.AreEqual('', Equipment."Assigned Employee No.", 'X should have no employee');
        Assert.AreEqual(1, CountAssignments(Equipment."No.", Assignment.Status::Closed), 'The entry should be Closed');
        Assert.AreEqual(0, CountAssignments(Equipment."No.", Assignment.Status::Active), 'No entry should be Active');

        // [WHEN] X is assigned to the employee again
        asserterror Equipment.AssignEmployee(Employee."No.");

        // [THEN] The open maintenance error names X
        Assert.ExpectedError(StrSubstNo(MaintenanceOpenAssignErr, Equipment."No."));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EmployeeWithAssignedEquipmentCannotBeDeleted()
    var
        Employee: Record Employee;
        Equipment: Record "EQM Equipment";
    begin
        // [SCENARIO] (negative) An employee with assigned equipment cannot be deleted
        Initialize();

        // [GIVEN] Equipment X assigned to an employee
        CreateEmployee(Employee);
        CreateEquipment(Equipment, CreateCategory());
        Equipment.AssignEmployee(Employee."No.");

        // [WHEN] The employee is deleted
        asserterror Employee.Delete(true);

        // [THEN] The error names the employee
        Assert.ExpectedError(StrSubstNo(EmployeeHasAssignedEquipmentErr, Employee."No."));
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EmployeeCanBeDeletedAfterTheEquipmentIsReturned()
    var
        Employee: Record Employee;
        Equipment: Record "EQM Equipment";
        Assignment: Record "EQM Equipment Assignment";
        EmployeeNo: Code[20];
    begin
        // [SCENARIO] An employee can be deleted once the equipment is returned, and the assignment history is kept
        Initialize();

        // [GIVEN] Equipment X assigned to an employee and returned
        CreateEmployee(Employee);
        EmployeeNo := Employee."No.";
        CreateEquipment(Equipment, CreateCategory());
        Equipment.AssignEmployee(EmployeeNo);
        Equipment.Get(Equipment."No.");
        Equipment.UnassignEmployee();

        // [WHEN] The employee is deleted
        Employee.Delete(true);

        // [THEN] The employee is gone, the Closed assignment entry still exists and X is Available
        Assert.IsFalse(Employee.Get(EmployeeNo), 'The employee should be deleted');
        Assignment.SetRange("Equipment No.", Equipment."No.");
        Assignment.SetRange("Employee No.", EmployeeNo);
        Assignment.SetRange(Status, Assignment.Status::Closed);
        Assert.IsFalse(Assignment.IsEmpty(), 'The closed assignment entry should be kept');
        Equipment.Get(Equipment."No.");
        Assert.AreEqual(Equipment.Status::Available, Equipment.Status, 'X should be Available');
    end;

    // ---------------------------------------------------------------------------------------------------------------
    // Maintenance Flow
    // ---------------------------------------------------------------------------------------------------------------

    [Test]
    [HandlerFunctions('ConfirmYesHandler,SendNotificationHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AssignedEquipmentGoesThroughMaintenanceAndIsReassigned()
    var
        Employee: Record Employee;
        Equipment: Record "EQM Equipment";
        MaintenanceRecord: Record "EQM Maintenance Record";
        HistoryEntry: Record "EQM Maintenance History Entry";
        Assignment: Record "EQM Equipment Assignment";
        AuditEntry: Record "EQM Equipment Audit Entry";
        Expected: List of [Text];
        FirstAssignedEntryNo: Integer;
        Cost: Decimal;
        Posted: Boolean;
    begin
        // [SCENARIO] Assigned equipment goes through maintenance and is assigned again
        Initialize();

        // [GIVEN] Equipment X assigned to an employee
        CreateEmployee(Employee);
        CreateEquipment(Equipment, CreateCategory());
        Equipment.AssignEmployee(Employee."No.");
        Equipment.Get(Equipment."No.");
        AuditEntry.SetRange("Equipment No.", Equipment."No.");
        AuditEntry.SetRange("Event Type", AuditEntry."Event Type"::Assigned);
        AuditEntry.FindFirst();
        FirstAssignedEntryNo := AuditEntry."Entry No.";

        // [WHEN] A Corrective record is registered, posted with confirmation, and X is assigned to the employee again
        Cost := 1 + Random(1000);
        InitMaintenance(MaintenanceRecord, Equipment."No.", Today());
        MaintenanceRecord."Maintenance Type" := MaintenanceRecord."Maintenance Type"::Corrective;
        MaintenanceRecord.Cost := Cost;
        MaintenanceRecord.Insert(true);
        Posted := MaintenanceMgt.PostWithConfirmation(MaintenanceRecord);
        Equipment.Get(Equipment."No.");
        Equipment.AssignEmployee(Employee."No.");

        // [THEN] The posting succeeded and the record is Posted
        Assert.IsTrue(Posted, 'PostWithConfirmation should return true');
        MaintenanceRecord.Get(MaintenanceRecord."No.");
        Assert.AreEqual(MaintenanceRecord.Status::Posted, MaintenanceRecord.Status, 'The record should be Posted');

        // [THEN] There is one history entry with the equipment, the cost, the type and the current user
        HistoryEntry.SetRange("Maintenance No.", MaintenanceRecord."No.");
        Assert.AreEqual(1, HistoryEntry.Count(), 'There should be one history entry');
        HistoryEntry.FindFirst();
        Assert.AreEqual(Equipment."No.", HistoryEntry."Equipment No.", 'The history entry should be for X');
        Assert.AreEqual(Cost, HistoryEntry.Cost, 'The history entry should have the cost');
        Assert.AreEqual(HistoryEntry."Maintenance Type"::Corrective, HistoryEntry."Maintenance Type", 'The history entry should be Corrective');
        Assert.AreEqual(CopyStr(UserId(), 1, MaxStrLen(HistoryEntry."Posted By")), HistoryEntry."Posted By", 'The history entry should be posted by the current user');

        // [THEN] X is Assigned to the employee with one Closed and one Active entry
        Equipment.Get(Equipment."No.");
        Assert.AreEqual(Equipment.Status::Assigned, Equipment.Status, 'X should be Assigned');
        Assert.AreEqual(Employee."No.", Equipment."Assigned Employee No.", 'X should be assigned to the employee');
        Assert.AreEqual(1, CountAssignments(Equipment."No.", Assignment.Status::Closed), 'There should be one Closed entry');
        Assert.AreEqual(1, CountAssignments(Equipment."No.", Assignment.Status::Active), 'There should be one Active entry');

        // [THEN] After the first Assigned entry the audit trail has Returned (In Maintenance), Sent to Maintenance (record), Updated (Available), Assigned
        Expected.Add(Format(Enum::"EQM Audit Event Type"::Returned));
        Expected.Add(Format(Enum::"EQM Audit Event Type"::"Sent to Maintenance"));
        Expected.Add(Format(Enum::"EQM Audit Event Type"::Updated));
        Expected.Add(Format(Enum::"EQM Audit Event Type"::Assigned));
        Assert.AreEqual(JoinList(Expected), GetAuditSequence(Equipment."No.", FirstAssignedEntryNo), 'The audit sequence after the first assignment should match the process');
        FindAuditEntry(AuditEntry, Equipment."No.", AuditEntry."Event Type"::Returned, FirstAssignedEntryNo);
        Assert.AreEqual(AuditEntry."Status After"::"In Maintenance", AuditEntry."Status After", 'Returned should have Status After In Maintenance');
        FindAuditEntry(AuditEntry, Equipment."No.", AuditEntry."Event Type"::"Sent to Maintenance", FirstAssignedEntryNo);
        Assert.AreEqual(MaintenanceRecord."No.", AuditEntry."Maintenance No.", 'Sent to Maintenance should name the record');
        FindAuditEntry(AuditEntry, Equipment."No.", AuditEntry."Event Type"::Updated, FirstAssignedEntryNo);
        Assert.AreEqual(AuditEntry."Status After"::Available, AuditEntry."Status After", 'Updated should have Status After Available');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler,SendNotificationHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CorrectionBeforePostingIsLoggedAndReachesTheHistory()
    var
        Equipment: Record "EQM Equipment";
        MaintenanceRecord: Record "EQM Maintenance Record";
        HistoryEntry: Record "EQM Maintenance History Entry";
        LogEntry: Record "EQM Maintenance Log Entry";
        Expected: List of [Text];
        FirstCost: Decimal;
        SecondCost: Decimal;
    begin
        // [SCENARIO] A correction before posting is logged and reaches the maintenance history
        Initialize();

        // [GIVEN] Available equipment X and an open record with a cost
        CreateEquipment(Equipment, CreateCategory());
        FirstCost := 1 + Random(1000);
        InitMaintenance(MaintenanceRecord, Equipment."No.", Today());
        MaintenanceRecord.Cost := FirstCost;
        MaintenanceRecord.Insert(true);

        // [WHEN] The cost is changed and the record is posted with confirmation
        SecondCost := FirstCost + 1 + Random(1000);
        MaintenanceRecord.Validate(Cost, SecondCost);
        MaintenanceRecord.Modify(true);
        MaintenanceMgt.PostWithConfirmation(MaintenanceRecord);

        // [THEN] The log sequence is Registered, Changed, Posted
        Expected.Add(Format(Enum::"EQM Maintenance Log Action"::Registered));
        Expected.Add(Format(Enum::"EQM Maintenance Log Action"::Changed));
        Expected.Add(Format(Enum::"EQM Maintenance Log Action"::Posted));
        Assert.AreEqual(JoinList(Expected), GetLogSequence(MaintenanceRecord."No."), 'The log sequence should match the process');

        // [THEN] The Changed entry names the cost field, the old and new values and the current user
        LogEntry.SetRange("Maintenance No.", MaintenanceRecord."No.");
        LogEntry.SetRange("Action", LogEntry."Action"::Changed);
        LogEntry.FindFirst();
        Assert.AreEqual(MaintenanceRecord.FieldNo(Cost), LogEntry."Field No.", 'The Changed entry should be for the cost field');
        Assert.AreEqual(Format(FirstCost, 0, 9), LogEntry."Old Value", 'The Changed entry should have the old cost');
        Assert.AreEqual(Format(SecondCost, 0, 9), LogEntry."New Value", 'The Changed entry should have the new cost');
        Assert.AreEqual(CopyStr(UserId(), 1, MaxStrLen(LogEntry."User ID")), LogEntry."User ID", 'The Changed entry should have the current user');

        // [THEN] The history entry has the corrected cost
        HistoryEntry.SetRange("Maintenance No.", MaintenanceRecord."No.");
        HistoryEntry.FindFirst();
        Assert.AreEqual(SecondCost, HistoryEntry.Cost, 'The history entry should have the corrected cost');
    end;

    [Test]
    [HandlerFunctions('ConfirmNoHandler,SendNotificationHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DecliningThePostingConfirmationChangesNothing()
    var
        Equipment: Record "EQM Equipment";
        MaintenanceRecord: Record "EQM Maintenance Record";
        HistoryEntry: Record "EQM Maintenance History Entry";
        Expected: List of [Text];
        Posted: Boolean;
    begin
        // [SCENARIO] (negative) Declining the posting confirmation changes nothing
        Initialize();

        // [GIVEN] Available equipment X with an open maintenance record
        CreateEquipment(Equipment, CreateCategory());
        InitMaintenance(MaintenanceRecord, Equipment."No.", Today());
        MaintenanceRecord.Insert(true);

        // [WHEN] The user posts the record and answers No
        Posted := MaintenanceMgt.PostWithConfirmation(MaintenanceRecord);

        // [THEN] Nothing is posted: the record is Open, there is no history, the log has only Registered, X is In Maintenance, no notification
        Assert.IsFalse(Posted, 'PostWithConfirmation should return false');
        MaintenanceRecord.Get(MaintenanceRecord."No.");
        Assert.AreEqual(MaintenanceRecord.Status::Open, MaintenanceRecord.Status, 'The record should stay Open');
        HistoryEntry.SetRange("Maintenance No.", MaintenanceRecord."No.");
        Assert.IsTrue(HistoryEntry.IsEmpty(), 'There should be no history entry');
        Expected.Add(Format(Enum::"EQM Maintenance Log Action"::Registered));
        Assert.AreEqual(JoinList(Expected), GetLogSequence(MaintenanceRecord."No."), 'The log should only have Registered');
        Equipment.Get(Equipment."No.");
        Assert.AreEqual(Equipment.Status::"In Maintenance", Equipment.Status, 'X should stay In Maintenance');
        Assert.AreEqual(0, SentNotificationIds.Count(), 'No notification should be sent');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler,SendNotificationHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EquipmentIsAssignableOnlyAfterTheLastOpenRecordIsPosted()
    var
        Employee: Record Employee;
        Equipment: Record "EQM Equipment";
        FirstRecord: Record "EQM Maintenance Record";
        SecondRecord: Record "EQM Maintenance Record";
        HistoryEntry: Record "EQM Maintenance History Entry";
    begin
        // [SCENARIO] Equipment can be assigned only after the last open maintenance record is posted
        Initialize();

        // [GIVEN] Available equipment X with two open records, and an employee
        CreateEmployee(Employee);
        CreateEquipment(Equipment, CreateCategory());
        InitMaintenance(FirstRecord, Equipment."No.", Today());
        FirstRecord.Insert(true);
        InitMaintenance(SecondRecord, Equipment."No.", Today());
        SecondRecord.Insert(true);

        // [WHEN] The first record is posted, X is still In Maintenance, then the second record is posted and X is assigned
        MaintenanceMgt.PostWithConfirmation(FirstRecord);
        Equipment.Get(Equipment."No.");
        Assert.AreEqual(Equipment.Status::"In Maintenance", Equipment.Status, 'X should still be In Maintenance');
        MaintenanceMgt.PostWithConfirmation(SecondRecord);
        Equipment.Get(Equipment."No.");
        Equipment.AssignEmployee(Employee."No.");

        // [THEN] X is Assigned to the employee and has two history entries
        Equipment.Get(Equipment."No.");
        Assert.AreEqual(Equipment.Status::Assigned, Equipment.Status, 'X should be Assigned');
        Assert.AreEqual(Employee."No.", Equipment."Assigned Employee No.", 'X should be assigned to the employee');
        HistoryEntry.SetRange("Equipment No.", Equipment."No.");
        Assert.AreEqual(2, HistoryEntry.Count(), 'There should be two history entries');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler,SendNotificationHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PostingOneOfTwoRecordsStillBlocksAssignment()
    var
        Employee: Record Employee;
        Equipment: Record "EQM Equipment";
        FirstRecord: Record "EQM Maintenance Record";
        SecondRecord: Record "EQM Maintenance Record";
    begin
        // [SCENARIO] (negative) Posting one of two open records still blocks assigning the equipment
        Initialize();

        // [GIVEN] Equipment X with two open records, the first one posted
        CreateEmployee(Employee);
        CreateEquipment(Equipment, CreateCategory());
        InitMaintenance(FirstRecord, Equipment."No.", Today());
        FirstRecord.Insert(true);
        InitMaintenance(SecondRecord, Equipment."No.", Today());
        SecondRecord.Insert(true);
        MaintenanceMgt.PostWithConfirmation(FirstRecord);
        Equipment.Get(Equipment."No.");

        // [WHEN] X is assigned to the employee
        asserterror Equipment.AssignEmployee(Employee."No.");

        // [THEN] The open maintenance error names X
        Assert.ExpectedError(StrSubstNo(MaintenanceOpenAssignErr, Equipment."No."));
    end;

    // ---------------------------------------------------------------------------------------------------------------
    // Approval Flow
    // ---------------------------------------------------------------------------------------------------------------

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RequestIsApprovedAndCompletedWithEquipmentAssigned()
    var
        Employee: Record Employee;
        Equipment: Record "EQM Equipment";
        Request: Record "EQM Equipment Request";
        AuditEntry: Record "EQM Equipment Audit Entry";
        OutboxEntry: Record "EQM Integration Event Entry";
        SeriesCode: Code[20];
        CategoryCode: Code[20];
        ActiveEntryNo: Integer;
    begin
        // [SCENARIO] A request goes from creation through approval by another user to assigned equipment
        Initialize();

        // [GIVEN] An active employee, a category, available equipment of that category and a request series
        SeriesCode := CreateRequestSeries();
        CreateEmployee(Employee);
        CategoryCode := CreateCategory();
        CreateEquipment(Equipment, CategoryCode);

        // [WHEN] A request is created with a blank number, sent, approved by another user and the equipment is assigned
        CreateRequest(Request, Employee."No.", CategoryCode);
        SendAndApprove(Request);
        RequestApprovalMgt.AssignEquipment(Request, Equipment."No.");

        // [THEN] The request has a series number, is Completed with the equipment, and records the sender and the decision
        Request.Get(Request."No.");
        Assert.IsTrue(Format(Request."No.").StartsWith('EQMPITR'), 'The request number should come from the test series');
        Assert.AreEqual(SeriesCode, Request."No. Series", 'The request should use the test series');
        Assert.AreEqual(Request.Status::Completed, Request.Status, 'The request should be Completed');
        Assert.AreEqual(Equipment."No.", Request."Assigned Equipment No.", 'The request should name the equipment');
        Assert.AreEqual(CopyStr(OtherUserTok, 1, MaxStrLen(Request."Sent for Approval By")), Request."Sent for Approval By", 'The request should keep the other sender');
        Assert.AreEqual(CopyStr(UserId(), 1, MaxStrLen(Request."Decided By")), Request."Decided By", 'The request should be decided by the current user');
        Assert.AreEqual(WorkDate(), Request."Decision Date", 'The decision date should be the work date');
        Assert.AreEqual(CopyStr(CommentTok, 1, MaxStrLen(Request."Decision Comment")), Request."Decision Comment", 'The decision comment should be kept');

        // [THEN] X is Assigned to the employee with one Active entry
        Equipment.Get(Equipment."No.");
        Assert.AreEqual(Equipment.Status::Assigned, Equipment.Status, 'X should be Assigned');
        Assert.AreEqual(Employee."No.", Equipment."Assigned Employee No.", 'X should be assigned to the employee');
        Assert.AreEqual(1, CountAssignments(Equipment."No.", "EQM Assignment Status"::Active), 'There should be one Active entry');
        ActiveEntryNo := GetActiveAssignmentEntryNo(Equipment."No.");

        // [THEN] The audit trail has one Assigned entry for the employee and the Active entry
        AuditEntry.SetRange("Equipment No.", Equipment."No.");
        AuditEntry.SetRange("Event Type", AuditEntry."Event Type"::Assigned);
        Assert.AreEqual(1, AuditEntry.Count(), 'There should be one Assigned audit entry');
        AuditEntry.FindFirst();
        Assert.AreEqual(Employee."No.", AuditEntry."Employee No.", 'The audit entry should name the employee');
        Assert.AreEqual(ActiveEntryNo, AuditEntry."Assignment Entry No.", 'The audit entry should point to the Active entry');

        // [THEN] The outbox has one Equipment Assigned entry with the same assignment entry
        OutboxEntry.SetRange("Equipment No.", Equipment."No.");
        OutboxEntry.SetRange("Event Type", OutboxEntry."Event Type"::"Equipment Assigned");
        Assert.AreEqual(1, OutboxEntry.Count(), 'There should be one Equipment Assigned outbox entry');
        OutboxEntry.FindFirst();
        Assert.AreEqual(ActiveEntryNo, OutboxEntry."Assignment Entry No.", 'The outbox entry should point to the Active entry');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReturningEquipmentKeepsTheRequestCompleted()
    var
        Employee: Record Employee;
        Equipment: Record "EQM Equipment";
        Request: Record "EQM Equipment Request";
        CategoryCode: Code[20];
    begin
        // [SCENARIO] Returning the equipment later leaves the request Completed
        Initialize();

        // [GIVEN] A completed request with equipment X assigned
        CreateRequestSeries();
        CreateEmployee(Employee);
        CategoryCode := CreateCategory();
        CreateEquipment(Equipment, CategoryCode);
        CreateRequest(Request, Employee."No.", CategoryCode);
        SendAndApprove(Request);
        RequestApprovalMgt.AssignEquipment(Request, Equipment."No.");

        // [WHEN] X is returned
        Equipment.Get(Equipment."No.");
        Equipment.UnassignEmployee();

        // [THEN] The request stays Completed with X, X is Available and the entry is Closed
        Request.Get(Request."No.");
        Assert.AreEqual(Request.Status::Completed, Request.Status, 'The request should stay Completed');
        Assert.AreEqual(Equipment."No.", Request."Assigned Equipment No.", 'The request should keep the equipment');
        Equipment.Get(Equipment."No.");
        Assert.AreEqual(Equipment.Status::Available, Equipment.Status, 'X should be Available');
        Assert.AreEqual(1, CountAssignments(Equipment."No.", "EQM Assignment Status"::Closed), 'The entry should be Closed');
        Assert.AreEqual(0, CountAssignments(Equipment."No.", "EQM Assignment Status"::Active), 'No entry should be Active');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RejectedRequestCannotGetEquipment()
    var
        Employee: Record Employee;
        Equipment: Record "EQM Equipment";
        Request: Record "EQM Equipment Request";
        CategoryCode: Code[20];
    begin
        // [SCENARIO] (negative) A rejected request cannot get equipment
        Initialize();

        // [GIVEN] A request that was sent and rejected, and available equipment of its category
        CreateRequestSeries();
        CreateEmployee(Employee);
        CategoryCode := CreateCategory();
        CreateEquipment(Equipment, CategoryCode);
        CreateRequest(Request, Employee."No.", CategoryCode);
        RequestApprovalMgt.SendForApproval(Request);
        RequestApprovalMgt.Reject(Request, CopyStr(RejectCommentTok, 1, MaxStrLen(Request."Decision Comment")));
        Assert.AreEqual(Request.Status::Rejected, Request.Status, 'The request should be Rejected');
        Assert.AreEqual(CopyStr(UserId(), 1, MaxStrLen(Request."Decided By")), Request."Decided By", 'The request should be decided by the current user');

        // [WHEN] Equipment is assigned for the request
        asserterror RequestApprovalMgt.AssignEquipment(Request, Equipment."No.");

        // [THEN] The rejected error names the request
        Assert.ExpectedError(StrSubstNo(RequestRejectedErr, Request."No."));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ApprovedRequestCannotGetEquipmentThatWentIntoMaintenance()
    var
        Employee: Record Employee;
        Equipment: Record "EQM Equipment";
        Request: Record "EQM Equipment Request";
        MaintenanceRecord: Record "EQM Maintenance Record";
        CategoryCode: Code[20];
    begin
        // [SCENARIO] (negative) An approved request cannot get equipment that went into maintenance
        Initialize();

        // [GIVEN] An approved request, and available equipment of its category that then gets a maintenance record
        CreateRequestSeries();
        CreateEmployee(Employee);
        CategoryCode := CreateCategory();
        CreateEquipment(Equipment, CategoryCode);
        CreateRequest(Request, Employee."No.", CategoryCode);
        SendAndApprove(Request);
        InitMaintenance(MaintenanceRecord, Equipment."No.", Today());
        MaintenanceRecord.Insert(true);

        // [WHEN] The equipment is assigned for the request
        asserterror RequestApprovalMgt.AssignEquipment(Request, Equipment."No.");

        // [THEN] The open maintenance error names the equipment
        Assert.ExpectedError(StrSubstNo(MaintenanceOpenAssignErr, Equipment."No."));
    end;

    // ---------------------------------------------------------------------------------------------------------------
    // Notification Flow
    // ---------------------------------------------------------------------------------------------------------------

    [Test]
    [HandlerFunctions('ConfirmYesHandler,SendNotificationHandler,RecallNotificationHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PostingTheLastRecordSendsTheReturnedNotification()
    var
        Equipment: Record "EQM Equipment";
        MaintenanceRecord: Record "EQM Maintenance Record";
    begin
        // [SCENARIO] Posting the last open record sends the returned-from-maintenance notification
        Initialize();

        // [GIVEN] Registered notifications and available equipment X with an open record
        NotificationMgt.RegisterDefaultNotifications();
        CreateEquipment(Equipment, CreateCategory());
        InitMaintenance(MaintenanceRecord, Equipment."No.", Today());
        MaintenanceRecord.Insert(true);

        // [WHEN] The record is posted with confirmation
        MaintenanceMgt.PostWithConfirmation(MaintenanceRecord);

        // [THEN] One returned notification is sent and its message names X
        Assert.AreEqual(1, CountSent(NotificationMgt.GetReturnedFromMaintenanceNotificationId()), 'One returned notification should be sent');
        Assert.IsTrue(LastSentMessage.Contains(Equipment."No."), 'The message should name X');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler,SendNotificationHandler,RecallNotificationHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NoReturnedNotificationWhileOtherMaintenanceIsOpen()
    var
        Equipment: Record "EQM Equipment";
        FirstRecord: Record "EQM Maintenance Record";
        SecondRecord: Record "EQM Maintenance Record";
    begin
        // [SCENARIO] (negative) No returned notification is sent while other maintenance is open
        Initialize();

        // [GIVEN] Registered notifications and equipment X with two open records
        NotificationMgt.RegisterDefaultNotifications();
        CreateEquipment(Equipment, CreateCategory());
        InitMaintenance(FirstRecord, Equipment."No.", Today());
        FirstRecord.Insert(true);
        InitMaintenance(SecondRecord, Equipment."No.", Today());
        SecondRecord.Insert(true);

        // [WHEN] The first record is posted with confirmation
        MaintenanceMgt.PostWithConfirmation(FirstRecord);

        // [THEN] No returned notification is sent
        Assert.AreEqual(0, CountSent(NotificationMgt.GetReturnedFromMaintenanceNotificationId()), 'No returned notification should be sent');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler,SendNotificationHandler,RecallNotificationHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UserWhoSwitchedOffTheNotificationGetsNone()
    var
        Equipment: Record "EQM Equipment";
        MaintenanceRecord: Record "EQM Maintenance Record";
        MyNotifications: Record "My Notifications";
    begin
        // [SCENARIO] (negative) A user who switched the notification off in My Notifications gets none
        Initialize();

        // [GIVEN] Registered notifications with the returned notification switched off, and equipment X with an open record
        NotificationMgt.RegisterDefaultNotifications();
        MyNotifications.Disable(NotificationMgt.GetReturnedFromMaintenanceNotificationId());
        CreateEquipment(Equipment, CreateCategory());
        InitMaintenance(MaintenanceRecord, Equipment."No.", Today());
        MaintenanceRecord.Insert(true);

        // [WHEN] The record is posted with confirmation
        MaintenanceMgt.PostWithConfirmation(MaintenanceRecord);

        // [THEN] No returned notification is sent and the record is Posted
        Assert.AreEqual(0, CountSent(NotificationMgt.GetReturnedFromMaintenanceNotificationId()), 'No returned notification should be sent');
        MaintenanceRecord.Get(MaintenanceRecord."No.");
        Assert.AreEqual(MaintenanceRecord.Status::Posted, MaintenanceRecord.Status, 'The record should be Posted');
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler,RecallNotificationHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure GeneratedWarrantyAlertShowsAWarrantyNotification()
    var
        Equipment: Record "EQM Equipment";
    begin
        // [SCENARIO] A generated warranty alert shows a warranty notification for the equipment
        Initialize();

        // [GIVEN] Registered notifications and equipment X with a warranty alert
        NotificationMgt.RegisterDefaultNotifications();
        CreateEquipmentWithWarrantyAlert(Equipment);

        // [WHEN] The equipment notifications are shown for X
        NotificationMgt.ShowEquipmentNotifications(Equipment);

        // [THEN] One warranty notification is sent and its message names X
        Assert.AreEqual(1, CountSent(NotificationMgt.GetWarrantyNotificationId()), 'One warranty notification should be sent');
        Assert.IsTrue(LastSentMessage.Contains(Equipment."No."), 'The message should name X');
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler,RecallNotificationHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AcknowledgedAlertShowsNoWarrantyNotification()
    var
        Equipment: Record "EQM Equipment";
        WarrantyAlert: Record "EQM Warranty Alert";
    begin
        // [SCENARIO] (negative) An acknowledged warranty alert shows no warranty notification
        Initialize();

        // [GIVEN] Registered notifications and equipment X whose warranty alert is acknowledged
        NotificationMgt.RegisterDefaultNotifications();
        CreateEquipmentWithWarrantyAlert(Equipment);
        WarrantyAlert.SetRange("Equipment No.", Equipment."No.");
        WarrantyAlertMgt.AcknowledgeAlerts(WarrantyAlert);

        // [WHEN] The equipment notifications are shown for X
        NotificationMgt.ShowEquipmentNotifications(Equipment);

        // [THEN] No warranty notification is sent
        Assert.AreEqual(0, CountSent(NotificationMgt.GetWarrantyNotificationId()), 'No warranty notification should be sent');
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler,RecallNotificationHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OverdueMaintenanceShowsAnOverdueNotification()
    var
        Equipment: Record "EQM Equipment";
        MaintenanceRecord: Record "EQM Maintenance Record";
    begin
        // [SCENARIO] Overdue open maintenance shows an overdue notification for the equipment
        Initialize();

        // [GIVEN] Registered notifications and equipment X with an open record older than the overdue days
        NotificationMgt.RegisterDefaultNotifications();
        CreateEquipment(Equipment, CreateCategory());
        InitMaintenance(MaintenanceRecord, Equipment."No.", Today() - MaintenanceMgt.GetMaintenanceOverdueDays() - 1 - Random(30));
        MaintenanceRecord.Insert(true);
        Equipment.Get(Equipment."No.");

        // [WHEN] The equipment notifications are shown for X
        NotificationMgt.ShowEquipmentNotifications(Equipment);

        // [THEN] One overdue notification is sent, it names the record, and nothing else is sent
        Assert.AreEqual(1, CountSent(NotificationMgt.GetOverdueMaintenanceNotificationId()), 'One overdue notification should be sent');
        Assert.IsTrue(LastSentMessage.Contains(MaintenanceRecord."No."), 'The message should name the record');
        Assert.AreEqual(1, SentNotificationIds.Count(), 'Only one notification should be sent');
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler,RecallNotificationHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MaintenanceOpenExactlyTheOverdueDaysIsNotOverdue()
    var
        Equipment: Record "EQM Equipment";
        MaintenanceRecord: Record "EQM Maintenance Record";
    begin
        // [SCENARIO] (negative, boundary) Maintenance open exactly the overdue days is not overdue
        Initialize();

        // [GIVEN] Registered notifications and equipment X with an open record dated exactly the overdue days ago
        NotificationMgt.RegisterDefaultNotifications();
        CreateEquipment(Equipment, CreateCategory());
        InitMaintenance(MaintenanceRecord, Equipment."No.", Today() - MaintenanceMgt.GetMaintenanceOverdueDays());
        MaintenanceRecord.Insert(true);
        Equipment.Get(Equipment."No.");

        // [WHEN] The equipment notifications are shown for X
        NotificationMgt.ShowEquipmentNotifications(Equipment);

        // [THEN] No overdue notification is sent
        Assert.AreEqual(0, CountSent(NotificationMgt.GetOverdueMaintenanceNotificationId()), 'No overdue notification should be sent');
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler,RecallNotificationHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NotificationsFeatureOffSuppressesEquipmentNotifications()
    var
        Equipment: Record "EQM Equipment";
        MaintenanceRecord: Record "EQM Maintenance Record";
    begin
        // [SCENARIO] (negative) Turning the Notifications feature off suppresses the equipment notifications
        Initialize();

        // [GIVEN] The Notifications feature is off, and equipment X has a warranty alert and an overdue open record
        NotificationMgt.RegisterDefaultNotifications();
        FeatureMgt.SetFeatureEnabled(Enum::"EQM Feature"::Notifications, false);
        CreateEquipmentWithWarrantyAlert(Equipment);
        InitMaintenance(MaintenanceRecord, Equipment."No.", Today() - MaintenanceMgt.GetMaintenanceOverdueDays() - 1 - Random(30));
        MaintenanceRecord.Insert(true);
        Equipment.Get(Equipment."No.");

        // [WHEN] The equipment notifications are shown for X
        NotificationMgt.ShowEquipmentNotifications(Equipment);

        // [THEN] No notification is sent
        Assert.AreEqual(0, SentNotificationIds.Count(), 'No notification should be sent');
    end;

    // ---------------------------------------------------------------------------------------------------------------
    // Handlers
    // ---------------------------------------------------------------------------------------------------------------

    [ConfirmHandler]
    procedure ConfirmYesHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    procedure ConfirmNoHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [SendNotificationHandler(true)]
    procedure SendNotificationHandler(var TheNotification: Notification): Boolean
    begin
        SentNotificationIds.Add(Format(TheNotification.Id));
        LastSentMessage := TheNotification.Message;
        exit(true);
    end;

    [RecallNotificationHandler(true)]
    procedure RecallNotificationHandler(var TheNotification: Notification): Boolean
    begin
        exit(true);
    end;

    // ---------------------------------------------------------------------------------------------------------------
    // Helpers
    // ---------------------------------------------------------------------------------------------------------------

    local procedure Initialize()
    var
        FeatureSetup: Record "EQM Feature Setup";
        EquipmentSetup: Record "EQM Equipment Setup";
    begin
        // Everything runs in the test transaction, which is rolled back (AutoRollback), so nothing is committed or cleaned up.
        WorkDate(Today());
        FeatureSetup.DeleteAll();
        if not EquipmentSetup.Get() then begin
            EquipmentSetup.Init();
            EquipmentSetup.Insert(false);
        end;
        EquipmentSetup."Integration Events Enabled" := true;
        EquipmentSetup."Default Warranty Alert Days" := WarrantyAlertMgt.GetLongestIntervalDays();
        EquipmentSetup.Modify(false);
        Clear(SentNotificationIds);
        LastSentMessage := '';
    end;

    local procedure NextId(): Text
    begin
        Counter += 1;
        exit(Format(Counter, 0, CounterFormatTok));
    end;

    local procedure CreateEmployee(var Employee: Record Employee)
    begin
        Employee.Init();
        Employee."No." := CopyStr(StrSubstNo(EmployeeNoTok, NextId()), 1, MaxStrLen(Employee."No."));
        Employee."First Name" := FirstNameTok;
        Employee."Last Name" := Employee."No.";
        Employee.Status := Employee.Status::Active;
        Employee."Privacy Blocked" := false;
        Employee.Insert(false);
    end;

    local procedure CreateCategory(): Code[20]
    var
        Category: Record "EQM Equipment Category";
    begin
        Category.Init();
        Category.Code := CopyStr(StrSubstNo(CategoryCodeTok, NextId()), 1, MaxStrLen(Category.Code));
        Category.Description := Category.Code;
        Category.Active := true;
        Category.Insert(false);
        exit(Category.Code);
    end;

    local procedure CreateEquipment(var Equipment: Record "EQM Equipment"; CategoryCode: Code[20])
    begin
        Equipment.Init();
        Equipment."No." := CopyStr(StrSubstNo(EquipmentNoTok, NextId()), 1, MaxStrLen(Equipment."No."));
        Equipment.Description := Equipment."No.";
        Equipment."Category Code" := CategoryCode;
        Equipment.Insert(true);
        Equipment.Get(Equipment."No.");
    end;

    local procedure CreateEquipmentWithWarrantyAlert(var Equipment: Record "EQM Equipment")
    var
        CreatedCount: Integer;
        CancelledCount: Integer;
    begin
        CreateEquipment(Equipment, CreateCategory());
        Equipment."Warranty End Date" := Today() + 1 + Random(30);
        Equipment.Modify(true);
        WarrantyAlertMgt.GenerateAlerts(Today(), false, CreatedCount, CancelledCount);
        Equipment.Get(Equipment."No.");
    end;

    local procedure InitMaintenance(var MaintenanceRecord: Record "EQM Maintenance Record"; EquipmentNo: Code[20]; MaintenanceDate: Date)
    begin
        MaintenanceRecord.Init();
        MaintenanceRecord."No." := CopyStr(StrSubstNo(MaintenanceNoTok, NextId()), 1, MaxStrLen(MaintenanceRecord."No."));
        MaintenanceRecord."Equipment No." := EquipmentNo;
        MaintenanceRecord."Maintenance Date" := MaintenanceDate;
        MaintenanceRecord.Description := MaintenanceRecord."No.";
    end;

    local procedure CreateRequestSeries(): Code[20]
    var
        EquipmentSetup: Record "EQM Equipment Setup";
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        SeriesCode: Code[20];
        StartingNo: Code[20];
    begin
        SeriesCode := CopyStr(StrSubstNo(RequestSeriesTok, NextId()), 1, MaxStrLen(SeriesCode));
        StartingNo := CopyStr(StrSubstNo(RequestStartNoTok, NextId()), 1, MaxStrLen(StartingNo));

        NoSeries.Init();
        NoSeries.Code := SeriesCode;
        NoSeries.Description := SeriesCode;
        NoSeries."Default Nos." := true;
        NoSeries."Manual Nos." := true;
        NoSeries.Insert();

        NoSeriesLine.Init();
        NoSeriesLine."Series Code" := SeriesCode;
        NoSeriesLine."Line No." := 10000;
        NoSeriesLine.Validate("Starting No.", StartingNo);
        NoSeriesLine.Validate("Increment-by No.", 1);
        NoSeriesLine.Insert(true);

        EquipmentSetup.Get();
        EquipmentSetup."Request Nos." := SeriesCode;
        EquipmentSetup.Modify(false);
        exit(SeriesCode);
    end;

    local procedure CreateRequest(var Request: Record "EQM Equipment Request"; EmployeeNo: Code[20]; CategoryCode: Code[20])
    begin
        Request.Init();
        Request."No." := '';
        Request.Validate("Employee No.", EmployeeNo);
        Request.Validate("Requested Equipment Type", CategoryCode);
        Request.Justification := JustificationTok;
        Request.Insert(true);
    end;

    local procedure SendAndApprove(var Request: Record "EQM Equipment Request")
    begin
        RequestApprovalMgt.SendForApproval(Request);
        // Simulates a sender other than the current user, so the real self-approval check stays active.
        Request."Sent for Approval By" := CopyStr(OtherUserTok, 1, MaxStrLen(Request."Sent for Approval By"));
        Request.Modify(false);
        RequestApprovalMgt.Approve(Request, CopyStr(CommentTok, 1, MaxStrLen(Request."Decision Comment")));
    end;

    local procedure JoinList(Items: List of [Text]): Text
    var
        Item: Text;
        Result: Text;
    begin
        foreach Item in Items do begin
            if Result <> '' then
                Result += SequenceSeparatorTok;
            Result += Item;
        end;
        exit(Result);
    end;

    local procedure GetAuditSequence(EquipmentNo: Code[20]; AfterEntryNo: Integer): Text
    var
        AuditEntry: Record "EQM Equipment Audit Entry";
        Items: List of [Text];
    begin
        AuditEntry.SetRange("Equipment No.", EquipmentNo);
        AuditEntry.SetFilter("Entry No.", '>%1', AfterEntryNo);
        if AuditEntry.FindSet() then
            repeat
                Items.Add(Format(AuditEntry."Event Type"));
            until AuditEntry.Next() = 0;
        exit(JoinList(Items));
    end;

    local procedure FindAuditEntry(var AuditEntry: Record "EQM Equipment Audit Entry"; EquipmentNo: Code[20]; EventType: Enum "EQM Audit Event Type"; AfterEntryNo: Integer)
    begin
        AuditEntry.Reset();
        AuditEntry.SetRange("Equipment No.", EquipmentNo);
        AuditEntry.SetRange("Event Type", EventType);
        AuditEntry.SetFilter("Entry No.", '>%1', AfterEntryNo);
        AuditEntry.FindFirst();
    end;

    local procedure GetOutboxSequence(EquipmentNo: Code[20]): Text
    var
        OutboxEntry: Record "EQM Integration Event Entry";
        Items: List of [Text];
    begin
        OutboxEntry.SetRange("Equipment No.", EquipmentNo);
        if OutboxEntry.FindSet() then
            repeat
                Items.Add(Format(OutboxEntry."Event Type"));
            until OutboxEntry.Next() = 0;
        exit(JoinList(Items));
    end;

    local procedure GetLogSequence(MaintenanceNo: Code[20]): Text
    var
        LogEntry: Record "EQM Maintenance Log Entry";
        Items: List of [Text];
    begin
        LogEntry.SetRange("Maintenance No.", MaintenanceNo);
        if LogEntry.FindSet() then
            repeat
                Items.Add(Format(LogEntry."Action"));
            until LogEntry.Next() = 0;
        exit(JoinList(Items));
    end;

    local procedure CountAssignments(EquipmentNo: Code[20]; AssignmentStatus: Enum "EQM Assignment Status"): Integer
    var
        Assignment: Record "EQM Equipment Assignment";
    begin
        Assignment.SetRange("Equipment No.", EquipmentNo);
        Assignment.SetRange(Status, AssignmentStatus);
        exit(Assignment.Count());
    end;

    local procedure GetActiveAssignmentEntryNo(EquipmentNo: Code[20]): Integer
    var
        Assignment: Record "EQM Equipment Assignment";
    begin
        Assignment.SetRange("Equipment No.", EquipmentNo);
        Assignment.SetRange(Status, Assignment.Status::Active);
        Assignment.FindFirst();
        exit(Assignment."Entry No.");
    end;

    local procedure CountSent(NotificationId: Guid): Integer
    var
        SentId: Text;
        SentCount: Integer;
    begin
        foreach SentId in SentNotificationIds do
            if SentId = Format(NotificationId) then
                SentCount += 1;
        exit(SentCount);
    end;
}
