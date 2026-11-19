namespace MiguelCarvalho.EquipmentManagement;

/// <summary>
/// Logs the usage telemetry signals EQM0005 to EQM0009. Signals carry no customer content.
/// </summary>
codeunit 50140 "EQM Telemetry Mgt."
{
    Access = Internal;

    var
        EquipmentCreatedTelemetryTok: Label 'EQM0005', Locked = true;
        EquipmentCreatedTelemetryMsg: Label 'Equipment created.', Locked = true;
        EquipmentAssignedTelemetryTok: Label 'EQM0006', Locked = true;
        EquipmentAssignedTelemetryMsg: Label 'Equipment assigned.', Locked = true;
        EquipmentReturnedTelemetryTok: Label 'EQM0007', Locked = true;
        EquipmentReturnedTelemetryMsg: Label 'Equipment returned.', Locked = true;
        MaintenanceRegisteredTelemetryTok: Label 'EQM0008', Locked = true;
        MaintenanceRegisteredTelemetryMsg: Label 'Maintenance registered.', Locked = true;
        WarrantyExpiredTelemetryTok: Label 'EQM0009', Locked = true;
        WarrantyExpiredTelemetryMsg: Label 'Warranty expired.', Locked = true;
        EquipmentStatusDimTok: Label 'EquipmentStatus', Locked = true;
        MaintenanceTypeDimTok: Label 'MaintenanceType', Locked = true;
        AssignmentDaysDimTok: Label 'AssignmentDays', Locked = true;

    /// <summary>
    /// Logs EQM0005 for new equipment, with the equipment status as dimension.
    /// </summary>
    /// <param name="Equipment">The new equipment.</param>
    internal procedure LogEquipmentCreated(Equipment: Record "EQM Equipment")
    var
        Dimensions: Dictionary of [Text, Text];
    begin
        Dimensions.Add(EquipmentStatusDimTok, GetEquipmentStatusName(Equipment.Status));
        LogUsage(EquipmentCreatedTelemetryTok, EquipmentCreatedTelemetryMsg, Dimensions);
    end;

    /// <summary>
    /// Logs EQM0006 for an assignment, without dimensions.
    /// </summary>
    internal procedure LogEquipmentAssigned()
    var
        Dimensions: Dictionary of [Text, Text];
    begin
        LogUsage(EquipmentAssignedTelemetryTok, EquipmentAssignedTelemetryMsg, Dimensions);
    end;

    /// <summary>
    /// Logs EQM0007 for a return, with the equipment status and, when the dates allow it, the days assigned.
    /// </summary>
    /// <param name="Equipment">The equipment with its new values.</param>
    /// <param name="EquipmentAssignment">The assignment entry that was closed.</param>
    internal procedure LogEquipmentReturned(Equipment: Record "EQM Equipment"; EquipmentAssignment: Record "EQM Equipment Assignment")
    var
        Dimensions: Dictionary of [Text, Text];
    begin
        Dimensions.Add(EquipmentStatusDimTok, GetEquipmentStatusName(Equipment.Status));
        if (EquipmentAssignment."Assignment Date" <> 0D) and (EquipmentAssignment."Closing Date" <> 0D) and
           (EquipmentAssignment."Closing Date" >= EquipmentAssignment."Assignment Date")
        then
            Dimensions.Add(AssignmentDaysDimTok, Format(EquipmentAssignment."Closing Date" - EquipmentAssignment."Assignment Date", 0, 9));
        LogUsage(EquipmentReturnedTelemetryTok, EquipmentReturnedTelemetryMsg, Dimensions);
    end;

    /// <summary>
    /// Logs EQM0008 for a new maintenance record, with the maintenance type as dimension.
    /// </summary>
    /// <param name="MaintenanceRecord">The new maintenance record.</param>
    internal procedure LogMaintenanceRegistered(MaintenanceRecord: Record "EQM Maintenance Record")
    var
        Dimensions: Dictionary of [Text, Text];
    begin
        Dimensions.Add(MaintenanceTypeDimTok, GetMaintenanceTypeName(MaintenanceRecord."Maintenance Type"));
        LogUsage(MaintenanceRegisteredTelemetryTok, MaintenanceRegisteredTelemetryMsg, Dimensions);
    end;

    /// <summary>
    /// Logs EQM0009 for equipment whose warranty expired, with the equipment status as dimension.
    /// </summary>
    /// <param name="Equipment">The equipment.</param>
    internal procedure LogWarrantyExpired(Equipment: Record "EQM Equipment")
    var
        Dimensions: Dictionary of [Text, Text];
    begin
        Dimensions.Add(EquipmentStatusDimTok, GetEquipmentStatusName(Equipment.Status));
        LogUsage(WarrantyExpiredTelemetryTok, WarrantyExpiredTelemetryMsg, Dimensions);
    end;

    /// <summary>
    /// Raised after each usage signal is logged. Internal: used by the test app to observe the signals.
    /// </summary>
    /// <param name="EventId">The telemetry event ID that was logged.</param>
    /// <param name="Dimensions">The custom dimensions that were logged.</param>
    [InternalEvent(false)]
    internal procedure OnAfterLogUsageTelemetry(EventId: Text; Dimensions: Dictionary of [Text, Text])
    begin
    end;

    local procedure LogUsage(EventId: Text; Message: Text; Dimensions: Dictionary of [Text, Text])
    begin
        Session.LogMessage(EventId, Message, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, Dimensions);
        OnAfterLogUsageTelemetry(EventId, Dimensions);
    end;

    local procedure GetEquipmentStatusName(Status: Enum "EQM Equipment Status"): Text
    var
        Index: Integer;
    begin
        Index := Status.Ordinals().IndexOf(Status.AsInteger());
        if Index = 0 then
            exit(Format(Status.AsInteger(), 0, 9));
        exit(Status.Names().Get(Index));
    end;

    local procedure GetMaintenanceTypeName(MaintenanceType: Enum "EQM Maintenance Type"): Text
    var
        Index: Integer;
    begin
        Index := MaintenanceType.Ordinals().IndexOf(MaintenanceType.AsInteger());
        if Index = 0 then
            exit(Format(MaintenanceType.AsInteger(), 0, 9));
        exit(MaintenanceType.Names().Get(Index));
    end;
}
