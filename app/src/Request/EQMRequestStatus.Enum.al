namespace MiguelCarvalho.EquipmentManagement;

/// <summary>
/// Status of an equipment request; FR-032 creates requests as Open.
/// </summary>
enum 50110 "EQM Request Status"
{
    Caption = 'Request Status';
    Extensible = false;

    value(0; Open)
    {
        Caption = 'Open';
    }
    value(1; "Pending Approval")
    {
        Caption = 'Pending Approval';
    }
    value(2; Approved)
    {
        Caption = 'Approved';
    }
    value(3; Rejected)
    {
        Caption = 'Rejected';
    }
    value(4; Completed)
    {
        Caption = 'Completed';
    }
}
