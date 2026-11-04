namespace MiguelCarvalho.EquipmentManagement;

using Microsoft.HumanResources.Employee;

page 50111 "EQM Equipment FactBox"
{
    Caption = 'Assignment Details';
    PageType = CardPart;
    ApplicationArea = All;
    SourceTable = "EQM Equipment";
    Editable = false;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.")
            {
            }
            field(Status; Rec.Status)
            {
                StyleExpr = StatusStyle;
            }
            group(CurrentAssignment)
            {
                Caption = 'Current Assignment';

                field("Assigned Employee No."; Rec."Assigned Employee No.")
                {
                    trigger OnDrillDown()
                    var
                        Employee: Record Employee;
                    begin
                        if Rec."Assigned Employee No." = '' then
                            exit;
                        if not Employee.ReadPermission() then
                            exit;
                        if Employee.Get(Rec."Assigned Employee No.") then
                            Page.Run(Page::"Employee Card", Employee);
                    end;
                }
                field(EmployeeName; EmployeeName)
                {
                    Caption = 'Employee Name';
                    ToolTip = 'Specifies the name of the employee the equipment is assigned to.';
                }
                field(EmployeeJobTitle; EmployeeJobTitle)
                {
                    Caption = 'Job Title';
                    ToolTip = 'Specifies the job title of the employee the equipment is assigned to.';
                }
                field(EmployeeEmail; EmployeeEmail)
                {
                    Caption = 'Company Email';
                    ExtendedDatatype = EMail;
                    ToolTip = 'Specifies the company email address of the employee the equipment is assigned to.';
                }
                field(AssignedSince; AssignedSince)
                {
                    Caption = 'Assigned Since';
                    ToolTip = 'Specifies the date the equipment was assigned to the current employee. It is blank when the equipment is not assigned.';
                }
                field(AssignedBy; AssignedBy)
                {
                    Caption = 'Assigned By';
                    ToolTip = 'Specifies the user who assigned the equipment to the current employee. It is blank when the equipment is not assigned.';
                }
            }
            group(History)
            {
                Caption = 'History';

                field(NoOfAssignments; NoOfAssignments)
                {
                    Caption = 'No. of Assignments';
                    ToolTip = 'Specifies how many times the equipment has been assigned, including the current assignment. Choose the number to see the assignment history.';

                    trigger OnDrillDown()
                    var
                        AssignmentMgt: Codeunit "EQM Assignment Mgt.";
                    begin
                        AssignmentMgt.ShowAssignments(Rec."No.");
                    end;
                }
                field(LastClosedDate; LastClosedDate)
                {
                    Caption = 'Last Assignment Closed';
                    ToolTip = 'Specifies the date the most recent closed assignment of the equipment ended, because the equipment was returned or its status changed. It is blank when no assignment has been closed.';
                }
            }
        }
    }

    var
        StatusStyle: Text;
        EmployeeName: Text[100];
        EmployeeJobTitle: Text[30];
        EmployeeEmail: Text[80];
        AssignedSince: Date;
        AssignedBy: Code[50];
        NoOfAssignments: Integer;
        LastClosedDate: Date;

    trigger OnAfterGetRecord()
    begin
        ClearFactBox();
        UpdateFactBox();
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        ClearFactBox();
        exit(Rec.Find(Which));
    end;

    local procedure ClearFactBox()
    begin
        StatusStyle := '';
        EmployeeName := '';
        EmployeeJobTitle := '';
        EmployeeEmail := '';
        AssignedSince := 0D;
        AssignedBy := '';
        NoOfAssignments := 0;
        LastClosedDate := 0D;
    end;

    local procedure UpdateFactBox()
    var
        Employee: Record Employee;
        EquipmentAssignment: Record "EQM Equipment Assignment";
        AssignmentMgt: Codeunit "EQM Assignment Mgt.";
    begin
        StatusStyle := Rec.GetStatusStyle();

        if (Rec."Assigned Employee No." <> '') and Employee.ReadPermission() then begin
            Employee.SetLoadFields("First Name", "Middle Name", "Last Name", "Job Title", "Company E-Mail");
            if Employee.Get(Rec."Assigned Employee No.") then begin
                EmployeeName := Employee.FullName();
                EmployeeJobTitle := Employee."Job Title";
                EmployeeEmail := Employee."Company E-Mail";
            end;
        end;

        if Rec.Status = Rec.Status::Assigned then
            if AssignmentMgt.GetActiveAssignment(Rec."No.", EquipmentAssignment) then begin
                AssignedSince := EquipmentAssignment."Assignment Date";
                AssignedBy := EquipmentAssignment."Assigned By";
            end;

        if Rec."No." <> '' then begin
            NoOfAssignments := AssignmentMgt.CountAssignments(Rec."No.");
            if NoOfAssignments > 0 then
                if AssignmentMgt.GetLastClosedAssignment(Rec."No.", EquipmentAssignment) then
                    LastClosedDate := EquipmentAssignment."Closing Date";
        end;
    end;
}
