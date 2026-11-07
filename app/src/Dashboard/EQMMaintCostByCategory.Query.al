namespace MiguelCarvalho.EquipmentManagement;

query 50102 "EQM Maint. Cost by Category"
{
    Caption = 'Maintenance Cost by Category';
    QueryType = Normal;
    Access = Internal;
    DataAccessIntent = ReadOnly;
    OrderBy = descending(TotalCost), ascending(CategoryCode);

    elements
    {
        dataitem(Equipment; "EQM Equipment")
        {
            column(CategoryCode; "Category Code")
            {
            }
            dataitem(HistoryEntry; "EQM Maintenance History Entry")
            {
                DataItemLink = "Equipment No." = Equipment."No.";
                SqlJoinType = InnerJoin;

                column(TotalCost; Cost)
                {
                    Method = Sum;
                    ColumnFilter = TotalCost = filter(> 0);
                }
            }
        }
    }
}
