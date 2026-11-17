# Decisions

## 2026-11-17 FR-061 Code Quality Compliance
- FR-061 analyzer scope | CodeCop + UICop + AppSourceCop on the main app; test app CodeCop + UICop locally; enableCodeAnalyzersOnTestApps true in CI | Reversible: yes
- FR-061 test-app AppSourceCop | Not run locally: AS0015 (TranslationFile missing in test/app.json) is an error and blocks packaging; test/app.json and ruleset untouched (user decision) | Reversible: yes
- FR-061 AppSourceCop.json | app/AppSourceCop.json with mandatoryAffixes EQM (Option A); test/AppSourceCop.json not created | Reversible: yes
- FR-061 local severity parity | al.ruleSetPath -> .AL-Go/equipment.ruleset.json | Reversible: yes
- FR-061 regression gate | failOn newWarning deferred to phase 2 | Reversible: yes
- FR-061 manifest diagnostics | Documented exception register (AS0051/52/81/84/92) | Reversible: yes
- FR-061 AA0477 | Fixed using order in EQMEquipmentPictureTests | Reversible: yes
- FR-061 AA0210 | API test filters on "No." and asserts Description (user chose fix) | Reversible: yes
