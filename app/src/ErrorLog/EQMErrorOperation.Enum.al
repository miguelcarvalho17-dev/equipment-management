namespace MiguelCarvalho.EquipmentManagement;

/// <summary>
/// The process of the app that raised a logged error.
/// </summary>
enum 50113 "EQM Error Operation"
{
    Extensible = false;
    Access = Internal;
    Caption = 'Error Operation';

    value(0; " ")
    {
        Caption = ' ';
    }
    value(1; "Warranty Alert Job")
    {
        Caption = 'Warranty Alert Job';
    }
    value(2; "Overdue Maintenance Job")
    {
        Caption = 'Overdue Maintenance Job';
    }
    value(3; "Schedule Monitoring Jobs")
    {
        Caption = 'Schedule Monitoring Jobs';
    }
}
