namespace MiguelCarvalho.EquipmentManagement.Tests;

using MiguelCarvalho.EquipmentManagement;
using System.Environment;
using System.Text;
using System.TestLibraries.Security.AccessControl;
using System.TestLibraries.Utilities;
using System.Utilities;

codeunit 50178 "EQM Equipment Picture Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        PermissionsMock: Codeunit "Permissions Mock";
        PictureMgt: Codeunit "EQM Equipment Picture Mgt.";
        ConfirmReply: Boolean;
        ConfirmCount: Integer;
        PngBase64Txt: Label 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==', Locked = true;
        EquipmentNoTok: Label 'LT001', Locked = true;
        CategoryCodeTok: Label 'LAPTOP', Locked = true;
        FileNameATok: Label 'a.png', Locked = true;
        FileNameBTok: Label 'b.png', Locked = true;
        // Copies of the text of the internal labels of codeunit 50117; labels of another app are not accessible.
        SaveEquipmentFirstErr: Label 'Save the equipment before you add a picture.';
        NoPictureErr: Label 'Equipment %1 has no picture to export.', Comment = '%1 = equipment number';
        PermissionErr: Label 'Sorry, the current permissions prevented the action', Locked = true;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SetPictureOnEquipmentWithoutPicture()
    var
        Equipment: Record "EQM Equipment";
        ModifiedAtBefore: DateTime;
    begin
        // [SCENARIO 1] Setting a picture on equipment without one stores exactly one picture and modifies the record
        // [GIVEN] Saved equipment E without a picture
        CreateEquipment(Equipment);
        Assert.AreEqual(0, Equipment.Picture.Count(), 'New equipment should have no picture');
        ModifiedAtBefore := Equipment.SystemModifiedAt;

        // [WHEN] A picture is set
        SetPicture(Equipment, FileNameATok);

        // [THEN] The stored record has one picture and was modified
        Equipment.Get(EquipmentNoTok);
        Assert.AreEqual(1, Equipment.Picture.Count(), 'Equipment should have exactly one picture');
        Assert.IsTrue(Equipment.SystemModifiedAt >= ModifiedAtBefore, 'SystemModifiedAt should not go backwards after setting the picture');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SetPictureReplacesExistingPicture()
    var
        Equipment: Record "EQM Equipment";
        TenantMedia: Record "Tenant Media";
        MediaIdA: Guid;
    begin
        // [SCENARIO 2] Setting a second picture replaces the first one and never adds
        // [GIVEN] Equipment E with picture A
        CreateEquipment(Equipment);
        SetPicture(Equipment, FileNameATok);
        MediaIdA := Equipment.Picture.Item(1);

        // [WHEN] Picture B is set
        SetPicture(Equipment, FileNameBTok);

        // [THEN] E has one picture, and it is B, not A
        Equipment.Get(EquipmentNoTok);
        Assert.AreEqual(1, Equipment.Picture.Count(), 'Setting a picture again should replace, not add');
        Assert.AreNotEqual(MediaIdA, Equipment.Picture.Item(1), 'The stored picture should be a new media record');
        TenantMedia.Get(Equipment.Picture.Item(1));
        Assert.AreEqual(FileNameBTok, TenantMedia.Description, 'The stored media should be picture B');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('ConfirmHandler')]
    procedure ReplaceAnsweredNoKeepsPicture()
    var
        Equipment: Record "EQM Equipment";
        MediaIdBefore: Guid;
    begin
        // [SCENARIO 3] Answering No to the replace confirmation leaves the picture unchanged
        // [GIVEN] Equipment E with a picture and the confirmation answered No
        CreateEquipment(Equipment);
        SetPicture(Equipment, FileNameATok);
        MediaIdBefore := Equipment.Picture.Item(1);
        ConfirmReply := false;
        ConfirmCount := 0;

        // [WHEN] Import and Take are started
        // [THEN] Both return false after asking once each, and the picture is unchanged
        Assert.IsFalse(PictureMgt.ImportPictureFromFile(Equipment), 'Import should stop when replace is declined');
        Assert.IsFalse(PictureMgt.TakePicture(Equipment), 'Take should stop when replace is declined');
        Assert.AreEqual(2, ConfirmCount, 'Each action should ask the replace confirmation once');
        Equipment.Get(EquipmentNoTok);
        Assert.AreEqual(1, Equipment.Picture.Count(), 'Picture count should be unchanged');
        Assert.AreEqual(MediaIdBefore, Equipment.Picture.Item(1), 'The picture should be unchanged');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NoReplaceConfirmationWithoutPicture()
    var
        Equipment: Record "EQM Equipment";
    begin
        // [SCENARIO 3b] Equipment without a picture does not ask for replace confirmation
        // [GIVEN] Equipment E without a picture (no confirm handler: an unexpected confirmation fails the test)
        CreateEquipment(Equipment);

        // [WHEN] The replace confirmation is evaluated
        // [THEN] It passes without asking
        Assert.IsTrue(PictureMgt.ConfirmReplace(Equipment), 'No confirmation is needed when there is no picture');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('ConfirmHandler')]
    procedure ReplaceConfirmationAskedWithPicture()
    var
        Equipment: Record "EQM Equipment";
    begin
        // [SCENARIO 3c] Equipment with a picture asks and honors the answer (boundary of 3)
        // [GIVEN] Equipment E with a picture, confirmation answered Yes
        CreateEquipment(Equipment);
        SetPicture(Equipment, FileNameATok);
        ConfirmReply := true;
        ConfirmCount := 0;

        // [WHEN] The replace confirmation is evaluated
        // [THEN] It asks once and returns true
        Assert.IsTrue(PictureMgt.ConfirmReplace(Equipment), 'Confirmed replace should return true');
        Assert.AreEqual(1, ConfirmCount, 'The replace confirmation should be asked once');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SetPictureRequiresSavedEquipment()
    var
        Equipment: Record "EQM Equipment";
    begin
        // [SCENARIO 4] Setting a picture on unsaved equipment or a blank number is rejected
        // [GIVEN] Equipment with a blank No.
        Equipment.Init();

        // [WHEN] A picture is set
        asserterror SetPicture(Equipment, FileNameATok);

        // [THEN] The save-first error is raised
        Assert.ExpectedError(SaveEquipmentFirstErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SetPictureRejectsNumberThatIsNotSaved()
    var
        Equipment: Record "EQM Equipment";
    begin
        // [SCENARIO 4b] A filled but not yet inserted No. is also rejected
        // [GIVEN] Equipment record with a No. that does not exist in the database
        Equipment.Init();
        Equipment."No." := EquipmentNoTok;

        // [WHEN] A picture is set
        asserterror SetPicture(Equipment, FileNameATok);

        // [THEN] The save-first error is raised
        Assert.ExpectedError(SaveEquipmentFirstErr);
        Assert.IsFalse(Equipment.Get(EquipmentNoTok), 'The equipment must not be inserted by SetPicture');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('ConfirmHandler')]
    procedure DeletePictureConfirmedRemovesPicture()
    var
        Equipment: Record "EQM Equipment";
    begin
        // [SCENARIO 6] Delete confirmed removes the picture
        // [GIVEN] Equipment E with a picture
        CreateEquipment(Equipment);
        SetPicture(Equipment, FileNameATok);
        ConfirmReply := true;
        ConfirmCount := 0;

        // [WHEN] Delete is confirmed
        // [THEN] It returns true and E has no picture
        Assert.IsTrue(PictureMgt.DeletePicture(Equipment), 'Delete should return true when confirmed');
        Equipment.Get(EquipmentNoTok);
        Assert.AreEqual(0, Equipment.Picture.Count(), 'Picture should be gone after confirmed delete');
        Assert.AreEqual(1, ConfirmCount, 'Delete should ask once');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('ConfirmHandler')]
    procedure DeletePictureDeclinedKeepsPicture()
    var
        Equipment: Record "EQM Equipment";
    begin
        // [SCENARIO 6b] Delete answered No leaves the picture
        // [GIVEN] Equipment E with a picture
        CreateEquipment(Equipment);
        SetPicture(Equipment, FileNameATok);
        ConfirmReply := false;
        ConfirmCount := 0;

        // [WHEN] Delete is declined
        // [THEN] It returns false and the picture remains
        Assert.IsFalse(PictureMgt.DeletePicture(Equipment), 'Delete should return false when declined');
        Equipment.Get(EquipmentNoTok);
        Assert.AreEqual(1, Equipment.Picture.Count(), 'Picture should remain after declined delete');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DeletePictureWithoutPictureAsksNothing()
    var
        Equipment: Record "EQM Equipment";
    begin
        // [SCENARIO 6c] Delete on equipment without a picture returns false and asks nothing
        // [GIVEN] Equipment E without a picture (no confirm handler: any confirmation fails the test)
        CreateEquipment(Equipment);

        // [WHEN] Delete is run
        // [THEN] It returns false
        Assert.IsFalse(PictureMgt.DeletePicture(Equipment), 'Delete should return false when there is no picture');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ExportWithoutPictureRaisesError()
    var
        Equipment: Record "EQM Equipment";
    begin
        // [SCENARIO 7] Export on equipment without a picture is rejected
        // [GIVEN] Equipment E without a picture
        CreateEquipment(Equipment);

        // [WHEN] Export is run
        asserterror PictureMgt.ExportPicture(Equipment);

        // [THEN] The no-picture error names the equipment
        Assert.ExpectedError(StrSubstNo(NoPictureErr, EquipmentNoTok));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DeletingEquipmentRemovesItsPictureMedia()
    var
        Equipment: Record "EQM Equipment";
        TenantMedia: Record "Tenant Media";
        MediaId: Guid;
    begin
        // [SCENARIO 8] Deleting equipment removes its Tenant Media rows (plan verification V2)
        // [GIVEN] Equipment E with a picture, no history, no maintenance
        CreateEquipment(Equipment);
        SetPicture(Equipment, FileNameATok);
        MediaId := Equipment.Picture.Item(1);
        Assert.IsTrue(TenantMedia.Get(MediaId), 'The picture media should exist before the delete');

        // [WHEN] The equipment is deleted
        Equipment.Delete(true);

        // [THEN] The media row is gone
        Assert.IsFalse(TenantMedia.Get(MediaId), 'The picture media should be removed with the equipment');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('ConfirmHandler')]
    procedure ClearingPictureRemovesItsMedia()
    var
        Equipment: Record "EQM Equipment";
        TenantMedia: Record "Tenant Media";
        MediaId: Guid;
    begin
        // [SCENARIO 6d] A confirmed delete leaves no orphan Tenant Media row (plan verification V2)
        // [GIVEN] Equipment E with a picture
        CreateEquipment(Equipment);
        SetPicture(Equipment, FileNameATok);
        MediaId := Equipment.Picture.Item(1);
        ConfirmReply := true;

        // [WHEN] The picture is deleted and confirmed
        PictureMgt.DeletePicture(Equipment);

        // [THEN] The media row is gone
        Assert.IsFalse(TenantMedia.Get(MediaId), 'The picture media should be removed when the picture is deleted');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PictureFactBoxOnCardFollowsPictureState()
    var
        Equipment: Record "EQM Equipment";
        EquipmentCard: TestPage "EQM Equipment Card";
    begin
        // [SCENARIO 9] The Card shows the Picture FactBox; Export is enabled only with a picture
        // [GIVEN] Equipment E without a picture
        CreateEquipment(Equipment);

        // [WHEN] The card is opened
        EquipmentCard.OpenView();
        EquipmentCard.GoToRecord(Equipment);

        // [THEN] Export is disabled; Import is enabled for a Manager
        Assert.IsFalse(EquipmentCard.Picture.ExportFile.Enabled(), 'Export should be disabled without a picture');
        Assert.IsFalse(EquipmentCard.Picture.DeletePicture.Enabled(), 'Delete should be disabled without a picture');
        Assert.IsTrue(EquipmentCard.Picture.ImportPicture.Enabled(), 'Import should be enabled for a user who can edit');
        EquipmentCard.Close();

        // [GIVEN] E now has a picture
        SetPicture(Equipment, FileNameATok);

        // [WHEN] The card is opened again
        EquipmentCard.OpenView();
        EquipmentCard.GoToRecord(Equipment);

        // [THEN] Export and Delete are enabled
        Assert.IsTrue(EquipmentCard.Picture.ExportFile.Enabled(), 'Export should be enabled with a picture');
        Assert.IsTrue(EquipmentCard.Picture.DeletePicture.Enabled(), 'Delete should be enabled with a picture');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PictureFactBoxOnListFollowsPictureState()
    var
        Equipment: Record "EQM Equipment";
        EquipmentList: TestPage "EQM Equipment List";
    begin
        // [SCENARIO 9b] The List shows the Picture FactBox; Export is enabled only with a picture
        // [GIVEN] Equipment E without a picture
        CreateEquipment(Equipment);

        // [WHEN] The list is opened on E
        EquipmentList.OpenView();
        EquipmentList.GoToRecord(Equipment);

        // [THEN] Export is disabled
        Assert.IsFalse(EquipmentList.Picture.ExportFile.Enabled(), 'Export should be disabled without a picture');
        EquipmentList.Close();

        // [GIVEN] E now has a picture
        SetPicture(Equipment, FileNameATok);

        // [WHEN] The list is opened on E again
        EquipmentList.OpenView();
        EquipmentList.GoToRecord(Equipment);

        // [THEN] Export is enabled
        Assert.IsTrue(EquipmentList.Picture.ExportFile.Enabled(), 'Export should be enabled with a picture');
    end;

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

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        ConfirmCount += 1;
        Reply := ConfirmReply;
    end;
}
