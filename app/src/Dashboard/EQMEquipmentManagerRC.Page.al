namespace MiguelCarvalho.EquipmentManagement;

page 50110 "EQM Equipment Manager RC"
{
    Caption = 'Equipment Manager';
    PageType = RoleCenter;
    ApplicationArea = All;

    layout
    {
        area(RoleCenter)
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
        area(Embedding)
        {
            action(EquipmentList)
            {
                Caption = 'Equipment';
                ToolTip = 'Open the list of all equipment.';
                RunObject = page "EQM Equipment List";
            }
            action(AssignmentList)
            {
                Caption = 'Assignments';
                ToolTip = 'Open the assignment history of all equipment.';
                RunObject = page "EQM Equipment Assignments";
            }
            action(RequestList)
            {
                Caption = 'Equipment Requests';
                ToolTip = 'Open the equipment requests.';
                RunObject = page "EQM Equipment Requests";
            }
            action(MaintenanceList)
            {
                Caption = 'Maintenance';
                ToolTip = 'Open the maintenance records of all equipment.';
                RunObject = page "EQM Maintenance Records";
            }
            action(MaintenanceHistoryList)
            {
                Caption = 'Maintenance History';
                ToolTip = 'Open the posted maintenance history of all equipment, with costs.';
                RunObject = page "EQM Maintenance History";
            }
            action(WarrantyAlertList)
            {
                Caption = 'Warranty Alerts';
                ToolTip = 'Open the warranty alerts of all equipment.';
                RunObject = page "EQM Warranty Alerts";
            }
        }
        area(Sections)
        {
            group(Setup)
            {
                Caption = 'Setup';

                action(EquipmentSetup)
                {
                    Caption = 'Equipment Setup';
                    ToolTip = 'Open the equipment setup.';
                    RunObject = page "EQM Equipment Setup";
                }
                action(EquipmentFeatures)
                {
                    Caption = 'Equipment Features';
                    ToolTip = 'Turn the optional equipment features on or off for this company.';
                    RunObject = page "EQM Equipment Features";
                }
                action(EquipmentCategories)
                {
                    Caption = 'Equipment Categories';
                    ToolTip = 'Open the list of equipment categories.';
                    RunObject = page "EQM Equipment Categories";
                }
            }
        }
        area(Creation)
        {
            action(NewEquipment)
            {
                Caption = 'Equipment';
                ToolTip = 'Create a new equipment record.';
                Image = New;
                RunObject = page "EQM Equipment Card";
                RunPageMode = Create;
            }
            action(NewMaintenanceRecord)
            {
                Caption = 'Maintenance Record';
                ToolTip = 'Register maintenance that was performed on equipment.';
                Image = New;
                RunObject = page "EQM Maintenance Record Card";
                RunPageMode = Create;
            }
        }
        area(Reporting)
        {
            action(EquipmentRegister)
            {
                Caption = 'Equipment Register';
                ToolTip = 'Print the equipment register: a list of equipment with category, status, assigned employee and purchase data. You can filter by category, status, employee and purchase date.';
                Image = Report;
                RunObject = report "EQM Equipment Register";
            }
            action(AssetUtilization)
            {
                Caption = 'Asset Utilization';
                ToolTip = 'Print the asset utilization: total, assigned, available and in-maintenance equipment and the utilization percentage. Lost and disposed equipment is not counted. You can filter by category and location.';
                Image = Report;
                RunObject = report "EQM Asset Utilization";
            }
            action(MaintenanceCostAnalysis)
            {
                Caption = 'Maintenance Cost Analysis';
                ToolTip = 'Print the maintenance cost analysis: posted maintenance cost and number of maintenances per category, equipment, year and month. Open maintenance is not included. You can filter by equipment, category, maintenance date and maintenance type.';
                Image = Report;
                RunObject = report "EQM Maint. Cost Analysis";
            }
            action(UsageAnalytics)
            {
                Caption = 'Usage Analytics';
                ToolTip = 'Open the usage analytics: the most assigned categories, maintenance trends, equipment growth and active users for a period, in an Excel workbook with one sheet per metric.';
                Image = Report;
                RunObject = report "EQM Usage Analytics";
            }
        }
    }
}
