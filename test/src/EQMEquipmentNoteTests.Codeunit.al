namespace MiguelCarvalho.EquipmentManagement.Tests;

using MiguelCarvalho.EquipmentManagement;
using System.TestLibraries.Utilities;

codeunit 50183 "EQM Equipment Note Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        EquipmentNoTok: Label 'LT001', Locked = true;
        EquipmentNo2Tok: Label 'LT002', Locked = true;
        RenamedNoTok: Label 'LT009', Locked = true;
        MissingNoTok: Label 'LT999', Locked = true;
        CategoryCodeTok: Label 'LAPTOP', Locked = true;
        FirstCommentTok: Label 'Charger issued', Locked = true;
        SecondCommentTok: Label 'Charger returned', Locked = true;
        ChangedCommentTok: Label 'Changed text', Locked = true;
        // Copies of the labels in tables 50109 and 50100; labels of another app are not accessible.
        EquipmentNotFoundErr: Label 'Equipment %1 does not exist. You cannot add a note to equipment that does not exist.', Comment = '%1 = equipment number';
        CommentRequiredErr: Label 'You must enter a comment for the note.';
        ModifyNotAllowedErr: Label 'You cannot change equipment note %1. Notes are kept as written. To correct a note, add a new note.', Comment = '%1 = entry number';
        DeleteNotAllowedErr: Label 'You cannot delete equipment note %1. Equipment notes are kept permanently.', Comment = '%1 = entry number';
        RenameNotAllowedErr: Label 'You cannot change the number of equipment note %1.', Comment = '%1 = entry number';
        DeleteNotesExistErr: Label 'You cannot delete equipment %1 because it has notes. To stop using the equipment, set its status to %2 instead.', Comment = '%1 = equipment number, %2 = Disposed status caption';
        NotesListRowCount: Integer;
        NotesListOtherEquipmentFound: Boolean;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure InsertedNoteGetsSystemUserAndTime()
    var
        Equipment: Record "EQM Equipment";
        EquipmentNote: Record "EQM Equipment Note";
        TimeBefore: DateTime;
        TimeAfter: DateTime;
    begin
        // [SCENARIO 1] A note is stored with the system user and creation time
        // [GIVEN] Saved equipment E
        CreateEquipment(Equipment, EquipmentNoTok);

        // [WHEN] A note is inserted
        TimeBefore := CurrentDateTime();
        AddNote(EquipmentNote, EquipmentNoTok, FirstCommentTok);
        TimeAfter := CurrentDateTime();

        // [THEN] Exactly one note exists for E, with the current user and a time between the two readings
        FilterNotes(EquipmentNote, EquipmentNoTok);
        Assert.RecordCount(EquipmentNote, 1);
        EquipmentNote.FindFirst();
        Assert.AreEqual(FirstCommentTok, EquipmentNote.Comment, 'The comment should be stored');
        Assert.AreEqual(CopyStr(UserId(), 1, MaxStrLen(EquipmentNote."User ID")), EquipmentNote."User ID", 'User ID should be the current user');
        Assert.IsTrue(EquipmentNote."Created At" >= TimeBefore, 'Created At should not be before the insert');
        Assert.IsTrue(EquipmentNote."Created At" <= TimeAfter, 'Created At should not be after the insert');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PresetUserAndTimeAreOverwritten()
    var
        Equipment: Record "EQM Equipment";
        EquipmentNote: Record "EQM Equipment Note";
        OldDateTime: DateTime;
    begin
        // [SCENARIO 2] User ID and Created At cannot be supplied by the caller
        // [GIVEN] Saved equipment E and a note with preset User ID X and Created At 01-01-2020
        CreateEquipment(Equipment, EquipmentNoTok);
        OldDateTime := CreateDateTime(DMY2Date(1, 1, 2020), 000000T);
        EquipmentNote.Init();
        EquipmentNote."Equipment No." := EquipmentNoTok;
        EquipmentNote.Comment := FirstCommentTok;
        EquipmentNote."User ID" := 'X';
        EquipmentNote."Created At" := OldDateTime;

        // [WHEN] The note is inserted
        EquipmentNote.Insert(true);

        // [THEN] Both values are overwritten by the system
        EquipmentNote.Get(EquipmentNote."Entry No.");
        Assert.AreNotEqual('X', EquipmentNote."User ID", 'The preset user should be overwritten');
        Assert.AreEqual(CopyStr(UserId(), 1, MaxStrLen(EquipmentNote."User ID")), EquipmentNote."User ID", 'User ID should be the current user');
        Assert.IsTrue(EquipmentNote."Created At" > OldDateTime, 'The preset time should be overwritten');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BlankCommentIsRejected()
    var
        Equipment: Record "EQM Equipment";
        EquipmentNote: Record "EQM Equipment Note";
    begin
        // [SCENARIO 3a] (negative) An empty comment is rejected
        // The row count cannot be asserted afterwards: asserterror rolls back the test's own setup writes too.
        // [GIVEN] Saved equipment E
        CreateEquipment(Equipment, EquipmentNoTok);

        // [WHEN] A note with an empty comment is inserted
        asserterror AddNote(EquipmentNote, EquipmentNoTok, '');

        // [THEN] The comment-required error is raised
        Assert.ExpectedError(CommentRequiredErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SpacesOnlyCommentIsRejected()
    var
        Equipment: Record "EQM Equipment";
        EquipmentNote: Record "EQM Equipment Note";
    begin
        // [SCENARIO 3b] (negative) A comment of spaces only is rejected
        // [GIVEN] Saved equipment E
        CreateEquipment(Equipment, EquipmentNoTok);

        // [WHEN] A note with a comment of spaces is inserted
        asserterror AddNote(EquipmentNote, EquipmentNoTok, '   ');

        // [THEN] The comment-required error is raised
        Assert.ExpectedError(CommentRequiredErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BlankEquipmentNoIsRejected()
    var
        Equipment: Record "EQM Equipment";
        EquipmentNote: Record "EQM Equipment Note";
    begin
        // [SCENARIO 4a] (negative) A note without an equipment number is rejected
        // [GIVEN] Saved equipment E
        CreateEquipment(Equipment, EquipmentNoTok);

        // [WHEN] A note with a blank Equipment No. is inserted
        asserterror AddNote(EquipmentNote, '', FirstCommentTok);

        // [THEN] A TestField error is raised
        Assert.ExpectedErrorCode('TestField');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UnknownEquipmentNoIsRejected()
    var
        Equipment: Record "EQM Equipment";
        EquipmentNote: Record "EQM Equipment Note";
    begin
        // [SCENARIO 4b] (negative) A note for equipment that does not exist is rejected
        // [GIVEN] Saved equipment E, and no equipment LT999
        CreateEquipment(Equipment, EquipmentNoTok);

        // [WHEN] A note for LT999 is inserted
        asserterror AddNote(EquipmentNote, MissingNoTok, FirstCommentTok);

        // [THEN] The equipment-not-found error is raised
        Assert.ExpectedError(StrSubstNo(EquipmentNotFoundErr, MissingNoTok));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ModifyingNoteIsRejected()
    var
        Equipment: Record "EQM Equipment";
        EquipmentNote: Record "EQM Equipment Note";
        EntryNo: Integer;
    begin
        // [SCENARIO 5] (negative) A saved note cannot be changed
        // [GIVEN] A note on E
        CreateEquipment(Equipment, EquipmentNoTok);
        AddNote(EquipmentNote, EquipmentNoTok, FirstCommentTok);
        EntryNo := EquipmentNote."Entry No.";

        // [WHEN] The comment is changed and Modify is called
        EquipmentNote.Comment := ChangedCommentTok;
        asserterror EquipmentNote.Modify(true);

        // [THEN] The modify error is raised (the unchanged comment cannot be re-read: asserterror rolls back the setup)
        Assert.ExpectedError(StrSubstNo(ModifyNotAllowedErr, EntryNo));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DeletingNoteIsRejected()
    var
        Equipment: Record "EQM Equipment";
        EquipmentNote: Record "EQM Equipment Note";
        EntryNo: Integer;
    begin
        // [SCENARIO 6a] (negative) A saved note cannot be deleted
        // [GIVEN] A note on E
        CreateEquipment(Equipment, EquipmentNoTok);
        AddNote(EquipmentNote, EquipmentNoTok, FirstCommentTok);
        EntryNo := EquipmentNote."Entry No.";

        // [WHEN] Delete is called
        asserterror EquipmentNote.Delete(true);

        // [THEN] The delete error is raised
        Assert.ExpectedError(StrSubstNo(DeleteNotAllowedErr, EntryNo));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RenamingNoteIsRejected()
    var
        Equipment: Record "EQM Equipment";
        EquipmentNote: Record "EQM Equipment Note";
        EntryNo: Integer;
    begin
        // [SCENARIO 6b] (negative) A saved note cannot be renamed
        // [GIVEN] A note on E
        CreateEquipment(Equipment, EquipmentNoTok);
        AddNote(EquipmentNote, EquipmentNoTok, FirstCommentTok);
        EntryNo := EquipmentNote."Entry No.";

        // [WHEN] The entry number is changed with Rename
        asserterror EquipmentNote.Rename(EntryNo + 1000);

        // [THEN] The rename error is raised
        Assert.ExpectedError(StrSubstNo(RenameNotAllowedErr, EntryNo));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NotesAreSeparatedPerEquipment()
    var
        Equipment: Record "EQM Equipment";
        Equipment2: Record "EQM Equipment";
        EquipmentNote: Record "EQM Equipment Note";
    begin
        // [SCENARIO 7] Notes are filtered per equipment
        // [GIVEN] 2 notes on E and 1 on E2
        CreateEquipment(Equipment, EquipmentNoTok);
        CreateEquipment(Equipment2, EquipmentNo2Tok);
        AddNote(EquipmentNote, EquipmentNoTok, FirstCommentTok);
        AddNote(EquipmentNote, EquipmentNoTok, SecondCommentTok);
        AddNote(EquipmentNote, EquipmentNo2Tok, FirstCommentTok);

        // [WHEN] The notes are filtered by Equipment No.
        // [THEN] E returns 2 and E2 returns 1
        FilterNotes(EquipmentNote, EquipmentNoTok);
        Assert.RecordCount(EquipmentNote, 2);
        FilterNotes(EquipmentNote, EquipmentNo2Tok);
        Assert.RecordCount(EquipmentNote, 1);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DeletingEquipmentWithNotesIsRejected()
    var
        Equipment: Record "EQM Equipment";
        EquipmentNote: Record "EQM Equipment Note";
    begin
        // [SCENARIO 8a] (negative) Equipment with notes cannot be deleted
        // E and its note stay because the error aborts the delete; this cannot be re-read after asserterror.
        // [GIVEN] Equipment E with a note
        CreateEquipment(Equipment, EquipmentNoTok);
        AddNote(EquipmentNote, EquipmentNoTok, FirstCommentTok);

        // [WHEN] E is deleted
        asserterror Equipment.Delete(true);

        // [THEN] The notes-exist error is raised
        Assert.ExpectedError(StrSubstNo(DeleteNotesExistErr, EquipmentNoTok, Format(Equipment.Status::Disposed)));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DeletingEquipmentWithoutNotesSucceeds()
    var
        Equipment: Record "EQM Equipment";
        Equipment2: Record "EQM Equipment";
        EquipmentNote: Record "EQM Equipment Note";
    begin
        // [SCENARIO 8b] (regression) Equipment without notes can still be deleted
        // [GIVEN] E with a note and E2 without notes
        CreateEquipment(Equipment, EquipmentNoTok);
        CreateEquipment(Equipment2, EquipmentNo2Tok);
        AddNote(EquipmentNote, EquipmentNoTok, FirstCommentTok);

        // [WHEN] E2 is deleted
        Equipment2.Delete(true);

        // [THEN] E2 is gone and E is untouched
        Assert.IsFalse(Equipment2.Get(EquipmentNo2Tok), 'Equipment without notes should be deleted');
        Assert.IsTrue(Equipment.Get(EquipmentNoTok), 'Other equipment should be untouched');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RenamingEquipmentMovesItsNotes()
    var
        Equipment: Record "EQM Equipment";
        EquipmentNote: Record "EQM Equipment Note";
    begin
        // [SCENARIO 9] Renaming equipment moves its notes to the new number (plan verification V1)
        // [GIVEN] Equipment E (LT001) with 2 notes
        CreateEquipment(Equipment, EquipmentNoTok);
        AddNote(EquipmentNote, EquipmentNoTok, FirstCommentTok);
        AddNote(EquipmentNote, EquipmentNoTok, SecondCommentTok);

        // [WHEN] E is renamed to LT009
        Equipment.Rename(RenamedNoTok);

        // [THEN] 2 notes carry LT009 and none carry LT001
        FilterNotes(EquipmentNote, RenamedNoTok);
        Assert.RecordCount(EquipmentNote, 2);
        FilterNotes(EquipmentNote, EquipmentNoTok);
        Assert.RecordIsEmpty(EquipmentNote);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NoteCanBeAddedToLostEquipment()
    var
        Equipment: Record "EQM Equipment";
        EquipmentNote: Record "EQM Equipment Note";
    begin
        // [SCENARIO 10] Notes are allowed in every status, here Lost
        // [GIVEN] Equipment E with status Lost
        CreateEquipment(Equipment, EquipmentNoTok);
        Equipment.Status := Equipment.Status::Lost;
        Equipment.Modify(false);

        // [WHEN] A note is added
        AddNote(EquipmentNote, EquipmentNoTok, FirstCommentTok);

        // [THEN] The note exists
        FilterNotes(EquipmentNote, EquipmentNoTok);
        Assert.RecordCount(EquipmentNote, 1);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CardPartShowsNewestFirstAndLocksExistingLines()
    var
        Equipment: Record "EQM Equipment";
        EquipmentNote: Record "EQM Equipment Note";
        EquipmentCard: TestPage "EQM Equipment Card";
    begin
        // [SCENARIO 11a] The card part lists notes newest first; existing lines are read-only, a new line is editable (plan verification V2)
        // [GIVEN] Equipment E with 2 notes, the first added before the second
        CreateEquipment(Equipment, EquipmentNoTok);
        AddNote(EquipmentNote, EquipmentNoTok, FirstCommentTok);
        AddNote(EquipmentNote, EquipmentNoTok, SecondCommentTok);

        // [WHEN] The card of E is opened for editing
        EquipmentCard.OpenEdit();
        EquipmentCard.GoToRecord(Equipment);

        // [THEN] The newest note is first and the older one second
        EquipmentCard.EquipmentNotes.First();
        Assert.AreEqual(SecondCommentTok, EquipmentCard.EquipmentNotes.Comment.Value(), 'The newest note should be listed first');
        Assert.IsFalse(EquipmentCard.EquipmentNotes.Comment.Editable(), 'Comment of an existing note should not be editable');
        EquipmentCard.EquipmentNotes.Next();
        Assert.AreEqual(FirstCommentTok, EquipmentCard.EquipmentNotes.Comment.Value(), 'The older note should be second');

        // [THEN] A new line has an editable comment
        EquipmentCard.EquipmentNotes.New();
        Assert.IsTrue(EquipmentCard.EquipmentNotes.Comment.Editable(), 'Comment of a new line should be editable');
        EquipmentCard.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NoteTypedOnNewCardPartLineIsSaved()
    var
        Equipment: Record "EQM Equipment";
        EquipmentNote: Record "EQM Equipment Note";
        EquipmentCard: TestPage "EQM Equipment Card";
    begin
        // [SCENARIO 11b] Typing a comment on the new line of the part inserts a note linked to E (boundary of 11, V2)
        // [GIVEN] The card of saved equipment E
        CreateEquipment(Equipment, EquipmentNoTok);
        EquipmentCard.OpenEdit();
        EquipmentCard.GoToRecord(Equipment);

        // [WHEN] A comment is typed on a new line and the line is left
        EquipmentCard.EquipmentNotes.New();
        EquipmentCard.EquipmentNotes.Comment.SetValue(FirstCommentTok);
        EquipmentCard.EquipmentNotes.New();
        EquipmentCard.Close();

        // [THEN] One note exists for E with the comment
        FilterNotes(EquipmentNote, EquipmentNoTok);
        Assert.RecordCount(EquipmentNote, 1);
        EquipmentNote.FindFirst();
        Assert.AreEqual(FirstCommentTok, EquipmentNote.Comment, 'The typed comment should be stored');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('NotesListHandler')]
    procedure ShowEquipmentNotesActionOpensListFilteredOnEquipment()
    var
        Equipment: Record "EQM Equipment";
        Equipment2: Record "EQM Equipment";
        EquipmentNote: Record "EQM Equipment Note";
        EquipmentCard: TestPage "EQM Equipment Card";
    begin
        // [SCENARIO 11c] The action opens page 50131 filtered on the equipment
        // [GIVEN] E with 2 notes and E2 with 1 note
        CreateEquipment(Equipment, EquipmentNoTok);
        CreateEquipment(Equipment2, EquipmentNo2Tok);
        AddNote(EquipmentNote, EquipmentNoTok, FirstCommentTok);
        AddNote(EquipmentNote, EquipmentNoTok, SecondCommentTok);
        AddNote(EquipmentNote, EquipmentNo2Tok, FirstCommentTok);
        EquipmentCard.OpenView();
        EquipmentCard.GoToRecord(Equipment);
        NotesListRowCount := 0;
        NotesListOtherEquipmentFound := false;

        // [WHEN] ShowEquipmentNotes is invoked
        EquipmentCard.ShowEquipmentNotes.Invoke();

        // [THEN] The list (handler) showed the 2 notes of E and none of E2
        Assert.AreEqual(2, NotesListRowCount, 'The list should show the notes of E only');
        Assert.IsFalse(NotesListOtherEquipmentFound, 'The list should not show notes of other equipment');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ShowEquipmentNotesActionDisabledOnNewCard()
    var
        EquipmentCard: TestPage "EQM Equipment Card";
    begin
        // [SCENARIO 11d] (negative) The action needs a saved record
        // [GIVEN] A new unsaved card
        // [WHEN] The card is opened new
        EquipmentCard.OpenNew();

        // [THEN] ShowEquipmentNotes is disabled
        Assert.IsFalse(EquipmentCard.ShowEquipmentNotes.Enabled(), 'Equipment Notes should be disabled on an unsaved card');
        EquipmentCard.Close();
    end;

    local procedure CreateEquipment(var Equipment: Record "EQM Equipment"; EquipmentNo: Code[20])
    var
        Category: Record "EQM Equipment Category";
    begin
        Category.Init();
        Category.Code := CategoryCodeTok;
        Category.Active := true;
        if not Category.Insert() then
            Category.Modify();

        Equipment.Init();
        Equipment."No." := EquipmentNo;
        Equipment.Description := 'Test laptop';
        Equipment."Category Code" := CategoryCodeTok;
        Equipment.Insert(true);
    end;

    local procedure AddNote(var EquipmentNote: Record "EQM Equipment Note"; EquipmentNo: Code[20]; NoteComment: Text[250])
    begin
        Clear(EquipmentNote);
        EquipmentNote.Init();
        EquipmentNote."Equipment No." := EquipmentNo;
        EquipmentNote.Comment := NoteComment;
        EquipmentNote.Insert(true);
    end;

    local procedure FilterNotes(var EquipmentNote: Record "EQM Equipment Note"; EquipmentNo: Code[20])
    begin
        EquipmentNote.Reset();
        EquipmentNote.SetRange("Equipment No.", EquipmentNo);
    end;

    [PageHandler]
    procedure NotesListHandler(var EquipmentNotes: TestPage "EQM Equipment Notes")
    begin
        if EquipmentNotes.First() then
            repeat
                NotesListRowCount += 1;
                if EquipmentNotes."Equipment No.".Value() <> EquipmentNoTok then
                    NotesListOtherEquipmentFound := true;
            until not EquipmentNotes.Next();
    end;
}
