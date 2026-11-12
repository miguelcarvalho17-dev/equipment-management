namespace MiguelCarvalho.EquipmentManagement;

using Microsoft.Foundation.Attachment;

codeunit 50118 "EQM Doc. Attachment Subscr."
{
    Access = Internal;

    /// <summary>
    /// Tells the Document Attachment framework that equipment is identified by its "No." field.
    /// </summary>
    /// <param name="TableNo">The table the framework is asking about.</param>
    /// <param name="Result">Set to true for the equipment table.</param>
    /// <param name="FieldNo">Set to the field number of "No." for the equipment table.</param>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document Attachment Mgmt", 'OnAfterTableHasNumberFieldPrimaryKey', '', false, false)]
    local procedure OnAfterTableHasNumberFieldPrimaryKey(TableNo: Integer; var Result: Boolean; var FieldNo: Integer)
    var
        Equipment: Record "EQM Equipment";
    begin
        if TableNo <> Database::"EQM Equipment" then
            exit;

        Result := true;
        FieldNo := Equipment.FieldNo("No.");
    end;

    /// <summary>
    /// Opens the record the attachment belongs to when the attachment belongs to equipment.
    /// The record stays unpositioned when the equipment no longer exists.
    /// </summary>
    /// <param name="RecRef">The record reference to open and position.</param>
    /// <param name="DocumentAttachment">The attachment being resolved.</param>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document Attachment Mgmt", 'OnAfterGetRefTable', '', false, false)]
    local procedure OnAfterGetRefTable(var RecRef: RecordRef; DocumentAttachment: Record "Document Attachment")
    var
        Equipment: Record "EQM Equipment";
    begin
        if DocumentAttachment."Table ID" <> Database::"EQM Equipment" then
            exit;
        if RecRef.Number <> 0 then
            exit;

        RecRef.Open(Database::"EQM Equipment");
        if Equipment.Get(DocumentAttachment."No.") then
            RecRef.GetTable(Equipment);
    end;

    /// <summary>
    /// Checks whether the attachments are filtered on the equipment table, in filter group 0, 2 or 4.
    /// The original filter group is restored.
    /// </summary>
    /// <param name="DocumentAttachment">The attachment record with the page filters.</param>
    /// <returns>True if the "Table ID" filter is the equipment table.</returns>
    internal procedure IsEquipmentAttachmentView(var DocumentAttachment: Record "Document Attachment"): Boolean
    var
        OriginalFilterGroup: Integer;
        IsEquipmentView: Boolean;
    begin
        OriginalFilterGroup := DocumentAttachment.FilterGroup();
        IsEquipmentView :=
            HasEquipmentTableFilter(DocumentAttachment, 0) or
            HasEquipmentTableFilter(DocumentAttachment, 2) or
            HasEquipmentTableFilter(DocumentAttachment, 4);
        DocumentAttachment.FilterGroup(OriginalFilterGroup);
        exit(IsEquipmentView);
    end;

    local procedure HasEquipmentTableFilter(var DocumentAttachment: Record "Document Attachment"; FilterGroupNo: Integer): Boolean
    var
        TableId: Integer;
    begin
        DocumentAttachment.FilterGroup(FilterGroupNo);
        if Evaluate(TableId, DocumentAttachment.GetFilter("Table ID")) then
            exit(TableId = Database::"EQM Equipment");
        exit(false);
    end;
}
