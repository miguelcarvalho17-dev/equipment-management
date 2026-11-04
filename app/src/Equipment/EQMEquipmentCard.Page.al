namespace MiguelCarvalho.EquipmentManagement;

using Microsoft.HumanResources.Employee;
using System.Security.AccessControl;

page 50101 "EQM Equipment Card"
{
    Caption = 'Equipment Card';
    AboutTitle = 'About equipment details';
    AboutText = 'Here you manage one piece of equipment. The first sections show its details, its current status and who it is assigned to. Use **Assign to Employee** and **Return** to change the assignment. Further down, **Assignment History** lists every assignment, and **Audit** shows who created the record and who changed it last.';
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "EQM Equipment";
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field("No."; Rec."No.")
                {
                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEdit() then
                            CurrPage.Update(false);
                    end;
                }
                field(Description; Rec.Description)
                {
                }
                field("Category Code"; Rec."Category Code")
                {
                    ShowMandatory = true;
                }
                field("Serial No."; Rec."Serial No.")
                {
                }
                field(Manufacturer; Rec.Manufacturer)
                {
                }
                field(Model; Rec.Model)
                {
                }
            }
            group(Assignment)
            {
                Caption = 'Assignment';

                field(StatusNew; Rec.Status)
                {
                    ValuesAllowed = Available, "In Maintenance";
                    Importance = Promoted;
                    Visible = IsNewRecord;
                    StyleExpr = StatusStyle;

                    trigger OnValidate()
                    begin
                        UpdateControls();
                    end;
                }
                field(Status; Rec.Status)
                {
                    Importance = Promoted;
                    Visible = IsSaved;
                    StyleExpr = StatusStyle;

                    trigger OnValidate()
                    begin
                        if (Rec.Status = Rec.Status::Assigned) and (xRec.Status <> Rec.Status::Assigned) then
                            Error(UseAssignActionErr);

                        UpdateControls();
                    end;
                }
                field("Assigned Employee No."; Rec."Assigned Employee No.")
                {
                    Editable = false;
                }
                field("Assigned Employee Name"; AssignedEmployeeName)
                {
                    Caption = 'Assigned Employee Name';
                    Editable = false;
                    ToolTip = 'Specifies the name of the employee the equipment is assigned to.';
                }
                field(AssignedSince; ActiveAssignmentDate)
                {
                    Caption = 'Assigned Since';
                    Editable = false;
                    ToolTip = 'Specifies the date the equipment was assigned to the current employee. It is blank when the equipment is not assigned.';
                }
                field(AssignedBy; ActiveAssignedBy)
                {
                    Caption = 'Assigned By';
                    Editable = false;
                    ToolTip = 'Specifies the user who assigned the equipment to the current employee. It is blank when the equipment is not assigned.';
                }
                field("Location Code"; Rec."Location Code")
                {
                }
            }
            group(Purchase)
            {
                Caption = 'Purchase';

                field("Purchase Date"; Rec."Purchase Date")
                {
                }
                field("Purchase Cost"; Rec."Purchase Cost")
                {
                }
            }
            part(AssignmentHistory; "EQM Assignment History Part")
            {
                Caption = 'Assignment History';
                SubPageLink = "Equipment No." = field("No.");
            }
            group(Audit)
            {
                Caption = 'Audit';

                field(CreatedDate; Rec.SystemCreatedAt)
                {
                    Caption = 'Created Date';
                    Editable = false;
                    ToolTip = 'Specifies when the equipment record was created.';
                }
                field(CreatedBy; CreatedByUserName)
                {
                    Caption = 'Created By';
                    Editable = false;
                    ToolTip = 'Specifies the user who created the equipment record.';
                }
                field(LastModifiedDate; Rec.SystemModifiedAt)
                {
                    Caption = 'Last Modified Date';
                    Editable = false;
                    ToolTip = 'Specifies when the equipment record was last modified.';
                }
                field(LastModifiedBy; ModifiedByUserName)
                {
                    Caption = 'Last Modified By';
                    Editable = false;
                    ToolTip = 'Specifies the user who last changed the equipment record.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(AssignToEmployee)
            {
                Caption = 'Assign to Employee';
                ToolTip = 'Assigns available equipment to an active employee that you select. The assignment is recorded with the work date and your user name.';
                Image = Employee;
                Enabled = CanAssign;

                trigger OnAction()
                var
                    EmployeeNo: Code[20];
                begin
                    if SelectActiveEmployee(EmployeeNo) then begin
                        Rec.AssignEmployee(EmployeeNo);
                        CurrPage.Update(false);
                    end;
                end;
            }
            action(Unassign)
            {
                Caption = 'Return';
                ToolTip = 'Returns the equipment from the assigned employee. The status changes to Available and the assignment is closed with the work date and your user name. The assignment stays in the history.';
                Image = Undo;
                Enabled = IsAssigned;

                trigger OnAction()
                begin
                    Rec.UnassignEmployee();
                    CurrPage.Update(false);
                end;
            }
        }
        area(Navigation)
        {
            action(Assignments)
            {
                Caption = 'Assignments';
                ToolTip = 'View the assignment history of the equipment.';
                Image = History;
                Enabled = IsSaved;
                RunObject = page "EQM Equipment Assignments";
                RunPageLink = "Equipment No." = field("No.");
            }
        }
        area(Promoted)
        {
            actionref(AssignToEmployee_Promoted; AssignToEmployee)
            {
            }
            actionref(Unassign_Promoted; Unassign)
            {
            }
            actionref(Assignments_Promoted; Assignments)
            {
            }
        }
    }

    var
        AssignedEmployeeName: Text[100];
        IsAssigned: Boolean;
        IsSaved: Boolean;
        IsNewRecord: Boolean;
        CanAssign: Boolean;
        StatusStyle: Text;
        ActiveAssignmentDate: Date;
        ActiveAssignedBy: Code[50];
        CreatedByUserName: Code[50];
        ModifiedByUserName: Code[50];
        UseAssignActionErr: Label 'To assign equipment, use the Assign to Employee action.';

    trigger OnAfterGetRecord()
    begin
        UpdateControls();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        UpdateControls();
    end;

    local procedure SelectActiveEmployee(var EmployeeNo: Code[20]): Boolean
    var
        Employee: Record Employee;
        EmployeeList: Page "Employee List";
    begin
        Employee.SetRange(Status, Employee.Status::Active);
        Employee.SetRange("Privacy Blocked", false);
        EmployeeList.SetTableView(Employee);
        EmployeeList.LookupMode(true);
        if EmployeeList.RunModal() <> Action::LookupOK then
            exit(false);

        EmployeeList.GetRecord(Employee);
        EmployeeNo := Employee."No.";
        exit(true);
    end;

    local procedure UpdateControls()
    var
        Employee: Record Employee;
        ActiveAssignment: Record "EQM Equipment Assignment";
        AssignmentMgt: Codeunit "EQM Assignment Mgt.";
    begin
        IsAssigned := Rec.Status = Rec.Status::Assigned;
        IsSaved := Rec.SystemCreatedAt <> 0DT;
        IsNewRecord := not IsSaved;
        StatusStyle := Rec.GetStatusStyle();
        CanAssign := IsSaved and (Rec.Status = Rec.Status::Available);
        AssignedEmployeeName := '';
        if (Rec."Assigned Employee No." <> '') and Employee.ReadPermission() then begin
            Employee.SetLoadFields("First Name", "Middle Name", "Last Name");
            if Employee.Get(Rec."Assigned Employee No.") then
                AssignedEmployeeName := Employee.FullName();
        end;

        ActiveAssignmentDate := 0D;
        ActiveAssignedBy := '';
        CreatedByUserName := '';
        ModifiedByUserName := '';
        if IsSaved and (Rec.Status = Rec.Status::Assigned) then
            if AssignmentMgt.GetActiveAssignment(Rec."No.", ActiveAssignment) then begin
                ActiveAssignmentDate := ActiveAssignment."Assignment Date";
                ActiveAssignedBy := ActiveAssignment."Assigned By";
            end;
        CreatedByUserName := GetUserName(Rec.SystemCreatedBy);
        ModifiedByUserName := GetUserName(Rec.SystemModifiedBy);
    end;

    local procedure GetUserName(UserSecurityId: Guid): Code[50]
    var
        User: Record User;
    begin
        if IsNullGuid(UserSecurityId) then
            exit('');
        if not User.ReadPermission() then
            exit('');
        User.SetLoadFields("User Name");
        if User.Get(UserSecurityId) then
            exit(User."User Name");
        exit('');
    end;
}
