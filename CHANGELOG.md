# Changelog
Newest first. Grouped by Added / Changed / Fixed / Obsolete.

## NFR-004 Automation (version stays 29.0.0.0, no bump)
### Added
- Documentation only: docs/features/NFR-004-automation.md traces the requirement (monitoring fully automated through Job Queue) to FR-018 (codeunits 50111, 50114, 50115, 50104, page 50103) and lists the open gaps; help article docs/help/NFR-004-automation.md; section "NFR-004 sandbox checks" in docs/TODO.md.
### Changed
- None.
### Fixed
- None.
### Obsolete
- None.

Release notes: The daily monitoring of warranties and overdue maintenance runs through Business Central job queue entries that the app creates by itself. This version adds documentation only; there is no change in behavior.

Note: no AL change, no new object, no upgrade code, no permission change, no tests. Met in code, not verified in a sandbox. Open gaps (not fixed): existing entries are never repaired, companies skipped at multi-company install need the action, no notification job.

## FR-022 Warranty Dashboard (version stays 29.0.0.0, no bump)
### Added
- Table 50104 "EQM Equipment Cue": field 33 "Active Warranties" (FlowField) with FlowFilter 42, field 34 "Warranties Expiring 90 Days" (FlowField) with FlowFilter 43. Nothing is stored.
- Page 50106: tiles Active Warranties and Warranties Expiring in 90 Days at the start of the Warranty group, both with drill-down to the Equipment List. Shown on the dashboard and the Role Center.
- Active Warranties: Warranty End Date today or later (includes warranties expiring soon). Warranties Expiring in 90 Days: end date from today to today + 90 (includes the 30-day tile). Lost and Disposed equipment and blank end dates are not counted; start date is ignored; real date, not Work Date. The 90 days come from the 90 Days warranty alert interval (FR-016).
- Help article docs/help/FR-022-warranty-dashboard.md.
### Changed
- Captions of the existing tiles: "Warranty Expiring Soon" is now "Warranties Expiring in 30 Days", "Warranty Expired" is now "Expired Warranties" (field names unchanged; counting unchanged).
- Codeunit 50107 `SetWarrantyCueFilters` also sets the two new filters (signature unchanged). AboutText and search terms of the Equipment Dashboard.
### Fixed
- None.
### Obsolete
- None.

Release notes: The equipment dashboard and the Role Center now show four warranty numbers: Active Warranties, Warranties Expiring in 90 Days, Warranties Expiring in 30 Days and Expired Warranties. Choose a number to see the equipment behind it. The two existing warranty tiles were renamed to match; they count as before.

Note: no new objects, no stored data, no upgrade code, no new event, no permission change. Review: APPROVE. CodeCop and UICop compile clean. Automated tests are deferred (test ID 50176 reserved); platform checks V1, V4 and V5 and sandbox checks WD-SB1 to WD-SB8 are not run.

## FR-021 Maintenance Dashboard (version stays 29.0.0.0, no bump)
### Added
- Table 50104 "EQM Equipment Cue": field 22 "Total Maintenance Cost YTD" (FlowField) with FlowFilter 23, field 52 "Planned Maintenance This Month" (FlowField) with FlowFilter 53. Nothing is stored.
- Page 50106: tile Planned Maintenance This Month (group Planned Maintenance, before Overdue Maintenance Equipment) and tile Total Maintenance Cost YTD (group Maintenance Costs, between Total and Average), both with drill-down. Shown on the dashboard and the Role Center.
- Planned this month: Next Maintenance Date from the first to the last day of the current month, Lost and Disposed excluded; overdue dates earlier in the month are included, so the overdue tile can count the same equipment. Cost YTD: posted maintenance with Maintenance Date from 1 January to today. Both use the real date, not Work Date.
- Internal procedure codeunit 50107 `SetMaintenanceCostCueFilters`.
- Help article docs/help/FR-021-maintenance-dashboard.md.
### Changed
- Codeunit 50107 `SetPlannedMaintenanceCueFilters` also sets the month filter. AboutText and search terms of the Equipment Dashboard.
### Fixed
- None.
### Obsolete
- None.

Release notes: The equipment dashboard and the Role Center have two new tiles. Planned Maintenance This Month counts the equipment whose next maintenance date falls in the current month, and Total Maintenance Cost YTD shows the cost of posted maintenance from 1 January to today. Both open the records behind the number.

Note: no new objects in the app, no stored data, no upgrade code, no new event, no permission change. Review: APPROVE WITH COMMENTS, no blockers. CodeCop and UICop compile clean (0 errors, 0 warnings). Automated tests are deferred (test ID 50175 reserved); platform checks V2 and V3 and sandbox checks MD-SB1 to MD-SB8 are open.

## FR-020 Overdue Maintenance Monitoring (version stays 29.0.0.0, no bump)
### Added
- Equipment is overdue when Next Maintenance Date is before today (real date, not Work Date); due today is not overdue. Blank dates and Lost / Disposed equipment are never overdue. Nothing is stored.
- Next Maintenance Date is shown in red on the Equipment List, the Equipment Card (refreshed on validate of the plan fields and status) and the Maintenance FactBox.
- Table 50104 "EQM Equipment Cue": field 50 "Overdue Maintenance Equipment" (FlowField) and field 51 "Overdue Maintenance Filter" (FlowFilter). Page 50106: cue group Planned Maintenance with the tile (red above 0, green at 0), drill-down to the Equipment List.
- Internal procedures: table 50100 `IsPlannedMaintenanceOverdue`, `GetNextMaintenanceDateStyle`; codeunit 50107 `SetPlannedMaintenanceCueFilters`, `GetOverdueMaintenanceCueStyle`.
- Help article docs/help/FR-020-overdue-maintenance-monitoring.md.
### Changed
- ToolTip of Next Maintenance Date; AboutText of the Equipment List and the Equipment Dashboard; search terms of the dashboard ('overdue maintenance', 'maintenance due').
### Fixed
- None.
### Obsolete
- None.

Release notes: Equipment whose next maintenance date is before today is now highlighted. The next maintenance date is shown in red on the Equipment list, the Equipment Card and the Maintenance FactBox, and the new tile Overdue Maintenance Equipment on the dashboard and Role Center counts the overdue equipment and opens the list of it. Lost and disposed equipment and equipment without a next maintenance date are not counted.

Note: no new objects, no stored data, no upgrade code, no new event, no permission change. CodeCop and UICop compile clean. Automated tests are deferred (test ID 50174 reserved); sandbox checks OM-SB1 to OM-SB9 are not run.

## FR-019 Planned Maintenance (version stays 29.0.0.0, no bump)
### Added
- Table 50100 "EQM Equipment": stored fields 21 "Last Maintenance Date", 22 "Next Maintenance Date" (not editable, calculated) and 23 "Maintenance Frequency (Months)" (0 to 120, 0 shown blank).
- Next Maintenance Date = Last Maintenance Date + frequency in months; recalculated on validation, insert and modify. Last Maintenance Date cannot be later than today.
- Posting a Preventive maintenance record moves Last Maintenance Date forward (never backwards); other types do not change it.
- Published events on table 50100: `OnBeforeCalcNextMaintenanceDate` (with IsHandled) and `OnBeforeUpdateLastMaintenanceFromPosting`.
- Equipment Card group Planned Maintenance; Equipment List columns Next Maintenance Date (visible), Last Maintenance Date and Maintenance Frequency (Months) (hidden); Next Maintenance Date in the Maintenance FactBox.
- Help article docs/help/FR-019-planned-maintenance.md.
### Changed
- Maintenance FactBox captions 'Last Maintenance Date' / 'Last Maintenance Type' renamed to 'Latest Record Date' / 'Latest Record Type' (same calculation).
- Codeunit 50109 "EQM Maintenance-Post": `CompleteEquipmentMaintenance` also updates the planned maintenance dates. `CheckEquipmentConsistency` rejects a future Last Maintenance Date. Teaching tips of the Equipment Card and List updated.
### Fixed
- None.
### Obsolete
- None.

Release notes: On the Equipment Card you can now enter how often equipment must be maintained (in months) and when it was last maintained, and the app calculates the next maintenance date. Posting a Preventive maintenance record moves the last maintenance date forward automatically. The Equipment list shows the next maintenance date, so you can filter for equipment that is due in a period. In the Maintenance FactBox, the fields for the most recent record are renamed Latest Record Date and Latest Record Type.

Note: no upgrade code, no new objects, no permission change; existing equipment has blank dates. Fields 21 to 23 and the two events become permanent at release. Code and UICop compile clean; AppSourceCop shows only the 8 project-level app.json/config errors that also exist on main. Automated tests are deferred (test ID 50173 reserved); platform checks V1 to V4 and sandbox checks PM-SB1 to PM-SB9 are not run.

## FR-018 Automated Background Processing (version stays 29.0.0.0, no bump)
### Added
- Codeunit 50114 "EQM Maintenance Monitor Job" (public, run from a job queue entry): daily overdue maintenance check, logs a count to telemetry, changes no data.
- Codeunit 50115 "EQM Monitoring Job Mgt." (internal): creates job queue category `EQM` and one daily entry (`<1D>`, 06:00, 3 attempts) for codeunits 50111 and 50114 when none exists; never changes existing entries. Skips with telemetry when a write transaction is open or tasks cannot be created.
- Entries are created on install, when the setup is first created in a company, and by the new Equipment Setup action Schedule Monitoring Jobs.
- Equipment Setup: group Background Monitoring (status of both jobs), actions Schedule Monitoring Jobs and Monitoring Job Queue Entries, teaching tip text and search terms.
- Codeunit 50108 internal procedure `CheckOverdueMaintenance`. Telemetry EQM0002 (overdue check), EQM0003 (entries ensured), EQM0004 (entries not created).
- Permissions: EQM - Reader execute on codeunits 50114 and 50115; EQM - Administrator indirect `rim` on Job Queue Entry.
- Help article docs/help/FR-018-automated-background-processing.md.
### Changed
- `OnInstallAppPerCompany` (codeunit 50104) and `OnOpenPage` of Equipment Setup schedule the monitoring jobs before writing default data.
### Fixed
- None.
### Obsolete
- None.

Release notes: The app now creates two daily job queue entries by itself, one that creates warranty alerts and one that checks overdue maintenance. Equipment Setup shows the status of both jobs, and the new action Schedule Monitoring Jobs creates missing entries without changing existing ones.

Note: no upgrade code, no published events. Run-on flags and rerun delay are left to the standard defaults. Codeunit ID 50114, category `EQM` and telemetry IDs become permanent at release. Automated tests are deferred (test ID 50172 reserved); sandbox checks BG-SB1 to BG-SB9 are not run, build result and review verdict not recorded here.

## FR-017 Equipment Notifications (version stays 29.0.0.0, no bump)
### Added
- Codeunit 50112 "EQM Notification Mgt." (internal): warranty expiring, overdue maintenance and returned from maintenance notifications with actions and Don't show again.
- Codeunit 50113 "EQM Notification Subscribers" (internal): subscribes to page "My Notifications" `OnInitializingNotificationWithDefaultState` and registers the three kinds (enabled by default).
- Codeunit 50108 internal procedures for overdue maintenance (open more than 14 days after the Maintenance Date); codeunit 50110 internal procedures `HasOpenAlert`, `CountOpenAlerts`, `ShowOpenAlerts`.
- Table 50105 key `StatusDate` (Status, Maintenance Date).
- Notifications on the Equipment Card, the Maintenance Record Card, after posting maintenance, and from the cue part on the Equipment Manager Role Center and the Equipment Dashboard.
- Permissions: EQM - Reader execute on codeunits 50112 and 50113.
- Help article docs/help/FR-017-equipment-notifications.md.
### Changed
- `PostWithConfirmation` (codeunit 50108) shows a notification after posting when the equipment is back from maintenance. Confirm text and return value unchanged.
### Fixed
- None.
### Obsolete
- None.

Release notes: The app now shows a notification when a warranty is about to end (while its warranty alert is open), when a maintenance record has been open for more than 14 days without being posted, and when posting maintenance makes equipment available again. Notifications appear on the Equipment Card, the Maintenance Record Card, the Equipment Manager Role Center and the dashboard, each with an action that opens the matching records. You can switch each kind off with Don't show again or in My Notifications.

Note: no upgrade code, no published events; one standard event subscribed (My Notifications). The three notification GUIDs become permanent at release. Known limitations: shown only when a page is opened; warranty notifications need FR-016 alerts; fixed 14-day overdue limit; no tile or list notifications. Automated tests are deferred (test ID 50171 reserved); sandbox checks NT-SB1 to NT-SB12 are not run (My Notifications registration, enabled-by-default behavior, action handlers in the internal codeunit, Reader permissions, cue-part notifications on the Role Center). Build result and review verdict not recorded by the documenter. See docs/features/FR-017-equipment-notifications.md.

## FR-016 Warranty Alerts (version stays 29.0.0.0, no bump)
### Added
- Enums 50105 "EQM Warranty Alert Interval" (30, 60, 90 Days) and 50106 "EQM Warranty Alert Status" (Open, Acknowledged, Cancelled); both not extensible.
- Table 50107 "EQM Warranty Alert" (public, stored): one alert per equipment, warranty end date and interval.
- Page 50120 "EQM Warranty Alerts": list with actions Acknowledge, Generate Alerts and Equipment, and views Open, Acknowledged, Cancelled.
- Codeunit 50110 "EQM Warranty Alert Mgt." (internal) and codeunit 50111 "EQM Warranty Alert Job" (public, run from a job queue entry). Telemetry signal EQM0001 per run (counts only).
- Table 50100 internal procedure `GetWarrantyDaysRemaining`; table 50104 FlowField 32 "Open Warranty Alerts"; third tile in the Warranty cue group; action "Warranty Alerts" on the Equipment Card and the Equipment Manager Role Center.
- Permissions: EQM - Reader R on the alert table plus execute on the new objects; EQM - Manager RIM on the alert table.
- Help article docs/help/FR-016-warranty-alerts.md.
### Changed
- Teaching tip and search terms of the Equipment Dashboard.
### Fixed
- None.
### Obsolete
- None.

Release notes: The app now creates a warranty alert 90, 60 and 30 days before a warranty ends, so you can renew it, plan a replacement or raise a claim in time. Open the new Warranty Alerts list from the Equipment Manager Role Center or the Equipment Card, see the number of open alerts in the new Open Warranty Alerts tile on the dashboard, and acknowledge alerts when you have acted on them. Alerts are created every day by a job queue entry that an administrator sets up, or when a manager chooses Generate Alerts. If the warranty end date changes, the open alerts are cancelled and new ones are created for the new date.

Note: no upgrade code, no events. The job queue entry is not created by the app; see the help article. Known limitations: alerts appear only when a run happens; fixed 90/60/30 intervals; no notification or email; alerts are never deleted. Automated tests are deferred (Q12; test ID 50170 reserved); sandbox checks WA-SB1 to WA-SB12 are not run. Build: no source-file diagnostics from the compiler, CodeCop, UICop and AppSourceCop; only the known app.json diagnostics AS0051, AS0052, AS0054, AS0084 and AS0092 remain. Review verdict not recorded by the documenter. See docs/features/FR-016-warranty-alerts.md.

## FR-015 Warranty Monitoring (version stays 29.0.0.0, no bump)
### Added
- Enum 50104 "EQM Warranty Status" (blank, Active, Expiring Soon, Expired; not extensible). Calculated from "Warranty End Date" and today's date, never stored.
- Table 50100 internal procedures `GetWarrantyExpiringSoonDays` (30), `CalcWarrantyStatus`, `GetWarrantyStatus`, `GetWarrantyStatusStyle`.
- Table 50104 FlowFields "Warranty Expiring Soon" and "Warranty Expired" (Lost and Disposed excluded) and two FlowFilters; codeunit 50107 internal `SetWarrantyCueFilters`.
- Cue group "Warranty" with two tiles on page 50106 (dashboard and Role Center), drilling down to the Equipment List.
- Warranty Status on the Equipment Card (after Warranty End Date) and as a visible column on the Equipment list, styled green / yellow / red.
- Help article docs/help/FR-015-warranty-monitoring.md.
### Changed
- ToolTip of "Warranty End Date"; teaching tips of the Equipment list and the dashboard; dashboard search terms.
### Fixed
- None.
### Obsolete
- None.

Release notes: The Equipment Card and Equipment list now show a Warranty Status: Active, Expiring Soon (the warranty ends within 30 days) or Expired. It is calculated automatically from the Warranty End Date and is blank when no end date is filled in. The dashboard and the Equipment Manager Role Center have two new tiles, Warranty Expiring Soon and Warranty Expired, which open the matching equipment. The tiles do not count lost and disposed equipment.

Note: no stored field, no permission set change, no upgrade code, no events. Known limitation: Warranty Status cannot be filtered, sorted or exported; "30 days" is fixed and also written in several tooltips. Automated tests are deferred (Q10; test ID 50169 reserved); sandbox checks WM-SB1 to WM-SB10 are not run. Review: APPROVE WITH COMMENTS; build without AL errors or warnings. See docs/features/FR-015-warranty-monitoring.md.

## FR-014 Warranty Information (version stays 29.0.0.0, no bump)
### Added
- Table 50100 fields 17 "Warranty Start Date" (Date), 18 "Warranty End Date" (Date), 19 "Warranty Provider" (Text[100]), 20 "Warranty Reference No." (Text[50]); all optional, stored.
- Rule: when both warranty dates are filled in, the end date must be later than the start date (equal dates rejected). Checked on field validation and in `CheckEquipmentConsistency` (insert and modify).
- Event `OnBeforeCheckWarrantyDates(Equipment, var IsHandled)` (local integration event on table 50100); IsHandled skips the standard rule.
- Equipment Card: group Warranty after Purchase (End Date and Provider shown when collapsed). Equipment list: four warranty columns, hidden by default.
- Help article docs/help/FR-014-warranty-information.md.
### Changed
- Equipment Card teaching tip mentions purchase and warranty information.
### Fixed
- None.
### Obsolete
- None.

Release notes: You can now record the warranty of each piece of equipment: start date, end date, provider and reference number. The fields are in the new Warranty section of the Equipment Card and can be shown as columns on the Equipment list, for example to filter on the warranty end date. All fields are optional. When you fill in both dates, the end date must be later than the start date.

Note: no new objects, no permission set change, no upgrade code. Automated tests are deferred (Q8; test ID 50168 reserved); sandbox checks WS-SB1 to WS-SB8 are not run. Build result and review verdict: not recorded by the documenter. See docs/features/FR-014-warranty-information.md.

## FR-013 Maintenance Cost Tracking (version stays 29.0.0.0, no bump)
### Added
- Table 50100 fields 13 "Date Filter" (FlowFilter), 14 "Total Maintenance Cost", 15 "No. of Posted Maintenances", 16 "Average Maintenance Cost" (FlowFields over table 50106); internal `GetMaintenanceCostPercentage`, `GetMaintenanceCostStyle`.
- Table 50104 FlowFields "Total Maintenance Cost" and "Average Maintenance Cost"; cue group "Maintenance Costs" on page 50106.
- Internal queries 50102 "EQM Maint. Cost by Category" and 50103 "EQM Maint. Cost by Equipment".
- Pages 50118 "EQM Category Cost Chart" and 50119 "EQM Equipment Cost Chart" (top 10), on the dashboard and the Equipment Manager Role Center. Role Center Embedding action Maintenance History.
- Codeunit 50107: internal `GetMaintenanceCostByCategory`, `GetTopMaintenanceCostByEquipment`, `GetTopEquipmentLimit`, `ShowMaintenanceHistory`.
- Equipment list: Total Maintenance Cost column; No. of Posted Maintenances, Average Maintenance Cost and Maintenance Cost % (red at 100 % or more) hidden by default. Maintenance FactBox: Average Maintenance Cost and Maintenance Cost %.
- EQM - Reader: X on the two queries and two chart pages.
- Help article docs/help/FR-013-maintenance-cost-tracking.md.
### Changed
- **Behavior change:** the Maintenance FactBox "Total Maintenance Cost" now sums posted maintenance only (it summed open and posted records). Record counts still include open records. Docs of FR-007, FR-009, FR-010 and FR-011 updated.
- Dashboard teaching tip, Refresh ToolTip and search terms; Equipment list teaching tip.
### Fixed
- None.
### Obsolete
- None. Codeunit 50108 internal `GetTotalMaintenanceCost` removed (no other caller; nothing released).

Release notes: Maintenance costs are now tracked. The Equipment list shows the total posted maintenance cost per equipment, with optional columns for the number of maintenances, the average cost and the cost as a percentage of the purchase cost (red at 100 % or more). Use Filter totals by > Date Filter to see the cost of a period. The dashboard and the Equipment Manager Role Center show total and average maintenance cost tiles, a chart of cost by category and a chart of the ten most expensive pieces of equipment. The total in the Maintenance pane now counts posted maintenance only.

Note: source builds with 0 errors and 0 warnings (CodeCop, UICop, AppSourceCop); remaining diagnostics are app.json manifest items. Review APPROVE WITH CHANGES, no blockers. No automated tests (deferred, Q8; test ID 50167 reserved); sandbox checks CS-SB1 to CS-SB10 not run. See docs/features/FR-013-maintenance-cost-tracking.md.

## FR-012 Equipment Maintenance Status (version stays 29.0.0.0, no bump)
### Added
- Table 50100: internal `StartMaintenance` and `CompleteMaintenance`; events `OnBeforeStartMaintenance` and `OnBeforeCompleteMaintenance` (local; the latter with IsHandled).
- Codeunit 50108: internal `HasOpenMaintenance`, `CountOpenMaintenanceRecords`, `ShowOpenMaintenanceRecords`. Key `EquipmentStatus` on table 50105.
- Maintenance FactBox: field Open Maintenance Records with drill-down.
- Help article docs/help/FR-012-equipment-maintenance-status.md.
### Changed
- Registering maintenance sets the equipment to In Maintenance; assigned equipment asks for confirmation and is returned from the employee (assignment closed).
- Posting the last open maintenance record sets In Maintenance equipment to Available (codeunit 50109).
- Equipment with an open maintenance record cannot be assigned, and In Maintenance equipment cannot be set to Available by hand while a record is open (Lost and Disposed stay allowed). IsHandled of `OnBeforeCheckStatusTransitionAllowed` cannot bypass this.
- Equipment Card: Assign to Employee is unavailable while maintenance is open. ToolTips, AboutTexts and the post confirmation text updated.
- Reverses FR-010 "registering does not change the status"; FR-011 posting may now set the status. Docs of FR-003, FR-004, FR-005, FR-010 and FR-011 corrected (FR-003 help wrongly said In Maintenance equipment can be assigned directly).
### Fixed
- None.
### Obsolete
- None.

Release notes: Registering maintenance now sets the equipment to In Maintenance, and equipment with open maintenance cannot be assigned. Posting the last open maintenance record sets the equipment back to Available. For assigned equipment you confirm first; the equipment is then returned from the employee. The Maintenance FactBox shows the number of open records.

Note: built with alc and the analyzers, no new warnings. Review CHANGES resolved. No automated tests (deferred, Q9; test ID 50166 reserved); sandbox checks MS-SB0 to MS-SB10 not run. Accepted: the confirmation for assigned equipment is asked while the number series line and the equipment row are locked, so other users may wait. See docs/features/FR-012-equipment-maintenance-status.md.

## FR-011 Equipment Maintenance History (version stays 29.0.0.0, no bump)
### Added
- Enum 50103 "EQM Maintenance Status" (Open, Posted; not extensible). Field 11 Status on table 50105.
- Table 50106 "EQM Maintenance History Entry" (read-only; no modify, rename or delete; insert only through posting).
- Codeunit 50109 "EQM Maintenance-Post" (public): posts a record, freezes it and writes the history entry. Integration events `OnBeforePostMaintenanceRecord`, `OnBeforeInsertMaintenanceHistoryEntry`, `OnAfterPostMaintenanceRecord` (local).
- Pages 50116 'Maintenance History' (Equipment Card part) and 50117 'Maintenance History' (list, History in Tell Me, views per type).
- Post action (F9) and History Entry action on the maintenance list and card; Status column; views Open and Posted on the list.
- Equipment Card: Maintenance History part and action.
- EQM - Reader: R on table 50106, X on the new table, pages and codeunit. EQM - Manager: indirect insert on table 50106.
- Help article docs/help/FR-011-maintenance-history.md.
### Changed
- A maintenance record can be corrected only while Open. A posted record cannot be changed by any role. A record cannot be inserted as Posted.
- Internal: `PostWithConfirmation` in codeunit 50108, `GetStatusStyle` in table 50105.
### Fixed
- None.
### Obsolete
- None.

Release notes: Maintenance records now have a status. Choose Post (F9) when a record is final: it is locked and copied to a read-only maintenance history that cannot be changed or deleted. The history is shown on the Equipment Card and in a new Maintenance History list, with date, type, vendor, cost and description. The Equipment Maintenance list has a Status column and views for open and posted records.

Note: build clean under CodeCop and UICop (0 errors, 0 warnings). No automated tests (deferred, Q8; test ID 50165 reserved); sandbox checks HS-SB1 to HS-SB12 not run, including equipment rename (R2). See docs/features/FR-011-maintenance-history.md.

## FR-010 Maintenance Registration (version stays 29.0.0.0, no bump)
### Added
- Table 50105 "EQM Maintenance Record", enum 50102 "EQM Maintenance Type" (Preventive, Corrective, Inspection, Upgrade, extensible), codeunit 50108 "EQM Maintenance Mgt." (internal).
- Pages 50113 'Equipment Maintenance' (list, views per type), 50114 'Maintenance Record' (card), 50115 'Maintenance' (FactBox).
- Field "Maintenance Nos." (field 3) on Equipment Setup; default data creates number series EQMAINT (MNT00001).
- Equipment Card: action Register Maintenance, action Maintenance, Maintenance FactBox. Equipment List: action Maintenance, Maintenance FactBox. Equipment Manager Role Center: Maintenance and Maintenance Record actions.
- Integration event `OnAfterCheckMaintenanceConsistency` (local) on table 50105.
- EQM - Reader: R on the new table, X on the new table, pages and codeunit. EQM - Manager: RIM on maintenance records.
- Help article docs/help/FR-010-maintenance-registration.md.
### Changed
- Equipment cannot be deleted when it has maintenance records.
- `EQM Default Data` creates both number series through the local `EnsureNoSeries`.
### Fixed
- None.
### Obsolete
- None.

Release notes: You can now register maintenance on equipment: date, type (preventive, corrective, inspection, upgrade), vendor, cost and who did the work. Choose Register Maintenance on the equipment card, or open the Equipment Maintenance list. A new Maintenance FactBox shows the number of records, the last maintenance and the total cost. Maintenance records cannot be deleted. In companies that already use the app, an administrator must choose Maintenance Nos. in Equipment Setup.

Note: build clean under CodeCop and UICop. No automated tests (deferred, Q10; test ID 50164 reserved); sandbox checks MT-SB0 to MT-SB11 not run. Register Maintenance uses image ServiceLedger instead of the planned Maintenance (AL0482). Existing companies must set Maintenance Nos. in Equipment Setup. See docs/features/FR-010-maintenance-registration.md.

## NFR-003 Usability (version stays 29.0.0.0, no bump)
### Added
- Page 50111 "EQM Equipment FactBox" ('Assignment Details') on the Equipment List and Card: status, employee (name, job title, company email), assigned since/by, number of assignments, last assignment closed.
- Page 50112 "EQM Assigned Equipment FactBox" ('Assigned Equipment') on the Employee Card, shown only to users who can read equipment.
- Notes (visible) and Links (hidden by default) on the Equipment List and Card.
- Ctrl+F7 for Assignments on the Equipment List and Card.
- Teaching tips on Equipment Categories and Equipment Assignments; search terms on the Equipment List, Categories, Setup and Assignments.
- Three internal procedures in codeunit 50106: `CountAssignments`, `GetLastClosedAssignment`, `ShowAssignments`.
- EQM - Reader: X on pages 50111 and 50112.
- Help article docs/help/NFR-003-usability.md.
### Changed
- Actions grouped on all pages (Process / Report / Equipment or Navigate); Dashboard moved to Reports on the Equipment List; Categories and Setup no longer promoted on the list (under Related > Setup); Setup action caption is now 'Equipment Setup'.
- Equipment Assignments is listed under History in Tell Me (was Lists).
- Equipment Card: Description, Category Code and Assigned Employee Name have `Importance = Promoted`.
- Action ToolTips are imperative ("Open ...", "Assign ...").
- Employee Card: equipment actions in a group 'Equipment', Equipment Assignments uses the History image.
- Equipment Manager Role Center no longer lists Categories twice.
### Fixed
- FR-001 help sentence about reassigning: equipment must be returned first. Stale Employee Card action paths in the FR-004 to FR-007 help.
### Obsolete
- None.

Release notes: Equipment actions are now grouped like other Business Central pages: Assignments under Equipment (Ctrl+F7), Categories and Setup under Related, Dashboard under Reports. New FactBoxes show who has the equipment, since when and how often it was assigned, and the equipment assigned to an employee on the Employee Card. Equipment pages also have Notes and Links. The Equipment Manager home page no longer lists Categories twice.

Note: built with no warnings (reported by the user); review APPROVE WITH CHANGES (applied). No automated tests (deferred, Q1); sandbox checks UX-SB1 to UX-SB12 not run; risk R1 (ReadPermission() vs the indirect D365 BASIC read on the Employee Card FactBox) unverified. No schema change, events or upgrade logic. See docs/features/NFR-003-usability.md.

## NFR-002 Role-based access (version stays 29.0.0.0, no bump)
Version note: nothing has been released; the version stays 29.0.0.0 (confirmed by the user 2026-11-04). The earlier "29.1.0.0" heading for FR-002 was renamed to match.
### Added
- Help article docs/help/NFR-002-role-based-access.md.
- Equipment Setup and Equipment Categories open read-only for users without write permission.
- Error `SetupMissingErr` when a user without write permission opens Equipment Setup in a company with no setup record.
### Changed
- Permission sets renamed and re-captioned (object IDs unchanged): EQM - Read -> EQM - Reader ('Equipment Reader'), EQM - Edit -> EQM - Manager ('Equipment Manager'), EQM - Admin -> EQM - Administrator ('Equipment Administrator').
- Reader: read only; no longer has indirect insert on categories or insert/modify on setup.
- Manager: no longer deletes equipment (RIM).
- Administrator: gains delete on equipment and indirect insert/read on No. Series and No. Series Line.
- Employee names on the equipment list, card, Equipment Assignments and the history part are blank instead of raising an error when the user has no Employee read permission.
### Fixed
- TODO items "Setup permissions" (Reader too permissive) and "Assigned Employee Name" (Employee read), addressed in code, not yet verified in a sandbox.
### Obsolete
- None.

Release notes: The app now has three clear roles. Equipment Reader can view everything but change nothing, Equipment Manager can also create and change equipment and assign and return it, and Equipment Administrator can also delete equipment and maintain categories and setup. The permission sets were renamed (Equipment Reader, Equipment Manager, Equipment Administrator): in test environments, assign the new sets to users again. All users still need the standard D365 BASIC set.

Note: built with no warnings; review APPROVE WITH CHANGES (applied). No automated tests (deferred, Q7); sandbox checks SB0-SB12 not run. No schema change, events or upgrade logic. See docs/features/NFR-002-role-based-access.md.

## FR-009 Dashboard and KPIs (version stays 29.0.0.0, no bump)
### Added
- Equipment Dashboard (page 50109): six KPI tiles (Total, Available, Assigned, In Maintenance, Lost, Disposed equipment), chart Equipment by Category (column) and chart Equipment by Status (pie). Tiles and chart data points open the Equipment list filtered to the equipment behind the number.
- New role **Equipment Manager** (profile "EQM EQUIPMENT MANAGER", Role Center page 50110 with the dashboard, navigation and setup shortcuts). Choose it in My Settings (Role field) or have an administrator assign it in Profiles (Roles). It is not assigned automatically.
- New objects: table 50104 "EQM Equipment Cue" (temporary), queries 50100 and 50101, codeunit 50107 "EQM Dashboard Mgt." (internal), pages 50106 to 50110.
- Equipment List: action Dashboard.
- EQM - Read: execute permission on the new table, queries, pages and codeunit.
### Changed
- None.
### Fixed
- None.
### Obsolete
- None.

Release notes: New Equipment Dashboard with six equipment tiles and charts by category and by status. Choose a tile or chart segment to see the equipment behind it. The new Equipment Manager role shows the dashboard as your home page: choose it in My Settings. Other users open the dashboard from Tell Me or the Dashboard action on the Equipment list.

Note: build clean for FR-009 files; review APPROVE WITH CHANGES (applied). No automated tests (deferred, Q6); not run in a sandbox (chart drill-down payload key, Count FlowFields on the temporary table, chart rendering, Role Center/profile, D365 BASIC requirement for charts are open). Known edge case: equipment with a blank category shows as an unlabeled column. No schema change, events or upgrade logic. See docs/features/FR-009-dashboard-kpis.md.

## FR-008 Equipment Card (version stays 29.0.0.0, no bump)
### Added
- Equipment Card: teaching tip; fields Assigned Since and Assigned By (from the active assignment); Assignment History section (new page 50105 "EQM Assignment History Part"); fields Created By and Last Modified By.
- Internal procedure `GetActiveAssignment` in codeunit "EQM Assignment Mgt.".
- EQM - Read: execute permission on page "EQM Assignment History Part".
### Changed
- Status is promoted on the card; Created Date and Last Modified Date are visible by default.
### Fixed
- None.
### Obsolete
- None.

Release notes: The equipment card now shows who the equipment is assigned to and since when, lists the full assignment history, and shows who created and last changed the record. Created By and Last Modified By are blank for users without access to the user list.

Note: not compiled and not run in a sandbox; no automated tests (deferred by user, Q5). The translation file must be regenerated with AL: Package. No schema change, events or upgrade logic. See docs/features/FR-008-equipment-card.md.

## FR-007 Equipment List Management (version stays 29.0.0.0, no bump)
### Added
- Equipment List: teaching tip on search and filters, and a column "Assigned Employee Name".
- Action Equipment on Equipment Categories (list filtered on the category) and action Assigned Equipment on the Employee Card (list filtered on the employee).
### Changed
- None.
### Fixed
- None.
### Obsolete
- None.

Release notes: The equipment list now explains how to search and filter, shows the name of the assigned employee, and can be opened already filtered from a category (Equipment Categories > Equipment) and from an employee (Employee Card > Assigned Equipment).

Note: not compiled and no automated tests (deferred by user, Q5); not run in a sandbox. Review: APPROVE WITH COMMENTS. No new objects, events or schema changes. Name column needs Employee read access (D365 BASIC); known limitation. See docs/features/FR-007-equipment-list-management.md.

## FR-006 Assignment History Tracking (version stays 29.0.0.0, no bump)
### Added
- Closed assignment entries can no longer be modified or renamed (error `ClosedEntryCannotBeChangedErr`, raised by the table triggers).
- Internal procedure `HasAssignmentHistory` in codeunit "EQM Assignment Mgt.".
### Changed
- Equipment with any assignment entry (active or closed) cannot be deleted; the message tells the user to set the status to Disposed. Closed entries are no longer deleted with their equipment. Supersedes the FR-004 and FR-005 delete rule.
- EQM - Edit has `Rim` (no delete) on assignments; the codeunit permission `d` was removed.
- Tooltip of the Status field on assignments extended. Field names are unchanged: Start Date = Assignment Date, End Date = Closing Date.
### Fixed
- None.
### Obsolete
- Removed internal `DeleteAssignments` and the label `ActiveAssignmentExistsErr`.

Release notes: Assignment history is now protected. Every assignment is kept with its start date (Assignment Date), end date (Closing Date) and the user who assigned it. Closed assignments cannot be changed, and equipment that has ever been assigned cannot be deleted; set it to Disposed instead.

Note: no automated tests (deferred, D4) and not run in a sandbox; see docs/features/FR-006-assignment-history-tracking.md. No new objects, events or schema changes. Trigger-less writes (`Modify(false)`, `Delete(false)`) bypass both rules.

## FR-005 Equipment Unassignment (version stays 29.0.0.0, no bump)
### Added
- FR-005 Equipment Unassignment: equipment can be returned from the equipment card (action Return) and from the Employee Card (action Return Equipment, pick the employee's assigned equipment). A return clears the employee, sets the status to Available and closes the assignment entry, which is kept as history.
### Changed
- The card action "Unassign" is now "Return"; related messages and tooltips reworded. Internal names are unchanged.
- Assigned equipment can become Available only through Return; choosing Available in the Status field is refused with a message.
- `UnassignEmployee` (internal) refuses equipment that is not Assigned, asks a return-specific confirmation and returns a Boolean.
### Fixed
- None.
### Obsolete
- None.

Note: no automated tests (deferred by user request); the return flow and the Employee Card action are not run-tested in a sandbox. No new events or objects. See docs/features/FR-005-equipment-unassignment.md.

## FR-004 Equipment Assignment (version stays 29.0.0.0, no bump)
### Added
- FR-004 Equipment Assignment: every assignment is recorded (equipment, employee, assignment date, assigned by) and closed automatically when the equipment stops being Assigned. Assignments list with views Active and Closed; actions on the equipment card, equipment list and Employee Card.
- Table "EQM Equipment Assignment", enum "EQM Assignment Status", codeunit "EQM Assignment Mgt.", page "EQM Equipment Assignments", page extension "EQM Employee Card".
- Events `OnBeforeInsertAssignment` and `OnBeforeCloseAssignment` in codeunit "EQM Assignment Mgt.".
### Changed
- Only Available equipment can be assigned: In Maintenance to Assigned is now refused (partners can relax it with `OnBeforeCheckStatusTransitionAllowed`).
- Assigned equipment cannot be reassigned in one step; unassign first.
- New equipment cannot be created as Assigned; the Status control on a new card offers Available and In Maintenance.
- Assigned Employee No. on the equipment card is read-only; use Assign to Employee.
- Deleting equipment: refused while Assigned (replaces the confirmation) or with an active assignment; closed assignments are deleted with the equipment.
- EQM - Read gets read on assignments; EQM - Edit gets indirect rights only.
### Fixed
- None.
### Obsolete
- None.

Note: not compiled (.NET 10 missing locally) and no automated tests (decision D8); see docs/features/FR-004-equipment-assignment.md. Equipment already Assigned before FR-004 has no assignment entry (no backfill).

## FR-003 Equipment Status Management
### Added
- FR-003 Equipment Status Management: statuses Available, Assigned, In Maintenance, Lost and Disposed. Lost and Disposed are final: they cannot be assigned, cannot be changed to another status, and cannot be set on new equipment. Changing to Lost or Disposed asks for confirmation and removes the assigned employee.
- Status colors on the equipment list and card; list views for each status.
- Event `OnBeforeCheckStatusTransitionAllowed` in table "EQM Equipment".
### Changed
- Enum "EQM Equipment Status": value "Under Maintenance" renamed to "In Maintenance", Retired renamed to Disposed (ordinals unchanged, so stored Retired records are now Disposed and final), new value Lost.
- An employee is now allowed only when the status is Assigned; this can no longer be skipped by an extension.
- Event `OnBeforeCheckAssignedEmployeeAllowed` replaced by `OnBeforeCheckEmployeeIsEligible`, which only skips the "employee is Active / not privacy blocked" checks.
- Assign to Employee is disabled for Lost and Disposed equipment.
### Fixed
- None.
### Obsolete
- None.

## FR-002 Equipment Categories - 2026-11-02 (version stays 29.0.0.0, no bump)
### Added
- FR-002 Equipment Categories: **Active** flag on equipment categories (default Yes). Only active categories can be newly set on equipment; equipment that already uses a category keeps it.
- Starter categories TABLET and PRINTER for new companies.
- Event `OnBeforeCheckCategoryIsActive` in table "EQM Equipment".
- Feature `TranslationFile` in app.json (source file `Equipment Management.g.xlf` is generated by the first build).
### Changed
- A non-existing category code on equipment now raises the app's own error instead of the platform table-relation error (FR-001 scenario 9).
- Category maintenance (create, edit, delete) moved from EQM - Edit to EQM - Admin (FR-001 scenario 53). EQM - Edit can still read categories.
- Deleting a category in use is still refused; the message now suggests clearing Active.
- Renaming an inactive category that equipment uses is refused.
- Starter category PHONE is now described as "Mobile Phone" (new companies only).
- Development sandboxes: existing category rows get Active = false after the schema sync; reinstall or tick Active.
### Fixed
- None.
### Obsolete
- None.

Note: not yet compiled or tested (tests deferred to V5; .NET 10 missing locally); see docs/features/FR-002-equipment-categories.md.

## 29.0.0.0 - 2026-11-02
### Added
- FR-001 Equipment Registration: equipment master data with number series, categories, serial number, purchase data, status and employee assignment; list, card, categories and setup pages.
- Default data on install: number series EQUIP and categories LAPTOP, MONITOR, PHONE, VEHICLE, TOOL.
- Permission sets EQM - Read, EQM - Edit, EQM - Admin; permission set extension for D365 BASIC (indirect read on equipment).
- Events `OnBeforeCheckSerialNoIsUnique`, `OnBeforeCheckAssignedEmployeeAllowed` and `OnAfterCheckEquipmentConsistency` in table "EQM Equipment".
### Changed
- Deleting an Employee is refused while equipment is assigned to that employee.
### Fixed
- None.
### Obsolete
- None.

Note: not yet compiled or tested; see docs/features/FR-001-equipment-registration.md.

---

# Release notes text (AppSource)

**Equipment registration.** You can now keep a register of your equipment. Each item gets a number, a
category, an optional serial number and purchase details, and you can assign it to an active employee and
unassign it again. Starter categories are included. Note that an employee who still has equipment
assigned can no longer be deleted until the equipment is unassigned.

**Equipment categories.** Administrators can now mark an equipment category as inactive. Inactive categories
can no longer be chosen for new equipment or when changing an equipment category, while equipment that already
uses them keeps them. Maintaining categories now requires the Equipment - Admin permission set. New companies also
get the Tablet and Printer categories.

**Equipment status management.** Equipment now has the statuses Available, Assigned, In Maintenance, Lost and Disposed, shown in color, with a view for each status on the equipment list. Lost and Disposed are final: you confirm the change, the employee is removed, and the status cannot be changed again. New equipment cannot start as Lost or Disposed. "Under Maintenance" is now called In Maintenance and "Retired" is now called Disposed.

**Equipment assignment.** Every assignment of equipment to an employee is now recorded with the date and the user, and closed automatically when the equipment is unassigned or its status changes. You can view the history per equipment and per employee. Only available equipment can be assigned: equipment in maintenance must first be set to Available, assigned equipment must be unassigned before it goes to someone else, and new equipment cannot start as Assigned. Equipment that is assigned cannot be deleted.
