namespace MiguelCarvalho.EquipmentManagement;

using System.Threading;

/// <summary>
/// Runs from a job queue entry and creates the warranty alerts for today. Schedule it once a day.
/// </summary>
codeunit 50111 "EQM Warranty Alert Job"
{
    TableNo = "Job Queue Entry";

    trigger OnRun()
    var
        WarrantyAlertMgt: Codeunit "EQM Warranty Alert Mgt.";
        CreatedCount: Integer;
        CancelledCount: Integer;
    begin
        WarrantyAlertMgt.GenerateAlerts(Today(), true, CreatedCount, CancelledCount);
    end;
}
