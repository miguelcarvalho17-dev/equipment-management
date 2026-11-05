namespace MiguelCarvalho.EquipmentManagement;

page 50103 "EQM Equipment Setup"
{
    Caption = 'Equipment Setup';
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    AdditionalSearchTerms = 'equipment numbers, equipment number series, maintenance number series';
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
                field("Maintenance Nos."; Rec."Maintenance Nos.")
                {
                }
            }
        }
    }

    var
        SetupMissingErr: Label 'The equipment setup has not been created in this company yet. Ask a user with the Equipment Administrator permission set to open the Equipment Setup page.';

    trigger OnOpenPage()
    var
        DefaultData: Codeunit "EQM Default Data";
    begin
        if not Rec.Get() then begin
            if not Rec.WritePermission() then
                Error(SetupMissingErr);
            DefaultData.CreateDefaultData();
            Rec.Get();
        end;
        if not Rec.WritePermission() then
            CurrPage.Editable := false;
    end;
}
