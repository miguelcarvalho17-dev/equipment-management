namespace MiguelCarvalho.EquipmentManagement;

query 50105 "EQM Assignments by Category"
{
    Caption = 'Assignments by Category';
    QueryType = Normal;
    Access = Internal;
    DataAccessIntent = ReadOnly;
    OrderBy = descending(NoOfAssignments), ascending(CategoryCode);

    elements
    {
        dataitem(Assignment; "EQM Equipment Assignment")
        {
            filter(AssignmentDateFilter; "Assignment Date")
            {
            }
            column(NoOfAssignments)
            {
                Method = Count;
            }
            dataitem(Equipment; "EQM Equipment")
            {
                DataItemLink = "No." = Assignment."Equipment No.";
                SqlJoinType = LeftOuterJoin;

                column(CategoryCode; "Category Code")
                {
                }
            }
        }
    }
}
