namespace MiguelCarvalho.EquipmentManagement;

/// <summary>
/// Posts a maintenance record: freezes it, writes a read-only maintenance history entry, moves the equipment's last
/// maintenance date forward for preventive maintenance and, when no other maintenance is open, sets the equipment from
/// In Maintenance back to Available. Run it with Codeunit.Run on the record. It shows no dialogs.
/// </summary>
codeunit 50109 "EQM Maintenance-Post"
{
    Access = Public;
    TableNo = "EQM Maintenance Record";
    Permissions = tabledata "EQM Maintenance History Entry" = ri;

    var
        RecordNotSavedErr: Label 'You cannot post maintenance record %1 because it has not been saved.', Comment = '%1 = maintenance record number';
        AlreadyPostedErr: Label 'Maintenance record %1 is already posted.', Comment = '%1 = maintenance record number';

    trigger OnRun()
    var
        StoredRecord: Record "EQM Maintenance Record";
        MaintenanceHistoryEntry: Record "EQM Maintenance History Entry";
        MaintenanceLogMgt: Codeunit "EQM Maintenance Log Mgt.";
    begin
        StoredRecord.ReadIsolation := IsolationLevel::UpdLock;
        StoredRecord.SetLoadFields(Status);
        if not StoredRecord.Get(Rec."No.") then
            Error(RecordNotSavedErr, Rec."No.");
        if StoredRecord.Status = StoredRecord.Status::Posted then
            Error(AlreadyPostedErr, Rec."No.");

        MaintenanceHistoryEntry.SetCurrentKey("Maintenance No.");
        MaintenanceHistoryEntry.SetRange("Maintenance No.", Rec."No.");
        if not MaintenanceHistoryEntry.IsEmpty() then
            Error(AlreadyPostedErr, Rec."No.");

        OnBeforePostMaintenanceRecord(Rec);

        Rec.Status := Rec.Status::Posted;
        Rec.Modify(true);

        InsertHistoryEntry(Rec, MaintenanceHistoryEntry);
        MaintenanceLogMgt.LogPosted(Rec);
        CompleteEquipmentMaintenance(Rec);

        OnAfterPostMaintenanceRecord(Rec, MaintenanceHistoryEntry);
    end;

    local procedure InsertHistoryEntry(MaintenanceRecord: Record "EQM Maintenance Record"; var MaintenanceHistoryEntry: Record "EQM Maintenance History Entry")
    var
        MaintenanceMgt: Codeunit "EQM Maintenance Mgt.";
    begin
        MaintenanceHistoryEntry.Init();
        MaintenanceHistoryEntry."Maintenance No." := MaintenanceRecord."No.";
        MaintenanceHistoryEntry."Equipment No." := MaintenanceRecord."Equipment No.";
        MaintenanceHistoryEntry."Maintenance Date" := MaintenanceRecord."Maintenance Date";
        MaintenanceHistoryEntry."Maintenance Type" := MaintenanceRecord."Maintenance Type";
        MaintenanceHistoryEntry."Vendor No." := MaintenanceRecord."Vendor No.";
        MaintenanceHistoryEntry.Cost := MaintenanceRecord.Cost;
        MaintenanceHistoryEntry.Description := MaintenanceRecord.Description;
        MaintenanceHistoryEntry."Performed By" := MaintenanceRecord."Performed By";
        MaintenanceHistoryEntry."Vendor Name" := MaintenanceMgt.GetVendorName(MaintenanceRecord."Vendor No.");
        MaintenanceHistoryEntry."Posted By" := CopyStr(UserId(), 1, MaxStrLen(MaintenanceHistoryEntry."Posted By"));
        MaintenanceHistoryEntry."Posted At" := CurrentDateTime();

        OnBeforeInsertMaintenanceHistoryEntry(MaintenanceHistoryEntry, MaintenanceRecord);

        MaintenanceHistoryEntry.AllowInsertFromPosting();
        MaintenanceHistoryEntry.Insert(true);
    end;

    local procedure CompleteEquipmentMaintenance(MaintenanceRecord: Record "EQM Maintenance Record")
    var
        Equipment: Record "EQM Equipment";
    begin
        Equipment.ReadIsolation := IsolationLevel::UpdLock;
        if Equipment.Get(MaintenanceRecord."Equipment No.") then begin
            Equipment.UpdateLastMaintenanceFromPosting(MaintenanceRecord);
            Equipment.CompleteMaintenance(MaintenanceRecord);
        end;
    end;

    /// <summary>
    /// Raised after the checks that the record is saved, Open and not yet in the history, and before the status changes.
    /// </summary>
    /// <param name="MaintenanceRecord">The record being posted. Raise an error to stop posting. You can fill fields your extension added. Do not change the standard fields.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforePostMaintenanceRecord(var MaintenanceRecord: Record "EQM Maintenance Record")
    begin
    end;

    /// <summary>
    /// Raised after all standard fields of the history entry are filled, just before the insert.
    /// </summary>
    /// <param name="MaintenanceHistoryEntry">The entry about to be inserted. Fill the fields your extension added. Do not change the standard fields.</param>
    /// <param name="MaintenanceRecord">The record being posted (passed by value).</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertMaintenanceHistoryEntry(var MaintenanceHistoryEntry: Record "EQM Maintenance History Entry"; MaintenanceRecord: Record "EQM Maintenance Record")
    begin
    end;

    /// <summary>
    /// Raised after the status change and the insert of the history entry. Subscribers must not commit.
    /// The equipment status and planned maintenance dates have already been updated.
    /// </summary>
    /// <param name="MaintenanceRecord">The posted record (passed by value).</param>
    /// <param name="MaintenanceHistoryEntry">The history entry that was written (passed by value).</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterPostMaintenanceRecord(MaintenanceRecord: Record "EQM Maintenance Record"; MaintenanceHistoryEntry: Record "EQM Maintenance History Entry")
    begin
    end;
}
