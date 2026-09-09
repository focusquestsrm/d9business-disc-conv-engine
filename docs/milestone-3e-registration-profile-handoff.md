# Milestone 3E — Registration and Profile Handoff

## Scope

This milestone introduces a provider-boundary registration and profile handoff model for prospect invitations, approval gating, provider sync ingestion, and manual review handling. It is intentionally scoped to local persistence and workflow semantics without claiming live provider activation.

## Persistence model

The migration adds these tables:

- `public.registration_invitations`
- `public.registration_handoffs`
- `public.member_profile_links`
- `public.registration_journey_events`
- `public.registration_match_candidates`
- `public.brilliant_directories_sync_events`

These tables are backed by uniqueness constraints, indexes, and row-level security policies so that invitation, handoff, and profile-link records remain auditable and append-safe.

## Approval and delivery gating

The registration invitation eligibility function enforces the contract:

- consent must be granted
- opt-out must be inactive
- frequency checks must pass
- expired or revoked invitations are not eligible
- human approval must be granted

If the human approval gate fails, the function returns the `human_approval_required` code and blocks delivery. The database trigger on `registration_invitations` reinforces this requirement before update or insert operations.

## Provider boundary

The model treats Brilliant Directories as a provider boundary rather than an actively connected live integration. Provider payloads are stored in `brilliant_directories_sync_events` and reviewed through duplicate candidate and review queue flows without assuming credentialed outbound calls are available.

## Journal and review flow

- `registration_journey_events` records lifecycle movement across stages.
- `registration_match_candidates` captures likely duplicate or provider-matched identities.
- `get_registration_journey` and `get_registration_review_queue` expose the canonical read paths for local review.
- The journey table is protected by an append-only trigger to prevent mutation of historical records.

## Validation approach

The accompanying verifier inspects:

- table existence and schema coverage
- index presence
- row-level security enablement
- policy existence
- function body semantics via `pg_get_functiondef`

This is a local correctness check for the migration contract and deliberately does not execute SQL against Supabase.

## Guardrails

- No live SQL execution against a hosted Supabase instance
- No undocumented Brilliant Directories endpoints or provider credentials in client code
- No autonomous outreach or send-only bypasses
- No migration changes for Releases 3A–3D

## Rerun safety

Each object uses `CREATE TABLE IF NOT EXISTS`, `CREATE UNIQUE INDEX IF NOT EXISTS`, `DROP POLICY IF EXISTS`, `CREATE OR REPLACE FUNCTION`, and `CREATE TRIGGER IF NOT EXISTS` patterns so the migration is safe to re-run in a local development workflow.
