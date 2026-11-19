namespace MiguelCarvalho.EquipmentManagement;

/// <summary>
/// Open warranty alerts with the current warranty end date and status of their equipment. EquipmentNo is blank when the
/// equipment no longer exists. Used to cancel stale alerts in one read.
/// </summary>
query 50104 "EQM Open Warranty Alerts"
{
    Caption = 'Open Warranty Alerts';
    QueryType = Normal;
    Access = Internal;
    // Read inside the write transaction of GenerateAlerts (after LockTable), so never from a read-only replica
    DataAccessIntent = ReadWrite;

    elements
    {
        dataitem(WarrantyAlert; "EQM Warranty Alert")
        {
            DataItemTableFilter = Status = const(Open);
            column(EntryNo; "Entry No.")
            {
            }
            column(AlertWarrantyEndDate; "Warranty End Date")
            {
            }
            dataitem(Equipment; "EQM Equipment")
            {
                DataItemLink = "No." = WarrantyAlert."Equipment No.";
                SqlJoinType = LeftOuterJoin;
                column(EquipmentNo; "No.")
                {
                }
                column(EquipmentWarrantyEndDate; "Warranty End Date")
                {
                }
                column(EquipmentStatus; Status)
                {
                }
            }
        }
    }
}
