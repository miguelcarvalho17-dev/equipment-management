# Developer report (EXAMPLE: format for the final reply of al-developer)

**Plan:** docs/plans/discount-groups.md
**Build:** succeeded, 0 errors, 0 warnings (CodeCop, UICop, AppSourceCop)

## Files changed
- app/src/Setup/ACMEDiscountGroup.Table.al (new)
- app/src/Setup/ACMEDiscountGroups.Page.al (new)
- app/src/Sales/ACMECustomerExt.TableExt.al (new)
- app/src/Sales/ACMECustomerCardExt.PageExt.al (new)
- app/src/Sales/ACMEDiscountMgt.Codeunit.al (new)
- app/src/Sales/ACMESalesLineSubscribers.Codeunit.al (new)
- app/src/Permissions/ACMEEdit.PermissionSet.al (new)

## Deviations from the plan
- None. (Or: "Plan said table ID 50101 for the list page too; pages and tables have separate ID spaces, kept 50101 for both.")

## Notes for the reviewer
- Manual-discount question from the plan's open items: implemented as "only apply when line discount is 0".
