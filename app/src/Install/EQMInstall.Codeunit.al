namespace MiguelCarvalho.EquipmentManagement;

codeunit 50104 "EQM Install"
{
    Subtype = Install;
    Access = Internal;

    trigger OnInstallAppPerCompany()
    var
        ChangeLogRegistration: Codeunit "EQM Change Log Registration";
        DefaultData: Codeunit "EQM Default Data";
        MonitoringJobMgt: Codeunit "EQM Monitoring Job Mgt.";
        UpgradeMgt: Codeunit "EQM Upgrade Mgt.";
    begin
        // The isolated run must come before any write in the install transaction.
        MonitoringJobMgt.TryEnsureMonitoringJobs(MonitoringJobMgt.GetInstallTrigger());
        DefaultData.CreateDefaultData();
        ChangeLogRegistration.RegisterChangeLogSetupOnce();
        UpgradeMgt.UpgradePerCompany();
    end;
}
