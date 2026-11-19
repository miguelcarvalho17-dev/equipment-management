namespace MiguelCarvalho.EquipmentManagement;

/// <summary>
/// Tracks the records that Create Demo Data inserted, by table, number and system ID. Delete Demo Data removes only
/// records that have a row here, so it never touches data that users created, and it still finds a demo record that
/// was renamed. Rows are written and deleted only by codeunit "EQM Demo Data Mgt.".
/// </summary>
table 50149 "EQM Demo Data Entry"
{
    Caption = 'Equipment Demo Data Entry';
    DataClassification = CustomerContent;
    Access = Internal;

    fields
    {
        field(1; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            ToolTip = 'Specifies the table of the record that the demo data created.';
            DataClassification = SystemMetadata;
        }
        field(2; "Record No."; Code[20])
        {
            Caption = 'Record No.';
            ToolTip = 'Specifies the number of the record when the demo data created it.';
        }
        field(3; "Record System Id"; Guid)
        {
            Caption = 'Record System ID';
            ToolTip = 'Specifies the system ID of the record that the demo data created. It identifies the record even after it is renamed.';
            DataClassification = SystemMetadata;
        }
        field(4; "Created At"; DateTime)
        {
            Caption = 'Created At';
            ToolTip = 'Specifies when the demo record was created.';
            DataClassification = SystemMetadata;
        }
        field(5; "Created By"; Code[50])
        {
            Caption = 'Created By';
            ToolTip = 'Specifies the user who created the demo data.';
            DataClassification = EndUserIdentifiableInformation;
        }
    }

    keys
    {
        key(PK; "Table ID", "Record No.")
        {
            Clustered = true;
        }
        key(SystemId; "Record System Id")
        {
        }
    }
}
