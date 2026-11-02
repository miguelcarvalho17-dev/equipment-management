namespace MiguelCarvalho.EquipmentManagement;

using Microsoft.HumanResources.Employee;

// Permission design: all access to EQM tables on behalf of an Employee delete happens in this
// codeunit. The Permissions property grants INDIRECT permissions only: it works when the user's
// permission sets contain the matching indirect (lowercase) right. That right is provided by the
// permissionsetextension "EQM D365 BASIC" (tabledata "EQM Equipment" = r) and by the EQM sets, so a
// user who may delete employees still gets the guard error, not a permission error.
// This behavior still needs a sandbox check.
codeunit 50103 "EQM Employee Subscribers"
{
    Access = Internal;
    Permissions = tabledata "EQM Equipment" = r;

    var
        EmployeeHasAssignedEquipmentErr: Label 'You cannot delete employee %1 because one or more equipment records are assigned to the employee.', Comment = '%1 = employee number';

    [EventSubscriber(ObjectType::Table, Database::Employee, 'OnBeforeDeleteEvent', '', false, false)]
    local procedure CheckNoAssignedEquipmentOnBeforeDeleteEmployee(var Rec: Record Employee; RunTrigger: Boolean)
    var
        Equipment: Record "EQM Equipment";
    begin
        if not RunTrigger then
            exit;
        if Rec.IsTemporary() then
            exit;

        Equipment.SetLoadFields("No.");
        Equipment.SetCurrentKey("Assigned Employee No.", Status);
        Equipment.SetRange("Assigned Employee No.", Rec."No.");
        if not Equipment.IsEmpty() then
            Error(EmployeeHasAssignedEquipmentErr, Rec."No.");
    end;
}
