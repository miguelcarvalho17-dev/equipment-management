namespace MiguelCarvalho.EquipmentManagement;

/// <summary>
/// Outbox for external systems. One entry is written for each business event, in the same transaction as the
/// operation that raised it. Entries can only be created and marked as processed by the integration codeunit, and
/// only processed entries can be deleted.
/// </summary>
table 50110 "EQM Integration Event Entry"
{
    Caption = 'Integration Event Entry';
    DataClassification = CustomerContent;
    Access = Public;
    LookupPageId = "EQM Integration Event Entries";
    DrillDownPageId = "EQM Integration Event Entries";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            ToolTip = 'Specifies the number of the integration event entry.';
            AutoIncrement = true;
            Editable = false;
        }
        field(2; "Event Type"; Enum "EQM Integration Event Type")
        {
            Caption = 'Event Type';
            ToolTip = 'Specifies the business event that the entry records.';
            Editable = false;
        }
        field(3; "Equipment No."; Code[20])
        {
            Caption = 'Equipment No.';
            ToolTip = 'Specifies the number of the equipment that the event is about.';
            TableRelation = "EQM Equipment"."No.";
            ValidateTableRelation = false;
            Editable = false;
        }
        field(4; "Equipment Status"; Enum "EQM Equipment Status")
        {
            Caption = 'Equipment Status';
            ToolTip = 'Specifies the status of the equipment when the event happened.';
            Editable = false;
        }
        field(5; "Assignment Entry No."; Integer)
        {
            Caption = 'Assignment Entry No.';
            ToolTip = 'Specifies the number of the assignment entry that the event is about. It is 0 for events that are not about an assignment.';
            TableRelation = "EQM Equipment Assignment"."Entry No.";
            ValidateTableRelation = false;
            Editable = false;
        }
        field(6; "Maintenance No."; Code[20])
        {
            Caption = 'Maintenance No.';
            ToolTip = 'Specifies the number of the maintenance record that was created. It is blank for other events.';
            TableRelation = "EQM Maintenance Record"."No.";
            ValidateTableRelation = false;
            Editable = false;
        }
        field(7; Processed; Boolean)
        {
            Caption = 'Processed';
            ToolTip = 'Specifies that the external system has processed the entry.';
            Editable = false;
        }
        field(8; "Processed At"; DateTime)
        {
            Caption = 'Processed At';
            ToolTip = 'Specifies when the entry was marked as processed.';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(Processed; Processed, "Entry No.")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Entry No.", "Event Type", "Equipment No.", Processed)
        {
        }
        fieldgroup(Brick; "Event Type", "Equipment No.", Processed)
        {
        }
    }

    var
        InsertAllowed: Boolean;
        ModifyAllowed: Boolean;
        InsertNotAllowedErr: Label 'You cannot create integration event entries directly. Entries are created when equipment is created, assigned or returned, when maintenance is registered, or when a warranty expires.';
        ModifyNotAllowedErr: Label 'You cannot change integration event entry %1. Entries can only be marked as processed.', Comment = '%1 = entry number';
        DeleteNotAllowedErr: Label 'You cannot delete integration event entry %1 because it has not been processed yet.', Comment = '%1 = entry number';
        RenameNotAllowedErr: Label 'You cannot change the number of integration event entry %1.', Comment = '%1 = entry number';

    trigger OnInsert()
    begin
        if not InsertAllowed then
            Error(InsertNotAllowedErr);

        InsertAllowed := false;
    end;

    trigger OnModify()
    begin
        if not ModifyAllowed then
            Error(ModifyNotAllowedErr, "Entry No.");

        ModifyAllowed := false;
    end;

    trigger OnDelete()
    begin
        if not Processed then
            Error(DeleteNotAllowedErr, "Entry No.");
    end;

    trigger OnRename()
    begin
        Error(RenameNotAllowedErr, xRec."Entry No.");
    end;

    /// <summary>
    /// Enables the next insert on this record variable. Only the integration codeunit calls it.
    /// </summary>
    internal procedure AllowInsertFromMgt()
    begin
        InsertAllowed := true;
    end;

    /// <summary>
    /// Enables the next modify on this record variable. Only the integration codeunit calls it.
    /// </summary>
    internal procedure AllowModifyFromMgt()
    begin
        ModifyAllowed := true;
    end;
}
