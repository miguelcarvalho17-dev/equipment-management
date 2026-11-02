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
        field(3; Active; Boolean)
        {
            Caption = 'Active';
            ToolTip = 'Specifies whether the category can be selected for equipment. Equipment that already uses an inactive category keeps it.';
            InitValue = true;
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
        CategoryInUseErr: Label 'You cannot delete category %1 because it is used by one or more equipment records. To stop using the category, clear the Active check box instead.', Comment = '%1 = category code';
        CategoryRenameInactiveErr: Label 'You cannot rename category %1 because it is not active and is used by equipment. Select the Active check box, rename the category, and then clear the check box again.', Comment = '%1 = category code';

    trigger OnDelete()
    var
        Equipment: Record "EQM Equipment";
    begin
        Equipment.SetCurrentKey("Category Code");
        Equipment.SetRange("Category Code", Code);
        if not Equipment.IsEmpty() then
            Error(CategoryInUseErr, Code);
    end;

    /// <summary>
    /// Blocks renaming an inactive category that equipment uses. Equipment follows a renamed category through
    /// the table relation, which is filtered to active categories. It is not verified that the platform updates
    /// equipment for an inactive category, so the rename is refused to keep the data consistent.
    /// </summary>
    trigger OnRename()
    var
        Equipment: Record "EQM Equipment";
    begin
        if xRec.Active and Active then
            exit;

        Equipment.SetCurrentKey("Category Code");
        Equipment.SetRange("Category Code", xRec.Code);
        if not Equipment.IsEmpty() then
            Error(CategoryRenameInactiveErr, xRec.Code);
    end;
}
