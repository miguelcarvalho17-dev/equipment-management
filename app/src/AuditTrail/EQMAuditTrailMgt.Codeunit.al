namespace MiguelCarvalho.EquipmentManagement;

/// <summary>
/// Writes the equipment audit trail. The trail cannot be switched off. Entries are written in the transaction of the
/// operation, so a rolled back operation leaves no entry.
/// </summary>
codeunit 50135 "EQM Audit Trail Mgt."
{
    Access = Internal;
    Permissions = tabledata "EQM Equipment Audit Entry" = ri,
                  tabledata "EQM Equipment" = r;

    /// <summary>
    /// Writes a Created entry for new equipment.
    /// </summary>
    /// <param name="Equipment">The equipment that was created.</param>
    internal procedure LogCreated(Equipment: Record "EQM Equipment")
    begin
        InsertEntry(Equipment, "EQM Audit Event Type"::Created, '', 0, '');
    end;

    /// <summary>
    /// Writes an Assigned or Returned entry with the employee and the assignment entry behind it.
    /// </summary>
    /// <param name="EventType">Assigned or Returned.</param>
    /// <param name="Equipment">The equipment; its status is stored as Status After.</param>
    /// <param name="EquipmentAssignment">The assignment entry that was created or closed.</param>
    internal procedure LogAssignment(EventType: Enum "EQM Audit Event Type"; Equipment: Record "EQM Equipment"; EquipmentAssignment: Record "EQM Equipment Assignment")
    begin
        InsertEntry(Equipment, EventType, EquipmentAssignment."Employee No.", EquipmentAssignment."Entry No.", '');
    end;

    /// <summary>
    /// Compares the equipment with the stored record and writes the entries for the change: Sent to Maintenance when the
    /// status changes to In Maintenance, Disposed when it changes to Disposed, and at most one Updated entry when a
    /// tracked field changed or the status changed in a way that has no event of its own (for example to Lost, or from
    /// In Maintenance back to Available). Writes nothing when the equipment is not stored yet.
    /// </summary>
    /// <param name="Equipment">The equipment as it is being saved.</param>
    /// <param name="MaintenanceNo">The maintenance record that sends the equipment to maintenance; blank for a manual status change.</param>
    internal procedure LogEquipmentChanges(Equipment: Record "EQM Equipment"; MaintenanceNo: Code[20])
    var
        StoredEquipment: Record "EQM Equipment";
        StatusChanged: Boolean;
        LogUpdated: Boolean;
    begin
        StoredEquipment.SetLoadFields(Status, Description, "Category Code", "Serial No.", Manufacturer, Model, "Purchase Date", "Purchase Cost", "Location Code", "Warranty Start Date", "Warranty End Date", "Warranty Provider", "Warranty Reference No.", "Last Maintenance Date", "Maintenance Frequency (Months)");
        if not StoredEquipment.Get(Equipment."No.") then
            exit;

        StatusChanged := StoredEquipment.Status <> Equipment.Status;
        if StatusChanged and (Equipment.Status = Equipment.Status::"In Maintenance") then
            InsertEntry(Equipment, "EQM Audit Event Type"::"Sent to Maintenance", '', 0, MaintenanceNo);
        if StatusChanged and (Equipment.Status = Equipment.Status::Disposed) then
            InsertEntry(Equipment, "EQM Audit Event Type"::Disposed, '', 0, '');

        LogUpdated := HasTrackedFieldChanged(StoredEquipment, Equipment);
        if StatusChanged and (StoredEquipment.Status <> StoredEquipment.Status::Assigned) and
           not (Equipment.Status in [Equipment.Status::Assigned, Equipment.Status::"In Maintenance", Equipment.Status::Disposed])
        then
            LogUpdated := true;
        if LogUpdated then
            InsertEntry(Equipment, "EQM Audit Event Type"::Updated, '', 0, '');
    end;

    local procedure HasTrackedFieldChanged(StoredEquipment: Record "EQM Equipment"; Equipment: Record "EQM Equipment"): Boolean
    begin
        exit(
            (StoredEquipment.Description <> Equipment.Description) or
            (StoredEquipment."Category Code" <> Equipment."Category Code") or
            (StoredEquipment."Serial No." <> Equipment."Serial No.") or
            (StoredEquipment.Manufacturer <> Equipment.Manufacturer) or
            (StoredEquipment.Model <> Equipment.Model) or
            (StoredEquipment."Purchase Date" <> Equipment."Purchase Date") or
            (StoredEquipment."Purchase Cost" <> Equipment."Purchase Cost") or
            (StoredEquipment."Location Code" <> Equipment."Location Code") or
            (StoredEquipment."Warranty Start Date" <> Equipment."Warranty Start Date") or
            (StoredEquipment."Warranty End Date" <> Equipment."Warranty End Date") or
            (StoredEquipment."Warranty Provider" <> Equipment."Warranty Provider") or
            (StoredEquipment."Warranty Reference No." <> Equipment."Warranty Reference No.") or
            (StoredEquipment."Last Maintenance Date" <> Equipment."Last Maintenance Date") or
            (StoredEquipment."Maintenance Frequency (Months)" <> Equipment."Maintenance Frequency (Months)"));
    end;

    local procedure InsertEntry(Equipment: Record "EQM Equipment"; EventType: Enum "EQM Audit Event Type"; EmployeeNo: Code[20]; AssignmentEntryNo: Integer; MaintenanceNo: Code[20])
    var
        AuditEntry: Record "EQM Equipment Audit Entry";
    begin
        AuditEntry.Init();
        AuditEntry."Equipment No." := Equipment."No.";
        AuditEntry."Event Type" := EventType;
        AuditEntry."Status After" := Equipment.Status;
        AuditEntry."Employee No." := EmployeeNo;
        AuditEntry."Assignment Entry No." := AssignmentEntryNo;
        AuditEntry."Maintenance No." := MaintenanceNo;
        AuditEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(AuditEntry."User ID"));
        AuditEntry."Logged At" := CurrentDateTime();
        AuditEntry.AllowInsertFromAuditTrail();
        AuditEntry.Insert(true);
    end;
}
