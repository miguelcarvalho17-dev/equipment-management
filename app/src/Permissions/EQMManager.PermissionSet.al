namespace MiguelCarvalho.EquipmentManagement;

permissionset 50101 "EQM - Manager"
{
    Caption = 'Equipment Manager';
    Assignable = true;
    IncludedPermissionSets = "EQM - Reader";

    Permissions =
        tabledata "EQM Equipment" = RIM,
        tabledata "EQM Equipment Assignment" = Rim,
        tabledata "EQM Maintenance Record" = RIM;
}
