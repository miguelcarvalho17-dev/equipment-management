# Discount groups for customers  (EXAMPLE: planner output format)

## Goal
Allow assigning a discount group to each customer and automatically apply the group's discount
percentage to new item lines on sales orders.

## Approach and rejected alternatives
- Chosen: new table "ACME Discount Group", a field on Customer via table extension, and an
  event subscriber on Sales Line validation of "No." that calls a new codeunit.
- Rejected: base app Customer Discount Group - already used for price calculation; mixing semantics risks regressions.
- Rejected: modifying Sales-Post flow - discount must be visible at entry time, not at posting.

## Objects
| Type | ID | Name | New/Extend | Purpose |
|---|---|---|---|---|
| Table | 50101 | ACME Discount Group | New | Stores groups and percentages |
| Page | 50101 | ACME Discount Groups | New | List/maintenance |
| TableExtension | 50100 | ACME Customer Ext | Extend Customer | Adds "ACME Discount Group" |
| PageExtension | 50100 | ACME Customer Card Ext | Extend Customer Card | Shows the field |
| Codeunit | 50112 | ACME Discount Mgt | New | Calculation + extension events |
| Codeunit | 50110 | ACME Sales Line Subscribers | New | Thin subscriber |
| PermissionSet | 50100 | ACME - Edit | New | Access to the new objects |

## Data model and upgrade impact
- New table, new field on Customer (empty for existing customers => no discount; no upgrade codeunit needed).
- DataClassification: CustomerContent for all fields.

## Events
- Subscribed: Sales Line `OnAfterValidateEvent` for "No." (only Type = Item, only when "No." changed).
- Published: `OnBeforeCalculateDiscount(SalesLine, var Discount, var IsHandled)`,
  `OnAfterCalculateDiscount(SalesLine, var Discount)`.

## Permissions
- New permission set "ACME - Edit" covering table 50101 and pages; add to the app's permission set list.

## Compatibility
- AppSource: only new public objects/events, no change to existing signatures. No breaking-change risk.

## Test scenarios
1. Given a customer with group of 10%, when an item line is added to an order, then line discount % = 10.
2. Given a customer without group, when an item line is added, then line discount % = 0.
3. Given a group, when discount % > 100 is entered, then an error is raised.
4. Given a non-item line (G/L Account), when it is added, then the subscriber does nothing.
5. Given a partner subscriber setting IsHandled, when calculating discount, then default logic is skipped.

## Risks and open questions
- Should the discount overwrite a manually entered line discount? (Assumed: only applied when line discount is 0. Confirm.)
- Multi-currency: not relevant for percentages; no action.
