namespace MiguelCarvalho.EquipmentManagement;

page 50106 "EQM Equipment Cues"
{
    Caption = 'Equipment Activities';
    PageType = CardPart;
    ApplicationArea = All;
    SourceTable = "EQM Equipment Cue";
    RefreshOnActivate = true;
    Editable = false;

    layout
    {
        area(Content)
        {
            cuegroup(Equipment)
            {
                Caption = 'Equipment';

                field("Total Equipment"; Rec."Total Equipment")
                {
                    DrillDownPageId = "EQM Equipment List";
                }
                field("Available Equipment"; Rec."Available Equipment")
                {
                    DrillDownPageId = "EQM Equipment List";
                }
                field("Assigned Equipment"; Rec."Assigned Equipment")
                {
                    DrillDownPageId = "EQM Equipment List";
                }
                field("Equipment in Maintenance"; Rec."Equipment in Maintenance")
                {
                    DrillDownPageId = "EQM Equipment List";
                }
                field("Lost Equipment"; Rec."Lost Equipment")
                {
                    DrillDownPageId = "EQM Equipment List";
                }
                field("Disposed Equipment"; Rec."Disposed Equipment")
                {
                    DrillDownPageId = "EQM Equipment List";
                }
            }
            cuegroup(Warranty)
            {
                Caption = 'Warranty';

                field("Warranty Expiring Soon"; Rec."Warranty Expiring Soon")
                {
                    DrillDownPageId = "EQM Equipment List";
                }
                field("Warranty Expired"; Rec."Warranty Expired")
                {
                    DrillDownPageId = "EQM Equipment List";
                }
                field("Open Warranty Alerts"; Rec."Open Warranty Alerts")
                {
                    DrillDownPageId = "EQM Warranty Alerts";
                }
            }
            cuegroup(PlannedMaintenance)
            {
                Caption = 'Planned Maintenance';

                field("Planned Maintenance This Month"; Rec."Planned Maintenance This Month")
                {
                    DrillDownPageId = "EQM Equipment List";
                }
                field("Overdue Maintenance Equipment"; Rec."Overdue Maintenance Equipment")
                {
                    DrillDownPageId = "EQM Equipment List";
                    StyleExpr = OverdueMaintenanceStyle;
                }
            }
            cuegroup(MaintenanceCosts)
            {
                Caption = 'Maintenance Costs';

                field("Total Maintenance Cost"; Rec."Total Maintenance Cost")
                {
                    DrillDownPageId = "EQM Maintenance History";
                }
                field("Total Maintenance Cost YTD"; Rec."Total Maintenance Cost YTD")
                {
                    DrillDownPageId = "EQM Maintenance History";
                }
                field("Average Maintenance Cost"; Rec."Average Maintenance Cost")
                {
                    DrillDownPageId = "EQM Maintenance History";
                }
            }
        }
    }

    var
        OverdueMaintenanceStyle: Text;

    trigger OnOpenPage()
    var
        DashboardMgt: Codeunit "EQM Dashboard Mgt.";
        NotificationMgt: Codeunit "EQM Notification Mgt.";
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
        DashboardMgt.SetWarrantyCueFilters(Rec, Today());
        DashboardMgt.SetPlannedMaintenanceCueFilters(Rec, Today());
        DashboardMgt.SetMaintenanceCostCueFilters(Rec, Today());
        NotificationMgt.ShowRoleCenterNotifications();
    end;

    trigger OnAfterGetRecord()
    var
        DashboardMgt: Codeunit "EQM Dashboard Mgt.";
    begin
        Rec.CalcFields("Overdue Maintenance Equipment");
        OverdueMaintenanceStyle := DashboardMgt.GetOverdueMaintenanceCueStyle(Rec."Overdue Maintenance Equipment");
    end;

    /// <summary>
    /// Recalculates the tiles with the current equipment data.
    /// </summary>
    internal procedure RefreshCues()
    begin
        CurrPage.Update(false);
    end;
}
