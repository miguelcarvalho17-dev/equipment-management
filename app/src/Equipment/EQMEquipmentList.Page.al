namespace MiguelCarvalho.EquipmentManagement;

using Microsoft.HumanResources.Employee;

page 50100 "EQM Equipment List"
{
    Caption = 'Equipment';
    AboutTitle = 'About equipment';
    AboutText = 'This list shows all your equipment. Use **Search** to find equipment by its number, serial number, or any other column you can see. To filter by category, status, or assigned employee, open the filter pane and add a filter on that field. You can also choose a status view at the top of the list.';
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
            }
        }
        area(FactBoxes)
        {
            part(EquipmentFactBox; "EQM Equipment FactBox")
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

    trigger OnAfterGetRecord()
    var
        Employee: Record Employee;
    begin
        StatusStyle := Rec.GetStatusStyle();
        AssignedEmployeeName := '';
        if (Rec."Assigned Employee No." <> '') and Employee.ReadPermission() then begin
            Employee.SetLoadFields("First Name", "Middle Name", "Last Name");
            if Employee.Get(Rec."Assigned Employee No.") then
                AssignedEmployeeName := Employee.FullName();
        end;
    end;
}
