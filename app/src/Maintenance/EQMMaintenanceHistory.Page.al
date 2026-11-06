namespace MiguelCarvalho.EquipmentManagement;

page 50117 "EQM Maintenance History"
{
    Caption = 'Maintenance History';
    AboutTitle = 'About the maintenance history';
    AboutText = 'This list shows every maintenance that was posted, with its date, type, vendor and cost. An entry is created when you post a maintenance record. Entries cannot be changed or deleted, so the history stays complete. Choose a view at the top to see one maintenance type.';
    PageType = List;
    ApplicationArea = All;
    UsageCategory = History;
    AdditionalSearchTerms = 'posted maintenance, maintenance history entries, maintenance costs, equipment service history';
    SourceTable = "EQM Maintenance History Entry";
    SourceTableView = sorting("Entry No.") order(descending);
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Entries)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    Visible = false;
                }
                field("Maintenance Date"; Rec."Maintenance Date")
                {
                }
                field("Equipment No."; Rec."Equipment No.")
                {
                }
                field("Equipment Description"; Rec."Equipment Description")
                {
                }
                field("Maintenance Type"; Rec."Maintenance Type")
                {
                }
                field(Description; Rec.Description)
                {
                }
                field("Vendor No."; Rec."Vendor No.")
                {
                }
                field("Vendor Name"; Rec."Vendor Name")
                {
                }
                field("Performed By"; Rec."Performed By")
                {
                }
                field(Cost; Rec.Cost)
                {
                }
                field("Maintenance No."; Rec."Maintenance No.")
                {
                }
                field("Posted By"; Rec."Posted By")
                {
                }
                field("Posted At"; Rec."Posted At")
                {
                }
            }
        }
        area(FactBoxes)
        {
            part(EquipmentFactBox; "EQM Equipment FactBox")
            {
                SubPageLink = "No." = field("Equipment No.");
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
            action(Equipment)
            {
                Caption = 'Equipment';
                ToolTip = 'Open the equipment card.';
                Image = FixedAssets;
                RunObject = page "EQM Equipment Card";
                RunPageLink = "No." = field("Equipment No.");
            }
            action(MaintenanceRecord)
            {
                Caption = 'Maintenance Record';
                ToolTip = 'Open the posted maintenance record that this entry was created from.';
                Image = View;
                RunObject = page "EQM Maintenance Record Card";
                RunPageLink = "No." = field("Maintenance No.");
            }
        }
        area(Promoted)
        {
            group(Category_Category4)
            {
                Caption = 'Navigate';

                actionref(Equipment_Promoted; Equipment)
                {
                }
                actionref(MaintenanceRecord_Promoted; MaintenanceRecord)
                {
                }
            }
        }
    }

    views
    {
        view(Preventive)
        {
            Caption = 'Preventive';
            Filters = where("Maintenance Type" = const(Preventive));
        }
        view(Corrective)
        {
            Caption = 'Corrective';
            Filters = where("Maintenance Type" = const(Corrective));
        }
        view(Inspection)
        {
            Caption = 'Inspection';
            Filters = where("Maintenance Type" = const(Inspection));
        }
        view(Upgrade)
        {
            Caption = 'Upgrade';
            Filters = where("Maintenance Type" = const(Upgrade));
        }
    }
}
