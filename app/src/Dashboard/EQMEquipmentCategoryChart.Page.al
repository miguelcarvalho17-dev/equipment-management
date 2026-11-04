namespace MiguelCarvalho.EquipmentManagement;

using System.Integration;
using System.Visualization;

page 50107 "EQM Equipment Category Chart"
{
    Caption = 'Equipment by Category';
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
                ToolTip = 'Update the chart with the current equipment data.';
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
        EquipmentCounts: List of [Integer];
        IsChartReady: Boolean;
        EquipmentMeasureLbl: Label 'Equipment';
        CategoryDimensionLbl: Label 'Category';

    /// <summary>
    /// Rebuilds the chart with the current equipment data.
    /// </summary>
    internal procedure RefreshChart()
    begin
        UpdateChart();
    end;

    local procedure UpdateChart()
    var
        Index: Integer;
    begin
        if not IsChartReady then
            exit;

        DashboardMgt.GetEquipmentCountByCategory(CategoryCodes, EquipmentCounts);

        BusinessChart.Initialize();
        BusinessChart.AddMeasure(EquipmentMeasureLbl, 1, Enum::"Business Chart Data Type"::Integer, Enum::"Business Chart Type"::Column);
        BusinessChart.SetXDimension(CategoryDimensionLbl, Enum::"Business Chart Data Type"::String);

        Clear(CategoryLabels);
        for Index := 1 to CategoryCodes.Count() do begin
            CategoryLabels.Add(Format(CategoryCodes.Get(Index)));
            BusinessChart.AddDataRowWithXDimension(CategoryLabels.Get(Index));
            BusinessChart.SetValue(EquipmentMeasureLbl, Index - 1, EquipmentCounts.Get(Index));
        end;

        BusinessChart.Update(CurrPage.Chart);
    end;
}
