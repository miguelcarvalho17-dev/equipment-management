namespace MiguelCarvalho.EquipmentManagement.Tests;

using Microsoft.HumanResources.Employee;
using MiguelCarvalho.EquipmentManagement;
using System.TestLibraries.Utilities;

codeunit 50198 "EQM Feature Mgt. Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        FeatureMgt: Codeunit "EQM Feature Mgt.";
        Counter: Integer;
        EquipmentNoTok: Label 'FMEQ%1X', Locked = true;
        CategoryCodeTok: Label 'FMCAT%1', Locked = true;
        EmployeeNoTok: Label 'FMEMP%1', Locked = true;
        CounterFormatTok: Label '<Integer,4><Filler Character,0>', Locked = true;
        // Copy of the internal label of codeunit 50138; labels of another app are not accessible.
        FeatureDisabledErr: Label 'The %1 feature is turned off in this company. To use it, ask an administrator to turn it on in the Equipment Features page.', Comment = '%1 = feature name';

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure WithoutConfigurationEveryFeatureIsEnabled()
    var
        Ordinal: Integer;
    begin
        Initialize();
        // [SCENARIO 1] Without configuration every feature is enabled
        // [GIVEN] No feature setup rows (Initialize)

        // [WHEN] IsEnabled is called for each feature
        // [THEN] Each returns true
        foreach Ordinal in Enum::"EQM Feature".Ordinals() do
            Assert.IsTrue(FeatureMgt.IsEnabled(Enum::"EQM Feature".FromInteger(Ordinal)), 'Feature should be enabled without a row');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TurningOneFeatureOffLeavesOthersOn()
    var
        Ordinal: Integer;
        Feature: Enum "EQM Feature";
    begin
        Initialize();
        // [SCENARIO 2] Turning one feature off leaves the others on
        // [GIVEN] Warranty Alerts is turned off
        FeatureMgt.SetFeatureEnabled(Enum::"EQM Feature"::"Warranty Alerts", false);

        // [WHEN] IsEnabled is called for all five
        // [THEN] Warranty Alerts is off and the other four are on
        foreach Ordinal in Enum::"EQM Feature".Ordinals() do begin
            Feature := Enum::"EQM Feature".FromInteger(Ordinal);
            if Feature = Enum::"EQM Feature"::"Warranty Alerts" then
                Assert.IsFalse(FeatureMgt.IsEnabled(Feature), 'Warranty Alerts should be off')
            else
                Assert.IsTrue(FeatureMgt.IsEnabled(Feature), 'Other features should stay on');
        end;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FeatureCanBeTurnedOnAgain()
    var
        FeatureSetup: Record "EQM Feature Setup";
    begin
        Initialize();
        // [SCENARIO 3] A feature can be turned on again
        // [GIVEN] Approval Workflows was turned off
        FeatureMgt.SetFeatureEnabled(Enum::"EQM Feature"::"Approval Workflows", false);
        Assert.IsFalse(FeatureMgt.IsEnabled(Enum::"EQM Feature"::"Approval Workflows"), 'Approval Workflows should be off');

        // [WHEN] It is turned on
        FeatureMgt.SetFeatureEnabled(Enum::"EQM Feature"::"Approval Workflows", true);

        // [THEN] IsEnabled is true and exactly one row exists for it
        Assert.IsTrue(FeatureMgt.IsEnabled(Enum::"EQM Feature"::"Approval Workflows"), 'Approval Workflows should be on');
        FeatureSetup.SetRange(Feature, Enum::"EQM Feature"::"Approval Workflows");
        Assert.AreEqual(1, FeatureSetup.Count(), 'Exactly one row should exist');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure InitializeFeaturesCreatesRowsAndKeepsChoices()
    var
        FeatureSetup: Record "EQM Feature Setup";
    begin
        Initialize();
        // [SCENARIO 4] InitializeFeatures creates one enabled row per feature and keeps existing choices
        // [GIVEN] Maintenance Planning was turned off
        FeatureMgt.SetFeatureEnabled(Enum::"EQM Feature"::"Maintenance Planning", false);

        // [WHEN] InitializeFeatures runs twice
        FeatureMgt.InitializeFeatures();
        FeatureMgt.InitializeFeatures();

        // [THEN] There is one row per feature, Maintenance Planning is still off and every other row is enabled
        Assert.AreEqual(Enum::"EQM Feature".Ordinals().Count(), FeatureSetup.Count(), 'One row per feature');
        FeatureSetup.Get(Enum::"EQM Feature"::"Maintenance Planning");
        Assert.IsFalse(FeatureSetup.Enabled, 'Maintenance Planning should stay off');
        FeatureSetup.SetFilter(Feature, '<>%1', Enum::"EQM Feature"::"Maintenance Planning");
        FeatureSetup.SetRange(Enabled, false);
        Assert.IsTrue(FeatureSetup.IsEmpty(), 'Every other row should be enabled');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CheckEnabledOnDisabledFeatureRaisesError()
    begin
        Initialize();
        // [SCENARIO 5] CheckEnabled on a disabled feature raises the specific error
        // [GIVEN] API Integration is turned off
        FeatureMgt.SetFeatureEnabled(Enum::"EQM Feature"::"API Integration", false);

        // [WHEN] CheckEnabled is called
        asserterror FeatureMgt.CheckEnabled(Enum::"EQM Feature"::"API Integration");

        // [THEN] The feature-off error is raised
        AssertFeatureDisabledError(Enum::"EQM Feature"::"API Integration");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CheckEnabledOnEnabledFeaturePasses()
    begin
        Initialize();
        // [SCENARIO 6] CheckEnabled on an enabled feature passes
        // [GIVEN] No feature setup rows

        // [WHEN] CheckEnabled is called
        FeatureMgt.CheckEnabled(Enum::"EQM Feature"::"API Integration");

        // [THEN] No error is raised
        Assert.IsTrue(FeatureMgt.IsEnabled(Enum::"EQM Feature"::"API Integration"), 'API Integration should be on');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AdministratorTurnsFeatureOffOnPage()
    var
        FeatureSetup: Record "EQM Feature Setup";
        EquipmentFeatures: TestPage "EQM Equipment Features";
    begin
        Initialize();
        // [SCENARIO 7] An administrator turns a feature off on the Equipment Features page
        // [GIVEN] No feature setup rows

        // [WHEN] The page is opened for editing and Equipment Images is turned off
        EquipmentFeatures.OpenEdit();
        EquipmentFeatures.GoToKey(Enum::"EQM Feature"::"Equipment Images");
        EquipmentFeatures.Enabled.SetValue(false);
        EquipmentFeatures.Close();

        // [THEN] There is one row per feature and Equipment Images is off
        Assert.AreEqual(Enum::"EQM Feature".Ordinals().Count(), FeatureSetup.Count(), 'One row per feature');
        Assert.IsFalse(FeatureMgt.IsEnabled(Enum::"EQM Feature"::"Equipment Images"), 'Equipment Images should be off');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CardHidesControlsOfDisabledFeatures()
    var
        Equipment: Record "EQM Equipment";
        EquipmentCard: TestPage "EQM Equipment Card";
    begin
        Initialize();
        // [SCENARIO 8] The Equipment Card hides the controls of disabled features
        // [GIVEN] Equipment Images, Warranty Alerts and Maintenance Planning are off, and equipment E exists
        FeatureMgt.SetFeatureEnabled(Enum::"EQM Feature"::"Equipment Images", false);
        FeatureMgt.SetFeatureEnabled(Enum::"EQM Feature"::"Warranty Alerts", false);
        FeatureMgt.SetFeatureEnabled(Enum::"EQM Feature"::"Maintenance Planning", false);
        CreateEquipment(Equipment);

        // [WHEN] The card is opened on E
        EquipmentCard.OpenView();
        EquipmentCard.GoToRecord(Equipment);

        // [THEN] The Picture part, the warranty alerts action and the maintenance planning fields are hidden
        Assert.IsFalse(EquipmentCard.Picture.Visible(), 'Picture should be hidden');
        Assert.IsFalse(EquipmentCard.WarrantyAlerts.Visible(), 'Warranty Alerts action should be hidden');
        Assert.IsFalse(EquipmentCard."Next Maintenance Date".Visible(), 'Next Maintenance Date should be hidden');
        Assert.IsFalse(EquipmentCard.MaintenanceFactBox."Next Maintenance Date".Visible(), 'FactBox Next Maintenance Date should be hidden');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CardShowsControlsWhenFeaturesAreOn()
    var
        Equipment: Record "EQM Equipment";
        EquipmentCard: TestPage "EQM Equipment Card";
    begin
        Initialize();
        // [SCENARIO 9] The Equipment Card shows the controls when the features are on
        // [GIVEN] No feature setup rows and equipment E
        CreateEquipment(Equipment);

        // [WHEN] The card is opened on E
        EquipmentCard.OpenView();
        EquipmentCard.GoToRecord(Equipment);

        // [THEN] The controls are visible
        Assert.IsTrue(EquipmentCard.Picture.Visible(), 'Picture should be visible');
        Assert.IsTrue(EquipmentCard.WarrantyAlerts.Visible(), 'Warranty Alerts action should be visible');
        Assert.IsTrue(EquipmentCard."Next Maintenance Date".Visible(), 'Next Maintenance Date should be visible');
        Assert.IsTrue(EquipmentCard.MaintenanceFactBox."Next Maintenance Date".Visible(), 'FactBox Next Maintenance Date should be visible');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CardHidesOnlyPictureWhenOnlyImagesIsOff()
    var
        Equipment: Record "EQM Equipment";
        EquipmentCard: TestPage "EQM Equipment Card";
    begin
        Initialize();
        // [SCENARIO 10] Only Equipment Images is off: the other controls stay visible
        // [GIVEN] Equipment Images is off and equipment E exists
        FeatureMgt.SetFeatureEnabled(Enum::"EQM Feature"::"Equipment Images", false);
        CreateEquipment(Equipment);

        // [WHEN] The card is opened on E
        EquipmentCard.OpenView();
        EquipmentCard.GoToRecord(Equipment);

        // [THEN] Picture is hidden; the warranty alerts action and Next Maintenance Date are visible
        Assert.IsFalse(EquipmentCard.Picture.Visible(), 'Picture should be hidden');
        Assert.IsTrue(EquipmentCard.WarrantyAlerts.Visible(), 'Warranty Alerts action should stay visible');
        Assert.IsTrue(EquipmentCard."Next Maintenance Date".Visible(), 'Next Maintenance Date should stay visible');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ListHidesPictureAndNextMaintenanceDateWhenOff()
    var
        Equipment: Record "EQM Equipment";
        EquipmentList: TestPage "EQM Equipment List";
    begin
        Initialize();
        // [SCENARIO 11] The Equipment List hides the Picture part and Next Maintenance Date
        // [GIVEN] Equipment Images and Maintenance Planning are off, and equipment E exists
        FeatureMgt.SetFeatureEnabled(Enum::"EQM Feature"::"Equipment Images", false);
        FeatureMgt.SetFeatureEnabled(Enum::"EQM Feature"::"Maintenance Planning", false);
        CreateEquipment(Equipment);

        // [WHEN] The list is opened on E
        EquipmentList.OpenView();
        EquipmentList.GoToRecord(Equipment);

        // [THEN] Both are hidden
        Assert.IsFalse(EquipmentList.Picture.Visible(), 'Picture should be hidden');
        Assert.IsFalse(EquipmentList."Next Maintenance Date".Visible(), 'Next Maintenance Date should be hidden');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ListShowsPictureAndNextMaintenanceDateWhenOn()
    var
        Equipment: Record "EQM Equipment";
        EquipmentList: TestPage "EQM Equipment List";
    begin
        Initialize();
        // [SCENARIO 11b] The Equipment List shows the Picture part and Next Maintenance Date when the features are on
        // [GIVEN] No feature setup rows and equipment E
        CreateEquipment(Equipment);

        // [WHEN] The list is opened on E
        EquipmentList.OpenView();
        EquipmentList.GoToRecord(Equipment);

        // [THEN] Both are visible
        Assert.IsTrue(EquipmentList.Picture.Visible(), 'Picture should be visible');
        Assert.IsTrue(EquipmentList."Next Maintenance Date".Visible(), 'Next Maintenance Date should be visible');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CuesHideTilesOfDisabledFeatures()
    var
        CuesPage: TestPage "EQM Equipment Cues";
    begin
        Initialize();
        // [SCENARIO 12] The Cues hide the tiles of disabled features
        // [GIVEN] Approval Workflows, Warranty Alerts and Maintenance Planning are off
        FeatureMgt.SetFeatureEnabled(Enum::"EQM Feature"::"Approval Workflows", false);
        FeatureMgt.SetFeatureEnabled(Enum::"EQM Feature"::"Warranty Alerts", false);
        FeatureMgt.SetFeatureEnabled(Enum::"EQM Feature"::"Maintenance Planning", false);

        // [WHEN] The cue page is opened
        CuesPage.OpenView();

        // [THEN] The tiles of those features are hidden and the equipment tiles stay visible
        Assert.IsFalse(CuesPage."Requests Pending Approval".Visible(), 'Requests Pending Approval should be hidden');
        Assert.IsFalse(CuesPage."Open Warranty Alerts".Visible(), 'Open Warranty Alerts should be hidden');
        Assert.IsFalse(CuesPage."Planned Maintenance This Month".Visible(), 'Planned Maintenance This Month should be hidden');
        Assert.IsTrue(CuesPage."Total Equipment".Visible(), 'Total Equipment should stay visible');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SetupPageHidesIntegrationAndWarrantyJobControls()
    var
        SetupPage: TestPage "EQM Equipment Setup";
    begin
        Initialize();
        // [SCENARIO 13] The Setup page hides the integration and warranty job controls
        // [GIVEN] The equipment setup exists, and API Integration and Warranty Alerts are off
        EnsureEquipmentSetup(false);
        FeatureMgt.SetFeatureEnabled(Enum::"EQM Feature"::"API Integration", false);
        FeatureMgt.SetFeatureEnabled(Enum::"EQM Feature"::"Warranty Alerts", false);

        // [WHEN] The Equipment Setup page is opened
        SetupPage.OpenView();

        // [THEN] The integration and warranty job controls are hidden, and the features action is visible
        Assert.IsFalse(SetupPage."Integration Events Enabled".Visible(), 'Integration Events Enabled should be hidden');
        Assert.IsFalse(SetupPage.WarrantyJobStatus.Visible(), 'Warranty Alert Job should be hidden');
        Assert.IsFalse(SetupPage.IntegrationEventEntries.Visible(), 'Integration Event Entries action should be hidden');
        Assert.IsTrue(SetupPage.EquipmentFeatures.Visible(), 'Equipment Features action should be visible');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EmployeeCardHidesRequestsWhenApprovalWorkflowsIsOff()
    var
        Employee: Record Employee;
        EmployeeCard: TestPage "Employee Card";
    begin
        Initialize();
        // [SCENARIO 14] The Employee Card hides Equipment Requests when Approval Workflows is off
        // [GIVEN] Employee X and Approval Workflows is off
        FeatureMgt.SetFeatureEnabled(Enum::"EQM Feature"::"Approval Workflows", false);
        CreateEmployee(Employee);

        // [WHEN] The Employee Card is opened on X
        EmployeeCard.OpenView();
        EmployeeCard.GoToRecord(Employee);

        // [THEN] Equipment Requests is hidden and Assigned Equipment stays visible
        Assert.IsFalse(EmployeeCard.EQMEquipmentRequests.Visible(), 'Equipment Requests should be hidden');
        Assert.IsTrue(EmployeeCard.EQMAssignedEquipment.Visible(), 'Assigned Equipment should stay visible');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure WarrantyAlertsPageRefusesToOpenWhenOff()
    var
        WarrantyAlerts: TestPage "EQM Warranty Alerts";
    begin
        Initialize();
        // [SCENARIO 15] The Warranty Alerts page refuses to open when the feature is off
        // [GIVEN] Warranty Alerts is off
        FeatureMgt.SetFeatureEnabled(Enum::"EQM Feature"::"Warranty Alerts", false);

        // [WHEN] The page is opened
        asserterror WarrantyAlerts.OpenView();

        // [THEN] The feature-off error is raised
        AssertFeatureDisabledError(Enum::"EQM Feature"::"Warranty Alerts");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure WarrantyAlertsPageOpensWhenOn()
    var
        WarrantyAlerts: TestPage "EQM Warranty Alerts";
    begin
        Initialize();
        // [SCENARIO 16] The Warranty Alerts page opens when the feature is on
        // [GIVEN] No feature setup rows

        // [WHEN] The page is opened
        WarrantyAlerts.OpenView();

        // [THEN] No error is raised
        WarrantyAlerts.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RequestListRefusesToOpenWhenApprovalWorkflowsIsOff()
    var
        RequestList: TestPage "EQM Equipment Requests";
    begin
        Initialize();
        // [SCENARIO 17] The request list refuses to open when Approval Workflows is off
        // [GIVEN] Approval Workflows is off
        FeatureMgt.SetFeatureEnabled(Enum::"EQM Feature"::"Approval Workflows", false);

        // [WHEN] The list is opened
        asserterror RequestList.OpenView();

        // [THEN] The feature-off error is raised
        AssertFeatureDisabledError(Enum::"EQM Feature"::"Approval Workflows");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RequestCardRefusesToOpenWhenApprovalWorkflowsIsOff()
    var
        RequestCard: TestPage "EQM Equipment Request Card";
    begin
        Initialize();
        // [SCENARIO 17b] The request card refuses to open when Approval Workflows is off
        // [GIVEN] Approval Workflows is off
        FeatureMgt.SetFeatureEnabled(Enum::"EQM Feature"::"Approval Workflows", false);

        // [WHEN] The card is opened for editing, as the other request tests do
        asserterror RequestCard.OpenEdit();

        // [THEN] The feature-off error is raised
        AssertFeatureDisabledError(Enum::"EQM Feature"::"Approval Workflows");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure IntegrationEventEntriesRefuseToOpenWhenApiIntegrationIsOff()
    var
        IntegrationEntries: TestPage "EQM Integration Event Entries";
    begin
        Initialize();
        // [SCENARIO 18] The Integration Event Entries page refuses to open when API Integration is off
        // [GIVEN] API Integration is off
        FeatureMgt.SetFeatureEnabled(Enum::"EQM Feature"::"API Integration", false);

        // [WHEN] The page is opened
        asserterror IntegrationEntries.OpenView();

        // [THEN] The feature-off error is raised
        AssertFeatureDisabledError(Enum::"EQM Feature"::"API Integration");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NoIntegrationEventsWhileApiIntegrationIsOff()
    var
        IntegrationEventMgt: Codeunit "EQM Integration Event Mgt.";
    begin
        Initialize();
        // [SCENARIO 19] No integration events are written while API Integration is off
        // [GIVEN] Integration Events Enabled is on and API Integration is off
        EnsureEquipmentSetup(true);
        FeatureMgt.SetFeatureEnabled(Enum::"EQM Feature"::"API Integration", false);

        // [WHEN] IsEnabled is called on the integration event codeunit
        // [THEN] It returns false
        Assert.IsFalse(IntegrationEventMgt.IsEnabled(), 'Integration events should not be written');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure IntegrationEventsAreWrittenWhenApiIntegrationIsOn()
    var
        IntegrationEventMgt: Codeunit "EQM Integration Event Mgt.";
    begin
        Initialize();
        // [SCENARIO 20] Integration events are written when API Integration is on
        // [GIVEN] Integration Events Enabled is on and no feature setup rows
        EnsureEquipmentSetup(true);

        // [WHEN] IsEnabled is called on the integration event codeunit
        // [THEN] It returns true
        Assert.IsTrue(IntegrationEventMgt.IsEnabled(), 'Integration events should be written');
    end;

    local procedure Initialize()
    var
        FeatureSetup: Record "EQM Feature Setup";
    begin
        FeatureSetup.DeleteAll();
    end;

    local procedure NextId(): Text
    begin
        Counter += 1;
        exit(Format(Counter, 0, CounterFormatTok));
    end;

    local procedure CreateEquipment(var Equipment: Record "EQM Equipment")
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
        Equipment.Insert(true);
    end;

    local procedure CreateEmployee(var Employee: Record Employee)
    begin
        Employee.Init();
        Employee."No." := CopyStr(StrSubstNo(EmployeeNoTok, NextId()), 1, MaxStrLen(Employee."No."));
        Employee."First Name" := Employee."No.";
        Employee."Last Name" := Employee."No.";
        Employee.Status := Employee.Status::Active;
        Employee.Insert(false);
    end;

    local procedure EnsureEquipmentSetup(IntegrationEventsEnabled: Boolean)
    var
        EquipmentSetup: Record "EQM Equipment Setup";
    begin
        if not EquipmentSetup.Get() then begin
            EquipmentSetup.Init();
            EquipmentSetup.Insert(false);
        end;
        EquipmentSetup."Integration Events Enabled" := IntegrationEventsEnabled;
        EquipmentSetup.Modify(false);
    end;

    local procedure AssertFeatureDisabledError(Feature: Enum "EQM Feature")
    begin
        Assert.ExpectedError(StrSubstNo(FeatureDisabledErr, Format(Feature)));
    end;
}
