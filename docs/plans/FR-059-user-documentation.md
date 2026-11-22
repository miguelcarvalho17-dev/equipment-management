# FR-059 User Documentation — Plan

> Request (verbatim): FR-059 User Documentation. Use this as reference to build documentation. https://docs.bricklead.eu/en-us/apps/ins/
> Status: **approved**

## Request
Write a single, consolidated end-user guide for Equipment Management (issue #100, FR-059). It follows the section order of the reference site the user named, reuses the existing per-feature help articles and links to them, and adds the FR-059 feature doc, help article and CHANGELOG entry that `repo_checks.py` requires. This is documentation only: no AL, no `app.json`, no test changes.
Target: AppSource

Note: the issue #100 text could not be read by the planner; the only requirement text in the repo is README.md line 130: "FR-059 User Documentation ... Complete user help and developer documentation". FR-060 owns the developer half, so this plan covers end users, functional consultants and administrators.

## Definition of done
- [ ] `docs/user-guide/` holds the 19 files in Steps 1-19. Each follows the page template in Step 0 (H1, intro, "In this article" list, H2/H3 task sections, numbered imperative steps, bold UI names, "What to know", "Related", Previous/Next footer).
- [ ] The guide's sections are in this order: Overview, Getting started, Setup and configuration, one page per functional area, Integration, Using the API, Pages and UI reference, Advanced scenarios, Troubleshooting and FAQ, Security and permissions, Releases.
- [ ] Every functional page ends with a "Related" list that links the per-feature `docs/help/FR-0NN-*.md` articles it was built from, using relative links.
- [ ] Every relative link in `docs/user-guide/*.md` and in the FR-059 docs resolves to an existing file (check in Step 22).
- [ ] Every page, report and role name in bold in `pages-and-ui-reference.md` exists as a `Caption` in `app/src` (check in Step 22).
- [ ] No object IDs and no AL object names (`EQM ...`) appear in `docs/user-guide/`.
- [ ] No sentence is copied from the reference site. Only its section structure is reused.
- [ ] Any statement taken from a help article that carries `TODO(verify)` keeps the `TODO(verify)` marker in the guide.
- [ ] `git diff --stat origin/main -- app/ test/ .github/ .AL-Go/` is empty.
- [ ] `docs/features/FR-059-user-documentation.md`, `docs/help/FR-059-user-documentation.md` and a `## FR-059 User Documentation (version stays 29.0.0.0, no bump)` CHANGELOG entry exist.
- [ ] `docs/plans/FR-059-user-documentation.md` has `> Status: **approved**` in its first 12 lines.
- [ ] `python3 .github/scripts/repo_checks.py --base origin/main --branch feature/FR-059-user-documentation` passes (the main agent runs it).
- [ ] `README.md` links to the guide (one added line). `docs/TODO.md` has an "FR-059 checks" section.
- [ ] Reports say: "No AL change, no tests. Not verified in a Business Central sandbox. No separate AppSource validation ran."

## Out of scope
- Developer and contributor documentation: FR-060. The guide leaves out the content of these articles and only names FR-060: FR-029 (business events for developers), FR-044 internals, FR-045, FR-046, FR-047, FR-048, FR-049, FR-061.
- `app.json` `help`, `contextSensitiveHelpUrl`, `supportedLocales` (stop list), and `ContextSensitiveHelpPage` on pages and request pages (AL change). Phase 2.
- Publishing the guide to a website. Phase 2.
- Screenshots. There is no sandbox, so they cannot be captured. Phase 3.
- Translating the guide into pt-PT or es-ES. Phase 3.
- An assisted setup guide (new AL object). Phase 3. The guide states that none exists.
- Editing the existing `docs/help/FR-0NN-*.md`, `docs/features/*` or `docs/plans/*` files. They stay as they are.
- Fixing the stale "V4 progress" text in README.md (no drive-by edits).
- Any change to `repo_checks.py`, CI or the agent/skill files.

Later phases:
- Phase 2: publish the guide on a host, ask the user (stop list) for `app.json` `help`/`contextSensitiveHelpUrl`/`supportedLocales`, add `ContextSensitiveHelpPage` per the page-to-article map in the feature doc, and add a markdown link check as a new `repo_checks.py` check.
- Phase 3: sandbox screenshots after each step, pt-PT/es-ES versions of the guide, an optional assisted setup guide.

## Objects
| Type | ID | Name | New/Changed | File |
|---|---|---|---|---|
| none | n/a | No AL objects are created or changed. `al_getnextobjectid` is not needed. | n/a | n/a |

Documentation files (all new unless marked Changed):

| File | New/Changed | Written by |
|---|---|---|
| docs/user-guide/README.md | New | developer |
| docs/user-guide/getting-started.md | New | developer |
| docs/user-guide/setup-and-configuration.md | New | developer |
| docs/user-guide/equipment-register.md | New | developer |
| docs/user-guide/assignments.md | New | developer |
| docs/user-guide/equipment-requests.md | New | developer |
| docs/user-guide/maintenance.md | New | developer |
| docs/user-guide/warranty.md | New | developer |
| docs/user-guide/dashboards-and-role-center.md | New | developer |
| docs/user-guide/reports.md | New | developer |
| docs/user-guide/notifications-and-monitoring.md | New | developer |
| docs/user-guide/audit-and-change-tracking.md | New | developer |
| docs/user-guide/integration.md | New | developer |
| docs/user-guide/using-the-api.md | New | developer |
| docs/user-guide/pages-and-ui-reference.md | New | developer |
| docs/user-guide/advanced-scenarios.md | New | developer |
| docs/user-guide/troubleshooting-and-faq.md | New | developer |
| docs/user-guide/security-and-permissions.md | New | developer |
| docs/user-guide/releases.md | New | developer |
| README.md | Changed (one line) | developer |
| docs/TODO.md | Changed (new section at end) | developer |
| docs/features/FR-059-user-documentation.md | New | al-docs |
| docs/help/FR-059-user-documentation.md | New | al-docs |
| CHANGELOG.md | Changed (new top entry) | al-docs |
| docs/plans/FR-059-user-documentation.md | New | main agent (this plan, house header) |

## Events and standard symbols
| Symbol | Exact signature | Verified with al_symbolsearch |
|---|---|---|
| none | No AL code, so no standard events, procedures or fields are used. | n/a. `al_symbolsearch` also returned "No projects are loaded". Object names and captions in this plan come from a grep of `app/src`. |

## Steps
**Step 0 — rules that apply to every guide page (read before Step 1)**

Page template (one `.md` per page):
```
# <Title in sentence case>

<1-3 sentences: what the page covers and who it is for.>

**In this article**
- [<H2 1>](#anchor)
- ...

## <Task, e.g. "Create equipment">
1. Choose the search icon, enter **<Page caption>**, and choose the related link.
2. <Imperative step with **bold UI names**.>

### Fields            (only where Step N asks for a field table)
| Field | Description |
|---|---|

## What to know
- <Caveats and limits as plain sentences.>

## Related
- [<guide page>](<file>.md)
- Feature article: [<H1 of help article>](../help/FR-0NN-<slug>.md)
- Learn: [<title>](https://learn.microsoft.com/...)   (standard BC behaviour only)

---
Previous: [<title>](<file>.md) | Next: [<title>](<file>.md)
```
Content rules:
- **Sources, in this order of trust:** (1) the AL source in `app/src` for captions, field names, ToolTips, action names and what is visible by default; (2) the newest FR help article that covers the topic; (3) older help articles. When sources disagree, the higher one wins. Example: `docs/help/FR-001-equipment-registration.md` lists only three permission sets, while FR-036 and FR-057 add API Consumer and Operator. List each conflict in the developer report under "Conflicts found". Do not edit the older article.
- **Field tables:** list the fields in page order. The Description is the field's `ToolTip` text from AL (on the page field, or on the table field when the page has none), unchanged, or shortened only by dropping a leading "Specifies ". Leave out fields with `Visible = false`.
- Do not invent error messages. To quote an error, copy the text of the `Err` label from `app/src`. Otherwise describe the error in plain words.
- No object IDs, no `EQM` object names, no AL code in the guide. User-facing captions only.
- English. Second person, imperative, present tense, short sentences, formal tone. Use "Choose", not "Click". Sentence-case headings. Bold for UI names. No marketing language. Follow the Microsoft Learn authoring guide (References).
- Do not copy any sentence from the reference site, and do not link it from the guide. Ignore its Getting Started copy error.
- Keep `TODO(verify)` markers from the source article for any statement you reuse.
- For standard BC behaviour (Tell Me, Extension Management, permission sets, Job Queue, retention policies, Data Classification Worksheet, Change Log, Power Automate), link Learn and do not re-explain it.
- No images. Do not add placeholder image links.
- Previous/Next follow the order of Steps 1-19. README has only Next. Releases has only Previous.

1. `docs/user-guide/README.md` — Overview and contents. H1 "Equipment Management user guide". Status note under the H1: "Applies to Equipment Management 29.0.0.0, which is not released yet. The steps are not verified in a Business Central sandbox." Sections: "What the app does" (rewrite the problem/solution from root README.md for end users), "Who this guide is for" (end users, managers, administrators, integrators; developers go to FR-060 developer documentation, not written yet, plain text, no link), "Key concepts" (equipment, category, status values from enum "EQM Equipment Status" captions, assignment, maintenance record vs. posted history, warranty alert, equipment request), "Contents" (links to the 18 other pages, in order, one line each). Why: landing page and sidebar of the guide.
2. `getting-started.md` — Prerequisites: Business Central online version 29.0 or later (from `app.json` `application`, no release-wave name). To install, the user needs the D365 Extension Mgt. user group or the EXTEND. MGT. - ADMIN permission set (Learn link). Install: from Marketplace once listed, or upload the .app in **Extension Management**. Add a sentence that the app is not listed yet. What the install creates: the setup, the EQUIP number series and the starter categories (from `docs/help/FR-001-equipment-registration.md` and `app/src/Setup/EQMDefaultData.Codeunit.al`). Add the monitoring jobs only if `docs/help/FR-018-automated-background-processing.md` says the install schedules them; otherwise point to **Schedule Monitoring Jobs**. Assign permission sets (short table of the five roles with a link to security-and-permissions.md). Choose the **Equipment Manager** role (profile caption) in My Settings. State that there is no assisted setup guide and that you configure the app on **Equipment Setup**. Optional: **Create Demo Data** (FR-066). Change language (FR-055: English, Portuguese (Portugal), Spanish (Spain)). "Next steps" links. Sources: FR-001, FR-036, FR-057, FR-043, FR-055, FR-066, NFR-002 help.
3. `setup-and-configuration.md` — "Equipment Setup": a Field|Description table for every visible field of `app/src/Setup/EQMEquipmentSetup.Page.al`, grouped by its FastTabs (Numbering, Defaults, Features, Integration, Background monitoring), plus a table of the page actions (Schedule Monitoring Jobs, Create Demo Data, Delete Demo Data, Monitoring Job Queue Entries, Error Log, Integration Event Entries, Equipment Features), using the action captions and ToolTips from the page. "Equipment categories": create, deactivate, delete rules (FR-002). "Equipment features": turn features on and off, with what each switch hides (FR-042, FR-043; enum "EQM Feature" captions). "Demo data" (FR-066). "Requirements" (permission needed: Administrator). Sources: FR-002, FR-042, FR-043, FR-066, FR-018, NFR-004, FR-030 help.
4. `equipment-register.md` — Create equipment, the Equipment Card (Field|Description table per FastTab from `app/src/Equipment/EQMEquipmentCard.Page.al`), status management and final statuses, find and filter the list, picture, notes, attachments and attachment category, the card FactBoxes, delete rules. Sources: FR-001, FR-002, FR-003, FR-007, FR-008, FR-023, FR-024, FR-025, FR-037, NFR-003, FR-053 help.
5. `assignments.md` — Assign to an employee, return, assignment history, Employee Card actions and the Assigned Equipment FactBox, employee delete guard. Sources: FR-004, FR-005, FR-006, NFR-003, FR-001 help.
6. `equipment-requests.md` — Create a request (Field|Description table from `app/src/Request/EQMEquipmentRequestCard.Page.al`), the request statuses (enum "EQM Request Status" captions), send for approval, approve or reject (no self-approval), assign equipment, what happens when the Approval Workflows feature is off. Sources: FR-032, FR-033, FR-042 help.
7. `maintenance.md` — Register a maintenance record (Field|Description table from `app/src/Maintenance/EQMMaintenanceRecordCard.Page.al`), post it, maintenance history, the effect on equipment status, planned maintenance and the next date, overdue highlighting, cost tracking, the maintenance log and its regional value display. Sources: FR-010, FR-011, FR-012, FR-013, FR-019, FR-020, NFR-005, FR-056 help.
8. `warranty.md` — Warranty fields on the card, warranty status, warranty monitoring, the Warranty Alerts page (acknowledge, generate), alert days from setup. Sources: FR-014, FR-015, FR-016, FR-043 help.
9. `dashboards-and-role-center.md` — The Equipment Manager Role Center, Equipment Dashboard, the cue groups and tiles (captions from `app/src/Dashboard/EQMEquipmentCues.Page.al`) and the charts, with drill-down and Refresh. Sources: FR-009, FR-021, FR-022, FR-038, NFR-001 help.
10. `reports.md` — One H2 per report: Equipment Register, Asset Utilization, Maintenance Cost Analysis, Usage Analytics. For each: how to open it, the request-page filters, the sheets or columns, and an example reading. Sources: FR-039, FR-040, FR-041, FR-052 help.
11. `notifications-and-monitoring.md` — In-app notifications and My Notifications, the three daily jobs and their times, Schedule Monitoring Jobs, job status on setup, the Equipment Error Log, retention policies. Sources: FR-017, FR-018, NFR-004, FR-051, FR-054 help.
12. `audit-and-change-tracking.md` — Equipment Audit Trail, Change Log support, Maintenance Log Entries. Sources: FR-034, FR-035, NFR-005 help.
13. `integration.md` — "Integration with other apps": integration event entries and the Integration Events Enabled switch, Power Automate flows (the two events and the example flows), and one sentence that developers can subscribe to business events (see FR-060). Sources: FR-030, FR-031, FR-029 help (user-level facts only).
14. `using-the-api.md` — For integrators: what the APIs expose (equipment, categories, assignments, integration events), the URL pattern and fields, the bound actions, the permission set (API Consumer), and a Microsoft Entra application (Learn link). Sources: FR-026, FR-027, FR-028, FR-036 help. Keep their `TODO(verify)` markers.
15. `pages-and-ui-reference.md` — One table, `| Page | Type | How to open | Use it to | Article |`, with these rows (captions as in AL; "Tell Me" = searchable): Equipment (list, Tell Me Lists); Equipment Card (card, from the list); Equipment Categories (list, Tell Me Administration); Equipment Setup (card, Tell Me Administration); Equipment Features (list, Tell Me Administration); Equipment Assignments (list, Tell Me History); Equipment Maintenance (list, Tell Me Lists); Maintenance Record (card, from the list); Maintenance History (list, Tell Me History); Maintenance Log Entries (list, Tell Me History); Warranty Alerts (list, Tell Me Lists); Equipment Requests (list, Tell Me Lists); Equipment Request (card); Equipment Request Decision (dialog); Equipment Notes (list, Tell Me History); Equipment Audit Trail (list, Tell Me History); Integration Event Entries (list, from Equipment Setup); Equipment Error Log (list, Tell Me Administration); Equipment Dashboard (Tell Me Reports and analysis); Equipment Manager (Role Center). A second table lists the parts and FactBoxes and the page that hosts each: Equipment Activities, Equipment by Category, Equipment by Status, Maintenance Cost by Category, Top 10 Equipment by Maintenance Cost, Assignment Details, Assignment History, Maintenance, Maintenance History, Equipment Notes, Picture, Equipment Summary, Equipment Statistics, Attachment Summary, Assigned Equipment (Employee Card). A third table covers the reports (Equipment Register, Asset Utilization, Maintenance Cost Analysis, Usage Analytics; Tell Me Reports and analysis). A fourth covers the additions to standard pages (Employee Card actions and FactBox; the attachment category on Document Attachment Details). Confirm the host pages and the Tell Me categories in AL (`PageType`, `UsageCategory`, `part(`) before you write them.
16. `advanced-scenarios.md` — Several companies and new companies (setup created on install or when an Administrator opens Equipment Setup; see docs/TODO.md "New companies"), large registers (FR-053, NFR-001), languages and regional formats (FR-055, FR-056), upgrading the app (what an administrator sees, from FR-044 help only), telemetry for administrators (FR-050), feature switches and their limits (FR-042: disabled pages still appear in Tell Me).
17. `troubleshooting-and-faq.md` — "Common issues": each as H3 with **Symptom**, **Possible causes** and **Solution**. Cover at least: setup missing in a company; Equipment Nos. is blank; equipment cannot be deleted (assigned or has history); equipment cannot be assigned (In Maintenance, open maintenance, already assigned, inactive or privacy-blocked employee); category cannot be deleted; duplicate serial number; warranty end date not after start date; a page shows a "feature is turned off" error; you cannot approve your own request; employee names are blank (no Employee read, D365 BASIC missing); daily jobs do not run or show Error (Schedule Monitoring Jobs, Error Log); no notifications (feature off, My Notifications); API call is denied (API Consumer, Entra app). Take each cause and solution from the help articles and AL labels. "FAQ" in **Q:**/**A:** form, at least: Can equipment have several pictures? (No, one picture, README V3 status.) Can equipment be assigned to resources? (No, only employees.) Does the app do depreciation or fixed-asset accounting? (No, out of scope.) Is location tracking available? (Not yet, on the roadmap.) Which languages are available? Does Delete Demo Data remove my own records? (FR-066 rules.) What happens to data when the app is uninstalled? (Learn link.)
18. `security-and-permissions.md` — The five permission sets (captions Equipment Reader, Equipment Operator, Equipment Manager, Equipment Administrator, Equipment API Consumer) in a matrix of who can do what, the need for D365 BASIC, assigning sets (Learn link), data classification and marking employee numbers as personal, who can see the error log. Sources: FR-036, NFR-002, FR-057, FR-058, FR-051 help.
19. `releases.md` — H2 "29.0.0.0 (not released yet)". Under it, H3 per area in the order of README V1-V4 (Equipment register and assignments; Maintenance; Warranty; Notifications and monitoring; Documents, notes and pictures; Integration and API; Requests and approvals; Audit; Dashboards and reports; Configuration; Localization; Security and compliance; Documentation). Each H3 has bullets that summarise the "Release notes:" paragraphs of the matching CHANGELOG.md entries. Leave out contributor-only entries (FR-045-049, FR-061). Add a final bullet for FR-059 (this guide). Why: the reference site has release notes per version; the app has one unreleased version.
20. `README.md` (root) — After line 85 ("Feature documentation is in `docs/features/`, user help in `docs/help/` ..."), add one line: "The consolidated user guide is in [`docs/user-guide/`](docs/user-guide/README.md)." Change nothing else.
21. `docs/TODO.md` — Add at the end a section "## FR-059 checks (documentation only; not verified in a sandbox)" with these items: walk through every guide page in a sandbox and clear its `TODO(verify)` markers; add screenshots (phase 3); decide hosting and the `app.json` `help`/`contextSensitiveHelpUrl` values (stop list, user decision, phase 2); add `ContextSensitiveHelpPage` per the map in `docs/features/FR-059-user-documentation.md` (phase 2); keep the guide in sync in each new FR (see the feature doc, "Maintaining the guide").
22. Verification (developer, Bash, no file left behind). Run a link check from the scratchpad with `python3 -I <scratchpad>/linkcheck.py /Users/miguelcarvalho/Developer/equipment-management`. For every `docs/user-guide/*.md`, plus `docs/help/FR-059-*.md` and `docs/features/FR-059-*.md` once they exist, the script resolves every `](relative/path.md...)` target (anchor stripped) against the file's folder and prints the missing ones. Expected: none. Then run `grep -rnE "EQM |\b501[0-9]{2}\b" docs/user-guide/`. Expected: no match. Grep each bold page name from Step 15 as `Caption = '<name>'` in `app/src`; each must match. Finally `git diff --stat origin/main -- app/ test/ .github/ .AL-Go/` must be empty. Report all four results.

Docs stage (al-docs, after the reviewer approves):
23. `docs/features/FR-059-user-documentation.md` — Purpose. Status (branch, not merged, docs only, version stays 29.0.0.0). Verification status (no AL, no tests, no sandbox, no separate AppSource validation, repo_checks not run by al-docs). Structure of the guide (the file list). Name the structural reference as "a public third-party Business Central app documentation site supplied by the user (https://docs.bricklead.eu/en-us/apps/ins/); structure only, no text reused". Source map (guide page → help articles, as in Steps 2-19). Excluded contributor articles and FR-060. "Maintaining the guide": each future FR updates the matching guide page and `releases.md`, and per-feature help stays the detailed record. A page-to-article map for phase 2, `| AL object (name) | Guide slug |`, covering every page and report in Step 15 (object IDs are allowed here). Open items (phases 2 and 3).
24. `docs/help/FR-059-user-documentation.md` — Short end-user article "Equipment Management user guide (AppSource end-user help)": where the guide is, its contents in one list linking `../user-guide/*.md`, how it relates to the per-feature articles, a "Release notes" section.
25. `CHANGELOG.md` — New top entry `## FR-059 User Documentation (version stays 29.0.0.0, no bump)` in the FR-058 format: Added (the user guide, its sections, the link from README), Changed: None, Fixed: None, Obsolete: None, a "Release notes:" paragraph, and a "Note:" line (no `app/` change, no `app.json` change, no tests, not verified in a sandbox, no separate AppSource validation ran).

Main agent:
26. `docs/plans/FR-059-user-documentation.md` — Save this plan with the house header. Then run `python3 .github/scripts/repo_checks.py --base origin/main --branch feature/FR-059-user-documentation`.

## Tests
No AL code changes, so there are no AL tests and no existing tests are affected. The checks below are documentation acceptance checks for Step 22 and the reviewer.
- [SCENARIO] Links resolve. [GIVEN] all guide pages and the FR-059 docs. [WHEN] the link check runs. [THEN] it reports 0 missing targets.
- [SCENARIO] A broken link is detected (negative). [GIVEN] a temporary copy of one guide page in the scratchpad with a link to `missing.md`. [WHEN] the link check runs on the scratchpad copy. [THEN] it reports exactly that link. This proves the check can fail. Delete the copy afterwards.
- [SCENARIO] UI names exist. [GIVEN] the bold page, report and role names in `pages-and-ui-reference.md`. [WHEN] each is grepped as a `Caption` in `app/src`. [THEN] every name matches.
- [SCENARIO] No internal identifiers leak (negative). [GIVEN] `docs/user-guide/`. [WHEN] it is grepped for `EQM ` and `501NN`. [THEN] there is no match.
- [SCENARIO] No code change. [GIVEN] the branch. [WHEN] `git diff --stat origin/main -- app/ test/ .github/ .AL-Go/` runs. [THEN] the output is empty.
- [SCENARIO] Repo checks pass. [GIVEN] the plan, feature doc, help article and CHANGELOG entry. [WHEN] `repo_checks.py --base origin/main --branch feature/FR-059-user-documentation` runs. [THEN] "All repository checks passed."
- [SCENARIO] Repo check catches a missing FR-059 help article (negative, reasoning only, not run). [GIVEN] `docs/help/FR-059-*.md` absent. [THEN] `check_feature_files` reports "FR-059: no help article found". This is why Step 24 is mandatory.
- [SCENARIO] Reviewer spot check: no copied text. [GIVEN] three guide pages chosen at random. [WHEN] they are compared with the matching reference pages. [THEN] no sentence is reused.
- [SCENARIO] Reviewer spot check: facts match the source. [GIVEN] the field tables in setup-and-configuration.md and equipment-register.md. [WHEN] they are compared with the ToolTips in `EQMEquipmentSetup.Page.al` and `EQMEquipmentCard.Page.al`. [THEN] the field names and descriptions match.

## Assumptions
- Assumed the FR-059 requirement is "complete user help" (README.md line 130) shaped by the user's reference site, because issue #100 could not be read by the planner. If the issue sets extra acceptance criteria, compare them with the Definition of done before approval.
- Assumed the audience is end users, consultants, administrators and integrators, and that developer topics go to FR-060, because README pairs FR-059 with FR-060 Developer Documentation.
- Assumed Markdown in the repo with no site generator, because the repo has no mkdocs, docfx or toc files and publishing needs hosting and `app.json` decisions (stop list).
- Assumed English only for the guide, because the XLIFF translation workflow (FR-055) covers UI text, not Markdown.
- Assumed no screenshots, because no sandbox is available to agents.
- Assumed the install creates the defaults described in the FR-001 help (setup, EQUIP series, starter categories). The developer confirms this in `EQMDefaultData.Codeunit.al` and the FR-018 help before writing Getting started.

## DECISIONS
- FR-059 location | Chose a new folder `docs/user-guide/` with one file per section over adding pages to `docs/help/` or one large file, because `docs/help/` is one-article-per-FR and the guide needs its own sidebar order | Reversible: yes
- FR-059 file names | Chose stable unnumbered kebab-case slugs (e.g. `equipment-register.md`) over numbered file names, so the names can become `ContextSensitiveHelpPage` targets in phase 2 without renames | Reversible: yes until phase 2 ships help links
- FR-059 reuse | Chose a consolidated, task-oriented rewrite of the current behaviour that links the per-feature articles under "Related", over an index of links only (does not match the reference structure) or moving or deleting the per-feature articles (they are the per-FR record and are referenced by plans and CHANGELOG) | Reversible: yes
- FR-059 old articles | Chose to leave the existing `docs/help/FR-0NN-*.md` unchanged and report conflicts, over correcting them now (smallest change; same approach as FR-049) | Reversible: yes
- FR-059 source precedence | Chose AL source > newest FR help article > older help article when they disagree | Reversible: yes
- FR-059 identifiers | Chose no object IDs or AL names in the guide, and the page-to-article map with object names only in the feature doc, following the al-docs rule "no object IDs in user-facing docs" | Reversible: yes
- FR-059 field tables | Chose field descriptions taken from the AL ToolTips over new wording, so the guide matches what users see in the client | Reversible: yes
- FR-059 releases | Chose one "29.0.0.0 (not released yet)" section grouped by area, built from the CHANGELOG release notes, over a per-FR list, because only one unreleased version exists | Reversible: yes
- FR-059 scope | Chose to leave contributor articles (FR-045-049, FR-061, developer part of FR-029) out of the user guide and leave them to FR-060 | Reversible: yes
- FR-059 verification | Chose a one-off link and caption check run by the developer over a new `repo_checks.py` check (phase 2), to keep this change docs-only | Reversible: yes
- FR-059 help links | Chose not to set `app.json` `help`/`contextSensitiveHelpUrl` or `ContextSensitiveHelpPage` in phase 1, because `app.json` is on the stop list and there is no host yet | Reversible: yes

## Risks
- **Content drift.** The guide and the per-feature articles now say similar things in two places. Mitigation: the "Maintaining the guide" rule in the feature doc. The al-docs agent instructions do not yet tell it to update `docs/user-guide/`. Changing `.claude/agents/al-docs.md` is a configuration change the user should decide on; raise it in the final report, do not do it unasked.
- **Stale facts in older help articles** (example: FR-001 lists three permission sets). The reviewer should check the developer's "Conflicts found" list and the role matrix in security-and-permissions.md against `app/src/Permissions/*.PermissionSet.al`.
- **Nothing is verified in a sandbox.** UI names and menu paths may differ in the client. Mitigation: `TODO(verify)` markers are carried over, and docs/TODO.md gets an FR-059 section.
- **Copying from the reference site.** The reviewer runs the "no copied text" spot check. The reference's Getting Started page has an error copied from another product; it is ignored.
- **Large Markdown diff (about 20 files).** The review is reading-heavy. The reviewer should prioritise Getting started, Setup, Security and Troubleshooting, where wrong facts cost users the most.
- **Relative links to `../help/`** break if only `docs/user-guide/` is published later. Phase 2 decides whether per-feature help is published too; the feature doc records this.
- **AppSource marketing validation needs a public help link** (`app.json` `help`). Phase 1 does not meet that. It is already an open item in docs/TODO.md (Marketplace properties, AS0051/AS0052/AS0092).
- **The `TODO(verify)` count grows in user-facing text.** That is accepted: honest status beats unverified claims.
- **CI:** the CI/CD push workflow ignores `**.md`. The PR build and the Repo checks still run on the PR. No AL build impact is expected.

## References
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/help/context-sensitive-help
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-adding-help-links-from-pages-tables-xmlports
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/user-assistance
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/deployment/configure-help
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/help/writing-guide
- https://learn.microsoft.com/dynamics365/business-central/ui-extensions-install-uninstall
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-checklist-submission
