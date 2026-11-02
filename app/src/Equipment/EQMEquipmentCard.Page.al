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

                field(Status; Rec.Status)
                {
                    trigger OnValidate()
                    begin
                        UpdateControls();
                    end;
                }
                field("Assigned Employee No."; Rec."Assigned Employee No.")
                {
                    Editable = IsAssigned;
                    ShowMandatory = IsAssigned;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        EmployeeNo: Code[20];
                    begin
                        if SelectActiveEmployee(EmployeeNo) then begin
                            Text := EmployeeNo;
                            exit(true);
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        UpdateControls();
                    end;
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
                ToolTip = 'Assigns the equipment to an active employee that you select.';
                Image = Employee;
                Enabled = IsSaved;

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
                ToolTip = 'Removes the assigned employee and sets the status to Available.';
                Image = Undo;
                Enabled = IsAssigned;

                trigger OnAction()
                begin
                    Rec.UnassignEmployee();
                    CurrPage.Update(false);
                end;
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
        }
    }

    var
        AssignedEmployeeName: Text[100];
        IsAssigned: Boolean;
        IsSaved: Boolean;

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
        AssignedEmployeeName := '';
        if Rec."Assigned Employee No." <> '' then
            if Employee.Get(Rec."Assigned Employee No.") then
                AssignedEmployeeName := Employee.FullName();
    end;
}
