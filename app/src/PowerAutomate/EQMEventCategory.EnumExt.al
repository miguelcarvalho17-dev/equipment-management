namespace MiguelCarvalho.EquipmentManagement;

using System.Integration;

/// <summary>
/// Groups the Equipment Management external business events in Power Automate.
/// </summary>
enumextension 50100 "EQM Event Category" extends EventCategory
{
    value(50100; "EQM Equipment Management")
    {
        Caption = 'Equipment Management';
    }
}
