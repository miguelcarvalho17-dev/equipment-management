# FR-038 Enhanced Role Center

> **Sandbox verification (2026-11-24):** verified in a Business Central sandbox by the project owner; no defects were reported. The detailed results are not recorded here, so statements below that say "not verified" or carry `TODO(verify)` predate this run.

## Purpose
Four operational KPI tiles on the equipment cue part (GitHub issue #76): **Requests Pending Approval**, **Warranties Expiring This Month**, **Open Maintenance Activities** and **Total Assets Value**. They show the approval queue, the warranties that end before the end of the month, the open maintenance records and the purchase cost of the equipment in use, on the Equipment Manager Role Center and the Equipment Dashboard, without opening other pages. The existing tiles stay as they are.

Status: implemented on branch `feature/FR-038-enhanced-role-center`, not committed, not merged. App version stays 29.0.0.0 (unreleased, no bump, no upgrade code). No new object, no event, no published procedure, no API page, no permission set change. The four tiles are FlowFields on the existing temporary cue table.

## Verification status
- **Build:** `app/` and `test/` compile with 0 errors (verified by the reviewer with `alc`). The warning count was not reported separately.
- **Review:** APPROVED. No blocker, no major finding. One minor finding is open: see "Test status".
- **Tests: written, compile, NOT executed.** Test codeunit 50161 "EQM Dashboard Tests" (12 test procedures) has not been run. There is no command-line test runner and no sandbox run yet. Nothing here claims the tests pass.
- **AppSource validation:** no separate AppSource validation ran. The reviewer checked the AppSource rules.
- **Not verified:** sandbox checks S1 to S3. See `docs/TODO.md`, section "FR-038 sandbox checks".

## What the cue part shows
The **Operational Indicators** group sits directly after the **Equipment** group and before the **Warranty** group. It is on the Equipment Manager Role Center and the Equipment Dashboard, because both host the cue part. The layout of those two pages does not change.

| Tile | Counts | Drill-down |
|---|---|---|
| Requests Pending Approval | Equipment requests with status Pending Approval | Equipment Requests, filtered to Pending Approval |
| Warranties Expiring This Month | Equipment whose warranty ends from today up to and including the last day of the current month | Equipment List, with the same filter |
| Open Maintenance Activities | Maintenance records with status Open | Maintenance Records, filtered to Open |
| Total Assets Value | Sum of the purchase cost of equipment that is not Lost or Disposed, in local currency | Equipment List, with the same filter |

The Refresh action of the dashboard and the refresh on activation of the Role Center also update the four tiles.

## Rules
- **Requests Pending Approval** counts only Pending Approval. Open requests have not been sent for approval yet, so they are not counted.
- **Warranties Expiring This Month** uses today's real date, not the work date. The window is today to the last day of the current month, both ends included. Warranties that ended earlier in the month are not counted here; they are Expired.
- **Warranties Expiring This Month** excludes Lost and Disposed equipment and equipment without a warranty end date.
- **Open Maintenance Activities** counts records, not equipment. It counts records of every equipment status, so an open record of equipment that is later set to Lost or Disposed is still counted.
- **Total Assets Value** is the sum of the purchase cost only. Equipment without a purchase cost counts as zero. Depreciation is not taken into account. Lost and Disposed equipment is excluded. The amount is in local currency.
- Statuses added by an extension are included in **Total Assets Value** and in **Warranties Expiring This Month**, because only Lost and Disposed are excluded.

## Changed filter
`SetWarrantyCueFilters` also sets the window of **Warranties Expiring This Month**. The procedure signature is unchanged. The cue page calls it with today's date when it opens, so the window starts at the current date. Passing 0D means today.

## Relation to the other warranty tiles
- **Warranties Expiring This Month** overlaps the **Warranties Expiring in 30 Days** tile by design. The first is a calendar window, the second a rolling 30-day window. Neither tile changes.
- The new tile does not replace **Expired Warranties**. A warranty that ended earlier this month stays in Expired only.

## Objects
| Type | ID | Name | Change |
|---|---|---|---|
| Table (Temporary, Internal) | 50104 | EQM Equipment Cue | Five fields added: 16 "Total Assets Value", 35 "Warranties Expiring This Month", 44 "Warranty Month Filter" (FlowFilter), 54 "Open Maintenance Activities", 60 "Requests Pending Approval" |
| Codeunit (Internal) | 50107 | EQM Dashboard Mgt. | `SetWarrantyCueFilters` sets the month filter as well; doc comment updated |
| Page (CardPart) | 50106 | EQM Equipment Cues | New cuegroup "Operational Indicators" with four tiles |
| Page (Card) | 50109 | EQM Equipment Dashboard | About text describes the new tiles |
| XLIFF | – | Equipment Management.g.xlf | Regenerated by the build |
| Test codeunit | 50161 | EQM Dashboard Tests | New, not executed |

Field IDs in table 50104 are local to that table. The new fields follow the existing blocks.

The page and control names are part of the public layout from the first AppSource release. The table and codeunit are Internal.

## Permissions
- No permission set changed. **EQM - Reader** already has read on Equipment Request, Maintenance Record and Equipment. **EQM - Manager** and **EQM - Administrator** include Reader rights.
- A user without read on Equipment Request or Maintenance Record gets a permission error when the cue calculates. Every EQM permission set grants read on both.

## Design decisions
- New FlowFields on the existing temporary cue table, and tiles on the shared cue part 50106. Both hosts already embed that part, and FlowFields give drill-down without code.
- One new cuegroup for the four tiles, after the Equipment group. The tiles are not spread over the existing groups.
- Total Assets Value excludes Lost and Disposed, the same rule as the warranty and planned maintenance tiles.
- Warranties Expiring This Month is a calendar window that starts today. Warranties that already expired are not counted again.
- Open Maintenance Activities counts records, because the enum has only Open and Posted. The existing "Equipment in Maintenance" tile counts equipment.
- Test codeunit 50161 is used because it was reserved for this cue part in the earlier dashboard plan.

## Translations
New captions and ToolTips, and the changed About text, are in `app/Translations/Equipment Management.g.xlf`, regenerated by the build. Never edit it by hand.

## Known limitations
- A cue page left open past midnight keeps the old window until it is reopened. Refresh does not reset it.
- Total Assets Value is a plain sum, with no key on the purchase cost. Volumes are expected to be small. A later, non-breaking key can follow if performance requires it.
- Total Assets Value is in local currency only. There is no currency conversion and no depreciation.
- Styling of the new tiles is not done. For example, a tile is not red when requests are pending.

## Test status
- Build: `app/` and `test/` compile with 0 errors (reviewer, `alc`).
- Tests: test codeunit 50161 has 12 test procedures. Not executed (no CLI runner, no sandbox). The scenarios cover the pending approval count, the warranty window (both boundaries, outside dates, Lost and Disposed, last day of the month, 0D), open and posted maintenance, the value of in-use equipment and the excluded statuses, and the cue page wiring.
- Reviewer MINOR, open: in the page test, the page's Total Assets Value is rounded, while the expected value from the cue record is not. The reviewer suggested comparing with `Round(..., 0.01)`. Not changed here; no code was edited by the documenter.
- Open sandbox checks: S1 to S3 (see `docs/TODO.md`).

## Related
- Help article: `docs/help/FR-038-enhanced-role-center.md`
- Changelog: `CHANGELOG.md`, entry FR-038
- Plan: `docs/plans/FR-038-enhanced-role-center.md`
- Sandbox checks: `docs/TODO.md`, section "FR-038 sandbox checks"
- Earlier warranty and dashboard docs: `docs/features/FR-022-warranty-dashboard.md`, `docs/features/FR-021-maintenance-dashboard.md`
