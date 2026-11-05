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
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }
}
