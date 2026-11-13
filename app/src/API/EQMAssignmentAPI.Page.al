namespace MiguelCarvalho.EquipmentManagement;

page 50125 "EQM Assignment API"
{
    Caption = 'Assignment API';
    PageType = API;
    APIPublisher = 'miguelCarvalho';
    APIGroup = 'equipment';
    APIVersion = 'v1.0';
    EntityName = 'assignment';
    EntitySetName = 'assignments';
    EntityCaption = 'Assignment';
    EntitySetCaption = 'Assignments';
    SourceTable = "EQM Equipment Assignment";
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
                field(entryNumber; Rec."Entry No.")
                {
                    Caption = 'Entry No.';
                }
                field(equipmentNumber; Rec."Equipment No.")
                {
                    Caption = 'Equipment No.';
                }
                field(employeeNumber; Rec."Employee No.")
                {
                    Caption = 'Employee No.';
                }
                field(assignmentDate; Rec."Assignment Date")
                {
                    Caption = 'Assignment Date';
                }
                field(status; Rec.Status)
                {
                    Caption = 'Status';
                }
                field(closingDate; Rec."Closing Date")
                {
                    Caption = 'Closing Date';
                }
                field(lastModifiedDateTime; Rec.SystemModifiedAt)
                {
                    Caption = 'Last Modified Date-Time';
                }
            }
        }
    }
}
