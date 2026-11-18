namespace MiguelCarvalho.EquipmentManagement;

using Microsoft.HumanResources.Employee;

page 50134 "EQM Equipment Request Card"
{
    Caption = 'Equipment Request';
    AboutTitle = 'About equipment requests';
    AboutText = 'Raise a request for equipment. Choose the employee who needs it, the type of equipment, and enter why it is needed. The request date is today unless you change it. New requests are Open. You can correct or delete a request while it is open. Send an open request for approval; another manager approves or rejects it, and approved requests are completed by assigning equipment.';
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
            group(Approval)
            {
                Caption = 'Approval';

                field("Sent for Approval By"; Rec."Sent for Approval By")
                {
                }
                field("Decided By"; Rec."Decided By")
                {
                }
                field("Decision Date"; Rec."Decision Date")
                {
                }
                field("Decision Comment"; Rec."Decision Comment")
                {
                    MultiLine = true;
                }
                field("Assigned Equipment No."; Rec."Assigned Equipment No.")
                {
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SendForApproval)
            {
                Caption = 'Send for Approval';
                ToolTip = 'Send the open request for approval. Another manager then approves or rejects it.';
                Image = SendApprovalRequest;
                Enabled = CanSendForApproval;

                trigger OnAction()
                begin
                    RequestApprovalMgt.SendForApproval(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(Approve)
            {
                Caption = 'Approve';
                ToolTip = 'Approve the request. You cannot approve a request that you sent for approval.';
                Image = Approve;
                Enabled = CanDecide;

                trigger OnAction()
                begin
                    RequestApprovalMgt.ApproveWithDialog(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(Reject)
            {
                Caption = 'Reject';
                ToolTip = 'Reject the request. You must enter the reason. A rejected request cannot be reopened.';
                Image = Reject;
                Enabled = CanDecide;

                trigger OnAction()
                begin
                    RequestApprovalMgt.RejectWithDialog(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(AssignEquipment)
            {
                Caption = 'Assign Equipment';
                ToolTip = 'Choose available equipment of the requested type and assign it to the employee. The request is then completed.';
                Image = Allocate;
                Enabled = CanAssignEquipment;

                trigger OnAction()
                begin
                    RequestApprovalMgt.AssignEquipmentWithLookup(Rec);
                    CurrPage.Update(false);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(SendForApproval_Promoted; SendForApproval)
                {
                }
                actionref(Approve_Promoted; Approve)
                {
                }
                actionref(Reject_Promoted; Reject)
                {
                }
                actionref(AssignEquipment_Promoted; AssignEquipment)
                {
                }
            }
        }
    }

    var
        RequestApprovalMgt: Codeunit "EQM Request Approval Mgt.";
        EmployeeName: Text[100];
        StatusStyle: Text;
        IsOpen: Boolean;
        CanSendForApproval: Boolean;
        CanDecide: Boolean;
        CanAssignEquipment: Boolean;

    trigger OnOpenPage()
    var
        FeatureMgt: Codeunit "EQM Feature Mgt.";
    begin
        FeatureMgt.CheckEnabled("EQM Feature"::"Approval Workflows");
    end;

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
        UpdateActionStates();
    end;

    local procedure UpdateActionStates()
    begin
        IsOpen := Rec.Status = Rec.Status::Open;
        CanSendForApproval := IsOpen;
        CanDecide := Rec.Status = Rec.Status::"Pending Approval";
        CanAssignEquipment := Rec.Status = Rec.Status::Approved;
    end;

    local procedure UpdateControls()
    begin
        UpdateActionStates();
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
