# Integration Events (AppSource end-user help)

Integration Events let other systems learn what happens to your equipment without polling every record. When you turn the feature on, Equipment Management writes one entry for each business event: equipment created, assigned or returned, maintenance created, and warranty expired. The other system reads the pending entries through the Business Central API and marks each one as processed.

TODO(verify): this feature has not been tested in a sandbox. Automated tests are written and compile, but have not been run yet. The API address, reading and marking entries, and permissions are not verified.

## Before you start: permissions
- **Equipment Reader, Manager and Administrator** can read integration events (list and API).
- **Administrator** can mark entries as processed through the API and delete processed entries.
- Manager and Administrator create entries indirectly, by assigning, returning and registering equipment and maintenance.

TODO(verify): permissions were not checked in a sandbox.

## Turn it on
1. Search for **Equipment Setup** and open it.
2. In the **Integration** group, turn on **Integration Events Enabled**.

It is off by default. While it is off, no entries are written. Events that happened before you turned it on are not recorded.

## View the entries
On Equipment Setup, choose **Integration Event Entries**. The list shows the newest entry first.

| Column | What it shows |
|---|---|
| Entry No. | Running number of the entry. |
| Event Type | Equipment Created, Equipment Assigned, Equipment Returned, Maintenance Created or Warranty Expired. |
| Equipment No. | The equipment the event is about. |
| Equipment Status | The equipment status when the event happened. |
| Assignment Entry No. | The assignment entry, for assigned and returned events. 0 for other events. |
| Maintenance No. | The maintenance record, for Maintenance Created. Blank otherwise. |
| Created At | When the entry was written. |
| Processed | Whether the other system has handled the entry. |
| Processed At | When it was marked processed. |

Entries cannot be created or changed by hand. Registering maintenance on assigned equipment writes two entries: Equipment Returned, then Maintenance Created. Warranty Expired entries are written by the daily warranty job.

## Delete processed entries
Entries are not removed automatically. To keep the list short, an Administrator can delete entries that are marked Processed. Entries that are not yet processed cannot be deleted.

## Read the entries from another system
Address: `/api/miguelCarvalho/equipment/v1.0/companies({companyId})/integrationEvents`. Authentication is the same as for other Business Central APIs. TODO(verify): the address was not tested against a sandbox.

Fields (all read-only): `id`, `entryNumber`, `eventType`, `equipmentNumber`, `equipmentStatus`, `assignmentEntryNumber`, `maintenanceNumber`, `processed`, `processedDateTime`, `createdDateTime`, `lastModifiedDateTime`.

Recommended routine:
1. GET `integrationEvents?$filter=processed eq false&$orderby=entryNumber`.
2. Handle each entry.
3. For each handled entry, POST `integrationEvents({id})/Microsoft.NAV.markProcessed`.

Calling `markProcessed` again on a processed entry changes nothing, so it is safe to retry. The user names and employee numbers are not included in the entries; to see the employee of an assignment, read the assignment through the Assignment API (`assignments`) and filter on `entryNumber` equal to the entry's `assignmentEntryNumber`.

## Good to know
- An entry exists only when the operation that caused it was saved. If the operation fails, no entry is written.
- If writing an entry fails, the operation that caused it fails too.
- If nobody marks entries as processed, the list keeps growing.
- Version 1.0 is a frozen public contract once released: field names and event types will not change. Breaking changes will come as a new version (v2.0).

For authentication and general API use, see the Microsoft Learn documentation for Business Central APIs.

## Release notes
Integration Events: other systems can now follow what happens to your equipment. Turn on Integration Events Enabled in Equipment Setup and Business Central records an entry each time equipment is created, assigned or returned, maintenance is created, or a warranty expires. External systems read the pending entries through the API (v1.0, publisher miguelCarvalho, group equipment, entity integrationEvents) and mark them as processed. The setting is off by default.
