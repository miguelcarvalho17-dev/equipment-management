namespace MiguelCarvalho.EquipmentManagement;

page 50124 "EQM Category API"
{
    Caption = 'Category API';
    PageType = API;
    APIPublisher = 'miguelCarvalho';
    APIGroup = 'equipment';
    APIVersion = 'v1.0';
    EntityName = 'category';
    EntitySetName = 'categories';
    EntityCaption = 'Category';
    EntitySetCaption = 'Categories';
    SourceTable = "EQM Equipment Category";
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    Extensible = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    DataAccessIntent = ReadOnly;

    layout
    {
        area(Content)
        {
            repeater(Records)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'Id';
                }
                field(code; Rec.Code)
                {
                    Caption = 'Code';
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                }
                field(active; Rec.Active)
                {
                    Caption = 'Active';
                }
                field(lastModifiedDateTime; Rec.SystemModifiedAt)
                {
                    Caption = 'Last Modified Date-Time';
                }
            }
        }
    }
}
