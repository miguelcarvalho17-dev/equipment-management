# FR-016 Warranty Alerts

## Purpose
When a warranty is about to end, the app creates an alert 90, 60 and 30 days before the Warranty End Date, so users can plan a renewal, schedule a replacement or raise a warranty claim in time. Alerts are stored records. A daily job queue entry (or a manager, with the Generate Alerts action) creates them; users see them in the Warranty Alerts list, in a dashboard tile and from the Equipment Card, and acknowledge them when they have acted.

Status: describes the code as implemented (uncommitted changes on branch `feature/FR-016-warranty-alerts`). The code compiles with the compiler, CodeCop, UICop and AppSourceCop with no diagnostics in source files; only the known app.json diagnostics AS0051, AS0052, AS0054, AS0084 and the AS0092 warning remain (they pre-exist). **No automated tests (deferred, plan decision Q12; test codeunit 50170 reserved, nothing written). Nothing is verified in a sandbox; sandbox checks WA-SB1 to WA-SB12 are open.** App version stays 29.0.0.0. No upgrade codeunit, no standard events subscribed, no published events, no events report.

## Objects
| Type | ID | Name | Change |
|---|---|---|---|
| Enum | 50105 | EQM Warranty Alert Interval | New. Values 30 "30 Days", 60 "60 Days", 90 "90 Days". `Extensible = false`. |
| Enum | 50106 | EQM Warranty Alert Status | New. Values 0 Open, 1 Acknowledged, 2 Cancelled. `Extensible = false`. |
| Table | 50107 | EQM Warranty Alert | New, `Access = Public`. One row per fired interval. Fields below. |
| Page | 50120 | EQM Warranty Alerts | New list. Actions Acknowledge, Generate Alerts, Equipment; views Open, Acknowledged, Cancelled. |
| Codeunit | 50110 | EQM Warranty Alert Mgt. | New, `Access = Internal`. Generate, cancel, acknowledge, interval rule, telemetry. |
| Codeunit | 50111 | EQM Warranty Alert Job | New, public, `TableNo = "Job Queue Entry"`, `OnRun` only. Run by the job queue. |
| Table | 50100 | EQM Equipment | New internal procedure `GetWarrantyDaysRemaining(ReferenceDate)`. |
| Table | 50104 | EQM Equipment Cue (temporary) | FlowField 32 "Open Warranty Alerts" (count of Open alerts). |
| Page | 50106 | EQM Equipment Cues | Third tile "Open Warranty Alerts" in cue group Warranty, drills down to page 50120. |
| Page | 50101 | EQM Equipment Card | Navigation action "Warranty Alerts" (enabled when the card is saved) plus promoted actionref; opens page 50120 filtered to the equipment. |
| Page | 50110 | EQM Equipment Manager RC | Embedding action "Warranty Alerts". |
| Page | 50109 | EQM Equipment Dashboard | AboutText and search terms only. |
| PermissionSet | 50100 / 50101 | EQM - Reader / EQM - Manager | See Permissions. |

### Table 50107 "EQM Warranty Alert"
| ID | Name | Type | Meaning |
|---|---|---|---|
| 1 | Entry No. | Integer, AutoIncrement | Alert number. |
| 2 | Equipment No. | Code[20] | Relation to "EQM Equipment". |
| 3 | Equipment Description | FlowField | Lookup of the equipment description. Blank when the equipment was deleted. |
| 4 | Warranty Provider | FlowField | Lookup of the equipment's Warranty Provider. |
| 5 | Alert Interval | Enum 50105 | Interval that fired. |
| 6 | Warranty End Date | Date | Snapshot of the equipment's end date when the alert was created. |
| 7 | Alert Date | Date | Reference date of the run that created the alert. |
| 8 | Status | Enum 50106 | Open, Acknowledged or Cancelled. |
| 9 | Acknowledged By | Code[50] | User ID; `EndUserIdentifiableInformation`. |
| 10 | Acknowledged At | DateTime | Set on acknowledge. |
| 11 | Cancelled At | DateTime | Set on cancel. |

All fields are not editable. Keys: PK (Entry No.), "Equipment No.", "Warranty End Date", "Alert Interval", and Status, "Warranty End Date". The table has no triggers and no procedures. Table classification is `CustomerContent`.

## Behavior
Reference date R = `Today()` (not the work date). Days remaining = Warranty End Date - R (`GetWarrantyDaysRemaining`).

| Days remaining | Interval created |
|---|---|
| less than 0 (warranty expired) | none |
| 0 to 30 | 30 Days |
| 31 to 60 | 60 Days |
| 61 to 90 | 90 Days |
| more than 90 | none |

`GenerateAlerts(ReferenceDate, IsScheduled, var CreatedCount, var CancelledCount)` in codeunit 50110 does, in order:
1. Reference date 0D becomes `Today()`. `LockTable` on the alert table.
2. **Cancel stale alerts.** Each Open alert is set to Cancelled (with Cancelled At) when its equipment no longer exists, the equipment's Warranty End Date differs from the alert's (changed or cleared), or the equipment is Lost or Disposed. An Open alert whose warranty has simply expired (date unchanged) stays Open.
3. **Create due alerts.** For equipment with a Warranty End Date from R to R + 90, skipping Lost and Disposed, and only when `CalcWarrantyStatus(R)` is Active or Expiring Soon: find the due interval and create an alert unless an Open or Acknowledged alert exists for the same Equipment No., Warranty End Date and Alert Interval. Cancelled alerts do not block.
4. One telemetry signal (below).

Consequences:
- **Once per interval.** Running twice on a day creates nothing new.
- **Catch-up (plan Q2).** Only the most urgent due interval is created: equipment with 45 days left gets the 60-day alert only; the 90-day alert is never created late.
- **Re-arm.** A changed end date cancels the old Open alerts on the next run and the new date has no alerts yet, so all intervals can fire again. Changing the date back also re-arms, unless an alert for that date was Acknowledged.
- **Start date is ignored.** The equipment record is only read, never modified; no table 50100 event is raised.
- No `Message`, `Confirm` or `Commit` in `GenerateAlerts`, so it runs in the job queue. Alerts only appear when a run happens (job or Generate Alerts).

`AcknowledgeAlerts(var WarrantyAlert)` adds Status = Open to the filter, raises the error 'The selected warranty alerts are already acknowledged or cancelled.' when nothing is open, otherwise sets Status Acknowledged, Acknowledged By (user ID) and Acknowledged At on each record, restores the caller's Status filter and returns the count.

### Warranty Alerts page (50120)
Sorted by Status, Warranty End Date; read-only (no insert, modify, delete). Page variable "Days Remaining" = alert end date - today (negative after the end date). Acknowledged At, Cancelled At and Entry No. are hidden by default. Acknowledge uses the selected rows; Generate Alerts runs `GenerateAlerts(Today(), false, ...)` and shows 'N warranty alerts were created and M alerts that no longer apply were cancelled.' Both actions are enabled only when `Rec.WritePermission()` is true (Manager, Administrator).

### Telemetry
`Session.LogMessage` event ID `EQM0001`, message 'Warranty alerts generated.', `Verbosity::Normal`, `DataClassification::SystemMetadata`, `TelemetryScope::All`, once per run. Dimensions: AlertsCreated, AlertsCancelled, ReferenceDate (format 9), Trigger (`JobQueue` or `Manual`). No equipment numbers or user names. `applicationInsightsConnectionString` is still missing in app.json (see docs/TODO.md); with scope All the signal reaches the environment's own Application Insights.

## Setup (job queue entry)
No code creates the job queue entry (plan Q6). An administrator creates it:
1. Open **Job Queue Entries** > **New**.
2. Object Type to Run = Codeunit, Object ID to Run = 50111 (EQM Warranty Alert Job).
3. Set it to recurring, all days, with a starting time (the plan suggests 06:00).
4. Set the status to Ready.

The entry runs as the user who sets it to Ready; that user needs EQM - Manager (plan Q7). Object ID 50111 is stored in customers' entries and must not change after release. Field-level steps in the Job Queue Entry page are from the plan, not checked in a sandbox (WA-SB5): TODO(verify).

## Extending (events)
None published (plan Q10). Table 50107 is `Access = Public`, so a partner can subscribe to its standard `OnAfterInsertEvent` to react to new alerts. No standard events are subscribed. Codeunit 50110 and `GetWarrantyDaysRemaining` are `internal`; codeunit 50111 is the only public codeunit and has no procedures.

## Permissions
| Permission set | Change |
|---|---|
| 50100 EQM - Reader | `tabledata "EQM Warranty Alert" = R`, `table` X, `page "EQM Warranty Alerts"` X, `codeunit "EQM Warranty Alert Mgt."` X, `codeunit "EQM Warranty Alert Job"` X. |
| 50101 EQM - Manager | `tabledata "EQM Warranty Alert" = RIM`. |
| 50102 EQM - Administrator | No change (includes Manager). |

| Function | Reader | Manager | Administrator |
|---|---|---|---|
| See alerts, tile, card action | yes | yes | yes |
| Acknowledge, Generate Alerts | no (disabled) | yes | yes |
| Run the job queue entry (as its user) | no | yes | yes |
| Delete alerts | no | no | no |

From code reading, not a sandbox run (WA-SB8, WA-SB9). Renaming equipment renames "Equipment No." in table 50107 and needs M on it, which Manager has.

## Translations
`app/Translations/Equipment Management.g.xlf` is regenerated by the build and shows as modified. Never edit it by hand. TODO(verify) that locked telemetry labels are not translation units (WA-SB1).

## Upgrade and compatibility
New stored table, no change to existing stored fields, no upgrade codeunit (nothing released). After publishing, the table is empty; the first run creates the due alert for every warranty ending within 90 days. Public surface that becomes permanent at release: enums 50105 and 50106 (values and ordinals), table 50107 fields, codeunit 50111 and its ID. No existing rule, control or tile was changed.

## Known limitations
- Alerts are only as fresh as the last run. Without a job queue entry nothing appears until a manager chooses Generate Alerts.
- `Today()` in a job queue session can differ from the user's date; an alert can appear a day early or late.
- Between an end date change and the next run the old alert stays Open and the new one does not exist yet.
- Changing the end date back to a value whose alert was Acknowledged does not fire that interval again.
- `LockTable` reduces but does not fully prevent duplicates when two runs start at the same time on an empty table (a comment in the code says so).
- No notification, no email, no retention or delete of alerts, intervals fixed at 90/60/30.
- Alerts of deleted equipment stay as Cancelled history with a blank description.

## Test status
No test objects; test codeunit 50170 "EQM Warranty Alert Tests" is reserved. Scenarios WA1 to WA37 in docs/plans/FR-016-warranty-alerts.md are a reference only. **Sandbox checks WA-SB1 to WA-SB12 are not run.**

TODO(verify) in a sandbox: generation and counts (WA-SB2, SB3), acknowledge (SB4), job queue run and the date used by the job session (SB5), tile, drill-down and card action including the image (SB6, SB7), Reader and Manager permissions and rename (SB8, SB9), Tell Me and teaching tips (SB10), telemetry (SB11), deleted equipment (SB12).

## Discrepancies plan vs code
- None in behavior. Differences in structure only: two extra local helpers (`IsAlertStale`, `RestoreStatusFilter`) and the telemetry dimension names are held in locked labels; a comment on `LockTable` states the residual duplicate risk.
- The plan's updates to FR-015, FR-009 and FR-008 feature and help documents and to docs/TODO.md were not made in this step; TODO.
