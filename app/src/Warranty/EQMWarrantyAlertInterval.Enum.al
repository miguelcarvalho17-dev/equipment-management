namespace MiguelCarvalho.EquipmentManagement;

/// <summary>
/// The number of days before the warranty end date at which a warranty alert is created.
/// </summary>
enum 50105 "EQM Warranty Alert Interval"
{
    Caption = 'Warranty Alert Interval';
    Extensible = false;

    value(30; "30 Days")
    {
        Caption = '30 Days';
    }
    value(60; "60 Days")
    {
        Caption = '60 Days';
    }
    value(90; "90 Days")
    {
        Caption = '90 Days';
    }
}
