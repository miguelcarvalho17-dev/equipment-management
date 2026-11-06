namespace MiguelCarvalho.EquipmentManagement;

/// <summary>
/// Read-only maintenance history. One entry is written when a maintenance record is posted. Entries cannot be created
/// except by posting, and they can never be changed, renamed or deleted.
/// </summary>
table 50106 "EQM Maintenance History Entry"
{
    Caption = 'Maintenance History Entry';
    DataClassification = CustomerContent;
    Access = Public;
    LookupPageId = "EQM Maintenance History";
    DrillDownPageId = "EQM Maintenance History";
    DataCaptionFields = "Maintenance No.", Description;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            ToolTip = 'Specifies the number of the maintenance history entry.';
            AutoIncrement = true;
            Editable = false;
        }
        field(2; "Maintenance No."; Code[20])
        {
            Caption = 'Maintenance No.';
            ToolTip = 'Specifies the number of the maintenance record that was posted to create this entry.';
            TableRelation = "EQM Maintenance Record"."No.";
            ValidateTableRelation = false;
            Editable = false;
        }
        field(3; "Equipment No."; Code[20])
        {
            Caption = 'Equipment No.';
            ToolTip = 'Specifies the equipment the maintenance was performed on.';
            TableRelation = "EQM Equipment"."No.";
            ValidateTableRelation = false;
            Editable = false;
        }
        field(4; "Maintenance Date"; Date)
        {
            Caption = 'Maintenance Date';
            ToolTip = 'Specifies the date the maintenance was performed.';
            Editable = false;
        }
        field(5; "Maintenance Type"; Enum "EQM Maintenance Type")
        {
            Caption = 'Maintenance Type';
            ToolTip = 'Specifies the type of maintenance: Preventive, Corrective, Inspection or Upgrade.';
            Editable = false;
        }
        field(6; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            ToolTip = 'Specifies the number of the vendor that performed the maintenance, as it was when the maintenance was posted.';
            Editable = false;
        }
        field(7; "Vendor Name"; Text[100])
        {
            Caption = 'Vendor Name';
            ToolTip = 'Specifies the name of the vendor as it was when the maintenance was posted.';
            Editable = false;
        }
        field(8; Cost; Decimal)
        {
            Caption = 'Cost';
            ToolTip = 'Specifies the cost of the maintenance in local currency.';
            AutoFormatType = 1;
            Editable = false;
        }
        field(9; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description of the maintenance work.';
            Editable = false;
        }
        field(10; "Performed By"; Text[100])
        {
            Caption = 'Performed By';
            ToolTip = 'Specifies the name of the person or team that performed the maintenance.';
            Editable = false;
        }
        field(11; "Posted By"; Code[50])
        {
            Caption = 'Posted By';
            ToolTip = 'Specifies the user who posted the maintenance.';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(12; "Posted At"; DateTime)
        {
            Caption = 'Posted At';
            ToolTip = 'Specifies the date and time when the maintenance was posted.';
            Editable = false;
        }
        field(13; "Equipment Description"; Text[100])
        {
            Caption = 'Equipment Description';
            ToolTip = 'Specifies the description of the equipment.';
            FieldClass = FlowField;
            CalcFormula = lookup("EQM Equipment".Description where("No." = field("Equipment No.")));
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(EquipmentDate; "Equipment No.", "Maintenance Date")
        {
            SumIndexFields = Cost;
        }
        key(MaintenanceNo; "Maintenance No.")
        {
            Unique = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Entry No.", "Equipment No.", "Maintenance Date", "Maintenance Type", Description)
        {
        }
        fieldgroup(Brick; "Equipment No.", "Maintenance Date", "Maintenance Type", Cost)
        {
        }
    }

    var
        InsertFromPostingAllowed: Boolean;
        InsertNotAllowedErr: Label 'You cannot create maintenance history entries directly. Entries are created when you post a maintenance record.';
        ModifyNotAllowedErr: Label 'You cannot change maintenance history entry %1. The maintenance history is read-only.', Comment = '%1 = entry number';
        DeleteNotAllowedErr: Label 'You cannot delete maintenance history entry %1. The maintenance history is kept permanently.', Comment = '%1 = entry number';
        RenameNotAllowedErr: Label 'You cannot change the number of maintenance history entry %1.', Comment = '%1 = entry number';

    trigger OnInsert()
    begin
        if not InsertFromPostingAllowed then
            Error(InsertNotAllowedErr);

        InsertFromPostingAllowed := false;

        TestField("Maintenance No.");
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
    /// Enables the next insert on this record variable. Only the maintenance posting codeunit calls it.
    /// </summary>
    internal procedure AllowInsertFromPosting()
    begin
        InsertFromPostingAllowed := true;
    end;
}
