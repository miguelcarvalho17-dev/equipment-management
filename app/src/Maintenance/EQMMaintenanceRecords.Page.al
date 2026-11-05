namespace MiguelCarvalho.EquipmentManagement;

using Microsoft.Purchases.Vendor;

page 50113 "EQM Maintenance Records"
{
    Caption = 'Equipment Maintenance';
    AboutTitle = 'About equipment maintenance';
    AboutText = 'This list shows the maintenance work done on your equipment: when, what type, by whom and at what cost. Choose **New** to register maintenance. Maintenance records cannot be deleted, so they stay in the history of the equipment. Choose a view at the top to see one maintenance type.';
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    AdditionalSearchTerms = 'equipment maintenance, maintenance history, repairs, inspections, equipment service';
    SourceTable = "EQM Maintenance Record";
    SourceTableView = sorting("No.") order(descending);
    CardPageId = "EQM Maintenance Record Card";
    Editable = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(MaintenanceRecords)
            {
                field("No."; Rec."No.")
                {
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
                field(VendorName; VendorName)
                {
                    Caption = 'Vendor Name';
                    ToolTip = 'Specifies the name of the vendor that performed the maintenance.';
                }
                field("Performed By"; Rec."Performed By")
                {
                }
                field(Cost; Rec.Cost)
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
            action(Vendor)
            {
                Caption = 'Vendor';
                ToolTip = 'Open the vendor card.';
                Image = Vendor;
                RunObject = page "Vendor Card";
                RunPageLink = "No." = field("Vendor No.");
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
                actionref(Vendor_Promoted; Vendor)
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

    var
        VendorName: Text[100];

    trigger OnAfterGetRecord()
    var
        MaintenanceMgt: Codeunit "EQM Maintenance Mgt.";
    begin
        VendorName := MaintenanceMgt.GetVendorName(Rec."Vendor No.");
    end;
}
