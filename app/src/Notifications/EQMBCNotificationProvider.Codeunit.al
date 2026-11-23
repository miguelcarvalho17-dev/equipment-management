namespace MiguelCarvalho.EquipmentManagement;

/// <summary>
/// Delivers equipment notifications as Business Central notifications in the user's session.
/// </summary>
codeunit 50147 "EQM BC Notification Provider" implements "EQM INotification Provider"
{
    Access = Internal;

    /// <summary>
    /// Shows the payload as a Business Central notification with its data and actions.
    /// </summary>
    /// <param name="NotificationPayload">The notification content.</param>
    procedure Send(var NotificationPayload: Codeunit "EQM Notification Payload")
    var
        Notification: Notification;
        DataKey: Text;
        ActionCaption: Text;
        HandlerMethodName: Text;
        HandlerCodeunitId: Integer;
        ActionIndex: Integer;
    begin
        Notification.Id := NotificationPayload.GetNotificationId();
        Notification.Scope := NotificationScope::LocalScope;
        Notification.Message := NotificationPayload.GetMessage();
        foreach DataKey in NotificationPayload.GetDataKeys() do
            Notification.SetData(DataKey, NotificationPayload.GetData(DataKey));
        for ActionIndex := 1 to NotificationPayload.GetActionCount() do begin
            NotificationPayload.GetAction(ActionIndex, ActionCaption, HandlerCodeunitId, HandlerMethodName);
            Notification.AddAction(ActionCaption, HandlerCodeunitId, HandlerMethodName);
        end;
        Notification.Send();
    end;

    /// <summary>
    /// Removes the Business Central notification with the given ID.
    /// </summary>
    /// <param name="NotificationId">The ID of the notification to remove.</param>
    procedure Recall(NotificationId: Guid)
    var
        Notification: Notification;
    begin
        Notification.Id := NotificationId;
        Notification.Recall();
    end;
}
