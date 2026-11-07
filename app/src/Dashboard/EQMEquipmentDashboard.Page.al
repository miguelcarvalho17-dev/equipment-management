namespace MiguelCarvalho.EquipmentManagement;

page 50109 "EQM Equipment Dashboard"
{
    Caption = 'Equipment Dashboard';
    AboutTitle = 'About the equipment dashboard';
    AboutText = 'The tiles count your equipment by status and show the total and average cost of posted maintenance. **Total Equipment** includes lost and disposed equipment. The charts show how your equipment is spread over categories and statuses, which categories cost the most in maintenance, and the ten pieces of equipment with the highest maintenance cost. Choose a tile or a chart segment to see the details. Choose **Refresh** to update the numbers.';
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = ReportsAndAnalysis;
    AdditionalSearchTerms = 'equipment kpi, equipment overview, equipment chart, maintenance cost, maintenance kpi';
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
            part(CategoryCostChart; "EQM Category Cost Chart")
            {
            }
            part(EquipmentCostChart; "EQM Equipment Cost Chart")
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
                ToolTip = 'Update the tiles and charts with the current equipment and maintenance data.';
                Image = Refresh;

                trigger OnAction()
                begin
                    CurrPage.Cues.Page.RefreshCues();
                    CurrPage.CategoryChart.Page.RefreshChart();
                    CurrPage.StatusChart.Page.RefreshChart();
                    CurrPage.CategoryCostChart.Page.RefreshChart();
                    CurrPage.EquipmentCostChart.Page.RefreshChart();
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
