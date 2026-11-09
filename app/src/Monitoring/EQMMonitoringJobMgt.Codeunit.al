namespace MiguelCarvalho.EquipmentManagement;

using System.Threading;

// Permission design: the job queue entries are created in this codeunit. The Permissions property grants
// INDIRECT permissions only: it works only with matching rights in the user's permission sets
// (EQM - Administrator has indirect rim on Job Queue Entry). The category table has inherent permissions.
// Creating an entry also needs Execute on the target codeunit, which EQM - Reader gives.
/// <summary>
/// Creates the job queue entries that run the equipment monitoring every day, and shows their state.
/// </summary>
codeunit 50115 "EQM Monitoring Job Mgt."
{
    Access = Internal;
    Permissions = tabledata "Job Queue Entry" = rim;

    trigger OnRun()
    var
        CreatedCount: Integer;
        ExistingCount: Integer;
    begin
        EnsureMonitoringJobs(CreatedCount, ExistingCount, CallerTrigger);
    end;

    var
        CallerTrigger: Text;
        JobQueueCategoryCodeTok: Label 'EQM', Locked = true;
        JobQueueCategoryDescTxt: Label 'Equipment Management', MaxLength = 30;
        WarrantyJobDescTxt: Label 'Equipment Management: create warranty alerts', MaxLength = 250;
        MaintenanceJobDescTxt: Label 'Equipment Management: check overdue maintenance', MaxLength = 250;
        NotScheduledTxt: Label 'Not scheduled', Comment = 'Shown on Equipment Setup when no job queue entry exists for the monitoring job.';
        DailyFormulaTok: Label '<1D>', Locked = true;
        JobsScheduledTelemetryTok: Label 'EQM0003', Locked = true;
        JobsScheduledTelemetryMsg: Label 'Monitoring job queue entries ensured.', Locked = true;
        JobsNotScheduledTelemetryTok: Label 'EQM0004', Locked = true;
        JobsNotScheduledTelemetryMsg: Label 'Monitoring job queue entries could not be created.', Locked = true;
        InstallTriggerTok: Label 'Install', Locked = true;
        SetupTriggerTok: Label 'SetupCreated', Locked = true;
        ActionTriggerTok: Label 'Action', Locked = true;
        CreatedDimTok: Label 'Created', Locked = true;
        ExistingDimTok: Label 'Existing', Locked = true;
        TriggerDimTok: Label 'Trigger', Locked = true;
        ReasonDimTok: Label 'Reason', Locked = true;
        ErrorCodeDimTok: Label 'ErrorCode', Locked = true;
        CannotCreateTaskReasonTok: Label 'CannotCreateTask', Locked = true;
        ErrorReasonTok: Label 'Error', Locked = true;
        WriteTransactionReasonTok: Label 'WriteTransaction', Locked = true;

    /// <summary>
    /// Returns the trigger name used in telemetry when the app is installed.
    /// </summary>
    /// <returns>The trigger name.</returns>
    internal procedure GetInstallTrigger(): Text
    begin
        exit(InstallTriggerTok);
    end;

    /// <summary>
    /// Returns the trigger name used in telemetry when the setup is created on first use.
    /// </summary>
    /// <returns>The trigger name.</returns>
    internal procedure GetSetupTrigger(): Text
    begin
        exit(SetupTriggerTok);
    end;

    /// <summary>
    /// Returns the trigger name used in telemetry when a user runs the schedule action.
    /// </summary>
    /// <returns>The trigger name.</returns>
    internal procedure GetActionTrigger(): Text
    begin
        exit(ActionTriggerTok);
    end;

    /// <summary>
    /// Sets the trigger name that OnRun passes to the ensure procedure.
    /// </summary>
    /// <param name="TriggerTok">The trigger name.</param>
    internal procedure SetCallerTrigger(TriggerTok: Text)
    begin
        CallerTrigger := TriggerTok;
    end;

    /// <summary>
    /// Creates the missing monitoring job queue entries without raising an error. Returns false and logs telemetry
    /// when they cannot be created, for example when the user cannot schedule tasks. Call it only when no write
    /// transaction is open.
    /// </summary>
    /// <param name="TriggerTok">The trigger name for telemetry.</param>
    /// <returns>True when the entries exist afterwards; false when they could not be created.</returns>
    internal procedure TryEnsureMonitoringJobs(TriggerTok: Text): Boolean
    var
        MonitoringJobMgt: Codeunit "EQM Monitoring Job Mgt.";
    begin
        if Database.IsInWriteTransaction() then begin
            LogNotScheduled(TriggerTok, WriteTransactionReasonTok, '');
            exit(false);
        end;
        if not TaskScheduler.CanCreateTask() then begin
            LogNotScheduled(TriggerTok, CannotCreateTaskReasonTok, '');
            exit(false);
        end;
        MonitoringJobMgt.SetCallerTrigger(TriggerTok);
        ClearLastError();
        if MonitoringJobMgt.Run() then
            exit(true);
        LogNotScheduled(TriggerTok, ErrorReasonTok, GetLastErrorCode());
        exit(false);
    end;

    /// <summary>
    /// Creates a daily recurring job queue entry for each monitoring job that has no entry in this company yet.
    /// Existing entries are never changed, whatever their status.
    /// </summary>
    /// <param name="CreatedCount">Returns the number of entries created.</param>
    /// <param name="ExistingCount">Returns the number of entries that already existed.</param>
    /// <param name="TriggerTok">The trigger name for telemetry.</param>
    internal procedure EnsureMonitoringJobs(var CreatedCount: Integer; var ExistingCount: Integer; TriggerTok: Text)
    begin
        CreatedCount := 0;
        ExistingCount := 0;
        EnsureJobQueueCategory();
        EnsureJob(Codeunit::"EQM Warranty Alert Job", WarrantyJobDescTxt, CreatedCount, ExistingCount);
        EnsureJob(Codeunit::"EQM Maintenance Monitor Job", MaintenanceJobDescTxt, CreatedCount, ExistingCount);
        LogScheduled(TriggerTok, CreatedCount, ExistingCount);
    end;

    local procedure EnsureJob(CodeunitId: Integer; JobDescription: Text; var CreatedCount: Integer; var ExistingCount: Integer)
    begin
        if JobExists(CodeunitId) then
            ExistingCount += 1
        else begin
            CreateRecurringJob(CodeunitId, JobDescription);
            CreatedCount += 1;
        end;
    end;

    /// <summary>
    /// Returns whether a job queue entry for the codeunit exists in this company, whatever its status, category or user.
    /// </summary>
    /// <param name="CodeunitId">The codeunit ID that the entry runs.</param>
    /// <returns>True when an entry exists.</returns>
    internal procedure JobExists(CodeunitId: Integer): Boolean
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        SetJobFilter(JobQueueEntry, CodeunitId);
        exit(not JobQueueEntry.IsEmpty());
    end;

    local procedure SetJobFilter(var JobQueueEntry: Record "Job Queue Entry"; CodeunitId: Integer)
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", CodeunitId);
    end;

    // The only place that decides how an entry is created and made ready. It uses the standard public
    // procedure for a recurring codeunit entry (category, attempts, daily formula, start time); that procedure
    // enqueues the entry itself.
    local procedure CreateRecurringJob(CodeunitId: Integer; JobDescription: Text)
    var
        JobQueueEntry: Record "Job Queue Entry";
        NoRecordId: RecordId;
        DailyFormula: DateFormula;
    begin
        Evaluate(DailyFormula, DailyFormulaTok);
        JobQueueEntry.ScheduleRecurrentJobQueueEntryWithRunDateFormula(
            JobQueueEntry."Object Type to Run"::Codeunit, CodeunitId, NoRecordId, GetJobQueueCategoryCode(), 3, DailyFormula, 060000T);
        JobQueueEntry.Description := CopyStr(JobDescription, 1, MaxStrLen(JobQueueEntry.Description));
        JobQueueEntry.Modify(true);
    end;

    local procedure EnsureJobQueueCategory()
    var
        JobQueueCategory: Record "Job Queue Category";
    begin
        if JobQueueCategory.Get(GetJobQueueCategoryCode()) then
            exit;
        JobQueueCategory.Init();
        JobQueueCategory.Code := GetJobQueueCategoryCode();
        JobQueueCategory.Description := CopyStr(JobQueueCategoryDescTxt, 1, MaxStrLen(JobQueueCategory.Description));
        JobQueueCategory.Insert(true);
    end;

    local procedure GetJobQueueCategoryCode(): Code[10]
    begin
        exit(CopyStr(JobQueueCategoryCodeTok, 1, 10));
    end;

    /// <summary>
    /// Returns the status caption of the job queue entry that runs the codeunit.
    /// </summary>
    /// <param name="CodeunitId">The codeunit ID that the entry runs.</param>
    /// <returns>The status caption, Not scheduled when no entry exists, or blank when the user cannot read entries.</returns>
    internal procedure GetJobStatusText(CodeunitId: Integer): Text
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        if not JobQueueEntry.ReadPermission() then
            exit('');
        SetJobFilter(JobQueueEntry, CodeunitId);
        JobQueueEntry.SetLoadFields(Status);
        if JobQueueEntry.FindFirst() then
            exit(Format(JobQueueEntry.Status));
        exit(NotScheduledTxt);
    end;

    /// <summary>
    /// Opens the job queue entries that run the equipment monitoring.
    /// </summary>
    internal procedure ShowMonitoringJobs()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetFilter("Object ID to Run", '%1|%2', Codeunit::"EQM Warranty Alert Job", Codeunit::"EQM Maintenance Monitor Job");
        Page.Run(Page::"Job Queue Entries", JobQueueEntry);
    end;

    local procedure LogScheduled(TriggerTok: Text; CreatedCount: Integer; ExistingCount: Integer)
    var
        Dimensions: Dictionary of [Text, Text];
    begin
        Dimensions.Add(CreatedDimTok, Format(CreatedCount, 0, 9));
        Dimensions.Add(ExistingDimTok, Format(ExistingCount, 0, 9));
        Dimensions.Add(TriggerDimTok, TriggerTok);
        Session.LogMessage(JobsScheduledTelemetryTok, JobsScheduledTelemetryMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, Dimensions);
    end;

    local procedure LogNotScheduled(TriggerTok: Text; ReasonTok: Text; ErrorCode: Text)
    var
        Dimensions: Dictionary of [Text, Text];
    begin
        Dimensions.Add(TriggerDimTok, TriggerTok);
        Dimensions.Add(ReasonDimTok, ReasonTok);
        Dimensions.Add(ErrorCodeDimTok, ErrorCode);
        Session.LogMessage(JobsNotScheduledTelemetryTok, JobsNotScheduledTelemetryMsg, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::All, Dimensions);
    end;
}
