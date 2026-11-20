namespace MiguelCarvalho.EquipmentManagement;

/// <summary>
/// In-memory buffer for the usage analytics report: one row per category (most assigned categories) or per month (trends, growth, active users).
/// </summary>
table 50116 "EQM Usage Analytics Buffer"
{
    Caption = 'Usage Analytics Buffer';
    DataClassification = CustomerContent;
    TableType = Temporary;
    Access = Internal;

    fields
    {
        field(1; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(2; "Period Start Date"; Date)
        {
            Caption = 'Period Start Date';
        }
        field(3; "Period End Date"; Date)
        {
            Caption = 'Period End Date';
        }
        field(4; "Category Code"; Code[20])
        {
            Caption = 'Category Code';
        }
        field(5; "Category Description"; Text[100])
        {
            Caption = 'Category Description';
        }
        field(6; Rank; Integer)
        {
            Caption = 'Rank';
        }
        field(7; "No. of Assignments"; Integer)
        {
            Caption = 'No. of Assignments';
        }
        field(8; "Assignment Share %"; Decimal)
        {
            Caption = 'Share of Assignments %';
            DecimalPlaces = 0 : 2;
        }
        field(9; "No. of Maintenances"; Integer)
        {
            Caption = 'No. of Maintenances';
        }
        field(10; "Maintenance Cost"; Decimal)
        {
            Caption = 'Maintenance Cost';
            AutoFormatType = 1;
        }
        field(11; "New Equipment"; Integer)
        {
            Caption = 'New Equipment';
        }
        field(12; "Total Equipment"; Integer)
        {
            Caption = 'Total Equipment';
        }
        field(13; "Active Users"; Integer)
        {
            Caption = 'Active Users';
        }
    }

    keys
    {
        key(PK; "Line No.")
        {
            Clustered = true;
        }
    }
}
