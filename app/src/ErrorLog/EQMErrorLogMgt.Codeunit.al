namespace MiguelCarvalho.EquipmentManagement;

/// <summary>
/// Writes entries to the equipment error log. When no write transaction is open, the entry is written in its own
/// transaction and committed, so it survives the rollback of the process that failed.
/// </summary>
codeunit 50142 "EQM Error Log Mgt."
{
    Access = Internal;

    trigger OnRun()
    begin
        if PendingEntryExists then
            InsertPendingEntry();
    end;

    var
        PendingOperation: Enum "EQM Error Operation";
        PendingObjectId: Integer;
        PendingErrorMessage: Text;
        PendingErrorCode: Text;
        PendingErrorCallStack: Text;
        PendingEntryExists: Boolean;

    /// <summary>
    /// Writes an error log entry. It never raises an error into the caller. An empty error message writes nothing.
    /// </summary>
    /// <param name="Operation">The process that failed.</param>
    /// <param name="ObjectId">The ID of the codeunit that ran the process.</param>
    /// <param name="ErrorMessage">The error message.</param>
    /// <param name="ErrorCode">The error code.</param>
    /// <param name="ErrorCallStack">The AL call stack.</param>
    /// <returns>True when an entry was written.</returns>
    internal procedure LogError(Operation: Enum "EQM Error Operation"; ObjectId: Integer; ErrorMessage: Text; ErrorCode: Text; ErrorCallStack: Text): Boolean
    var
        ErrorLogWriter: Codeunit "EQM Error Log Mgt.";
    begin
        if ErrorMessage = '' then
            exit(false);
        if Database.IsInWriteTransaction() then begin
            SetPendingEntry(Operation, ObjectId, ErrorMessage, ErrorCode, ErrorCallStack);
            InsertPendingEntry();
            exit(true);
        end;
        ErrorLogWriter.SetPendingEntry(Operation, ObjectId, ErrorMessage, ErrorCode, ErrorCallStack);
        exit(ErrorLogWriter.Run());
    end;

    /// <summary>
    /// Writes an error log entry for the last error of the session.
    /// </summary>
    /// <param name="Operation">The process that failed.</param>
    /// <param name="ObjectId">The ID of the codeunit that ran the process.</param>
    /// <returns>True when an entry was written.</returns>
    internal procedure LogLastError(Operation: Enum "EQM Error Operation"; ObjectId: Integer): Boolean
    begin
        exit(LogError(Operation, ObjectId, GetLastErrorText(), GetLastErrorCode(), GetLastErrorCallStack()));
    end;

    /// <summary>
    /// Sets the entry that the next Run of this codeunit instance writes.
    /// </summary>
    /// <param name="Operation">The process that failed.</param>
    /// <param name="ObjectId">The ID of the codeunit that ran the process.</param>
    /// <param name="ErrorMessage">The error message.</param>
    /// <param name="ErrorCode">The error code.</param>
    /// <param name="ErrorCallStack">The AL call stack.</param>
    internal procedure SetPendingEntry(Operation: Enum "EQM Error Operation"; ObjectId: Integer; ErrorMessage: Text; ErrorCode: Text; ErrorCallStack: Text)
    begin
        PendingOperation := Operation;
        PendingObjectId := ObjectId;
        PendingErrorMessage := ErrorMessage;
        PendingErrorCode := ErrorCode;
        PendingErrorCallStack := ErrorCallStack;
        PendingEntryExists := true;
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"EQM Error Log Entry", 'I', InherentPermissionsScope::Permissions)]
    local procedure InsertPendingEntry()
    var
        ErrorLogEntry: Record "EQM Error Log Entry";
    begin
        ErrorLogEntry.Init();
        ErrorLogEntry."Logged At" := CurrentDateTime();
        ErrorLogEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(ErrorLogEntry."User ID"));
        ErrorLogEntry.Operation := PendingOperation;
        ErrorLogEntry."Object ID" := PendingObjectId;
        ErrorLogEntry."Error Message" := CopyStr(PendingErrorMessage, 1, MaxStrLen(ErrorLogEntry."Error Message"));
        ErrorLogEntry."Error Code" := CopyStr(PendingErrorCode, 1, MaxStrLen(ErrorLogEntry."Error Code"));
        ErrorLogEntry."Error Call Stack" := CopyStr(PendingErrorCallStack, 1, MaxStrLen(ErrorLogEntry."Error Call Stack"));
        ErrorLogEntry.AllowInsertFromErrorLog();
        ErrorLogEntry.Insert(true);
        PendingEntryExists := false;
    end;
}
