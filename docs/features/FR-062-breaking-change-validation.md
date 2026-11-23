# FR-062 Breaking Change Validation

## Purpose
A pull request that makes an incompatible schema change to the main app fails the repository checks before it reaches `main`. The check covers removed or renamed objects, fields and keys, changed field types, enum values that are removed or renamed, and obsolete states that are set in the wrong order. It also records the rules for retiring a field and for extending an enum.

Phase 1 is a static check in Python (GitHub issue #103). It compares the AL source in `app/` of the pull request with the same source on `main`. It needs no release, no change to `app/AppSourceCop.json`, no change to the ruleset and no workflow change.

Plan: `docs/plans/FR-062-breaking-change-validation.md` (approved).

## Status
- Branch `feature/FR-062-breaking-change-validation`. Files not committed at the time of writing.
- New: `.github/scripts/schema_check.py`, `.github/scripts/test_schema_check.py`, `.github/schema/accepted-breaking-changes.json` (contains `{"accepted": []}`).
- Changed: `.github/scripts/repo_checks.py`. It runs the schema check as check 8, only when `--base` is given.
- No AL change. No change to `app.json`, `AppSourceCop.json`, the ruleset or any workflow. App version stays 29.0.0.0.
- No behaviour of the app changes. No data, object, field, permission or translation changes.

## Verification status
- **Review:** APPROVED.
- **Local runs:** not recorded in this document. The docs step did not run the scripts. Before the pull request, run `python3 .github/scripts/test_schema_check.py`, `python3 .github/scripts/schema_check.py --base origin/main` (expected: `Schema check: OK`, no findings) and `python3 .github/scripts/repo_checks.py --base origin/main --branch feature/FR-062-breaking-change-validation`.
- **History run (plan step 6):** run on 2026-11-23 with `schema_check.py --base <sha>` against b8b885d (FR-044 merge, 112 objects) and 9be7e25 (HEAD~30, 93 objects). Both gave 0 errors and 0 warnings.
- **CI:** not verified. The result of check 8 is in the "Repo checks" log of the pull request, after the push.
- **AL compile:** not needed. No AL file changed.
- **AppSource validation:** no separate AppSource validation ran. The reviewer checked the rules against the AppSourceCop descriptions.

## How the check runs
- It runs as check 8 of `repo_checks.py` in the `Repo checks` workflow, on pull requests into `main` only. The workflow already fetches the full history and passes `--base`.
- The base is the `app/` AL source on `origin/main`. The head is the `app/` folder of the pull request. Only `.al` files are read.
- The reader is line based. It is not the AL compiler. It finds objects, fields, keys, enum values and their properties by pattern. See Limitations.
- Errors fail the check. Warnings are printed as GitHub annotations and do not fail it.
- The output ends with a summary line, `Schema check: base <n> objects, head <m> objects, <e> breaking, <w> warnings, <a> accepted`, and `Schema check: OK` when there are no errors.

## Rules
Severity is the default. "Warning" rows say when a finding is a warning instead of an error.

| Rule | Severity | What it finds | AppSourceCop rule (Microsoft Learn) |
|---|---|---|---|
| SCH00 | Warning | The base source cannot be read. The check is skipped. | None |
| SCH01 | Error. Warning for a non-table object that was Pending in base | An object is removed | AS0001 (tables), AS0088 and AS0089 (other referenceable objects) |
| SCH02 | Error | An object is renamed, or the `extends` target of an extension changes | AS0006 (tables), AS0090 (objects) |
| SCH03 | Error | The namespace of an object changes | AS0007 |
| SCH04 | Error | A field is removed, whatever its ObsoleteState | AS0002 |
| SCH05 | Error | A field is renamed. The check is case sensitive. | AS0005 |
| SCH06 | Error. Warning when a Text or Code field gets longer | The type changes; a Text or Code field gets shorter; the FieldClass changes | AS0004 (type), AS0080 (shorter), AS0086 (longer) |
| SCH07 | Error | The TableType of a table changes | None |
| SCH08 | Error. Warning for a secondary key removed after it was Pending | The primary key changes or is removed; a secondary key is removed or its fields change | AS0009, AS0010 |
| SCH09 | Error. Warning for a value removed while its enum was Pending | An enum value (or an enum extension value) is removed or renamed | AS0082 (rename), AS0083 (delete) |
| SCH10 | Error when `Extensible` goes from true to false. Warning when it goes from false to true | The extensibility of an enum changes | AS0050 (false to true is not listed by AS0050; the check adds a warning) |
| SCH11 | Error | An invalid obsolete transition: a Removed element returns to another state, or a Removed state is set without Pending in base | None |
| SCH12 | Error | An element is Pending or Removed without `ObsoleteReason`, or with an `ObsoleteTag` that is not `'Major.Minor'` (for example `'29.1'`) | None |
| SCH13 | Warning | A table or field becomes Pending: move its data in an upgrade step. A field goes from Pending to Removed: confirm the data was moved in an earlier release. | None |
| SCH14 | Error for an invalid entry in the accepted list. Warning for a stale entry | Problems in `.github/schema/accepted-breaking-changes.json` | None |

The AppSourceCop rules AS0072 to AS0076 check obsolete tags. They are not enabled in the ruleset; turning them on is a user decision (stop list).

The rule ID is at the start of every message. Each message ends with `See docs/features/FR-062-breaking-change-validation.md. [key: <key>]`. The key is the rule, the object kind and ID, and the member when there is one. For example: `SCH04 table <id> field <n>`, `SCH08 table <id> key <name>`, `SCH09 enum <id> value <ordinal>`. Use the key in the accepted list (see below).

## Field removal lifecycle
A field is never deleted from the source. It goes through three releases:

1. **Pending (release N).** Set `ObsoleteState = Pending`, `ObsoleteReason = '<reason>'` and `ObsoleteTag = '<Major.Minor>'` (the version of the release, for example `'29.1'`). The check requires the reason and the tag (SCH12). Moving the field to Pending gives a warning (SCH13) that the data must be moved.
2. **Move the data (release N).** Move the data in an upgrade step in the `EQM Upgrade Mgt.` codeunit while the field is Pending. The steps and the tag rule are in [FR-044](FR-044-data-upgrade-support.md), "How to add an upgrade step". The check does not read the upgrade code. It only warns.
3. **Removed (release N+1 or later).** Set `ObsoleteState = Removed`, keep the reason and the tag, and keep the field in the source. The check rejects Removed when the field was not Pending in base (SCH11). It warns when the field goes from Pending to Removed (SCH13): confirm the data was moved in an earlier release.

Deleting the field from the source is an error (SCH04), in any state. Renaming the field is an error (SCH05).

The same path applies to secondary keys: set Pending first, then remove the key in a later release. The check warns when a key that was Pending in base is removed (SCH08), and gives an error otherwise.

Enum values follow the same path. Set the value to Pending with a reason and a tag, keep it in the source, and set it to Removed in a later release. See "Enum extension strategy".

Microsoft Learn: [ObsoleteState property](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/properties/devenv-obsoletestate-property), [Obsolete objects](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-obsolete-objects).

## Enum extension strategy
- Three enums are extensible (`Extensible = true`): `EQM Equipment Status`, `EQM Maintenance Type` and `EQM Attachment Category`. The other enums of the app are not extensible. For enums the default is false.
- Adding a value is allowed, to an extensible enum or to a non-extensible one.
- Never delete or renumber a value. Renaming a value is an error (SCH09, AS0082). Deleting a value is an error (SCH09, AS0083). The only exception: the whole enum was Pending in base. Then the check warns (SCH09).
- Never change an extensible enum to non-extensible. That is an error (SCH10, AS0050), because partners may already extend it.
- Changing a non-extensible enum to extensible is allowed, but it cannot be undone. The check warns (SCH10). Make that decision once, deliberately.
- Every `case` over an extensible enum needs an `else` branch. Another extension can add a value, and the code must still work for it. The existing status `case` statements already have one.
- The enum extension `EQM Event Category` (extends `EventCategory`) follows the same value rules.
- Give a new value an ordinal above the highest one in use. Never reuse the ordinal of a removed value.

Microsoft Learn: [Extensible enums](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-extensible-enums).

## Upgrade processing
The check does not run upgrade code. It checks the sequence of states and warns when data has to move. Where data has to move, the upgrade step is written as described in [FR-044](FR-044-data-upgrade-support.md): one step per data change, guarded by an upgrade tag, run once per company. Never change a shipped upgrade tag.

## Accepted breaking changes
A breaking change that was approved by the user can be merged with an entry in `.github/schema/accepted-breaking-changes.json`. The file holds one list:

```json
{
  "accepted": [
    {
      "key": "SCH04 table <id> field <n>",
      "reason": "Short reason for the change",
      "decision": "<DECISIONS.md line or issue link>"
    }
  ]
}
```

- Each entry needs non-empty `key`, `reason` and `decision` text. Otherwise the check fails with SCH14.
- An entry accepts only error findings with the same key. Warnings are never accepted.
- **An entry accepts every finding that shares its key.** The key names the rule, the object and the member, not the change. For example, one entry for `SCH06 table <id> field <n>` accepts both a type change and a FieldClass change on that field. Write the reason so that it names every change that is accepted.
- An accepted finding is printed as a warning with the reason and the decision.
- An entry that matches no finding is a stale entry. The check warns and asks for its removal.
- The check does not confirm that the decision exists. It checks only that the text is present. The reviewer checks the reference.
- The file is read from the pull request head. A pull request can therefore add its own entry. Only the review stops that.
- Adding an entry needs the user's decision. Record that decision in `DECISIONS.md` and put its line in the `decision` field. Remove the entry in the next pull request after the change is in a release, or once the stale warning appears.

## Limitations
- **Object headers split over two lines are not parsed and give a false SCH01 error.** The object is then missing in head, so the check reports it as removed when the base has it. Remedy: keep object headers on one line.
- Field, key and value declarations must also be on one line. A split declaration is not read, so a field can seem removed (a false SCH04 error). Keep them on one line.
- `#if` blocks are read as if every branch is present. A field defined in one branch is counted.
- Only the first key of a table is the primary key. The check reads the primary key as the first key in the source.
- Only `app/` is checked. The test app (`test/`) is not checked. It is never installed in a customer tenant.
- Only schema and object identity are checked. Procedures, events, page controls, report dataset columns and API fields are not checked. AppSourceCop covers some of them in phase 2; a static check of API page fields and report columns is phase 4.
- `interface`, `profile` and `controladdin` objects are not checked (no numeric ID).
- The baseline is `main`, not a release. Anything merged to `main` is treated as published. Two pull requests can move a field from Pending to Removed between two releases, and the check passes. SCH13 warns about it.
- Names are compared case sensitively. A case-only rename is an error (SCH05).
- If `main` cannot be read, the check is skipped with the warning SCH00. The summary line says `skipped`, the warning is printed, and `Schema check: OK` is not printed.

## Phases
- **Phase 1 (this feature):** the static check on `main`, and the rules above.
- **Phase 2:** the user runs AL-Go **Create release** once. AppSourceCop then compares the app with the release in the Pull Request Build (its binary baseline). Whether to set `obsoleteTagVersion` in `app/AppSourceCop.json` and to enable AS0072 to AS0076 are user decisions (stop list).
- **Phase 3:** the base of the check moves from `main` to the latest release tag.
- **Phase 4:** a static check of API page fields, entity names and report dataset columns.

## Test status
- Python unit tests: `.github/scripts/test_schema_check.py` (the plan's tests T0 to T21). They run locally with `python3 .github/scripts/test_schema_check.py`. CI does not run them; the workflows are not changed in this feature.
- Results: not recorded in this document. The docs step did not run them.

## Events
None.

## Compatibility
Repository checks only. No app object, table, field, permission, translation or manifest change. The only change for contributors is check 8, which runs on pull requests.

## Related
- Plan: `docs/plans/FR-062-breaking-change-validation.md`
- Help article: `docs/help/FR-062-breaking-change-validation.md`
- Upgrade steps: [FR-044](FR-044-data-upgrade-support.md)
- Analyzers: [FR-061](FR-061-code-quality-compliance.md), [FR-048](FR-048-automated-build-pipeline.md)
- Pipeline: [CI/CD](../setup/ci-cd.md)
- Microsoft Learn: [AppSourceCop analyzer](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/analyzers/appsourcecop), [Extensible enums](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-extensible-enums)
