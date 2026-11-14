namespace MiguelCarvalho.EquipmentManagement;

/// <summary>
/// Integration events that notify partner extensions about business moments. The events only notify: they are raised
/// after the fact and cannot change or skip the standard logic. Subscribers run in the caller's transaction, so an
/// error in a subscriber stops the operation that raised the event. Subscribers must not show UI or call Commit.
/// </summary>
codeunit 50119 "EQM Business Events"
{
    Access = Public;

    /// <summary>
    /// Raised after new equipment is inserted with Insert(true) (not for temporary records or Insert(false)). The
    /// record is stored in the database. No UI, no Commit.
    /// </summary>
    /// <param name="Equipment">The new equipment (passed by value).</param>
    [IntegrationEvent(false, false)]
    internal procedure OnEquipmentCreated(Equipment: Record "EQM Equipment")
    begin
    end;

    /// <summary>
    /// Raised when equipment is assigned, right after the active assignment entry is inserted. Raised while the
    /// equipment is being saved: the assignment entry is written, but the equipment row is not yet, and the operation
    /// can still fail and be rolled back. Read the equipment from this parameter, not from the database. Do not Modify
    /// the equipment, and do not make non-transactional calls (HTTP, telemetry); queue them instead. No UI, no Commit.
    /// </summary>
    /// <param name="Equipment">The equipment with its new values (passed by value).</param>
    /// <param name="EquipmentAssignment">The new active assignment entry (passed by value).</param>
    [IntegrationEvent(false, false)]
    internal procedure OnEquipmentAssigned(Equipment: Record "EQM Equipment"; EquipmentAssignment: Record "EQM Equipment Assignment")
    begin
    end;

    /// <summary>
    /// Raised whenever an active assignment is closed, right after the entry is modified: by the Return action, by
    /// registering maintenance, by setting the status to Lost or Disposed, or by a new assignment that closes a
    /// leftover active entry. The entry is Closed. Equipment.Status (Available, In Maintenance, Lost, Disposed or
    /// Assigned) shows the reason. Raised while the equipment is being saved (on the maintenance path, inside the
    /// Maintenance Record insert, before that record is stored): the assignment entry is written, but the equipment row
    /// is not yet, and the operation can still fail and be rolled back. Read the equipment from this parameter, not
    /// from the database. Do not Modify the equipment, and do not make non-transactional calls (HTTP, telemetry);
    /// queue them instead. No UI, no Commit.
    /// </summary>
    /// <param name="Equipment">The equipment with its new values (passed by value).</param>
    /// <param name="EquipmentAssignment">The closed assignment entry (passed by value).</param>
    [IntegrationEvent(false, false)]
    internal procedure OnEquipmentReturned(Equipment: Record "EQM Equipment"; EquipmentAssignment: Record "EQM Equipment Assignment")
    begin
    end;

    /// <summary>
    /// Raised after a maintenance record is inserted with Insert(true) (not for temporary records or Insert(false)).
    /// The record is stored and the equipment is already In Maintenance. No UI, no Commit.
    /// </summary>
    /// <param name="MaintenanceRecord">The new maintenance record (passed by value).</param>
    [IntegrationEvent(false, false)]
    internal procedure OnMaintenanceCreated(MaintenanceRecord: Record "EQM Maintenance Record")
    begin
    end;

    /// <summary>
    /// Raised by the daily warranty job, in the job queue session, for equipment whose warranty ended yesterday (the
    /// first day the warranty status is Expired) and whose status is not final. It is not raised by manual alert
    /// generation. A day the job does not run is missed. No UI, no Commit.
    /// </summary>
    /// <param name="Equipment">The equipment whose warranty expired (passed by value).</param>
    [IntegrationEvent(false, false)]
    internal procedure OnWarrantyExpired(Equipment: Record "EQM Equipment")
    begin
    end;
}
