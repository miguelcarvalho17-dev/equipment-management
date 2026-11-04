namespace MiguelCarvalho.EquipmentManagement;

page 50109 "EQM Equipment Dashboard"
{
    Caption = 'Equipment Dashboard';
    AboutTitle = 'About the equipment dashboard';
    AboutText = 'The tiles count your equipment by status. **Total Equipment** includes lost and disposed equipment. The charts show how your equipment is spread over categories and statuses. Choose a tile or a chart segment to open the matching equipment. Choose **Refresh** to update the numbers.';
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = ReportsAndAnalysis;
    AdditionalSearchTerms = 'equipment kpi, equipment overview, equipment chart';
    Editable = false;

    layout
    {
        area(Content)
        {
            part(Cues; "EQM Equipment Cues")
            {
            }
            part(CategoryChart; "EQM Equipment Category Chart")
            {
            }
            part(StatusChart; "EQM Equipment Status Chart")
            {
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Refresh)
            {
                Caption = 'Refresh';
                ToolTip = 'Update the tiles and charts with the current equipment data.';
                Image = Refresh;

                trigger OnAction()
                begin
                    CurrPage.Cues.Page.RefreshCues();
                    CurrPage.CategoryChart.Page.RefreshChart();
                    CurrPage.StatusChart.Page.RefreshChart();
                end;
            }
        }
        area(Navigation)
        {
            action(Equipment)
            {
                Caption = 'Equipment';
                ToolTip = 'Open the list of all equipment.';
                Image = FixedAssets;
                RunObject = page "EQM Equipment List";
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Refresh_Promoted; Refresh)
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Navigate';

                actionref(Equipment_Promoted; Equipment)
                {
                }
            }
        }
    }
}
