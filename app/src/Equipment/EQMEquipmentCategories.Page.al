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

    actions
    {
        area(Navigation)
        {
            action(Equipment)
            {
                Caption = 'Equipment';
                ToolTip = 'View the equipment in the selected category.';
                Image = FixedAssets;
                RunObject = page "EQM Equipment List";
                RunPageLink = "Category Code" = field("Code");
            }
        }
        area(Promoted)
        {
            actionref(Equipment_Promoted; Equipment)
            {
            }
        }
    }
}
