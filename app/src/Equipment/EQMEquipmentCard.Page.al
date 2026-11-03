namespace MiguelCarvalho.EquipmentManagement;

using Microsoft.HumanResources.Employee;

page 50101 "EQM Equipment Card"
{
    Caption = 'Equipment Card';
    PageType = Card;
    ApplicationArea = All;
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
                    Visible = IsNewRecord;
                    StyleExpr = StatusStyle;

                    trigger OnValidate()
                    begin
                        UpdateControls();
                    end;
                }
                field(Status; Rec.Status)
                {
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
            group(Audit)
            {
                Caption = 'Audit';

                field(CreatedDate; Rec.SystemCreatedAt)
                {
                    Caption = 'Created Date';
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies when the equipment record was created.';
                }
                field(LastModifiedDate; Rec.SystemModifiedAt)
                {
                    Caption = 'Last Modified Date';
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies when the equipment record was last modified.';
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
                Caption = 'Unassign';
                ToolTip = 'Removes the assigned employee, sets the status to Available and closes the assignment.';
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
    begin
        IsAssigned := Rec.Status = Rec.Status::Assigned;
        IsSaved := Rec.SystemCreatedAt <> 0DT;
        IsNewRecord := not IsSaved;
        StatusStyle := Rec.GetStatusStyle();
        CanAssign := IsSaved and (Rec.Status = Rec.Status::Available);
        AssignedEmployeeName := '';
        if Rec."Assigned Employee No." <> '' then
            if Employee.Get(Rec."Assigned Employee No.") then
                AssignedEmployeeName := Employee.FullName();
    end;
}
