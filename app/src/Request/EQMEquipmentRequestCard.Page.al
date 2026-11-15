namespace MiguelCarvalho.EquipmentManagement;

using Microsoft.HumanResources.Employee;

page 50134 "EQM Equipment Request Card"
{
    Caption = 'Equipment Request';
    AboutTitle = 'About equipment requests';
    AboutText = 'Raise a request for equipment. Choose the employee who needs it, the type of equipment, and enter why it is needed. The request date is today unless you change it. New requests are Open. You can correct or delete a request while it is open.';
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "EQM Equipment Request";
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
                Editable = IsOpen;

                field("No."; Rec."No.")
                {
                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEdit() then
                            CurrPage.Update(false);
                    end;
                }
                field("Employee No."; Rec."Employee No.")
                {
                    Importance = Promoted;
                    ShowMandatory = true;

                    trigger OnValidate()
                    begin
                        UpdateEmployeeName();
                    end;
                }
                field("Employee Name"; EmployeeName)
                {
                    Caption = 'Employee Name';
                    Editable = false;
                    ToolTip = 'Specifies the name of the employee.';
                }
                field("Requested Equipment Type"; Rec."Requested Equipment Type")
                {
                    Importance = Promoted;
                    ShowMandatory = true;
                }
                field("Equipment Type Description"; Rec."Equipment Type Description")
                {
                }
                field(Justification; Rec.Justification)
                {
                    Importance = Promoted;
                    ShowMandatory = true;
                    MultiLine = true;
                }
                field("Request Date"; Rec."Request Date")
                {
                }
                field(Status; Rec.Status)
                {
                    Importance = Promoted;
                    StyleExpr = StatusStyle;
                }
            }
        }
    }

    var
        EmployeeName: Text[100];
        StatusStyle: Text;
        IsOpen: Boolean;

    trigger OnAfterGetRecord()
    begin
        UpdateControls();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        UpdateControls();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        IsOpen := Rec.Status = Rec.Status::Open;
    end;

    local procedure UpdateControls()
    begin
        IsOpen := Rec.Status = Rec.Status::Open;
        StatusStyle := Rec.GetStatusStyle();
        UpdateEmployeeName();
    end;

    local procedure UpdateEmployeeName()
    var
        EmployeeRec: Record Employee;
    begin
        EmployeeName := '';
        if EmployeeRec.ReadPermission() then begin
            EmployeeRec.SetLoadFields("First Name", "Middle Name", "Last Name");
            if EmployeeRec.Get(Rec."Employee No.") then
                EmployeeName := EmployeeRec.FullName();
        end;
    end;
}
