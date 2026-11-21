# FR-058 Data Classification

## Purpose
Every table and field of the app must have a data classification (issue #99). The classification tells the platform and the administrator what kind of data a field holds, so that personal data can be found and handled for compliance. This change checks the classifications of all fields, decides the two open personal-data items in `docs/TODO.md`, and adds a test that keeps them from drifting.

Status: implemented on branch `feature/FR-058-data-classification`, not committed, not merged. Plan: `docs/plans/FR-058-data-classification.md` (status approved). Target: AppSource. App version stays 29.0.0.0 (unreleased, no bump). No `app/` change, no `app.json` change, no new permission set, no new event, no new published procedure, no upgrade code.

## Verification status
- **Review:** APPROVED. The reviewer confirmed the decisions. The Microsoft Learn definitions page for data classification could not be fetched during the review, so the definitions in this document are described in plain words and not quoted.
- **Tests: written, NOT executed locally.** Test codeunit "EQM Data Classification Tests" (in `test/`) holds six tests, DC1 to DC6. There is no command-line test runner and no sandbox run yet. Not verified: tests not executed locally, CI result pending.
- **Build:** not recorded in this document. The compile result of `app/` and `test/` is reported with the pull request.
- **repo_checks.py:** not run by al-docs. The main agent runs it after this change.
- **AppSource validation:** No separate AppSource validation ran. The reviewer checked the AppSource rules by reading the code.
- **Sandbox:** not run. The steps for the Data Classification Worksheet are marked TODO(verify) in the help article.

## Audit method
1. All 18 tables and the one table extension in `app/src` were read, field by field.
2. Every table sets `DataClassification = CustomerContent` at table level. Normal fields inherit that value or set their own. No field uses `ToBeClassified`. Fields that inherit the table value count as classified.
3. Fields that are filled from the user session (`UserId()`) were checked for the end-user classification.
4. FlowFields and FlowFilters are not stored. The platform gives them `SystemMetadata`.
5. The result: no AL field needed a change. No published metadata changed, so there is no breaking-change risk.

## Classification terms used
- **CustomerContent (CC):** the default for the business data of the app: equipment, employees, vendors, maintenance, notes and free text entered by users.
- **EndUserIdentifiableInformation (EUII):** used here for the identifiers of the people who use the service, that is the Business Central user names that the app stores from the user session.
- **Not used:** OrganizationIdentifiableInformation (OII), AccountData and EndUserPseudonymousIdentifiers (EUPI). OII is for data that identifies the tenant organization. The app stores no such data. The other two do not match any field.
- **SystemMetadata:** used for technical fields that hold no business data (error operation, object ID, error code, call stack, system IDs and timestamps used for telemetry or tracking).

The exact Microsoft definitions are on the Learn page linked under Related. Check them there before you rely on this register for a compliance decision.

## Register
CC = CustomerContent, EUII = EndUserIdentifiableInformation. Fields not listed inherit the table value (CC).

| Table | Table-level | Overrides and notes |
|---|---|---|
| Equipment | CC | "Assigned Employee No." personal data, kept CC (see decisions). Picture may show people (CC). FlowFilter and FlowFields are not stored. |
| Category | CC | |
| Setup | CC | |
| Assignment | CC | "Employee No." CC. "Assigned By" and "Closed By" EUII. A FlowField. |
| Cue | CC | Temporary. FlowFields and FlowFilters only. |
| Maintenance Record | CC | "Performed By" free text, CC. A FlowField. |
| History | CC | "Vendor No." and "Vendor Name" CC. "Performed By" CC. "Posted By" EUII. A FlowField. |
| Warranty Alert | CC | "Acknowledged By" EUII. Two FlowFields. |
| Maintenance Log | CC | "Old Value" and "New Value" CC. "User ID" EUII. A FlowField. |
| Note | CC | "User ID" EUII. "Comment" CC. |
| Integration Event Entry | CC | |
| Request | CC | "Employee No." and "Justification" and "Decision Comment" CC. "Sent for Approval By" and "Decided By" EUII. A FlowField. |
| Audit | CC | "Employee No." CC. "User ID" EUII. |
| Cost buffer | CC | Temporary. |
| Feature Setup | CC | |
| Error Log Entry | CC | "User ID" EUII. "Error Message" CC. "Operation", "Object ID", "Error Code" and "Error Call Stack" SystemMetadata. |
| Usage Analytics buffer | CC | Temporary. Counts only. |
| Demo Data Entry | CC | "Created By" EUII. "Table ID", "Record System Id" and "Created At" SystemMetadata. |
| Table extension on Document Attachment | - | Field "EQM Attachment Category" CC (explicit). |

Notes on the register:
- The fields that the app fills from `UserId()` are EUII: 11 fields in total. They are listed in the register above.
- System-generated fields such as Entry No., Logged At, Posted At, Processed At and setup and enum fields keep CC. They are not moved to SystemMetadata (see decisions).

## Personal-data decisions
| Field | Classification | Reason |
|---|---|---|
| Equipment "Assigned Employee No.", Assignment, Request and Audit "Employee No." | CC | Employee numbers identify data subjects (employees), not users of the service. An administrator can mark them Personal in the Data Classification Worksheet. |
| "Posted By" (History) | EUII | Confirmed. It stores the user name of the person who posted the record. |
| "Performed By" (Maintenance Record and History) | CC | Free text entered by a user, or third-party data. Not a user name from the session. |
| "Vendor Name" (History) | CC | Third-party data. |

## Test codeunit
Test codeunit "EQM Data Classification Tests" (in `test/src/`) runs the checks against the compiled metadata. It is read-only and uses `AutoRollback`.

- **DC1:** Every Normal field of the app's tables (ID range 50100 to 50149) is not `ToBeClassified`. When a field fails, the message names the table and the field. **The test reports only the first unclassified field it finds.** Fix that field and run again to see the next one.
- **DC2:** Anti-vacuous check. The DC1 scan covers the Equipment table field "Description" and excludes the FlowField "Total Maintenance Cost", so a scan that finds nothing fails.
- **DC3:** Every Code[50] field named "User ID" or ending in " By" is EUII. At least one field must match. **Limit: the rule works on the field name and the field length only.** It checks only Code[50] fields whose name is "User ID" or ends in " By". A future field with another name, or a field of another length, is not checked by DC3. A future field with a matching name that is not a user ID fails DC3 and needs a decision.
- **DC4:** The 11 known user-ID fields are EUII.
- **DC5:** The decided personal-data fields stay CC, including "Assigned Employee No.", the "Employee No." fields, "Performed By", "Vendor Name" and "Vendor No.", and the free-text fields.
- **DC6:** The explicit SystemMetadata fields stay SystemMetadata, and the table extension field stays CC.

The test codeunit uses the field numbers from `FieldNo()` and record variables, not literal numbers. A later change to a field number does not break the test.

## Design decisions
- **Keep table-level CC inheritance.** Fields are not given their own `DataClassification` value. The effective value is the same, about 150 published fields are not touched, and AppSourceCop AS0016 checks the classification.
- **Employee numbers stay CC.** An administrator can flag them Personal in the worksheet.
- **"Performed By", "Vendor Name" and "Vendor No." stay CC.** They are free text or third-party data.
- **"Posted By" stays EUII.** No change.
- **No move of system fields to SystemMetadata.** Moving a field to a higher classification is safe. Moving one down changes published metadata, so it is not done.
- **Metadata test instead of a Python check.** The test reads the compiled metadata in CI, so it sees what the platform sees.
- **Test codeunit ID 50163.** It was the reservation for NFR-003, which was never built, so the ID is free. The ID came from a source scan.

## Not in this change (out of scope)
- Moving system-generated fields from CC to SystemMetadata.
- Writing field-level `DataClassification` on fields that already inherit the table value.
- Default Data Sensitivity records. They need install code and data writes, which are on the stop list. Administrators use the Data Classification Worksheet.
- Telemetry `Session.LogMessage` calls. They are already SystemMetadata (FR-050).

## Known limitations and open points
- **DC3 uses a name rule** (see the test section). Its limit is that a new user-ID field with another name is not caught.
- **DC1 reports one field at a time.** A run that fails shows only the first problem.
- **Learn definitions not confirmed in writing.** The register uses the terms in plain words. The definitions must be checked on Learn before a compliance review.
- **Future reclassification.** A change of any classification value must be checked against AppSourceCop and the baseline. No such change is made here.

## Related
- Help article: `docs/help/FR-058-data-classification.md`
- Changelog: `CHANGELOG.md`, entry FR-058
- Plan: `docs/plans/FR-058-data-classification.md`
- Open items: `docs/TODO.md`, at the FR-011 follow-ups (R5) and the personal-data classification item
- Microsoft Learn: [Classify data (developer)](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-classifying-data), [Privacy for developers](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/security/privacy-developers), [Classify data sensitivity (admin)](https://learn.microsoft.com/dynamics365/business-central/admin-classifying-data-sensitivity), [AppSourceCop AS0016](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/analyzers/appsourcecop-as0016)
