namespace MiguelCarvalho.EquipmentManagement;

page 50131 "EQM Equipment Notes"
{
    Caption = 'Equipment Notes';
    AboutTitle = 'About equipment notes';
    AboutText = 'Here you see the dated notes recorded for equipment, newest first. Notes cannot be changed or deleted. To add a note, open the equipment card and type on a new line in **Equipment Notes**.';
    AdditionalSearchTerms = 'equipment notes, equipment comments, operational notes';
    PageType = List;
    ApplicationArea = All;
    UsageCategory = History;
    SourceTable = "EQM Equipment Note";
    SourceTableView = sorting("Entry No.") order(descending);
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Notes)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    Visible = false;
                }
                field("Equipment No."; Rec."Equipment No.")
                {
                }
                field("Created At"; Rec."Created At")
                {
                }
                field("User ID"; Rec."User ID")
                {
                }
                field(Comment; Rec.Comment)
                {
                }
            }
        }
    }
}
