namespace MiguelCarvalho.EquipmentManagement;

using System.Threading;

/// <summary>
/// Runs from a job queue entry and creates the warranty alerts for today. Schedule it once a day.
/// An error that stops the job is written to the equipment error log.
/// </summary>
codeunit 50111 "EQM Warranty Alert Job"
{
    TableNo = "Job Queue Entry";

    trigger OnRun()
    var
        JobRunner: Codeunit "EQM Monitoring Job Runner";
    begin
        JobRunner.RunJob(Codeunit::"EQM Warranty Alert Job", "EQM Error Operation"::"Warranty Alert Job");
    end;
}
