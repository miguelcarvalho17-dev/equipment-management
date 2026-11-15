namespace MiguelCarvalho.EquipmentManagement.Tests;

using Microsoft.Foundation.NoSeries;
using Microsoft.HumanResources.Employee;
using MiguelCarvalho.EquipmentManagement;
using System.TestLibraries.Utilities;

/// <summary>
/// Tests for FR-032 Equipment Request Process (table 50111, enum 50110, pages 50133/50134, setup field "Request Nos.").
/// Every test builds its own data in the test transaction (AutoRollback); there is no Commit.
/// Scenario 16 of the plan (permissions, Tell Me, Role Center, event subscriber) is a manual sandbox check.
/// </summary>
codeunit 50188 "EQM Equipment Request Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        ActiveEmployeeTok: Label 'EQMREQ-E1', Locked = true;
        ActiveEmployee2Tok: Label 'EQMREQ-E2', Locked = true;
        InactiveEmployeeTok: Label 'EQMREQ-E3', Locked = true;
        InactiveEmployee2Tok: Label 'EQMREQ-E4', Locked = true;
        BlockedEmployeeTok: Label 'EQMREQ-E5', Locked = true;
        MissingEmployeeTok: Label 'EQMREQ-E9', Locked = true;
        ActiveCategoryTok: Label 'EQMREQ-C1', Locked = true;
        InactiveCategoryTok: Label 'EQMREQ-C2', Locked = true;
        MissingCategoryTok: Label 'EQMREQ-C9', Locked = true;
        ActiveCategoryDescriptionTok: Label 'EQMREQ active category', Locked = true;
        TestSeriesTok: Label 'EQMREQT', Locked = true;
        TestSeriesStartTok: Label 'TREQ0001', Locked = true;
        TestSeriesSecondTok: Label 'TREQ0002', Locked = true;
        DefaultSeriesTok: Label 'EQREQ', Locked = true;
        DefaultSeriesStartTok: Label 'REQ00001', Locked = true;
        ManualNoTok: Label 'EQMREQ-M1', Locked = true;
        ManualNo2Tok: Label 'EQMREQ-M2', Locked = true;
        JustificationTok: Label 'Needs a laptop for the new project', Locked = true;
        ChangedJustificationTok: Label 'Changed justification', Locked = true;
        // Copies of the labels in table 50111; labels of another app are not accessible.
        EmployeeNotFoundErr: Label 'Employee %1 does not exist.', Comment = '%1 = employee number';
        EmployeeNotActiveErr: Label 'You cannot raise an equipment request for employee %1 because the employee status is %2.', Comment = '%1 = employee number, %2 = employee status';
        EmployeePrivacyBlockedErr: Label 'You cannot raise an equipment request for employee %1 because the employee is blocked for privacy reasons.', Comment = '%1 = employee number';
        CategoryNotFoundErr: Label 'Equipment type %1 does not exist. Choose a category from the Equipment Categories page.', Comment = '%1 = equipment category code';
        CategoryInactiveErr: Label 'You cannot request equipment type %1 because the category is not active.', Comment = '%1 = equipment category code';
        JustificationRequiredErr: Label 'You must enter a justification for the equipment request.';
        FutureDateErr: Label 'The request date %1 is in the future. Enter a date that is not later than today (%2).', Comment = '%1 = request date, %2 = today''s date';
        InsertNotOpenErr: Label 'Equipment request %1 must be created with the status Open.', Comment = '%1 = request number';
        RequestNotOpenErr: Label 'You cannot change equipment request %1 because its status is %2. Only open requests can be changed.', Comment = '%1 = request number, %2 = status';
        DeleteNotOpenErr: Label 'You cannot delete equipment request %1 because its status is %2. Only open requests can be deleted.', Comment = '%1 = request number, %2 = status';
        RenameNotAllowedErr: Label 'You cannot change the number of equipment request %1.', Comment = '%1 = request number';
        HandlerEmployeeNo: Code[20];
        HandlerRowCount: Integer;
        HandlerForeignRowFound: Boolean;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure InsertTakesNumberFromSeriesAndStartsOpen()
    var
        Request: Record "EQM Equipment Request";
    begin
        // [SCENARIO 1] A new request gets its number from the Request Nos. series, is Open and dated WorkDate
        Initialize();

        // [GIVEN] Setup Request Nos. = test series and a request with a blank No.
        NewRequest(Request, '', ActiveEmployeeTok, ActiveCategoryTok);

        // [WHEN] The request is inserted
        Request.Insert(true);

        // [THEN] No. and No. Series come from the series, Status is Open, Request Date is WorkDate
        Assert.AreEqual(TestSeriesStartTok, Request."No.", 'No. should be the first number of the test series');
        Assert.AreEqual(TestSeriesTok, Request."No. Series", 'No. Series should be the Request Nos. series');
        Assert.AreEqual(Request.Status::Open, Request.Status, 'A new request should be Open');
        Assert.AreEqual(WorkDate(), Request."Request Date", 'A blank Request Date should default to the work date');
        Assert.IsTrue(Request.Get(TestSeriesStartTok), 'The request should be stored under the series number');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SecondRequestGetsNextSeriesNumber()
    var
        Request: Record "EQM Equipment Request";
        Request2: Record "EQM Equipment Request";
    begin
        // [SCENARIO 1b] Two requests inserted in a row get consecutive numbers
        Initialize();

        // [GIVEN] One request inserted from the series
        NewRequest(Request, '', ActiveEmployeeTok, ActiveCategoryTok);
        Request.Insert(true);

        // [WHEN] A second request is inserted
        NewRequest(Request2, '', ActiveEmployee2Tok, ActiveCategoryTok);
        Request2.Insert(true);

        // [THEN] The second number follows the first
        Assert.AreEqual(TestSeriesSecondTok, Request2."No.", 'The second request should get the next number');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PastRequestDateIsKept()
    var
        Request: Record "EQM Equipment Request";
        PastDate: Date;
    begin
        // [SCENARIO 2] A past Request Date is kept on insert
        Initialize();

        // [GIVEN] A request with a Request Date 30 days ago
        PastDate := Today() - 30;
        NewRequest(Request, ManualNoTok, ActiveEmployeeTok, ActiveCategoryTok);
        Request."Request Date" := PastDate;

        // [WHEN] The request is inserted
        Request.Insert(true);

        // [THEN] The stored date is unchanged
        Request.Get(ManualNoTok);
        Assert.AreEqual(PastDate, Request."Request Date", 'A past Request Date should be kept');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TodayRequestDateIsAccepted()
    var
        Request: Record "EQM Equipment Request";
    begin
        // [SCENARIO 3b] Boundary: today is not in the future
        Initialize();

        // [GIVEN] A request dated today
        NewRequest(Request, ManualNoTok, ActiveEmployeeTok, ActiveCategoryTok);
        Request.Validate("Request Date", Today());

        // [WHEN] The request is inserted
        Request.Insert(true);

        // [THEN] It is stored with today's date
        Request.Get(ManualNoTok);
        Assert.AreEqual(Today(), Request."Request Date", 'Today should be accepted as Request Date');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FutureRequestDateIsRejectedOnValidateAndInsert()
    var
        Request: Record "EQM Equipment Request";
        FutureDate: Date;
    begin
        // [SCENARIO 3] A Request Date after today is rejected on validate and on insert
        Initialize();
        FutureDate := Today() + 1;

        // [GIVEN] A request
        NewRequest(Request, ManualNoTok, ActiveEmployeeTok, ActiveCategoryTok);

        // [WHEN] Request Date is validated with tomorrow
        asserterror Request.Validate("Request Date", FutureDate);

        // [THEN] FutureDateErr is raised
        Assert.ExpectedError(StrSubstNo(FutureDateErr, FutureDate, Today()));

        // [WHEN] The request is inserted with tomorrow as Request Date (no validation)
        Request."Request Date" := FutureDate;
        asserterror Request.Insert(true);

        // [THEN] FutureDateErr is raised and no row exists
        Assert.ExpectedError(StrSubstNo(FutureDateErr, FutureDate, Today()));
        Assert.IsFalse(Request.Get(ManualNoTok), 'No request should be stored');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BlankEmployeeIsRejected()
    var
        Request: Record "EQM Equipment Request";
    begin
        // [SCENARIO 4a] A blank Employee No. is rejected
        Initialize();

        // [GIVEN] A request without employee
        NewRequest(Request, ManualNoTok, '', ActiveCategoryTok);

        // [WHEN] The request is inserted
        asserterror Request.Insert(true);

        // [THEN] A TestField error is raised and no row exists
        Assert.ExpectedErrorCode('TestField');
        Assert.ExpectedError(Request.FieldCaption("Employee No."));
        Assert.IsFalse(Request.Get(ManualNoTok), 'No request should be stored');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BlankEquipmentTypeIsRejected()
    var
        Request: Record "EQM Equipment Request";
    begin
        // [SCENARIO 4b] A blank Requested Equipment Type is rejected
        Initialize();

        // [GIVEN] A request without equipment type
        NewRequest(Request, ManualNoTok, ActiveEmployeeTok, '');

        // [WHEN] The request is inserted
        asserterror Request.Insert(true);

        // [THEN] A TestField error is raised and no row exists
        Assert.ExpectedErrorCode('TestField');
        Assert.ExpectedError(Request.FieldCaption("Requested Equipment Type"));
        Assert.IsFalse(Request.Get(ManualNoTok), 'No request should be stored');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BlankJustificationIsRejected()
    var
        Request: Record "EQM Equipment Request";
    begin
        // [SCENARIO 4c] A blank justification is rejected
        Initialize();

        // [GIVEN] A request with empty Justification
        NewRequest(Request, ManualNoTok, ActiveEmployeeTok, ActiveCategoryTok);
        Request.Justification := '';

        // [WHEN] The request is inserted
        asserterror Request.Insert(true);

        // [THEN] JustificationRequiredErr is raised and no row exists
        Assert.ExpectedError(JustificationRequiredErr);
        Assert.IsFalse(Request.Get(ManualNoTok), 'No request should be stored');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SpacesOnlyJustificationIsRejected()
    var
        Request: Record "EQM Equipment Request";
    begin
        // [SCENARIO 4d] A justification made only of spaces is rejected
        Initialize();

        // [GIVEN] A request with Justification = three spaces
        NewRequest(Request, ManualNoTok, ActiveEmployeeTok, ActiveCategoryTok);
        Request.Justification := '   ';

        // [WHEN] The request is inserted
        asserterror Request.Insert(true);

        // [THEN] JustificationRequiredErr is raised and no row exists
        Assert.ExpectedError(JustificationRequiredErr);
        Assert.IsFalse(Request.Get(ManualNoTok), 'No request should be stored');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NonExistingEmployeeIsRejectedOnInsert()
    var
        Request: Record "EQM Equipment Request";
    begin
        // [SCENARIO 5a] An employee that does not exist is rejected on validate and on insert
        // The field has ValidateTableRelation = false, so EmployeeNotFoundErr is raised, not the standard relation error.
        Initialize();

        // [GIVEN] A request for a non-existing employee
        NewRequest(Request, ManualNoTok, MissingEmployeeTok, ActiveCategoryTok);

        // [WHEN] The employee is validated
        asserterror Request.Validate("Employee No.", MissingEmployeeTok);

        // [THEN] EmployeeNotFoundErr is raised
        Assert.ExpectedError(StrSubstNo(EmployeeNotFoundErr, MissingEmployeeTok));

        // [WHEN] The request is inserted
        asserterror Request.Insert(true);

        // [THEN] EmployeeNotFoundErr is raised and no row exists
        Assert.ExpectedError(StrSubstNo(EmployeeNotFoundErr, MissingEmployeeTok));
        Assert.IsFalse(Request.Get(ManualNoTok), 'No request should be stored');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure InactiveEmployeeIsRejectedOnValidateAndInsert()
    var
        Request: Record "EQM Equipment Request";
    begin
        // [SCENARIO 5b] An Inactive employee is rejected on validate and on insert
        Initialize();

        // [GIVEN] A request
        NewRequest(Request, ManualNoTok, ActiveEmployeeTok, ActiveCategoryTok);

        // [WHEN] The Inactive employee is validated
        asserterror Request.Validate("Employee No.", InactiveEmployeeTok);

        // [THEN] EmployeeNotActiveErr names the employee and the status
        Assert.ExpectedError(StrSubstNo(EmployeeNotActiveErr, InactiveEmployeeTok, Format(Enum::"Employee Status"::Inactive)));

        // [WHEN] The request is inserted for the Inactive employee (no validation)
        Request."Employee No." := InactiveEmployeeTok;
        asserterror Request.Insert(true);

        // [THEN] The same error is raised and no row exists
        Assert.ExpectedError(StrSubstNo(EmployeeNotActiveErr, InactiveEmployeeTok, Format(Enum::"Employee Status"::Inactive)));
        Assert.IsFalse(Request.Get(ManualNoTok), 'No request should be stored');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PrivacyBlockedEmployeeIsRejectedOnValidateAndInsert()
    var
        Request: Record "EQM Equipment Request";
    begin
        // [SCENARIO 5c] A privacy-blocked employee is rejected on validate and on insert
        Initialize();

        // [GIVEN] A request
        NewRequest(Request, ManualNoTok, ActiveEmployeeTok, ActiveCategoryTok);

        // [WHEN] The privacy-blocked employee is validated
        asserterror Request.Validate("Employee No.", BlockedEmployeeTok);

        // [THEN] EmployeePrivacyBlockedErr is raised
        Assert.ExpectedError(StrSubstNo(EmployeePrivacyBlockedErr, BlockedEmployeeTok));

        // [WHEN] The request is inserted for the blocked employee
        Request."Employee No." := BlockedEmployeeTok;
        asserterror Request.Insert(true);

        // [THEN] The same error is raised and no row exists
        Assert.ExpectedError(StrSubstNo(EmployeePrivacyBlockedErr, BlockedEmployeeTok));
        Assert.IsFalse(Request.Get(ManualNoTok), 'No request should be stored');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NonExistingEquipmentTypeIsRejectedOnValidateAndInsert()
    var
        Request: Record "EQM Equipment Request";
    begin
        // [SCENARIO 6a] A type that is not a category is rejected on validate and on insert
        Initialize();

        // [GIVEN] A request
        NewRequest(Request, ManualNoTok, ActiveEmployeeTok, ActiveCategoryTok);

        // [WHEN] A non-existing type is validated
        asserterror Request.Validate("Requested Equipment Type", MissingCategoryTok);

        // [THEN] CategoryNotFoundErr is raised
        Assert.ExpectedError(StrSubstNo(CategoryNotFoundErr, MissingCategoryTok));

        // [WHEN] The request is inserted with the non-existing type
        Request."Requested Equipment Type" := MissingCategoryTok;
        asserterror Request.Insert(true);

        // [THEN] The same error is raised and no row exists
        Assert.ExpectedError(StrSubstNo(CategoryNotFoundErr, MissingCategoryTok));
        Assert.IsFalse(Request.Get(ManualNoTok), 'No request should be stored');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure InactiveCategoryIsRejectedOnValidateAndInsert()
    var
        Request: Record "EQM Equipment Request";
    begin
        // [SCENARIO 6b] An inactive category is rejected on validate and on insert
        Initialize();

        // [GIVEN] A request
        NewRequest(Request, ManualNoTok, ActiveEmployeeTok, ActiveCategoryTok);

        // [WHEN] The inactive category is validated
        asserterror Request.Validate("Requested Equipment Type", InactiveCategoryTok);

        // [THEN] CategoryInactiveErr is raised
        Assert.ExpectedError(StrSubstNo(CategoryInactiveErr, InactiveCategoryTok));

        // [WHEN] The request is inserted with the inactive category
        Request."Requested Equipment Type" := InactiveCategoryTok;
        asserterror Request.Insert(true);

        // [THEN] The same error is raised and no row exists
        Assert.ExpectedError(StrSubstNo(CategoryInactiveErr, InactiveCategoryTok));
        Assert.IsFalse(Request.Get(ManualNoTok), 'No request should be stored');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OpenRequestStaysEditableAfterEmployeeAndCategoryBecomeIneligible()
    var
        Request: Record "EQM Equipment Request";
        Employee: Record Employee;
        Category: Record "EQM Equipment Category";
    begin
        // [SCENARIO 7] The active checks apply only to new or changed employee/type values
        Initialize();

        // [GIVEN] An Open request, then its employee becomes Inactive and its category inactive
        NewRequest(Request, ManualNoTok, ActiveEmployeeTok, ActiveCategoryTok);
        Request.Insert(true);
        Employee.Get(ActiveEmployeeTok);
        Employee.Status := Employee.Status::Inactive;
        Employee.Modify(false);
        Category.Get(ActiveCategoryTok);
        Category.Active := false;
        Category.Modify(false);

        // [WHEN] Justification is changed and the request is modified
        Request.Justification := ChangedJustificationTok;
        Request.Modify(true);

        // [THEN] The change is stored
        Request.Get(ManualNoTok);
        Assert.AreEqual(ChangedJustificationTok, Request.Justification, 'Justification should be changed');

        // [WHEN] The employee is changed to another Inactive employee (validate)
        asserterror Request.Validate("Employee No.", InactiveEmployee2Tok);

        // [THEN] EmployeeNotActiveErr is raised
        Assert.ExpectedError(StrSubstNo(EmployeeNotActiveErr, InactiveEmployee2Tok, Format(Enum::"Employee Status"::Inactive)));

        // [WHEN] The employee is changed without validation and the request is modified
        Request.Get(ManualNoTok);
        Request."Employee No." := InactiveEmployee2Tok;
        asserterror Request.Modify(true);

        // [THEN] The modify check also rejects the changed Inactive employee, the stored employee is unchanged
        Assert.ExpectedError(StrSubstNo(EmployeeNotActiveErr, InactiveEmployee2Tok, Format(Enum::"Employee Status"::Inactive)));
        Request.Get(ManualNoTok);
        Assert.AreEqual(ActiveEmployeeTok, Request."Employee No.", 'The stored employee should be unchanged');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ChangingToInactiveCategoryOnModifyIsRejected()
    var
        Request: Record "EQM Equipment Request";
    begin
        // [SCENARIO 7b] Changing the type to an inactive category on modify is rejected
        Initialize();

        // [GIVEN] An Open request
        NewRequest(Request, ManualNoTok, ActiveEmployeeTok, ActiveCategoryTok);
        Request.Insert(true);

        // [WHEN] The type is changed to the inactive category and the request is modified
        Request."Requested Equipment Type" := InactiveCategoryTok;
        asserterror Request.Modify(true);

        // [THEN] CategoryInactiveErr is raised and the stored type is unchanged
        Assert.ExpectedError(StrSubstNo(CategoryInactiveErr, InactiveCategoryTok));
        Request.Get(ManualNoTok);
        Assert.AreEqual(ActiveCategoryTok, Request."Requested Equipment Type", 'The stored type should be unchanged');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure InsertWithStatusOtherThanOpenIsRejected()
    var
        Request: Record "EQM Equipment Request";
    begin
        // [SCENARIO 8] A request cannot be inserted with a status other than Open
        Initialize();

        // [GIVEN] A request with Status = Pending Approval
        NewRequest(Request, ManualNoTok, ActiveEmployeeTok, ActiveCategoryTok);
        Request.Status := Request.Status::"Pending Approval";

        // [WHEN] The request is inserted
        asserterror Request.Insert(true);

        // [THEN] InsertNotOpenErr is raised and no row exists
        Assert.ExpectedError(StrSubstNo(InsertNotOpenErr, ManualNoTok));
        Assert.IsFalse(Request.Get(ManualNoTok), 'No request should be stored');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OpenRequestCanBeModifiedAndDeleted()
    var
        Request: Record "EQM Equipment Request";
    begin
        // [SCENARIO 9] An Open request can be corrected and deleted
        Initialize();

        // [GIVEN] An Open request
        NewRequest(Request, ManualNoTok, ActiveEmployeeTok, ActiveCategoryTok);
        Request.Insert(true);

        // [WHEN] Justification is changed
        Request.Justification := ChangedJustificationTok;
        Request.Modify(true);

        // [THEN] The change is stored
        Request.Get(ManualNoTok);
        Assert.AreEqual(ChangedJustificationTok, Request.Justification, 'Justification should be changed');

        // [WHEN] The request is deleted
        Request.Delete(true);

        // [THEN] The request is gone
        Assert.IsFalse(Request.Get(ManualNoTok), 'The request should be deleted');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PendingApprovalRequestIsLocked()
    begin
        // [SCENARIO 10a] A Pending Approval request cannot be changed or deleted
        Initialize();
        VerifyStatusLock(Enum::"EQM Request Status"::"Pending Approval");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ApprovedRequestIsLocked()
    begin
        // [SCENARIO 10b] An Approved request cannot be changed or deleted
        Initialize();
        VerifyStatusLock(Enum::"EQM Request Status"::Approved);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RejectedRequestIsLocked()
    begin
        // [SCENARIO 10c] A Rejected request cannot be changed or deleted
        Initialize();
        VerifyStatusLock(Enum::"EQM Request Status"::Rejected);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CompletedRequestIsLocked()
    begin
        // [SCENARIO 10d] A Completed request cannot be changed or deleted
        Initialize();
        VerifyStatusLock(Enum::"EQM Request Status"::Completed);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RenameIsNotAllowed()
    var
        Request: Record "EQM Equipment Request";
    begin
        // [SCENARIO 11] The request number cannot be changed
        Initialize();

        // [GIVEN] An Open request
        NewRequest(Request, ManualNoTok, ActiveEmployeeTok, ActiveCategoryTok);
        Request.Insert(true);

        // [WHEN] The request is renamed
        asserterror Request.Rename(ManualNo2Tok);

        // [THEN] RenameNotAllowedErr is raised and the number is unchanged
        Assert.ExpectedError(StrSubstNo(RenameNotAllowedErr, ManualNoTok));
        Assert.IsTrue(Request.Get(ManualNoTok), 'The request should keep its number');
        Assert.IsFalse(Request.Get(ManualNo2Tok), 'No request with the new number should exist');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure StatusEnumHasFiveValues()
    var
        Ordinals: List of [Integer];
        Names: List of [Text];
    begin
        // [SCENARIO 12] Enum 50110 has exactly the five documented values
        // [GIVEN] The enum EQM Request Status
        // [WHEN] Names and ordinals are read
        Ordinals := Enum::"EQM Request Status".Ordinals();
        Names := Enum::"EQM Request Status".Names();

        // [THEN] There are 5 values with ordinals 0 to 4 and the documented names
        Assert.AreEqual(5, Ordinals.Count(), 'The enum should have 5 values');
        Assert.AreEqual(5, Names.Count(), 'The enum should have 5 names');
        Assert.AreEqual(0, Ordinals.Get(1), 'Ordinal 1');
        Assert.AreEqual(1, Ordinals.Get(2), 'Ordinal 2');
        Assert.AreEqual(2, Ordinals.Get(3), 'Ordinal 3');
        Assert.AreEqual(3, Ordinals.Get(4), 'Ordinal 4');
        Assert.AreEqual(4, Ordinals.Get(5), 'Ordinal 5');
        Assert.AreEqual('Open', Names.Get(1), 'Name of 0');
        Assert.AreEqual('Pending Approval', Names.Get(2), 'Name of 1');
        Assert.AreEqual('Approved', Names.Get(3), 'Name of 2');
        Assert.AreEqual('Rejected', Names.Get(4), 'Name of 3');
        Assert.AreEqual('Completed', Names.Get(5), 'Name of 4');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EquipmentTypeDescriptionIsCalculatedFromCategory()
    var
        Request: Record "EQM Equipment Request";
    begin
        // [SCENARIO 13] The FlowField returns the category description
        Initialize();

        // [GIVEN] An inserted request for the active category
        NewRequest(Request, ManualNoTok, ActiveEmployeeTok, ActiveCategoryTok);
        Request.Insert(true);

        // [WHEN] The FlowField is calculated
        Request.CalcFields("Equipment Type Description");

        // [THEN] It equals the category description
        Assert.AreEqual(ActiveCategoryDescriptionTok, Request."Equipment Type Description", 'Description should come from the category');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure StatusStyleMatchesStatus()
    var
        Request: Record "EQM Equipment Request";
    begin
        // [SCENARIO 12b] Each status has its style
        // [GIVEN] A request record (not stored)
        // [WHEN] Status is set to each value
        // [THEN] GetStatusStyle returns the documented style
        Request.Status := Request.Status::Open;
        Assert.AreEqual('Standard', Request.GetStatusStyle(), 'Open style');
        Request.Status := Request.Status::"Pending Approval";
        Assert.AreEqual('Ambiguous', Request.GetStatusStyle(), 'Pending Approval style');
        Request.Status := Request.Status::Approved;
        Assert.AreEqual('Favorable', Request.GetStatusStyle(), 'Approved style');
        Request.Status := Request.Status::Rejected;
        Assert.AreEqual('Unfavorable', Request.GetStatusStyle(), 'Rejected style');
        Request.Status := Request.Status::Completed;
        Assert.AreEqual('Subordinate', Request.GetStatusStyle(), 'Completed style');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CardCreatesOpenRequest()
    var
        Request: Record "EQM Equipment Request";
        RequestCard: TestPage "EQM Equipment Request Card";
    begin
        // [SCENARIO 14a] A new card that is filled in and closed creates an Open request
        Initialize();

        // [GIVEN] A new request card
        RequestCard.OpenNew();

        // [WHEN] Employee, type and justification are entered and the card is closed
        RequestCard."Employee No.".SetValue(ActiveEmployeeTok);
        RequestCard."Requested Equipment Type".SetValue(ActiveCategoryTok);
        RequestCard.Justification.SetValue(JustificationTok);
        RequestCard.Close();

        // [THEN] One Open request exists for the employee, numbered from the series
        Request.SetRange("Employee No.", ActiveEmployeeTok);
        Assert.RecordCount(Request, 1);
        Request.FindFirst();
        Assert.AreEqual(Request.Status::Open, Request.Status, 'The card should create an Open request');
        Assert.AreEqual(TestSeriesStartTok, Request."No.", 'The number should come from the series');
        Assert.AreEqual(ActiveCategoryTok, Request."Requested Equipment Type", 'The type should be stored');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CardIsNotEditableForCompletedRequest()
    var
        Request: Record "EQM Equipment Request";
        RequestCard: TestPage "EQM Equipment Request Card";
    begin
        // [SCENARIO 14b] The General fields are read-only unless the request is Open
        Initialize();

        // [GIVEN] A Completed request and an Open request
        NewRequest(Request, ManualNoTok, ActiveEmployeeTok, ActiveCategoryTok);
        Request.Insert(true);
        Request.Status := Request.Status::Completed;
        Request.Modify(false);

        // [WHEN] The card is opened on the Completed request
        RequestCard.OpenView();
        RequestCard.GoToRecord(Request);

        // [THEN] The fields are not editable
        Assert.IsFalse(RequestCard."Employee No.".Editable(), 'Employee No. should not be editable');
        Assert.IsFalse(RequestCard."Requested Equipment Type".Editable(), 'Requested Equipment Type should not be editable');
        Assert.IsFalse(RequestCard.Justification.Editable(), 'Justification should not be editable');
        Assert.IsFalse(RequestCard."Request Date".Editable(), 'Request Date should not be editable');
        RequestCard.Close();

        // [GIVEN] The request is reopened by code
        Request.Status := Request.Status::Open;
        Request.Modify(false);

        // [WHEN] The card is opened again
        RequestCard.OpenView();
        RequestCard.GoToRecord(Request);

        // [THEN] The fields are editable
        Assert.IsTrue(RequestCard."Employee No.".Editable(), 'Employee No. should be editable for an Open request');
        Assert.IsTrue(RequestCard.Justification.Editable(), 'Justification should be editable for an Open request');
        RequestCard.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ListFilteredOnOpenShowsOnlyOpenRequests()
    var
        Request: Record "EQM Equipment Request";
        RequestList: TestPage "EQM Equipment Requests";
    begin
        // [SCENARIO 14c] A list filtered on status Open shows only Open requests
        // Note: TestPage cannot select a page view; this applies the same filter that the view "Open" defines.
        Initialize();

        // [GIVEN] One Open and one Completed request
        NewRequest(Request, ManualNoTok, ActiveEmployeeTok, ActiveCategoryTok);
        Request.Insert(true);
        NewRequest(Request, ManualNo2Tok, ActiveEmployeeTok, ActiveCategoryTok);
        Request.Insert(true);
        Request.Status := Request.Status::Completed;
        Request.Modify(false);

        // [WHEN] The list is opened with Status = Open
        RequestList.OpenView();
        RequestList.Filter.SetFilter(Status, Format(Request.Status::Open));

        // [THEN] Only the Open request is shown
        Assert.IsTrue(RequestList.First(), 'The Open request should be listed');
        Assert.AreEqual(ManualNoTok, Format(RequestList."No.".Value()), 'The Open request should be shown');
        Assert.IsFalse(RequestList.Next(), 'The Completed request should not be listed');
        RequestList.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('RequestListHandler')]
    procedure EmployeeCardActionOpensRequestsOfThatEmployee()
    var
        Request: Record "EQM Equipment Request";
        Employee: Record Employee;
        EmployeeCard: TestPage "Employee Card";
    begin
        // [SCENARIO 14d] The Employee Card action opens the request list filtered on the employee
        Initialize();

        // [GIVEN] One request for each of two employees
        NewRequest(Request, ManualNoTok, ActiveEmployeeTok, ActiveCategoryTok);
        Request.Insert(true);
        NewRequest(Request, ManualNo2Tok, ActiveEmployee2Tok, ActiveCategoryTok);
        Request.Insert(true);
        HandlerEmployeeNo := ActiveEmployeeTok;
        HandlerRowCount := 0;
        HandlerForeignRowFound := false;

        // [WHEN] The action is invoked on the card of the first employee
        Employee.Get(ActiveEmployeeTok);
        EmployeeCard.OpenView();
        EmployeeCard.GoToRecord(Employee);
        EmployeeCard.EQMEquipmentRequests.Invoke();

        // [THEN] The handler saw exactly the first employee's request
        Assert.AreEqual(1, HandlerRowCount, 'Exactly one request should be listed');
        Assert.IsFalse(HandlerForeignRowFound, 'No request of another employee should be listed');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CreateDefaultDataCreatesRequestSeries()
    var
        EquipmentSetup: Record "EQM Equipment Setup";
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        DefaultData: Codeunit "EQM Default Data";
    begin
        // [SCENARIO 15a] With a blank Request Nos., the default data creates and assigns series EQREQ
        Initialize();

        // [GIVEN] No EQREQ series and a blank Request Nos.
        NoSeriesLine.SetRange("Series Code", DefaultSeriesTok);
        NoSeriesLine.DeleteAll(false);
        if NoSeries.Get(DefaultSeriesTok) then
            NoSeries.Delete(false);
        EquipmentSetup.Get();
        EquipmentSetup."Request Nos." := '';
        EquipmentSetup.Modify(false);

        // [WHEN] CreateDefaultData runs
        DefaultData.CreateDefaultData();

        // [THEN] The setup points to EQREQ, the series exists with a line starting at REQ00001
        EquipmentSetup.Get();
        Assert.AreEqual(DefaultSeriesTok, EquipmentSetup."Request Nos.", 'Request Nos. should be set to EQREQ');
        Assert.IsTrue(NoSeries.Get(DefaultSeriesTok), 'Series EQREQ should exist');
        NoSeriesLine.SetRange("Series Code", DefaultSeriesTok);
        Assert.RecordCount(NoSeriesLine, 1);
        NoSeriesLine.FindFirst();
        Assert.AreEqual(DefaultSeriesStartTok, NoSeriesLine."Starting No.", 'The series should start at REQ00001');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CreateDefaultDataKeepsExistingRequestNos()
    var
        EquipmentSetup: Record "EQM Equipment Setup";
        DefaultData: Codeunit "EQM Default Data";
    begin
        // [SCENARIO 15b] An existing Request Nos. value is kept
        Initialize();

        // [GIVEN] Request Nos. = the test series
        EquipmentSetup.Get();
        Assert.AreEqual(TestSeriesTok, EquipmentSetup."Request Nos.", 'Precondition: Request Nos. is the test series');

        // [WHEN] CreateDefaultData runs
        DefaultData.CreateDefaultData();

        // [THEN] Request Nos. is unchanged
        EquipmentSetup.Get();
        Assert.AreEqual(TestSeriesTok, EquipmentSetup."Request Nos.", 'An existing Request Nos. should be kept');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure InsertWithoutRequestNosFailsOnSetupField()
    var
        EquipmentSetup: Record "EQM Equipment Setup";
        Request: Record "EQM Equipment Request";
    begin
        // [SCENARIO 15c] Boundary: a blank Request Nos. blocks inserts with a blank number (risk R2 in the plan)
        Initialize();

        // [GIVEN] A blank Request Nos.
        EquipmentSetup.Get();
        EquipmentSetup."Request Nos." := '';
        EquipmentSetup.Modify(false);
        NewRequest(Request, '', ActiveEmployeeTok, ActiveCategoryTok);

        // [WHEN] A request without number is inserted
        asserterror Request.Insert(true);

        // [THEN] A TestField error names Request Nos.
        Assert.ExpectedErrorCode('TestField');
        Assert.ExpectedError(EquipmentSetup.FieldCaption("Request Nos."));
    end;

    local procedure VerifyStatusLock(NewStatus: Enum "EQM Request Status")
    var
        Request: Record "EQM Equipment Request";
    begin
        // [GIVEN] An Open request moved to the status by code (Modify without triggers)
        NewRequest(Request, ManualNoTok, ActiveEmployeeTok, ActiveCategoryTok);
        Request.Insert(true);
        Request.Status := NewStatus;
        Request.Modify(false);

        // [WHEN] Justification is changed with triggers
        Request.Justification := ChangedJustificationTok;
        asserterror Request.Modify(true);

        // [THEN] RequestNotOpenErr is raised and the record is unchanged
        Assert.ExpectedError(StrSubstNo(RequestNotOpenErr, ManualNoTok, Format(NewStatus)));
        Request.Get(ManualNoTok);
        Assert.AreEqual(JustificationTok, Request.Justification, 'Justification should be unchanged');
        Assert.AreEqual(NewStatus, Request.Status, 'Status should be unchanged');

        // [WHEN] The request is deleted with triggers
        asserterror Request.Delete(true);

        // [THEN] DeleteNotOpenErr is raised and the request still exists
        Assert.ExpectedError(StrSubstNo(DeleteNotOpenErr, ManualNoTok, Format(NewStatus)));
        Assert.IsTrue(Request.Get(ManualNoTok), 'The request should still exist');
    end;

    local procedure NewRequest(var Request: Record "EQM Equipment Request"; RequestNo: Code[20]; EmployeeNo: Code[20]; EquipmentType: Code[20])
    begin
        Request.Init();
        Request."No." := RequestNo;
        Request."Employee No." := EmployeeNo;
        Request."Requested Equipment Type" := EquipmentType;
        Request.Justification := JustificationTok;
    end;

    local procedure Initialize()
    var
        EquipmentSetup: Record "EQM Equipment Setup";
    begin
        // Everything runs in the test transaction, which is rolled back (AutoRollback), so nothing is committed or cleaned up.
        WorkDate(Today());

        CreateCategory(ActiveCategoryTok, true);
        CreateCategory(InactiveCategoryTok, false);

        CreateEmployee(ActiveEmployeeTok, Enum::"Employee Status"::Active, false);
        CreateEmployee(ActiveEmployee2Tok, Enum::"Employee Status"::Active, false);
        CreateEmployee(InactiveEmployeeTok, Enum::"Employee Status"::Inactive, false);
        CreateEmployee(InactiveEmployee2Tok, Enum::"Employee Status"::Inactive, false);
        CreateEmployee(BlockedEmployeeTok, Enum::"Employee Status"::Active, true);

        CreateNoSeries(TestSeriesTok, TestSeriesStartTok);

        if not EquipmentSetup.Get() then begin
            EquipmentSetup.Init();
            EquipmentSetup.Insert();
        end;
        EquipmentSetup."Request Nos." := TestSeriesTok;
        EquipmentSetup.Modify();
    end;

    local procedure CreateCategory(CategoryCode: Code[20]; IsActive: Boolean)
    var
        Category: Record "EQM Equipment Category";
    begin
        if Category.Get(CategoryCode) then
            Category.Delete();
        Category.Init();
        Category.Code := CategoryCode;
        if IsActive then
            Category.Description := CopyStr(ActiveCategoryDescriptionTok, 1, MaxStrLen(Category.Description))
        else
            Category.Description := 'EQMREQ inactive category';
        Category.Active := IsActive;
        Category.Insert();
    end;

    local procedure CreateEmployee(EmployeeNo: Code[20]; EmployeeStatus: Enum "Employee Status"; PrivacyBlocked: Boolean)
    var
        Employee: Record Employee;
    begin
        Employee.Init();
        Employee."No." := EmployeeNo;
        Employee."First Name" := 'EQMREQ';
        Employee."Last Name" := EmployeeNo;
        Employee.Status := EmployeeStatus;
        Employee."Privacy Blocked" := PrivacyBlocked;
        Employee.Insert(false);
    end;

    local procedure CreateNoSeries(SeriesCode: Code[20]; StartingNo: Code[20])
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        NoSeries.Init();
        NoSeries.Code := SeriesCode;
        NoSeries.Description := 'EQMREQ test series';
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

    [PageHandler]
    procedure RequestListHandler(var RequestList: TestPage "EQM Equipment Requests")
    begin
        if RequestList.First() then
            repeat
                HandlerRowCount += 1;
                if Format(RequestList."Employee No.".Value()) <> HandlerEmployeeNo then
                    HandlerForeignRowFound := true;
            until not RequestList.Next();
    end;
}
