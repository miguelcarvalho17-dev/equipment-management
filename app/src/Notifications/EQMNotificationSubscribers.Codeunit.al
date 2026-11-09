namespace MiguelCarvalho.EquipmentManagement;

using System.Environment.Configuration;

/// <summary>
/// Registers the equipment notifications in My Notifications so that users can switch them off.
/// </summary>
codeunit 50113 "EQM Notification Subscribers"
{
    Access = Internal;

    [EventSubscriber(ObjectType::Page, Page::"My Notifications", 'OnInitializingNotificationWithDefaultState', '', false, false)]
    local procedure RegisterNotificationsOnInitializingNotificationWithDefaultState()
    var
        NotificationMgt: Codeunit "EQM Notification Mgt.";
    begin
        NotificationMgt.RegisterDefaultNotifications();
    end;
}
