namespace MiguelCarvalho.EquipmentManagement;

permissionset 50105 "EQM - Operator"
{
    Caption = 'Equipment Operator';
    Assignable = true;
    IncludedPermissionSets = "EQM - Reader";

    Permissions =
        tabledata "EQM Equipment" = RM,
        tabledata "EQM Equipment Assignment" = Rim,
        tabledata "EQM Equipment Audit Entry" = i,
        tabledata "EQM Equipment Note" = RI,
        tabledata "EQM Integration Event Entry" = i,
        tabledata "EQM Maintenance History Entry" = i,
        tabledata "EQM Maintenance Log Entry" = i,
        tabledata "EQM Maintenance Record" = RIM,
        tabledata "EQM Warranty Alert" = RIM;
}
