namespace MiguelCarvalho.EquipmentManagement;

/// <summary>
/// Writes the maintenance log: one entry when a maintenance record is registered, one entry per changed field when an
/// open record is corrected, and one entry when it is posted. The log cannot be switched off.
/// </summary>
codeunit 50116 "EQM Maintenance Log Mgt."
{
    Access = Internal;
    Permissions = tabledata "EQM Maintenance Log Entry" = ri;

    /// <summary>
    /// Writes a Registered entry for the maintenance record.
    /// </summary>
    /// <param name="MaintenanceRecord">The record that was registered.</param>
    internal procedure LogRegistered(MaintenanceRecord: Record "EQM Maintenance Record")
    begin
        InsertEntry(MaintenanceRecord."No.", "EQM Maintenance Log Action"::Registered, 0, '', '');
    end;

    /// <summary>
    /// Writes one Changed entry for each audited field whose value differs between the stored and the new record.
    /// Audited fields: Maintenance Date, Maintenance Type, Vendor No., Cost, Description, Performed By.
    /// </summary>
    /// <param name="OldRecord">The record as stored.</param>
    /// <param name="NewRecord">The record as it is being saved.</param>
    internal procedure LogChanges(OldRecord: Record "EQM Maintenance Record"; NewRecord: Record "EQM Maintenance Record")
    begin
        if OldRecord."Maintenance Date" <> NewRecord."Maintenance Date" then
            InsertChange(NewRecord."No.", NewRecord.FieldNo("Maintenance Date"), Format(OldRecord."Maintenance Date", 0, 9), Format(NewRecord."Maintenance Date", 0, 9));
        if OldRecord."Maintenance Type" <> NewRecord."Maintenance Type" then
            InsertChange(NewRecord."No.", NewRecord.FieldNo("Maintenance Type"), Format(OldRecord."Maintenance Type", 0, 9), Format(NewRecord."Maintenance Type", 0, 9));
        if OldRecord."Vendor No." <> NewRecord."Vendor No." then
            InsertChange(NewRecord."No.", NewRecord.FieldNo("Vendor No."), Format(OldRecord."Vendor No.", 0, 9), Format(NewRecord."Vendor No.", 0, 9));
        if OldRecord.Cost <> NewRecord.Cost then
            InsertChange(NewRecord."No.", NewRecord.FieldNo(Cost), Format(OldRecord.Cost, 0, 9), Format(NewRecord.Cost, 0, 9));
        if OldRecord.Description <> NewRecord.Description then
            InsertChange(NewRecord."No.", NewRecord.FieldNo(Description), Format(OldRecord.Description, 0, 9), Format(NewRecord.Description, 0, 9));
        if OldRecord."Performed By" <> NewRecord."Performed By" then
            InsertChange(NewRecord."No.", NewRecord.FieldNo("Performed By"), Format(OldRecord."Performed By", 0, 9), Format(NewRecord."Performed By", 0, 9));
    end;

    /// <summary>
    /// Writes a Posted entry for the maintenance record.
    /// </summary>
    /// <param name="MaintenanceRecord">The record that was posted.</param>
    internal procedure LogPosted(MaintenanceRecord: Record "EQM Maintenance Record")
    begin
        InsertEntry(MaintenanceRecord."No.", "EQM Maintenance Log Action"::Posted, 0, '', '');
    end;

    /// <summary>
    /// Converts a stored log value (XML format) into the regional format of the user. Display only: the stored value is
    /// never changed. A value that cannot be converted is returned as stored.
    /// </summary>
    /// <param name="FieldNo">The number of the maintenance record field that the value belongs to.</param>
    /// <param name="StoredValue">The value as stored in the log, in XML format.</param>
    /// <returns>The value in the regional format, or the stored value when it cannot be converted.</returns>
    internal procedure FormatLogValueForDisplay(FieldNo: Integer; StoredValue: Text): Text
    var
        MaintenanceRecord: Record "EQM Maintenance Record";
        MaintenanceType: Enum "EQM Maintenance Type";
        DateValue: Date;
        DecimalValue: Decimal;
        Ordinal: Integer;
    begin
        if StoredValue = '' then
            exit('');

        case FieldNo of
            MaintenanceRecord.FieldNo("Maintenance Date"):
                if Evaluate(DateValue, StoredValue, 9) then
                    exit(Format(DateValue));
            MaintenanceRecord.FieldNo(Cost):
                if Evaluate(DecimalValue, StoredValue, 9) then
                    exit(Format(DecimalValue));
            MaintenanceRecord.FieldNo("Maintenance Type"):
                if Evaluate(Ordinal, StoredValue, 9) then
                    if MaintenanceType.Ordinals().Contains(Ordinal) then begin
                        MaintenanceType := Enum::"EQM Maintenance Type".FromInteger(Ordinal);
                        exit(Format(MaintenanceType));
                    end;
        end;

        exit(StoredValue);
    end;

    local procedure InsertChange(MaintenanceNo: Code[20]; FieldNo: Integer; OldValue: Text; NewValue: Text)
    begin
        InsertEntry(MaintenanceNo, "EQM Maintenance Log Action"::Changed, FieldNo, OldValue, NewValue);
    end;

    local procedure InsertEntry(MaintenanceNo: Code[20]; LogAction: Enum "EQM Maintenance Log Action"; FieldNo: Integer; OldValue: Text; NewValue: Text)
    var
        LogEntry: Record "EQM Maintenance Log Entry";
    begin
        LogEntry.Init();
        LogEntry."Maintenance No." := MaintenanceNo;
        LogEntry."Action" := LogAction;
        LogEntry."Field No." := FieldNo;
        LogEntry."Old Value" := CopyStr(OldValue, 1, MaxStrLen(LogEntry."Old Value"));
        LogEntry."New Value" := CopyStr(NewValue, 1, MaxStrLen(LogEntry."New Value"));
        LogEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(LogEntry."User ID"));
        LogEntry."Logged At" := CurrentDateTime();
        LogEntry.AllowInsertFromLog();
        LogEntry.Insert(true);
    end;
}
