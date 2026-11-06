namespace MiguelCarvalho.EquipmentManagement;

/// <summary>
/// Status of a maintenance record. Open records can be corrected. Posting a record freezes it and writes it to the
/// maintenance history.
/// </summary>
enum 50103 "EQM Maintenance Status"
{
    Caption = 'Maintenance Status';
    Extensible = false;

    value(0; Open)
    {
        Caption = 'Open';
    }
    value(1; Posted)
    {
        Caption = 'Posted';
    }
}
