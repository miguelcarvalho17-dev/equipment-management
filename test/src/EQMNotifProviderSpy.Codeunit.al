namespace MiguelCarvalho.EquipmentManagement.Tests;

using MiguelCarvalho.EquipmentManagement;

/// <summary>
/// FR-064 test double of the notification provider. It records what is sent and recalled instead of showing a
/// notification. It is single instance so the copy handed to the notification management keeps the same state as the
/// copy the test reads.
/// </summary>
codeunit 50174 "EQM Notif. Provider Spy" implements "EQM INotification Provider"
{
    SingleInstance = true;
    Access = Internal;

    var
        SentIds: List of [Guid];
        RecalledIds: List of [Guid];
        LastMessage: Text;
        LastData: Dictionary of [Text, Text];
        LastActionCaptions: List of [Text];
        LastActionCodeunitIds: List of [Integer];
        LastActionMethodNames: List of [Text];

    procedure Send(var NotificationPayload: Codeunit "EQM Notification Payload")
    var
        DataKey: Text;
        ActionCaption: Text;
        HandlerMethodName: Text;
        HandlerCodeunitId: Integer;
        ActionIndex: Integer;
    begin
        SentIds.Add(NotificationPayload.GetNotificationId());
        LastMessage := NotificationPayload.GetMessage();
        Clear(LastData);
        foreach DataKey in NotificationPayload.GetDataKeys() do
            LastData.Set(DataKey, NotificationPayload.GetData(DataKey));
        Clear(LastActionCaptions);
        Clear(LastActionCodeunitIds);
        Clear(LastActionMethodNames);
        for ActionIndex := 1 to NotificationPayload.GetActionCount() do begin
            NotificationPayload.GetAction(ActionIndex, ActionCaption, HandlerCodeunitId, HandlerMethodName);
            LastActionCaptions.Add(ActionCaption);
            LastActionCodeunitIds.Add(HandlerCodeunitId);
            LastActionMethodNames.Add(HandlerMethodName);
        end;
    end;

    procedure Recall(NotificationId: Guid)
    begin
        RecalledIds.Add(NotificationId);
    end;

    internal procedure Reset()
    begin
        Clear(SentIds);
        Clear(RecalledIds);
        Clear(LastMessage);
        Clear(LastData);
        Clear(LastActionCaptions);
        Clear(LastActionCodeunitIds);
        Clear(LastActionMethodNames);
    end;

    internal procedure SentCount(): Integer
    begin
        exit(SentIds.Count());
    end;

    internal procedure CountSent(NotificationId: Guid): Integer
    var
        SentId: Guid;
        Result: Integer;
    begin
        foreach SentId in SentIds do
            if SentId = NotificationId then
                Result += 1;
        exit(Result);
    end;

    internal procedure RecallCount(): Integer
    begin
        exit(RecalledIds.Count());
    end;

    internal procedure GetLastMessage(): Text
    begin
        exit(LastMessage);
    end;

    internal procedure GetLastData(DataKey: Text): Text
    var
        DataValue: Text;
    begin
        if LastData.Get(DataKey, DataValue) then
            exit(DataValue);
        exit('');
    end;

    internal procedure GetLastActionCount(): Integer
    begin
        exit(LastActionCaptions.Count());
    end;

    internal procedure GetLastAction(ActionIndex: Integer; var ActionCaption: Text; var HandlerCodeunitId: Integer; var HandlerMethodName: Text)
    begin
        ActionCaption := LastActionCaptions.Get(ActionIndex);
        HandlerCodeunitId := LastActionCodeunitIds.Get(ActionIndex);
        HandlerMethodName := LastActionMethodNames.Get(ActionIndex);
    end;
}
