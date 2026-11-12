namespace MiguelCarvalho.EquipmentManagement;

using Microsoft.Foundation.Attachment;

pageextension 50101 "EQM Doc. Attachment Details" extends "Document Attachment Details"
{
    layout
    {
        addafter(Name)
        {
            field("EQM Attachment Category"; Rec."EQM Attachment Category")
            {
                ApplicationArea = All;
                Visible = EQMIsEquipmentView;
            }
        }
    }

    var
        EQMIsEquipmentView: Boolean;

    trigger OnOpenPage()
    var
        DocAttachmentSubscr: Codeunit "EQM Doc. Attachment Subscr.";
    begin
        EQMIsEquipmentView := DocAttachmentSubscr.IsEquipmentAttachmentView(Rec);
    end;
}
