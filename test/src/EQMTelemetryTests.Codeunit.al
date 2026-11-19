namespace MiguelCarvalho.EquipmentManagement.Tests;

using Microsoft.HumanResources.Employee;
using MiguelCarvalho.EquipmentManagement;
using System.TestLibraries.Utilities;

/// <summary>
/// Tests for the usage telemetry signals EQM0005 to EQM0009 (FR-050), scenarios 1 to 12. The signals are observed with
/// the manual subscriber codeunit 50152, bound in each test after the setup, so setup actions are not counted. That the
/// signals reach Application Insights cannot be tested here and is verified manually in the sandbox.
/// A failed statement (asserterror) rolls back the whole test transaction, so each test that expects an error has
/// exactly one asserterror, as its last action. The state of the subscriber lives in the codeunit instance and is not
/// rolled back, so it can still be read afterwards.
/// </summary>
codeunit 50151 "EQM Telemetry Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        CategoryTok: Label 'EQMTEL-CAT', Locked = true;
        EmployeeTok: Label 'EQMTEL-E1', Locked = true;
        EquipmentNoTok: Label 'EQMTEL-EQ', Locked = true;
        NewEquipmentNoTok: Label 'EQMTEL-NEW', Locked = true;
        MaintenanceNoTok: Label 'EQMTEL-M1', Locked = true;
        WarrantyNoTok: Label 'EQMTEL-W%1', Locked = true;
        CreatedIdTok: Label 'EQM0005', Locked = true;
        AssignedIdTok: Label 'EQM0006', Locked = true;
        ReturnedIdTok: Label 'EQM0007', Locked = true;
        MaintenanceIdTok: Label 'EQM0008', Locked = true;
        WarrantyIdTok: Label 'EQM0009', Locked = true;
        EquipmentStatusDimTok: Label 'EquipmentStatus', Locked = true;
        MaintenanceTypeDimTok: Label 'MaintenanceType', Locked = true;
        AssignmentDaysDimTok: Label 'AssignmentDays', Locked = true;
        EquipmentDescriptionTok: Label 'EQMTEL test equipment', Locked = true;
        MaintenanceDescriptionTok: Label 'EQMTEL test maintenance', Locked = true;
        ChangedDescriptionTok: Label 'EQMTEL changed description', Locked = true;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EquipmentCreatedLogsEQM0005()
    var
        Equipment: Record "EQM Equipment";
        Subscriber: Codeunit "EQM Telemetry Test Subscr";
    begin
        // [SCENARIO 1] Insert(true) of new equipment logs EQM0005 once, with the equipment status
        Initialize();

        // [GIVEN] The subscriber is bound
        BindSubscription(Subscriber);

        // [WHEN] New equipment is inserted with Insert(true)
        InitEquipment(Equipment, NewEquipmentNoTok);
        Equipment.Insert(true);

        // [THEN] EQM0005 is logged once with status Available, and nothing else is logged
        Assert.AreEqual(1, Subscriber.CountOf(CreatedIdTok), 'EQM0005 should be logged once');
        Assert.AreEqual('Available', Subscriber.GetDimension(CreatedIdTok, EquipmentStatusDimTok), 'EQM0005 should carry the status name');
        Assert.AreEqual(1, Subscriber.TotalCount(), 'Only one signal should be logged');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NoCreatedSignalForInsertFalseOrTemporary()
    var
        Equipment: Record "EQM Equipment";
        TempEquipment: Record "EQM Equipment" temporary;
        Subscriber: Codeunit "EQM Telemetry Test Subscr";
    begin
        // [SCENARIO 2] (neg) Insert(false) and a temporary record log nothing
        Initialize();

        // [GIVEN] The subscriber is bound
        BindSubscription(Subscriber);

        // [WHEN] Equipment is inserted with Insert(false), and a temporary record with Insert(true)
        InitEquipment(Equipment, NewEquipmentNoTok);
        Equipment.Insert(false);
        InitEquipment(TempEquipment, EquipmentNoTok);
        TempEquipment.Insert(true);

        // [THEN] No signal is logged
        Assert.AreEqual(0, Subscriber.TotalCount(), 'No signal should be logged for Insert(false) or temporary records');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NoCreatedSignalWhenInsertFails()
    var
        Equipment: Record "EQM Equipment";
        Subscriber: Codeunit "EQM Telemetry Test Subscr";
    begin
        // [SCENARIO 3] (neg) A failing insert (no category) logs no EQM0005
        Initialize();

        // [GIVEN] The subscriber is bound, and equipment without a category
        BindSubscription(Subscriber);
        InitEquipment(Equipment, NewEquipmentNoTok);
        Equipment."Category Code" := '';

        // [WHEN] The equipment is inserted with Insert(true)
        asserterror Equipment.Insert(true);

        // [THEN] The insert failed and EQM0005 was not logged
        Assert.AreEqual(0, Subscriber.CountOf(CreatedIdTok), 'EQM0005 should not be logged when the insert fails');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EquipmentAssignedLogsEQM0006()
    var
        Equipment: Record "EQM Equipment";
        Subscriber: Codeunit "EQM Telemetry Test Subscr";
    begin
        // [SCENARIO 4] Assigning equipment logs EQM0006 once, without dimensions
        Initialize();

        // [GIVEN] Available equipment EQ and the bound subscriber
        CreateEquipment(Equipment, EquipmentNoTok);
        BindSubscription(Subscriber);

        // [WHEN] EQ is assigned to E1
        Equipment.AssignEmployee(EmployeeTok);

        // [THEN] EQM0006 is logged once, with no status dimension, and no return is logged
        Assert.AreEqual(1, Subscriber.CountOf(AssignedIdTok), 'EQM0006 should be logged once');
        Assert.AreEqual(0, Subscriber.CountOf(ReturnedIdTok), 'EQM0007 should not be logged by an assignment');
        Assert.IsFalse(Subscriber.HasDimension(AssignedIdTok, EquipmentStatusDimTok), 'EQM0006 should carry no status dimension');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NoAssignedSignalWhenAssignFails()
    var
        Equipment: Record "EQM Equipment";
        MaintenanceRecord: Record "EQM Maintenance Record";
        Subscriber: Codeunit "EQM Telemetry Test Subscr";
    begin
        // [SCENARIO 5] (neg) A failing assignment logs no EQM0006
        Initialize();

        // [GIVEN] EQ with an open maintenance record (status In Maintenance), and the bound subscriber
        CreateEquipment(Equipment, EquipmentNoTok);
        InitMaintenance(MaintenanceRecord, MaintenanceNoTok, EquipmentNoTok);
        MaintenanceRecord.Insert(true);
        Equipment.Get(EquipmentNoTok);
        BindSubscription(Subscriber);

        // [WHEN] EQ is assigned to E1
        asserterror Equipment.AssignEmployee(EmployeeTok);

        // [THEN] The assignment failed and EQM0006 was not logged
        Assert.AreEqual(0, Subscriber.CountOf(AssignedIdTok), 'EQM0006 should not be logged when the assignment fails');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure EquipmentReturnedLogsEQM0007()
    var
        Equipment: Record "EQM Equipment";
        Subscriber: Codeunit "EQM Telemetry Test Subscr";
    begin
        // [SCENARIO 6] Returning equipment logs EQM0007 once, with the status and the days assigned
        Initialize();

        // [GIVEN] EQ assigned to E1, and the bound subscriber
        CreateEquipment(Equipment, EquipmentNoTok);
        Equipment.AssignEmployee(EmployeeTok);
        BindSubscription(Subscriber);

        // [WHEN] EQ is returned (confirm Yes)
        Equipment.Get(EquipmentNoTok);
        Assert.IsTrue(Equipment.UnassignEmployee(), 'The return should be done');

        // [THEN] EQM0007 is logged once with status Available and 0 days (assigned and returned the same day)
        Assert.AreEqual(1, Subscriber.CountOf(ReturnedIdTok), 'EQM0007 should be logged once');
        Assert.AreEqual('Available', Subscriber.GetDimension(ReturnedIdTok, EquipmentStatusDimTok), 'EQM0007 should carry the status name');
        Assert.AreEqual('0', Subscriber.GetDimension(ReturnedIdTok, AssignmentDaysDimTok), 'EQM0007 should carry the days assigned');
        Assert.AreEqual(0, Subscriber.CountOf(AssignedIdTok), 'EQM0006 should not be logged by a return');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure MaintenanceOnAssignedLogsEQM0007AndEQM0008()
    var
        Equipment: Record "EQM Equipment";
        MaintenanceRecord: Record "EQM Maintenance Record";
        Subscriber: Codeunit "EQM Telemetry Test Subscr";
    begin
        // [SCENARIO 7] Registering maintenance for assigned equipment logs EQM0007 and EQM0008
        Initialize();

        // [GIVEN] EQ assigned to E1, and the bound subscriber
        CreateEquipment(Equipment, EquipmentNoTok);
        Equipment.AssignEmployee(EmployeeTok);
        BindSubscription(Subscriber);

        // [WHEN] A Corrective maintenance record is inserted for EQ (confirm Yes)
        InitMaintenance(MaintenanceRecord, MaintenanceNoTok, EquipmentNoTok);
        MaintenanceRecord."Maintenance Type" := MaintenanceRecord."Maintenance Type"::Corrective;
        MaintenanceRecord.Insert(true);

        // [THEN] EQM0007 is logged once with status In Maintenance
        Assert.AreEqual(1, Subscriber.CountOf(ReturnedIdTok), 'EQM0007 should be logged once');
        Assert.AreEqual('In Maintenance', Subscriber.GetDimension(ReturnedIdTok, EquipmentStatusDimTok), 'EQM0007 should carry the status name');

        // [THEN] EQM0008 is logged once with type Corrective
        Assert.AreEqual(1, Subscriber.CountOf(MaintenanceIdTok), 'EQM0008 should be logged once');
        Assert.AreEqual('Corrective', Subscriber.GetDimension(MaintenanceIdTok, MaintenanceTypeDimTok), 'EQM0008 should carry the type name');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('ConfirmNoHandler')]
    procedure NoSignalWhenReturnCancelledOrDescriptionChanged()
    var
        Equipment: Record "EQM Equipment";
        Subscriber: Codeunit "EQM Telemetry Test Subscr";
    begin
        // [SCENARIO 8] (neg) A cancelled return and an unrelated change log nothing
        Initialize();

        // [GIVEN] EQ assigned to E1, and the bound subscriber
        CreateEquipment(Equipment, EquipmentNoTok);
        Equipment.AssignEmployee(EmployeeTok);
        BindSubscription(Subscriber);

        // [WHEN] The return is answered No
        Equipment.Get(EquipmentNoTok);
        Assert.IsFalse(Equipment.UnassignEmployee(), 'The return should be cancelled');

        // [THEN] No signal is logged
        Assert.AreEqual(0, Subscriber.TotalCount(), 'No signal should be logged for a cancelled return');

        // [WHEN] The description of the assigned EQ is changed and modified
        Equipment.Get(EquipmentNoTok);
        Equipment.Description := CopyStr(ChangedDescriptionTok, 1, MaxStrLen(Equipment.Description));
        Equipment.Modify(true);

        // [THEN] No signal is logged
        Assert.AreEqual(0, Subscriber.TotalCount(), 'No signal should be logged for a description change');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NoMaintenanceSignalOnModifyOrPost()
    var
        Equipment: Record "EQM Equipment";
        MaintenanceRecord: Record "EQM Maintenance Record";
        Subscriber: Codeunit "EQM Telemetry Test Subscr";
    begin
        // [SCENARIO 9] (neg) Modifying and posting a maintenance record does not log EQM0008 again
        Initialize();

        // [GIVEN] An open maintenance record for EQ, and the bound subscriber
        CreateEquipment(Equipment, EquipmentNoTok);
        InitMaintenance(MaintenanceRecord, MaintenanceNoTok, EquipmentNoTok);
        MaintenanceRecord.Insert(true);
        BindSubscription(Subscriber);

        // [WHEN] The record is modified and then posted
        MaintenanceRecord.Get(MaintenanceNoTok);
        MaintenanceRecord.Description := CopyStr(ChangedDescriptionTok, 1, MaxStrLen(MaintenanceRecord.Description));
        MaintenanceRecord.Modify(true);
        Codeunit.Run(Codeunit::"EQM Maintenance-Post", MaintenanceRecord);

        // [THEN] The record is posted and EQM0008 was not logged
        MaintenanceRecord.Get(MaintenanceNoTok);
        Assert.AreEqual(MaintenanceRecord.Status::Posted, MaintenanceRecord.Status, 'The record should be posted');
        Assert.AreEqual(0, Subscriber.CountOf(MaintenanceIdTok), 'EQM0008 should not be logged by modify or post');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure WarrantyExpiredLogsEQM0009()
    var
        Equipment: Record "EQM Equipment";
        WarrantyAlertMgt: Codeunit "EQM Warranty Alert Mgt.";
        Subscriber: Codeunit "EQM Telemetry Test Subscr";
        ReferenceDate: Date;
    begin
        // [SCENARIO 10] EQM0009 is logged once for the equipment whose warranty ended the day before
        Initialize();
        ReferenceDate := Today();

        // [GIVEN] W1 (end R-1), W2 (end R), and the bound subscriber
        CreateEquipmentWithWarranty(Equipment, 1, ReferenceDate - 1);
        CreateEquipmentWithWarranty(Equipment, 2, ReferenceDate);
        BindSubscription(Subscriber);

        // [WHEN] The warranty expired events are raised for R
        WarrantyAlertMgt.RaiseWarrantyExpiredEvents(ReferenceDate);

        // [THEN] EQM0009 is logged once, with status Available
        Assert.AreEqual(1, Subscriber.CountOf(WarrantyIdTok), 'EQM0009 should be logged once');
        Assert.AreEqual('Available', Subscriber.GetDimension(WarrantyIdTok, EquipmentStatusDimTok), 'EQM0009 should carry the status name');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NoWarrantyExpiredSignalFromAlertGeneration()
    var
        Equipment: Record "EQM Equipment";
        WarrantyAlertMgt: Codeunit "EQM Warranty Alert Mgt.";
        Subscriber: Codeunit "EQM Telemetry Test Subscr";
        ReferenceDate: Date;
        CreatedCount: Integer;
        CancelledCount: Integer;
    begin
        // [SCENARIO 11] (neg) Generating the alerts does not log EQM0009
        Initialize();
        ReferenceDate := Today();

        // [GIVEN] W1 (end R-1), and the bound subscriber
        CreateEquipmentWithWarranty(Equipment, 1, ReferenceDate - 1);
        BindSubscription(Subscriber);

        // [WHEN] The alerts are generated for R (not scheduled)
        WarrantyAlertMgt.GenerateAlerts(ReferenceDate, false, CreatedCount, CancelledCount);

        // [THEN] EQM0009 is not logged
        Assert.AreEqual(0, Subscriber.CountOf(WarrantyIdTok), 'EQM0009 should not be logged by alert generation');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure SignalsCarryNoCustomerContent()
    var
        Equipment: Record "EQM Equipment";
        MaintenanceRecord: Record "EQM Maintenance Record";
        Subscriber: Codeunit "EQM Telemetry Test Subscr";
    begin
        // [SCENARIO 12] (neg, privacy) No dimension value holds an equipment, employee or maintenance number, a description or the user ID
        Initialize();

        // [GIVEN] The subscriber is bound
        BindSubscription(Subscriber);

        // [WHEN] Equipment is created, assigned to E1, and a maintenance record M1 is registered (confirm Yes)
        CreateEquipment(Equipment, EquipmentNoTok);
        Equipment.AssignEmployee(EmployeeTok);
        InitMaintenance(MaintenanceRecord, MaintenanceNoTok, EquipmentNoTok);
        MaintenanceRecord.Insert(true);

        // [THEN] Four signals are logged (EQM0005 to EQM0008), and none holds customer content
        Assert.AreEqual(4, Subscriber.TotalCount(), 'Four signals should be logged');
        Assert.IsFalse(Subscriber.AnyValueContains(EquipmentNoTok), 'No value should contain the equipment number');
        Assert.IsFalse(Subscriber.AnyValueContains(EmployeeTok), 'No value should contain the employee number');
        Assert.IsFalse(Subscriber.AnyValueContains(MaintenanceNoTok), 'No value should contain the maintenance number');
        Assert.IsFalse(Subscriber.AnyValueContains(EquipmentDescriptionTok), 'No value should contain the equipment description');
        Assert.IsFalse(Subscriber.AnyValueContains(MaintenanceDescriptionTok), 'No value should contain the maintenance description');
        Assert.IsFalse(Subscriber.AnyValueContains(UserId()), 'No value should contain the user ID');
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
        Employee."First Name" := 'TEL';
        Employee."Last Name" := EmployeeTok;
        Employee.Status := Employee.Status::Active;
        Employee.Insert(false);
    end;

    local procedure InitEquipment(var Equipment: Record "EQM Equipment"; EquipmentNo: Code[20])
    begin
        Equipment.Init();
        Equipment."No." := EquipmentNo;
        Equipment.Description := CopyStr(EquipmentDescriptionTok, 1, MaxStrLen(Equipment.Description));
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
        MaintenanceRecord.Description := CopyStr(MaintenanceDescriptionTok, 1, MaxStrLen(MaintenanceRecord.Description));
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
