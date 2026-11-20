namespace MiguelCarvalho.EquipmentManagement;

page 50141 "EQM Error Log"
{
    Caption = 'Equipment Error Log';
    AboutTitle = 'About the equipment error log';
    AboutText = 'This list shows the errors that stopped the daily monitoring jobs of the equipment app, and the scheduling of those jobs: when it happened, which process failed, the error message and the user. Choose **Show Details** to read the error message and the call stack. Entries cannot be changed. Delete entries that you no longer need.';
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    AdditionalSearchTerms = 'equipment errors, equipment error log, monitoring job errors, job failures';
    SourceTable = "EQM Error Log Entry";
    SourceTableView = sorting("Entry No.") order(descending);
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = true;

    layout
    {
        area(Content)
        {
            repeater(Entries)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    Visible = false;
                }
                field("Logged At"; Rec."Logged At")
                {
                }
                field(Operation; Rec.Operation)
                {
                }
                field("Error Message"; Rec."Error Message")
                {
                }
                field("User ID"; Rec."User ID")
                {
                }
                field("Object ID"; Rec."Object ID")
                {
                }
                field("Error Code"; Rec."Error Code")
                {
                    Visible = false;
                }
                field("Error Call Stack"; Rec."Error Call Stack")
                {
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ShowDetails)
            {
                Caption = 'Show Details';
                ToolTip = 'Show the full error message and the call stack of the selected entry.';
                Image = ViewDetails;

                trigger OnAction()
                begin
                    Message(ErrorDetailsMsg, Rec."Error Message", Rec."Error Call Stack");
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(ShowDetails_Promoted; ShowDetails)
                {
                }
            }
        }
    }

    var
        ErrorDetailsMsg: Label '%1\\Call stack:\%2', Comment = '%1 = error message, %2 = AL call stack';
}
