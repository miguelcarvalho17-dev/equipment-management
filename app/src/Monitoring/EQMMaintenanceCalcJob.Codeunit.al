namespace MiguelCarvalho.EquipmentManagement;

using System.Threading;

/// <summary>
/// Runs from a job queue entry and recalculates the next maintenance date of the equipment every day.
/// Equipment Setup schedules it automatically. An error that stops the job is written to the equipment error log.
/// </summary>
codeunit 50145 "EQM Maintenance Calc. Job"
{
    TableNo = "Job Queue Entry";

    trigger OnRun()
    var
        JobRunner: Codeunit "EQM Monitoring Job Runner";
    begin
        JobRunner.RunJob(Codeunit::"EQM Maintenance Calc. Job", "EQM Error Operation"::"Maintenance Calculation Job");
    end;
}
