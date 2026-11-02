namespace MiguelCarvalho.EquipmentManagement;

permissionset 50102 "EQM - Admin"
{
    Caption = 'Equipment - Admin';
    Assignable = true;
    IncludedPermissionSets = "EQM - Edit";

    Permissions =
        tabledata "EQM Equipment Setup" = RIMD;
}
