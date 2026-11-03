namespace MiguelCarvalho.EquipmentManagement;

/// <summary>
/// Status of an equipment assignment entry. Active means the equipment is currently assigned to the employee;
/// Closed means the assignment has ended.
/// </summary>
enum 50101 "EQM Assignment Status"
{
    Caption = 'Equipment Assignment Status';
    Extensible = false;

    value(0; Active)
    {
        Caption = 'Active';
    }
    value(1; Closed)
    {
        Caption = 'Closed';
    }
}
