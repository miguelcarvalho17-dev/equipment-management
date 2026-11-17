namespace MiguelCarvalho.EquipmentManagement;

using Microsoft.HumanResources.Employee;

page 50137 "EQM Equipment Summary FactBox"
{
    Caption = 'Equipment Summary';
    PageType = CardPart;
    ApplicationArea = All;
    SourceTable = "EQM Equipment";
    Editable = false;

    layout
    {
        area(Content)
        {
            field(Status; Rec.Status)
            {
                StyleExpr = StatusStyle;
            }
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
                Caption = 'Assigned Employee Name';
                ToolTip = 'Specifies the name of the employee the equipment is assigned to. It is blank when the equipment is not assigned.';
            }
            field(WarrantyStatus; WarrantyStatus)
            {
                Caption = 'Warranty Status';
                ToolTip = 'Specifies whether the warranty is Active, Expiring Soon (it ends within 30 days) or Expired (the end date has passed). It is calculated from the warranty end date and today''s date, and is blank when no warranty end date is filled in.';
                StyleExpr = WarrantyStatusStyle;
            }
        }
    }

    var
        StatusStyle: Text;
        EmployeeName: Text[100];
        WarrantyStatus: Enum "EQM Warranty Status";
        WarrantyStatusStyle: Text;

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
        WarrantyStatus := "EQM Warranty Status"::" ";
        WarrantyStatusStyle := '';
    end;

    local procedure UpdateFactBox()
    var
        Employee: Record Employee;
    begin
        StatusStyle := Rec.GetStatusStyle();

        if (Rec."Assigned Employee No." <> '') and Employee.ReadPermission() then begin
            Employee.SetLoadFields("First Name", "Middle Name", "Last Name");
            if Employee.Get(Rec."Assigned Employee No.") then
                EmployeeName := Employee.FullName();
        end;

        WarrantyStatus := Rec.GetWarrantyStatus();
        WarrantyStatusStyle := Rec.GetWarrantyStatusStyle(WarrantyStatus);
    end;
}
