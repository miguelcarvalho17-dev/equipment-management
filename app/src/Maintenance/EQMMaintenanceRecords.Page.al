namespace MiguelCarvalho.EquipmentManagement;

using Microsoft.Purchases.Vendor;

page 50113 "EQM Maintenance Records"
{
    Caption = 'Equipment Maintenance';
    AboutTitle = 'About equipment maintenance';
    AboutText = 'This list shows the maintenance work done on your equipment: when, what type, by whom and at what cost. Choose **New** to register maintenance and **Post** when a record is final. Posting copies the record to the maintenance history and locks it. No record can be deleted. Choose a view at the top to see one maintenance type, or only open or posted records.';
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
                field(Status; Rec.Status)
                {
                    StyleExpr = StatusStyle;
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
        area(Processing)
        {
            action(Post)
            {
                Caption = 'Post';
                ToolTip = 'Post the maintenance record. It is copied to the maintenance history, and after that it cannot be changed or deleted.';
                Image = PostDocument;
                ShortCutKey = 'F9';
                Enabled = CanPost;

                trigger OnAction()
                begin
                    if MaintenanceMgt.PostWithConfirmation(Rec) then
                        CurrPage.Update(false);
                end;
            }
        }
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
            action(HistoryEntry)
            {
                Caption = 'History Entry';
                ToolTip = 'View the maintenance history entry that was created when the record was posted.';
                Image = LedgerEntries;
                Enabled = CanShowHistoryEntry;
                RunObject = page "EQM Maintenance History";
                RunPageLink = "Maintenance No." = field("No.");
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Post_Promoted; Post)
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Navigate';

                actionref(Equipment_Promoted; Equipment)
                {
                }
                actionref(Vendor_Promoted; Vendor)
                {
                }
                actionref(HistoryEntry_Promoted; HistoryEntry)
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
        view(OpenRecords)
        {
            Caption = 'Open';
            Filters = where(Status = const(Open));
        }
        view(PostedRecords)
        {
            Caption = 'Posted';
            Filters = where(Status = const(Posted));
        }
    }

    var
        MaintenanceMgt: Codeunit "EQM Maintenance Mgt.";
        VendorName: Text[100];
        StatusStyle: Text;
        CanPost: Boolean;
        CanShowHistoryEntry: Boolean;

    trigger OnAfterGetRecord()
    begin
        VendorName := MaintenanceMgt.GetVendorName(Rec."Vendor No.");
        StatusStyle := Rec.GetStatusStyle();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        CanPost := (Rec."No." <> '') and (Rec.Status = Rec.Status::Open);
        CanShowHistoryEntry := Rec.Status = Rec.Status::Posted;
    end;
}
