namespace MiguelCarvalho.EquipmentManagement;

/// <summary>
/// Append-only operational notes on a piece of equipment. The system sets the creation time and the user when a note
/// is inserted. A note can never be changed, renamed or deleted.
/// </summary>
table 50109 "EQM Equipment Note"
{
    Caption = 'Equipment Note';
    DataClassification = CustomerContent;
    Access = Public;
    LookupPageId = "EQM Equipment Notes";
    DrillDownPageId = "EQM Equipment Notes";
    DataCaptionFields = "Equipment No.";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            ToolTip = 'Specifies the number of the equipment note.';
            AutoIncrement = true;
            Editable = false;
        }
        field(2; "Equipment No."; Code[20])
        {
            Caption = 'Equipment No.';
            ToolTip = 'Specifies the equipment the note is about.';
            TableRelation = "EQM Equipment"."No.";
            NotBlank = true;
        }
        field(3; "Created At"; DateTime)
        {
            Caption = 'Created At';
            ToolTip = 'Specifies the date and time when the note was written. The system sets it.';
            Editable = false;
        }
        field(4; "User ID"; Code[50])
        {
            Caption = 'User ID';
            ToolTip = 'Specifies the user who wrote the note. The system sets it.';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(5; Comment; Text[250])
        {
            Caption = 'Comment';
            ToolTip = 'Specifies the note. A note cannot be changed or deleted after it is saved.';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(EquipmentNo; "Equipment No.", "Entry No.")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Entry No.", "Equipment No.", "Created At", Comment)
        {
        }
        fieldgroup(Brick; "Created At", "User ID", Comment)
        {
        }
    }

    var
        EquipmentNotFoundErr: Label 'Equipment %1 does not exist. You cannot add a note to equipment that does not exist.', Comment = '%1 = equipment number';
        CommentRequiredErr: Label 'You must enter a comment for the note.';
        ModifyNotAllowedErr: Label 'You cannot change equipment note %1. Notes are kept as written. To correct a note, add a new note.', Comment = '%1 = entry number';
        DeleteNotAllowedErr: Label 'You cannot delete equipment note %1. Equipment notes are kept permanently.', Comment = '%1 = entry number';
        RenameNotAllowedErr: Label 'You cannot change the number of equipment note %1.', Comment = '%1 = entry number';

    trigger OnInsert()
    var
        Equipment: Record "EQM Equipment";
    begin
        TestField("Equipment No.");
        Equipment.SetLoadFields("No.");
        if not Equipment.Get("Equipment No.") then
            Error(EquipmentNotFoundErr, "Equipment No.");
        if DelChr(Comment, '<>', ' ') = '' then
            Error(CommentRequiredErr);

        "Created At" := CurrentDateTime();
        "User ID" := CopyStr(UserId(), 1, MaxStrLen("User ID"));
    end;

    trigger OnModify()
    begin
        Error(ModifyNotAllowedErr, "Entry No.");
    end;

    trigger OnDelete()
    begin
        Error(DeleteNotAllowedErr, "Entry No.");
    end;

    trigger OnRename()
    begin
        Error(RenameNotAllowedErr, xRec."Entry No.");
    end;
}
