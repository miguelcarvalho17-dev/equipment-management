# FR-023 Equipment Images

## Purpose
Each equipment record can hold one picture (GitHub issue #61). The picture is stored in a MediaSet field and shown in a "Picture" FactBox on the Equipment Card and the Equipment List. Users with edit rights can take, import, export and delete it; importing or taking a new picture replaces the existing one after confirmation, as Item Picture (page 346) does.

Status: describes the code as implemented (uncommitted changes on branch `feature/FR-023-equipment-images`). **Build: not re-run by the documenter; no AL code line was changed by the documentation step.** **Tests: 17 test procedures exist in test codeunit 50178 and compile, but have NOT been run (no sandbox).** Sandbox checks and verification items V2 to V4 are open. App version stays 29.0.0.0. No upgrade codeunit, no event published or subscribed (no events report).

## Known gaps against issue #61 (user decision)
- IM-R3 "multiple images may be attached to a single equipment record" is **intentionally not met**: one picture per equipment, like Item, Employee and Vendor pictures. Importing or taking a picture replaces the existing one.
- Picture types (equipment photo, asset label, manufacturer image) are **not recorded**. The single picture can show any of them; IM-R2 is not met separately.

## Objects
| Type | ID | Name | Change |
|---|---|---|---|
| Table | 50100 | EQM Equipment | Field 24 `Picture` (MediaSet); `Picture` appended to fieldgroup Brick |
| Page | 50122 | EQM Equipment Picture | New CardPart FactBox, source table 50100, caption "Picture" |
| Codeunit | 50117 | EQM Equipment Picture Mgt. | New, `Access = Internal`: set, replace confirmation, import, take, export, delete |
| Page | 50101 | EQM Equipment Card | FactBox part `Picture` (first FactBox, linked on "No."); AboutText sentence added |
| Page | 50100 | EQM Equipment List | FactBox part `Picture` (first FactBox, linked on "No.") |
| PermissionSet | 50100 | EQM - Reader | Execute on page 50122 and codeunit 50117 |
| Codeunit (test app) | 50178 | EQM Equipment Picture Tests | 17 tests, not run |

App `app.json` gets `internalsVisibleTo` for the test app so the tests can call the internal codeunit. The test app now depends on Library Assert and Tests-TestLibraries (29.0.0.0).

## Field
| Field | Meaning |
|---|---|
| 24 Picture | MediaSet holding the equipment picture. Empty until a picture is imported or taken. Data classification inherited from the table (CustomerContent). Shown in tile view through fieldgroup Brick ("No.", Description, Status, Picture). |

## Behavior
The FactBox actions call codeunit 50117; each successful action refreshes the part.

| Action | Visible / enabled | What it does |
|---|---|---|
| Take | Visible when `Camera.IsAvailable()`; enabled with write permission on table 50100 | Asks for confirmation if a picture exists, calls `Camera.GetPicture`, replaces the picture. File name falls back to `<No.>.jpg`. |
| Import | Enabled with write permission | Asks for confirmation if a picture exists, then uploads a file (filter jpg, jpeg, png, gif, bmp, tif, tiff) and replaces the picture. |
| Export | Enabled when a picture exists | Downloads the picture from Tenant Media under its stored file name (fallback `<No.>.jpg`). |
| Delete | Enabled with write permission and a picture | Asks for confirmation, clears the MediaSet, modifies the record. |

- **Replace, never add:** `SetPicture` clears the MediaSet, imports the stream, then `Modify(true)`. `Picture.Count()` is 0 or 1.
- **Saved equipment only:** Take, Import and `SetPicture` raise "Save the equipment before you add a picture." when "No." is blank or the record does not exist.
- **File check:** Import checks only the file extension of the uploaded name; any other extension raises "The file %1 is not a supported picture. Choose a JPG, PNG, GIF, BMP or TIFF file." The extension check does not inspect the content.
- **Confirmations:** the replace question ("The existing picture will be replaced. Do you want to continue?") is asked only when a picture exists; the delete question is "Are you sure you want to delete the picture?". Both use `GetResponseOrDefault(..., false)`, so the default answer is No.
- **Export without picture:** raises "Equipment %1 has no picture to export." (also when the media row or its content is missing).
- **Modify(true):** import and delete run the table's OnModify logic, so equipment checks run and the modified timestamp changes.
- **Lost and Disposed equipment:** pictures are allowed on any status (plan question Q3, not changed).
- **Not changed:** table 50100 `OnDelete` does not touch the picture; cleanup of the media relies on the platform (see V2).

## Setup
No setup. The FactBox appears on the Equipment Card and Equipment List. TODO(verify): the FactBox is visible by default on both pages in the web client.

## Extending (events)
None published, none subscribed. Codeunit 50117 is `internal`; partners cannot call it. XML doc comments are on its internal procedures (repo convention).

## Permissions
| Function | Reader | Manager | Administrator |
|---|---|---|---|
| See the picture, Export | yes (execute on page 50122 and codeunit 50117) | yes | yes |
| Take, Import, Delete | no (actions disabled, no write on table 50100) | yes (table 50100 already RIM) | yes |

Manager and Administrator permission sets are unchanged. TODO(verify) V3: that a Reader can export, i.e. can read Tenant Media. Fallback if not: add `tabledata "Tenant Media" = r` to EQM - Reader.

## Translations
`app/Translations/Equipment Management.g.xlf` is regenerated by the build and shows as modified. Never edit it by hand. TODO(verify): the new captions, tooltips, labels and AboutText are in the file.

## Upgrade and compatibility
New empty field on an unreleased table: no upgrade code. Field 24 and the Brick fieldgroup on the public table 50100 become contract at first release. The card and list only gain a part.

## Known limitations
- One picture per equipment; no picture types.
- Only the file extension is checked on import. Whether `ImportStream` rejects non-image content is TODO(verify) V3.
- The picture is stored in Tenant Media; the size is not limited by this app.

## Test status
- 17 tests in codeunit 50178 (test app, `test/src/EQMEquipmentPictureTests.Codeunit.al`) compile but **have not been run**. They cover: set on empty and replace (Count stays 1), replace confirmation (asked only with a picture, No keeps the picture), unsaved and unknown equipment errors, delete (confirmed, declined, no picture), export without picture, media removal after equipment delete and after Delete (V2), FactBox state on card and list, Reader (Export enabled; Import, Take, Delete disabled; direct `SetPicture` rejected).
- Not covered by automated tests: file upload dialog, unsupported file type, camera, actual download, Take visibility on a device without camera.
- Open verification:
  - V2: the platform deletes the Tenant Media of a deleted record and of a cleared MediaSet (tests 8 and 6d check it; not run). Fallback in the plan: remove the media via `Picture.Remove` before clearing and in `OnDelete`.
  - V3: Reader can export (Tenant Media read access); `Camera.IsAvailable` and `Camera.GetPicture` behave as used; `ImportStream` and non-image content.
  - V4: Item List and Employee List carry a picture FactBox, which is why the Equipment List got one. Not verified.
  - Sandbox checks for the upload filter, unsupported file, export download and camera visibility.

## Discrepancies plan vs code
- None found in behavior. Delivered as in plan revision 3. Additions beyond the plan text: Export also errors when the Tenant Media row or its content is missing; `internalsVisibleTo` and test app dependencies were added for the tests.
