namespace MiguelCarvalho.EquipmentManagement;

page 50139 "EQM Attachment Count FactBox"
{
    Caption = 'Attachment Summary';
    PageType = CardPart;
    ApplicationArea = All;
    SourceTable = "EQM Equipment";
    Editable = false;

    layout
    {
        area(Content)
        {
            field(NoOfDocuments; NoOfDocuments)
            {
                Caption = 'Document Count';
                ToolTip = 'Specifies how many of the files attached to the equipment are documents, such as PDF, Word or Excel files. Images are counted separately. Choose the number to see the attachments.';

                trigger OnDrillDown()
                var
                    AttachmentMgt: Codeunit "EQM Equipment Attachment Mgt.";
                begin
                    AttachmentMgt.ShowAttachments(Rec."No.");
                    CurrPage.Update(false);
                end;
            }
            field(NoOfImages; NoOfImages)
            {
                Caption = 'Image Count';
                ToolTip = 'Specifies how many of the files attached to the equipment are images, such as JPG or PNG files. The equipment picture is not included. Choose the number to see the attachments.';

                trigger OnDrillDown()
                var
                    AttachmentMgt: Codeunit "EQM Equipment Attachment Mgt.";
                begin
                    AttachmentMgt.ShowAttachments(Rec."No.");
                    CurrPage.Update(false);
                end;
            }
        }
    }

    var
        NoOfDocuments: Integer;
        NoOfImages: Integer;

    trigger OnAfterGetRecord()
    var
        AttachmentMgt: Codeunit "EQM Equipment Attachment Mgt.";
    begin
        NoOfDocuments := 0;
        NoOfImages := 0;
        if Rec."No." <> '' then begin
            NoOfDocuments := AttachmentMgt.CountDocuments(Rec."No.");
            NoOfImages := AttachmentMgt.CountImages(Rec."No.");
        end;
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        NoOfDocuments := 0;
        NoOfImages := 0;
        exit(Rec.Find(Which));
    end;
}
