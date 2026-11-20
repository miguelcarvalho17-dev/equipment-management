namespace MiguelCarvalho.EquipmentManagement;

/// <summary>
/// Runs the body of a monitoring job and writes an error log entry when it fails. The job runs in its own
/// Codeunit.Run, so its failure rolls back only the job; the entry is written afterwards and survives.
/// </summary>
codeunit 50143 "EQM Monitoring Job Runner"
{
    Access = Internal;

    trigger OnRun()
    begin
        OnBeforeRunMonitoringJob(JobCodeunitId);
        case JobCodeunitId of
            Codeunit::"EQM Warranty Alert Job":
                RunWarrantyAlertJob();
            Codeunit::"EQM Maintenance Monitor Job":
                RunMaintenanceMonitorJob();
            Codeunit::"EQM Maintenance Calc. Job":
                RunMaintenanceCalculationJob();
        end;
    end;

    var
        JobCodeunitId: Integer;
        OriginalErrorTok: Label '%1', Locked = true;

    /// <summary>
    /// Runs the job body. When it fails, the error is written to the error log and raised again with the same text.
    /// When a write transaction is already open, the job runs as before: not isolated and not logged.
    /// </summary>
    /// <param name="JobCodeunitIdToRun">The ID of the job codeunit: 50111, 50114 or 50145.</param>
    /// <param name="Operation">The operation that the error log entry gets.</param>
    internal procedure RunJob(JobCodeunitIdToRun: Integer; Operation: Enum "EQM Error Operation")
    var
        JobRunner: Codeunit "EQM Monitoring Job Runner";
        ErrorLogMgt: Codeunit "EQM Error Log Mgt.";
        ErrorText: Text;
    begin
        JobRunner.SetJob(JobCodeunitIdToRun);
        if Database.IsInWriteTransaction() then begin
            JobRunner.Run();
            exit;
        end;
        ClearLastError();
        if JobRunner.Run() then
            exit;
        ErrorText := GetLastErrorText();
        ErrorLogMgt.LogLastError(Operation, JobCodeunitIdToRun);
        Error(OriginalErrorTok, ErrorText);
    end;

    /// <summary>
    /// Sets the job that the next Run of this codeunit instance runs.
    /// </summary>
    /// <param name="JobCodeunitIdToRun">The ID of the job codeunit: 50111, 50114 or 50145.</param>
    internal procedure SetJob(JobCodeunitIdToRun: Integer)
    begin
        JobCodeunitId := JobCodeunitIdToRun;
    end;

    /// <summary>
    /// Raised before the body of a monitoring job runs. Internal: used by the test app to make a job fail.
    /// </summary>
    /// <param name="JobCodeunitIdToRun">The ID of the job codeunit that is about to run.</param>
    [InternalEvent(false)]
    internal procedure OnBeforeRunMonitoringJob(JobCodeunitIdToRun: Integer)
    begin
    end;

    local procedure RunWarrantyAlertJob()
    var
        WarrantyAlertMgt: Codeunit "EQM Warranty Alert Mgt.";
        FeatureMgt: Codeunit "EQM Feature Mgt.";
        CreatedCount: Integer;
        CancelledCount: Integer;
    begin
        // Warranty Alerts turned off: no alerts are created. The warranty-expired business event is not part of the feature.
        if FeatureMgt.IsEnabled("EQM Feature"::"Warranty Alerts") then begin
            WarrantyAlertMgt.GenerateAlerts(Today(), true, CreatedCount, CancelledCount);
            // A failing partner subscriber of OnWarrantyExpired must not roll back the alerts that were just created.
            Commit();
        end;
        WarrantyAlertMgt.RaiseWarrantyExpiredEvents(Today());
    end;

    local procedure RunMaintenanceMonitorJob()
    var
        MaintenanceMgt: Codeunit "EQM Maintenance Mgt.";
    begin
        MaintenanceMgt.CheckOverdueMaintenance(Today(), true);
    end;

    local procedure RunMaintenanceCalculationJob()
    var
        MaintenanceMgt: Codeunit "EQM Maintenance Mgt.";
        FeatureMgt: Codeunit "EQM Feature Mgt.";
        CheckedCount: Integer;
        UpdatedCount: Integer;
        PlannedOverdueCount: Integer;
    begin
        // Maintenance Planning turned off: the planned dates are not recalculated.
        if not FeatureMgt.IsEnabled("EQM Feature"::"Maintenance Planning") then
            exit;
        // Commits per batch only when the job runs isolated; a transaction that a caller opened is never committed.
        MaintenanceMgt.RecalculateNextMaintenanceDates(Today(), true, not Database.IsInWriteTransaction(), CheckedCount, UpdatedCount, PlannedOverdueCount);
    end;
}
