namespace MiguelCarvalho.EquipmentManagement.Tests;

using MiguelCarvalho.EquipmentManagement;
using System.TestLibraries.Utilities;

/// <summary>
/// FR-045 Automated Unit Tests, area Warranty Calculation. Covers the warranty status and days remaining of table 50100
/// on the procedures themselves (exact boundaries, a blank reference date), and the alert generation and
/// acknowledgement of codeunit 50110 "EQM Warranty Alert Mgt." that the existing tests do not reach.
/// The thresholds come from the app getters, and the dates are random offsets from today.
/// GenerateAlerts reads every equipment in the company, so the assertions filter on the equipment of the test.
/// A failed statement (asserterror) rolls back the whole test transaction, so each test that expects an error has
/// exactly one asserterror, as its last action, and only checks the error text afterwards.
/// </summary>
codeunit 50168 "EQM Warranty Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        WarrantyAlertMgt: Codeunit "EQM Warranty Alert Mgt.";
        Counter: Integer;
        EquipmentNoTok: Label 'EQMWTY%1X', Locked = true;
        CategoryCodeTok: Label 'EQMWTYC%1', Locked = true;
        CounterFormatTok: Label '<Integer,4><Filler Character,0>', Locked = true;
        // Copy of the text of the label in codeunit 50110; labels of another app are not accessible.
        NothingToAcknowledgeErr: Label 'The selected warranty alerts are already acknowledged or cancelled.';

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EndDateTodayIsExpiringSoon()
    var
        Equipment: Record "EQM Equipment";
    begin
        // [SCENARIO W1] A warranty that ends today is Expiring Soon
        // [GIVEN] Equipment E whose warranty ends today
        Equipment."Warranty End Date" := Today();

        // [WHEN] The warranty status is calculated for today
        // [THEN] It is Expiring Soon
        Assert.AreEqual("EQM Warranty Status"::"Expiring Soon", Equipment.CalcWarrantyStatus(Today()), 'Warranty status');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EndDateOnTheLastExpiringSoonDayIsExpiringSoon()
    var
        Equipment: Record "EQM Equipment";
    begin
        // [SCENARIO W2] (boundary) A warranty that ends exactly the expiring soon days after the reference date is Expiring Soon
        // [GIVEN] Equipment E whose warranty ends the expiring soon days after today
        Equipment."Warranty End Date" := Today() + Equipment.GetWarrantyExpiringSoonDays();

        // [WHEN] The warranty status is calculated for today
        // [THEN] It is Expiring Soon
        Assert.AreEqual("EQM Warranty Status"::"Expiring Soon", Equipment.CalcWarrantyStatus(Today()), 'Warranty status');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EndDateOneDayBeyondTheWindowIsActive()
    var
        Equipment: Record "EQM Equipment";
    begin
        // [SCENARIO W3] (boundary) A warranty that ends one day after the expiring soon window is Active
        // [GIVEN] Equipment E whose warranty ends the expiring soon days plus one day after today
        Equipment."Warranty End Date" := Today() + Equipment.GetWarrantyExpiringSoonDays() + 1;

        // [WHEN] The warranty status is calculated for today
        // [THEN] It is Active
        Assert.AreEqual("EQM Warranty Status"::Active, Equipment.CalcWarrantyStatus(Today()), 'Warranty status');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EndDateYesterdayIsExpired()
    var
        Equipment: Record "EQM Equipment";
    begin
        // [SCENARIO W4] (boundary) A warranty that ended yesterday is Expired
        // [GIVEN] Equipment E whose warranty ended yesterday
        Equipment."Warranty End Date" := Today() - 1;

        // [WHEN] The warranty status is calculated for today
        // [THEN] It is Expired
        Assert.AreEqual("EQM Warranty Status"::Expired, Equipment.CalcWarrantyStatus(Today()), 'Warranty status');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BlankReferenceDateMeansToday()
    var
        Equipment: Record "EQM Equipment";
    begin
        // [SCENARIO W5] A blank reference date is today
        // [GIVEN] Equipment E whose warranty ended yesterday
        Equipment."Warranty End Date" := Today() - 1;

        // [WHEN] The warranty status is calculated with a blank reference date
        // [THEN] It is Expired, as it is for today
        Assert.AreEqual("EQM Warranty Status"::Expired, Equipment.CalcWarrantyStatus(0D), 'Warranty status');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DaysRemainingCountsToTheEndDate()
    var
        Equipment: Record "EQM Equipment";
        Days: Integer;
    begin
        // [SCENARIO W6] The days remaining are the days from the reference date to the end date
        // [GIVEN] Equipment E whose warranty ends a random number of days after today
        Days := 1 + Random(365);
        Equipment."Warranty End Date" := Today() + Days;

        // [WHEN] The days remaining are calculated for today
        // [THEN] They equal the number of days
        Assert.AreEqual(Days, Equipment.GetWarrantyDaysRemaining(Today()), 'Days remaining');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DaysRemainingAreNegativeAfterTheEndDate()
    var
        Equipment: Record "EQM Equipment";
        Days: Integer;
    begin
        // [SCENARIO W7] (negative) The days remaining are negative after the end date
        // [GIVEN] Equipment E whose warranty ended a random number of days before today
        Days := 1 + Random(365);
        Equipment."Warranty End Date" := Today() - Days;

        // [WHEN] The days remaining are calculated for today
        // [THEN] They equal the number of days, negated
        Assert.AreEqual(-Days, Equipment.GetWarrantyDaysRemaining(Today()), 'Days remaining');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DaysRemainingAreZeroWithoutAnEndDate()
    var
        Equipment: Record "EQM Equipment";
    begin
        // [SCENARIO W8] (negative) Equipment without a warranty end date has 0 days remaining
        // [GIVEN] Equipment E without a warranty end date
        Equipment."Warranty End Date" := 0D;

        // [WHEN] The days remaining are calculated for today
        // [THEN] They are 0
        Assert.AreEqual(0, Equipment.GetWarrantyDaysRemaining(Today()), 'Days remaining');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DueIntervalIsTheMostUrgentOne()
    var
        Interval30: Integer;
        Interval60: Integer;
        Interval90: Integer;
    begin
        // [SCENARIO W9] The due interval is the most urgent interval that the days remaining fit in
        // [GIVEN] The 30, 60 and 90 day intervals
        Interval30 := WarrantyAlertMgt.GetIntervalDays("EQM Warranty Alert Interval"::"30 Days");
        Interval60 := WarrantyAlertMgt.GetIntervalDays("EQM Warranty Alert Interval"::"60 Days");
        Interval90 := WarrantyAlertMgt.GetIntervalDays("EQM Warranty Alert Interval"::"90 Days");

        // [WHEN] The due interval is found for days remaining on and just after each boundary
        // [THEN] The most urgent interval that fits is returned
        AssertDueInterval(0, "EQM Warranty Alert Interval"::"30 Days");
        AssertDueInterval(Interval30, "EQM Warranty Alert Interval"::"30 Days");
        AssertDueInterval(Interval30 + 1, "EQM Warranty Alert Interval"::"60 Days");
        AssertDueInterval(Interval60, "EQM Warranty Alert Interval"::"60 Days");
        AssertDueInterval(Interval60 + 1, "EQM Warranty Alert Interval"::"90 Days");
        AssertDueInterval(Interval90, "EQM Warranty Alert Interval"::"90 Days");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NoIntervalIsDueOutsideTheRange()
    var
        AlertInterval: Enum "EQM Warranty Alert Interval";
    begin
        // [SCENARIO W10] (negative) No interval is due for negative days or for days beyond the longest interval
        // [GIVEN] The longest interval
        // [WHEN] The due interval is found for -1 day and for the longest interval plus one day
        // [THEN] No interval is due in either case
        Assert.IsFalse(WarrantyAlertMgt.FindDueInterval(-1, AlertInterval), 'No interval should be due for negative days');
        Assert.IsFalse(WarrantyAlertMgt.FindDueInterval(WarrantyAlertMgt.GetLongestIntervalDays() + 1, AlertInterval), 'No interval should be due beyond the longest interval');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SecondAlertRunCreatesNoDuplicate()
    var
        Equipment: Record "EQM Equipment";
        WarrantyAlert: Record "EQM Warranty Alert";
        CreatedCount: Integer;
        CancelledCount: Integer;
    begin
        Initialize();
        // [SCENARIO W11] (negative) Running the alert generation twice does not create a second alert
        // [GIVEN] Equipment E whose warranty ends inside the alert days, and one alert run
        CreateEquipment(Equipment, Today() + Random(WarrantyAlertMgt.GetLongestIntervalDays()));
        WarrantyAlertMgt.GenerateAlerts(Today(), false, CreatedCount, CancelledCount);
        FilterAlerts(WarrantyAlert, Equipment."No.");
        Assert.RecordCount(WarrantyAlert, 1);

        // [WHEN] The alerts are generated again
        WarrantyAlertMgt.GenerateAlerts(Today(), false, CreatedCount, CancelledCount);

        // [THEN] The second run creates nothing and E still has one alert
        Assert.AreEqual(0, CreatedCount, 'The second run should create no alert');
        Assert.RecordCount(WarrantyAlert, 1);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DisposedEquipmentGetsNoAlert()
    var
        Equipment: Record "EQM Equipment";
        WarrantyAlert: Record "EQM Warranty Alert";
        CreatedCount: Integer;
        CancelledCount: Integer;
    begin
        Initialize();
        // [SCENARIO W12] (negative) Disposed equipment gets no alert
        // [GIVEN] Disposed equipment E whose warranty ends inside the alert days
        CreateEquipment(Equipment, Today() + Random(WarrantyAlertMgt.GetLongestIntervalDays()));
        Equipment.Status := Equipment.Status::Disposed;
        Equipment.Modify(false);

        // [WHEN] The alerts are generated
        WarrantyAlertMgt.GenerateAlerts(Today(), false, CreatedCount, CancelledCount);

        // [THEN] E has no alert
        FilterAlerts(WarrantyAlert, Equipment."No.");
        Assert.RecordIsEmpty(WarrantyAlert);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ExpiredWarrantyGetsNoAlert()
    var
        Equipment: Record "EQM Equipment";
        WarrantyAlert: Record "EQM Warranty Alert";
        CreatedCount: Integer;
        CancelledCount: Integer;
    begin
        Initialize();
        // [SCENARIO W13] (negative) Equipment whose warranty already expired gets no alert
        // [GIVEN] Equipment E whose warranty ended a random number of days ago
        CreateEquipment(Equipment, Today() - 1 - Random(365));

        // [WHEN] The alerts are generated
        WarrantyAlertMgt.GenerateAlerts(Today(), false, CreatedCount, CancelledCount);

        // [THEN] E has no alert
        FilterAlerts(WarrantyAlert, Equipment."No.");
        Assert.RecordIsEmpty(WarrantyAlert);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ChangingTheEndDateCancelsTheOpenAlertAndCreatesANewOne()
    var
        Equipment: Record "EQM Equipment";
        WarrantyAlert: Record "EQM Warranty Alert";
        CreatedCount: Integer;
        CancelledCount: Integer;
        OldEndDate: Date;
        NewEndDate: Date;
    begin
        Initialize();
        // [SCENARIO W14] Changing the warranty end date cancels the open alert and creates a new one
        // [GIVEN] Equipment E with an open alert for its warranty end date
        OldEndDate := Today() + Random(Equipment.GetWarrantyExpiringSoonDays());
        CreateEquipment(Equipment, OldEndDate);
        WarrantyAlertMgt.GenerateAlerts(Today(), false, CreatedCount, CancelledCount);
        Assert.IsTrue(WarrantyAlertMgt.HasOpenAlert(Equipment."No.", OldEndDate), 'The first run should create an open alert');

        // [WHEN] The end date of E is changed to a later date inside the alert days and the alerts are generated
        NewEndDate := OldEndDate + Equipment.GetWarrantyExpiringSoonDays();
        Equipment.Validate("Warranty End Date", NewEndDate);
        Equipment.Modify(true);
        WarrantyAlertMgt.GenerateAlerts(Today(), false, CreatedCount, CancelledCount);

        // [THEN] The alert of the old date is Cancelled, and an alert of the new date is Open
        FilterAlerts(WarrantyAlert, Equipment."No.");
        WarrantyAlert.SetRange("Warranty End Date", OldEndDate);
        WarrantyAlert.SetFilter(Status, '<>%1', WarrantyAlert.Status::Cancelled);
        Assert.RecordIsEmpty(WarrantyAlert);
        Assert.IsTrue(WarrantyAlertMgt.HasOpenAlert(Equipment."No.", NewEndDate), 'The new end date should have an open alert');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AcknowledgeRecordsStatusUserAndTime()
    var
        Equipment: Record "EQM Equipment";
        WarrantyAlert: Record "EQM Warranty Alert";
        CreatedCount: Integer;
        CancelledCount: Integer;
    begin
        Initialize();
        // [SCENARIO W15] Acknowledging an open alert records the status, the user and the time
        // [GIVEN] Equipment E with one open alert
        CreateEquipment(Equipment, Today() + Random(WarrantyAlertMgt.GetLongestIntervalDays()));
        WarrantyAlertMgt.GenerateAlerts(Today(), false, CreatedCount, CancelledCount);
        FilterAlerts(WarrantyAlert, Equipment."No.");

        // [WHEN] The alert is acknowledged
        Assert.AreEqual(1, WarrantyAlertMgt.AcknowledgeAlerts(WarrantyAlert), 'One alert should be acknowledged');

        // [THEN] The alert is Acknowledged by the current user at a time
        WarrantyAlert.FindFirst();
        Assert.AreEqual(WarrantyAlert.Status::Acknowledged, WarrantyAlert.Status, 'Alert status');
        Assert.AreEqual(CopyStr(UserId(), 1, MaxStrLen(WarrantyAlert."Acknowledged By")), WarrantyAlert."Acknowledged By", 'Acknowledged by should be the current user');
        Assert.AreNotEqual(0DT, WarrantyAlert."Acknowledged At", 'Acknowledged at should be filled in');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AcknowledgeWithNothingOpenIsRejected()
    var
        Equipment: Record "EQM Equipment";
        WarrantyAlert: Record "EQM Warranty Alert";
        CreatedCount: Integer;
        CancelledCount: Integer;
    begin
        Initialize();
        // [SCENARIO W16] (negative) Acknowledging alerts that are already acknowledged is rejected
        // [GIVEN] Equipment E whose only alert is already acknowledged
        CreateEquipment(Equipment, Today() + Random(WarrantyAlertMgt.GetLongestIntervalDays()));
        WarrantyAlertMgt.GenerateAlerts(Today(), false, CreatedCount, CancelledCount);
        FilterAlerts(WarrantyAlert, Equipment."No.");
        WarrantyAlertMgt.AcknowledgeAlerts(WarrantyAlert);

        // [WHEN] The alerts of E are acknowledged again
        asserterror WarrantyAlertMgt.AcknowledgeAlerts(WarrantyAlert);

        // [THEN] The nothing to acknowledge error is raised
        Assert.ExpectedError(NothingToAcknowledgeErr);
    end;

    local procedure Initialize()
    var
        FeatureSetup: Record "EQM Feature Setup";
        EquipmentSetup: Record "EQM Equipment Setup";
    begin
        // Everything runs in the test transaction, which is rolled back (AutoRollback), so nothing is committed or cleaned up.
        FeatureSetup.DeleteAll();
        if not EquipmentSetup.Get() then begin
            EquipmentSetup.Init();
            EquipmentSetup.Insert(false);
        end;
        EquipmentSetup."Default Warranty Alert Days" := WarrantyAlertMgt.GetLongestIntervalDays();
        EquipmentSetup.Modify(false);
    end;

    local procedure NextId(): Text
    begin
        Counter += 1;
        exit(Format(Counter, 0, CounterFormatTok));
    end;

    local procedure CreateEquipment(var Equipment: Record "EQM Equipment"; WarrantyEndDate: Date)
    var
        Category: Record "EQM Equipment Category";
    begin
        Category.Init();
        Category.Code := CopyStr(StrSubstNo(CategoryCodeTok, NextId()), 1, MaxStrLen(Category.Code));
        Category.Description := Category.Code;
        Category.Active := true;
        Category.Insert(false);

        Equipment.Init();
        Equipment."No." := CopyStr(StrSubstNo(EquipmentNoTok, NextId()), 1, MaxStrLen(Equipment."No."));
        Equipment.Description := Equipment."No.";
        Equipment."Category Code" := Category.Code;
        Equipment."Warranty End Date" := WarrantyEndDate;
        Equipment.Insert(true);
    end;

    local procedure FilterAlerts(var WarrantyAlert: Record "EQM Warranty Alert"; EquipmentNo: Code[20])
    begin
        WarrantyAlert.Reset();
        WarrantyAlert.SetRange("Equipment No.", EquipmentNo);
    end;

    local procedure AssertDueInterval(DaysRemaining: Integer; ExpectedInterval: Enum "EQM Warranty Alert Interval")
    var
        AlertInterval: Enum "EQM Warranty Alert Interval";
    begin
        Assert.IsTrue(WarrantyAlertMgt.FindDueInterval(DaysRemaining, AlertInterval), 'An interval should be due');
        Assert.AreEqual(ExpectedInterval, AlertInterval, 'Due interval');
    end;
}
