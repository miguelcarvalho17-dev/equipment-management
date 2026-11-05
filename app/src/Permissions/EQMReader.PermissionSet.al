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
        tabledata "EQM Maintenance Record" = R,
        table "EQM Equipment" = X,
        table "EQM Equipment Assignment" = X,
        table "EQM Equipment Category" = X,
        table "EQM Equipment Setup" = X,
        table "EQM Maintenance Record" = X,
        table "EQM Equipment Cue" = X,
        query "EQM Equipment by Category" = X,
        query "EQM Equipment by Status" = X,
        page "EQM Equipment List" = X,
        page "EQM Equipment Card" = X,
        page "EQM Equipment Assignments" = X,
        page "EQM Assignment History Part" = X,
        page "EQM Equipment FactBox" = X,
        page "EQM Assigned Equipment FactBox" = X,
        page "EQM Equipment Categories" = X,
        page "EQM Equipment Setup" = X,
        page "EQM Equipment Cues" = X,
        page "EQM Equipment Category Chart" = X,
        page "EQM Equipment Status Chart" = X,
        page "EQM Equipment Dashboard" = X,
        page "EQM Equipment Manager RC" = X,
        page "EQM Maintenance Records" = X,
        page "EQM Maintenance Record Card" = X,
        page "EQM Maintenance FactBox" = X,
        codeunit "EQM Assignment Mgt." = X,
        codeunit "EQM Employee Subscribers" = X,
        codeunit "EQM Default Data" = X,
        codeunit "EQM Dashboard Mgt." = X,
        codeunit "EQM Maintenance Mgt." = X;
}
