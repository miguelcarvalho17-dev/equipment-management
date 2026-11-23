namespace MiguelCarvalho.EquipmentManagement;

/// <summary>
/// Channel-neutral content of an equipment notification: ID, message, data and the ordered actions. Notification
/// providers read it to deliver the notification on their channel.
/// </summary>
codeunit 50146 "EQM Notification Payload"
{
    Access = Internal;

    var
        NotificationId: Guid;
        MessageText: Text;
        DataValues: Dictionary of [Text, Text];
        ActionCaptions: List of [Text];
        ActionCodeunitIds: List of [Integer];
        ActionMethodNames: List of [Text];

    /// <summary>
    /// Sets the ID of the notification.
    /// </summary>
    /// <param name="NewNotificationId">The notification ID.</param>
    internal procedure SetNotificationId(NewNotificationId: Guid)
    begin
        NotificationId := NewNotificationId;
    end;

    /// <summary>
    /// Returns the ID of the notification.
    /// </summary>
    /// <returns>The notification ID.</returns>
    internal procedure GetNotificationId(): Guid
    begin
        exit(NotificationId);
    end;

    /// <summary>
    /// Sets the message of the notification.
    /// </summary>
    /// <param name="NewMessage">The message text.</param>
    internal procedure SetMessage(NewMessage: Text)
    begin
        MessageText := NewMessage;
    end;

    /// <summary>
    /// Returns the message of the notification.
    /// </summary>
    /// <returns>The message text.</returns>
    internal procedure GetMessage(): Text
    begin
        exit(MessageText);
    end;

    /// <summary>
    /// Sets a data value on the notification. An existing value with the same key is replaced.
    /// </summary>
    /// <param name="DataKey">The data key.</param>
    /// <param name="DataValue">The data value.</param>
    internal procedure SetData(DataKey: Text; DataValue: Text)
    begin
        DataValues.Set(DataKey, DataValue);
    end;

    /// <summary>
    /// Returns the data keys of the notification.
    /// </summary>
    /// <returns>The data keys.</returns>
    internal procedure GetDataKeys(): List of [Text]
    begin
        exit(DataValues.Keys());
    end;

    /// <summary>
    /// Returns a data value of the notification.
    /// </summary>
    /// <param name="DataKey">The data key.</param>
    /// <returns>The data value, or blank when the key is not set.</returns>
    internal procedure GetData(DataKey: Text): Text
    var
        DataValue: Text;
    begin
        if DataValues.Get(DataKey, DataValue) then
            exit(DataValue);
        exit('');
    end;

    /// <summary>
    /// Adds an action to the notification. Actions keep the order in which they are added.
    /// </summary>
    /// <param name="ActionCaption">The caption of the action.</param>
    /// <param name="HandlerCodeunitId">The ID of the codeunit that handles the action.</param>
    /// <param name="HandlerMethodName">The name of the handler procedure.</param>
    internal procedure AddAction(ActionCaption: Text; HandlerCodeunitId: Integer; HandlerMethodName: Text)
    begin
        ActionCaptions.Add(ActionCaption);
        ActionCodeunitIds.Add(HandlerCodeunitId);
        ActionMethodNames.Add(HandlerMethodName);
    end;

    /// <summary>
    /// Returns the number of actions on the notification.
    /// </summary>
    /// <returns>The number of actions.</returns>
    internal procedure GetActionCount(): Integer
    begin
        exit(ActionCaptions.Count());
    end;

    /// <summary>
    /// Returns one action of the notification.
    /// </summary>
    /// <param name="ActionIndex">The position of the action, starting at 1.</param>
    /// <param name="ActionCaption">Returns the caption of the action.</param>
    /// <param name="HandlerCodeunitId">Returns the ID of the codeunit that handles the action.</param>
    /// <param name="HandlerMethodName">Returns the name of the handler procedure.</param>
    internal procedure GetAction(ActionIndex: Integer; var ActionCaption: Text; var HandlerCodeunitId: Integer; var HandlerMethodName: Text)
    begin
        ActionCaption := ActionCaptions.Get(ActionIndex);
        HandlerCodeunitId := ActionCodeunitIds.Get(ActionIndex);
        HandlerMethodName := ActionMethodNames.Get(ActionIndex);
    end;
}
