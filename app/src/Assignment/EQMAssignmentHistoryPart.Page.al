namespace MiguelCarvalho.EquipmentManagement;

using Microsoft.HumanResources.Employee;

page 50105 "EQM Assignment History Part"
{
    Caption = 'Assignment History';
    PageType = ListPart;
    ApplicationArea = All;
    SourceTable = "EQM Equipment Assignment";
    SourceTableView = sorting("Entry No.") order(descending);
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(History)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    Visible = false;
                }
                field("Employee No."; Rec."Employee No.")
                {
                }
                field("Employee Name"; EmployeeName)
                {
                    Caption = 'Employee Name';
                    ToolTip = 'Specifies the name of the employee.';
                }
                field("Assignment Date"; Rec."Assignment Date")
                {
                }
                field("Assigned By"; Rec."Assigned By")
                {
                }
                field(Status; Rec.Status)
                {
                    StyleExpr = StatusStyle;
                }
                field("Closing Date"; Rec."Closing Date")
                {
                }
                field("Closed By"; Rec."Closed By")
                {
                }
            }
        }
    }

    var
        EmployeeName: Text[100];
        StatusStyle: Text;
        FavorableStyleTok: Label 'Favorable', Locked = true;
        SubordinateStyleTok: Label 'Subordinate', Locked = true;

    trigger OnAfterGetRecord()
    var
        Employee: Record Employee;
    begin
        EmployeeName := '';
        if Employee.ReadPermission() then begin
            Employee.SetLoadFields("First Name", "Middle Name", "Last Name");
            if Employee.Get(Rec."Employee No.") then
                EmployeeName := Employee.FullName();
        end;

        if Rec.Status = Rec.Status::Active then
            StatusStyle := FavorableStyleTok
        else
            StatusStyle := SubordinateStyleTok;
    end;
}
