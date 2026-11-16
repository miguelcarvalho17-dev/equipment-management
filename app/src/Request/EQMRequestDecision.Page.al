namespace MiguelCarvalho.EquipmentManagement;

/// <summary>
/// Dialog that collects the comment for approving or rejecting an equipment request.
/// </summary>
page 50135 "EQM Request Decision"
{
    Caption = 'Equipment Request Decision';
    PageType = StandardDialog;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(InstructionText; Instruction)
            {
                ShowCaption = false;
                Editable = false;
                MultiLine = true;
                ToolTip = 'Specifies what to enter in the comment.';
            }
            field(CommentText; Comment)
            {
                Caption = 'Comment';
                MultiLine = true;
                ToolTip = 'Specifies a comment on the decision.';
            }
        }
    }

    var
        Instruction: Text;
        Comment: Text[250];

    /// <summary>
    /// Sets the instruction text shown above the comment.
    /// </summary>
    /// <param name="NewInstruction">The instruction text.</param>
    internal procedure SetInstruction(NewInstruction: Text)
    begin
        Instruction := NewInstruction;
    end;

    /// <summary>
    /// Returns the comment the user entered.
    /// </summary>
    /// <returns>The comment, at most 250 characters.</returns>
    internal procedure GetComment(): Text[250]
    begin
        exit(Comment);
    end;
}
