# Repo-level tests (plan)

Flutter unit/widget tests live in `test/` and run with `flutter test`.

This `tests/` folder will hold cross-cutting scenario checklists + Python ML tests
(Phases 5, 10, 11, 19):

- Scenario 1: far from boundary → LOW/SAFE
- Scenario 2: approaching → CAUTION/WARNING
- Scenario 3: fast approach → HIGH
- Scenario 4: inside polygon → CRITICAL
- Scenario 5: ML missing → deterministic fallback works
- Scenario 6: internet OFF → core pipeline works
- Scenario 7: GPS unavailable → clear state, no fabricated location

No tests implemented in Phase 1 beyond the default `test/widget_test.dart`.
