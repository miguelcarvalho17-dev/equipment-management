namespace MiguelCarvalho.EquipmentManagement.Tests;

using Microsoft.HumanResources.Employee;
using MiguelCarvalho.EquipmentManagement;
using System.TestLibraries.Utilities;
using System.Text;
using System.Utilities;

/// <summary>
/// Tests for FR-035 Equipment Audit Trail (table 50112, codeunits 50135 and 50136, hook in table 50100 OnModify),
/// scenarios 1 to 13 of the plan plus the one-Updated-per-save rule (D1) and Insert(false). Scenarios 14 and 15
/// (Manager and Reader in the sandbox, rename, integration off) are manual sandbox checks.
/// A failed statement (asserterror) rolls back the whole test transaction, so each test that expects an error has
/// exactly one asserterror, as its last action. Everything rolls back (AutoRollback); there is no Commit.
/// </summary>
codeunit 50192 "EQM Audit Trail Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        CategoryTok: Label 'EQMAUD-CAT', Locked = true;
        EmployeeTok: Label 'EQMAUD-E1', Locked = true;
        EquipmentNoTok: Label 'EQMAUD-EQ', Locked = true;
        NewEquipmentNoTok: Label 'EQMAUD-NEW', Locked = true;
        MaintenanceNoTok: Label 'EQMAUD-M1', Locked = true;
        PngBase64Txt: Label 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==', Locked = true;
        InsertNotAllowedErr: Label 'You cannot create equipment audit entries directly. Entries are created when equipment is created, changed, assigned, returned, sent to maintenance or disposed.';
        ModifyNotAllowedErr: Label 'You cannot change equipment audit entry %1. The audit trail is read-only.', Comment = '%1 = entry number';
        DeleteNotAllowedErr: Label 'You cannot delete equipment audit entry %1. The audit trail is kept permanently.', Comment = '%1 = entry number';
        RenameNotAllowedErr: Label 'You cannot change the number of equipment audit entry %1.', Comment = '%1 = entry number';

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CreatedEntryWrittenOnInsert()
    var
        Equipment: Record "EQM Equipment";
        AuditEntry: Record "EQM Equipment Audit Entry";
        LoggedBefore: DateTime;
        LoggedAfter: DateTime;
    begin
        // [SCENARIO 1] Insert(true) writes exactly one Created entry with status, user and time
        Initialize();

        // [GIVEN] New equipment X (Available), not inserted yet
        InitEquipment(Equipment, NewEquipmentNoTok);

        // [WHEN] X is inserted with Insert(true)
        LoggedBefore := CurrentDateTime();
        Equipment.Insert(true);
        LoggedAfter := CurrentDateTime();

        // [THEN] Exactly one Created entry exists, and it is the only entry of X
        Assert.AreEqual(1, CountEntries(NewEquipmentNoTok, AuditEntry."Event Type"::Created), 'Exactly one Created entry should exist');
        Assert.AreEqual(1, CountAllEntries(NewEquipmentNoTok), 'Created should be the only entry of the new equipment');
        FindEntry(NewEquipmentNoTok, AuditEntry."Event Type"::Created, AuditEntry);
        Assert.AreEqual(Equipment.Status::Available, AuditEntry."Status After", 'Status After should be Available');
        Assert.AreEqual(CopyStr(UserId(), 1, MaxStrLen(AuditEntry."User ID")), AuditEntry."User ID", 'User ID should be the current user');
        Assert.AreNotEqual(0DT, AuditEntry."Logged At", 'Logged At should be filled');
        // The database may round a DateTime by a few milliseconds, so allow one second either side.
        Assert.IsTrue((AuditEntry."Logged At" >= LoggedBefore - 1000) and (AuditEntry."Logged At" <= LoggedAfter + 1000), 'Logged At should be the time of the insert');
        Assert.AreEqual('', AuditEntry."Employee No.", 'Employee No. should be blank for Created');
        Assert.AreEqual(0, AuditEntry."Assignment Entry No.", 'Assignment Entry No. should be 0 for Created');
        Assert.AreEqual('', AuditEntry."Maintenance No.", 'Maintenance No. should be blank for Created');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure InsertWithoutTriggersWritesNoEntry()
    var
        Equipment: Record "EQM Equipment";
    begin
        // [SCENARIO] (neg) Insert(false) does not raise the created event, so no entry is written
        Initialize();

        // [GIVEN] New equipment
        InitEquipment(Equipment, NewEquipmentNoTok);

        // [WHEN] It is inserted with Insert(false)
        Equipment.Insert(false);

        // [THEN] No audit entry exists
        Assert.AreEqual(0, CountAllEntries(NewEquipmentNoTok), 'Insert(false) should not write an entry');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AssignedEntryWrittenOnAssign()
    var
        Equipment: Record "EQM Equipment";
        AuditEntry: Record "EQM Equipment Audit Entry";
    begin
        // [SCENARIO 2] Assigning writes one Assigned entry with employee and assignment entry, and no Updated entry
        Initialize();

        // [GIVEN] Available equipment X
        CreateEquipment(Equipment, EquipmentNoTok);

        // [WHEN] X is assigned to E
        Equipment.AssignEmployee(EmployeeTok);

        // [THEN] One Assigned entry with the employee, the active assignment entry and status Assigned
        Assert.AreEqual(1, CountEntries(EquipmentNoTok, AuditEntry."Event Type"::Assigned), 'Exactly one Assigned entry should exist');
        FindEntry(EquipmentNoTok, AuditEntry."Event Type"::Assigned, AuditEntry);
        Assert.AreEqual(EmployeeTok, AuditEntry."Employee No.", 'Employee No. should be E');
        Assert.AreEqual(GetActiveEntryNo(EquipmentNoTok), AuditEntry."Assignment Entry No.", 'Assignment Entry No. should be the active assignment entry');
        Assert.AreEqual(Equipment.Status::Assigned, AuditEntry."Status After", 'Status After should be Assigned');
        Assert.AreEqual(0, CountEntries(EquipmentNoTok, AuditEntry."Event Type"::Updated), 'Assigning should not write an Updated entry');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReturnedEntryWrittenOnUnassign()
    var
        Equipment: Record "EQM Equipment";
        AuditEntry: Record "EQM Equipment Audit Entry";
        AssignmentEntryNo: Integer;
    begin
        // [SCENARIO 3] Returning writes one Returned entry with the employee and status Available, and no Updated entry
        Initialize();

        // [GIVEN] X assigned to E
        CreateEquipment(Equipment, EquipmentNoTok);
        Equipment.AssignEmployee(EmployeeTok);
        AssignmentEntryNo := GetActiveEntryNo(EquipmentNoTok);

        // [WHEN] X is returned (confirm Yes)
        Assert.IsTrue(Equipment.UnassignEmployee(), 'The return should be confirmed');

        // [THEN] One Returned entry with employee E, the closed assignment entry and status Available
        Assert.AreEqual(1, CountEntries(EquipmentNoTok, AuditEntry."Event Type"::Returned), 'Exactly one Returned entry should exist');
        FindEntry(EquipmentNoTok, AuditEntry."Event Type"::Returned, AuditEntry);
        Assert.AreEqual(EmployeeTok, AuditEntry."Employee No.", 'Employee No. should be E');
        Assert.AreEqual(AssignmentEntryNo, AuditEntry."Assignment Entry No.", 'Assignment Entry No. should be the assignment that was closed');
        Assert.AreEqual(Equipment.Status::Available, AuditEntry."Status After", 'Status After should be Available');
        Assert.AreEqual(0, CountEntries(EquipmentNoTok, AuditEntry."Event Type"::Updated), 'Returning should not write an Updated entry');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SentToMaintenanceEntryWrittenOnMaintenanceInsert()
    var
        Equipment: Record "EQM Equipment";
        MaintenanceRecord: Record "EQM Maintenance Record";
        AuditEntry: Record "EQM Equipment Audit Entry";
    begin
        // [SCENARIO 4] Registering maintenance writes one Sent to Maintenance entry with the maintenance number
        Initialize();

        // [GIVEN] Available equipment X
        CreateEquipment(Equipment, EquipmentNoTok);

        // [WHEN] Maintenance record M is inserted
        InitMaintenance(MaintenanceRecord);
        MaintenanceRecord.Insert(true);

        // [THEN] One Sent to Maintenance entry with Maintenance No. = M and Status After = In Maintenance
        Assert.AreEqual(1, CountEntries(EquipmentNoTok, AuditEntry."Event Type"::"Sent to Maintenance"), 'Exactly one Sent to Maintenance entry should exist');
        FindEntry(EquipmentNoTok, AuditEntry."Event Type"::"Sent to Maintenance", AuditEntry);
        Assert.AreEqual(MaintenanceNoTok, AuditEntry."Maintenance No.", 'Maintenance No. should be M');
        Assert.AreEqual(Equipment.Status::"In Maintenance", AuditEntry."Status After", 'Status After should be In Maintenance');
        Assert.AreEqual(0, CountEntries(EquipmentNoTok, AuditEntry."Event Type"::Returned), 'Available equipment has nothing to return');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReturnedIsLoggedBeforeSentToMaintenance()
    var
        Equipment: Record "EQM Equipment";
        MaintenanceRecord: Record "EQM Maintenance Record";
        AuditEntry: Record "EQM Equipment Audit Entry";
        ReturnedEntryNo: Integer;
        SentEntryNo: Integer;
    begin
        // [SCENARIO 5] Maintenance on assigned equipment logs Returned (In Maintenance) before Sent to Maintenance
        Initialize();

        // [GIVEN] X assigned to E
        CreateEquipment(Equipment, EquipmentNoTok);
        Equipment.AssignEmployee(EmployeeTok);

        // [WHEN] Maintenance M is registered (confirm Yes)
        InitMaintenance(MaintenanceRecord);
        MaintenanceRecord.Insert(true);

        // [THEN] One Returned entry with status In Maintenance and one Sent to Maintenance entry, Returned first
        Assert.AreEqual(1, CountEntries(EquipmentNoTok, AuditEntry."Event Type"::Returned), 'Exactly one Returned entry should exist');
        Assert.AreEqual(1, CountEntries(EquipmentNoTok, AuditEntry."Event Type"::"Sent to Maintenance"), 'Exactly one Sent to Maintenance entry should exist');
        FindEntry(EquipmentNoTok, AuditEntry."Event Type"::Returned, AuditEntry);
        ReturnedEntryNo := AuditEntry."Entry No.";
        Assert.AreEqual(Equipment.Status::"In Maintenance", AuditEntry."Status After", 'Returned should show In Maintenance as the reason');
        Assert.AreEqual(EmployeeTok, AuditEntry."Employee No.", 'Returned should name the employee');
        FindEntry(EquipmentNoTok, AuditEntry."Event Type"::"Sent to Maintenance", AuditEntry);
        SentEntryNo := AuditEntry."Entry No.";
        Assert.AreEqual(MaintenanceNoTok, AuditEntry."Maintenance No.", 'Sent to Maintenance should carry M');
        Assert.IsTrue(ReturnedEntryNo < SentEntryNo, 'Returned should be logged before Sent to Maintenance');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ManualMaintenanceStatusHasBlankMaintenanceNo()
    var
        Equipment: Record "EQM Equipment";
        AuditEntry: Record "EQM Equipment Audit Entry";
    begin
        // [SCENARIO 6] A manual status change to In Maintenance writes Sent to Maintenance without a maintenance number
        Initialize();

        // [GIVEN] Available equipment X
        CreateEquipment(Equipment, EquipmentNoTok);

        // [WHEN] Status is validated to In Maintenance and saved
        Equipment.Validate(Status, Equipment.Status::"In Maintenance");
        Equipment.Modify(true);

        // [THEN] One Sent to Maintenance entry with a blank Maintenance No.
        Assert.AreEqual(1, CountEntries(EquipmentNoTok, AuditEntry."Event Type"::"Sent to Maintenance"), 'Exactly one Sent to Maintenance entry should exist');
        FindEntry(EquipmentNoTok, AuditEntry."Event Type"::"Sent to Maintenance", AuditEntry);
        Assert.AreEqual('', AuditEntry."Maintenance No.", 'Maintenance No. should be blank for a manual change');
        Assert.AreEqual(Equipment.Status::"In Maintenance", AuditEntry."Status After", 'Status After should be In Maintenance');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DisposingAssignedEquipmentLogsReturnedThenDisposed()
    var
        Equipment: Record "EQM Equipment";
        AuditEntry: Record "EQM Equipment Audit Entry";
        ReturnedEntryNo: Integer;
    begin
        // [SCENARIO 7] Disposing assigned equipment logs Returned then Disposed, both with Status After = Disposed
        Initialize();

        // [GIVEN] X assigned to E
        CreateEquipment(Equipment, EquipmentNoTok);
        Equipment.AssignEmployee(EmployeeTok);

        // [WHEN] Status is set to Disposed (confirm Yes) and saved
        Equipment.Validate(Status, Equipment.Status::Disposed);
        Equipment.Modify(true);

        // [THEN] One Returned and one Disposed entry, both Disposed, Returned first
        Assert.AreEqual(1, CountEntries(EquipmentNoTok, AuditEntry."Event Type"::Returned), 'Exactly one Returned entry should exist');
        Assert.AreEqual(1, CountEntries(EquipmentNoTok, AuditEntry."Event Type"::Disposed), 'Exactly one Disposed entry should exist');
        FindEntry(EquipmentNoTok, AuditEntry."Event Type"::Returned, AuditEntry);
        ReturnedEntryNo := AuditEntry."Entry No.";
        Assert.AreEqual(Equipment.Status::Disposed, AuditEntry."Status After", 'Returned should show Disposed');
        FindEntry(EquipmentNoTok, AuditEntry."Event Type"::Disposed, AuditEntry);
        Assert.AreEqual(Equipment.Status::Disposed, AuditEntry."Status After", 'Disposed should show Disposed');
        Assert.IsTrue(ReturnedEntryNo < AuditEntry."Entry No.", 'Returned should be logged before Disposed');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OneUpdatedEntryPerSaveWithSeveralFieldsChanged()
    var
        Equipment: Record "EQM Equipment";
        AuditEntry: Record "EQM Equipment Audit Entry";
    begin
        // [SCENARIO 8] Changing Description and Purchase Cost in one Modify(true) writes exactly one Updated entry
        Initialize();

        // [GIVEN] Equipment X
        CreateEquipment(Equipment, EquipmentNoTok);

        // [WHEN] Description and Purchase Cost change in one Modify(true)
        Equipment.Description := 'EQMAUD changed description';
        Equipment."Purchase Cost" := 1234.5;
        Equipment.Modify(true);

        // [THEN] Exactly one Updated entry with the current status, and no fields or values stored
        Assert.AreEqual(1, CountEntries(EquipmentNoTok, AuditEntry."Event Type"::Updated), 'Exactly one Updated entry should exist');
        FindEntry(EquipmentNoTok, AuditEntry."Event Type"::Updated, AuditEntry);
        Assert.AreEqual(Equipment.Status::Available, AuditEntry."Status After", 'Status After should be the current status');
        Assert.AreEqual(2, CountAllEntries(EquipmentNoTok), 'Only Created and Updated should exist');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EachSaveWritesItsOwnUpdatedEntry()
    var
        Equipment: Record "EQM Equipment";
        AuditEntry: Record "EQM Equipment Audit Entry";
    begin
        // [SCENARIO D1] Two saves that each change a field write two Updated entries (the card saves per field)
        Initialize();

        // [GIVEN] Equipment X
        CreateEquipment(Equipment, EquipmentNoTok);

        // [WHEN] Description is changed and saved, then Model is changed and saved
        Equipment.Description := 'EQMAUD first change';
        Equipment.Modify(true);
        Equipment.Model := 'EQMAUD second change';
        Equipment.Modify(true);

        // [THEN] Two Updated entries exist
        Assert.AreEqual(2, CountEntries(EquipmentNoTok, AuditEntry."Event Type"::Updated), 'Each save should write one Updated entry');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NoEntryWhenNothingTrackedChanged()
    var
        Equipment: Record "EQM Equipment";
    begin
        // [SCENARIO 9a] (neg) Modify(true) without any change writes no entry
        Initialize();

        // [GIVEN] Equipment X with only its Created entry
        CreateEquipment(Equipment, EquipmentNoTok);
        Assert.AreEqual(1, CountAllEntries(EquipmentNoTok), 'Only Created should exist before the save');

        // [WHEN] X is saved with no change
        Equipment.Modify(true);

        // [THEN] No entry was added
        Assert.AreEqual(1, CountAllEntries(EquipmentNoTok), 'A save without change should not add an entry');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NoEntryWhenOnlyPictureChanged()
    var
        Equipment: Record "EQM Equipment";
        PictureMgt: Codeunit "EQM Equipment Picture Mgt.";
        TempBlob: Codeunit "Temp Blob";
        Base64Convert: Codeunit "Base64 Convert";
        PictureOutStream: OutStream;
        PictureInStream: InStream;
    begin
        // [SCENARIO 9b] (neg) Changing only the picture writes no entry
        Initialize();

        // [GIVEN] Equipment X with only its Created entry
        CreateEquipment(Equipment, EquipmentNoTok);
        TempBlob.CreateOutStream(PictureOutStream);
        Base64Convert.FromBase64(PngBase64Txt, PictureOutStream);
        TempBlob.CreateInStream(PictureInStream);

        // [WHEN] The picture is set (the equipment is saved with Modify(true))
        PictureMgt.SetPicture(Equipment, PictureInStream, 'EQMAUD.png');

        // [THEN] The picture is stored, and no entry was added
        Equipment.Get(EquipmentNoTok);
        Assert.AreEqual(1, Equipment.Picture.Count(), 'The picture should be stored');
        Assert.AreEqual(1, CountAllEntries(EquipmentNoTok), 'Changing only the picture should not add an entry');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure StatusToLostIsLoggedAsUpdated()
    var
        Equipment: Record "EQM Equipment";
        AuditEntry: Record "EQM Equipment Audit Entry";
    begin
        // [SCENARIO 10a] (D2) Available to Lost writes one Updated entry with Status After = Lost
        Initialize();

        // [GIVEN] Available equipment X
        CreateEquipment(Equipment, EquipmentNoTok);

        // [WHEN] Status is set to Lost (confirm Yes) and saved
        Equipment.Validate(Status, Equipment.Status::Lost);
        Equipment.Modify(true);

        // [THEN] One Updated entry with Status After = Lost, and no Disposed or Sent to Maintenance entry
        Assert.AreEqual(1, CountEntries(EquipmentNoTok, AuditEntry."Event Type"::Updated), 'Exactly one Updated entry should exist');
        FindEntry(EquipmentNoTok, AuditEntry."Event Type"::Updated, AuditEntry);
        Assert.AreEqual(Equipment.Status::Lost, AuditEntry."Status After", 'Status After should be Lost');
        Assert.AreEqual(0, CountEntries(EquipmentNoTok, AuditEntry."Event Type"::Disposed), 'Lost is not Disposed');
        Assert.AreEqual(0, CountEntries(EquipmentNoTok, AuditEntry."Event Type"::"Sent to Maintenance"), 'Lost is not Sent to Maintenance');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PostingMaintenanceLogsStatusBackToAvailableAsUpdated()
    var
        Equipment: Record "EQM Equipment";
        MaintenanceRecord: Record "EQM Maintenance Record";
        AuditEntry: Record "EQM Equipment Audit Entry";
    begin
        // [SCENARIO 10b] (D2) Posting the last open maintenance logs an Updated entry with Status After = Available
        Initialize();

        // [GIVEN] X In Maintenance through M
        CreateEquipment(Equipment, EquipmentNoTok);
        InitMaintenance(MaintenanceRecord);
        MaintenanceRecord.Insert(true);

        // [WHEN] M is posted
        MaintenanceRecord.Get(MaintenanceNoTok);
        Codeunit.Run(Codeunit::"EQM Maintenance-Post", MaintenanceRecord);

        // [THEN] The equipment is Available and an Updated entry with Status After = Available exists
        Equipment.Get(EquipmentNoTok);
        Assert.AreEqual(Equipment.Status::Available, Equipment.Status, 'The equipment should be Available after posting');
        AuditEntry.SetRange("Equipment No.", EquipmentNoTok);
        AuditEntry.SetRange("Event Type", AuditEntry."Event Type"::Updated);
        AuditEntry.SetRange("Status After", AuditEntry."Status After"::Available);
        Assert.IsFalse(AuditEntry.IsEmpty(), 'An Updated entry with Status After = Available should exist');
        Assert.AreEqual(1, CountEntries(EquipmentNoTok, AuditEntry."Event Type"::"Sent to Maintenance"), 'Posting should not add a Sent to Maintenance entry');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TemporaryEquipmentWritesNoEntry()
    var
        TempEquipment: Record "EQM Equipment" temporary;
    begin
        // [SCENARIO 11] (neg) A temporary record that is inserted and modified writes no entry
        Initialize();

        // [GIVEN] A temporary equipment record
        InitEquipment(TempEquipment, NewEquipmentNoTok);

        // [WHEN] It is inserted and modified with triggers
        TempEquipment.Insert(true);
        TempEquipment.Description := 'EQMAUD temporary change';
        TempEquipment.Modify(true);

        // [THEN] No audit entry exists
        Assert.AreEqual(0, CountAllEntries(NewEquipmentNoTok), 'A temporary record should not write an entry');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DirectInsertIsRejected()
    var
        AuditEntry: Record "EQM Equipment Audit Entry";
    begin
        // [SCENARIO 12a] (neg) Insert without the allow flag raises the insert error
        Initialize();

        // [GIVEN] An audit entry that was not enabled for insert
        AuditEntry.Init();
        AuditEntry."Equipment No." := EquipmentNoTok;

        // [WHEN] It is inserted
        asserterror AuditEntry.Insert(true);

        // [THEN] The insert error is raised
        Assert.ExpectedError(InsertNotAllowedErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure InsertWithoutEquipmentNoIsRejected()
    var
        AuditEntry: Record "EQM Equipment Audit Entry";
    begin
        // [SCENARIO 12b] (neg) Even with the allow flag, an entry without Equipment No. is rejected
        Initialize();

        // [GIVEN] An enabled entry with a blank Equipment No.
        AuditEntry.Init();
        AuditEntry.AllowInsertFromAuditTrail();

        // [WHEN] It is inserted
        asserterror AuditEntry.Insert(true);

        // [THEN] The TestField error is raised
        Assert.ExpectedErrorCode('TestField');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ModifyIsRejected()
    var
        Equipment: Record "EQM Equipment";
        AuditEntry: Record "EQM Equipment Audit Entry";
    begin
        // [SCENARIO 12c] (neg) Modify of an entry raises the modify error
        Initialize();

        // [GIVEN] An existing entry (Created)
        CreateEquipment(Equipment, EquipmentNoTok);
        FindEntry(EquipmentNoTok, AuditEntry."Event Type"::Created, AuditEntry);

        // [WHEN] The entry is modified
        AuditEntry."Status After" := AuditEntry."Status After"::Lost;
        asserterror AuditEntry.Modify(true);

        // [THEN] The modify error is raised with the entry number
        Assert.ExpectedError(StrSubstNo(ModifyNotAllowedErr, AuditEntry."Entry No."));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DeleteIsRejected()
    var
        Equipment: Record "EQM Equipment";
        AuditEntry: Record "EQM Equipment Audit Entry";
    begin
        // [SCENARIO 12d] (neg) Delete of an entry raises the delete error
        Initialize();

        // [GIVEN] An existing entry (Created)
        CreateEquipment(Equipment, EquipmentNoTok);
        FindEntry(EquipmentNoTok, AuditEntry."Event Type"::Created, AuditEntry);

        // [WHEN] The entry is deleted
        asserterror AuditEntry.Delete(true);

        // [THEN] The delete error is raised with the entry number
        Assert.ExpectedError(StrSubstNo(DeleteNotAllowedErr, AuditEntry."Entry No."));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RenameIsRejected()
    var
        Equipment: Record "EQM Equipment";
        AuditEntry: Record "EQM Equipment Audit Entry";
        OldEntryNo: Integer;
    begin
        // [SCENARIO 12e] (neg) Rename of an entry raises the rename error
        Initialize();

        // [GIVEN] An existing entry (Created)
        CreateEquipment(Equipment, EquipmentNoTok);
        FindEntry(EquipmentNoTok, AuditEntry."Event Type"::Created, AuditEntry);
        OldEntryNo := AuditEntry."Entry No.";

        // [WHEN] The entry number is changed
        asserterror AuditEntry.Rename(OldEntryNo + 100000);

        // [THEN] The rename error is raised with the old entry number
        Assert.ExpectedError(StrSubstNo(RenameNotAllowedErr, OldEntryNo));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EntryIsRolledBackWithFailedOperation()
    var
        Equipment: Record "EQM Equipment";
        MaintenanceRecord: Record "EQM Maintenance Record";
        Subscriber: Codeunit "EQM Audit Trail Test Subscr";
    begin
        // [SCENARIO 13] (neg) An error after the audit entry was written leaves no entry
        Initialize();

        // [GIVEN] Available equipment X, and a subscriber that fails after the equipment was sent to maintenance
        CreateEquipment(Equipment, EquipmentNoTok);
        BindSubscription(Subscriber);

        // [WHEN] Maintenance M is registered and the operation fails after the hook ran
        InitMaintenance(MaintenanceRecord);
        asserterror MaintenanceRecord.Insert(true);

        // [THEN] The failure is the forced one, the entry existed at that moment, and no entry remains afterwards
        Assert.ExpectedError(Subscriber.GetForcedFailureText());
        Assert.AreEqual(1, Subscriber.GetSentToMaintenanceEntriesAtFailure(), 'The Sent to Maintenance entry should have been written before the failure');
        Assert.AreEqual(0, CountAllEntries(EquipmentNoTok), 'The failed operation should leave no audit entry');
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
        Employee."First Name" := 'AUD';
        Employee."Last Name" := EmployeeTok;
        Employee.Status := Employee.Status::Active;
        Employee.Insert(false);
    end;

    local procedure InitEquipment(var Equipment: Record "EQM Equipment"; EquipmentNo: Code[20])
    begin
        Equipment.Init();
        Equipment."No." := EquipmentNo;
        Equipment.Description := 'EQMAUD test equipment';
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
        MaintenanceRecord.Description := 'EQMAUD test maintenance';
    end;

    local procedure GetActiveEntryNo(EquipmentNo: Code[20]): Integer
    var
        Assignment: Record "EQM Equipment Assignment";
    begin
        Assignment.SetRange("Equipment No.", EquipmentNo);
        Assignment.SetRange(Status, Assignment.Status::Active);
        Assignment.FindFirst();
        exit(Assignment."Entry No.");
    end;

    local procedure CountEntries(EquipmentNo: Code[20]; EventType: Enum "EQM Audit Event Type"): Integer
    var
        AuditEntry: Record "EQM Equipment Audit Entry";
    begin
        AuditEntry.SetRange("Equipment No.", EquipmentNo);
        AuditEntry.SetRange("Event Type", EventType);
        exit(AuditEntry.Count());
    end;

    local procedure CountAllEntries(EquipmentNo: Code[20]): Integer
    var
        AuditEntry: Record "EQM Equipment Audit Entry";
    begin
        AuditEntry.SetRange("Equipment No.", EquipmentNo);
        exit(AuditEntry.Count());
    end;

    local procedure FindEntry(EquipmentNo: Code[20]; EventType: Enum "EQM Audit Event Type"; var AuditEntry: Record "EQM Equipment Audit Entry")
    begin
        AuditEntry.Reset();
        AuditEntry.SetRange("Equipment No.", EquipmentNo);
        AuditEntry.SetRange("Event Type", EventType);
        AuditEntry.FindFirst();
    end;

    [ConfirmHandler]
    procedure ConfirmYesHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}
