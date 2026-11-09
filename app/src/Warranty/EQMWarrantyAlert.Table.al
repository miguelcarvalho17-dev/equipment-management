namespace MiguelCarvalho.EquipmentManagement;

/// <summary>
/// A warranty alert created when the warranty of a piece of equipment reaches 90, 60 or 30 days before its end date.
/// </summary>
table 50107 "EQM Warranty Alert"
{
    Caption = 'Warranty Alert';
    DataClassification = CustomerContent;
    Access = Public;
    LookupPageId = "EQM Warranty Alerts";
    DrillDownPageId = "EQM Warranty Alerts";
    DataCaptionFields = "Equipment No.", "Alert Interval";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            ToolTip = 'Specifies the number of the warranty alert.';
            AutoIncrement = true;
            Editable = false;
        }
        field(2; "Equipment No."; Code[20])
        {
            Caption = 'Equipment No.';
            ToolTip = 'Specifies the equipment whose warranty is about to end.';
            TableRelation = "EQM Equipment"."No.";
            NotBlank = true;
            Editable = false;
        }
        field(3; "Equipment Description"; Text[100])
        {
            Caption = 'Equipment Description';
            ToolTip = 'Specifies the description of the equipment.';
            FieldClass = FlowField;
            CalcFormula = lookup("EQM Equipment".Description where("No." = field("Equipment No.")));
            Editable = false;
        }
        field(4; "Warranty Provider"; Text[100])
        {
            Caption = 'Warranty Provider';
            ToolTip = 'Specifies the company that provides the warranty. Contact it to renew the warranty or to raise a claim.';
            FieldClass = FlowField;
            CalcFormula = lookup("EQM Equipment"."Warranty Provider" where("No." = field("Equipment No.")));
            Editable = false;
        }
        field(5; "Alert Interval"; Enum "EQM Warranty Alert Interval")
        {
            Caption = 'Alert Interval';
            ToolTip = 'Specifies how many days before the warranty end date the alert was created: 90, 60 or 30 days.';
            Editable = false;
        }
        field(6; "Warranty End Date"; Date)
        {
            Caption = 'Warranty End Date';
            ToolTip = 'Specifies the warranty end date of the equipment when the alert was created. If the end date of the equipment is changed later, this alert is cancelled and new alerts are created for the new date.';
            Editable = false;
        }
        field(7; "Alert Date"; Date)
        {
            Caption = 'Alert Date';
            ToolTip = 'Specifies the date the alert was created.';
            Editable = false;
        }
        field(8; Status; Enum "EQM Warranty Alert Status")
        {
            Caption = 'Status';
            ToolTip = 'Specifies whether the alert is Open, Acknowledged or Cancelled. Use the Acknowledge action when you have acted on an alert. Alerts are cancelled automatically when the warranty end date changes or the equipment is lost, disposed of or deleted.';
            Editable = false;
        }
        field(9; "Acknowledged By"; Code[50])
        {
            Caption = 'Acknowledged By';
            ToolTip = 'Specifies the user who acknowledged the alert.';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(10; "Acknowledged At"; DateTime)
        {
            Caption = 'Acknowledged At';
            ToolTip = 'Specifies when the alert was acknowledged.';
            Editable = false;
        }
        field(11; "Cancelled At"; DateTime)
        {
            Caption = 'Cancelled At';
            ToolTip = 'Specifies when the alert was cancelled.';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(Equipment; "Equipment No.", "Warranty End Date", "Alert Interval")
        {
        }
        key(Status; Status, "Warranty End Date")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Entry No.", "Equipment No.", "Alert Interval", "Warranty End Date", Status)
        {
        }
        fieldgroup(Brick; "Equipment No.", "Equipment Description", "Alert Interval", Status)
        {
        }
    }
}
