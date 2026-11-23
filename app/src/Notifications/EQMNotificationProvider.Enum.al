namespace MiguelCarvalho.EquipmentManagement;

/// <summary>
/// The channels that can deliver equipment notifications.
/// </summary>
enum 50114 "EQM Notification Provider" implements "EQM INotification Provider"
{
    Caption = 'Equipment Notification Provider';
    Extensible = false;
    Access = Internal;

    value(0; "Business Central")
    {
        Caption = 'Business Central notification';
        Implementation = "EQM INotification Provider" = "EQM BC Notification Provider";
    }
}
