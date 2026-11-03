namespace MiguelCarvalho.EquipmentManagement;

using Microsoft.HumanResources.Employee;

pageextension 50100 "EQM Employee Card" extends "Employee Card"
{
    actions
    {
        addlast(Navigation)
        {
            action(EQMEquipmentAssignments)
            {
                ApplicationArea = All;
                Caption = 'Equipment Assignments';
                ToolTip = 'View the equipment assignments of the employee.';
                Image = Employee;
                RunObject = page "EQM Equipment Assignments";
                RunPageLink = "Employee No." = field("No.");
            }
        }
    }
}
