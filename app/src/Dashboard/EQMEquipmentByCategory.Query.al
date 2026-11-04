namespace MiguelCarvalho.EquipmentManagement;

query 50100 "EQM Equipment by Category"
{
    Caption = 'Equipment by Category';
    QueryType = Normal;
    Access = Internal;
    DataAccessIntent = ReadOnly;
    OrderBy = ascending(CategoryCode);

    elements
    {
        dataitem(Equipment; "EQM Equipment")
        {
            column(CategoryCode; "Category Code")
            {
            }
            column(NoOfEquipment)
            {
                Method = Count;
            }
        }
    }
}
