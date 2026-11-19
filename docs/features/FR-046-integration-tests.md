# FR-046 Integration Tests

## Purpose
Adds integration-level tests for four business processes: equipment assignment, maintenance, equipment request approval and notifications. Each test runs several business steps in one transaction and checks the effects across modules: assignment history, audit trail, integration outbox, maintenance log, equipment requests and notifications. The earlier unit tests check one rule at a time. These tests check that the steps agree with each other. The tests use the test app in `test/`. The app itself does not change.

Status: implemented on branch `feature/FR-046-integration-tests`, not committed, not merged. App version stays 29.0.0.0. No change to `app/`, `app.json`, permission sets, captions or translations. Plan: `docs/plans/FR-046-integration-tests.md` (status approved).

## Verification status
- **Tests: written, NOT executed locally.** 21 test procedures in one test codeunit. There is no command-line test runner and no sandbox here. Not verified: tests not executed locally, CI result pending. Nothing here claims the tests pass.
- **Review:** APPROVED.
- **AppSource validation:** No separate AppSource validation ran. The reviewer checked the AppSource rules.
- **Assumption:** `GuiAllowed()` is true in the AL-Go test session. The tests that answer confirm dialogs and the notification tests depend on it. See the risks below.

## Test codeunit

| ID | Name | Tests | Flows |
|---|---|---|---|
| 50158 | EQM Process Integration Tests | 21 | Assignment 4, Maintenance 5, Approval 4, Notification 8 |

The ID 50158 was reserved for FR-006 (assignment history tracking). FR-046 uses it. The assignment history scenarios are covered by this codeunit and by the existing tests in 50156 and 50182.

Conventions: `TestPermissions = Disabled`, `[TransactionModel(TransactionModel::AutoRollback)]` on every test, `[SCENARIO]/[GIVEN]/[WHEN]/[THEN]` comments, and at most one `asserterror` as the last action. Test data uses Locked labels with the prefix `EQMPIT` and a counter, and `Random()`. Thresholds come from the app getters (`GetMaintenanceOverdueDays`, `GetLongestIntervalDays`).

## Test scenarios

**Equipment Assignment Flow**

| ID | Test procedure | Kind | Checks |
|---|---|---|---|
| AF1 | AssignmentLifecycleKeepsHistoryAuditAndOutboxInStep | Positive | Create, assign, return and reassign. The history has two entries, one Closed and one Active. The audit sequence and the outbox sequence match the steps. |
| AF2 | MaintenanceTakesEquipmentBackAndBlocksReassignment | Negative | Maintenance registered on assigned equipment takes it back. Reassignment fails with the open maintenance error. |
| AF3 | EmployeeWithAssignedEquipmentCannotBeDeleted | Negative | Deleting an employee who has assigned equipment fails with the guard error. |
| AF4 | EmployeeCanBeDeletedAfterTheEquipmentIsReturned | Positive | After the return, the employee can be deleted. The closed history entry is kept. |

**Maintenance Flow**

| ID | Test procedure | Kind | Checks |
|---|---|---|---|
| MF1 | AssignedEquipmentGoesThroughMaintenanceAndIsReassigned | Positive | Assigned equipment goes to maintenance, the record is posted with the user posting path, the equipment is Available and it is reassigned. The history and audit trail agree. |
| MF2 | CorrectionBeforePostingIsLoggedAndReachesTheHistory | Positive | A cost correction before posting is in the maintenance log (Registered, Changed, Posted) and the history shows the corrected cost. |
| MF3 | DecliningThePostingConfirmationChangesNothing | Negative | Answering No to the posting confirmation posts nothing. The record stays open and no notification is sent. |
| MF4 | EquipmentIsAssignableOnlyAfterTheLastOpenRecordIsPosted | Positive | With two open records, the equipment stays In Maintenance after the first post. It is assignable after the second post. |
| MF5 | PostingOneOfTwoRecordsStillBlocksAssignment | Negative | With two open records and one posted, assignment fails with the open maintenance error. |

**Approval Flow**

| ID | Test procedure | Kind | Checks |
|---|---|---|---|
| AP1 | RequestIsApprovedAndCompletedWithEquipmentAssigned | Positive | A request is numbered from the series, sent, approved by a different user and completed with equipment. The equipment, history, audit trail and outbox show the assignment. |
| AP2 | ReturningEquipmentKeepsTheRequestCompleted | Positive | Returning the equipment later does not change the completed request. |
| AP3 | RejectedRequestCannotGetEquipment | Negative | A rejected request cannot get equipment. The error names the request. |
| AP4 | ApprovedRequestCannotGetEquipmentThatWentIntoMaintenance | Negative | Equipment that went into maintenance after approval cannot be assigned to the request. |

**Notification Flow**

| ID | Test procedure | Kind | Checks |
|---|---|---|---|
| NF1 | PostingTheLastRecordSendsTheReturnedNotification | Positive | Posting the last open record sends the returned-from-maintenance notification for the equipment. |
| NF2 | NoReturnedNotificationWhileOtherMaintenanceIsOpen | Negative | Posting one of two records sends no returned notification. |
| NF3 | UserWhoSwitchedOffTheNotificationGetsNone | Negative | A user who switched off the notification in My Notifications gets none. The record is still posted. |
| NF4 | GeneratedWarrantyAlertShowsAWarrantyNotification | Positive | A generated warranty alert shows the warranty notification. |
| NF5 | AcknowledgedAlertShowsNoWarrantyNotification | Negative | An acknowledged alert shows no warranty notification. |
| NF6 | OverdueMaintenanceShowsAnOverdueNotification | Positive | An open record older than the overdue limit shows the overdue notification. |
| NF7 | MaintenanceOpenExactlyTheOverdueDaysIsNotOverdue | Negative | An open record exactly at the overdue limit is not overdue. Boundary test. |
| NF8 | NotificationsFeatureOffSuppressesEquipmentNotifications | Negative | With the Notifications feature off, no equipment notification is sent, even when a warranty alert and an overdue record exist. |

## Assumptions and risks
- `GuiAllowed()` is true in CI. If it is false, the ConfirmHandler tests and NF1, NF4 and NF6 fail or see no notification. FR-045 and test 50199 share this dependency. Check the CI log for test 50199 `NotificationIsSentWhenNotificationsAreOn`.
- The approval tests act as a different approver by setting "Sent for Approval By" to another user. The self-approval check stays active. This is the technique used in test codeunit 50189.
- Two tests use `Today()` as the reference date, because the notification code uses `Today()`. NF7 could flip if the test runs across midnight. This is accepted as negligible.
- The exact sequences in AF1 and MF2 fail if a later feature adds audit or log entries. This is intended.
- AF3 and AF4 rely on the standard Employee delete trigger, and on the guard in codeunit 50103.
- `GenerateAlerts` also processes other equipment in the company. The warranty tests filter on the test's own equipment or on the notification Id.

## Not covered (later phases)
- TestPage UI flows (Equipment Card and Request Card actions).
- Role Center summary notifications and the maintenance card notification.
- Notification action handlers and `ShowMaintenanceRecordNotification`.
- Job queue runs (warranty job, overdue check).
- API pages and Power Automate flows.

## Test status
- Test codeunit 50158 (21 tests): written; not executed locally. Not verified: tests not executed locally, CI result pending.
- Open items are in `docs/TODO.md`, section "FR-046 checks".

## Related
- Help article: `docs/help/FR-046-integration-tests.md`
- Changelog: `CHANGELOG.md`, entry FR-046
- Plan: `docs/plans/FR-046-integration-tests.md`
- Unit tests: `docs/features/FR-045-automated-unit-tests.md`
- Assignment history: `docs/features/FR-006-assignment-history-tracking.md`
- Approval workflow: `docs/features/FR-033-approval-workflow.md`
- Notifications: `docs/features/FR-017-equipment-notifications.md`
