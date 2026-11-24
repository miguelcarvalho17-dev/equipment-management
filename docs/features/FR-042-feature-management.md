# FR-042 Feature Management

> **Sandbox verification (2026-11-24):** verified in a Business Central sandbox by the project owner; no defects were reported. The detailed results are not recorded here, so statements below that say "not verified" or carry `TODO(verify)` predate this run.

## Purpose
An administrator turns five optional features on or off for each company, on the Equipment Features page, without code changes (GitHub issue #83). The features are Equipment Images, Warranty Alerts, Approval Workflows, API Integration and Maintenance Planning. Each feature switches on its own. When a feature is off, its controls are hidden and its entry pages show an error. No data is deleted.

Status: implemented on branch `feature/FR-042-feature-management`, not committed, not merged. App version stays 29.0.0.0 (unreleased, no bump, no upgrade code, no install code, no app.json change, no new permission set). One new enum, one new table (one row per feature, per company), one new codeunit, one new list page, and changes to existing pages, codeunits and the three permission sets.

## Verification status
- **Build:** not recorded in this document. Before the pull request, confirm that `app/` and `test/` compile with 0 errors and 0 warnings.
- **Review:** not recorded in this document.
- **Tests: written, NOT executed.** Test codeunit 50198 "EQM Feature Mgt. Tests" (21 test procedures) is new. Test codeunit 50162 "EQM Role Permission Tests" has 1 new and 4 changed test procedures for the feature settings. Neither has been run locally (no command-line test runner, no sandbox). CI (AL-Go) result pending. Nothing here claims the tests pass.
- **AppSource validation:** no separate AppSource validation ran. The reviewer checked the AppSource rules (affix, captions, ToolTips, translations, no breaking change).
- **Not verified:** sandbox checks S1 to S10. See `docs/TODO.md`, section "FR-042 sandbox checks".

## The Equipment Features page
The page is a list. It shows one row per feature with three columns: Feature, Description and Enabled. Only Enabled can be changed, and only by a user with write permission (EQM - Administrator).

Rows are created the first time a user with write permission opens the page: one row per feature, Enabled set to true. Rows that already exist are not changed. A user without write permission sees the page read-only. Until an administrator has opened the page once, a read-only user sees an empty list.

**A feature without a row is enabled.** Existing tenants and new installs behave exactly as before until an administrator turns a feature off.

The page is found with Tell Me (Administration), from the Navigation area of Equipment Setup and from the Setup section of the Equipment Manager Role Center.

## What each feature hides when it is off

| Feature | Hidden when off | Error when the page is opened |
|---|---|---|
| Equipment Images | Picture FactBox on the Equipment Card and the Equipment List. | None. |
| Warranty Alerts | Warranty Alerts action on the Equipment Card. Open Warranty Alerts tile on the dashboard and Role Center. Warranty Alert Job field on Equipment Setup. Warranty notifications (card and Role Center) are not sent. The daily job creates no alerts. | Warranty Alerts page. |
| Approval Workflows | Equipment Requests action on the Employee Card. Requests Pending Approval tile on the dashboard and Role Center. | Equipment Requests and Equipment Request Card pages. |
| API Integration | Integration group and Integration Events Enabled field on Equipment Setup. Integration Event Entries action on Equipment Setup. No integration event entries are written. | The four equipment API pages (equipment, category, assignment and integration event). Integration Event Entries page. |
| Maintenance Planning | Planned Maintenance group on the Equipment Card (Last Maintenance Date, Maintenance Frequency (Months), Next Maintenance Date). Next Maintenance Date column on the Equipment List. Next Maintenance Date field on the Maintenance FactBox. Planned Maintenance tiles on the dashboard and Role Center (two tiles). | None. |

The Role Center actions Equipment Requests and Warranty Alerts are **not** hidden. See Design decisions.

The error for a page that is off is an ErrorInfo with the text "The <feature> feature is turned off in this company. To use it, ask an administrator to turn it on in the Equipment Features page." It has one action, Open Equipment Features, which opens the page.

## Rules
- **A missing row means enabled.** Nothing changes until an administrator turns a feature off.
- **Off hides; it never deletes.** Pictures, warranty alerts, equipment requests and integration event entries stay in the database and appear again when the feature is turned on.
- **Per company.** A feature switched off in one company does not change another company. The table is stored per company, like Equipment Setup.
- **Changes apply the next time a page is opened.** The visibility of controls is set when a page opens. A page that is already open keeps its state until it is opened again.
- **Each feature switches independently.** Turning off one feature leaves the others on.
- **Warranty Alerts off:** warranty end dates and the warranty status stay visible. The warranty-expired business event is still raised by the daily job, because it is not part of this feature.
- **Approval Workflows off:** the whole equipment request process is hidden. A request must be approved before equipment is assigned, so requests are not completed without approval. Requests that exist are kept.
- **API Integration off:** the four API pages return an error when opened, and no integration event entries are written. The integration event settings are hidden.
- **Maintenance Planning off:** the next maintenance date is still calculated. Only the display is hidden.
- **Fail open.** When a user cannot read the feature table, every feature is treated as on. Feature activation hides user interface; it is not a security boundary. Permission sets are.
- **Only the Administrator changes features.** Manager and Reader can read them. The API Consumer can read them, because the API pages check the feature in the API session.

## Objects
| Type | ID | Name | Change |
|---|---|---|---|
| Enum | 50112 | EQM Feature | New. Five values: Equipment Images, Warranty Alerts, Approval Workflows, API Integration, Maintenance Planning. Not extensible. Internal. |
| Table | 50114 | EQM Feature Setup | New. Per company. One row per feature, with the Enabled field (initial value true). Internal. Not stored by install or upgrade code. |
| Codeunit | 50138 | EQM Feature Mgt. | New. Internal. Procedures IsEnabled, CheckEnabled, InitializeFeatures, SetFeatureEnabled and GetFeatureDescription. |
| Page (List) | 50140 | EQM Equipment Features | New. Tell Me, Administration. Only Enabled is editable. |
| Page | 50101 | EQM Equipment Card | Changed. Picture part, Planned Maintenance group and its three fields, Warranty Alerts action. |
| Page | 50100 | EQM Equipment List | Changed. Picture part and Next Maintenance Date column. |
| Page | 50115 | EQM Maintenance FactBox | Changed. Next Maintenance Date field. |
| Page | 50106 | EQM Equipment Cues | Changed. Requests Pending Approval, Open Warranty Alerts, Planned Maintenance group. The dashboard and the Role Center embed this part. |
| Page | 50110 | EQM Equipment Manager RC | Changed. New action Equipment Features in the Setup section. The Role Center page cannot have triggers, so no other gate is set here. |
| Page | 50103 | EQM Equipment Setup | Changed. Integration group, Integration Events Enabled, Warranty Alert Job, Integration Event Entries action hidden when off. New action Equipment Features in the Navigation area. |
| PageExtension | 50100 | EQM Employee Card | Changed. Equipment Requests action hidden when Approval Workflows is off. |
| Page | 50120 | EQM Warranty Alerts | Changed. Error on open when Warranty Alerts is off. |
| Page | 50133 | EQM Equipment Requests | Changed. Error on open when Approval Workflows is off. |
| Page | 50134 | EQM Equipment Request Card | Changed. Error on open when Approval Workflows is off. |
| Page | 50132 | EQM Integration Event Entries | Changed. Error on open when API Integration is off. |
| Page (API) | 50123, 50124, 50125, 50126 | EQM Equipment, Category, Assignment and Integration Event API | Changed. An OnOpenPage trigger only. No field or property changed. |
| Codeunit | 50112 | EQM Notification Mgt. | Changed. Warranty notifications are not sent when Warranty Alerts is off. |
| Codeunit | 50111 | EQM Warranty Alert Job | Changed. No alerts are created when Warranty Alerts is off. The warranty-expired event is still raised. |
| Codeunit | 50122 | EQM Integration Event Mgt. | Changed. IsEnabled also checks API Integration. Same signature. |
| Permission set | 50100 | EQM - Reader | Changed. Read on the feature table; execute on the table, the page and the codeunit. |
| Permission set | 50102 | EQM - Administrator | Changed. Read, insert, modify and delete on the feature table. |
| Permission set | 50104 | EQM - API Consumer | Changed. Read and execute on the feature table; execute on the codeunit. No page. |
| Codeunit (test) | 50198 | EQM Feature Mgt. Tests | New, not executed. 21 test procedures. |
| Codeunit (test) | 50162 | EQM Role Permission Tests | Changed, not executed. 1 new and 4 changed test procedures. |
| XLIFF | – | Equipment Management.g.xlf | Regenerated by the build. |

No event is published or subscribed to. No base application object is changed.

## Permissions
- **EQM - Reader:** read on the feature table; execute on the table, the Equipment Features page and the feature codeunit. Equipment Manager and Equipment Administrator inherit it.
- **EQM - Administrator:** read, insert, modify and delete on the feature table. Only this role can change a feature.
- **EQM - API Consumer:** read on the feature table; execute on the table and the feature codeunit. It has no access to the Equipment Features page, and the test 50162 checks this.
- **EQM - Manager:** no new entries. It inherits Reader.

## Design decisions
- **A new table keyed by feature, with "missing row means enabled".** Boolean fields on the existing setup table would read false on existing rows, so every feature would turn off on upgrade. Upgrade code would be needed, and that is on the stop list. The new table also keeps the setup table free for the centralized setup page (FR-043).
- **Visibility variables and an actionable error, not application areas.** Custom application areas would hide pages from Tell Me, but they need install and upgrade code to be safe for existing tenants. That is phase 2.
- **Approval Workflows off hides the whole process.** The other option, letting requests skip approval, is a new business rule. It is phase 3, if wanted.
- **API Integration off also stops the integration event outbox.** The outbox does not grow while its API is closed.
- **Warranty Alerts off stops the daily job from creating alerts.** New alerts would fire the Power Automate "warranty expiring" flow for a feature the user has hidden.
- **Only the Next Maintenance Date column is gated on the list.** The other two maintenance columns are hidden by default, and a variable would make them visible by default when the feature is on.
- **Fail open when the feature table cannot be read.** See Rules.
- **Role Center actions are not gated.** A Role Center page cannot have triggers (compiler error AL0378), so the Visible variables cannot be set there. The actions Equipment Requests and Warranty Alerts stay visible. Opening one shows the feature error. The tiles on the Role Center are hidden, because they are on the embedded cue part.
- **Entry points:** Tell Me, the Navigation area of Equipment Setup and the Setup section of the Equipment Manager Role Center.

## Translations
New captions, ToolTips, labels, the AboutTitle and AboutText, and the search terms are in `app/Translations/Equipment Management.g.xlf`, regenerated by the build. Never edit it by hand.

## Known limitations
- **Tell Me still lists pages of a feature that is off** (for example Warranty Alerts and Equipment Requests). Opening one shows the error. Hiding them from Tell Me needs custom application areas (phase 2, needs approval).
- **The Role Center actions Equipment Requests and Warranty Alerts stay visible** when their feature is off. Opening one shows the error.
- **Pages that are already open keep their state** until they are opened again.
- **Read-only users see an empty list** on Equipment Features until an administrator has opened the page once.
- **Two administrators opening Equipment Features for the first time at the same moment** can cause a duplicate key error in the second session, and the page closes. Opening the page again works. This is accepted.
- **The HTTP status of an API call while API Integration is off** is not known yet. Sandbox check S4 records it.
- **Not part of these five features:** Power Automate business events, document attachments (including image attachments), warranty information fields and warranty status tiles, and overdue maintenance monitoring. They stay on as before.

## Test status
- **Codeunit 50198 "EQM Feature Mgt. Tests" (21 test procedures):** the feature codeunit (no rows means enabled, features switch independently, a feature can be turned on again, initialization keeps existing choices, the error for a disabled feature), the page (an administrator turns a feature off), the visibility of controls on the Equipment Card, the Equipment List, the Cues, the Setup page and the Employee Card, the entry pages that refuse to open, and that no integration event entries are written while API Integration is off. Written; not executed locally. CI result pending.
- **Codeunit 50162 "EQM Role Permission Tests":** 4 changed tests (the API Consumer matrices now include the feature table and feature codeunit) and 1 new test (only the Administrator can change features). Not executed locally. CI result pending.
- Existing tests that open gated pages are expected to pass, because no row means enabled. CI confirms this. If one fails with "feature is turned off", a test left a row behind.
- Sandbox checks S1 to S10 are open (`docs/TODO.md`, section "FR-042 sandbox checks").

## Related
- Help article: `docs/help/FR-042-feature-management.md`
- Changelog: `CHANGELOG.md`, entry FR-042
- Plan: `docs/plans/FR-042-feature-management.md`
- Sandbox checks: `docs/TODO.md`, section "FR-042 sandbox checks"
- Maintenance planning fields: `docs/features/FR-019-planned-maintenance.md`
- Warranty alerts: `docs/features/FR-016-warranty-alerts.md`
- Equipment request process: `docs/features/FR-032-equipment-request-process.md`
