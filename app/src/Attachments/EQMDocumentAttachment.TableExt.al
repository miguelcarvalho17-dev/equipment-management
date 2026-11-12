namespace MiguelCarvalho.EquipmentManagement;

using Microsoft.Foundation.Attachment;

tableextension 50100 "EQM Document Attachment" extends "Document Attachment"
{
    fields
    {
        field(50100; "EQM Attachment Category"; Enum "EQM Attachment Category")
        {
            Caption = 'Category';
            ToolTip = 'Specifies the kind of document, such as a purchase invoice, maintenance report, warranty certificate, user manual or delivery note.';
            DataClassification = CustomerContent;
        }
    }
}
