namespace MiguelCarvalho.EquipmentManagement;

using Microsoft.Purchases.Vendor;

page 50114 "EQM Maintenance Record Card"
{
    Caption = 'Maintenance Record';
    AboutTitle = 'About maintenance records';
    AboutText = 'Register maintenance on equipment. Choose the equipment, the date and the type of maintenance, and add the vendor, the cost and who did the work. When you register the record, the equipment status changes to In Maintenance and the equipment cannot be assigned. You cannot register maintenance for lost or disposed equipment. You can correct the record until you choose **Post**. Posting copies it to the maintenance history, locks it and, when no other maintenance is open, makes the equipment Available again. Maintenance records can never be deleted.';
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "EQM Maintenance Record";
    DelayedInsert = true;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
                Editable = IsOpen;

                field("No."; Rec."No.")
                {
                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEdit() then
                            CurrPage.Update(false);
                    end;
                }
                field("Equipment No."; Rec."Equipment No.")
                {
                    Importance = Promoted;
                    ShowMandatory = true;
                    Editable = IsNewRecord;
                }
                field("Equipment Description"; Rec."Equipment Description")
                {
                }
                field("Maintenance Date"; Rec."Maintenance Date")
                {
                    Importance = Promoted;
                }
                field("Maintenance Type"; Rec."Maintenance Type")
                {
                    Importance = Promoted;
                }
                field(Description; Rec.Description)
                {
                    Importance = Promoted;
                }
                field(Status; Rec.Status)
                {
                    Importance = Promoted;
                    StyleExpr = StatusStyle;
                }
            }
            group(Execution)
            {
                Caption = 'Vendor and Cost';
                Editable = IsOpen;

                field("Vendor No."; Rec."Vendor No.")
                {
                    trigger OnValidate()
                    begin
                        VendorName := MaintenanceMgt.GetVendorName(Rec."Vendor No.");
                    end;
                }
                field(VendorName; VendorName)
                {
                    Caption = 'Vendor Name';
                    Editable = false;
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
            part(MaintenanceFactBox; "EQM Maintenance FactBox")
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
                ToolTip = 'Post the maintenance record. It is copied to the maintenance history, and after that it cannot be changed or deleted. If no other maintenance is open for the equipment, the equipment becomes Available.';
                Image = PostDocument;
                ShortCutKey = 'F9';
                Enabled = CanPost;

                trigger OnAction()
                begin
                    CurrPage.SaveRecord();
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
                Enabled = not IsOpen;
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

    var
        MaintenanceMgt: Codeunit "EQM Maintenance Mgt.";
        VendorName: Text[100];
        IsNewRecord: Boolean;
        IsOpen: Boolean;
        CanPost: Boolean;
        StatusStyle: Text;

    trigger OnAfterGetRecord()
    begin
        UpdateControls();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        UpdateControls();
    end;

    local procedure UpdateControls()
    begin
        IsNewRecord := Rec.SystemCreatedAt = 0DT;
        IsOpen := Rec.Status = Rec.Status::Open;
        CanPost := (not IsNewRecord) and IsOpen;
        StatusStyle := Rec.GetStatusStyle();
        VendorName := MaintenanceMgt.GetVendorName(Rec."Vendor No.");
    end;
}
