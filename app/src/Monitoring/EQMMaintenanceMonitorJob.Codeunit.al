namespace MiguelCarvalho.EquipmentManagement;

using System.Threading;

/// <summary>
/// Runs from a job queue entry and checks every day which maintenance records are overdue. Schedule it once a day;
/// Equipment Setup does this automatically. An error that stops the job is written to the equipment error log.
/// </summary>
codeunit 50114 "EQM Maintenance Monitor Job"
{
    TableNo = "Job Queue Entry";

    trigger OnRun()
    var
        JobRunner: Codeunit "EQM Monitoring Job Runner";
    begin
        JobRunner.RunJob(Codeunit::"EQM Maintenance Monitor Job", "EQM Error Operation"::"Overdue Maintenance Job");
    end;
}
