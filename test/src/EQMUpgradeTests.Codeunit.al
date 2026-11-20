namespace MiguelCarvalho.EquipmentManagement.Tests;

using MiguelCarvalho.EquipmentManagement;
using System.DataAdministration;
using System.TestLibraries.Utilities;
using System.Upgrade;

codeunit 50177 "EQM Upgrade Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        UpgradeMgt: Codeunit "EQM Upgrade Mgt.";
        WarrantyAlertMgt: Codeunit "EQM Warranty Alert Mgt.";
        EquipmentNosTok: Label 'UPGNOS', Locked = true;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BlankAlertDaysAreInitialized()
    var
        EquipmentSetup: Record "EQM Equipment Setup";
    begin
        Initialize();
        // [SCENARIO 1] Blank alert days are initialized
        // [GIVEN] The setup row has Default Warranty Alert Days = 0
        SetAlertDays(0);

        // [WHEN] The initialization runs
        UpgradeMgt.InitDefaultWarrantyAlertDays();

        // [THEN] Default Warranty Alert Days is the longest alert interval
        EquipmentSetup.Get();
        Assert.AreEqual(
            WarrantyAlertMgt.GetLongestIntervalDays(), EquipmentSetup."Default Warranty Alert Days",
            EquipmentSetup.FieldCaption("Default Warranty Alert Days"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UserValueIsKept()
    var
        EquipmentSetup: Record "EQM Equipment Setup";
        UserValue: Integer;
    begin
        Initialize();
        // [SCENARIO 2] (negative) A value the user set is kept
        // [GIVEN] Default Warranty Alert Days is the 30-day interval
        UserValue := WarrantyAlertMgt.GetIntervalDays("EQM Warranty Alert Interval"::"30 Days");
        SetAlertDays(UserValue);

        // [WHEN] The initialization runs
        UpgradeMgt.InitDefaultWarrantyAlertDays();

        // [THEN] The value is unchanged
        EquipmentSetup.Get();
        Assert.AreEqual(UserValue, EquipmentSetup."Default Warranty Alert Days", EquipmentSetup.FieldCaption("Default Warranty Alert Days"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OtherSetupDataIsPreserved()
    var
        EquipmentSetup: Record "EQM Equipment Setup";
        EquipmentNos: Code[20];
        IntegrationEventsEnabled: Boolean;
        MaintFreqMonths: Integer;
    begin
        Initialize();
        // [SCENARIO 3] (negative) Other setup data is preserved
        // [GIVEN] The alert days are 0 and the other setup fields hold known values
        EquipmentSetup.Get();
        EquipmentNos := CopyStr(EquipmentNosTok, 1, MaxStrLen(EquipmentNos));
        IntegrationEventsEnabled := not EquipmentSetup."Integration Events Enabled";
        MaintFreqMonths := Date2DMY(Today(), 1);
        EquipmentSetup."Default Warranty Alert Days" := 0;
        EquipmentSetup."Equipment Nos." := EquipmentNos;
        EquipmentSetup."Integration Events Enabled" := IntegrationEventsEnabled;
        EquipmentSetup."Default Maint. Freq. (Months)" := MaintFreqMonths;
        EquipmentSetup.Modify(false);

        // [WHEN] The initialization runs
        UpgradeMgt.InitDefaultWarrantyAlertDays();

        // [THEN] The other fields are unchanged and the alert days are set
        EquipmentSetup.Get();
        Assert.AreEqual(EquipmentNos, EquipmentSetup."Equipment Nos.", EquipmentSetup.FieldCaption("Equipment Nos."));
        Assert.AreEqual(IntegrationEventsEnabled, EquipmentSetup."Integration Events Enabled", EquipmentSetup.FieldCaption("Integration Events Enabled"));
        Assert.AreEqual(MaintFreqMonths, EquipmentSetup."Default Maint. Freq. (Months)", EquipmentSetup.FieldCaption("Default Maint. Freq. (Months)"));
        Assert.AreEqual(
            WarrantyAlertMgt.GetLongestIntervalDays(), EquipmentSetup."Default Warranty Alert Days",
            EquipmentSetup.FieldCaption("Default Warranty Alert Days"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MissingSetupIsNotCreated()
    var
        EquipmentSetup: Record "EQM Equipment Setup";
    begin
        Initialize();
        // [SCENARIO 4] (negative) A missing setup row is not created
        // [GIVEN] No setup row exists
        EquipmentSetup.DeleteAll();

        // [WHEN] The initialization runs
        UpgradeMgt.InitDefaultWarrantyAlertDays();

        // [THEN] There is no error and no setup row
        Assert.RecordIsEmpty(EquipmentSetup);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure InitializationIsIdempotent()
    var
        EquipmentSetup: Record "EQM Equipment Setup";
    begin
        Initialize();
        // [SCENARIO 5] The initialization gives the same result when it runs twice
        // [GIVEN] The setup row has Default Warranty Alert Days = 0
        SetAlertDays(0);

        // [WHEN] The initialization runs twice
        UpgradeMgt.InitDefaultWarrantyAlertDays();
        UpgradeMgt.InitDefaultWarrantyAlertDays();

        // [THEN] The alert days are the longest interval and there is still one setup row
        EquipmentSetup.Get();
        Assert.AreEqual(
            WarrantyAlertMgt.GetLongestIntervalDays(), EquipmentSetup."Default Warranty Alert Days",
            EquipmentSetup.FieldCaption("Default Warranty Alert Days"));
        Assert.AreEqual(1, EquipmentSetup.Count(), EquipmentSetup.TableCaption());
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UpgradeTagStopsSecondRun()
    var
        EquipmentSetup: Record "EQM Equipment Setup";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        Initialize();
        // [SCENARIO 6] (negative) The upgrade tag stops a second run
        // [GIVEN] The upgrade tag of the step is set and the alert days are 0
        EnsureTagSet();
        Assert.IsTrue(UpgradeTag.HasUpgradeTag(UpgradeMgt.GetDefaultWarrantyAlertDaysTag()), 'The upgrade tag should be set');
        SetAlertDays(0);

        // [WHEN] The upgrade step runs
        UpgradeMgt.UpgradeDefaultWarrantyAlertDays();

        // [THEN] The alert days are still 0
        EquipmentSetup.Get();
        Assert.AreEqual(0, EquipmentSetup."Default Warranty Alert Days", EquipmentSetup.FieldCaption("Default Warranty Alert Days"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RetentionPolicyTablesAreRegistered()
    var
        RetenPolAllowedTables: Codeunit "Reten. Pol. Allowed Tables";
    begin
        // [SCENARIO RP1] The error log, warranty alert and integration event tables become allowed tables of retention policies
        // [GIVEN] No setup is needed

        // [WHEN] The registration runs
        UpgradeMgt.AddRetentionPolicyAllowedTables();

        // [THEN] The three tables are allowed tables
        Assert.IsTrue(RetenPolAllowedTables.IsAllowedTable(Database::"EQM Error Log Entry"), 'Error Log Entry');
        Assert.IsTrue(RetenPolAllowedTables.IsAllowedTable(Database::"EQM Warranty Alert"), 'Warranty Alert');
        Assert.IsTrue(RetenPolAllowedTables.IsAllowedTable(Database::"EQM Integration Event Entry"), 'Integration Event Entry');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RetentionPolicyStepIsTagGuardedAndIdempotent()
    var
        RetenPolAllowedTables: Codeunit "Reten. Pol. Allowed Tables";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        // [SCENARIO RP2] The retention policy step sets its tag and can run twice without an error
        // [GIVEN] No setup is needed

        // [WHEN] The step runs twice
        UpgradeMgt.UpgradeRetentionPolicyTables();
        UpgradeMgt.UpgradeRetentionPolicyTables();

        // [THEN] The tag is set and the three tables are still allowed tables
        Assert.IsTrue(UpgradeTag.HasUpgradeTag(UpgradeMgt.GetRetentionPolicyTablesTag()), 'The upgrade tag should be set');
        Assert.IsTrue(RetenPolAllowedTables.IsAllowedTable(Database::"EQM Error Log Entry"), 'Error Log Entry');
        Assert.IsTrue(RetenPolAllowedTables.IsAllowedTable(Database::"EQM Warranty Alert"), 'Warranty Alert');
        Assert.IsTrue(RetenPolAllowedTables.IsAllowedTable(Database::"EQM Integration Event Entry"), 'Integration Event Entry');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AuditAndHistoryTablesAreNeverAllowed()
    var
        RetenPolAllowedTables: Codeunit "Reten. Pol. Allowed Tables";
    begin
        // [SCENARIO RP3] (negative) The audit, maintenance log, history and assignment tables are never allowed tables
        // [GIVEN] No setup is needed

        // [WHEN] The registration runs
        UpgradeMgt.AddRetentionPolicyAllowedTables();

        // [THEN] None of those tables is an allowed table
        Assert.IsFalse(RetenPolAllowedTables.IsAllowedTable(Database::"EQM Equipment Audit Entry"), 'Equipment Audit Entry');
        Assert.IsFalse(RetenPolAllowedTables.IsAllowedTable(Database::"EQM Maintenance Log Entry"), 'Maintenance Log Entry');
        Assert.IsFalse(RetenPolAllowedTables.IsAllowedTable(Database::"EQM Maintenance History Entry"), 'Maintenance History Entry');
        Assert.IsFalse(RetenPolAllowedTables.IsAllowedTable(Database::"EQM Equipment Assignment"), 'Equipment Assignment');
    end;

    local procedure Initialize()
    var
        EquipmentSetup: Record "EQM Equipment Setup";
    begin
        if not EquipmentSetup.Get() then begin
            EquipmentSetup.Init();
            EquipmentSetup.Insert(false);
        end;
    end;

    local procedure SetAlertDays(Value: Integer)
    var
        EquipmentSetup: Record "EQM Equipment Setup";
    begin
        EquipmentSetup.Get();
        EquipmentSetup."Default Warranty Alert Days" := Value;
        EquipmentSetup.Modify(false);
    end;

    local procedure EnsureTagSet()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag(UpgradeMgt.GetDefaultWarrantyAlertDaysTag()) then
            UpgradeTag.SetUpgradeTag(UpgradeMgt.GetDefaultWarrantyAlertDaysTag());
    end;
}
