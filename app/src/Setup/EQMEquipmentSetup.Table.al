namespace MiguelCarvalho.EquipmentManagement;

using Microsoft.Foundation.NoSeries;

table 50102 "EQM Equipment Setup"
{
    Caption = 'Equipment Setup';
    DataClassification = CustomerContent;
    Access = Public;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            ToolTip = 'Specifies the primary key of the equipment setup record.';
        }
        field(2; "Equipment Nos."; Code[20])
        {
            Caption = 'Equipment Nos.';
            ToolTip = 'Specifies the number series used to assign numbers to new equipment.';
            TableRelation = "No. Series";
        }
        field(3; "Maintenance Nos."; Code[20])
        {
            Caption = 'Maintenance Nos.';
            ToolTip = 'Specifies the number series used to assign numbers to new maintenance records.';
            TableRelation = "No. Series";
        }
        field(4; "Integration Events Enabled"; Boolean)
        {
            Caption = 'Integration Events Enabled';
            ToolTip = 'Specifies that an integration event entry is written for each business event (equipment created, assigned or returned, maintenance created, warranty expired), so that external systems can read them through the API. Entries are written only when this is on.';
        }
        field(5; "Request Nos."; Code[20])
        {
            Caption = 'Request Nos.';
            ToolTip = 'Specifies the number series used to assign numbers to new equipment requests.';
            TableRelation = "No. Series";
        }
        field(6; "Default Warranty Alert Days"; Integer)
        {
            Caption = 'Default Warranty Alert Days';
            ToolTip = 'Specifies how many days before the warranty end date warranty alerts start to be created, from 1 to 90. Alerts are created 90, 60 and 30 days before the end date, as far as these fall within this number of days; for example, with 30 only the 30-day alert is created. When the field is blank, 90 days is used. Alerts that are already open are kept when you lower the number.';
            InitValue = 90;
            BlankZero = true;

            trigger OnValidate()
            var
                WarrantyAlertMgt: Codeunit "EQM Warranty Alert Mgt.";
            begin
                CheckValueInRange(FieldNo("Default Warranty Alert Days"), FieldCaption("Default Warranty Alert Days"), "Default Warranty Alert Days", 1, WarrantyAlertMgt.GetLongestIntervalDays());
            end;
        }
        field(7; "Default Maint. Freq. (Months)"; Integer)
        {
            Caption = 'Default Maintenance Frequency (Months)';
            ToolTip = 'Specifies the maintenance frequency, in months, that new equipment gets when you create it on the equipment card, from 0 to 120. You can change the frequency on each piece of equipment. Leave the field blank when new equipment has no planned maintenance by default. Existing equipment, and equipment created through the API or by import, is not changed.';
            BlankZero = true;

            trigger OnValidate()
            begin
                // 120 is the MaxValue of field 23 "Maintenance Frequency (Months)" on table 50100
                CheckValueInRange(FieldNo("Default Maint. Freq. (Months)"), FieldCaption("Default Maint. Freq. (Months)"), "Default Maint. Freq. (Months)", 0, 120);
            end;
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

    var
        ValueOutOfRangeErr: Label '%1 must be between %2 and %3. You entered %4.', Comment = '%1 = field caption, %2 = lowest allowed value, %3 = highest allowed value, %4 = the value that was entered';

    local procedure CheckValueInRange(FieldNumber: Integer; FieldCaptionText: Text; Value: Integer; MinValue: Integer; MaxValue: Integer)
    var
        OutOfRangeError: ErrorInfo;
    begin
        if (Value >= MinValue) and (Value <= MaxValue) then
            exit;
        OutOfRangeError.Message(StrSubstNo(ValueOutOfRangeErr, FieldCaptionText, MinValue, MaxValue, Value));
        OutOfRangeError.TableId(Database::"EQM Equipment Setup");
        OutOfRangeError.FieldNo(FieldNumber);
        OutOfRangeError.RecordId(RecordId());
        Error(OutOfRangeError);
    end;
}
