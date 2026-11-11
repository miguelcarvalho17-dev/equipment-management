namespace MiguelCarvalho.EquipmentManagement;

page 50121 "EQM Maintenance Log Entries"
{
    Caption = 'Maintenance Log Entries';
    AboutTitle = 'About the maintenance log';
    AboutText = 'This list shows who registered, changed and posted maintenance records, and when. For every changed field it shows the old and the new value. Entries cannot be changed or deleted.';
    PageType = List;
    ApplicationArea = All;
    UsageCategory = History;
    AdditionalSearchTerms = 'maintenance audit, maintenance changes, maintenance log';
    SourceTable = "EQM Maintenance Log Entry";
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
                field("Maintenance No."; Rec."Maintenance No.")
                {
                }
                field("Action"; Rec."Action")
                {
                }
                field("Field Caption"; Rec."Field Caption")
                {
                }
                field("Old Value"; Rec."Old Value")
                {
                }
                field("New Value"; Rec."New Value")
                {
                }
                field("User ID"; Rec."User ID")
                {
                }
            }
        }
    }
}
