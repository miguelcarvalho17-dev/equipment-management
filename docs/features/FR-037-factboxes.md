# FR-037 FactBoxes

> **Sandbox verification (2026-11-24):** verified in a Business Central sandbox by the project owner; no defects were reported. The detailed results are not recorded here, so statements below that say "not verified" or carry `TODO(verify)` predate this run.

## Purpose
Three read-only FactBoxes on the Equipment Card (GitHub issue #75): **Equipment Summary**, **Equipment Statistics** and **Attachment Summary**. They show the status, the assignment, the warranty, the assignment and maintenance figures, and the attachment counts of one piece of equipment without opening other pages. The existing FactBoxes stay on the card.

Status: implemented on branch `feature/FR-037-factboxes`, not committed, not merged. App version stays 29.0.0.0 (unreleased, no bump, no upgrade code). No table, field, event, published procedure or API page changed.

## Verification status
- **Build:** the app and the test app were reported to compile with 0 errors and 0 warnings in the VS Code build (CodeCop, UICop, AppSourceCop). This was not independently verified in the agent session.
- **Review:** APPROVED (round 2).
- **Tests: written, compile, NOT executed.** Test codeunit "EQM Equipment FactBox Tests" (16 test procedures) has not been run. There is no command-line test runner and no sandbox run yet. Nothing here claims the tests pass.
- **AppSource validation:** no separate AppSource validation ran. The reviewer checked the AppSource rules.
- **Not verified:** sandbox checks S1 to S3. See `docs/TODO.md`, section "FR-037 sandbox checks".

## What the Equipment Card shows
The three parts sit directly after the **Picture** FactBox, in this order.

| FactBox | Field | Shows | Drill-down |
|---|---|---|---|
| Equipment Summary | Status | Status, styled as on the card | None |
| | Assigned Employee No. | Employee number of the current assignment | Opens the Employee Card |
| | Assigned Employee Name | Full name of the assigned employee | None |
| | Warranty Status | Active, Expiring Soon, Expired, or blank | None |
| Equipment Statistics | Assignment Count | All assignment entries, active and closed | Opens Equipment Assignments for the equipment |
| | Maintenance Count | Posted maintenance records | Opens Maintenance History |
| | Total Maintenance Cost | Total cost of posted maintenance | Opens Maintenance History |
| Attachment Summary | Document Count | Attached files whose file type is not Image | Opens Document Attachment Details |
| | Image Count | Attached files whose file type is Image | Opens Document Attachment Details |

## Rules
- **Warranty Status** is calculated from the warranty end date and today's date. It is not stored. Rules are the same as on the card: Expiring Soon means the warranty ends within 30 days. See the FR-015 feature doc.
- **Assigned Employee Name** is blank when the equipment is not assigned, and when the user cannot read employees.
- **Assignment Count** includes the current assignment.
- **Maintenance Count** and **Total Maintenance Cost** include posted maintenance only. Open maintenance records are shown in the Maintenance FactBox, not in these numbers. There is no date filter.
- **Document Count** and **Image Count** add up to all attachments of the equipment. The equipment picture is not an attachment and is not counted. It is shown in the Picture FactBox.
- Only attachments of this equipment are counted. Rows of other equipment, or of other tables with the same number, are not counted.
- The attachment counts use the standard file type of Business Central. Which files are recognized as images is set by Business Central. See the help article.
- The attachment counts refresh after the Document Attachment Details page closes.
- On a new card that is not saved yet, all new FactBoxes show 0 or blank. No error is raised.
- If the user cannot read attachments, the attachment counts show 0.

## Objects
| Type | Name | Change |
|---|---|---|
| Page (CardPart) | EQM Equipment Summary FactBox | New |
| Page (CardPart) | EQM Equipment Stats. FactBox | New |
| Page (CardPart) | EQM Attachment Count FactBox | New |
| Codeunit (internal) | EQM Equipment Attachment Mgt. | New. Counts and shows the attachments of equipment. Nothing is written |
| Page | EQM Equipment Card | Changed. Three parts added. About text extended |
| PermissionSet | EQM - Reader | Changed. Execute on the three pages and the codeunit |
| Test codeunit | EQM Equipment FactBox Tests | New, not executed |

The new page names are part of the public contract from the first AppSource release. They cannot be removed or renamed after that.

## Permissions
- **EQM - Reader** can execute the three FactBox pages and the attachment codeunit. **EQM - Manager** and **EQM - Administrator** get them through inclusion.
- **EQM - API Consumer** is unchanged. It has no UI pages, so it gets none of the new pages.
- The attachment counts use the read permission on Document Attachment. Reader has it.

## Design decisions
- Three new FactBox pages, not extensions of the existing FactBoxes. The issue names three FactBoxes with their own content.
- The existing Assignment Details, Maintenance and standard Attachments FactBoxes stay visible. Hiding them is a possible follow-up.
- Image and document counts use the standard file type of Document Attachment, not the EQM attachment category. The category has no image value.
- Maintenance Count uses posted records, so the count and the total cost describe the same set.
- The attachment logic is in an internal codeunit, not in new fields on the equipment table. This keeps the published table and API unchanged.

## Translations
New captions and ToolTips are in `app/Translations/Equipment Management.g.xlf`, regenerated by the build.

## Known limitations
- Which file extensions Business Central treats as images is not verified in this session. Sandbox check S1 covers real uploads.
- The counts do not respond to a date filter.
- The Equipment Card now shows more FactBoxes. Hiding the older ones is not done.

## Related
- Help article: `docs/help/FR-037-factboxes.md`
- Changelog: `CHANGELOG.md`, entry FR-037
- Plan: `docs/plans/FR-037-factboxes.md`
- Sandbox checks: `docs/TODO.md`, section "FR-037 sandbox checks"
