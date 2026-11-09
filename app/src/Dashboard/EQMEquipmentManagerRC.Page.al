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
    }
}
