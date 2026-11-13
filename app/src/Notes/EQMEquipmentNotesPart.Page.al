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
        CurrentEquipmentNo: Code[20];

    /// <summary>
    /// Sets the equipment that new note lines are created for. The Equipment Card calls this whenever its record changes.
    /// </summary>
    /// <param name="EquipmentNo">The number of the equipment shown on the card.</param>
    procedure SetEquipmentNo(EquipmentNo: Code[20])
    begin
        CurrentEquipmentNo := EquipmentNo;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        IsNewLine := true;
        Rec."Equipment No." := CurrentEquipmentNo;
    end;

    trigger OnAfterGetCurrRecord()
    begin
        IsNewLine := Rec."Entry No." = 0;
    end;
}
