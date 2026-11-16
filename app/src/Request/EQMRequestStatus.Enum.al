namespace MiguelCarvalho.EquipmentManagement;

/// <summary>
/// Status of an equipment request. Open, then Pending Approval, then Approved or Rejected; Approved requests become Completed when equipment is assigned. Rejected and Completed are final.
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
