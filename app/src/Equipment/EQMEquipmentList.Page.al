namespace MiguelCarvalho.EquipmentManagement;

page 50100 "EQM Equipment List"
{
    Caption = 'Equipment';
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
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
    }

    actions
    {
        area(Navigation)
        {
            action(Categories)
            {
                Caption = 'Categories';
                ToolTip = 'Opens the list of equipment categories.';
                Image = Category;
                RunObject = page "EQM Equipment Categories";
            }
            action(Setup)
            {
                Caption = 'Setup';
                ToolTip = 'Opens the equipment setup.';
                Image = Setup;
                RunObject = page "EQM Equipment Setup";
            }
        }
        area(Promoted)
        {
            actionref(Categories_Promoted; Categories)
            {
            }
            actionref(Setup_Promoted; Setup)
            {
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

    trigger OnAfterGetRecord()
    begin
        StatusStyle := Rec.GetStatusStyle();
    end;
}
