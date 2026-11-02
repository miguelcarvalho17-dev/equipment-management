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
            ToolTip = 'Specifies the status of the equipment. To assign equipment to an employee, use the Assign to Employee action.';
            InitValue = Available;

            trigger OnValidate()
            var
                ConfirmManagement: Codeunit "Confirm Management";
            begin
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
            ToolTip = 'Specifies the employee the equipment is assigned to. The employee can only be set when the status is Assigned.';
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
        SerialNoAlreadyUsedErr: Label 'Serial No. %1 is already used by equipment %2.', Comment = '%1 = serial number, %2 = equipment number';
        EmployeeOnlyWhenAssignedErr: Label 'You can only fill in %1 when the status is %2.', Comment = '%1 = Assigned Employee No. field caption, %2 = Assigned status caption';
        AssignedEmployeeRequiredErr: Label 'You must fill in %1 for equipment %2 because its status is %3. On the equipment card, use the Assign to Employee action.', Comment = '%1 = field caption, %2 = equipment number, %3 = status caption';
        EmployeeNotFoundErr: Label 'Employee %1 assigned to equipment %2 no longer exists. Use the Unassign action, then assign another employee.', Comment = '%1 = employee number, %2 = equipment number';
        EmployeeNotActiveErr: Label 'You cannot assign equipment to employee %1 because the employee status is %2.', Comment = '%1 = employee number, %2 = employee status';
        EmployeePrivacyBlockedErr: Label 'You cannot assign equipment to employee %1 because the employee is blocked for privacy reasons.', Comment = '%1 = employee number';
        StatusChangeRemovesEmployeeQst: Label 'Changing the status removes the assigned employee %1 from equipment %2. Do you want to continue?', Comment = '%1 = employee number, %2 = equipment number';
        CategoryNotFoundErr: Label 'Equipment category %1 does not exist. Choose a category from the Equipment Categories page.', Comment = '%1 = category code';
        CategoryInactiveErr: Label 'You cannot select equipment category %1 because it is not active. Choose an active category, or ask an administrator to activate it.', Comment = '%1 = category code';
        DeleteAssignedQst: Label 'Equipment %1 is assigned to employee %2. Do you want to delete it anyway?', Comment = '%1 = equipment number, %2 = employee number';

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
    begin
        CheckEquipmentConsistency(false);
    end;

    trigger OnDelete()
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if (Status = Status::Assigned) and ("Assigned Employee No." <> '') then
            if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(DeleteAssignedQst, "No.", "Assigned Employee No."), true) then
                Error('');
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
    /// Can also be used to reassign equipment that is already assigned.
    /// </summary>
    /// <param name="EmployeeNo">The employee to assign. Must exist, be Active and not be privacy blocked; otherwise an error is raised.</param>
    internal procedure AssignEmployee(EmployeeNo: Code[20])
    begin
        Validate(Status, Status::Assigned);
        Validate("Assigned Employee No.", EmployeeNo);
        Modify(true);
    end;

    /// <summary>
    /// Sets the status to Available, which clears the assigned employee, and saves the record with triggers.
    /// If an employee is set, the user is asked to confirm first; answering No cancels with a silent error.
    /// Without a UI session the confirmation defaults to Yes.
    /// </summary>
    internal procedure UnassignEmployee()
    begin
        Validate(Status, Status::Available);
        Modify(true);
    end;

    /// <summary>
    /// Validates the record before it is inserted or modified: category filled in, category exists and is active
    /// (active only when the category is new or changed), serial number unique, assigned employee allowed,
    /// and employee present when the status is Assigned.
    /// Raises OnAfterCheckEquipmentConsistency at the end.
    /// </summary>
    /// <param name="IsNewRecord">True on insert. On modify (false), the Active / not privacy blocked check on the employee runs only if the assigned employee differs from the stored record.</param>
    internal procedure CheckEquipmentConsistency(IsNewRecord: Boolean)
    var
        StoredEquipment: Record "EQM Equipment";
        CategoryChanged: Boolean;
        EmployeeChanged: Boolean;
    begin
        TestField("Category Code");

        CategoryChanged := true;
        EmployeeChanged := true;
        if not IsNewRecord then begin
            StoredEquipment.SetLoadFields("Assigned Employee No.", "Category Code");
            if StoredEquipment.Get("No.") then begin
                CategoryChanged := StoredEquipment."Category Code" <> "Category Code";
                EmployeeChanged := StoredEquipment."Assigned Employee No." <> "Assigned Employee No.";
            end;
        end;
        CheckCategoryAllowed(CategoryChanged);

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
        OnBeforeCheckAssignedEmployeeAllowed(Rec, IsHandled);
        if IsHandled then
            exit;

        if "Assigned Employee No." = '' then
            exit;

        if Status <> Status::Assigned then
            Error(EmployeeOnlyWhenAssignedErr, FieldCaption("Assigned Employee No."), Format(Status::Assigned));

        Employee.SetLoadFields(Status, "Privacy Blocked");
        if not Employee.Get("Assigned Employee No.") then
            Error(EmployeeNotFoundErr, "Assigned Employee No.", "No.");

        if CheckEmployeeIsActive then begin
            if Employee."Privacy Blocked" then
                Error(EmployeePrivacyBlockedErr, "Assigned Employee No.");
            if Employee.Status <> Employee.Status::Active then
                Error(EmployeeNotActiveErr, "Assigned Employee No.", Format(Employee.Status));
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
    /// Raised before the assigned employee checks (employee only when status is Assigned, employee exists,
    /// employee is Active and not privacy blocked).
    /// </summary>
    /// <param name="Equipment">The record being checked (passed by value; changes are not kept).</param>
    /// <param name="IsHandled">Set to true to skip those checks. The rule that Assigned equipment must have an employee still applies.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckAssignedEmployeeAllowed(Equipment: Record "EQM Equipment"; var IsHandled: Boolean)
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
}
