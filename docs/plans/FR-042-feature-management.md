# FR-042 Feature Management — Plan

> Request (verbatim): "FR-042 Feature Management" (GitHub issue #83)
> Status: **approved**

## Request
Add configurable feature activation. An administrator can turn five optional features on or off for each company on a new **Equipment Features** page, with no code changes. The features are Equipment Images, Warranty Alerts, Approval Workflows, API Integration and Maintenance Planning. Each feature can be switched independently. When a feature is off, its UI is hidden and its entry pages refuse to open. FR-043 (#84) owns the centralized setup page, so this change leaves table 50102 alone.
Target: AppSource

Tooling note: the AL MCP still reports "No AL projects are loaded", so `al_getnextobjectid` and `al_symbolsearch` failed. This is the same situation as FR-038 to FR-041. I took the IDs from a scan of every object declaration in `app/src` and `test/src`, plus the reservations in `docs/plans`:
- Pages 50127-50129 are the API reserve.
- Codeunits 50123-50129 are the API reserve.
- Test codeunits 50150-50177 are reserved.
- I followed the house rule "next after the highest in use".

The plan uses no base-application symbol, and no event is published or subscribed. I confirmed the platform methods on Learn (see References). The compile is the final check.

## Definition of done
- [ ] New enum 50112 "EQM Feature" (Extensible = false, Access = Internal) with values 0 Equipment Images, 1 Warranty Alerts, 2 Approval Workflows, 3 API Integration, 4 Maintenance Planning.
- [ ] New table 50114 "EQM Feature Setup" (Access = Internal, per company). Primary key Feature. Field Enabled has InitValue true.
- [ ] **A missing row means enabled.** Existing tenants and new installs therefore behave exactly as today until an administrator turns something off. No install or upgrade code.
- [ ] New page 50140 "EQM Equipment Features" (List, Tell Me, UsageCategory Administration).
  - When a user with write permission opens it, it creates the missing rows (one per enum value, Enabled = true).
  - Shows Feature, Description and Enabled. Only Enabled is editable.
  - Read-only for users without write permission.
  - Reachable from Equipment Setup (Navigation) and from the Role Center Setup section.
- [ ] New codeunit 50138 "EQM Feature Mgt." (Internal) with `IsEnabled`, `CheckEnabled`, `InitializeFeatures`, `SetFeatureEnabled` and `GetFeatureDescription`.
- [ ] Gates applied:

| Feature off | Effect |
|---|---|
| Equipment Images | Picture FactBox hidden on Equipment Card 50101 and Equipment List 50100. |
| Warranty Alerts | Card action Warranty Alerts hidden. Role Center action Warranty Alerts hidden. Cue Open Warranty Alerts hidden. Setup field Warranty Alert Job hidden. Page 50120 errors on open. Warranty notifications (card and Role Center) not sent. The job creates no alerts. The warranty-expired business event is still raised. |
| Approval Workflows | Pages 50133 and 50134 error on open. Role Center action Equipment Requests hidden. Employee Card action Equipment Requests hidden. Cue Requests Pending Approval hidden. |
| API Integration | The 4 API pages (50123-50126) error on open. Setup Integration group hidden. Setup action Integration Event Entries hidden. Page 50132 errors on open. No integration event entries are written. |
| Maintenance Planning | Card Planned Maintenance group and its 3 fields hidden. List column Next Maintenance Date hidden. Maintenance FactBox field Next Maintenance Date hidden. Cue group Planned Maintenance (2 tiles) hidden. |

- [ ] The "feature off" error is an ErrorInfo with the text `The <feature> feature is turned off in this company. To use it, ask an administrator to turn it on in the Equipment Features page.` and a navigation action **Open Equipment Features** (page 50140).
- [ ] Permissions:
  - Reader: R on tabledata 50114, X on table 50114, page 50140 and codeunit 50138.
  - Administrator: RIMD on tabledata 50114.
  - API Consumer: R on tabledata 50114, X on table 50114 and codeunit 50138.
  - Manager: nothing new; it inherits Reader.
- [ ] `app/Translations/Equipment Management.g.xlf` is regenerated with the new captions, ToolTips and labels.
- [ ] `app/` then `test/` compile with 0 errors and 0 warnings (CodeCop, UICop, AppSourceCop on app).
- [ ] New test codeunit 50198 and the 50162 changes compile. Report them as "Not verified: tests not executed locally, CI result pending".

## Out of scope
- Hiding pages from Tell Me search. That needs custom application areas: a table extension on "Application Area Setup", subscribers and re-tagging ApplicationArea on published controls. Learn recommends enabling them in an install codeunit, and existing tenants would need upgrade code. Both are on the stop list. This is phase 2 and needs the user's yes.
- The centralized setup page (FR-043). No field on table 50102 changes.
- Power Automate / business events (FR-029/FR-031), document attachments (FR-024, including image attachments), warranty information fields and warranty-status tiles (FR-014/015/022), overdue open-maintenance monitoring and notifications (FR-020). These are not among the five named features.
- Skipping the approval step when Approval Workflows is off (see DECISIONS). This needs a business rule, so it is phase 2 if the user wants it.
- Any `app.json` change, new permission set, install or upgrade code, published event, or deletion of data when a feature is turned off.

Later phases:
- Phase 2: hide disabled pages from Tell Me through custom application areas (needs install and upgrade codeunits, stop list).
- Phase 3: an optional "requests without approval" mode when Approval Workflows is off (needs a business rule).
- Phase 4: FR-043 embeds the features list in the centralized setup page.

## Objects
| Type | ID | Name | New/Changed | File |
|---|---|---|---|---|
| Enum | 50112 | EQM Feature | New | `app/src/Features/EQMFeature.Enum.al` |
| Table | 50114 | EQM Feature Setup | New | `app/src/Features/EQMFeatureSetup.Table.al` |
| Codeunit | 50138 | EQM Feature Mgt. | New | `app/src/Features/EQMFeatureMgt.Codeunit.al` |
| Page (List) | 50140 | EQM Equipment Features | New | `app/src/Features/EQMEquipmentFeatures.Page.al` |
| PermissionSet | 50100 | EQM - Reader | Changed (+4 lines) | `app/src/Permissions/EQMReader.PermissionSet.al` |
| PermissionSet | 50102 | EQM - Administrator | Changed (+1 line) | `app/src/Permissions/EQMAdministrator.PermissionSet.al` |
| PermissionSet | 50104 | EQM - API Consumer | Changed (+3 lines) | `app/src/Permissions/EQMAPIConsumer.PermissionSet.al` |
| Page | 50101 | EQM Equipment Card | Changed | `app/src/Equipment/EQMEquipmentCard.Page.al` |
| Page | 50100 | EQM Equipment List | Changed | `app/src/Equipment/EQMEquipmentList.Page.al` |
| Page | 50115 | EQM Maintenance FactBox | Changed | `app/src/Maintenance/EQMMaintenanceFactBox.Page.al` |
| Page | 50106 | EQM Equipment Cues | Changed | `app/src/Dashboard/EQMEquipmentCues.Page.al` |
| Page | 50110 | EQM Equipment Manager RC | Changed | `app/src/Dashboard/EQMEquipmentManagerRC.Page.al` |
| Page | 50103 | EQM Equipment Setup | Changed | `app/src/Setup/EQMEquipmentSetup.Page.al` |
| PageExtension | 50100 | EQM Employee Card | Changed | `app/src/Employee/EQMEmployeeCard.PageExt.al` |
| Page | 50120 | EQM Warranty Alerts | Changed | `app/src/Warranty/EQMWarrantyAlerts.Page.al` |
| Page | 50133 | EQM Equipment Requests | Changed | `app/src/Request/EQMEquipmentRequests.Page.al` |
| Page | 50134 | EQM Equipment Request Card | Changed | `app/src/Request/EQMEquipmentRequestCard.Page.al` |
| Page | 50132 | EQM Integration Event Entries | Changed | `app/src/Integration/EQMIntegrationEventEntries.Page.al` |
| Page (API) | 50123, 50124, 50125, 50126 | EQM Equipment / Category / Assignment / Integration Event API | Changed (OnOpenPage only) | `app/src/API/EQMEquipmentAPI.Page.al`, `EQMCategoryAPI.Page.al`, `EQMAssignmentAPI.Page.al`, `EQMIntegrationEventAPI.Page.al` |
| Codeunit | 50112 | EQM Notification Mgt. | Changed (2 guards) | `app/src/Notifications/EQMNotificationMgt.Codeunit.al` |
| Codeunit | 50111 | EQM Warranty Alert Job | Changed (OnRun guard) | `app/src/Warranty/EQMWarrantyAlertJob.Codeunit.al` |
| Codeunit | 50122 | EQM Integration Event Mgt. | Changed (IsEnabled) | `app/src/Integration/EQMIntegrationEventMgt.Codeunit.al` |
| XLIFF | – | Equipment Management.g.xlf | Regenerated by build | `app/Translations/Equipment Management.g.xlf` |
| Codeunit (test) | 50198 | EQM Feature Mgt. Tests | New | `test/src/EQMFeatureMgtTests.Codeunit.al` |
| Codeunit (test) | 50162 | EQM Role Permission Tests | Changed | `test/src/EQMRolePermissionTests.Codeunit.al` |

## Events and standard symbols
No event is published or subscribed to. No base-application object is touched.

| Symbol | Exact signature / usage | Verified with al_symbolsearch |
|---|---|---|
| `Enum::"EQM Feature".Ordinals(): List of [Integer]` and `Enum::"EQM Feature".FromInteger(Value: Integer)` | Loop over the features in InitializeFeatures and the tests | MCP down. Confirmed on Learn (runtime 4.0) |
| `ErrorInfo.Message(Text)`, `ErrorInfo.PageNo(Integer)`, `ErrorInfo.AddNavigationAction([Caption: Text])`, `Error(ErrorInfo)` | Feature-off error with a show-it action | Learn: AddNavigationAction needs runtime 11.0, app runtime is 18.0 |
| Page property `Visible = <global Boolean>`, set in OnOpenPage | All the UI gates | Learn: dynamic for group, part, field and action; variable resolved in OnInit/OnOpenPage |
| `OnOpenPage` on API pages | API gate | Learn: the API page type article uses OnOpenPage |
| `TestPart.Visible()`, `TestField.Visible()`, `TestAction.Visible()` | Tests | Learn (TestPart.Visible needs runtime 15.1) |
| Table 50102 "EQM Equipment Setup" field 4 "Integration Events Enabled" Boolean | Read by 50122 and set in a test | Read in source |
| Codeunit 50122 `internal procedure IsEnabled(): Boolean` | Changed body, same signature | Read in source |
| Codeunit 50112 local `SendEquipmentWarrantyNotification`, `SendOpenWarrantyAlertsNotification` | Guards added | Read in source |
| Codeunit 50111 OnRun (`GenerateAlerts(Today(), true, CreatedCount, CancelledCount)`, `Commit()`, `RaiseWarrantyExpiredEvents(Today())`) | Guard added | Read in source |
| Page "Employee Card" (base) via page extension 50100 | Existing extension, OnOpenPage already present | Read in source. Already compiles today |
| Codeunit "Library Assert" | Tests | Already a dependency of the test app |

## Steps
1. **`app/src/Features/EQMFeature.Enum.al`** (new). The namespace is `MiguelCarvalho.EquipmentManagement`. Add a `/// <summary>` that reads "Optional features of Equipment Management that an administrator can turn on or off per company."
   - Properties: `enum 50112 "EQM Feature"`, `Caption = 'Equipment Feature'; Extensible = false; Access = Internal;`.
   - Values:
     - `value(0; "Equipment Images") { Caption = 'Equipment Images'; }`
     - `value(1; "Warranty Alerts") { Caption = 'Warranty Alerts'; }`
     - `value(2; "Approval Workflows") { Caption = 'Approval Workflows'; }`
     - `value(3; "API Integration") { Caption = 'API Integration'; }`
     - `value(4; "Maintenance Planning") { Caption = 'Maintenance Planning'; }`
   - Write the blocks on several lines, in house style (see `EQMRequestStatus.Enum.al`).

2. **`app/src/Features/EQMFeatureSetup.Table.al`** (new):
   - Declaration: `table 50114 "EQM Feature Setup"`, `Caption = 'Equipment Feature Setup'; DataClassification = CustomerContent; Access = Internal;`. Add a `/// <summary>` that reads "One row per optional feature. A feature without a row is enabled."
   - Field `field(1; Feature; Enum "EQM Feature")`:
     - Caption 'Feature'.
     - ToolTip 'Specifies the optional part of Equipment Management that you can turn on or off.'
   - Field `field(2; Enabled; Boolean)`:
     - Caption 'Enabled', `InitValue = true`.
     - ToolTip 'Specifies whether the feature is turned on in this company. When it is off, its pages, fields, actions and tiles are hidden, and pages that belong only to this feature show an error when they are opened. No data is deleted. Users see the change the next time they open a page.'
   - `keys { key(PK; Feature) { Clustered = true; } }`.
   - No LookupPageId yet; step 3 adds it.

3. **`app/src/Features/EQMFeatureMgt.Codeunit.al`** and **`app/src/Features/EQMEquipmentFeatures.Page.al`** (new, in one step because they reference each other). Also add `LookupPageId = "EQM Equipment Features"; DrillDownPageId = "EQM Equipment Features";` to table 50114.

   Codeunit:
   ```al
   namespace MiguelCarvalho.EquipmentManagement;

   /// <summary>
   /// Feature activation: tells whether an optional feature is turned on in the current company. A feature without a
   /// row in "EQM Feature Setup" is enabled, so nothing changes until an administrator turns a feature off.
   /// </summary>
   codeunit 50138 "EQM Feature Mgt."
   {
       Access = Internal;

       var
           FeatureDisabledErr: Label 'The %1 feature is turned off in this company. To use it, ask an administrator to turn it on in the Equipment Features page.', Comment = '%1 = feature name, for example Warranty Alerts';
           OpenFeaturesLbl: Label 'Open Equipment Features';
           OpenFeaturesDescLbl: Label 'Open the page where administrators turn equipment features on or off.';
           EquipmentImagesDescTxt: Label 'Shows the Picture FactBox on the equipment card and list, where users take, import, export and delete equipment pictures. Pictures that are already stored are kept when the feature is off.';
           WarrantyAlertsDescTxt: Label 'Shows the Warranty Alerts page, its actions, tile and notifications, and lets the daily job create warranty alerts. Warranty dates and the warranty status stay visible when the feature is off.';
           ApprovalWorkflowsDescTxt: Label 'Shows the equipment request process: the Equipment Requests pages, the approval actions and the Requests Pending Approval tile. Requests must be approved before equipment is assigned, so the requests are hidden when the feature is off.';
           ApiIntegrationDescTxt: Label 'Lets external systems use the equipment APIs and shows the integration event settings and entries. When the feature is off, the APIs return an error and no integration event entries are written.';
           MaintenancePlanningDescTxt: Label 'Shows the planned maintenance fields (last maintenance date, maintenance frequency and next maintenance date) and the planned maintenance tiles. The next maintenance date is still calculated when the feature is off.';

       /// <summary>Returns whether the feature is turned on in the current company.</summary>
       /// <param name="Feature">The feature.</param>
       /// <returns>True when the feature has no setup row, when its row is enabled, or when the user cannot read the setup.</returns>
       internal procedure IsEnabled(Feature: Enum "EQM Feature"): Boolean
       var
           FeatureSetup: Record "EQM Feature Setup";
       begin
           // Fail open: feature activation hides UI; it is not a security boundary (permissions are)
           if not FeatureSetup.ReadPermission() then
               exit(true);
           FeatureSetup.SetLoadFields(Enabled);
           if not FeatureSetup.Get(Feature) then
               exit(true);
           exit(FeatureSetup.Enabled);
       end;

       /// <summary>Raises an actionable error when the feature is turned off.</summary>
       /// <param name="Feature">The feature.</param>
       internal procedure CheckEnabled(Feature: Enum "EQM Feature")
       var
           FeatureDisabledError: ErrorInfo;
       begin
           if IsEnabled(Feature) then
               exit;
           FeatureDisabledError.Message(StrSubstNo(FeatureDisabledErr, Format(Feature)));
           FeatureDisabledError.PageNo(Page::"EQM Equipment Features");
           FeatureDisabledError.AddNavigationAction(OpenFeaturesLbl, OpenFeaturesDescLbl);
           Error(FeatureDisabledError);
       end;

       /// <summary>Creates the missing setup rows, one per feature, enabled. Existing rows are not changed.</summary>
       internal procedure InitializeFeatures()
       var
           FeatureSetup: Record "EQM Feature Setup";
           Ordinal: Integer;
       begin
           foreach Ordinal in Enum::"EQM Feature".Ordinals() do
               if not FeatureSetup.Get(Enum::"EQM Feature".FromInteger(Ordinal)) then begin
                   FeatureSetup.Init();
                   FeatureSetup.Feature := Enum::"EQM Feature".FromInteger(Ordinal);
                   FeatureSetup.Enabled := true;
                   FeatureSetup.Insert(true);
               end;
       end;

       /// <summary>Turns a feature on or off, creating its setup row when needed.</summary>
       /// <param name="Feature">The feature.</param>
       /// <param name="NewEnabled">True to turn the feature on.</param>
       internal procedure SetFeatureEnabled(Feature: Enum "EQM Feature"; NewEnabled: Boolean)
       var
           FeatureSetup: Record "EQM Feature Setup";
       begin
           if not FeatureSetup.Get(Feature) then begin
               FeatureSetup.Init();
               FeatureSetup.Feature := Feature;
               FeatureSetup.Enabled := NewEnabled;
               FeatureSetup.Insert(true);
               exit;
           end;
           if FeatureSetup.Enabled = NewEnabled then
               exit;
           FeatureSetup.Enabled := NewEnabled;
           FeatureSetup.Modify(true);
       end;

       /// <summary>Returns the description of what the feature shows and what happens when it is off.</summary>
       /// <param name="Feature">The feature.</param>
       /// <returns>The description.</returns>
       internal procedure GetFeatureDescription(Feature: Enum "EQM Feature"): Text
       begin
           case Feature of
               Feature::"Equipment Images":
                   exit(EquipmentImagesDescTxt);
               Feature::"Warranty Alerts":
                   exit(WarrantyAlertsDescTxt);
               Feature::"Approval Workflows":
                   exit(ApprovalWorkflowsDescTxt);
               Feature::"API Integration":
                   exit(ApiIntegrationDescTxt);
               Feature::"Maintenance Planning":
                   exit(MaintenancePlanningDescTxt);
           end;
           exit('');
       end;
   }
   ```
   - If the compiler rejects the 2-argument `AddNavigationAction` (runtime 12.0), use the 1-argument form and drop OpenFeaturesDescLbl.
   - No Commit and no lock. Every read is a single Get on a 5-row table.

   Page:
   ```al
   namespace MiguelCarvalho.EquipmentManagement;

   page 50140 "EQM Equipment Features"
   {
       Caption = 'Equipment Features';
       PageType = List;
       ApplicationArea = All;
       UsageCategory = Administration;
       AdditionalSearchTerms = 'feature management, feature activation, turn on equipment features, turn off equipment features, enable features, disable features';
       AboutTitle = 'About equipment features';
       AboutText = 'Turn the optional parts of Equipment Management on or off for this company: equipment images, warranty alerts, approval workflows, API integration and maintenance planning. When a feature is off, its pages, fields, actions and tiles are hidden, and pages that belong only to that feature show an error when they are opened. No data is deleted, and turning the feature on again shows everything as before. Users see a change the next time they open a page.';
       SourceTable = "EQM Feature Setup";
       InsertAllowed = false;
       DeleteAllowed = false;

       layout
       {
           area(Content)
           {
               repeater(Features)
               {
                   field(Feature; Rec.Feature)
                   {
                       Editable = false;
                   }
                   field(Description; FeatureDescription)
                   {
                       Caption = 'Description';
                       ToolTip = 'Specifies what the feature shows and what happens when it is turned off.';
                       Editable = false;
                   }
                   field(Enabled; Rec.Enabled)
                   {
                   }
               }
           }
       }

       var
           FeatureMgt: Codeunit "EQM Feature Mgt.";
           FeatureDescription: Text;

       trigger OnOpenPage()
       begin
           if Rec.WritePermission() then
               FeatureMgt.InitializeFeatures()
           else
               CurrPage.Editable := false;
       end;

       trigger OnAfterGetRecord()
       begin
           FeatureDescription := FeatureMgt.GetFeatureDescription(Rec.Feature);
       end;
   }
   ```

4. **Permission sets** (alphabetical placement as in the files):
   - `EQMReader.PermissionSet.al`:
     - Add `tabledata "EQM Feature Setup" = R,` after `tabledata "EQM Equipment Setup" = R,`.
     - Add `table "EQM Feature Setup" = X,` after `table "EQM Equipment Setup" = X,`.
     - Add `page "EQM Equipment Features" = X,` after `page "EQM Equipment Setup" = X,`.
     - Add `codeunit "EQM Feature Mgt." = X,` after `codeunit "EQM Default Data" = X,`.
   - `EQMAdministrator.PermissionSet.al`: add `tabledata "EQM Feature Setup" = RIMD,` after `tabledata "EQM Equipment Setup" = RIMD,`.
   - `EQMAPIConsumer.PermissionSet.al`:
     - Add `tabledata "EQM Feature Setup" = R,` after `tabledata "EQM Equipment Setup" = R,`.
     - Add `table "EQM Feature Setup" = X,` after `table "EQM Equipment Setup" = X,`.
     - Add `codeunit "EQM Feature Mgt." = X,` after `codeunit "EQM Maintenance Mgt." = X,`.
     - Do not add page 50140: test 50162 SCENARIO 4 forbids non-API pages for this role.
   - Why: the API pages and the integration subscriber call IsEnabled in the API Consumer's session.

5. **Build `app/`** (`al_compile` + `al_getdiagnostics`). If the MCP still has no project, use the direct alc build as in FR-039 to FR-041. Fix every warning.

6. **`app/src/Equipment/EQMEquipmentCard.Page.al`**:
   - Globals: add `FeatureMgt: Codeunit "EQM Feature Mgt."; ImagesEnabled: Boolean; WarrantyAlertsEnabled: Boolean; MaintenancePlanningEnabled: Boolean;`.
   - Add before `trigger OnAfterGetRecord()`:
     ```al
     trigger OnOpenPage()
     begin
         ImagesEnabled := FeatureMgt.IsEnabled("EQM Feature"::"Equipment Images");
         WarrantyAlertsEnabled := FeatureMgt.IsEnabled("EQM Feature"::"Warranty Alerts");
         MaintenancePlanningEnabled := FeatureMgt.IsEnabled("EQM Feature"::"Maintenance Planning");
     end;
     ```
   - `group(PlannedMaintenance)`: add `Visible = MaintenancePlanningEnabled;`. Also add the same line to each of its 3 fields ("Last Maintenance Date", "Maintenance Frequency (Months)", "Next Maintenance Date"), so test pages can assert visibility on the fields.
   - `part(Picture; "EQM Equipment Picture")`: add `Visible = ImagesEnabled;`.
   - `action(WarrantyAlerts)`: add `Visible = WarrantyAlertsEnabled;`. Its actionref follows it.
   - Change nothing else. AboutText stays.

7. **`app/src/Equipment/EQMEquipmentList.Page.al`**:
   - Globals: add `FeatureMgt`, `ImagesEnabled` and `MaintenancePlanningEnabled`.
   - Add a `trigger OnOpenPage()` that sets the two Booleans as in step 6.
   - `part(Picture; ...)`: add `Visible = ImagesEnabled;`.
   - `field("Next Maintenance Date"; ...)`: add `Visible = MaintenancePlanningEnabled;`.
   - Leave `"Last Maintenance Date"` and `"Maintenance Frequency (Months)"` unchanged (they stay `Visible = false`; see DECISIONS).

8. **`app/src/Maintenance/EQMMaintenanceFactBox.Page.al`**:
   - Globals: add `FeatureMgt` and `MaintenancePlanningEnabled`.
   - Add `trigger OnOpenPage()` that sets `MaintenancePlanningEnabled`.
   - `field("Next Maintenance Date"; ...)`: add `Visible = MaintenancePlanningEnabled;`.

9. **`app/src/Dashboard/EQMEquipmentCues.Page.al`**:
   - Globals: add `FeatureMgt: Codeunit "EQM Feature Mgt."; ApprovalWorkflowsEnabled: Boolean; WarrantyAlertsEnabled: Boolean; MaintenancePlanningEnabled: Boolean;`.
   - In the existing `OnOpenPage`, add the three assignments as its first statements.
   - Visibility:
     - `"Requests Pending Approval"` gets `Visible = ApprovalWorkflowsEnabled;`.
     - `"Open Warranty Alerts"` gets `Visible = WarrantyAlertsEnabled;`.
     - `cuegroup(PlannedMaintenance)` and both of its fields get `Visible = MaintenancePlanningEnabled;`.
   - The dashboard 50109 and the Role Center embed this part, so both are covered.

10. **`app/src/Dashboard/EQMEquipmentManagerRC.Page.al`**:
    - Add `var FeatureMgt: Codeunit "EQM Feature Mgt."; ApprovalWorkflowsEnabled: Boolean; WarrantyAlertsEnabled: Boolean;`.
    - Add `trigger OnOpenPage()` that sets both Booleans.
    - `action(RequestList)` gets `Visible = ApprovalWorkflowsEnabled;`. `action(WarrantyAlertList)` gets `Visible = WarrantyAlertsEnabled;`.
    - In `area(Sections)` → `group(Setup)`, after `action(EquipmentSetup)`, add `action(EquipmentFeatures) { Caption = 'Equipment Features'; ToolTip = 'Turn the optional equipment features on or off for this company.'; RunObject = page "EQM Equipment Features"; }` on multiple lines.
    - **Fallback:** if the compiler rejects the trigger or the variables on a RoleCenter page, remove only the trigger, the variables and the two Visible lines. Keep the new action. Report it. The target pages are still gated (steps 13-15).

11. **`app/src/Setup/EQMEquipmentSetup.Page.al`**:
    - Globals: add `FeatureMgt: Codeunit "EQM Feature Mgt."; ApiIntegrationEnabled: Boolean; WarrantyAlertsEnabled: Boolean;`.
    - At the very start of the existing `OnOpenPage`, set both Booleans.
    - Visibility:
      - `group(Integration)` and `field("Integration Events Enabled")` get `Visible = ApiIntegrationEnabled;`.
      - `field(WarrantyJobStatus)` gets `Visible = WarrantyAlertsEnabled;`.
      - `action(IntegrationEventEntries)` gets `Visible = ApiIntegrationEnabled;`.
    - In `area(Navigation)`, after `IntegrationEventEntries`, add `action(EquipmentFeatures) { Caption = 'Equipment Features'; ToolTip = 'Turn the optional equipment features on or off for this company: images, warranty alerts, approval workflows, API integration and maintenance planning.'; Image = Setup; RunObject = page "EQM Equipment Features"; }`.
    - Add `, feature management, turn features on or off` to the end of AdditionalSearchTerms.

12. **`app/src/Employee/EQMEmployeeCard.PageExt.al`**:
    - Globals: add `EQMFeatureMgt: Codeunit "EQM Feature Mgt."; EQMApprovalWorkflowsEnabled: Boolean;`.
    - In `OnOpenPage`, after the existing line, add:
      ```al
      // Users without equipment permissions keep today's behaviour and never call the feature codeunit
      EQMApprovalWorkflowsEnabled := true;
      if EQMShowEquipmentFactBox then
          EQMApprovalWorkflowsEnabled := EQMFeatureMgt.IsEnabled("EQM Feature"::"Approval Workflows");
      ```
    - `action(EQMEquipmentRequests)`: add `Visible = EQMApprovalWorkflowsEnabled;`.

13. **`app/src/Warranty/EQMWarrantyAlerts.Page.al`**: in the existing `OnOpenPage`, add a local `FeatureMgt: Codeunit "EQM Feature Mgt.";` and make `FeatureMgt.CheckEnabled("EQM Feature"::"Warranty Alerts");` the first statement.

14. **`app/src/Request/EQMEquipmentRequests.Page.al`** and **`EQMEquipmentRequestCard.Page.al`**: add a `trigger OnOpenPage()` to each (neither has one) with a local FeatureMgt and `FeatureMgt.CheckEnabled("EQM Feature"::"Approval Workflows");`.

15. **`app/src/Integration/EQMIntegrationEventEntries.Page.al`**: add `trigger OnOpenPage()` with `CheckEnabled("EQM Feature"::"API Integration")`.

16. **API pages 50123, 50124, 50125, 50126**: add after the layout block (before the `[ServiceEnabled]` procedure in 50126):
    ```al
    trigger OnOpenPage()
    var
        FeatureMgt: Codeunit "EQM Feature Mgt.";
    begin
        FeatureMgt.CheckEnabled("EQM Feature"::"API Integration");
    end;
    ```
    Change nothing else. Fields and properties are an API contract.

17. **`app/src/Notifications/EQMNotificationMgt.Codeunit.al`**:
    - Add the global `FeatureMgt: Codeunit "EQM Feature Mgt.";`.
    - In `SendEquipmentWarrantyNotification` and in `SendOpenWarrantyAlertsNotification`, add `if not FeatureMgt.IsEnabled("EQM Feature"::"Warranty Alerts") then exit;` directly after the `IsNotificationEnabled` check.
    - The overdue and returned notifications are unchanged.

18. **`app/src/Warranty/EQMWarrantyAlertJob.Codeunit.al`**: replace the OnRun body with:
    ```al
    // Warranty Alerts turned off: no alerts are created. The warranty-expired business event is not part of the feature.
    if FeatureMgt.IsEnabled("EQM Feature"::"Warranty Alerts") then begin
        WarrantyAlertMgt.GenerateAlerts(Today(), true, CreatedCount, CancelledCount);
        // A failing partner subscriber of OnWarrantyExpired must not roll back the alerts that were just created.
        Commit();
    end;
    WarrantyAlertMgt.RaiseWarrantyExpiredEvents(Today());
    ```
    Add the local `FeatureMgt: Codeunit "EQM Feature Mgt.";`.

19. **`app/src/Integration/EQMIntegrationEventMgt.Codeunit.al`**:
    - In `IsEnabled()`, add a local FeatureMgt.
    - Make the first statement `if not FeatureMgt.IsEnabled("EQM Feature"::"API Integration") then exit(false);`.
    - Change the summary to "Checks whether the API Integration feature is on and Integration Events Enabled is switched on in the equipment setup." and the `<returns>` to "True when the feature is on, the setup exists and Integration Events Enabled is on."

20. **Build `app/`** with 0 errors and 0 warnings. Keep the regenerated `.g.xlf`. New trans-units are expected for:
    - the enum, table, field and page captions and ToolTips
    - the 8 codeunit labels
    - 2 new actions
    - the AboutTitle and AboutText
    - the changed AdditionalSearchTerms

21. **`test/src/EQMFeatureMgtTests.Codeunit.al`**: new codeunit 50198 "EQM Feature Mgt. Tests".
    - Header:
      - `namespace MiguelCarvalho.EquipmentManagement.Tests;`
      - usings `Microsoft.HumanResources.Employee; MiguelCarvalho.EquipmentManagement; System.TestLibraries.Utilities;`
      - `Subtype = Test; TestPermissions = Disabled;`
    - Every test has `[Test]` and `[TransactionModel(TransactionModel::AutoRollback)]`, and starts with `Initialize()`, which runs `FeatureSetup.DeleteAll()` (clean slate inside the rollback).
    - Globals:
      - `Assert: Codeunit "Library Assert"`, `FeatureMgt: Codeunit "EQM Feature Mgt."`, `Counter: Integer`.
      - Locked Tok labels: `EquipmentNoTok 'FMEQ%1X'`, `CategoryCodeTok 'FMCAT%1'`, `EmployeeNoTok 'FMEMP%1'`, `CounterFormatTok '<Integer,4><Filler Character,0>'`.
      - A copy of the error label: `FeatureDisabledErr: Label 'The %1 feature is turned off in this company. To use it, ask an administrator to turn it on in the Equipment Features page.', Comment = '%1 = feature name';` with the comment "Copy of the internal label of codeunit 50138", as in `EQMEquipmentPictureTests`.
    - Helpers:
      - `NextId()`
      - `CreateEquipment(): Record` (category Active, Insert(false); equipment Insert(true), as in `EQMMaintCostAnalysisTests`)
      - `CreateEmployee(): Code[20]` (Init, No., First Name, Last Name, Status Active, `Insert(false)`, as in `EQMEquipmentRequestTests` lines 1076-1086)
      - `EnsureEquipmentSetup(IntegrationEventsEnabled: Boolean)` (Get, or Init+Insert(false); set field 4; Modify(false))
      - `AssertFeatureDisabledError(Feature)` = `Assert.ExpectedError(StrSubstNo(FeatureDisabledErr, Format(Feature)))`.
    - Implement the scenarios under Tests, one behaviour per test. The API page and job checks are sandbox checks, not tests.

22. **`test/src/EQMRolePermissionTests.Codeunit.al`**:
    - `ApiConsumerTableDataMatchesMatrix`: add `AssertTableDataRights(ApiConsumerRoleTok, Database::"EQM Feature Setup", 'Y----');` and change the count `7` to `8`.
    - `ApiConsumerExecuteMatchesMatrix`:
      - Add `AssertExecute(ApiConsumerRoleTok, 1, Database::"EQM Feature Setup");` and change the table count `7` to `8`.
      - Add `AssertExecute(ApiConsumerRoleTok, 5, Codeunit::"EQM Feature Mgt.");` and change the codeunit count `10` to `11`.
      - Change the SCENARIO comment to "8 tables, 4 API pages, 11 codeunits, no query".
    - `ApiConsumerCannotWriteCategorySetupOrMaintenance` and `ApiConsumerCannotDeleteEquipmentOrAssignmentsOrEvents`: add one line each for `Database::"EQM Feature Setup"`. In the second, update the comment "seven tables" to "eight tables".
    - Add a new test `OnlyAdministratorCanChangeFeatures` (SCENARIO 9):
      - `AssertTableDataRights(AdministratorRoleTok, Database::"EQM Feature Setup", 'YYYY-');`
      - `AssertNoWriteRights(ManagerRoleTok, Database::"EQM Feature Setup");`
      - `AssertNoWriteRights(ReaderRoleTok, Database::"EQM Feature Setup");`
    - Update the codeunit summary line "scenarios 1 to 8" to "scenarios 1 to 9".

23. **Build `test/`** with 0 errors and 0 warnings. Report the tests as not executed (CI pending).

24. **Documenter** (after review):
    - Write `docs/features/FR-042-feature-management.md` and `docs/help/FR-042-feature-management.md`. The help covers:
      - the page
      - what each feature hides
      - "changes apply when a page is reopened"
      - per company
      - no data is deleted
      - the Tell Me limitation
      - the Approval Workflows behaviour
      - the API error when API Integration is off
    - `CHANGELOG.md`: add the heading `## FR-042 Feature Management (version stays 29.0.0.0, no bump)`.
    - `docs/TODO.md`: add a section "FR-042 sandbox checks" with S1-S10 below. No events report.

## Tests
New codeunit 50198. Every test starts from an empty "EQM Feature Setup".

**Feature Mgt.**
- [SCENARIO 1] Without configuration every feature is enabled.
  - [GIVEN] No feature setup rows.
  - [WHEN] IsEnabled is called for each ordinal of the enum.
  - [THEN] Each returns true.
- [SCENARIO 2] (negative) Turning one feature off leaves the others on (independence).
  - [GIVEN] SetFeatureEnabled(Warranty Alerts, false).
  - [WHEN] IsEnabled is called for all five.
  - [THEN] Warranty Alerts is false and the other four are true.
- [SCENARIO 3] A feature can be turned on again.
  - [GIVEN] Approval Workflows was turned off.
  - [WHEN] SetFeatureEnabled(Approval Workflows, true).
  - [THEN] IsEnabled is true, and exactly one row exists for it.
- [SCENARIO 4] InitializeFeatures creates one enabled row per feature and keeps existing choices.
  - [GIVEN] Maintenance Planning was set off.
  - [WHEN] InitializeFeatures runs twice.
  - [THEN] Count = `Enum::"EQM Feature".Ordinals().Count()`, Maintenance Planning is still off, and every other row is Enabled.
- [SCENARIO 5] (negative) CheckEnabled on a disabled feature raises the specific error.
  - [GIVEN] API Integration off.
  - [WHEN] `asserterror FeatureMgt.CheckEnabled(API Integration)`.
  - [THEN] AssertFeatureDisabledError(API Integration).
- [SCENARIO 6] CheckEnabled on an enabled feature passes.
  - [GIVEN] No rows.
  - [WHEN] CheckEnabled(API Integration).
  - [THEN] No error. Assert `IsEnabled` is true as an anchor.

**Configuration without code (page 50140)**
- [SCENARIO 7] An administrator turns a feature off on the Equipment Features page.
  - [GIVEN] No rows.
  - [WHEN] Equipment Features is opened with OpenEdit (rows are created), GoToKey(Equipment Images), Enabled set to false, and the page is closed.
  - [THEN] Five rows exist and IsEnabled(Equipment Images) is false.

**Visibility (positive and negative per page)**
- [SCENARIO 8] (negative) The Equipment Card hides the controls of disabled features.
  - [GIVEN] Equipment Images, Warranty Alerts and Maintenance Planning off, and equipment E.
  - [WHEN] The card is opened (OpenView, GoToRecord E).
  - [THEN] `Picture.Visible()` is false, `WarrantyAlerts.Visible()` is false, `"Next Maintenance Date".Visible()` is false, and `MaintenanceFactBox."Next Maintenance Date".Visible()` is false.
- [SCENARIO 9] The Equipment Card shows them when the features are on.
  - [GIVEN] No rows.
  - [WHEN] The card is opened.
  - [THEN] All four are true.
- [SCENARIO 10] (independence at UI level) Only Images off.
  - [WHEN] The card is opened.
  - [THEN] Picture is hidden, and WarrantyAlerts and "Next Maintenance Date" are visible.
- [SCENARIO 11] (negative) The Equipment List hides the Picture part and Next Maintenance Date.
  - [GIVEN] Images and Planning off.
  - [THEN] Both Visible() are false.
  - Also: with no rows, both are true. Use two tests, one behaviour each.
- [SCENARIO 12] (negative) The Cues hide the tiles of disabled features.
  - [GIVEN] Approval Workflows, Warranty Alerts and Maintenance Planning off.
  - [WHEN] TestPage "EQM Equipment Cues" is opened with OpenView.
  - [THEN] "Requests Pending Approval", "Open Warranty Alerts" and "Planned Maintenance This Month" are not visible, and "Total Equipment" is visible.
- [SCENARIO 13] (negative) The Setup page hides the integration and warranty job controls.
  - [GIVEN] EnsureEquipmentSetup(false); API Integration and Warranty Alerts off.
  - [WHEN] The Equipment Setup page is opened.
  - [THEN] "Integration Events Enabled", WarrantyJobStatus and IntegrationEventEntries are not visible, and EquipmentFeatures is visible.
- [SCENARIO 14] (negative) The Employee Card hides Equipment Requests when Approval Workflows is off.
  - [GIVEN] Employee X; Approval Workflows off.
  - [WHEN] Employee Card is opened on X.
  - [THEN] `EQMEquipmentRequests.Visible()` is false and `EQMAssignedEquipment.Visible()` is true.

**Entry pages refuse to open**
- [SCENARIO 15] (negative) Warranty Alerts page with the feature off.
  - [WHEN] `asserterror WarrantyAlerts.OpenView()`.
  - [THEN] AssertFeatureDisabledError(Warranty Alerts).
- [SCENARIO 16] Warranty Alerts page opens when the feature is on.
  - [GIVEN] No rows.
  - [THEN] OpenView succeeds; Close.
- [SCENARIO 17] (negative) Equipment Requests list and Request Card with Approval Workflows off.
  - [THEN] Both OpenView calls raise the feature error. Use two asserterror blocks in one test, since both are the same rule.
- [SCENARIO 18] (negative) Integration Event Entries with API Integration off.
  - [THEN] The feature error is raised.

**Behaviour**
- [SCENARIO 19] (negative) No integration events are written while API Integration is off.
  - [GIVEN] EnsureEquipmentSetup(true); API Integration off.
  - [WHEN] `IntegrationEventMgt.IsEnabled()` is called (codeunit 50122, internal, reachable through internalsVisibleTo).
  - [THEN] It is false.
- [SCENARIO 20] The same with the feature on.
  - [GIVEN] No rows, setup flag on.
  - [THEN] IsEnabled is true.

**Permissions (50162)**
- [SCENARIO 2 extended] The API Consumer matrix includes Feature Setup (R) and Feature Mgt. (X).
- [SCENARIO 4 existing] Page 50140 is picked up automatically. It is a negative check: API Consumer has no entry for it.
- [SCENARIO 8 existing] Reader has X on table 50114, page 50140 and codeunit 50138, picked up automatically.
- [SCENARIO 9 new] (negative) Only the Administrator can write Feature Setup. Reader and Manager cannot.

Existing tests likely affected:
- 50162 (changed on purpose; the counts change from 7/7/10 to 8/8/11).
- These tests open the gated pages and still pass, because no rows means enabled:
  - 50178 (card and list Picture part)
  - 50194 (card FactBoxes)
  - 50188 and 50189 (request pages, Employee Card action)
  - 50161 (Cues)
  - 50186 (integration events; IsEnabled now also reads the feature table)
- If one of them fails in CI with "feature is turned off", a test left a row behind. Check that codeunit 50198 uses AutoRollback everywhere.

Manual sandbox checks (go to `docs/TODO.md`):
- S1: An administrator opens Equipment Features from Tell Me. It shows 5 enabled rows. A Reader opens it read-only.
- S2: Turn each feature off, reopen the card, list, dashboard, Role Center, setup and Employee Card, and confirm the controls are hidden. Turn it on again and confirm they come back.
- S3: Turn Warranty Alerts or Approval Workflows off and find the page in Tell Me. Opening it shows the error with **Open Equipment Features**, and the action opens page 50140. Record that Tell Me still lists the page.
- S4: With API Integration off, run GET on `equipments` and the POST `markProcessed` action. Record the HTTP status and message. With the feature on, they work.
- S5: With Warranty Alerts off, run the Warranty Alert job. No new alerts and no Power Automate "warranty expiring" flow. Turn it on and run again: the due alerts are created.
- S6: With API Integration off and Integration Events Enabled on, assign equipment. No integration event entry is written.
- S7: The Role Center actions Equipment Requests and Warranty Alerts are hidden when their features are off (dynamic Visible on a RoleCenter page; see Risks).
- S8: An HR user without EQM permission sets opens the Employee Card without error.
- S9: Two companies: turning a feature off in one does not affect the other.
- S10: A page that is already open keeps its state until it is reopened. Confirm the help text matches.

## Assumptions
- Assumed **no row means enabled**, because the five features are live in every installed tenant today. Boolean fields with InitValue true do not reach existing rows. Defaulting to off would hide features on upgrade, and seeding rows would need install or upgrade code (stop list).
- Assumed feature activation is **per company** (normal table, DataPerCompany), the same as Equipment Setup.
- Assumed the five features map to existing functionality as follows:
  - Equipment Images = FR-023 Picture FactBox (not document attachments).
  - Warranty Alerts = FR-016 alerts page, job, tile and notifications. Warranty dates and status (FR-014/015/022) are not part of it.
  - Approval Workflows = FR-032/FR-033 request process.
  - API Integration = the 4 API pages plus the FR-030 integration event outbox. Power Automate business events are not part of it.
  - Maintenance Planning = FR-019 planned maintenance fields and tiles. FR-020 overdue open-record monitoring is not part of it.
- Assumed "not visible" means hidden through Visible on fields, parts, actions and tiles, and an actionable error when an entry page is opened by URL, Tell Me, drill-down or notification. Tell Me cannot be filtered without application areas.
- Assumed changes apply the next time a page is opened, because Visible variables are resolved in OnOpenPage (Learn).
- Assumed IsEnabled **fails open** when the user cannot read the setup. Feature activation is not a security boundary; permission sets are.
- Assumed only the Administrator role changes features (RIMD). Manager and Reader read them.
- Assumed data is never deleted or changed when a feature is turned off: pictures, alerts, requests and integration entries stay and reappear when the feature is turned on.
- Assumed IDs 50112 (enum), 50114 (table), 50138 (codeunit), 50140 (page) and 50198 (test), each the next after the highest in use (house rule). The gap at codeunits 50100-50102 stays unused. After this change only test codeunit 50199 is free.
- No mismatch found between `CLAUDE.md` and `app/app.json`.

## DECISIONS
- FR-042 | Chose a new table "EQM Feature Setup" keyed by enum "EQM Feature" with "missing row = enabled" over Boolean fields on table 50102 "EQM Equipment Setup", because new Boolean fields read false on existing rows and would turn every feature off on upgrade unless upgrade code ran (stop list). It also keeps table 50102 free for FR-043 | Reversible: no (published table and enum; can only be obsoleted)
- FR-042 | Chose Visible variables set in OnOpenPage plus an actionable ErrorInfo on entry pages over custom application areas ("Application Area Setup" extension, experience-tier subscribers, re-tagging ApplicationArea), because application areas need install and upgrade code to be safe for existing tenants (stop list). Limitation: disabled pages stay listed in Tell Me and show an error when opened | Reversible: yes (phase 2)
- FR-042 | Chose that Approval Workflows off hides the whole equipment request process over letting requests skip approval, because requests can only be completed after approval (codeunit 50132 CheckApproved), and skipping approval would be a new business rule. The user can choose the other option when approving the plan | Reversible: yes
- FR-042 | Chose that API Integration off also stops writing integration event entries (codeunit 50122 IsEnabled) over UI-only gating, so the outbox does not grow unseen while its API is closed | Reversible: yes
- FR-042 | Chose that Warranty Alerts off stops alert creation in the daily job while the warranty-expired business event is still raised, over leaving the job untouched, because new alerts would fire the Power Automate "warranty expiring" flow for a hidden feature | Reversible: yes
- FR-042 | Chose to gate only the default-visible list column "Next Maintenance Date" and leave the hidden-by-default columns "Last Maintenance Date" and "Maintenance Frequency (Months)" as Visible = false, because a variable would make them visible by default when the feature is on | Reversible: yes
- FR-042 | Chose fail-open (treated as enabled) when the user cannot read the feature setup, over fail-closed, because activation hides UI and is not a permission mechanism | Reversible: yes
- FR-042 | Chose entry points Tell Me (Administration), an Equipment Setup Navigation action and a Role Center Setup section action over a separate menu | Reversible: no (published actions cannot be removed, AS0031; they can be obsoleted)
- FR-042 | Chose IDs enum 50112, table 50114, codeunit 50138, page 50140 and test codeunit 50198 (MCP ID tool unavailable, IDs from a source scan) | Reversible: yes

## Risks
- **Tell Me still lists disabled pages** (Warranty Alerts, Equipment Requests). This partly misses "not visible". It is mitigated by the actionable error and documented in the help. The full fix is phase 2 (application areas) and needs the user's yes.
- **Dynamic Visible on a RoleCenter page** (step 10) is not confirmed on Learn for navigation-menu actions. If the compile fails or S7 shows the actions anyway, apply the step 10 fallback and report it. Do not work around it silently.
- **API OnOpenPage** behaviour on POST and bound actions needs sandbox check S4. Learn shows OnOpenPage on API pages, but not the HTTP status of an error raised there.
- **Test ID range:** after 50198 only 50199 is free. Extending the range is an `app.json` change (stop list).
- **Execute permission:** callers without EQM permission sets must not reach codeunit 50138. The Employee Card extension only calls it when the user can read equipment (step 12). The reviewer checks that no other base-page extension calls it.
- **Concurrent first open of page 50140** by two administrators: the second Insert can fail with a duplicate key, and the page closes. Reopening works. This is accepted and is not worth a lock.
- **Already open pages** keep their visibility until reopened. This is documented in the ToolTip, AboutText and help.
- **Approval Workflows decision** changes what users see more than any other gate. The main agent should point it out when asking for plan approval.
- **API contract:** adding OnOpenPage does not change the API schema. The reviewer confirms no field or property changed on 50123-50126.
- **Analyzer:** the enum has a value with ordinal 0 that is a real feature (not blank). This is intended. If CodeCop flags the enum key, report it; do not renumber.
- No separate AppSource validation ran. The reviewer checks the AppSource rules (affix, captions, ToolTips, translations, no breaking change).

## References
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-extending-application-areas — custom application areas need an "Application Area Setup" extension, experience-tier subscribers and enabling in OnInstallAppPerCompany (why they are phase 2)
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/properties/devenv-visible-property — dynamic Visible with global Boolean variables on groups, parts, fields and actions, resolved in OnInit/OnOpenPage; users cannot force a control visible while the variable is false
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/triggers-auto/page/devenv-onopenpage-page-trigger — OnOpenPage sets Visible; an error in it closes the page
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-api-pagetype — OnOpenPage used on API pages
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/errorinfo/errorinfo-addnavigationaction-string-string-method — AddNavigationAction(Caption, Description), runtime 12.0
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/errorinfo/errorinfo-pageno-method — PageNo as the target of the show-it action
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/enum/enum-ordinals--method and https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/enum/enum-frominteger-method — looping over the enum
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/testpart/testpart-visible-method — TestPart.Visible (runtime 15.1)
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-checklist-submission — AppSource technical validation checklist (captions, ToolTips, translations, no breaking changes)
- Pattern files: `app/src/Setup/EQMEquipmentSetup.Page.al` (WritePermission and Editable in OnOpenPage), `app/src/Employee/EQMEmployeeCard.PageExt.al` (Visible variable), `test/src/EQMEquipmentPictureTests.Codeunit.al` (TestPage part checks and label copies), `docs/plans/FR-041-maintenance-cost-analysis.md` (house format)
