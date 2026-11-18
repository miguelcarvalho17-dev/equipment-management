namespace MiguelCarvalho.EquipmentManagement;

/// <summary>
/// One row per optional feature. A feature without a row is enabled.
/// </summary>
table 50114 "EQM Feature Setup"
{
    Caption = 'Equipment Feature Setup';
    DataClassification = CustomerContent;
    Access = Internal;
    LookupPageId = "EQM Equipment Features";
    DrillDownPageId = "EQM Equipment Features";

    fields
    {
        field(1; Feature; Enum "EQM Feature")
        {
            Caption = 'Feature';
            ToolTip = 'Specifies the optional part of Equipment Management that you can turn on or off.';
        }
        field(2; Enabled; Boolean)
        {
            Caption = 'Enabled';
            InitValue = true;
            ToolTip = 'Specifies whether the feature is turned on in this company. When it is off, its pages, fields, actions and tiles are hidden, and pages that belong only to this feature show an error when they are opened. No data is deleted. Users see the change the next time they open a page.';
        }
    }

    keys
    {
        key(PK; Feature)
        {
            Clustered = true;
        }
    }
}
