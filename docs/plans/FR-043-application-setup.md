# FR-043 Application Setup — Plan

> Request (verbatim): "FR-043 Application Setup" (GitHub issue #84)
> Status: **approved**

Make the existing Equipment Setup page (50103) the central place where administrators configure the solution. It gets five options: Default Warranty Alert Days, Default Maintenance Frequency, Enable Notifications, Enable Equipment Requests and Enable APIs. Two of the "Enable" switches already exist as FR-042 features, so this change reuses them and does not add a second copy.

Target: AppSource

Tooling note: the AL MCP reported "No AL projects are loaded", so `al_getnextobjectid` and `al_symbolsearch` failed during planning (same as FR-038 to FR-042). IDs came from a source scan. The plan uses no new base-application symbol. Every symbol it touches is in this app and was read in source.

## Definition of done

- [ ] Table 50102 "EQM Equipment Setup" has 2 new fields:
  - 6 "Default Warranty Alert Days" (Integer, InitValue 90, BlankZero, allowed 1..90)
  - 7 "Default Maint. Freq. (Months)" (Integer, caption "Default Maintenance Frequency (Months)", BlankZero, allowed 0..120)
  - Values outside the range raise an actionable ErrorInfo.
- [ ] Enum 50112 "EQM Feature" has a new value 5 `Notifications`. A missing row still means enabled. Equipment Features (50140) lists 6 features, and the new one has a description.
- [ ] The Equipment Setup page has two new groups:
  - **Defaults:** the 2 new fields. Default Warranty Alert Days is visible only when Warranty Alerts is on. Default Maintenance Frequency is visible only when Maintenance Planning is on.
  - **Features:** 3 Boolean controls, Enable Notifications, Enable Equipment Requests and Enable APIs. They read and write the FR-042 feature rows Notifications, Approval Workflows and API Integration.
  - The page stays read-only for users without write permission on the setup.
- [ ] `GenerateAlerts` only creates alerts for equipment whose warranty ends within the configured number of days. If the field is blank (setups created before this change) or the setup is missing, it uses 90 days (today's behaviour).
- [ ] A new equipment record started on the Equipment Card (OnNewRecord) is prefilled with the default maintenance frequency when it is greater than 0. The user can change it before saving. Code, API and configuration-package inserts are not changed.
- [ ] When Notifications is off, the equipment card, maintenance record card, Role Center and "returned from maintenance" notifications are not sent to any user in the company. Per-user My Notifications keeps working as before when the feature is on.
- [ ] No upgrade or install code. No new object in app/. No permission set changes (every object involved is already in the sets).
- [ ] `app/Translations/Equipment Management.g.xlf` is regenerated.
- [ ] `app/` and then `test/` compile with 0 errors and 0 warnings (CodeCop, UICop, AppSourceCop on app).
- [ ] New test codeunit 50199 compiles. Report as "Not verified: tests not executed locally, CI result pending".

## Out of scope

- New Boolean fields on 50102 for requests or APIs (would duplicate the FR-042 feature table; new Booleans read false on existing rows).
- Changing the warranty "Expiring Soon" threshold (`GetWarrantyExpiringSoonDays` = 30), the alert interval enum 50105, or cancelling open alerts when the alert days are lowered.
- Applying the default maintenance frequency to equipment created through the API, AL code or configuration packages, or to existing equipment.
- Gating Power Automate business events, integration events (already gated by API Integration), job queue jobs or telemetry with Enable Notifications.
- Hiding pages from Tell Me (FR-042 phase 2), and any `app.json` change.

Later phases:
- Phase 2: the default maintenance frequency also applies to API and code inserts (table OnInsert), if wanted.
- Phase 3: optionally cancel open warranty alerts outside a lowered alert window.

## Objects

| Type | ID | Name | New/Changed | File |
|---|---|---|---|---|
| Enum | 50112 | EQM Feature | Changed (+value 5 Notifications) | `app/src/Features/EQMFeature.Enum.al` |
| Codeunit | 50138 | EQM Feature Mgt. | Changed (+1 label, +1 case) | `app/src/Features/EQMFeatureMgt.Codeunit.al` |
| Page | 50140 | EQM Equipment Features | Changed (AboutText only) | `app/src/Features/EQMEquipmentFeatures.Page.al` |
| Table | 50102 | EQM Equipment Setup | Changed (+fields 6, 7, +1 local procedure, +1 label) | `app/src/Setup/EQMEquipmentSetup.Table.al` |
| Codeunit | 50110 | EQM Warranty Alert Mgt. | Changed (+GetWarrantyAlertDays, GenerateAlerts window) | `app/src/Warranty/EQMWarrantyAlertMgt.Codeunit.al` |
| Table | 50100 | EQM Equipment | Changed (+internal ApplySetupDefaults) | `app/src/Equipment/EQMEquipment.Table.al` |
| Page | 50101 | EQM Equipment Card | Changed (OnNewRecord, 1 line) | `app/src/Equipment/EQMEquipmentCard.Page.al` |
| Codeunit | 50112 | EQM Notification Mgt. | Changed (4 guards) | `app/src/Notifications/EQMNotificationMgt.Codeunit.al` |
| Page | 50103 | EQM Equipment Setup | Changed (2 groups, 3 vars, OnOpenPage, texts) | `app/src/Setup/EQMEquipmentSetup.Page.al` |
| XLIFF | – | Equipment Management.g.xlf | Regenerated by build | `app/Translations/Equipment Management.g.xlf` |
| Codeunit (test) | 50199 | EQM Application Setup Tests | New | `test/src/EQMApplicationSetupTests.Codeunit.al` |

Permission sets do not change: Reader already has R on tabledata 50102 and 50114 and X on codeunits 50110, 50112, 50138 and page 50103; Administrator already has RIMD on 50102 and 50114; test 50162 needs no change.

## Events and standard symbols

No event is published or subscribed. No base-application object is touched. Symbols used (all in-app, read in source; MCP was down):
- Codeunit 50138: `IsEnabled(Feature: Enum "EQM Feature"): Boolean`, `SetFeatureEnabled(Feature; NewEnabled: Boolean)`, `GetFeatureDescription(Feature): Text`
- Codeunit 50110: `GetLongestIntervalDays(): Integer`, `GenerateAlerts(ReferenceDate: Date; IsScheduled: Boolean; var CreatedCount: Integer; var CancelledCount: Integer)`
- Codeunit 50112: `ShowEquipmentNotifications(Equipment)`, `ShowMaintenanceRecordNotification(MaintenanceRecord)`, `ShowRoleCenterNotifications()`, `SendReturnedFromMaintenanceNotification(EquipmentNo: Code[20]; StatusBeforePosting: Enum "EQM Equipment Status")`, `RegisterDefaultNotifications()`
- Table 50100 field 23 "Maintenance Frequency (Months)" Integer (MinValue 0, MaxValue 120); table 50102 fields 1-5 exist (last is 5 "Request Nos.")
- `ErrorInfo.Message/.TableId/.FieldNo/.RecordId`, `Error(ErrorInfo)` (runtime 18.0 supports them)
- `[SendNotificationHandler(true)]` with `procedure X(var TheNotification: Notification): Boolean`

## Steps

1. **`EQMFeature.Enum.al`**: after value 4 add `value(5; Notifications) { Caption = 'Notifications'; }`. Do not renumber or rename existing values.

   **`EQMFeatureMgt.Codeunit.al`**: add label `NotificationsDescTxt: Label 'Shows the equipment notifications to the users of this company: expiring warranties, overdue maintenance and equipment that is back from maintenance. Each user can still turn single notifications off in My Notifications. When the feature is off, no equipment notification is shown.';` and in `GetFeatureDescription` add `Feature::Notifications: exit(NotificationsDescTxt);` after the Maintenance Planning case.

   **`EQMEquipmentFeatures.Page.al`**: in AboutText change "API integration and maintenance planning." to "API integration, maintenance planning and notifications." Nothing else.

2. **`EQMEquipmentSetup.Table.al`**: add after field 5:
   ```al
   field(6; "Default Warranty Alert Days"; Integer)
   {
       Caption = 'Default Warranty Alert Days';
       ToolTip = 'Specifies how many days before the warranty end date warranty alerts start to be created, from 1 to 90. Alerts are created 90, 60 and 30 days before the end date, as far as these fall within this number of days; for example, with 30 only the 30-day alert is created. When the field is blank, 90 days is used. Alerts that are already open are kept when you lower the number.';
       InitValue = 90;
       BlankZero = true;

       trigger OnValidate()
       var
           WarrantyAlertMgt: Codeunit "EQM Warranty Alert Mgt.";
       begin
           CheckValueInRange(FieldNo("Default Warranty Alert Days"), FieldCaption("Default Warranty Alert Days"), "Default Warranty Alert Days", 1, WarrantyAlertMgt.GetLongestIntervalDays());
       end;
   }
   field(7; "Default Maint. Freq. (Months)"; Integer)
   {
       Caption = 'Default Maintenance Frequency (Months)';
       ToolTip = 'Specifies the maintenance frequency, in months, that new equipment gets when you create it on the equipment card, from 0 to 120. You can change the frequency on each piece of equipment. Leave the field blank when new equipment has no planned maintenance by default. Existing equipment, and equipment created through the API or by import, is not changed.';
       BlankZero = true;

       trigger OnValidate()
       begin
           // 120 is the MaxValue of field 23 "Maintenance Frequency (Months)" on table 50100
           CheckValueInRange(FieldNo("Default Maint. Freq. (Months)"), FieldCaption("Default Maint. Freq. (Months)"), "Default Maint. Freq. (Months)", 0, 120);
       end;
   }
   ```
   After `keys` add:
   ```al
   var
       ValueOutOfRangeErr: Label '%1 must be between %2 and %3. You entered %4.', Comment = '%1 = field caption, %2 = lowest allowed value, %3 = highest allowed value, %4 = the value that was entered';

   local procedure CheckValueInRange(FieldNumber: Integer; FieldCaptionText: Text; Value: Integer; MinValue: Integer; MaxValue: Integer)
   var
       OutOfRangeError: ErrorInfo;
   begin
       if (Value >= MinValue) and (Value <= MaxValue) then
           exit;
       OutOfRangeError.Message(StrSubstNo(ValueOutOfRangeErr, FieldCaptionText, MinValue, MaxValue, Value));
       OutOfRangeError.TableId(Database::"EQM Equipment Setup");
       OutOfRangeError.FieldNo(FieldNumber);
       OutOfRangeError.RecordId(RecordId());
       Error(OutOfRangeError);
   end;
   ```
   No MinValue/MaxValue properties. DataClassification inherited from the table.

3. **`EQMWarrantyAlertMgt.Codeunit.al`**: after `GetLongestIntervalDays` add:
   ```al
   /// <summary>
   /// Returns how many days before the warranty end date warranty alerts start to be created: Default Warranty Alert Days
   /// from the equipment setup, or the longest interval (90) when the setup is missing or the field is blank or out of range.
   /// </summary>
   /// <returns>The number of days.</returns>
   internal procedure GetWarrantyAlertDays(): Integer
   var
       EquipmentSetup: Record "EQM Equipment Setup";
   begin
       EquipmentSetup.SetLoadFields("Default Warranty Alert Days");
       if EquipmentSetup.Get() then
           if (EquipmentSetup."Default Warranty Alert Days" >= 1) and (EquipmentSetup."Default Warranty Alert Days" <= GetLongestIntervalDays()) then
               exit(EquipmentSetup."Default Warranty Alert Days");
       exit(GetLongestIntervalDays());
   end;
   ```
   In `GenerateAlerts`: add local `AlertDays: Integer;`; right after the `if ReferenceDate = 0D ...` block and **before** `WarrantyAlert.LockTable();` add `AlertDays := GetWarrantyAlertDays();`; change `SetRange("Warranty End Date", ReferenceDate, ReferenceDate + GetLongestIntervalDays())` to use `AlertDays`. Update the summary ("within the warranty alert days of the setup (90 by default)"). Leave `FindDueInterval` unchanged.

4. **`EQMEquipment.Table.al`**: after `AssistEdit()` add:
   ```al
   /// <summary>
   /// Fills in setup defaults on a new equipment record that is not saved yet: the maintenance frequency gets Default
   /// Maintenance Frequency (Months) from the equipment setup when it is still 0. Does nothing when the setup is missing,
   /// the user cannot read it, or the default is 0. The record is not saved.
   /// </summary>
   internal procedure ApplySetupDefaults()
   var
       EquipmentSetup: Record "EQM Equipment Setup";
   begin
       if "Maintenance Frequency (Months)" <> 0 then
           exit;
       if not EquipmentSetup.ReadPermission() then
           exit;
       EquipmentSetup.SetLoadFields("Default Maint. Freq. (Months)");
       if not EquipmentSetup.Get() then
           exit;
       "Maintenance Frequency (Months)" := EquipmentSetup."Default Maint. Freq. (Months)";
   end;
   ```
   Direct assignment, not Validate.

   **`EQMEquipmentCard.Page.al`**: in `OnNewRecord` add `Rec.ApplySetupDefaults();` as the first statement, before `UpdateControls();`.

5. **`EQMNotificationMgt.Codeunit.al`**: add `if not FeatureMgt.IsEnabled("EQM Feature"::Notifications) then exit;` directly after the existing `if not GuiAllowed() then exit;` in `ShowEquipmentNotifications` (keep the two Recall calls before both guards), `ShowMaintenanceRecordNotification`, `ShowRoleCenterNotifications`, `SendReturnedFromMaintenanceNotification`. Add to the codeunit summary: "Nothing is shown when the Notifications feature is turned off in the company."

6. **`EQMEquipmentSetup.Page.al`**:
   - Globals: `MaintenancePlanningEnabled`, `EnableNotifications`, `EnableEquipmentRequests`, `EnableApis` (Boolean).
   - OnOpenPage: after the 2 existing feature assignments add `MaintenancePlanningEnabled := FeatureMgt.IsEnabled("EQM Feature"::"Maintenance Planning");`; after `CanManage := Rec.WritePermission();` add `EnableNotifications := FeatureMgt.IsEnabled("EQM Feature"::Notifications); EnableEquipmentRequests := FeatureMgt.IsEnabled("EQM Feature"::"Approval Workflows"); EnableApis := ApiIntegrationEnabled;`.
   - Layout: between `group(Numbering)` and `group(Integration)` add:
     - `group(Defaults)` (Caption 'Defaults') with fields `"Default Warranty Alert Days"` (Visible = WarrantyAlertsEnabled) and `"Default Maint. Freq. (Months)"` (Visible = MaintenancePlanningEnabled).
     - `group(Features)` (Caption 'Features') with 3 Boolean fields, each with OnValidate calling `FeatureMgt.SetFeatureEnabled(...)`:
       - `EnableNotifications` → `"EQM Feature"::Notifications`. Caption 'Enable Notifications'. ToolTip: 'Specifies whether users in this company see equipment notifications about expiring warranties, overdue maintenance and equipment that is back from maintenance. When it is off, no equipment notification is shown; when it is on, each user can still turn single notifications off in My Notifications. This is the Notifications feature on the Equipment Features page.'
       - `EnableEquipmentRequests` → `"EQM Feature"::"Approval Workflows"`. Caption 'Enable Equipment Requests'. ToolTip: 'Specifies whether employees can request equipment and approvers can approve or reject the requests. When it is off, the Equipment Requests pages, actions and tile are hidden and existing requests are kept. This is the Approval Workflows feature on the Equipment Features page. Users see the change the next time they open a page.'
       - `EnableApis` → `"EQM Feature"::"API Integration"`. Caption 'Enable APIs'. ToolTip: 'Specifies whether external systems can use the equipment APIs. When it is off, the APIs return an error, the integration settings are hidden and no integration event entries are written. This is the API Integration feature on the Equipment Features page. Users see the change the next time they open a page.'
   - Action EquipmentFeatures ToolTip: "API integration and maintenance planning." → "API integration, maintenance planning and notifications."
   - AdditionalSearchTerms: append `, application setup, default warranty alert days, default maintenance frequency, enable notifications, enable equipment requests, enable APIs`.
   - AboutText: replace with 'Set the number series for equipment, maintenance records and equipment requests, the default warranty alert days and maintenance frequency, and turn notifications, equipment requests and the APIs on or off for this company. The app runs its monitoring every day through job queue entries: one creates warranty alerts, one checks overdue maintenance. They are created automatically; if one is missing, choose **Schedule Monitoring Jobs**. Turn on **Integration Events Enabled** to record business events for external systems. Users see a change to a feature the next time they open a page.'
   - Page-level `CurrPage.Editable := false` already makes toggles read-only for non-writers.

7. **Build `app/`** (`al_compile` + `al_getdiagnostics`; if MCP has no project, use direct alc build as in FR-039 to FR-042). 0 errors, 0 warnings. Keep the regenerated `.g.xlf`.

8. **`test/src/EQMApplicationSetupTests.Codeunit.al`** (new): codeunit 50199 "EQM Application Setup Tests".
   - `namespace MiguelCarvalho.EquipmentManagement.Tests;` usings `MiguelCarvalho.EquipmentManagement; System.TestLibraries.Utilities;` (add Configuration only if used). `Subtype = Test; TestPermissions = Disabled;`
   - Every test: `[Test]`, `[TransactionModel(TransactionModel::AutoRollback)]`, starts with `Initialize()`.
   - Globals: `Assert: Codeunit "Library Assert"`, `FeatureMgt`, `WarrantyAlertMgt`, `NotificationMgt`, `Counter`, `SentNotificationCount`; locked Tok labels `EquipmentNoTok 'ASEQ%1X'`, `CategoryCodeTok 'ASCAT%1'`, `CounterFormatTok '<Integer,4><Filler Character,0>'`; a copy of `ValueOutOfRangeErr` (comment "Copy of the internal label of table 50102").
   - Helpers: `Initialize()` (feature setup `DeleteAll()`, ensure setup row exists via Get or Init+Insert(false), `SentNotificationCount := 0`); `SetSetupDefaults(AlertDays; MaintFreq)` (direct assignment + `Modify(false)`); `NextId()`, `CreateEquipment(var Equipment; WarrantyEndDate: Date)` same pattern as `EQMFeatureMgtTests.CreateEquipment`; `[SendNotificationHandler(true)] procedure SendNotificationHandler(var TheNotification: Notification): Boolean` increments `SentNotificationCount`, returns true.
   - Derive day counts from `WarrantyAlertMgt.GetIntervalDays(...)`, not literals. Filter warranty alerts on the test equipment's "No."; never rely on CreatedCount.

9. **Build `test/`** with 0 errors and 0 warnings. Report tests as not executed (CI pending).

10. **Documenter** (after review): `docs/features/FR-043-application-setup.md`, `docs/help/FR-043-application-setup.md` (two new groups; 1..90 and 0..120 ranges; blank = 90 for existing companies; lowering alert days keeps open alerts; maintenance default applies on the card only; the three switches equal the Equipment Features rows, Enable Equipment Requests = Approval Workflows; changes apply when a page is reopened; settings are per company); `CHANGELOG.md` heading `## FR-043 Application Setup (version stays 29.0.0.0, no bump)`; `docs/TODO.md` section "FR-043 sandbox checks" with S1-S9.

## Tests

New codeunit 50199. Every test starts with no feature rows and an existing setup row.

**Default Warranty Alert Days**
- S1 (negative): alert days = 30-day interval; equipment ends in 30+15 days; `GenerateAlerts(Today(), false, ...)` → no alert for E.
- S2: alert days = 30; E ends in 30-10 days → exactly one alert, interval "30 Days".
- S3: `SetSetupDefaults(0, 0)`; E ends in 90-10 days → alert with "90 Days"; `GetWarrantyAlertDays()` = `GetLongestIntervalDays()`.
- S4 (negative): `asserterror Validate("Default Warranty Alert Days", GetLongestIntervalDays() + 1)` → `Assert.ExpectedError(StrSubstNo(ValueOutOfRangeErr, FieldCaption, 1, 90, 91))`, numbers computed.
- S5 (negative): Validate with 0 → same specific error with 0.
- S6: a setup after `Init()` (not inserted) has the field = GetLongestIntervalDays().

**Default Maintenance Frequency**
- S7: default 6, `Equipment.Init()`, `ApplySetupDefaults()` → 6.
- S8 (negative): default 0 → frequency 0.
- S9 (negative): default 6, frequency set to 3 → stays 3.
- S10: default 6, `EquipmentCard.OpenNew()` → `"Maintenance Frequency (Months)".AsInteger()` = 6. Do not call Close (see Risks).
- S11 (negative): default 6, CreateEquipment (Insert(true)) → stored frequency 0.
- S12 (negative): 121 rejected with the specific error.

**Setup page switches**
- S13: Notifications off; OpenEdit → EnableNotifications false, EnableEquipmentRequests and EnableApis true.
- S14: OpenEdit, `EnableEquipmentRequests.SetValue(false)`, Close → Approval Workflows off; Notifications and API Integration still on.
- S15: API Integration off; OpenEdit, `EnableApis.SetValue(true)`, Close → on.
- S16: OpenEdit, set alert days to the 60-day interval and frequency 12, Close → stored 60 and 12.
- S17 (negative): Warranty Alerts and Maintenance Planning off; OpenView → both default fields Visible() false; EnableNotifications Visible() true.

**Enable Notifications** (`[HandlerFunctions('SendNotificationHandler')]`)
- S18 (negative): `RegisterDefaultNotifications()`, Notifications off, equipment E Available; `SendReturnedFromMaintenanceNotification(E."No.", "In Maintenance")` → SentNotificationCount = 0.
- S19: same, feature on → 1.
- S20: `GetFeatureDescription(Notifications)` <> ''.

Existing tests likely affected, expected to still pass: 50198 (ordinal loops include Notifications; no row = enabled), 50184/50187 (setup missing or Init() = 90), 50178/50194 (default 0), 50162 (no change). If any fail in CI, check 50199 uses AutoRollback everywhere.

Manual sandbox checks (go to `docs/TODO.md`):
- S1: admin sees Defaults and Features groups; a Reader sees them read-only.
- S2: switches and Equipment Features page stay in sync both ways.
- S3: Enable Notifications off → no notification on equipment card, maintenance card, Role Center or after posting; on → they return, My Notifications still per user.
- S4: Enable Equipment Requests off behaves like Approval Workflows off (FR-042 S2/S3).
- S5: Enable APIs off → GET on `equipments` errors.
- S6: Default Warranty Alert Days = 30 → warranty alert job creates only alerts within 30 days.
- S7: upgraded tenant shows the field blank and alerts still start at 90 days.
- S8: Default Maintenance Frequency = 6 → a new card shows 6; opening a new card and closing it without input creates no record.
- S9: two companies have independent settings.

## Assumptions

- "Enable Equipment Requests" = FR-042 feature **Approval Workflows** (DECISIONS.md 2026-11-18). "Enable APIs" = **API Integration**.
- "Enable Notifications" = company-wide switch for the equipment in-app notifications, above the per-user My Notifications switch, which stays.
- "Default Warranty Alert Days" = days before warranty end when alert creation starts (standard 90, the longest interval of enum 50105). Not the "Expiring Soon" threshold (30).
- Blank or 0 (rows from before FR-043) means 90; new setup rows get InitValue 90. InitValue does not reach existing rows, so the getter handles 0 and no upgrade code is needed.
- "Default Maintenance Frequency" is in months, range 0..120 like field 23 on table 50100. 0 means no default.
- Settings are per company. Only users with write permission on the setup (EQM - Administrator) change them.
- Test codeunit ID 50199 is the last free test ID (source scan; MCP ID tool unavailable).
- No mismatch between `CLAUDE.md` and `app/app.json`.

## DECISIONS

- FR-043 | Chose to bind Enable Equipment Requests and Enable APIs to the existing FR-042 features (Approval Workflows, API Integration) through page variables, over new Boolean fields on table 50102. New fields would create a second source of truth, and new Booleans read false on existing rows (upgrade code is on the stop list) | Reversible: yes
- FR-043 | Chose a new enum value 5 "Notifications" in "EQM Feature" (missing row = enabled) for Enable Notifications, over a Boolean on table 50102, for the same upgrade reason and so the switch also appears on the Equipment Features page | Reversible: no (published enum value; can only be obsoleted)
- FR-043 | Chose that Notifications off suppresses all four equipment in-app notification paths company-wide, while per-user My Notifications keeps working. Business events, integration events and jobs are not affected | Reversible: yes
- FR-043 | Chose Default Warranty Alert Days = the alert-creation window (1..90, default 90 = today's behaviour), over the Expiring Soon status threshold (30). The threshold drives status, styles and dashboard tiles, and changing it is a wider behaviour change | Reversible: no (published field; semantics can only be changed before release)
- FR-043 | Chose blank/0 = 90 days in the getter plus InitValue 90 for new setups, over upgrade code that fills existing rows | Reversible: yes
- FR-043 | Chose that lowering the alert days keeps already open alerts outside the new window, over cancelling them | Reversible: yes
- FR-043 | Chose to apply the default maintenance frequency in the Equipment Card's OnNewRecord, so the user sees it and can clear it before saving, over the table OnInsert (would also cover API, code and imports, but a deliberate 0 could not be saved) | Reversible: yes
- FR-043 | Chose range checks in OnValidate with an ErrorInfo label, over MinValue/MaxValue properties, for an actionable and testable message | Reversible: yes
- FR-043 | Chose three explicit switches on the setup page, over embedding the whole features list as a part (FR-042 phase 4). The issue names exactly these three options, and the Equipment Features action stays for the rest | Reversible: yes
- FR-043 | Chose to hide each default field when its feature (Warranty Alerts / Maintenance Planning) is off, consistent with FR-042 gating | Reversible: yes
- FR-043 | Chose test codeunit 50199 (MCP ID tool unavailable, IDs from a source scan), the last free ID in the test range | Reversible: yes (test objects are not published)

## Risks

- **Test ID range exhausted** after 50199. The next feature with tests needs the test `app.json` idRanges extended (stop-list item).
- **AL MCP down:** neither the ID tool nor symbol search ran. All symbols are in-app and were read in source. The compile is the final check.
- **S19 (positive notification)** depends on `GuiAllowed()` being true in the AL-Go test session. If CI shows 0, keep the test and report it; do not weaken the guard order. S18 is valid either way.
- **S10 (OpenNew on the card)** leaves the TestPage open on purpose. Closing a new record holding only OnNewRecord values should not insert it, but this is not confirmed on Learn. If teardown raises "Category Code must have a value", the developer reports it and drops the OpenNew test. Do not add Close. Sandbox check S8 covers it.
- **Two entry points for the same switch** (setup page and Equipment Features) write the same row through `SetFeatureEnabled`, so they cannot disagree. An already open page shows the old state until reopened (ToolTips say so).
- **Naming:** "Enable Equipment Requests" appears as "Approval Workflows" on the Equipment Features page; the enum value cannot be renamed (published), so the ToolTip names the mapping.
- **Concurrency:** two administrators switching the same feature for the first time can hit a duplicate insert in `SetFeatureEnabled`; retry works. Accepted, as in FR-042.
- **GenerateAlerts** reads the setup before `LockTable`, so the lock scope does not change. Reviewer confirms the order.
- **API contract:** pages 50123-50126 are not touched. The API does not apply the maintenance default (documented).
- No separate AppSource validation ran. The reviewer checks the AppSource rules: affix, captions, ToolTips, translations, no breaking change (additive fields and enum value only).

## References

- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/properties/devenv-initvalue-property
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/triggers-auto/page/devenv-onnewrecord-page-trigger
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/properties/devenv-delayedinsert-property
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/attributes/devenv-sendnotificationhandler-attribute
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/attributes/devenv-handlerfunctions-attribute
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/properties/devenv-visible-property
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-checklist-submission
- Pattern files: `docs/plans/FR-042-feature-management.md`, `test/src/EQMFeatureMgtTests.Codeunit.al`, `app/src/Setup/EQMEquipmentSetup.Page.al`
