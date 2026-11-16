namespace MiguelCarvalho.EquipmentManagement;

/// <summary>
/// The kind of lifecycle event recorded in the equipment audit trail.
/// </summary>
enum 50111 "EQM Audit Event Type"
{
    Extensible = false;
    Caption = 'Audit Event Type';

    value(0; Created)
    {
        Caption = 'Created';
    }
    value(1; Updated)
    {
        Caption = 'Updated';
    }
    value(2; Assigned)
    {
        Caption = 'Assigned';
    }
    value(3; Returned)
    {
        Caption = 'Returned';
    }
    value(4; "Sent to Maintenance")
    {
        Caption = 'Sent to Maintenance';
    }
    value(5; Disposed)
    {
        Caption = 'Disposed';
    }
}
