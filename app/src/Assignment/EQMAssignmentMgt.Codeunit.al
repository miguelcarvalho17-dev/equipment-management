namespace MiguelCarvalho.EquipmentManagement;

/// <summary>
/// Keeps the equipment assignment entries in sync with the equipment status.
/// </summary>
codeunit 50106 "EQM Assignment Mgt."
{
    Access = Public;
    Permissions = tabledata "EQM Equipment Assignment" = rim,
                  tabledata "EQM Equipment" = r;

    /// <summary>
    /// Creates an active assignment entry when saved equipment becomes Assigned, and closes it when the
    /// equipment stops being Assigned. Call it from the equipment modify trigger, after the consistency check.
    /// </summary>
    /// <param name="Equipment">The equipment being modified, with its new values.</param>
    internal procedure UpdateAssignmentOnSave(Equipment: Record "EQM Equipment")
    var
        StoredEquipment: Record "EQM Equipment";
        WasAssigned: Boolean;
        IsAssigned: Boolean;
    begin
        StoredEquipment.SetLoadFields(Status);
        if StoredEquipment.Get(Equipment."No.") then
            WasAssigned := StoredEquipment.Status = StoredEquipment.Status::Assigned;
        IsAssigned := Equipment.Status = Equipment.Status::Assigned;

        if (not WasAssigned) and IsAssigned then
            CreateAssignment(Equipment);
        if WasAssigned and (not IsAssigned) then
            CloseActiveAssignments(Equipment);
    end;

    /// <summary>
    /// Returns whether the equipment has any assignment entry, active or closed. Equipment with assignment
    /// history cannot be deleted.
    /// </summary>
    /// <param name="EquipmentNo">The equipment number.</param>
    /// <returns>True when at least one entry exists.</returns>
    internal procedure HasAssignmentHistory(EquipmentNo: Code[20]): Boolean
    var
        EquipmentAssignment: Record "EQM Equipment Assignment";
    begin
        EquipmentAssignment.SetCurrentKey("Equipment No.", Status);
        EquipmentAssignment.SetRange("Equipment No.", EquipmentNo);
        exit(not EquipmentAssignment.IsEmpty());
    end;

    local procedure CreateAssignment(Equipment: Record "EQM Equipment")
    var
        EquipmentAssignment: Record "EQM Equipment Assignment";
    begin
        CloseActiveAssignments(Equipment);

        EquipmentAssignment.Init();
        EquipmentAssignment."Equipment No." := Equipment."No.";
        EquipmentAssignment."Employee No." := Equipment."Assigned Employee No.";
        EquipmentAssignment."Assignment Date" := WorkDate();
        EquipmentAssignment."Assigned By" := CopyStr(UserId(), 1, MaxStrLen(EquipmentAssignment."Assigned By"));
        EquipmentAssignment.Status := EquipmentAssignment.Status::Active;
        OnBeforeInsertAssignment(EquipmentAssignment, Equipment);
        EquipmentAssignment.Insert(true);
    end;

    local procedure CloseActiveAssignments(Equipment: Record "EQM Equipment")
    var
        ActiveAssignment: Record "EQM Equipment Assignment";
        EquipmentAssignment: Record "EQM Equipment Assignment";
    begin
        ActiveAssignment.SetCurrentKey("Equipment No.", Status);
        ActiveAssignment.SetRange("Equipment No.", Equipment."No.");
        ActiveAssignment.SetRange(Status, ActiveAssignment.Status::Active);
        if ActiveAssignment.FindSet() then
            repeat
                EquipmentAssignment.Get(ActiveAssignment."Entry No.");
                EquipmentAssignment.Status := EquipmentAssignment.Status::Closed;
                EquipmentAssignment."Closing Date" := WorkDate();
                EquipmentAssignment."Closed By" := CopyStr(UserId(), 1, MaxStrLen(EquipmentAssignment."Closed By"));
                OnBeforeCloseAssignment(EquipmentAssignment, Equipment);
                EquipmentAssignment.Modify(true);
            until ActiveAssignment.Next() = 0;
    end;

    /// <summary>
    /// Raised before a new active assignment entry is inserted.
    /// </summary>
    /// <param name="EquipmentAssignment">The new entry. You can set fields that your extension added; do not change the standard fields.</param>
    /// <param name="Equipment">The equipment being assigned (passed by value).</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertAssignment(var EquipmentAssignment: Record "EQM Equipment Assignment"; Equipment: Record "EQM Equipment")
    begin
    end;

    /// <summary>
    /// Raised before an active assignment entry is closed.
    /// </summary>
    /// <param name="EquipmentAssignment">The entry being closed, with Status, Closing Date and Closed By already set. You can set fields that your extension added.</param>
    /// <param name="Equipment">The equipment (passed by value); its status shows why the assignment closes.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCloseAssignment(var EquipmentAssignment: Record "EQM Equipment Assignment"; Equipment: Record "EQM Equipment")
    begin
    end;
}
