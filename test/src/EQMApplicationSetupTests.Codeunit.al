namespace MiguelCarvalho.EquipmentManagement.Tests;

using MiguelCarvalho.EquipmentManagement;
using System.TestLibraries.Utilities;

codeunit 50199 "EQM Application Setup Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        FeatureMgt: Codeunit "EQM Feature Mgt.";
        WarrantyAlertMgt: Codeunit "EQM Warranty Alert Mgt.";
        NotificationMgt: Codeunit "EQM Notification Mgt.";
        Counter: Integer;
        SentNotificationCount: Integer;
        EquipmentNoTok: Label 'ASEQ%1X', Locked = true;
        CategoryCodeTok: Label 'ASCAT%1', Locked = true;
        CounterFormatTok: Label '<Integer,4><Filler Character,0>', Locked = true;
        // Copy of the internal label of table 50102; labels of another app are not accessible.
        ValueOutOfRangeErr: Label '%1 must be between %2 and %3. You entered %4.', Comment = '%1 = field caption, %2 = lowest allowed value, %3 = highest allowed value, %4 = the value that was entered';

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure WarrantyOutsideAlertDaysCreatesNoAlert()
    var
        Equipment: Record "EQM Equipment";
        WarrantyAlert: Record "EQM Warranty Alert";
        CreatedCount: Integer;
        CancelledCount: Integer;
        ThirtyDays: Integer;
    begin
        Initialize();
        // [SCENARIO 1] (negative) Equipment whose warranty ends outside the alert days gets no alert
        // [GIVEN] Default Warranty Alert Days is the 30-day interval and equipment E has a warranty ending 15 days after that
        ThirtyDays := WarrantyAlertMgt.GetIntervalDays("EQM Warranty Alert Interval"::"30 Days");
        SetSetupDefaults(ThirtyDays, 0);
        CreateEquipment(Equipment, Today() + ThirtyDays + 15);

        // [WHEN] Alerts are generated
        WarrantyAlertMgt.GenerateAlerts(Today(), false, CreatedCount, CancelledCount);

        // [THEN] No alert exists for E
        WarrantyAlert.SetRange("Equipment No.", Equipment."No.");
        Assert.IsTrue(WarrantyAlert.IsEmpty(), 'No alert should be created outside the alert days');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure WarrantyInsideAlertDaysCreatesAlert()
    var
        Equipment: Record "EQM Equipment";
        WarrantyAlert: Record "EQM Warranty Alert";
        CreatedCount: Integer;
        CancelledCount: Integer;
        ThirtyDays: Integer;
    begin
        Initialize();
        // [SCENARIO 2] Equipment whose warranty ends inside the alert days gets the matching alert
        // [GIVEN] Default Warranty Alert Days is the 30-day interval and equipment E has a warranty ending 10 days before that
        ThirtyDays := WarrantyAlertMgt.GetIntervalDays("EQM Warranty Alert Interval"::"30 Days");
        SetSetupDefaults(ThirtyDays, 0);
        CreateEquipment(Equipment, Today() + ThirtyDays - 10);

        // [WHEN] Alerts are generated
        WarrantyAlertMgt.GenerateAlerts(Today(), false, CreatedCount, CancelledCount);

        // [THEN] Exactly one alert exists for E, with the 30-day interval
        WarrantyAlert.SetRange("Equipment No.", Equipment."No.");
        Assert.AreEqual(1, WarrantyAlert.Count(), 'One alert should be created');
        WarrantyAlert.FindFirst();
        Assert.AreEqual("EQM Warranty Alert Interval"::"30 Days", WarrantyAlert."Alert Interval", 'Alert interval');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BlankAlertDaysUseTheLongestInterval()
    var
        Equipment: Record "EQM Equipment";
        WarrantyAlert: Record "EQM Warranty Alert";
        CreatedCount: Integer;
        CancelledCount: Integer;
        LongestDays: Integer;
    begin
        Initialize();
        // [SCENARIO 3] A blank Default Warranty Alert Days (setup from before this feature) means 90 days
        // [GIVEN] Default Warranty Alert Days is blank and equipment E has a warranty ending 10 days before the longest interval
        LongestDays := WarrantyAlertMgt.GetLongestIntervalDays();
        SetSetupDefaults(0, 0);
        CreateEquipment(Equipment, Today() + LongestDays - 10);

        // [WHEN] Alerts are generated
        WarrantyAlertMgt.GenerateAlerts(Today(), false, CreatedCount, CancelledCount);

        // [THEN] The alert days are the longest interval and E has the 90-day alert
        Assert.AreEqual(LongestDays, WarrantyAlertMgt.GetWarrantyAlertDays(), 'Alert days');
        WarrantyAlert.SetRange("Equipment No.", Equipment."No.");
        Assert.AreEqual(1, WarrantyAlert.Count(), 'One alert should be created');
        WarrantyAlert.FindFirst();
        Assert.AreEqual("EQM Warranty Alert Interval"::"90 Days", WarrantyAlert."Alert Interval", 'Alert interval');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AlertDaysAboveTheLongestIntervalAreRejected()
    var
        EquipmentSetup: Record "EQM Equipment Setup";
        LongestDays: Integer;
    begin
        Initialize();
        // [SCENARIO 4] (negative) Default Warranty Alert Days above the longest interval is rejected
        // [GIVEN] The equipment setup
        EquipmentSetup.Get();
        LongestDays := WarrantyAlertMgt.GetLongestIntervalDays();

        // [WHEN] The field is validated with one day more than the longest interval
        asserterror EquipmentSetup.Validate("Default Warranty Alert Days", LongestDays + 1);

        // [THEN] The out-of-range error is raised
        Assert.ExpectedError(StrSubstNo(ValueOutOfRangeErr, EquipmentSetup.FieldCaption("Default Warranty Alert Days"), 1, LongestDays, LongestDays + 1));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AlertDaysOfZeroAreRejected()
    var
        EquipmentSetup: Record "EQM Equipment Setup";
    begin
        Initialize();
        // [SCENARIO 5] (negative) Default Warranty Alert Days of 0 is rejected
        // [GIVEN] The equipment setup
        EquipmentSetup.Get();

        // [WHEN] The field is validated with 0
        asserterror EquipmentSetup.Validate("Default Warranty Alert Days", 0);

        // [THEN] The out-of-range error is raised
        Assert.ExpectedError(StrSubstNo(ValueOutOfRangeErr, EquipmentSetup.FieldCaption("Default Warranty Alert Days"), 1, WarrantyAlertMgt.GetLongestIntervalDays(), 0));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NewSetupStartsWithTheLongestInterval()
    var
        EquipmentSetup: Record "EQM Equipment Setup";
    begin
        Initialize();
        // [SCENARIO 6] A new setup record starts with the longest interval as alert days
        // [GIVEN] A setup record that is initialized but not inserted
        // [WHEN] Init is called
        EquipmentSetup.Init();

        // [THEN] Default Warranty Alert Days is the longest interval
        Assert.AreEqual(WarrantyAlertMgt.GetLongestIntervalDays(), EquipmentSetup."Default Warranty Alert Days", 'Initial alert days');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NewEquipmentGetsTheDefaultMaintenanceFrequency()
    var
        Equipment: Record "EQM Equipment";
    begin
        Initialize();
        // [SCENARIO 7] New equipment gets the default maintenance frequency
        // [GIVEN] Default Maintenance Frequency is 6
        SetSetupDefaults(0, 6);
        Equipment.Init();

        // [WHEN] The setup defaults are applied
        Equipment.ApplySetupDefaults();

        // [THEN] The maintenance frequency is 6
        Assert.AreEqual(6, Equipment."Maintenance Frequency (Months)", 'Maintenance frequency');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NoDefaultLeavesTheMaintenanceFrequencyEmpty()
    var
        Equipment: Record "EQM Equipment";
    begin
        Initialize();
        // [SCENARIO 8] (negative) Without a default the maintenance frequency stays 0
        // [GIVEN] Default Maintenance Frequency is 0
        SetSetupDefaults(0, 0);
        Equipment.Init();

        // [WHEN] The setup defaults are applied
        Equipment.ApplySetupDefaults();

        // [THEN] The maintenance frequency is 0
        Assert.AreEqual(0, Equipment."Maintenance Frequency (Months)", 'Maintenance frequency');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DefaultDoesNotOverwriteAFilledFrequency()
    var
        Equipment: Record "EQM Equipment";
    begin
        Initialize();
        // [SCENARIO 9] (negative) The default does not overwrite a maintenance frequency that is already filled in
        // [GIVEN] Default Maintenance Frequency is 6 and the equipment has a frequency of 3
        SetSetupDefaults(0, 6);
        Equipment.Init();
        Equipment."Maintenance Frequency (Months)" := 3;

        // [WHEN] The setup defaults are applied
        Equipment.ApplySetupDefaults();

        // [THEN] The maintenance frequency is still 3
        Assert.AreEqual(3, Equipment."Maintenance Frequency (Months)", 'Maintenance frequency');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NewEquipmentCardShowsTheDefaultMaintenanceFrequency()
    var
        EquipmentCard: TestPage "EQM Equipment Card";
    begin
        Initialize();
        // [SCENARIO 10] A new equipment card shows the default maintenance frequency
        // [GIVEN] Default Maintenance Frequency is 6
        SetSetupDefaults(0, 6);

        // [WHEN] The card is opened new
        EquipmentCard.OpenNew();

        // [THEN] The maintenance frequency shows 6
        Assert.AreEqual(6, EquipmentCard."Maintenance Frequency (Months)".AsInteger(), 'Maintenance frequency');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EquipmentCreatedInCodeIgnoresTheDefaultMaintenanceFrequency()
    var
        Equipment: Record "EQM Equipment";
    begin
        Initialize();
        // [SCENARIO 11] (negative) Equipment created in code does not get the default maintenance frequency
        // [GIVEN] Default Maintenance Frequency is 6
        SetSetupDefaults(0, 6);

        // [WHEN] Equipment is inserted in code
        CreateEquipment(Equipment, 0D);

        // [THEN] The stored maintenance frequency is 0
        Equipment.Get(Equipment."No.");
        Assert.AreEqual(0, Equipment."Maintenance Frequency (Months)", 'Maintenance frequency');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MaintenanceFrequencyAbove120IsRejected()
    var
        EquipmentSetup: Record "EQM Equipment Setup";
    begin
        Initialize();
        // [SCENARIO 12] (negative) Default Maintenance Frequency above 120 is rejected
        // [GIVEN] The equipment setup
        EquipmentSetup.Get();

        // [WHEN] The field is validated with 121
        asserterror EquipmentSetup.Validate("Default Maint. Freq. (Months)", 121);

        // [THEN] The out-of-range error is raised
        Assert.ExpectedError(StrSubstNo(ValueOutOfRangeErr, EquipmentSetup.FieldCaption("Default Maint. Freq. (Months)"), 0, 120, 121));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SetupPageShowsTheFeatureSwitches()
    var
        EquipmentSetup: TestPage "EQM Equipment Setup";
    begin
        Initialize();
        // [SCENARIO 13] The setup page shows the state of the features
        // [GIVEN] Notifications is turned off
        FeatureMgt.SetFeatureEnabled(Enum::"EQM Feature"::Notifications, false);

        // [WHEN] The setup page is opened for editing
        EquipmentSetup.OpenEdit();

        // [THEN] Enable Notifications is off, the other two switches are on
        Assert.IsFalse(EquipmentSetup.EnableNotifications.AsBoolean(), 'Enable Notifications');
        Assert.IsTrue(EquipmentSetup.EnableEquipmentRequests.AsBoolean(), 'Enable Equipment Requests');
        Assert.IsTrue(EquipmentSetup.EnableApis.AsBoolean(), 'Enable APIs');
        EquipmentSetup.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TurningOffEquipmentRequestsTurnsOffApprovalWorkflows()
    var
        EquipmentSetup: TestPage "EQM Equipment Setup";
    begin
        Initialize();
        // [SCENARIO 14] Enable Equipment Requests is the Approval Workflows feature
        // [GIVEN] No feature setup rows

        // [WHEN] Enable Equipment Requests is turned off on the setup page
        EquipmentSetup.OpenEdit();
        EquipmentSetup.EnableEquipmentRequests.SetValue(false);
        EquipmentSetup.Close();

        // [THEN] Approval Workflows is off; Notifications and API Integration stay on
        Assert.IsFalse(FeatureMgt.IsEnabled(Enum::"EQM Feature"::"Approval Workflows"), 'Approval Workflows');
        Assert.IsTrue(FeatureMgt.IsEnabled(Enum::"EQM Feature"::Notifications), 'Notifications');
        Assert.IsTrue(FeatureMgt.IsEnabled(Enum::"EQM Feature"::"API Integration"), 'API Integration');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TurningOnApisTurnsOnApiIntegration()
    var
        EquipmentSetup: TestPage "EQM Equipment Setup";
    begin
        Initialize();
        // [SCENARIO 15] Enable APIs is the API Integration feature
        // [GIVEN] API Integration is turned off
        FeatureMgt.SetFeatureEnabled(Enum::"EQM Feature"::"API Integration", false);

        // [WHEN] Enable APIs is turned on on the setup page
        EquipmentSetup.OpenEdit();
        EquipmentSetup.EnableApis.SetValue(true);
        EquipmentSetup.Close();

        // [THEN] API Integration is on
        Assert.IsTrue(FeatureMgt.IsEnabled(Enum::"EQM Feature"::"API Integration"), 'API Integration');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SetupPageSavesTheDefaults()
    var
        EquipmentSetup: Record "EQM Equipment Setup";
        EquipmentSetupPage: TestPage "EQM Equipment Setup";
        SixtyDays: Integer;
    begin
        Initialize();
        // [SCENARIO 16] The defaults entered on the setup page are saved
        // [GIVEN] The setup page is open for editing
        SixtyDays := WarrantyAlertMgt.GetIntervalDays("EQM Warranty Alert Interval"::"60 Days");
        EquipmentSetupPage.OpenEdit();

        // [WHEN] The alert days are set to the 60-day interval and the maintenance frequency to 12
        EquipmentSetupPage."Default Warranty Alert Days".SetValue(SixtyDays);
        EquipmentSetupPage."Default Maint. Freq. (Months)".SetValue(12);
        EquipmentSetupPage.Close();

        // [THEN] The setup stores 60 and 12
        EquipmentSetup.Get();
        Assert.AreEqual(SixtyDays, EquipmentSetup."Default Warranty Alert Days", 'Alert days');
        Assert.AreEqual(12, EquipmentSetup."Default Maint. Freq. (Months)", 'Maintenance frequency');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SetupPageHidesDefaultsOfDisabledFeatures()
    var
        EquipmentSetup: TestPage "EQM Equipment Setup";
    begin
        Initialize();
        // [SCENARIO 17] (negative) The default fields are hidden when their feature is off
        // [GIVEN] Warranty Alerts and Maintenance Planning are turned off
        FeatureMgt.SetFeatureEnabled(Enum::"EQM Feature"::"Warranty Alerts", false);
        FeatureMgt.SetFeatureEnabled(Enum::"EQM Feature"::"Maintenance Planning", false);

        // [WHEN] The setup page is opened
        EquipmentSetup.OpenView();

        // [THEN] Both default fields are hidden and Enable Notifications is visible
        Assert.IsFalse(EquipmentSetup."Default Warranty Alert Days".Visible(), 'Default Warranty Alert Days should be hidden');
        Assert.IsFalse(EquipmentSetup."Default Maint. Freq. (Months)".Visible(), 'Default Maintenance Frequency should be hidden');
        Assert.IsTrue(EquipmentSetup.EnableNotifications.Visible(), 'Enable Notifications should be visible');
        EquipmentSetup.Close();
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NoNotificationWhenNotificationsAreOff()
    var
        Equipment: Record "EQM Equipment";
    begin
        Initialize();
        // [SCENARIO 18] (negative) No notification is sent while the Notifications feature is off
        // [GIVEN] Notifications is turned off and equipment E is available
        NotificationMgt.RegisterDefaultNotifications();
        FeatureMgt.SetFeatureEnabled(Enum::"EQM Feature"::Notifications, false);
        CreateEquipment(Equipment, 0D);

        // [WHEN] The returned-from-maintenance notification is requested
        NotificationMgt.SendReturnedFromMaintenanceNotification(Equipment."No.", "EQM Equipment Status"::"In Maintenance");

        // [THEN] Nothing is sent
        Assert.AreEqual(0, SentNotificationCount, 'No notification should be sent');
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NotificationIsSentWhenNotificationsAreOn()
    var
        Equipment: Record "EQM Equipment";
    begin
        Initialize();
        // [SCENARIO 19] The notification is sent while the Notifications feature is on
        // [GIVEN] No feature setup rows and equipment E is available
        NotificationMgt.RegisterDefaultNotifications();
        CreateEquipment(Equipment, 0D);

        // [WHEN] The returned-from-maintenance notification is requested
        NotificationMgt.SendReturnedFromMaintenanceNotification(Equipment."No.", "EQM Equipment Status"::"In Maintenance");

        // [THEN] One notification is sent
        Assert.AreEqual(1, SentNotificationCount, 'One notification should be sent');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NotificationsFeatureHasADescription()
    begin
        Initialize();
        // [SCENARIO 20] The Notifications feature has a description
        // [GIVEN] The feature management codeunit
        // [WHEN] The description is requested
        // [THEN] It is not blank
        Assert.AreNotEqual('', FeatureMgt.GetFeatureDescription(Enum::"EQM Feature"::Notifications), 'Description');
    end;

    [SendNotificationHandler(true)]
    procedure SendNotificationHandler(var TheNotification: Notification): Boolean
    begin
        SentNotificationCount += 1;
        exit(true);
    end;

    local procedure Initialize()
    var
        FeatureSetup: Record "EQM Feature Setup";
        EquipmentSetup: Record "EQM Equipment Setup";
    begin
        FeatureSetup.DeleteAll();
        if not EquipmentSetup.Get() then begin
            EquipmentSetup.Init();
            EquipmentSetup.Insert(false);
        end;
        SentNotificationCount := 0;
    end;

    local procedure SetSetupDefaults(AlertDays: Integer; MaintenanceFrequency: Integer)
    var
        EquipmentSetup: Record "EQM Equipment Setup";
    begin
        EquipmentSetup.Get();
        EquipmentSetup."Default Warranty Alert Days" := AlertDays;
        EquipmentSetup."Default Maint. Freq. (Months)" := MaintenanceFrequency;
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
}
