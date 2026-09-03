# Milestone 2 security and authorization plan

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

## Live requirements still deferred

- execution and verification of RLS policies in a real Supabase environment
- audit-history immutability checks
- privilege-escalation prevention tests validated through live DB role contexts
- real browser-level authorization checks using the production role model

The repository includes a verification script at supabase/scripts/verify_milestone_2_rls.sql and a mirror at supabase/verification/verify_milestone_2_rls.sql, but neither claims live execution has occurred locally.
