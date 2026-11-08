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
            }
            cuegroup(MaintenanceCosts)
            {
                Caption = 'Maintenance Costs';

                field("Total Maintenance Cost"; Rec."Total Maintenance Cost")
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

    trigger OnOpenPage()
    var
        DashboardMgt: Codeunit "EQM Dashboard Mgt.";
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
        DashboardMgt.SetWarrantyCueFilters(Rec, Today());
    end;

    /// <summary>
    /// Recalculates the tiles with the current equipment data.
    /// </summary>
    internal procedure RefreshCues()
    begin
        CurrPage.Update(false);
    end;
}
