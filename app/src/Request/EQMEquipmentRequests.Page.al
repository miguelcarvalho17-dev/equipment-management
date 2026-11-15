namespace MiguelCarvalho.EquipmentManagement;

using Microsoft.HumanResources.Employee;

page 50133 "EQM Equipment Requests"
{
    Caption = 'Equipment Requests';
    AboutTitle = 'About equipment requests';
    AboutText = 'This list shows the equipment requests raised for employees, newest first: who needs equipment, which type, why and when. Choose **New** to raise a request. Open requests can be corrected or deleted. Choose a view at the top to see requests with one status.';
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    AdditionalSearchTerms = 'equipment requests, request equipment, equipment request process';
    SourceTable = "EQM Equipment Request";
    SourceTableView = sorting("No.") order(descending);
    CardPageId = "EQM Equipment Request Card";
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Requests)
            {
                field("No."; Rec."No.")
                {
                }
                field("Request Date"; Rec."Request Date")
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
                field("Requested Equipment Type"; Rec."Requested Equipment Type")
                {
                }
                field("Equipment Type Description"; Rec."Equipment Type Description")
                {
                }
                field(Justification; Rec.Justification)
                {
                }
                field(Status; Rec.Status)
                {
                    StyleExpr = StatusStyle;
                }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(Employee)
            {
                Caption = 'Employee';
                ToolTip = 'Open the employee card.';
                Image = Employee;
                RunObject = page "Employee Card";
                RunPageLink = "No." = field("Employee No.");
            }
        }
        area(Promoted)
        {
            group(Category_Category4)
            {
                Caption = 'Navigate';

                actionref(Employee_Promoted; Employee)
                {
                }
            }
        }
    }

    views
    {
        view(OpenRequests)
        {
            Caption = 'Open';
            Filters = where(Status = const(Open));
        }
        view(PendingApproval)
        {
            Caption = 'Pending Approval';
            Filters = where(Status = const("Pending Approval"));
        }
        view(Approved)
        {
            Caption = 'Approved';
            Filters = where(Status = const(Approved));
        }
        view(Rejected)
        {
            Caption = 'Rejected';
            Filters = where(Status = const(Rejected));
        }
        view(Completed)
        {
            Caption = 'Completed';
            Filters = where(Status = const(Completed));
        }
    }

    var
        EmployeeName: Text[100];
        StatusStyle: Text;

    trigger OnAfterGetRecord()
    var
        EmployeeRec: Record Employee;
    begin
        EmployeeName := '';
        if EmployeeRec.ReadPermission() then begin
            EmployeeRec.SetLoadFields("First Name", "Middle Name", "Last Name");
            if EmployeeRec.Get(Rec."Employee No.") then
                EmployeeName := EmployeeRec.FullName();
        end;
        StatusStyle := Rec.GetStatusStyle();
    end;
}
