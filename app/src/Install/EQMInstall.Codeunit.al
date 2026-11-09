namespace MiguelCarvalho.EquipmentManagement;

codeunit 50104 "EQM Install"
{
    Subtype = Install;
    Access = Internal;

    trigger OnInstallAppPerCompany()
    var
        DefaultData: Codeunit "EQM Default Data";
        MonitoringJobMgt: Codeunit "EQM Monitoring Job Mgt.";
    begin
        // The isolated run must come before any write in the install transaction.
        MonitoringJobMgt.TryEnsureMonitoringJobs(MonitoringJobMgt.GetInstallTrigger());
        DefaultData.CreateDefaultData();
    end;
}
