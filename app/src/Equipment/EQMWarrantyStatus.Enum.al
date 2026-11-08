namespace MiguelCarvalho.EquipmentManagement;

/// <summary>
/// Calculated warranty status of equipment, based on the Warranty End Date and today's date. Blank when no end date
/// is filled in. Never stored.
/// </summary>
enum 50104 "EQM Warranty Status"
{
    Caption = 'Warranty Status';
    Extensible = false;

    value(0; " ")
    {
        Caption = ' ';
    }
    value(1; Active)
    {
        Caption = 'Active';
    }
    value(2; "Expiring Soon")
    {
        Caption = 'Expiring Soon';
    }
    value(3; Expired)
    {
        Caption = 'Expired';
    }
}
