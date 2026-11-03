namespace MiguelCarvalho.EquipmentManagement;

using Microsoft.HumanResources.Employee;

page 50104 "EQM Equipment Assignments"
{
    Caption = 'Equipment Assignments';
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
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
            repeater(Assignments)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    Visible = false;
                }
                field("Equipment No."; Rec."Equipment No.")
                {
                }
                field("Equipment Description"; Rec."Equipment Description")
                {
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

    actions
    {
        area(Navigation)
        {
            action(Equipment)
            {
                Caption = 'Equipment';
                ToolTip = 'Opens the equipment card.';
                Image = FixedAssets;
                RunObject = page "EQM Equipment Card";
                RunPageLink = "No." = field("Equipment No.");
            }
            action(Employee)
            {
                Caption = 'Employee';
                ToolTip = 'Opens the employee card.';
                Image = Employee;
                RunObject = page "Employee Card";
                RunPageLink = "No." = field("Employee No.");
            }
        }
        area(Promoted)
        {
            actionref(Equipment_Promoted; Equipment)
            {
            }
            actionref(Employee_Promoted; Employee)
            {
            }
        }
    }

    views
    {
        view(Active)
        {
            Caption = 'Active';
            Filters = where(Status = const(Active));
        }
        view(Closed)
        {
            Caption = 'Closed';
            Filters = where(Status = const(Closed));
        }
    }

    var
        EmployeeName: Text[100];
        StatusStyle: Text;
        FavorableStyleTok: Label 'Favorable', Locked = true;
        SubordinateStyleTok: Label 'Subordinate', Locked = true;

    trigger OnAfterGetRecord()
    var
        EmployeeRec: Record Employee;
    begin
        EmployeeName := '';
        EmployeeRec.SetLoadFields("First Name", "Middle Name", "Last Name");
        if EmployeeRec.Get(Rec."Employee No.") then
            EmployeeName := EmployeeRec.FullName();

        if Rec.Status = Rec.Status::Active then
            StatusStyle := FavorableStyleTok
        else
            StatusStyle := SubordinateStyleTok;
    end;
}
