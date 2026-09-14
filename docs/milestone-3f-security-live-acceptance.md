# Milestone 3F: Security and live acceptance

## Scope

Release 3F adds the repository-side security and live acceptance model that completes the operational governance layer without connecting external providers or executing SQL against a live Supabase project. The migration is additive and rerun-safe.

## Security model

The Release 3F migration introduces the following repository-side controls:

- `public.security_role_matrix` for explicit role-permission scope checks
- `public.export_audit_events` for workbook and report generation/download auditing
- `public.assert_security_role_matrix(...)` as the canonical permission gate
- `public.record_export_audit_event(...)` and `public.record_export_download_event(...)` for export evidence capture

These checks are deliberately conservative and align with the existing Milestone 1 app-role model rather than creating a new PostgreSQL-only permission regime.

## Role and permission matrix

The migration seeds a small but explicit matrix covering:

- platform_admin
- operations_admin
- reviewer
- operator
- analyst
- auditor
- membership_owner

The role matrix is intentionally compact and scoped to the security and export surface area for the current release. It keeps all access decisions explicit and auditable while preserving the existing `current_user_is_platform_admin()` and `user_has_permission()` path.

## Export generation and download auditing

The export audit events table records:

- the export scope and target resource type
- file name, format, and row count
- the generating actor
- the downloaded actor when a file is opened or retrieved
- the final status (`generated`, `downloaded`, `rejected`, or `failed`)
- a file hash and metadata payload for later verification

This supports a later live acceptance checklist without requiring any external integration or third-party storage.

## Local repository guardrails

- No live Supabase SQL execution
- No deployment or Netlify push during this phase
- No external integration activation or provider credential use
- No modification to Releases 3A–3E migration history or live database state
- All acceptance evidence remains local and repository-scoped

## Acceptance evidence

The canonical verifier at `supabase/verification/verify_milestone_3f_security_live_acceptance.sql` checks:

- table existence and RLS enablement
- index presence
- policy presence
- function existence and role guard semantics
- export audit function body validation through normalized source matching
- final PASS/FAIL aggregation with an OVERALL row

## Remaining live acceptance steps

Live acceptance remains deferred until the target Supabase project is available and an authorized environment can execute the migration and verifier in situ. The remaining steps are:

1. apply the 3F migration in the live Supabase project
2. validate the role matrix under the target auth configuration
3. confirm export audit rows are produced for workbook generation/download flows
4. verify the live app enforces the same admin and security checks in browser sessions
5. resolve any environment-specific gap before marking the release as fully accepted

This repository-only implementation ensures the security and export-audit gate is ready and testable without claiming a live environment is already running.
