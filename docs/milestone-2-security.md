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

The canonical read-only verifier is at C:\Users\danie\d9business-disc-conv-engine\supabase\scripts\verify_milestone_2_rls.sql.

This script is intentionally read-only. It checks table existence, function existence, required object counts, RLS enablement, policy presence, key/index presence, Quick Capture dependency presence, and the required workflow/duplicate-management functions, then returns a consolidated PASS/FAIL result set with an OVERALL row.

How to interpret the result set:
- each row includes category, object_name, check_name, expected_result, actual_result, status, and details
- status values are only PASS or FAIL
- the OVERALL row must be PASS before Netlify acceptance begins
- a FAIL row for any required object means the live target project is not yet ready for the next acceptance gate
- schema verification does not replace live role-based browser testing against the real Supabase project
