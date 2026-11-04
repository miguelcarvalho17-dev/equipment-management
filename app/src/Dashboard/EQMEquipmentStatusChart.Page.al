namespace MiguelCarvalho.EquipmentManagement;

using System.Integration;
using System.Visualization;

page 50108 "EQM Equipment Status Chart"
{
    Caption = 'Equipment by Status';
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
                    StatusIndex: Integer;
                begin
                    if not Point.Get('XValueString', XValueToken) then
                        exit;
                    if not XValueToken.IsValue() then
                        exit;
                    if XValueToken.AsValue().IsNull() then
                        exit;
                    StatusIndex := StatusCaptions.IndexOf(XValueToken.AsValue().AsText());
                    if StatusIndex = 0 then
                        exit;
                    DashboardMgt.ShowEquipmentByStatus(StatusOrdinals.Get(StatusIndex));
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
                ToolTip = 'Updates the chart with the current equipment data.';
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
        StatusOrdinals: List of [Integer];
        EquipmentCounts: List of [Integer];
        StatusCaptions: List of [Text];
        IsChartReady: Boolean;
        EquipmentMeasureLbl: Label 'Equipment';
        StatusDimensionLbl: Label 'Status';

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

        DashboardMgt.GetEquipmentCountByStatus(StatusOrdinals, EquipmentCounts);

        BusinessChart.Initialize();
        BusinessChart.AddMeasure(EquipmentMeasureLbl, 1, Enum::"Business Chart Data Type"::Integer, Enum::"Business Chart Type"::Pie);
        BusinessChart.SetXDimension(StatusDimensionLbl, Enum::"Business Chart Data Type"::String);

        Clear(StatusCaptions);
        for Index := 1 to StatusOrdinals.Count() do begin
            StatusCaptions.Add(DashboardMgt.GetStatusCaption(StatusOrdinals.Get(Index)));
            BusinessChart.AddDataRowWithXDimension(StatusCaptions.Get(Index));
            BusinessChart.SetValue(EquipmentMeasureLbl, Index - 1, EquipmentCounts.Get(Index));
        end;

        BusinessChart.Update(CurrPage.Chart);
    end;
}
