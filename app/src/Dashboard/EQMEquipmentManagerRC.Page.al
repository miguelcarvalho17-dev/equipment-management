namespace MiguelCarvalho.EquipmentManagement;

page 50110 "EQM Equipment Manager RC"
{
    Caption = 'Equipment Manager';
    PageType = RoleCenter;
    ApplicationArea = All;

    layout
    {
        area(RoleCenter)
        {
            part(Cues; "EQM Equipment Cues")
            {
            }
            part(CategoryChart; "EQM Equipment Category Chart")
            {
            }
            part(StatusChart; "EQM Equipment Status Chart")
            {
            }
        }
    }

    actions
    {
        area(Embedding)
        {
            action(EquipmentList)
            {
                Caption = 'Equipment';
                ToolTip = 'Opens the list of all equipment.';
                RunObject = page "EQM Equipment List";
            }
            action(AssignmentList)
            {
                Caption = 'Assignments';
                ToolTip = 'Opens the assignment history of all equipment.';
                RunObject = page "EQM Equipment Assignments";
            }
            action(CategoryList)
            {
                Caption = 'Categories';
                ToolTip = 'Opens the list of equipment categories.';
                RunObject = page "EQM Equipment Categories";
            }
        }
        area(Sections)
        {
            group(Setup)
            {
                Caption = 'Setup';

                action(EquipmentSetup)
                {
                    Caption = 'Equipment Setup';
                    ToolTip = 'Opens the equipment setup.';
                    RunObject = page "EQM Equipment Setup";
                }
                action(EquipmentCategories)
                {
                    Caption = 'Equipment Categories';
                    ToolTip = 'Opens the list of equipment categories.';
                    RunObject = page "EQM Equipment Categories";
                }
            }
        }
        area(Creation)
        {
            action(NewEquipment)
            {
                Caption = 'Equipment';
                ToolTip = 'Creates a new equipment record.';
                Image = New;
                RunObject = page "EQM Equipment Card";
                RunPageMode = Create;
            }
        }
    }
}
