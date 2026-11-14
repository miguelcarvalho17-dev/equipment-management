namespace MiguelCarvalho.EquipmentManagement;

/// <summary>
/// The business event that an integration event entry records. Values are part of the integration contract.
/// </summary>
enum 50109 "EQM Integration Event Type"
{
    Caption = 'Integration Event Type';
    Extensible = false;

    value(0; "Equipment Created")
    {
        Caption = 'Equipment Created';
    }
    value(1; "Equipment Assigned")
    {
        Caption = 'Equipment Assigned';
    }
    value(2; "Equipment Returned")
    {
        Caption = 'Equipment Returned';
    }
    value(3; "Maintenance Created")
    {
        Caption = 'Maintenance Created';
    }
    value(4; "Warranty Expired")
    {
        Caption = 'Warranty Expired';
    }
}
