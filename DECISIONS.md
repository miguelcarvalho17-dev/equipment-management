# Decisions log

Non-trivial choices made by the agents. Written only by the main agent, appended at the end of each pipeline run. Entries are final unless the user reverses them; a reversal is a new entry, not an edit.

Format:

`- YYYY-MM-DD | <task> | Chose X over Y because Z | Reversible: yes/no`

A decision that applies to all future work (not just one task) belongs in the "Standing decisions" section of `CLAUDE.md` instead.

---

- 2026-11-17 | FR-037 FactBoxes | Chose three new CardPart pages over extending "EQM Equipment FactBox" and "EQM Maintenance FactBox", because the issue defines three named FactBoxes and the existing parts are reused on 4 other pages | Reversible: yes
- 2026-11-17 | FR-037 FactBoxes | Chose to keep the existing Assignment Details and Maintenance FactBoxes visible on the card over hiding them; the pane grows to 9 parts, and hiding is a non-breaking follow-up | Reversible: yes
- 2026-11-17 | FR-037 FactBoxes | Chose Image = Document Attachment "File Type" Image and Document = every other attachment, over counting the Picture or classifying by "EQM Attachment Category" | Reversible: yes
- 2026-11-17 | FR-037 FactBoxes | Chose Maintenance Count = posted maintenances (FlowField 15) over all records, so count and total cost describe the same set | Reversible: yes
- 2026-11-17 | FR-037 FactBoxes | Chose a new internal codeunit "EQM Equipment Attachment Mgt." over FlowFields on table 50100, to avoid widening the published table and API surface | Reversible: yes
- 2026-11-17 | FR-037 test build | Developer verified test/ with the direct alc compiler because al_build for test/ returned no diagnostics; its copy of the app in test/.alpackages broke the MCP compile and was deleted. Compile was finally confirmed by the user's VS Code build | Reversible: yes
- 2026-11-17 | FR-061 Code Quality Compliance | Chose CodeCop + UICop + AppSourceCop on the main app and CodeCop + UICop on the test app locally (enableCodeAnalyzersOnTestApps in CI) over AppSourceCop on both, because AS0015 (TranslationFile missing in test/app.json) is an error that stops the test app from packaging and test/app.json stays untouched | Reversible: yes
- 2026-11-17 | FR-061 Code Quality Compliance | Chose app/AppSourceCop.json with mandatoryAffixes EQM (Option A) and no test/AppSourceCop.json | Reversible: yes
- 2026-11-17 | FR-061 Code Quality Compliance | Chose al.ruleSetPath pointing at .AL-Go/equipment.ruleset.json over default severities, for local and CI parity | Reversible: yes
- 2026-11-17 | FR-061 Code Quality Compliance | Chose a documented exception register for manifest diagnostics (AS0051, AS0052, AS0081, AS0084, AS0092) over placeholder values in app.json; failOn newWarning deferred to phase 2 | Reversible: yes
- 2026-11-17 | FR-061 Code Quality Compliance | Chose to fix AA0210 in EQMEquipmentAPITests by filtering on "No." and asserting Description, and AA0477 by reordering usings | Reversible: yes
- 2026-11-17 | FR-061 Code Quality Compliance | Chose enableCodeAnalyzersOnTestApps false over adding TranslationFile to test/app.json, because PR #132 CI showed AppSourceCop runs on the test app (AS0015, AS0054 errors); test app stays analysed locally by CodeCop and UICop only | Reversible: yes
- 2026-11-17 | FR-038 Enhanced Role Center | Chose new FlowFields on the existing temporary cue table 50104 and tiles on page 50106 over a new cue page or page-variable tiles, because both hosts (RC 50110, dashboard 50109) already embed 50106 and FlowFields give drill-down without code | Reversible: yes
- 2026-11-17 | FR-038 Enhanced Role Center | Chose one new cuegroup "Operational Indicators" with all four tiles in the issue's order, after the Equipment group, over spreading them into the existing groups | Reversible: yes
- 2026-11-17 | FR-038 Enhanced Role Center | Chose Total Assets Value = sum of Purchase Cost excluding Lost and Disposed, over including all equipment, consistent with the other warranty/maintenance tiles | Reversible: yes
- 2026-11-17 | FR-038 Enhanced Role Center | Chose "Warranties Expiring This Month" = today to end of month, over the whole calendar month, so already-expired warranties stay in the Expired tile only | Reversible: yes
- 2026-11-17 | FR-038 Enhanced Role Center | Chose Open Maintenance Activities = maintenance records with Status Open (records, not equipment), counting records of every equipment status | Reversible: yes
- 2026-11-17 | FR-038 Enhanced Role Center | Chose test codeunit ID 50161 (reserved by FR-009 for "EQM Dashboard Tests") over the next free 50195 | Reversible: yes
- 2026-11-17 | FR-038 tests | Used a single Counter for equipment, request and maintenance numbers in Locked Tok labels over fixed numbers, so tests that insert several records never collide | Reversible: yes
- 2026-11-17 | FR-038 build | The AL MCP could not load symbols, so app/ and test/ were compiled with the extension's alc.dll directly (analyzers on app/, none on test/) | Reversible: yes
- 2026-11-17 | FR-039 Equipment Register Report | Chose a single compiler-generated Excel layout over an RDLC or Word layout; a printable Word layout is phase 2 | Reversible: yes
- 2026-11-17 | FR-039 Equipment Register Report | Chose RequestFilterFields ("Category Code", Status, "Assigned Employee No.", "Purchase Date") on one data item over custom request-page fields | Reversible: yes
- 2026-11-17 | FR-039 Equipment Register Report | Chose the Employee filter on the current "Assigned Employee No." over a filter on assignment history | Reversible: yes
- 2026-11-17 | FR-039 Equipment Register Report | Chose to list all statuses by default, including Lost and Disposed, over excluding final statuses as the dashboard tiles do | Reversible: yes
- 2026-11-17 | FR-039 Equipment Register Report | Chose category description and employee name as report variables with a Dictionary cache over new FlowFields on table 50100 (same reasoning as FR-037) | Reversible: yes
- 2026-11-17 | FR-039 Equipment Register Report | Chose not to set DataAccessIntent = ReadOnly | Reversible: yes
- 2026-11-17 | FR-039 Equipment Register Report | Chose entry points Tell Me + Equipment List Report group + Role Center Reporting area over the list page only | Reversible: no (published actions cannot be removed, AS0031; they can be obsoleted)
- 2026-11-17 | FR-039 Equipment Register Report | Chose report ID 50100 and test codeunit 50195 (MCP ID tool unavailable, IDs from a source scan) | Reversible: yes
- 2026-11-17 | FR-039 Equipment Register Report | Chose testing via Report.SaveAs to XML with text Contains checks over "Library - Report Dataset" (would need a test-app dependency) | Reversible: yes
- 2026-11-17 | FR-039 Equipment Register Report | Chose to extend test 50162 so reports are part of the "Reader has Execute on every object" check | Reversible: yes
- 2026-11-17 | FR-039 build | The AL MCP could not load symbols, so app/ and test/ were compiled with the extension's alc.dll directly with /generatereportlayout+ (analyzers on app/, none on test/) | Reversible: yes
- 2026-11-17 | FR-039 tests | Added always-true AreNotEqual anchor assertions in positive/negative test pairs over dropping the unused variables (reviewer MINOR m1, left open) | Reversible: yes
- 2026-11-17 | FR-040 Asset Utilization Report | Chose Total = equipment not Lost and not Disposed (extension statuses included) over all statuses as in the dashboard Total Equipment tile, because final statuses can never be assigned | Reversible: yes
- 2026-11-17 | FR-040 Asset Utilization Report | Chose to add an In Maintenance column next to the issue's four metrics, so Total reconciles | Reversible: no (dataset columns are a contract; can only be added)
- 2026-11-17 | FR-040 Asset Utilization Report | Chose one summary row for the filtered set (request filters Category Code, Location Code) over a per-category breakdown; the breakdown is phase 2 | Reversible: yes
- 2026-11-17 | FR-040 Asset Utilization Report | Chose the calculation in two new internal procedures on "EQM Dashboard Mgt." over a new codeunit or new cue FlowFields, because Reader already has Execute on it | Reversible: yes
- 2026-11-17 | FR-040 Asset Utilization Report | Chose a filtered Count() per status in filter group 10 (user filters in group 0 still apply) over looping the records or a new query | Reversible: yes
- 2026-11-17 | FR-040 Asset Utilization Report | Chose Utilization % rounded to 0.01, and 0 when Total = 0 | Reversible: yes
- 2026-11-17 | FR-040 Asset Utilization Report | Chose a single compiler-generated Excel layout and the FR-039 entry points (Tell Me, Equipment List Report group, Role Center Reporting area) | Reversible: no (published actions cannot be removed, AS0031)
- 2026-11-17 | FR-040 Asset Utilization Report | Chose report ID 50101 and test codeunit 50196 (MCP ID tool unavailable, IDs from a source scan) | Reversible: yes
- 2026-11-17 | FR-040 build | The AL MCP could not load symbols, so app/ and test/ were compiled with the extension's alc.dll directly (analyzers on app/, none on test/) | Reversible: yes
- 2026-11-17 | FR-040 report | Added `using System.Utilities;` for the Integer data item, as the compiler required | Reversible: yes
- 2026-11-17 | FR-041 Maintenance Cost Analysis | Chose an aggregated dataset (one row per category, equipment, year, month) filled into a TableType=Temporary buffer table over one row per history entry, because the issue asks for a breakdown and it stays pivotable in Excel | Reversible: no (dataset columns are a contract once released; can only be added)
- 2026-11-17 | FR-041 Maintenance Cost Analysis | Chose to aggregate in AL (filtered FindSet + Dictionary + temporary buffer) over a query with Year/Month date methods, because a query cannot take the report's request-page views | Reversible: yes
- 2026-11-17 | FR-041 Maintenance Cost Analysis | Chose the procedure on "EQM Dashboard Mgt." over a new codeunit, same reasoning as FR-040 | Reversible: yes
- 2026-11-17 | FR-041 Maintenance Cost Analysis | Chose posted maintenance (history entries) only, and the equipment's current category, consistent with FR-013/FR-037 and query 50102 | Reversible: yes
- 2026-11-17 | FR-041 Maintenance Cost Analysis | Chose request filters Equipment: No., Category Code and Posted Maintenance: Maintenance Date, Maintenance Type | Reversible: yes
- 2026-11-17 | FR-041 Maintenance Cost Analysis | Chose zero-cost entries counted in No. of Maintenances | Reversible: yes
- 2026-11-17 | FR-041 Maintenance Cost Analysis | Chose a single compiler-generated Excel layout and the FR-039/040 entry points (Tell Me, Equipment List Report group, Role Center Reporting area) | Reversible: no (published actions cannot be removed, AS0031)
- 2026-11-17 | FR-041 Maintenance Cost Analysis | Chose report 50102, table 50113 and test codeunit 50197 (MCP ID tool unavailable, IDs from a source scan) | Reversible: yes
- 2026-11-17 | FR-041 build | The AL MCP had no project loaded, so app/ and test/ were compiled with the extension's alc compiler directly | Reversible: yes
- 2026-11-17 | FR-041 tests | Passed the category description dictionary as var over by value, to make the shared cache explicit | Reversible: yes
- 2026-11-18 | FR-042 Feature Management | Chose a new table "EQM Feature Setup" keyed by enum "EQM Feature" with "missing row = enabled" over Boolean fields on table 50102, because new Booleans read false on existing rows and would turn every feature off on upgrade (upgrade code is on the stop list); also keeps table 50102 free for FR-043 | Reversible: no (published table and enum; can only be obsoleted)
- 2026-11-18 | FR-042 Feature Management | Chose Visible variables set in OnOpenPage plus an actionable ErrorInfo on entry pages over custom application areas, because application areas need install and upgrade code (stop list). Limitation: disabled pages stay listed in Tell Me | Reversible: yes (phase 2)
- 2026-11-18 | FR-042 Feature Management | Chose that Approval Workflows off hides the whole equipment request process over letting requests skip approval, because skipping approval would be a new business rule | Reversible: yes
- 2026-11-18 | FR-042 Feature Management | Chose that API Integration off also stops writing integration event entries (codeunit 50122 IsEnabled) over UI-only gating | Reversible: yes
- 2026-11-18 | FR-042 Feature Management | Chose that Warranty Alerts off stops alert creation in the daily job while the warranty-expired business event is still raised | Reversible: yes
- 2026-11-18 | FR-042 Feature Management | Chose to gate only the default-visible list column "Next Maintenance Date"; the hidden-by-default columns stay Visible = false | Reversible: yes
- 2026-11-18 | FR-042 Feature Management | Chose fail-open (treated as enabled) when the user cannot read the feature setup, because activation hides UI and is not a permission mechanism | Reversible: yes
- 2026-11-18 | FR-042 Feature Management | Chose entry points Tell Me (Administration), an Equipment Setup Navigation action and a Role Center Setup section action | Reversible: no (published actions cannot be removed, AS0031)
- 2026-11-18 | FR-042 Feature Management | Chose enum 50112, table 50114, codeunit 50138, page 50140 and test codeunit 50198 (MCP ID tool unavailable, IDs from a source scan) | Reversible: yes
- 2026-11-18 | FR-042 Feature Management | Applied the plan's step 10 fallback: Role Center 50110 gets no OnOpenPage or Visible gating (AL0378 forbids triggers on Role Center pages). Actions Equipment Requests and Warranty Alerts stay visible there and their pages show the feature-off error | Reversible: yes
- 2026-11-18 | FR-042 build | The AL MCP had no project loaded, so app/ and test/ were compiled with the extension's alc compiler directly | Reversible: yes
- 2026-11-18 | FR-043 Application Setup | Chose to bind Enable Equipment Requests and Enable APIs to the existing FR-042 features (Approval Workflows, API Integration) through page variables, over new Boolean fields on table 50102. New fields would create a second source of truth, and new Booleans read false on existing rows (upgrade code is on the stop list) | Reversible: yes
- 2026-11-18 | FR-043 Application Setup | Chose a new enum value 5 "Notifications" in "EQM Feature" (missing row = enabled) for Enable Notifications, over a Boolean on table 50102, for the same upgrade reason and so the switch also appears on the Equipment Features page | Reversible: no (published enum value; can only be obsoleted)
- 2026-11-18 | FR-043 Application Setup | Chose that Notifications off suppresses all four equipment in-app notification paths company-wide, while per-user My Notifications keeps working. Business events, integration events and jobs are not affected | Reversible: yes
- 2026-11-18 | FR-043 Application Setup | Chose Default Warranty Alert Days = the alert-creation window (1..90, default 90 = today's behaviour), over the Expiring Soon status threshold (30) | Reversible: no (published field; semantics can only be changed before release)
- 2026-11-18 | FR-043 Application Setup | Chose blank/0 = 90 days in the getter plus InitValue 90 for new setups, over upgrade code that fills existing rows | Reversible: yes
- 2026-11-18 | FR-043 Application Setup | Chose that lowering the alert days keeps already open alerts outside the new window, over cancelling them | Reversible: yes
- 2026-11-18 | FR-043 Application Setup | Chose to apply the default maintenance frequency in the Equipment Card's OnNewRecord, over the table OnInsert (a deliberate 0 could not be saved there). It also applies when Maintenance Planning is off (reviewer m2, documented in help) | Reversible: yes
- 2026-11-18 | FR-043 Application Setup | Chose range checks in OnValidate with an ErrorInfo label, over MinValue/MaxValue properties, for an actionable and testable message | Reversible: yes
- 2026-11-18 | FR-043 Application Setup | Chose three explicit switches on the setup page, over embedding the whole features list as a part (FR-042 phase 4) | Reversible: yes
- 2026-11-18 | FR-043 Application Setup | Chose to hide each default field when its feature (Warranty Alerts / Maintenance Planning) is off, consistent with FR-042 gating | Reversible: yes
- 2026-11-18 | FR-043 Application Setup | Chose test codeunit 50199 (MCP ID tool unavailable, IDs from a source scan), the last free ID in the test range | Reversible: yes
- 2026-11-18 | FR-043 build | The AL MCP had no project loaded, so app/ and test/ were compiled with the extension's alc compiler directly, and the new app.app was copied into test/.alpackages (gitignored) | Reversible: yes
