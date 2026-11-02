namespace MiguelCarvalho.EquipmentManagement;

page 50102 "EQM Equipment Categories"
{
    Caption = 'Equipment Categories';
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "EQM Equipment Category";
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Categories)
            {
                field("Code"; Rec."Code")
                {
                }
                field(Description; Rec.Description)
                {
                }
                field(Active; Rec.Active)
                {
                }
            }
        }
    }
}
