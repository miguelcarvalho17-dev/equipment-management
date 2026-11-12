namespace MiguelCarvalho.EquipmentManagement.Tests;

using MiguelCarvalho.EquipmentManagement;
using System.TestLibraries.Security.AccessControl;
using System.TestLibraries.Utilities;
using System.Text;
using System.Utilities;

codeunit 50179 "EQM Picture Permission Tests"
{
    Subtype = Test;
    TestPermissions = Restrictive;

    var
        Assert: Codeunit "Library Assert";
        PermissionsMock: Codeunit "Permissions Mock";
        PictureMgt: Codeunit "EQM Equipment Picture Mgt.";
        PngBase64Txt: Label 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==', Locked = true;
        EquipmentNoTok: Label 'LT001', Locked = true;
        CategoryCodeTok: Label 'LAPTOP', Locked = true;
        FileNameATok: Label 'a.png', Locked = true;
        PermissionErr: Label 'Sorry, the current permissions prevented the action', Locked = true;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReaderCannotChangePictureButCanExport()
    var
        Equipment: Record "EQM Equipment";
        EquipmentCard: TestPage "EQM Equipment Card";
    begin
        // [SCENARIO 10] A Reader sees Export enabled and Import, Take and Delete disabled
        // [GIVEN] Equipment E with a picture, and the user lowered to the EQM - Reader permission set
        CreateEquipment(Equipment);
        SetPicture(Equipment, FileNameATok);
        PermissionsMock.Set('EQM - Reader');
        PermissionsMock.Start();

        // [WHEN] The card is opened
        EquipmentCard.OpenView();
        EquipmentCard.GoToRecord(Equipment);

        // [THEN] Only Export is enabled
        Assert.IsTrue(EquipmentCard.Picture.ExportFile.Enabled(), 'Export should work for a Reader');
        Assert.IsFalse(EquipmentCard.Picture.ImportPicture.Enabled(), 'Import should be disabled for a Reader');
        Assert.IsFalse(EquipmentCard.Picture.TakePicture.Enabled(), 'Take should be disabled for a Reader');
        Assert.IsFalse(EquipmentCard.Picture.DeletePicture.Enabled(), 'Delete should be disabled for a Reader');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReaderSetPictureIsRejected()
    var
        Equipment: Record "EQM Equipment";
    begin
        // [SCENARIO 10b] (negative) A direct SetPicture as Reader raises a permission error
        // [GIVEN] Equipment E, and the user lowered to the EQM - Reader permission set
        CreateEquipment(Equipment);
        PermissionsMock.Set('EQM - Reader');
        PermissionsMock.Start();

        // [WHEN] A picture is set
        asserterror SetPicture(Equipment, FileNameATok);

        // [THEN] A permission error is raised and the picture is not stored
        Assert.ExpectedError(PermissionErr);
        PermissionsMock.Stop();
        Equipment.Get(EquipmentNoTok);
        Assert.AreEqual(0, Equipment.Picture.Count(), 'No picture should be stored for a Reader');
    end;

    local procedure CreateEquipment(var Equipment: Record "EQM Equipment")
    var
        Category: Record "EQM Equipment Category";
    begin
        Category.Init();
        Category.Code := CategoryCodeTok;
        Category.Active := true;
        if not Category.Insert() then
            Category.Modify();

        Equipment.Init();
        Equipment."No." := EquipmentNoTok;
        Equipment.Description := 'Test laptop';
        Equipment."Category Code" := CategoryCodeTok;
        Equipment.Insert(true);
    end;

    local procedure SetPicture(var Equipment: Record "EQM Equipment"; FileName: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        Base64Convert: Codeunit "Base64 Convert";
        PictureOutStream: OutStream;
        PictureInStream: InStream;
    begin
        TempBlob.CreateOutStream(PictureOutStream);
        Base64Convert.FromBase64(PngBase64Txt, PictureOutStream);
        TempBlob.CreateInStream(PictureInStream);
        PictureMgt.SetPicture(Equipment, PictureInStream, FileName);
    end;
}
