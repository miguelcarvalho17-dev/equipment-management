# Data classification of the app (administrator help)

This article is for the environment administrator. It lists which fields of Equipment Management hold personal data and how to mark them in your environment. The design is described in `docs/features/FR-058-data-classification.md`.

TODO(verify): the worksheet steps below are not tested in a sandbox yet. Check the menu names against your version of Business Central.

## What the app stores
Every field of Equipment Management has a data classification. Most business data is classified as CustomerContent. The app does not store personal data about end users beyond their user names, which are stored in the fields listed below.

| Kind of data | Fields (examples) | Classification in the app |
|---|---|---|
| User names of the people who used the app | "Assigned By", "Closed By", "Posted By", "Acknowledged By", "User ID" (notes, logs, audit), "Sent for Approval By", "Decided By", "Created By" (demo data) | End user identifiable information |
| Employee numbers | "Assigned Employee No." (equipment), "Employee No." (assignments, requests, audit) | Customer content. Mark them Personal in your environment (see below). |
| Free text that may name people or vendors | "Performed By" (maintenance), "Vendor Name" and "Vendor No." (maintenance history), notes, comments, justifications, error messages | Customer content |
| Technical fields | Error operation, object ID, error code, call stack, record system ID, creation time (demo data) | System metadata |

The app's classifications are defaults. You can change them in your environment.

## Mark employee data as personal
Employee numbers identify employees, who are data subjects. The app keeps them as customer content, so that you can decide how to classify them in your environment.

1. Use Tell Me (or the search) to open **Data Classification Worksheet**.
2. Choose **Find New Fields** (or the equivalent action in your version) to load the fields of the app.
3. Find the field, for example **Assigned Employee No.** on the table **EQM Equipment**, or **Employee No.** on the assignment, request or audit tables.
4. Set **Data Sensitivity** to **Personal**, then apply the change.
5. Repeat for each employee number field that holds personal data in your company.

Learn: [Classify data sensitivity](https://learn.microsoft.com/dynamics365/business-central/admin-classifying-data-sensitivity).

## What to know
- Your choice applies to your environment only. It does not change the app.
- The worksheet records your sensitivity choices. It does not change the classification in the app.
- Personal data in the free text fields (notes, comments, error messages, maintenance text) is not found by the classification. Review that text under your own privacy process.
- If you add your own fields to the app's tables, classify them yourself.

## Release notes
Every field of Equipment Management has a data classification. This article lists the fields that hold personal data. An administrator can mark the employee numbers as personal data in the Data Classification Worksheet. The app does not change any stored data.
