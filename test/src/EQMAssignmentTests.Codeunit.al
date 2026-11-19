namespace MiguelCarvalho.EquipmentManagement.Tests;

using Microsoft.HumanResources.Employee;
using MiguelCarvalho.EquipmentManagement;
using System.TestLibraries.Utilities;

/// <summary>
/// FR-045 Automated Unit Tests, area Assignment Logic. Covers the example of the request (create equipment, assign an
/// employee, verify the status) end to end, and the assignment rules that the existing tests do not reach: employee
/// eligibility, open maintenance, the closing data of the history and reassignment.
/// A failed statement (asserterror) rolls back the whole test transaction, so each test that expects an error has
/// exactly one asserterror, as its last action, and only checks the error text afterwards.
/// </summary>
codeunit 50156 "EQM Assignment Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        Counter: Integer;
        EquipmentNoTok: Label 'EQMASG%1X', Locked = true;
        CategoryCodeTok: Label 'EQMASGC%1', Locked = true;
        EmployeeNoTok: Label 'EQMASGE%1', Locked = true;
        MaintenanceNoTok: Label 'EQMASGM%1', Locked = true;
        CounterFormatTok: Label '<Integer,4><Filler Character,0>', Locked = true;
        // Copies of the text of the labels in table 50100; labels of another app are not accessible.
        EmployeePrivacyBlockedErr: Label 'You cannot assign equipment to employee %1 because the employee is blocked for privacy reasons.', Comment = '%1 = employee number';
        MaintenanceOpenAssignErr: Label 'You cannot assign equipment %1 because it has open maintenance. Post the open maintenance records of the equipment first.', Comment = '%1 = equipment number';
        AlreadyAssignedErr: Label 'Equipment %1 is already assigned to employee %2. Return the equipment first, and then assign it again.', Comment = '%1 = equipment number, %2 = employee number';

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CreateEquipmentAndAssignEmployeeSetsStatusAssigned()
    var
        Equipment: Record "EQM Equipment";
        Employee: Record Employee;
        EquipmentAssignment: Record "EQM Equipment Assignment";
    begin
        // [SCENARIO A1] Create equipment, assign an employee, and verify the status is Assigned
        // [GIVEN] An active employee E1
        CreateEmployee(Employee, false);

        // [WHEN] New equipment E is created and assigned to E1
        CreateEquipment(Equipment);
        Equipment.Get(Equipment."No.");
        Equipment.AssignEmployee(Employee."No.");

        // [THEN] E is Assigned to E1
        Equipment.Get(Equipment."No.");
        Assert.AreEqual(Equipment.Status::Assigned, Equipment.Status, 'Status should be Assigned');
        Assert.AreEqual(Employee."No.", Equipment."Assigned Employee No.", 'Assigned employee');

        // [THEN] Exactly one assignment entry exists, Active, for E1, dated with the work date and made by the current user
        FilterAssignments(EquipmentAssignment, Equipment."No.");
        Assert.RecordCount(EquipmentAssignment, 1);
        EquipmentAssignment.FindFirst();
        Assert.AreEqual(EquipmentAssignment.Status::Active, EquipmentAssignment.Status, 'The entry should be Active');
        Assert.AreEqual(Employee."No.", EquipmentAssignment."Employee No.", 'Entry employee');
        Assert.AreEqual(WorkDate(), EquipmentAssignment."Assignment Date", 'Assignment date should be the work date');
        Assert.AreEqual(CopyStr(UserId(), 1, MaxStrLen(EquipmentAssignment."Assigned By")), EquipmentAssignment."Assigned By", 'Assigned by should be the current user');
        Assert.AreEqual(0D, EquipmentAssignment."Closing Date", 'An active entry has no closing date');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PrivacyBlockedEmployeeCannotBeAssigned()
    var
        Equipment: Record "EQM Equipment";
        Employee: Record Employee;
    begin
        // [SCENARIO A2] (negative) Equipment cannot be assigned to an employee that is blocked for privacy reasons
        // [GIVEN] Available equipment E and an active employee E3 that is privacy blocked
        CreateEquipment(Equipment);
        CreateEmployee(Employee, true);
        Equipment.Get(Equipment."No.");

        // [WHEN] E is assigned to E3
        asserterror Equipment.AssignEmployee(Employee."No.");

        // [THEN] The privacy error names E3
        Assert.ExpectedError(StrSubstNo(EmployeePrivacyBlockedErr, Employee."No."));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UnknownEmployeeCannotBeAssigned()
    var
        Equipment: Record "EQM Equipment";
        UnknownEmployeeNo: Code[20];
    begin
        // [SCENARIO A3] (negative) Equipment cannot be assigned to an employee that does not exist
        // [GIVEN] Available equipment E and an employee number that is not in the database
        CreateEquipment(Equipment);
        UnknownEmployeeNo := CopyStr(StrSubstNo(EmployeeNoTok, NextId()), 1, MaxStrLen(UnknownEmployeeNo));
        Equipment.Get(Equipment."No.");

        // [WHEN] E is assigned to the unknown employee
        asserterror Equipment.AssignEmployee(UnknownEmployeeNo);

        // [THEN] The error names the employee number
        Assert.ExpectedError(UnknownEmployeeNo);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EquipmentWithOpenMaintenanceCannotBeAssigned()
    var
        Equipment: Record "EQM Equipment";
        Employee: Record Employee;
        MaintenanceRecord: Record "EQM Maintenance Record";
    begin
        // [SCENARIO A4] (negative) Equipment with an open maintenance record cannot be assigned
        // [GIVEN] Equipment E with an open maintenance record, and an active employee E1
        CreateEquipment(Equipment);
        CreateEmployee(Employee, false);
        CreateOpenMaintenance(MaintenanceRecord, Equipment."No.");
        Equipment.Get(Equipment."No.");

        // [WHEN] E is assigned to E1
        asserterror Equipment.AssignEmployee(Employee."No.");

        // [THEN] The open maintenance error names E
        Assert.ExpectedError(StrSubstNo(MaintenanceOpenAssignErr, Equipment."No."));
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReturnClosesTheEntryWithClosingDateAndUser()
    var
        Equipment: Record "EQM Equipment";
        Employee: Record Employee;
        EquipmentAssignment: Record "EQM Equipment Assignment";
    begin
        // [SCENARIO A5] Returning assigned equipment closes the entry with the closing date and the user
        // [GIVEN] Equipment E assigned to E1
        CreateEmployee(Employee, false);
        CreateEquipment(Equipment);
        Equipment.Get(Equipment."No.");
        Equipment.AssignEmployee(Employee."No.");
        Equipment.Get(Equipment."No.");

        // [WHEN] E is returned (confirm Yes)
        Assert.IsTrue(Equipment.UnassignEmployee(), 'The return should be done');

        // [THEN] E is Available without an employee
        Equipment.Get(Equipment."No.");
        Assert.AreEqual(Equipment.Status::Available, Equipment.Status, 'Status should be Available');
        Assert.AreEqual('', Equipment."Assigned Employee No.", 'The employee should be removed');

        // [THEN] The only entry is Closed, with the work date as closing date and the current user as closed by
        FilterAssignments(EquipmentAssignment, Equipment."No.");
        Assert.RecordCount(EquipmentAssignment, 1);
        EquipmentAssignment.FindFirst();
        Assert.AreEqual(EquipmentAssignment.Status::Closed, EquipmentAssignment.Status, 'The entry should be Closed');
        Assert.AreEqual(WorkDate(), EquipmentAssignment."Closing Date", 'Closing date should be the work date');
        Assert.AreEqual(CopyStr(UserId(), 1, MaxStrLen(EquipmentAssignment."Closed By")), EquipmentAssignment."Closed By", 'Closed by should be the current user');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReassignAfterReturnKeepsTheHistory()
    var
        Equipment: Record "EQM Equipment";
        FirstEmployee: Record Employee;
        SecondEmployee: Record Employee;
        EquipmentAssignment: Record "EQM Equipment Assignment";
    begin
        // [SCENARIO A6] Equipment that is assigned again after a return keeps the closed entry and gets a new active one
        // [GIVEN] Equipment E assigned to E1 and returned, and a second active employee E2
        CreateEmployee(FirstEmployee, false);
        CreateEmployee(SecondEmployee, false);
        CreateEquipment(Equipment);
        Equipment.Get(Equipment."No.");
        Equipment.AssignEmployee(FirstEmployee."No.");
        Equipment.Get(Equipment."No.");
        Equipment.UnassignEmployee();
        Equipment.Get(Equipment."No.");

        // [WHEN] E is assigned to E2
        Equipment.AssignEmployee(SecondEmployee."No.");

        // [THEN] E has two entries: Closed for E1, and Active for E2
        FilterAssignments(EquipmentAssignment, Equipment."No.");
        Assert.RecordCount(EquipmentAssignment, 2);
        EquipmentAssignment.SetRange(Status, EquipmentAssignment.Status::Closed);
        Assert.RecordCount(EquipmentAssignment, 1);
        EquipmentAssignment.FindFirst();
        Assert.AreEqual(FirstEmployee."No.", EquipmentAssignment."Employee No.", 'The closed entry should be for E1');
        EquipmentAssignment.SetRange(Status, EquipmentAssignment.Status::Active);
        Assert.RecordCount(EquipmentAssignment, 1);
        EquipmentAssignment.FindFirst();
        Assert.AreEqual(SecondEmployee."No.", EquipmentAssignment."Employee No.", 'The active entry should be for E2');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EmployeeOfAssignedEquipmentCannotBeChangedDirectly()
    var
        Equipment: Record "EQM Equipment";
        FirstEmployee: Record Employee;
        SecondEmployee: Record Employee;
    begin
        // [SCENARIO A7] (negative) The employee of assigned equipment cannot be changed without returning the equipment first
        // [GIVEN] Equipment E assigned to E1, and a second active employee E2
        CreateEmployee(FirstEmployee, false);
        CreateEmployee(SecondEmployee, false);
        CreateEquipment(Equipment);
        Equipment.Get(Equipment."No.");
        Equipment.AssignEmployee(FirstEmployee."No.");
        Equipment.Get(Equipment."No.");

        // [WHEN] The assigned employee of E is changed to E2 and E is modified
        Equipment.Validate("Assigned Employee No.", SecondEmployee."No.");
        asserterror Equipment.Modify(true);

        // [THEN] The already assigned error names E and E1
        Assert.ExpectedError(StrSubstNo(AlreadyAssignedErr, Equipment."No.", FirstEmployee."No."));
    end;

    local procedure NextId(): Text
    begin
        Counter += 1;
        exit(Format(Counter, 0, CounterFormatTok));
    end;

    local procedure CreateEmployee(var Employee: Record Employee; PrivacyBlocked: Boolean)
    begin
        Employee.Init();
        Employee."No." := CopyStr(StrSubstNo(EmployeeNoTok, NextId()), 1, MaxStrLen(Employee."No."));
        Employee."First Name" := 'EQMASG';
        Employee."Last Name" := Employee."No.";
        Employee.Status := Employee.Status::Active;
        Employee."Privacy Blocked" := PrivacyBlocked;
        Employee.Insert(false);
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

    local procedure CreateOpenMaintenance(var MaintenanceRecord: Record "EQM Maintenance Record"; EquipmentNo: Code[20])
    begin
        MaintenanceRecord.Init();
        MaintenanceRecord."No." := CopyStr(StrSubstNo(MaintenanceNoTok, NextId()), 1, MaxStrLen(MaintenanceRecord."No."));
        MaintenanceRecord."Equipment No." := EquipmentNo;
        MaintenanceRecord."Maintenance Date" := Today();
        MaintenanceRecord.Description := MaintenanceRecord."No.";
        MaintenanceRecord.Insert(true);
    end;

    local procedure FilterAssignments(var EquipmentAssignment: Record "EQM Equipment Assignment"; EquipmentNo: Code[20])
    begin
        EquipmentAssignment.Reset();
        EquipmentAssignment.SetRange("Equipment No.", EquipmentNo);
    end;

    [ConfirmHandler]
    procedure ConfirmYesHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}
