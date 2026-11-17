namespace MiguelCarvalho.EquipmentManagement;

using System.Utilities;

report 50101 "EQM Asset Utilization"
{
    Caption = 'Asset Utilization';
    ApplicationArea = All;
    UsageCategory = ReportsAndAnalysis;
    AdditionalSearchTerms = 'equipment utilization, utilisation, asset usage, assigned equipment percentage';
    DefaultRenderingLayout = AssetUtilizationExcel;

    dataset
    {
        dataitem(Equipment; "EQM Equipment")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "Category Code", "Location Code";

            trigger OnPreDataItem()
            begin
                DashboardMgt.CalcAssetUtilization(Equipment, TotalEquipment, AssignedEquipment, AvailableEquipment, InMaintenanceEquipment);
                UtilizationPct := DashboardMgt.CalcUtilizationPct(AssignedEquipment, TotalEquipment);
                CurrReport.Break();
            end;
        }
        dataitem(Summary; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = const(1));

            column(TotalEquipment; TotalEquipment)
            {
            }
            column(AssignedEquipment; AssignedEquipment)
            {
            }
            column(AvailableEquipment; AvailableEquipment)
            {
            }
            column(InMaintenanceEquipment; InMaintenanceEquipment)
            {
            }
            column(UtilizationPct; UtilizationPct)
            {
            }
        }
    }

    rendering
    {
        layout(AssetUtilizationExcel)
        {
            Type = Excel;
            LayoutFile = './src/Reports/Layouts/EQMAssetUtilization.xlsx';
            Caption = 'Asset Utilization (Excel)';
            Summary = 'Shows total, assigned, available and in-maintenance equipment and the utilization percentage (assigned divided by total, times 100) for the equipment that matches your filters. Lost and disposed equipment is not counted.';
        }
    }

    var
        DashboardMgt: Codeunit "EQM Dashboard Mgt.";
        TotalEquipment: Integer;
        AssignedEquipment: Integer;
        AvailableEquipment: Integer;
        InMaintenanceEquipment: Integer;
        UtilizationPct: Decimal;
}
