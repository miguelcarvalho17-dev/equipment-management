# FR-059 User Documentation

## Purpose
Equipment Management has one help article for each feature, but no single guide for end users, functional consultants and administrators. This change adds a consolidated user guide in `docs/user-guide/` (issue #100). The guide describes the current behaviour as task-based pages, in one sidebar order. Each functional page links the per-feature help articles it was built from. The change is documentation only.

Status: implemented on branch `feature/FR-059-user-documentation`, not committed by al-docs, not merged. Plan: `docs/plans/FR-059-user-documentation.md` (status approved). Target: AppSource. App version stays 29.0.0.0 (unreleased, no bump). No `app/` change, no `app.json` change, no test change, no permission set change, no new event or procedure.

## Verification status
- **AL:** no AL change. The guide was written from the AL source in `app/src` (captions, ToolTips, page and report names) and from the help articles. No code was compiled for this change.
- **Tests:** none written and none run. Not verified: tests not executed locally.
- **Sandbox:** not run. Not verified in a Business Central sandbox. The steps, menu paths and Tell Me categories are not checked in a running client. The guide keeps the `TODO(verify)` markers of the source articles.
- **AppSource validation:** No separate AppSource validation ran.
- **repo_checks.py:** not run by al-docs. The main agent runs it after this change.
- **Plan Step 22 checks** (link check, object ID and EQM name grep, caption check, `app/` and `test/` diff): run by the developer. Their results are not restated here.

## Structure of the guide
The guide has 19 files. The section order follows a public third-party Business Central app documentation site supplied by the user (https://docs.bricklead.eu/en-us/apps/ins/). Only the structure is reused. No sentence is copied from that site, and the guide does not link to it.

| Order | File | Covers |
|---|---|---|
| 1 | `docs/user-guide/README.md` | Overview, who the guide is for, key concepts, contents |
| 2 | `docs/user-guide/getting-started.md` | Prerequisites, install, permission sets, role, language |
| 3 | `docs/user-guide/setup-and-configuration.md` | Equipment Setup, categories, features, demo data |
| 4 | `docs/user-guide/equipment-register.md` | Equipment, the equipment card, status, picture, notes, attachments |
| 5 | `docs/user-guide/assignments.md` | Assign, return, assignment history |
| 6 | `docs/user-guide/equipment-requests.md` | Requests, approval, assignment of requested equipment |
| 7 | `docs/user-guide/maintenance.md` | Maintenance records, posting, history, planning, costs |
| 8 | `docs/user-guide/warranty.md` | Warranty data, warranty status, warranty alerts |
| 9 | `docs/user-guide/dashboards-and-role-center.md` | Equipment Manager Role Center, dashboard, cues, charts |
| 10 | `docs/user-guide/reports.md` | The four Excel reports |
| 11 | `docs/user-guide/notifications-and-monitoring.md` | Notifications, daily jobs, error log, retention |
| 12 | `docs/user-guide/audit-and-change-tracking.md` | Audit trail, change log, maintenance log |
| 13 | `docs/user-guide/integration.md` | Integration event entries, Power Automate |
| 14 | `docs/user-guide/using-the-api.md` | APIs for integrators |
| 15 | `docs/user-guide/pages-and-ui-reference.md` | Pages, parts, reports and additions to standard pages |
| 16 | `docs/user-guide/advanced-scenarios.md` | Companies, large registers, languages, upgrades, telemetry |
| 17 | `docs/user-guide/troubleshooting-and-faq.md` | Common issues and questions |
| 18 | `docs/user-guide/security-and-permissions.md` | Permission sets, data protection |
| 19 | `docs/user-guide/releases.md` | Release notes for 29.0.0.0, grouped by area |

## Source map
Each guide page is built from the AL source first, then the newest help article that covers the topic, then older help articles. When sources disagree, the higher one wins. The list below names the help articles used.

| Guide page | Help articles used |
|---|---|
| getting-started.md | FR-001, FR-018, FR-036, FR-043, FR-055, FR-057, FR-066, NFR-002 |
| setup-and-configuration.md | FR-002, FR-018, FR-030, FR-042, FR-043, FR-066, NFR-004 |
| equipment-register.md | FR-001, FR-002, FR-003, FR-007, FR-008, FR-023, FR-024, FR-025, FR-037, FR-053, NFR-003 |
| assignments.md | FR-001, FR-004, FR-005, FR-006, NFR-003 |
| equipment-requests.md | FR-032, FR-033, FR-042 |
| maintenance.md | FR-010, FR-011, FR-012, FR-013, FR-019, FR-020, FR-056, NFR-005 |
| warranty.md | FR-014, FR-015, FR-016, FR-043 |
| dashboards-and-role-center.md | FR-009, FR-021, FR-022, FR-038, NFR-001 |
| reports.md | FR-039, FR-040, FR-041, FR-052 |
| notifications-and-monitoring.md | FR-017, FR-018, FR-051, FR-054, NFR-004 |
| audit-and-change-tracking.md | FR-034, FR-035, NFR-005 |
| integration.md | FR-029 (user-level facts only), FR-030, FR-031 |
| using-the-api.md | FR-026, FR-027, FR-028, FR-036 |
| pages-and-ui-reference.md | AL source (page types, `UsageCategory`, `part(`), the articles above |
| advanced-scenarios.md | FR-044 (upgrade, user level only), FR-042, FR-050, FR-053, FR-055, FR-056, NFR-001 |
| troubleshooting-and-faq.md | The help articles above and the AL labels of the error messages |
| security-and-permissions.md | FR-036, FR-051, FR-057, FR-058, NFR-002 |
| releases.md | `CHANGELOG.md` (release notes paragraphs) |

## Excluded contributor articles and FR-060
The guide leaves out the contributor content of these articles: FR-029 (business events for developers), FR-044 (internals), FR-045, FR-046, FR-047, FR-048, FR-049 and FR-061. Developer documentation is FR-060, which is not written yet. The guide names FR-060 only in the overview page.

## Maintaining the guide
- Each new FR updates the matching guide page and the release notes in `releases.md`.
- The per-feature help article stays the detailed record for that FR. The guide does not replace it.
- The guide follows the AL source. When a help article and the AL source disagree, the guide follows the source, and the help article is not edited.
- The al-docs agent instructions do not yet name `docs/user-guide/`. Changing the agent instructions is a configuration change for the user to decide.

## Page-to-article map (for phase 2)
Phase 2 uses this map for `ContextSensitiveHelpPage` on the pages. No AL change is made in phase 1. Object IDs are listed here only, not in the guide.

| AL object (name) | Guide slug |
|---|---|
| EQM Equipment List (page 50100) | equipment-register.md |
| EQM Equipment Card (page 50101) | equipment-register.md |
| EQM Equipment Picture (page 50122) | equipment-register.md |
| EQM Equipment Notes Part (page 50130) | equipment-register.md |
| EQM Equipment Notes (page 50131) | equipment-register.md |
| EQM Equipment FactBox (page 50111) | equipment-register.md |
| EQM Equipment Summary FactBox (page 50137) | equipment-register.md |
| EQM Equipment Stats. FactBox (page 50138) | equipment-register.md |
| EQM Attachment Count FactBox (page 50139) | equipment-register.md |
| EQM Equipment Categories (page 50102) | setup-and-configuration.md |
| EQM Equipment Setup (page 50103) | setup-and-configuration.md |
| EQM Equipment Features (page 50140) | setup-and-configuration.md |
| EQM Equipment Assignments (page 50104) | assignments.md |
| EQM Assignment History Part (page 50105) | assignments.md |
| EQM Assigned Equipment FactBox (page 50112) | assignments.md |
| EQM Maintenance Records (page 50113) | maintenance.md |
| EQM Maintenance Record Card (page 50114) | maintenance.md |
| EQM Maintenance FactBox (page 50115) | maintenance.md |
| EQM Maintenance History Part (page 50116) | maintenance.md |
| EQM Maintenance History (page 50117) | maintenance.md |
| EQM Warranty Alerts (page 50120) | warranty.md |
| EQM Equipment Cues (page 50106) | dashboards-and-role-center.md |
| EQM Equipment Dashboard (page 50109) | dashboards-and-role-center.md |
| EQM Equipment Manager RC (page 50110) | dashboards-and-role-center.md |
| EQM Equipment Category Chart (page 50107) | dashboards-and-role-center.md |
| EQM Equipment Status Chart (page 50108) | dashboards-and-role-center.md |
| EQM Equipment Cost Chart (page 50119) | dashboards-and-role-center.md |
| EQM Category Cost Chart (page 50118) | dashboards-and-role-center.md |
| EQM Equipment Register (report 50100) | reports.md |
| EQM Asset Utilization (report 50101) | reports.md |
| EQM Maint. Cost Analysis (report 50102) | reports.md |
| EQM Usage Analytics (report 50103) | reports.md |
| EQM Equipment Requests (page 50133) | equipment-requests.md |
| EQM Equipment Request Card (page 50134) | equipment-requests.md |
| EQM Request Decision (page 50135) | equipment-requests.md |
| EQM Maintenance Log Entries (page 50121) | audit-and-change-tracking.md |
| EQM Equipment Audit Trail (page 50136) | audit-and-change-tracking.md |
| EQM Integration Event Entries (page 50132) | integration.md |
| EQM Error Log (page 50141) | notifications-and-monitoring.md |
| EQM Equipment API (page 50123) | using-the-api.md |
| EQM Category API (page 50124) | using-the-api.md |
| EQM Assignment API (page 50125) | using-the-api.md |
| EQM Integration Event API (page 50126) | using-the-api.md |

## Open items
Phase 2 (publishing and help links):
- Decide where the guide is published. The user decides the host.
- Set `app.json` `help`, `contextSensitiveHelpUrl` and `supportedLocales`. These are on the stop list and need the user's decision.
- Add `ContextSensitiveHelpPage` to the pages and request pages, using the map above. This is an AL change.
- Decide whether the per-feature help articles are published too. The guide links to them with `../help/` links, and those links break if only `docs/user-guide/` is published.
- Add a markdown link check to `repo_checks.py`. In phase 1 the link check was a one-off check.
- AppSource marketing validation needs a public help link in `app.json` `help`. This is already open in `docs/TODO.md` (Marketplace properties).

Phase 3 (content and languages):
- Walk through every guide page in a sandbox and clear the `TODO(verify)` markers.
- Add screenshots. No sandbox was available, so none were captured.
- Translate the guide into pt-PT and es-ES.
- Decide on an assisted setup guide. It would be a new AL object. The guide states that none exists.

The sandbox checks for this change are listed in `docs/TODO.md`, section "FR-059 checks".

## Known minor findings (not fixed)
These were found in review and are left as they are in this change.
- `docs/user-guide/notifications-and-monitoring.md`, line 44: the text says that only the two 06:00 jobs retry up to 3 times. All three daily jobs try up to 3 times.
- `docs/user-guide/reports.md`: the sheet tab names in the Usage Analytics Excel layout have no spaces.
- `docs/user-guide/pages-and-ui-reference.md`, the Assignment Details row: the hosts column misses Equipment Maintenance and Maintenance History. Check the hosts against the AL page parts before fixing.
- `docs/user-guide/using-the-api.md`, line 128: the permission text omits Equipment Operator.

## Stale facts in older help articles (not edited)
The guide follows the AL source and the newest help article. These older articles contain facts that no longer match the app. They are left unedited, as the plan says.
- `docs/help/FR-001-equipment-registration.md`: lists three permission sets. FR-036 and FR-057 add API Consumer and Operator.
- `docs/help/FR-016-warranty-alerts.md`, `FR-032-equipment-request-process.md`, `FR-042-feature-management.md`, `FR-043-application-setup.md` and `FR-066-demo-data.md`: stale facts, found in review. The guide uses the current facts.
- `docs/help/FR-018-automated-background-processing.md` and `docs/help/NFR-004-automation.md`: stale job facts. The notifications page of the guide has the current job facts.
- `docs/help/FR-030-event-subscribers.md`: stale facts, found in review.
- Root `README.md`: the API path and the claim about several pictures per equipment are out of date. The guide says that equipment has one picture.

## Related
- Plan: `docs/plans/FR-059-user-documentation.md`
- User guide: `docs/user-guide/README.md`
- Help article: `docs/help/FR-059-user-documentation.md`
- Changelog: `CHANGELOG.md`, entry FR-059
- Open checks: `docs/TODO.md`, section "FR-059 checks"
