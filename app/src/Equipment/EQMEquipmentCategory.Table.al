namespace MiguelCarvalho.EquipmentManagement;

table 50101 "EQM Equipment Category"
{
    Caption = 'Equipment Category';
    DataClassification = CustomerContent;
    Access = Public;
    LookupPageId = "EQM Equipment Categories";
    DrillDownPageId = "EQM Equipment Categories";

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            ToolTip = 'Specifies the code of the equipment category.';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description of the equipment category.';
        }
    }

    keys
    {
        key(PK; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Code", Description)
        {
        }
    }

    var
        CategoryInUseErr: Label 'You cannot delete category %1 because it is used by one or more equipment records.', Comment = '%1 = category code';

    trigger OnDelete()
    var
        Equipment: Record "EQM Equipment";
    begin
        Equipment.SetCurrentKey("Category Code");
        Equipment.SetRange("Category Code", Code);
        if not Equipment.IsEmpty() then
            Error(CategoryInUseErr, Code);
    end;
}
