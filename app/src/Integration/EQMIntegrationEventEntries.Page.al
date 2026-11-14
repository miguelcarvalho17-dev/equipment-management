namespace MiguelCarvalho.EquipmentManagement;

page 50132 "EQM Integration Event Entries"
{
    Caption = 'Integration Event Entries';
    AboutTitle = 'About integration event entries';
    AboutText = 'This list is the outbox for external systems: one entry for each business event, written when the operation is saved. External systems read the pending entries through the API and mark them as processed. Only processed entries can be deleted.';
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "EQM Integration Event Entry";
    SourceTableView = sorting("Entry No.") order(descending);
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = true;

    layout
    {
        area(Content)
        {
            repeater(Entries)
            {
                field("Entry No."; Rec."Entry No.")
                {
                }
                field("Event Type"; Rec."Event Type")
                {
                }
                field("Equipment No."; Rec."Equipment No.")
                {
                }
                field("Equipment Status"; Rec."Equipment Status")
                {
                }
                field("Assignment Entry No."; Rec."Assignment Entry No.")
                {
                }
                field("Maintenance No."; Rec."Maintenance No.")
                {
                }
                field(CreatedAt; Rec.SystemCreatedAt)
                {
                    Caption = 'Created At';
                    ToolTip = 'Specifies when the entry was created.';
                }
                field(Processed; Rec.Processed)
                {
                }
                field("Processed At"; Rec."Processed At")
                {
                }
            }
        }
    }
}
