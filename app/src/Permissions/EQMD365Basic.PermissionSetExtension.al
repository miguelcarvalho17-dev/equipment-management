namespace MiguelCarvalho.EquipmentManagement;

using System.Security.AccessControl;

// Indirect-only permission: the lowercase "r" exposes no data directly. It only takes effect inside
// objects whose Permissions property lists the table (codeunit "EQM Employee Subscribers"), so users
// who can delete employees get the equipment guard error instead of a permission error.
permissionsetextension 50103 "EQM D365 BASIC" extends "D365 BASIC"
{
    Permissions =
        tabledata "EQM Equipment" = r;
}
