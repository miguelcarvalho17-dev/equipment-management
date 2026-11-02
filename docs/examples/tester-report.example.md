# Tester report (EXAMPLE: format for the final reply of al-tester)

**Plan:** docs/plans/discount-groups.md
**Result:** 4 passed, 1 failed

| # | Scenario (plan) | Test procedure | Result |
|---|---|---|---|
| 1 | Group 10% -> line discount 10 | DiscountAppliedForCustomerWithDiscountGroup | PASS |
| 2 | No group -> 0 | NoDiscountForCustomerWithoutDiscountGroup | PASS |
| 3 | % > 100 rejected | RejectsDiscountPercentAbove100 | PASS |
| 4 | Non-item line ignored | SubscriberIgnoresGLAccountLines | FAIL |
| 5 | IsHandled skips default | HandledEventSkipsDefaultLogic | PASS |

## Failure details
- Scenario 4: expected line discount 0, actual 10.
  Suspected cause: subscriber in ACMESalesLineSubscribers.Codeunit.al checks `Rec.Type` AFTER calling
  the discount codeunit. I did not change the app code; the failing test is kept as evidence.
