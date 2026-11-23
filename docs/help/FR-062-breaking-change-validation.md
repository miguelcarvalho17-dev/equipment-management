# Breaking change checks (contributor help)

This article is for people who change this repository. It is not an end-user article. It explains why a pull request fails the schema check, how to read the message and how to fix it.

The feature doc is `docs/features/FR-062-breaking-change-validation.md`. It has the full rule table and the reasons.

## What the check does
The check runs as check 8 of **Repo checks** on every pull request into `main`. It compares the `app/` AL source of your branch with `main`. It fails when your change would break an existing installation or an extension that depends on the app. Examples:
- removing or renaming a table, a field, a key or an enum value;
- changing the type of a field, or making a Text or Code field shorter;
- setting a field to Removed without setting it to Pending first.

It does not check the test app, procedures or events. See the limitations in the feature doc.

## What a failure looks like
A message has this form:

```text
SCH04 table <id> "<Name>": field <n> "<Field>" removed. Keep it and set ObsoleteState = Pending, then Removed in a later release. See docs/features/FR-062-breaking-change-validation.md. [key: SCH04 table <id> field <n>]
```

- The first word is the rule (`SCH04`). The rule table in the feature doc says what it means.
- `[key: ...]` is what you use in the accepted list (see below). You do not need it to fix the problem.
- Warnings are shown in the log and do not fail the check. Read them: SCH13, for example, asks you to move data in an upgrade step.

## How to fix the common errors
| Error | What to do |
|---|---|
| Object, field, key or value removed (SCH01, SCH04, SCH08, SCH09) | Put the element back. Set `ObsoleteState = Pending`, `ObsoleteReason = '<reason>'` and `ObsoleteTag = '<Major.Minor>'` (for example `'29.1'`) instead. |
| Renamed object, field or enum value (SCH02, SCH05, SCH09) | Restore the published name. A new name is a new element: add it, and make the old one Pending. |
| Type changed, or a Text or Code field made shorter (SCH06) | Keep the type and the length. Add a new field for the new type and retire the old one. A longer Text or Code field is only a warning. |
| Removed without Pending first (SCH11) | Set Pending first, keep the field in the source, and set Removed in a later release. |
| Reason or tag missing (SCH12) | Add `ObsoleteReason` and an `ObsoleteTag` in the `'Major.Minor'` form, for example `'29.1'`. |
| Enum changed from extensible to not extensible (SCH10) | Set `Extensible` back to `true`. |
| Namespace changed (SCH03) | Restore the namespace. |
| Table type changed (SCH07) | Restore the table type. |

Warnings you can act on:
- **SCH13, table or field becomes Pending:** move the data in an upgrade step in the `EQM Upgrade Mgt.` codeunit while the element is Pending. Follow "How to add an upgrade step" in [FR-044](FR-044-data-upgrade-support.md).
- **SCH13, field goes from Pending to Removed:** confirm the data was moved in an earlier release.

Never delete a published field, key or enum value from the source. Retire it instead.

## Enums
- Three enums are extensible: `EQM Equipment Status`, `EQM Maintenance Type` and `EQM Attachment Category`. Adding values to them is fine.
- Do not delete, rename or renumber an enum value.
- Every `case` over an extensible enum needs an `else` branch.
- Do not change an extensible enum to not extensible.

## Accepted breaking changes
Use this only when the user has approved the break. The approval comes from the user, not from you or another agent. Record it in `DECISIONS.md` first.

The entries are in `.github/schema/accepted-breaking-changes.json`. Each entry has a `key` (copy it from the message), a `reason` and a `decision` (the `DECISIONS.md` line or an issue link).

An entry accepts every finding with the same key. For a field, the key is the rule, the object and the field number. One entry therefore accepts a type change and a FieldClass change on that field. Name every change in the reason.

Remove the entry in the next pull request after the change is released. The check warns with `SCH14 stale entry` when an entry matches nothing.

## Run the check locally
Fetch `main` first, then run:

```text
python3 .github/scripts/schema_check.py --base origin/main
```

A clean result ends with `Schema check: OK` and shows no findings. To run the Python unit tests:

```text
python3 .github/scripts/test_schema_check.py
```

To run all the repository checks:

```text
python3 .github/scripts/repo_checks.py --base origin/main --branch <branch>
```

## Known limits
- Keep each object header on one line. A header split over two lines is not read, and the check then reports the object as removed (a false SCH01 error).
- Keep each field, key and value declaration on one line too.
- The check reads the source as text, not as the compiler does. If a result looks wrong, check the source first, then tell the maintainer.
