namespace MiguelCarvalho.EquipmentManagement;

using Microsoft.HumanResources.Employee;

pageextension 50100 "EQM Employee Card" extends "Employee Card"
{
    layout
    {
        addfirst(FactBoxes)
        {
            part(EQMAssignedEquipmentFactBox; "EQM Assigned Equipment FactBox")
            {
                ApplicationArea = All;
                SubPageLink = "Assigned Employee No." = field("No.");
                Visible = EQMShowEquipmentFactBox;
            }
        }
    }

    actions
    {
        addlast(Navigation)
        {
            group(EQMEquipment)
            {
                Caption = 'Equipment';
                Image = FixedAssets;

                action(EQMEquipmentAssignments)
                {
                    ApplicationArea = All;
                    Caption = 'Equipment Assignments';
                    ToolTip = 'View the equipment assignment history of the employee.';
                    Image = History;
                    RunObject = page "EQM Equipment Assignments";
                    RunPageLink = "Employee No." = field("No.");
                }
                action(EQMAssignedEquipment)
                {
                    ApplicationArea = All;
                    Caption = 'Assigned Equipment';
                    ToolTip = 'View the equipment that is currently assigned to the employee.';
                    Image = FixedAssets;
                    RunObject = page "EQM Equipment List";
                    RunPageLink = "Assigned Employee No." = field("No.");
                }
            }
        }
        addlast(Processing)
        {
            action(EQMReturnEquipment)
            {
                ApplicationArea = All;
                Caption = 'Return Equipment';
                ToolTip = 'Return equipment that is assigned to this employee. Choose the equipment in the list. Its status changes to Available and the assignment is closed.';
                Image = Undo;

                trigger OnAction()
                begin
                    ReturnAssignedEquipment();
                end;
            }
        }
    }

    var
        EQMShowEquipmentFactBox: Boolean;
        NoAssignedEquipmentMsg: Label 'No equipment is assigned to employee %1.', Comment = '%1 = employee number';
        EquipmentNoLongerAssignedErr: Label 'Equipment %1 is no longer assigned to employee %2.', Comment = '%1 = equipment number, %2 = employee number';

    trigger OnOpenPage()
    var
        Equipment: Record "EQM Equipment";
    begin
        EQMShowEquipmentFactBox := Equipment.ReadPermission();
    end;

    local procedure ReturnAssignedEquipment()
    var
        Equipment: Record "EQM Equipment";
        EquipmentList: Page "EQM Equipment List";
    begin
        Equipment.SetCurrentKey("Assigned Employee No.", Status);
        Equipment.SetRange("Assigned Employee No.", Rec."No.");
        Equipment.SetRange(Status, Equipment.Status::Assigned);
        if Equipment.IsEmpty() then begin
            Message(NoAssignedEquipmentMsg, Rec."No.");
            exit;
        end;

        EquipmentList.SetTableView(Equipment);
        EquipmentList.LookupMode(true);
        if EquipmentList.RunModal() <> Action::LookupOK then
            exit;

        EquipmentList.GetRecord(Equipment);
        Equipment.Get(Equipment."No.");
        if (Equipment.Status <> Equipment.Status::Assigned) or (Equipment."Assigned Employee No." <> Rec."No.") then
            Error(EquipmentNoLongerAssignedErr, Equipment."No.", Rec."No.");

        Equipment.UnassignEmployee();
    end;
}
