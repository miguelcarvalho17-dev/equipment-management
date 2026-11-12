namespace MiguelCarvalho.EquipmentManagement.Tests;

using Microsoft.Foundation.Attachment;
using Microsoft.Sales.Customer;
using MiguelCarvalho.EquipmentManagement;
using System.TestLibraries.Utilities;
using System.Utilities;

codeunit 50179 "EQM Doc. Attachment Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        EquipmentNoTok: Label 'LT001', Locked = true;
        EquipmentNo2Tok: Label 'LT002', Locked = true;
        RenamedNoTok: Label 'LT009', Locked = true;
        CustomerNoTok: Label 'EQMCUST1', Locked = true;
        EmployeeNoTok: Label 'EQMEMP1', Locked = true;
        CategoryCodeTok: Label 'LAPTOP', Locked = true;
        FileNameTok: Label 'file%1.txt', Locked = true;
        // Copy of the text of the label in table 50100; labels of another app are not accessible.
        DeleteAssignedErr: Label 'You cannot delete equipment %1 because it is assigned to employee %2. Return the equipment first.', Comment = '%1 = equipment number, %2 = employee number';
        CategoryVisibleOnPage: Boolean;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SavedAttachmentIsLinkedToEquipmentWithCategoryOther()
    var
        Equipment: Record "EQM Equipment";
        DocumentAttachment: Record "Document Attachment";
    begin
        // [SCENARIO 1] A file saved for equipment is stored with the equipment table and number, category Other
        // [GIVEN] Saved equipment E
        CreateEquipment(Equipment, EquipmentNoTok);

        // [WHEN] A file is saved as attachment for E
        AttachFile(Equipment, 1);

        // [THEN] One row exists for table 50100 and E, with category Other
        FilterAttachments(DocumentAttachment, Database::"EQM Equipment", EquipmentNoTok);
        Assert.RecordCount(DocumentAttachment, 1);
        DocumentAttachment.FindFirst();
        Assert.AreEqual(EquipmentNoTok, DocumentAttachment."No.", 'The attachment should carry the equipment number');
        Assert.AreEqual("EQM Attachment Category"::Other, DocumentAttachment."EQM Attachment Category", 'A new attachment should default to category Other');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AttachmentsAreSeparatedPerEquipment()
    var
        Equipment: Record "EQM Equipment";
        Equipment2: Record "EQM Equipment";
        DocumentAttachment: Record "Document Attachment";
        Index: Integer;
    begin
        // [SCENARIO 2] Several files can be attached to one equipment and are not visible on another
        // [GIVEN] Saved equipment E and E2
        CreateEquipment(Equipment, EquipmentNoTok);
        CreateEquipment(Equipment2, EquipmentNo2Tok);

        // [WHEN] Three files are attached to E
        for Index := 1 to 3 do
            AttachFile(Equipment, Index);

        // [THEN] E has 3 attachments and E2 has none
        FilterAttachments(DocumentAttachment, Database::"EQM Equipment", EquipmentNoTok);
        Assert.RecordCount(DocumentAttachment, 3);
        FilterAttachments(DocumentAttachment, Database::"EQM Equipment", EquipmentNo2Tok);
        Assert.RecordIsEmpty(DocumentAttachment);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CategoryCanBeChangedAndReadBack()
    var
        Equipment: Record "EQM Equipment";
        DocumentAttachment: Record "Document Attachment";
    begin
        // [SCENARIO 3] The category of an attachment can be set and is stored
        // [GIVEN] An attachment of E
        CreateEquipment(Equipment, EquipmentNoTok);
        AttachFile(Equipment, 1);
        FilterAttachments(DocumentAttachment, Database::"EQM Equipment", EquipmentNoTok);
        DocumentAttachment.FindFirst();

        // [WHEN] The category is set to Warranty Certificate and the row is modified
        DocumentAttachment."EQM Attachment Category" := "EQM Attachment Category"::"Warranty Certificate";
        DocumentAttachment.Modify(true);

        // [THEN] It reads back Warranty Certificate
        Clear(DocumentAttachment);
        FilterAttachments(DocumentAttachment, Database::"EQM Equipment", EquipmentNoTok);
        DocumentAttachment.FindFirst();
        Assert.AreEqual("EQM Attachment Category"::"Warranty Certificate", DocumentAttachment."EQM Attachment Category", 'The category should be stored');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DeletingEquipmentRemovesItsAttachments()
    var
        Equipment: Record "EQM Equipment";
        DocumentAttachment: Record "Document Attachment";
    begin
        // [SCENARIO 4] Deleting equipment removes its attachments
        // [GIVEN] Equipment E with 2 attachments, no history
        CreateEquipment(Equipment, EquipmentNoTok);
        AttachFile(Equipment, 1);
        AttachFile(Equipment, 2);
        FilterAttachments(DocumentAttachment, Database::"EQM Equipment", EquipmentNoTok);
        Assert.RecordCount(DocumentAttachment, 2);

        // [WHEN] E is deleted
        Equipment.Delete(true);

        // [THEN] No attachment rows remain for table 50100 and LT001
        Assert.RecordIsEmpty(DocumentAttachment);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DeletingAssignedEquipmentIsRejected()
    var
        Equipment: Record "EQM Equipment";
    begin
        // [SCENARIO 5] (negative) Assigned equipment cannot be deleted
        // The attachments are kept because the error is raised before DeleteAttachedDocuments and
        // the failed delete is rolled back. A test cannot assert the row count afterwards: asserterror
        // rolls back the test's own setup writes too.
        // [GIVEN] Assigned equipment E with 2 attachments
        CreateEquipment(Equipment, EquipmentNoTok);
        AttachFile(Equipment, 1);
        AttachFile(Equipment, 2);
        MarkAssigned(Equipment);

        // [WHEN] Delete is attempted
        asserterror Equipment.Delete(true);

        // [THEN] The assigned error is raised
        Assert.ExpectedError(StrSubstNo(DeleteAssignedErr, EquipmentNoTok, EmployeeNoTok));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RenamingEquipmentMovesItsAttachments()
    var
        Equipment: Record "EQM Equipment";
        DocumentAttachment: Record "Document Attachment";
    begin
        // [SCENARIO 6] Renaming equipment moves its attachments to the new number (plan verification V2)
        // [GIVEN] Equipment E (LT001) with 2 attachments
        CreateEquipment(Equipment, EquipmentNoTok);
        AttachFile(Equipment, 1);
        AttachFile(Equipment, 2);

        // [WHEN] E is renamed to LT009
        Equipment.Rename(RenamedNoTok);

        // [THEN] 2 rows have LT009 and none have LT001
        FilterAttachments(DocumentAttachment, Database::"EQM Equipment", RenamedNoTok);
        Assert.RecordCount(DocumentAttachment, 2);
        FilterAttachments(DocumentAttachment, Database::"EQM Equipment", EquipmentNoTok);
        Assert.RecordIsEmpty(DocumentAttachment);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RenamingEquipmentKeepsCategoryOfAttachments()
    var
        Equipment: Record "EQM Equipment";
        DocumentAttachment: Record "Document Attachment";
    begin
        // [SCENARIO 6b] The category survives the rename (boundary of 6)
        // [GIVEN] Equipment E with an attachment of category User Manual
        CreateEquipment(Equipment, EquipmentNoTok);
        AttachFile(Equipment, 1);
        FilterAttachments(DocumentAttachment, Database::"EQM Equipment", EquipmentNoTok);
        DocumentAttachment.FindFirst();
        DocumentAttachment."EQM Attachment Category" := "EQM Attachment Category"::"User Manual";
        DocumentAttachment.Modify(true);

        // [WHEN] E is renamed
        Equipment.Rename(RenamedNoTok);

        // [THEN] The moved attachment still has category User Manual
        FilterAttachments(DocumentAttachment, Database::"EQM Equipment", RenamedNoTok);
        DocumentAttachment.FindFirst();
        Assert.AreEqual("EQM Attachment Category"::"User Manual", DocumentAttachment."EQM Attachment Category", 'The category should survive the rename');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CustomerAttachmentIsNotAffectedBySubscribers()
    var
        Customer: Record Customer;
        DocumentAttachment: Record "Document Attachment";
        RecRef: RecordRef;
    begin
        // [SCENARIO 7] Attaching a file to a customer keeps the customer number; the equipment subscribers do not interfere
        // [GIVEN] A customer
        Customer.Init();
        Customer."No." := CustomerNoTok;
        Customer.Insert(false);
        RecRef.GetTable(Customer);

        // [WHEN] A file is attached to the customer
        SaveAttachment(RecRef, 1);

        // [THEN] The row has the customer table and number
        FilterAttachments(DocumentAttachment, Database::Customer, CustomerNoTok);
        Assert.RecordCount(DocumentAttachment, 1);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('DetailsPageHandler')]
    procedure CategoryColumnVisibleWhenOpenedFromEquipmentCard()
    var
        Equipment: Record "EQM Equipment";
        EquipmentCard: TestPage "EQM Equipment Card";
    begin
        // [SCENARIO 8] The Attachments action opens the details page with the Category column visible
        // [GIVEN] The card of saved equipment E
        CreateEquipment(Equipment, EquipmentNoTok);
        EquipmentCard.OpenView();
        EquipmentCard.GoToRecord(Equipment);
        CategoryVisibleOnPage := false;

        // [WHEN] Attachments is invoked
        EquipmentCard.Attachments.Invoke();

        // [THEN] The details page (handler) showed the Category column
        Assert.IsTrue(CategoryVisibleOnPage, 'The Category column should be visible for equipment attachments');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('DetailsPageHandler')]
    procedure CategoryColumnHiddenWhenOpenedForCustomer()
    var
        Customer: Record Customer;
        DocumentAttachmentDetails: Page "Document Attachment Details";
        RecRef: RecordRef;
    begin
        // [SCENARIO 8b] (negative) The details page for a customer does not show the Category column
        // [GIVEN] A customer
        Customer.Init();
        Customer."No." := CustomerNoTok;
        Customer.Insert(false);
        RecRef.GetTable(Customer);
        CategoryVisibleOnPage := true;

        // [WHEN] The details page is opened for the customer
        DocumentAttachmentDetails.OpenForRecRef(RecRef);
        DocumentAttachmentDetails.RunModal();

        // [THEN] The Category column is not visible
        Assert.IsFalse(CategoryVisibleOnPage, 'The Category column should be hidden outside equipment');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EquipmentViewDetectedFromTableIdFilter()
    var
        DocumentAttachment: Record "Document Attachment";
        DocAttachmentSubscr: Codeunit "EQM Doc. Attachment Subscr.";
        OriginalFilterGroup: Integer;
    begin
        // [SCENARIO 8c] The numeric filter comparison recognises equipment in any checked filter group and nothing else
        // [GIVEN] No Table ID filter
        // [THEN] Not an equipment view
        Assert.IsFalse(DocAttachmentSubscr.IsEquipmentAttachmentView(DocumentAttachment), 'No filter is not an equipment view');

        // [GIVEN] Table ID filter on equipment in filter group 0
        DocumentAttachment.SetRange("Table ID", Database::"EQM Equipment");
        Assert.IsTrue(DocAttachmentSubscr.IsEquipmentAttachmentView(DocumentAttachment), 'Equipment filter in group 0 should be detected');

        // [GIVEN] Table ID filter on equipment in filter group 2 only
        Clear(DocumentAttachment);
        DocumentAttachment.FilterGroup(2);
        DocumentAttachment.SetRange("Table ID", Database::"EQM Equipment");
        DocumentAttachment.FilterGroup(0);
        // [THEN] Detected, and the filter group is restored
        Assert.IsTrue(DocAttachmentSubscr.IsEquipmentAttachmentView(DocumentAttachment), 'Equipment filter in group 2 should be detected');
        Assert.AreEqual(0, DocumentAttachment.FilterGroup(), 'The filter group should be restored');

        // [GIVEN] Table ID filter on equipment in filter group 4, current group 4
        Clear(DocumentAttachment);
        DocumentAttachment.FilterGroup(4);
        DocumentAttachment.SetRange("Table ID", Database::"EQM Equipment");
        OriginalFilterGroup := DocumentAttachment.FilterGroup();
        Assert.IsTrue(DocAttachmentSubscr.IsEquipmentAttachmentView(DocumentAttachment), 'Equipment filter in group 4 should be detected');
        Assert.AreEqual(OriginalFilterGroup, DocumentAttachment.FilterGroup(), 'The original filter group should be restored');

        // [GIVEN] Table ID filter on customer
        Clear(DocumentAttachment);
        DocumentAttachment.SetRange("Table ID", Database::Customer);
        Assert.IsFalse(DocAttachmentSubscr.IsEquipmentAttachmentView(DocumentAttachment), 'A customer filter is not an equipment view');

        // [GIVEN] A range of tables that is not a single number
        Clear(DocumentAttachment);
        DocumentAttachment.SetRange("Table ID", Database::"EQM Equipment", Database::"EQM Equipment" + 1);
        Assert.IsFalse(DocAttachmentSubscr.IsEquipmentAttachmentView(DocumentAttachment), 'A range of tables is not an equipment view');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AttachmentsActionDisabledOnNewCardAndFactBoxExistsOnSavedCard()
    var
        Equipment: Record "EQM Equipment";
        EquipmentCard: TestPage "EQM Equipment Card";
    begin
        // [SCENARIO 9] The Attachments action needs a saved record; the FactBox is on the card
        // [GIVEN] A new unsaved card
        EquipmentCard.OpenNew();

        // [THEN] The Attachments action is disabled
        Assert.IsFalse(EquipmentCard.Attachments.Enabled(), 'Attachments should be disabled on an unsaved card');
        EquipmentCard.Close();

        // [GIVEN] Saved equipment E
        CreateEquipment(Equipment, EquipmentNoTok);

        // [WHEN] The card is opened on E
        EquipmentCard.OpenView();
        EquipmentCard.GoToRecord(Equipment);

        // [THEN] The action is enabled and the FactBox is visible
        Assert.IsTrue(EquipmentCard.Attachments.Enabled(), 'Attachments should be enabled on a saved card');
        Assert.IsTrue(EquipmentCard.AttachedDocuments.Visible(), 'The Attachments FactBox should be on the card');
    end;

    local procedure CreateEquipment(var Equipment: Record "EQM Equipment"; EquipmentNo: Code[20])
    var
        Category: Record "EQM Equipment Category";
    begin
        Category.Init();
        Category.Code := CategoryCodeTok;
        Category.Active := true;
        if not Category.Insert() then
            Category.Modify();

        Equipment.Init();
        Equipment."No." := EquipmentNo;
        Equipment.Description := 'Test laptop';
        Equipment."Category Code" := CategoryCodeTok;
        Equipment.Insert(true);
    end;

    local procedure MarkAssigned(var Equipment: Record "EQM Equipment")
    begin
        // Set the fields directly, without validation, to avoid dependency on the assignment flow and employee data
        Equipment.Status := Equipment.Status::Assigned;
        Equipment."Assigned Employee No." := EmployeeNoTok;
        Equipment.Modify(false);
    end;

    local procedure AttachFile(var Equipment: Record "EQM Equipment"; Index: Integer)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Equipment);
        SaveAttachment(RecRef, Index);
    end;

    local procedure SaveAttachment(var RecRef: RecordRef; Index: Integer)
    var
        DocumentAttachment: Record "Document Attachment";
        TempBlob: Codeunit "Temp Blob";
        ContentOutStream: OutStream;
        ContentInStream: InStream;
    begin
        TempBlob.CreateOutStream(ContentOutStream);
        ContentOutStream.WriteText('Test content');
        TempBlob.CreateInStream(ContentInStream);
        DocumentAttachment.SaveAttachmentFromStream(ContentInStream, RecRef, StrSubstNo(FileNameTok, Index));
    end;

    local procedure FilterAttachments(var DocumentAttachment: Record "Document Attachment"; TableId: Integer; No: Code[20])
    begin
        DocumentAttachment.Reset();
        DocumentAttachment.SetRange("Table ID", TableId);
        DocumentAttachment.SetRange("No.", No);
    end;

    [ModalPageHandler]
    procedure DetailsPageHandler(var DocumentAttachmentDetails: TestPage "Document Attachment Details")
    begin
        CategoryVisibleOnPage := DocumentAttachmentDetails."EQM Attachment Category".Visible();
    end;
}
