namespace MiguelCarvalho.EquipmentManagement;

page 50138 "EQM Equipment Stats. FactBox"
{
    Caption = 'Equipment Statistics';
    PageType = CardPart;
    ApplicationArea = All;
    SourceTable = "EQM Equipment";
    Editable = false;

    layout
    {
        area(Content)
        {
            field(NoOfAssignments; NoOfAssignments)
            {
                Caption = 'Assignment Count';
                ToolTip = 'Specifies how many times the equipment has been assigned, including the current assignment. Choose the number to see the assignment history.';

                trigger OnDrillDown()
                var
                    AssignmentMgt: Codeunit "EQM Assignment Mgt.";
                begin
                    AssignmentMgt.ShowAssignments(Rec."No.");
                end;
            }
            field(NoOfPostedMaintenances; Rec."No. of Posted Maintenances")
            {
                Caption = 'Maintenance Count';
                ToolTip = 'Specifies how many maintenance records of the equipment have been posted. Open maintenance records are counted when they are posted. Choose the number to see the maintenance history.';
            }
            field(TotalMaintenanceCost; Rec."Total Maintenance Cost")
            {
            }
        }
    }

    var
        NoOfAssignments: Integer;

    trigger OnAfterGetRecord()
    var
        AssignmentMgt: Codeunit "EQM Assignment Mgt.";
    begin
        NoOfAssignments := 0;
        if Rec."No." <> '' then
            NoOfAssignments := AssignmentMgt.CountAssignments(Rec."No.");
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        NoOfAssignments := 0;
        exit(Rec.Find(Which));
    end;
}
