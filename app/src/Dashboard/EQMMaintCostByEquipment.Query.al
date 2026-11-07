namespace MiguelCarvalho.EquipmentManagement;

query 50103 "EQM Maint. Cost by Equipment"
{
    Caption = 'Maintenance Cost by Equipment';
    QueryType = Normal;
    Access = Internal;
    DataAccessIntent = ReadOnly;
    OrderBy = descending(TotalCost), ascending(EquipmentNo);

    elements
    {
        dataitem(HistoryEntry; "EQM Maintenance History Entry")
        {
            column(EquipmentNo; "Equipment No.")
            {
            }
            column(TotalCost; Cost)
            {
                Method = Sum;
                ColumnFilter = TotalCost = filter(> 0);
            }
        }
    }
}
