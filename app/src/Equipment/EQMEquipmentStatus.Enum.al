namespace MiguelCarvalho.EquipmentManagement;

/// <summary>
/// Lifecycle status of equipment. Lost and Disposed are final: they cannot be assigned,
/// cannot be changed to another status, and cannot be used for new equipment.
/// </summary>
enum 50100 "EQM Equipment Status"
{
    Caption = 'Equipment Status';
    Extensible = true;

    value(0; Available)
    {
        Caption = 'Available';
    }
    value(1; Assigned)
    {
        Caption = 'Assigned';
    }
    value(2; "In Maintenance")
    {
        Caption = 'In Maintenance';
    }
    value(3; Disposed)
    {
        Caption = 'Disposed';
    }
    value(4; Lost)
    {
        Caption = 'Lost';
    }
}
