# Gate 2C Part 1 todo list

## Scope

This release branch is in Gate 2C, not Gate 2B. Gate 2B functionality remains intact and is preserved.

## In-scope work

### Nominations
- [x] Nomination lifecycle model and validation
- [x] Duplicate screening before acceptance
- [x] Decision validation for rejection reasons
- [x] Prospect creation from accepted nominations
- [ ] UI review flow and detail panels for nomination records
- [ ] Role-based enforcement and persisted activity history through Supabase service rules
- [ ] Live database-backed validation for production approval workflow

### Imports
- [x] CSV template generation and row normalization
- [x] Validation preview for required fields and malformed rows
- [x] Duplicate-match indicator and summary metrics
- [x] Confirmation gating and idempotency key generation
- [ ] Transaction-safe commit function for import execution
- [ ] Persisted import history, source records, and error CSV exports in live Supabase
- [ ] RLS and role checks enforced by database policies and RPCs

## Notes
- Live SQL execution is intentionally deferred per the current workflow.
- The branch is maintained on release/2-discovery without merge or deployment.
- This checklist reflects Gate 2C Part 1, not Gate 2B.
