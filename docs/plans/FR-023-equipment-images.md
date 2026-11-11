# FR-023 Equipment Images

> Status: **APPROVED** Revision 3: user decided Q1 = single picture with strict page 346 "Item Picture" behavior (every Import/Take replaces the existing picture after confirmation). The 10-picture maximum (Q2), add-to-set import, multi-picture zip export and "Number of Pictures" field are dropped. See Deviations.
> Source: GitHub issue #61. Branch `feature/FR-023-equipment-images`. No events report: only own objects (table 50100, pages 50100/50101, permission set 50100) and system codeunits are used; no standard behavior is hooked.
> Scope: main app. New: 1 FactBox page, 1 codeunit. Changed: table 50100 (field + fieldgroup), pages 50100 and 50101, permission set 50100. No version bump (29.0.0.0, unreleased). No upgrade code. Tests deferred by default (Q4).

## Goal
Each equipment record can hold one picture in a `Picture` MediaSet field, exactly as Item Picture works, shown in a "Picture" FactBox on the Equipment Card and List. Users with edit rights can take, import, export and delete it; importing or taking a new picture replaces the existing one after confirmation.

## Approach and rejected alternatives
- Chosen: field 24 `Picture` (MediaSet, as the issue requires) on table 50100; CardPart FactBox "EQM Equipment Picture" copying page 346 (actions Take, Import, Export, Delete; replace and delete confirmations with the standard wording); one small internal codeunit holds the logic.
- Codeunit kept for testability: the replace/import core takes an InStream, so it can be tested without a file dialog or camera; the page only handles UI. Cost is one object.
- Rejected: logic inside the page as page 346 does. Not testable without a file dialog.
- Rejected: multiple pictures per equipment (revision 2) and a child image table (revision 1). Superseded by the user's decision.
- Rejected: server-file APIs of older Item Picture code (`MediaSet.ImportFile/ExportFile`, `FileManagement.UploadFile`, `TemporaryPath`). OnPrem scope, not allowed in AppSource; stream APIs instead.

## Objects
IDs in use (checked in `app/src`): tables 50100-50108, pages 50100-50121, codeunits 50103-50116, enums 50100-50107, queries 50100-50103, page ext 50100, permission sets 50100-50102, permission set ext 50103. Table 50100 fields 1-23.

| Type | ID | Name | New/Extend | Purpose |
|---|---|---|---|---|
| Page | 50122 | EQM Equipment Picture | New | CardPart FactBox; file `app/src/Equipment/EQMEquipmentPicture.Page.al` |
| Codeunit | 50117 | EQM Equipment Picture Mgt. | New | `Access = Internal`; set, import, take, export, delete; file `app/src/Equipment/EQMEquipmentPictureMgt.Codeunit.al` |
| Table | 50100 | EQM Equipment | Modify (own) | Field 24 Picture; Picture appended to fieldgroup Brick |
| Page | 50101 / 50100 | EQM Equipment Card / List | Modify (own) | FactBox part "Picture"; AboutText sentence on the card |
| PermissionSet | 50100 | EQM - Reader | Modify (own) | X on page 50122 and codeunit 50117 |
Next free after FR-023: table 50109, page 50123, codeunit 50118, enum 50108, table 50100 field 25. Test: codeunit 50178 "EQM Equipment Picture Tests" reserved (Q4).

## Data model and upgrade impact
- Field 24 `Picture`: MediaSet, Caption 'Picture', ToolTip 'Specifies the picture of the equipment, such as a photo of the asset.' DataClassification inherited from the table (CustomerContent).
- Fieldgroup Brick becomes "No.", Description, Status, Picture (tile view, as Item).
- No upgrade codeunit: new empty field on an unreleased table. `OnDelete` of 50100 not changed (Item does not touch its Picture either; V2).

## Events
Subscribed: none. Published: none (no partner need stated; additive later).

## Permissions
- EQM - Reader: `page "EQM Equipment Picture" = X`, `codeunit "EQM Equipment Picture Mgt." = X` (Reader may view and export).
- EQM - Manager and Administrator: no change. Import/Take/Delete only modify table 50100, already RIM.

## Compatibility
- Development phase, nothing released: no Obsolete handling. Field 24 on Public table 50100 and fieldgroup Brick become contract at first release. Card/List: parts added only. No breaking-change risk.

## Implementation steps
1. Table 50100: field 24 Picture (see Data model) after field 23; append Picture to fieldgroup Brick. Compile.
2. Codeunit 50117, internal procedures with `/// <summary>`, all text in labels with Comments, confirmations via Confirm Management `GetResponseOrDefault(..., false)`:
   - `SetPicture(var Equipment; PictureInStream: InStream; FileName: Text)` (testable core): error `SaveEquipmentFirstErr` ('Save the equipment before you add a picture.') unless "No." is filled and the record exists (`Find`); `Clear(Picture)`; `Picture.ImportStream(PictureInStream, FileName)`; `Modify(true)`. Always replaces, never adds.
   - `ConfirmReplace(Equipment): Boolean`: true when `Picture.Count() = 0`; else confirm `OverrideImageQst` ('The existing picture will be replaced. Do you want to continue?', page 346 wording).
   - `ImportPictureFromFile(var Equipment): Boolean`: saved check; `ConfirmReplace`, No -> false; `UploadIntoStream` with title 'Select a picture to upload' and Locked filter 'Image files|*.jpg;*.jpeg;*.png;*.gif;*.bmp;*.tif;*.tiff'; cancelled -> false; other extension -> `UnsupportedFileErr` ('The file %1 is not a supported picture. Choose a JPG, PNG, GIF, BMP or TIFF file.'); `SetPicture`; true.
   - `TakePicture(var Equipment): Boolean`: saved check; `ConfirmReplace`; `Camera.GetPicture(InStream, PictureName)`; false when cancelled; `SetPicture` with PictureName (fallback '<No.>.jpg').
   - `ExportPicture(Equipment)`: `NoPictureErr` ('Equipment %1 has no picture to export.') when Count = 0; read `Picture.Item(1)` from Tenant Media (`CalcFields Content`); `DownloadFromStream` named by the media Description (fallback '<No.>.jpg').
   - `DeletePicture(var Equipment): Boolean`: false when Count = 0; confirm `DeleteImageQst` ('Are you sure you want to delete the picture?', page 346 wording); `Clear(Picture)`; `Modify(true)`; true.
3. Page 50122 (CardPart, SourceTable 50100, Caption 'Picture', `ApplicationArea = All`, `InsertAllowed/DeleteAllowed/LinksAllowed = false`): field Picture (`ShowCaption = false`). Actions (Processing, each with ToolTip, as page 346): TakePicture ('Take', Image Camera, Visible when `Camera.IsAvailable()` from OnOpenPage), ImportPicture ('Import', Image Import), ExportFile ('Export', Image Export), DeletePicture ('Delete', Image Delete). Take/Import enabled when `Rec.WritePermission()`; Export enabled when a picture exists; Delete when both. Each calls the codeunit then `CurrPage.Update(false)`. Compile.
4. Page 50101: first in FactBoxes `part(Picture; "EQM Equipment Picture")`, SubPageLink "No." = field("No."). AboutText: add "The **Picture** FactBox shows the picture of the equipment; use its actions to take, import, export or delete it."
5. Page 50100: same part, first in FactBoxes.
6. Permission set 50100 (see Permissions). Build; commit regenerated `.g.xlf`.

## Test scenarios
Setup: category LAPTOP, saved equipment E (LT001), Manager user unless stated. Pictures are small PNGs built from Base64 and passed to `SetPicture` (needs `internalsVisibleTo` for the test app). Dialog/camera/download steps are sandbox checks.
1. Given E without a picture, when a picture is set, then `Picture.Count() = 1` and E is modified.
2. Given E with picture A, when picture B is set, then Count = 1 and the media is B (replace, never add).
3. Given E with a picture, when Import/Take is answered No at the replace confirmation, then the picture is unchanged; given E without a picture, then no confirmation is asked.
4. (negative) Given a new unsaved equipment or blank No., when a picture is set, then `SaveEquipmentFirstErr`.
5. (negative) Given an upload "manual.pdf" (sandbox), then `UnsupportedFileErr` and no change.
6. Given E with a picture, when Delete is confirmed, then Count = 0; when answered No, then unchanged; given E without a picture, then Delete returns false and asks nothing.
7. (negative) Given E without a picture, when Export runs, then `NoPictureErr`; given E with a picture (sandbox), then one image file is downloaded.
8. Given E with a picture and no history or maintenance, when an Administrator deletes E, then its Tenant Media rows are gone (V2).
9. Given the Equipment Card and List of E, when opened (TestPage), then the Picture FactBox is present and Export is enabled only when E has a picture.
10. Given a Reader, then Import, Take and Delete are disabled and Export works; (negative) a direct `SetPicture` as Reader raises a permission error.
11. Given a device without camera, then Take is not visible (sandbox: visible in the mobile app).

## Deviations from issue #61 (known gaps, user decision)
- IM-R3 "multiple images may be attached to a single equipment record" is intentionally **not met**: one picture per equipment, consistent with Item, Employee and Vendor pictures.
- The image types "equipment photos, asset labels, manufacturer images" are covered only by that single picture; no type is recorded (IM-R2 not met separately).

## Risks and open questions
- Q3 Pictures allowed on Lost/Disposed equipment. Q4 Tests deferred as in FR-003 to NFR-005; codeunit 50178 reserved, sandbox checks instead.
- V2 Unverified: platform deletes Tenant Media of a deleted record and of a cleared MediaSet (page 346 relies on `Clear` + `Modify` too). Fallback: `SetPicture`/`DeletePicture` and table 50100 `OnDelete` remove the media ID via `Picture.Remove` before clearing.
- V3 Verify against symbols: `Camera.IsAvailable()`, `Camera.GetPicture(var InStream; var Text): Boolean`, `MediaSet.ImportStream` rejecting non-image content, Reader read access to Tenant Media for Export (fallback: `tabledata "Tenant Media" = r` in EQM - Reader).
- V4 Unverified that page 31 Item List / 5201 Employee List carry their picture FactBox; kept on the List because identifying assets while browsing is the purpose of IM-R4. Remove step 5 if the reviewer disagrees.
- Assumed no Description is required before import (page 346 requires one for the export file name) because the export name comes from the stored file name or "No.".
- Assumed `Modify(true)` on import/delete (runs equipment consistency checks and updates SystemModifiedAt, as Item does).
- Docs (documenter): feature doc, help (Picture FactBox actions, replace behavior, known gaps), CHANGELOG (version stays 29.0.0.0), README V3 progress, TODO "FR-023 sandbox checks" (V2-V4, scenarios 5, 7, 11).
