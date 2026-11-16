namespace MiguelCarvalho.EquipmentManagement;

page 50136 "EQM Equipment Audit Trail"
{
    Caption = 'Equipment Audit Trail';
    AboutTitle = 'About the equipment audit trail';
    AboutText = 'This list shows the life of the equipment: when it was created, changed, assigned, returned, sent to maintenance or disposed, who did it, and the status afterwards. Changed does not show field values; use the Change Log for that. Entries cannot be changed or deleted.';
    PageType = List;
    ApplicationArea = All;
    UsageCategory = History;
    AdditionalSearchTerms = 'equipment history, equipment lifecycle, equipment audit';
    SourceTable = "EQM Equipment Audit Entry";
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
                field("Logged At"; Rec."Logged At")
                {
                }
                field("Equipment No."; Rec."Equipment No.")
                {
                }
                field("Event Type"; Rec."Event Type")
                {
                }
                field("Status After"; Rec."Status After")
                {
                }
                field("Employee No."; Rec."Employee No.")
                {
                }
                field("Maintenance No."; Rec."Maintenance No.")
                {
                }
                field("Assignment Entry No."; Rec."Assignment Entry No.")
                {
                }
                field("User ID"; Rec."User ID")
                {
                }
            }
        }
    }
}
