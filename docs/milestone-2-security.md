# Milestone 2 security and authorization plan

## Root causes identified in the live verifier

The live Milestone 2 schema failed for a small set of distinct reasons rather than one broad issue:

- several required database functions were created under the wrong implementation pattern or were missing entirely from the executed migration
- the verifier treated PostgreSQL policy roles as if they must contain a literal `platform_admin` role instead of checking the application-level admin helper expression used by Supabase RLS
- the live schema had RLS enabled for operational tables but no usable policies for the high-risk discovery tables
- the duplicate-management and workflow transition functions were present but too weak or incomplete to satisfy the acceptance contract
- the `tenant_allowed_read` helper returned `true` for all authenticated users, which violates least-privilege and fail-closed behavior

## Required role model

The app continues to rely on the Milestone 1 role model:

- platform_admin
- operations_admin
- operator
- reviewer
- intern
- analyst
- auditor
- integration_service

The key distinction is that `platform_admin` is an application role stored in `public.roles` and `public.user_role_assignments`; it is not a PostgreSQL policy role. Supabase policies normally target `authenticated`, while the policy expression calls `public.current_user_is_platform_admin()` to evaluate the actual role assignment securely.

## Repair migration path

The repair package is additive and non-destructive:

1. leave the previously executed Milestone 1 and Milestone 2 migrations untouched
2. create a new repair migration at `supabase/migrations/20260904_000003_milestone_2_rls_repair.sql`
3. replace weak or missing functions using `CREATE OR REPLACE FUNCTION` with explicit signatures and safe `search_path`
4. add secure RLS policies for `public.businesses`, `public.discovery_sources`, `public.prospects`, and `public.workflow_assignments`
5. validate the resulting schema with the canonical read-only verifier without weakening checks

## Functions and behavior

- `public.set_updated_at()` is the canonical trigger helper that updates `updated_at` on row updates.
- `public.tenant_allowed_read()` is fail-closed and only grants access to authenticated platform administrators or explicitly authorized operational roles, not all authenticated users.
- `public.build_d9_match_candidate()` normalizes text, strips obvious PII-bearing elements such as phone numbers, and returns a structured match candidate without exposing restricted contact data.
- `public.enforce_workflow_transition()` blocks forbidden transitions, enforces consent renewal before an opt-out is cleared, and routes duplicate or suppressed records correctly.
- `public.record_workflow_transition()` persists audit history using the authenticated actor when available, so the database records the actual acting user and not an arbitrary browser-provided value.

## RLS policy matrix

Relevant Milestone 2 tables are protected by policy sets that require authenticated access and explicit authorization when reading or mutating records:

- `public.discovery_sources`: authenticated operational staff may read/update only when they hold platform or operational access
- `public.businesses`: authenticated users may read records in approved operational scope; writes are restricted to authorized staff and preserve ownership semantics
- `public.prospects`: only approved authenticated users may insert or update; ownership and assignment checks are enforced rather than allowing unrestricted mutation
- `public.workflow_assignments`: assignment reads are limited to the actor, assignee, or authorized platform/operations roles; writes are restricted to authorized staff and cannot silently escalate ownership
- `public.workflow_events` and `public.opt_outs`: writes are restricted to authenticated actors with explicit authorization; direct audit mutation remains blocked

## Security controls required before live acceptance

- Anonymous users must not access internal operational tables.
- Only platform administrators may manage platform-level access and security assignments.
- Operations administrators can manage operational data without escalating to security-admin controls.
- Operators may access only the records required for their approved tasks.
- Reviewers access review queues and decisions.
- Intern access is restricted to approved read-only and limited-write tasks.
- Analysts receive read-only reporting access.
- Auditors receive history access without modification rights.
- Integration services receive minimum required access.

## Protected data

- direct personal contact details
- opt-out and suppression information
- membership-match materials
- import files and row errors
- audit history
- administrative configuration

## Canonical verifier and expected results

The canonical read-only verifier remains at `supabase/scripts/verify_milestone_2_rls.sql` and must be rerun after applying the additive repair migration. The verifier is intentionally strict:

- it checks object existence and expected signatures
- it detects ambiguous NULL results as a failure condition
- it verifies RLS is enabled and that non-public tables have usable policies
- it confirms the application-level platform-admin authorization path exists without requiring a PostgreSQL `platform_admin` policy role
- it requires an overall PASS row before the Milestone 2 gate can be considered cleared

## Rollback considerations

Because the repair is additive, rollback is straightforward:

- remove the new repair migration from the migration history only by a deliberate down-migration or by restoring the database state in a disposable environment
- do not modify the previously executed Milestone 2 migration file
- preserve existing data and role assignments, especially Danielle’s platform-admin assignment and all seeded reference data
- maintain audit history immutability by keeping direct `UPDATE`/`DELETE` access to `audit_events` blocked

The canonical read-only verifier is at `C:\Users\danie\d9business-disc-conv-engine\supabase\scripts\verify_milestone_2_rls.sql`.

This script is intentionally read-only. It checks table existence, function existence, required object counts, RLS enablement, policy presence, key/index presence, Quick Capture dependency presence, and the required workflow/duplicate-management functions, then returns a consolidated PASS/FAIL result set with an OVERALL row.

How to interpret the result set:
- each row includes category, object_name, check_name, expected_result, actual_result, status, and details
- status values are only PASS or FAIL
- the OVERALL row must be PASS before the Milestone 2 gate is accepted
- a FAIL row for any required object means the live target project is not yet ready for the next acceptance gate
- schema verification does not replace live role-based browser testing against the real Supabase project
