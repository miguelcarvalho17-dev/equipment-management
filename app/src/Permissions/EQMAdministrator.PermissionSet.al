namespace MiguelCarvalho.EquipmentManagement;

using Microsoft.Foundation.NoSeries;

permissionset 50102 "EQM - Administrator"
{
    Caption = 'Equipment Administrator';
    Assignable = true;
    IncludedPermissionSets = "EQM - Manager";

    Permissions =
        tabledata "EQM Equipment" = RIMD,
        tabledata "EQM Equipment Category" = RIMD,
        tabledata "EQM Equipment Setup" = RIMD,
        tabledata "No. Series" = ri,
        tabledata "No. Series Line" = ri;
}
