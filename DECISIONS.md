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

