namespace MiguelCarvalho.EquipmentManagement;

permissionset 50101 "EQM - Manager"
{
    Caption = 'Equipment Manager';
    Assignable = true;
    IncludedPermissionSets = "EQM - Reader";

    Permissions =
        tabledata "EQM Equipment" = RIM,
        tabledata "EQM Equipment Assignment" = Rim,
        tabledata "EQM Maintenance History Entry" = i,
        tabledata "EQM Maintenance Log Entry" = i,
        tabledata "EQM Maintenance Record" = RIM,
        tabledata "EQM Warranty Alert" = RIM;
}
