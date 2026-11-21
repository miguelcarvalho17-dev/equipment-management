# FR-058 Data Classification — Plan

> Request (verbatim): FR-058 Data Classification
> Status: **approved**

GitHub issue #99: "All fields shall have data classifications assigned. Examples: CustomerContent, SystemMetadata, OrganizationIdentifiableInformation. Business Value: Supports compliance requirements. Related: Open items in docs/TODO.md: classification of 'Assigned Employee No.' and of 'Posted By', 'Performed By' and 'Vendor Name' (FR-011 R5)."

## Request
Make sure every field in the app has a correct DataClassification (issue #99), and close the two open TODO items on personal-data classification: "Assigned Employee No." (docs/TODO.md:158) and "Posted By", "Performed By" and "Vendor Name" (FR-011 R5, docs/TODO.md:67). Add a test that keeps the classifications from drifting.

Target: AppSource

**Audit result.** All 18 tables and the one table extension in `app/src` were read. No field is missing a classification and none is wrong:
- Every table sets `DataClassification = CustomerContent` at table level; every Normal field inherits it or sets its own value. Nothing uses `ToBeClassified`.
- All 11 fields filled from `UserId()` are already `EndUserIdentifiableInformation`: 50103 fields 5 and 8; 50111 fields 9 and 10; 50112 field 8; 50108 field 8; 50109 field 4; 50115 field 3; 50107 field 9; 50106 field 11 "Posted By"; 50149 field 5.
- Already `SystemMetadata`: 50115 fields 4, 5, 7, 8 and 50149 fields 1, 3, 4.
- The only field added to a standard table is tableextension 50100 field 50100 on "Document Attachment" (explicit `CustomerContent`).
- FlowFields and FlowFilters get `SystemMetadata` from the platform automatically (AS0016).

So no AL field needs to change. No published metadata changes; no breaking-change risk.

## Definition of done
- [ ] `app/` is unchanged (`git diff --stat main -- app/` is empty).
- [ ] New test codeunit 50163 "EQM Data Classification Tests" compiles in `test/` with no warnings under CodeCop and UICop.
- [ ] The test proves: (a) every Normal field of tables 50100..50149 is classified; (b) every user-ID field (Code[50] named "User ID" or "... By") is EndUserIdentifiableInformation; (c) the decided personal-data fields stay CustomerContent; (d) the explicit SystemMetadata fields stay SystemMetadata, and the table-extension field is CustomerContent.
- [ ] `docs/TODO.md`: line 158 checked with the FR-058 decision; line 67 R5 part checked (H8 already met, `internalsVisibleTo` exists).
- [ ] `docs/features/FR-058-data-classification.md` holds the register; `docs/help/FR-058-data-classification.md` holds admin guidance; `CHANGELOG.md` has a `## FR-058 Data Classification (version stays 29.0.0.0, no bump)` entry.
- [ ] Report says: "Not verified: tests not executed locally, CI result pending" and "No separate AppSource validation ran".

## Out of scope
- Moving system-generated fields (Entry No., Logged At, Posted At, Processed At, setup and enum fields) from CustomerContent to SystemMetadata.
- Writing field-level DataClassification on fields that already inherit the table value.
- Default Data Sensitivity records (needs install/upgrade code and data writes; stop list). Admins use the Data Classification Worksheet.
- Telemetry `Session.LogMessage` calls (already SystemMetadata, FR-050).

## Objects
| Type | ID | Name | New/Changed | File |
|---|---|---|---|---|
| Codeunit (test app) | 50163 | EQM Data Classification Tests | New | test/src/EQMDataClassificationTests.Codeunit.al |

ID from a source scan (`al_getnextobjectid` failed: no AL projects loaded). Free IDs in 50150..50199: 50163, 50165-50167, 50170, 50171, 50173-50175.

## Events and standard symbols
| Symbol | Used | Verified |
|---|---|---|
| System table `Field` (System.Reflection) | `TableNo`, `"No."`, `FieldName`, `Type`, `Len`, `Class`, `DataClassification` | NOT verified with MCP (no project loaded); confirm at compile |
| Table "Document Attachment" | `Database::"Document Attachment"` | Already used in app/src/Equipment/EQMEquipment.Table.al:389 |
| Codeunit "Library Assert" | `IsTrue`, `AreEqual` | Already used in all test codeunits |

No events used.

## Steps
1. **Create the test codeunit** `test/src/EQMDataClassificationTests.Codeunit.al`.
   - `namespace MiguelCarvalho.EquipmentManagement.Tests;` usings: `MiguelCarvalho.EquipmentManagement`, `System.Reflection`, `System.TestLibraries.Utilities`, `Microsoft.Foundation.Attachment`.
   - `codeunit 50163 "EQM Data Classification Tests"`, `Subtype = Test; TestPermissions = Disabled;`, XML summary mentioning FR-058.
   - Locked labels for ranges (`50100..50149`, `1..1999999999`), `User ID`, ` By`, and assertion messages with Comments.
   - Helpers: `FilterAppNormalFields`, `GetField`, `AssertEndUserIdentifiable`, `AssertCustomerContent`, `AssertSystemMetadata`, `IsUserIdField`.
   - Field numbers always via record variables and `FieldNo()`, never literals.
   - Tests DC1-DC6, each `[Test]` + `[TransactionModel(TransactionModel::AutoRollback)]`, read-only.
2. **Compile** `app/` then `test/` (`al_compile` + `al_getdiagnostics`); fallback to alc on a scratchpad copy as in FR-051..054. Fix all warnings. Do not commit `app/Translations/*.g.xlf` changes.
3. **Feature doc** `docs/features/FR-058-data-classification.md`: audit method, register (below), why OII/AccountData/EUPI are unused, the test codeunit, "no metadata change, no breaking-change impact".
4. **Help article** `docs/help/FR-058-data-classification.md`: which fields hold personal data, how to mark them Personal in the Data Classification Worksheet (Find New Fields), tenant can override.
5. **TODO and changelog**: docs/TODO.md lines 158 and 67; CHANGELOG.md entry as in FR-054.

Register (CC = CustomerContent, EUII = EndUserIdentifiableInformation):

| Table | Table-level | Overrides and notes |
|---|---|---|
| 50100 Equipment | CC | 10 "Assigned Employee No." personal (CC). 24 Picture may show people (CC). 13 FlowFilter; 14-16 FlowFields |
| 50101 Category | CC | |
| 50102 Setup | CC | |
| 50103 Assignment | CC | 3 Employee No. (CC). 5, 8 EUII. 9 FlowField |
| 50104 Cue | CC | Temporary; FlowFields/FlowFilters only |
| 50105 Maintenance Record | CC | 8 "Performed By" free text (CC). 10 FlowField |
| 50106 History | CC | 7 Vendor Name, 10 Performed By CC. 11 Posted By EUII. 13 FlowField |
| 50107 Warranty Alert | CC | 9 EUII. 3, 4 FlowFields |
| 50108 Maintenance Log | CC | 6, 7 Old/New Value CC. 8 EUII. 5 FlowField |
| 50109 Note | CC | 4 EUII. 5 Comment CC |
| 50110 Integration Event Entry | CC | |
| 50111 Request | CC | 2, 4, 12 CC. 9, 10 EUII. 8 FlowField |
| 50112 Audit | CC | 5 Employee No. CC. 8 EUII |
| 50113 Cost buffer | CC | Temporary |
| 50114 Feature Setup | CC | |
| 50115 Error Log | CC | 3 EUII. 4, 5, 7, 8 SystemMetadata. 6 Error Message CC |
| 50116 Usage Analytics buffer | CC | Temporary; counts only |
| 50149 Demo Data Entry | CC | 1, 3, 4 SystemMetadata. 5 EUII |
| tableext 50100 on Document Attachment | — | field 50100 CC (explicit) |

## Tests (codeunit 50163)
- **DC1** Every Normal field of the app's tables is not `ToBeClassified`; message names table and field.
- **DC2** (anti-vacuous) The DC1 scan covers `EQM Equipment`.Description and excludes the FlowField `Total Maintenance Cost`.
- **DC3** Every Code[50] field named "User ID" or "... By" is EUII; at least one matched.
- **DC4** The 11 known user-ID fields are EUII: Assignment "Assigned By", "Closed By"; Request "Sent for Approval By", "Decided By"; Audit, Maintenance Log, Note, Error Log "User ID"; Warranty Alert "Acknowledged By"; History "Posted By"; Demo Data "Created By".
- **DC5** Personal data stays CC: Equipment "Assigned Employee No."; Assignment/Request/Audit "Employee No."; Request Justification, "Decision Comment"; Maintenance Record and History "Performed By"; History "Vendor Name", "Vendor No."; Note Comment; Maintenance Log "Old Value", "New Value"; Error Log "Error Message".
- **DC6** SystemMetadata: Error Log Operation, "Object ID", "Error Code", "Error Call Stack"; Demo Data "Table ID", "Record System Id", "Created At". CC: Document Attachment field "EQM Attachment Category".

Existing tests affected: none.

## Assumptions
- Table-level `DataClassification` counts as "assigned" for inheriting fields (AS0016 has accepted this in every earlier build).
- EUII means identifiers of end users of the service (BC user names from `UserId()`); employees, vendors and free-text names entered by users are CustomerContent. The Learn definitions page redirected and could not be fetched.
- `Field.DataClassification` reports SystemMetadata for system fields; tests filter those out so nothing depends on it.
- Test ID 50163 (unbuilt NFR-003 reservation).

## DECISIONS
- FR-058 Data Classification | Keep table-level CustomerContent inheritance rather than writing DataClassification on every field (same effective value, ~150 published fields untouched, AS0016 enforces) | Reversible: yes
- FR-058 Data Classification | Keep employee-number fields CustomerContent (50100 f10, 50103 f3, 50111 f2, 50112 f5): employees are data subjects, not end users of the service; admins flag them Personal in the worksheet | Reversible: yes (metadata-only)
- FR-058 Data Classification | "Performed By" (50105 f8, 50106 f10) and "Vendor Name" (50106 f7) stay CustomerContent, not EUII/OII (free text or third-party data; OII is for data identifying the tenant organization) | Reversible: yes
- FR-058 Data Classification | "Posted By" (50106 f11) confirmed EUII; no change | Reversible: yes
- FR-058 Data Classification | Do not move system-generated fields from CustomerContent to SystemMetadata (classifying higher is safe; lowering touches published metadata) | Reversible: yes
- FR-058 Data Classification | Metadata test on system table `Field` instead of a Python repo check (runs in CI against compiled metadata) | Reversible: yes
- FR-058 Data Classification | Test codeunit ID 50163 instead of extending 50162 or widening test/app.json (stop list); ID from source scan | Reversible: yes

## Risks
- AL MCP had no project loaded, so no symbol is MCP-verified. Developer must confirm `Field` members and option names at compile. Fallbacks: simplify `IsUserIdField` to the name rule plus `"Type Name"`; or compare `Format(..., 0, 9)` values.
- Learn's data classification definitions page redirected; the reviewer should confirm CC/EUII/OII definitions before approving the DECISIONS.
- Standard classification of `Vendor.Name` / Employee fields not checked; the CC decision does not depend on it.
- No DataClassification value changes, so no breaking-change impact; the full AppSourceCop rule list was not confirmed for DataClassification rules. Future reclassification must be checked.
- DC3 name heuristic may flag a future Code[50] "... By" field that is not a user ID; the failure forces a decision.
- Tests are not executed locally; result comes from CI after push.

## References
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/analyzers/appsourcecop-as0016
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/security/privacy-developers
- https://learn.microsoft.com/dynamics365/business-central/admin-classifying-data-sensitivity
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/analyzers/appsourcecop
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-classifying-data (not fetchable; reviewer to check)
