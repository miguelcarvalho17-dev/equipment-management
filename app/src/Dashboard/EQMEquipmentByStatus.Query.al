namespace MiguelCarvalho.EquipmentManagement;

query 50101 "EQM Equipment by Status"
{
    Caption = 'Equipment by Status';
    QueryType = Normal;
    Access = Internal;
    DataAccessIntent = ReadOnly;

    elements
    {
        dataitem(Equipment; "EQM Equipment")
        {
            column(Status; Status)
            {
            }
            column(NoOfEquipment)
            {
                Method = Count;
            }
        }
    }
}
