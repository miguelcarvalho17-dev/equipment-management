namespace MiguelCarvalho.EquipmentManagement.Tests;

using MiguelCarvalho.EquipmentManagement;
using System.TestLibraries.Utilities;
using System.Threading;

/// <summary>
/// FR-054 Background Processing Optimization: the maintenance calculation job (codeunit 50145 and the recalculation in
/// "EQM Maintenance Mgt."), the three scheduled monitoring entries, and the warranty alert generation with its preloaded
/// alert keys. The jobs read every equipment of the company, so the assertions filter on the equipment of the test.
/// Everything runs in the test transaction, which is rolled back (AutoRollback). The write transaction stays open, so the
/// job runs unisolated and does not commit. A failed statement (asserterror) rolls back the test transaction, so a test
/// that expects an error has exactly one asserterror, as its last action.
/// </summary>
codeunit 50172 "EQM Background Process. Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        MaintenanceMgt: Codeunit "EQM Maintenance Mgt.";
        WarrantyAlertMgt: Codeunit "EQM Warranty Alert Mgt.";
        Counter: Integer;
        EquipmentNoTok: Label 'EQMBGP%1X', Locked = true;
        CategoryCodeTok: Label 'EQMBGPC%1', Locked = true;
        CounterFormatTok: Label '<Integer,4><Filler Character,0>', Locked = true;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RecalculationCorrectsAStaleDate()
    var
        Equipment: Record "EQM Equipment";
        CheckedCount: Integer;
        UpdatedCount: Integer;
        PlannedOverdueCount: Integer;
        ExpectedDate: Date;
    begin
        Initialize();
        // [SCENARIO BP1] A stale stored next maintenance date is corrected
        // [GIVEN] Equipment E with a plan whose stored next date was overwritten with a wrong date, without triggers
        CreateEquipmentWithPlan(Equipment, Today() - 1 - Random(365));
        ExpectedDate := Equipment."Next Maintenance Date";
        MakeStale(Equipment);

        // [WHEN] The recalculation runs
        MaintenanceMgt.RecalculateNextMaintenanceDates(Today(), false, false, CheckedCount, UpdatedCount, PlannedOverdueCount);

        // [THEN] The stored date is the calculated date again, and at least one date was updated
        Equipment.Get(Equipment."No.");
        Assert.AreEqual(ExpectedDate, Equipment."Next Maintenance Date", Equipment.FieldCaption("Next Maintenance Date"));
        Assert.IsTrue(UpdatedCount >= 1, 'At least one date should be updated');
        Assert.IsTrue(CheckedCount >= UpdatedCount, 'Every updated equipment should have been checked');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RecalculationDoesNotWriteACorrectRow()
    var
        Equipment: Record "EQM Equipment";
        CheckedCount: Integer;
        UpdatedCount: Integer;
        PlannedOverdueCount: Integer;
        StoredDate: Date;
        ModifiedAt: DateTime;
    begin
        Initialize();
        // [SCENARIO BP2] (negative) A row whose stored date is correct is not written
        // [GIVEN] Equipment E whose plan was set with triggers, and the recalculation already ran once
        CreateEquipmentWithPlan(Equipment, Today() - 1 - Random(365));
        MaintenanceMgt.RecalculateNextMaintenanceDates(Today(), false, false, CheckedCount, UpdatedCount, PlannedOverdueCount);
        Equipment.Get(Equipment."No.");
        StoredDate := Equipment."Next Maintenance Date";
        ModifiedAt := Equipment.SystemModifiedAt;

        // [WHEN] The recalculation runs again
        MaintenanceMgt.RecalculateNextMaintenanceDates(Today(), false, false, CheckedCount, UpdatedCount, PlannedOverdueCount);

        // [THEN] The date and the modified time of E are unchanged, and nothing was updated
        Equipment.Get(Equipment."No.");
        Assert.AreEqual(StoredDate, Equipment."Next Maintenance Date", Equipment.FieldCaption("Next Maintenance Date"));
        Assert.AreEqual(ModifiedAt, Equipment.SystemModifiedAt, Equipment.FieldCaption(SystemModifiedAt));
        Assert.AreEqual(0, UpdatedCount, 'The second run should update nothing');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RecalculationSkipsDisposedEquipment()
    var
        Equipment: Record "EQM Equipment";
        CheckedCount: Integer;
        UpdatedCount: Integer;
        PlannedOverdueCount: Integer;
        StaleDate: Date;
    begin
        Initialize();
        // [SCENARIO BP3] (negative) Equipment with a final status is not touched
        // [GIVEN] Equipment E with a stale next date that is then set to Disposed without triggers
        CreateEquipmentWithPlan(Equipment, Today() - 1 - Random(365));
        MakeStale(Equipment);
        StaleDate := Equipment."Next Maintenance Date";
        Equipment.Status := Equipment.Status::Disposed;
        Equipment.Modify(false);

        // [WHEN] The recalculation runs
        MaintenanceMgt.RecalculateNextMaintenanceDates(Today(), false, false, CheckedCount, UpdatedCount, PlannedOverdueCount);

        // [THEN] The stale date is kept
        Equipment.Get(Equipment."No.");
        Assert.AreEqual(StaleDate, Equipment."Next Maintenance Date", Equipment.FieldCaption("Next Maintenance Date"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RecalculationClearsTheDateWhenThePlanIsRemoved()
    var
        Equipment: Record "EQM Equipment";
        CheckedCount: Integer;
        UpdatedCount: Integer;
        PlannedOverdueCount: Integer;
    begin
        Initialize();
        // [SCENARIO BP4] The next date is cleared when the plan was removed
        // [GIVEN] Equipment E whose frequency was set to 0 without triggers while the next date is still filled
        CreateEquipmentWithPlan(Equipment, Today() - 1 - Random(365));
        Assert.AreNotEqual(0D, Equipment."Next Maintenance Date", Equipment.FieldCaption("Next Maintenance Date"));
        Equipment."Maintenance Frequency (Months)" := 0;
        Equipment.Modify(false);

        // [WHEN] The recalculation runs
        MaintenanceMgt.RecalculateNextMaintenanceDates(Today(), false, false, CheckedCount, UpdatedCount, PlannedOverdueCount);

        // [THEN] The next date is blank
        Equipment.Get(Equipment."No.");
        Assert.AreEqual(0D, Equipment."Next Maintenance Date", Equipment.FieldCaption("Next Maintenance Date"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RecalculationCountsPlannedOverdueEquipment()
    var
        Equipment: Record "EQM Equipment";
        CheckedCount: Integer;
        UpdatedCount: Integer;
        PlannedOverdueCount: Integer;
        BaselineOverdueCount: Integer;
    begin
        Initialize();
        // [SCENARIO BP5] Equipment whose planned date is before the reference date is counted
        // [GIVEN] A baseline run, then equipment E whose next date is before today
        MaintenanceMgt.RecalculateNextMaintenanceDates(Today(), false, false, CheckedCount, UpdatedCount, BaselineOverdueCount);
        CreateEquipmentWithPlan(Equipment, Today() - 400 - Random(300));
        Assert.IsTrue(Equipment."Next Maintenance Date" < Today(), 'The next date should be before today');

        // [WHEN] The recalculation runs again
        MaintenanceMgt.RecalculateNextMaintenanceDates(Today(), false, false, CheckedCount, UpdatedCount, PlannedOverdueCount);

        // [THEN] The planned overdue count is one higher than the baseline
        Assert.AreEqual(BaselineOverdueCount + 1, PlannedOverdueCount, 'Planned overdue count');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure JobDoesNothingWhenMaintenancePlanningIsOff()
    var
        Equipment: Record "EQM Equipment";
        JobQueueEntry: Record "Job Queue Entry";
        FeatureMgt: Codeunit "EQM Feature Mgt.";
        StaleDate: Date;
    begin
        Initialize();
        // [SCENARIO BP6] (negative) With Maintenance Planning off, the job changes nothing and raises no error
        // [GIVEN] Maintenance Planning is turned off, and equipment E has a stale next date
        FeatureMgt.SetFeatureEnabled(Enum::"EQM Feature"::"Maintenance Planning", false);
        CreateEquipmentWithPlan(Equipment, Today() - 1 - Random(365));
        MakeStale(Equipment);
        StaleDate := Equipment."Next Maintenance Date";

        // [WHEN] The job codeunit runs
        Codeunit.Run(Codeunit::"EQM Maintenance Calc. Job", JobQueueEntry);

        // [THEN] The stale date is unchanged
        Equipment.Get(Equipment."No.");
        Assert.AreEqual(StaleDate, Equipment."Next Maintenance Date", Equipment.FieldCaption("Next Maintenance Date"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MaintCalcJobCorrectsStaleDate()
    var
        Equipment: Record "EQM Equipment";
        JobQueueEntry: Record "Job Queue Entry";
        ExpectedDate: Date;
    begin
        Initialize();
        // [SCENARIO BP7] The job codeunit corrects a stale date
        // [GIVEN] Maintenance Planning is on, and equipment E has a stale next date. A write transaction is open, so the job
        // runs unisolated and does not commit
        CreateEquipmentWithPlan(Equipment, Today() - 1 - Random(365));
        ExpectedDate := Equipment."Next Maintenance Date";
        MakeStale(Equipment);
        Assert.IsTrue(Database.IsInWriteTransaction(), 'A write transaction should be open');

        // [WHEN] The job codeunit runs
        Codeunit.Run(Codeunit::"EQM Maintenance Calc. Job", JobQueueEntry);

        // [THEN] The stored date is the calculated date again
        Equipment.Get(Equipment."No.");
        Assert.AreEqual(ExpectedDate, Equipment."Next Maintenance Date", Equipment.FieldCaption("Next Maintenance Date"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EnsureCreatesNothingWhenAllThreeEntriesExist()
    var
        MonitoringJobMgt: Codeunit "EQM Monitoring Job Mgt.";
        CreatedCount: Integer;
        ExistingCount: Integer;
    begin
        // [SCENARIO BP8] (negative) Ensure creates nothing when an entry exists for each of the three jobs
        // [GIVEN] One on-hold entry for each of the three job codeunits
        DeleteJobEntries();
        InsertJobEntry(Codeunit::"EQM Warranty Alert Job");
        InsertJobEntry(Codeunit::"EQM Maintenance Monitor Job");
        InsertJobEntry(Codeunit::"EQM Maintenance Calc. Job");

        // [WHEN] The monitoring jobs are ensured
        MonitoringJobMgt.EnsureMonitoringJobs(CreatedCount, ExistingCount, '');

        // [THEN] Nothing is created, three exist, there is one entry per job, and the status is unchanged
        Assert.AreEqual(0, CreatedCount, 'Created count');
        Assert.AreEqual(3, ExistingCount, 'Existing count');
        AssertOneOnHoldEntry(Codeunit::"EQM Warranty Alert Job");
        AssertOneOnHoldEntry(Codeunit::"EQM Maintenance Monitor Job");
        AssertOneOnHoldEntry(Codeunit::"EQM Maintenance Calc. Job");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure JobExistsIsFalseWithoutAnEntry()
    var
        MonitoringJobMgt: Codeunit "EQM Monitoring Job Mgt.";
    begin
        // [SCENARIO BP9a] (negative) JobExists is false when no entry runs the maintenance calculation job
        // [GIVEN] The entries of the job are deleted
        DeleteJobEntries();

        // [WHEN] [THEN] JobExists is false
        Assert.IsFalse(MonitoringJobMgt.JobExists(Codeunit::"EQM Maintenance Calc. Job"), 'JobExists');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure JobExistsIsTrueWithAnEntry()
    var
        MonitoringJobMgt: Codeunit "EQM Monitoring Job Mgt.";
    begin
        // [SCENARIO BP9b] JobExists is true when an entry runs the maintenance calculation job
        // [GIVEN] The entries of the job are deleted, then one is inserted directly
        DeleteJobEntries();
        InsertJobEntry(Codeunit::"EQM Maintenance Calc. Job");

        // [WHEN] [THEN] JobExists is true
        Assert.IsTrue(MonitoringJobMgt.JobExists(Codeunit::"EQM Maintenance Calc. Job"), 'JobExists');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AcknowledgedAlertBlocksRecreation()
    var
        Equipment: Record "EQM Equipment";
        WarrantyAlert: Record "EQM Warranty Alert";
        CreatedCount: Integer;
        CancelledCount: Integer;
    begin
        Initialize();
        // [SCENARIO BP-W1] (negative) An acknowledged alert blocks creating the same alert again
        // [GIVEN] Equipment E whose warranty ends soon, alerts generated once, and the alert acknowledged
        CreateEquipment(Equipment, Today() + 1 + Random(20));
        WarrantyAlertMgt.GenerateAlerts(Today(), false, CreatedCount, CancelledCount);
        WarrantyAlert.SetRange("Equipment No.", Equipment."No.");
        WarrantyAlertMgt.AcknowledgeAlerts(WarrantyAlert);

        // [WHEN] The alerts are generated again
        WarrantyAlertMgt.GenerateAlerts(Today(), false, CreatedCount, CancelledCount);

        // [THEN] E still has exactly one alert, and it is acknowledged
        WarrantyAlert.Reset();
        WarrantyAlert.SetRange("Equipment No.", Equipment."No.");
        Assert.RecordCount(WarrantyAlert, 1);
        WarrantyAlert.FindFirst();
        Assert.AreEqual(WarrantyAlert.Status::Acknowledged, WarrantyAlert.Status, WarrantyAlert.FieldCaption(Status));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AlertOfAnotherIntervalDoesNotBlockTheDueOne()
    var
        Equipment: Record "EQM Equipment";
        WarrantyAlert: Record "EQM Warranty Alert";
        CreatedCount: Integer;
        CancelledCount: Integer;
    begin
        Initialize();
        // [SCENARIO BP-W2] An open alert of another interval does not block the due interval
        // [GIVEN] Equipment E whose warranty ends within 30 days, and an open 90 Days alert for the same end date
        CreateEquipment(Equipment, Today() + 1 + Random(20));
        WarrantyAlert.Init();
        WarrantyAlert."Equipment No." := Equipment."No.";
        WarrantyAlert."Alert Interval" := WarrantyAlert."Alert Interval"::"90 Days";
        WarrantyAlert."Warranty End Date" := Equipment."Warranty End Date";
        WarrantyAlert."Alert Date" := Today();
        WarrantyAlert.Status := WarrantyAlert.Status::Open;
        WarrantyAlert.Insert(true);

        // [WHEN] The alerts are generated
        WarrantyAlertMgt.GenerateAlerts(Today(), false, CreatedCount, CancelledCount);

        // [THEN] E also has a 30 Days alert
        WarrantyAlert.Reset();
        WarrantyAlert.SetRange("Equipment No.", Equipment."No.");
        WarrantyAlert.SetRange("Alert Interval", WarrantyAlert."Alert Interval"::"30 Days");
        Assert.RecordCount(WarrantyAlert, 1);
    end;

    local procedure Initialize()
    var
        FeatureSetup: Record "EQM Feature Setup";
        EquipmentSetup: Record "EQM Equipment Setup";
    begin
        // Everything runs in the test transaction, which is rolled back (AutoRollback), so nothing is committed or cleaned up.
        FeatureSetup.DeleteAll();
        if not EquipmentSetup.Get() then begin
            EquipmentSetup.Init();
            EquipmentSetup.Insert(false);
        end;
        EquipmentSetup."Default Warranty Alert Days" := WarrantyAlertMgt.GetLongestIntervalDays();
        EquipmentSetup.Modify(false);
    end;

    local procedure NextId(): Text
    begin
        Counter += 1;
        exit(Format(Counter, 0, CounterFormatTok));
    end;

    local procedure CreateEquipment(var Equipment: Record "EQM Equipment"; WarrantyEndDate: Date)
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
        Equipment."Warranty End Date" := WarrantyEndDate;
        Equipment.Insert(true);
    end;

    local procedure CreateEquipmentWithPlan(var Equipment: Record "EQM Equipment"; LastMaintenanceDate: Date)
    begin
        CreateEquipment(Equipment, 0D);
        Equipment."Maintenance Frequency (Months)" := 1 + Random(12);
        Equipment."Last Maintenance Date" := LastMaintenanceDate;
        Equipment.Modify(true);
        Equipment.Get(Equipment."No.");
    end;

    // Overwrites the stored next date with a wrong date, without triggers.
    local procedure MakeStale(var Equipment: Record "EQM Equipment")
    begin
        Equipment."Next Maintenance Date" := Equipment."Next Maintenance Date" + 1 + Random(100);
        Equipment.Modify(false);
    end;

    local procedure DeleteJobEntries()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetFilter(
            "Object ID to Run", '%1|%2|%3', Codeunit::"EQM Warranty Alert Job", Codeunit::"EQM Maintenance Monitor Job", Codeunit::"EQM Maintenance Calc. Job");
        JobQueueEntry.DeleteAll(false);
    end;

    local procedure InsertJobEntry(CodeunitId: Integer)
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.Init();
        JobQueueEntry.ID := CreateGuid();
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := CodeunitId;
        JobQueueEntry.Status := JobQueueEntry.Status::"On Hold";
        JobQueueEntry.Insert(false);
    end;

    local procedure AssertOneOnHoldEntry(CodeunitId: Integer)
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", CodeunitId);
        Assert.RecordCount(JobQueueEntry, 1);
        JobQueueEntry.FindFirst();
        Assert.AreEqual(JobQueueEntry.Status::"On Hold", JobQueueEntry.Status, JobQueueEntry.FieldCaption(Status));
    end;
}
