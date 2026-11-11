namespace MiguelCarvalho.EquipmentManagement;

using System.Reflection;

/// <summary>
/// Read-only audit trail of maintenance operations: registered, changed (one entry per changed field, with old and new
/// value) and posted. Entries are written only by the maintenance log codeunit and can never be changed, renamed or
/// deleted.
/// </summary>
table 50108 "EQM Maintenance Log Entry"
{
    Caption = 'Maintenance Log Entry';
    DataClassification = CustomerContent;
    Access = Public;
    LookupPageId = "EQM Maintenance Log Entries";
    DrillDownPageId = "EQM Maintenance Log Entries";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            ToolTip = 'Specifies the number of the maintenance log entry.';
            AutoIncrement = true;
            Editable = false;
        }
        field(2; "Maintenance No."; Code[20])
        {
            Caption = 'Maintenance No.';
            ToolTip = 'Specifies the number of the maintenance record that the operation was performed on.';
            TableRelation = "EQM Maintenance Record"."No.";
            ValidateTableRelation = false;
            Editable = false;
        }
        field(3; "Action"; Enum "EQM Maintenance Log Action")
        {
            Caption = 'Action';
            ToolTip = 'Specifies the operation that was performed: Registered, Changed or Posted.';
            Editable = false;
        }
        field(4; "Field No."; Integer)
        {
            Caption = 'Field No.';
            ToolTip = 'Specifies the number of the field that was changed. It is 0 for Registered and Posted entries.';
            Editable = false;
        }
        field(5; "Field Caption"; Text[80])
        {
            Caption = 'Field Caption';
            ToolTip = 'Specifies the name of the field that was changed.';
            FieldClass = FlowField;
            CalcFormula = lookup(Field."Field Caption" where(TableNo = const(50105), "No." = field("Field No.")));
            Editable = false;
        }
        field(6; "Old Value"; Text[250])
        {
            Caption = 'Old Value';
            ToolTip = 'Specifies the value of the field before the change, in XML format.';
            Editable = false;
        }
        field(7; "New Value"; Text[250])
        {
            Caption = 'New Value';
            ToolTip = 'Specifies the value of the field after the change, in XML format.';
            Editable = false;
        }
        field(8; "User ID"; Code[50])
        {
            Caption = 'User ID';
            ToolTip = 'Specifies the user who performed the operation.';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(9; "Logged At"; DateTime)
        {
            Caption = 'Logged At';
            ToolTip = 'Specifies the date and time when the operation was performed.';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(MaintenanceNo; "Maintenance No.")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Entry No.", "Maintenance No.", "Action", "Logged At")
        {
        }
        fieldgroup(Brick; "Maintenance No.", "Action", "Logged At", "User ID")
        {
        }
    }

    var
        InsertAllowed: Boolean;
        InsertNotAllowedErr: Label 'You cannot create maintenance log entries directly. Entries are created when you register, change or post a maintenance record.';
        ModifyNotAllowedErr: Label 'You cannot change maintenance log entry %1. The maintenance log is read-only.', Comment = '%1 = entry number';
        DeleteNotAllowedErr: Label 'You cannot delete maintenance log entry %1. The maintenance log is kept permanently.', Comment = '%1 = entry number';
        RenameNotAllowedErr: Label 'You cannot change the number of maintenance log entry %1.', Comment = '%1 = entry number';

    trigger OnInsert()
    begin
        if not InsertAllowed then
            Error(InsertNotAllowedErr);

        InsertAllowed := false;

        TestField("Maintenance No.");
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

    /// <summary>
    /// Enables the next insert on this record variable. Only the maintenance log codeunit calls it.
    /// </summary>
    internal procedure AllowInsertFromLog()
    begin
        InsertAllowed := true;
    end;
}
