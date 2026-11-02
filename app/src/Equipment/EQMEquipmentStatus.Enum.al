namespace MiguelCarvalho.EquipmentManagement;

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
    value(2; "Under Maintenance")
    {
        Caption = 'Under Maintenance';
    }
    value(3; Retired)
    {
        Caption = 'Retired';
    }
}
