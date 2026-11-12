namespace MiguelCarvalho.EquipmentManagement.Tests;

using Microsoft.Foundation.NoSeries;
using Microsoft.HumanResources.Employee;
using MiguelCarvalho.EquipmentManagement;
using System.TestLibraries.Utilities;

/// <summary>
/// Tests for the equipment API page 50123 (FR-026). The calls are real HTTP calls through "Library - Graph Mgt".
/// A web service call runs in its own session, so the test data must be committed first. These tests therefore
/// cannot use AutoRollback: every test starts with Initialize (removes leftovers, creates the data, commits) and ends
/// with CleanUp (removes the data and restores the Equipment Setup). All test data uses the prefix EQMAPI.
/// Rule checks that cannot be made through the API without a UI session (the history setup for the delete test) use
/// the table directly and say so where they do.
/// </summary>
codeunit 50180 "EQM Equipment API Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        LibraryUtility: Codeunit "Library - Utility";
        TestNoSeriesCode: Code[20];
        OriginalEquipmentNos: Code[20];
        SetupSaved: Boolean;
        EquipmentNoTok: Label 'EQMAPI-E1', Locked = true;
        EquipmentNo2Tok: Label 'EQMAPI-E2', Locked = true;
        ManualNoTok: Label 'EQMAPI-MANUAL', Locked = true;
        TestPrefixTok: Label 'EQMAPI*', Locked = true;
        SeriesStartTok: Label 'EQMAPI0001', Locked = true;
        SeriesEndTok: Label 'EQMAPI9999', Locked = true;
        ActiveCategoryTok: Label 'EQMAPILAP', Locked = true;
        InactiveCategoryTok: Label 'EQMAPIOLD', Locked = true;
        ActiveEmployeeTok: Label 'EQMAPIEMP1', Locked = true;
        InactiveEmployeeTok: Label 'EQMAPIEMP2', Locked = true;
        EmployeePrefixTok: Label 'EQMAPIEMP*', Locked = true;
        CategoryPrefixTok: Label 'EQMAPI*', Locked = true;
        SerialTok: Label 'EQMAPI-S1', Locked = true;
        NewDescriptionTok: Label 'EQMAPI created by API', Locked = true;
        UpdatedDescriptionTok: Label 'EQMAPI updated by API', Locked = true;
        NegativeDescriptionTok: Label 'EQMAPI negative case', Locked = true;
        // Query strings. Spaces are encoded as %20 and the enum value In Maintenance as In_x0020_Maintenance.
        NumberFilterTok: Label '?$filter=number%20eq%20''%1''', Locked = true;
        NumberAndStatusFilterTok: Label '?$filter=number%20eq%20''%1''%20and%20status%20eq%20''In_x0020_Maintenance''', Locked = true;
        ActionUrlTok: Label '%1/Microsoft.NAV.%2', Locked = true;
        // Copies of the text of the labels in table 50100; labels of another app are not accessible.
        NewEquipmentAssignedErr: Label 'You cannot create equipment with the status %1. Create the equipment first, and then use the Assign to Employee action.', Comment = '%1 = status caption';
        NewEquipmentFinalStatusErr: Label 'You cannot create equipment with the status %1. Create the equipment first, and then change its status.', Comment = '%1 = status caption';
        CategoryInactiveErr: Label 'You cannot select equipment category %1 because it is not active. Choose an active category, or ask an administrator to activate it.', Comment = '%1 = category code';
        SerialNoAlreadyUsedErr: Label 'Serial No. %1 is already used by equipment %2.', Comment = '%1 = serial number, %2 = equipment number';
        StatusIsFinalErr: Label 'You cannot change the status of equipment %1 to %3 because %2 is a final status.', Comment = '%1 = equipment number, %2 = current status caption, %3 = new status caption';
        UseReturnActionErr: Label 'To make assigned equipment %1 available, use the Return action on the equipment card or the Return Equipment action on the employee card.', Comment = '%1 = equipment number';
        AssignedEmployeeRequiredErr: Label 'You must fill in %1 for equipment %2 because its status is %3. On the equipment card, use the Assign to Employee action.', Comment = '%1 = field caption, %2 = equipment number, %3 = status caption';
        EmployeeNotActiveErr: Label 'You cannot assign equipment to employee %1 because the employee status is %2.', Comment = '%1 = employee number, %2 = employee status';
        CannotAssignFinalStatusErr: Label 'You cannot assign equipment %1 because its status is %2.', Comment = '%1 = equipment number, %2 = status caption';
        AlreadyAssignedErr: Label 'Equipment %1 is already assigned to employee %2. Return the equipment first, and then assign it again.', Comment = '%1 = equipment number, %2 = employee number';
        NotAssignedErr: Label 'You cannot return equipment %1 because it is not assigned. Its status is %2.', Comment = '%1 = equipment number, %2 = status caption';
        DeleteHistoryExistsErr: Label 'You cannot delete equipment %1 because it has assignment history. To stop using the equipment, set its status to %2 instead.', Comment = '%1 = equipment number, %2 = Disposed status caption';
        DeleteAssignedErr: Label 'You cannot delete equipment %1 because it is assigned to employee %2. Return the equipment first.', Comment = '%1 = equipment number, %2 = employee number';
        // Fragments that do not depend on the date format of the session.
        WarrantyEndDateFragmentTxt: Label 'must be later than the warranty start date', Locked = true;
        CategoryCodeCaptionTxt: Label 'Category Code', Locked = true;

    [Test]
    procedure GetReturnsEquipmentWithCodesAndStatus()
    var
        Equipment: Record "EQM Equipment";
        Response: Text;
        Item: JsonObject;
    begin
        // [SCENARIO 1] GET equipments returns the equipment with id, number, category and status
        Initialize();

        // [GIVEN] Saved equipment E (Available)
        CreateEquipment(Equipment, EquipmentNoTok);
        Commit();

        // [WHEN] GET equipments filtered on the number of E
        Response := ApiGet(GetBaseUrl() + StrSubstNo(NumberFilterTok, EquipmentNoTok));

        // [THEN] E is returned with id = SystemId, number, categoryCode and status Available
        Item := GetFirstValueItem(Response);
        Assert.AreEqual(LowerCase(Format(Equipment.SystemId, 0, 4)), LowerCase(GetText(Item, 'id')), 'id should be the SystemId of the equipment');
        Assert.AreEqual(EquipmentNoTok, GetText(Item, 'number'), 'number should be the equipment number');
        Assert.AreEqual(ActiveCategoryTok, GetText(Item, 'categoryCode'), 'categoryCode should be the category of the equipment');
        Assert.AreEqual('Available', GetText(Item, 'status'), 'status should be the enum value name');

        CleanUp();
    end;

    [Test]
    procedure GetSingleEntityByIdReturnsThatEquipment()
    var
        Equipment: Record "EQM Equipment";
        Response: Text;
        Item: JsonObject;
    begin
        // [SCENARIO 2a] GET equipments({id}) returns a single entity
        Initialize();

        // [GIVEN] Saved equipment E and E2
        CreateEquipment(Equipment, EquipmentNoTok);
        CreateEquipment(Equipment, EquipmentNo2Tok);
        Commit();

        // [WHEN] GET equipments({id of E2})
        Response := ApiGet(GetEntityUrl(Equipment.SystemId));

        // [THEN] A single entity (not a collection) for E2 is returned
        Assert.IsTrue(Item.ReadFrom(Response), 'The response should be a JSON object');
        Assert.IsFalse(Item.Contains('value'), 'A single entity should not be wrapped in a value collection');
        Assert.AreEqual(EquipmentNo2Tok, GetText(Item, 'number'), 'The entity should be the requested equipment');

        CleanUp();
    end;

    [Test]
    procedure GetFilterOnEnumStatusFindsInMaintenanceEquipment()
    var
        Equipment: Record "EQM Equipment";
        Response: Text;
        Item: JsonObject;
    begin
        // [SCENARIO 2b] The filter status eq 'In_x0020_Maintenance' returns equipment that is In Maintenance
        Initialize();

        // [GIVEN] Equipment E in status In Maintenance (set on the table: the status change needs no assignment)
        CreateEquipment(Equipment, EquipmentNoTok);
        Equipment.Status := Equipment.Status::"In Maintenance";
        Equipment.Modify(true);
        Commit();

        // [WHEN] GET equipments with the number of E and the status filter In_x0020_Maintenance
        Response := ApiGet(GetBaseUrl() + StrSubstNo(NumberAndStatusFilterTok, EquipmentNoTok));

        // [THEN] E is returned and its status is encoded with _x0020_
        Item := GetFirstValueItem(Response);
        Assert.AreEqual(EquipmentNoTok, GetText(Item, 'number'), 'The In Maintenance equipment should match the filter');
        Assert.AreEqual('In_x0020_Maintenance', GetText(Item, 'status'), 'A space in an enum value should be encoded as _x0020_');

        CleanUp();
    end;

    [Test]
    procedure PostCreatesEquipmentWithSeriesNumberAndAvailableStatus()
    var
        Equipment: Record "EQM Equipment";
        Body: JsonObject;
        Response: Text;
        Item: JsonObject;
    begin
        // [SCENARIO 3] POST with description and category creates equipment with a series number and status Available
        Initialize();

        // [GIVEN] The setup with an active category and a number series
        Body.Add('description', NewDescriptionTok);
        Body.Add('categoryCode', ActiveCategoryTok);

        // [WHEN] POST equipments
        Response := ApiPost(GetBaseUrl(), Body);

        // [THEN] The response contains the created entity and the record exists with the first number of the series
        Assert.IsTrue(Item.ReadFrom(Response), 'The response should be a JSON object');
        Assert.AreEqual('Available', GetText(Item, 'status'), 'New equipment should be Available');
        Equipment.SetRange(Description, NewDescriptionTok);
        Assert.RecordCount(Equipment, 1);
        Equipment.FindFirst();
        Assert.AreEqual(SeriesStartTok, Equipment."No.", 'The number should come from the number series');
        Assert.AreEqual(Equipment.Status::Available, Equipment.Status, 'The stored status should be Available');
        Assert.AreEqual(Equipment."No.", GetText(Item, 'number'), 'The response should carry the new number');

        CleanUp();
    end;

    [Test]
    procedure PostWithAssignedOrDisposedStatusIsRejected()
    var
        Equipment: Record "EQM Equipment";
        Body: JsonObject;
    begin
        // [SCENARIO 4] (negative) New equipment cannot start as Assigned or Disposed
        Initialize();

        // [GIVEN] A body with description, category and status Assigned
        Body := NewBody(NegativeDescriptionTok, ActiveCategoryTok);
        Body.Add('status', 'Assigned');

        // [WHEN] POST equipments
        asserterror ApiPost(GetBaseUrl(), Body);

        // [THEN] The assigned-on-creation error is returned and no record exists
        AssertLastErrorContains(StrSubstNo(NewEquipmentAssignedErr, 'Assigned'));
        Equipment.SetRange(Description, NegativeDescriptionTok);
        Assert.RecordIsEmpty(Equipment);

        // [GIVEN] The same body with status Disposed
        Clear(Body);
        Body := NewBody(NegativeDescriptionTok, ActiveCategoryTok);
        Body.Add('status', 'Disposed');

        // [WHEN] POST equipments
        asserterror ApiPost(GetBaseUrl(), Body);

        // [THEN] The final-status-on-creation error is returned and no record exists
        AssertLastErrorContains(StrSubstNo(NewEquipmentFinalStatusErr, 'Disposed'));
        Assert.RecordIsEmpty(Equipment);

        CleanUp();
    end;

    [Test]
    procedure PostWithInactiveCategoryIsRejected()
    var
        Equipment: Record "EQM Equipment";
    begin
        // [SCENARIO 5a] (negative) POST with an inactive category is rejected
        Initialize();

        // [GIVEN] An inactive category (created in Initialize)
        // [WHEN] POST equipments with that category
        asserterror ApiPost(GetBaseUrl(), NewBody(NegativeDescriptionTok, InactiveCategoryTok));

        // [THEN] CategoryInactiveErr is returned and no record exists
        AssertLastErrorContains(StrSubstNo(CategoryInactiveErr, InactiveCategoryTok));
        Equipment.SetRange(Description, NegativeDescriptionTok);
        Assert.RecordIsEmpty(Equipment);

        CleanUp();
    end;

    [Test]
    procedure PostWithoutCategoryIsRejected()
    var
        Equipment: Record "EQM Equipment";
        Body: JsonObject;
    begin
        // [SCENARIO 5b] (negative) POST without a category is rejected
        Initialize();

        // [GIVEN] A body with a description only
        Body.Add('description', NegativeDescriptionTok);

        // [WHEN] POST equipments
        asserterror ApiPost(GetBaseUrl(), Body);

        // [THEN] The category is required (TestField error names the field) and no record exists
        AssertLastErrorContains(CategoryCodeCaptionTxt);
        Equipment.SetRange(Description, NegativeDescriptionTok);
        Assert.RecordIsEmpty(Equipment);

        CleanUp();
    end;

    [Test]
    procedure PostWithUsedSerialNumberIsRejected()
    var
        Equipment: Record "EQM Equipment";
        Body: JsonObject;
    begin
        // [SCENARIO 6] (negative) POST with a serial number that another equipment already has
        Initialize();

        // [GIVEN] Equipment E with serial S1
        CreateEquipment(Equipment, EquipmentNoTok);
        Equipment."Serial No." := SerialTok;
        Equipment.Modify(true);
        Commit();
        Body := NewBody(NegativeDescriptionTok, ActiveCategoryTok);
        Body.Add('serialNumber', SerialTok);

        // [WHEN] POST another equipment with S1
        asserterror ApiPost(GetBaseUrl(), Body);

        // [THEN] SerialNoAlreadyUsedErr is returned and no second record exists
        AssertLastErrorContains(StrSubstNo(SerialNoAlreadyUsedErr, SerialTok, EquipmentNoTok));
        Equipment.Reset();
        Equipment.SetRange("Serial No.", SerialTok);
        Assert.RecordCount(Equipment, 1);

        CleanUp();
    end;

    [Test]
    procedure PatchDescriptionIsSaved()
    var
        Equipment: Record "EQM Equipment";
        Body: JsonObject;
        Response: Text;
    begin
        // [SCENARIO 7a] PATCH description saves the new value
        Initialize();

        // [GIVEN] Saved equipment E
        CreateEquipment(Equipment, EquipmentNoTok);
        Commit();
        Body.Add('description', UpdatedDescriptionTok);

        // [WHEN] PATCH equipments({id})
        Response := ApiPatch(GetEntityUrl(Equipment.SystemId), Body);

        // [THEN] The description is stored
        Equipment.Get(EquipmentNoTok);
        Assert.AreEqual(UpdatedDescriptionTok, Equipment.Description, 'The description should be saved');

        CleanUp();
    end;

    [Test]
    procedure PatchWarrantyEndBeforeStartIsRejected()
    var
        Equipment: Record "EQM Equipment";
        Body: JsonObject;
    begin
        // [SCENARIO 7b] (negative) PATCH of a warranty end date before the start date is rejected and nothing changes
        Initialize();

        // [GIVEN] Equipment E with warranty start 2025-06-01 and no end date
        CreateEquipment(Equipment, EquipmentNoTok);
        Equipment."Warranty Start Date" := DMY2Date(1, 6, 2025);
        Equipment.Modify(true);
        Commit();
        Body.Add('warrantyEndDate', '2025-01-01');

        // [WHEN] PATCH warrantyEndDate to 2025-01-01
        asserterror ApiPatch(GetEntityUrl(Equipment.SystemId), Body);

        // [THEN] The warranty end date error is returned and the end date is still empty
        AssertLastErrorContains(WarrantyEndDateFragmentTxt);
        Equipment.Get(EquipmentNoTok);
        Assert.AreEqual(0D, Equipment."Warranty End Date", 'The end date should not be saved');

        CleanUp();
    end;

    [Test]
    procedure PatchStatusDisposedAppliesWithoutConfirmAndIsFinal()
    var
        Equipment: Record "EQM Equipment";
        Body: JsonObject;
        Response: Text;
    begin
        // [SCENARIO 8] PATCH status Disposed is applied without a confirmation; a further change is rejected
        Initialize();

        // [GIVEN] Saved Available equipment E
        CreateEquipment(Equipment, EquipmentNoTok);
        Commit();
        Body.Add('status', 'Disposed');

        // [WHEN] PATCH status Disposed
        Response := ApiPatch(GetEntityUrl(Equipment.SystemId), Body);

        // [THEN] E is Disposed (the confirm defaults to Yes without a UI session)
        Equipment.Get(EquipmentNoTok);
        Assert.AreEqual(Equipment.Status::Disposed, Equipment.Status, 'Status should be Disposed');

        // [WHEN] PATCH status Available afterwards
        Clear(Body);
        Body.Add('status', 'Available');
        asserterror ApiPatch(GetEntityUrl(Equipment.SystemId), Body);

        // [THEN] StatusIsFinalErr is returned and E stays Disposed
        AssertLastErrorContains(StrSubstNo(StatusIsFinalErr, EquipmentNoTok, 'Disposed', 'Available'));
        Equipment.Get(EquipmentNoTok);
        Assert.AreEqual(Equipment.Status::Disposed, Equipment.Status, 'A final status should not change');

        CleanUp();
    end;

    [Test]
    procedure PatchStatusLostClearsEmployeeAndClosesAssignment()
    var
        Equipment: Record "EQM Equipment";
        EquipmentAssignment: Record "EQM Equipment Assignment";
        Body: JsonObject;
        Response: Text;
    begin
        // [SCENARIO 9] PATCH status Lost on assigned equipment clears the employee and closes the active entry
        Initialize();

        // [GIVEN] Equipment E assigned to EMP1 (one Active entry)
        CreateAssignedEquipment(Equipment, EquipmentNoTok);
        Commit();
        Body.Add('status', 'Lost');

        // [WHEN] PATCH status Lost
        Response := ApiPatch(GetEntityUrl(Equipment.SystemId), Body);

        // [THEN] E is Lost without an employee, the entry is Closed and no entry is Active
        Equipment.Get(EquipmentNoTok);
        Assert.AreEqual(Equipment.Status::Lost, Equipment.Status, 'Status should be Lost');
        Assert.AreEqual('', Equipment."Assigned Employee No.", 'The employee should be cleared');
        FilterAssignments(EquipmentAssignment, EquipmentNoTok, EquipmentAssignment.Status::Closed);
        Assert.RecordCount(EquipmentAssignment, 1);
        FilterAssignments(EquipmentAssignment, EquipmentNoTok, EquipmentAssignment.Status::Active);
        Assert.RecordIsEmpty(EquipmentAssignment);

        CleanUp();
    end;

    [Test]
    procedure PatchAssignedEquipmentToAvailableIsRejected()
    var
        Equipment: Record "EQM Equipment";
        Body: JsonObject;
    begin
        // [SCENARIO 10] (negative) PATCH status Available on assigned equipment must use the return action
        Initialize();

        // [GIVEN] Equipment E assigned to EMP1
        CreateAssignedEquipment(Equipment, EquipmentNoTok);
        Commit();
        Body.Add('status', 'Available');

        // [WHEN] PATCH status Available
        asserterror ApiPatch(GetEntityUrl(Equipment.SystemId), Body);

        // [THEN] UseReturnActionErr is returned and E is still assigned
        AssertLastErrorContains(StrSubstNo(UseReturnActionErr, EquipmentNoTok));
        Equipment.Get(EquipmentNoTok);
        Assert.AreEqual(Equipment.Status::Assigned, Equipment.Status, 'E should still be Assigned');
        Assert.AreEqual(ActiveEmployeeTok, Equipment."Assigned Employee No.", 'The employee should be kept');

        CleanUp();
    end;

    [Test]
    procedure PatchStatusAssignedIsRejectedWithEmployeeRequiredError()
    var
        Equipment: Record "EQM Equipment";
        Body: JsonObject;
    begin
        // [SCENARIO 10b] (negative) PATCH status Assigned on Available equipment fails: no employee can be set through PATCH
        // Observation for the plan: the error text tells the caller to use the Assign to Employee action on the
        // equipment card, which an API client does not have (it should use the assign bound action).
        Initialize();

        // [GIVEN] Available equipment E
        CreateEquipment(Equipment, EquipmentNoTok);
        Commit();
        Body.Add('status', 'Assigned');

        // [WHEN] PATCH status Assigned
        asserterror ApiPatch(GetEntityUrl(Equipment.SystemId), Body);

        // [THEN] AssignedEmployeeRequiredErr is returned and E is still Available without an employee or entry
        AssertLastErrorContains(StrSubstNo(AssignedEmployeeRequiredErr, Equipment.FieldCaption("Assigned Employee No."), EquipmentNoTok, 'Assigned'));
        Equipment.Get(EquipmentNoTok);
        Assert.AreEqual(Equipment.Status::Available, Equipment.Status, 'E should still be Available');
        Assert.AreEqual('', Equipment."Assigned Employee No.", 'No employee should be set');

        CleanUp();
    end;

    [Test]
    procedure PatchAssignedEmployeeNumberDoesNotAssign()
    var
        Equipment: Record "EQM Equipment";
        Body: JsonObject;
        RequestSucceeded: Boolean;
    begin
        // [SCENARIO 11] (negative) assignedEmployeeNumber is read-only: PATCH fails or is ignored, the employee stays blank
        // The plan asks to record which of the two happens. The test accepts both and asserts the state; the
        // outcome (ignored or error) is held in RequestSucceeded and should be reported from the first real run.
        Initialize();

        // [GIVEN] Available equipment E
        CreateEquipment(Equipment, EquipmentNoTok);
        Commit();
        Body.Add('assignedEmployeeNumber', ActiveEmployeeTok);

        // [WHEN] PATCH assignedEmployeeNumber
        RequestSucceeded := TryApiPatch(GetEntityUrl(Equipment.SystemId), Body);

        // [THEN] E is still Available, has no employee and no assignment entry
        Equipment.Get(EquipmentNoTok);
        Assert.AreEqual('', Equipment."Assigned Employee No.", 'The employee should stay blank (request succeeded: ' + Format(RequestSucceeded) + ')');
        Assert.AreEqual(Equipment.Status::Available, Equipment.Status, 'The status should stay Available');
        Assert.AreEqual(0, CountAssignments(EquipmentNoTok), 'No assignment entry should be created');

        CleanUp();
    end;

    [Test]
    procedure AssignActionAssignsEquipmentToEmployee()
    var
        Equipment: Record "EQM Equipment";
        EquipmentAssignment: Record "EQM Equipment Assignment";
        Body: JsonObject;
        Response: Text;
    begin
        // [SCENARIO 12] The assign action sets status Assigned, the employee and one Active entry
        Initialize();

        // [GIVEN] Available equipment E and active employee EMP1
        CreateEquipment(Equipment, EquipmentNoTok);
        Commit();
        Body.Add('employeeNumber', ActiveEmployeeTok);

        // [WHEN] POST equipments({id})/Microsoft.NAV.assign
        Response := ApiPost(StrSubstNo(ActionUrlTok, GetEntityUrl(Equipment.SystemId), 'assign'), Body);

        // [THEN] E is Assigned to EMP1 with exactly one Active entry for EMP1
        Equipment.Get(EquipmentNoTok);
        Assert.AreEqual(Equipment.Status::Assigned, Equipment.Status, 'Status should be Assigned');
        Assert.AreEqual(ActiveEmployeeTok, Equipment."Assigned Employee No.", 'The employee should be EMP1');
        FilterAssignments(EquipmentAssignment, EquipmentNoTok, EquipmentAssignment.Status::Active);
        Assert.RecordCount(EquipmentAssignment, 1);
        EquipmentAssignment.FindFirst();
        Assert.AreEqual(ActiveEmployeeTok, EquipmentAssignment."Employee No.", 'The entry should be for EMP1');

        CleanUp();
    end;

    [Test]
    procedure AssignActionRejectsInactiveEmployee()
    var
        Equipment: Record "EQM Equipment";
        Employee: Record Employee;
        Body: JsonObject;
    begin
        // [SCENARIO 13a] (negative) assign with an inactive employee is rejected
        Initialize();

        // [GIVEN] Available equipment E and inactive employee EMP2
        CreateEquipment(Equipment, EquipmentNoTok);
        Commit();
        Body.Add('employeeNumber', InactiveEmployeeTok);

        // [WHEN] The assign action is called with EMP2
        asserterror ApiPost(StrSubstNo(ActionUrlTok, GetEntityUrl(Equipment.SystemId), 'assign'), Body);

        // [THEN] EmployeeNotActiveErr is returned and E stays Available
        AssertLastErrorContains(StrSubstNo(EmployeeNotActiveErr, InactiveEmployeeTok, Format(Employee.Status::Inactive)));
        Equipment.Get(EquipmentNoTok);
        Assert.AreEqual(Equipment.Status::Available, Equipment.Status, 'E should stay Available');
        Assert.AreEqual(0, CountAssignments(EquipmentNoTok), 'No assignment entry should be created');

        CleanUp();
    end;

    [Test]
    procedure AssignActionRejectsLostEquipment()
    var
        Equipment: Record "EQM Equipment";
        Body: JsonObject;
    begin
        // [SCENARIO 13b] (negative) assign on Lost equipment is rejected
        Initialize();

        // [GIVEN] Lost equipment E (set on the table: Available to Lost needs no confirmation)
        CreateEquipment(Equipment, EquipmentNoTok);
        Equipment.Status := Equipment.Status::Lost;
        Equipment.Modify(true);
        Commit();
        Body.Add('employeeNumber', ActiveEmployeeTok);

        // [WHEN] The assign action is called
        asserterror ApiPost(StrSubstNo(ActionUrlTok, GetEntityUrl(Equipment.SystemId), 'assign'), Body);

        // [THEN] CannotAssignFinalStatusErr is returned
        AssertLastErrorContains(StrSubstNo(CannotAssignFinalStatusErr, EquipmentNoTok, 'Lost'));
        Assert.AreEqual(0, CountAssignments(EquipmentNoTok), 'No assignment entry should be created');

        CleanUp();
    end;

    [Test]
    procedure AssignActionRejectsAlreadyAssignedEquipment()
    var
        Equipment: Record "EQM Equipment";
        Body: JsonObject;
    begin
        // [SCENARIO 13c] (negative) assign on equipment that is already assigned is rejected
        Initialize();

        // [GIVEN] Equipment E assigned to EMP1
        CreateAssignedEquipment(Equipment, EquipmentNoTok);
        Commit();
        Body.Add('employeeNumber', ActiveEmployeeTok);

        // [WHEN] The assign action is called again
        asserterror ApiPost(StrSubstNo(ActionUrlTok, GetEntityUrl(Equipment.SystemId), 'assign'), Body);

        // [THEN] AlreadyAssignedErr is returned and only the first entry exists
        AssertLastErrorContains(StrSubstNo(AlreadyAssignedErr, EquipmentNoTok, ActiveEmployeeTok));
        Assert.AreEqual(1, CountAssignments(EquipmentNoTok), 'No second assignment entry should be created');

        CleanUp();
    end;

    [Test]
    procedure ReturnActionMakesEquipmentAvailableAndClosesEntry()
    var
        Equipment: Record "EQM Equipment";
        EquipmentAssignment: Record "EQM Equipment Assignment";
        Body: JsonObject;
        Response: Text;
    begin
        // [SCENARIO 14a] The returnEquipment action makes assigned equipment Available and closes the entry
        Initialize();

        // [GIVEN] Equipment E assigned to EMP1
        CreateAssignedEquipment(Equipment, EquipmentNoTok);
        Commit();

        // [WHEN] POST equipments({id})/Microsoft.NAV.returnEquipment (empty body)
        Response := ApiPost(StrSubstNo(ActionUrlTok, GetEntityUrl(Equipment.SystemId), 'returnEquipment'), Body);

        // [THEN] E is Available without employee, its entry is Closed and none is Active
        Equipment.Get(EquipmentNoTok);
        Assert.AreEqual(Equipment.Status::Available, Equipment.Status, 'Status should be Available');
        Assert.AreEqual('', Equipment."Assigned Employee No.", 'The employee should be cleared');
        FilterAssignments(EquipmentAssignment, EquipmentNoTok, EquipmentAssignment.Status::Closed);
        Assert.RecordCount(EquipmentAssignment, 1);
        FilterAssignments(EquipmentAssignment, EquipmentNoTok, EquipmentAssignment.Status::Active);
        Assert.RecordIsEmpty(EquipmentAssignment);

        CleanUp();
    end;

    [Test]
    procedure ReturnActionRejectsEquipmentThatIsNotAssigned()
    var
        Equipment: Record "EQM Equipment";
        Body: JsonObject;
    begin
        // [SCENARIO 14b] (negative) returnEquipment on Available equipment is rejected
        Initialize();

        // [GIVEN] Available equipment E
        CreateEquipment(Equipment, EquipmentNoTok);
        Commit();

        // [WHEN] The returnEquipment action is called
        asserterror ApiPost(StrSubstNo(ActionUrlTok, GetEntityUrl(Equipment.SystemId), 'returnEquipment'), Body);

        // [THEN] NotAssignedErr is returned
        AssertLastErrorContains(StrSubstNo(NotAssignedErr, EquipmentNoTok, 'Available'));

        CleanUp();
    end;

    [Test]
    procedure DeleteRemovesEquipmentWithoutHistory()
    var
        Equipment: Record "EQM Equipment";
        EquipmentId: Guid;
        Response: Text;
    begin
        // [SCENARIO 15a] DELETE removes equipment that was never assigned
        Initialize();

        // [GIVEN] Saved equipment E without history
        CreateEquipment(Equipment, EquipmentNoTok);
        EquipmentId := Equipment.SystemId;
        Commit();

        // [WHEN] DELETE equipments({id})
        Response := ApiDelete(GetEntityUrl(EquipmentId));

        // [THEN] E no longer exists
        Assert.IsFalse(Equipment.Get(EquipmentNoTok), 'The equipment should be deleted');

        CleanUp();
    end;

    [Test]
    procedure DeleteIsRejectedForEquipmentWithAssignmentHistory()
    var
        Equipment: Record "EQM Equipment";
        EquipmentAssignment: Record "EQM Equipment Assignment";
    begin
        // [SCENARIO 15b] (negative) DELETE of equipment with assignment history is rejected
        Initialize();

        // [GIVEN] Available equipment E with one Closed assignment entry
        // The entry is inserted directly: returning through the table would ask for a confirmation in the test session.
        CreateEquipment(Equipment, EquipmentNoTok);
        EquipmentAssignment.Init();
        EquipmentAssignment."Equipment No." := EquipmentNoTok;
        EquipmentAssignment."Employee No." := ActiveEmployeeTok;
        EquipmentAssignment.Status := EquipmentAssignment.Status::Closed;
        EquipmentAssignment.Insert(false);
        Commit();

        // [WHEN] DELETE equipments({id})
        asserterror ApiDelete(GetEntityUrl(Equipment.SystemId));

        // [THEN] DeleteHistoryExistsErr is returned and E still exists
        AssertLastErrorContains(StrSubstNo(DeleteHistoryExistsErr, EquipmentNoTok, 'Disposed'));
        Assert.IsTrue(Equipment.Get(EquipmentNoTok), 'The equipment should still exist');

        CleanUp();
    end;

    [Test]
    procedure DeleteIsRejectedForAssignedEquipment()
    var
        Equipment: Record "EQM Equipment";
    begin
        // [SCENARIO 15c] (negative) DELETE of assigned equipment is rejected
        Initialize();

        // [GIVEN] Equipment E assigned to EMP1
        CreateAssignedEquipment(Equipment, EquipmentNoTok);
        Commit();

        // [WHEN] DELETE equipments({id})
        asserterror ApiDelete(GetEntityUrl(Equipment.SystemId));

        // [THEN] DeleteAssignedErr is returned and E still exists
        AssertLastErrorContains(StrSubstNo(DeleteAssignedErr, EquipmentNoTok, ActiveEmployeeTok));
        Assert.IsTrue(Equipment.Get(EquipmentNoTok), 'The equipment should still exist');

        CleanUp();
    end;

    [Test]
    procedure PostWithExplicitNumberIsRejectedWhenSeriesIsNotManual()
    var
        Equipment: Record "EQM Equipment";
        Body: JsonObject;
    begin
        // [SCENARIO 16] (negative) POST with an explicit number is rejected while the series does not allow manual numbers
        Initialize();

        // [GIVEN] The Equipment Nos. series has Manual Nos. = false (created in Initialize), and a body with a number
        Body := NewBody(NegativeDescriptionTok, ActiveCategoryTok);
        Body.Add('number', ManualNoTok);

        // [WHEN] POST equipments
        // The text of the standard TestManual error is not copied here (it belongs to the base app); the test
        // checks that the request fails and that no record is created.
        asserterror ApiPost(GetBaseUrl(), Body);

        // [THEN] The request failed and no equipment with the manual number exists
        Assert.AreNotEqual('', GetLastErrorText(), 'The request should fail with an error');
        Assert.IsFalse(Equipment.Get(ManualNoTok), 'No equipment should be created with a manual number');

        CleanUp();
    end;

    // Scenario 17 (permissions: Reader GET ok / PATCH denied, Manager DELETE denied, Administrator all) is not
    // automated. The permissions mock is unreliable (FR-023), so it is checked manually in the sandbox.

    local procedure Initialize()
    var
        EquipmentSetup: Record "EQM Equipment Setup";
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        // Remove leftovers of an earlier failed run, then build the data. Commit is needed because the API runs in another session.
        DeleteTestData();

        if not SetupSaved then begin
            if EquipmentSetup.Get() then;
            OriginalEquipmentNos := EquipmentSetup."Equipment Nos.";
            SetupSaved := true;
        end;

        LibraryUtility.CreateNoSeries(NoSeries, true, false, false);
        TestNoSeriesCode := NoSeries.Code;
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, TestNoSeriesCode, SeriesStartTok, SeriesEndTok);

        if not EquipmentSetup.Get() then begin
            EquipmentSetup.Init();
            EquipmentSetup.Insert();
        end;
        EquipmentSetup."Equipment Nos." := TestNoSeriesCode;
        EquipmentSetup.Modify();

        InsertCategory(ActiveCategoryTok, true);
        InsertCategory(InactiveCategoryTok, false);
        InsertEmployee(ActiveEmployeeTok, "Employee Status"::Active);
        InsertEmployee(InactiveEmployeeTok, "Employee Status"::Inactive);
        Commit();
    end;

    local procedure CleanUp()
    var
        EquipmentSetup: Record "EQM Equipment Setup";
        NoSeries: Record "No. Series";
    begin
        DeleteTestData();

        if NoSeries.Get(TestNoSeriesCode) then
            NoSeries.Delete(true);
        TestNoSeriesCode := '';

        if SetupSaved then
            if EquipmentSetup.Get() then begin
                EquipmentSetup."Equipment Nos." := OriginalEquipmentNos;
                EquipmentSetup.Modify();
            end;
        Commit();
    end;

    local procedure DeleteTestData()
    var
        Equipment: Record "EQM Equipment";
        EquipmentAssignment: Record "EQM Equipment Assignment";
        Category: Record "EQM Equipment Category";
        Employee: Record Employee;
        NoSeries: Record "No. Series";
    begin
        // Direct deletes without triggers: the delete rules (history, assigned) must not block the cleanup.
        EquipmentAssignment.SetFilter("Equipment No.", TestPrefixTok);
        EquipmentAssignment.DeleteAll(false);
        Equipment.SetFilter("No.", TestPrefixTok);
        Equipment.DeleteAll(false);
        Category.SetFilter(Code, CategoryPrefixTok);
        Category.DeleteAll(false);
        Employee.SetFilter("No.", EmployeePrefixTok);
        Employee.DeleteAll(false);
        if TestNoSeriesCode <> '' then
            if NoSeries.Get(TestNoSeriesCode) then
                NoSeries.Delete(true);
    end;

    local procedure InsertCategory(CategoryCode: Code[20]; IsActive: Boolean)
    var
        Category: Record "EQM Equipment Category";
    begin
        Category.Init();
        Category.Code := CategoryCode;
        Category.Active := IsActive;
        Category.Insert();
    end;

    local procedure InsertEmployee(EmployeeNo: Code[20]; EmployeeStatus: Enum "Employee Status")
    var
        Employee: Record Employee;
    begin
        Employee.Init();
        Employee."No." := EmployeeNo;
        Employee."First Name" := 'API';
        Employee."Last Name" := EmployeeNo;
        Employee.Status := EmployeeStatus;
        Employee.Insert();
    end;

    local procedure CreateEquipment(var Equipment: Record "EQM Equipment"; EquipmentNo: Code[20])
    begin
        Equipment.Init();
        Equipment."No." := EquipmentNo;
        Equipment.Description := 'EQMAPI test equipment';
        Equipment."Category Code" := ActiveCategoryTok;
        Equipment.Insert(true);
    end;

    local procedure CreateAssignedEquipment(var Equipment: Record "EQM Equipment"; EquipmentNo: Code[20])
    begin
        // Uses the real procedure so that the Active assignment entry exists (no confirmation is asked when assigning).
        CreateEquipment(Equipment, EquipmentNo);
        Equipment.AssignEmployee(ActiveEmployeeTok);
    end;

    local procedure FilterAssignments(var EquipmentAssignment: Record "EQM Equipment Assignment"; EquipmentNo: Code[20]; AssignmentStatus: Enum "EQM Assignment Status")
    begin
        EquipmentAssignment.Reset();
        EquipmentAssignment.SetRange("Equipment No.", EquipmentNo);
        EquipmentAssignment.SetRange(Status, AssignmentStatus);
    end;

    local procedure CountAssignments(EquipmentNo: Code[20]): Integer
    var
        EquipmentAssignment: Record "EQM Equipment Assignment";
    begin
        EquipmentAssignment.SetRange("Equipment No.", EquipmentNo);
        exit(EquipmentAssignment.Count());
    end;

    local procedure NewBody(Description: Text; CategoryCode: Text) Body: JsonObject
    begin
        Body.Add('description', Description);
        Body.Add('categoryCode', CategoryCode);
    end;

    local procedure AssertLastErrorContains(ExpectedText: Text)
    begin
        // The HTTP helper can wrap the server message, so compare with a substring instead of ExpectedError.
        Assert.IsTrue(StrPos(GetLastErrorText(), ExpectedText) > 0, 'The error should contain: ' + ExpectedText + '. Actual: ' + GetLastErrorText());
    end;

    local procedure GetFirstValueItem(Response: Text) Item: JsonObject
    var
        Root: JsonObject;
        ValueToken: JsonToken;
        ItemToken: JsonToken;
    begin
        Assert.IsTrue(Root.ReadFrom(Response), 'The response should be a JSON object');
        Assert.IsTrue(Root.Get('value', ValueToken), 'The response should contain a value collection');
        Assert.AreEqual(1, ValueToken.AsArray().Count(), 'The filter should return exactly one entity');
        ValueToken.AsArray().Get(0, ItemToken);
        Item := ItemToken.AsObject();
    end;

    local procedure GetText(Item: JsonObject; PropertyName: Text): Text
    var
        PropertyToken: JsonToken;
    begin
        Assert.IsTrue(Item.Get(PropertyName, PropertyToken), 'The response should contain the property ' + PropertyName);
        exit(PropertyToken.AsValue().AsText());
    end;

    // The HTTP layer. Only these helpers talk to "Library - Graph Mgt"; if a signature differs in BC 29, fix it here.

    local procedure GetBaseUrl(): Text
    begin
        exit(GetUrl(ClientType::Api, CompanyName(), ObjectType::Page, Page::"EQM Equipment API"));
    end;

    local procedure GetEntityUrl(EquipmentId: Guid): Text
    begin
        exit(GetBaseUrl() + '(' + LowerCase(Format(EquipmentId, 0, 4)) + ')');
    end;

    local procedure ApiGet(Url: Text) Response: Text
    begin
        LibraryGraphMgt.GetFromWebService(Response, Url);
    end;

    local procedure ApiPost(Url: Text; Body: JsonObject) Response: Text
    var
        RequestBody: Text;
    begin
        Body.WriteTo(RequestBody);
        LibraryGraphMgt.PostToWebService(Url, RequestBody, Response);
    end;

    local procedure ApiPatch(Url: Text; Body: JsonObject) Response: Text
    var
        RequestBody: Text;
    begin
        Body.WriteTo(RequestBody);
        LibraryGraphMgt.PatchToWebService(Url, RequestBody, Response);
    end;

    local procedure ApiDelete(Url: Text) Response: Text
    begin
        LibraryGraphMgt.DeleteFromWebService(Url, '', Response);
    end;

    [TryFunction]
    local procedure TryApiPatch(Url: Text; Body: JsonObject)
    begin
        ApiPatch(Url, Body);
    end;
}
