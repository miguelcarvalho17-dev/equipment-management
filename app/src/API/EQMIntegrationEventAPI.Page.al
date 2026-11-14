namespace MiguelCarvalho.EquipmentManagement;

page 50126 "EQM Integration Event API"
{
    Caption = 'Integration Event API';
    PageType = API;
    APIPublisher = 'miguelCarvalho';
    APIGroup = 'equipment';
    APIVersion = 'v1.0';
    EntityName = 'integrationEvent';
    EntitySetName = 'integrationEvents';
    EntityCaption = 'Integration Event';
    EntitySetCaption = 'Integration Events';
    SourceTable = "EQM Integration Event Entry";
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    Extensible = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

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
                field(eventType; Rec."Event Type")
                {
                    Caption = 'Event Type';
                }
                field(equipmentNumber; Rec."Equipment No.")
                {
                    Caption = 'Equipment No.';
                }
                field(equipmentStatus; Rec."Equipment Status")
                {
                    Caption = 'Equipment Status';
                }
                field(assignmentEntryNumber; Rec."Assignment Entry No.")
                {
                    Caption = 'Assignment Entry No.';
                }
                field(maintenanceNumber; Rec."Maintenance No.")
                {
                    Caption = 'Maintenance No.';
                }
                field(processed; Rec.Processed)
                {
                    Caption = 'Processed';
                }
                field(processedDateTime; Rec."Processed At")
                {
                    Caption = 'Processed Date-Time';
                }
                field(createdDateTime; Rec.SystemCreatedAt)
                {
                    Caption = 'Created Date-Time';
                }
                field(lastModifiedDateTime; Rec.SystemModifiedAt)
                {
                    Caption = 'Last Modified Date-Time';
                }
            }
        }
    }

    /// <summary>
    /// Bound action: marks the entry as processed. Calling it again on a processed entry changes nothing.
    /// </summary>
    /// <param name="ActionContext">The web service action context returned to the caller.</param>
    [ServiceEnabled]
    procedure markProcessed(var ActionContext: WebServiceActionContext)
    var
        IntegrationEventMgt: Codeunit "EQM Integration Event Mgt.";
    begin
        IntegrationEventMgt.MarkProcessed(Rec);
        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"EQM Integration Event API");
        ActionContext.AddEntityKey(Rec.FieldNo(SystemId), Rec.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;
}
