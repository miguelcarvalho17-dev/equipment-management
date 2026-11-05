namespace MiguelCarvalho.EquipmentManagement;

using Microsoft.Purchases.Vendor;

page 50114 "EQM Maintenance Record Card"
{
    Caption = 'Maintenance Record';
    AboutTitle = 'About maintenance records';
    AboutText = 'Register maintenance that was done on equipment. Choose the equipment, the date and the type of maintenance, and add the vendor, the cost and who did the work. You cannot register maintenance for lost or disposed equipment. You can correct a record later, but you cannot delete it or move it to other equipment.';
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
            }
            group(Execution)
            {
                Caption = 'Vendor and Cost';

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

    var
        MaintenanceMgt: Codeunit "EQM Maintenance Mgt.";
        VendorName: Text[100];
        IsNewRecord: Boolean;

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
        VendorName := MaintenanceMgt.GetVendorName(Rec."Vendor No.");
    end;
}
