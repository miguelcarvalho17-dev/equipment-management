# NFR-002 Role-based access

## Purpose
The app ships three roles as permission sets: **Equipment Reader** (view only), **Equipment Manager** (create and change equipment, assign and return) and **Equipment Administrator** (full functional access). Enforcement is in the permission sets only; pages do not check role names.

## Objects
| Type | ID | Name | Change |
|---|---|---|---|
| PermissionSet | 50100 | EQM - Reader | Renamed from EQM - Read, caption 'Equipment Reader'. Direct R only; was Ri on categories and Rim on setup. |
| PermissionSet | 50101 | EQM - Manager | Renamed from EQM - Edit, caption 'Equipment Manager'. Equipment is RIM (was RIMD). |
| PermissionSet | 50102 | EQM - Administrator | Renamed from EQM - Admin, caption 'Equipment Administrator'. Adds delete on equipment and indirect No. Series rights. |
| Page | 50103 | EQM Equipment Setup | Creates setup and defaults only with write permission; read-only without it. |
| Page | 50102 | EQM Equipment Categories | Read-only without write permission. |
| Page | 50100 / 50101 / 50104 / 50105 | Equipment List / Card / Assignments / Assignment History Part | Employee name is filled only when the user has Employee read permission. |
| Codeunit | 50105 | EQM Default Data | Header comment only; no code change. |

Object IDs are unchanged. No table, field, key, event or upgrade change. `app.json` stays 29.0.0.0. The permission set extension 50103 (D365 BASIC) is unchanged. Rename mapping: EQM - Read -> EQM - Reader, EQM - Edit -> EQM - Manager, EQM - Admin -> EQM - Administrator.

## Setup
1. Assign one EQM set per user: Users > user card > User Permission Sets, or a security group that contains the set.
2. Every user also needs the standard **D365 BASIC** set (Employee, Location, No. Series, User read). The EQM sets do not grant it.
3. In a sandbox where users held the old sets (EQM - READ/EDIT/ADMIN), assign the new sets again; the old assignments point to sets that no longer exist.
4. An Administrator opens **Equipment Setup** once in each company that has no setup record. Readers and Managers cannot create it.

## Behavior
- **Hierarchy by inclusion:** Administrator includes Manager, Manager includes Reader. All three are `Assignable = true`.
- **Equipment Setup (page 50103), `OnOpenPage`:** when the setup record is missing and the user has no write permission on it, error `SetupMissingErr` ("The equipment setup has not been created in this company yet. Ask a user with the Equipment Administrator permission set to open the Equipment Setup page."). With write permission, `CreateDefaultData` runs and the record is read. Afterwards the page is set not editable when the user has no write permission.
- **Equipment Categories (page 50102):** `OnOpenPage` sets the page not editable without write permission on categories. Lookup mode is untouched.
- **Employee name columns:** `Employee.Get` runs only when `Employee.ReadPermission()` is true. Without it the name stays blank, with no error. The Assigned Employee No. is still shown.
- **Custom actions** (Assign to Employee, Return, Return Equipment) are not hidden or disabled per role. A Reader gets the platform permission error when the record is saved. Assigning also needs Employee read (the Employee List lookup).
- **Assignment history is immutable for every role,** the Administrator included. Entries are written only through codeunit 50106 (indirect rights).
- The profile "Equipment Manager" (FR-009 Role Center) and the permission set 'Equipment Manager' share a caption but are unrelated. Anyone can choose the role center; what they can change depends on their set.

## Permissions
Effective table data after inclusion:
| Table | Reader | Manager | Administrator |
|---|---|---|---|
| 50100 EQM Equipment | R | RIM | RIMD |
| 50101 EQM Equipment Category | R | R | RIMD |
| 50102 EQM Equipment Setup | R | R | RIMD |
| 50103 EQM Equipment Assignment | R | R, indirect im | R, indirect im |
| 50104 EQM Equipment Cue (temporary) | X | X | X |
| No. Series, No. Series Line (base) | none | none | indirect ri (used only inside codeunit 50105) |

- Execute (X) on every table, query, page and the codeunits 50103, 50105, 50106, 50107 is granted in EQM - Reader and inherited. The install codeunit needs none. There are no reports.
- Employee, Location and User read come from D365 BASIC. `tabledata Employee = R` was deliberately not added to Reader (it would expose personal data to every reader).
- D365 BASIC extension 50103: indirect read on equipment for the Employee delete guard. Unchanged.

What each role may do:
| Function | Reader | Manager | Administrator |
|---|---|---|---|
| View list, card, history, categories, setup, dashboard | yes | yes | yes |
| Create and change equipment, change status | no | yes | yes |
| Assign and return | no | yes | yes |
| Delete equipment (history and assigned guards still apply) | no | no | yes |
| Maintain categories and setup | no | no | yes |
| Create setup and defaults when missing | no (error) | no (error) | yes |
| Change or delete assignment entries directly | no | no | no |

FR-011 update (maintenance, from code reading, not run in a sandbox):
| Table | Reader | Manager | Administrator |
|---|---|---|---|
| 50105 EQM Maintenance Record | R | RIM | RIM (inherited; delete always refused by the table) |
| 50106 EQM Maintenance History Entry | R | indirect i | indirect i (inherited) |

| Function | Reader | Manager | Administrator |
|---|---|---|---|
| See maintenance history | yes | yes | yes |
| Register and correct an Open maintenance record | no | yes | yes |
| Post a maintenance record | no (permission error) | yes | yes |
| Change a Posted record | no | no (business error) | no (business error) |
| Insert, change, rename or delete a history entry directly | no | no | no |

Partners extend roles with their own `permissionsetextension` on these sets. No events are published or subscribed by this feature.

## Upgrade and compatibility
Nothing was released, so the renames need no Obsolete handling and no upgrade code. After the first release the names "EQM - Reader", "EQM - Manager" and "EQM - Administrator" are stored as Role IDs in tenants and become a contract; captions can still change.

Behavior changes against earlier docs: Manager loses delete on equipment; Reader and Manager can no longer create setup and defaults (this reverses the former FR-001 sandbox expectation); Setup and Categories are read-only for non-administrators; employee names are blank instead of an error without Employee read.

## Known limitations / verification pending
- **Not verified in a sandbox.** Checks SB0-SB12 are open (listed in `docs/TODO.md`).
- **No automated tests.** Deferred by decision (Q7); test codeunit 50162 is reserved and not built.
- Built with no warnings; review verdict approve with changes, fixes applied.
- TODO(verify) (SB4): whether the client locks card fields and hides New/Delete without Modify/Insert/Delete permission. If not, a Reader gets the permission error at save and nothing is written.
- TODO(verify) (SB5): whether a Manager who is not SUPER can consume the number series when creating equipment. If not, the follow-up is indirect `m` on "No. Series Line" in the Manager set.
- TODO(verify) (SB8): the Administrator (not SUPER) creating EQUIP and the starter categories through the indirect rights in codeunit 50105.
- TODO(verify) (SB11): what a user with D365 BASIC only sees on the Employee Card actions Equipment Assignments / Assigned Equipment.
- `WritePermission()` is a combined check. A customer-made set with partial rights (for example only modify on setup) may get a read-only Setup or Categories page.
- Companies created after install still have no setup until an Administrator opens Equipment Setup (TODO "New companies"); Managers cannot create equipment there until then.
- `app/Translations/Equipment Management.g.xlf` is regenerated by the build; it contains the three new captions and `SetupMissingErr`.

## Discrepancies plan vs code
None that change behavior. The plan sets `CurrPage.Editable` to the write-permission result; the code only sets it to false when write permission is missing (same outcome).
