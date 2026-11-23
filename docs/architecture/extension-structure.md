# Extension structure

> Applies to Equipment Management 29.0.0.0 (not released). Facts are taken from the repository on branch feature/FR-060-developer-documentation; nothing is verified in a Business Central sandbox.

This page describes the repository layout, the app and test folders, the naming and ID rules, and lists every AL object of the app and the test app. The object tables are generated from the source with a script, not typed by hand, and they are reviewed against `app/src` and `test/src` in each change.

**In this article**
- [Repository layout](#repository-layout)
- [App folder](#app-folder)
- [Naming conventions](#naming-conventions)
- [Object ID allocation](#object-id-allocation)
- [Object inventory (app)](#object-inventory-app)
- [Public surface](#public-surface)
- [Permission sets](#permission-sets)
- [Test app](#test-app)
- [Maintaining this page](#maintaining-this-page)
- [Related](#related)

## Repository layout

```text
equipment-management/
├── app/                     main app (AL extension): app.json, AppSourceCop.json, src/, Translations/
├── test/                    test app: app.json, src/ (test codeunits)
├── .github/
│   ├── workflows/           AL-Go workflows (CICD, PullRequestHandler, RepoChecks, ...)
│   ├── scripts/             repo_checks.py, coverage_check.py, version_check.py, xlf_sync.py and their tests
│   ├── coverage/            coverage-register.json (FR-047)
│   ├── AL-Go-Settings.json  repository-level AL-Go settings
│   └── Test *.settings.json settings for the Test Current / Next Minor / Next Major workflows
├── .AL-Go/                  project settings, CI ruleset, local and cloud dev environment scripts
├── docs/                    documentation (see docs/README.md)
├── .claude/                 agent instructions and skills (not tracked in git: see .gitignore)
├── CHANGELOG.md             change history, newest first
├── DECISIONS.md             log of decisions
├── CLAUDE.md                project facts and rules for agents and contributors
├── README.md                project overview and roadmap
└── LICENSE
```

`src/` is not used as a top-level folder. The AL-Go settings (`appFolders` is `app`, `testFolders` is `test`), `repo_checks.py` and `coverage_check.py` read the folders `app/` and `test/`. A rename would break the build, the tests and the checks, so the documentation follows the existing structure.

## App folder

| Path | Purpose |
|---|---|
| `app/app.json` | Manifest. See [architecture overview](README.md#platform-and-manifest). |
| `app/AppSourceCop.json` | AppSourceCop settings. Holds `mandatoryAffixes` = `EQM` only. There is no baseline until the first release. |
| `app/.vscode/settings.json` | Analyzers CodeCop, UICop and AppSourceCop, and the CI ruleset `../.AL-Go/equipment.ruleset.json`. |
| `app/src/<Module>/` | One folder per functional module (26 folders). The modules are described in the [architecture overview](README.md#functional-modules). |
| `app/src/Reports/Layouts/` | The four Excel layouts: `EQMAssetUtilization.xlsx`, `EQMEquipmentRegister.xlsx`, `EQMMaintCostAnalysis.xlsx`, `EQMUsageAnalytics.xlsx`. |
| `app/Translations/` | `Equipment Management.g.xlf` (generated), `Equipment Management.pt-PT.xlf`, `Equipment Management.es-ES.xlf`. |
| `app/.alpackages/` | Downloaded symbols. Ignored by git (`.alpackages/` in `.gitignore`). |

Never edit the `.g.xlf` by hand. The build regenerates it. The language files are kept in step with `python3 .github/scripts/xlf_sync.py` (FR-055, see [setup](../setup/README.md#run-the-repository-checks-locally)).

`.app` files (`*.app`) are ignored by git. If an `.app` file exists in `app/` or `test/` on your machine, it is a local build output.

## Naming conventions

- **File name:** `EQM<Name>.<ObjectType>.al`, for example `EQMEquipment.Table.al`, `EQMAssignmentMgt.Codeunit.al`. The object type suffixes in use are `Table`, `TableExt`, `Page`, `PageExt`, `Codeunit`, `Enum`, `EnumExt`, `Query`, `Report`, `PermissionSet`, `PermissionSetExt` and `Profile`.
- **Object name:** starts with `EQM ` (for example `"EQM Equipment"`). The profile is named `EQM EQUIPMENT MANAGER` and the permission sets `EQM - Reader` and so on.
- **Members added to standard objects** carry the affix: the field `EQM Attachment Category`, the part `EQMAssignedEquipmentFactBox`, the actions `EQMEquipmentAssignments` and so on.
- **Codeunit roles:** `... Mgt.` holds business logic. `... Subscr.` and `... Subscribers` hold event subscribers and only delegate. `... Job` codeunits run from the job queue.
- **Labels:** suffix `Err`, `Msg`, `Qst`, `Lbl`, `Tok`, `Txt`. `Tok` labels are `Locked = true`.

## Object ID allocation

- App: 50100 to 50149. Test app: 50150 to 50199. Both ranges are demo ranges (see [AppSource readiness](appsource-readiness.md)).
- IDs are unique per object type. `repo_checks.py` (check 1) fails on a duplicate or an ID outside the range of the app that owns it.
- New IDs only come from `al_getnextobjectid` (or the plan). Do not pick an ID by hand.
- Widening a range changes `app.json` and is a user decision (stop list in `CLAUDE.md`).
- The demo data objects use the last ID of the app range (50149 for table and codeunit). Check free IDs with `al_getnextobjectid`.

## Object inventory (app)

Counts: 133 objects: 18 tables, 1 table extension, 39 pages, 2 page extensions, 4 reports, 39 codeunits, 6 queries, 15 enums, 1 enum extension, 1 interface, 5 permission sets, 1 permission set extension, 1 profile. FR-064 added codeunits 50146 and 50147, enum 50114 and the interface.

Access is the value of `Access =` in the file. "default (Public)" means the object has no `Access` property, which makes it public. Profiles have no ID.

| Type | ID | Name | Access | File |
|---|---|---|---|---|
| Table | 50100 | EQM Equipment | Public | `app/src/Equipment/EQMEquipment.Table.al` |
| Table | 50101 | EQM Equipment Category | Public | `app/src/Equipment/EQMEquipmentCategory.Table.al` |
| Table | 50102 | EQM Equipment Setup | Public | `app/src/Setup/EQMEquipmentSetup.Table.al` |
| Table | 50103 | EQM Equipment Assignment | Public | `app/src/Assignment/EQMEquipmentAssignment.Table.al` |
| Table | 50104 | EQM Equipment Cue | Internal | `app/src/Dashboard/EQMEquipmentCue.Table.al` |
| Table | 50105 | EQM Maintenance Record | Public | `app/src/Maintenance/EQMMaintenanceRecord.Table.al` |
| Table | 50106 | EQM Maintenance History Entry | Public | `app/src/Maintenance/EQMMaintenanceHistoryEntry.Table.al` |
| Table | 50107 | EQM Warranty Alert | Public | `app/src/Warranty/EQMWarrantyAlert.Table.al` |
| Table | 50108 | EQM Maintenance Log Entry | Public | `app/src/Maintenance/EQMMaintenanceLogEntry.Table.al` |
| Table | 50109 | EQM Equipment Note | Public | `app/src/Notes/EQMEquipmentNote.Table.al` |
| Table | 50110 | EQM Integration Event Entry | Public | `app/src/Integration/EQMIntegrationEventEntry.Table.al` |
| Table | 50111 | EQM Equipment Request | Public | `app/src/Request/EQMEquipmentRequest.Table.al` |
| Table | 50112 | EQM Equipment Audit Entry | Public | `app/src/AuditTrail/EQMEquipmentAuditEntry.Table.al` |
| Table | 50113 | EQM Maint. Cost Buffer | Internal | `app/src/Reports/EQMMaintCostBuffer.Table.al` |
| Table | 50114 | EQM Feature Setup | Internal | `app/src/Features/EQMFeatureSetup.Table.al` |
| Table | 50115 | EQM Error Log Entry | Internal | `app/src/ErrorLog/EQMErrorLogEntry.Table.al` |
| Table | 50116 | EQM Usage Analytics Buffer | Internal | `app/src/UsageAnalytics/EQMUsageAnalyticsBuffer.Table.al` |
| Table | 50149 | EQM Demo Data Entry | Internal | `app/src/DemoData/EQMDemoDataEntry.Table.al` |
| Table extension | 50100 | EQM Document Attachment | default (Public) | `app/src/Attachments/EQMDocumentAttachment.TableExt.al` |
| Page | 50100 | EQM Equipment List | default (Public) | `app/src/Equipment/EQMEquipmentList.Page.al` |
| Page | 50101 | EQM Equipment Card | default (Public) | `app/src/Equipment/EQMEquipmentCard.Page.al` |
| Page | 50102 | EQM Equipment Categories | default (Public) | `app/src/Equipment/EQMEquipmentCategories.Page.al` |
| Page | 50103 | EQM Equipment Setup | default (Public) | `app/src/Setup/EQMEquipmentSetup.Page.al` |
| Page | 50104 | EQM Equipment Assignments | default (Public) | `app/src/Assignment/EQMEquipmentAssignments.Page.al` |
| Page | 50105 | EQM Assignment History Part | default (Public) | `app/src/Assignment/EQMAssignmentHistoryPart.Page.al` |
| Page | 50106 | EQM Equipment Cues | default (Public) | `app/src/Dashboard/EQMEquipmentCues.Page.al` |
| Page | 50107 | EQM Equipment Category Chart | default (Public) | `app/src/Dashboard/EQMEquipmentCategoryChart.Page.al` |
| Page | 50108 | EQM Equipment Status Chart | default (Public) | `app/src/Dashboard/EQMEquipmentStatusChart.Page.al` |
| Page | 50109 | EQM Equipment Dashboard | default (Public) | `app/src/Dashboard/EQMEquipmentDashboard.Page.al` |
| Page | 50110 | EQM Equipment Manager RC | default (Public) | `app/src/Dashboard/EQMEquipmentManagerRC.Page.al` |
| Page | 50111 | EQM Equipment FactBox | default (Public) | `app/src/Equipment/EQMEquipmentFactBox.Page.al` |
| Page | 50112 | EQM Assigned Equipment FactBox | default (Public) | `app/src/Employee/EQMAssignedEquipmentFactBox.Page.al` |
| Page | 50113 | EQM Maintenance Records | default (Public) | `app/src/Maintenance/EQMMaintenanceRecords.Page.al` |
| Page | 50114 | EQM Maintenance Record Card | default (Public) | `app/src/Maintenance/EQMMaintenanceRecordCard.Page.al` |
| Page | 50115 | EQM Maintenance FactBox | default (Public) | `app/src/Maintenance/EQMMaintenanceFactBox.Page.al` |
| Page | 50116 | EQM Maintenance History Part | default (Public) | `app/src/Maintenance/EQMMaintenanceHistoryPart.Page.al` |
| Page | 50117 | EQM Maintenance History | default (Public) | `app/src/Maintenance/EQMMaintenanceHistory.Page.al` |
| Page | 50118 | EQM Category Cost Chart | default (Public) | `app/src/Dashboard/EQMCategoryCostChart.Page.al` |
| Page | 50119 | EQM Equipment Cost Chart | default (Public) | `app/src/Dashboard/EQMEquipmentCostChart.Page.al` |
| Page | 50120 | EQM Warranty Alerts | default (Public) | `app/src/Warranty/EQMWarrantyAlerts.Page.al` |
| Page | 50121 | EQM Maintenance Log Entries | default (Public) | `app/src/Maintenance/EQMMaintenanceLogEntries.Page.al` |
| Page | 50122 | EQM Equipment Picture | default (Public) | `app/src/Equipment/EQMEquipmentPicture.Page.al` |
| Page | 50123 | EQM Equipment API | default (Public) | `app/src/API/EQMEquipmentAPI.Page.al` |
| Page | 50124 | EQM Category API | default (Public) | `app/src/API/EQMCategoryAPI.Page.al` |
| Page | 50125 | EQM Assignment API | default (Public) | `app/src/API/EQMAssignmentAPI.Page.al` |
| Page | 50126 | EQM Integration Event API | default (Public) | `app/src/API/EQMIntegrationEventAPI.Page.al` |
| Page | 50130 | EQM Equipment Notes Part | default (Public) | `app/src/Notes/EQMEquipmentNotesPart.Page.al` |
| Page | 50131 | EQM Equipment Notes | default (Public) | `app/src/Notes/EQMEquipmentNotes.Page.al` |
| Page | 50132 | EQM Integration Event Entries | default (Public) | `app/src/Integration/EQMIntegrationEventEntries.Page.al` |
| Page | 50133 | EQM Equipment Requests | default (Public) | `app/src/Request/EQMEquipmentRequests.Page.al` |
| Page | 50134 | EQM Equipment Request Card | default (Public) | `app/src/Request/EQMEquipmentRequestCard.Page.al` |
| Page | 50135 | EQM Request Decision | default (Public) | `app/src/Request/EQMRequestDecision.Page.al` |
| Page | 50136 | EQM Equipment Audit Trail | default (Public) | `app/src/AuditTrail/EQMEquipmentAuditTrail.Page.al` |
| Page | 50137 | EQM Equipment Summary FactBox | default (Public) | `app/src/Equipment/EQMEquipmentSummaryFactBox.Page.al` |
| Page | 50138 | EQM Equipment Stats. FactBox | default (Public) | `app/src/Equipment/EQMEquipmentStatsFactBox.Page.al` |
| Page | 50139 | EQM Attachment Count FactBox | default (Public) | `app/src/Attachments/EQMAttachmentCountFactBox.Page.al` |
| Page | 50140 | EQM Equipment Features | default (Public) | `app/src/Features/EQMEquipmentFeatures.Page.al` |
| Page | 50141 | EQM Error Log | default (Public) | `app/src/ErrorLog/EQMErrorLog.Page.al` |
| Page extension | 50100 | EQM Employee Card | default (Public) | `app/src/Employee/EQMEmployeeCard.PageExt.al` |
| Page extension | 50101 | EQM Doc. Attachment Details | default (Public) | `app/src/Attachments/EQMDocAttachmentDetails.PageExt.al` |
| Report | 50100 | EQM Equipment Register | default (Public) | `app/src/Reports/EQMEquipmentRegister.Report.al` |
| Report | 50101 | EQM Asset Utilization | default (Public) | `app/src/Reports/EQMAssetUtilization.Report.al` |
| Report | 50102 | EQM Maint. Cost Analysis | default (Public) | `app/src/Reports/EQMMaintCostAnalysis.Report.al` |
| Report | 50103 | EQM Usage Analytics | default (Public) | `app/src/Reports/EQMUsageAnalytics.Report.al` |
| Codeunit | 50103 | EQM Employee Subscribers | Internal | `app/src/Employee/EQMEmployeeSubscribers.Codeunit.al` |
| Codeunit | 50104 | EQM Install | Internal | `app/src/Install/EQMInstall.Codeunit.al` |
| Codeunit | 50105 | EQM Default Data | Internal | `app/src/Setup/EQMDefaultData.Codeunit.al` |
| Codeunit | 50106 | EQM Assignment Mgt. | Public | `app/src/Assignment/EQMAssignmentMgt.Codeunit.al` |
| Codeunit | 50107 | EQM Dashboard Mgt. | Internal | `app/src/Dashboard/EQMDashboardMgt.Codeunit.al` |
| Codeunit | 50108 | EQM Maintenance Mgt. | Internal | `app/src/Maintenance/EQMMaintenanceMgt.Codeunit.al` |
| Codeunit | 50109 | EQM Maintenance-Post | Public | `app/src/Maintenance/EQMMaintenancePost.Codeunit.al` |
| Codeunit | 50110 | EQM Warranty Alert Mgt. | Internal | `app/src/Warranty/EQMWarrantyAlertMgt.Codeunit.al` |
| Codeunit | 50111 | EQM Warranty Alert Job | default (Public) | `app/src/Warranty/EQMWarrantyAlertJob.Codeunit.al` |
| Codeunit | 50112 | EQM Notification Mgt. | Internal | `app/src/Notifications/EQMNotificationMgt.Codeunit.al` |
| Codeunit | 50113 | EQM Notification Subscribers | Internal | `app/src/Notifications/EQMNotificationSubscribers.Codeunit.al` |
| Codeunit | 50114 | EQM Maintenance Monitor Job | default (Public) | `app/src/Monitoring/EQMMaintenanceMonitorJob.Codeunit.al` |
| Codeunit | 50115 | EQM Monitoring Job Mgt. | Internal | `app/src/Monitoring/EQMMonitoringJobMgt.Codeunit.al` |
| Codeunit | 50116 | EQM Maintenance Log Mgt. | Internal | `app/src/Maintenance/EQMMaintenanceLogMgt.Codeunit.al` |
| Codeunit | 50117 | EQM Equipment Picture Mgt. | Internal | `app/src/Equipment/EQMEquipmentPictureMgt.Codeunit.al` |
| Codeunit | 50118 | EQM Doc. Attachment Subscr. | Internal | `app/src/Attachments/EQMDocAttachmentSubscr.Codeunit.al` |
| Codeunit | 50119 | EQM Business Events | Public | `app/src/BusinessEvents/EQMBusinessEvents.Codeunit.al` |
| Codeunit | 50120 | EQM Business Event Subscr. | Internal | `app/src/BusinessEvents/EQMBusinessEventSubscr.Codeunit.al` |
| Codeunit | 50121 | EQM Integration Event Subscr. | Internal | `app/src/Integration/EQMIntegrationEventSubscr.Codeunit.al` |
| Codeunit | 50122 | EQM Integration Event Mgt. | Internal | `app/src/Integration/EQMIntegrationEventMgt.Codeunit.al` |
| Codeunit | 50130 | EQM Power Automate Events | Public | `app/src/PowerAutomate/EQMPowerAutomateEvents.Codeunit.al` |
| Codeunit | 50131 | EQM Power Automate Subscr. | Internal | `app/src/PowerAutomate/EQMPowerAutomateSubscr.Codeunit.al` |
| Codeunit | 50132 | EQM Request Approval Mgt. | Public | `app/src/Request/EQMRequestApprovalMgt.Codeunit.al` |
| Codeunit | 50133 | EQM Change Log Registration | Internal | `app/src/ChangeLog/EQMChangeLogRegistration.Codeunit.al` |
| Codeunit | 50134 | EQM Upgrade | Internal | `app/src/Install/EQMUpgrade.Codeunit.al` |
| Codeunit | 50135 | EQM Audit Trail Mgt. | Internal | `app/src/AuditTrail/EQMAuditTrailMgt.Codeunit.al` |
| Codeunit | 50136 | EQM Audit Trail Subscr. | Internal | `app/src/AuditTrail/EQMAuditTrailSubscr.Codeunit.al` |
| Codeunit | 50137 | EQM Equipment Attachment Mgt. | Internal | `app/src/Attachments/EQMEquipmentAttachmentMgt.Codeunit.al` |
| Codeunit | 50138 | EQM Feature Mgt. | Internal | `app/src/Features/EQMFeatureMgt.Codeunit.al` |
| Codeunit | 50139 | EQM Upgrade Mgt. | Internal | `app/src/Install/EQMUpgradeMgt.Codeunit.al` |
| Codeunit | 50140 | EQM Telemetry Mgt. | Internal | `app/src/Telemetry/EQMTelemetryMgt.Codeunit.al` |
| Codeunit | 50141 | EQM Telemetry Subscr. | Internal | `app/src/Telemetry/EQMTelemetrySubscr.Codeunit.al` |
| Codeunit | 50142 | EQM Error Log Mgt. | Internal | `app/src/ErrorLog/EQMErrorLogMgt.Codeunit.al` |
| Codeunit | 50143 | EQM Monitoring Job Runner | Internal | `app/src/ErrorLog/EQMMonitoringJobRunner.Codeunit.al` |
| Codeunit | 50144 | EQM Usage Analytics Mgt. | Internal | `app/src/UsageAnalytics/EQMUsageAnalyticsMgt.Codeunit.al` |
| Codeunit | 50145 | EQM Maintenance Calc. Job | default (Public) | `app/src/Monitoring/EQMMaintenanceCalcJob.Codeunit.al` |
| Codeunit | 50146 | EQM Notification Payload | Internal | `app/src/Notifications/EQMNotificationPayload.Codeunit.al` |
| Codeunit | 50147 | EQM BC Notification Provider | Internal | `app/src/Notifications/EQMBCNotificationProvider.Codeunit.al` |
| Codeunit | 50149 | EQM Demo Data Mgt. | Internal | `app/src/DemoData/EQMDemoDataMgt.Codeunit.al` |
| Query | 50100 | EQM Equipment by Category | Internal | `app/src/Dashboard/EQMEquipmentByCategory.Query.al` |
| Query | 50101 | EQM Equipment by Status | Internal | `app/src/Dashboard/EQMEquipmentByStatus.Query.al` |
| Query | 50102 | EQM Maint. Cost by Category | Internal | `app/src/Dashboard/EQMMaintCostByCategory.Query.al` |
| Query | 50103 | EQM Maint. Cost by Equipment | Internal | `app/src/Dashboard/EQMMaintCostByEquipment.Query.al` |
| Query | 50104 | EQM Open Warranty Alerts | Internal | `app/src/Warranty/EQMOpenWarrantyAlerts.Query.al` |
| Query | 50105 | EQM Assignments by Category | Internal | `app/src/UsageAnalytics/EQMAssignmentsByCategory.Query.al` |
| Enum | 50100 | EQM Equipment Status | default (Public) | `app/src/Equipment/EQMEquipmentStatus.Enum.al` |
| Enum | 50101 | EQM Assignment Status | default (Public) | `app/src/Assignment/EQMAssignmentStatus.Enum.al` |
| Enum | 50102 | EQM Maintenance Type | default (Public) | `app/src/Maintenance/EQMMaintenanceType.Enum.al` |
| Enum | 50103 | EQM Maintenance Status | default (Public) | `app/src/Maintenance/EQMMaintenanceStatus.Enum.al` |
| Enum | 50104 | EQM Warranty Status | default (Public) | `app/src/Equipment/EQMWarrantyStatus.Enum.al` |
| Enum | 50105 | EQM Warranty Alert Interval | default (Public) | `app/src/Warranty/EQMWarrantyAlertInterval.Enum.al` |
| Enum | 50106 | EQM Warranty Alert Status | default (Public) | `app/src/Warranty/EQMWarrantyAlertStatus.Enum.al` |
| Enum | 50107 | EQM Maintenance Log Action | default (Public) | `app/src/Maintenance/EQMMaintenanceLogAction.Enum.al` |
| Enum | 50108 | EQM Attachment Category | default (Public) | `app/src/Attachments/EQMAttachmentCategory.Enum.al` |
| Enum | 50109 | EQM Integration Event Type | default (Public) | `app/src/Integration/EQMIntegrationEventType.Enum.al` |
| Enum | 50110 | EQM Request Status | default (Public) | `app/src/Request/EQMRequestStatus.Enum.al` |
| Enum | 50111 | EQM Audit Event Type | default (Public) | `app/src/AuditTrail/EQMAuditEventType.Enum.al` |
| Enum | 50112 | EQM Feature | Internal | `app/src/Features/EQMFeature.Enum.al` |
| Enum | 50113 | EQM Error Operation | Internal | `app/src/ErrorLog/EQMErrorOperation.Enum.al` |
| Enum | 50114 | EQM Notification Provider | Internal | `app/src/Notifications/EQMNotificationProvider.Enum.al` |
| Enum extension | 50100 | EQM Event Category | default (Public) | `app/src/PowerAutomate/EQMEventCategory.EnumExt.al` |
| Interface | n/a | EQM INotification Provider | Internal | `app/src/Notifications/EQMINotificationProvider.Interface.al` |
| Permission set | 50100 | EQM - Reader | default (Public) | `app/src/Permissions/EQMReader.PermissionSet.al` |
| Permission set | 50101 | EQM - Manager | default (Public) | `app/src/Permissions/EQMManager.PermissionSet.al` |
| Permission set | 50102 | EQM - Administrator | default (Public) | `app/src/Permissions/EQMAdministrator.PermissionSet.al` |
| Permission set | 50104 | EQM - API Consumer | default (Public) | `app/src/Permissions/EQMAPIConsumer.PermissionSet.al` |
| Permission set | 50105 | EQM - Operator | default (Public) | `app/src/Permissions/EQMOperator.PermissionSet.al` |
| Permission set extension | 50103 | EQM D365 BASIC | default (Public) | `app/src/Permissions/EQMD365BASIC.PermissionSetExt.al` |
| Profile | - | EQM EQUIPMENT MANAGER | default (Public) | `app/src/Dashboard/EQMEquipmentManager.Profile.al` |

## Public surface

What a partner extension can reference. After the first AppSource release none of this can be removed, renamed or retyped; obsolete it instead (`ObsoleteState = Pending` with a reason and a tag, see the target profile in [`CLAUDE.md`](../../CLAUDE.md)).

- **Objects with `Access = Public` (17):** tables 50100, 50101, 50102, 50103, 50105, 50106, 50107, 50108, 50109, 50110, 50111 and 50112, and codeunits 50106 (EQM Assignment Mgt.), 50109 (EQM Maintenance-Post), 50119 (EQM Business Events), 50130 (EQM Power Automate Events) and 50132 (EQM Request Approval Mgt.).
- **Objects without an `Access` property (69):** pages, reports, enums, the permission sets, the profile and the extension objects, plus the three job codeunits 50111, 50114 and 50145. They are public by default.
- **API pages:** 50123 to 50126, route `/api/miguelCarvalho/equipment/v1.0/`. See [endpoints](../api/endpoints.md). They are `Extensible = false`.
- **Events:** the published events are listed in [events](../api/events.md). Most publishers are `local` procedures inside public objects; subscribers in other apps can still subscribe to them.
- **Permission sets:** 50100, 50101, 50102, 50104 and 50105, and the extension 50103 of `D365 BASIC`.
- **Enums with `Extensible = true`:** 50100 EQM Equipment Status, 50102 EQM Maintenance Type and 50108 EQM Attachment Category. All other enums set `Extensible = false`.

## Permission sets

| ID | Name | Includes | Purpose |
|---|---|---|---|
| 50100 | EQM - Reader | none | View everything, change nothing. Also holds the execute rights on codeunits that run in user sessions. |
| 50101 | EQM - Manager | EQM - Reader | Daily work. |
| 50102 | EQM - Administrator | EQM - Manager | Setup, categories, deletes. |
| 50104 | EQM - API Consumer | none | Service-to-service access through the API pages (no UI pages). |
| 50105 | EQM - Operator | EQM - Reader | Day-to-day work on existing equipment; sits between Reader and Manager (FR-057). |
| 50103 (extension) | EQM D365 BASIC | extends `D365 BASIC` | Adds `tabledata "EQM Equipment" = r` (indirect) so the employee delete guard works. |

The hierarchy is taken from `IncludedPermissionSets` in `app/src/Permissions`. Every new object goes into the existing sets in the same change. Details and the effective-rights matrix: [FR-036](../features/FR-036-permission-sets.md), [FR-057](../features/FR-057-permission-review.md).

## Test app

`test/app.json`: name `Equipment Management Tests`, version `1.0.0.0`, ID range 50150 to 50199, features `NoImplicitWith` only (no `TranslationFile`), dependencies on `Equipment Management` (minimum version `1.0.0.0`) and `Library Assert` (Microsoft, `29.0.0.0`). `test/.vscode/settings.json` runs CodeCop and UICop only. The test app reaches internal objects of the app through `internalsVisibleTo`. The dependency matrix is in [Dependencies](dependencies.md). How the tests are organised: [testing strategy](testing-strategy.md).

Test object inventory: 44 codeunits in `test/src`, namespace `MiguelCarvalho.EquipmentManagement.Tests`. 38 have `Subtype = Test`, and 6 are helpers (the `... Test Subscr` codeunits and the FR-064 notification provider spy) with no `Subtype`. The test app has no other object type. The list of test procedures per codeunit is in the [test catalogue](testing-strategy.md#test-codeunit-catalogue).

| Type | ID | Name | Access | File |
|---|---|---|---|---|
| Codeunit | 50150 | EQM Equipment Creation Tests | default (Public) | `test/src/EQMEquipmentCreationTests.Codeunit.al` |
| Codeunit | 50151 | EQM Telemetry Tests | default (Public) | `test/src/EQMTelemetryTests.Codeunit.al` |
| Codeunit | 50152 | EQM Telemetry Test Subscr | default (Public) | `test/src/EQMTelemetryTestSubscr.Codeunit.al` |
| Codeunit | 50153 | EQM Translation Tests | default (Public) | `test/src/EQMTranslationTests.Codeunit.al` |
| Codeunit | 50154 | EQM Error Log Tests | default (Public) | `test/src/EQMErrorLogTests.Codeunit.al` |
| Codeunit | 50155 | EQM Error Log Isolation Tests | default (Public) | `test/src/EQMErrorLogIsolationTests.Codeunit.al` |
| Codeunit | 50156 | EQM Assignment Tests | default (Public) | `test/src/EQMAssignmentTests.Codeunit.al` |
| Codeunit | 50157 | EQM Status Change Tests | default (Public) | `test/src/EQMStatusChangeTests.Codeunit.al` |
| Codeunit | 50158 | EQM Process Integration Tests | default (Public) | `test/src/EQMProcessIntegrationTests.Codeunit.al` |
| Codeunit | 50159 | EQM Performance Tests | default (Public) | `test/src/EQMPerformanceTests.Codeunit.al` |
| Codeunit | 50160 | EQM Error Log Test Subscr | default (Public) | `test/src/EQMErrorLogTestSubscr.Codeunit.al` |
| Codeunit | 50161 | EQM Dashboard Tests | default (Public) | `test/src/EQMDashboardTests.Codeunit.al` |
| Codeunit | 50162 | EQM Role Permission Tests | default (Public) | `test/src/EQMRolePermissionTests.Codeunit.al` |
| Codeunit | 50163 | EQM Data Classification Tests | default (Public) | `test/src/EQMDataClassificationTests.Codeunit.al` |
| Codeunit | 50164 | EQM Maintenance Tests | default (Public) | `test/src/EQMMaintenanceTests.Codeunit.al` |
| Codeunit | 50168 | EQM Warranty Tests | default (Public) | `test/src/EQMWarrantyTests.Codeunit.al` |
| Codeunit | 50169 | EQM Usage Analytics Tests | default (Public) | `test/src/EQMUsageAnalyticsTests.Codeunit.al` |
| Codeunit | 50171 | EQM Notification Tests | default (Public) | `test/src/EQMNotificationTests.Codeunit.al` |
| Codeunit | 50172 | EQM Background Process. Tests | default (Public) | `test/src/EQMBackgroundProcessTests.Codeunit.al` |
| Codeunit | 50174 | EQM Notif. Provider Spy | Internal | `test/src/EQMNotifProviderSpy.Codeunit.al` |
| Codeunit | 50176 | EQM Demo Data Tests | default (Public) | `test/src/EQMDemoDataTests.Codeunit.al` |
| Codeunit | 50177 | EQM Upgrade Tests | default (Public) | `test/src/EQMUpgradeTests.Codeunit.al` |
| Codeunit | 50178 | EQM Equipment Picture Tests | default (Public) | `test/src/EQMEquipmentPictureTests.Codeunit.al` |
| Codeunit | 50179 | EQM Doc. Attachment Tests | default (Public) | `test/src/EQMDocAttachmentTests.Codeunit.al` |
| Codeunit | 50180 | EQM Equipment API Tests | default (Public) | `test/src/EQMEquipmentAPITests.Codeunit.al` |
| Codeunit | 50181 | EQM Category API Tests | default (Public) | `test/src/EQMCategoryAPITests.Codeunit.al` |
| Codeunit | 50182 | EQM Assignment API Tests | default (Public) | `test/src/EQMAssignmentAPITests.Codeunit.al` |
| Codeunit | 50183 | EQM Equipment Note Tests | default (Public) | `test/src/EQMEquipmentNoteTests.Codeunit.al` |
| Codeunit | 50184 | EQM Business Events Tests | default (Public) | `test/src/EQMBusinessEventsTests.Codeunit.al` |
| Codeunit | 50185 | EQM Business Event Test Subscr | default (Public) | `test/src/EQMBusinessEventTestSubscr.Codeunit.al` |
| Codeunit | 50186 | EQM Integration Event Tests | default (Public) | `test/src/EQMIntegrationEventTests.Codeunit.al` |
| Codeunit | 50187 | EQM Power Automate Tests | default (Public) | `test/src/EQMPowerAutomateTests.Codeunit.al` |
| Codeunit | 50188 | EQM Equipment Request Tests | default (Public) | `test/src/EQMEquipmentRequestTests.Codeunit.al` |
| Codeunit | 50189 | EQM Request Approval Tests | default (Public) | `test/src/EQMRequestApprovalTests.Codeunit.al` |
| Codeunit | 50190 | EQM Request Appr. Test Subscr | default (Public) | `test/src/EQMRequestApprTestSubscr.Codeunit.al` |
| Codeunit | 50191 | EQM Change Log Setup Tests | default (Public) | `test/src/EQMChangeLogSetupTests.Codeunit.al` |
| Codeunit | 50192 | EQM Audit Trail Tests | default (Public) | `test/src/EQMAuditTrailTests.Codeunit.al` |
| Codeunit | 50193 | EQM Audit Trail Test Subscr | default (Public) | `test/src/EQMAuditTrailTestSubscr.Codeunit.al` |
| Codeunit | 50194 | EQM Equipment FactBox Tests | default (Public) | `test/src/EQMEquipmentFactBoxTests.Codeunit.al` |
| Codeunit | 50195 | EQM Equipment Register Tests | default (Public) | `test/src/EQMEquipmentRegisterTests.Codeunit.al` |
| Codeunit | 50196 | EQM Asset Utilization Tests | default (Public) | `test/src/EQMAssetUtilizationTests.Codeunit.al` |
| Codeunit | 50197 | EQM Maint. Cost Analysis Tests | default (Public) | `test/src/EQMMaintCostAnalysisTests.Codeunit.al` |
| Codeunit | 50198 | EQM Feature Mgt. Tests | default (Public) | `test/src/EQMFeatureMgtTests.Codeunit.al` |
| Codeunit | 50199 | EQM Application Setup Tests | default (Public) | `test/src/EQMApplicationSetupTests.Codeunit.al` |

## Maintaining this page

Regenerate the two inventory tables whenever an FR adds, renames or removes an object, and update the public-surface counts. The tables are produced with the same object pattern as `OBJECT_RE` in `.github/scripts/repo_checks.py`, plus `profile`. A permanent check in `repo_checks.py` is a possible later phase (see [`docs/TODO.md`](../TODO.md), "FR-060 checks").

## Related

- [Architecture overview](README.md)
- [Testing strategy](testing-strategy.md)
- Feature docs: [FR-036](../features/FR-036-permission-sets.md), [FR-057](../features/FR-057-permission-review.md), [FR-055](../features/FR-055-multi-language-support.md), [FR-058](../features/FR-058-data-classification.md), [FR-061](../features/FR-061-code-quality-compliance.md), [FR-064](../features/FR-064-feature-interfaces.md)
- [CLAUDE.md](../../CLAUDE.md)
- Microsoft Learn: [Access modifiers in AL](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-using-access-modifiers), [app.json files](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-json-files)
