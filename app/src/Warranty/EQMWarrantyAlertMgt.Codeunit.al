namespace MiguelCarvalho.EquipmentManagement;

/// <summary>
/// Creates, cancels and acknowledges warranty alerts.
/// </summary>
codeunit 50110 "EQM Warranty Alert Mgt."
{
    Access = Internal;

    var
        NothingToAcknowledgeErr: Label 'The selected warranty alerts are already acknowledged or cancelled.';
        AlertsGeneratedTelemetryTok: Label 'EQM0001', Locked = true;
        AlertsGeneratedTelemetryMsg: Label 'Warranty alerts generated.', Locked = true;
        ScheduledTok: Label 'JobQueue', Locked = true;
        ManualTok: Label 'Manual', Locked = true;
        AlertsCreatedDimTok: Label 'AlertsCreated', Locked = true;
        AlertsCancelledDimTok: Label 'AlertsCancelled', Locked = true;
        ReferenceDateDimTok: Label 'ReferenceDate', Locked = true;
        TriggerDimTok: Label 'Trigger', Locked = true;

    /// <summary>
    /// Returns the number of days before the warranty end date at which the interval is due.
    /// </summary>
    /// <param name="AlertInterval">The alert interval.</param>
    /// <returns>The number of days.</returns>
    internal procedure GetIntervalDays(AlertInterval: Enum "EQM Warranty Alert Interval"): Integer
    begin
        case AlertInterval of
            AlertInterval::"30 Days":
                exit(30);
            AlertInterval::"60 Days":
                exit(60);
            AlertInterval::"90 Days":
                exit(90);
            else
                exit(0);
        end;
    end;

    /// <summary>
    /// Returns the number of days of the longest alert interval.
    /// </summary>
    /// <returns>The number of days.</returns>
    internal procedure GetLongestIntervalDays(): Integer
    begin
        exit(GetIntervalDays("EQM Warranty Alert Interval"::"90 Days"));
    end;

    /// <summary>
    /// Finds the most urgent interval that is due for the number of days left. False when the warranty has ended or is
    /// more than 90 days away.
    /// </summary>
    /// <param name="DaysRemaining">The days from the reference date to the warranty end date.</param>
    /// <param name="AlertInterval">Returns the due interval.</param>
    /// <returns>True when an interval is due.</returns>
    internal procedure FindDueInterval(DaysRemaining: Integer; var AlertInterval: Enum "EQM Warranty Alert Interval"): Boolean
    begin
        if (DaysRemaining < 0) or (DaysRemaining > GetLongestIntervalDays()) then
            exit(false);

        if DaysRemaining <= GetIntervalDays("EQM Warranty Alert Interval"::"30 Days") then begin
            AlertInterval := "EQM Warranty Alert Interval"::"30 Days";
            exit(true);
        end;
        if DaysRemaining <= GetIntervalDays("EQM Warranty Alert Interval"::"60 Days") then begin
            AlertInterval := "EQM Warranty Alert Interval"::"60 Days";
            exit(true);
        end;
        if DaysRemaining <= GetIntervalDays("EQM Warranty Alert Interval"::"90 Days") then begin
            AlertInterval := "EQM Warranty Alert Interval"::"90 Days";
            exit(true);
        end;
        exit(false);
    end;

    /// <summary>
    /// Cancels open alerts that no longer apply and creates the due alert for each piece of equipment whose warranty
    /// ends within 90 days of the reference date. Each interval is created once per equipment and warranty end date. 0D
    /// means today.
    /// </summary>
    /// <param name="ReferenceDate">The date the days remaining are counted from. 0D means today.</param>
    /// <param name="IsScheduled">True when the run comes from the job queue, false when a user started it.</param>
    /// <param name="CreatedCount">Returns the number of alerts created.</param>
    /// <param name="CancelledCount">Returns the number of alerts cancelled.</param>
    internal procedure GenerateAlerts(ReferenceDate: Date; IsScheduled: Boolean; var CreatedCount: Integer; var CancelledCount: Integer)
    var
        WarrantyAlert: Record "EQM Warranty Alert";
        Equipment: Record "EQM Equipment";
        AlertInterval: Enum "EQM Warranty Alert Interval";
        WarrantyStatus: Enum "EQM Warranty Status";
    begin
        CreatedCount := 0;
        CancelledCount := 0;
        if ReferenceDate = 0D then
            ReferenceDate := Today();

        // Reduces concurrent runs (job queue and manual) creating the same alert twice. It does not fully prevent it:
        // on the first run there may be no rows to lock yet, so a residual duplicate risk remains (plan R5).
        WarrantyAlert.LockTable();
        CancelledCount := CancelStaleAlerts();

        Equipment.SetLoadFields("No.", "Warranty End Date", Status);
        Equipment.SetRange("Warranty End Date", ReferenceDate, ReferenceDate + GetLongestIntervalDays());
        if Equipment.FindSet() then
            repeat
                if not Equipment.IsFinalStatus(Equipment.Status) then begin
                    WarrantyStatus := Equipment.CalcWarrantyStatus(ReferenceDate);
                    if WarrantyStatus in [WarrantyStatus::Active, WarrantyStatus::"Expiring Soon"] then
                        if FindDueInterval(Equipment.GetWarrantyDaysRemaining(ReferenceDate), AlertInterval) then
                            if not AlertExists(Equipment."No.", Equipment."Warranty End Date", AlertInterval) then begin
                                CreateAlert(Equipment, AlertInterval, ReferenceDate);
                                CreatedCount += 1;
                            end;
                end;
            until Equipment.Next() = 0;

        LogGenerationTelemetry(ReferenceDate, IsScheduled, CreatedCount, CancelledCount);
    end;

    local procedure CancelStaleAlerts(): Integer
    var
        WarrantyAlert: Record "EQM Warranty Alert";
        WarrantyAlertToCancel: Record "EQM Warranty Alert";
        Equipment: Record "EQM Equipment";
        CancelledCount: Integer;
    begin
        Equipment.SetLoadFields("Warranty End Date", Status);
        WarrantyAlert.SetLoadFields("Entry No.", "Equipment No.", "Warranty End Date", Status);
        WarrantyAlert.SetRange(Status, WarrantyAlert.Status::Open);
        if WarrantyAlert.FindSet() then
            repeat
                if IsAlertStale(WarrantyAlert, Equipment) then begin
                    WarrantyAlertToCancel.Get(WarrantyAlert."Entry No.");
                    WarrantyAlertToCancel.Status := WarrantyAlertToCancel.Status::Cancelled;
                    WarrantyAlertToCancel."Cancelled At" := CurrentDateTime();
                    WarrantyAlertToCancel.Modify(false);
                    CancelledCount += 1;
                end;
            until WarrantyAlert.Next() = 0;
        exit(CancelledCount);
    end;

    local procedure IsAlertStale(WarrantyAlert: Record "EQM Warranty Alert"; var Equipment: Record "EQM Equipment"): Boolean
    begin
        if not Equipment.Get(WarrantyAlert."Equipment No.") then
            exit(true);
        if Equipment."Warranty End Date" <> WarrantyAlert."Warranty End Date" then
            exit(true);
        exit(Equipment.IsFinalStatus(Equipment.Status));
    end;

    local procedure AlertExists(EquipmentNo: Code[20]; WarrantyEndDate: Date; AlertInterval: Enum "EQM Warranty Alert Interval"): Boolean
    var
        WarrantyAlert: Record "EQM Warranty Alert";
    begin
        WarrantyAlert.SetCurrentKey("Equipment No.", "Warranty End Date", "Alert Interval");
        WarrantyAlert.SetRange("Equipment No.", EquipmentNo);
        WarrantyAlert.SetRange("Warranty End Date", WarrantyEndDate);
        WarrantyAlert.SetRange("Alert Interval", AlertInterval);
        WarrantyAlert.SetFilter(Status, '<>%1', WarrantyAlert.Status::Cancelled);
        exit(not WarrantyAlert.IsEmpty());
    end;

    local procedure CreateAlert(Equipment: Record "EQM Equipment"; AlertInterval: Enum "EQM Warranty Alert Interval"; ReferenceDate: Date)
    var
        WarrantyAlert: Record "EQM Warranty Alert";
    begin
        WarrantyAlert.Init();
        WarrantyAlert."Equipment No." := Equipment."No.";
        WarrantyAlert."Alert Interval" := AlertInterval;
        WarrantyAlert."Warranty End Date" := Equipment."Warranty End Date";
        WarrantyAlert."Alert Date" := ReferenceDate;
        WarrantyAlert.Status := WarrantyAlert.Status::Open;
        WarrantyAlert.Insert(true);
    end;

    /// <summary>
    /// Acknowledges the open alerts in the filter. Acknowledged and cancelled alerts are skipped. Raises an error when
    /// no open alert is in the filter.
    /// </summary>
    /// <param name="WarrantyAlert">The alerts to acknowledge. The caller's Status filter is kept.</param>
    /// <returns>The number of alerts acknowledged.</returns>
    internal procedure AcknowledgeAlerts(var WarrantyAlert: Record "EQM Warranty Alert"): Integer
    var
        WarrantyAlertToUpdate: Record "EQM Warranty Alert";
        StatusFilter: Text;
        AcknowledgedCount: Integer;
    begin
        StatusFilter := WarrantyAlert.GetFilter(Status);
        WarrantyAlert.SetRange(Status, WarrantyAlert.Status::Open);
        if WarrantyAlert.IsEmpty() then begin
            RestoreStatusFilter(WarrantyAlert, StatusFilter);
            Error(NothingToAcknowledgeErr);
        end;

        WarrantyAlert.FindSet();
        repeat
            WarrantyAlertToUpdate.Get(WarrantyAlert."Entry No.");
            WarrantyAlertToUpdate.Status := WarrantyAlertToUpdate.Status::Acknowledged;
            WarrantyAlertToUpdate."Acknowledged By" := CopyStr(UserId(), 1, MaxStrLen(WarrantyAlertToUpdate."Acknowledged By"));
            WarrantyAlertToUpdate."Acknowledged At" := CurrentDateTime();
            WarrantyAlertToUpdate.Modify(true);
            AcknowledgedCount += 1;
        until WarrantyAlert.Next() = 0;

        RestoreStatusFilter(WarrantyAlert, StatusFilter);
        exit(AcknowledgedCount);
    end;

    /// <summary>
    /// Returns whether an open warranty alert exists for the equipment and warranty end date.
    /// </summary>
    /// <param name="EquipmentNo">The equipment number.</param>
    /// <param name="WarrantyEndDate">The warranty end date the alert was created for.</param>
    /// <returns>True when an open alert exists.</returns>
    internal procedure HasOpenAlert(EquipmentNo: Code[20]; WarrantyEndDate: Date): Boolean
    var
        WarrantyAlert: Record "EQM Warranty Alert";
    begin
        WarrantyAlert.SetCurrentKey("Equipment No.", "Warranty End Date", "Alert Interval");
        WarrantyAlert.SetRange("Equipment No.", EquipmentNo);
        WarrantyAlert.SetRange("Warranty End Date", WarrantyEndDate);
        WarrantyAlert.SetRange(Status, WarrantyAlert.Status::Open);
        exit(not WarrantyAlert.IsEmpty());
    end;

    /// <summary>
    /// Returns the number of open warranty alerts.
    /// </summary>
    /// <returns>The number of open alerts.</returns>
    internal procedure CountOpenAlerts(): Integer
    var
        WarrantyAlert: Record "EQM Warranty Alert";
    begin
        WarrantyAlert.SetCurrentKey(Status, "Warranty End Date");
        WarrantyAlert.SetRange(Status, WarrantyAlert.Status::Open);
        exit(WarrantyAlert.Count());
    end;

    /// <summary>
    /// Opens the open warranty alerts, for one piece of equipment or for all equipment.
    /// </summary>
    /// <param name="EquipmentNo">The equipment number to filter on. Blank shows all equipment.</param>
    internal procedure ShowOpenAlerts(EquipmentNo: Code[20])
    var
        WarrantyAlert: Record "EQM Warranty Alert";
    begin
        WarrantyAlert.SetRange(Status, WarrantyAlert.Status::Open);
        if EquipmentNo <> '' then
            WarrantyAlert.SetRange("Equipment No.", EquipmentNo);
        Page.Run(Page::"EQM Warranty Alerts", WarrantyAlert);
    end;

    local procedure RestoreStatusFilter(var WarrantyAlert: Record "EQM Warranty Alert"; StatusFilter: Text)
    begin
        if StatusFilter = '' then
            WarrantyAlert.SetRange(Status)
        else
            WarrantyAlert.SetFilter(Status, StatusFilter);
    end;

    local procedure LogGenerationTelemetry(ReferenceDate: Date; IsScheduled: Boolean; CreatedCount: Integer; CancelledCount: Integer)
    var
        Dimensions: Dictionary of [Text, Text];
    begin
        Dimensions.Add(AlertsCreatedDimTok, Format(CreatedCount, 0, 9));
        Dimensions.Add(AlertsCancelledDimTok, Format(CancelledCount, 0, 9));
        Dimensions.Add(ReferenceDateDimTok, Format(ReferenceDate, 0, 9));
        if IsScheduled then
            Dimensions.Add(TriggerDimTok, ScheduledTok)
        else
            Dimensions.Add(TriggerDimTok, ManualTok);
        Session.LogMessage(AlertsGeneratedTelemetryTok, AlertsGeneratedTelemetryMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, Dimensions);
    end;
}
