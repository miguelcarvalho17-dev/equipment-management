namespace MiguelCarvalho.EquipmentManagement;

permissionset 50101 "EQM - Edit"
{
    Caption = 'Equipment - Edit';
    Assignable = true;
    IncludedPermissionSets = "EQM - Read";

    Permissions =
        tabledata "EQM Equipment" = RIMD,
        tabledata "EQM Equipment Category" = RIMD;
}
