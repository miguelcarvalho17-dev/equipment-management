namespace MiguelCarvalho.EquipmentManagement;

page 50130 "EQM Equipment Notes Part"
{
    Caption = 'Equipment Notes';
    PageType = ListPart;
    ApplicationArea = All;
    SourceTable = "EQM Equipment Note";
    SourceTableView = sorting("Entry No.") order(descending);
    DelayedInsert = true;
    InsertAllowed = true;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Notes)
            {
                field("Created At"; Rec."Created At")
                {
                }
                field("User ID"; Rec."User ID")
                {
                }
                field(Comment; Rec.Comment)
                {
                    Editable = IsNewLine;
                }
            }
        }
    }

    var
        IsNewLine: Boolean;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        IsNewLine := true;
        // Take the equipment from the card's SubPageLink filter when it is a single value.
        if Rec."Equipment No." = '' then
            if Rec.GetFilter("Equipment No.") <> '' then
                if Rec.GetRangeMin("Equipment No.") = Rec.GetRangeMax("Equipment No.") then
                    Rec."Equipment No." := Rec.GetRangeMin("Equipment No.");
    end;

    trigger OnAfterGetCurrRecord()
    begin
        IsNewLine := Rec."Entry No." = 0;
    end;
}
