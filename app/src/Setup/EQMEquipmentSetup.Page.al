namespace MiguelCarvalho.EquipmentManagement;

page 50103 "EQM Equipment Setup"
{
    Caption = 'Equipment Setup';
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    AdditionalSearchTerms = 'equipment numbers, equipment number series, maintenance number series, equipment request numbers, equipment job queue, equipment monitoring, integration events, outbox, feature management, turn features on or off, application setup, default warranty alert days, default maintenance frequency, enable notifications, enable equipment requests, enable APIs';
    AboutTitle = 'About equipment setup';
    AboutText = 'Set the number series for equipment, maintenance records and equipment requests, the default warranty alert days and maintenance frequency, and turn notifications, equipment requests and the APIs on or off for this company. The app runs its monitoring every day through job queue entries: one creates warranty alerts, one checks overdue maintenance. They are created automatically; if one is missing, choose **Schedule Monitoring Jobs**. Turn on **Integration Events Enabled** to record business events for external systems. Users see a change to a feature the next time they open a page.';
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
                field("Request Nos."; Rec."Request Nos.")
                {
                }
            }
            group(Defaults)
            {
                Caption = 'Defaults';

                field("Default Warranty Alert Days"; Rec."Default Warranty Alert Days")
                {
                    Visible = WarrantyAlertsEnabled;
                }
                field("Default Maint. Freq. (Months)"; Rec."Default Maint. Freq. (Months)")
                {
                    Visible = MaintenancePlanningEnabled;
                }
            }
            group(Features)
            {
                Caption = 'Features';

                field(EnableNotifications; EnableNotifications)
                {
                    Caption = 'Enable Notifications';
                    ToolTip = 'Specifies whether users in this company see equipment notifications about expiring warranties, overdue maintenance and equipment that is back from maintenance. When it is off, no equipment notification is shown; when it is on, each user can still turn single notifications off in My Notifications. This is the Notifications feature on the Equipment Features page.';

                    trigger OnValidate()
                    begin
                        FeatureMgt.SetFeatureEnabled("EQM Feature"::Notifications, EnableNotifications);
                    end;
                }
                field(EnableEquipmentRequests; EnableEquipmentRequests)
                {
                    Caption = 'Enable Equipment Requests';
                    ToolTip = 'Specifies whether employees can request equipment and approvers can approve or reject the requests. When it is off, the Equipment Requests pages, actions and tile are hidden and existing requests are kept. This is the Approval Workflows feature on the Equipment Features page. Users see the change the next time they open a page.';

                    trigger OnValidate()
                    begin
                        FeatureMgt.SetFeatureEnabled("EQM Feature"::"Approval Workflows", EnableEquipmentRequests);
                    end;
                }
                field(EnableApis; EnableApis)
                {
                    Caption = 'Enable APIs';
                    ToolTip = 'Specifies whether external systems can use the equipment APIs. When it is off, the APIs return an error, the integration settings are hidden and no integration event entries are written. This is the API Integration feature on the Equipment Features page. Users see the change the next time they open a page.';

                    trigger OnValidate()
                    begin
                        FeatureMgt.SetFeatureEnabled("EQM Feature"::"API Integration", EnableApis);
                    end;
                }
            }
            group(Integration)
            {
                Caption = 'Integration';
                Visible = ApiIntegrationEnabled;

                field("Integration Events Enabled"; Rec."Integration Events Enabled")
                {
                    Visible = ApiIntegrationEnabled;
                }
            }
            group(BackgroundMonitoring)
            {
                Caption = 'Background Monitoring';

                field(WarrantyJobStatus; WarrantyJobStatus)
                {
                    Caption = 'Warranty Alert Job';
                    Editable = false;
                    Visible = WarrantyAlertsEnabled;
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
            action(CreateDemoData)
            {
                Caption = 'Create Demo Data';
                ToolTip = 'Create sample employees, equipment, assignments and maintenance records in this company so that you can try out the app. Existing records are not changed, and running it again only adds what is missing.';
                Image = Import;
                Enabled = CanManage;

                trigger OnAction()
                begin
                    DemoDataMgt.CreateDemoDataWithConfirmation();
                    CurrPage.Update(false);
                end;
            }
            action(DeleteDemoData)
            {
                Caption = 'Delete Demo Data';
                ToolTip = 'Delete the demo data that Create Demo Data added to this company. Records that users created, and demo records that users added data to, are kept.';
                Image = Delete;
                Enabled = CanManage;

                trigger OnAction()
                begin
                    DemoDataMgt.DeleteDemoDataWithConfirmation();
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
            action(ErrorLog)
            {
                Caption = 'Error Log';
                ToolTip = 'View the errors that stopped the daily monitoring jobs or the scheduling of these jobs.';
                Image = ErrorLog;
                Visible = CanReadErrorLog;
                RunObject = page "EQM Error Log";
            }
            action(IntegrationEventEntries)
            {
                Caption = 'Integration Event Entries';
                ToolTip = 'View the integration event entries that external systems read through the API.';
                Image = Log;
                Visible = ApiIntegrationEnabled;
                RunObject = page "EQM Integration Event Entries";
            }
            action(EquipmentFeatures)
            {
                Caption = 'Equipment Features';
                ToolTip = 'Turn the optional equipment features on or off for this company: images, warranty alerts, approval workflows, API integration, maintenance planning and notifications.';
                Image = Setup;
                RunObject = page "EQM Equipment Features";
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
        FeatureMgt: Codeunit "EQM Feature Mgt.";
        DemoDataMgt: Codeunit "EQM Demo Data Mgt.";
        ApiIntegrationEnabled: Boolean;
        WarrantyAlertsEnabled: Boolean;
        MaintenancePlanningEnabled: Boolean;
        EnableNotifications: Boolean;
        EnableEquipmentRequests: Boolean;
        EnableApis: Boolean;
        CanManage: Boolean;
        CanReadErrorLog: Boolean;
        WarrantyJobStatus: Text;
        MaintenanceJobStatus: Text;
        JobsScheduledMsg: Label '%1 monitoring job queue entries were created. %2 already existed and were not changed.', Comment = '%1 = number of job queue entries created, %2 = number of job queue entries that already existed';
        SetupMissingErr: Label 'The equipment setup has not been created in this company yet. Ask a user with the Equipment Administrator permission set to open the Equipment Setup page.';

    trigger OnOpenPage()
    var
        ErrorLogEntry: Record "EQM Error Log Entry";
        DefaultData: Codeunit "EQM Default Data";
    begin
        CanReadErrorLog := ErrorLogEntry.ReadPermission();
        ApiIntegrationEnabled := FeatureMgt.IsEnabled("EQM Feature"::"API Integration");
        WarrantyAlertsEnabled := FeatureMgt.IsEnabled("EQM Feature"::"Warranty Alerts");
        MaintenancePlanningEnabled := FeatureMgt.IsEnabled("EQM Feature"::"Maintenance Planning");
        if not Rec.Get() then begin
            if not Rec.WritePermission() then
                Error(SetupMissingErr);
            MonitoringJobMgt.TryEnsureMonitoringJobs(MonitoringJobMgt.GetSetupTrigger());
            DefaultData.CreateDefaultData();
            Rec.Get();
        end;
        CanManage := Rec.WritePermission();
        EnableNotifications := FeatureMgt.IsEnabled("EQM Feature"::Notifications);
        EnableEquipmentRequests := FeatureMgt.IsEnabled("EQM Feature"::"Approval Workflows");
        EnableApis := ApiIntegrationEnabled;
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
