namespace MiguelCarvalho.EquipmentManagement;

permissionset 50100 "EQM - Read"
{
    Caption = 'Equipment - Read';
    Assignable = true;

    Permissions =
        tabledata "EQM Equipment" = R,
        tabledata "EQM Equipment Assignment" = R,
        tabledata "EQM Equipment Category" = Ri,
        tabledata "EQM Equipment Setup" = Rim,
        table "EQM Equipment" = X,
        table "EQM Equipment Assignment" = X,
        table "EQM Equipment Category" = X,
        table "EQM Equipment Setup" = X,
        page "EQM Equipment List" = X,
        page "EQM Equipment Card" = X,
        page "EQM Equipment Assignments" = X,
        page "EQM Equipment Categories" = X,
        page "EQM Equipment Setup" = X,
        codeunit "EQM Assignment Mgt." = X,
        codeunit "EQM Employee Subscribers" = X,
        codeunit "EQM Default Data" = X;
}
