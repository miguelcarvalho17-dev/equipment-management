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
        }
    }

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
    end;

    /// <summary>
    /// Recalculates the tiles with the current equipment data.
    /// </summary>
    internal procedure RefreshCues()
    begin
        CurrPage.Update(false);
    end;
}
