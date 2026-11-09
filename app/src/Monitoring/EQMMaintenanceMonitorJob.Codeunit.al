namespace MiguelCarvalho.EquipmentManagement;

using System.Threading;

/// <summary>
/// Runs from a job queue entry and checks every day which maintenance records are overdue. Schedule it once a day;
/// Equipment Setup does this automatically.
/// </summary>
codeunit 50114 "EQM Maintenance Monitor Job"
{
    TableNo = "Job Queue Entry";

    trigger OnRun()
    var
        MaintenanceMgt: Codeunit "EQM Maintenance Mgt.";
    begin
        MaintenanceMgt.CheckOverdueMaintenance(Today(), true);
    end;
}
