namespace MiguelCarvalho.EquipmentManagement;

/// <summary>
/// The status of a warranty alert. Open alerts need action; Acknowledged alerts were handled by a user; Cancelled
/// alerts no longer apply because the warranty end date changed or the equipment was lost, disposed of or deleted.
/// </summary>
enum 50106 "EQM Warranty Alert Status"
{
    Caption = 'Warranty Alert Status';
    Extensible = false;

    value(0; Open)
    {
        Caption = 'Open';
    }
    value(1; Acknowledged)
    {
        Caption = 'Acknowledged';
    }
    value(2; Cancelled)
    {
        Caption = 'Cancelled';
    }
}
