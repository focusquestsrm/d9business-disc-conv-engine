# Milestone 2 data model and persistence plan

## Core persistence objects

This release targets the following database objects in the Milestone 2 migration package.

- discovery_sources
- businesses
- business_contacts
- prospects
- campaigns
- nominations
- import_jobs
- import_rows
- workflow_assignments
- workflow_events
- possible_duplicates
- opt_outs
- prospect_source_events
- integration_statuses

## Persistence standards

- UUID primary keys are used for all business records.
- Updated timestamps are maintained with a set_updated_at trigger pattern.
- Status checks are enforced with CHECK constraints.
- Foreign keys cascade or set null when appropriate.
- Indexes are created for route and review queries.
- Idempotency and duplicate suppression logic is defined in the migration package and helper modules.

## Local implementation boundary

The local app implements validation logic, summary generation, workflow state enforcement, and UI behavior in code modules. However, local arrays and component state are not treated as production persistence and are explicitly excluded from the live acceptance claim.

## Deferred live verification items

- RLS execution in a target Supabase project
- Migration execution against a clean local or remote database
- Role-policy validation from authenticated role contexts
- Actual audit event persistence and query validation
- Live integration health records and external service checks
