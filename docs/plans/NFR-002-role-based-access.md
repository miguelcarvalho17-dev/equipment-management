# NFR-002 Role-based access

> Status: **APPROVED by the user with the defaults for Q1-Q8.** The plan is written with those defaults,
> and each question says what changes if the user picks the other answer.
> Source: GitHub issue #23. Branch: `feature/NFR-002-role-based-access`.
> No events report: NFR-002 changes only this app's permission sets and five of its own pages. It subscribes to no
> events, publishes none, and changes no standard behavior. The permission set extension on D365 BASIC is not changed.
> al-event-finder is not needed.
> Scope: main app only. **No new objects. Three permission sets renamed and re-scoped (IDs kept), five pages and one
> codeunit comment changed. No change to any table, field or key. No version bump** (app.json stays 29.0.0.0, as in
> FR-004 to FR-009). **No upgrade logic.** **No automated tests by default** (Q7: deferred, as in FR-003 to FR-009; the
> scenarios are a reference, and test codeunit 50162 is reserved).
> Workflow for NFR-002: developer -> reviewer -> build -> **tester step SKIPPED (Q7)** -> documenter ->
> appsource-validator.

## Goal
The app ships three roles as permission sets: **Equipment Reader** (view all equipment data, history, setup and the
dashboard, change nothing), **Equipment Manager** (Reader plus create and change equipment, assign and return it) and
**Equipment Administrator** (full functional access: Manager plus delete equipment, maintain categories and setup).
The existing sets EQM - Read, EQM - Edit and EQM - Admin become these roles. Over-wide rights found in the audit
(indirect insert/modify on setup and categories in the read set) are removed, and the pages for setup and categories
open read-only for users who cannot change them.

### Requirement restated
- S-R1 Role **Equipment Reader**: view data only.
- S-R2 Role **Equipment Manager**: create and modify equipment, perform assignments (assign and return).
- S-R3 Role **Equipment Administrator**: full access.

### Interpretation (defaults, see Q1-Q4)
- "View data" covers every page of the app: equipment list and card, assignment history, categories, setup and the
  dashboard (tiles, charts, Role Center). A Reader changes nothing, also not indirectly (no default data, no setup
  record).
- "Create and modify equipment" includes status changes (In Maintenance, Lost, Disposed). It does **not** include
  deleting equipment (Q1), maintaining categories, or changing the setup.
- "Perform assignments" = Assign to Employee and Return (card and Employee Card). These write assignment entries only
  through codeunit 50106 (indirect rights), as today.
- "Full access" = everything a user can do in the app's UI and through the app's logic. Assignment history stays
  immutable for everyone, the Administrator included (FR-006 design, Q2): nobody may delete or change entries directly.
- Employee data is not part of the roles. Users keep needing the standard **D365 BASIC** set, which grants Employee,
  Location, No. Series and User read (documented since FR-001). Pages must not fail when Employee read is missing
  (Q4).

### Audit of the current state (on this branch)
| Set | Today | Problem |
|---|---|---|
| 50100 EQM - Read | R on equipment and assignments; **Ri** on categories; **Rim** on setup; X on every object | The indirect `i`/`m` let a reader create the setup record, the EQUIP series rows (via codeunit 50105) and the starter categories by opening Equipment Setup (TODO "Setup permissions"). Not "view only". |
| 50101 EQM - Edit | includes Read; RIMD on equipment; Rim on assignments | `D` on equipment goes beyond "create and modify" (Q1). Otherwise matches the Manager role. |
| 50102 EQM - Admin | includes Edit; RIMD on categories and setup | Matches the Administrator role, but a non-SUPER admin cannot create the EQUIP number series when the setup is missing: no EQM set gives the indirect No. Series rights that codeunit 50105 relies on (TODO "New companies"). |
| 50103 EQM D365 BASIC (extension) | indirect `r` on equipment for the Employee delete guard | Correct, unchanged. |

Other audit findings:
- Every object with an ID has X in EQM - Read: tables 50100-50104, queries 50100-50101, pages 50100-50110, codeunits
  50103, 50105, 50106, 50107. Install codeunit 50104 needs none (the platform runs it). The page extension 50100,
  the enums and the profile are not permission objects. There are **no reports** in the app. Nothing is missing.
- Pages 50100, 50101, 50104 and 50105 call `Employee.Get` for the name column with no permission check. Without
  Employee read, every row with an employee raises a permission error (TODO "Assigned Employee Name").
- Page 50103 Equipment Setup always tries to create the setup and the defaults when the record is missing, whoever
  opens it.
- Custom actions Assign to Employee, Return (card) and Return Equipment (Employee Card) have no permission check: a
  Reader gets the platform permission error at the save, after the lookup or the confirmation.
- Actions that only run a page (`RunObject`) are covered by the X permissions, which every role has.

## Approach and rejected alternatives
- Chosen:
  - **Keep the three permission set objects and their IDs (50100-50102), rename them and change their captions now,
    before the first AppSource release:** "EQM - Reader" / 'Equipment Reader', "EQM - Manager" / 'Equipment Manager',
    "EQM - Administrator" / 'Equipment Administrator' (Q3). The app is not released, so there is no baseline and no
    Obsolete cycle. After the first release the names become a contract and cannot change.
  - **Hierarchy by inclusion, as today:** Administrator includes Manager, Manager includes Reader. Each set adds only
    its delta. All three stay `Assignable = true`.
  - **Least privilege per table** (full matrix under Permissions): Reader R only. Manager RIM on equipment plus the
    existing indirect `im` on assignments. Administrator adds D on equipment, RIMD on categories and setup, and
    indirect `ri` on No. Series and No. Series Line (used only through codeunit 50105).
  - **Setup page:** when the setup record is missing, only a user with write permission on the setup creates it and
    the default data. Everyone else gets a clear error that tells them to ask an administrator. The page opens
    read-only for users without write permission on the setup.
  - **Categories page:** opens read-only for users without write permission on categories.
  - **Employee name columns:** guarded with `ReadPermission()` on the Employee record (the FR-008 pattern for the
    User table). Without Employee read the name stays blank instead of failing (Q4).
  - **Enforcement stays in the permission sets.** No code-based role checks. Custom actions are not hidden or
    disabled per role (Q5).
- Rejected: keeping the object names and changing only the captions. The Role ID column (Users, Permission Sets) would
  show "EQM - EDIT" next to 'Equipment Manager' forever, and this is the last moment a rename is free.
- Rejected: new permission set objects (50104-50106) with the role names next to the old sets. That gives six sets for
  three roles, or a removal cycle for the old ones.
- Rejected: user groups. They are replaced by security groups, which are tenant data (often Microsoft Entra
  groups) and cannot ship in an AppSource app. The help explains how to put the sets into security groups.
- Rejected: permission set extensions of standard sets (for example D365 READ or D365 BASIC) to grant the roles. Every
  user of those sets would get equipment rights without the customer deciding. The existing D365 BASIC extension
  (indirect `r` for the Employee delete guard) stays the only one.
- Rejected: `tabledata Employee = R` in EQM - Reader (TODO suggestion). It grants direct read on the whole Employee
  table (addresses, birth date, bank and social security fields) to every equipment reader. That duplicates D365
  BASIC, and AppSource reviewers flag it as over-granting personal data.
- Rejected: indirect Employee read through a new name-lookup procedure with a `Permissions` property (Q4 option B).
  It changes four pages and a codeunit for users who do not have D365 BASIC, which the app requires anyway.
- Rejected: disabling Assign/Return per role with `WritePermission()` on the equipment record. Under Q1 the Manager has
  RIM without D, and `WritePermission()` covers insert, modify and delete together, so the result for partial sets is
  not reliable. It would disable the actions for managers. A permission error at the save is safe.
- Rejected: making the Equipment Card read-only in code. Same `WritePermission()` problem. The client already blocks
  saving without Modify permission (sandbox check SB4).
- Rejected: entitlements. They are for licensed (transact) offers and are not needed for role separation.
- Rejected: a non-assignable "objects only" base set. The X list is small and already lives in the Reader set.

## Objects
IDs in use (checked in `app/src` on this branch): tables 50100-50104, pages 50100-50110, codeunits 50103-50107,
queries 50100-50101, enums 50100-50101, page extension 50100, permission sets 50100-50102, permission set extension
50103, profile "EQM EQUIPMENT MANAGER". Test app: no objects (test codeunits 50150-50161 reserved by FR-001 to FR-009,
none built).

| Type | ID | Name | New/Extend | Purpose |
|---|---|---|---|---|
| PermissionSet | 50100 | EQM - Reader (was EQM - Read) | Modify (own, rename) | Reader role: R on the four stored tables, X on every object |
| PermissionSet | 50101 | EQM - Manager (was EQM - Edit) | Modify (own, rename) | Manager role: includes Reader; RIM on equipment; indirect im on assignments |
| PermissionSet | 50102 | EQM - Administrator (was EQM - Admin) | Modify (own, rename) | Administrator role: includes Manager; D on equipment; RIMD on categories and setup; indirect ri on No. Series tables |
| Page | 50103 | EQM Equipment Setup | Modify (own) | Create the setup and defaults only for users with write permission, else a clear error; read-only without write permission |
| Page | 50102 | EQM Equipment Categories | Modify (own) | Read-only without write permission on categories |
| Page | 50100 | EQM Equipment List | Modify (own) | Employee name only when Employee read is allowed |
| Page | 50101 | EQM Equipment Card | Modify (own) | Same guard on the Assigned Employee Name |
| Page | 50104 | EQM Equipment Assignments | Modify (own) | Same guard on Employee Name |
| Page | 50105 | EQM Assignment History Part | Modify (own) | Same guard on Employee Name |
| Codeunit | 50105 | EQM Default Data | Modify (own, comment only) | Update the permission comment; no code change |

Not changed: tables 50100-50104, pages 50106-50110, codeunits 50103, 50104, 50106, 50107, queries, enums, page
extension 50100, permission set extension 50103, the profile, `app/app.json`, `test/`.
Next free IDs after NFR-002 (unchanged): tables 50105, pages 50111, codeunits 50108, queries 50102, enums 50102, page
extensions 50101, permission sets 50104. Test app: test codeunit **50162 reserved for NFR-002 "EQM Role Permission
Tests", not built now (Q7).**

### Platform names and behaviors to verify before coding (not design choices)
- Permission set object names may be at most 20 characters (they become the Role ID, Code[20]). "EQM - Administrator"
  has 19. If the compiler rejects a name, stop and report; do not shorten it on your own.
- `Record.WritePermission()` and `Record.ReadPermission()` exist on runtime 18 records. `CurrPage.Editable` can be set
  in `OnOpenPage`.
- `Microsoft.Foundation.NoSeries` is the namespace of tables "No. Series" and "No. Series Line" (already used in
  codeunit 50105).

### File renames (use `git mv` so history follows)
- `app/src/Permissions/EQMRead.PermissionSet.al` -> `app/src/Permissions/EQMReader.PermissionSet.al`
- `app/src/Permissions/EQMEdit.PermissionSet.al` -> `app/src/Permissions/EQMManager.PermissionSet.al`
- `app/src/Permissions/EQMAdmin.PermissionSet.al` -> `app/src/Permissions/EQMAdministrator.PermissionSet.al`

### Permission set 50100 "EQM - Reader" (rename and change)
- Object name `"EQM - Reader"`, `Caption = 'Equipment Reader'`, `Assignable = true`, no `IncludedPermissionSets`.
- Table data, all **direct read only**:
  - `tabledata "EQM Equipment" = R` (unchanged)
  - `tabledata "EQM Equipment Assignment" = R` (unchanged)
  - `tabledata "EQM Equipment Category" = R` (**was Ri**)
  - `tabledata "EQM Equipment Setup" = R` (**was Rim**)
- Object X entries: the existing list stays exactly as it is: 5 tables, 2 queries, 11 pages, codeunits "EQM Assignment
  Mgt.", "EQM Employee Subscribers", "EQM Default Data", "EQM Dashboard Mgt.". No `tabledata` entry for the temporary
  cue table.

### Permission set 50101 "EQM - Manager" (rename and change)
- Object name `"EQM - Manager"`, `Caption = 'Equipment Manager'`, `Assignable = true`,
  `IncludedPermissionSets = "EQM - Reader"`.
- `tabledata "EQM Equipment" = RIM` (**was RIMD**: no delete, Q1).
- `tabledata "EQM Equipment Assignment" = Rim` (unchanged: read, plus indirect insert/modify used only by codeunit
  50106).
- Nothing on categories or setup (read comes from Reader).

### Permission set 50102 "EQM - Administrator" (rename and change)
- Object name `"EQM - Administrator"`, `Caption = 'Equipment Administrator'`, `Assignable = true`,
  `IncludedPermissionSets = "EQM - Manager"`.
- `tabledata "EQM Equipment" = RIMD` (**new**: adds delete, Q1).
- `tabledata "EQM Equipment Category" = RIMD` (unchanged).
- `tabledata "EQM Equipment Setup" = RIMD` (unchanged).
- `tabledata "No. Series" = ri` and `tabledata "No. Series Line" = ri` (**new**, indirect only, add
  `using Microsoft.Foundation.NoSeries;`). They take effect only inside codeunit 50105, whose `Permissions` property
  lists the same rights. A non-SUPER administrator can then create the EQUIP series from the setup page in a company
  without setup.
- No entry for "EQM Equipment Assignment" (history is immutable, Q2; read and indirect im are inherited).

### Page 50103 "EQM Equipment Setup" (change)
- New label in `var`: `SetupMissingErr: Label 'The equipment setup has not been created in this company yet. Ask a
  user with the Equipment Administrator permission set to open the Equipment Setup page.'` (one line in the source; no
  placeholders, so no Comment).
- `OnOpenPage` becomes, in this order:
  1. When `Rec.Get()` fails (no setup record):
     - when `Rec.WritePermission()` is false: raise `SetupMissingErr`;
     - otherwise call `DefaultData.CreateDefaultData()` (it creates the setup record itself, then the series and the
       categories), then `Rec.Get()`.
  2. Set the page's editable state at runtime (`CurrPage.Editable`) to the result of `Rec.WritePermission()`.
  The old call `DefaultData.EnsureSetupExists()` is no longer used by the page. Do not remove the procedure from
  codeunit 50105 (it is still called by `CreateDefaultData`).
- Behavior for administrators is unchanged: defaults are created only when the setup record was missing.
- Section order: `layout`, then `var`, then triggers (AL0926).

### Page 50102 "EQM Equipment Categories" (change)
- New trigger `OnOpenPage`: set `CurrPage.Editable` to `Rec.WritePermission()`. Nothing else changes. In lookup mode
  (Category Code on the card) the page still returns the selected record.
- Section order: `layout`, `actions`, then the trigger.

### Pages 50100, 50101, 50104, 50105 (change, Employee name guard)
In each page, the existing `Employee.Get(...)` that fills the name variable runs **only when `Employee.ReadPermission()`
is true** on the local Employee record. Otherwise the name stays `''`. No message, no error.
- 50100 "EQM Equipment List", `OnAfterGetRecord`: condition becomes "Assigned Employee No. is not blank **and**
  Employee.ReadPermission()". The `SetLoadFields` line stays before the Get.
- 50101 "EQM Equipment Card", `UpdateControls`: same condition for `AssignedEmployeeName`. Also add
  `SetLoadFields("First Name", "Middle Name", "Last Name")` before the Get, as on the list.
- 50104 "EQM Equipment Assignments", `OnAfterGetRecord`: Get only when `EmployeeRec.ReadPermission()`.
- 50105 "EQM Assignment History Part", `OnAfterGetRecord`: Get only when `Employee.ReadPermission()`.
- `SelectActiveEmployee` on the card is **not** changed: assigning needs the Employee List, so it needs Employee read
  (D365 BASIC). The ToolTips of the name fields stay as they are; the help explains the blank name.

### Codeunit 50105 "EQM Default Data" (comment only)
Replace the header comment so that it matches NFR-002, with this meaning: every write of setup, categories and No.
Series for the default data happens in this codeunit; its `Permissions` property grants indirect rights that work only
with matching rights in the user's sets. Only EQM - Administrator has them (direct RIMD on setup and categories,
indirect ri on No. Series and No. Series Line). The setup page calls the codeunit only for users with write permission
on the setup. The install codeunit runs it as the installing user. Remove the sentence about EQM - Read having Rim and
Ri. **No code change, the `Permissions` property stays as it is.**

### app.json, translations
- **app.json: no change.** The version stays 29.0.0.0.
- **Translations:** the build regenerates `app/Translations/Equipment Management.g.xlf`: three changed permission set
  captions and the new `SetupMissingErr`. Commit the regenerated file. Never edit it by hand.

## Data model and upgrade impact
- **No schema change.** No table, field or key changes. No DataClassification changes.
- **Permission set rename:** users are assigned to permission sets through the Role ID, which is the object name. In a
  sandbox where users already have "EQM - READ", "EQM - EDIT" or "EQM - ADMIN", those assignments point to sets that no
  longer exist after the publish. Assign the new sets again (sandbox step SB0). This matters only before release,
  because there are no customer tenants yet.
- Upgrade codeunit: not needed (nothing released, nothing stored). If Q3 shows the app **was** already published to a
  customer or AppSource, the rename is replaced by "captions only" (see Q3). No upgrade code would be needed then
  either.

## Events
**Standard BC events: none.** No events report required.

Subscribed: none new. The existing Employee `OnBeforeDeleteEvent` subscriber (codeunit 50103) and its indirect
permission through the D365 BASIC extension are unchanged.

Published: **none.** Permission sets are configuration, not logic. Partners extend roles with their own
`permissionsetextension` objects on "EQM - Reader" / "EQM - Manager" / "EQM - Administrator", or include them in their
own sets. No IsHandled is needed.

## Permissions
### Table data matrix (effective, after inclusion)
| Table | Reader | Manager | Administrator |
|---|---|---|---|
| 50100 EQM Equipment | R | RIM | RIMD |
| 50101 EQM Equipment Category | R | R | RIMD |
| 50102 EQM Equipment Setup | R | R | RIMD |
| 50103 EQM Equipment Assignment | R | R + indirect im | R + indirect im |
| 50104 EQM Equipment Cue (temporary) | X only | X only | X only |
| No. Series, No. Series Line (base) | none (D365 BASIC) | none (D365 BASIC) | + indirect ri |
| Employee, Location, User (base) | none (D365 BASIC) | none (D365 BASIC) | none (D365 BASIC) |

### Functional matrix (what each role may do)
| Object / function | Reader | Manager | Administrator |
|---|---|---|---|
| Equipment list, card, list views, search | view | view, create, change | view, create, change, delete |
| Status changes (In Maintenance, Lost, Disposed) | no | yes | yes |
| Assign to Employee, Return (card), Return Equipment (Employee Card) | no (permission error at save) | yes | yes |
| Assignment history (page 50104, history part, Employee Card > Equipment Assignments) | view | view (entries written only by the app) | view (same) |
| Delete or change assignment entries directly | no | no | no |
| Equipment Categories | view (read-only page) | view (read-only page) | create, change, delete (in-use guard stays) |
| Equipment Setup | view (read-only page); error if setup missing | same as Reader | change; creates setup and defaults when missing |
| Dashboard page, cue tiles, charts, drill-down | yes | yes | yes |
| Equipment Manager Role Center / profile | can choose it; New Equipment fails on save | yes | yes |
| Employee Card actions Equipment Assignments / Assigned Equipment | yes | yes | yes |
| Employee delete guard (codeunit 50103) | works for every user through the D365 BASIC extension, also without an EQM set | | |

### Prerequisite
All three roles assume the standard **D365 BASIC** set (Employee, Location, No. Series, User read; number series
consumption when creating equipment). This has been the documented baseline since FR-001. Without it, a Reader still
sees all equipment data, but employee names are blank (Q4).

### Visibility versus permissions (decision)
- Permissions are the only enforcement. The pages do not check roles or permission set names.
- Actions that open a page through `RunObject` are visible to every role, because all three roles have X on every page.
- The client blocks New, Edit and Delete on pages whose source table the user cannot insert, modify or delete. This is
  platform behavior and is checked in the sandbox (SB4-SB6), not coded.
- The two admin-only maintenance pages (Setup, Categories) are set read-only in code. On those tables the roles differ
  only between R and RIMD, so `WritePermission()` gives a reliable answer.
- Custom code actions (Assign to Employee, Return, Return Equipment) stay visible and enabled for Readers. They fail
  with the platform permission error when the record is saved, and no data is written (Q5).

## Compatibility
- AppSource mode, development phase: nothing is released and there is no baseline (to be confirmed, Q3), so renaming
  the permission sets needs no Obsolete handling.
- **After the first release these become contracts:** the permission set names "EQM - Reader", "EQM - Manager",
  "EQM - Administrator" are stored as Role IDs in every tenant (user and security group assignments) and referenced by
  partner `IncludedPermissionSets` and `permissionsetextension` objects. Renaming or removing them later breaks tenant
  assignments and partner apps. Captions can still change. Removing rights from a set after release is a behavior
  change that needs release notes.
- Behavior changes against today's documentation (all pre-release, listed in CHANGELOG):
  - The Edit/Manager set loses delete on equipment (Q1).
  - The Read/Reader set can no longer create the setup and default data. Opening Equipment Setup in a company without
    setup now raises `SetupMissingErr` for Readers and Managers. This reverses the FR-001 sandbox expectation "a user
    with only EQM - Read can open Equipment Setup in a fresh company".
  - Setup and Categories pages are read-only for non-administrators.
- No public procedure, event, field, key or page ID changes. Codeunit 50105 is internal.
- Doc references to update (documenter, not developer). Historical plans in `docs/plans/` are **not** edited:
  - New `docs/features/NFR-002-role-based-access.md`: requirement, the audit table, both matrices, the
    visibility decision, the prerequisite, the rename mapping (EQM - Read -> EQM - Reader, EQM - Edit -> EQM - Manager,
    EQM - Admin -> EQM - Administrator, IDs unchanged), and open sandbox checks.
  - New `docs/help/NFR-002-role-based-access.md` (end-user/admin help):
    - which role to give whom (the functional matrix in plain words);
    - how an administrator assigns the sets (Users > user card > User Permission Sets, or a security group);
    - that D365 BASIC is required, and what a Reader sees without it (blank employee names);
    - that the **Equipment Manager role center (profile)** is not the same as the **Equipment Manager permission set**:
      anyone can choose the role center, but what they can change depends on their permission set.
  - `docs/help/FR-001` to `FR-009`, section "Before you start: permissions": replace "Equipment - Read / Edit / Admin"
    with "Equipment Reader / Manager / Administrator". In FR-001 help, "Equipment - Edit (create, change, delete
    equipment)" becomes "Equipment Manager (create and change equipment, assign and return)" and "Equipment
    Administrator (also delete equipment and change setup and categories)". In FR-007 help, add one sentence: employee
    names need D365 BASIC. In FR-009 help, add the role center vs. permission set sentence.
  - `docs/features/FR-001` to `FR-009`: replace the old set names with the new ones where they describe current
    behavior. In FR-001, correct the description of Read (now R only on setup and categories) and Edit (now no delete).
    No history narrative.
  - `CHANGELOG.md`: new top section `## NFR-002 Role-based access (version stays 29.0.0.0, no bump)`:
    - Added: help article; read-only Setup and Categories pages for non-administrators; `SetupMissingErr`.
    - Changed: the three set renames and captions (IDs unchanged); Reader drops indirect setup/category rights; Manager
      drops delete on equipment; Administrator gains delete on equipment and indirect No. Series rights; employee
      names are blank instead of an error without Employee read.
    - Fixed: TODO items "Setup permissions" and "Assigned Employee Name".
    - Obsolete: none.
    - A release-notes paragraph, and a note that sandbox users must be given the renamed sets again.
  - `docs/TODO.md`:
    - tick "Setup permissions" and "FR-007 known limitation" (resolved by NFR-002, one line each);
    - replace the FR-001 sandbox check "A user with only EQM - Read can open Equipment Setup in a fresh company" with
      the NFR-002 expectation (SetupMissingErr for Reader/Manager; defaults created for Administrator);
    - under "New companies", add that the administrator path now has the No. Series rights, but defaults are still
      created only on install or when an administrator opens Setup;
    - add the NFR-002 sandbox checks SB0-SB12.

## Test scenarios
**No automated tests in this iteration (Q7 default: deferred, as in FR-003 to FR-009). No test codeunits, no
`test/app.json` change. ID 50162 is reserved, and the tester step is skipped.** The list is the reference for the
user, who writes the tests later in test codeunit 50162 "EQM Role Permission Tests" with
`TestPermissions = Restrictive`.
- Permissions are set with `Library - Lower Permissions` (push D365 BASIC, then add the EQM set by Role ID
  'EQM - READER', 'EQM - MANAGER' or 'EQM - ADMINISTRATOR'). The procedure names in BC 29 are UNVERIFIED and must be
  checked in the test framework symbols.
- Test data is created **before** the permissions are lowered: setup with a fresh number series, categories C1 (active)
  and C2 (active, no equipment), active employee P1 ("First Name" and "Last Name" filled), equipment E1 (C1, Available,
  never assigned), E2 (C1, assigned to P1 through `AssignEmployee`), E3 (C1, assigned to P1 and returned: Available
  with one Closed entry).
- Permission errors are asserted with `Assert.ExpectedErrorCode` for the platform permission error code (UNVERIFIED
  code name, likely 'DB:ClientInsertDenied' / 'DB:ClientModifyDenied' / 'DB:ClientDeleteDenied'). App errors are
  asserted with the label text.
- `[ConfirmHandler]` answers Yes where a return or final status asks for confirmation.

Reader (EQM - Reader + D365 BASIC unless stated)
- R1 Given the test data, when pages 50100, 50101 (E2), 50104, 50102, 50103 and 50109 are opened as TestPages, then no
  error is raised. E2 shows Status Assigned and Assigned Employee Name = P1's full name, and the history part of E2
  shows one Active entry.
- R2 Given a Reader, when a new equipment record is inserted with `Insert(true)`, then a permission error is raised
  and no record exists.
- R3 Given a Reader, when E1.Description is changed and `Modify(true)` is called, then a permission error is raised.
- R4 Given a Reader, when E1 is deleted with `Delete(true)`, then a permission error is raised.
- R5 Given a Reader, when `E1.AssignEmployee(P1)` is called, then a permission error is raised, E1 is still Available,
  and no new assignment entry exists.
- R6 Given a Reader, when `E2.UnassignEmployee()` is called (confirm Yes), then a permission error is raised, E2 is
  still Assigned, and its entry is still Active.
- R7 Given a Reader, when a category is inserted, C2 is modified, or C2 is deleted, then each raises a permission
  error.
- R8 Given a Reader, when the setup record is modified, then a permission error is raised.
- R9 Given a Reader and **no setup record** (deleted before lowering permissions), when page 50103 is opened, then
  `SetupMissingErr` is raised, and no setup record, no new No. Series and no new category exist afterwards.
- R10 Given a Reader and an existing setup, when page 50103 is opened, then the page is not editable ("Equipment Nos."
  not editable).
- R11 Given a Reader, when page 50102 is opened, then the page is not editable and New is not possible.
- R12 Given a Reader, when an assignment entry is inserted, the Active entry is modified, or an entry is deleted
  directly, then each raises a permission error.
- R13 Given a user with **EQM - Reader only (no D365 BASIC)**, when pages 50100, 50101 (E2), 50104 and the history part
  are opened, then no error is raised and the employee name fields are blank. The Assigned Employee No. is still shown.
- R14 Given a Reader, when dashboard page 50109 is opened and Refresh is invoked, then the tiles show the counts (same
  as FR-009 N5).

Manager (EQM - Manager + D365 BASIC)
- M1 Given a Manager, when new equipment with category C1 is inserted with `Insert(true)` (No. blank), then it
  succeeds and gets the next number from the series.
- M2 Given a Manager, when E1.Description is changed and E1.Status is set to "In Maintenance" with `Modify(true)`, then
  both succeed.
- M3 Given a Manager, when `E1.AssignEmployee(P1)` and then `E1.UnassignEmployee()` (confirm Yes) are called, then E1 is
  Available again, and one new entry exists with Status Closed, the Assigned By and Closed By of the test user.
- M4 Given a Manager, when E1 is deleted with `Delete(true)`, then a permission error is raised (Q1) and E1 still
  exists.
- M5 Given a Manager, when a category is inserted, modified or deleted, then each raises a permission error.
- M6 Given a Manager, when the setup is modified, then a permission error is raised. When page 50103 is opened, it is
  not editable.
- M7 Given a Manager and no setup record, when page 50103 is opened, then `SetupMissingErr` is raised and nothing is
  created.
- M8 Given a Manager, when an assignment entry is modified or deleted directly (`Modify(true)` / `Delete(true)`), then
  a permission error is raised (indirect rights only).
- M9 Given a Manager, when page 50101 is opened on E1, then Description is editable and the Assign to Employee action
  is enabled (no regression from the read-only changes).
- M10 Given a Manager, when E1.Status is set to Disposed (confirm Yes) and saved, then it succeeds.
- M11 Given a Manager on the Employee Card of P1, when Return Equipment is invoked and E2 is chosen (modal page handler
  + confirm Yes), then E2 is Available.

Administrator (EQM - Administrator + D365 BASIC)
- A1 Given an Administrator, when E1 (never assigned) is deleted with `Delete(true)`, then it succeeds.
- A2 Given an Administrator, when E3 (Closed history) is deleted, then `DeleteHistoryExistsErr` is raised, not a
  permission error.
- A3 Given an Administrator, when a category is created, C2 is modified, and C2 is deleted, then all succeed. When C1
  (in use) is deleted, then `CategoryInUseErr` is raised.
- A4 Given an Administrator, when the setup "Equipment Nos." is changed, then it succeeds. Page 50103 and page 50102
  open editable.
- A5 Given an Administrator and no setup record, when page 50103 is opened, then the setup record exists with
  "Equipment Nos." = EQUIP, series EQUIP has one line, the seven starter categories exist, and no permission error is
  raised (also proves the indirect No. Series rights).
- A6 Given an Administrator, when an assignment entry is deleted or the Closed entry of E3 is modified directly, then a
  permission error is raised (Q2: history immutable for every role).
- A7 Given an Administrator, when M1-M3 are repeated, then they succeed (inclusion of Manager).

No EQM set (D365 BASIC only)
- N1 Given a user with D365 BASIC only, when page 50100 is opened, then a permission error is raised.
- N2 Given E2 assigned to P1 and a user with D365 BASIC only who may delete employees, when P1 is deleted with
  `Delete(true)`, then `EmployeeHasAssignedEquipmentErr` is raised, not a permission error (regression of FR-001
  scenario 54).

Structure (code review, or a test on the system table "Expanded Permission" if it is readable in tests, UNVERIFIED)
- ST1 Given the three sets, then Reader has no I, M or D (direct or indirect) on any EQM table. Manager has no D on
  equipment and no I/M/D on categories or setup. Administrator matches the table data matrix.
- ST2 Given the three sets, then Administrator includes Manager, Manager includes Reader, all are Assignable, and the
  captions are 'Equipment Reader', 'Equipment Manager' and 'Equipment Administrator'.
- ST3 Given every object with an ID in `app/src` (tables, queries, pages, codeunits except the install codeunit), then
  each has X in EQM - Reader.

### Manual sandbox checks (for the user; these replace the automated tests for now)
- SB0 After publishing, open Permission Sets: EQM - READER / Equipment Reader, EQM - MANAGER / Equipment Manager and
  EQM - ADMINISTRATOR / Equipment Administrator exist, and the old EQM - READ/EDIT/ADMIN are gone. Assign the new sets
  to the test users again (old assignments are orphaned).
- SB1 Create three test users (not SUPER), each with D365 BASIC plus one EQM set, and a fourth with EQM - Reader only.
- SB2 Reader: list, card, history, categories, setup and dashboard open, and nothing can be changed.
- SB3 Reader: Assign to Employee on an Available card: pick an employee, then the permission error appears, and the
  card is unchanged. Return on an Assigned card: confirm, then the permission error appears.
- SB4 Reader on the Equipment List and Card: New and Delete are not offered or are blocked. Typing in a card field
  cannot be saved. Record what the client does (fields locked, or an error at save). If fields stay editable and the
  error appears only at save, note it in TODO (R2). It is not a defect of this plan.
- SB5 Manager: create, change, change status, assign, return. Delete is not offered or fails with a permission error.
- SB6 Manager: Equipment Categories and Equipment Setup open read-only.
- SB7 Administrator: delete never-assigned equipment, maintain categories, change the setup.
- SB8 New company without setup (or delete the setup record as SUPER): Reader and Manager opening Setup get
  `SetupMissingErr`. The Administrator (not SUPER) opening Setup creates EQUIP and the starter categories with no
  permission error.
- SB9 Reader without D365 BASIC: Equipment list, card, Assignments and the history part open with blank employee
  names and no error.
- SB10 Reader on the Equipment Manager Role Center: tiles and charts work; New > Equipment fails on save with a
  permission error.
- SB11 D365 BASIC only: the Employee Card actions Equipment Assignments / Assigned Equipment are hidden or fail with a
  permission error (record which). Deleting an employee with equipment shows the guard error.
- SB12 After the build, `Equipment Management.g.xlf` has the three new permission set captions and `SetupMissingErr`,
  and there are no CodeCop, UICop or AppSourceCop warnings.

## Risks and open questions
Open questions (defaults applied in this plan):
- **Q1 May the Manager delete equipment?** The requirement lists only "create and modify". **Default: no.** Delete is
  for the Administrator (Manager RIM, Administrator RIMD). If yes: Manager keeps RIMD, and the Administrator gets no
  "EQM Equipment" entry. Remove M4 and A1, and add a Manager delete scenario. The FR-001 help keeps "delete" for the
  Manager.
- **Q2 Does "full access" let the Administrator delete or change assignment history?** **Default: no.** History stays
  immutable for everyone, as FR-006 designed. If yes, that needs its own feature (direct D on table 50103, plus a page
  that allows delete, which conflicts with the FR-006 "equipment with history cannot be deleted" rule). It is out of
  scope here.
- **Q3 Rename the permission set objects now, or change only the captions?** **Default: rename now** (names and
  captions), because nothing is released. Please confirm that no version has been published to AppSource or to a
  customer tenant. `CHANGELOG.md` has a "29.1.0.0" heading, while `app.json` and the later plans say 29.0.0.0 with no
  release. If something was published: keep the names "EQM - Read/Edit/Admin" and change only the captions. Then
  ST2, SB0 and the CHANGELOG change accordingly.
- **Q4 Employee names for users without D365 BASIC.** **Default: guard with `ReadPermission()`, so the name is blank.**
  Option B: show the name through an internal lookup procedure with an indirect Employee `r` (in the Reader set and a
  codeunit `Permissions` property). Four pages and one codeunit would change. Option C: direct
  `tabledata Employee = R` in Reader (rejected above, personal data).
- **Q5 Should Assign/Return be hidden or disabled for Readers?** **Default: no.** The platform permission error at
  save is the enforcement. A reliable check would need a dedicated permission helper. That is a later UX item if
  wanted.
- **Q6 The profile "Equipment Manager" (FR-009) and the permission set "Equipment Manager" have the same caption.**
  **Default: keep both.** The help explains that the role center is a home page, not a permission. Alternative: rename
  the profile caption (for example 'Equipment Management'). The profile is not released, so this is free now.
- **Q7 Tests.** **Default: deferred** (test codeunit 50162 reserved, tester step skipped, sandbox checks SB0-SB12 are
  the verification). For a security requirement, the user may want R1-R14, M1-M11, A1-A7 and N1-N2 built now. That
  first needs the test-app fix from `docs/TODO.md` (dependencies on Library Assert / Tests-TestLibraries, remove the
  old `test` property).
- **Q8 Setup missing for non-administrators: error or empty page?** **Default: error `SetupMissingErr`** (clear next
  step). Alternative: open an empty, read-only page. That is confusing, because "Equipment Nos." looks blank and not
  missing.

Risks:
- R1 `WritePermission()` is used only on setup and categories, where the roles hold either R or RIMD. A
  customer-made set with partial rights (for example only M on setup) may get a read-only page although Modify would
  be allowed. This is accepted. Such a user can still change data through other means their set allows.
- R2 Whether the client locks card fields without Modify permission, and whether it hides New/Delete without
  Insert/Delete permission, is platform behavior. It is not verified here (SB4-SB6). If it does not, a Reader can type
  into the card and gets the permission error on save. No data is written. A fix would be a follow-up (Q5 style).
- R3 Creating equipment consumes the number series (modifies "No. Series Line"). That relies on D365 BASIC (or the
  base "No. Series" implementation's own permissions) and is UNVERIFIED for non-SUPER Managers (SB5). If it fails,
  add indirect `m` on "No. Series Line" to the Manager set in a follow-up. Do not grant direct rights.
- R4 The rename orphans existing sandbox assignments (SB0). Anyone testing must reassign the sets.
- R5 Behavior changes against earlier docs: the Manager loses delete, Setup is read-only and raises an error for
  non-admins, and the FR-001 sandbox expectation is reversed. The documenter must update every help file listed under
  Compatibility, or the help contradicts the app.
- R6 Companies created after install still have no setup until an Administrator opens Equipment Setup. Managers cannot
  create equipment there until then (TODO "New companies", not solved by NFR-002).
- R7 After release, the permission set names are a permanent contract (see Compatibility).
- R8 No automated tests (Q7), so permission regressions are caught only by review and the sandbox checks.
