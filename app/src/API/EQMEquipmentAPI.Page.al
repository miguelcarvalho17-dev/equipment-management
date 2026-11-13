namespace MiguelCarvalho.EquipmentManagement;

page 50123 "EQM Equipment API"
{
    Caption = 'Equipment API';
    PageType = API;
    APIPublisher = 'miguelCarvalho';
    APIGroup = 'equipment';
    APIVersion = 'v1.0';
    EntityName = 'equipment';
    EntitySetName = 'equipments';
    EntityCaption = 'Equipment';
    EntitySetCaption = 'Equipment';
    SourceTable = "EQM Equipment";
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    Extensible = false;

    layout
    {
        area(Content)
        {
            repeater(Records)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'Id';
                    Editable = false;
                }
                field(number; Rec."No.")
                {
                    Caption = 'No.';
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                }
                field(categoryCode; Rec."Category Code")
                {
                    Caption = 'Category Code';
                }
                field(serialNumber; Rec."Serial No.")
                {
                    Caption = 'Serial No.';
                }
                field(manufacturer; Rec.Manufacturer)
                {
                    Caption = 'Manufacturer';
                }
                field(model; Rec.Model)
                {
                    Caption = 'Model';
                }
                field(purchaseDate; Rec."Purchase Date")
                {
                    Caption = 'Purchase Date';
                }
                field(purchaseCost; Rec."Purchase Cost")
                {
                    Caption = 'Purchase Cost';
                }
                field(status; Rec.Status)
                {
                    Caption = 'Status';
                }
                field(assignedEmployeeNumber; Rec."Assigned Employee No.")
                {
                    Caption = 'Assigned Employee No.';
                    Editable = false;
                }
                field(locationCode; Rec."Location Code")
                {
                    Caption = 'Location Code';
                }
                field(warrantyStartDate; Rec."Warranty Start Date")
                {
                    Caption = 'Warranty Start Date';
                }
                field(warrantyEndDate; Rec."Warranty End Date")
                {
                    Caption = 'Warranty End Date';
                }
                field(warrantyProvider; Rec."Warranty Provider")
                {
                    Caption = 'Warranty Provider';
                }
                field(warrantyReferenceNumber; Rec."Warranty Reference No.")
                {
                    Caption = 'Warranty Reference No.';
                }
                field(lastMaintenanceDate; Rec."Last Maintenance Date")
                {
                    Caption = 'Last Maintenance Date';
                }
                field(nextMaintenanceDate; Rec."Next Maintenance Date")
                {
                    Caption = 'Next Maintenance Date';
                    Editable = false;
                }
                field(maintenanceFrequencyMonths; Rec."Maintenance Frequency (Months)")
                {
                    Caption = 'Maintenance Frequency (Months)';
                }
                field(lastModifiedDateTime; Rec.SystemModifiedAt)
                {
                    Caption = 'Last Modified Date-Time';
                    Editable = false;
                }
            }
        }
    }

    /// <summary>
    /// Bound action: assigns the equipment to an employee through the same procedure as the UI.
    /// </summary>
    /// <param name="ActionContext">The web service action context returned to the caller.</param>
    /// <param name="employeeNumber">The number of the employee to assign.</param>
    [ServiceEnabled]
    procedure assign(var ActionContext: WebServiceActionContext; employeeNumber: Code[20])
    begin
        Rec.AssignEmployee(employeeNumber);
        SetUpdatedContext(ActionContext);
    end;

    /// <summary>
    /// Bound action: returns assigned equipment from its employee through the same procedure as the UI.
    /// </summary>
    /// <param name="ActionContext">The web service action context returned to the caller.</param>
    [ServiceEnabled]
    procedure returnEquipment(var ActionContext: WebServiceActionContext)
    begin
        Rec.UnassignEmployee();
        SetUpdatedContext(ActionContext);
    end;

    local procedure SetUpdatedContext(var ActionContext: WebServiceActionContext)
    begin
        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"EQM Equipment API");
        ActionContext.AddEntityKey(Rec.FieldNo(SystemId), Rec.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;
}
