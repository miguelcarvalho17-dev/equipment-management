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
