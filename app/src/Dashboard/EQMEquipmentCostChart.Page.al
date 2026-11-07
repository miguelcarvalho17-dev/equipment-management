namespace MiguelCarvalho.EquipmentManagement;

using System.Integration;
using System.Visualization;

page 50119 "EQM Equipment Cost Chart"
{
    Caption = 'Top 10 Equipment by Maintenance Cost';
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
                    EquipmentLabel: Text;
                    EquipmentIndex: Integer;
                begin
                    if not Point.Get('XValueString', XValueToken) then
                        exit;
                    if not XValueToken.IsValue() then
                        exit;
                    if XValueToken.AsValue().IsNull() then
                        exit;
                    EquipmentLabel := XValueToken.AsValue().AsText();
                    EquipmentIndex := EquipmentLabels.IndexOf(EquipmentLabel);
                    if EquipmentIndex = 0 then
                        exit;
                    DashboardMgt.ShowMaintenanceHistory(EquipmentNos.Get(EquipmentIndex));
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
        EquipmentNos: List of [Code[20]];
        EquipmentLabels: List of [Text];
        MaintenanceCosts: List of [Decimal];
        IsChartReady: Boolean;
        MaintenanceCostMeasureLbl: Label 'Maintenance Cost';
        EquipmentDimensionLbl: Label 'Equipment';

    /// <summary>
    /// Rebuilds the chart with the current maintenance costs.
    /// </summary>
    internal procedure RefreshChart()
    begin
        UpdateChart();
    end;

    local procedure UpdateChart()
    var
        EquipmentLabel: Text;
        Index: Integer;
    begin
        if not IsChartReady then
            exit;

        DashboardMgt.GetTopMaintenanceCostByEquipment(DashboardMgt.GetTopEquipmentLimit(), EquipmentNos, MaintenanceCosts);

        BusinessChart.Initialize();
        BusinessChart.AddMeasure(MaintenanceCostMeasureLbl, 1, Enum::"Business Chart Data Type"::Decimal, Enum::"Business Chart Type"::Column);
        BusinessChart.SetXDimension(EquipmentDimensionLbl, Enum::"Business Chart Data Type"::String);

        Clear(EquipmentLabels);
        for Index := 1 to EquipmentNos.Count() do begin
            EquipmentLabel := Format(EquipmentNos.Get(Index));
            EquipmentLabels.Add(EquipmentLabel);
            BusinessChart.AddDataRowWithXDimension(EquipmentLabel);
            BusinessChart.SetValue(MaintenanceCostMeasureLbl, Index - 1, MaintenanceCosts.Get(Index));
        end;

        BusinessChart.Update(CurrPage.Chart);
    end;
}
