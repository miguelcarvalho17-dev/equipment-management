namespace MiguelCarvalho.EquipmentManagement;

page 50116 "EQM Maintenance History Part"
{
    Caption = 'Maintenance History';
    PageType = ListPart;
    ApplicationArea = All;
    SourceTable = "EQM Maintenance History Entry";
    SourceTableView = sorting("Equipment No.", "Maintenance Date") order(descending);
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(History)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    Visible = false;
                }
                field("Maintenance Date"; Rec."Maintenance Date")
                {
                }
                field("Maintenance Type"; Rec."Maintenance Type")
                {
                }
                field("Vendor No."; Rec."Vendor No.")
                {
                }
                field("Vendor Name"; Rec."Vendor Name")
                {
                }
                field(Cost; Rec.Cost)
                {
                }
                field(Description; Rec.Description)
                {
                }
                field("Performed By"; Rec."Performed By")
                {
                    Visible = false;
                }
                field("Maintenance No."; Rec."Maintenance No.")
                {
                    Visible = false;
                }
                field("Posted By"; Rec."Posted By")
                {
                    Visible = false;
                }
                field("Posted At"; Rec."Posted At")
                {
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ShowMaintenanceRecord)
            {
                Caption = 'Show Maintenance Record';
                ToolTip = 'Open the posted maintenance record that this history entry was created from.';
                Image = View;
                RunObject = page "EQM Maintenance Record Card";
                RunPageLink = "No." = field("Maintenance No.");
            }
        }
    }
}
