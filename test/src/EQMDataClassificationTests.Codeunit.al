namespace MiguelCarvalho.EquipmentManagement.Tests;

using Microsoft.Foundation.Attachment;
using MiguelCarvalho.EquipmentManagement;
using System.Reflection;
using System.TestLibraries.Utilities;

/// <summary>
/// FR-058: keeps the data classification of the app's fields from drifting.
/// Reads the compiled field metadata from the system table Field.
/// </summary>
codeunit 50163 "EQM Data Classification Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        AppTableRangeTok: Label '50100..50149', Locked = true;
        AllFieldsRangeTok: Label '1..1999999999', Locked = true;
        UserIdNameTok: Label 'User ID', Locked = true;
        BySuffixTok: Label ' By', Locked = true;
        UnclassifiedFieldErr: Label 'Field %1 of table %2 is not classified (ToBeClassified).', Comment = '%1 = field name, %2 = table number';
        NotCoveredErr: Label 'The scan did not cover field %1 of table %2.', Comment = '%1 = field name, %2 = table number';
        FlowFieldCoveredErr: Label 'The scan covered the FlowField %1 of table %2, but it must only cover Normal fields.', Comment = '%1 = field name, %2 = table number';
        NoUserIdFieldErr: Label 'No user ID field was found; the name rule matched nothing.';
        WrongClassificationErr: Label 'Field %1 of table %2 has the wrong data classification.', Comment = '%1 = field name, %2 = table number';
        FieldMissingErr: Label 'Field %1 of table %2 was not found in the metadata.', Comment = '%1 = field number, %2 = table number';

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EveryNormalFieldIsClassified()
    var
        "Field": Record "Field";
    begin
        // [SCENARIO] No Normal field of the app's tables is left as ToBeClassified
        // [GIVEN] The fields of all tables in the app's object range
        FilterAppNormalFields("Field");

        // [WHEN] The fields still marked ToBeClassified are selected
        "Field".SetRange(DataClassification, "Field".DataClassification::ToBeClassified);

        // [THEN] There are none; a failure names the table and the field
        if "Field".FindFirst() then
            Assert.Fail(StrSubstNo(UnclassifiedFieldErr, "Field".FieldName, "Field".TableNo));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ScanCoversNormalFieldsOnly()
    var
        "Field": Record "Field";
        Equipment: Record "EQM Equipment";
    begin
        // [SCENARIO] The field scan includes Normal fields and excludes FlowFields
        // [GIVEN] The fields of all tables in the app's object range
        FilterAppNormalFields("Field");

        // [WHEN] A known Normal field is looked up
        // [THEN] The scan contains it
        "Field".SetRange(TableNo, Database::"EQM Equipment");
        "Field".SetRange("No.", Equipment.FieldNo(Description));
        Assert.IsFalse("Field".IsEmpty(), StrSubstNo(NotCoveredErr, Equipment.FieldName(Description), Database::"EQM Equipment"));

        // [THEN] A known FlowField is not in the scan
        "Field".SetRange("No.", Equipment.FieldNo("Total Maintenance Cost"));
        Assert.IsTrue("Field".IsEmpty(), StrSubstNo(FlowFieldCoveredErr, Equipment.FieldName("Total Maintenance Cost"), Database::"EQM Equipment"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UserIdFieldsAreEndUserIdentifiable()
    var
        "Field": Record "Field";
        Found: Boolean;
    begin
        // [SCENARIO] Every Code[50] field named "User ID" or "... By" holds a user name and is EndUserIdentifiableInformation
        // [GIVEN] The Normal fields of the app's tables
        FilterAppNormalFields("Field");
        "Field".SetRange(Type, "Field".Type::Code);
        "Field".SetRange(Len, 50);

        // [WHEN] Each field that looks like a user ID is checked
        if "Field".FindSet() then
            repeat
                if IsUserIdField("Field") then begin
                    Found := true;
                    // [THEN] It is EndUserIdentifiableInformation
                    Assert.IsTrue(
                        "Field".DataClassification = "Field".DataClassification::EndUserIdentifiableInformation,
                        StrSubstNo(WrongClassificationErr, "Field".FieldName, "Field".TableNo));
                end;
            until "Field".Next() = 0;

        // [THEN] At least one field was checked
        Assert.IsTrue(Found, NoUserIdFieldErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure KnownUserIdFieldsAreEndUserIdentifiable()
    var
        Assignment: Record "EQM Equipment Assignment";
        Request: Record "EQM Equipment Request";
        AuditEntry: Record "EQM Equipment Audit Entry";
        LogEntry: Record "EQM Maintenance Log Entry";
        Note: Record "EQM Equipment Note";
        ErrorLogEntry: Record "EQM Error Log Entry";
        WarrantyAlert: Record "EQM Warranty Alert";
        HistoryEntry: Record "EQM Maintenance History Entry";
        DemoDataEntry: Record "EQM Demo Data Entry";
    begin
        // [SCENARIO] The fields filled from UserId() stay EndUserIdentifiableInformation
        // [GIVEN] The known user-ID fields of the app
        // [WHEN] Their classification is read from the metadata
        // [THEN] Each one is EndUserIdentifiableInformation
        AssertEndUserIdentifiable(Database::"EQM Equipment Assignment", Assignment.FieldNo("Assigned By"));
        AssertEndUserIdentifiable(Database::"EQM Equipment Assignment", Assignment.FieldNo("Closed By"));
        AssertEndUserIdentifiable(Database::"EQM Equipment Request", Request.FieldNo("Sent for Approval By"));
        AssertEndUserIdentifiable(Database::"EQM Equipment Request", Request.FieldNo("Decided By"));
        AssertEndUserIdentifiable(Database::"EQM Equipment Audit Entry", AuditEntry.FieldNo("User ID"));
        AssertEndUserIdentifiable(Database::"EQM Maintenance Log Entry", LogEntry.FieldNo("User ID"));
        AssertEndUserIdentifiable(Database::"EQM Equipment Note", Note.FieldNo("User ID"));
        AssertEndUserIdentifiable(Database::"EQM Error Log Entry", ErrorLogEntry.FieldNo("User ID"));
        AssertEndUserIdentifiable(Database::"EQM Warranty Alert", WarrantyAlert.FieldNo("Acknowledged By"));
        AssertEndUserIdentifiable(Database::"EQM Maintenance History Entry", HistoryEntry.FieldNo("Posted By"));
        AssertEndUserIdentifiable(Database::"EQM Demo Data Entry", DemoDataEntry.FieldNo("Created By"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PersonalDataFieldsStayCustomerContent()
    var
        Equipment: Record "EQM Equipment";
        Assignment: Record "EQM Equipment Assignment";
        Request: Record "EQM Equipment Request";
        AuditEntry: Record "EQM Equipment Audit Entry";
        MaintenanceRecord: Record "EQM Maintenance Record";
        HistoryEntry: Record "EQM Maintenance History Entry";
        Note: Record "EQM Equipment Note";
        LogEntry: Record "EQM Maintenance Log Entry";
        ErrorLogEntry: Record "EQM Error Log Entry";
    begin
        // [SCENARIO] Employee, vendor and free-text personal data stays CustomerContent (FR-058 decision)
        // [GIVEN] The fields that hold employee numbers, vendor data and free text
        // [WHEN] Their classification is read from the metadata
        // [THEN] Each one is CustomerContent
        AssertCustomerContent(Database::"EQM Equipment", Equipment.FieldNo("Assigned Employee No."));
        AssertCustomerContent(Database::"EQM Equipment Assignment", Assignment.FieldNo("Employee No."));
        AssertCustomerContent(Database::"EQM Equipment Request", Request.FieldNo("Employee No."));
        AssertCustomerContent(Database::"EQM Equipment Request", Request.FieldNo(Justification));
        AssertCustomerContent(Database::"EQM Equipment Request", Request.FieldNo("Decision Comment"));
        AssertCustomerContent(Database::"EQM Equipment Audit Entry", AuditEntry.FieldNo("Employee No."));
        AssertCustomerContent(Database::"EQM Maintenance Record", MaintenanceRecord.FieldNo("Performed By"));
        AssertCustomerContent(Database::"EQM Maintenance History Entry", HistoryEntry.FieldNo("Performed By"));
        AssertCustomerContent(Database::"EQM Maintenance History Entry", HistoryEntry.FieldNo("Vendor Name"));
        AssertCustomerContent(Database::"EQM Maintenance History Entry", HistoryEntry.FieldNo("Vendor No."));
        AssertCustomerContent(Database::"EQM Equipment Note", Note.FieldNo(Comment));
        AssertCustomerContent(Database::"EQM Maintenance Log Entry", LogEntry.FieldNo("Old Value"));
        AssertCustomerContent(Database::"EQM Maintenance Log Entry", LogEntry.FieldNo("New Value"));
        AssertCustomerContent(Database::"EQM Error Log Entry", ErrorLogEntry.FieldNo("Error Message"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SystemFieldsStaySystemMetadata()
    var
        ErrorLogEntry: Record "EQM Error Log Entry";
        DemoDataEntry: Record "EQM Demo Data Entry";
        DocumentAttachment: Record "Document Attachment";
    begin
        // [SCENARIO] The explicit SystemMetadata fields stay SystemMetadata and the table extension field stays CustomerContent
        // [GIVEN] The explicitly classified system fields and the field added to Document Attachment
        // [WHEN] Their classification is read from the metadata
        // [THEN] The system fields are SystemMetadata
        AssertSystemMetadata(Database::"EQM Error Log Entry", ErrorLogEntry.FieldNo(Operation));
        AssertSystemMetadata(Database::"EQM Error Log Entry", ErrorLogEntry.FieldNo("Object ID"));
        AssertSystemMetadata(Database::"EQM Error Log Entry", ErrorLogEntry.FieldNo("Error Code"));
        AssertSystemMetadata(Database::"EQM Error Log Entry", ErrorLogEntry.FieldNo("Error Call Stack"));
        AssertSystemMetadata(Database::"EQM Demo Data Entry", DemoDataEntry.FieldNo("Table ID"));
        AssertSystemMetadata(Database::"EQM Demo Data Entry", DemoDataEntry.FieldNo("Record System Id"));
        AssertSystemMetadata(Database::"EQM Demo Data Entry", DemoDataEntry.FieldNo("Created At"));

        // [THEN] The table extension field is CustomerContent
        AssertCustomerContent(Database::"Document Attachment", DocumentAttachment.FieldNo("EQM Attachment Category"));
    end;

    local procedure FilterAppNormalFields(var "Field": Record "Field")
    begin
        "Field".Reset();
        "Field".SetFilter(TableNo, AppTableRangeTok);
        "Field".SetFilter("No.", AllFieldsRangeTok);
        "Field".SetRange(Class, "Field".Class::Normal);
    end;

    local procedure GetField(var "Field": Record "Field"; TableNo: Integer; FieldNo: Integer)
    begin
        if not "Field".Get(TableNo, FieldNo) then
            Assert.Fail(StrSubstNo(FieldMissingErr, FieldNo, TableNo));
    end;

    local procedure IsUserIdField("Field": Record "Field"): Boolean
    begin
        exit(("Field".FieldName = UserIdNameTok) or "Field".FieldName.EndsWith(BySuffixTok));
    end;

    local procedure AssertEndUserIdentifiable(TableNo: Integer; FieldNo: Integer)
    var
        "Field": Record "Field";
    begin
        GetField("Field", TableNo, FieldNo);
        Assert.IsTrue(
            "Field".DataClassification = "Field".DataClassification::EndUserIdentifiableInformation,
            StrSubstNo(WrongClassificationErr, "Field".FieldName, TableNo));
    end;

    local procedure AssertCustomerContent(TableNo: Integer; FieldNo: Integer)
    var
        "Field": Record "Field";
    begin
        GetField("Field", TableNo, FieldNo);
        Assert.IsTrue(
            "Field".DataClassification = "Field".DataClassification::CustomerContent,
            StrSubstNo(WrongClassificationErr, "Field".FieldName, TableNo));
    end;

    local procedure AssertSystemMetadata(TableNo: Integer; FieldNo: Integer)
    var
        "Field": Record "Field";
    begin
        GetField("Field", TableNo, FieldNo);
        Assert.IsTrue(
            "Field".DataClassification = "Field".DataClassification::SystemMetadata,
            StrSubstNo(WrongClassificationErr, "Field".FieldName, TableNo));
    end;
}
