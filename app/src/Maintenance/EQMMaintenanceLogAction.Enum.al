namespace MiguelCarvalho.EquipmentManagement;

/// <summary>
/// The kind of operation recorded in the maintenance log.
/// </summary>
enum 50107 "EQM Maintenance Log Action"
{
    Extensible = false;
    Caption = 'Maintenance Log Action';

    value(0; Registered)
    {
        Caption = 'Registered';
    }
    value(1; Changed)
    {
        Caption = 'Changed';
    }
    value(2; Posted)
    {
        Caption = 'Posted';
    }
}
