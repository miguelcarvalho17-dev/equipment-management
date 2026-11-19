namespace MiguelCarvalho.EquipmentManagement.Tests;

using Microsoft.HumanResources.Employee;
using MiguelCarvalho.EquipmentManagement;
using System.TestLibraries.Utilities;

/// <summary>
/// FR-045 Automated Unit Tests, area Status Changes. Covers the status rules of table 50100 that the existing tests do
/// not reach: final status Lost, open maintenance and the status In Maintenance, manual In Maintenance on assigned
/// equipment (with and without the confirmation), disposal with open maintenance and posting on disposed equipment.
/// A failed statement (asserterror) rolls back the whole test transaction, so each test that expects an error has
/// exactly one asserterror, as its last action, and only checks the error text afterwards.
/// </summary>
codeunit 50157 "EQM Status Change Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        Counter: Integer;
        EquipmentNoTok: Label 'EQMSTS%1X', Locked = true;
        CategoryCodeTok: Label 'EQMSTSC%1', Locked = true;
        EmployeeNoTok: Label 'EQMSTSE%1', Locked = true;
        MaintenanceNoTok: Label 'EQMSTSM%1', Locked = true;
        CounterFormatTok: Label '<Integer,4><Filler Character,0>', Locked = true;
        // Copies of the text of the labels in table 50100; labels of another app are not accessible.
        MaintenanceOpenStatusErr: Label 'You cannot change the status of equipment %1 to %2 because it has open maintenance. The status changes to %3 automatically when the last open maintenance record is posted.', Comment = '%1 = equipment number, %2 = new status caption, %3 = Available status caption';
        StatusIsFinalErr: Label 'You cannot change the status of equipment %1 to %3 because %2 is a final status.', Comment = '%1 = equipment number, %2 = current status caption, %3 = new status caption';

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OpenMaintenanceBlocksLeavingInMaintenance()
    var
        Equipment: Record "EQM Equipment";
        MaintenanceRecord: Record "EQM Maintenance Record";
    begin
        // [SCENARIO S1] (negative) Equipment with an open maintenance record cannot be set to Available by hand
        // [GIVEN] Equipment E with an open maintenance record, so its status is In Maintenance
        CreateEquipment(Equipment);
        CreateOpenMaintenance(MaintenanceRecord, Equipment."No.");
        Equipment.Get(Equipment."No.");

        // [WHEN] The status of E is set to Available
        asserterror Equipment.Validate(Status, Equipment.Status::Available);

        // [THEN] The open maintenance error is raised
        Assert.ExpectedError(StrSubstNo(MaintenanceOpenStatusErr, Equipment."No.", Format(Equipment.Status::Available), Format(Equipment.Status::Available)));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure InMaintenanceWithoutOpenRecordsCanBecomeAvailable()
    var
        Equipment: Record "EQM Equipment";
    begin
        // [SCENARIO S2] Equipment set to In Maintenance by hand, without open maintenance records, can be set back to Available
        // [GIVEN] Available equipment E that is set to In Maintenance by hand
        CreateEquipment(Equipment);
        Equipment.Get(Equipment."No.");
        Equipment.Validate(Status, Equipment.Status::"In Maintenance");
        Equipment.Modify(true);
        Equipment.Get(Equipment."No.");

        // [WHEN] The status of E is set to Available
        Equipment.Validate(Status, Equipment.Status::Available);
        Equipment.Modify(true);

        // [THEN] E is Available
        Equipment.Get(Equipment."No.");
        Assert.AreEqual(Equipment.Status::Available, Equipment.Status, 'Status should be Available');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ManualInMaintenanceOnAssignedEquipmentReturnsIt()
    var
        Equipment: Record "EQM Equipment";
        Employee: Record Employee;
        EquipmentAssignment: Record "EQM Equipment Assignment";
    begin
        // [SCENARIO S3] Setting assigned equipment to In Maintenance removes the employee and closes the assignment (confirm Yes)
        // [GIVEN] Equipment E assigned to an employee
        CreateAssignedEquipment(Equipment, Employee);

        // [WHEN] The status of E is set to In Maintenance and the confirmation is answered Yes
        Equipment.Validate(Status, Equipment.Status::"In Maintenance");
        Equipment.Modify(true);

        // [THEN] E is In Maintenance without an employee
        Equipment.Get(Equipment."No.");
        Assert.AreEqual(Equipment.Status::"In Maintenance", Equipment.Status, 'Status should be In Maintenance');
        Assert.AreEqual('', Equipment."Assigned Employee No.", 'The employee should be removed');

        // [THEN] The assignment is closed and no assignment is active
        EquipmentAssignment.SetRange("Equipment No.", Equipment."No.");
        EquipmentAssignment.SetRange(Status, EquipmentAssignment.Status::Active);
        Assert.RecordIsEmpty(EquipmentAssignment);
        EquipmentAssignment.SetRange(Status, EquipmentAssignment.Status::Closed);
        Assert.RecordCount(EquipmentAssignment, 1);
    end;

    [Test]
    [HandlerFunctions('ConfirmNoHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DecliningTheConfirmationStopsTheStatusChange()
    var
        Equipment: Record "EQM Equipment";
        Employee: Record Employee;
    begin
        // [SCENARIO S4] (negative) When the confirmation is answered No, the change of an assigned equipment to In Maintenance is stopped
        // [GIVEN] Equipment E assigned to an employee
        CreateAssignedEquipment(Equipment, Employee);

        // [WHEN] The status of E is set to In Maintenance and the confirmation is answered No
        asserterror Equipment.Validate(Status, Equipment.Status::"In Maintenance");

        // [THEN] The validation stopped with an empty error
        Assert.AreEqual('', GetLastErrorText(), 'Declining the confirmation should raise an empty error');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LostIsAFinalStatus()
    var
        Equipment: Record "EQM Equipment";
    begin
        // [SCENARIO S5] (negative) The status of lost equipment cannot be changed again
        // [GIVEN] Equipment E that was set to Lost (confirm Yes)
        CreateEquipment(Equipment);
        Equipment.Get(Equipment."No.");
        Equipment.Validate(Status, Equipment.Status::Lost);
        Equipment.Modify(true);
        Equipment.Get(Equipment."No.");

        // [WHEN] The status of E is set to Available
        asserterror Equipment.Validate(Status, Equipment.Status::Available);

        // [THEN] The final status error names E, Lost and Available
        Assert.ExpectedError(StrSubstNo(StatusIsFinalErr, Equipment."No.", Format(Equipment.Status::Lost), Format(Equipment.Status::Available)));
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OpenMaintenanceDoesNotBlockDisposal()
    var
        Equipment: Record "EQM Equipment";
        MaintenanceRecord: Record "EQM Maintenance Record";
    begin
        // [SCENARIO S6] Equipment with an open maintenance record can be disposed of (confirm Yes)
        // [GIVEN] Equipment E with an open maintenance record
        CreateEquipment(Equipment);
        CreateOpenMaintenance(MaintenanceRecord, Equipment."No.");
        Equipment.Get(Equipment."No.");

        // [WHEN] The status of E is set to Disposed
        Equipment.Validate(Status, Equipment.Status::Disposed);
        Equipment.Modify(true);

        // [THEN] E is Disposed
        Equipment.Get(Equipment."No.");
        Assert.AreEqual(Equipment.Status::Disposed, Equipment.Status, 'Status should be Disposed');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PostingTheLastOpenRecordOfDisposedEquipmentKeepsItDisposed()
    var
        Equipment: Record "EQM Equipment";
        MaintenanceRecord: Record "EQM Maintenance Record";
    begin
        // [SCENARIO S7] (negative) Posting the last open maintenance record of disposed equipment does not make it Available
        // [GIVEN] Equipment E with an open maintenance record, disposed of (confirm Yes)
        CreateEquipment(Equipment);
        CreateOpenMaintenance(MaintenanceRecord, Equipment."No.");
        Equipment.Get(Equipment."No.");
        Equipment.Validate(Status, Equipment.Status::Disposed);
        Equipment.Modify(true);

        // [WHEN] The maintenance record is posted
        MaintenanceRecord.Get(MaintenanceRecord."No.");
        Codeunit.Run(Codeunit::"EQM Maintenance-Post", MaintenanceRecord);

        // [THEN] The record is Posted and E is still Disposed
        MaintenanceRecord.Get(MaintenanceRecord."No.");
        Assert.AreEqual(MaintenanceRecord.Status::Posted, MaintenanceRecord.Status, 'The record should be posted');
        Equipment.Get(Equipment."No.");
        Assert.AreEqual(Equipment.Status::Disposed, Equipment.Status, 'Status should stay Disposed');
    end;

    local procedure NextId(): Text
    begin
        Counter += 1;
        exit(Format(Counter, 0, CounterFormatTok));
    end;

    local procedure CreateEquipment(var Equipment: Record "EQM Equipment")
    var
        Category: Record "EQM Equipment Category";
    begin
        Category.Init();
        Category.Code := CopyStr(StrSubstNo(CategoryCodeTok, NextId()), 1, MaxStrLen(Category.Code));
        Category.Description := Category.Code;
        Category.Active := true;
        Category.Insert(false);

        Equipment.Init();
        Equipment."No." := CopyStr(StrSubstNo(EquipmentNoTok, NextId()), 1, MaxStrLen(Equipment."No."));
        Equipment.Description := Equipment."No.";
        Equipment."Category Code" := Category.Code;
        Equipment.Insert(true);
    end;

    local procedure CreateAssignedEquipment(var Equipment: Record "EQM Equipment"; var Employee: Record Employee)
    begin
        Employee.Init();
        Employee."No." := CopyStr(StrSubstNo(EmployeeNoTok, NextId()), 1, MaxStrLen(Employee."No."));
        Employee."First Name" := 'EQMSTS';
        Employee."Last Name" := Employee."No.";
        Employee.Status := Employee.Status::Active;
        Employee.Insert(false);

        CreateEquipment(Equipment);
        Equipment.Get(Equipment."No.");
        Equipment.AssignEmployee(Employee."No.");
        Equipment.Get(Equipment."No.");
    end;

    local procedure CreateOpenMaintenance(var MaintenanceRecord: Record "EQM Maintenance Record"; EquipmentNo: Code[20])
    begin
        MaintenanceRecord.Init();
        MaintenanceRecord."No." := CopyStr(StrSubstNo(MaintenanceNoTok, NextId()), 1, MaxStrLen(MaintenanceRecord."No."));
        MaintenanceRecord."Equipment No." := EquipmentNo;
        MaintenanceRecord."Maintenance Date" := Today();
        MaintenanceRecord.Description := MaintenanceRecord."No.";
        MaintenanceRecord.Insert(true);
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
