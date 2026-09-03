# Milestone 2 acceptance matrix

This matrix tracks the local implementation status for the in-repo Milestone 2 workflow. It is intentionally explicit that local state, arrays, and UI-only behavior do not count as production persistence until the repository/data-service layer reads and writes through the Supabase-backed tables and security model.

## Summary

| Module | UI implemented | Validation implemented | Supabase read | Supabase write | DB enforcement | RLS policy | Audit event | Test coverage | Live verification pending |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Prospect Intake | Yes | Yes | Partial local only | Partial local only | No | No | Partial local event model | Yes | Yes |
| Prospects | Yes | Yes | Partial local only | Partial local only | No | No | Partial local event model | Yes | Yes |
| Businesses | Yes | Yes | Partial local only | Partial local only | No | No | Partial local event model | Yes | Yes |
| Workflow Routing | Yes | Yes | Partial local only | Partial local only | No | No | Partial local event model | Yes | Yes |
| Duplicate Review | Yes | Yes | Partial local only | Partial local only | No | No | Partial local event model | Yes | Yes |
| Nominations | Yes | Yes | Partial local only | Partial local only | No | No | Partial local event model | Yes | Yes |
| Imports | Yes | Yes | Partial local only | Partial local only | No | No | Partial local event model | Yes | Yes |
| Campaigns | Yes | Yes | Partial local only | Partial local only | No | No | Partial local event model | Yes | Yes |
| Work Queue | Yes | Yes | Partial local only | Partial local only | No | No | Partial local event model | Yes | Yes |
| Dashboard | Yes | Yes | Partial local only | Partial local only | No | No | Partial local event model | Yes | Yes |

## Module-level notes

### Prospect Intake
- Local UI for creation and validation exists in the app shell.
- Validation rules are implemented in the nomination/import helpers and the discovery logic.
- The current repository does not provenly persist through the production Supabase layer because no live migration/RLS execution has been performed.

### Prospects and Businesses
- Canonical record management is represented in app state and helper logic.
- Production persistence is deferred until the Milestone 2 migration and RLS package are executed against a target database.

### Workflow Routing
- Route decisions are implemented in the local workflow engine and respected in UI navigation.
- The DB-level trigger and enforcement package exists in the migration file but has not been executed live.

### Duplicate Review
- Duplicate classification and manual review flows are implemented locally.
- Database enforcement and audit events remain migration- and policy-dependent.

### Nominations, Imports, Campaigns, Work Queue, Dashboard
- The app surfaces operational behavior with local helper logic and tests.
- These flows are not treated as production-persisted until a live migration and RLS verification pass is performed.

## Local compliance status

The app meets the local development standard for workflow and validation coverage, but it is not a claimed live database completion. The local branch is ready for live acceptance only after the migration, RLS script, and Netlify/Supabase acceptance testing are executed in the target environment.
