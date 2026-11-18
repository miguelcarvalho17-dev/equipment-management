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
        FeatureMgt: Codeunit "EQM Feature Mgt.";
        CreatedCount: Integer;
        CancelledCount: Integer;
    begin
        // Warranty Alerts turned off: no alerts are created. The warranty-expired business event is not part of the feature.
        if FeatureMgt.IsEnabled("EQM Feature"::"Warranty Alerts") then begin
            WarrantyAlertMgt.GenerateAlerts(Today(), true, CreatedCount, CancelledCount);
            // A failing partner subscriber of OnWarrantyExpired must not roll back the alerts that were just created.
            Commit();
        end;
        WarrantyAlertMgt.RaiseWarrantyExpiredEvents(Today());
    end;
}
