namespace MiguelCarvalho.EquipmentManagement;

page 50112 "EQM Assigned Equipment FactBox"
{
    Caption = 'Assigned Equipment';
    PageType = ListPart;
    ApplicationArea = All;
    SourceTable = "EQM Equipment";
    SourceTableView = sorting("Assigned Employee No.", Status) where(Status = const(Assigned));
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Equipment)
            {
                field("No."; Rec."No.")
                {
                    trigger OnDrillDown()
                    var
                        Equipment: Record "EQM Equipment";
                    begin
                        Equipment.SetRange("No.", Rec."No.");
                        Page.Run(Page::"EQM Equipment Card", Equipment);
                    end;
                }
                field(Description; Rec.Description)
                {
                }
                field("Serial No."; Rec."Serial No.")
                {
                    Visible = false;
                }
            }
        }
    }
}
