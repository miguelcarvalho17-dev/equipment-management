namespace MiguelCarvalho.EquipmentManagement;

/// <summary>
/// Optional features of Equipment Management that an administrator can turn on or off per company.
/// </summary>
enum 50112 "EQM Feature"
{
    Caption = 'Equipment Feature';
    Extensible = false;
    Access = Internal;

    value(0; "Equipment Images")
    {
        Caption = 'Equipment Images';
    }
    value(1; "Warranty Alerts")
    {
        Caption = 'Warranty Alerts';
    }
    value(2; "Approval Workflows")
    {
        Caption = 'Approval Workflows';
    }
    value(3; "API Integration")
    {
        Caption = 'API Integration';
    }
    value(4; "Maintenance Planning")
    {
        Caption = 'Maintenance Planning';
    }
}
