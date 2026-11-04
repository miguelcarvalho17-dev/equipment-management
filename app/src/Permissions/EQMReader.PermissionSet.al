namespace MiguelCarvalho.EquipmentManagement;

permissionset 50100 "EQM - Reader"
{
    Caption = 'Equipment Reader';
    Assignable = true;

    Permissions =
        tabledata "EQM Equipment" = R,
        tabledata "EQM Equipment Assignment" = R,
        tabledata "EQM Equipment Category" = R,
        tabledata "EQM Equipment Setup" = R,
        table "EQM Equipment" = X,
        table "EQM Equipment Assignment" = X,
        table "EQM Equipment Category" = X,
        table "EQM Equipment Setup" = X,
        table "EQM Equipment Cue" = X,
        query "EQM Equipment by Category" = X,
        query "EQM Equipment by Status" = X,
        page "EQM Equipment List" = X,
        page "EQM Equipment Card" = X,
        page "EQM Equipment Assignments" = X,
        page "EQM Assignment History Part" = X,
        page "EQM Equipment Categories" = X,
        page "EQM Equipment Setup" = X,
        page "EQM Equipment Cues" = X,
        page "EQM Equipment Category Chart" = X,
        page "EQM Equipment Status Chart" = X,
        page "EQM Equipment Dashboard" = X,
        page "EQM Equipment Manager RC" = X,
        codeunit "EQM Assignment Mgt." = X,
        codeunit "EQM Employee Subscribers" = X,
        codeunit "EQM Default Data" = X,
        codeunit "EQM Dashboard Mgt." = X;
}
