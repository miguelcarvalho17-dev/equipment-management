namespace MiguelCarvalho.EquipmentManagement;

report 50102 "EQM Maint. Cost Analysis"
{
    Caption = 'Maintenance Cost Analysis';
    ApplicationArea = All;
    UsageCategory = ReportsAndAnalysis;
    AdditionalSearchTerms = 'maintenance cost report, maintenance spend, repair cost per equipment, maintenance cost by month';
    DefaultRenderingLayout = MaintCostAnalysisExcel;

    dataset
    {
        dataitem(Equipment; "EQM Equipment")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Category Code";

            trigger OnPreDataItem()
            begin
                // Carries the equipment filters of the request page only
                CurrReport.Break();
            end;
        }
        dataitem(HistoryEntry; "EQM Maintenance History Entry")
        {
            DataItemTableView = sorting("Entry No.");
            RequestFilterFields = "Maintenance Date", "Maintenance Type";
            RequestFilterHeading = 'Posted Maintenance';

            trigger OnPreDataItem()
            begin
                // Carries the maintenance filters of the request page only
                CurrReport.Break();
            end;
        }
        dataitem(CostLine; "EQM Maint. Cost Buffer")
        {
            DataItemTableView = sorting("Category Code", "Equipment No.", "Cost Year", "Cost Month");

            column(CategoryCode; "Category Code")
            {
                IncludeCaption = true;
            }
            column(CategoryDescription; "Category Description")
            {
                IncludeCaption = true;
            }
            column(EquipmentNo; "Equipment No.")
            {
                IncludeCaption = true;
            }
            column(EquipmentDescription; "Equipment Description")
            {
                IncludeCaption = true;
            }
            column(CostYear; "Cost Year")
            {
                IncludeCaption = true;
            }
            column(CostMonth; "Cost Month")
            {
                IncludeCaption = true;
            }
            column(PeriodStartDate; "Period Start Date")
            {
                IncludeCaption = true;
            }
            column(NoOfMaintenances; "No. of Maintenances")
            {
                IncludeCaption = true;
            }
            column(TotalCost; "Total Cost")
            {
                IncludeCaption = true;
            }

            trigger OnPreDataItem()
            begin
                DashboardMgt.BuildMaintenanceCostBuffer(Equipment, HistoryEntry, CostLine);
            end;
        }
    }

    rendering
    {
        layout(MaintCostAnalysisExcel)
        {
            Type = Excel;
            LayoutFile = './src/Reports/Layouts/EQMMaintCostAnalysis.xlsx';
            Caption = 'Maintenance Cost Analysis (Excel)';
            Summary = 'Shows the posted maintenance cost and the number of maintenances per category, equipment, year and month for the equipment and maintenance that match your filters, in an Excel workbook that you can total and pivot. Open maintenance records are not included.';
        }
    }

    var
        DashboardMgt: Codeunit "EQM Dashboard Mgt.";
}
