namespace MiguelCarvalho.EquipmentManagement.Tests;

using Microsoft.HumanResources.Employee;
using MiguelCarvalho.EquipmentManagement;
using System.TestLibraries.Utilities;

/// <summary>
/// Tests for the two external business events of codeunit 50130 (FR-031), scenarios 1 to 7. The events are observed
/// with the manual subscriber codeunit 50188, bound after the setup so setup actions are not counted. Scenario 8
/// (Power Automate discovery, Teams message, email, rollback, Reader permission) is verified in the sandbox.
/// A failed statement (asserterror) rolls back the test transaction, so a test that expects an error has exactly one
/// asserterror, as its last action. The subscriber counters live in the codeunit instance and survive the rollback.
/// </summary>
codeunit 50187 "EQM Power Automate Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        CategoryTok: Label 'EQMPAE-CAT', Locked = true;
        EmployeeTok: Label 'EQMPAE-E1', Locked = true;
        EquipmentNoTok: Label 'EQMPAE-EQ', Locked = true;
        WarrantyNoTok: Label 'EQMPAE-W%1', Locked = true;
        MaintenanceNoTok: Label 'EQMPAE-M1', Locked = true;
        DescriptionTok: Label 'EQMPAE test equipment', Locked = true;
        ProviderTok: Label 'EQMPAE Provider', Locked = true;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EquipmentAssignedRaisedOnAssign()
    var
        Equipment: Record "EQM Equipment";
        Assignment: Record "EQM Equipment Assignment";
        Subscriber: Codeunit "EQM Power Automate Test Subscr";
    begin
        // [SCENARIO 1] EquipmentAssigned is raised once with the equipment values and the stored active entry
        Initialize();

        // [GIVEN] Available equipment EQ and the bound subscriber
        CreateEquipment(Equipment, EquipmentNoTok);
        BindSubscription(Subscriber);

        // [WHEN] EQ is assigned to E1
        Equipment.AssignEmployee(EmployeeTok);

        // [THEN] The event is raised once, with the SystemId, number, description and employee of EQ
        Equipment.Get(EquipmentNoTok);
        Assert.AreEqual(1, Subscriber.GetAssignedCount(), 'EquipmentAssigned should be raised once');
        Assert.AreEqual(Equipment.SystemId, Subscriber.GetLastAssignedEquipmentId(), 'The event should carry the SystemId of EQ');
        Assert.AreEqual(EquipmentNoTok, Subscriber.GetLastAssignedEquipmentNo(), 'The event should carry the number of EQ');
        Assert.AreEqual(DescriptionTok, Subscriber.GetLastAssignedDescription(), 'The event should carry the description of EQ');
        Assert.AreEqual(EmployeeTok, Subscriber.GetLastAssignedEmployeeNo(), 'The event should carry employee E1');

        // [THEN] The assignment id and date are those of the stored active entry
        Assignment.SetRange("Equipment No.", EquipmentNoTok);
        Assignment.SetRange(Status, Assignment.Status::Active);
        Assignment.FindFirst();
        Assert.AreEqual(Assignment.SystemId, Subscriber.GetLastAssignedAssignmentId(), 'The event should carry the SystemId of the active entry');
        Assert.AreEqual(Assignment."Assignment Date", Subscriber.GetLastAssignedDate(), 'The event should carry the assignment date of the active entry');
        Assert.AreEqual(0, Subscriber.GetExpiringCount(), 'WarrantyExpiring should not be raised by an assignment');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EquipmentAssignedNotRaisedWhenAssignFails()
    var
        Equipment: Record "EQM Equipment";
        MaintenanceRecord: Record "EQM Maintenance Record";
        Subscriber: Codeunit "EQM Power Automate Test Subscr";
    begin
        // [SCENARIO 2] (neg) A failing assignment does not raise EquipmentAssigned
        Initialize();

        // [GIVEN] EQ with an open maintenance record, and the bound subscriber
        CreateEquipment(Equipment, EquipmentNoTok);
        InitMaintenance(MaintenanceRecord);
        MaintenanceRecord.Insert(true);
        Equipment.Get(EquipmentNoTok);
        BindSubscription(Subscriber);

        // [WHEN] EQ is assigned to E1
        asserterror Equipment.AssignEmployee(EmployeeTok);

        // [THEN] The assignment failed and the event was not raised
        Assert.AreEqual(0, Subscriber.GetAssignedCount(), 'EquipmentAssigned should not be raised when the assignment fails');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure EquipmentAssignedNotRaisedOnUnassign()
    var
        Equipment: Record "EQM Equipment";
        Subscriber: Codeunit "EQM Power Automate Test Subscr";
    begin
        // [SCENARIO 3] (neg) Returning equipment does not raise EquipmentAssigned
        Initialize();

        // [GIVEN] EQ assigned to E1, and the bound subscriber
        CreateEquipment(Equipment, EquipmentNoTok);
        Equipment.AssignEmployee(EmployeeTok);
        BindSubscription(Subscriber);

        // [WHEN] EQ is returned (confirm Yes)
        Equipment.Get(EquipmentNoTok);
        Assert.IsTrue(Equipment.UnassignEmployee(), 'The return should be done');

        // [THEN] No event is raised
        Assert.AreEqual(0, Subscriber.GetAssignedCount(), 'EquipmentAssigned should not be raised by a return');
        Assert.AreEqual(0, Subscriber.GetExpiringCount(), 'WarrantyExpiring should not be raised by a return');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure WarrantyExpiringRaisedWhenAlertCreated()
    var
        Equipment: Record "EQM Equipment";
        WarrantyAlertMgt: Codeunit "EQM Warranty Alert Mgt.";
        Subscriber: Codeunit "EQM Power Automate Test Subscr";
        ReferenceDate: Date;
        CreatedCount: Integer;
        CancelledCount: Integer;
    begin
        // [SCENARIO 4] WarrantyExpiring is raised once when the 30 day alert is created
        Initialize();
        ReferenceDate := Today();

        // [GIVEN] Equipment W with warranty end R+20, and the bound subscriber
        CreateEquipmentWithWarranty(Equipment, 1, ReferenceDate + 20);
        BindSubscription(Subscriber);

        // [WHEN] The alerts are generated for R
        WarrantyAlertMgt.GenerateAlerts(ReferenceDate, false, CreatedCount, CancelledCount);

        // [THEN] One alert is created and the event is raised once with the values of W
        Assert.AreEqual(1, CreatedCount, 'One alert should be created');
        Assert.AreEqual(1, Subscriber.GetExpiringCount(), 'WarrantyExpiring should be raised once');
        Assert.AreEqual(Equipment.SystemId, Subscriber.GetLastExpiringEquipmentId(), 'The event should carry the SystemId of W');
        Assert.AreEqual(Equipment."No.", Subscriber.GetLastExpiringEquipmentNo(), 'The event should carry the number of W');
        Assert.AreEqual(DescriptionTok, Subscriber.GetLastExpiringDescription(), 'The event should carry the description of W');
        Assert.AreEqual(ProviderTok, Subscriber.GetLastExpiringProvider(), 'The event should carry the warranty provider of W');
        Assert.AreEqual(ReferenceDate + 20, Subscriber.GetLastExpiringEndDate(), 'The event should carry the warranty end date');
        Assert.AreEqual(20, Subscriber.GetLastExpiringDaysRemaining(), 'The event should carry 20 days remaining');
        Assert.AreEqual(30, Subscriber.GetLastExpiringIntervalDays(), 'The event should carry the 30 day interval');
        Assert.AreEqual(0, Subscriber.GetAssignedCount(), 'EquipmentAssigned should not be raised by alert generation');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure WarrantyExpiringNotRaisedAgainForSameAlert()
    var
        Equipment: Record "EQM Equipment";
        WarrantyAlertMgt: Codeunit "EQM Warranty Alert Mgt.";
        Subscriber: Codeunit "EQM Power Automate Test Subscr";
        ReferenceDate: Date;
        CreatedCount: Integer;
        CancelledCount: Integer;
    begin
        // [SCENARIO 5] (neg) Generating the alerts again creates no alert and raises no further event
        Initialize();
        ReferenceDate := Today();

        // [GIVEN] W (end R+20) with its alert already generated, and the bound subscriber
        CreateEquipmentWithWarranty(Equipment, 1, ReferenceDate + 20);
        WarrantyAlertMgt.GenerateAlerts(ReferenceDate, false, CreatedCount, CancelledCount);
        BindSubscription(Subscriber);

        // [WHEN] The alerts are generated again for R
        WarrantyAlertMgt.GenerateAlerts(ReferenceDate, false, CreatedCount, CancelledCount);

        // [THEN] No alert is created and the event is not raised
        Assert.AreEqual(0, CreatedCount, 'No alert should be created the second time');
        Assert.AreEqual(0, Subscriber.GetExpiringCount(), 'WarrantyExpiring should not be raised again');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure WarrantyExpiringNotRaisedForTemporaryOrWithoutTriggers()
    var
        Equipment: Record "EQM Equipment";
        WarrantyAlert: Record "EQM Warranty Alert";
        TempWarrantyAlert: Record "EQM Warranty Alert" temporary;
        Subscriber: Codeunit "EQM Power Automate Test Subscr";
        ReferenceDate: Date;
    begin
        // [SCENARIO 6] (neg) A temporary alert and an Insert(false) raise no event
        Initialize();
        ReferenceDate := Today();

        // [GIVEN] Equipment W with warranty end R+20, and the bound subscriber
        CreateEquipmentWithWarranty(Equipment, 1, ReferenceDate + 20);
        BindSubscription(Subscriber);

        // [WHEN] An alert for W is inserted as a temporary record, and another with Insert(false)
        InitAlert(TempWarrantyAlert, Equipment, ReferenceDate);
        TempWarrantyAlert.Insert(true);
        InitAlert(WarrantyAlert, Equipment, ReferenceDate);
        WarrantyAlert.Insert(false);

        // [THEN] The event is not raised
        Assert.AreEqual(0, Subscriber.GetExpiringCount(), 'WarrantyExpiring should not be raised for temporary records or Insert(false)');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure WarrantyExpiringNotRaisedOutsideWindowOrForDisposed()
    var
        Equipment: Record "EQM Equipment";
        WarrantyAlertMgt: Codeunit "EQM Warranty Alert Mgt.";
        Subscriber: Codeunit "EQM Power Automate Test Subscr";
        ReferenceDate: Date;
        CreatedCount: Integer;
        CancelledCount: Integer;
    begin
        // [SCENARIO 7] (neg) No event for a warranty ending beyond 90 days, or for disposed equipment
        Initialize();
        ReferenceDate := Today();

        // [GIVEN] W1 with end R+120, W2 with end R+20 and status Disposed, and the bound subscriber
        CreateEquipmentWithWarranty(Equipment, 1, ReferenceDate + 120);
        CreateEquipmentWithWarranty(Equipment, 2, ReferenceDate + 20);
        Equipment.Validate(Status, Equipment.Status::Disposed);
        Equipment.Modify(true);
        BindSubscription(Subscriber);

        // [WHEN] The alerts are generated for R
        WarrantyAlertMgt.GenerateAlerts(ReferenceDate, false, CreatedCount, CancelledCount);

        // [THEN] No alert is created and the event is not raised
        Assert.AreEqual(0, CreatedCount, 'No alert should be created');
        Assert.AreEqual(0, Subscriber.GetExpiringCount(), 'WarrantyExpiring should not be raised');
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
        Employee."First Name" := 'PAE';
        Employee."Last Name" := EmployeeTok;
        Employee.Status := Employee.Status::Active;
        Employee.Insert(false);
    end;

    local procedure CreateEquipment(var Equipment: Record "EQM Equipment"; EquipmentNo: Code[20])
    begin
        Equipment.Init();
        Equipment."No." := EquipmentNo;
        Equipment.Description := DescriptionTok;
        Equipment."Category Code" := CategoryTok;
        Equipment."Warranty Provider" := ProviderTok;
        Equipment.Insert(true);
    end;

    local procedure CreateEquipmentWithWarranty(var Equipment: Record "EQM Equipment"; Index: Integer; WarrantyEndDate: Date)
    begin
        Equipment.Init();
        Equipment."No." := CopyStr(StrSubstNo(WarrantyNoTok, Index), 1, MaxStrLen(Equipment."No."));
        Equipment.Description := DescriptionTok;
        Equipment."Category Code" := CategoryTok;
        Equipment."Warranty Provider" := ProviderTok;
        Equipment."Warranty End Date" := WarrantyEndDate;
        Equipment.Insert(true);
    end;

    local procedure InitMaintenance(var MaintenanceRecord: Record "EQM Maintenance Record")
    begin
        MaintenanceRecord.Init();
        MaintenanceRecord."No." := MaintenanceNoTok;
        MaintenanceRecord."Equipment No." := EquipmentNoTok;
        MaintenanceRecord."Maintenance Date" := Today();
        MaintenanceRecord.Description := 'EQMPAE test maintenance';
    end;

    local procedure InitAlert(var WarrantyAlert: Record "EQM Warranty Alert"; Equipment: Record "EQM Equipment"; ReferenceDate: Date)
    begin
        WarrantyAlert.Init();
        WarrantyAlert."Equipment No." := Equipment."No.";
        WarrantyAlert."Alert Interval" := WarrantyAlert."Alert Interval"::"30 Days";
        WarrantyAlert."Warranty End Date" := Equipment."Warranty End Date";
        WarrantyAlert."Alert Date" := ReferenceDate;
        WarrantyAlert.Status := WarrantyAlert.Status::Open;
    end;

    [ConfirmHandler]
    procedure ConfirmYesHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}
