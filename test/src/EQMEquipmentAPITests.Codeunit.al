namespace MiguelCarvalho.EquipmentManagement.Tests;

using Microsoft.Foundation.NoSeries;
using Microsoft.HumanResources.Employee;
using MiguelCarvalho.EquipmentManagement;
using System.TestLibraries.Utilities;

/// <summary>
/// Tests for the business rules that the equipment API page 50123 (FR-026) triggers on every write.
/// The API page has no write logic of its own: the platform validates the posted fields and then calls
/// Insert(true), Modify(true) or Delete(true) on table 50100, and the bound actions call AssignEmployee and
/// UnassignEmployee. These tests run the same table calls directly, with the same field order as a request.
/// Real HTTP calls cannot be authenticated in the CI container (UserPassword authentication, no credentials from the
/// test library), so the plan's table-level fallback is used (user-approved).
/// Not covered here and verified manually in the sandbox: scenario 1 (GET list), scenario 2a/2b (GET by id and the
/// OData filter with the enum encoding In_x0020_Maintenance), scenario 11 (PATCH of a read-only field: the page
/// marks id, assignedEmployeeNumber, nextMaintenanceDate and lastModifiedDateTime as Editable = false; the table
/// rule behind it is tested below), URL and field naming, the ETag/If-Match behavior, and scenario 17 (permissions).
/// A failed statement (asserterror) rolls back the whole test transaction, so each test that expects an error has
/// exactly one asserterror, as its last action, and only checks the error text afterwards.
/// </summary>
codeunit 50180 "EQM Equipment API Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        ConfirmReply: Boolean;
        ConfirmCount: Integer;
        TestNoSeriesCode: Code[20];
        EquipmentNoTok: Label 'EQMAPI-E1', Locked = true;
        EquipmentNo2Tok: Label 'EQMAPI-E2', Locked = true;
        ManualNoTok: Label 'EQMAPI-MANUAL', Locked = true;
        SeriesCodeTok: Label 'EQMAPISER', Locked = true;
        SeriesStartTok: Label 'EQMAPI0001', Locked = true;
        SeriesEndTok: Label 'EQMAPI9999', Locked = true;
        ActiveCategoryTok: Label 'EQMAPILAP', Locked = true;
        InactiveCategoryTok: Label 'EQMAPIOLD', Locked = true;
        MissingCategoryTok: Label 'EQMAPINONE', Locked = true;
        ActiveEmployeeTok: Label 'EQMAPIEMP1', Locked = true;
        InactiveEmployeeTok: Label 'EQMAPIEMP2', Locked = true;
        SerialTok: Label 'EQMAPI-S1', Locked = true;
        NewDescriptionTok: Label 'EQMAPI created by API', Locked = true;
        UpdatedDescriptionTok: Label 'EQMAPI updated by API', Locked = true;
        // Copies of the text of the labels in table 50100; labels of another app are not accessible.
        NewEquipmentAssignedErr: Label 'You cannot create equipment with the status %1. Create the equipment first, and then use the Assign to Employee action.', Comment = '%1 = status caption';
        NewEquipmentFinalStatusErr: Label 'You cannot create equipment with the status %1. Create the equipment first, and then change its status.', Comment = '%1 = status caption';
        CategoryInactiveErr: Label 'You cannot select equipment category %1 because it is not active. Choose an active category, or ask an administrator to activate it.', Comment = '%1 = category code';
        CategoryNotFoundErr: Label 'Equipment category %1 does not exist. Choose a category from the Equipment Categories page.', Comment = '%1 = category code';
        SerialNoAlreadyUsedErr: Label 'Serial No. %1 is already used by equipment %2.', Comment = '%1 = serial number, %2 = equipment number';
        StatusIsFinalErr: Label 'You cannot change the status of equipment %1 to %3 because %2 is a final status.', Comment = '%1 = equipment number, %2 = current status caption, %3 = new status caption';
        UseReturnActionErr: Label 'To make assigned equipment %1 available, use the Return action on the equipment card or the Return Equipment action on the employee card.', Comment = '%1 = equipment number';
        AssignedEmployeeRequiredErr: Label 'You must fill in %1 for equipment %2 because its status is %3. On the equipment card, use the Assign to Employee action.', Comment = '%1 = field caption, %2 = equipment number, %3 = status caption';
        EmployeeOnlyWhenAssignedErr: Label 'You can only fill in %1 when the status is %2.', Comment = '%1 = Assigned Employee No. field caption, %2 = Assigned status caption';
        EmployeeNotActiveErr: Label 'You cannot assign equipment to employee %1 because the employee status is %2.', Comment = '%1 = employee number, %2 = employee status';
        CannotAssignFinalStatusErr: Label 'You cannot assign equipment %1 because its status is %2.', Comment = '%1 = equipment number, %2 = status caption';
        AlreadyAssignedErr: Label 'Equipment %1 is already assigned to employee %2. Return the equipment first, and then assign it again.', Comment = '%1 = equipment number, %2 = employee number';
        NotAssignedErr: Label 'You cannot return equipment %1 because it is not assigned. Its status is %2.', Comment = '%1 = equipment number, %2 = status caption';
        DeleteHistoryExistsErr: Label 'You cannot delete equipment %1 because it has assignment history. To stop using the equipment, set its status to %2 instead.', Comment = '%1 = equipment number, %2 = Disposed status caption';
        DeleteAssignedErr: Label 'You cannot delete equipment %1 because it is assigned to employee %2. Return the equipment first.', Comment = '%1 = equipment number, %2 = employee number';
        // Fragment that does not depend on the date format of the session.
        WarrantyEndDateFragmentTxt: Label 'must be later than the warranty start date', Locked = true;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure InsertGivesSeriesNumberAndAvailableStatus()
    var
        Equipment: Record "EQM Equipment";
    begin
        // [SCENARIO 3] POST with description and category creates equipment with a series number and status Available
        Initialize();

        // [GIVEN] The setup with an active category and a number series, and a new record with description and category
        Equipment.Init();
        Equipment.Validate(Description, NewDescriptionTok);
        Equipment.Validate("Category Code", ActiveCategoryTok);

        // [WHEN] The record is inserted (the platform does this at the end of a POST, DelayedInsert)
        Equipment.Insert(true);

        // [THEN] The record has the first number of the series, the series code and status Available
        Equipment.SetRange(Description, NewDescriptionTok);
        Assert.RecordCount(Equipment, 1);
        Equipment.FindFirst();
        Assert.AreEqual(SeriesStartTok, Equipment."No.", 'The number should come from the number series');
        Assert.AreEqual(TestNoSeriesCode, Equipment."No. Series", 'The number series should be stored on the record');
        Assert.AreEqual(Equipment.Status::Available, Equipment.Status, 'New equipment should be Available');
        Assert.AreEqual('', Equipment."Assigned Employee No.", 'New equipment should have no employee');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure InsertWithAssignedStatusIsRejected()
    var
        Equipment: Record "EQM Equipment";
    begin
        // [SCENARIO 4a] (negative) New equipment cannot start as Assigned
        Initialize();

        // [GIVEN] A new record with description and category
        Equipment.Init();
        Equipment.Validate(Description, NewDescriptionTok);
        Equipment.Validate("Category Code", ActiveCategoryTok);

        // [WHEN] Status Assigned is validated on the new record (a POST with status Assigned)
        asserterror Equipment.Validate(Status, Equipment.Status::Assigned);

        // [THEN] The assigned-on-creation error is raised
        Assert.ExpectedError(StrSubstNo(NewEquipmentAssignedErr, Format(Equipment.Status::Assigned)));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure InsertWithDisposedStatusIsRejected()
    var
        Equipment: Record "EQM Equipment";
    begin
        // [SCENARIO 4b] (negative) New equipment cannot start as Disposed
        Initialize();

        // [GIVEN] A new record with description and category
        Equipment.Init();
        Equipment.Validate(Description, NewDescriptionTok);
        Equipment.Validate("Category Code", ActiveCategoryTok);

        // [WHEN] Status Disposed is validated on the new record (a POST with status Disposed)
        asserterror Equipment.Validate(Status, Equipment.Status::Disposed);

        // [THEN] The final-status-on-creation error is raised
        Assert.ExpectedError(StrSubstNo(NewEquipmentFinalStatusErr, Format(Equipment.Status::Disposed)));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure InsertWithLostStatusSetWithoutValidateIsRejected()
    var
        Equipment: Record "EQM Equipment";
    begin
        // [SCENARIO 4c] (negative) The insert check also rejects a final status that was set without validation
        Initialize();

        // [GIVEN] A new record with a final status assigned directly
        Equipment.Init();
        Equipment.Description := NewDescriptionTok;
        Equipment."Category Code" := ActiveCategoryTok;
        Equipment.Status := Equipment.Status::Lost;

        // [WHEN] The record is inserted
        asserterror Equipment.Insert(true);

        // [THEN] The final-status-on-creation error is raised
        Assert.ExpectedError(StrSubstNo(NewEquipmentFinalStatusErr, Format(Equipment.Status::Lost)));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure InsertWithAssignedStatusSetWithoutValidateIsRejected()
    var
        Equipment: Record "EQM Equipment";
    begin
        // [SCENARIO 4d] (negative) The insert check also rejects status Assigned that was set without validation
        Initialize();

        // [GIVEN] A new record with status Assigned and an employee, assigned directly
        Equipment.Init();
        Equipment.Description := NewDescriptionTok;
        Equipment."Category Code" := ActiveCategoryTok;
        Equipment.Status := Equipment.Status::Assigned;
        Equipment."Assigned Employee No." := ActiveEmployeeTok;

        // [WHEN] The record is inserted
        asserterror Equipment.Insert(true);

        // [THEN] The assigned-on-creation error is raised
        Assert.ExpectedError(StrSubstNo(NewEquipmentAssignedErr, Format(Equipment.Status::Assigned)));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure InsertWithInactiveCategoryIsRejected()
    var
        Equipment: Record "EQM Equipment";
    begin
        // [SCENARIO 5a] (negative) POST with an inactive category is rejected
        Initialize();

        // [GIVEN] An inactive category and a new record
        Equipment.Init();
        Equipment.Validate(Description, NewDescriptionTok);

        // [WHEN] The inactive category is validated
        asserterror Equipment.Validate("Category Code", InactiveCategoryTok);

        // [THEN] CategoryInactiveErr is raised
        Assert.ExpectedError(StrSubstNo(CategoryInactiveErr, InactiveCategoryTok));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure InsertWithInactiveCategoryWithoutValidateIsRejected()
    var
        Equipment: Record "EQM Equipment";
    begin
        // [SCENARIO 5b] (negative) The insert check rejects an inactive category even when the field was not validated
        Initialize();

        // [GIVEN] A new record with an inactive category assigned directly
        Equipment.Init();
        Equipment.Description := NewDescriptionTok;
        Equipment."Category Code" := InactiveCategoryTok;

        // [WHEN] The record is inserted
        asserterror Equipment.Insert(true);

        // [THEN] CategoryInactiveErr is raised
        Assert.ExpectedError(StrSubstNo(CategoryInactiveErr, InactiveCategoryTok));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure InsertWithUnknownCategoryIsRejected()
    var
        Equipment: Record "EQM Equipment";
    begin
        // [SCENARIO 5c] (negative) POST with a category that does not exist is rejected
        Initialize();

        // [GIVEN] A new record
        Equipment.Init();
        Equipment.Validate(Description, NewDescriptionTok);

        // [WHEN] An unknown category is validated
        asserterror Equipment.Validate("Category Code", MissingCategoryTok);

        // [THEN] CategoryNotFoundErr is raised
        Assert.ExpectedError(StrSubstNo(CategoryNotFoundErr, MissingCategoryTok));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure InsertWithoutCategoryIsRejected()
    var
        Equipment: Record "EQM Equipment";
    begin
        // [SCENARIO 5d] (negative) POST without a category is rejected
        Initialize();

        // [GIVEN] A new record with a description only
        Equipment.Init();
        Equipment.Validate(Description, NewDescriptionTok);

        // [WHEN] The record is inserted
        asserterror Equipment.Insert(true);

        // [THEN] The error names the Category Code field (TestField; the base text is not copied)
        Assert.ExpectedError(Equipment.FieldCaption("Category Code"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure InsertWithUsedSerialNumberIsRejected()
    var
        Equipment: Record "EQM Equipment";
        NewEquipment: Record "EQM Equipment";
    begin
        // [SCENARIO 6] (negative) POST with a serial number that another equipment already has
        Initialize();

        // [GIVEN] Equipment E with serial S1
        CreateEquipment(Equipment, EquipmentNoTok);
        Equipment.Validate("Serial No.", SerialTok);
        Equipment.Modify(true);
        NewEquipment.Init();
        NewEquipment.Validate(Description, NewDescriptionTok);
        NewEquipment.Validate("Category Code", ActiveCategoryTok);

        // [WHEN] The same serial number is validated on a new equipment
        asserterror NewEquipment.Validate("Serial No.", SerialTok);

        // [THEN] SerialNoAlreadyUsedErr names the serial number and E
        Assert.ExpectedError(StrSubstNo(SerialNoAlreadyUsedErr, SerialTok, EquipmentNoTok));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure InsertWithUsedSerialNumberSetWithoutValidateIsRejected()
    var
        Equipment: Record "EQM Equipment";
        NewEquipment: Record "EQM Equipment";
    begin
        // [SCENARIO 6b] (negative) The insert check rejects a used serial number even when the field was not validated
        Initialize();

        // [GIVEN] Equipment E with serial S1, and a new record with S1 assigned directly
        CreateEquipment(Equipment, EquipmentNoTok);
        Equipment.Validate("Serial No.", SerialTok);
        Equipment.Modify(true);
        NewEquipment.Init();
        NewEquipment.Description := NewDescriptionTok;
        NewEquipment."Category Code" := ActiveCategoryTok;
        NewEquipment."Serial No." := SerialTok;

        // [WHEN] The record is inserted
        asserterror NewEquipment.Insert(true);

        // [THEN] SerialNoAlreadyUsedErr is raised
        Assert.ExpectedError(StrSubstNo(SerialNoAlreadyUsedErr, SerialTok, EquipmentNoTok));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PatchKeepsOwnSerialNumber()
    var
        Equipment: Record "EQM Equipment";
    begin
        // [SCENARIO 6c] A PATCH that sends the serial number the equipment already has is not a duplicate
        Initialize();

        // [GIVEN] Equipment E with serial S1
        CreateEquipment(Equipment, EquipmentNoTok);
        Equipment.Validate("Serial No.", SerialTok);
        Equipment.Modify(true);

        // [WHEN] The same serial number is validated and saved again
        Equipment.Get(EquipmentNoTok);
        Equipment.Validate("Serial No.", SerialTok);
        Equipment.Modify(true);

        // [THEN] No error is raised and the serial number is kept
        Equipment.Get(EquipmentNoTok);
        Assert.AreEqual(SerialTok, Equipment."Serial No.", 'The serial number should be kept');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PatchDescriptionIsSaved()
    var
        Equipment: Record "EQM Equipment";
    begin
        // [SCENARIO 7a] PATCH description saves the new value
        Initialize();

        // [GIVEN] Saved equipment E
        CreateEquipment(Equipment, EquipmentNoTok);

        // [WHEN] The description is validated and the record is modified (a PATCH)
        Equipment.Get(EquipmentNoTok);
        Equipment.Validate(Description, UpdatedDescriptionTok);
        Equipment.Modify(true);

        // [THEN] The description is stored
        Equipment.Get(EquipmentNoTok);
        Assert.AreEqual(UpdatedDescriptionTok, Equipment.Description, 'The description should be saved');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PatchWarrantyEndBeforeStartIsRejected()
    var
        Equipment: Record "EQM Equipment";
    begin
        // [SCENARIO 7b] (negative) PATCH of a warranty end date before the start date is rejected
        Initialize();

        // [GIVEN] Equipment E with warranty start 2025-06-01 and no end date
        CreateEquipment(Equipment, EquipmentNoTok);
        Equipment.Validate("Warranty Start Date", DMY2Date(1, 6, 2025));
        Equipment.Modify(true);
        Equipment.Get(EquipmentNoTok);

        // [WHEN] The warranty end date 2025-01-01 is validated
        asserterror Equipment.Validate("Warranty End Date", DMY2Date(1, 1, 2025));

        // [THEN] The warranty end date error is raised
        Assert.ExpectedError(WarrantyEndDateFragmentTxt);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PatchWarrantyEndEqualToStartIsRejected()
    var
        Equipment: Record "EQM Equipment";
    begin
        // [SCENARIO 7c] (negative, boundary) A warranty end date equal to the start date is rejected
        Initialize();

        // [GIVEN] Equipment E with warranty start 2025-06-01
        CreateEquipment(Equipment, EquipmentNoTok);
        Equipment.Validate("Warranty Start Date", DMY2Date(1, 6, 2025));
        Equipment.Modify(true);
        Equipment.Get(EquipmentNoTok);

        // [WHEN] The same date is validated as the end date
        asserterror Equipment.Validate("Warranty End Date", DMY2Date(1, 6, 2025));

        // [THEN] The warranty end date error is raised
        Assert.ExpectedError(WarrantyEndDateFragmentTxt);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PatchWarrantyEndAfterStartIsSaved()
    var
        Equipment: Record "EQM Equipment";
    begin
        // [SCENARIO 7d] (boundary) A warranty end date one day after the start date is accepted
        Initialize();

        // [GIVEN] Equipment E with warranty start 2025-06-01
        CreateEquipment(Equipment, EquipmentNoTok);
        Equipment.Validate("Warranty Start Date", DMY2Date(1, 6, 2025));
        Equipment.Modify(true);
        Equipment.Get(EquipmentNoTok);

        // [WHEN] The end date 2025-06-02 is validated and saved
        Equipment.Validate("Warranty End Date", DMY2Date(2, 6, 2025));
        Equipment.Modify(true);

        // [THEN] The end date is stored
        Equipment.Get(EquipmentNoTok);
        Assert.AreEqual(DMY2Date(2, 6, 2025), Equipment."Warranty End Date", 'The end date should be saved');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('ConfirmHandler')]
    procedure PatchStatusDisposedIsApplied()
    var
        Equipment: Record "EQM Equipment";
    begin
        // [SCENARIO 8a] PATCH status Disposed on Available equipment is applied
        // Through the API the final-status confirm defaults to Yes (no GUI). The handler answers Yes here.
        Initialize();

        // [GIVEN] Saved Available equipment E
        CreateEquipment(Equipment, EquipmentNoTok);
        ConfirmReply := true;
        ConfirmCount := 0;

        // [WHEN] Status Disposed is validated and the record is modified
        Equipment.Get(EquipmentNoTok);
        Equipment.Validate(Status, Equipment.Status::Disposed);
        Equipment.Modify(true);

        // [THEN] E is Disposed and the final-status question was asked once
        Equipment.Get(EquipmentNoTok);
        Assert.AreEqual(Equipment.Status::Disposed, Equipment.Status, 'Status should be Disposed');
        Assert.AreEqual(1, ConfirmCount, 'The final status confirmation should be asked once');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('ConfirmHandler')]
    procedure PatchStatusDisposedDeclinedKeepsStatus()
    var
        Equipment: Record "EQM Equipment";
    begin
        // [SCENARIO 8b] (boundary) When the final-status confirmation is answered No, the change is stopped
        Initialize();

        // [GIVEN] Saved Available equipment E and the confirmation answered No
        CreateEquipment(Equipment, EquipmentNoTok);
        ConfirmReply := false;
        ConfirmCount := 0;
        Equipment.Get(EquipmentNoTok);

        // [WHEN] Status Disposed is validated
        asserterror Equipment.Validate(Status, Equipment.Status::Disposed);

        // [THEN] The question was asked once and the validation stopped with an empty error
        Assert.AreEqual(1, ConfirmCount, 'The final status confirmation should be asked once');
        Assert.AreEqual('', GetLastErrorText(), 'Declining the confirmation should raise an empty error');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('ConfirmHandler')]
    procedure PatchDisposedEquipmentToAvailableIsRejected()
    var
        Equipment: Record "EQM Equipment";
    begin
        // [SCENARIO 8c] (negative) A further status change on Disposed equipment is rejected
        Initialize();

        // [GIVEN] Disposed equipment E
        CreateEquipment(Equipment, EquipmentNoTok);
        ConfirmReply := true;
        SetStatus(EquipmentNoTok, "EQM Equipment Status"::Disposed);
        Equipment.Get(EquipmentNoTok);

        // [WHEN] Status Available is validated
        asserterror Equipment.Validate(Status, Equipment.Status::Available);

        // [THEN] StatusIsFinalErr is raised
        Assert.ExpectedError(StrSubstNo(StatusIsFinalErr, EquipmentNoTok, Format(Equipment.Status::Disposed), Format(Equipment.Status::Available)));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('ConfirmHandler')]
    procedure PatchStatusLostClearsEmployeeAndClosesAssignment()
    var
        Equipment: Record "EQM Equipment";
        EquipmentAssignment: Record "EQM Equipment Assignment";
    begin
        // [SCENARIO 9] PATCH status Lost on assigned equipment clears the employee and closes the active entry
        Initialize();

        // [GIVEN] Equipment E assigned to EMP1 (one Active entry)
        CreateEquipment(Equipment, EquipmentNoTok);
        Equipment.AssignEmployee(ActiveEmployeeTok);
        ConfirmReply := true;
        ConfirmCount := 0;

        // [WHEN] Status Lost is validated and the record is modified
        Equipment.Get(EquipmentNoTok);
        Equipment.Validate(Status, Equipment.Status::Lost);
        Equipment.Modify(true);

        // [THEN] E is Lost without an employee, the entry is Closed and no entry is Active
        Assert.AreEqual(1, ConfirmCount, 'The final status confirmation should be asked once');
        Equipment.Get(EquipmentNoTok);
        Assert.AreEqual(Equipment.Status::Lost, Equipment.Status, 'Status should be Lost');
        Assert.AreEqual('', Equipment."Assigned Employee No.", 'The employee should be cleared');
        FilterAssignments(EquipmentAssignment, EquipmentNoTok, EquipmentAssignment.Status::Closed);
        Assert.RecordCount(EquipmentAssignment, 1);
        FilterAssignments(EquipmentAssignment, EquipmentNoTok, EquipmentAssignment.Status::Active);
        Assert.RecordIsEmpty(EquipmentAssignment);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PatchAssignedEquipmentToAvailableIsRejected()
    var
        Equipment: Record "EQM Equipment";
    begin
        // [SCENARIO 10a] (negative) PATCH status Available on assigned equipment must use the return action
        Initialize();

        // [GIVEN] Equipment E assigned to EMP1
        CreateEquipment(Equipment, EquipmentNoTok);
        Equipment.AssignEmployee(ActiveEmployeeTok);
        Equipment.Get(EquipmentNoTok);

        // [WHEN] Status Available is validated
        asserterror Equipment.Validate(Status, Equipment.Status::Available);

        // [THEN] UseReturnActionErr is raised
        Assert.ExpectedError(StrSubstNo(UseReturnActionErr, EquipmentNoTok));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PatchStatusAssignedWithoutEmployeeIsRejected()
    var
        Equipment: Record "EQM Equipment";
    begin
        // [SCENARIO 10b] (negative) PATCH status Assigned on Available equipment fails: no employee can be set through PATCH
        // Observation for the plan: the error text points to the Assign to Employee action on the equipment card,
        // which an API client does not have (it should use the assign bound action).
        Initialize();

        // [GIVEN] Available equipment E with status Assigned validated and no employee
        CreateEquipment(Equipment, EquipmentNoTok);
        Equipment.Get(EquipmentNoTok);
        Equipment.Validate(Status, Equipment.Status::Assigned);

        // [WHEN] The record is modified
        asserterror Equipment.Modify(true);

        // [THEN] AssignedEmployeeRequiredErr is raised
        Assert.ExpectedError(StrSubstNo(AssignedEmployeeRequiredErr, Equipment.FieldCaption("Assigned Employee No."), EquipmentNoTok, Format(Equipment.Status::Assigned)));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EmployeeCannotBeSetOnAvailableEquipment()
    var
        Equipment: Record "EQM Equipment";
    begin
        // [SCENARIO 11] (negative) The table rule behind the read-only assignedEmployeeNumber field:
        // an employee can only be set when the status is Assigned. The page-level Editable = false is checked in the sandbox.
        Initialize();

        // [GIVEN] Available equipment E
        CreateEquipment(Equipment, EquipmentNoTok);
        Equipment.Get(EquipmentNoTok);

        // [WHEN] An employee is validated on the equipment
        asserterror Equipment.Validate("Assigned Employee No.", ActiveEmployeeTok);

        // [THEN] EmployeeOnlyWhenAssignedErr is raised
        Assert.ExpectedError(StrSubstNo(EmployeeOnlyWhenAssignedErr, Equipment.FieldCaption("Assigned Employee No."), Format(Equipment.Status::Assigned)));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AssignActionAssignsEquipmentToEmployee()
    var
        Equipment: Record "EQM Equipment";
        EquipmentAssignment: Record "EQM Equipment Assignment";
    begin
        // [SCENARIO 12] The assign action sets status Assigned, the employee and one Active entry
        Initialize();

        // [GIVEN] Available equipment E and active employee EMP1
        CreateEquipment(Equipment, EquipmentNoTok);
        Equipment.Get(EquipmentNoTok);

        // [WHEN] AssignEmployee is called with EMP1 (the bound action assign)
        Equipment.AssignEmployee(ActiveEmployeeTok);

        // [THEN] E is Assigned to EMP1 with exactly one Active entry for EMP1
        Equipment.Get(EquipmentNoTok);
        Assert.AreEqual(Equipment.Status::Assigned, Equipment.Status, 'Status should be Assigned');
        Assert.AreEqual(ActiveEmployeeTok, Equipment."Assigned Employee No.", 'The employee should be EMP1');
        FilterAssignments(EquipmentAssignment, EquipmentNoTok, EquipmentAssignment.Status::Active);
        Assert.RecordCount(EquipmentAssignment, 1);
        EquipmentAssignment.FindFirst();
        Assert.AreEqual(ActiveEmployeeTok, EquipmentAssignment."Employee No.", 'The entry should be for EMP1');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AssignActionRejectsInactiveEmployee()
    var
        Equipment: Record "EQM Equipment";
        Employee: Record Employee;
    begin
        // [SCENARIO 13a] (negative) assign with an inactive employee is rejected
        Initialize();

        // [GIVEN] Available equipment E and inactive employee EMP2
        CreateEquipment(Equipment, EquipmentNoTok);
        Equipment.Get(EquipmentNoTok);

        // [WHEN] AssignEmployee is called with EMP2
        asserterror Equipment.AssignEmployee(InactiveEmployeeTok);

        // [THEN] EmployeeNotActiveErr is raised
        Assert.ExpectedError(StrSubstNo(EmployeeNotActiveErr, InactiveEmployeeTok, Format(Employee.Status::Inactive)));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('ConfirmHandler')]
    procedure AssignActionRejectsLostEquipment()
    var
        Equipment: Record "EQM Equipment";
    begin
        // [SCENARIO 13b] (negative) assign on Lost equipment is rejected
        Initialize();

        // [GIVEN] Lost equipment E
        CreateEquipment(Equipment, EquipmentNoTok);
        ConfirmReply := true;
        SetStatus(EquipmentNoTok, "EQM Equipment Status"::Lost);
        Equipment.Get(EquipmentNoTok);

        // [WHEN] AssignEmployee is called
        asserterror Equipment.AssignEmployee(ActiveEmployeeTok);

        // [THEN] CannotAssignFinalStatusErr is raised
        Assert.ExpectedError(StrSubstNo(CannotAssignFinalStatusErr, EquipmentNoTok, Format(Equipment.Status::Lost)));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AssignActionRejectsAlreadyAssignedEquipment()
    var
        Equipment: Record "EQM Equipment";
    begin
        // [SCENARIO 13c] (negative) assign on equipment that is already assigned is rejected
        Initialize();

        // [GIVEN] Equipment E assigned to EMP1
        CreateEquipment(Equipment, EquipmentNoTok);
        Equipment.AssignEmployee(ActiveEmployeeTok);
        Equipment.Get(EquipmentNoTok);

        // [WHEN] AssignEmployee is called again
        asserterror Equipment.AssignEmployee(ActiveEmployeeTok);

        // [THEN] AlreadyAssignedErr is raised
        Assert.ExpectedError(StrSubstNo(AlreadyAssignedErr, EquipmentNoTok, ActiveEmployeeTok));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('ConfirmHandler')]
    procedure ReturnActionMakesEquipmentAvailableAndClosesEntry()
    var
        Equipment: Record "EQM Equipment";
        EquipmentAssignment: Record "EQM Equipment Assignment";
        Returned: Boolean;
    begin
        // [SCENARIO 14a] The returnEquipment action makes assigned equipment Available and closes the entry
        // Through the API the return confirm defaults to Yes (no GUI). The handler answers Yes here.
        Initialize();

        // [GIVEN] Equipment E assigned to EMP1
        CreateEquipment(Equipment, EquipmentNoTok);
        Equipment.AssignEmployee(ActiveEmployeeTok);
        Equipment.Get(EquipmentNoTok);
        ConfirmReply := true;
        ConfirmCount := 0;

        // [WHEN] UnassignEmployee is called (the bound action returnEquipment)
        Returned := Equipment.UnassignEmployee();

        // [THEN] E is Available without employee, its entry is Closed and none is Active
        Assert.IsTrue(Returned, 'The return should succeed');
        Assert.AreEqual(1, ConfirmCount, 'The return confirmation should be asked once');
        Equipment.Get(EquipmentNoTok);
        Assert.AreEqual(Equipment.Status::Available, Equipment.Status, 'Status should be Available');
        Assert.AreEqual('', Equipment."Assigned Employee No.", 'The employee should be cleared');
        FilterAssignments(EquipmentAssignment, EquipmentNoTok, EquipmentAssignment.Status::Closed);
        Assert.RecordCount(EquipmentAssignment, 1);
        FilterAssignments(EquipmentAssignment, EquipmentNoTok, EquipmentAssignment.Status::Active);
        Assert.RecordIsEmpty(EquipmentAssignment);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('ConfirmHandler')]
    procedure ReturnActionDeclinedKeepsEquipmentAssigned()
    var
        Equipment: Record "EQM Equipment";
        Returned: Boolean;
    begin
        // [SCENARIO 14b] (boundary) When the return confirmation is answered No, nothing changes
        Initialize();

        // [GIVEN] Equipment E assigned to EMP1 and the confirmation answered No
        CreateEquipment(Equipment, EquipmentNoTok);
        Equipment.AssignEmployee(ActiveEmployeeTok);
        Equipment.Get(EquipmentNoTok);
        ConfirmReply := false;
        ConfirmCount := 0;

        // [WHEN] UnassignEmployee is called
        Returned := Equipment.UnassignEmployee();

        // [THEN] It returns false, and E is still assigned to EMP1
        Assert.IsFalse(Returned, 'The return should report that it was cancelled');
        Assert.AreEqual(1, ConfirmCount, 'The return confirmation should be asked once');
        Equipment.Get(EquipmentNoTok);
        Assert.AreEqual(Equipment.Status::Assigned, Equipment.Status, 'E should still be Assigned');
        Assert.AreEqual(ActiveEmployeeTok, Equipment."Assigned Employee No.", 'The employee should be kept');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReturnActionRejectsEquipmentThatIsNotAssigned()
    var
        Equipment: Record "EQM Equipment";
    begin
        // [SCENARIO 14c] (negative) returnEquipment on Available equipment is rejected
        Initialize();

        // [GIVEN] Available equipment E
        CreateEquipment(Equipment, EquipmentNoTok);
        Equipment.Get(EquipmentNoTok);

        // [WHEN] UnassignEmployee is called
        asserterror Equipment.UnassignEmployee();

        // [THEN] NotAssignedErr is raised
        Assert.ExpectedError(StrSubstNo(NotAssignedErr, EquipmentNoTok, Format(Equipment.Status::Available)));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DeleteRemovesEquipmentWithoutHistory()
    var
        Equipment: Record "EQM Equipment";
    begin
        // [SCENARIO 15a] DELETE removes equipment that was never assigned
        Initialize();

        // [GIVEN] Saved equipment E without history
        CreateEquipment(Equipment, EquipmentNoTok);
        CreateEquipment(Equipment, EquipmentNo2Tok);
        Equipment.Get(EquipmentNoTok);

        // [WHEN] E is deleted (a DELETE)
        Equipment.Delete(true);

        // [THEN] E no longer exists and the other equipment is untouched
        Assert.IsFalse(Equipment.Get(EquipmentNoTok), 'The equipment should be deleted');
        Assert.IsTrue(Equipment.Get(EquipmentNo2Tok), 'The other equipment should still exist');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('ConfirmHandler')]
    procedure DeleteIsRejectedForEquipmentWithAssignmentHistory()
    var
        Equipment: Record "EQM Equipment";
    begin
        // [SCENARIO 15b] (negative) DELETE of equipment with assignment history is rejected
        Initialize();

        // [GIVEN] Available equipment E that was assigned and returned (one Closed entry)
        CreateEquipment(Equipment, EquipmentNoTok);
        Equipment.AssignEmployee(ActiveEmployeeTok);
        Equipment.Get(EquipmentNoTok);
        ConfirmReply := true;
        Assert.IsTrue(Equipment.UnassignEmployee(), 'The setup return should succeed');
        Equipment.Get(EquipmentNoTok);

        // [WHEN] E is deleted
        asserterror Equipment.Delete(true);

        // [THEN] DeleteHistoryExistsErr is raised
        Assert.ExpectedError(StrSubstNo(DeleteHistoryExistsErr, EquipmentNoTok, Format(Equipment.Status::Disposed)));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DeleteIsRejectedForAssignedEquipment()
    var
        Equipment: Record "EQM Equipment";
    begin
        // [SCENARIO 15c] (negative) DELETE of assigned equipment is rejected
        Initialize();

        // [GIVEN] Equipment E assigned to EMP1
        CreateEquipment(Equipment, EquipmentNoTok);
        Equipment.AssignEmployee(ActiveEmployeeTok);
        Equipment.Get(EquipmentNoTok);

        // [WHEN] E is deleted
        asserterror Equipment.Delete(true);

        // [THEN] DeleteAssignedErr is raised
        Assert.ExpectedError(StrSubstNo(DeleteAssignedErr, EquipmentNoTok, ActiveEmployeeTok));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure InsertWithExplicitNumberIsRejectedWhenSeriesIsNotManual()
    var
        Equipment: Record "EQM Equipment";
    begin
        // [SCENARIO 16a] (negative) POST with an explicit number is rejected while the series does not allow manual numbers
        Initialize();

        // [GIVEN] The Equipment Nos. series has Manual Nos. = false (set in Initialize), and a new record
        Equipment.Init();

        // [WHEN] An explicit number is validated
        asserterror Equipment.Validate("No.", ManualNoTok);

        // [THEN] The standard TestManual error is raised (its text belongs to the base app and is not copied)
        Assert.AreNotEqual('', GetLastErrorText(), 'Validating an explicit number should fail');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure InsertWithExplicitNumberIsAcceptedWhenSeriesIsManual()
    var
        Equipment: Record "EQM Equipment";
    begin
        // [SCENARIO 16b] (boundary) POST with an explicit number is accepted when the series allows manual numbers
        Initialize();

        // [GIVEN] The Equipment Nos. series allows manual numbers, and a new record
        SetSeriesManual(true);
        Equipment.Init();
        Equipment.Validate("No.", ManualNoTok);
        Equipment.Validate(Description, NewDescriptionTok);
        Equipment.Validate("Category Code", ActiveCategoryTok);

        // [WHEN] The record is inserted
        Equipment.Insert(true);

        // [THEN] The record exists with the explicit number and no number series
        Assert.IsTrue(Equipment.Get(ManualNoTok), 'The equipment should be created with the explicit number');
        Assert.AreEqual('', Equipment."No. Series", 'A manual number should have no number series');
    end;

    local procedure Initialize()
    var
        EquipmentSetup: Record "EQM Equipment Setup";
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        Category: Record "EQM Equipment Category";
        Employee: Record Employee;
    begin
        // Everything runs in the test transaction, which is rolled back (AutoRollback), so nothing is committed or cleaned up.
        TestNoSeriesCode := SeriesCodeTok;
        NoSeries.Init();
        NoSeries.Code := TestNoSeriesCode;
        NoSeries.Description := TestNoSeriesCode;
        NoSeries."Default Nos." := true;
        NoSeries."Manual Nos." := false;
        NoSeries.Insert();

        NoSeriesLine.Init();
        NoSeriesLine."Series Code" := TestNoSeriesCode;
        NoSeriesLine."Line No." := 10000;
        NoSeriesLine.Validate("Starting No.", SeriesStartTok);
        NoSeriesLine.Validate("Ending No.", SeriesEndTok);
        NoSeriesLine.Insert(true);

        if not EquipmentSetup.Get() then begin
            EquipmentSetup.Init();
            EquipmentSetup.Insert();
        end;
        EquipmentSetup."Equipment Nos." := TestNoSeriesCode;
        EquipmentSetup.Modify();

        Category.Init();
        Category.Code := ActiveCategoryTok;
        Category.Active := true;
        Category.Insert();
        Category.Init();
        Category.Code := InactiveCategoryTok;
        Category.Active := false;
        Category.Insert();

        Employee.Init();
        Employee."No." := ActiveEmployeeTok;
        Employee."First Name" := 'API';
        Employee."Last Name" := ActiveEmployeeTok;
        Employee.Status := Employee.Status::Active;
        Employee.Insert(false);
        Employee.Init();
        Employee."No." := InactiveEmployeeTok;
        Employee."First Name" := 'API';
        Employee."Last Name" := InactiveEmployeeTok;
        Employee.Status := Employee.Status::Inactive;
        Employee.Insert(false);
    end;

    local procedure SetSeriesManual(AllowManual: Boolean)
    var
        NoSeries: Record "No. Series";
    begin
        NoSeries.Get(TestNoSeriesCode);
        NoSeries."Manual Nos." := AllowManual;
        NoSeries.Modify();
    end;

    local procedure CreateEquipment(var Equipment: Record "EQM Equipment"; EquipmentNo: Code[20])
    begin
        Equipment.Init();
        Equipment."No." := EquipmentNo;
        Equipment.Description := 'EQMAPI test equipment';
        Equipment."Category Code" := ActiveCategoryTok;
        Equipment.Insert(true);
    end;

    local procedure SetStatus(EquipmentNo: Code[20]; NewStatus: Enum "EQM Equipment Status")
    var
        Equipment: Record "EQM Equipment";
    begin
        // Same calls as a PATCH of the status. The caller must have set up ConfirmHandler for final statuses.
        Equipment.Get(EquipmentNo);
        Equipment.Validate(Status, NewStatus);
        Equipment.Modify(true);
    end;

    local procedure FilterAssignments(var EquipmentAssignment: Record "EQM Equipment Assignment"; EquipmentNo: Code[20]; AssignmentStatus: Enum "EQM Assignment Status")
    begin
        EquipmentAssignment.Reset();
        EquipmentAssignment.SetRange("Equipment No.", EquipmentNo);
        EquipmentAssignment.SetRange(Status, AssignmentStatus);
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        ConfirmCount += 1;
        Reply := ConfirmReply;
    end;
}
