namespace MiguelCarvalho.EquipmentManagement.Tests;

using Microsoft.Foundation.Attachment;
using Microsoft.HumanResources.Employee;
using Microsoft.Sales.Customer;
using MiguelCarvalho.EquipmentManagement;
using System.TestLibraries.Utilities;
using System.Utilities;

codeunit 50194 "EQM Equipment FactBox Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        EquipmentNoTok: Label 'FB001', Locked = true;
        EquipmentNo2Tok: Label 'FB002', Locked = true;
        EmployeeNoTok: Label 'FBEMP1', Locked = true;
        FirstNameTok: Label 'Fbfirst', Locked = true;
        LastNameTok: Label 'Fblast', Locked = true;
        CategoryCodeTok: Label 'FBCAT', Locked = true;
        MaintenanceNoTok: Label 'FBMNT1', Locked = true;
        HistoryMaintenanceNoTok: Label 'FBHIS%1', Locked = true;
        HistoryCounter: Integer;
        FileNameTok: Label 'fbfile%1.dat', Locked = true;
        TextFileNameTok: Label 'fbfile1.txt', Locked = true;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SummaryShowsStatusAndAssignedEmployee()
    var
        Equipment: Record "EQM Equipment";
        Employee: Record Employee;
        EquipmentCard: TestPage "EQM Equipment Card";
    begin
        // [SCENARIO 1] Summary shows the status and assigned employee of assigned equipment
        // [GIVEN] Employee EMP with a first and last name, and equipment E assigned to EMP
        CreateEmployee(Employee);
        CreateEquipment(Equipment, EquipmentNoTok);
        MarkAssigned(Equipment, Employee."No.");

        // [WHEN] The card of E is opened
        OpenCard(EquipmentCard, Equipment);

        // [THEN] The summary shows status Assigned, the employee number and the employee name
        Assert.AreEqual(Format(Equipment.Status::Assigned), EquipmentCard.EquipmentSummary.Status.Value(), 'The summary should show the status');
        Assert.AreEqual(Employee."No.", EquipmentCard.EquipmentSummary."Assigned Employee No.".Value(), 'The summary should show the employee number');
        Assert.AreEqual(Employee.FullName(), EquipmentCard.EquipmentSummary.EmployeeName.Value(), 'The summary should show the employee name');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SummaryShowsNoEmployeeForAvailableEquipment()
    var
        Equipment: Record "EQM Equipment";
        EquipmentCard: TestPage "EQM Equipment Card";
    begin
        // [SCENARIO 2] (negative) Available equipment shows no employee
        // [GIVEN] Equipment E with status Available and no employee
        CreateEquipment(Equipment, EquipmentNoTok);

        // [WHEN] The card is opened
        OpenCard(EquipmentCard, Equipment);

        // [THEN] The status is Available and the employee fields are blank
        Assert.AreEqual(Format(Equipment.Status::Available), EquipmentCard.EquipmentSummary.Status.Value(), 'The summary should show the status');
        Assert.AreEqual('', EquipmentCard.EquipmentSummary."Assigned Employee No.".Value(), 'The employee number should be blank');
        Assert.AreEqual('', EquipmentCard.EquipmentSummary.EmployeeName.Value(), 'The employee name should be blank');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SummaryWarrantyIsExpiringSoonInsideWindow()
    var
        Equipment: Record "EQM Equipment";
        EquipmentCard: TestPage "EQM Equipment Card";
    begin
        // [SCENARIO 3] Warranty Status is Expiring Soon inside the 30-day window
        // [GIVEN] Equipment E with a warranty end date within 30 days
        CreateEquipment(Equipment, EquipmentNoTok);
        SetWarrantyEndDate(Equipment, Today() + Random(30) - 1);

        // [WHEN] The card is opened
        OpenCard(EquipmentCard, Equipment);

        // [THEN] The warranty status is Expiring Soon
        Assert.AreEqual(Format("EQM Warranty Status"::"Expiring Soon"), EquipmentCard.EquipmentSummary.WarrantyStatus.Value(), 'The warranty should be expiring soon');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SummaryWarrantyIsActiveBeyondWindow()
    var
        Equipment: Record "EQM Equipment";
        EquipmentCard: TestPage "EQM Equipment Card";
    begin
        // [SCENARIO 3b] Warranty Status is Active beyond the window
        // [GIVEN] Equipment E with a warranty end date more than 30 days away
        CreateEquipment(Equipment, EquipmentNoTok);
        SetWarrantyEndDate(Equipment, Today() + 31 + Random(300));

        // [WHEN] The card is opened
        OpenCard(EquipmentCard, Equipment);

        // [THEN] The warranty status is Active
        Assert.AreEqual(Format("EQM Warranty Status"::Active), EquipmentCard.EquipmentSummary.WarrantyStatus.Value(), 'The warranty should be active');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SummaryWarrantyIsExpiredWhenEndDatePassed()
    var
        Equipment: Record "EQM Equipment";
        EquipmentCard: TestPage "EQM Equipment Card";
    begin
        // [SCENARIO 3c] (negative) Warranty Status is Expired when the end date has passed
        // [GIVEN] Equipment E with a warranty end date in the past
        CreateEquipment(Equipment, EquipmentNoTok);
        SetWarrantyEndDate(Equipment, Today() - Random(30));

        // [WHEN] The card is opened
        OpenCard(EquipmentCard, Equipment);

        // [THEN] The warranty status is Expired
        Assert.AreEqual(Format("EQM Warranty Status"::Expired), EquipmentCard.EquipmentSummary.WarrantyStatus.Value(), 'The warranty should be expired');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SummaryWarrantyIsBlankWithoutEndDate()
    var
        Equipment: Record "EQM Equipment";
        EquipmentCard: TestPage "EQM Equipment Card";
    begin
        // [SCENARIO 3d] (negative) Warranty Status is blank without an end date
        // [GIVEN] Equipment E without a warranty end date
        CreateEquipment(Equipment, EquipmentNoTok);

        // [WHEN] The card is opened
        OpenCard(EquipmentCard, Equipment);

        // [THEN] The warranty status is blank
        Assert.AreEqual(Format("EQM Warranty Status"::" "), EquipmentCard.EquipmentSummary.WarrantyStatus.Value(), 'The warranty status should be blank');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AssignmentCountIncludesActiveAndClosedOfThisEquipmentOnly()
    var
        Equipment: Record "EQM Equipment";
        Equipment2: Record "EQM Equipment";
        EquipmentAssignment: Record "EQM Equipment Assignment";
        EquipmentCard: TestPage "EQM Equipment Card";
        ClosedCount: Integer;
        Index: Integer;
    begin
        // [SCENARIO 4] Assignment Count counts active and closed entries of this equipment only
        // [GIVEN] Equipment E with N closed entries and 1 active entry, and equipment E2 with its own entries
        CreateEquipment(Equipment, EquipmentNoTok);
        CreateEquipment(Equipment2, EquipmentNo2Tok);
        ClosedCount := Random(5);
        for Index := 1 to ClosedCount do
            InsertAssignment(EquipmentNoTok, EquipmentAssignment.Status::Closed);
        InsertAssignment(EquipmentNoTok, EquipmentAssignment.Status::Active);
        for Index := 1 to Random(3) do
            InsertAssignment(EquipmentNo2Tok, EquipmentAssignment.Status::Active);

        // [WHEN] The card of E is opened
        OpenCard(EquipmentCard, Equipment);

        // [THEN] The count is N + 1
        Assert.AreEqual(ClosedCount + 1, EquipmentCard.EquipmentStatistics.NoOfAssignments.AsInteger(), 'The count should include active and closed entries of E only');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MaintenanceCountAndCostComeFromPostedHistory()
    var
        Equipment: Record "EQM Equipment";
        EquipmentCard: TestPage "EQM Equipment Card";
        HistoryCount: Integer;
        Cost: Decimal;
        TotalCost: Decimal;
        Index: Integer;
    begin
        // [SCENARIO 5] Maintenance Count and Total Maintenance Cost come from posted history
        // [GIVEN] Equipment E with M history entries that have random costs
        CreateEquipment(Equipment, EquipmentNoTok);
        HistoryCount := Random(4);
        for Index := 1 to HistoryCount do begin
            Cost := Random(10000) / 100;
            TotalCost += Cost;
            InsertHistoryEntry(EquipmentNoTok, Cost);
        end;

        // [WHEN] The card is opened
        OpenCard(EquipmentCard, Equipment);

        // [THEN] The count is M and the cost is the sum
        Assert.AreEqual(HistoryCount, EquipmentCard.EquipmentStatistics.NoOfPostedMaintenances.AsInteger(), 'The count should be the posted entries');
        Assert.AreEqual(TotalCost, EquipmentCard.EquipmentStatistics.TotalMaintenanceCost.AsDecimal(), 'The cost should be the sum of the posted entries');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OpenMaintenanceAndOtherEquipmentAreNotCounted()
    var
        Equipment: Record "EQM Equipment";
        Equipment2: Record "EQM Equipment";
        EquipmentCard: TestPage "EQM Equipment Card";
    begin
        // [SCENARIO 5b] (negative) Open maintenance and other equipment are not counted
        // [GIVEN] Equipment E with one open maintenance record and no history, and equipment E2 with one history entry
        CreateEquipment(Equipment, EquipmentNoTok);
        CreateEquipment(Equipment2, EquipmentNo2Tok);
        InsertOpenMaintenanceRecord(EquipmentNoTok);
        InsertHistoryEntry(EquipmentNo2Tok, Random(10000) / 100);

        // [WHEN] The card of E is opened
        OpenCard(EquipmentCard, Equipment);

        // [THEN] The count and cost are 0
        Assert.AreEqual(0, EquipmentCard.EquipmentStatistics.NoOfPostedMaintenances.AsInteger(), 'Open records and other equipment should not be counted');
        Assert.AreEqual(0, EquipmentCard.EquipmentStatistics.TotalMaintenanceCost.AsDecimal(), 'Open records and other equipment should not add cost');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure StatisticsAreZeroForEquipmentWithoutHistory()
    var
        Equipment: Record "EQM Equipment";
        EquipmentCard: TestPage "EQM Equipment Card";
    begin
        // [SCENARIO 6] (negative, empty) Equipment without history shows zeros
        // [GIVEN] A new saved equipment E
        CreateEquipment(Equipment, EquipmentNoTok);

        // [WHEN] The card is opened
        OpenCard(EquipmentCard, Equipment);

        // [THEN] All three statistics are 0
        Assert.AreEqual(0, EquipmentCard.EquipmentStatistics.NoOfAssignments.AsInteger(), 'The assignment count should be 0');
        Assert.AreEqual(0, EquipmentCard.EquipmentStatistics.NoOfPostedMaintenances.AsInteger(), 'The maintenance count should be 0');
        Assert.AreEqual(0, EquipmentCard.EquipmentStatistics.TotalMaintenanceCost.AsDecimal(), 'The cost should be 0');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DocumentsAndImagesAreCountedSeparately()
    var
        Equipment: Record "EQM Equipment";
        DocumentAttachment: Record "Document Attachment";
        AttachmentMgt: Codeunit "EQM Equipment Attachment Mgt.";
        ImageCount: Integer;
        DocumentCount: Integer;
        Index: Integer;
    begin
        // [SCENARIO 7] Documents and images are counted separately
        // [GIVEN] Equipment E with I image rows and D non-image rows, one of them with a blank file type
        CreateEquipment(Equipment, EquipmentNoTok);
        ImageCount := Random(3);
        for Index := 1 to ImageCount do
            InsertAttachment(Database::"EQM Equipment", EquipmentNoTok, Index, DocumentAttachment."File Type"::Image);
        DocumentCount := Random(3);
        for Index := 1 to DocumentCount do
            InsertAttachment(Database::"EQM Equipment", EquipmentNoTok, 100 + Index, DocumentAttachment."File Type"::PDF);
        InsertAttachment(Database::"EQM Equipment", EquipmentNoTok, 200, DocumentAttachment."File Type"::" ");
        DocumentCount += 1;

        // [WHEN] The documents and images are counted
        // [THEN] They return D and I
        Assert.AreEqual(DocumentCount, AttachmentMgt.CountDocuments(EquipmentNoTok), 'The document count should exclude images');
        Assert.AreEqual(ImageCount, AttachmentMgt.CountImages(EquipmentNoTok), 'The image count should include images only');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OtherEquipmentAndOtherTablesAreNotCounted()
    var
        Equipment: Record "EQM Equipment";
        Equipment2: Record "EQM Equipment";
        DocumentAttachment: Record "Document Attachment";
        AttachmentMgt: Codeunit "EQM Equipment Attachment Mgt.";
    begin
        // [SCENARIO 7b] (negative) Other equipment and other tables are not counted
        // [GIVEN] Image and document rows for E2, and rows of the Customer table with the number of E
        CreateEquipment(Equipment, EquipmentNoTok);
        CreateEquipment(Equipment2, EquipmentNo2Tok);
        InsertAttachment(Database::"EQM Equipment", EquipmentNo2Tok, 1, DocumentAttachment."File Type"::Image);
        InsertAttachment(Database::"EQM Equipment", EquipmentNo2Tok, 2, DocumentAttachment."File Type"::PDF);
        InsertAttachment(Database::Customer, EquipmentNoTok, 3, DocumentAttachment."File Type"::Image);
        InsertAttachment(Database::Customer, EquipmentNoTok, 4, DocumentAttachment."File Type"::PDF);

        // [WHEN] The documents and images of E are counted
        // [THEN] Both counts are 0
        Assert.AreEqual(0, AttachmentMgt.CountDocuments(EquipmentNoTok), 'Rows of other equipment or tables should not be counted as documents');
        Assert.AreEqual(0, AttachmentMgt.CountImages(EquipmentNoTok), 'Rows of other equipment or tables should not be counted as images');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BlankEquipmentNoReturnsZero()
    var
        AttachmentMgt: Codeunit "EQM Equipment Attachment Mgt.";
    begin
        // [SCENARIO 7c] (boundary) A blank equipment number returns 0
        // [WHEN] The documents and images of a blank number are counted
        // [THEN] Both return 0 and no error is raised
        Assert.AreEqual(0, AttachmentMgt.CountDocuments(''), 'A blank number should have no documents');
        Assert.AreEqual(0, AttachmentMgt.CountImages(''), 'A blank number should have no images');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SavedTextFileCountsAsDocument()
    var
        Equipment: Record "EQM Equipment";
        DocumentAttachment: Record "Document Attachment";
        AttachmentMgt: Codeunit "EQM Equipment Attachment Mgt.";
        TempBlob: Codeunit "Temp Blob";
        RecRef: RecordRef;
        ContentOutStream: OutStream;
        ContentInStream: InStream;
    begin
        // [SCENARIO 7d] A text file saved through the standard framework counts as a document
        // [GIVEN] Equipment E and a text file saved as its attachment
        CreateEquipment(Equipment, EquipmentNoTok);
        RecRef.GetTable(Equipment);
        TempBlob.CreateOutStream(ContentOutStream);
        ContentOutStream.WriteText('Test content');
        TempBlob.CreateInStream(ContentInStream);
        DocumentAttachment.SaveAttachmentFromStream(ContentInStream, RecRef, TextFileNameTok);

        // [WHEN] The documents and images are counted
        // [THEN] There is 1 document and no image
        Assert.AreEqual(1, AttachmentMgt.CountDocuments(EquipmentNoTok), 'A text file should count as a document');
        Assert.AreEqual(0, AttachmentMgt.CountImages(EquipmentNoTok), 'A text file should not count as an image');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CardShowsAttachmentCounts()
    var
        Equipment: Record "EQM Equipment";
        DocumentAttachment: Record "Document Attachment";
        EquipmentCard: TestPage "EQM Equipment Card";
    begin
        // [SCENARIO 8] The card shows the attachment counts
        // [GIVEN] Equipment E with 2 image rows and 1 PDF row
        CreateEquipment(Equipment, EquipmentNoTok);
        InsertAttachment(Database::"EQM Equipment", EquipmentNoTok, 1, DocumentAttachment."File Type"::Image);
        InsertAttachment(Database::"EQM Equipment", EquipmentNoTok, 2, DocumentAttachment."File Type"::Image);
        InsertAttachment(Database::"EQM Equipment", EquipmentNoTok, 3, DocumentAttachment."File Type"::PDF);

        // [WHEN] The card is opened
        OpenCard(EquipmentCard, Equipment);

        // [THEN] The FactBox shows 1 document and 2 images
        Assert.AreEqual(1, EquipmentCard.AttachmentSummary.NoOfDocuments.AsInteger(), 'The card should show the document count');
        Assert.AreEqual(2, EquipmentCard.AttachmentSummary.NoOfImages.AsInteger(), 'The card should show the image count');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NewCardShowsEmptyFactBoxes()
    var
        EquipmentCard: TestPage "EQM Equipment Card";
    begin
        // [SCENARIO 9] (negative) A new card shows empty FactBoxes without error
        // [WHEN] A new card is opened
        EquipmentCard.OpenNew();

        // [THEN] The three FactBoxes are visible and show zeros or blanks
        Assert.IsTrue(EquipmentCard.EquipmentSummary.Visible(), 'The summary FactBox should be on the card');
        Assert.IsTrue(EquipmentCard.EquipmentStatistics.Visible(), 'The statistics FactBox should be on the card');
        Assert.IsTrue(EquipmentCard.AttachmentSummary.Visible(), 'The attachment FactBox should be on the card');
        Assert.AreEqual(0, EquipmentCard.EquipmentStatistics.NoOfAssignments.AsInteger(), 'The assignment count should be 0');
        Assert.AreEqual(0, EquipmentCard.AttachmentSummary.NoOfDocuments.AsInteger(), 'The document count should be 0');
        Assert.AreEqual(0, EquipmentCard.AttachmentSummary.NoOfImages.AsInteger(), 'The image count should be 0');
        Assert.AreEqual('', EquipmentCard.EquipmentSummary.EmployeeName.Value(), 'The employee name should be blank');
        Assert.AreEqual(Format("EQM Warranty Status"::" "), EquipmentCard.EquipmentSummary.WarrantyStatus.Value(), 'The warranty status should be blank');
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

    local procedure CreateEmployee(var Employee: Record Employee)
    begin
        Employee.Init();
        Employee."No." := EmployeeNoTok;
        Employee."First Name" := FirstNameTok;
        Employee."Last Name" := LastNameTok;
        Employee.Insert(false);
    end;

    local procedure MarkAssigned(var Equipment: Record "EQM Equipment"; EmployeeNo: Code[20])
    begin
        // Set the fields directly, without validation, to avoid dependency on the assignment flow
        Equipment.Status := Equipment.Status::Assigned;
        Equipment."Assigned Employee No." := EmployeeNo;
        Equipment.Modify(false);
    end;

    local procedure SetWarrantyEndDate(var Equipment: Record "EQM Equipment"; EndDate: Date)
    begin
        Equipment."Warranty End Date" := EndDate;
        Equipment.Modify(false);
    end;

    local procedure InsertAssignment(EquipmentNo: Code[20]; AssignmentStatus: Enum "EQM Assignment Status")
    var
        EquipmentAssignment: Record "EQM Equipment Assignment";
    begin
        EquipmentAssignment.Init();
        EquipmentAssignment."Equipment No." := EquipmentNo;
        EquipmentAssignment."Employee No." := EmployeeNoTok;
        EquipmentAssignment."Assignment Date" := Today();
        EquipmentAssignment.Status := AssignmentStatus;
        EquipmentAssignment.Insert(false);
    end;

    local procedure InsertHistoryEntry(EquipmentNo: Code[20]; Cost: Decimal)
    var
        HistoryEntry: Record "EQM Maintenance History Entry";
    begin
        HistoryCounter += 1;
        HistoryEntry.Init();
        HistoryEntry."Maintenance No." := CopyStr(StrSubstNo(HistoryMaintenanceNoTok, HistoryCounter), 1, MaxStrLen(HistoryEntry."Maintenance No."));
        HistoryEntry."Equipment No." := EquipmentNo;
        HistoryEntry."Maintenance Date" := Today();
        HistoryEntry.Cost := Cost;
        HistoryEntry.Insert(false);
    end;

    local procedure InsertOpenMaintenanceRecord(EquipmentNo: Code[20])
    var
        MaintenanceRecord: Record "EQM Maintenance Record";
    begin
        MaintenanceRecord.Init();
        MaintenanceRecord."No." := MaintenanceNoTok;
        MaintenanceRecord."Equipment No." := EquipmentNo;
        MaintenanceRecord."Maintenance Date" := Today();
        MaintenanceRecord.Cost := Random(10000) / 100;
        MaintenanceRecord.Status := MaintenanceRecord.Status::Open;
        MaintenanceRecord.Insert(false);
    end;

    local procedure InsertAttachment(TableId: Integer; No: Code[20]; LineNo: Integer; FileType: Enum "Document Attachment File Type")
    var
        DocumentAttachment: Record "Document Attachment";
    begin
        DocumentAttachment.Init();
        DocumentAttachment."Table ID" := TableId;
        DocumentAttachment."No." := No;
        DocumentAttachment."Line No." := LineNo;
        DocumentAttachment."File Name" := StrSubstNo(FileNameTok, LineNo);
        DocumentAttachment."File Type" := FileType;
        DocumentAttachment.Insert(false);
    end;

    local procedure OpenCard(var EquipmentCard: TestPage "EQM Equipment Card"; var Equipment: Record "EQM Equipment")
    begin
        EquipmentCard.OpenView();
        EquipmentCard.GoToRecord(Equipment);
    end;
}
