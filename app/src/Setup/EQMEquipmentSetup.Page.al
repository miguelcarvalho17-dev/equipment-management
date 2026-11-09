namespace MiguelCarvalho.EquipmentManagement;

page 50103 "EQM Equipment Setup"
{
    Caption = 'Equipment Setup';
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    AdditionalSearchTerms = 'equipment numbers, equipment number series, maintenance number series, equipment job queue, equipment monitoring';
    AboutTitle = 'About equipment setup';
    AboutText = 'Set the number series for equipment and maintenance records. The app runs its monitoring every day through job queue entries: one creates warranty alerts, one checks overdue maintenance. They are created automatically; if one is missing, choose **Schedule Monitoring Jobs**.';
    SourceTable = "EQM Equipment Setup";
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(Numbering)
            {
                Caption = 'Numbering';

                field("Equipment Nos."; Rec."Equipment Nos.")
                {
                }
                field("Maintenance Nos."; Rec."Maintenance Nos.")
                {
                }
            }
            group(BackgroundMonitoring)
            {
                Caption = 'Background Monitoring';

                field(WarrantyJobStatus; WarrantyJobStatus)
                {
                    Caption = 'Warranty Alert Job';
                    Editable = false;
                    ToolTip = 'Specifies the status of the job queue entry that creates warranty alerts every day. Not scheduled means that no entry exists; choose Schedule Monitoring Jobs to create it.';
                }
                field(MaintenanceJobStatus; MaintenanceJobStatus)
                {
                    Caption = 'Overdue Maintenance Job';
                    Editable = false;
                    ToolTip = 'Specifies the status of the job queue entry that checks overdue maintenance every day. Not scheduled means that no entry exists; choose Schedule Monitoring Jobs to create it.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ScheduleMonitoringJobs)
            {
                Caption = 'Schedule Monitoring Jobs';
                ToolTip = 'Create the job queue entries that run the equipment monitoring every day, if they do not exist. Existing entries are not changed.';
                Image = Calendar;
                Enabled = CanManage;

                trigger OnAction()
                var
                    CreatedCount: Integer;
                    ExistingCount: Integer;
                begin
                    MonitoringJobMgt.EnsureMonitoringJobs(CreatedCount, ExistingCount, MonitoringJobMgt.GetActionTrigger());
                    Message(JobsScheduledMsg, CreatedCount, ExistingCount);
                    CurrPage.Update(false);
                end;
            }
        }
        area(Navigation)
        {
            action(MonitoringJobQueueEntries)
            {
                Caption = 'Monitoring Job Queue Entries';
                ToolTip = 'View the job queue entries that run the equipment monitoring, to see when they ran, change the time or restart them.';
                Image = JobListSetup;

                trigger OnAction()
                begin
                    MonitoringJobMgt.ShowMonitoringJobs();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(ScheduleMonitoringJobs_Promoted; ScheduleMonitoringJobs)
                {
                }
            }
        }
    }

    var
        MonitoringJobMgt: Codeunit "EQM Monitoring Job Mgt.";
        CanManage: Boolean;
        WarrantyJobStatus: Text;
        MaintenanceJobStatus: Text;
        JobsScheduledMsg: Label '%1 monitoring job queue entries were created. %2 already existed and were not changed.', Comment = '%1 = number of job queue entries created, %2 = number of job queue entries that already existed';
        SetupMissingErr: Label 'The equipment setup has not been created in this company yet. Ask a user with the Equipment Administrator permission set to open the Equipment Setup page.';

    trigger OnOpenPage()
    var
        DefaultData: Codeunit "EQM Default Data";
    begin
        if not Rec.Get() then begin
            if not Rec.WritePermission() then
                Error(SetupMissingErr);
            MonitoringJobMgt.TryEnsureMonitoringJobs(MonitoringJobMgt.GetSetupTrigger());
            DefaultData.CreateDefaultData();
            Rec.Get();
        end;
        CanManage := Rec.WritePermission();
        if not CanManage then
            CurrPage.Editable := false;
    end;

    trigger OnAfterGetRecord()
    begin
        UpdateJobStatus();
    end;

    local procedure UpdateJobStatus()
    begin
        WarrantyJobStatus := MonitoringJobMgt.GetJobStatusText(Codeunit::"EQM Warranty Alert Job");
        MaintenanceJobStatus := MonitoringJobMgt.GetJobStatusText(Codeunit::"EQM Maintenance Monitor Job");
    end;
}
