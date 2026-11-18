# Data Upgrade Support (AppSource end-user help)

When you upgrade Equipment Management, the app now checks the data of each company and fills in one value that was left blank by earlier versions. The app runs this check once per company. Values you have set are kept. Nothing else changes.

TODO(verify): this feature has not been tested in a sandbox. The behaviour after an upgrade may differ slightly from the description below.

## Before you start: permissions
- Nothing changes for your user permissions. The upgrade does not ask you for anything.

## What you see after an upgrade
- **Default Warranty Alert Days** on the Equipment Setup page shows **90** when it was blank before. Warranty alerts start 90 days before the end date, as before.
- If you had set a value, for example 30, the value stays 30.
- The upgrade does not change equipment, assignments, maintenance records, warranty alerts or the number series.

## How to check
1. Use **Tell Me**: search for "Equipment Setup".
2. Open the page. Under **Defaults**, check **Default Warranty Alert Days**. It shows a value from 1 to 90.

## Good to know
- You do not need to run anything. The upgrade runs when the new version is installed.

## Known limitations
- **A company created after the install** gets its Equipment Setup only when an administrator opens Equipment Setup. The new setup starts with 90 days. Default data for new companies is a planned follow-up.

## Release notes
Existing setups show 90 in Default Warranty Alert Days when the field was blank. Values you set are kept. Equipment, assignments, maintenance records and warranty alerts are not changed.
