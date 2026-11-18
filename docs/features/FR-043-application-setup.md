# FR-043 Application Setup

## Purpose
The Equipment Setup page (GitHub issue #84) becomes the central place where an administrator configures Equipment Management for each company. It gets two groups of settings:
- **Defaults:** Default Warranty Alert Days and Default Maintenance Frequency (Months).
- **Features:** three switches, Enable Notifications, Enable Equipment Requests and Enable APIs.

Two of the switches reuse FR-042 features, so the setup page and the Equipment Features page always show and change the same setting. No setting is stored twice.

Status: implemented on branch `feature/FR-043-application-setup`, not committed, not merged. App version stays 29.0.0.0 (unreleased, no bump, no upgrade code, no install code, no app.json change, no new permission set). Two new fields on table 50102, one new value on enum 50112, one new test codeunit. No new object in the app.

## Verification status
- **Build:** not recorded in this document. Before the pull request, confirm that `app/` and `test/` compile with 0 errors and 0 warnings.
- **Review:** APPROVED.
- **Tests: written, NOT executed.** Test codeunit 50199 "EQM Application Setup Tests" (20 test procedures) is new. It has not been run locally (no command-line test runner, no sandbox). CI (AL-Go) result pending. Nothing here claims the tests pass.
- **AppSource validation:** no separate AppSource validation ran. The reviewer checked the AppSource rules (affix, captions, ToolTips, translations, no breaking change: two new fields and one new enum value only).
- **Not verified:** sandbox checks S1 to S9. See `docs/TODO.md`, section "FR-043 sandbox checks".

## The Equipment Setup page
The page has these groups, in this order: Numbering, Defaults, Features, Integration and Background Monitoring.

**Defaults**
- **Default Warranty Alert Days:** visible only when Warranty Alerts is on. Allowed values are 1 to 90. The default is 90.
- **Default Maintenance Frequency (Months):** visible only when Maintenance Planning is on. Allowed values are 0 to 120. The default is 0, which means no default.

**Features**
- **Enable Notifications:** the Notifications feature on the Equipment Features page.
- **Enable Equipment Requests:** the Approval Workflows feature on the Equipment Features page.
- **Enable APIs:** the API Integration feature on the Equipment Features page.

Only a user with write permission on the setup (EQM - Administrator) can change the page. Other users see it read-only.

## Rules
- **Range checks.** A value outside the allowed range is rejected with a message that names the field, the allowed range and the value entered.
- **Default Warranty Alert Days controls when warranty alerts start.** Alerts are created 90, 60 and 30 days before the warranty end date, as far as these fall within the number of days. For example, with 30 only the 30-day alert is created.
- **Blank means 90 days.** A setup created before this change can have the field blank. The app then uses 90 days, as before. A new setup starts with 90. Entering 0 is rejected, so the field cannot be blanked again.
- **Lowering the alert days keeps open alerts.** Open warranty alerts outside the new window are not cancelled.
- **The maintenance default is applied on the Equipment Card only.** When a user starts a new equipment record on the card, the record gets the default frequency if it is greater than 0. The user can change or clear it before saving. Equipment that already exists is not changed.
- **The maintenance default is not applied to API, code or configuration package inserts.** Nor is it applied to equipment created by import.
- **The maintenance default is applied even when Maintenance Planning is off.** The field is then hidden on the card, so the value is set without being visible.
- **Notifications off suppresses the equipment notifications for the whole company.** When Enable Notifications is off, the equipment card, maintenance record card, Role Center and "returned from maintenance" notifications are not sent to any user in the company. Each user's My Notifications setting still works as before when the feature is on.
- **Notifications off does not affect** business events, integration events, job queue jobs or telemetry.
- **The three switches apply the next time a page is opened.** A page that is already open keeps its state until it is opened again.
- **Settings are per company.**

## Objects
| Type | ID | Name | Change |
|---|---|---|---|
| Enum | 50112 | EQM Feature | Changed. New value 5 Notifications. Existing values are not changed. |
| Codeunit | 50138 | EQM Feature Mgt. | Changed. Description for the Notifications feature. |
| Page (List) | 50140 | EQM Equipment Features | Changed. About text only. Lists six features. |
| Table | 50102 | EQM Equipment Setup | Changed. New fields 6 "Default Warranty Alert Days" and 7 "Default Maint. Freq. (Months)", with range checks. |
| Codeunit | 50110 | EQM Warranty Alert Mgt. | Changed. Alerts start at the Default Warranty Alert Days. |
| Table | 50100 | EQM Equipment | Changed. Internal procedure that applies the maintenance default to a new record. |
| Page | 50101 | EQM Equipment Card | Changed. The maintenance default is applied when a new record starts. |
| Codeunit | 50112 | EQM Notification Mgt. | Changed. The four equipment notifications are not sent when Notifications is off. |
| Page | 50103 | EQM Equipment Setup | Changed. Groups Defaults and Features. |
| Codeunit (test) | 50199 | EQM Application Setup Tests | New, not executed. 20 test procedures. |
| XLIFF | - | Equipment Management.g.xlf | Regenerated by the build. |

No event is published or subscribed to. No base application object is changed. Permission sets do not change.

## Permissions
- **EQM - Reader:** unchanged. Sees the setup page read-only.
- **EQM - Administrator:** unchanged. Can change the defaults and the three switches.
- **EQM - API Consumer:** unchanged. Has no access to the setup page.

## Design decisions
- **The three switches reuse the FR-042 feature table.** Enable Equipment Requests and Enable APIs are the existing Approval Workflows and API Integration features. New Boolean fields would be a second source of truth, and new Booleans read false on existing rows.
- **Enable Notifications is a new feature.** It is one more row in the feature table, and a missing row means enabled. Existing companies keep their notifications.
- **Default Warranty Alert Days is the alert window, not the Expiring Soon threshold.** The threshold (30 days) drives the status and the tiles and is not changed.
- **The maintenance default is applied in the card, so the user sees it and can clear it.** A table trigger would also cover the API and code inserts, but then a deliberate 0 could not be saved.
- **Range checks are explicit.** They give a message that says what is allowed.

## Translations
New captions, ToolTips, labels, the About text and the search terms are in `app/Translations/Equipment Management.g.xlf`, regenerated by the build. Never edit it by hand.

## Known limitations
- **Enable Equipment Requests and Enable APIs hide and show what FR-042 describes.** Their effects, including the Role Center actions that stay visible when a feature is off, are listed in `docs/help/FR-042-feature-management.md`.
- **Default Warranty Alert Days can be blank** in setups created before this change. The app uses 90 days.
- **Equipment created through the API, by code or by import does not get the maintenance default.**
- **Pages that are already open keep their state** until they are opened again.

## Test status
- **Codeunit 50199 "EQM Application Setup Tests" (20 test procedures):** the alert window (a 30-day window creates no alert outside it, a blank setup uses 90 days, the range is enforced), the maintenance default (applied to a new record, not applied when 0, not overwritten, applied on the card, not stored by an insert), the setup page switches (each switch changes its feature, the page hides the default fields when their feature is off), and Notifications (no notification when off, one when on, the feature has a description).
- Written; not executed locally. CI result pending.
- Sandbox checks S1 to S9 are open (`docs/TODO.md`, section "FR-043 sandbox checks").

## Related
- Help article: `docs/help/FR-043-application-setup.md`
- Changelog: `CHANGELOG.md`, entry FR-043
- Plan: `docs/plans/FR-043-application-setup.md`
- Sandbox checks: `docs/TODO.md`, section "FR-043 sandbox checks"
- Equipment features: `docs/features/FR-042-feature-management.md`
- Warranty alerts: `docs/features/FR-016-warranty-alerts.md`
- Notifications: `docs/features/FR-017-equipment-notifications.md`
- Planned maintenance: `docs/features/FR-019-planned-maintenance.md`
