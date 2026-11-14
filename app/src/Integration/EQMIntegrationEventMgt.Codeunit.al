namespace MiguelCarvalho.EquipmentManagement;

/// <summary>
/// Writes and processes the integration event entries (the outbox for external systems).
/// </summary>
codeunit 50122 "EQM Integration Event Mgt."
{
    Access = Internal;
    Permissions = tabledata "EQM Integration Event Entry" = rim;

    /// <summary>
    /// Checks whether integration events are switched on in the equipment setup.
    /// </summary>
    /// <returns>True when the setup exists and Integration Events Enabled is on.</returns>
    internal procedure IsEnabled(): Boolean
    var
        EquipmentSetup: Record "EQM Equipment Setup";
    begin
        EquipmentSetup.SetLoadFields("Integration Events Enabled");
        if not EquipmentSetup.Get() then
            exit(false);
        exit(EquipmentSetup."Integration Events Enabled");
    end;

    /// <summary>
    /// Appends one entry to the outbox.
    /// </summary>
    /// <param name="EventType">The business event.</param>
    /// <param name="EquipmentNo">The equipment the event is about.</param>
    /// <param name="EquipmentStatus">The equipment status at event time.</param>
    /// <param name="AssignmentEntryNo">The assignment entry number, or 0.</param>
    /// <param name="MaintenanceNo">The maintenance record number, or blank.</param>
    internal procedure RecordEvent(EventType: Enum "EQM Integration Event Type"; EquipmentNo: Code[20]; EquipmentStatus: Enum "EQM Equipment Status"; AssignmentEntryNo: Integer; MaintenanceNo: Code[20])
    var
        IntegrationEventEntry: Record "EQM Integration Event Entry";
    begin
        IntegrationEventEntry.Init();
        IntegrationEventEntry."Event Type" := EventType;
        IntegrationEventEntry."Equipment No." := EquipmentNo;
        IntegrationEventEntry."Equipment Status" := EquipmentStatus;
        IntegrationEventEntry."Assignment Entry No." := AssignmentEntryNo;
        IntegrationEventEntry."Maintenance No." := MaintenanceNo;
        IntegrationEventEntry.AllowInsertFromMgt();
        IntegrationEventEntry.Insert(true);
    end;

    /// <summary>
    /// Marks an entry as processed. Does nothing when it is already processed.
    /// </summary>
    /// <param name="IntegrationEventEntry">The entry to mark.</param>
    internal procedure MarkProcessed(var IntegrationEventEntry: Record "EQM Integration Event Entry")
    begin
        if IntegrationEventEntry.Processed then
            exit;
        IntegrationEventEntry.Processed := true;
        IntegrationEventEntry."Processed At" := CurrentDateTime();
        IntegrationEventEntry.AllowModifyFromMgt();
        IntegrationEventEntry.Modify(true);
    end;
}
