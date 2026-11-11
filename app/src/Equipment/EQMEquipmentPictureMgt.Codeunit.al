namespace MiguelCarvalho.EquipmentManagement;

using System.Device;
using System.Environment;
using System.Utilities;

codeunit 50117 "EQM Equipment Picture Mgt."
{
    Access = Internal;

    var
        SaveEquipmentFirstErr: Label 'Save the equipment before you add a picture.';
        UnsupportedFileErr: Label 'The file %1 is not a supported picture. Choose a JPG, PNG, GIF, BMP or TIFF file.', Comment = '%1 = file name';
        NoPictureErr: Label 'Equipment %1 has no picture to export.', Comment = '%1 = equipment number';
        OverrideImageQst: Label 'The existing picture will be replaced. Do you want to continue?';
        DeleteImageQst: Label 'Are you sure you want to delete the picture?';
        SelectPictureTitleTxt: Label 'Select a picture to upload';
        PictureFilterTxt: Label 'Image files|*.jpg;*.jpeg;*.png;*.gif;*.bmp;*.tif;*.tiff', Locked = true;
        DefaultFileNameTxt: Label '%1.jpg', Locked = true, Comment = '%1 = equipment number';

    /// <summary>
    /// Replaces the picture of the equipment with the picture in the stream. Never adds a second picture.
    /// </summary>
    /// <param name="Equipment">The saved equipment record.</param>
    /// <param name="PictureInStream">The picture content.</param>
    /// <param name="FileName">The name of the picture file.</param>
    internal procedure SetPicture(var Equipment: Record "EQM Equipment"; PictureInStream: InStream; FileName: Text)
    begin
        CheckSaved(Equipment);
        Clear(Equipment.Picture);
        Equipment.Picture.ImportStream(PictureInStream, FileName);
        Equipment.Modify(true);
    end;

    /// <summary>
    /// Asks for confirmation when the equipment already has a picture.
    /// </summary>
    /// <param name="Equipment">The equipment record.</param>
    /// <returns>True when there is no picture or the user confirmed the replacement.</returns>
    internal procedure ConfirmReplace(Equipment: Record "EQM Equipment"): Boolean
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if Equipment.Picture.Count() = 0 then
            exit(true);
        exit(ConfirmManagement.GetResponseOrDefault(OverrideImageQst, false));
    end;

    /// <summary>
    /// Lets the user upload a picture file and replaces the picture of the equipment.
    /// </summary>
    /// <param name="Equipment">The saved equipment record.</param>
    /// <returns>True when the picture was replaced.</returns>
    internal procedure ImportPictureFromFile(var Equipment: Record "EQM Equipment"): Boolean
    var
        PictureInStream: InStream;
        FileName: Text;
    begin
        CheckSaved(Equipment);
        if not ConfirmReplace(Equipment) then
            exit(false);
        if not UploadIntoStream(SelectPictureTitleTxt, '', PictureFilterTxt, FileName, PictureInStream) then
            exit(false);
        if not IsSupportedExtension(FileName) then
            Error(UnsupportedFileErr, FileName);
        SetPicture(Equipment, PictureInStream, FileName);
        exit(true);
    end;

    /// <summary>
    /// Takes a picture with the device camera and replaces the picture of the equipment.
    /// </summary>
    /// <param name="Equipment">The saved equipment record.</param>
    /// <returns>True when the picture was replaced.</returns>
    internal procedure TakePicture(var Equipment: Record "EQM Equipment"): Boolean
    var
        Camera: Codeunit Camera;
        PictureInStream: InStream;
        PictureName: Text;
    begin
        CheckSaved(Equipment);
        if not ConfirmReplace(Equipment) then
            exit(false);
        if not Camera.GetPicture(PictureInStream, PictureName) then
            exit(false);
        if PictureName = '' then
            PictureName := StrSubstNo(DefaultFileNameTxt, Equipment."No.");
        SetPicture(Equipment, PictureInStream, PictureName);
        exit(true);
    end;

    /// <summary>
    /// Downloads the picture of the equipment as a file.
    /// </summary>
    /// <param name="Equipment">The equipment record.</param>
    internal procedure ExportPicture(Equipment: Record "EQM Equipment")
    var
        TenantMedia: Record "Tenant Media";
        PictureInStream: InStream;
        FileName: Text;
    begin
        if Equipment.Picture.Count() = 0 then
            Error(NoPictureErr, Equipment."No.");
        if not TenantMedia.Get(Equipment.Picture.Item(1)) then
            Error(NoPictureErr, Equipment."No.");
        TenantMedia.CalcFields(Content);
        if not TenantMedia.Content.HasValue() then
            Error(NoPictureErr, Equipment."No.");
        FileName := TenantMedia.Description;
        if FileName = '' then
            FileName := StrSubstNo(DefaultFileNameTxt, Equipment."No.");
        TenantMedia.Content.CreateInStream(PictureInStream);
        DownloadFromStream(PictureInStream, '', '', '', FileName);
    end;

    /// <summary>
    /// Deletes the picture of the equipment after confirmation.
    /// </summary>
    /// <param name="Equipment">The saved equipment record.</param>
    /// <returns>True when the picture was deleted.</returns>
    internal procedure DeletePicture(var Equipment: Record "EQM Equipment"): Boolean
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if Equipment.Picture.Count() = 0 then
            exit(false);
        if not ConfirmManagement.GetResponseOrDefault(DeleteImageQst, false) then
            exit(false);
        Clear(Equipment.Picture);
        Equipment.Modify(true);
        exit(true);
    end;

    local procedure CheckSaved(var Equipment: Record "EQM Equipment")
    begin
        if Equipment."No." = '' then
            Error(SaveEquipmentFirstErr);
        if not Equipment.Find() then
            Error(SaveEquipmentFirstErr);
    end;

    local procedure IsSupportedExtension(FileName: Text): Boolean
    var
        Extension: Text;
        Position: Integer;
    begin
        Position := StrLen(FileName);
        while (Position > 0) and (FileName[Position] <> '.') do
            Position -= 1;
        if Position = 0 then
            exit(false);
        Extension := LowerCase(CopyStr(FileName, Position + 1));
        exit(Extension in ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'tif', 'tiff']);
    end;
}
