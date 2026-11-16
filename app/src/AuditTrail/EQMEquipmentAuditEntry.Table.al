namespace MiguelCarvalho.EquipmentManagement;

using Microsoft.HumanResources.Employee;

/// <summary>
/// Read-only lifecycle timeline of equipment: created, updated, assigned, returned, sent to maintenance and disposed.
/// Entries are written only by the audit trail codeunit and can never be changed, renamed or deleted. Updated entries
/// do not hold field values; field-level old and new values are in the standard Change Log.
/// </summary>
table 50112 "EQM Equipment Audit Entry"
{
    Caption = 'Equipment Audit Entry';
    DataClassification = CustomerContent;
    Access = Public;
    LookupPageId = "EQM Equipment Audit Trail";
    DrillDownPageId = "EQM Equipment Audit Trail";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            ToolTip = 'Specifies the number of the audit entry.';
            AutoIncrement = true;
            Editable = false;
        }
        field(2; "Equipment No."; Code[20])
        {
            Caption = 'Equipment No.';
            ToolTip = 'Specifies the number of the equipment that the event happened to.';
            TableRelation = "EQM Equipment"."No.";
            ValidateTableRelation = false;
            Editable = false;
        }
        field(3; "Event Type"; Enum "EQM Audit Event Type")
        {
            Caption = 'Event Type';
            ToolTip = 'Specifies what happened to the equipment: Created, Updated, Assigned, Returned, Sent to Maintenance or Disposed. Updated does not show which fields changed; the Change Log shows the old and new values when it is set up.';
            Editable = false;
        }
        field(4; "Status After"; Enum "EQM Equipment Status")
        {
            Caption = 'Status After';
            ToolTip = 'Specifies the status of the equipment after the event.';
            Editable = false;
        }
        field(5; "Employee No."; Code[20])
        {
            Caption = 'Employee No.';
            ToolTip = 'Specifies the employee the equipment was assigned to or returned from. It is blank for other events.';
            TableRelation = Employee."No.";
            ValidateTableRelation = false;
            Editable = false;
        }
        field(6; "Assignment Entry No."; Integer)
        {
            Caption = 'Assignment Entry No.';
            ToolTip = 'Specifies the number of the assignment entry behind an Assigned or Returned event. It is 0 for other events.';
            TableRelation = "EQM Equipment Assignment"."Entry No.";
            ValidateTableRelation = false;
            BlankZero = true;
            Editable = false;
        }
        field(7; "Maintenance No."; Code[20])
        {
            Caption = 'Maintenance No.';
            ToolTip = 'Specifies the maintenance record that sent the equipment to maintenance. It is blank when the status was changed manually and for other events.';
            TableRelation = "EQM Maintenance Record"."No.";
            ValidateTableRelation = false;
            Editable = false;
        }
        field(8; "User ID"; Code[50])
        {
            Caption = 'User ID';
            ToolTip = 'Specifies the user who caused the event.';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(9; "Logged At"; DateTime)
        {
            Caption = 'Logged At';
            ToolTip = 'Specifies the date and time when the event happened.';
            Editable = false;
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
        fieldgroup(DropDown; "Entry No.", "Equipment No.", "Event Type", "Logged At")
        {
        }
        fieldgroup(Brick; "Equipment No.", "Event Type", "Logged At", "User ID")
        {
        }
    }

    var
        InsertAllowed: Boolean;
        InsertNotAllowedErr: Label 'You cannot create equipment audit entries directly. Entries are created when equipment is created, changed, assigned, returned, sent to maintenance or disposed.';
        ModifyNotAllowedErr: Label 'You cannot change equipment audit entry %1. The audit trail is read-only.', Comment = '%1 = entry number';
        DeleteNotAllowedErr: Label 'You cannot delete equipment audit entry %1. The audit trail is kept permanently.', Comment = '%1 = entry number';
        RenameNotAllowedErr: Label 'You cannot change the number of equipment audit entry %1.', Comment = '%1 = entry number';

    trigger OnInsert()
    begin
        if not InsertAllowed then
            Error(InsertNotAllowedErr);

        InsertAllowed := false;

        TestField("Equipment No.");
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
    /// Enables the next insert on this record variable. Only the audit trail codeunit calls it.
    /// </summary>
    internal procedure AllowInsertFromAuditTrail()
    begin
        InsertAllowed := true;
    end;
}
