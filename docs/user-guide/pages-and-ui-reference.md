# Pages and UI reference

This article lists every page, report, part and FactBox of Equipment Management, how to open it and where to read more. Use it to find a page quickly. In the tables, "Tell Me" means that you can find the page with the search icon.

**In this article**
- [Pages](#pages)
- [Parts and FactBoxes](#parts-and-factboxes)
- [Reports](#reports)
- [Additions to standard pages](#additions-to-standard-pages)

## Pages

| Page | Type | How to open | Use it to | Article |
|---|---|---|---|---|
| **Equipment** | List | Tell Me, category Lists. | Find, filter and open equipment. | [Equipment register](equipment-register.md) |
| **Equipment Card** | Card | From the **Equipment** list. | Manage one piece of equipment. | [Equipment register](equipment-register.md) |
| **Equipment Categories** | List | Tell Me, category Administration. | Add, deactivate and review categories. | [Setup and configuration](setup-and-configuration.md) |
| **Equipment Setup** | Card | Tell Me, category Administration. | Set numbering, defaults, features and monitoring. | [Setup and configuration](setup-and-configuration.md) |
| **Equipment Features** | List | Tell Me, category Administration. | Turn optional features on or off. | [Setup and configuration](setup-and-configuration.md) |
| **Equipment Assignments** | List | Tell Me, category History. | Review the assignment history. | [Assignments](assignments.md) |
| **Equipment Maintenance** | List | Tell Me, category Lists. | Review and register maintenance records. | [Maintenance](maintenance.md) |
| **Maintenance Record** | Card | From the **Equipment Maintenance** list, or **Register Maintenance** on the equipment card. | Register, correct and post one maintenance record. | [Maintenance](maintenance.md) |
| **Maintenance History** | List | Tell Me, category History. | Review posted maintenance and its cost. | [Maintenance](maintenance.md) |
| **Maintenance Log Entries** | List | Tell Me, category History. | See who registered, changed and posted maintenance records. | [Audit and change tracking](audit-and-change-tracking.md) |
| **Warranty Alerts** | List | Tell Me, category Lists. | Review, acknowledge and generate warranty alerts. | [Warranty](warranty.md) |
| **Equipment Requests** | List | Tell Me, category Lists. | Review requests and run the approval actions. | [Equipment requests](equipment-requests.md) |
| **Equipment Request** | Card | From the **Equipment Requests** list. | Raise and process one request. | [Equipment requests](equipment-requests.md) |
| **Equipment Request Decision** | Dialog | When you choose **Approve** or **Reject**. | Enter the comment for a decision. | [Equipment requests](equipment-requests.md) |
| **Equipment Notes** | List | Tell Me, category History. | Read all notes of equipment. | [Equipment register](equipment-register.md) |
| **Equipment Audit Trail** | List | Tell Me, category History. | Follow the life of equipment. | [Audit and change tracking](audit-and-change-tracking.md) |
| **Integration Event Entries** | List | From **Equipment Setup**. | See the entries that external systems read. | [Integration with other apps](integration.md) |
| **Equipment Error Log** | List | Tell Me, category Administration. | See the errors of the daily jobs. | [Notifications and monitoring](notifications-and-monitoring.md) |
| **Equipment Dashboard** | Card | Tell Me, category Reports and analysis. | See tiles and charts. | [Dashboards and role center](dashboards-and-role-center.md) |
| **Equipment Manager** | Role center | **My Settings**, **Role** field. | Use the home page of an equipment manager. | [Dashboards and role center](dashboards-and-role-center.md) |

Equipment Management also has the API pages for the equipment, categories, assignments and integration events. They are not shown in the client. See [Using the API](using-the-api.md).

## Parts and FactBoxes

| Part | Hosted on | Shows | Article |
|---|---|---|---|
| **Equipment Activities** | **Equipment Dashboard** and **Equipment Manager** | The tiles. | [Dashboards and role center](dashboards-and-role-center.md) |
| **Equipment by Category** | **Equipment Dashboard** and **Equipment Manager** | A chart of equipment by category. | [Dashboards and role center](dashboards-and-role-center.md) |
| **Equipment by Status** | **Equipment Dashboard** and **Equipment Manager** | A chart of equipment by status. | [Dashboards and role center](dashboards-and-role-center.md) |
| **Maintenance Cost by Category** | **Equipment Dashboard** and **Equipment Manager** | A chart of the posted maintenance cost by category. | [Dashboards and role center](dashboards-and-role-center.md) |
| **Top 10 Equipment by Maintenance Cost** | **Equipment Dashboard** and **Equipment Manager** | A chart of the ten most expensive pieces of equipment. | [Dashboards and role center](dashboards-and-role-center.md) |
| **Assignment Details** | **Equipment**, **Equipment Card** and **Maintenance Record** | The employee, since when and how often the equipment was assigned. | [Equipment register](equipment-register.md) |
| **Assignment History** | **Equipment Card** | Every assignment of the equipment. | [Assignments](assignments.md) |
| **Maintenance** | **Equipment**, **Equipment Card** and **Maintenance Record** | The number of records, the latest record and the cost. | [Maintenance](maintenance.md) |
| **Maintenance History** | **Equipment Card** | The posted maintenance of the equipment. | [Maintenance](maintenance.md) |
| **Equipment Notes** | **Equipment Card** | The notes of the equipment. | [Equipment register](equipment-register.md) |
| **Picture** | **Equipment** and **Equipment Card** | The picture of the equipment. | [Equipment register](equipment-register.md) |
| **Equipment Summary** | **Equipment Card** | The status, the assigned employee and the warranty status. | [Equipment register](equipment-register.md) |
| **Equipment Statistics** | **Equipment Card** | The assignment count, the maintenance count and the cost. | [Equipment register](equipment-register.md) |
| **Attachment Summary** | **Equipment Card** | The number of attached documents and images. | [Equipment register](equipment-register.md) |
| **Assigned Equipment** | **Employee Card** | The equipment that is assigned to the employee. | [Assignments](assignments.md) |

## Reports

| Report | How to open | Use it to | Article |
|---|---|---|---|
| **Equipment Register** | Tell Me, category Reports and analysis. | List equipment with its main data in Excel. | [Reports](reports.md) |
| **Asset Utilization** | Tell Me, category Reports and analysis. | See how much of the equipment is assigned. | [Reports](reports.md) |
| **Maintenance Cost Analysis** | Tell Me, category Reports and analysis. | See the maintenance cost by category, equipment, year and month. | [Reports](reports.md) |
| **Usage Analytics** | Tell Me, category Reports and analysis. | See how the register is used over a period. | [Reports](reports.md) |

## Additions to standard pages

| Page | Addition | Article |
|---|---|---|
| **Employee Card** | The **Assigned Equipment** FactBox. Under **Related**, **Equipment**, the actions **Equipment Assignments**, **Assigned Equipment** and **Equipment Requests**. The action **Return Equipment** under **Process**. | [Assignments](assignments.md) |
| **Document Attachment Details** | The **Attachment Category** field, shown for equipment attachments. | [Equipment register](equipment-register.md) |

## What to know

- Pages that belong to a feature that is turned off are still found with Tell Me. Opening them shows an error. See [Setup and configuration](setup-and-configuration.md).
- Equipment Categories and Equipment Assignments show a short tip the first time you open them.

## Related

- [Overview](README.md)
- Feature article: [Find actions and see assignment details](../help/NFR-003-usability.md)
- Feature article: [Equipment Features](../help/FR-042-feature-management.md)
- Feature article: [Equipment Summary, Equipment Statistics and Attachment Summary](../help/FR-037-factboxes.md)

---
Previous: [Using the API](using-the-api.md) | Next: [Advanced scenarios](advanced-scenarios.md)
