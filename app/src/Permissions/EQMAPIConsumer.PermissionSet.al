namespace MiguelCarvalho.EquipmentManagement;

permissionset 50104 "EQM - API Consumer"
{
    Caption = 'Equipment API Consumer';
    Assignable = true;

    Permissions =
        tabledata "EQM Equipment" = RIM,
        tabledata "EQM Equipment Assignment" = Rim,
        tabledata "EQM Equipment Audit Entry" = ri,
        tabledata "EQM Equipment Category" = R,
        tabledata "EQM Equipment Setup" = R,
        tabledata "EQM Integration Event Entry" = Rim,
        tabledata "EQM Maintenance Record" = R,
        table "EQM Equipment" = X,
        table "EQM Equipment Assignment" = X,
        table "EQM Equipment Audit Entry" = X,
        table "EQM Equipment Category" = X,
        table "EQM Equipment Setup" = X,
        table "EQM Integration Event Entry" = X,
        table "EQM Maintenance Record" = X,
        page "EQM Equipment API" = X,
        page "EQM Category API" = X,
        page "EQM Assignment API" = X,
        page "EQM Integration Event API" = X,
        codeunit "EQM Assignment Mgt." = X,
        codeunit "EQM Maintenance Mgt." = X,
        codeunit "EQM Business Events" = X,
        codeunit "EQM Business Event Subscr." = X,
        codeunit "EQM Integration Event Subscr." = X,
        codeunit "EQM Integration Event Mgt." = X,
        codeunit "EQM Power Automate Events" = X,
        codeunit "EQM Power Automate Subscr." = X,
        codeunit "EQM Audit Trail Mgt." = X,
        codeunit "EQM Audit Trail Subscr." = X;
}
