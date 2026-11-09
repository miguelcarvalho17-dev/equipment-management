# Event search report: FR-018 Automated Background Processing, Job Queue API lookup

**Feature:** Create and show recurring Job Queue Entries for codeunits 50111 and 50114 (consumer of the standard Job Queue, no standard behavior changed)
**Target:** BC 29 (Base Application 29.0.54011.57272, System Application 29.0.54011.57272, System 29.0.57237.0; symbols in app/.alpackages read: yes)  |  Base app source available: no (BASEAPP_SOURCE_PATH not set)
Search terms: job queue, job queue entry, job queue category, enqueue, recurring, schedule, TaskScheduler, permission set, company initialize.
Note: `.alpackages` at repo root is empty; symbols are in `app/.alpackages`. The Job Queue objects are in the Base Application package (namespace `System.Threading`). Everything below was read from SymbolReference.json (fields, option members, procedure names and parameters, object properties, permission set values). Symbols do not contain procedure bodies, so what the standard code does inside is marked "not verified".

## Recommendation
**No event is needed.** FR-018 only consumes the Job Queue (job codeunits with `TableNo = "Job Queue Entry"`, plus code that inserts entries). The standard API names the plan relies on exist and are listed below. Four plan corrections are required (see "Plan corrections"); the biggest is that Job Queue Category Description is Text[30], and the planned label is 31 characters.
- Alternative considered for new companies (plan Q4): the standard company-initialize event. Not searched in depth and not recommended; the plan's Equipment Setup path covers it. If the user picks that alternative in Q4, run a new search.
- Confidence: **high** for names, types, option members, lengths and signatures (read from symbols). **Medium** for runtime behavior of Enqueue and the table triggers (no source). **Medium-low** for the exact effective permissions (value codes in permission sets are only partly decodable, see V9).

## Verification results (plan V1-V9, V11)

### V1 Table 472 "Job Queue Entry" (namespace System.Threading) - verified
DataPerCompany: default (not overridden). No InherentPermissions on the table. Table `Permissions` property: Job Queue Entry rimd, Job Queue Log Entry rimd, Job Queue Category rm. Primary key: `ID`.
| Field | No. | Type in symbols | Remark |
|---|---|---|---|
| ID | 1 | Guid | Primary key. Whether OnInsert assigns it when null: NOT verified (no source). Safe code: `if IsNullGuid(ID) then ID := CreateGuid();` is NOT recommended without a test; see V2 |
| User ID | 2 | Text[65] | Do not set; platform sets it (OnInsert, event `OnInsertOnBeforeSetDefaultValues` exists, not verified how) |
| Earliest Start Date/Time | 6 | DateTime | |
| Object Type to Run | 7 | **Option** (members: "", "", "", Report, "", Codeunit), InitValue Report | NOT an enum. Use `JobQueueEntry."Object Type to Run"::Codeunit` |
| Object ID to Run | 8 | Integer | |
| Maximum No. of Attempts to Run | 11 | Integer | |
| Status | 13 | **Option**: Ready, In Process, Error, On Hold, Finished, On Hold with Inactivity Timeout, Waiting | 7 values, not 5. Editable = false (use `SetStatus`/`Restart`/Enqueue, not direct assignment) |
| Recurring Job | 17 | Boolean | |
| No. of Minutes between Runs | 18 | Integer | |
| Run on Mondays ... Run on Sundays | 19-25 | Boolean | Names exactly "Run on Mondays", "Run on Tuesdays", "Run on Wednesdays", "Run on Thursdays", "Run on Fridays", "Run on Saturdays", "Run on Sundays" |
| Starting Time | 26 | Time | |
| Ending Time | 27 | Time | |
| Next Run Date Formula | 29 | DateFormula | Alternative to the seven day flags |
| Description | 30 | Text[250] | |
| Job Queue Category Code | 33 | Code[10] | |
| Error Message | 34 | Text[2048] | |
| Rerun Delay (sec.) | 47 | Integer | |
| Scheduled | 49 | Boolean | |
| Manual Recurrence | 50 | Boolean | |
| Job Timeout | 54 | Duration | |
| Priority Within Category | 57 | Enum "Job Queue Priority" | |
All field names the plan uses exist with those exact names. Related public procedures on the table (from symbols): `SetStatus(NewStatus: Option)`, `Restart()`, `HasRequiredPermissions(): Boolean`, `TryCheckRequiredPermissions(): Boolean`, `CheckRequiredPermissions()`, `ScheduleTask(): Guid`, `FindJobQueueEntry(ObjType: Option; ObjID: Integer): Boolean`, `InitRecurringJob(NoofMinutesbetweenRuns: Integer)`.

### V2 Enqueue - verified (existence and signature); behavior NOT verified
**Codeunit 453 "Job Queue - Enqueue"** (namespace System.Threading), public (no Access property), `TableNo = "Job Queue Entry"`, own `Permissions`: Job Queue Entry rimd, Job Queue Category rim. Call as planned: `Codeunit.Run(Codeunit::"Job Queue - Enqueue", JobQueueEntry)`.
Its only published members are four local IntegrationEvents (OnAfterEnqueueJobQueueEntry, OnBeforeEnqueueJobQueueEntry, OnBeforeJobQueueScheduleTask, OnEnqueueJobQueueEntryOnBeforeJobQueueEntrySecondModify); `OnRun` is not in the symbols. Not verified: whether it inserts the record, whether it sets "User ID" and "Earliest Start Date/Time". The event name "...BeforeJobQueueEntrySecondModify" suggests it inserts or modifies the record itself, but that is a guess. **Do not insert and then run Enqueue without a test**: the developer must confirm in a sandbox whether Enqueue expects an inserted or an uninserted record (BG-SB2/BG1).
**Public alternatives on the table (fallback for "schedule a recurring codeunit entry")**, all from symbols; bodies not verified:
| Procedure | Parameters | Note |
|---|---|---|
| ScheduleRecurrentJobQueueEntryWithFrequency | (ObjType: Option; ObjID: Integer; RecId: RecordId; NoofMinutesbetweenRuns: Integer) and a second overload with `StartTime: Time` | Public. The overload with MaxAttemptsToRun and RerunDelay is **internal**, so unusable |
| ScheduleRecurrentJobQueueEntryWithRunDateFormula | (ObjType: Option; ObjID: Integer; RecId: RecordId; JobQueueCategoryCode: Code[10]; MaxAttemptsToRun: Integer; NextRunDateFormula: DateFormula; StartingTime: Time) | Public. Closest to the plan (category, 3 attempts, daily via formula `1D`, start 06:00). The overload with `JobTimeout` is internal. Not verified: what it does for the seven day flags and "Rerun Delay (sec.)" |
| ScheduleJobQueueEntry | (CodeunitID: Integer; RecordIDToProcess: RecordId) | One-off, not recurring |
Second fallback if Enqueue behaves unexpectedly: set the fields, `Insert(true)`, then `Restart()` or `SetStatus(...)` (public). Verify in a sandbox first. Pick one approach after the sandbox test; do not pick one from this report alone.

### V3 Table 471 "Job Queue Category" (namespace System.Threading) - verified, one plan problem
Fields: `Code` Code[10]; **`Description` Text[30]**; "Recovery Task Id" Guid; "Recovery Task Start Time" DateTime. **InherentPermissions = rimx**, Permissions property: Job Queue Category rimd. Public procedure `InsertRec(CodeToInsert: Code[10]; DescriptionToInsert: Text[30])` exists (not verified what it does besides inserting; could replace `Init/Insert(true)` in `EnsureJobQueueCategory`).
**Plan problem:** label `JobQueueCategoryDescTxt` = "Equipment Management monitoring" is 31 characters; Description is 30. A Label with `MaxLength = 30` would not compile (AL error), and `CopyStr` would silently cut the last letter. Use a text of at most 30 characters, for example "Equipment Management" (20) or "EQM monitoring" (14).

### V4 Page 672 "Job Queue Entries" - verified
Namespace System.Threading, PageType List, SourceTable 472 "Job Queue Entry". `Page.Run(Page::"Job Queue Entries", JobQueueEntry)` with a filtered record is valid by name. Table 471 has DrillDown/Lookup page "Job Queue Category List" (not needed).

### V5 TaskScheduler.CanCreateTask - NOT verifiable in symbols
`TaskScheduler` is a platform type (not present in the System, System Application or Base Application symbols; only unrelated local events named OnCanCreateTask exist). The compiler on runtime 18.0 is the only check. Keep the plan's fallback (drop the guard; the isolated `Codeunit.Run` catches the failure).

### V6 Recurring entry after the last failed attempt - NOT verified
No source. Symbols show `OnBeforeHandleExecutionError(var JobQueueEntry; var IsHandled)` on the table and "Error Message", "No. of Attempts to Run", "Manual Recurrence" fields, but not the outcome. Keep it as sandbox check BG-SB5; keep risk R2 as written.

### V7 / V8 Codeunit.Run isolation in install, delegated admin - NOT verifiable in symbols
Platform and runtime behavior. Keep the plan's fallback and sandbox checks BG-SB3/BG11. Note for V8: Job Queue Entry has `HasRequiredPermissions`/`TryCheckRequiredPermissions`; the table label list contains `NoPermissionsErr`, so inserting an entry whose target codeunit the user cannot execute is refused (see V9 and Plan corrections).

### V9 Permissions - partly verified
| Source | Job Queue Entry (472) | Job Queue Category (471) |
|---|---|---|
| Table property InherentPermissions | none | **rimx** |
| Codeunit 453 own Permissions | rimd | rim |
| Permission set "D365 Basic - Read" (included by D365 BASIC through "D365 Basic - Edit") | value 1 (read) | value 1 (read) |
| Permission set "D365 Basic - Edit" (included by D365 BASIC) | value 14 | value 448 |
| "D365 BASIC" | includes "D365 Basic - Edit" and "D365 Agent" | same |
| "D365 TEAM MEMBER", "D365 AUTOMATION", "D365 BASIC ISV", "Job Queue - Admin" (not assignable, shown as "Job Queue Setup") | 15 (rimd) | 15 (rimd) |
| "D365 READ" | 1 | 1 |
Decoding: 1 = read and 15 = rimd are unambiguous (they match the Job Queue - Admin set). Values 14 and 448 are partly ambiguous without the AL permission value table; 14 looks like direct i+m+d (read comes from "D365 Basic - Read"), 448 looks like indirect rights (not direct). Treat as: **D365 BASIC users very likely have direct read and insert/modify on Job Queue Entry, and direct read plus (probably) only indirect write on Job Queue Category.**
Conclusion for the plan:
- Job Queue Category: InherentPermissions rimx means code can read and insert without any permission set line. **The `tabledata "Job Queue Category" = ri` line in permission set 50102 and in codeunit 50115 `Permissions` can be dropped** (keeping it is harmless but redundant).
- Job Queue Entry: no inherent permissions. D365 BASIC probably already covers rim, but because the exact value 14 is not fully decoded and permissions can vary with tenant setup, keep the indirect `rim` line on codeunit 50115 `Permissions` and the Administrator line (as in the plan) until BG26 passes, then drop if redundant. The reviewer may prefer dropping; decide after BG26.
- The standard "Job Queue - Admin" set is not assignable (hidden); do not include it in EQM sets.

### V11 `Format(JobQueueEntry.Status)` - verified in part
Status is an Option with OptionCaption "Ready,In Process,Error,On Hold,Finished,On Hold with Inactivity Timeout,Waiting", so `Format` returns the translated caption. Behavior is standard AL; no further check needed.

## Standard objects and procedures to call (summary)
| Object | Name / signature | Use |
|---|---|---|
| Table 472 (System.Threading) | `Job Queue Entry`, fields above | Entry creation, filters, status text |
| Codeunit 453 | `Job Queue - Enqueue`, TableNo = Job Queue Entry | Make an entry Ready (behavior unverified, V2) |
| Table 471 | `Job Queue Category`, `Code` Code[10], `Description` Text[30], `InsertRec(Code[10]; Text[30])` | Category "EQM" |
| Page 672 | `Job Queue Entries` | Action "Monitoring Job Queue Entries" |
| Table 472 procedures | `SetStatus(Option)`, `Restart()`, `HasRequiredPermissions()`, `ScheduleRecurrentJobQueueEntryWithRunDateFormula(...)` | Fallbacks (V2) |

## Alternatives considered
| Candidate | Why ranked lower |
|---|---|
| Event on codeunit 453 (OnBeforeEnqueueJobQueueEntry, OnAfterEnqueueJobQueueEntry) | Fire for every enqueue in the system; the app does not need to react to others' entries; no need to change standard behavior |
| Table 472 implicit insert/modify events | Same reason; our code creates the entries itself |
| Company-initialize event to schedule jobs in new companies (plan Q4 alternative) | Not searched; not needed for the default; would also hook every new company without an administrator action |
| Own scheduling with TaskScheduler directly | Loses the Job Queue UI, retries, log and category handling |

## Published events found (from symbols)
| Object | Event | Signature | Relevant? |
|---|---|---|---|
| Codeunit 453 "Job Queue - Enqueue" | OnBeforeEnqueueJobQueueEntry | (var JobQueueEntry: Record "Job Queue Entry") | No |
| Codeunit 453 "Job Queue - Enqueue" | OnAfterEnqueueJobQueueEntry | (var JobQueueEntry: Record "Job Queue Entry") | No |
| Codeunit 453 "Job Queue - Enqueue" | OnBeforeJobQueueScheduleTask | (var JobQueueEntry: Record "Job Queue Entry"; var DoNotScheduleTask: Boolean) | No (could stop the task from being scheduled; do not use) |
| Codeunit 453 "Job Queue - Enqueue" | OnEnqueueJobQueueEntryOnBeforeJobQueueEntrySecondModify | (var JobQueueEntry: Record "Job Queue Entry") | No |
(Events on table 472 such as OnBeforeScheduleTask, OnBeforeSetStatusValue exist; not relevant.)

## Plan corrections needed
1. **Category description label too long.** Change `JobQueueCategoryDescTxt` to at most 30 characters (for example "Equipment Management"); `MaxLength` = 30 (V3). Job description labels (Text[250]) are fine.
2. **Option, not enum.** "Object Type to Run" and "Status" are Option fields. Write `JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit`. Status has 7 values (Ready, In Process, Error, On Hold, Finished, On Hold with Inactivity Timeout, Waiting); `Status` is not editable, so entries must be made Ready through Enqueue, `SetStatus` or `Restart` (V1, V2).
3. **Category permission can go.** Job Queue Category has InherentPermissions rimx: drop `tabledata "Job Queue Category" = ri` from permission set 50102 and the Permissions property of 50115. Keep the Job Queue Entry line until BG26 (V9). The Permissions plan table and the Administrator row must be updated accordingly.
4. **Enqueue behavior and the Insert step must be sandbox-confirmed before choosing the code.** The plan's step 8 ("then make it Ready through the V2 mechanism") must say: use `Codeunit.Run(Codeunit::"Job Queue - Enqueue", JobQueueEntry)`; whether to `Insert(true)` first is decided by a sandbox test; documented public fallbacks are `ScheduleRecurrentJobQueueEntryWithRunDateFormula` (category, 3 attempts, `1D` formula, 06:00) and `Insert(true)` + `Restart()`. The internal overloads that take RerunDelay cannot be used.
5. **Execute permission on the target codeunit.** The table has `HasRequiredPermissions`/`CheckRequiredPermissions` and a "no permissions" error label: creating an entry for codeunit 50111/50114 needs Execute on that codeunit (EQM - Reader has X). Add a sentence to the Permissions section and make sure the Administrator set includes Reader (via Manager); BG26 covers it.
6. Plan item V5 and V7/V8: not verifiable in symbols; keep the written fallbacks. No other name in the plan is wrong: `Job Queue Entry` field names, `Job Queue Category` `Code`, page `Job Queue Entries`, namespace `System.Threading` all match.

## Gaps and risks
- Enqueue body not verified (insert or not, "User ID", "Earliest Start Date/Time"); decides the code of `CreateRecurringJob`. Check in a sandbox (BG1, BG-SB2, BG-SB4).
- OnInsert assignment of `ID` not verified; test with `Init()` + `Insert(true)` and check `IsNullGuid(ID)` afterwards.
- Effective permissions: values 14 and 448 only partly decoded; BG26/BG-SB6 (non-SUPER administrator) is the real check.
- `TaskScheduler.CanCreateTask()` not in symbols; the compiler decides.
- AppSource: only public standard API is used (table 472 and 471 public fields and procedures, codeunit 453, page 672). The internal overloads are unavailable. Low break risk; `Job Queue Category.Description` length and Option fields are the type details most likely to bite.
- Verdict: no event needed and no event search gap; the API exists; apply the corrections above, then the developer may start codeunit 50115.
