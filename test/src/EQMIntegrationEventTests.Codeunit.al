namespace MiguelCarvalho.EquipmentManagement.Tests;

using Microsoft.HumanResources.Employee;
using MiguelCarvalho.EquipmentManagement;
using System.TestLibraries.Utilities;

/// <summary>
/// Tests for the integration event outbox (FR-030), scenarios 1 to 11. The outbox entries are written by the real
/// subscribers of the business events, so each test triggers the real business action and reads table 50110.
/// Scenario 12 (API calls, Reader permissions, scheduled warranty job) is verified manually in the sandbox.
/// A failed statement (asserterror) rolls back the whole test transaction, so each test that expects an error has
/// exactly one asserterror, as its last action.
/// </summary>
codeunit 50186 "EQM Integration Event Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        CategoryTok: Label 'EQMIEV-CAT', Locked = true;
        EmployeeTok: Label 'EQMIEV-E1', Locked = true;
        EquipmentNoTok: Label 'EQMIEV-EQ', Locked = true;
        NewEquipmentNoTok: Label 'EQMIEV-NEW', Locked = true;
        MaintenanceNoTok: Label 'EQMIEV-M1', Locked = true;
        WarrantyNoTok: Label 'EQMIEV-W1', Locked = true;
        InsertNotAllowedErr: Label 'You cannot create integration event entries directly. Entries are created when equipment is created, assigned or returned, when maintenance is registered, or when a warranty expires.', Locked = true;
        ModifyNotAllowedErr: Label 'You cannot change integration event entry %1. Entries can only be marked as processed.', Locked = true;
        DeleteNotAllowedErr: Label 'You cannot delete integration event entry %1 because it has not been processed yet.', Locked = true;
        RenameNotAllowedErr: Label 'You cannot change the number of integration event entry %1.', Locked = true;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EquipmentCreatedWritesEntry()
    var
        Equipment: Record "EQM Equipment";
        Entry: Record "EQM Integration Event Entry";
    begin
        // [SCENARIO 1] Creating equipment with Insert(true) writes one Equipment Created entry
        Initialize(true);

        // [GIVEN] Integration events are enabled

        // [WHEN] New equipment is inserted with Insert(true)
        CreateEquipment(Equipment, NewEquipmentNoTok);

        // [THEN] One Equipment Created entry exists with the number, status Available and Processed false
        Assert.AreEqual(1, CountEntries(NewEquipmentNoTok, Entry."Event Type"::"Equipment Created"), 'One Equipment Created entry should exist');
        FindEntry(Entry, NewEquipmentNoTok, Entry."Event Type"::"Equipment Created");
        Assert.AreEqual(Equipment.Status::Available, Entry."Equipment Status", 'The status should be Available');
        Assert.IsFalse(Entry.Processed, 'The entry should not be processed');
        Assert.AreEqual(0, Entry."Assignment Entry No.", 'There is no assignment for a created event');
        Assert.AreEqual('', Entry."Maintenance No.", 'There is no maintenance record for a created event');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EquipmentAssignedWritesEntry()
    var
        Equipment: Record "EQM Equipment";
        Entry: Record "EQM Integration Event Entry";
    begin
        // [SCENARIO 2] Assigning equipment writes one Equipment Assigned entry
        Initialize(true);

        // [GIVEN] Available equipment EQ
        CreateEquipment(Equipment, EquipmentNoTok);

        // [WHEN] EQ is assigned to E1
        Equipment.AssignEmployee(EmployeeTok);

        // [THEN] One Equipment Assigned entry exists with Status Assigned and the active assignment entry
        Assert.AreEqual(1, CountEntries(EquipmentNoTok, Entry."Event Type"::"Equipment Assigned"), 'One Equipment Assigned entry should exist');
        FindEntry(Entry, EquipmentNoTok, Entry."Event Type"::"Equipment Assigned");
        Assert.AreEqual(Equipment.Status::Assigned, Entry."Equipment Status", 'The status should be Assigned');
        Assert.AreEqual(GetAssignmentEntryNo(EquipmentNoTok, "EQM Assignment Status"::Active), Entry."Assignment Entry No.", 'The entry should carry the active assignment');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure EquipmentReturnedWritesEntry()
    var
        Equipment: Record "EQM Equipment";
        Entry: Record "EQM Integration Event Entry";
        AssignmentEntryNo: Integer;
    begin
        // [SCENARIO 3] Returning equipment writes one Equipment Returned entry
        Initialize(true);

        // [GIVEN] EQ assigned to E1
        CreateEquipment(Equipment, EquipmentNoTok);
        Equipment.AssignEmployee(EmployeeTok);
        AssignmentEntryNo := GetAssignmentEntryNo(EquipmentNoTok, "EQM Assignment Status"::Active);

        // [WHEN] EQ is returned (confirm Yes)
        Equipment.Get(EquipmentNoTok);
        Assert.IsTrue(Equipment.UnassignEmployee(), 'The return should be done');

        // [THEN] One Equipment Returned entry exists with Status Available and the closed assignment entry
        Assert.AreEqual(1, CountEntries(EquipmentNoTok, Entry."Event Type"::"Equipment Returned"), 'One Equipment Returned entry should exist');
        FindEntry(Entry, EquipmentNoTok, Entry."Event Type"::"Equipment Returned");
        Assert.AreEqual(Equipment.Status::Available, Entry."Equipment Status", 'The status should be Available');
        Assert.AreEqual(AssignmentEntryNo, Entry."Assignment Entry No.", 'The entry should carry the closed assignment');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure MaintenanceWritesReturnedAndMaintenanceEntries()
    var
        Equipment: Record "EQM Equipment";
        MaintenanceRecord: Record "EQM Maintenance Record";
        ReturnedEntry: Record "EQM Integration Event Entry";
        MaintenanceEntry: Record "EQM Integration Event Entry";
    begin
        // [SCENARIO 4] Registering maintenance for assigned equipment writes Returned, then Maintenance Created
        Initialize(true);

        // [GIVEN] EQ assigned to E1
        CreateEquipment(Equipment, EquipmentNoTok);
        Equipment.AssignEmployee(EmployeeTok);

        // [WHEN] A maintenance record M is inserted for EQ (confirm Yes)
        InitMaintenance(MaintenanceRecord);
        MaintenanceRecord.Insert(true);

        // [THEN] An Equipment Returned entry exists with Status In Maintenance
        Assert.AreEqual(1, CountEntries(EquipmentNoTok, ReturnedEntry."Event Type"::"Equipment Returned"), 'One Equipment Returned entry should exist');
        FindEntry(ReturnedEntry, EquipmentNoTok, ReturnedEntry."Event Type"::"Equipment Returned");
        Assert.AreEqual(Equipment.Status::"In Maintenance", ReturnedEntry."Equipment Status", 'The returned entry should have status In Maintenance');

        // [THEN] A Maintenance Created entry with a higher entry number has M and Status In Maintenance
        Assert.AreEqual(1, CountEntries(EquipmentNoTok, MaintenanceEntry."Event Type"::"Maintenance Created"), 'One Maintenance Created entry should exist');
        FindEntry(MaintenanceEntry, EquipmentNoTok, MaintenanceEntry."Event Type"::"Maintenance Created");
        Assert.AreEqual(MaintenanceNoTok, MaintenanceEntry."Maintenance No.", 'The entry should carry the maintenance number');
        Assert.AreEqual(Equipment.Status::"In Maintenance", MaintenanceEntry."Equipment Status", 'The maintenance entry should have status In Maintenance');
        Assert.IsTrue(MaintenanceEntry."Entry No." > ReturnedEntry."Entry No.", 'The maintenance entry should be written after the returned entry');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure WarrantyExpiredWritesEntry()
    var
        Equipment: Record "EQM Equipment";
        Entry: Record "EQM Integration Event Entry";
        WarrantyAlertMgt: Codeunit "EQM Warranty Alert Mgt.";
        ReferenceDate: Date;
    begin
        // [SCENARIO 5] Raising the warranty expired events writes one entry for the equipment that expired yesterday
        Initialize(true);
        ReferenceDate := Today();

        // [GIVEN] W1 with warranty end R-1
        InitEquipment(Equipment, WarrantyNoTok);
        Equipment."Warranty End Date" := ReferenceDate - 1;
        Equipment.Insert(true);

        // [WHEN] The warranty expired events are raised for R
        Assert.AreEqual(1, WarrantyAlertMgt.RaiseWarrantyExpiredEvents(ReferenceDate), 'One event should be raised');

        // [THEN] One Warranty Expired entry exists for W1
        Assert.AreEqual(1, CountEntries(WarrantyNoTok, Entry."Event Type"::"Warranty Expired"), 'One Warranty Expired entry should exist');
        FindEntry(Entry, WarrantyNoTok, Entry."Event Type"::"Warranty Expired");
        Assert.AreEqual(Equipment.Status::Available, Entry."Equipment Status", 'The status should be Available');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NoEntriesWhenIntegrationDisabled()
    var
        Equipment: Record "EQM Equipment";
        Entry: Record "EQM Integration Event Entry";
    begin
        // [SCENARIO 6] (neg) No entries are written when integration events are disabled
        Initialize(false);

        // [GIVEN] Integration events are disabled

        // [WHEN] Equipment is created and assigned
        CreateEquipment(Equipment, EquipmentNoTok);
        Equipment.AssignEmployee(EmployeeTok);

        // [THEN] No entry exists for the equipment
        Entry.SetRange("Equipment No.", EquipmentNoTok);
        Assert.RecordIsEmpty(Entry);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NoEntryForInsertWithoutTriggersOrTemporaryRecord()
    var
        Equipment: Record "EQM Equipment";
        TempEquipment: Record "EQM Equipment" temporary;
        Entry: Record "EQM Integration Event Entry";
    begin
        // [SCENARIO 7] (neg) Insert(false) and a temporary record write no entry
        Initialize(true);

        // [GIVEN] Integration events are enabled

        // [WHEN] Equipment is inserted with Insert(false), and a temporary record with Insert(true)
        InitEquipment(Equipment, NewEquipmentNoTok);
        Equipment.Insert(false);
        InitEquipment(TempEquipment, EquipmentNoTok);
        TempEquipment.Insert(true);

        // [THEN] No entry exists for either number
        Entry.SetFilter("Equipment No.", '%1|%2', NewEquipmentNoTok, EquipmentNoTok);
        Assert.RecordIsEmpty(Entry);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('ConfirmNoHandler')]
    procedure NoReturnedEntryWhenReturnCancelled()
    var
        Equipment: Record "EQM Equipment";
        Entry: Record "EQM Integration Event Entry";
    begin
        // [SCENARIO 8] (neg) A cancelled return writes no Returned entry
        Initialize(true);

        // [GIVEN] EQ assigned to E1
        CreateEquipment(Equipment, EquipmentNoTok);
        Equipment.AssignEmployee(EmployeeTok);

        // [WHEN] The return is answered No
        Equipment.Get(EquipmentNoTok);
        Assert.IsFalse(Equipment.UnassignEmployee(), 'The return should be cancelled');

        // [THEN] No Equipment Returned entry exists
        Assert.AreEqual(0, CountEntries(EquipmentNoTok, Entry."Event Type"::"Equipment Returned"), 'No Equipment Returned entry should exist');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MarkProcessedSetsFlagAndIsIdempotent()
    var
        Entry: Record "EQM Integration Event Entry";
        IntegrationEventMgt: Codeunit "EQM Integration Event Mgt.";
        FirstProcessedAt: DateTime;
    begin
        // [SCENARIO 9] MarkProcessed sets Processed and Processed At, and a second call changes nothing
        Initialize(true);

        // [GIVEN] A pending entry
        CreatePendingEntry(Entry);

        // [WHEN] MarkProcessed runs
        IntegrationEventMgt.MarkProcessed(Entry);

        // [THEN] The stored entry is processed with Processed At filled
        Entry.Get(Entry."Entry No.");
        Assert.IsTrue(Entry.Processed, 'The entry should be processed');
        Assert.AreNotEqual(0DT, Entry."Processed At", 'Processed At should be filled');
        FirstProcessedAt := Entry."Processed At";

        // [WHEN] MarkProcessed runs again
        IntegrationEventMgt.MarkProcessed(Entry);

        // [THEN] Processed At is unchanged
        Entry.Get(Entry."Entry No.");
        Assert.AreEqual(FirstProcessedAt, Entry."Processed At", 'Processed At should not change on a second call');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DirectInsertIsRejected()
    var
        Entry: Record "EQM Integration Event Entry";
    begin
        // [SCENARIO 10a] (neg) An entry cannot be inserted directly
        Initialize(true);

        // [GIVEN] An entry record with an equipment number
        Entry.Init();
        Entry."Equipment No." := EquipmentNoTok;

        // [WHEN] Insert is called without the integration codeunit
        asserterror Entry.Insert(true);

        // [THEN] The insert error is raised
        Assert.ExpectedError(InsertNotAllowedErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DirectModifyIsRejected()
    var
        Entry: Record "EQM Integration Event Entry";
        EntryNo: Integer;
    begin
        // [SCENARIO 10b] (neg) A stored entry cannot be modified directly
        Initialize(true);

        // [GIVEN] A stored pending entry
        CreatePendingEntry(Entry);
        EntryNo := Entry."Entry No.";
        Entry.Get(EntryNo);

        // [WHEN] Processed is set and Modify is called directly
        Entry.Processed := true;
        asserterror Entry.Modify(true);

        // [THEN] The modify error is raised
        Assert.ExpectedError(StrSubstNo(ModifyNotAllowedErr, EntryNo));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RenameIsRejected()
    var
        Entry: Record "EQM Integration Event Entry";
        EntryNo: Integer;
    begin
        // [SCENARIO 10c] (neg) A stored entry cannot be renamed
        Initialize(true);

        // [GIVEN] A stored pending entry
        CreatePendingEntry(Entry);
        EntryNo := Entry."Entry No.";
        Entry.Get(EntryNo);

        // [WHEN] The entry number is changed with Rename
        asserterror Entry.Rename(EntryNo + 1000);

        // [THEN] The rename error is raised
        Assert.ExpectedError(StrSubstNo(RenameNotAllowedErr, EntryNo));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DeletingPendingEntryIsRejected()
    var
        Entry: Record "EQM Integration Event Entry";
        EntryNo: Integer;
    begin
        // [SCENARIO 11a] (neg) A pending entry cannot be deleted
        Initialize(true);

        // [GIVEN] A pending entry
        CreatePendingEntry(Entry);
        EntryNo := Entry."Entry No.";
        Entry.Get(EntryNo);

        // [WHEN] Delete is called
        asserterror Entry.Delete(true);

        // [THEN] The delete error is raised
        Assert.ExpectedError(StrSubstNo(DeleteNotAllowedErr, EntryNo));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DeletingProcessedEntryIsAllowed()
    var
        Entry: Record "EQM Integration Event Entry";
        IntegrationEventMgt: Codeunit "EQM Integration Event Mgt.";
        EntryNo: Integer;
    begin
        // [SCENARIO 11b] A processed entry can be deleted
        Initialize(true);

        // [GIVEN] A processed entry
        CreatePendingEntry(Entry);
        EntryNo := Entry."Entry No.";
        IntegrationEventMgt.MarkProcessed(Entry);
        Entry.Get(EntryNo);

        // [WHEN] Delete is called
        Entry.Delete(true);

        // [THEN] The entry is gone
        Assert.IsFalse(Entry.Get(EntryNo), 'The processed entry should be deleted');
    end;

    local procedure Initialize(IntegrationEnabled: Boolean)
    var
        EquipmentSetup: Record "EQM Equipment Setup";
        Category: Record "EQM Equipment Category";
        Employee: Record Employee;
    begin
        // Everything runs in the test transaction, which is rolled back (AutoRollback), so nothing is committed or cleaned up.
        if not EquipmentSetup.Get() then begin
            EquipmentSetup.Init();
            EquipmentSetup.Insert();
        end;
        EquipmentSetup."Integration Events Enabled" := IntegrationEnabled;
        EquipmentSetup.Modify();

        Category.Init();
        Category.Code := CategoryTok;
        Category.Active := true;
        Category.Insert();

        Employee.Init();
        Employee."No." := EmployeeTok;
        Employee."First Name" := 'IEV';
        Employee."Last Name" := EmployeeTok;
        Employee.Status := Employee.Status::Active;
        Employee.Insert(false);
    end;

    local procedure InitEquipment(var Equipment: Record "EQM Equipment"; EquipmentNo: Code[20])
    begin
        Equipment.Init();
        Equipment."No." := EquipmentNo;
        Equipment.Description := 'EQMIEV test equipment';
        Equipment."Category Code" := CategoryTok;
    end;

    local procedure CreateEquipment(var Equipment: Record "EQM Equipment"; EquipmentNo: Code[20])
    begin
        InitEquipment(Equipment, EquipmentNo);
        Equipment.Insert(true);
    end;

    local procedure InitMaintenance(var MaintenanceRecord: Record "EQM Maintenance Record")
    begin
        MaintenanceRecord.Init();
        MaintenanceRecord."No." := MaintenanceNoTok;
        MaintenanceRecord."Equipment No." := EquipmentNoTok;
        MaintenanceRecord."Maintenance Date" := Today();
        MaintenanceRecord.Description := 'EQMIEV test maintenance';
    end;

    local procedure CreatePendingEntry(var Entry: Record "EQM Integration Event Entry")
    var
        IntegrationEventMgt: Codeunit "EQM Integration Event Mgt.";
    begin
        IntegrationEventMgt.RecordEvent("EQM Integration Event Type"::"Equipment Created", EquipmentNoTok, "EQM Equipment Status"::Available, 0, '');
        Entry.SetRange("Equipment No.", EquipmentNoTok);
        Entry.FindLast();
        Entry.SetRange("Equipment No.");
    end;

    local procedure CountEntries(EquipmentNo: Code[20]; EventType: Enum "EQM Integration Event Type"): Integer
    var
        Entry: Record "EQM Integration Event Entry";
    begin
        Entry.SetRange("Equipment No.", EquipmentNo);
        Entry.SetRange("Event Type", EventType);
        exit(Entry.Count());
    end;

    local procedure FindEntry(var Entry: Record "EQM Integration Event Entry"; EquipmentNo: Code[20]; EventType: Enum "EQM Integration Event Type")
    begin
        Entry.SetRange("Equipment No.", EquipmentNo);
        Entry.SetRange("Event Type", EventType);
        Entry.FindFirst();
    end;

    local procedure GetAssignmentEntryNo(EquipmentNo: Code[20]; AssignmentStatus: Enum "EQM Assignment Status"): Integer
    var
        Assignment: Record "EQM Equipment Assignment";
    begin
        Assignment.SetRange("Equipment No.", EquipmentNo);
        Assignment.SetRange(Status, AssignmentStatus);
        Assignment.FindFirst();
        exit(Assignment."Entry No.");
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
