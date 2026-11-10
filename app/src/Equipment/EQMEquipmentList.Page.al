namespace MiguelCarvalho.EquipmentManagement;

using Microsoft.HumanResources.Employee;

page 50100 "EQM Equipment List"
{
    Caption = 'Equipment';
    AboutTitle = 'About equipment';
    AboutText = 'This list shows all your equipment. Use **Search** to find equipment by its number, serial number, or any other column you can see. To filter by category, status, or assigned employee, open the filter pane and add a filter on that field. You can also choose a status view at the top of the list. **Warranty Status** shows whether the warranty is active, expiring soon or expired; to find equipment by warranty, filter on **Warranty End Date** or choose a warranty tile on the dashboard. **Next Maintenance Date** shows when planned maintenance is due and is highlighted when the maintenance is overdue; to find equipment that is due in a period, filter on it with a date range, or choose the **Overdue Maintenance Equipment** tile on the dashboard. **Total Maintenance Cost** shows the cost of posted maintenance; to see the cost of one period, set **Date Filter** under **Filter totals by**.';
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    AdditionalSearchTerms = 'devices, tools, hardware, company equipment';
    SourceTable = "EQM Equipment";
    CardPageId = "EQM Equipment Card";
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Equipment)
            {
                field("No."; Rec."No.")
                {
                }
                field(Description; Rec.Description)
                {
                }
                field("Category Code"; Rec."Category Code")
                {
                }
                field("Serial No."; Rec."Serial No.")
                {
                }
                field(Manufacturer; Rec.Manufacturer)
                {
                }
                field(Model; Rec.Model)
                {
                }
                field(Status; Rec.Status)
                {
                    StyleExpr = StatusStyle;
                }
                field("Assigned Employee No."; Rec."Assigned Employee No.")
                {
                }
                field("Assigned Employee Name"; AssignedEmployeeName)
                {
                    Caption = 'Assigned Employee Name';
                    ToolTip = 'Specifies the name of the employee the equipment is assigned to.';
                }
                field("Location Code"; Rec."Location Code")
                {
                }
                field("Purchase Date"; Rec."Purchase Date")
                {
                    Visible = false;
                }
                field("Purchase Cost"; Rec."Purchase Cost")
                {
                    Visible = false;
                }
                field(WarrantyStatus; WarrantyStatus)
                {
                    Caption = 'Warranty Status';
                    ToolTip = 'Specifies whether the warranty is Active, Expiring Soon (it ends within 30 days) or Expired (the end date has passed). It is calculated from the warranty end date and today''s date, and is blank when no warranty end date is filled in.';
                    StyleExpr = WarrantyStatusStyle;
                }
                field("Warranty Start Date"; Rec."Warranty Start Date")
                {
                    Visible = false;
                }
                field("Warranty End Date"; Rec."Warranty End Date")
                {
                    Visible = false;
                }
                field("Warranty Provider"; Rec."Warranty Provider")
                {
                    Visible = false;
                }
                field("Warranty Reference No."; Rec."Warranty Reference No.")
                {
                    Visible = false;
                }
                field("Next Maintenance Date"; Rec."Next Maintenance Date")
                {
                    StyleExpr = NextMaintenanceStyle;
                }
                field("Last Maintenance Date"; Rec."Last Maintenance Date")
                {
                    Visible = false;
                }
                field("Maintenance Frequency (Months)"; Rec."Maintenance Frequency (Months)")
                {
                    Visible = false;
                }
                field("Total Maintenance Cost"; Rec."Total Maintenance Cost")
                {
                }
                field("No. of Posted Maintenances"; Rec."No. of Posted Maintenances")
                {
                    Visible = false;
                }
                field("Average Maintenance Cost"; Rec."Average Maintenance Cost")
                {
                    Visible = false;
                }
                field(MaintenanceCostPct; MaintenanceCostPct)
                {
                    Caption = 'Maintenance Cost %';
                    ToolTip = 'Specifies the total posted maintenance cost as a percentage of the purchase cost. A value of 100 or more means that maintenance has cost as much as the equipment itself, which may justify replacing it. It is blank when the equipment has no purchase cost or no posted maintenance.';
                    DecimalPlaces = 0 : 1;
                    BlankZero = true;
                    StyleExpr = MaintenanceCostStyle;
                    Visible = false;
                }
            }
        }
        area(FactBoxes)
        {
            part(EquipmentFactBox; "EQM Equipment FactBox")
            {
                SubPageLink = "No." = field("No.");
            }
            part(MaintenanceFactBox; "EQM Maintenance FactBox")
            {
                SubPageLink = "No." = field("No.");
            }
            systempart(Links; Links)
            {
                Visible = false;
            }
            systempart(Notes; Notes)
            {
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            group(EquipmentGroup)
            {
                Caption = 'Equipment';
                Image = FixedAssets;

                action(Assignments)
                {
                    Caption = 'Assignments';
                    ToolTip = 'View the assignment history of the selected equipment.';
                    Image = History;
                    ShortCutKey = 'Ctrl+F7';
                    RunObject = page "EQM Equipment Assignments";
                    RunPageLink = "Equipment No." = field("No.");
                }
                action(Maintenance)
                {
                    Caption = 'Maintenance';
                    ToolTip = 'View the maintenance records of the selected equipment.';
                    Image = MaintenanceRegistrations;
                    RunObject = page "EQM Maintenance Records";
                    RunPageLink = "Equipment No." = field("No.");
                }
            }
            group(SetupGroup)
            {
                Caption = 'Setup';
                Image = Setup;

                action(Categories)
                {
                    Caption = 'Categories';
                    ToolTip = 'Open the list of equipment categories.';
                    Image = Category;
                    RunObject = page "EQM Equipment Categories";
                }
                action(Setup)
                {
                    Caption = 'Equipment Setup';
                    ToolTip = 'Open the equipment setup.';
                    Image = Setup;
                    RunObject = page "EQM Equipment Setup";
                }
            }
        }
        area(Reporting)
        {
            action(Dashboard)
            {
                Caption = 'Dashboard';
                ToolTip = 'Open the equipment dashboard with key figures and charts.';
                Image = BarChart;
                RunObject = page "EQM Equipment Dashboard";
            }
        }
        area(Promoted)
        {
            group(Category_Category4)
            {
                Caption = 'Equipment';

                actionref(Assignments_Promoted; Assignments)
                {
                }
                actionref(Maintenance_Promoted; Maintenance)
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report';

                actionref(Dashboard_Promoted; Dashboard)
                {
                }
            }
        }
    }

    views
    {
        view(Available)
        {
            Caption = 'Available';
            Filters = where(Status = const(Available));
        }
        view(Assigned)
        {
            Caption = 'Assigned';
            Filters = where(Status = const(Assigned));
        }
        view(InMaintenance)
        {
            Caption = 'In Maintenance';
            Filters = where(Status = const("In Maintenance"));
        }
        view(Lost)
        {
            Caption = 'Lost';
            Filters = where(Status = const(Lost));
        }
        view(Disposed)
        {
            Caption = 'Disposed';
            Filters = where(Status = const(Disposed));
        }
    }

    var
        StatusStyle: Text;
        AssignedEmployeeName: Text[100];
        MaintenanceCostPct: Decimal;
        MaintenanceCostStyle: Text;
        WarrantyStatus: Enum "EQM Warranty Status";
        WarrantyStatusStyle: Text;
        NextMaintenanceStyle: Text;

    trigger OnAfterGetRecord()
    var
        Employee: Record Employee;
    begin
        StatusStyle := Rec.GetStatusStyle();
        MaintenanceCostPct := Rec.GetMaintenanceCostPercentage();
        MaintenanceCostStyle := Rec.GetMaintenanceCostStyle(MaintenanceCostPct);
        WarrantyStatus := Rec.GetWarrantyStatus();
        WarrantyStatusStyle := Rec.GetWarrantyStatusStyle(WarrantyStatus);
        NextMaintenanceStyle := Rec.GetNextMaintenanceDateStyle();
        AssignedEmployeeName := '';
        if (Rec."Assigned Employee No." <> '') and Employee.ReadPermission() then begin
            Employee.SetLoadFields("First Name", "Middle Name", "Last Name");
            if Employee.Get(Rec."Assigned Employee No.") then
                AssignedEmployeeName := Employee.FullName();
        end;
    end;
}
