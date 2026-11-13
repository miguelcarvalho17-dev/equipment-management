namespace MiguelCarvalho.EquipmentManagement.Tests;

using Microsoft.HumanResources.Employee;
using MiguelCarvalho.EquipmentManagement;
using System.TestLibraries.Utilities;

/// <summary>
/// Tests for the read-only assignment history API page 50125 (FR-028). The page has no logic of its own: it exposes
/// table 50103 "EQM Equipment Assignment" (id = SystemId, entryNumber, equipmentNumber, employeeNumber, assignmentDate,
/// status, closingDate, lastModifiedDateTime = SystemModifiedAt). These tests run the table-level equivalents of the
/// requests: the filters equipmentNumber eq and status eq, assignments({id}), the stability of the id and the
/// immutability of closed entries. The history is built through AssignEmployee and UnassignEmployee on table 50100.
/// Real HTTP calls cannot be authenticated in the CI container (see FR-026), so scenarios 6 to 11 (GET list and by id,
/// 404, filters, rejected writes, equipment lookup, permissions) are verified manually in the sandbox.
/// A failed statement (asserterror) rolls back the whole test transaction, so each test that expects an error has
/// exactly one asserterror, as its last action, and only checks the error text afterwards.
/// </summary>
codeunit 50182 "EQM Assignment API Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        EquipmentNoTok: Label 'EQMASG-E', Locked = true;
        CategoryTok: Label 'EQMASG-CAT', Locked = true;
        EmployeeTok: Label 'EQMASG-E1', Locked = true;
        OtherEmployeeTok: Label 'EQMASG-E2', Locked = true;
        UnknownIdTok: Label '{00000000-0000-0000-0000-000000000001}', Locked = true;
        // Copy of the text of the label in table 50103; labels of another app are not accessible.
        ClosedEntryCannotBeChangedErr: Label 'You cannot change assignment entry %1 for equipment %2 because the assignment is closed. Closed assignments are kept as history and cannot be changed.', Comment = '%1 = entry number, %2 = equipment number';

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('ConfirmHandler')]
    procedure EquipmentFilterReturnsClosedAndActiveEntries()
    var
        Assignment: Record "EQM Equipment Assignment";
    begin
        // [SCENARIO 1] The filter equipmentNumber eq returns exactly the closed entry A1 and the active entry A2
        Initialize();

        // [GIVEN] Equipment E assigned to E1, returned (A1 Closed) and assigned again (A2 Active) (Initialize)

        // [WHEN] The entries are read for E's number
        Assignment.SetRange("Equipment No.", EquipmentNoTok);

        // [THEN] Exactly 2 entries are returned
        Assert.RecordCount(Assignment, 2);

        // [THEN] A1 is Closed with Closing Date filled, Employee No. E1 and Assignment Date filled
        Assignment.FindFirst();
        Assert.AreEqual(Assignment.Status::Closed, Assignment.Status, 'A1 should be Closed');
        Assert.AreNotEqual(0D, Assignment."Closing Date", 'A1 should have a closing date');
        Assert.AreEqual(EmployeeTok, Assignment."Employee No.", 'A1 employee should be E1');
        Assert.AreNotEqual(0D, Assignment."Assignment Date", 'A1 should have an assignment date');

        // [THEN] A2 is Active with Closing Date blank, Employee No. E1 and Assignment Date filled
        Assignment.FindLast();
        Assert.AreEqual(Assignment.Status::Active, Assignment.Status, 'A2 should be Active');
        Assert.AreEqual(0D, Assignment."Closing Date", 'A2 should have no closing date');
        Assert.AreEqual(EmployeeTok, Assignment."Employee No.", 'A2 employee should be E1');
        Assert.AreNotEqual(0D, Assignment."Assignment Date", 'A2 should have an assignment date');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('ConfirmHandler')]
    procedure EquipmentFilterExcludesOtherEquipment()
    var
        Assignment: Record "EQM Equipment Assignment";
    begin
        // [SCENARIO 1b] (boundary) The equipment filter does not return entries of another equipment
        Initialize();

        // [GIVEN] Equipment E with 2 entries (Initialize)

        // [WHEN] The entries are read for a number that has no equipment
        Assignment.SetRange("Equipment No.", OtherEmployeeTok);

        // [THEN] Nothing is returned
        Assert.RecordIsEmpty(Assignment);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('ConfirmHandler')]
    procedure StatusFilterSeparatesClosedAndActive()
    var
        Assignment: Record "EQM Equipment Assignment";
        ClosedEntryNo: Integer;
    begin
        // [SCENARIO 2] The filter status eq 'Closed' returns only A1, and status eq 'Active' only A2
        Initialize();

        // [GIVEN] Closed entry A1 and active entry A2 for E (Initialize)
        Assignment.SetRange("Equipment No.", EquipmentNoTok);
        Assignment.SetRange(Status, Assignment.Status::Closed);

        // [WHEN] The entries are read with Status = Closed
        // [THEN] Only A1 is returned
        Assert.RecordCount(Assignment, 1);
        Assignment.FindFirst();
        ClosedEntryNo := Assignment."Entry No.";

        // [WHEN] The entries are read with Status = Active
        Assignment.SetRange(Status, Assignment.Status::Active);

        // [THEN] Only A2 is returned, and it is a different entry than A1
        Assert.RecordCount(Assignment, 1);
        Assignment.FindFirst();
        Assert.AreNotEqual(ClosedEntryNo, Assignment."Entry No.", 'The active entry should differ from the closed entry');
        Assert.IsTrue(Assignment."Entry No." > ClosedEntryNo, 'The active entry should be newer than the closed entry');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('ConfirmHandler')]
    procedure EntryIsFoundBySystemId()
    var
        Assignment: Record "EQM Equipment Assignment";
        ById: Record "EQM Equipment Assignment";
    begin
        // [SCENARIO 3] assignments({id}) equivalent: A1 is read by its SystemId and the fields match
        Initialize();

        // [GIVEN] Closed entry A1
        FindEntry(Assignment, Assignment.Status::Closed);

        // [WHEN] It is read by its SystemId
        Assert.IsTrue(ById.GetBySystemId(Assignment.SystemId), 'The entry should be found by its SystemId');

        // [THEN] Entry No., Equipment No., Employee No. and Status match
        Assert.AreEqual(Assignment."Entry No.", ById."Entry No.", 'Entry No. should match');
        Assert.AreEqual(EquipmentNoTok, ById."Equipment No.", 'Equipment No. should match');
        Assert.AreEqual(EmployeeTok, ById."Employee No.", 'Employee No. should match');
        Assert.AreEqual(ById.Status::Closed, ById.Status, 'Status should match');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('ConfirmHandler')]
    procedure UnknownSystemIdIsNotFound()
    var
        Assignment: Record "EQM Equipment Assignment";
        UnknownId: Guid;
    begin
        // [SCENARIO 3b] (negative) An unknown id finds nothing (the 404 case of assignments({id}))
        Initialize();

        // [GIVEN] A GUID that belongs to no entry
        Evaluate(UnknownId, UnknownIdTok);

        // [WHEN] It is read by that SystemId
        // [THEN] No entry is found
        Assert.IsFalse(Assignment.GetBySystemId(UnknownId), 'An unknown SystemId should not be found');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('ConfirmHandler')]
    procedure ReturnKeepsSystemIdAndClosesEntry()
    var
        Assignment: Record "EQM Equipment Assignment";
        Equipment: Record "EQM Equipment";
        IdBefore: Guid;
        EntryNoBefore: Integer;
        ModifiedBefore: DateTime;
    begin
        // [SCENARIO 4] Returning E keeps the SystemId of A2, closes it, and SystemModifiedAt does not go back
        Initialize();

        // [GIVEN] Active entry A2, its SystemId and SystemModifiedAt
        FindEntry(Assignment, Assignment.Status::Active);
        IdBefore := Assignment.SystemId;
        EntryNoBefore := Assignment."Entry No.";
        ModifiedBefore := Assignment.SystemModifiedAt;

        // [WHEN] E is returned
        Equipment.Get(EquipmentNoTok);
        Assert.IsTrue(Equipment.UnassignEmployee(), 'The return should succeed');

        // [THEN] A2 keeps its SystemId and entry number, is Closed and SystemModifiedAt is not earlier than before
        Assignment.Get(EntryNoBefore);
        Assert.AreEqual(IdBefore, Assignment.SystemId, 'The SystemId should not change');
        Assert.AreEqual(Assignment.Status::Closed, Assignment.Status, 'A2 should be Closed');
        Assert.IsTrue(Assignment.SystemModifiedAt >= ModifiedBefore, 'SystemModifiedAt should not be earlier than before');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('ConfirmHandler')]
    procedure ClosedEntryCannotBeModified()
    var
        Assignment: Record "EQM Equipment Assignment";
        EntryNo: Integer;
    begin
        // [SCENARIO 5] (negative) The employee of a closed entry cannot be modified, the history is immutable
        Initialize();

        // [GIVEN] Closed entry A1
        FindEntry(Assignment, Assignment.Status::Closed);
        EntryNo := Assignment."Entry No.";

        // [WHEN] Its Employee No. is changed and modified with triggers
        Assignment."Employee No." := OtherEmployeeTok;
        asserterror Assignment.Modify(true);

        // [THEN] The closed-entry error is raised
        Assert.ExpectedError(StrSubstNo(ClosedEntryCannotBeChangedErr, EntryNo, EquipmentNoTok));
    end;

    local procedure Initialize()
    var
        Category: Record "EQM Equipment Category";
        Employee: Record Employee;
        Equipment: Record "EQM Equipment";
    begin
        // Everything runs in the test transaction, which is rolled back (AutoRollback), so nothing is committed or cleaned up.
        Category.Init();
        Category.Code := CategoryTok;
        Category.Active := true;
        Category.Insert();

        Employee.Init();
        Employee."No." := EmployeeTok;
        Employee."First Name" := 'ASG';
        Employee."Last Name" := EmployeeTok;
        Employee.Status := Employee.Status::Active;
        Employee.Insert(false);

        Equipment.Init();
        Equipment."No." := EquipmentNoTok;
        Equipment.Description := 'EQMASG test equipment';
        Equipment."Category Code" := CategoryTok;
        Equipment.Insert(true);

        // A1: assigned and returned (Closed). A2: assigned again (Active).
        Equipment.AssignEmployee(EmployeeTok);
        Equipment.Get(EquipmentNoTok);
        Equipment.UnassignEmployee();
        Equipment.Get(EquipmentNoTok);
        Equipment.AssignEmployee(EmployeeTok);
    end;

    local procedure FindEntry(var Assignment: Record "EQM Equipment Assignment"; AssignmentStatus: Enum "EQM Assignment Status")
    begin
        Assignment.Reset();
        Assignment.SetRange("Equipment No.", EquipmentNoTok);
        Assignment.SetRange(Status, AssignmentStatus);
        Assignment.FindFirst();
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}
