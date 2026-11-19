namespace MiguelCarvalho.EquipmentManagement.Tests;

using Microsoft.Foundation.Attachment;
using Microsoft.HumanResources.Employee;
using MiguelCarvalho.EquipmentManagement;
using System.TestLibraries.Utilities;

/// <summary>
/// Tests of Create Demo Data and Delete Demo Data (codeunit 50149): what is created, that nothing a user created is
/// changed or deleted, and that Delete removes only tracked demo records. The permission-denied path is not tested:
/// it needs the Library - Lower Permissions app, which would change test/app.json. The keep-rule for a picture on
/// demo equipment is not tested either: there is no test library to attach a media set.
/// </summary>
codeunit 50176 "EQM Demo Data Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        DemoDataMgt: Codeunit "EQM Demo Data Mgt.";
        Counter: Integer;
        EmployeesCreated: Integer;
        EquipmentCreated: Integer;
        AssignmentsCreated: Integer;
        MaintenanceCreated: Integer;
        SkippedCount: Integer;
        EquipmentDeleted: Integer;
        EmployeesDeleted: Integer;
        EquipmentKept: Integer;
        EmployeesKept: Integer;
        NotificationCount: Integer;
        LastNotificationText: Text;
        EquipmentFilterTok: Label 'EQMDEMO-*', Locked = true;
        EmployeeFilterTok: Label 'EQMDEMO-E*', Locked = true;
        MaintenanceFilterTok: Label 'EQMDEMO-M*', Locked = true;
        Equipment001Tok: Label 'EQMDEMO-001', Locked = true;
        Equipment002Tok: Label 'EQMDEMO-002', Locked = true;
        Equipment003Tok: Label 'EQMDEMO-003', Locked = true;
        Equipment005Tok: Label 'EQMDEMO-005', Locked = true;
        Equipment010Tok: Label 'EQMDEMO-010', Locked = true;
        Equipment012Tok: Label 'EQMDEMO-012', Locked = true;
        Equipment015Tok: Label 'EQMDEMO-015', Locked = true;
        Employee01Tok: Label 'EQMDEMO-E01', Locked = true;
        Employee03Tok: Label 'EQMDEMO-E03', Locked = true;
        Employee05Tok: Label 'EQMDEMO-E05', Locked = true;
        Employee06Tok: Label 'EQMDEMO-E06', Locked = true;
        Employee08Tok: Label 'EQMDEMO-E08', Locked = true;
        RenamedEquipmentTok: Label 'EQMREN-010', Locked = true;
        LaptopCategoryTok: Label 'LAPTOP', Locked = true;
        UserFirstNameTok: Label 'User', Locked = true;
        UserEmployeeNoTok: Label 'EQMDTU%1', Locked = true;
        UserEquipmentNoTok: Label 'EQMDTQ%1', Locked = true;
        UserMaintenanceNoTok: Label 'EQMDTM%1', Locked = true;
        UserRequestNoTok: Label 'EQMDTR%1', Locked = true;
        Equipment005AttachmentTok: Label 'EQMDEMO-005', Locked = true;
        Employee02Tok: Label 'EQMDEMO-E02', Locked = true;
        Employee04Tok: Label 'EQMDEMO-E04', Locked = true;
        CounterFormatTok: Label '<Integer,4><Filler Character,0>', Locked = true;
        SnapshotFormatTok: Label '%1|%2|%3|%4|%5|%6|%7|%8|%9|%10', Locked = true;
        UserNoteTok: Label 'Added by a user', Locked = true;
        ChangedDescriptionTok: Label 'Changed by a user', Locked = true;
        // Copies of the internal labels of codeunit 50149; labels of another app are not accessible.
        DemoDataCreatedMsg: Label 'Demo data was created: %1 employees, %2 equipment, %3 assignments and %4 maintenance records. %5 items were skipped because their number was already used or their category is missing or inactive.', Comment = '%1 = number of employees, %2 = number of equipment, %3 = number of assignments, %4 = number of maintenance records, %5 = number of skipped items';
        NoDemoDataMsg: Label 'There is no demo data to delete in this company.';

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CreateOnFreshCompanyCreatesTheFullDemoSet()
    var
        DemoDataEntry: Record "EQM Demo Data Entry";
        EquipmentAssignment: Record "EQM Equipment Assignment";
        MaintenanceRecord: Record "EQM Maintenance Record";
        MaintenanceHistoryEntry: Record "EQM Maintenance History Entry";
    begin
        Initialize();
        // [SCENARIO 1] Create on a company with the default categories makes the full demo set
        // [GIVEN] No demo data

        // [WHEN] Demo data is created
        CreateDemoData();

        // [THEN] The counts and the final statuses match the plan, and every record is tracked
        Assert.AreEqual(8, EmployeesCreated, 'Employees created');
        Assert.AreEqual(15, EquipmentCreated, 'Equipment created');
        Assert.AreEqual(13, AssignmentsCreated, 'Assignments created');
        Assert.AreEqual(12, MaintenanceCreated, 'Maintenance records created');
        Assert.AreEqual(0, SkippedCount, 'Nothing is skipped');
        AssertStatusCount("EQM Equipment Status"::Assigned, 7);
        AssertStatusCount("EQM Equipment Status"::Available, 3);
        AssertStatusCount("EQM Equipment Status"::"In Maintenance", 3);
        AssertStatusCount("EQM Equipment Status"::Lost, 1);
        AssertStatusCount("EQM Equipment Status"::Disposed, 1);
        EquipmentAssignment.SetFilter("Equipment No.", EquipmentFilterTok);
        Assert.RecordCount(EquipmentAssignment, 13);
        EquipmentAssignment.SetRange(Status, EquipmentAssignment.Status::Active);
        Assert.RecordCount(EquipmentAssignment, 7);
        MaintenanceRecord.SetFilter("No.", MaintenanceFilterTok);
        Assert.RecordCount(MaintenanceRecord, 12);
        MaintenanceRecord.SetRange(Status, MaintenanceRecord.Status::Open);
        Assert.RecordCount(MaintenanceRecord, 3);
        MaintenanceHistoryEntry.SetFilter("Equipment No.", EquipmentFilterTok);
        Assert.RecordCount(MaintenanceHistoryEntry, 9);
        Assert.RecordCount(DemoDataEntry, 35);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SecondCreateChangesNothing()
    var
        SnapshotBefore: Text;
    begin
        Initialize();
        // [SCENARIO 2] (negative) A second Create creates nothing and changes no row count
        // [GIVEN] Demo data was created
        CreateDemoData();
        SnapshotBefore := CountSnapshot();

        // [WHEN] Demo data is created again
        CreateDemoData();

        // [THEN] Nothing is created, 23 master records are skipped and no table changed its row count
        Assert.AreEqual(0, EmployeesCreated + EquipmentCreated + AssignmentsCreated + MaintenanceCreated, 'Nothing should be created');
        Assert.AreEqual(23, SkippedCount, 'Employees and equipment are skipped');
        Assert.AreEqual(SnapshotBefore, CountSnapshot(), 'Row counts should not change');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UserEmployeeWithDemoNumberIsNotChangedOrUsed()
    var
        Employee: Record Employee;
        Equipment: Record "EQM Equipment";
        EquipmentAssignment: Record "EQM Equipment Assignment";
        DemoDataEntry: Record "EQM Demo Data Entry";
    begin
        Initialize();
        // [SCENARIO 3] (negative) An employee that a user created with a demo number is neither changed nor assigned
        // [GIVEN] A user created employee EQMDEMO-E01
        InsertEmployee(Employee, Employee01Tok);

        // [WHEN] Demo data is created
        CreateDemoData();

        // [THEN] The employee is unchanged and untracked, nothing is assigned to it, and the equipment that needed it is Available
        Employee.Get(Employee01Tok);
        Assert.AreEqual(UserFirstNameTok, Employee."First Name", 'The user employee should not change');
        Assert.IsFalse(DemoDataEntry.Get(Database::Employee, Employee01Tok), 'The user employee should not be tracked');
        EquipmentAssignment.SetRange("Employee No.", Employee01Tok);
        Assert.IsTrue(EquipmentAssignment.IsEmpty(), 'Nothing should be assigned to the user employee');
        Equipment.Get(Equipment001Tok);
        Assert.AreEqual("EQM Equipment Status"::Available, Equipment.Status, 'Equipment 001');
        Equipment.Get(Equipment005Tok);
        Assert.AreEqual("EQM Equipment Status"::Available, Equipment.Status, 'Equipment 005');
        Assert.IsTrue(SkippedCount >= 3, 'The employee and two assignments are skipped');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UserEquipmentIsNotChangedByCreate()
    var
        UserEquipment: Record "EQM Equipment";
        EquipmentAssignment: Record "EQM Equipment Assignment";
        MaintenanceRecord: Record "EQM Maintenance Record";
        UserEquipmentNo: Code[20];
    begin
        Initialize();
        // [SCENARIO 4] (negative) Equipment that a user created is not changed
        // [GIVEN] User equipment U
        InsertEquipment(UserEquipment, '');
        UserEquipmentNo := UserEquipment."No.";

        // [WHEN] Demo data is created
        CreateDemoData();

        // [THEN] U keeps its status and description, and has no assignment and no maintenance
        UserEquipment.Get(UserEquipmentNo);
        Assert.AreEqual("EQM Equipment Status"::Available, UserEquipment.Status, 'Status');
        Assert.AreEqual(UserEquipmentNo, UserEquipment.Description, 'Description');
        EquipmentAssignment.SetRange("Equipment No.", UserEquipmentNo);
        Assert.IsTrue(EquipmentAssignment.IsEmpty(), 'No assignment');
        MaintenanceRecord.SetRange("Equipment No.", UserEquipmentNo);
        Assert.IsTrue(MaintenanceRecord.IsEmpty(), 'No maintenance');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DemoDataCoversWarrantyAndMaintenanceVariety()
    var
        Equipment: Record "EQM Equipment";
        MaintenanceMgt: Codeunit "EQM Maintenance Mgt.";
        OverdueBefore: Integer;
    begin
        Initialize();
        // [SCENARIO 5] The demo data has overdue maintenance, each warranty status and overdue planned maintenance
        // [GIVEN] The overdue count before the demo data
        OverdueBefore := MaintenanceMgt.CountOverdueMaintenance(Today());

        // [WHEN] Demo data is created
        CreateDemoData();

        // [THEN] Two more maintenance records are overdue, and the warranty and planned maintenance cases are present
        Assert.AreEqual(OverdueBefore + 2, MaintenanceMgt.CountOverdueMaintenance(Today()), 'Overdue maintenance records');
        Equipment.Get(Equipment002Tok);
        Assert.AreEqual("EQM Warranty Status"::"Expiring Soon", Equipment.GetWarrantyStatus(), 'Equipment 002');
        Equipment.Get(Equipment003Tok);
        Assert.AreEqual("EQM Warranty Status"::Expired, Equipment.GetWarrantyStatus(), 'Equipment 003');
        Equipment.Get(Equipment012Tok);
        Assert.IsTrue(Equipment.IsPlannedMaintenanceOverdue(Today()), 'Planned maintenance of equipment 012 is overdue');
        Equipment.Get(Equipment015Tok);
        Assert.AreEqual("EQM Warranty Status"::" ", Equipment.GetWarrantyStatus(), 'Equipment 015 has no warranty');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DemoDataWritesHistoryLogAndClosedAssignments()
    var
        MaintenanceRecord: Record "EQM Maintenance Record";
        MaintenanceLogEntry: Record "EQM Maintenance Log Entry";
        MaintenanceHistoryEntry: Record "EQM Maintenance History Entry";
        EquipmentAssignment: Record "EQM Equipment Assignment";
    begin
        Initialize();
        // [SCENARIO 6] The maintenance history and log are real, and closed assignments carry their planned dates
        // [GIVEN] No demo data

        // [WHEN] Demo data is created
        CreateDemoData();

        // [THEN] 9 history entries exist and each demo maintenance record has a log entry
        MaintenanceHistoryEntry.SetFilter("Equipment No.", EquipmentFilterTok);
        Assert.RecordCount(MaintenanceHistoryEntry, 9);
        MaintenanceRecord.SetFilter("No.", MaintenanceFilterTok);
        MaintenanceRecord.FindSet();
        repeat
            MaintenanceLogEntry.SetRange("Maintenance No.", MaintenanceRecord."No.");
            Assert.IsFalse(MaintenanceLogEntry.IsEmpty(), MaintenanceRecord."No.");
        until MaintenanceRecord.Next() = 0;

        // [THEN] Equipment 003 has two closed entries with the planned dates
        EquipmentAssignment.SetRange("Equipment No.", Equipment003Tok);
        EquipmentAssignment.SetRange(Status, EquipmentAssignment.Status::Closed);
        Assert.RecordCount(EquipmentAssignment, 2);
        EquipmentAssignment.SetRange("Employee No.", Employee03Tok);
        EquipmentAssignment.FindFirst();
        Assert.AreEqual(Today() - 880, EquipmentAssignment."Assignment Date", 'E03 assignment date');
        Assert.AreEqual(Today() - 300, EquipmentAssignment."Closing Date", 'E03 closing date');
        EquipmentAssignment.SetRange("Employee No.", Employee06Tok);
        EquipmentAssignment.FindFirst();
        Assert.AreEqual(Today() - 290, EquipmentAssignment."Assignment Date", 'E06 assignment date');
        Assert.AreEqual(Today() - 30, EquipmentAssignment."Closing Date", 'E06 closing date');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DeleteRemovesAllDemoData()
    var
        Equipment: Record "EQM Equipment";
        Employee: Record Employee;
        MaintenanceRecord: Record "EQM Maintenance Record";
        MaintenanceHistoryEntry: Record "EQM Maintenance History Entry";
        MaintenanceLogEntry: Record "EQM Maintenance Log Entry";
        AuditEntry: Record "EQM Equipment Audit Entry";
        EquipmentAssignment: Record "EQM Equipment Assignment";
        WarrantyAlert: Record "EQM Warranty Alert";
        IntegrationEventEntry: Record "EQM Integration Event Entry";
        DemoDataEntry: Record "EQM Demo Data Entry";
        WarrantyAlertMgt: Codeunit "EQM Warranty Alert Mgt.";
        AlertsCreated: Integer;
        AlertsCancelled: Integer;
    begin
        Initialize();
        // [SCENARIO 7] Delete removes the demo records and everything that exists only because of them
        // [GIVEN] Integration events are on, demo data was created and warranty alerts were generated
        EnableIntegrationEvents();
        CreateDemoData();
        WarrantyAlertMgt.GenerateAlerts(Today(), false, AlertsCreated, AlertsCancelled);
        WarrantyAlert.SetFilter("Equipment No.", EquipmentFilterTok);
        Assert.IsFalse(WarrantyAlert.IsEmpty(), 'Demo equipment should have warranty alerts before the delete');

        // [WHEN] Demo data is deleted
        DemoDataMgt.DeleteDemoData(EquipmentDeleted, EmployeesDeleted, EquipmentKept, EmployeesKept);

        // [THEN] Everything is gone and nothing was kept
        Assert.AreEqual(15, EquipmentDeleted, 'Equipment deleted');
        Assert.AreEqual(8, EmployeesDeleted, 'Employees deleted');
        Assert.AreEqual(0, EquipmentKept + EmployeesKept, 'Nothing is kept');
        Equipment.SetFilter("No.", EquipmentFilterTok);
        Assert.IsTrue(Equipment.IsEmpty(), 'Equipment');
        Employee.SetFilter("No.", EmployeeFilterTok);
        Assert.IsTrue(Employee.IsEmpty(), 'Employees');
        MaintenanceRecord.SetFilter("No.", MaintenanceFilterTok);
        Assert.IsTrue(MaintenanceRecord.IsEmpty(), 'Maintenance records');
        MaintenanceHistoryEntry.SetFilter("Equipment No.", EquipmentFilterTok);
        Assert.IsTrue(MaintenanceHistoryEntry.IsEmpty(), 'History');
        MaintenanceLogEntry.SetFilter("Maintenance No.", MaintenanceFilterTok);
        Assert.IsTrue(MaintenanceLogEntry.IsEmpty(), 'Log');
        AuditEntry.SetFilter("Equipment No.", EquipmentFilterTok);
        Assert.IsTrue(AuditEntry.IsEmpty(), 'Audit');
        EquipmentAssignment.SetFilter("Equipment No.", EquipmentFilterTok);
        Assert.IsTrue(EquipmentAssignment.IsEmpty(), 'Assignments');
        Assert.IsTrue(WarrantyAlert.IsEmpty(), 'Warranty alerts');
        IntegrationEventEntry.SetFilter("Equipment No.", EquipmentFilterTok);
        Assert.IsTrue(IntegrationEventEntry.IsEmpty(), 'Integration events');
        Assert.IsTrue(DemoDataEntry.IsEmpty(), 'Tracking rows');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DeleteKeepsRecordsThatUsersCreated()
    var
        UserEmployee: Record Employee;
        UserEquipment: Record "EQM Equipment";
        EquipmentAssignment: Record "EQM Equipment Assignment";
        UserEmployeeNo: Code[20];
        UserEquipmentNo: Code[20];
    begin
        Initialize();
        // [SCENARIO 8] (negative) Delete keeps a user employee and user equipment that are assigned to each other
        // [GIVEN] Demo data, a user employee and user equipment assigned to it
        CreateDemoData();
        InsertEmployee(UserEmployee, '');
        UserEmployeeNo := UserEmployee."No.";
        InsertEquipment(UserEquipment, '');
        UserEquipmentNo := UserEquipment."No.";
        UserEquipment.AssignEmployee(UserEmployeeNo);

        // [WHEN] Demo data is deleted
        DemoDataMgt.DeleteDemoData(EquipmentDeleted, EmployeesDeleted, EquipmentKept, EmployeesKept);

        // [THEN] The user records and their assignment entry remain
        Assert.IsTrue(UserEmployee.Get(UserEmployeeNo), 'The user employee should remain');
        Assert.IsTrue(UserEquipment.Get(UserEquipmentNo), 'The user equipment should remain');
        EquipmentAssignment.SetRange("Equipment No.", UserEquipmentNo);
        Assert.RecordCount(EquipmentAssignment, 1);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NoteKeepsDemoEquipmentAndItsEmployees()
    var
        Equipment: Record "EQM Equipment";
        EquipmentNote: Record "EQM Equipment Note";
        Employee: Record Employee;
        MaintenanceHistoryEntry: Record "EQM Maintenance History Entry";
        DemoDataEntry: Record "EQM Demo Data Entry";
    begin
        Initialize();
        // [SCENARIO 9] (negative) A note that a user added keeps the demo equipment, its history and the employees in its assignments
        // [GIVEN] Demo data and a note on equipment EQMDEMO-003
        CreateDemoData();
        EquipmentNote.Init();
        EquipmentNote."Equipment No." := Equipment003Tok;
        EquipmentNote.Comment := UserNoteTok;
        EquipmentNote.Insert(true);

        // [WHEN] Demo data is deleted
        DemoDataMgt.DeleteDemoData(EquipmentDeleted, EmployeesDeleted, EquipmentKept, EmployeesKept);

        // [THEN] Equipment 003, its history, its tracking row and employees E03 and E06 remain
        Assert.AreEqual(1, EquipmentKept, 'Equipment kept');
        Assert.AreEqual(2, EmployeesKept, 'Employees kept');
        Assert.IsTrue(Equipment.Get(Equipment003Tok), 'Equipment 003 should remain');
        MaintenanceHistoryEntry.SetRange("Equipment No.", Equipment003Tok);
        Assert.IsFalse(MaintenanceHistoryEntry.IsEmpty(), 'The history of equipment 003 should remain');
        Assert.IsTrue(DemoDataEntry.Get(Database::"EQM Equipment", Equipment003Tok), 'The tracking row should remain');
        Assert.IsTrue(Employee.Get(Employee03Tok), 'Employee E03 should remain');
        Assert.IsTrue(Employee.Get(Employee06Tok), 'Employee E06 should remain');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UserMaintenanceKeepsDemoEquipment()
    var
        Equipment: Record "EQM Equipment";
        MaintenanceRecord: Record "EQM Maintenance Record";
    begin
        Initialize();
        // [SCENARIO 10] (negative) A maintenance record that a user added keeps the demo equipment
        // [GIVEN] Demo data and a user maintenance record on equipment EQMDEMO-010
        CreateDemoData();
        MaintenanceRecord.Init();
        MaintenanceRecord."No." := CopyStr(StrSubstNo(UserMaintenanceNoTok, NextId()), 1, MaxStrLen(MaintenanceRecord."No."));
        MaintenanceRecord."Equipment No." := Equipment010Tok;
        MaintenanceRecord."Maintenance Date" := Today();
        MaintenanceRecord.Description := MaintenanceRecord."No.";
        MaintenanceRecord.Insert(true);

        // [WHEN] Demo data is deleted
        DemoDataMgt.DeleteDemoData(EquipmentDeleted, EmployeesDeleted, EquipmentKept, EmployeesKept);

        // [THEN] Equipment 010 is kept
        Assert.AreEqual(1, EquipmentKept, 'Equipment kept');
        Assert.IsTrue(Equipment.Get(Equipment010Tok), 'Equipment 010 should remain');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UserEquipmentAssignedToDemoEmployeeKeepsTheEmployee()
    var
        UserEquipment: Record "EQM Equipment";
        Employee: Record Employee;
    begin
        Initialize();
        // [SCENARIO 11] (negative) A demo employee that user equipment is assigned to is kept
        // [GIVEN] Demo data and user equipment assigned to EQMDEMO-E05
        CreateDemoData();
        InsertEquipment(UserEquipment, '');
        UserEquipment.AssignEmployee(Employee05Tok);

        // [WHEN] Demo data is deleted
        DemoDataMgt.DeleteDemoData(EquipmentDeleted, EmployeesDeleted, EquipmentKept, EmployeesKept);

        // [THEN] Only E05 is kept
        Assert.AreEqual(1, EmployeesKept, 'Employees kept');
        Assert.IsTrue(Employee.Get(Employee05Tok), 'Employee E05 should remain');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DeleteIgnoresDemoRecordsThatAreAlreadyGone()
    var
        Employee: Record Employee;
        EquipmentAssignment: Record "EQM Equipment Assignment";
        DemoDataEntry: Record "EQM Demo Data Entry";
    begin
        Initialize();
        // [SCENARIO 12] Delete runs without an error when tracked records no longer exist
        // [GIVEN] Demo data, where the assignment entry of equipment 010 and employee E08 were deleted without the tracking rows
        CreateDemoData();
        EquipmentAssignment.SetRange("Equipment No.", Equipment010Tok);
        EquipmentAssignment.DeleteAll(false);
        Employee.Get(Employee08Tok);
        Employee.Delete(false);

        // [WHEN] Demo data is deleted
        DemoDataMgt.DeleteDemoData(EquipmentDeleted, EmployeesDeleted, EquipmentKept, EmployeesKept);

        // [THEN] No error is raised and no tracking row is left
        Assert.AreEqual(15, EquipmentDeleted, 'Equipment deleted');
        Assert.AreEqual(7, EmployeesDeleted, 'Employees deleted');
        Assert.IsTrue(DemoDataEntry.IsEmpty(), 'Tracking rows');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EditedDemoRecordIsStillDeleted()
    var
        Equipment: Record "EQM Equipment";
    begin
        Initialize();
        // [SCENARIO 13] A demo record that a user only edited is still deleted
        // [GIVEN] Demo data where the description of equipment EQMDEMO-005 was changed
        CreateDemoData();
        Equipment.Get(Equipment005Tok);
        Equipment.Description := ChangedDescriptionTok;
        Equipment.Modify(false);

        // [WHEN] Demo data is deleted
        DemoDataMgt.DeleteDemoData(EquipmentDeleted, EmployeesDeleted, EquipmentKept, EmployeesKept);

        // [THEN] Equipment 005 is gone
        Assert.IsFalse(Equipment.Get(Equipment005Tok), 'Equipment 005 should be deleted');
        Assert.AreEqual(15, EquipmentDeleted, 'Equipment deleted');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RenamedDemoRecordIsNotCreatedAgainAndIsDeleted()
    var
        Equipment: Record "EQM Equipment";
    begin
        Initialize();
        // [SCENARIO 14] A renamed demo record is recognised by its system ID
        // [GIVEN] Demo data where equipment EQMDEMO-010 was renamed
        CreateDemoData();
        Equipment.Get(Equipment010Tok);
        Equipment.Rename(RenamedEquipmentTok);

        // [WHEN] Demo data is created again
        CreateDemoData();

        // [THEN] EQMDEMO-010 is not created again
        Assert.IsFalse(Equipment.Get(Equipment010Tok), 'Equipment 010 should not be created again');
        Assert.AreEqual(0, EquipmentCreated, 'Equipment created');

        // [WHEN] Demo data is deleted
        DemoDataMgt.DeleteDemoData(EquipmentDeleted, EmployeesDeleted, EquipmentKept, EmployeesKept);

        // [THEN] The renamed equipment is deleted
        Assert.IsFalse(Equipment.Get(RenamedEquipmentTok), 'The renamed equipment should be deleted');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CreateAfterDeleteCreatesTheFullSetAgain()
    begin
        Initialize();
        // [SCENARIO 15] Demo data can be created again after it was deleted
        // [GIVEN] Demo data that was created and deleted
        CreateDemoData();
        DemoDataMgt.DeleteDemoData(EquipmentDeleted, EmployeesDeleted, EquipmentKept, EmployeesKept);

        // [WHEN] Demo data is created
        CreateDemoData();

        // [THEN] The full set is created
        Assert.AreEqual(8, EmployeesCreated, 'Employees created');
        Assert.AreEqual(15, EquipmentCreated, 'Equipment created');
        Assert.AreEqual(13, AssignmentsCreated, 'Assignments created');
        Assert.AreEqual(12, MaintenanceCreated, 'Maintenance records created');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure InactiveCategorySkipsItsEquipment()
    var
        Category: Record "EQM Equipment Category";
        Equipment: Record "EQM Equipment";
    begin
        Initialize();
        // [SCENARIO 16] (negative) Equipment of an inactive category is skipped without an error
        // [GIVEN] The LAPTOP category is inactive
        Category.Get(LaptopCategoryTok);
        Category.Active := false;
        Category.Modify(false);

        // [WHEN] Demo data is created
        CreateDemoData();

        // [THEN] No demo equipment is in LAPTOP, and four items were skipped
        Equipment.SetFilter("No.", EquipmentFilterTok);
        Equipment.SetRange("Category Code", LaptopCategoryTok);
        Assert.IsTrue(Equipment.IsEmpty(), 'No demo laptop should be created');
        Assert.IsTrue(SkippedCount >= 4, 'The four laptops are skipped');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UsedSerialNumberIsLeftBlank()
    var
        UserEquipment: Record "EQM Equipment";
        Equipment: Record "EQM Equipment";
        SerialNoTok: Label 'EQMDEMO-SN-001', Locked = true;
    begin
        Initialize();
        // [SCENARIO 17] (negative) Demo equipment whose serial number is already used gets a blank serial number
        // [GIVEN] User equipment U with serial number EQMDEMO-SN-001
        InsertEquipment(UserEquipment, SerialNoTok);

        // [WHEN] Demo data is created
        CreateDemoData();

        // [THEN] EQMDEMO-001 exists with a blank serial number, and U is unchanged
        Equipment.Get(Equipment001Tok);
        Assert.AreEqual('', Equipment."Serial No.", 'The serial number should be blank');
        UserEquipment.Get(UserEquipment."No.");
        Assert.AreEqual(SerialNoTok, UserEquipment."Serial No.", 'The user equipment should not change');
    end;

    [Test]
    [HandlerFunctions('ConfirmNoHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AnsweringNoOnCreateChangesNothing()
    var
        Equipment: Record "EQM Equipment";
    begin
        Initialize();
        // [SCENARIO 18] (negative) Answering No to the create confirmation creates nothing and shows no notification
        // [GIVEN] No demo data

        // [WHEN] Create is started and the user answers No
        DemoDataMgt.CreateDemoDataWithConfirmation();

        // [THEN] No demo equipment exists
        Equipment.SetFilter("No.", EquipmentFilterTok);
        Assert.IsTrue(Equipment.IsEmpty(), 'Nothing should be created');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler,SendNotificationHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AnsweringYesOnCreateShowsTheCounts()
    begin
        Initialize();
        // [SCENARIO 19] The notification after Create names the counts
        // [GIVEN] No demo data

        // [WHEN] Create is started and the user answers Yes
        DemoDataMgt.CreateDemoDataWithConfirmation();

        // [THEN] One notification shows 8, 15, 13, 12 and 0
        Assert.AreEqual(1, NotificationCount, 'One notification');
        Assert.AreEqual(StrSubstNo(DemoDataCreatedMsg, 8, 15, 13, 12, 0), LastNotificationText, 'Notification text');
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DeleteWithNothingToDeleteSaysSoWithoutConfirm()
    begin
        Initialize();
        // [SCENARIO 20] (negative) Delete with no demo data shows a notification and asks nothing
        // [GIVEN] No demo data

        // [WHEN] Delete is started
        DemoDataMgt.DeleteDemoDataWithConfirmation();

        // [THEN] The no-demo-data notification is shown, and no confirmation was asked (an unhandled confirm would fail the test)
        Assert.AreEqual(NoDemoDataMsg, LastNotificationText, 'Notification text');
    end;

    [Test]
    [HandlerFunctions('ConfirmNoHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AnsweringNoOnDeleteKeepsEverything()
    var
        Equipment: Record "EQM Equipment";
    begin
        Initialize();
        // [SCENARIO 21] (negative) Answering No to the delete confirmation deletes nothing
        // [GIVEN] Demo data
        CreateDemoData();

        // [WHEN] Delete is started and the user answers No
        DemoDataMgt.DeleteDemoDataWithConfirmation();

        // [THEN] All 15 demo equipment records remain
        Equipment.SetFilter("No.", EquipmentFilterTok);
        Assert.RecordCount(Equipment, 15);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler,SendNotificationHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CreateDemoDataActionOnSetupPageCreatesTheData()
    var
        Equipment: Record "EQM Equipment";
        EquipmentSetupPage: TestPage "EQM Equipment Setup";
    begin
        Initialize();
        // [SCENARIO 22] The Create Demo Data action on the setup page creates the demo data
        // [GIVEN] The equipment setup page is open
        EquipmentSetupPage.OpenEdit();

        // [WHEN] The user chooses Create Demo Data and confirms
        EquipmentSetupPage.CreateDemoData.Invoke();

        // [THEN] Demo equipment exists
        Assert.IsTrue(Equipment.Get(Equipment001Tok), 'Equipment 001 should exist');
        EquipmentSetupPage.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DemoEquipmentAssignedToUserEmployeeIsKept()
    var
        UserEmployee: Record Employee;
        Equipment: Record "EQM Equipment";
        EquipmentAssignment: Record "EQM Equipment Assignment";
    begin
        Initialize();
        // [SCENARIO 23] (negative) Demo equipment that is assigned to a user employee is kept, with the assignment
        // [GIVEN] Demo data and equipment EQMDEMO-003 assigned to a user employee
        CreateDemoData();
        InsertEmployee(UserEmployee, '');
        Equipment.Get(Equipment003Tok);
        Equipment.AssignEmployee(UserEmployee."No.");

        // [WHEN] Demo data is deleted
        DemoDataMgt.DeleteDemoData(EquipmentDeleted, EmployeesDeleted, EquipmentKept, EmployeesKept);

        // [THEN] Equipment 003 is kept and the assignment entry of the user employee remains
        Assert.AreEqual(1, EquipmentKept, 'Equipment kept');
        Assert.IsTrue(Equipment.Get(Equipment003Tok), 'Equipment 003 should remain');
        EquipmentAssignment.SetRange("Employee No.", UserEmployee."No.");
        Assert.RecordCount(EquipmentAssignment, 1);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RequestForDemoEquipmentKeepsIt()
    var
        Equipment: Record "EQM Equipment";
        EquipmentRequest: Record "EQM Equipment Request";
    begin
        Initialize();
        // [SCENARIO 24] (negative) An equipment request that points to demo equipment keeps it
        // [GIVEN] Demo data and a request whose assigned equipment is EQMDEMO-010
        CreateDemoData();
        InsertRequest(EquipmentRequest);
        EquipmentRequest."Assigned Equipment No." := Equipment010Tok;
        EquipmentRequest.Modify(false);

        // [WHEN] Demo data is deleted
        DemoDataMgt.DeleteDemoData(EquipmentDeleted, EmployeesDeleted, EquipmentKept, EmployeesKept);

        // [THEN] Equipment 010 is kept
        Assert.AreEqual(1, EquipmentKept, 'Equipment kept');
        Assert.IsTrue(Equipment.Get(Equipment010Tok), 'Equipment 010 should remain');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AttachmentOnDemoEquipmentKeepsIt()
    var
        Equipment: Record "EQM Equipment";
        DocumentAttachment: Record "Document Attachment";
    begin
        Initialize();
        // [SCENARIO 25] (negative) A document attachment on demo equipment keeps it
        // [GIVEN] Demo data and an attachment on EQMDEMO-005
        CreateDemoData();
        DocumentAttachment.Init();
        DocumentAttachment."Table ID" := Database::"EQM Equipment";
        DocumentAttachment."No." := Equipment005AttachmentTok;
        DocumentAttachment.Insert(false);

        // [WHEN] Demo data is deleted
        DemoDataMgt.DeleteDemoData(EquipmentDeleted, EmployeesDeleted, EquipmentKept, EmployeesKept);

        // [THEN] Equipment 005 is kept
        Assert.AreEqual(1, EquipmentKept, 'Equipment kept');
        Assert.IsTrue(Equipment.Get(Equipment005Tok), 'Equipment 005 should remain');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RequestOrAttachmentKeepsDemoEmployee()
    var
        Employee: Record Employee;
        EquipmentRequest: Record "EQM Equipment Request";
        DocumentAttachment: Record "Document Attachment";
    begin
        Initialize();
        // [SCENARIO 26] (negative) A request of a demo employee, or an attachment on one, keeps the employee
        // [GIVEN] Demo data, a request of EQMDEMO-E02 and an attachment on EQMDEMO-E04
        CreateDemoData();
        InsertRequest(EquipmentRequest);
        EquipmentRequest."Employee No." := Employee02Tok;
        EquipmentRequest.Modify(false);
        DocumentAttachment.Init();
        DocumentAttachment."Table ID" := Database::Employee;
        DocumentAttachment."No." := Employee04Tok;
        DocumentAttachment.Insert(false);

        // [WHEN] Demo data is deleted
        DemoDataMgt.DeleteDemoData(EquipmentDeleted, EmployeesDeleted, EquipmentKept, EmployeesKept);

        // [THEN] Both employees are kept and no other employee is
        Assert.AreEqual(2, EmployeesKept, 'Employees kept');
        Assert.IsTrue(Employee.Get(Employee02Tok), 'Employee E02 should remain');
        Assert.IsTrue(Employee.Get(Employee04Tok), 'Employee E04 should remain');
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

    [SendNotificationHandler(true)]
    procedure SendNotificationHandler(var TheNotification: Notification): Boolean
    begin
        NotificationCount += 1;
        LastNotificationText := TheNotification.Message();
        exit(true);
    end;

    local procedure Initialize()
    var
        DefaultData: Codeunit "EQM Default Data";
    begin
        DefaultData.CreateDefaultData();
        NotificationCount := 0;
        LastNotificationText := '';
    end;

    local procedure CreateDemoData()
    begin
        DemoDataMgt.CreateDemoData(EmployeesCreated, EquipmentCreated, AssignmentsCreated, MaintenanceCreated, SkippedCount);
    end;

    local procedure NextId(): Text
    begin
        Counter += 1;
        exit(Format(Counter, 0, CounterFormatTok));
    end;

    local procedure EnableIntegrationEvents()
    var
        EquipmentSetup: Record "EQM Equipment Setup";
    begin
        EquipmentSetup.Get();
        EquipmentSetup."Integration Events Enabled" := true;
        EquipmentSetup.Modify(false);
    end;

    local procedure InsertEmployee(var Employee: Record Employee; EmployeeNo: Code[20])
    begin
        Employee.Init();
        if EmployeeNo = '' then
            Employee."No." := CopyStr(StrSubstNo(UserEmployeeNoTok, NextId()), 1, MaxStrLen(Employee."No."))
        else
            Employee."No." := EmployeeNo;
        Employee."First Name" := UserFirstNameTok;
        Employee."Last Name" := Employee."No.";
        Employee.Status := Employee.Status::Active;
        Employee.Insert(false);
    end;

    local procedure InsertEquipment(var Equipment: Record "EQM Equipment"; SerialNo: Code[50])
    begin
        Equipment.Init();
        Equipment."No." := CopyStr(StrSubstNo(UserEquipmentNoTok, NextId()), 1, MaxStrLen(Equipment."No."));
        Equipment.Description := Equipment."No.";
        Equipment."Category Code" := LaptopCategoryTok;
        Equipment."Serial No." := SerialNo;
        Equipment.Insert(true);
    end;

    local procedure InsertRequest(var EquipmentRequest: Record "EQM Equipment Request")
    begin
        EquipmentRequest.Init();
        EquipmentRequest."No." := CopyStr(StrSubstNo(UserRequestNoTok, NextId()), 1, MaxStrLen(EquipmentRequest."No."));
        EquipmentRequest.Insert(false);
    end;

    local procedure AssertStatusCount(EquipmentStatus: Enum "EQM Equipment Status"; ExpectedCount: Integer)
    var
        Equipment: Record "EQM Equipment";
    begin
        Equipment.SetFilter("No.", EquipmentFilterTok);
        Equipment.SetRange(Status, EquipmentStatus);
        Assert.RecordCount(Equipment, ExpectedCount);
    end;

    local procedure CountSnapshot(): Text
    var
        Equipment: Record "EQM Equipment";
        EquipmentAssignment: Record "EQM Equipment Assignment";
        MaintenanceRecord: Record "EQM Maintenance Record";
        MaintenanceHistoryEntry: Record "EQM Maintenance History Entry";
        MaintenanceLogEntry: Record "EQM Maintenance Log Entry";
        AuditEntry: Record "EQM Equipment Audit Entry";
        Employee: Record Employee;
        DemoDataEntry: Record "EQM Demo Data Entry";
        WarrantyAlert: Record "EQM Warranty Alert";
        IntegrationEventEntry: Record "EQM Integration Event Entry";
    begin
        exit(StrSubstNo(SnapshotFormatTok,
            Equipment.Count(), EquipmentAssignment.Count(), MaintenanceRecord.Count(), MaintenanceHistoryEntry.Count(),
            MaintenanceLogEntry.Count(), AuditEntry.Count(), Employee.Count(), DemoDataEntry.Count(),
            WarrantyAlert.Count(), IntegrationEventEntry.Count()));
    end;
}
