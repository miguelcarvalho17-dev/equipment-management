namespace MiguelCarvalho.EquipmentManagement.Tests;

using MiguelCarvalho.EquipmentManagement;
using System.TestLibraries.Utilities;

/// <summary>
/// FR-064 tests of the notification provider interface: the Business Central provider, the notification payload and
/// the dispatch of the equipment notifications through a provider. A spy provider captures what the notification
/// management sends, so the dispatch tests show no real notification. The existing notification tests (50158) keep
/// checking the real Business Central notifications.
/// </summary>
codeunit 50171 "EQM Notification Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        FeatureMgt: Codeunit "EQM Feature Mgt.";
        WarrantyAlertMgt: Codeunit "EQM Warranty Alert Mgt.";
        ProviderSpy: Codeunit "EQM Notif. Provider Spy";
        Counter: Integer;
        HandledId: Guid;
        HandledMessage: Text;
        HandledHasData: Boolean;
        HandledData: Text;
        HandledRecallId: Guid;
        EquipmentNoTok: Label 'EQMNTF%1X', Locked = true;
        CategoryCodeTok: Label 'EQMNTFC%1', Locked = true;
        CounterFormatTok: Label '<Integer,4><Filler Character,0>', Locked = true;
        EquipmentNoDataTok: Label 'EquipmentNo', Locked = true;
        FirstActionTok: Label 'First action', Locked = true;
        SecondActionTok: Label 'Second action', Locked = true;
        FirstMethodTok: Label 'FirstMethod', Locked = true;
        SecondMethodTok: Label 'SecondMethod', Locked = true;
        ShowWarrantyAlertsMethodTok: Label 'ShowWarrantyAlerts', Locked = true;
        DisableNotificationMethodTok: Label 'DisableNotification', Locked = true;
        OpenEquipmentCardMethodTok: Label 'OpenEquipmentCard', Locked = true;

    [Test]
    [HandlerFunctions('SendNotificationHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BusinessCentralProviderSendsThePayload()
    var
        NotificationPayload: Codeunit "EQM Notification Payload";
        BCProvider: Codeunit "EQM BC Notification Provider";
        Provider: Interface "EQM INotification Provider";
        NotificationId: Guid;
        MessageText: Text;
        DataValue: Text;
    begin
        // [SCENARIO] The Business Central provider shows the payload as a notification with the same ID, message and data
        Initialize();

        // [GIVEN] A payload with an ID, a message, one data value and one action
        NotificationId := CreateGuid();
        MessageText := Format(CreateGuid());
        DataValue := Format(CreateGuid());
        NotificationPayload.SetNotificationId(NotificationId);
        NotificationPayload.SetMessage(MessageText);
        NotificationPayload.SetData(EquipmentNoDataTok, DataValue);
        NotificationPayload.AddAction(FirstActionTok, Codeunit::"EQM Notification Mgt.", FirstMethodTok);

        // [WHEN] The Business Central provider sends the payload
        Provider := BCProvider;
        Provider.Send(NotificationPayload);

        // [THEN] The notification has the same ID, message and data
        Assert.AreEqual(NotificationId, HandledId, 'The notification ID should come from the payload');
        Assert.AreEqual(MessageText, HandledMessage, 'The message should come from the payload');
        Assert.IsTrue(HandledHasData, 'The notification should carry the data value');
        Assert.AreEqual(DataValue, HandledData, 'The data value should come from the payload');
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BusinessCentralProviderSendsNoDataWhenPayloadHasNone()
    var
        NotificationPayload: Codeunit "EQM Notification Payload";
        BCProvider: Codeunit "EQM BC Notification Provider";
        Provider: Interface "EQM INotification Provider";
    begin
        // [SCENARIO] (negative) A payload without data produces a notification without data
        Initialize();

        // [GIVEN] A payload with an ID and a message but no data
        NotificationPayload.SetNotificationId(CreateGuid());
        NotificationPayload.SetMessage(Format(CreateGuid()));

        // [WHEN] The Business Central provider sends the payload
        Provider := BCProvider;
        Provider.Send(NotificationPayload);

        // [THEN] The notification has no equipment number data
        Assert.IsFalse(HandledHasData, 'The notification should carry no data');
    end;

    [Test]
    [HandlerFunctions('RecallNotificationHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BusinessCentralProviderRecallsById()
    var
        BCProvider: Codeunit "EQM BC Notification Provider";
        Provider: Interface "EQM INotification Provider";
        NotificationId: Guid;
    begin
        // [SCENARIO] The Business Central provider recalls the notification with the given ID
        Initialize();

        // [GIVEN] A notification ID
        NotificationId := CreateGuid();

        // [WHEN] The Business Central provider recalls it
        Provider := BCProvider;
        Provider.Recall(NotificationId);

        // [THEN] The notification with that ID is recalled
        Assert.AreEqual(NotificationId, HandledRecallId, 'The recalled notification should have the given ID');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PayloadKeepsActionsInOrder()
    var
        NotificationPayload: Codeunit "EQM Notification Payload";
        ActionCaption: Text;
        HandlerMethodName: Text;
        HandlerCodeunitId: Integer;
    begin
        // [SCENARIO] The payload returns its actions in the order they were added
        Initialize();

        // [GIVEN] A payload with two actions
        NotificationPayload.AddAction(FirstActionTok, Codeunit::"EQM Notification Mgt.", FirstMethodTok);
        NotificationPayload.AddAction(SecondActionTok, Codeunit::"EQM Notification Mgt.", SecondMethodTok);

        // [WHEN] The actions are read back
        // [THEN] There are two actions, in insertion order, with their handler codeunit and method
        Assert.AreEqual(2, NotificationPayload.GetActionCount(), 'The payload should have two actions');
        NotificationPayload.GetAction(1, ActionCaption, HandlerCodeunitId, HandlerMethodName);
        Assert.AreEqual(FirstActionTok, ActionCaption, 'The first action caption should come first');
        Assert.AreEqual(Codeunit::"EQM Notification Mgt.", HandlerCodeunitId, 'The first handler codeunit should be kept');
        Assert.AreEqual(FirstMethodTok, HandlerMethodName, 'The first handler method should be kept');
        NotificationPayload.GetAction(2, ActionCaption, HandlerCodeunitId, HandlerMethodName);
        Assert.AreEqual(SecondActionTok, ActionCaption, 'The second action caption should come second');
        Assert.AreEqual(SecondMethodTok, HandlerMethodName, 'The second handler method should be kept');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NewPayloadIsEmpty()
    var
        NotificationPayload: Codeunit "EQM Notification Payload";
        NullGuid: Guid;
    begin
        // [SCENARIO] (negative) A new payload carries nothing and an unknown data key returns blank
        Initialize();

        // [GIVEN] A new payload
        // [WHEN] It is read
        // [THEN] It has no ID, message, actions or data keys, and an unknown key returns blank
        Assert.AreEqual(NullGuid, NotificationPayload.GetNotificationId(), 'A new payload should have no ID');
        Assert.AreEqual('', NotificationPayload.GetMessage(), 'A new payload should have no message');
        Assert.AreEqual(0, NotificationPayload.GetActionCount(), 'A new payload should have no actions');
        Assert.AreEqual(0, NotificationPayload.GetDataKeys().Count(), 'A new payload should have no data keys');
        Assert.AreEqual('', NotificationPayload.GetData(EquipmentNoDataTok), 'An unknown data key should return blank');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EquipmentNotificationsAreDispatchedThroughTheProvider()
    var
        Equipment: Record "EQM Equipment";
        NotificationMgt: Codeunit "EQM Notification Mgt.";
        Provider: Interface "EQM INotification Provider";
        ActionCaption: Text;
        HandlerMethodName: Text;
        HandlerCodeunitId: Integer;
    begin
        // [SCENARIO] The equipment notifications go through the provider instead of being shown directly
        Initialize();

        // [GIVEN] The notification management uses the spy provider, and equipment X has a warranty alert
        Provider := ProviderSpy;
        NotificationMgt.SetProvider(Provider);
        NotificationMgt.RegisterDefaultNotifications();
        CreateEquipmentWithWarrantyAlert(Equipment);

        // [WHEN] The equipment notifications are shown for X
        NotificationMgt.ShowEquipmentNotifications(Equipment);

        // [THEN] The provider got exactly one warranty notification for X with its data and two actions, and two recalls
        Assert.AreEqual(1, ProviderSpy.CountSent(NotificationMgt.GetWarrantyNotificationId()), 'One warranty notification should reach the provider');
        Assert.IsTrue(ProviderSpy.GetLastMessage().Contains(Equipment."No."), 'The message should name X');
        Assert.AreEqual(Equipment."No.", ProviderSpy.GetLastData(EquipmentNoDataTok), 'The data should carry the equipment number');
        Assert.AreEqual(2, ProviderSpy.GetLastActionCount(), 'The notification should have two actions');
        ProviderSpy.GetLastAction(1, ActionCaption, HandlerCodeunitId, HandlerMethodName);
        Assert.AreEqual(ShowWarrantyAlertsMethodTok, HandlerMethodName, 'The first action should show the warranty alerts');
        Assert.AreEqual(Codeunit::"EQM Notification Mgt.", HandlerCodeunitId, 'The handler codeunit should be the notification management');
        ProviderSpy.GetLastAction(2, ActionCaption, HandlerCodeunitId, HandlerMethodName);
        Assert.AreEqual(DisableNotificationMethodTok, HandlerMethodName, 'The second action should switch the notification off');
        Assert.AreEqual(Codeunit::"EQM Notification Mgt.", HandlerCodeunitId, 'The second handler codeunit should be the notification management');
        Assert.AreEqual(2, ProviderSpy.RecallCount(), 'The previous notifications should be recalled through the provider');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FeatureOffDispatchesNothing()
    var
        Equipment: Record "EQM Equipment";
        NotificationMgt: Codeunit "EQM Notification Mgt.";
        Provider: Interface "EQM INotification Provider";
    begin
        // [SCENARIO] (negative) With the Notifications feature off nothing is sent, but the previous ones are still recalled
        Initialize();

        // [GIVEN] The spy provider, the Notifications feature off and equipment X with a warranty alert
        Provider := ProviderSpy;
        NotificationMgt.SetProvider(Provider);
        NotificationMgt.RegisterDefaultNotifications();
        FeatureMgt.SetFeatureEnabled(Enum::"EQM Feature"::Notifications, false);
        CreateEquipmentWithWarrantyAlert(Equipment);

        // [WHEN] The equipment notifications are shown for X
        NotificationMgt.ShowEquipmentNotifications(Equipment);

        // [THEN] Nothing reaches the provider, and two recalls do
        Assert.AreEqual(0, ProviderSpy.SentCount(), 'No notification should reach the provider');
        Assert.AreEqual(2, ProviderSpy.RecallCount(), 'The previous notifications should still be recalled');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReturnedNotificationKeepsTheActionContract()
    var
        Equipment: Record "EQM Equipment";
        NotificationMgt: Codeunit "EQM Notification Mgt.";
        Provider: Interface "EQM INotification Provider";
        ActionCaption: Text;
        HandlerMethodName: Text;
        HandlerCodeunitId: Integer;
    begin
        // [SCENARIO] The returned-from-maintenance notification carries the equipment number and its two actions in order
        Initialize();

        // [GIVEN] The spy provider and available equipment X that was in maintenance
        Provider := ProviderSpy;
        NotificationMgt.SetProvider(Provider);
        NotificationMgt.RegisterDefaultNotifications();
        CreateEquipment(Equipment, CreateCategory());

        // [WHEN] The returned notification is sent for X
        NotificationMgt.SendReturnedFromMaintenanceNotification(Equipment."No.", Equipment.Status::"In Maintenance");

        // [THEN] The provider got one notification with data X and the actions Open equipment card, Don't show again
        Assert.AreEqual(1, ProviderSpy.CountSent(NotificationMgt.GetReturnedFromMaintenanceNotificationId()), 'One returned notification should reach the provider');
        Assert.AreEqual(Equipment."No.", ProviderSpy.GetLastData(EquipmentNoDataTok), 'The data should carry the equipment number');
        Assert.AreEqual(2, ProviderSpy.GetLastActionCount(), 'The notification should have two actions');
        ProviderSpy.GetLastAction(1, ActionCaption, HandlerCodeunitId, HandlerMethodName);
        Assert.AreEqual(OpenEquipmentCardMethodTok, HandlerMethodName, 'The first action should open the equipment card');
        Assert.AreEqual(Codeunit::"EQM Notification Mgt.", HandlerCodeunitId, 'The first handler codeunit should be the notification management');
        ProviderSpy.GetLastAction(2, ActionCaption, HandlerCodeunitId, HandlerMethodName);
        Assert.AreEqual(DisableNotificationMethodTok, HandlerMethodName, 'The second action should switch the notification off');
        Assert.AreEqual(Codeunit::"EQM Notification Mgt.", HandlerCodeunitId, 'The second handler codeunit should be the notification management');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NoReturnedNotificationWhenNotFromMaintenance()
    var
        Equipment: Record "EQM Equipment";
        NotificationMgt: Codeunit "EQM Notification Mgt.";
        Provider: Interface "EQM INotification Provider";
    begin
        // [SCENARIO] (negative) No returned notification is sent when the equipment was not in maintenance
        Initialize();

        // [GIVEN] The spy provider and available equipment X
        Provider := ProviderSpy;
        NotificationMgt.SetProvider(Provider);
        NotificationMgt.RegisterDefaultNotifications();
        CreateEquipment(Equipment, CreateCategory());

        // [WHEN] The returned notification is requested with the status before posting Available
        NotificationMgt.SendReturnedFromMaintenanceNotification(Equipment."No.", Equipment.Status::Available);

        // [THEN] Nothing reaches the provider
        Assert.AreEqual(0, ProviderSpy.SentCount(), 'No notification should reach the provider');
    end;

    [SendNotificationHandler(true)]
    procedure SendNotificationHandler(var TheNotification: Notification): Boolean
    begin
        HandledId := TheNotification.Id;
        HandledMessage := TheNotification.Message;
        HandledHasData := TheNotification.HasData(EquipmentNoDataTok);
        if HandledHasData then
            HandledData := TheNotification.GetData(EquipmentNoDataTok);
        exit(true);
    end;

    [RecallNotificationHandler(true)]
    procedure RecallNotificationHandler(var TheNotification: Notification): Boolean
    begin
        HandledRecallId := TheNotification.Id;
        exit(true);
    end;

    local procedure Initialize()
    var
        FeatureSetup: Record "EQM Feature Setup";
        EquipmentSetup: Record "EQM Equipment Setup";
        NullGuid: Guid;
    begin
        // Everything runs in the test transaction, which is rolled back (AutoRollback), so nothing is committed or cleaned up.
        WorkDate(Today());
        FeatureSetup.DeleteAll();
        if not EquipmentSetup.Get() then begin
            EquipmentSetup.Init();
            EquipmentSetup.Insert(false);
        end;
        EquipmentSetup."Integration Events Enabled" := true;
        EquipmentSetup."Default Warranty Alert Days" := WarrantyAlertMgt.GetLongestIntervalDays();
        EquipmentSetup.Modify(false);
        ProviderSpy.Reset();
        HandledId := NullGuid;
        HandledRecallId := NullGuid;
        HandledMessage := '';
        HandledHasData := false;
        HandledData := '';
    end;

    local procedure NextId(): Text
    begin
        Counter += 1;
        exit(Format(Counter, 0, CounterFormatTok));
    end;

    local procedure CreateCategory(): Code[20]
    var
        Category: Record "EQM Equipment Category";
    begin
        Category.Init();
        Category.Code := CopyStr(StrSubstNo(CategoryCodeTok, NextId()), 1, MaxStrLen(Category.Code));
        Category.Description := Category.Code;
        Category.Active := true;
        Category.Insert(false);
        exit(Category.Code);
    end;

    local procedure CreateEquipment(var Equipment: Record "EQM Equipment"; CategoryCode: Code[20])
    begin
        Equipment.Init();
        Equipment."No." := CopyStr(StrSubstNo(EquipmentNoTok, NextId()), 1, MaxStrLen(Equipment."No."));
        Equipment.Description := Equipment."No.";
        Equipment."Category Code" := CategoryCode;
        Equipment.Insert(true);
        Equipment.Get(Equipment."No.");
    end;

    local procedure CreateEquipmentWithWarrantyAlert(var Equipment: Record "EQM Equipment")
    var
        CreatedCount: Integer;
        CancelledCount: Integer;
    begin
        CreateEquipment(Equipment, CreateCategory());
        Equipment."Warranty End Date" := Today() + 1 + Random(30);
        Equipment.Modify(true);
        WarrantyAlertMgt.GenerateAlerts(Today(), false, CreatedCount, CancelledCount);
        Equipment.Get(Equipment."No.");
    end;
}
