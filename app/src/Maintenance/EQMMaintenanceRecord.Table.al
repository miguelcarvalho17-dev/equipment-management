namespace MiguelCarvalho.EquipmentManagement;

using Microsoft.Foundation.NoSeries;
using Microsoft.Purchases.Vendor;

/// <summary>
/// One record per maintenance activity performed on equipment. Maintenance cannot be registered for Lost or Disposed
/// equipment. Registering a record sets the equipment status to In Maintenance; while the equipment has open records it
/// cannot be assigned. Open records can be corrected. Posting freezes the record, writes a maintenance history entry
/// and, when no other record is open, sets the equipment back to Available. Records are never deleted, so equipment
/// that has maintenance records cannot be deleted either.
/// </summary>
table 50105 "EQM Maintenance Record"
{
    Caption = 'Maintenance Record';
    DataClassification = CustomerContent;
    Access = Public;
    LookupPageId = "EQM Maintenance Records";
    DrillDownPageId = "EQM Maintenance Records";
    DataCaptionFields = "No.", Description;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            ToolTip = 'Specifies the number of the maintenance record.';

            trigger OnValidate()
            var
                EquipmentSetup: Record "EQM Equipment Setup";
                NoSeries: Codeunit "No. Series";
            begin
                if "No." <> xRec."No." then begin
                    GetSetup(EquipmentSetup);
                    NoSeries.TestManual(EquipmentSetup."Maintenance Nos.");
                    "No. Series" := '';
                end;
            end;
        }
        field(2; "Equipment No."; Code[20])
        {
            Caption = 'Equipment No.';
            ToolTip = 'Specifies the equipment the maintenance is performed on. The equipment must exist and cannot be lost or disposed of. Registering the record sets the equipment status to In Maintenance. You cannot change the equipment after the record is created.';
            TableRelation = "EQM Equipment"."No.";
            NotBlank = true;

            trigger OnValidate()
            begin
                if ("Equipment No." <> xRec."Equipment No.") and IsStoredRecord() then
                    Error(EquipmentCannotChangeErr, "No.", xRec."Equipment No.");

                if "Equipment No." <> '' then
                    CheckEquipmentAllowsMaintenance();
            end;
        }
        field(3; "Maintenance Date"; Date)
        {
            Caption = 'Maintenance Date';
            ToolTip = 'Specifies the date the maintenance was performed. The date cannot be later than today. If you leave it blank, the work date is used.';

            trigger OnValidate()
            begin
                CheckMaintenanceDate();
            end;
        }
        field(4; "Maintenance Type"; Enum "EQM Maintenance Type")
        {
            Caption = 'Maintenance Type';
            ToolTip = 'Specifies the type of maintenance: Preventive, Corrective, Inspection or Upgrade. New records start as Preventive.';
            InitValue = Preventive;
        }
        field(5; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            ToolTip = 'Specifies the vendor that performed the maintenance. Leave it blank when the maintenance was done internally.';
            TableRelation = Vendor."No.";
        }
        field(6; Cost; Decimal)
        {
            Caption = 'Cost';
            ToolTip = 'Specifies the cost of the maintenance in local currency. The cost must be zero or greater.';
            AutoFormatType = 1;
            MinValue = 0;
        }
        field(7; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description of the maintenance work.';
        }
        field(8; "Performed By"; Text[100])
        {
            Caption = 'Performed By';
            ToolTip = 'Specifies the name of the person or team that performed the maintenance.';
        }
        field(9; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            ToolTip = 'Specifies the number series from which the maintenance record number was assigned.';
            TableRelation = "No. Series";
            Editable = false;
        }
        field(10; "Equipment Description"; Text[100])
        {
            Caption = 'Equipment Description';
            ToolTip = 'Specifies the description of the equipment.';
            FieldClass = FlowField;
            CalcFormula = lookup("EQM Equipment".Description where("No." = field("Equipment No.")));
            Editable = false;
        }
        field(11; Status; Enum "EQM Maintenance Status")
        {
            Caption = 'Status';
            ToolTip = 'Specifies whether the maintenance record is open or posted. While a record is open, the equipment is In Maintenance and cannot be assigned. Posting copies the record to the maintenance history, and after that it cannot be changed. When the last open record of the equipment is posted, the equipment becomes Available.';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "No.")
        {
            Clustered = true;
        }
        key(EquipmentDate; "Equipment No.", "Maintenance Date")
        {
            SumIndexFields = Cost;
        }
        key(EquipmentStatus; "Equipment No.", Status)
        {
        }
        key(StatusDate; Status, "Maintenance Date")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", "Equipment No.", "Maintenance Date", "Maintenance Type", Description)
        {
        }
        fieldgroup(Brick; "No.", "Equipment No.", "Maintenance Date", "Maintenance Type")
        {
        }
    }

    var
        MaintenanceCannotBeDeletedErr: Label 'You cannot delete maintenance record %1. Maintenance records are kept as the maintenance history of the equipment.', Comment = '%1 = maintenance record number';
        EquipmentNotFoundErr: Label 'Equipment %1 does not exist. Register the equipment before you register maintenance for it.', Comment = '%1 = equipment number';
        EquipmentFinalStatusErr: Label 'You cannot register maintenance for equipment %1 because its status is %2.', Comment = '%1 = equipment number, %2 = status caption (Lost or Disposed)';
        EquipmentCannotChangeErr: Label 'You cannot change the equipment of maintenance record %1. The record belongs to equipment %2.', Comment = '%1 = maintenance record number, %2 = equipment number';
        FutureDateErr: Label 'The maintenance date %1 is in the future. Enter a date that is not later than today (%2).', Comment = '%1 = maintenance date, %2 = today''s date';
        NegativeCostErr: Label 'The cost of maintenance record %1 must be zero or greater.', Comment = '%1 = maintenance record number';
        RenameNotAllowedErr: Label 'You cannot change the number of maintenance record %1.', Comment = '%1 = maintenance record number';
        PostedRecordCannotBeChangedErr: Label 'You cannot change maintenance record %1 because it is posted. Posted maintenance is part of the maintenance history and is read-only.', Comment = '%1 = maintenance record number';
        InsertPostedErr: Label 'Maintenance record %1 must be registered as open. Register the record first, and then post it.', Comment = '%1 = maintenance record number';
        AmbiguousStyleTok: Label 'Ambiguous', Locked = true;
        FavorableStyleTok: Label 'Favorable', Locked = true;
        StandardStyleTok: Label 'Standard', Locked = true;

    trigger OnInsert()
    var
        EquipmentSetup: Record "EQM Equipment Setup";
        Equipment: Record "EQM Equipment";
        NoSeries: Codeunit "No. Series";
    begin
        if "No." = '' then begin
            GetSetup(EquipmentSetup);
            EquipmentSetup.TestField("Maintenance Nos.");
            "No. Series" := EquipmentSetup."Maintenance Nos.";
            if (xRec."No. Series" <> '') and NoSeries.AreRelated(EquipmentSetup."Maintenance Nos.", xRec."No. Series") then
                "No. Series" := xRec."No. Series";
            "No." := NoSeries.GetNextNo("No. Series");
        end;
        if "Maintenance Date" = 0D then
            "Maintenance Date" := WorkDate();
        if Status <> Status::Open then
            Error(InsertPostedErr, "No.");
        CheckMaintenanceConsistency(true);

        Equipment.ReadIsolation := IsolationLevel::UpdLock;
        if Equipment.Get("Equipment No.") then
            Equipment.StartMaintenance(Rec);
    end;

    trigger OnModify()
    begin
        CheckNotPosted();
        CheckMaintenanceConsistency(false);
    end;

    trigger OnDelete()
    begin
        Error(MaintenanceCannotBeDeletedErr, "No.");
    end;

    trigger OnRename()
    begin
        Error(RenameNotAllowedErr, xRec."No.");
    end;

    /// <summary>
    /// Lets the user pick a number series for a new maintenance record and takes the next number from it.
    /// Does nothing when "No." is already filled in.
    /// </summary>
    /// <returns>True if a number was assigned to "No."; false if "No." was already filled in or the user cancelled the lookup.</returns>
    internal procedure AssistEdit(): Boolean
    var
        EquipmentSetup: Record "EQM Equipment Setup";
        NoSeries: Codeunit "No. Series";
    begin
        if "No." <> '' then
            exit(false);

        GetSetup(EquipmentSetup);
        EquipmentSetup.TestField("Maintenance Nos.");
        if NoSeries.LookupRelatedNoSeries(EquipmentSetup."Maintenance Nos.", xRec."No. Series", "No. Series") then begin
            "No." := NoSeries.GetNextNo("No. Series");
            exit(true);
        end;
        exit(false);
    end;

    /// <summary>
    /// Validates the record before it is inserted or modified: equipment filled in and existing, equipment
    /// not Lost or Disposed when a new record is registered, equipment not changed on a saved record, maintenance date
    /// filled in and not later than today, cost zero or greater. Raises OnAfterCheckMaintenanceConsistency at the end.
    /// </summary>
    /// <param name="IsNewRecord">True on insert. The Lost / Disposed check runs only for new records; the unchanged-equipment check runs only on modify.</param>
    internal procedure CheckMaintenanceConsistency(IsNewRecord: Boolean)
    var
        Equipment: Record "EQM Equipment";
        StoredRecord: Record "EQM Maintenance Record";
    begin
        TestField("Equipment No.");

        Equipment.SetLoadFields("No.");
        if not Equipment.Get("Equipment No.") then
            Error(EquipmentNotFoundErr, "Equipment No.");

        if IsNewRecord then
            CheckEquipmentAllowsMaintenance()
        else begin
            StoredRecord.SetLoadFields("Equipment No.");
            if StoredRecord.Get("No.") then
                if StoredRecord."Equipment No." <> "Equipment No." then
                    Error(EquipmentCannotChangeErr, "No.", StoredRecord."Equipment No.");
        end;

        TestField("Maintenance Date");
        CheckMaintenanceDate();

        if Cost < 0 then
            Error(NegativeCostErr, "No.");

        OnAfterCheckMaintenanceConsistency(Rec);
    end;

    /// <summary>
    /// Returns the style name used to show the status on pages.
    /// </summary>
    /// <returns>The style name for the current status.</returns>
    internal procedure GetStatusStyle(): Text
    begin
        case Status of
            Status::Open:
                exit(AmbiguousStyleTok);
            Status::Posted:
                exit(FavorableStyleTok);
            else
                exit(StandardStyleTok);
        end;
    end;

    local procedure CheckNotPosted()
    var
        StoredRecord: Record "EQM Maintenance Record";
    begin
        StoredRecord.SetLoadFields(Status);
        if StoredRecord.Get("No.") then
            if StoredRecord.Status = StoredRecord.Status::Posted then
                Error(PostedRecordCannotBeChangedErr, "No.");
    end;

    local procedure CheckEquipmentAllowsMaintenance()
    var
        Equipment: Record "EQM Equipment";
    begin
        Equipment.SetLoadFields(Status);
        if Equipment.Get("Equipment No.") then
            if Equipment.IsFinalStatus(Equipment.Status) then
                Error(EquipmentFinalStatusErr, "Equipment No.", Format(Equipment.Status));
    end;

    local procedure CheckMaintenanceDate()
    begin
        if "Maintenance Date" > Today() then
            Error(FutureDateErr, "Maintenance Date", Today());
    end;

    /// <summary>
    /// True when this maintenance record already exists in the database (used to detect new records).
    /// </summary>
    local procedure IsStoredRecord(): Boolean
    var
        StoredRecord: Record "EQM Maintenance Record";
    begin
        if "No." = '' then
            exit(false);

        StoredRecord.SetLoadFields("No.");
        exit(StoredRecord.Get("No."));
    end;

    local procedure GetSetup(var EquipmentSetup: Record "EQM Equipment Setup")
    begin
        if not EquipmentSetup.Get() then
            Clear(EquipmentSetup);
    end;

    /// <summary>
    /// Raised at the end of the consistency check on insert and modify, after all standard checks passed.
    /// </summary>
    /// <param name="MaintenanceRecord">The record being saved (passed by value; changes are not kept). Raise an error to reject the save.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckMaintenanceConsistency(MaintenanceRecord: Record "EQM Maintenance Record")
    begin
    end;
}
