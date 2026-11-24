# FR-056 Regional Settings

> **Sandbox verification (2026-11-24):** verified in a Business Central sandbox by the project owner; no defects were reported. The detailed results are not recorded here, so statements below that say "not verified" or carry `TODO(verify)` predate this run.

## Purpose
Shows dates, numbers and amounts in the user's Business Central regional format (My Settings > Region). Before this change, one page showed stored values in XML format: the Maintenance Log Entries page (50121) showed a date as `2026-11-19`, a cost as `1234.5` and a maintenance type as `1` instead of "Corrective".

The change is display only. The log keeps its stored format (NFR-005 Q4). The audit below records what was checked in the rest of the app.

Status: implemented on branch `feature/FR-056-regional-settings`, not committed, not merged. Plan: `docs/plans/FR-056-regional-settings.md` (status approved). Target: AppSource.

## Audit (before the change)
The audit checked `app/src` for values that do not follow the user's region.

| Area | Finding | Action |
|---|---|---|
| Amount fields (tables 50100, 50104, 50105, 50106, 50113) | Every money Decimal has `AutoFormatType = 1` (LCY). The client formats them by Region | None |
| Percent page variables (50120 list, maintenance FactBox) | `DecimalPlaces = 0 : 1`, typed Decimal | None |
| Dates and DateTimes on pages and FactBoxes | Typed Date/DateTime fields and variables. None are pre-formatted to text | None |
| Messages, errors, confirms, notifications (`StrSubstNo`, `Error`, `Message`) | Dates, integers and decimals are passed as typed values, so AL formats them by the user's region. Enums use `Format(enum)` = translated caption | None |
| Date formulas (`<%1M>`, `<1D>`, `<-CM>`, `<CM>`, `<-CY>`) | Angle-bracket formulas do not depend on language or region | None |
| `SetFilter` with dates | Uses `%1` placeholders with typed values, not text | None |
| Reports 50100–50102 | Compiler-generated Excel layouts take native Date/Decimal cells. The request page has Language/Format Region | None |
| Charts (50116–50119) | Pass Decimal values to the BusinessChart control | None |
| Telemetry EQM0001–EQM0009, business events, API pages | Machine-readable on purpose: `Format(x, 0, 9)`, enum Names() (FR-050 decision) | None. Must stay invariant |
| Maintenance log (table 50108, page 50121, codeunit 50116) | Stores values with `Format(value, 0, 9)` (NFR-005 Q4, user-approved). The page shows the raw XML text to users | Fix in this plan: display-only conversion. Storage unchanged |
| Hard-coded currency symbols, date patterns, number masks | None found in `app/src` | None |

Only the maintenance log showed non-regional values to users. It is the only change in this feature.

## What changed
### Maintenance Log Entries page (50121)
- Two new columns, **Old Value** and **New Value**, show the stored value in the user's regional format:
  - Maintenance Date: regional date format.
  - Cost: regional number format, with the regional decimal and thousands separators.
  - Maintenance Type: the translated caption of the type, for example "Corrective".
  - Vendor No., Description and Performed By: shown exactly as stored. They are text.
- The former **Old Value** and **New Value** columns stay on the page, hidden. Their captions are now **Old Value (XML Format)** and **New Value (XML Format)**. Users can show them through personalization.
- Registered and Posted entries have no field and no values. Their regional columns are blank.

### Conversion (codeunit 50116)
- New internal procedure `FormatLogValueForDisplay` converts one stored value for display.
- A stored value that cannot be converted is shown as stored. Examples: text that is not a valid date or number, a maintenance type ordinal that is not installed, or a blank value. The conversion never raises an error.
- The conversion is in memory. It reads no database record per row.

### Table 50108 (maintenance log entry)
- Two new internal procedures, `GetLocalOldValue` and `GetLocalNewValue`, call the conversion for the page.
- Fields 6 (Old Value) and 7 (New Value) are unchanged. Everything written to the log is unchanged: `Format(value, 0, 9)`.

## Behaviour changes for users
- On the Maintenance Log Entries page, the dates, costs and maintenance types of Changed entries follow the user's region. The Old Value and New Value columns show the regional values by default.
- The XML values are still there. They are in hidden columns, and each user can show them through personalization.
- Nothing else changes for users. Telemetry, business events, the API and reports keep their formats.

## Not changed (decided)
- **Stored log format.** Storage stays `Format(value, 0, 9)`. NFR-005 Q4 stands. No upgrade code and no data conversion.
- **Currency-specific decimal places.** Cost uses plain `Format(Decimal)`. The GL Setup "Amount Decimal Places" through the "Auto Format" codeunit is phase 2.
- **`AutoFormatExpression` on amount fields.** Not added (CodeCop AA0472/AA0474 Info). Phase 2.
- **Word and RDLC layouts, and a report `FormatRegion`.** No such layouts exist.
- **Translations into other languages.** FR-055.
- **Telemetry, business events and API.** They stay invariant, on purpose.
- **Object IDs, permissions, app.json.** No new objects, no permission set entries, no app.json change. The version stays 29.0.0.0.

## Verification status
- **Compile:** `app/` and `test/` compile clean, as reported by the reviewer. The docs step did not compile again.
- **Review:** APPROVED by al-reviewer.
- **Tests:** new tests in test codeunit 50164 "EQM Maintenance Tests" (R1 to R5 and N1 to N4 in the plan). They cover the converted values, the TestPage, unparsable values, an uninstalled maintenance type ordinal and the registered entry. Not verified: tests not executed locally, CI result pending.
- **AppSourceCop baseline:** not configured. No breaking-change comparison ran. The plan's breaking-change check is therefore still open.
- **repo_checks.py:** not run by al-docs. The main agent runs it after this change.
- **AppSource validation:** no separate AppSource validation ran. The reviewer checked the change against the plan and the AppSource rules.

## Open items
- Run the CI build and the tests in `Pull Request Build`, and read the result.
- Configure the AppSourceCop baseline and run the breaking-change comparison. Until then, no AS0009, AS0010, AS0038 or AS0042 check has run against the baseline.
- Sandbox check, web client, under two regions (for example English (United States) and German (Germany)): the Old Value and New Value columns show the regional date, cost and maintenance type for a Changed entry. The XML columns appear after personalization.
- Phase 2: LCY decimal places through the "Auto Format" codeunit.

## Related
- Help article: `docs/help/FR-056-regional-settings.md`
- Changelog: `CHANGELOG.md`, entry FR-056
- Plan: `docs/plans/FR-056-regional-settings.md`
- Maintenance log: `docs/features/NFR-005-auditability.md` (storage format, NFR-005 Q4)
- Microsoft Learn: [Change basic settings (Region)](https://learn.microsoft.com/dynamics365/business-central/ui-change-basic-settings#region), [Personalize your workspace](https://learn.microsoft.com/dynamics365/business-central/ui-personalization-user), [Format property](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-format-property), [Format field data](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-format-field-data), [AutoFormatType property](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/properties/devenv-autoformattype-property)
