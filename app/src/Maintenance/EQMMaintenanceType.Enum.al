namespace MiguelCarvalho.EquipmentManagement;

/// <summary>
/// Type of maintenance activity. New maintenance records start as Preventive.
/// </summary>
enum 50102 "EQM Maintenance Type"
{
    Caption = 'Maintenance Type';
    Extensible = true;

    value(0; Preventive)
    {
        Caption = 'Preventive';
    }
    value(1; Corrective)
    {
        Caption = 'Corrective';
    }
    value(2; Inspection)
    {
        Caption = 'Inspection';
    }
    value(3; Upgrade)
    {
        Caption = 'Upgrade';
    }
}
