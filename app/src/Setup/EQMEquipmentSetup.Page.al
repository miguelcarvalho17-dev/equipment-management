namespace MiguelCarvalho.EquipmentManagement;

page 50103 "EQM Equipment Setup"
{
    Caption = 'Equipment Setup';
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "EQM Equipment Setup";
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(Numbering)
            {
                Caption = 'Numbering';

                field("Equipment Nos."; Rec."Equipment Nos.")
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        DefaultData: Codeunit "EQM Default Data";
    begin
        if DefaultData.EnsureSetupExists() then
            DefaultData.CreateDefaultData();
        Rec.Get();
    end;
}
