namespace MiguelCarvalho.EquipmentManagement;

using Microsoft.Foundation.Attachment;

/// <summary>
/// Counts and shows the files attached to equipment.
/// </summary>
codeunit 50137 "EQM Equipment Attachment Mgt."
{
    Access = Internal;

    /// <summary>
    /// Returns the number of attached files of the equipment that are not images.
    /// </summary>
    /// <param name="EquipmentNo">The equipment number.</param>
    /// <returns>The number of document attachments, or 0 when the number is blank or the user cannot read attachments.</returns>
    internal procedure CountDocuments(EquipmentNo: Code[20]): Integer
    var
        DocumentAttachment: Record "Document Attachment";
    begin
        if (EquipmentNo = '') or not DocumentAttachment.ReadPermission() then
            exit(0);

        FilterEquipmentAttachments(DocumentAttachment, EquipmentNo);
        DocumentAttachment.SetFilter("File Type", '<>%1', DocumentAttachment."File Type"::Image);
        exit(DocumentAttachment.Count());
    end;

    /// <summary>
    /// Returns the number of attached files of the equipment that are images.
    /// </summary>
    /// <param name="EquipmentNo">The equipment number.</param>
    /// <returns>The number of image attachments, or 0 when the number is blank or the user cannot read attachments.</returns>
    internal procedure CountImages(EquipmentNo: Code[20]): Integer
    var
        DocumentAttachment: Record "Document Attachment";
    begin
        if (EquipmentNo = '') or not DocumentAttachment.ReadPermission() then
            exit(0);

        FilterEquipmentAttachments(DocumentAttachment, EquipmentNo);
        DocumentAttachment.SetRange("File Type", DocumentAttachment."File Type"::Image);
        exit(DocumentAttachment.Count());
    end;

    /// <summary>
    /// Opens the attachments of the equipment so the user can view, add and categorize files.
    /// </summary>
    /// <param name="EquipmentNo">The equipment number.</param>
    internal procedure ShowAttachments(EquipmentNo: Code[20])
    var
        Equipment: Record "EQM Equipment";
        DocumentAttachmentDetails: Page "Document Attachment Details";
        RecRef: RecordRef;
    begin
        if EquipmentNo = '' then
            exit;
        if not Equipment.Get(EquipmentNo) then
            exit;

        RecRef.GetTable(Equipment);
        DocumentAttachmentDetails.OpenForRecRef(RecRef);
        DocumentAttachmentDetails.RunModal();
    end;

    local procedure FilterEquipmentAttachments(var DocumentAttachment: Record "Document Attachment"; EquipmentNo: Code[20])
    begin
        DocumentAttachment.Reset();
        DocumentAttachment.SetRange("Table ID", Database::"EQM Equipment");
        DocumentAttachment.SetRange("No.", EquipmentNo);
    end;
}
