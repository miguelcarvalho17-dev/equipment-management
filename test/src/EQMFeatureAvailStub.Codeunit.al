namespace MiguelCarvalho.EquipmentManagement.Tests;

using MiguelCarvalho.EquipmentManagement;

/// <summary>
/// FR-065 test double: answers feature checks from memory instead of the Feature Setup table. Single instance, so
/// the copy handed to the code under test shares its state with the test.
/// </summary>
codeunit 50170 "EQM Feature Avail. Stub" implements "EQM IFeature Availability"
{
    SingleInstance = true;
    Access = Internal;

    var
        DisabledFeatures: List of [Integer];
        AskedFeatures: List of [Integer];

    procedure IsEnabled(Feature: Enum "EQM Feature"): Boolean
    begin
        AskedFeatures.Add(Feature.AsInteger());
        exit(not DisabledFeatures.Contains(Feature.AsInteger()));
    end;

    internal procedure Reset()
    begin
        Clear(DisabledFeatures);
        Clear(AskedFeatures);
    end;

    internal procedure Disable(Feature: Enum "EQM Feature")
    begin
        if not DisabledFeatures.Contains(Feature.AsInteger()) then
            DisabledFeatures.Add(Feature.AsInteger());
    end;

    internal procedure CountAsked(Feature: Enum "EQM Feature"): Integer
    var
        Asked: Integer;
        Count: Integer;
    begin
        foreach Asked in AskedFeatures do
            if Asked = Feature.AsInteger() then
                Count += 1;
        exit(Count);
    end;
}
