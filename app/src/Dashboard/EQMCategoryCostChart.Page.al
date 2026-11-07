namespace MiguelCarvalho.EquipmentManagement;

using System.Integration;
using System.Visualization;

page 50118 "EQM Category Cost Chart"
{
    Caption = 'Maintenance Cost by Category';
    PageType = CardPart;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            usercontrol(Chart; BusinessChart)
            {
                trigger AddInReady()
                begin
                    IsChartReady := true;
                    UpdateChart();
                end;

                trigger Refresh()
                begin
                    if IsChartReady then
                        UpdateChart();
                end;

                trigger DataPointClicked(Point: JsonObject)
                var
                    XValueToken: JsonToken;
                    CategoryLabel: Text;
                    CategoryIndex: Integer;
                begin
                    if not Point.Get('XValueString', XValueToken) then
                        exit;
                    if not XValueToken.IsValue() then
                        exit;
                    if XValueToken.AsValue().IsNull() then
                        exit;
                    CategoryLabel := XValueToken.AsValue().AsText();
                    CategoryIndex := CategoryLabels.IndexOf(CategoryLabel);
                    if CategoryIndex = 0 then
                        exit;
                    DashboardMgt.ShowEquipmentByCategory(CategoryCodes.Get(CategoryIndex));
                end;
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
                ToolTip = 'Update the chart with the current maintenance costs.';
                Image = Refresh;

                trigger OnAction()
                begin
                    UpdateChart();
                end;
            }
        }
    }

    var
        BusinessChart: Codeunit "Business Chart";
        DashboardMgt: Codeunit "EQM Dashboard Mgt.";
        CategoryCodes: List of [Code[20]];
        CategoryLabels: List of [Text];
        MaintenanceCosts: List of [Decimal];
        IsChartReady: Boolean;
        MaintenanceCostMeasureLbl: Label 'Maintenance Cost';
        CategoryDimensionLbl: Label 'Category';
        BlankCategoryLbl: Label '(blank)', Comment = 'Shown in the chart for equipment without a category';

    /// <summary>
    /// Rebuilds the chart with the current maintenance costs.
    /// </summary>
    internal procedure RefreshChart()
    begin
        UpdateChart();
    end;

    local procedure UpdateChart()
    var
        CategoryLabel: Text;
        Index: Integer;
    begin
        if not IsChartReady then
            exit;

        DashboardMgt.GetMaintenanceCostByCategory(CategoryCodes, MaintenanceCosts);

        BusinessChart.Initialize();
        BusinessChart.AddMeasure(MaintenanceCostMeasureLbl, 1, Enum::"Business Chart Data Type"::Decimal, Enum::"Business Chart Type"::Column);
        BusinessChart.SetXDimension(CategoryDimensionLbl, Enum::"Business Chart Data Type"::String);

        Clear(CategoryLabels);
        for Index := 1 to CategoryCodes.Count() do begin
            if CategoryCodes.Get(Index) = '' then
                CategoryLabel := BlankCategoryLbl
            else
                CategoryLabel := Format(CategoryCodes.Get(Index));
            CategoryLabels.Add(CategoryLabel);
            BusinessChart.AddDataRowWithXDimension(CategoryLabel);
            BusinessChart.SetValue(MaintenanceCostMeasureLbl, Index - 1, MaintenanceCosts.Get(Index));
        end;

        BusinessChart.Update(CurrPage.Chart);
    end;
}
