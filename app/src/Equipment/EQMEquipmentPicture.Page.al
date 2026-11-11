namespace MiguelCarvalho.EquipmentManagement;

using System.Device;

page 50122 "EQM Equipment Picture"
{
    Caption = 'Picture';
    PageType = CardPart;
    ApplicationArea = All;
    SourceTable = "EQM Equipment";
    InsertAllowed = false;
    DeleteAllowed = false;
    LinksAllowed = false;

    layout
    {
        area(Content)
        {
            field(Picture; Rec.Picture)
            {
                ShowCaption = false;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(TakePicture)
            {
                Caption = 'Take';
                ToolTip = 'Activate the camera on the device to take a picture of the equipment.';
                Image = Camera;
                Visible = CameraAvailable;
                Enabled = CanEditPicture;

                trigger OnAction()
                var
                    PictureMgt: Codeunit "EQM Equipment Picture Mgt.";
                begin
                    if PictureMgt.TakePicture(Rec) then
                        CurrPage.Update(false);
                end;
            }
            action(ImportPicture)
            {
                Caption = 'Import';
                ToolTip = 'Import a picture file for the equipment. An existing picture is replaced after you confirm.';
                Image = Import;
                Enabled = CanEditPicture;

                trigger OnAction()
                var
                    PictureMgt: Codeunit "EQM Equipment Picture Mgt.";
                begin
                    if PictureMgt.ImportPictureFromFile(Rec) then
                        CurrPage.Update(false);
                end;
            }
            action(ExportFile)
            {
                Caption = 'Export';
                ToolTip = 'Export the picture of the equipment to a file.';
                Image = Export;
                Enabled = HasPicture;

                trigger OnAction()
                var
                    PictureMgt: Codeunit "EQM Equipment Picture Mgt.";
                begin
                    PictureMgt.ExportPicture(Rec);
                end;
            }
            action(DeletePicture)
            {
                Caption = 'Delete';
                ToolTip = 'Delete the picture of the equipment.';
                Image = Delete;
                Enabled = CanDeletePicture;

                trigger OnAction()
                var
                    PictureMgt: Codeunit "EQM Equipment Picture Mgt.";
                begin
                    if PictureMgt.DeletePicture(Rec) then
                        CurrPage.Update(false);
                end;
            }
        }
    }

    var
        CameraAvailable: Boolean;
        CanEditPicture: Boolean;
        CanDeletePicture: Boolean;
        HasPicture: Boolean;

    trigger OnOpenPage()
    var
        Camera: Codeunit Camera;
    begin
        CameraAvailable := Camera.IsAvailable();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        HasPicture := Rec.Picture.Count() > 0;
        CanEditPicture := Rec.WritePermission();
        CanDeletePicture := CanEditPicture and HasPicture;
    end;
}
