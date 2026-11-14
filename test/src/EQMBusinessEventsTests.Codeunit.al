namespace MiguelCarvalho.EquipmentManagement.Tests;

using Microsoft.HumanResources.Employee;
using MiguelCarvalho.EquipmentManagement;
using System.TestLibraries.Utilities;

/// <summary>
/// Tests for the five business events of codeunit 50119 (FR-029), scenarios 1 to 12. The events are observed with the
/// manual subscriber codeunit 50185, bound in each test after the setup, so setup actions are not counted. Scenario 13
/// (a scheduled warranty job run raises OnWarrantyExpired and keeps the alerts) needs the job queue and a Commit, so it
/// is verified manually in the sandbox.
/// A failed statement (asserterror) rolls back the whole test transaction, so each test that expects an error has
/// exactly one asserterror, as its last action. The counters of the subscriber live in the codeunit instance and are
/// not rolled back, so they can still be read afterwards.
/// </summary>
codeunit 50184 "EQM Business Events Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        CategoryTok: Label 'EQMBEV-CAT', Locked = true;
        EmployeeTok: Label 'EQMBEV-E1', Locked = true;
        EquipmentNoTok: Label 'EQMBEV-EQ', Locked = true;
        NewEquipmentNoTok: Label 'EQMBEV-NEW', Locked = true;
        MaintenanceNoTok: Label 'EQMBEV-M1', Locked = true;
        WarrantyNoTok: Label 'EQMBEV-W%1', Locked = true;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EquipmentCreatedRaisedAfterInsert()
    var
        Equipment: Record "EQM Equipment";
        Subscriber: Codeunit "EQM Business Event Test Subscr";
    begin
        // [SCENARIO 1] OnEquipmentCreated is raised once after Insert(true), and the record is already stored
        Initialize();

        // [GIVEN] The subscriber is bound
        BindSubscription(Subscriber);

        // [WHEN] New equipment is inserted with Insert(true)
        InitEquipment(Equipment, NewEquipmentNoTok);
        Equipment.Insert(true);

        // [THEN] The event is raised once, for the new number, and the record is found in the database
        Assert.AreEqual(1, Subscriber.GetCreatedCount(), 'OnEquipmentCreated should be raised once');
        Assert.AreEqual(NewEquipmentNoTok, Subscriber.GetLastCreatedNo(), 'The event should carry the new equipment number');
        Assert.IsTrue(Subscriber.GetCreatedFoundInDb(), 'The equipment should be stored when the event is raised');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EquipmentCreatedNotRaisedWithoutTriggersOrForTemporary()
    var
        Equipment: Record "EQM Equipment";
        TempEquipment: Record "EQM Equipment" temporary;
        Subscriber: Codeunit "EQM Business Event Test Subscr";
    begin
        // [SCENARIO 2] (neg) Insert(false) and a temporary record do not raise OnEquipmentCreated
        Initialize();

        // [GIVEN] The subscriber is bound
        BindSubscription(Subscriber);

        // [WHEN] Equipment is inserted with Insert(false), and a temporary record with Insert(true)
        InitEquipment(Equipment, NewEquipmentNoTok);
        Equipment.Insert(false);
        InitEquipment(TempEquipment, EquipmentNoTok);
        TempEquipment.Insert(true);

        // [THEN] The event is not raised
        Assert.AreEqual(0, Subscriber.GetCreatedCount(), 'OnEquipmentCreated should not be raised for Insert(false) or temporary records');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EquipmentCreatedNotRaisedWhenInsertFails()
    var
        Equipment: Record "EQM Equipment";
        Subscriber: Codeunit "EQM Business Event Test Subscr";
    begin
        // [SCENARIO 3] (neg) A failing insert (no category) does not raise OnEquipmentCreated
        Initialize();

        // [GIVEN] The subscriber is bound, and equipment without a category
        BindSubscription(Subscriber);
        InitEquipment(Equipment, NewEquipmentNoTok);
        Equipment."Category Code" := '';

        // [WHEN] The equipment is inserted with Insert(true)
        asserterror Equipment.Insert(true);

        // [THEN] The insert failed and the event was not raised
        Assert.AreEqual(0, Subscriber.GetCreatedCount(), 'OnEquipmentCreated should not be raised when the insert fails');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EquipmentAssignedRaisedOnAssign()
    var
        Equipment: Record "EQM Equipment";
        Subscriber: Codeunit "EQM Business Event Test Subscr";
    begin
        // [SCENARIO 4] OnEquipmentAssigned is raised once with the new values and the stored Active entry
        Initialize();

        // [GIVEN] Available equipment EQ and the bound subscriber
        CreateEquipment(Equipment, EquipmentNoTok);
        BindSubscription(Subscriber);

        // [WHEN] EQ is assigned to E1
        Equipment.AssignEmployee(EmployeeTok);

        // [THEN] The event is raised once, with Status Assigned and employee E1
        Assert.AreEqual(1, Subscriber.GetAssignedCount(), 'OnEquipmentAssigned should be raised once');
        Assert.AreEqual(EquipmentNoTok, Subscriber.GetLastAssignedEquipmentNo(), 'The event should carry EQ');
        Assert.AreEqual(Equipment.Status::Assigned, Subscriber.GetLastAssignedStatus(), 'The equipment in the event should be Assigned');
        Assert.AreEqual(EmployeeTok, Subscriber.GetLastAssignedEmployeeNo(), 'The equipment in the event should have employee E1');

        // [THEN] The entry in the event is the stored Active entry of EQ
        Assert.IsTrue(Subscriber.GetAssignedEntryActiveInDb(), 'The entry should be stored and Active when the event is raised');
        Assert.AreEqual(GetActiveEntryNo(EquipmentNoTok), Subscriber.GetLastAssignedEntryNo(), 'The event should carry the Active entry of EQ');
        Assert.AreEqual(0, Subscriber.GetReturnedCount(), 'OnEquipmentReturned should not be raised on a first assignment');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure EquipmentReturnedRaisedOnReturn()
    var
        Equipment: Record "EQM Equipment";
        Subscriber: Codeunit "EQM Business Event Test Subscr";
        EntryNo: Integer;
    begin
        // [SCENARIO 5] OnEquipmentReturned is raised once by the Return action, with the Closed entry
        Initialize();

        // [GIVEN] EQ assigned to E1, and the bound subscriber
        CreateEquipment(Equipment, EquipmentNoTok);
        Equipment.AssignEmployee(EmployeeTok);
        EntryNo := GetActiveEntryNo(EquipmentNoTok);
        BindSubscription(Subscriber);

        // [WHEN] EQ is returned (confirm Yes)
        Equipment.Get(EquipmentNoTok);
        Assert.IsTrue(Equipment.UnassignEmployee(), 'The return should be done');

        // [THEN] The event is raised once, with Status Available and the Closed entry
        Assert.AreEqual(1, Subscriber.GetReturnedCount(), 'OnEquipmentReturned should be raised once');
        Assert.AreEqual(EquipmentNoTok, Subscriber.GetLastReturnedEquipmentNo(), 'The event should carry EQ');
        Assert.AreEqual(Equipment.Status::Available, Subscriber.GetLastReturnedStatus(), 'The equipment in the event should be Available');
        Assert.AreEqual(EntryNo, Subscriber.GetLastReturnedEntryNo(), 'The event should carry the entry that was active');
        Assert.AreEqual("EQM Assignment Status"::Closed, Subscriber.GetLastReturnedEntryStatus(), 'The entry in the event should be Closed');
        Assert.AreEqual(0, Subscriber.GetAssignedCount(), 'OnEquipmentAssigned should not be raised by a return');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure EquipmentReturnedAndMaintenanceCreatedRaisedOnMaintenance()
    var
        Equipment: Record "EQM Equipment";
        MaintenanceRecord: Record "EQM Maintenance Record";
        Subscriber: Codeunit "EQM Business Event Test Subscr";
    begin
        // [SCENARIO 6] Registering maintenance for assigned equipment raises OnEquipmentReturned and OnMaintenanceCreated
        Initialize();

        // [GIVEN] EQ assigned to E1, and the bound subscriber
        CreateEquipment(Equipment, EquipmentNoTok);
        Equipment.AssignEmployee(EmployeeTok);
        BindSubscription(Subscriber);

        // [WHEN] A maintenance record is inserted for EQ (confirm Yes)
        InitMaintenance(MaintenanceRecord, MaintenanceNoTok, EquipmentNoTok);
        MaintenanceRecord.Insert(true);

        // [THEN] OnEquipmentReturned is raised once, with Status In Maintenance and a Closed entry
        Assert.AreEqual(1, Subscriber.GetReturnedCount(), 'OnEquipmentReturned should be raised once');
        Assert.AreEqual(Equipment.Status::"In Maintenance", Subscriber.GetLastReturnedStatus(), 'The equipment in the event should be In Maintenance');
        Assert.AreEqual("EQM Assignment Status"::Closed, Subscriber.GetLastReturnedEntryStatus(), 'The entry in the event should be Closed');

        // [THEN] OnMaintenanceCreated is raised once with the record number, and the record is found in the database
        Assert.AreEqual(1, Subscriber.GetMaintenanceCreatedCount(), 'OnMaintenanceCreated should be raised once');
        Assert.AreEqual(MaintenanceNoTok, Subscriber.GetLastMaintenanceNo(), 'The event should carry the maintenance number');
        Assert.IsTrue(Subscriber.GetMaintenanceFoundInDb(), 'The maintenance record should be stored when the event is raised');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure EquipmentReturnedRaisedWhenSetToLost()
    var
        Equipment: Record "EQM Equipment";
        Subscriber: Codeunit "EQM Business Event Test Subscr";
    begin
        // [SCENARIO 7] Setting assigned equipment to Lost raises OnEquipmentReturned with Status Lost
        Initialize();

        // [GIVEN] EQ assigned to E1, and the bound subscriber
        CreateEquipment(Equipment, EquipmentNoTok);
        Equipment.AssignEmployee(EmployeeTok);
        BindSubscription(Subscriber);

        // [WHEN] The status is validated to Lost and the record is modified (confirm Yes)
        Equipment.Get(EquipmentNoTok);
        Equipment.Validate(Status, Equipment.Status::Lost);
        Equipment.Modify(true);

        // [THEN] The event is raised once, with Status Lost
        Assert.AreEqual(1, Subscriber.GetReturnedCount(), 'OnEquipmentReturned should be raised once');
        Assert.AreEqual(Equipment.Status::Lost, Subscriber.GetLastReturnedStatus(), 'The equipment in the event should be Lost');
        Assert.AreEqual("EQM Assignment Status"::Closed, Subscriber.GetLastReturnedEntryStatus(), 'The entry in the event should be Closed');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('ConfirmNoHandler')]
    procedure NoEventWhenReturnCancelledOrDescriptionChanged()
    var
        Equipment: Record "EQM Equipment";
        Subscriber: Codeunit "EQM Business Event Test Subscr";
    begin
        // [SCENARIO 8] (neg) A cancelled return and an unrelated change raise no event
        Initialize();

        // [GIVEN] EQ assigned to E1, and the bound subscriber
        CreateEquipment(Equipment, EquipmentNoTok);
        Equipment.AssignEmployee(EmployeeTok);
        BindSubscription(Subscriber);

        // [WHEN] The return is answered No
        Equipment.Get(EquipmentNoTok);
        Assert.IsFalse(Equipment.UnassignEmployee(), 'The return should be cancelled');

        // [THEN] No event is raised
        AssertNoEvents(Subscriber);

        // [WHEN] The description of the assigned EQ is changed and modified
        Equipment.Get(EquipmentNoTok);
        Equipment.Description := 'EQMBEV changed description';
        Equipment.Modify(true);

        // [THEN] No event is raised
        AssertNoEvents(Subscriber);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NoAssignedEventWhenAssignFails()
    var
        Equipment: Record "EQM Equipment";
        MaintenanceRecord: Record "EQM Maintenance Record";
        Subscriber: Codeunit "EQM Business Event Test Subscr";
    begin
        // [SCENARIO 9] (neg) A failing assignment does not raise OnEquipmentAssigned
        Initialize();

        // [GIVEN] EQ with an open maintenance record (status In Maintenance), and the bound subscriber
        CreateEquipment(Equipment, EquipmentNoTok);
        InitMaintenance(MaintenanceRecord, MaintenanceNoTok, EquipmentNoTok);
        MaintenanceRecord.Insert(true);
        Equipment.Get(EquipmentNoTok);
        BindSubscription(Subscriber);

        // [WHEN] EQ is assigned to E1
        asserterror Equipment.AssignEmployee(EmployeeTok);

        // [THEN] The assignment failed and the event was not raised
        Assert.AreEqual(0, Subscriber.GetAssignedCount(), 'OnEquipmentAssigned should not be raised when the assignment fails');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MaintenanceCreatedNotRaisedOnModifyOrPost()
    var
        Equipment: Record "EQM Equipment";
        MaintenanceRecord: Record "EQM Maintenance Record";
        Subscriber: Codeunit "EQM Business Event Test Subscr";
    begin
        // [SCENARIO 10] (neg) Modifying and posting a maintenance record does not raise OnMaintenanceCreated again
        Initialize();

        // [GIVEN] An open maintenance record for EQ, and the bound subscriber
        CreateEquipment(Equipment, EquipmentNoTok);
        InitMaintenance(MaintenanceRecord, MaintenanceNoTok, EquipmentNoTok);
        MaintenanceRecord.Insert(true);
        BindSubscription(Subscriber);

        // [WHEN] The record is modified and then posted
        MaintenanceRecord.Get(MaintenanceNoTok);
        MaintenanceRecord.Description := 'EQMBEV changed description';
        MaintenanceRecord.Modify(true);
        Codeunit.Run(Codeunit::"EQM Maintenance-Post", MaintenanceRecord);

        // [THEN] The record is posted and the event was not raised
        MaintenanceRecord.Get(MaintenanceNoTok);
        Assert.AreEqual(MaintenanceRecord.Status::Posted, MaintenanceRecord.Status, 'The record should be posted');
        Assert.AreEqual(0, Subscriber.GetMaintenanceCreatedCount(), 'OnMaintenanceCreated should not be raised by modify or post');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure WarrantyExpiredRaisedOnlyForEquipmentThatExpiredYesterday()
    var
        Equipment: Record "EQM Equipment";
        WarrantyAlertMgt: Codeunit "EQM Warranty Alert Mgt.";
        Subscriber: Codeunit "EQM Business Event Test Subscr";
        ReferenceDate: Date;
        RaisedCount: Integer;
    begin
        // [SCENARIO 11] OnWarrantyExpired is raised only for equipment whose warranty ended the day before the reference date
        Initialize();
        ReferenceDate := Today();

        // [GIVEN] W1 (end R-1), W2 (end R), W3 (end R-2), W4 (end R-1, Disposed) and W5 (no end date)
        CreateEquipmentWithWarranty(Equipment, 1, ReferenceDate - 1);
        CreateEquipmentWithWarranty(Equipment, 2, ReferenceDate);
        CreateEquipmentWithWarranty(Equipment, 3, ReferenceDate - 2);
        CreateEquipmentWithWarranty(Equipment, 4, ReferenceDate - 1);
        Equipment.Validate(Status, Equipment.Status::Disposed);
        Equipment.Modify(true);
        CreateEquipmentWithWarranty(Equipment, 5, 0D);
        BindSubscription(Subscriber);

        // [WHEN] The events are raised for R
        RaisedCount := WarrantyAlertMgt.RaiseWarrantyExpiredEvents(ReferenceDate);

        // [THEN] The procedure returns 1 and the event is raised only for W1
        Assert.AreEqual(1, RaisedCount, 'One event should be raised');
        Assert.AreEqual(1, Subscriber.GetWarrantyExpiredCount(), 'OnWarrantyExpired should be raised once');
        Assert.IsTrue(Subscriber.WarrantyExpiredWasRaisedFor(StrSubstNo(WarrantyNoTok, 1)), 'W1 (ended yesterday) should raise the event');
        Assert.IsFalse(Subscriber.WarrantyExpiredWasRaisedFor(StrSubstNo(WarrantyNoTok, 2)), 'W2 (ends today) should not raise the event');
        Assert.IsFalse(Subscriber.WarrantyExpiredWasRaisedFor(StrSubstNo(WarrantyNoTok, 3)), 'W3 (ended 2 days ago) should not raise the event');
        Assert.IsFalse(Subscriber.WarrantyExpiredWasRaisedFor(StrSubstNo(WarrantyNoTok, 4)), 'W4 (Disposed) should not raise the event');
        Assert.IsFalse(Subscriber.WarrantyExpiredWasRaisedFor(StrSubstNo(WarrantyNoTok, 5)), 'W5 (no end date) should not raise the event');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure WarrantyExpiredNotRaisedByAlertGeneration()
    var
        Equipment: Record "EQM Equipment";
        WarrantyAlertMgt: Codeunit "EQM Warranty Alert Mgt.";
        Subscriber: Codeunit "EQM Business Event Test Subscr";
        ReferenceDate: Date;
        CreatedCount: Integer;
        CancelledCount: Integer;
    begin
        // [SCENARIO 12] (neg) Generating the alerts does not raise OnWarrantyExpired
        Initialize();
        ReferenceDate := Today();

        // [GIVEN] W1 (end R-1), and the bound subscriber
        CreateEquipmentWithWarranty(Equipment, 1, ReferenceDate - 1);
        BindSubscription(Subscriber);

        // [WHEN] The alerts are generated for R (not scheduled)
        WarrantyAlertMgt.GenerateAlerts(ReferenceDate, false, CreatedCount, CancelledCount);

        // [THEN] The event is not raised
        Assert.AreEqual(0, Subscriber.GetWarrantyExpiredCount(), 'OnWarrantyExpired should not be raised by alert generation');
    end;

    local procedure Initialize()
    var
        Category: Record "EQM Equipment Category";
        Employee: Record Employee;
    begin
        // Everything runs in the test transaction, which is rolled back (AutoRollback), so nothing is committed or cleaned up.
        Category.Init();
        Category.Code := CategoryTok;
        Category.Active := true;
        Category.Insert();

        Employee.Init();
        Employee."No." := EmployeeTok;
        Employee."First Name" := 'BEV';
        Employee."Last Name" := EmployeeTok;
        Employee.Status := Employee.Status::Active;
        Employee.Insert(false);
    end;

    local procedure InitEquipment(var Equipment: Record "EQM Equipment"; EquipmentNo: Code[20])
    begin
        Equipment.Init();
        Equipment."No." := EquipmentNo;
        Equipment.Description := 'EQMBEV test equipment';
        Equipment."Category Code" := CategoryTok;
    end;

    local procedure CreateEquipment(var Equipment: Record "EQM Equipment"; EquipmentNo: Code[20])
    begin
        InitEquipment(Equipment, EquipmentNo);
        Equipment.Insert(true);
    end;

    local procedure CreateEquipmentWithWarranty(var Equipment: Record "EQM Equipment"; Index: Integer; WarrantyEndDate: Date)
    begin
        InitEquipment(Equipment, CopyStr(StrSubstNo(WarrantyNoTok, Index), 1, MaxStrLen(Equipment."No.")));
        Equipment."Warranty End Date" := WarrantyEndDate;
        Equipment.Insert(true);
    end;

    local procedure InitMaintenance(var MaintenanceRecord: Record "EQM Maintenance Record"; MaintenanceNo: Code[20]; EquipmentNo: Code[20])
    begin
        MaintenanceRecord.Init();
        MaintenanceRecord."No." := MaintenanceNo;
        MaintenanceRecord."Equipment No." := EquipmentNo;
        MaintenanceRecord."Maintenance Date" := Today();
        MaintenanceRecord.Description := 'EQMBEV test maintenance';
    end;

    local procedure GetActiveEntryNo(EquipmentNo: Code[20]): Integer
    var
        Assignment: Record "EQM Equipment Assignment";
    begin
        Assignment.SetRange("Equipment No.", EquipmentNo);
        Assignment.SetRange(Status, Assignment.Status::Active);
        Assignment.FindFirst();
        exit(Assignment."Entry No.");
    end;

    local procedure AssertNoEvents(Subscriber: Codeunit "EQM Business Event Test Subscr")
    begin
        Assert.AreEqual(0, Subscriber.GetCreatedCount(), 'OnEquipmentCreated should not be raised');
        Assert.AreEqual(0, Subscriber.GetAssignedCount(), 'OnEquipmentAssigned should not be raised');
        Assert.AreEqual(0, Subscriber.GetReturnedCount(), 'OnEquipmentReturned should not be raised');
        Assert.AreEqual(0, Subscriber.GetMaintenanceCreatedCount(), 'OnMaintenanceCreated should not be raised');
        Assert.AreEqual(0, Subscriber.GetWarrantyExpiredCount(), 'OnWarrantyExpired should not be raised');
    end;

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
}
