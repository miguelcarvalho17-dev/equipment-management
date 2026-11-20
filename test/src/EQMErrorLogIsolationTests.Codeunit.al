namespace MiguelCarvalho.EquipmentManagement.Tests;

using MiguelCarvalho.EquipmentManagement;
using System.TestLibraries.Utilities;
using System.Threading;

/// <summary>
/// Tests for FR-051 Error Logging, scenarios I1 to I3: a failing monitoring job writes an entry that survives the
/// rollback of the job, and the job still fails with the original text. The entry is committed by the platform, so
/// each test commits first, reads the new entries into variables, deletes them and commits again before it asserts.
/// A failed statement (asserterror) rolls back the transaction, so each test has exactly one asserterror.
/// </summary>
codeunit 50155 "EQM Error Log Isolation Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        PlaceholderTextTok: Label 'EQMERR literal placeholder %1 ', Locked = true;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure MonitorJobFailureIsLoggedAndJobStillFails()
    var
        FirstEntry: Record "EQM Error Log Entry";
        JobQueueEntry: Record "Job Queue Entry";
        Subscriber: Codeunit "EQM Error Log Test Subscr";
        StartEntryNo: Integer;
        EntryCount: Integer;
        ErrorText: Text;
        RaisedText: Text;
    begin
        // [SCENARIO I1] A failing overdue maintenance job writes one committed entry and still fails with the same text
        // [GIVEN] No open write transaction, and a subscriber that makes the job fail with a text that contains a placeholder
        PrepareWithoutWriteTransaction(StartEntryNo);
        ErrorText := PlaceholderTextTok;
        ErrorText += Format(CreateGuid());
        Subscriber.SetFailure(Codeunit::"EQM Maintenance Monitor Job", ErrorText);
        BindSubscription(Subscriber);

        // [WHEN] The job codeunit runs
        asserterror Codeunit.Run(Codeunit::"EQM Maintenance Monitor Job", JobQueueEntry);
        RaisedText := GetLastErrorText();
        EntryCount := TakeNewEntries(StartEntryNo, FirstEntry);

        // [THEN] The job failed with the original text, and exactly one entry holds the failure
        Assert.AreEqual(ErrorText, RaisedText, 'The job should fail with the original text');
        Assert.AreEqual(1, EntryCount, 'Exactly one entry should be written');
        Assert.AreEqual("EQM Error Operation"::"Overdue Maintenance Job", FirstEntry.Operation, 'Operation should be the overdue maintenance job');
        Assert.AreEqual(Codeunit::"EQM Maintenance Monitor Job", FirstEntry."Object ID", 'Object ID should be the job codeunit');
        Assert.AreEqual(ErrorText, FirstEntry."Error Message", 'Error message should be the original text');
        Assert.AreEqual(CopyStr(UserId(), 1, MaxStrLen(FirstEntry."User ID")), FirstEntry."User ID", 'User ID should be the current user');
        Assert.AreNotEqual('', FirstEntry."Error Call Stack", 'Call stack should not be empty');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure WarrantyJobFailureIsLoggedWithItsOperation()
    var
        FirstEntry: Record "EQM Error Log Entry";
        JobQueueEntry: Record "Job Queue Entry";
        Subscriber: Codeunit "EQM Error Log Test Subscr";
        StartEntryNo: Integer;
        EntryCount: Integer;
        ErrorText: Text;
        RaisedText: Text;
    begin
        // [SCENARIO I2] A failing warranty alert job writes one committed entry with its own operation
        // [GIVEN] No open write transaction, and a subscriber that makes the job fail
        PrepareWithoutWriteTransaction(StartEntryNo);
        ErrorText := PlaceholderTextTok;
        ErrorText += Format(CreateGuid());
        Subscriber.SetFailure(Codeunit::"EQM Warranty Alert Job", ErrorText);
        BindSubscription(Subscriber);

        // [WHEN] The job codeunit runs
        asserterror Codeunit.Run(Codeunit::"EQM Warranty Alert Job", JobQueueEntry);
        RaisedText := GetLastErrorText();
        EntryCount := TakeNewEntries(StartEntryNo, FirstEntry);

        // [THEN] The job failed with the original text, and exactly one entry holds the failure
        Assert.AreEqual(ErrorText, RaisedText, 'The job should fail with the original text');
        Assert.AreEqual(1, EntryCount, 'Exactly one entry should be written');
        Assert.AreEqual("EQM Error Operation"::"Warranty Alert Job", FirstEntry.Operation, 'Operation should be the warranty alert job');
        Assert.AreEqual(Codeunit::"EQM Warranty Alert Job", FirstEntry."Object ID", 'Object ID should be the job codeunit');
        Assert.AreEqual(ErrorText, FirstEntry."Error Message", 'Error message should be the original text');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure SuccessfulMonitorJobLogsNothing()
    var
        FirstEntry: Record "EQM Error Log Entry";
        JobQueueEntry: Record "Job Queue Entry";
        Subscriber: Codeunit "EQM Error Log Test Subscr";
        StartEntryNo: Integer;
        EntryCount: Integer;
    begin
        // [SCENARIO I3] (negative) A job that does not fail writes no entry
        // [GIVEN] No open write transaction, and a subscriber that fails no job
        PrepareWithoutWriteTransaction(StartEntryNo);
        BindSubscription(Subscriber);

        // [WHEN] The job codeunit runs
        Codeunit.Run(Codeunit::"EQM Maintenance Monitor Job", JobQueueEntry);
        EntryCount := TakeNewEntries(StartEntryNo, FirstEntry);

        // [THEN] The job body started once and no entry was written
        Assert.AreEqual(1, Subscriber.GetRaisedCount(), 'The job should have started once');
        Assert.AreEqual(0, EntryCount, 'No entry should be written');
    end;

    local procedure PrepareWithoutWriteTransaction(var StartEntryNo: Integer)
    var
        ErrorLogEntry: Record "EQM Error Log Entry";
    begin
        Commit();
        Assert.IsFalse(Database.IsInWriteTransaction(), 'No write transaction should be open');
        ErrorLogEntry.SetLoadFields("Entry No.");
        if ErrorLogEntry.FindLast() then
            StartEntryNo := ErrorLogEntry."Entry No."
        else
            StartEntryNo := 0;
    end;

    // Reads the first new entry into FirstEntry, then deletes all new entries and commits, so no test leaves entries behind.
    local procedure TakeNewEntries(StartEntryNo: Integer; var FirstEntry: Record "EQM Error Log Entry"): Integer
    var
        NewEntries: Record "EQM Error Log Entry";
        EntryCount: Integer;
    begin
        NewEntries.SetFilter("Entry No.", '>%1', StartEntryNo);
        EntryCount := NewEntries.Count();
        if NewEntries.FindFirst() then
            FirstEntry := NewEntries;
        NewEntries.DeleteAll(true);
        Commit();
        exit(EntryCount);
    end;
}
