# NFR-004 Automation

> Status: **DRAFT, waiting for user approval.**
> Source: GitHub issue #44 (milestone V2). Branch: `feature/NFR-004-automation`.
> Scope (chosen by the user): **verification only. No AL change, no new object, no table or permission change, no version bump, no upgrade logic.** Existing tests are not affected.
> No events report: nothing is subscribed or published, no standard behavior is touched. al-event-finder is not needed.
> Workflow: planner (this file) -> human approves -> documenter (feature doc, TODO, CHANGELOG). developer, reviewer, build, tester and appsource-validator steps are skipped because no code changes (re-run them if the user picks gap work from "Gaps" below).

## Goal
Show that the requirement "System monitoring processes shall be fully automated through Business Central Job Queue processing" is met by the code merged for FR-018, and record exactly what is and is not verified.

### Requirement restated
- A-R1 Monitoring processes run without a user starting them.
- A-R2 The automation uses Business Central Job Queue, not custom schedulers.

## Approach and tradeoff
- Chosen: **trace NFR-004 to FR-018 and document it; change no code.** Tradeoff: nothing can regress and no tests are touched, but the gaps below stay open and the requirement stays "met in code, not verified in a sandbox".
- Rejected: **new AL for the gaps now.** It would touch codeunits 50104, 50108 or 50115 and their (deferred) tests, for edge cases the user has not asked for. It is a separate decision (see Q1).
- Rejected: **duplicating FR-018 as a new job.** Two entries for the same codeunit would run the monitoring twice.

## Traceability
| Requirement | Where it is met | Object |
|---|---|---|
| A-R1 warranty monitoring runs daily | Recurring entry (`<1D>`, 06:00, 3 attempts, category EQM) running the warranty alert job | Codeunit 50111 "EQM Warranty Alert Job" |
| A-R1 maintenance monitoring runs daily | Same, running the overdue check | Codeunit 50114 "EQM Maintenance Monitor Job" |
| A-R1 no manual start | Entries are created on install (`TryEnsureMonitoringJobs`, codeunit 50104), on first setup in a new company (Equipment Setup `OnOpenPage`), and by the Schedule Monitoring Jobs action | Codeunits 50104, 50115; page 50103 |
| A-R2 Job Queue only | Entries are created with the standard `ScheduleRecurrentJobQueueEntryWithRunDateFormula`; no TaskScheduler job of its own | Codeunit 50115 |
| Visibility | Job status fields and Monitoring Job Queue Entries action on Equipment Setup; telemetry EQM0001 to EQM0004 | Page 50103 |

## Gaps found while reading the code (not fixed here)
1. **Existing entries are never repaired.** `JobExists` matches any entry for the codeunit whatever its status, so an entry that is On Hold, in Error or Finished counts as "existing" and monitoring silently stops. Equipment Setup shows the status, but nothing alerts anyone.
2. **Companies skipped at install.** When a write transaction is already open (multi-company install), scheduling is skipped (telemetry EQM0004, reason WriteTransaction). Those companies get entries only on first Equipment Setup open by an Administrator, or via the action.
3. **No job for notification generation** (FR-018 Q2 default: notifications are page-triggered; background sessions cannot show them).
4. **First run may be the next 06:00**, not immediate (standard procedure behavior; BG-SB4).

## Objects
None new or changed.

## Data model and upgrade impact
None.

## Events
None subscribed or published.

## Permissions
No change. (Administrator already has indirect `rim` on Job Queue Entry from FR-018.)

## Compatibility
No change to any public object, signature or event. No AppSource breaking-change risk.

## Test scenarios
No automated tests (none added, none changed; existing tests unaffected). Verification is by the FR-018 sandbox checks, which become the NFR-004 acceptance list:
1. BG-SB1 build with CodeCop, UICop and AppSourceCop: no warnings.
2. BG-SB2 (mandatory) existing company: Schedule Monitoring Jobs creates both entries; none duplicated on a second run.
3. BG-SB3 new sandbox install: both entries and category EQM exist in every company (multi-company check).
4. BG-SB4 (mandatory) first run time recorded; the entries then run daily without user action.
5. BG-SB5 a failing job shows Error with a log entry and does not block the other entry.
6. BG-SB6 new company, non-SUPER Administrator: setup and entries created.
7. BG-SB8 telemetry EQM0001 to EQM0004 appear.

## Risks and open questions
- **Q1 (default: no gap work).** Do you want any of the gaps 1 to 3 planned as a follow-up increment? Gap 1 is the most relevant to "fully automated": a stopped entry ends the automation unnoticed. Taking it would change codeunit 50115 (and test codeunit 50172 stays deferred).
- **Q2 (default: yes).** Record the BG-SB checks as one "NFR-004 sandbox checks" section in `docs/TODO.md` that points to FR-018's IDs rather than copying them.
- R1 Claiming "fully automated" before BG-SB2 and BG-SB4 run is unverified; the feature doc will say "met in code, not verified in a sandbox".

## Deliverables after approval
- `docs/features/NFR-004-automation.md` (the traceability table, gaps, verification status).
- `docs/help/NFR-004-automation.md` (AppSource mode): short admin note on where to see the jobs and what to do when one is On Hold or in Error.
- `docs/TODO.md`: NFR-004 sandbox checks section.
- `CHANGELOG.md`: "NFR-004 Automation (version stays 29.0.0.0, no bump)", Added: documentation only; Changed/Fixed/Obsolete: none.
