namespace MiguelCarvalho.EquipmentManagement;

using System.Integration;

/// <summary>
/// External business events for Power Automate ("When a business event occurs" in the Business Central connector).
/// The platform delivers an event after the transaction commits, and only to flows that subscribe to it. Raised by
/// codeunit "EQM Power Automate Subscr.". Event names, parameters and version are a frozen contract.
/// </summary>
codeunit 50130 "EQM Power Automate Events"
{
    Access = Public;

    /// <summary>
    /// Occurs when equipment is assigned to an employee. Delivered after commit, only to subscribed flows.
    /// </summary>
    /// <param name="EquipmentId">The SystemId of the equipment.</param>
    /// <param name="EquipmentNo">The equipment number.</param>
    /// <param name="EquipmentDescription">The equipment description.</param>
    /// <param name="EmployeeNo">The number of the employee the equipment is assigned to.</param>
    /// <param name="AssignmentId">The SystemId of the assignment entry.</param>
    /// <param name="AssignmentDate">The assignment date.</param>
    [ExternalBusinessEvent('equipmentAssigned', 'Equipment assigned', 'Occurs when equipment is assigned to an employee.', EventCategory::"EQM Equipment Management", '1.0')]
    [RequiredPermissions(PermissionObjectType::TableData, Database::"EQM Equipment Assignment", 'R')]
    internal procedure EquipmentAssigned(EquipmentId: Guid; EquipmentNo: Code[20]; EquipmentDescription: Text[100]; EmployeeNo: Code[20]; AssignmentId: Guid; AssignmentDate: Date)
    begin
    end;

    /// <summary>
    /// Occurs when a warranty alert is created, 90, 60 or 30 days before the warranty end date. Delivered after
    /// commit, only to subscribed flows.
    /// </summary>
    /// <param name="EquipmentId">The SystemId of the equipment.</param>
    /// <param name="EquipmentNo">The equipment number.</param>
    /// <param name="EquipmentDescription">The equipment description.</param>
    /// <param name="WarrantyProvider">The warranty provider.</param>
    /// <param name="WarrantyEndDate">The warranty end date.</param>
    /// <param name="DaysRemaining">The days from the alert date to the warranty end date.</param>
    /// <param name="AlertIntervalDays">The alert interval in days (90, 60 or 30).</param>
    [ExternalBusinessEvent('warrantyExpiring', 'Warranty expiring', 'Occurs when a warranty alert is created, 90, 60 or 30 days before the warranty end date.', EventCategory::"EQM Equipment Management", '1.0')]
    [RequiredPermissions(PermissionObjectType::TableData, Database::"EQM Warranty Alert", 'R')]
    internal procedure WarrantyExpiring(EquipmentId: Guid; EquipmentNo: Code[20]; EquipmentDescription: Text[100]; WarrantyProvider: Text[100]; WarrantyEndDate: Date; DaysRemaining: Integer; AlertIntervalDays: Integer)
    begin
    end;
}
