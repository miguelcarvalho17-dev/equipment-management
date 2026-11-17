namespace MiguelCarvalho.EquipmentManagement;

/// <summary>
/// In-memory buffer for the maintenance cost analysis report: posted maintenance cost per category, equipment, year and month.
/// </summary>
table 50113 "EQM Maint. Cost Buffer"
{
    Caption = 'Maintenance Cost Buffer';
    DataClassification = CustomerContent;
    TableType = Temporary;
    Access = Internal;

    fields
    {
        field(1; "Category Code"; Code[20])
        {
            Caption = 'Category Code';
        }
        field(2; "Equipment No."; Code[20])
        {
            Caption = 'Equipment No.';
        }
        field(3; "Cost Year"; Integer)
        {
            Caption = 'Year';
        }
        field(4; "Cost Month"; Integer)
        {
            Caption = 'Month';
        }
        field(5; "Period Start Date"; Date)
        {
            Caption = 'Period Start Date';
        }
        field(6; "Category Description"; Text[100])
        {
            Caption = 'Category Description';
        }
        field(7; "Equipment Description"; Text[100])
        {
            Caption = 'Equipment Description';
        }
        field(8; "No. of Maintenances"; Integer)
        {
            Caption = 'No. of Maintenances';
        }
        field(9; "Total Cost"; Decimal)
        {
            Caption = 'Total Cost';
            AutoFormatType = 1;
        }
    }

    keys
    {
        key(PK; "Category Code", "Equipment No.", "Cost Year", "Cost Month")
        {
            Clustered = true;
        }
    }
}
