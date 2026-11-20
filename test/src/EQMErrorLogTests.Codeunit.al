namespace MiguelCarvalho.EquipmentManagement.Tests;

using MiguelCarvalho.EquipmentManagement;
using System.TestLibraries.Utilities;
using System.Threading;

/// <summary>
/// Tests for FR-051 Error Logging, scenarios E1 to E8: the log codeunit 50142 and the table 50115. Every test
/// opens a write transaction first, so the entry is written in the test transaction and rolled back with it; the path
/// that commits an entry of its own is tested in codeunit 50155. A failed statement (asserterror) rolls back the whole
/// test transaction, so each test that expects an error has exactly one asserterror, as its last action.
/// </summary>
codeunit 50154 "EQM Error Log Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        PlainTok: Label '%1', Locked = true;
        InsertNotAllowedTok: Label 'You cannot create error log entries directly. Entries are created when a monitoring job fails.', Locked = true;
        ModifyNotAllowedTok: Label 'You cannot change error log entry %1. The error log is read-only.', Locked = true;
        PlaceholderTextTok: Label 'EQMERR literal placeholder %1 ', Locked = true;
        ErrorCodeTok: Label 'EQMERR-CODE', Locked = true;
        CallStackTok: Label 'EQMERR call stack', Locked = true;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LogErrorStoresAllFields()
    var
        ErrorLogEntry: Record "EQM Error Log Entry";
        ErrorLogMgt: Codeunit "EQM Error Log Mgt.";
        StartEntryNo: Integer;
        ErrorText: Text;
        Before: DateTime;
        After: DateTime;
        Logged: Boolean;
    begin
        // [SCENARIO E1] LogError writes one entry with every field
        // [GIVEN] An open write transaction and an error text
        StartEntryNo := LastEntryNo();
        OpenWriteTransaction();
        ErrorText := NewErrorText();

        // [WHEN] LogError is called
        Before := CurrentDateTime();
        Logged := ErrorLogMgt.LogError("EQM Error Operation"::"Overdue Maintenance Job", Codeunit::"EQM Maintenance Monitor Job", ErrorText, ErrorCodeTok, CallStackTok);
        After := CurrentDateTime();

        // [THEN] It returns true and exactly one new entry holds all fields
        Assert.IsTrue(Logged, 'LogError should return true');
        ErrorLogEntry.SetFilter("Entry No.", '>%1', StartEntryNo);
        Assert.AreEqual(1, ErrorLogEntry.Count(), 'Exactly one entry should be written');
        ErrorLogEntry.FindFirst();
        Assert.AreEqual("EQM Error Operation"::"Overdue Maintenance Job", ErrorLogEntry.Operation, 'Operation should be stored');
        Assert.AreEqual(Codeunit::"EQM Maintenance Monitor Job", ErrorLogEntry."Object ID", 'Object ID should be stored');
        Assert.AreEqual(ErrorText, ErrorLogEntry."Error Message", 'Error message should be stored');
        Assert.AreEqual(ErrorCodeTok, ErrorLogEntry."Error Code", 'Error code should be stored');
        Assert.AreEqual(CallStackTok, ErrorLogEntry."Error Call Stack", 'Call stack should be stored');
        Assert.AreEqual(CopyStr(UserId(), 1, MaxStrLen(ErrorLogEntry."User ID")), ErrorLogEntry."User ID", 'User ID should be the current user');
        Assert.IsTrue((ErrorLogEntry."Logged At" >= Before) and (ErrorLogEntry."Logged At" <= After), 'Logged At should be the time of the call');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LogLastErrorStoresTheCaughtError()
    var
        ErrorLogEntry: Record "EQM Error Log Entry";
        ErrorLogMgt: Codeunit "EQM Error Log Mgt.";
        StartEntryNo: Integer;
        ErrorText: Text;
        ExpectedCode: Text;
        Logged: Boolean;
    begin
        // [SCENARIO E2] LogLastError stores the text, code and call stack of the last error
        // [GIVEN] A caught error, and an open write transaction
        StartEntryNo := LastEntryNo();
        ErrorText := NewErrorText();
        ClearLastError();
        Assert.IsFalse(TryRaise(ErrorText), 'TryRaise should fail');
        ExpectedCode := GetLastErrorCode();
        OpenWriteTransaction();

        // [WHEN] LogLastError is called
        Logged := ErrorLogMgt.LogLastError("EQM Error Operation"::"Warranty Alert Job", Codeunit::"EQM Warranty Alert Job");

        // [THEN] The entry holds the caught error
        Assert.IsTrue(Logged, 'LogLastError should return true');
        ErrorLogEntry.SetFilter("Entry No.", '>%1', StartEntryNo);
        Assert.AreEqual(1, ErrorLogEntry.Count(), 'Exactly one entry should be written');
        ErrorLogEntry.FindFirst();
        Assert.AreEqual(ErrorText, ErrorLogEntry."Error Message", 'Error message should be the caught text');
        Assert.AreEqual(ExpectedCode, ErrorLogEntry."Error Code", 'Error code should be the caught code');
        Assert.AreNotEqual('', ErrorLogEntry."Error Call Stack", 'Call stack should not be empty');
        Assert.AreEqual("EQM Error Operation"::"Warranty Alert Job", ErrorLogEntry.Operation, 'Operation should be stored');
        Assert.AreEqual(Codeunit::"EQM Warranty Alert Job", ErrorLogEntry."Object ID", 'Object ID should be stored');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LogLastErrorWithoutErrorLogsNothing()
    var
        ErrorLogEntry: Record "EQM Error Log Entry";
        ErrorLogMgt: Codeunit "EQM Error Log Mgt.";
        StartEntryNo: Integer;
        Logged: Boolean;
    begin
        // [SCENARIO E3] (negative) With no last error, nothing is written
        // [GIVEN] No last error, and an open write transaction
        StartEntryNo := LastEntryNo();
        ClearLastError();
        OpenWriteTransaction();

        // [WHEN] LogLastError is called
        Logged := ErrorLogMgt.LogLastError("EQM Error Operation"::"Warranty Alert Job", Codeunit::"EQM Warranty Alert Job");

        // [THEN] It returns false and no entry is written
        Assert.IsFalse(Logged, 'LogLastError should return false without an error');
        ErrorLogEntry.SetFilter("Entry No.", '>%1', StartEntryNo);
        Assert.IsTrue(ErrorLogEntry.IsEmpty(), 'No entry should be written');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LongErrorTextIsCutNotRejected()
    var
        ErrorLogEntry: Record "EQM Error Log Entry";
        ErrorLogMgt: Codeunit "EQM Error Log Mgt.";
        StartEntryNo: Integer;
        LongText: Text;
        Logged: Boolean;
    begin
        // [SCENARIO E4] (boundary) A text longer than the fields is cut and does not raise an error
        // [GIVEN] A message and a call stack of 3000 characters, and an open write transaction
        StartEntryNo := LastEntryNo();
        LongText := PadStr('', 3000, 'x');
        OpenWriteTransaction();

        // [WHEN] LogError is called
        Logged := ErrorLogMgt.LogError("EQM Error Operation"::"Warranty Alert Job", Codeunit::"EQM Warranty Alert Job", LongText, ErrorCodeTok, LongText);

        // [THEN] It returns true and the stored texts are cut to the field length
        Assert.IsTrue(Logged, 'LogError should return true for a long text');
        ErrorLogEntry.SetFilter("Entry No.", '>%1', StartEntryNo);
        ErrorLogEntry.FindFirst();
        Assert.AreEqual(MaxStrLen(ErrorLogEntry."Error Message"), StrLen(ErrorLogEntry."Error Message"), 'Message should be cut to the field length');
        Assert.AreEqual(CopyStr(LongText, 1, MaxStrLen(ErrorLogEntry."Error Message")), ErrorLogEntry."Error Message", 'Message should be the start of the text');
        Assert.AreEqual(MaxStrLen(ErrorLogEntry."Error Call Stack"), StrLen(ErrorLogEntry."Error Call Stack"), 'Call stack should be cut to the field length');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EntryCannotBeInsertedDirectly()
    var
        ErrorLogEntry: Record "EQM Error Log Entry";
    begin
        // [SCENARIO E5] (negative) An entry cannot be inserted without the log codeunit
        // [GIVEN] A new entry
        ErrorLogEntry.Init();

        // [WHEN] Insert(true) is called directly
        asserterror ErrorLogEntry.Insert(true);

        // [THEN] The insert-not-allowed error is raised
        Assert.ExpectedError(InsertNotAllowedTok);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EntryCannotBeModified()
    var
        ErrorLogEntry: Record "EQM Error Log Entry";
        StartEntryNo: Integer;
    begin
        // [SCENARIO E6] (negative) An entry cannot be changed
        // [GIVEN] A logged entry
        StartEntryNo := LastEntryNo();
        InsertEntry(NewErrorText());
        ErrorLogEntry.SetFilter("Entry No.", '>%1', StartEntryNo);
        ErrorLogEntry.FindFirst();

        // [WHEN] The entry is modified
        ErrorLogEntry."Error Message" := CopyStr(NewErrorText(), 1, MaxStrLen(ErrorLogEntry."Error Message"));
        asserterror ErrorLogEntry.Modify(true);

        // [THEN] The modify error with the entry number is raised
        Assert.ExpectedError(StrSubstNo(ModifyNotAllowedTok, ErrorLogEntry."Entry No."));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EntryCanBeDeleted()
    var
        ErrorLogEntry: Record "EQM Error Log Entry";
        StartEntryNo: Integer;
        EntryNo: Integer;
    begin
        // [SCENARIO E7] An entry can be deleted
        // [GIVEN] A logged entry
        StartEntryNo := LastEntryNo();
        InsertEntry(NewErrorText());
        ErrorLogEntry.SetFilter("Entry No.", '>%1', StartEntryNo);
        ErrorLogEntry.FindFirst();
        EntryNo := ErrorLogEntry."Entry No.";

        // [WHEN] The entry is deleted
        ErrorLogEntry.Delete(true);

        // [THEN] It no longer exists
        Assert.IsFalse(ErrorLogEntry.Get(EntryNo), 'The entry should be deleted');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure JobErrorInOpenWriteTransactionIsRaisedUnchanged()
    var
        JobQueueEntry: Record "Job Queue Entry";
        Subscriber: Codeunit "EQM Error Log Test Subscr";
        ErrorText: Text;
    begin
        // [SCENARIO E8] (negative) A job that starts inside an open write transaction runs as before: its error is raised unchanged
        // [GIVEN] An open write transaction, and a subscriber that makes the overdue maintenance job fail with a text that contains a placeholder
        OpenWriteTransaction();
        ErrorText := PlaceholderTextTok;
        ErrorText += NewErrorText();
        Subscriber.SetFailure(Codeunit::"EQM Maintenance Monitor Job", ErrorText);
        BindSubscription(Subscriber);

        // [WHEN] The job codeunit runs
        asserterror Codeunit.Run(Codeunit::"EQM Maintenance Monitor Job", JobQueueEntry);

        // [THEN] The error text is exactly the text of the failure, including the literal placeholder
        Assert.AreEqual(ErrorText, GetLastErrorText(), 'The error should be raised unchanged');
        Assert.AreEqual(1, Subscriber.GetRaisedCount(), 'The job should have started once');
    end;

    local procedure OpenWriteTransaction()
    var
        EquipmentCategory: Record "EQM Equipment Category";
    begin
        EquipmentCategory.Init();
        EquipmentCategory.Code := CopyStr(Format(CreateGuid()), 2, 20);
        EquipmentCategory.Insert();
        Assert.IsTrue(Database.IsInWriteTransaction(), 'A write transaction should be open');
    end;

    local procedure InsertEntry(ErrorText: Text)
    var
        ErrorLogMgt: Codeunit "EQM Error Log Mgt.";
    begin
        OpenWriteTransaction();
        Assert.IsTrue(
            ErrorLogMgt.LogError("EQM Error Operation"::"Warranty Alert Job", Codeunit::"EQM Warranty Alert Job", ErrorText, ErrorCodeTok, CallStackTok),
            'The entry should be written');
    end;

    local procedure LastEntryNo(): Integer
    var
        ErrorLogEntry: Record "EQM Error Log Entry";
    begin
        ErrorLogEntry.SetLoadFields("Entry No.");
        if ErrorLogEntry.FindLast() then
            exit(ErrorLogEntry."Entry No.");
        exit(0);
    end;

    local procedure NewErrorText(): Text
    begin
        exit('EQMERR ' + Format(CreateGuid()));
    end;

    [TryFunction]
    local procedure TryRaise(ErrorText: Text)
    begin
        Error(PlainTok, ErrorText);
    end;
}
