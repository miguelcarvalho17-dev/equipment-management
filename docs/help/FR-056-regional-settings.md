# Regional format of the maintenance log (AppSource end-user help)

The Maintenance Log Entries page shows dates, costs and maintenance types in your regional format. The format follows the **Region** you set in **My Settings**.

## Set your region
1. Choose the **Settings** icon in the top right corner, and then choose **My Settings**.
2. In the **Region** field, select your region. For example, select the region where you work.
3. Choose **OK**.

The change affects only your own workspace. Other users keep their own region. See [Change basic settings](https://learn.microsoft.com/dynamics365/business-central/ui-change-basic-settings#region).

## Read the log in your regional format
1. Open the log: choose **Log Entries** on the **Equipment Maintenance** page or on the **Maintenance Record** card. To see all entries, search for **Maintenance Log Entries**.
2. Read the **Old Value** and **New Value** columns. For a Changed entry, they show the value before and after the change:
   - **Maintenance Date** is shown as a date in your regional format.
   - **Cost** is shown with the decimal and thousands separators of your region.
   - **Maintenance Type** is shown by its name, for example "Corrective".
   - **Vendor No.**, **Description** and **Performed By** are shown as they were entered.
3. Registered and Posted entries have no old or new value. Their columns are blank.

If a value cannot be shown in your regional format, it is shown as it was stored. No error appears.

The stored values are not changed. Only the way they are shown is different.

## Show the XML values
The XML values are the stored values in a fixed technical format. For example, a date is shown as `2026-11-19`, a cost as `1234.5`, and a maintenance type as a number. 
The XML columns are hidden by default. To show them, use personalization:
1. Choose the **Settings** icon, and then choose **Personalize**. The page shows the personalization banner.
2. Choose the **+ Field** action. The **Add field to page** pane opens.
3. In the pane, find **Old Value (XML Format)** or **New Value (XML Format)**. Drag it into the list, or select it and then choose **Show** on the hidden column.
4. Exit personalization mode.

The column stays visible for you until you hide it again. Other users are not affected. For more, see [Personalize your workspace](https://learn.microsoft.com/dynamics365/business-central/ui-personalization-user).

## Release notes
The Maintenance Log Entries page shows the old and new value of a change in your regional format: dates, costs and maintenance types. The stored values are not changed. Choose **My Settings** to set your region. To see the original XML values, show the **Old Value (XML Format)** and **New Value (XML Format)** columns with personalization.
