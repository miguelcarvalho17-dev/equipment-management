namespace MiguelCarvalho.EquipmentManagement.Tests;

using Microsoft.HumanResources.Employee;
using MiguelCarvalho.EquipmentManagement;
using System.TestLibraries.Utilities;

/// <summary>
/// FR-045 Automated Unit Tests, area Maintenance Processing. Covers the registration rules of table 50105 and the
/// posting codeunit 50109 "EQM Maintenance-Post": equipment status, history entry, planned maintenance dates and the
/// read-only rules. The tests post with Codeunit.Run on codeunit 50109, never with the confirmation of PostWithConfirmation.
/// A failed statement (asserterror) rolls back the whole test transaction, so each test that expects an error has
/// exactly one asserterror, as its last action, and only checks the error text afterwards.
/// </summary>
codeunit 50164 "EQM Maintenance Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        Counter: Integer;
        EquipmentNoTok: Label 'EQMMNT%1X', Locked = true;
        CategoryCodeTok: Label 'EQMMNTC%1', Locked = true;
        EmployeeNoTok: Label 'EQMMNTE%1', Locked = true;
        MaintenanceNoTok: Label 'EQMMNTM%1', Locked = true;
        CounterFormatTok: Label '<Integer,4><Filler Character,0>', Locked = true;
        MonthsDateFormulaTok: Label '<%1M>', Locked = true;
        FutureDateFragmentTxt: Label 'is in the future', Locked = true;
        // Copies of the text of the labels in tables 50100 and 50105 and codeunit 50109; labels of another app are not accessible.
        EquipmentNotFoundErr: Label 'Equipment %1 does not exist. Register the equipment before you register maintenance for it.', Comment = '%1 = equipment number';
        EquipmentFinalStatusErr: Label 'You cannot register maintenance for equipment %1 because its status is %2.', Comment = '%1 = equipment number, %2 = status caption (Lost or Disposed)';
        EquipmentCannotChangeErr: Label 'You cannot change the equipment of maintenance record %1. The record belongs to equipment %2.', Comment = '%1 = maintenance record number, %2 = equipment number';
        NegativeCostErr: Label 'The cost of maintenance record %1 must be zero or greater.', Comment = '%1 = maintenance record number';
        MaintenanceCannotBeDeletedErr: Label 'You cannot delete maintenance record %1. Maintenance records are kept as the maintenance history of the equipment.', Comment = '%1 = maintenance record number';
        PostedRecordCannotBeChangedErr: Label 'You cannot change maintenance record %1 because it is posted. Posted maintenance is part of the maintenance history and is read-only.', Comment = '%1 = maintenance record number';
        AlreadyPostedErr: Label 'Maintenance record %1 is already posted.', Comment = '%1 = maintenance record number';
        DeleteMaintenanceExistsErr: Label 'You cannot delete equipment %1 because it has maintenance records. To stop using the equipment, set its status to %2 instead.', Comment = '%1 = equipment number, %2 = Disposed status caption';

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RegisteringMaintenanceSetsEquipmentInMaintenance()
    var
        Equipment: Record "EQM Equipment";
        MaintenanceRecord: Record "EQM Maintenance Record";
    begin
        // [SCENARIO M1] Registering maintenance sets the equipment In Maintenance and the record Open
        // [GIVEN] Available equipment E
        CreateEquipment(Equipment);

        // [WHEN] A maintenance record for E is registered
        InitMaintenance(MaintenanceRecord, Equipment."No.");
        MaintenanceRecord.Insert(true);

        // [THEN] The record is Open and E is In Maintenance
        MaintenanceRecord.Get(MaintenanceRecord."No.");
        Assert.AreEqual(MaintenanceRecord.Status::Open, MaintenanceRecord.Status, 'The record should be open');
        Equipment.Get(Equipment."No.");
        Assert.AreEqual(Equipment.Status::"In Maintenance", Equipment.Status, 'Status should be In Maintenance');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LostEquipmentCannotGetMaintenance()
    var
        Equipment: Record "EQM Equipment";
        MaintenanceRecord: Record "EQM Maintenance Record";
    begin
        // [SCENARIO M2] (negative) Maintenance cannot be registered for lost equipment
        // [GIVEN] Equipment E with the status Lost
        CreateEquipment(Equipment);
        Equipment.Status := Equipment.Status::Lost;
        Equipment.Modify(false);
        InitMaintenance(MaintenanceRecord, Equipment."No.");

        // [WHEN] A maintenance record for E is registered
        asserterror MaintenanceRecord.Insert(true);

        // [THEN] The final status error names E and Lost
        Assert.ExpectedError(StrSubstNo(EquipmentFinalStatusErr, Equipment."No.", Format(Equipment.Status::Lost)));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UnknownEquipmentCannotGetMaintenance()
    var
        MaintenanceRecord: Record "EQM Maintenance Record";
        UnknownEquipmentNo: Code[20];
    begin
        // [SCENARIO M3] (negative) Maintenance cannot be registered for equipment that does not exist
        // [GIVEN] A maintenance record for an equipment number that is not in the database
        UnknownEquipmentNo := CopyStr(StrSubstNo(EquipmentNoTok, NextId()), 1, MaxStrLen(UnknownEquipmentNo));
        InitMaintenance(MaintenanceRecord, UnknownEquipmentNo);

        // [WHEN] The record is registered
        asserterror MaintenanceRecord.Insert(true);

        // [THEN] The error names the equipment number
        Assert.ExpectedError(StrSubstNo(EquipmentNotFoundErr, UnknownEquipmentNo));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FutureMaintenanceDateIsRejected()
    var
        Equipment: Record "EQM Equipment";
        MaintenanceRecord: Record "EQM Maintenance Record";
    begin
        // [SCENARIO M4] (negative) A maintenance date after today is rejected
        // [GIVEN] Equipment E and a maintenance record whose date is after today
        CreateEquipment(Equipment);
        InitMaintenance(MaintenanceRecord, Equipment."No.");
        MaintenanceRecord."Maintenance Date" := Today() + 1 + Random(365);

        // [WHEN] The record is registered
        asserterror MaintenanceRecord.Insert(true);

        // [THEN] The future date error is raised
        Assert.ExpectedError(FutureDateFragmentTxt);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NegativeCostIsRejected()
    var
        Equipment: Record "EQM Equipment";
        MaintenanceRecord: Record "EQM Maintenance Record";
    begin
        // [SCENARIO M5] (negative) A negative cost is rejected
        // [GIVEN] Equipment E and a maintenance record with a negative cost, set directly (no field validation)
        CreateEquipment(Equipment);
        InitMaintenance(MaintenanceRecord, Equipment."No.");
        MaintenanceRecord.Cost := -(1 + Random(1000));

        // [WHEN] The record is registered
        asserterror MaintenanceRecord.Insert(true);

        // [THEN] The negative cost error names the record
        Assert.ExpectedError(StrSubstNo(NegativeCostErr, MaintenanceRecord."No."));
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RegisteringMaintenanceOnAssignedEquipmentReturnsIt()
    var
        Equipment: Record "EQM Equipment";
        Employee: Record Employee;
        MaintenanceRecord: Record "EQM Maintenance Record";
        EquipmentAssignment: Record "EQM Equipment Assignment";
    begin
        // [SCENARIO M6] Registering maintenance on assigned equipment returns it from the employee (confirm Yes)
        // [GIVEN] Equipment E assigned to an employee
        CreateAssignedEquipment(Equipment, Employee);

        // [WHEN] A maintenance record for E is registered and the confirmation is answered Yes
        InitMaintenance(MaintenanceRecord, Equipment."No.");
        MaintenanceRecord.Insert(true);

        // [THEN] E is In Maintenance without an employee, and its assignment is closed
        Equipment.Get(Equipment."No.");
        Assert.AreEqual(Equipment.Status::"In Maintenance", Equipment.Status, 'Status should be In Maintenance');
        Assert.AreEqual('', Equipment."Assigned Employee No.", 'The employee should be removed');
        EquipmentAssignment.SetRange("Equipment No.", Equipment."No.");
        EquipmentAssignment.SetRange(Status, EquipmentAssignment.Status::Active);
        Assert.RecordIsEmpty(EquipmentAssignment);
    end;

    [Test]
    [HandlerFunctions('ConfirmNoHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DecliningTheConfirmationRegistersNoMaintenance()
    var
        Equipment: Record "EQM Equipment";
        Employee: Record Employee;
        MaintenanceRecord: Record "EQM Maintenance Record";
    begin
        // [SCENARIO M7] (negative) When the confirmation is answered No, no maintenance is registered for assigned equipment
        // [GIVEN] Equipment E assigned to an employee
        CreateAssignedEquipment(Equipment, Employee);

        // [WHEN] A maintenance record for E is registered and the confirmation is answered No
        InitMaintenance(MaintenanceRecord, Equipment."No.");
        asserterror MaintenanceRecord.Insert(true);

        // [THEN] The registration stopped with an empty error
        Assert.AreEqual('', GetLastErrorText(), 'Declining the confirmation should raise an empty error');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PostingWritesTheHistoryEntryAndMakesEquipmentAvailable()
    var
        Equipment: Record "EQM Equipment";
        MaintenanceRecord: Record "EQM Maintenance Record";
        HistoryEntry: Record "EQM Maintenance History Entry";
        ExpectedCost: Decimal;
    begin
        // [SCENARIO M8] Posting the only open record writes the history entry and makes the equipment Available
        // [GIVEN] Equipment E with an open inspection record that has a cost
        CreateEquipment(Equipment);
        ExpectedCost := 1 + Random(1000);
        InitMaintenance(MaintenanceRecord, Equipment."No.");
        MaintenanceRecord."Maintenance Type" := MaintenanceRecord."Maintenance Type"::Inspection;
        MaintenanceRecord.Cost := ExpectedCost;
        MaintenanceRecord.Insert(true);
        MaintenanceRecord.Get(MaintenanceRecord."No.");

        // [WHEN] The record is posted
        Codeunit.Run(Codeunit::"EQM Maintenance-Post", MaintenanceRecord);

        // [THEN] The record is Posted
        MaintenanceRecord.Get(MaintenanceRecord."No.");
        Assert.AreEqual(MaintenanceRecord.Status::Posted, MaintenanceRecord.Status, 'The record should be posted');

        // [THEN] One history entry has the equipment, cost, type and the current user
        HistoryEntry.SetRange("Maintenance No.", MaintenanceRecord."No.");
        Assert.RecordCount(HistoryEntry, 1);
        HistoryEntry.FindFirst();
        Assert.AreEqual(Equipment."No.", HistoryEntry."Equipment No.", 'History equipment');
        Assert.AreEqual(ExpectedCost, HistoryEntry.Cost, 'History cost');
        Assert.AreEqual(HistoryEntry."Maintenance Type"::Inspection, HistoryEntry."Maintenance Type", 'History type');
        Assert.AreEqual(CopyStr(UserId(), 1, MaxStrLen(HistoryEntry."Posted By")), HistoryEntry."Posted By", 'Posted by should be the current user');

        // [THEN] E is Available
        Equipment.Get(Equipment."No.");
        Assert.AreEqual(Equipment.Status::Available, Equipment.Status, 'Status should be Available');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PostingOneOfTwoOpenRecordsKeepsEquipmentInMaintenance()
    var
        Equipment: Record "EQM Equipment";
        FirstRecord: Record "EQM Maintenance Record";
        SecondRecord: Record "EQM Maintenance Record";
    begin
        // [SCENARIO M9] (negative) Posting one of two open records does not make the equipment Available
        // [GIVEN] Equipment E with two open maintenance records
        CreateEquipment(Equipment);
        InitMaintenance(FirstRecord, Equipment."No.");
        FirstRecord.Insert(true);
        InitMaintenance(SecondRecord, Equipment."No.");
        SecondRecord.Insert(true);
        FirstRecord.Get(FirstRecord."No.");

        // [WHEN] The first record is posted
        Codeunit.Run(Codeunit::"EQM Maintenance-Post", FirstRecord);

        // [THEN] E is still In Maintenance and the second record is still Open
        Equipment.Get(Equipment."No.");
        Assert.AreEqual(Equipment.Status::"In Maintenance", Equipment.Status, 'Status should stay In Maintenance');
        SecondRecord.Get(SecondRecord."No.");
        Assert.AreEqual(SecondRecord.Status::Open, SecondRecord.Status, 'The second record should stay open');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PostedRecordCannotBePostedAgain()
    var
        Equipment: Record "EQM Equipment";
        MaintenanceRecord: Record "EQM Maintenance Record";
    begin
        // [SCENARIO M10] (negative) A posted maintenance record cannot be posted again
        // [GIVEN] A posted maintenance record M for equipment E
        CreateEquipment(Equipment);
        InitMaintenance(MaintenanceRecord, Equipment."No.");
        MaintenanceRecord.Insert(true);
        MaintenanceRecord.Get(MaintenanceRecord."No.");
        Codeunit.Run(Codeunit::"EQM Maintenance-Post", MaintenanceRecord);
        MaintenanceRecord.Get(MaintenanceRecord."No.");

        // [WHEN] M is posted again
        asserterror Codeunit.Run(Codeunit::"EQM Maintenance-Post", MaintenanceRecord);

        // [THEN] The already posted error names M
        Assert.ExpectedError(StrSubstNo(AlreadyPostedErr, MaintenanceRecord."No."));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PostedRecordIsReadOnly()
    var
        Equipment: Record "EQM Equipment";
        MaintenanceRecord: Record "EQM Maintenance Record";
    begin
        // [SCENARIO M11] (negative) A posted maintenance record cannot be changed
        // [GIVEN] A posted maintenance record M for equipment E
        CreateEquipment(Equipment);
        InitMaintenance(MaintenanceRecord, Equipment."No.");
        MaintenanceRecord.Insert(true);
        MaintenanceRecord.Get(MaintenanceRecord."No.");
        Codeunit.Run(Codeunit::"EQM Maintenance-Post", MaintenanceRecord);
        MaintenanceRecord.Get(MaintenanceRecord."No.");

        // [WHEN] The description of M is changed and M is modified
        MaintenanceRecord.Description := CopyStr(StrSubstNo(MaintenanceNoTok, NextId()), 1, MaxStrLen(MaintenanceRecord.Description));
        asserterror MaintenanceRecord.Modify(true);

        // [THEN] The read-only error names M
        Assert.ExpectedError(StrSubstNo(PostedRecordCannotBeChangedErr, MaintenanceRecord."No."));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MaintenanceRecordCannotBeDeleted()
    var
        Equipment: Record "EQM Equipment";
        MaintenanceRecord: Record "EQM Maintenance Record";
    begin
        // [SCENARIO M12] (negative) A maintenance record cannot be deleted
        // [GIVEN] An open maintenance record M for equipment E
        CreateEquipment(Equipment);
        InitMaintenance(MaintenanceRecord, Equipment."No.");
        MaintenanceRecord.Insert(true);
        MaintenanceRecord.Get(MaintenanceRecord."No.");

        // [WHEN] M is deleted
        asserterror MaintenanceRecord.Delete(true);

        // [THEN] The cannot delete error names M
        Assert.ExpectedError(StrSubstNo(MaintenanceCannotBeDeletedErr, MaintenanceRecord."No."));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EquipmentOfASavedRecordCannotChange()
    var
        Equipment: Record "EQM Equipment";
        OtherEquipment: Record "EQM Equipment";
        MaintenanceRecord: Record "EQM Maintenance Record";
    begin
        // [SCENARIO M13] (negative) The equipment of a saved maintenance record cannot be changed
        // [GIVEN] An open maintenance record M for equipment E, and another equipment E2
        CreateEquipment(Equipment);
        CreateEquipment(OtherEquipment);
        InitMaintenance(MaintenanceRecord, Equipment."No.");
        MaintenanceRecord.Insert(true);
        MaintenanceRecord.Get(MaintenanceRecord."No.");

        // [WHEN] The equipment of M is changed to E2 and M is modified
        MaintenanceRecord."Equipment No." := OtherEquipment."No.";
        asserterror MaintenanceRecord.Modify(true);

        // [THEN] The error names M and E
        Assert.ExpectedError(StrSubstNo(EquipmentCannotChangeErr, MaintenanceRecord."No.", Equipment."No."));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PostingPreventiveMaintenanceMovesTheMaintenanceDates()
    var
        Equipment: Record "EQM Equipment";
        MaintenanceRecord: Record "EQM Maintenance Record";
        Frequency: Integer;
    begin
        // [SCENARIO M14] Posting a preventive record moves the last maintenance date and recalculates the next one
        // [GIVEN] Equipment E with a maintenance frequency and no last maintenance date, and an open preventive record dated today
        Frequency := 1 + Random(12);
        CreateEquipment(Equipment);
        Equipment."Maintenance Frequency (Months)" := Frequency;
        Equipment.Modify(true);
        InitMaintenance(MaintenanceRecord, Equipment."No.");
        MaintenanceRecord."Maintenance Type" := MaintenanceRecord."Maintenance Type"::Preventive;
        MaintenanceRecord.Insert(true);
        MaintenanceRecord.Get(MaintenanceRecord."No.");

        // [WHEN] The record is posted
        Codeunit.Run(Codeunit::"EQM Maintenance-Post", MaintenanceRecord);

        // [THEN] The last maintenance date is the record date, and the next date is that date plus the frequency
        Equipment.Get(Equipment."No.");
        Assert.AreEqual(MaintenanceRecord."Maintenance Date", Equipment."Last Maintenance Date", 'Last maintenance date');
        Assert.AreEqual(CalcDate(StrSubstNo(MonthsDateFormulaTok, Frequency), MaintenanceRecord."Maintenance Date"), Equipment."Next Maintenance Date", 'Next maintenance date');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PostingCorrectiveMaintenanceDoesNotMoveThePlannedDates()
    var
        Equipment: Record "EQM Equipment";
        MaintenanceRecord: Record "EQM Maintenance Record";
        LastDate: Date;
        NextDate: Date;
    begin
        // [SCENARIO M15] (negative) Posting a corrective record does not change the planned maintenance dates
        // [GIVEN] Equipment E with a last and next maintenance date, and an open corrective record dated today
        CreateEquipmentWithPlan(Equipment, Today() - 1 - Random(365));
        LastDate := Equipment."Last Maintenance Date";
        NextDate := Equipment."Next Maintenance Date";
        InitMaintenance(MaintenanceRecord, Equipment."No.");
        MaintenanceRecord."Maintenance Type" := MaintenanceRecord."Maintenance Type"::Corrective;
        MaintenanceRecord.Insert(true);
        MaintenanceRecord.Get(MaintenanceRecord."No.");

        // [WHEN] The record is posted
        Codeunit.Run(Codeunit::"EQM Maintenance-Post", MaintenanceRecord);

        // [THEN] The last and next maintenance dates are unchanged
        Equipment.Get(Equipment."No.");
        Assert.AreEqual(LastDate, Equipment."Last Maintenance Date", 'Last maintenance date should not change');
        Assert.AreEqual(NextDate, Equipment."Next Maintenance Date", 'Next maintenance date should not change');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PostingAnOlderPreventiveRecordDoesNotMoveTheLastDateBack()
    var
        Equipment: Record "EQM Equipment";
        MaintenanceRecord: Record "EQM Maintenance Record";
        NextDate: Date;
    begin
        // [SCENARIO M16] (negative) Posting a preventive record older than the last maintenance date does not move it back
        // [GIVEN] Equipment E with the last maintenance date today, and an open preventive record dated before it
        CreateEquipmentWithPlan(Equipment, Today());
        NextDate := Equipment."Next Maintenance Date";
        InitMaintenance(MaintenanceRecord, Equipment."No.");
        MaintenanceRecord."Maintenance Date" := Today() - 1 - Random(365);
        MaintenanceRecord."Maintenance Type" := MaintenanceRecord."Maintenance Type"::Preventive;
        MaintenanceRecord.Insert(true);
        MaintenanceRecord.Get(MaintenanceRecord."No.");

        // [WHEN] The record is posted
        Codeunit.Run(Codeunit::"EQM Maintenance-Post", MaintenanceRecord);

        // [THEN] The last maintenance date is still today, and the next date is unchanged
        Equipment.Get(Equipment."No.");
        Assert.AreEqual(Today(), Equipment."Last Maintenance Date", 'Last maintenance date should not move back');
        Assert.AreEqual(NextDate, Equipment."Next Maintenance Date", 'Next maintenance date should not change');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EquipmentWithMaintenanceRecordsCannotBeDeleted()
    var
        Equipment: Record "EQM Equipment";
        MaintenanceRecord: Record "EQM Maintenance Record";
    begin
        // [SCENARIO M17] (negative) Equipment that has maintenance records cannot be deleted
        // [GIVEN] Equipment E with a maintenance record
        CreateEquipment(Equipment);
        InitMaintenance(MaintenanceRecord, Equipment."No.");
        MaintenanceRecord.Insert(true);
        Equipment.Get(Equipment."No.");

        // [WHEN] E is deleted
        asserterror Equipment.Delete(true);

        // [THEN] The error names E and the Disposed status
        Assert.ExpectedError(StrSubstNo(DeleteMaintenanceExistsErr, Equipment."No.", Format(Equipment.Status::Disposed)));
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

    local procedure CreateEquipmentWithPlan(var Equipment: Record "EQM Equipment"; LastMaintenanceDate: Date)
    begin
        CreateEquipment(Equipment);
        Equipment."Maintenance Frequency (Months)" := 1 + Random(12);
        Equipment."Last Maintenance Date" := LastMaintenanceDate;
        Equipment.Modify(true);
        Equipment.Get(Equipment."No.");
    end;

    local procedure CreateAssignedEquipment(var Equipment: Record "EQM Equipment"; var Employee: Record Employee)
    begin
        Employee.Init();
        Employee."No." := CopyStr(StrSubstNo(EmployeeNoTok, NextId()), 1, MaxStrLen(Employee."No."));
        Employee."First Name" := 'EQMMNT';
        Employee."Last Name" := Employee."No.";
        Employee.Status := Employee.Status::Active;
        Employee.Insert(false);

        CreateEquipment(Equipment);
        Equipment.Get(Equipment."No.");
        Equipment.AssignEmployee(Employee."No.");
        Equipment.Get(Equipment."No.");
    end;

    local procedure InitMaintenance(var MaintenanceRecord: Record "EQM Maintenance Record"; EquipmentNo: Code[20])
    begin
        MaintenanceRecord.Init();
        MaintenanceRecord."No." := CopyStr(StrSubstNo(MaintenanceNoTok, NextId()), 1, MaxStrLen(MaintenanceRecord."No."));
        MaintenanceRecord."Equipment No." := EquipmentNo;
        MaintenanceRecord."Maintenance Date" := Today();
        MaintenanceRecord.Description := MaintenanceRecord."No.";
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
