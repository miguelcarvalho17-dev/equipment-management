namespace MiguelCarvalho.EquipmentManagement;

using Microsoft.Foundation.NoSeries;
using Microsoft.HumanResources.Employee;

/// <summary>
/// An equipment request raised for an employee: who needs equipment, which type (equipment category), why and when.
/// Requests are numbered from the Request Nos. series of the equipment setup and start as Open. Open requests can be
/// corrected and deleted; once another status is set (by a later feature), the request is locked.
/// </summary>
table 50111 "EQM Equipment Request"
{
    Caption = 'Equipment Request';
    DataClassification = CustomerContent;
    Access = Public;
    LookupPageId = "EQM Equipment Requests";
    DrillDownPageId = "EQM Equipment Requests";
    DataCaptionFields = "No.", "Employee No.";

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            ToolTip = 'Specifies the number of the equipment request. If you leave it blank, the next number from the Request Nos. series is used.';

            trigger OnValidate()
            var
                EquipmentSetup: Record "EQM Equipment Setup";
                NoSeries: Codeunit "No. Series";
            begin
                if "No." <> xRec."No." then begin
                    GetSetup(EquipmentSetup);
                    NoSeries.TestManual(EquipmentSetup."Request Nos.");
                    "No. Series" := '';
                end;
            end;
        }
        field(2; "Employee No."; Code[20])
        {
            Caption = 'Employee No.';
            ToolTip = 'Specifies the employee the equipment is requested for. The employee must exist, be active and not be blocked for privacy reasons.';
            TableRelation = Employee."No.";
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                if "Employee No." <> '' then
                    CheckEmployeeEligible();
            end;
        }
        field(3; "Requested Equipment Type"; Code[20])
        {
            Caption = 'Requested Equipment Type';
            ToolTip = 'Specifies the type of equipment that is requested. Choose an active equipment category, for example Laptop or Monitor.';
            TableRelation = "EQM Equipment Category".Code where(Active = const(true));
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                if "Requested Equipment Type" <> '' then
                    CheckEquipmentTypeAllowed();
            end;
        }
        field(4; Justification; Text[250])
        {
            Caption = 'Justification';
            ToolTip = 'Specifies why the equipment is needed. A justification is required.';
        }
        field(5; "Request Date"; Date)
        {
            Caption = 'Request Date';
            ToolTip = 'Specifies the date the equipment was requested. The date cannot be later than today. If you leave it blank, the work date is used.';

            trigger OnValidate()
            begin
                CheckRequestDate();
            end;
        }
        field(6; Status; Enum "EQM Request Status")
        {
            Caption = 'Status';
            ToolTip = 'Specifies the status of the request: Open, Pending Approval, Approved, Rejected or Completed. New requests are Open. Only open requests can be changed or deleted.';
            Editable = false;
            InitValue = Open;
        }
        field(7; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            ToolTip = 'Specifies the number series from which the request number was assigned.';
            TableRelation = "No. Series";
            Editable = false;
        }
        field(8; "Equipment Type Description"; Text[100])
        {
            Caption = 'Equipment Type Description';
            ToolTip = 'Specifies the description of the requested equipment type.';
            FieldClass = FlowField;
            CalcFormula = lookup("EQM Equipment Category".Description where(Code = field("Requested Equipment Type")));
            Editable = false;
        }
    }

    keys
    {
        key(PK; "No.")
        {
            Clustered = true;
        }
        key(EmployeeStatus; "Employee No.", Status)
        {
        }
        key(StatusDate; Status, "Request Date")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", "Employee No.", "Requested Equipment Type", "Request Date", Status)
        {
        }
        fieldgroup(Brick; "No.", "Employee No.", "Requested Equipment Type", "Request Date", Status)
        {
        }
    }

    var
        EmployeeNotFoundErr: Label 'Employee %1 does not exist.', Comment = '%1 = employee number';
        EmployeeNotActiveErr: Label 'You cannot raise an equipment request for employee %1 because the employee status is %2.', Comment = '%1 = employee number, %2 = employee status';
        EmployeePrivacyBlockedErr: Label 'You cannot raise an equipment request for employee %1 because the employee is blocked for privacy reasons.', Comment = '%1 = employee number';
        CategoryNotFoundErr: Label 'Equipment type %1 does not exist. Choose a category from the Equipment Categories page.', Comment = '%1 = equipment category code';
        CategoryInactiveErr: Label 'You cannot request equipment type %1 because the category is not active.', Comment = '%1 = equipment category code';
        JustificationRequiredErr: Label 'You must enter a justification for the equipment request.';
        FutureDateErr: Label 'The request date %1 is in the future. Enter a date that is not later than today (%2).', Comment = '%1 = request date, %2 = today''s date';
        InsertNotOpenErr: Label 'Equipment request %1 must be created with the status Open.', Comment = '%1 = request number';
        RequestNotOpenErr: Label 'You cannot change equipment request %1 because its status is %2. Only open requests can be changed.', Comment = '%1 = request number, %2 = status';
        DeleteNotOpenErr: Label 'You cannot delete equipment request %1 because its status is %2. Only open requests can be deleted.', Comment = '%1 = request number, %2 = status';
        RenameNotAllowedErr: Label 'You cannot change the number of equipment request %1.', Comment = '%1 = request number';
        StandardStyleTok: Label 'Standard', Locked = true;
        AmbiguousStyleTok: Label 'Ambiguous', Locked = true;
        FavorableStyleTok: Label 'Favorable', Locked = true;
        UnfavorableStyleTok: Label 'Unfavorable', Locked = true;
        SubordinateStyleTok: Label 'Subordinate', Locked = true;

    trigger OnInsert()
    var
        EquipmentSetup: Record "EQM Equipment Setup";
        NoSeries: Codeunit "No. Series";
    begin
        if "No." = '' then begin
            GetSetup(EquipmentSetup);
            EquipmentSetup.TestField("Request Nos.");
            "No. Series" := EquipmentSetup."Request Nos.";
            if (xRec."No. Series" <> '') and NoSeries.AreRelated(EquipmentSetup."Request Nos.", xRec."No. Series") then
                "No. Series" := xRec."No. Series";
            "No." := NoSeries.GetNextNo("No. Series");
        end;
        if "Request Date" = 0D then
            "Request Date" := WorkDate();
        if Status <> Status::Open then
            Error(InsertNotOpenErr, "No.");
        CheckRequestConsistency(true);
    end;

    trigger OnModify()
    var
        StoredRecord: Record "EQM Equipment Request";
    begin
        StoredRecord.SetLoadFields(Status);
        if StoredRecord.Get("No.") then
            if StoredRecord.Status <> StoredRecord.Status::Open then
                Error(RequestNotOpenErr, "No.", Format(StoredRecord.Status));
        CheckRequestConsistency(false);
    end;

    trigger OnDelete()
    var
        StoredRecord: Record "EQM Equipment Request";
    begin
        StoredRecord.SetLoadFields(Status);
        if StoredRecord.Get("No.") then
            if StoredRecord.Status <> StoredRecord.Status::Open then
                Error(DeleteNotOpenErr, "No.", Format(StoredRecord.Status));
    end;

    trigger OnRename()
    begin
        Error(RenameNotAllowedErr, xRec."No.");
    end;

    /// <summary>
    /// Lets the user pick a number series for a new request and takes the next number from it.
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
        EquipmentSetup.TestField("Request Nos.");
        if NoSeries.LookupRelatedNoSeries(EquipmentSetup."Request Nos.", xRec."No. Series", "No. Series") then begin
            "No." := NoSeries.GetNextNo("No. Series");
            exit(true);
        end;
        exit(false);
    end;

    /// <summary>
    /// Validates the request before it is inserted or modified: employee, equipment type and justification filled in,
    /// employee and category existing, employee active and not privacy blocked and category active (only for new
    /// requests or when the value changed), request date filled in and not later than today.
    /// Raises OnAfterCheckRequestConsistency at the end.
    /// </summary>
    /// <param name="IsNewRecord">True on insert. On modify, the active checks run only for values that differ from the stored record.</param>
    internal procedure CheckRequestConsistency(IsNewRecord: Boolean)
    var
        Employee: Record Employee;
        EquipmentCategory: Record "EQM Equipment Category";
        StoredRecord: Record "EQM Equipment Request";
        CheckEmployee: Boolean;
        CheckType: Boolean;
    begin
        TestField("Employee No.");
        TestField("Requested Equipment Type");
        TestField("Request Date");
        if DelChr(Justification, '<>', ' ') = '' then
            Error(JustificationRequiredErr);

        CheckEmployee := IsNewRecord;
        CheckType := IsNewRecord;
        if not IsNewRecord then begin
            StoredRecord.SetLoadFields("Employee No.", "Requested Equipment Type");
            if StoredRecord.Get("No.") then begin
                CheckEmployee := StoredRecord."Employee No." <> "Employee No.";
                CheckType := StoredRecord."Requested Equipment Type" <> "Requested Equipment Type";
            end else begin
                CheckEmployee := true;
                CheckType := true;
            end;
        end;

        if CheckEmployee then
            CheckEmployeeEligible()
        else begin
            Employee.SetLoadFields("No.");
            if not Employee.Get("Employee No.") then
                Error(EmployeeNotFoundErr, "Employee No.");
        end;

        if CheckType then
            CheckEquipmentTypeAllowed()
        else begin
            EquipmentCategory.SetLoadFields(Code);
            if not EquipmentCategory.Get("Requested Equipment Type") then
                Error(CategoryNotFoundErr, "Requested Equipment Type");
        end;

        CheckRequestDate();

        OnAfterCheckRequestConsistency(Rec);
    end;

    /// <summary>
    /// Returns the style name used to show the status on pages.
    /// </summary>
    /// <returns>The style name for the current status.</returns>
    internal procedure GetStatusStyle(): Text
    begin
        case Status of
            Status::"Pending Approval":
                exit(AmbiguousStyleTok);
            Status::Approved:
                exit(FavorableStyleTok);
            Status::Rejected:
                exit(UnfavorableStyleTok);
            Status::Completed:
                exit(SubordinateStyleTok);
            else
                exit(StandardStyleTok);
        end;
    end;

    local procedure CheckEmployeeEligible()
    var
        Employee: Record Employee;
    begin
        Employee.SetLoadFields(Status, "Privacy Blocked");
        if not Employee.Get("Employee No.") then
            Error(EmployeeNotFoundErr, "Employee No.");
        if Employee."Privacy Blocked" then
            Error(EmployeePrivacyBlockedErr, "Employee No.");
        if Employee.Status <> Employee.Status::Active then
            Error(EmployeeNotActiveErr, "Employee No.", Format(Employee.Status));
    end;

    local procedure CheckEquipmentTypeAllowed()
    var
        EquipmentCategory: Record "EQM Equipment Category";
    begin
        EquipmentCategory.SetLoadFields(Active);
        if not EquipmentCategory.Get("Requested Equipment Type") then
            Error(CategoryNotFoundErr, "Requested Equipment Type");
        if not EquipmentCategory.Active then
            Error(CategoryInactiveErr, "Requested Equipment Type");
    end;

    local procedure CheckRequestDate()
    begin
        if "Request Date" > Today() then
            Error(FutureDateErr, "Request Date", Today());
    end;

    local procedure GetSetup(var EquipmentSetup: Record "EQM Equipment Setup")
    begin
        if not EquipmentSetup.Get() then
            Clear(EquipmentSetup);
    end;

    /// <summary>
    /// Raised at the end of the consistency check on insert and modify, after all standard checks passed.
    /// </summary>
    /// <param name="EquipmentRequest">The request being saved (passed by value; changes are not kept). Raise an error to reject the save.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckRequestConsistency(EquipmentRequest: Record "EQM Equipment Request")
    begin
    end;
}
