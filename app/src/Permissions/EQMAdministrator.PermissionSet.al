namespace MiguelCarvalho.EquipmentManagement;

using Microsoft.Foundation.NoSeries;
using System.Threading;

permissionset 50102 "EQM - Administrator"
{
    Caption = 'Equipment Administrator';
    Assignable = true;
    IncludedPermissionSets = "EQM - Manager";

    Permissions =
        tabledata "EQM Demo Data Entry" = rimd,
        tabledata "EQM Equipment" = RIMD,
        tabledata "EQM Equipment Assignment" = Rimd,
        tabledata "EQM Equipment Audit Entry" = id,
        tabledata "EQM Equipment Category" = RIMD,
        tabledata "EQM Equipment Setup" = RIMD,
        tabledata "EQM Feature Setup" = RIMD,
        tabledata "EQM Integration Event Entry" = mD,
        tabledata "EQM Maintenance History Entry" = id,
        tabledata "EQM Maintenance Log Entry" = id,
        tabledata "EQM Maintenance Record" = RIMd,
        tabledata "EQM Warranty Alert" = RIMd,
        tabledata "No. Series" = ri,
        tabledata "No. Series Line" = ri,
        tabledata "Job Queue Entry" = rim;
}
