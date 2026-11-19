# Changelog
Newest first. Grouped by Added / Changed / Fixed / Obsolete.

## FR-049 Release Management (version stays 29.0.0.0, no bump)
### Added
- Version policy for the app: Major and Minor come from the app, Build and Revision come from each CI/CD run. Documented in docs/features/FR-049-release-management.md, with the release procedure and the FR-044 upgrade checklist.
- Check `version_check.py`, run by Repo checks on every pull request as check 6. It validates the app version, the AL-Go settings and the test app dependency (VER1 to VER7). It warns when the Major or Minor version is raised.
- Contributor help docs/help/FR-049-release-management.md (which version a build has, how to create a release, how to raise the version, what each VER message means).
### Changed
- Build artifacts are named with the app's Major.Minor: `equipment-management-main-Apps-29.0.<run>.0` instead of `1.0.<run>.0`. The `.app` inside already used 29.0.
- `.AL-Go/settings.json` sets `repoVersion` to 29.0 and `versioningStrategy` to 0 explicitly.
### Fixed
- None.
### Obsolete
- None.

Release notes: None (build tooling only).

Note: no AL code, no `app.json` change, no permission set change, no translation change, no AL-Go system workflow change. The app stays at 29.0.0.0. Verification gate: the AL-Go v10.0 settings and the IncrementVersionNumber script were checked before the change; findings are in the feature doc. Not verified: the Repo checks result and the new artifact names are pending the push; the reviewer's MINOR m1 (the version check fails on JSON that is not an object) is open. No separate AppSource validation ran. The feature doc is docs/features/FR-049-release-management.md.

## FR-047 Test Coverage Targets (version stays 29.0.0.0, no bump)
### Added
- Coverage targets for the test suite: Business Logic 80%, APIs 80% and Critical Processes 100%. A coverage register in `.github/coverage/` lists the rules of the six critical processes and the traces to tests.
- Check `coverage_check.py`, run by Repo checks on every pull request. It reports procedure reach for Business Logic and APIs and rule coverage for the critical processes. It fails the pull request when the register is inconsistent. Below target is a warning only in this phase.
- Feature doc docs/features/FR-047-test-coverage-targets.md (metric, scope, manual Test Explorer coverage run) and contributor help docs/help/FR-047-test-coverage-targets.md.
### Changed
- None.
### Fixed
- None.
### Obsolete
- None.

Release notes: None (build tooling only, no change for end users).

Note: no AL code, no tests added, no `app.json` change, no permission set change, no translation change. The metric is procedure reach, not line coverage: a procedure counts as reached when a test calls it by name or a register trace names a test. Measured line coverage is not in CI, because the BcContainerHelper test run has no coverage option. Baseline (2026-11-19): Business Logic 44.0% (target 80), APIs 0.0% (target 80), Critical Processes rule coverage 77.8% (target 100). Not verified: the first CI Repo checks result is pending the push; the manual VS Code Test Explorer coverage run is not done; the AL tests are not executed locally. No separate AppSource validation ran. The feature doc is docs/features/FR-047-test-coverage-targets.md.

## FR-046 Integration Tests (version stays 29.0.0.0, no bump)
### Added
- Integration tests for four business processes: equipment assignment, maintenance, equipment request approval and notifications. 21 test procedures in one test codeunit in the test app. Each test runs several steps in sequence and checks the history, audit trail, outbox, maintenance log, requests and notifications together. Written; not executed locally. CI result pending.
### Changed
- None.
### Fixed
- None.
### Obsolete
- None.

Release notes: no change for users. The release adds integration tests for the assignment, maintenance, equipment request approval and notification processes.

Note: test app only. No change to `app/`, `app.json`, permission sets, captions or translations. Not verified: tests not executed locally, CI result pending; no separate AppSource validation ran. The feature doc is `docs/features/FR-046-integration-tests.md`.

## FR-045 Automated Unit Tests (version stays 29.0.0.0, no bump)
### Added
- Automated tests for equipment creation, assignment, status changes, maintenance processing and warranty calculation: 52 test procedures in 5 test codeunits in the test app. Written and compiled; not executed locally. CI result pending.
### Changed
- None.
### Fixed
- None.
### Obsolete
- None.

Release notes: no change for users. The release adds automated tests for the equipment, assignment, status, maintenance and warranty rules.

Note: test app only. No change to `app/`, `app.json`, permission sets, captions or translations. Not verified: the tests have not been executed (no CLI runner, no sandbox; CI pending); no separate AppSource validation ran. Plan deviations and open MINORs are in `docs/plans/FR-045-automated-unit-tests.md`.

## FR-044 Data Upgrade Support (version stays 29.0.0.0, no bump)
### Added
- None.
### Changed
- Equipment Setup: an existing setup with a blank Default Warranty Alert Days now shows 90 days, the value the app already used. Values you set are kept. Equipment, assignments, maintenance records and warranty alerts are not changed.
- Permission set EQM - Reader: execute on the internal upgrade helper codeunit. Manager and Administrator inherit it.
### Fixed
- None.
### Obsolete
- None.

Release notes: existing Equipment Setup records now show 90 in Default Warranty Alert Days when the field was blank. Values you have set are kept. The upgrade runs once per company when the new version is installed.

Note: the upgrade runs in each company once and is recorded per company. Install code now runs the same step, so a fresh install and a reinstall also set the value. No event, no app.json change, no version bump. Review: APPROVED (one MINOR: no test for the positive tag path and the tag subscriber; sandbox checks SB1 and SB4 cover it). Not verified: the tests have not been executed (no CLI runner, no sandbox; CI pending); no separate AppSource validation ran; sandbox checks SB1 to SB5 are open (docs/TODO.md, section "FR-044 sandbox checks").

## FR-043 Application Setup (version stays 29.0.0.0, no bump)
### Added
- Equipment Setup: group Defaults with Default Warranty Alert Days (1 to 90, 90 by default: how early warranty alerts start) and Default Maintenance Frequency (Months) (0 to 120: the frequency new equipment gets on the Equipment Card).
- Equipment Setup: group Features with three switches, Enable Notifications, Enable Equipment Requests and Enable APIs. They change the same settings as the Equipment Features page; Enable Equipment Requests is Approval Workflows and Enable APIs is API Integration.
- Feature Notifications on the Equipment Features page (six features now). When it is off, no equipment notification is shown in the company: on the equipment card, the maintenance record card, the Role Center, or when equipment comes back from maintenance.
- Test codeunit "EQM Application Setup Tests" (20 test procedures). Written; not executed locally. CI result pending.
- Feature doc docs/features/FR-043-application-setup.md and help docs/help/FR-043-application-setup.md.
### Changed
- Warranty alerts start at the Default Warranty Alert Days before the warranty end date. Setups created before this version use 90 days, as before.
- Equipment Card: a new equipment record starts with the default maintenance frequency. You can change it before you save.
- Equipment Features page: the About text lists notifications.
### Fixed
- None.
### Obsolete
- None.

Release notes: Equipment Setup now has a Defaults group and a Features group. Set the Default Warranty Alert Days to choose how early warranty alerts start, and the Default Maintenance Frequency to have new equipment start with that frequency on the Equipment Card. Use the three switches to turn notifications, equipment requests and the APIs on or off for the company.

Note: no upgrade code, no install code, no app.json change, no permission set change, no event. Existing setups show Default Warranty Alert Days blank, which means 90 days; entering 0 is rejected. Enum value 5 Notifications is published and cannot be renamed. The new captions, ToolTips, labels and search terms are in the translation file, regenerated by the build. Review: APPROVED. Not verified: the tests have not been executed (no CLI runner, no sandbox; CI pending); no separate AppSource validation ran; sandbox checks S1 to S9 are open (docs/TODO.md, section "FR-043 sandbox checks").

## FR-042 Feature Management (version stays 29.0.0.0, no bump)
### Added
- Page "Equipment Features": an administrator turns five optional features on or off for the current company: Equipment Images, Warranty Alerts, Approval Workflows, API Integration and Maintenance Planning. Each feature switches on its own. The page is found with Tell Me, from Equipment Setup and from the Equipment Manager Role Center. Users who cannot change the settings see the page read-only. Nothing changes until a feature is turned off.
- When a feature is off, the pages that belong only to it show an error with an action that opens Equipment Features.
- Internal feature table, enum and codeunit for feature activation. Test codeunit "EQM Feature Mgt. Tests" (21 test procedures). Written; not executed locally. CI result pending.
- Feature doc docs/features/FR-042-feature-management.md and help docs/help/FR-042-feature-management.md.
### Changed
- With a feature off, its controls are hidden: the Picture FactBox (Equipment Images); the Warranty Alerts action, the Open Warranty Alerts tile and the warranty job field (Warranty Alerts); the Equipment Requests action on the Employee Card and the Requests Pending Approval tile (Approval Workflows); the integration settings and the Integration Event Entries action (API Integration); the planned maintenance fields and tiles (Maintenance Planning). The Equipment Requests and Warranty Alerts actions on the Role Center stay visible and show the error when opened.
- With a feature off, the warranty notifications are not sent and the daily job creates no warranty alerts. The equipment API pages return an error, and no integration event entries are written.
- Permission sets EQM - Reader, EQM - Administrator and EQM - API Consumer: access to the feature settings. Only the Administrator can change them. Manager inherits Reader.
- Test codeunit "EQM Role Permission Tests": 1 new and 4 changed test procedures for the feature settings. Not executed locally. CI result pending.
### Fixed
- None.
### Obsolete
- None.

Release notes: Equipment Management now lets an administrator turn five optional features on or off for each company: Equipment Images, Warranty Alerts, Approval Workflows, API Integration and Maintenance Planning. Open Equipment Features from Tell Me, Equipment Setup or the Equipment Manager Role Center. Nothing changes until you turn a feature off. Data is never deleted by switching a feature off. The Equipment Requests and Warranty Alerts actions on the Role Center stay visible even when their feature is off; opening them shows the message.

Note: no upgrade code, no install code, no event, no change to existing stored data, no app.json change, version stays 29.0.0.0. One new table holds one row per feature, created when an administrator opens the page. The new captions, ToolTips, labels, About text and search terms are in the translation file, regenerated by the build. Not verified: the tests have not been executed (no CLI runner, no sandbox; CI pending); no separate AppSource validation ran; sandbox checks S1 to S10 are open (docs/TODO.md, section "FR-042 sandbox checks").

## FR-041 Maintenance Cost Analysis (version stays 29.0.0.0, no bump)
### Added
- Report "Maintenance Cost Analysis": posted maintenance cost and number of maintenances, with one row per category, equipment, year and month, sorted by category, equipment, year and month. The request page has two tabs: Equipment (No., Category Code) and Posted Maintenance (Maintenance Date, Maintenance Type); the tabs combine with AND. Open maintenance is never counted. Zero-cost entries are counted. The category is the equipment's current category. With no filter, all posted maintenance is included. The output is an Excel workbook.
- Action "Maintenance Cost Analysis" in the Reporting area of the Equipment List and the Equipment Manager Role Center. The report is also found with Tell Me.
- Internal temporary buffer table "EQM Maint. Cost Buffer" (never stored) and internal procedure `BuildMaintenanceCostBuffer` on codeunit "EQM Dashboard Mgt.".
- Test codeunit "EQM Maint. Cost Analysis Tests" (12 test procedures). Written; not executed (no CLI runner, no sandbox). CI result pending.
- Feature doc docs/features/FR-041-maintenance-cost-analysis.md and help docs/help/FR-041-maintenance-cost-analysis.md.
### Changed
- Permission set EQM - Reader: execute on the report and the buffer table. Manager and Administrator inherit it. API Consumer is unchanged.
### Fixed
- None.
### Obsolete
- None.

Release notes: Equipment Management now has a Maintenance Cost Analysis report. It shows the posted maintenance cost and the number of maintenances for each category, equipment, year and month, in an Excel workbook that you can total and pivot. Filter it by equipment, category, maintenance date and maintenance type before you run it. Open maintenance is not included. Choose Maintenance Cost Analysis on the Equipment list or in the Equipment Manager Role Center.

Note: no upgrade code, no event, no schema change, no app.json change. The new captions, ToolTips, layout caption and search terms are in the translation file, regenerated by the build. The Excel layout is generated from the data; it has no formatting, totals or PivotTables yet. Not verified: the tests have not been executed (no CLI runner, no sandbox; CI pending); no separate AppSource validation ran; sandbox checks S1 to S6 are open (docs/TODO.md, section "FR-041 sandbox checks").

## FR-040 Asset Utilization Report (version stays 29.0.0.0, no bump)
### Added
- Report "Asset Utilization": one row with the total, assigned, available and in-maintenance equipment and the utilization percentage (assigned divided by total equipment, times 100, rounded to two decimals). Total counts all equipment except lost and disposed equipment. The request page filters on Category Code and Location Code; other fields can be added with "+ Filter". With no filter, all equipment is counted. The output is an Excel workbook.
- Action "Asset Utilization" in the Reporting area of the Equipment List and the Equipment Manager Role Center. The report is also found with Tell Me.
- Test codeunit "EQM Asset Utilization Tests" (10 test procedures). Written; not executed (no CLI runner, no sandbox).
- Feature doc docs/features/FR-040-asset-utilization-report.md and help docs/help/FR-040-asset-utilization-report.md.
### Changed
- Permission set EQM - Reader: execute on the report. Manager and Administrator inherit it. API Consumer is unchanged.
### Fixed
- None.
### Obsolete
- None.

Release notes: Equipment Management now has an Asset Utilization report. It shows how much of your equipment is assigned: total, assigned, available and in-maintenance equipment, and the utilization percentage. Lost and disposed equipment is not counted, so the total can be lower than the Total Equipment tile on the dashboard. Filter it by category and location before you run it. Choose Asset Utilization on the Equipment list or in the Equipment Manager Role Center.

Note: no upgrade code, no event, no schema change, no app.json change. The new captions, ToolTips, layout caption and search terms are in the translation file, regenerated by the build. The Excel layout is generated from the data; it has no formatting, totals or chart yet. Build: `app/` and `test/` compile with 0 errors and 0 warnings from this change. Review: APPROVED. Not verified: the tests have not been executed (no CLI runner, no sandbox); no separate AppSource validation ran; sandbox checks S1 to S5 are open (docs/TODO.md, section "FR-040 sandbox checks").

## FR-039 Equipment Register Report (version stays 29.0.0.0, no bump)
### Added
- Report "Equipment Register": one row per equipment with its main data (number, description, category, serial number, manufacturer, model, status, assigned employee, location, purchase date, purchase cost and warranty end date), sorted by number. The request page filters on Category Code, Status, Assigned Employee No. and Purchase Date; several filters combine with AND. With no filter, all equipment is listed, including lost and disposed equipment. The output is an Excel workbook.
- Action "Equipment Register" in the Reporting area of the Equipment List and the Equipment Manager Role Center. The report is also found with Tell Me.
- Test codeunit "EQM Equipment Register Tests" (11 test procedures). Written; not executed (no CLI runner, no sandbox).
- Feature doc docs/features/FR-039-equipment-register-report.md and help docs/help/FR-039-equipment-register-report.md.
### Changed
- Permission set EQM - Reader: execute on the report. Manager and Administrator inherit it. API Consumer is unchanged.
### Fixed
- None.
### Obsolete
- None.

Release notes: Equipment Management now has an Equipment Register. It lists your equipment with its category, status, assigned employee, purchase and warranty data, in an Excel workbook. Filter it by category, status, employee and purchase date before you run it. Choose Equipment Register on the Equipment list or in the Equipment Manager Role Center. Employee names are left blank for users who cannot read employees.

Note: no upgrade code, no event, no schema change, no app.json change. The new captions, ToolTips, layout caption and search terms are in the translation file, regenerated by the build. The Excel layout is generated from the data; it has no formatting, totals or pivot yet. Not verified: the tests have not been executed; no separate AppSource validation ran; sandbox checks S1 to S5 are open (docs/TODO.md, section "FR-039 sandbox checks").

## FR-038 Enhanced Role Center (version stays 29.0.0.0, no bump)
### Added
- Operational Indicators group on the Equipment Manager Role Center and the equipment dashboard, with four tiles: Requests Pending Approval (drill-down to the pending requests), Warranties Expiring This Month (warranties that end from today to the end of the month, drill-down to the equipment list), Open Maintenance Activities (open maintenance records) and Total Assets Value (purchase cost of equipment that is not lost or disposed of, in local currency).
- Test codeunit "EQM Dashboard Tests" (12 test procedures). Written and compiled; not executed (no CLI runner, no sandbox).
- Feature doc docs/features/FR-038-enhanced-role-center.md and help docs/help/FR-038-enhanced-role-center.md.
### Changed
- Equipment dashboard: the About text describes the new tiles. The Refresh action and the refresh on activation update the new tiles.
- Cue part "EQM Equipment Cues": new group Operational Indicators between the Equipment and Warranty groups. The existing tiles, groups and order are unchanged.
### Fixed
- None.
### Obsolete
- None.

Release notes: The Equipment Manager Role Center and the equipment dashboard have a new group, Operational Indicators, with four numbers. Requests Pending Approval counts the requests waiting for a decision. Warranties Expiring This Month counts the warranties that end before the end of the current month. Open Maintenance Activities counts the maintenance records that are not yet posted. Total Assets Value shows the total purchase cost of the equipment that is not lost or disposed of. Choose a number to see the records behind it.

Note: no upgrade code, no event, no schema change for stored data (the new fields are on the temporary cue table), no permission set change, no app.json change. The new captions, ToolTips and About text are in the translation file, regenerated by the build. Not verified: the tests have not been executed; no separate AppSource validation ran; sandbox checks S1 to S3 are open (docs/TODO.md, section "FR-038 sandbox checks").

## FR-061 Code Quality Compliance (version stays 29.0.0.0, no bump)
### Added
- Code analysis is switched on in the VS Code settings of both folders. The main app runs CodeCop, UICop and AppSourceCop. The test app runs CodeCop and UICop locally.
- AppSourceCop configuration for the main app with the EQM affix.
- Feature doc docs/features/FR-061-code-quality-compliance.md (diagnostic inventory and exception register) and contributor help docs/help/FR-061-code-quality-compliance.md.
### Changed
- AL-Go pipeline: CI analyses the main app with CodeCop, UICop and AppSourceCop. CI does not analyse the test app. The first PR build failed on the test app (AS0015 and AS0054), so test-app analysis in CI was turned off. Restoring it is a later decision.
- Feature doc and help for FR-048 (automated build pipeline) describe the analyzer scope as above.
### Fixed
- Two findings in the test app: a `using` order and a filter on a field without a key. Neither changes what the tests check.
### Obsolete
- None.

Release notes: No change for users. The app code now passes CodeCop, UICop and AppSourceCop with no errors and no warnings. Some manifest and registration warnings remain open; they are listed in the feature doc. The ruleset that lowers them is for this demo and must be removed before a real AppSource submission, so the app is not submission ready.

Note: no upgrade code, no event, no schema change, no ruleset or `app.json` change, no translation change. Not verified: the main-app analyzer lines and a green build in the next CI run after the fix; the tests have not been executed in CI; the test app is not analysed by AppSourceCop, locally or in CI, by decision.

## FR-037 FactBoxes (version stays 29.0.0.0, no bump)
### Added
- Three read-only FactBoxes on the Equipment Card: Equipment Summary (status, assigned employee, warranty status), Equipment Statistics (assignment count, maintenance count, total posted maintenance cost) and Attachment Summary (document count, image count). Choose a number to open the matching list.
- Internal codeunit "EQM Equipment Attachment Mgt." (counts and shows the attachments of equipment).
- Test codeunit "EQM Equipment FactBox Tests" (16 test procedures). Written and compiled; not executed (no CLI runner, no sandbox).
- Feature doc docs/features/FR-037-factboxes.md and help docs/help/FR-037-factboxes.md.
### Changed
- Equipment Card: the three FactBoxes sit after the Picture FactBox. The About text describes them. The existing FactBoxes stay visible.
- Permission set EQM - Reader: execute on the three FactBox pages and the attachment codeunit. Manager and Administrator inherit it. API Consumer is unchanged.
### Fixed
- None.
### Obsolete
- None.

Release notes: The Equipment Card has three new FactBoxes. Equipment Summary shows the status, the assigned employee and the warranty status. Equipment Statistics shows how often the equipment was assigned, how many maintenance records were posted and their total cost. Attachment Summary counts the attached documents and images. Choose a number to open the matching list. Images and documents are counted as recognized by Business Central.

Note: no upgrade code, no event, no schema change. Review: APPROVED (round 2). The app and test app were reported to compile with 0 errors and 0 warnings in the VS Code build; this was not independently verified. Not verified: the tests have not been executed (no CLI runner); no separate AppSource validation ran; sandbox checks S1 to S3 are open (docs/TODO.md, section "FR-037 sandbox checks").

## FR-036 Permission Sets (version stays 29.0.0.0, no bump)
### Added
- Permission set 50104 "EQM - API Consumer" (caption "Equipment API Consumer", assignable, includes no other set): data access through the four API pages only. Read and write on equipment (no delete), assignments and integration events (indirect, for `assign`, `returnEquipment`, `markProcessed`), read on categories, setup and maintenance records, indirect insert on audit entries. Execute on the 4 API pages, 7 tables and 10 codeunits of the write path; no UI page, no query. Assign together with D365 BASIC.
- Test codeunit 50162 "EQM Role Permission Tests" (14 test procedures): structural checks of all four sets. Written and compiled; not executed (no sandbox).
- Feature doc docs/features/FR-036-permission-sets.md (matrix and audit of the existing sets) and help docs/help/FR-036-permission-sets.md.
### Changed
- Nothing. Equipment Reader, Manager and Administrator were audited and left unchanged.
### Fixed
- None.
### Obsolete
- None.

Release notes: A new Equipment API Consumer permission set lets an external system use the Equipment API through a Microsoft Entra application without opening any page and without the right to delete equipment. Equipment Reader, Manager and Administrator are unchanged. Assign D365 BASIC together with any of them.

Note: decisions D1 full (API Consumer includes all API writes), D2 no (no DELETE on equipment). The Role ID "EQM - API Consumer" becomes a contract at the first AppSource release. Not verified: test codeunit 50162 not executed; sandbox scenarios S1 to S4 open (docs/TODO.md).

## FR-035 Equipment Audit Trail (version stays 29.0.0.0, no bump)
### Added
- Enum 50111 "EQM Audit Event Type" (not extensible): Created, Updated, Assigned, Returned, Sent to Maintenance, Disposed.
- Table 50112 "EQM Equipment Audit Entry" (public, append-only): equipment, event type, status after, employee, assignment entry, maintenance record, user, date and time. Insert only through the audit trail codeunit; Modify, Delete and Rename raise an error.
- Codeunit 50135 "EQM Audit Trail Mgt." and codeunit 50136 "EQM Audit Trail Subscr." (both internal). Created, Assigned and Returned come from the business events of codeunit 50119; Sent to Maintenance, Disposed and Updated come from `OnModify` of table 50100. No new published events.
- Page 50136 "EQM Equipment Audit Trail": read-only list, newest first.
- Action "Audit Trail" on page 50101 "EQM Equipment Card".
- Test codeunits 50192 "EQM Audit Trail Tests" (21 test procedures) and 50193 "EQM Audit Trail Test Subscr". Written and compiled; not executed (no sandbox, not yet run in CI).
- Feature doc docs/features/FR-035-equipment-audit-trail.md and help docs/help/FR-035-equipment-audit-trail.md.
### Changed
- Table 50100 "EQM Equipment": `OnModify` writes the audit entries; `StartMaintenance` passes the maintenance number (internal, no signature change).
- Page 50101 "EQM Equipment Card": About text mentions Audit Trail.
- Permission set EQM - Reader: read on table data 50112, execute on table 50112, page 50136 and codeunits 50135 and 50136. EQM - Manager: indirect insert on table data 50112. Administrator inherits.
### Fixed
- None.
### Obsolete
- None.

Release notes: Every piece of equipment now has a read-only audit trail of its life: created, updated, assigned, returned, sent to maintenance and disposed, with the user, the time and the status afterwards. Open it with Audit Trail on the Equipment Card. Updated entries do not show field values; the standard Change Log shows those.

Note: decisions D1 save (one Updated entry per save, no field names or values; the Equipment Card saves each edited field separately, so five edited fields give five Updated entries), D2 updated (status changes to Lost or back to Available log Updated with the new status), D3 keep (deleting equipment leaves its entries). Returned is logged before Sent to Maintenance and Disposed. Equipment created before this feature has no Created entry (no backfill). No upgrade code. Not verified: the tests have not been executed; sandbox scenarios 14 (rename cascade, Manager permission) and 15 (permissions) are open (docs/TODO.md).

## FR-034 Change Log Support (version stays 29.0.0.0, no bump)
### Added
- Codeunit 50133 "EQM Change Log Registration" (internal): registers table 50100 "EQM Equipment" in the standard Change Log setup (tables 403 and 404): Log Modification = Some Fields, with fields Category Code, Status, Assigned Employee No., Warranty Start Date, Warranty End Date, Warranty Provider and Warranty Reference No. Existing customer setup for the table is never overwritten. An upgrade tag (`MC-EQM-FR034-ChangeLogSetup-20261116`) makes it run once per company.
- Codeunit 50134 "EQM Upgrade" (internal, `OnUpgradePerCompany`): calls the registration for existing installations at the next version bump.
- Test codeunit 50191 "EQM Change Log Setup Tests" (7 tests). They pass in AL-Go CI (PR #128); not run in a BC sandbox.
- Feature doc docs/features/FR-034-change-log-support.md and help docs/help/FR-034-change-log-support.md.
### Changed
- Codeunit 50104 "EQM Install": calls the registration after the default data.
- docs/features/NFR-005-auditability.md and its help: the app now registers setup rows in the Change Log (it still does not activate it).
### Fixed
- None.
### Obsolete
- None.

Release notes: Equipment changes can now be tracked in the standard Business Central Change Log. The app registers equipment category, status, assigned employee and the warranty fields; an administrator turns on Change Log Activated in Change Log Setup. Only changes are recorded.

Note: decisions D1 off (Change Log Activated stays off), D2 and D3 no (tables 50101 and 50103 are not logged), D4 inputs (stored warranty fields 17-20; warranty status is calculated and not logged). No schema change. No new translatable text (the one new label is Locked), so `Equipment Management.g.xlf` does not change. Not verified: the manual sandbox checks (docs/TODO.md, FR-034, scenarios 8 and 9). The upgrade codeunit takes effect only at the next version bump.

## FR-033 Approval Workflow (version stays 29.0.0.0, no bump)
### Added
- Codeunit 50132 "EQM Request Approval Mgt." (public, internal procedures): Send for Approval, Approve, Reject and Assign Equipment for equipment requests. Open > Pending Approval > Approved > Completed, and Pending Approval > Rejected. The sender cannot approve; a rejection needs a comment; Rejected and Completed are final. Published events `OnBeforeCheckApproverAllowed` (IsHandled skips only the self-approval check) and `OnAfterRequestStatusChanged` (local integration events).
- Page 50135 "EQM Request Decision": comment dialog for approve and reject.
- Fields 9-13 on table 50111 "EQM Equipment Request": "Sent for Approval By", "Decided By", "Decision Date", "Decision Comment", "Assigned Equipment No." (not editable).
- Actions Send for Approval, Approve, Reject and Assign Equipment on pages 50134 and 50133; group Approval on the card.
- Test codeunits 50189 "EQM Request Approval Tests" (41 tests) and 50190 "EQM Request Appr. Test Subscr". They pass in AL-Go CI (PR #126); not run in a BC sandbox.
- Feature doc docs/features/FR-033-approval-workflow.md and help docs/help/FR-033-approval-workflow.md.
### Changed
- Permission set EQM - Reader: execute on codeunit 50132 and page 50135. Manager and Administrator inherit.
- Status ToolTip of table 50111, summaries of table 50111 and enum 50110, and About text of pages 50133 and 50134 describe the approval process.
### Fixed
- None.
### Obsolete
- None.

Release notes: Equipment requests now have an approval process. A manager sends an open request for approval; another manager approves it or rejects it with a reason. Approved requests are completed with Assign Equipment, which assigns available equipment of the requested type to the employee. Rejected and completed requests cannot be changed.

Note: decisions Q1 own approval (not BC Approvals Management), Q2 the sender cannot approve, Q3 assignment from the request is an action (direct assignment unchanged), Q4 no stock check at approval, Q5 employee deletion not blocked. No upgrade code, no schema change besides new fields. The AL-Go PR build was green (209 test functions, 0 failures). Not verified: the manual sandbox checks (docs/TODO.md, FR-033, scenario 17) are not done. At the first AppSource release, codeunit 50132, its two event signatures and fields 9-13 become contracts.

## FR-032 Equipment Request Process (version stays 29.0.0.0, no bump)
### Added
- Enum 50110 "EQM Request Status" (not extensible): Open, Pending Approval, Approved, Rejected, Completed.
- Table 50111 "EQM Equipment Request" (public): employee, requested equipment type (equipment category), justification, request date, status. Numbered from "Request Nos."; checks on insert and modify; only Open requests can be changed or deleted; the number cannot be renamed. Published event `OnAfterCheckRequestConsistency` (local integration event).
- Pages 50133 "EQM Equipment Requests" (list with views per status and an Employee action) and 50134 "EQM Equipment Request Card".
- Action "Equipment Requests" on the Employee Card (page extension 50100) and on the Equipment Manager Role Center (page 50110).
- Field 5 "Request Nos." on table 50102 "EQM Equipment Setup" and on page 50103; default number series EQREQ (REQ00001) created by codeunit 50105 when the field is blank.
- Test codeunit 50188 "EQM Equipment Request Tests": 46 tests, all pass in AL-Go CI (PR #124: 168 tests in total, 0 failed).
- Feature doc docs/features/FR-032-equipment-request-process.md and help docs/help/FR-032-equipment-request-process.md.
### Changed
- Permission set EQM - Reader: read on table data "EQM Equipment Request", execute on table 50111 and pages 50133 and 50134. EQM - Manager: RIMD on the table data. Administrator inherits.
- Existing companies keep a blank "Request Nos." until an administrator sets it.
### Fixed
- None.
### Obsolete
- None.

## FR-031 Power Automate Support (version stays 29.0.0.0, no bump)
### Added
- Codeunit 50130 "EQM Power Automate Events" (public): external business events `equipmentAssigned` and `warrantyExpiring` (version '1.0', category Equipment Management). Publishers are internal; delivered by the platform after commit, only to subscribed flows.
- Codeunit 50131 "EQM Power Automate Subscr." (internal): raises `equipmentAssigned` from `OnEquipmentAssigned` of codeunit 50119 and `warrantyExpiring` from `OnAfterInsertEvent` of table 50107 "EQM Warranty Alert".
- Enum extension 50100 "EQM Event Category" (extends `EventCategory`): category "Equipment Management".
- Test codeunit 50187 "EQM Power Automate Tests" (3 smoke tests: the operations that fire the subscribers run without an error).
- Feature doc docs/features/FR-031-power-automate-support.md and help docs/help/FR-031-power-automate-support.md (two example flows).
### Changed
- Permission set EQM - Reader: execute on codeunits 50130 and 50131. Manager and Administrator inherit it.
### Fixed
- None.
### Obsolete
- None.

Release notes: Equipment Management now offers two triggers for the "When a business event occurs" trigger of the Business Central connector in Power Automate, under the category Equipment Management. Equipment assigned starts a flow when equipment is assigned to an employee; Warranty expiring starts a flow when a 90, 60 or 30 day warranty alert is created. Events are sent only to flows that subscribe, and only after the operation is saved.

Note: no upgrade code, no schema change, no setup switch. Both apps compile with 0 errors and 0 warnings. The platform does not call an AL subscriber for an external business event in the test runner (CI PR #122), so the raise count and payload are not tested automatically; the 3 smoke tests pass in CI (PR #122 build: 122 tests, 0 failed, 0 skipped). Not verified (sandbox, scenarios 1, 4 and 8): the events are raised once with the right payload, no event for a failed assignment, a return, a repeated alert run, a temporary or Insert(false) alert, an alert outside the window or disposed equipment; event discovery under Equipment Management, event discovery under Equipment Management, Teams message and email flows, delivery after commit only, the BC permission needed to subscribe, Guid/Date rendering, translatability of the attribute strings. At first AppSource release the codeunit, event names, parameters and version become a frozen contract.

## FR-030 Event Subscribers (version stays 29.0.0.0, no bump)
### Added
- Enum 50109 "EQM Integration Event Type" (not extensible) and table 50110 "EQM Integration Event Entry" (public): the outbox, one entry per business event, written in the same transaction. Entries can only be created and marked processed through codeunit 50122; only processed entries can be deleted. Extra fieldgroups DropDown and Brick on the table.
- Codeunit 50121 "EQM Integration Event Subscr." (internal): subscribes to the five events of codeunit 50119. Codeunit 50122 "EQM Integration Event Mgt." (internal): `IsEnabled`, `RecordEvent`, `MarkProcessed`.
- Page 50132 "EQM Integration Event Entries" (read-only list, delete of processed entries allowed) and API page 50126 "EQM Integration Event API" (v1.0, publisher `miguelCarvalho`, group `equipment`, entity `integrationEvents`, read-only, bound action `markProcessed`).
- Test codeunit 50186 "EQM Integration Event Tests": 14 tests (all pass in AL-Go CI, PR #120).
- Feature doc docs/features/FR-030-event-subscribers.md and help docs/help/FR-030-event-subscribers.md.
### Changed
- Table 50102 "EQM Equipment Setup": new field 4 "Integration Events Enabled" (off by default). Page 50103: group "Integration" and action "Integration Event Entries".
- Permission sets: Reader gets read on table 50110 and execute on the new objects; Manager insert; Administrator modify and delete. Details in the feature doc.
### Fixed
- None.
### Obsolete
- None.

Release notes: Other systems can now follow what happens to your equipment. Turn on Integration Events Enabled in Equipment Setup and Business Central records an entry each time equipment is created, assigned or returned, maintenance is created, or a warranty expires. External systems read the pending entries through the API (v1.0, publisher miguelCarvalho, group equipment, entity integrationEvents) and mark them as processed. The setting is off by default.

Note: no upgrade code (the new setting defaults to off). The app compiles clean with CodeCop and UICop; AppSourceCop reports only the known manifest diagnostics. The 14 new tests pass in AL-Go CI (PR #120; 119 tests in total, 0 failed). Not verified: sandbox scenario 12 (API GET and markProcessed, Reader denied on markProcessed, scheduled warranty job writes entries); plan item V1 (bound action on an API page with ModifyAllowed = false). At first AppSource release the table, enum values and API v1.0 become a frozen contract.

## FR-029 Business Events (version stays 29.0.0.0, no bump)
### Added
- Codeunit 50119 "EQM Business Events" (public): five integration events `OnEquipmentCreated`, `OnEquipmentAssigned`, `OnEquipmentReturned`, `OnMaintenanceCreated`, `OnWarrantyExpired`. Publishers are internal: partners can subscribe, not raise. Notify only, no `IsHandled`.
- Codeunit 50120 "EQM Business Event Subscr." (internal): raises the two created events after `Insert(true)` of equipment and maintenance records.
- Procedure `RaiseWarrantyExpiredEvents` (internal) in codeunit 50110, called by the daily warranty job.
- Test codeunits 50184 "EQM Business Events Tests" and 50185 "EQM Business Event Test Subscr.": 12 scenarios, all pass in AL-Go CI (105 tests in total, 0 failed).
- Feature doc docs/features/FR-029-business-events.md and help docs/help/FR-029-business-events.md.
### Changed
- Codeunit 50106 raises assigned and returned (returned for every close: Return action, maintenance, Lost or Disposed, leftover entry on a new assignment).
- Codeunit 50111 "EQM Warranty Alert Job": after generating alerts it now calls `Commit()` and then raises OnWarrantyExpired. A failing subscriber stops the remaining equipment and sets the job queue entry to Error; the alerts are kept.
- Permission set EQM - Reader: execute on codeunits 50119 and 50120. Manager and Administrator inherit it.
### Fixed
- None.
### Obsolete
- None.

Release notes: Partner extensions can now subscribe to five new events in Equipment Management: equipment created, equipment assigned, equipment returned, maintenance created and warranty expired. The events notify only and cannot change standard behavior. Assigned and returned are raised while the equipment is being saved, and the warranty event is raised once a day by the warranty job. Other extensions can subscribe to the events but cannot raise them.

Note: no upgrade code, no schema change. Not verified: sandbox scenario 13 (scheduled warranty job run, `Commit()` behavior, event raised); permissions per role. At first AppSource release the codeunit, event names and parameters become a frozen contract. Optional later chore: a key on Warranty End Date.

## FR-028 Assignment History API (version stays 29.0.0.0, no bump)
### Added
- Page 50125 "EQM Assignment API" (API v1.0, publisher `miguelCarvalho`, group `equipment`, entity `assignments`): read-only GET on table 50103 with `id`, `entryNumber`, `equipmentNumber`, `employeeNumber`, `assignmentDate`, `status`, `closingDate`, `lastModifiedDateTime`. Returns active and closed entries; clients filter on `status`, `equipmentNumber` or `lastModifiedDateTime`. `assignedBy`/`closedBy` are deliberately excluded (personal data). Not extensible.
- Test codeunit 50182 "EQM Assignment API Tests": 7 table-level AutoRollback tests (all 7 pass in AL-Go CI, PR #117; one test that wrapped Modify in a TryFunction failed in the first run and was removed).
- Feature doc docs/features/FR-028-assignment-history-api.md and help docs/help/FR-028-assignment-history-api.md.
### Changed
- Permission set EQM - Reader: `page "EQM Assignment API" = X`. Manager and Administrator inherit it.
### Fixed
- None.
### Obsolete
- None.

Release notes: Other systems can now read the assignment history of your equipment through the Business Central API (v1.0, publisher miguelCarvalho, group equipment, entity assignments). Each entry shows the equipment, the employee, the assignment date, the status and the closing date, for current and past assignments. The API is read-only and does not include user names. Equipment Reader, Manager and Administrator can use it.

Note: no event published, no upgrade code. Both apps compile with 0 errors and 0 warnings (CodeCop, UICop). Review verdict: APPROVE WITH CHANGES (no blockers; xlf regenerated and test codeunit added since). The 7 automated tests pass in AL-Go CI (PR #117); the 8th, a TryFunction around Modify (not allowed in a test run), failed in the first run and was removed. Not verified: sandbox scenarios 6 to 11 (GET list and by id, 404, filters, rejected writes and their HTTP status, equipment join, permissions). At first AppSource release v1.0 becomes a frozen contract.

## FR-027 Equipment Categories API (version stays 29.0.0.0, no bump)
### Added
- Page 50124 "EQM Category API" (API v1.0, publisher `miguelCarvalho`, group `equipment`, entity `categories`): read-only GET on table 50101 with `id`, `code`, `description`, `active`, `lastModifiedDateTime`. Returns all categories; clients filter with `$filter=active eq true`. Not extensible.
- Test codeunit 50181 "EQM Category API Tests": 6 table-level AutoRollback tests (all 6 pass in AL-Go CI).
- Feature doc docs/features/FR-027-equipment-categories-api.md and help docs/help/FR-027-equipment-categories-api.md.
### Changed
- Permission set EQM - Reader: `page "EQM Category API" = X`. Manager and Administrator inherit it.
### Fixed
- None.
### Obsolete
- None.

Release notes: Other systems can now read your equipment categories through the Business Central API (v1.0, publisher miguelCarvalho, group equipment, entity categories). The list includes the code, description and active flag of every category. The API is read-only. Equipment Reader, Manager and Administrator can use it.

Note: no event published, no upgrade code. Both apps compile with CodeCop and UICop. Review verdict: APPROVE WITH COMMENTS. The 6 automated tests pass in AL-Go CI (PR #115). Not verified: sandbox scenarios 4 to 8 (GET list and by id, 404, equipment categoryCode lookup, permissions) and the HTTP status for rejected writes (V1). At first AppSource release v1.0 becomes a frozen contract.

## FR-025 Equipment Notes (version stays 29.0.0.0, no bump)
### Added
- Table 50109 "EQM Equipment Note" (public, append-only): Entry No., Equipment No., Created At, User ID, Comment. The system sets Created At and User ID on insert; modify, delete and rename raise errors.
- Page 50131 "EQM Equipment Notes" (read-only list) and page 50130 "EQM Equipment Notes Part" (insert-only ListPart, newest first).
- Test codeunit 50183 "EQM Equipment Note Tests": 18 tests; all 18 passed in AL-Go CI (commit dc2149d), including the rename cascade and a note typed on a new card part line (the card passes the equipment number with SetEquipmentNo). Not checked in a sandbox: permissions per role, Tell Me, web client layout.
- Feature doc docs/features/FR-025-equipment-notes.md and help docs/help/FR-025-equipment-notes.md.
### Changed
- Equipment Card: part Equipment Notes, action ShowEquipmentNotes, AboutText sentence.
- Table 50100 "EQM Equipment": equipment that has notes can no longer be deleted (public table, behavior change).
- Permission sets: Reader gets read and execute on the new table and pages; Manager gets RI on the new table. No set can modify or delete notes.
### Fixed
- None.
### Obsolete
- None.

Release notes: You can now record dated notes on a piece of equipment. Each note shows when it was written and by whom, appears newest first in Equipment Notes on the Equipment Card, and cannot be changed or deleted afterwards. Equipment that has notes can no longer be deleted; set its status to Disposed instead. Equipment Reader can see notes; Equipment Manager can also add them.

Note: no event published, no upgrade code. V1 (rename of equipment with notes) is confirmed by the passing CI test. Not verified: the fixed test has not been re-run in CI; V2 (new-line editability of Comment) partly; sandbox scenario 12 (permissions, Tell Me). At first AppSource release table 50109 becomes a frozen contract.

## FR-026 Equipment API (version stays 29.0.0.0, no bump)
### Added
- Page 50123 "EQM Equipment API" (API v1.0, publisher `miguelCarvalho`, group `equipment`, entity `equipments`): GET, POST, PATCH, DELETE on table 50100, plus bound actions `assign(employeeNumber)` and `returnEquipment`. Not extensible. Sets the API conventions C1 to C10 for FR-027 and FR-028.
- Test codeunit 50180 "EQM Equipment API Tests": 35 table-level AutoRollback tests that run the table triggers and the AssignEmployee / UnassignEmployee procedures the API page uses. No HTTP calls and no Tests-TestLibraries dependency (test/app.json depends only on the main app and Library Assert). All 35 pass in AL-Go CI (PR #111, merge commit 0f9718f).
- Feature doc docs/features/FR-026-equipment-api.md and help docs/help/FR-026-equipment-api.md.
### Changed
- Permission set EQM - Reader: `page "EQM Equipment API" = X`. Writes depend on the existing tabledata rights (Manager cannot DELETE).
- Via the API, final-status confirmations default to Yes, so Lost and Disposed apply without a prompt.
### Fixed
- None.
### Obsolete
- None.

Release notes: Other systems can now read and maintain equipment through a new Business Central API (v1.0, publisher miguelCarvalho, group equipment). You can list, create, change and delete equipment, and assign or return it with the assign and returnEquipment actions. The same business rules as in the app apply. Equipment Reader can only read; Equipment Manager can change but not delete.

Note: no event published, no upgrade code. The app compiles with CodeCop, UICop and AppSourceCop with no diagnostics from the new page (only the known manifest gaps of the demo app). CI (commit 9dc8102): the main app compiled with only the known AppSource manifest warnings; the test app compiled. The first HTTP-based tests failed in CI with HTTP 401 (the AL-Go container uses UserPassword authentication and Library - Graph Mgt sends no credentials), so they were replaced by table-level tests (plan Q3 fallback). The new table-level tests pass in CI (35 of 35). Not verified: API-layer behavior is checked manually in the sandbox and not done yet (GET and the OData enum filter, scenarios 1 and 2a/2b; PATCH of a read-only field at page level, scenario 11; URL and field naming; ETag; permissions, scenario 17); enum encoding `In_x0020_Maintenance`; Code[20] action parameter; the publisher `miguelCarvalho` assumption. At first AppSource release v1.0 becomes a frozen contract.

## FR-048 Automated Build Pipeline (version stays 29.0.0.0, no bump)
### Added
- `.AL-Go/settings.json`: `enableCodeCop`, `enableUICop` and `enableAppSourceCop` set to true (AppSourceCop was already on through the AppSource App type; now explicit). Analyzers run on the main app only.
- Feature doc docs/features/FR-048-automated-build-pipeline.md and contributor help docs/help/FR-048-automated-build-pipeline.md.
### Changed
- CI/CD, Pull Request Build, NextMajor and NextMinor now also run CodeCop and UICop. New warnings on the main app are possible; only errors fail the build.
### Fixed
- None.
### Obsolete
- None.

Release notes: None (build tooling only, no change for end users).

Note: no AL code, no tests added, no workflow YAML changed. Not verified: analyzer output in CI (needs a run after push), run history and branch protection, CreateRelease (never run; plan Q2 no). Artifact names are 1.0.<run>.0 while the .app is 29.0.x. `enableCodeAnalyzersOnTestApps` is not enabled (optional follow-up). Setting reference: https://aka.ms/ALGoSettings#enableappsourcecop

## FR-024 Document Attachments (version stays 29.0.0.0, no bump)
### Added
- Enum 50108 "EQM Attachment Category" (extensible: Other, Purchase Invoice, Maintenance Report, Warranty Certificate, User Manual, Delivery Note).
- TableExtension 50100 "EQM Document Attachment": field 50100 "EQM Attachment Category" on table 1173; PageExtension 50101 "EQM Doc. Attachment Details" shows it for equipment only.
- Codeunit 50118 "EQM Doc. Attachment Subscr." (internal): subscribes to `OnAfterTableHasNumberFieldPrimaryKey` and `OnAfterGetRefTable` of codeunit 1173 "Document Attachment Mgmt".
- Equipment Card (50101): "Attachments" FactBox and action "Attachments" (enabled once the equipment is saved).
- Test codeunit 50179 "EQM Doc. Attachment Tests" (12 tests, compiled, NOT run).
- Help article docs/help/FR-024-document-attachments.md.
### Changed
- Table 50100 "EQM Equipment": `OnDelete` deletes the attachments; new `OnRename` moves them to the new "No.".
- Permission sets: EQM - Reader gets Document Attachment R and execute on codeunit 50118; EQM - Manager gets Document Attachment RIMD. AboutText of the Equipment Card.
### Fixed
- None.
### Obsolete
- None.

Release notes: You can now attach files such as invoices, maintenance reports, warranty certificates, user manuals and delivery notes to a piece of equipment. The files appear in the Attachments FactBox on the Equipment Card. Choose Attachments to add files and set a category for each one. Attachments follow the equipment when you rename it and are deleted when you delete it.

Note: no upgrade code, no event published. The 12 tests are compiled but NOT run (no BC sandbox). Not verified: plan items V1-V4 (the two event hooks suffice, rename via `MoveAttachmentsWithinSameRecordType`, filter group of `OpenForRecRef`, Tenant Media rights) and the sandbox checks (upload, drill-down, FactBox count, Reader). Pre-existing open AppSource items: app.json / AppSourceCop AS0051, AS0052, AS0054, AS0084.

## FR-023 Equipment Images (version stays 29.0.0.0, no bump)
### Added
- Table 50100 "EQM Equipment": field 24 "Picture" (MediaSet); Picture added to fieldgroup Brick.
- Page 50122 "EQM Equipment Picture" (CardPart FactBox) with actions Take, Import, Export, Delete; shown first in the FactBoxes of the Equipment Card (50101) and Equipment List (50100).
- Codeunit 50117 "EQM Equipment Picture Mgt." (internal): set, import, take, export, delete.
- One picture per equipment: Import and Take replace the existing picture after confirmation, as Item Picture does. Supported files: JPG, JPEG, PNG, GIF, BMP, TIF, TIFF (checked by file extension). Equipment must be saved first.
- Test codeunit 50178 "EQM Equipment Picture Tests" (15 tests, passing in CI); `internalsVisibleTo` for the test app; test app depends on Library Assert; AL-Go CI now runs the test app.
- Help article docs/help/FR-023-equipment-images.md.
### Changed
- Permission set EQM - Reader: execute on page 50122 and codeunit 50117. AboutText of the Equipment Card.
### Fixed
- None.
### Obsolete
- None.

Release notes: Each piece of equipment can now have a picture, shown in the Picture FactBox on the Equipment Card and the Equipment List. Use Take, Import, Export and Delete to manage it. A new picture replaces the existing one after you confirm. Only one picture per equipment is supported.

Note: no upgrade code, no new event. Known gaps against issue #61 (user decision): multiple images per equipment (IM-R3) are not supported and picture types are not recorded. The tests run in AL-Go CI (15 in codeunit 50178 passed); media cleanup on delete (V2) is confirmed by them. Not verified (no automated Reader test; Permissions Mock did not lower rights in CI): Reader behavior, Reader export and Tenant Media access (V3), picture FactBox on Item List and Employee List (V4), upload, camera and download in a sandbox.

## NFR-005 Auditability (version stays 29.0.0.0, no bump)
### Added
- Enum 50107 "EQM Maintenance Log Action" (Registered, Changed, Posted); table 50108 "EQM Maintenance Log Entry" (append-only; modify, delete and rename always raise an error); codeunit 50116 "EQM Maintenance Log Mgt." (internal); page 50121 "EQM Maintenance Log Entries" (read-only list).
- Logging: a Registered entry when a maintenance record is registered, one Changed entry per changed field (Maintenance Date, Maintenance Type, Vendor No., Cost, Description, Performed By) with old and new value in XML format, and a Posted entry when it is posted. User ID and Logged At are stored.
- Action Log Entries on the Equipment Maintenance list and the Maintenance Record card. Permissions: EQM - Reader reads and executes; EQM - Manager has indirect insert. No role can delete records or log entries.
- Help article docs/help/NFR-005-auditability.md.
### Changed
- Table 50105 `OnInsert`/`OnModify` and codeunit 50109 `OnRun` call the log (no signature or event change). AboutText of pages 50113 and 50114.
### Fixed
- None.
### Obsolete
- None.

Release notes: Every maintenance record now has a permanent, read-only log of who registered, changed and posted it, and when, including the old and new value of each corrected field. Choose Log Entries on Equipment Maintenance or on the Maintenance Record card. Log entries cannot be changed or deleted.

Note: no upgrade code, no new event. Review: APPROVE. CodeCop and UICop compile clean. Automated tests are deferred (test ID 50177 reserved); sandbox checks are not run, including the Field Caption FlowField for non-SUPER users and the XML format of Maintenance Type. Not logged: planned-maintenance fields on equipment, code running with RunTrigger = false.

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
