# Equipment pictures (AppSource end-user help)

Each piece of equipment can have one picture, for example a photo of the asset. The picture is shown in the **Picture** FactBox on the **Equipment Card** and the **Equipment List**.

## Before you start: permissions
- **Equipment Reader**: can see the picture and **Export** it. **Take**, **Import** and **Delete** are disabled.
- **Equipment Manager** and **Administrator**: can also take, import and delete the picture.

TODO(verify): that Export works for a Reader in a sandbox.

## What you can do
Open an equipment record, or select it in the list, and look at the **Picture** FactBox.

| Action | What it does |
|---|---|
| **Take** | Takes a picture with the device camera. Only shown when your device has a camera. |
| **Import** | Uploads a picture file from your computer. Supported files: JPG, JPEG, PNG, GIF, BMP, TIF, TIFF. |
| **Export** | Downloads the picture as a file. Available when the equipment has a picture. |
| **Delete** | Removes the picture after you confirm. Available when the equipment has a picture. |

## Add or replace a picture
1. Open the equipment and save it first. A new equipment that is not saved yet cannot get a picture.
2. In the **Picture** FactBox, choose **Import** (or **Take**).
3. If the equipment already has a picture, confirm that it will be replaced.
4. Select the file (or take the photo). The new picture appears in the FactBox.

## Good to know
- **One picture per equipment.** Importing or taking a new picture replaces the existing one; you cannot keep several pictures. This is a known gap against the original requirement for multiple images.
- The app does not record what the picture shows (equipment photo, asset label or manufacturer image).
- If you choose a file of another type (for example a PDF), you get a message and the picture is not changed.
- If you choose **No** at the replace or delete question, nothing changes.
- Equipment with any status, including Lost and Disposed, can have a picture.
- In the tile view of the Equipment List the picture is shown with the equipment.

TODO(verify): the FactBox layout, the tile view and the Take action on a mobile device were not checked in a sandbox.

## Release notes
Equipment pictures: each piece of equipment can now have a picture, shown in the Picture FactBox on the Equipment Card and the Equipment List. Use Take, Import, Export and Delete to manage it. A new picture replaces the existing one after you confirm. Only one picture per equipment is supported.
