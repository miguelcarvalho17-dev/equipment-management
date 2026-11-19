namespace MiguelCarvalho.EquipmentManagement;

using Microsoft.HumanResources.Employee;

page 50104 "EQM Equipment Assignments"
{
    Caption = 'Equipment Assignments';
    AboutTitle = 'About equipment assignments';
    AboutText = 'This list shows every assignment of equipment to an employee, newest first. Active assignments show who has the equipment now. Closed assignments are kept as history and cannot be changed. Choose a view at the top to see only active or closed assignments, and choose **Equipment** or **Employee** to open the related card.';
    PageType = List;
    ApplicationArea = All;
    UsageCategory = History;
    AdditionalSearchTerms = 'equipment history, equipment loans, issued equipment';
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
                ToolTip = 'Open the equipment card.';
                Image = FixedAssets;
                RunObject = page "EQM Equipment Card";
                RunPageLink = "No." = field("Equipment No.");
            }
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

                actionref(Equipment_Promoted; Equipment)
                {
                }
                actionref(Employee_Promoted; Employee)
                {
                }
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
        EmployeeNames: Dictionary of [Code[20], Text];
        EmployeeName: Text[100];
        CanReadEmployees: Boolean;
        StatusStyle: Text;
        FavorableStyleTok: Label 'Favorable', Locked = true;
        SubordinateStyleTok: Label 'Subordinate', Locked = true;

    trigger OnOpenPage()
    var
        EmployeeRec: Record Employee;
    begin
        CanReadEmployees := EmployeeRec.ReadPermission();
    end;

    trigger OnAfterGetRecord()
    begin
        EmployeeName := GetEmployeeName(Rec."Employee No.");

        if Rec.Status = Rec.Status::Active then
            StatusStyle := FavorableStyleTok
        else
            StatusStyle := SubordinateStyleTok;
    end;

    local procedure GetEmployeeName(EmployeeNo: Code[20]): Text[100]
    var
        EmployeeRec: Record Employee;
        CachedName: Text;
    begin
        if (EmployeeNo = '') or not CanReadEmployees then
            exit('');
        if EmployeeNames.Get(EmployeeNo, CachedName) then
            exit(CopyStr(CachedName, 1, MaxStrLen(EmployeeName)));
        EmployeeRec.SetLoadFields("First Name", "Middle Name", "Last Name");
        if EmployeeRec.Get(EmployeeNo) then
            CachedName := EmployeeRec.FullName();
        EmployeeNames.Add(EmployeeNo, CachedName);
        exit(CopyStr(CachedName, 1, MaxStrLen(EmployeeName)));
    end;
}
