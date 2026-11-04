namespace MiguelCarvalho.EquipmentManagement;

page 50102 "EQM Equipment Categories"
{
    Caption = 'Equipment Categories';
    AboutTitle = 'About equipment categories';
    AboutText = 'Categories group your equipment, for example laptops or phones. Every piece of equipment needs an active category. To stop using a category, clear **Active** instead of deleting it. Choose **Equipment** to see the equipment in a category.';
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    AdditionalSearchTerms = 'equipment types, equipment groups';
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
            group(Category_Category4)
            {
                Caption = 'Navigate';

                actionref(Equipment_Promoted; Equipment)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        if not Rec.WritePermission() then
            CurrPage.Editable := false;
    end;
}
