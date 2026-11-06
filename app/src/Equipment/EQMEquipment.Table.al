namespace MiguelCarvalho.EquipmentManagement;

using Microsoft.Foundation.NoSeries;
using Microsoft.HumanResources.Employee;
using Microsoft.Inventory.Location;
using System.Utilities;

table 50100 "EQM Equipment"
{
    Caption = 'Equipment';
    DataClassification = CustomerContent;
    Access = Public;
    LookupPageId = "EQM Equipment List";
    DrillDownPageId = "EQM Equipment List";
    DataCaptionFields = "No.", Description;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            ToolTip = 'Specifies the number of the equipment.';

            trigger OnValidate()
            var
                EquipmentSetup: Record "EQM Equipment Setup";
                NoSeries: Codeunit "No. Series";
            begin
                if "No." <> xRec."No." then begin
                    GetSetup(EquipmentSetup);
                    NoSeries.TestManual(EquipmentSetup."Equipment Nos.");
                    "No. Series" := '';
                end;
            end;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description of the equipment.';
        }
        field(3; "Category Code"; Code[20])
        {
            Caption = 'Category Code';
            ToolTip = 'Specifies the category of the equipment. Only active categories can be selected.';
            TableRelation = "EQM Equipment Category" where(Active = const(true));
            ValidateTableRelation = false;
            NotBlank = true;

            trigger OnValidate()
            begin
                CheckCategoryAllowed("Category Code" <> xRec."Category Code");
            end;
        }
        field(4; "Serial No."; Code[50])
        {
            Caption = 'Serial No.';
            ToolTip = 'Specifies the serial number of the equipment. A serial number can be used by one equipment record only.';

            trigger OnValidate()
            begin
                CheckSerialNoIsUnique();
            end;
        }
        field(5; Manufacturer; Text[100])
        {
            Caption = 'Manufacturer';
            ToolTip = 'Specifies the manufacturer of the equipment.';
        }
        field(6; Model; Text[100])
        {
            Caption = 'Model';
            ToolTip = 'Specifies the model of the equipment.';
        }
        field(7; "Purchase Date"; Date)
        {
            Caption = 'Purchase Date';
            ToolTip = 'Specifies the date the equipment was purchased.';
        }
        field(8; "Purchase Cost"; Decimal)
        {
            Caption = 'Purchase Cost';
            ToolTip = 'Specifies the purchase cost of the equipment.';
            AutoFormatType = 1;
            MinValue = 0;
        }
        field(9; Status; Enum "EQM Equipment Status")
        {
            Caption = 'Status';
            ToolTip = 'Specifies the lifecycle status of the equipment: Available, Assigned, In Maintenance, Lost or Disposed. Only saved, available equipment without open maintenance can be assigned; use the Assign to Employee action. Assigned equipment becomes available only through the Return action. Registering maintenance sets the status to In Maintenance, and posting the last open maintenance record sets it back to Available. Lost and Disposed are final statuses: the equipment cannot be assigned or change status again. New equipment cannot start as Assigned, Lost or Disposed.';
            InitValue = Available;

            trigger OnValidate()
            var
                ConfirmManagement: Codeunit "Confirm Management";
                ConfirmQuestion: Text;
                IsNew: Boolean;
            begin
                IsNew := not IsStoredRecord();

                if IsFinalStatus(Status) and IsNew then
                    Error(NewEquipmentFinalStatusErr, Format(Status));

                if (Status = Status::Assigned) and IsNew then
                    Error(NewEquipmentAssignedErr, Format(Status));

                if (xRec.Status = Status::Assigned) and (Status = Status::Available) and not ReturnInProgress then
                    Error(UseReturnActionErr, "No.");

                if Status <> xRec.Status then
                    CheckStatusTransitionAllowed(xRec.Status, Status);

                if IsFinalStatus(Status) and (Status <> xRec.Status) then begin
                    if "Assigned Employee No." <> '' then
                        ConfirmQuestion := StrSubstNo(FinalStatusAssignedQst, "No.", "Assigned Employee No.", Format(Status))
                    else
                        ConfirmQuestion := StrSubstNo(FinalStatusQst, "No.", Format(Status));
                    if not ConfirmManagement.GetResponseOrDefault(ConfirmQuestion, true) then
                        Error('');
                    "Assigned Employee No." := '';
                    exit;
                end;

                if (Status <> Status::Assigned) and ("Assigned Employee No." <> '') then begin
                    if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(StatusChangeRemovesEmployeeQst, "Assigned Employee No.", "No."), true) then
                        Error('');
                    "Assigned Employee No." := '';
                end;
            end;
        }
        field(10; "Assigned Employee No."; Code[20])
        {
            Caption = 'Assigned Employee No.';
            ToolTip = 'Specifies the employee the equipment is assigned to. To assign available equipment, use the Assign to Employee action. To change the employee, return the equipment first.';
            TableRelation = Employee."No.";

            trigger OnValidate()
            begin
                CheckAssignedEmployeeAllowed(true);
            end;
        }
        field(11; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            ToolTip = 'Specifies the location where the equipment is kept.';
            TableRelation = Location.Code;
        }
        field(12; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            ToolTip = 'Specifies the number series from which the equipment number was assigned.';
            TableRelation = "No. Series";
            Editable = false;
        }
    }

    keys
    {
        key(PK; "No.")
        {
            Clustered = true;
        }
        key(SerialNo; "Serial No.")
        {
        }
        key(CategoryCode; "Category Code")
        {
        }
        key(AssignedEmployee; "Assigned Employee No.", Status)
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", Description, "Category Code", Status)
        {
        }
        fieldgroup(Brick; "No.", Description, Status)
        {
        }
    }

    var
        ReturnInProgress: Boolean;
        SerialNoAlreadyUsedErr: Label 'Serial No. %1 is already used by equipment %2.', Comment = '%1 = serial number, %2 = equipment number';
        EmployeeOnlyWhenAssignedErr: Label 'You can only fill in %1 when the status is %2.', Comment = '%1 = Assigned Employee No. field caption, %2 = Assigned status caption';
        AssignedEmployeeRequiredErr: Label 'You must fill in %1 for equipment %2 because its status is %3. On the equipment card, use the Assign to Employee action.', Comment = '%1 = field caption, %2 = equipment number, %3 = status caption';
        EmployeeNotFoundErr: Label 'Employee %1 assigned to equipment %2 no longer exists. Use the Return action, then assign another employee.', Comment = '%1 = employee number, %2 = equipment number';
        EmployeeNotActiveErr: Label 'You cannot assign equipment to employee %1 because the employee status is %2.', Comment = '%1 = employee number, %2 = employee status';
        EmployeePrivacyBlockedErr: Label 'You cannot assign equipment to employee %1 because the employee is blocked for privacy reasons.', Comment = '%1 = employee number';
        StatusChangeRemovesEmployeeQst: Label 'Changing the status removes the assigned employee %1 from equipment %2. Do you want to continue?', Comment = '%1 = employee number, %2 = equipment number';
        CategoryNotFoundErr: Label 'Equipment category %1 does not exist. Choose a category from the Equipment Categories page.', Comment = '%1 = category code';
        CategoryInactiveErr: Label 'You cannot select equipment category %1 because it is not active. Choose an active category, or ask an administrator to activate it.', Comment = '%1 = category code';
        CannotAssignFinalStatusErr: Label 'You cannot assign equipment %1 because its status is %2.', Comment = '%1 = equipment number, %2 = status caption';
        StatusIsFinalErr: Label 'You cannot change the status of equipment %1 to %3 because %2 is a final status.', Comment = '%1 = equipment number, %2 = current status caption, %3 = new status caption';
        NewEquipmentFinalStatusErr: Label 'You cannot create equipment with the status %1. Create the equipment first, and then change its status.', Comment = '%1 = status caption';
        FinalStatusQst: Label 'The status %2 is final. After you change equipment %1 to %2, you cannot change its status again. Do you want to continue?', Comment = '%1 = equipment number, %2 = status caption';
        FinalStatusAssignedQst: Label 'Equipment %1 is assigned to employee %2. Changing the status to %3 removes the employee, and you cannot change the status again. Do you want to continue?', Comment = '%1 = equipment number, %2 = employee number, %3 = status caption';
        FavorableStyleTok: Label 'Favorable', Locked = true;
        StandardStyleTok: Label 'Standard', Locked = true;
        AmbiguousStyleTok: Label 'Ambiguous', Locked = true;
        UnfavorableStyleTok: Label 'Unfavorable', Locked = true;
        SubordinateStyleTok: Label 'Subordinate', Locked = true;
        NotAvailableForAssignmentErr: Label 'You cannot assign equipment %1 because its status is %2. Only equipment with the status %3 can be assigned.', Comment = '%1 = equipment number, %2 = current status caption, %3 = Available status caption';
        AlreadyAssignedErr: Label 'Equipment %1 is already assigned to employee %2. Return the equipment first, and then assign it again.', Comment = '%1 = equipment number, %2 = employee number';
        NewEquipmentAssignedErr: Label 'You cannot create equipment with the status %1. Create the equipment first, and then use the Assign to Employee action.', Comment = '%1 = status caption';
        DeleteAssignedErr: Label 'You cannot delete equipment %1 because it is assigned to employee %2. Return the equipment first.', Comment = '%1 = equipment number, %2 = employee number';
        DeleteHistoryExistsErr: Label 'You cannot delete equipment %1 because it has assignment history. To stop using the equipment, set its status to %2 instead.', Comment = '%1 = equipment number, %2 = Disposed status caption';
        DeleteMaintenanceExistsErr: Label 'You cannot delete equipment %1 because it has maintenance records. To stop using the equipment, set its status to %2 instead.', Comment = '%1 = equipment number, %2 = Disposed status caption';
        NotAssignedErr: Label 'You cannot return equipment %1 because it is not assigned. Its status is %2.', Comment = '%1 = equipment number, %2 = status caption';
        ReturnEquipmentQst: Label 'Do you want to return equipment %1 from employee %2? The status changes to %3 and the assignment is closed.', Comment = '%1 = equipment number, %2 = employee number, %3 = Available status caption';
        UseReturnActionErr: Label 'To make assigned equipment %1 available, use the Return action on the equipment card or the Return Equipment action on the employee card.', Comment = '%1 = equipment number';
        MaintenanceOpenAssignErr: Label 'You cannot assign equipment %1 because it has open maintenance. Post the open maintenance records of the equipment first.', Comment = '%1 = equipment number';
        MaintenanceOpenStatusErr: Label 'You cannot change the status of equipment %1 to %2 because it has open maintenance. The status changes to %3 automatically when the last open maintenance record is posted.', Comment = '%1 = equipment number, %2 = new status caption, %3 = Available status caption';
        StartMaintenanceAssignedQst: Label 'Equipment %1 is assigned to employee %2. Registering maintenance returns the equipment from the employee and changes its status to %3. Do you want to continue?', Comment = '%1 = equipment number, %2 = employee number, %3 = In Maintenance status caption';

    trigger OnInsert()
    var
        EquipmentSetup: Record "EQM Equipment Setup";
        NoSeries: Codeunit "No. Series";
    begin
        if "No." = '' then begin
            GetSetup(EquipmentSetup);
            EquipmentSetup.TestField("Equipment Nos.");
            "No. Series" := EquipmentSetup."Equipment Nos.";
            if (xRec."No. Series" <> '') and NoSeries.AreRelated(EquipmentSetup."Equipment Nos.", xRec."No. Series") then
                "No. Series" := xRec."No. Series";
            "No." := NoSeries.GetNextNo("No. Series");
        end;
        CheckEquipmentConsistency(true);
    end;

    trigger OnModify()
    var
        AssignmentMgt: Codeunit "EQM Assignment Mgt.";
    begin
        CheckEquipmentConsistency(false);
        AssignmentMgt.UpdateAssignmentOnSave(Rec);
    end;

    trigger OnDelete()
    var
        AssignmentMgt: Codeunit "EQM Assignment Mgt.";
        MaintenanceMgt: Codeunit "EQM Maintenance Mgt.";
    begin
        if Status = Status::Assigned then
            Error(DeleteAssignedErr, "No.", "Assigned Employee No.");
        if AssignmentMgt.HasAssignmentHistory("No.") then
            Error(DeleteHistoryExistsErr, "No.", Format(Status::Disposed));
        if MaintenanceMgt.HasMaintenanceRecords("No.") then
            Error(DeleteMaintenanceExistsErr, "No.", Format(Status::Disposed));
    end;

    /// <summary>
    /// Lets the user pick a number series for a new equipment record and takes the next number from it.
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
        EquipmentSetup.TestField("Equipment Nos.");
        if NoSeries.LookupRelatedNoSeries(EquipmentSetup."Equipment Nos.", xRec."No. Series", "No. Series") then begin
            "No." := NoSeries.GetNextNo("No. Series");
            exit(true);
        end;
        exit(false);
    end;

    /// <summary>
    /// Sets the status to Assigned, assigns the employee and saves the record with triggers.
    /// Only saved, Available equipment can be assigned. An active assignment entry with the work date and the current user
    /// is created. Raises an error when the equipment is already assigned, or when the status is not Available (Lost and
    /// Disposed always; other statuses unless an extension allows the transition). Raises an error when the equipment has
    /// open maintenance.
    /// </summary>
    /// <param name="EmployeeNo">The employee to assign. Must exist, be Active and not be privacy blocked; otherwise an error is raised.</param>
    internal procedure AssignEmployee(EmployeeNo: Code[20])
    begin
        if IsFinalStatus(Status) then
            Error(CannotAssignFinalStatusErr, "No.", Format(Status));
        if Status = Status::Assigned then
            Error(AlreadyAssignedErr, "No.", "Assigned Employee No.");

        Validate(Status, Status::Assigned);
        Validate("Assigned Employee No.", EmployeeNo);
        Modify(true);
    end;

    /// <summary>
    /// Returns assigned equipment: removes the assigned employee, sets the status to Available, saves the record with
    /// triggers and closes the active assignment entry. The entry is kept as history. The user is asked to confirm first;
    /// without a UI session the answer defaults to Yes. This is the only way to change Assigned equipment to Available.
    /// Raises an error when the equipment is not Assigned.
    /// </summary>
    /// <returns>True when the equipment was returned; false when the user cancelled.</returns>
    internal procedure UnassignEmployee(): Boolean
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if Status <> Status::Assigned then
            Error(NotAssignedErr, "No.", Format(Status));

        if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(ReturnEquipmentQst, "No.", "Assigned Employee No.", Format(Status::Available)), true) then
            exit(false);

        "Assigned Employee No." := '';
        ReturnInProgress := true;
        Validate(Status, Status::Available);
        ReturnInProgress := false;
        Modify(true);
        exit(true);
    end;

    /// <summary>
    /// Sets the status to In Maintenance and saves the record with triggers. Called when a maintenance record is
    /// registered. Does nothing when the status is already In Maintenance, Lost or Disposed. For assigned equipment the user
    /// is asked to confirm (Yes without a UI session); the equipment is then returned from the employee and the assignment
    /// is closed. Raises an empty error when the user answers No.
    /// </summary>
    /// <param name="MaintenanceRecord">The maintenance record being registered (passed by value). Used for the event.</param>
    internal procedure StartMaintenance(MaintenanceRecord: Record "EQM Maintenance Record")
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if Status = Status::"In Maintenance" then
            exit;
        if IsFinalStatus(Status) then
            exit;

        if Status = Status::Assigned then begin
            if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(StartMaintenanceAssignedQst, "No.", "Assigned Employee No.", Format(Status::"In Maintenance")), true) then
                Error('');
            "Assigned Employee No." := '';
        end;

        Status := Status::"In Maintenance";
        OnBeforeStartMaintenance(Rec, MaintenanceRecord);
        Modify(true);
    end;

    /// <summary>
    /// Sets the status from In Maintenance back to Available and saves the record with triggers, when the
    /// equipment has no open maintenance record left. Called after a maintenance record is posted. Does nothing when the
    /// status is not In Maintenance or when other maintenance is still open.
    /// </summary>
    /// <param name="MaintenanceRecord">The posted maintenance record (passed by value). Used for the event.</param>
    internal procedure CompleteMaintenance(MaintenanceRecord: Record "EQM Maintenance Record")
    var
        MaintenanceMgt: Codeunit "EQM Maintenance Mgt.";
        IsHandled: Boolean;
    begin
        if Status <> Status::"In Maintenance" then
            exit;
        if MaintenanceMgt.HasOpenMaintenance("No.") then
            exit;

        OnBeforeCompleteMaintenance(Rec, MaintenanceRecord, IsHandled);
        if IsHandled then
            exit;

        Validate(Status, Status::Available);
        Modify(true);
    end;

    /// <summary>
    /// Validates the record before it is inserted or modified: category filled in, category exists and is active
    /// (active only when the category is new or changed), new equipment not in a final status (Lost or Disposed),
    /// new equipment cannot be Assigned, status transition allowed on modify, the employee of assigned equipment
    /// cannot be changed (return first), serial number unique, assigned employee allowed only when the status
    /// is Assigned, and employee present when the status is Assigned.
    /// Raises OnAfterCheckEquipmentConsistency at the end.
    /// </summary>
    /// <param name="IsNewRecord">True on insert. On modify (false), the Active / not privacy blocked check on the employee runs only if the assigned employee differs from the stored record.</param>
    internal procedure CheckEquipmentConsistency(IsNewRecord: Boolean)
    var
        StoredEquipment: Record "EQM Equipment";
        CategoryChanged: Boolean;
        EmployeeChanged: Boolean;
        IsReassignment: Boolean;
        StatusChanged: Boolean;
        StoredEmployeeNo: Code[20];
        StoredStatus: Enum "EQM Equipment Status";
    begin
        TestField("Category Code");

        CategoryChanged := true;
        EmployeeChanged := true;
        if not IsNewRecord then begin
            StoredEquipment.SetLoadFields("Assigned Employee No.", "Category Code", Status);
            if StoredEquipment.Get("No.") then begin
                CategoryChanged := StoredEquipment."Category Code" <> "Category Code";
                EmployeeChanged := StoredEquipment."Assigned Employee No." <> "Assigned Employee No.";
                StatusChanged := StoredEquipment.Status <> Status;
                StoredStatus := StoredEquipment.Status;
                StoredEmployeeNo := StoredEquipment."Assigned Employee No.";
                IsReassignment := (StoredEquipment.Status = Status::Assigned) and (Status = Status::Assigned) and
                    (StoredEmployeeNo <> '') and ("Assigned Employee No." <> '') and (StoredEmployeeNo <> "Assigned Employee No.");
            end;
        end;
        CheckCategoryAllowed(CategoryChanged);

        if IsNewRecord and IsFinalStatus(Status) then
            Error(NewEquipmentFinalStatusErr, Format(Status));
        if IsNewRecord and (Status = Status::Assigned) then
            Error(NewEquipmentAssignedErr, Format(Status));
        if StatusChanged then
            CheckStatusTransitionAllowed(StoredStatus, Status);
        if IsReassignment then
            Error(AlreadyAssignedErr, "No.", StoredEmployeeNo);

        CheckSerialNoIsUnique();
        CheckAssignedEmployeeAllowed(EmployeeChanged);

        if (Status = Status::Assigned) and ("Assigned Employee No." = '') then
            Error(AssignedEmployeeRequiredErr, FieldCaption("Assigned Employee No."), "No.", Format(Status));

        OnAfterCheckEquipmentConsistency(Rec);
    end;

    local procedure CheckCategoryAllowed(CheckIsActive: Boolean)
    var
        Category: Record "EQM Equipment Category";
        IsHandled: Boolean;
    begin
        if "Category Code" = '' then
            exit;

        Category.SetLoadFields(Active);
        if not Category.Get("Category Code") then
            Error(CategoryNotFoundErr, "Category Code");

        if not CheckIsActive then
            exit;

        OnBeforeCheckCategoryIsActive(Rec, IsHandled);
        if IsHandled then
            exit;

        if not Category.Active then
            Error(CategoryInactiveErr, "Category Code");
    end;

    local procedure CheckSerialNoIsUnique()
    var
        OtherEquipment: Record "EQM Equipment";
        IsHandled: Boolean;
    begin
        OnBeforeCheckSerialNoIsUnique(Rec, IsHandled);
        if IsHandled then
            exit;

        if "Serial No." = '' then
            exit;

        OtherEquipment.SetLoadFields("No.");
        OtherEquipment.SetCurrentKey("Serial No.");
        OtherEquipment.SetRange("Serial No.", "Serial No.");
        OtherEquipment.SetFilter("No.", '<>%1', "No.");
        if OtherEquipment.FindFirst() then
            Error(SerialNoAlreadyUsedErr, "Serial No.", OtherEquipment."No.");
    end;

    local procedure CheckAssignedEmployeeAllowed(CheckEmployeeIsActive: Boolean)
    var
        Employee: Record Employee;
        IsHandled: Boolean;
    begin
        if "Assigned Employee No." = '' then
            exit;

        if Status <> Status::Assigned then
            Error(EmployeeOnlyWhenAssignedErr, FieldCaption("Assigned Employee No."), Format(Status::Assigned));

        Employee.SetLoadFields(Status, "Privacy Blocked");
        if not Employee.Get("Assigned Employee No.") then
            Error(EmployeeNotFoundErr, "Assigned Employee No.", "No.");

        if not CheckEmployeeIsActive then
            exit;

        OnBeforeCheckEmployeeIsEligible(Rec, IsHandled);
        if IsHandled then
            exit;

        if Employee."Privacy Blocked" then
            Error(EmployeePrivacyBlockedErr, "Assigned Employee No.");
        if Employee.Status <> Employee.Status::Active then
            Error(EmployeeNotActiveErr, "Assigned Employee No.", Format(Employee.Status));
    end;

    local procedure CheckStatusTransitionAllowed(FromStatus: Enum "EQM Equipment Status"; ToStatus: Enum "EQM Equipment Status")
    var
        MaintenanceMgt: Codeunit "EQM Maintenance Mgt.";
        IsHandled: Boolean;
    begin
        if FromStatus = ToStatus then
            exit;

        if (ToStatus = ToStatus::Assigned) and IsFinalStatus(FromStatus) then
            Error(CannotAssignFinalStatusErr, "No.", Format(FromStatus));

        if (ToStatus = ToStatus::Assigned) and MaintenanceMgt.HasOpenMaintenance("No.") then
            Error(MaintenanceOpenAssignErr, "No.");

        if (FromStatus = FromStatus::"In Maintenance") and not IsFinalStatus(ToStatus) and MaintenanceMgt.HasOpenMaintenance("No.") then
            Error(MaintenanceOpenStatusErr, "No.", Format(ToStatus), Format(Status::Available));

        OnBeforeCheckStatusTransitionAllowed(Rec, FromStatus, ToStatus, IsHandled);
        if IsHandled then
            exit;

        if IsFinalStatus(FromStatus) then
            Error(StatusIsFinalErr, "No.", Format(FromStatus), Format(ToStatus));

        if (ToStatus = ToStatus::Assigned) and (FromStatus <> FromStatus::Available) then
            Error(NotAvailableForAssignmentErr, "No.", Format(FromStatus), Format(Status::Available));
    end;

    /// <summary>
    /// True when this equipment already exists in the database (used to detect new records).
    /// </summary>
    local procedure IsStoredRecord(): Boolean
    var
        StoredEquipment: Record "EQM Equipment";
    begin
        if "No." = '' then
            exit(false);

        StoredEquipment.SetLoadFields("No.");
        exit(StoredEquipment.Get("No."));
    end;

    /// <summary>
    /// Returns whether the status is final. Lost and Disposed are final statuses.
    /// </summary>
    /// <param name="EquipmentStatus">The status to check.</param>
    /// <returns>True when the status is Lost or Disposed.</returns>
    internal procedure IsFinalStatus(EquipmentStatus: Enum "EQM Equipment Status"): Boolean
    begin
        exit(EquipmentStatus in [EquipmentStatus::Lost, EquipmentStatus::Disposed]);
    end;

    /// <summary>
    /// Returns the page style name used to show the status of this record.
    /// </summary>
    /// <returns>The style name. Statuses added by extensions use the Standard style.</returns>
    internal procedure GetStatusStyle(): Text
    begin
        case Status of
            Status::Available:
                exit(FavorableStyleTok);
            Status::Assigned:
                exit(StandardStyleTok);
            Status::"In Maintenance":
                exit(AmbiguousStyleTok);
            Status::Lost:
                exit(UnfavorableStyleTok);
            Status::Disposed:
                exit(SubordinateStyleTok);
            else
                exit(StandardStyleTok);
        end;
    end;

    local procedure GetSetup(var EquipmentSetup: Record "EQM Equipment Setup")
    begin
        if not EquipmentSetup.Get() then
            Clear(EquipmentSetup);
    end;

    /// <summary>
    /// Raised before the check that a new or changed category is active.
    /// </summary>
    /// <param name="Equipment">The record being checked (passed by value; changes are not kept).</param>
    /// <param name="IsHandled">Set to true to allow an inactive category. The category must still exist.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckCategoryIsActive(Equipment: Record "EQM Equipment"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before the serial number uniqueness check, on field validation and on insert/modify.
    /// </summary>
    /// <param name="Equipment">The record being checked (passed by value; changes are not kept).</param>
    /// <param name="IsHandled">Set to true to skip the standard uniqueness check.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSerialNoIsUnique(Equipment: Record "EQM Equipment"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before the checks that the assigned employee is Active and not blocked for privacy reasons.
    /// </summary>
    /// <param name="Equipment">The record being checked (passed by value; changes are not kept).</param>
    /// <param name="IsHandled">Set to true to allow an employee that is not Active or is privacy blocked. The employee must still exist, and an employee is only allowed when the status is Assigned.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckEmployeeIsEligible(Equipment: Record "EQM Equipment"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before the standard status transition rules run, when the status changes.
    /// </summary>
    /// <param name="Equipment">The record being checked (passed by value; changes are not kept).</param>
    /// <param name="FromStatus">The current status (the previous value on validate, the stored value on modify).</param>
    /// <param name="ToStatus">The new status.</param>
    /// <param name="IsHandled">Set to true to skip the standard transition rules: Lost and Disposed being final, and only Available equipment being assignable. Lost and disposed equipment still cannot be assigned. Equipment with open maintenance still cannot be assigned, and its status cannot leave In Maintenance except to Lost or Disposed.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckStatusTransitionAllowed(Equipment: Record "EQM Equipment"; FromStatus: Enum "EQM Equipment Status"; ToStatus: Enum "EQM Equipment Status"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised at the end of the consistency check on insert and modify, after all standard checks passed.
    /// </summary>
    /// <param name="Equipment">The record being saved (passed by value; changes are not kept). Raise an error to reject the save.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckEquipmentConsistency(Equipment: Record "EQM Equipment")
    begin
    end;

    /// <summary>
    /// Raised when registering maintenance changes the equipment status to In Maintenance, after the status and the
    /// employee are set and before the record is saved.
    /// </summary>
    /// <param name="Equipment">The equipment, with Status = In Maintenance and the employee removed. You can set fields that your extension added; do not change the standard fields. Raise an error to stop the registration.</param>
    /// <param name="MaintenanceRecord">The maintenance record being registered (passed by value).</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeStartMaintenance(var Equipment: Record "EQM Equipment"; MaintenanceRecord: Record "EQM Maintenance Record")
    begin
    end;

    /// <summary>
    /// Raised when the last open maintenance record of equipment in maintenance is posted, before the status changes to
    /// Available.
    /// </summary>
    /// <param name="Equipment">The equipment, still In Maintenance.</param>
    /// <param name="MaintenanceRecord">The posted maintenance record (passed by value).</param>
    /// <param name="IsHandled">Set to true to keep the equipment In Maintenance. The user can set it to Available later.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCompleteMaintenance(var Equipment: Record "EQM Equipment"; MaintenanceRecord: Record "EQM Maintenance Record"; var IsHandled: Boolean)
    begin
    end;
}
