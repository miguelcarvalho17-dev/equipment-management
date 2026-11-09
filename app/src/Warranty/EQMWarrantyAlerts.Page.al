namespace MiguelCarvalho.EquipmentManagement;

page 50120 "EQM Warranty Alerts"
{
    Caption = 'Warranty Alerts';
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "EQM Warranty Alert";
    SourceTableView = sorting(Status, "Warranty End Date");
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    AdditionalSearchTerms = 'warranty expiration, expiring warranties, warranty renewal, warranty claims, warranty reminders';
    AboutTitle = 'About warranty alerts';
    AboutText = 'An alert is created when a warranty has 90, 60 or 30 days left, so you can renew it, plan a replacement or raise a claim in time. Alerts are created every day by a job queue entry, or when you choose **Generate Alerts**. When you have acted on an alert, choose **Acknowledge**. If the warranty end date of the equipment changes, its open alerts are cancelled and new alerts are created for the new date.';

    layout
    {
        area(Content)
        {
            repeater(Alerts)
            {
                field("Equipment No."; Rec."Equipment No.")
                {
                }
                field("Equipment Description"; Rec."Equipment Description")
                {
                }
                field("Alert Interval"; Rec."Alert Interval")
                {
                }
                field("Warranty End Date"; Rec."Warranty End Date")
                {
                }
                field(DaysRemaining; DaysRemaining)
                {
                    Caption = 'Days Remaining';
                    ToolTip = 'Specifies how many days are left until the warranty end date of the alert, counted from today. It is negative when the end date has passed.';
                }
                field("Warranty Provider"; Rec."Warranty Provider")
                {
                }
                field(Status; Rec.Status)
                {
                }
                field("Alert Date"; Rec."Alert Date")
                {
                }
                field("Acknowledged By"; Rec."Acknowledged By")
                {
                }
                field("Acknowledged At"; Rec."Acknowledged At")
                {
                    Visible = false;
                }
                field("Cancelled At"; Rec."Cancelled At")
                {
                    Visible = false;
                }
                field("Entry No."; Rec."Entry No.")
                {
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Acknowledge)
            {
                Caption = 'Acknowledge';
                ToolTip = 'Mark the selected open alerts as handled. Acknowledged alerts are not created again for the same warranty end date.';
                Image = Approve;
                Enabled = CanManage;

                trigger OnAction()
                var
                    WarrantyAlert: Record "EQM Warranty Alert";
                    WarrantyAlertMgt: Codeunit "EQM Warranty Alert Mgt.";
                begin
                    CurrPage.SetSelectionFilter(WarrantyAlert);
                    WarrantyAlertMgt.AcknowledgeAlerts(WarrantyAlert);
                    CurrPage.Update(false);
                end;
            }
            action(GenerateAlerts)
            {
                Caption = 'Generate Alerts';
                ToolTip = 'Create the warranty alerts that are due today now, instead of waiting for the job queue. Alerts that already exist are not created again.';
                Image = CreateDocument;
                Enabled = CanManage;

                trigger OnAction()
                var
                    WarrantyAlertMgt: Codeunit "EQM Warranty Alert Mgt.";
                    CreatedCount: Integer;
                    CancelledCount: Integer;
                begin
                    WarrantyAlertMgt.GenerateAlerts(Today(), false, CreatedCount, CancelledCount);
                    Message(AlertsGeneratedMsg, CreatedCount, CancelledCount);
                    CurrPage.Update(false);
                end;
            }
        }
        area(Navigation)
        {
            action(EquipmentCard)
            {
                Caption = 'Equipment';
                ToolTip = 'Open the equipment card of the selected alert.';
                Image = FixedAssets;
                RunObject = page "EQM Equipment Card";
                RunPageLink = "No." = field("Equipment No.");
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Acknowledge_Promoted; Acknowledge)
                {
                }
                actionref(GenerateAlerts_Promoted; GenerateAlerts)
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Equipment';

                actionref(EquipmentCard_Promoted; EquipmentCard)
                {
                }
            }
        }
    }

    views
    {
        view(OpenAlerts)
        {
            Caption = 'Open';
            Filters = where(Status = const(Open));
        }
        view(AcknowledgedAlerts)
        {
            Caption = 'Acknowledged';
            Filters = where(Status = const(Acknowledged));
        }
        view(CancelledAlerts)
        {
            Caption = 'Cancelled';
            Filters = where(Status = const(Cancelled));
        }
    }

    var
        DaysRemaining: Integer;
        CanManage: Boolean;
        AlertsGeneratedMsg: Label '%1 warranty alerts were created and %2 alerts that no longer apply were cancelled.', Comment = '%1 = number of new alerts, %2 = number of cancelled alerts';

    trigger OnOpenPage()
    begin
        CanManage := Rec.WritePermission();
    end;

    trigger OnAfterGetRecord()
    begin
        DaysRemaining := Rec."Warranty End Date" - Today();
    end;
}
