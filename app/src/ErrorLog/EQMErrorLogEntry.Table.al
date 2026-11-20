namespace MiguelCarvalho.EquipmentManagement;

/// <summary>
/// Log of errors that stopped an unattended process of the app, such as a monitoring job. Entries are written only by
/// the error log codeunit and cannot be changed. The error message can contain data from the records that were
/// processed, so only administrators can read and delete entries.
/// </summary>
table 50115 "EQM Error Log Entry"
{
    Caption = 'Error Log Entry';
    DataClassification = CustomerContent;
    Access = Internal;
    LookupPageId = "EQM Error Log";
    DrillDownPageId = "EQM Error Log";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            ToolTip = 'Specifies the number of the error log entry.';
            AutoIncrement = true;
            Editable = false;
        }
        field(2; "Logged At"; DateTime)
        {
            Caption = 'Logged At';
            ToolTip = 'Specifies the date and time when the error happened.';
            Editable = false;
        }
        field(3; "User ID"; Code[50])
        {
            Caption = 'User ID';
            ToolTip = 'Specifies the user who ran the process that failed. For a job queue entry, this is the user that the job runs as.';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(4; Operation; Enum "EQM Error Operation")
        {
            Caption = 'Operation';
            ToolTip = 'Specifies the process that failed: the warranty alert job, the overdue maintenance job, or the scheduling of these jobs.';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(5; "Object ID"; Integer)
        {
            Caption = 'Object ID';
            ToolTip = 'Specifies the ID of the codeunit that ran the process that failed.';
            DataClassification = SystemMetadata;
            BlankZero = true;
            Editable = false;
        }
        field(6; "Error Message"; Text[2048])
        {
            Caption = 'Error Message';
            ToolTip = 'Specifies the error message. It can contain data from the records that were processed.';
            Editable = false;
        }
        field(7; "Error Code"; Text[250])
        {
            Caption = 'Error Code';
            ToolTip = 'Specifies the classification of the error that the platform returned, for support.';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(8; "Error Call Stack"; Text[2048])
        {
            Caption = 'Error Call Stack';
            ToolTip = 'Specifies the AL call stack at the moment of the error, for support.';
            DataClassification = SystemMetadata;
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Entry No.", "Logged At", Operation, "Error Message")
        {
        }
        fieldgroup(Brick; "Logged At", Operation, "Error Message", "User ID")
        {
        }
    }

    var
        InsertAllowed: Boolean;
        InsertNotAllowedErr: Label 'You cannot create error log entries directly. Entries are created when a monitoring job fails.';
        ModifyNotAllowedErr: Label 'You cannot change error log entry %1. The error log is read-only.', Comment = '%1 = entry number';
        RenameNotAllowedErr: Label 'You cannot change the number of error log entry %1.', Comment = '%1 = entry number';

    trigger OnInsert()
    begin
        if not InsertAllowed then
            Error(InsertNotAllowedErr);

        InsertAllowed := false;
    end;

    trigger OnModify()
    begin
        Error(ModifyNotAllowedErr, "Entry No.");
    end;

    trigger OnRename()
    begin
        Error(RenameNotAllowedErr, xRec."Entry No.");
    end;

    /// <summary>
    /// Enables the next insert on this record variable. Only the error log codeunit calls it.
    /// </summary>
    internal procedure AllowInsertFromErrorLog()
    begin
        InsertAllowed := true;
    end;
}
