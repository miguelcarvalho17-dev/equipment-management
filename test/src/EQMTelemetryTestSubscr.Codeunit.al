namespace MiguelCarvalho.EquipmentManagement.Tests;

using MiguelCarvalho.EquipmentManagement;

/// <summary>
/// Manual subscriber that observes the usage telemetry signals of codeunit 50140 (FR-050). A test binds it with
/// BindSubscription, so only that test sees the signals. The state lives in the codeunit instance, so it survives a
/// rolled back asserterror.
/// </summary>
codeunit 50152 "EQM Telemetry Test Subscr"
{
    EventSubscriberInstance = Manual;

    var
        EventIds: List of [Text];
        DimensionValues: Dictionary of [Text, Text];
        AllValues: List of [Text];

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"EQM Telemetry Mgt.", OnAfterLogUsageTelemetry, '', false, false)]
    local procedure CaptureUsageTelemetry(EventId: Text; Dimensions: Dictionary of [Text, Text])
    var
        DimKey: Text;
        DimValue: Text;
    begin
        EventIds.Add(EventId);
        foreach DimKey in Dimensions.Keys() do begin
            DimValue := Dimensions.Get(DimKey);
            DimensionValues.Set(EventId + '|' + DimKey, DimValue);
            AllValues.Add(DimValue);
        end;
    end;

    internal procedure CountOf(EventId: Text): Integer
    var
        Logged: Text;
        Total: Integer;
    begin
        foreach Logged in EventIds do
            if Logged = EventId then
                Total += 1;
        exit(Total);
    end;

    internal procedure TotalCount(): Integer
    begin
        exit(EventIds.Count());
    end;

    internal procedure HasDimension(EventId: Text; DimKey: Text): Boolean
    begin
        exit(DimensionValues.ContainsKey(EventId + '|' + DimKey));
    end;

    internal procedure GetDimension(EventId: Text; DimKey: Text): Text
    var
        DimValue: Text;
    begin
        if DimensionValues.Get(EventId + '|' + DimKey, DimValue) then
            exit(DimValue);
        exit('');
    end;

    internal procedure AnyValueContains(Fragment: Text): Boolean
    var
        DimValue: Text;
    begin
        foreach DimValue in AllValues do
            if DimValue.Contains(Fragment) then
                exit(true);
        exit(false);
    end;
}
