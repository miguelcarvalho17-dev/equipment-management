namespace MiguelCarvalho.EquipmentManagement.Tests;

using MiguelCarvalho.EquipmentManagement;
using System.Diagnostics;
using System.TestLibraries.Utilities;
using System.Upgrade;

/// <summary>
/// Tests for FR-034 Change Log Support (codeunit 50133 "EQM Change Log Registration"). Scenarios 1-5 and 7 call
/// RegisterEquipmentChangeLogSetup directly because the install has already set the upgrade tag in the test company.
/// Scenarios 8 and 9 of the plan (real Change Log entries, fresh install) are manual sandbox checks.
/// Every test clears the setup rows of the tables involved first and rolls back (AutoRollback); there is no Commit.
/// </summary>
codeunit 50191 "EQM Change Log Setup Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RegistrationInsertsTableRowAndSevenFieldRows()
    var
        ChangeLogSetupTable: Record "Change Log Setup (Table)";
        ChangeLogSetupField: Record "Change Log Setup (Field)";
        Equipment: Record "EQM Equipment";
        ChangeLogRegistration: Codeunit "EQM Change Log Registration";
    begin
        // [SCENARIO] Registration adds one table row (Some Fields) and one field row for each of the 7 tracked fields
        Initialize();

        // [GIVEN] No setup rows for table 50100 (Initialize)

        // [WHEN] The registration runs
        ChangeLogRegistration.RegisterEquipmentChangeLogSetup();

        // [THEN] One 403 row exists with Some Fields and no insertion/deletion logging
        Assert.IsTrue(ChangeLogSetupTable.Get(Database::"EQM Equipment"), 'The table setup row should exist');
        Assert.AreEqual(ChangeLogSetupTable."Log Modification"::"Some Fields", ChangeLogSetupTable."Log Modification", 'Log Modification should be Some Fields');
        Assert.AreEqual(ChangeLogSetupTable."Log Insertion"::" ", ChangeLogSetupTable."Log Insertion", 'Log Insertion should be blank');
        Assert.AreEqual(ChangeLogSetupTable."Log Deletion"::" ", ChangeLogSetupTable."Log Deletion", 'Log Deletion should be blank');

        // [THEN] Exactly 7 field rows exist, for the expected fields, with modification logging only
        ChangeLogSetupField.SetRange("Table No.", Database::"EQM Equipment");
        Assert.AreEqual(7, ChangeLogSetupField.Count(), 'Exactly 7 field rows should exist');
        AssertFieldRow(Equipment.FieldNo("Category Code"));
        AssertFieldRow(Equipment.FieldNo(Status));
        AssertFieldRow(Equipment.FieldNo("Assigned Employee No."));
        AssertFieldRow(Equipment.FieldNo("Warranty Start Date"));
        AssertFieldRow(Equipment.FieldNo("Warranty End Date"));
        AssertFieldRow(Equipment.FieldNo("Warranty Provider"));
        AssertFieldRow(Equipment.FieldNo("Warranty Reference No."));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RegistrationIsIdempotent()
    var
        ChangeLogSetupTable: Record "Change Log Setup (Table)";
        ChangeLogSetupField: Record "Change Log Setup (Field)";
        Equipment: Record "EQM Equipment";
        ChangeLogRegistration: Codeunit "EQM Change Log Registration";
    begin
        // [SCENARIO] Running the registration twice leaves counts and values unchanged
        Initialize();

        // [GIVEN] The registration has run once
        ChangeLogRegistration.RegisterEquipmentChangeLogSetup();

        // [WHEN] It runs again
        ChangeLogRegistration.RegisterEquipmentChangeLogSetup();

        // [THEN] Still one table row and 7 field rows, with the same values
        ChangeLogSetupTable.SetRange("Table No.", Database::"EQM Equipment");
        Assert.AreEqual(1, ChangeLogSetupTable.Count(), 'Still exactly one table row');
        ChangeLogSetupTable.FindFirst();
        Assert.AreEqual(ChangeLogSetupTable."Log Modification"::"Some Fields", ChangeLogSetupTable."Log Modification", 'Log Modification should still be Some Fields');
        ChangeLogSetupField.SetRange("Table No.", Database::"EQM Equipment");
        Assert.AreEqual(7, ChangeLogSetupField.Count(), 'Still exactly 7 field rows');
        AssertFieldRow(Equipment.FieldNo(Status));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ExistingAllFieldsRowIsLeftUntouched()
    var
        ChangeLogSetupTable: Record "Change Log Setup (Table)";
        ChangeLogSetupField: Record "Change Log Setup (Field)";
        ChangeLogRegistration: Codeunit "EQM Change Log Registration";
    begin
        // [SCENARIO] A customer's own All Fields row for the equipment table is not changed and gets no field rows
        Initialize();

        // [GIVEN] A customer row for 50100 with Log Modification = All Fields
        InsertCustomerTableRow(ChangeLogSetupTable."Log Modification"::"All Fields");

        // [WHEN] The registration runs
        ChangeLogRegistration.RegisterEquipmentChangeLogSetup();

        // [THEN] The row is unchanged and no field rows were added
        ChangeLogSetupTable.Get(Database::"EQM Equipment");
        Assert.AreEqual(ChangeLogSetupTable."Log Modification"::"All Fields", ChangeLogSetupTable."Log Modification", 'The customer row must stay All Fields');
        ChangeLogSetupField.SetRange("Table No.", Database::"EQM Equipment");
        Assert.RecordIsEmpty(ChangeLogSetupField);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ExistingSwitchedOffRowIsLeftUntouched()
    var
        ChangeLogSetupTable: Record "Change Log Setup (Table)";
        ChangeLogSetupField: Record "Change Log Setup (Field)";
        ChangeLogRegistration: Codeunit "EQM Change Log Registration";
    begin
        // [SCENARIO] A customer's row that is switched off (blank) is respected
        Initialize();

        // [GIVEN] A customer row for 50100 with all logging blank
        InsertCustomerTableRow(ChangeLogSetupTable."Log Modification"::" ");

        // [WHEN] The registration runs
        ChangeLogRegistration.RegisterEquipmentChangeLogSetup();

        // [THEN] The row stays blank and no field rows were added
        ChangeLogSetupTable.Get(Database::"EQM Equipment");
        Assert.AreEqual(ChangeLogSetupTable."Log Modification"::" ", ChangeLogSetupTable."Log Modification", 'The switched-off row must stay blank');
        Assert.AreEqual(ChangeLogSetupTable."Log Insertion"::" ", ChangeLogSetupTable."Log Insertion", 'Log Insertion must stay blank');
        Assert.AreEqual(ChangeLogSetupTable."Log Deletion"::" ", ChangeLogSetupTable."Log Deletion", 'Log Deletion must stay blank');
        ChangeLogSetupField.SetRange("Table No.", Database::"EQM Equipment");
        Assert.RecordIsEmpty(ChangeLogSetupField);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ChangeLogActivatedFlagIsNotChanged()
    var
        ChangeLogSetup: Record "Change Log Setup";
        ChangeLogRegistration: Codeunit "EQM Change Log Registration";
    begin
        // [SCENARIO] The registration never reads or changes "Change Log Activated" (D1 = off), whether false or true
        Initialize();

        // [GIVEN] The Change Log is not activated
        SetChangeLogActivated(false);

        // [WHEN] The registration runs
        ChangeLogRegistration.RegisterEquipmentChangeLogSetup();

        // [THEN] The flag is still false
        ChangeLogSetup.Get();
        Assert.IsFalse(ChangeLogSetup."Change Log Activated", 'The flag must stay false');

        // [GIVEN] The Change Log is activated and the equipment rows are removed again
        SetChangeLogActivated(true);
        DeleteSetupRows(Database::"EQM Equipment");

        // [WHEN] The registration runs
        ChangeLogRegistration.RegisterEquipmentChangeLogSetup();

        // [THEN] The flag is still true
        ChangeLogSetup.Get();
        Assert.IsTrue(ChangeLogSetup."Change Log Activated", 'The flag must stay true');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UpgradeTagMakesRegistrationSkipDeletedRows()
    var
        ChangeLogSetupTable: Record "Change Log Setup (Table)";
        ChangeLogSetupField: Record "Change Log Setup (Field)";
        ChangeLogRegistration: Codeunit "EQM Change Log Registration";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        // [SCENARIO] When the upgrade tag is set, the registration does not re-add rows that were deleted on purpose
        Initialize();

        // [GIVEN] The upgrade tag is set (the install sets it; set here if the test company lacks it) and the rows are deleted
        if not UpgradeTag.HasUpgradeTag(ChangeLogRegistration.GetChangeLogUpgradeTag()) then
            UpgradeTag.SetUpgradeTag(ChangeLogRegistration.GetChangeLogUpgradeTag());
        Assert.IsTrue(UpgradeTag.HasUpgradeTag(ChangeLogRegistration.GetChangeLogUpgradeTag()), 'The upgrade tag should be set');
        DeleteSetupRows(Database::"EQM Equipment");

        // [WHEN] RegisterChangeLogSetupOnce runs
        ChangeLogRegistration.RegisterChangeLogSetupOnce();

        // [THEN] No rows were inserted
        ChangeLogSetupTable.SetRange("Table No.", Database::"EQM Equipment");
        Assert.RecordIsEmpty(ChangeLogSetupTable);
        ChangeLogSetupField.SetRange("Table No.", Database::"EQM Equipment");
        Assert.RecordIsEmpty(ChangeLogSetupField);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RegistrationAddsNoRowsForOtherFieldsOrTables()
    var
        ChangeLogSetupTable: Record "Change Log Setup (Table)";
        ChangeLogSetupField: Record "Change Log Setup (Field)";
        Equipment: Record "EQM Equipment";
        ChangeLogRegistration: Codeunit "EQM Change Log Registration";
    begin
        // [SCENARIO] Only the 7 tracked fields of 50100 are registered; Description, Location Code and tables 50101/50103 are not
        Initialize();

        // [GIVEN] No setup rows (Initialize)

        // [WHEN] The registration runs
        ChangeLogRegistration.RegisterEquipmentChangeLogSetup();

        // [THEN] No field rows for Description or Location Code
        Assert.IsFalse(ChangeLogSetupField.Get(Database::"EQM Equipment", Equipment.FieldNo(Description)), 'Description must not be logged');
        Assert.IsFalse(ChangeLogSetupField.Get(Database::"EQM Equipment", Equipment.FieldNo("Location Code")), 'Location Code must not be logged');

        // [THEN] No table rows for the category and assignment tables
        Assert.IsFalse(ChangeLogSetupTable.Get(Database::"EQM Equipment Category"), 'The category table must not be registered');
        Assert.IsFalse(ChangeLogSetupTable.Get(Database::"EQM Equipment Assignment"), 'The assignment table must not be registered');
    end;

    local procedure Initialize()
    begin
        DeleteSetupRows(Database::"EQM Equipment");
        DeleteSetupRows(Database::"EQM Equipment Category");
        DeleteSetupRows(Database::"EQM Equipment Assignment");
    end;

    local procedure DeleteSetupRows(TableNo: Integer)
    var
        ChangeLogSetupTable: Record "Change Log Setup (Table)";
        ChangeLogSetupField: Record "Change Log Setup (Field)";
    begin
        ChangeLogSetupField.SetRange("Table No.", TableNo);
        ChangeLogSetupField.DeleteAll();
        ChangeLogSetupTable.SetRange("Table No.", TableNo);
        ChangeLogSetupTable.DeleteAll();
    end;

    local procedure InsertCustomerTableRow(LogModification: Option " ","Some Fields","All Fields")
    var
        ChangeLogSetupTable: Record "Change Log Setup (Table)";
    begin
        ChangeLogSetupTable.Init();
        ChangeLogSetupTable."Table No." := Database::"EQM Equipment";
        ChangeLogSetupTable."Log Modification" := LogModification;
        ChangeLogSetupTable.Insert();
    end;

    local procedure SetChangeLogActivated(Activated: Boolean)
    var
        ChangeLogSetup: Record "Change Log Setup";
    begin
        if not ChangeLogSetup.Get() then begin
            ChangeLogSetup.Init();
            ChangeLogSetup.Insert();
        end;
        ChangeLogSetup."Change Log Activated" := Activated;
        ChangeLogSetup.Modify();
    end;

    local procedure AssertFieldRow(FieldNo: Integer)
    var
        ChangeLogSetupField: Record "Change Log Setup (Field)";
    begin
        Assert.IsTrue(ChangeLogSetupField.Get(Database::"EQM Equipment", FieldNo), 'A field row should exist for field ' + Format(FieldNo));
        Assert.IsTrue(ChangeLogSetupField."Log Modification", 'Log Modification should be true for field ' + Format(FieldNo));
        Assert.IsFalse(ChangeLogSetupField."Log Insertion", 'Log Insertion should be false for field ' + Format(FieldNo));
        Assert.IsFalse(ChangeLogSetupField."Log Deletion", 'Log Deletion should be false for field ' + Format(FieldNo));
    end;
}
