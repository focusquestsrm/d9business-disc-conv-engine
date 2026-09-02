# Security and roles

## Planned production model

- Supabase Auth for staff login and session management
- Row-level security for role-scoped record access
- Least-privilege role mapping for Operator, Campaign Manager, Verification Reviewer, Membership Owner, Platform Administrator, and Executive roles
- Consent ledger and suppression enforcement
- Audit logging for administrative actions and workflow history

## Release 1 status

This phase focuses on UI structure and operational design, and the app shell is functionally working in the browser. Live authentication, role enforcement, and database security are not yet accepted as complete.

## Live verification status

Actual live results observed on 2026-09-02:

- the user confirmed that the corrected SQL migration, seed, and verification scripts were executed successfully in the live Supabase project
- the Netlify route loads successfully
- the remaining acceptance check is to validate the live browser authentication flow against the redeployed production app
- the app must still be tested with a real Supabase user, a valid role assignment in `public.user_role_assignments`, and a live browser session
- the RLS restrictions still require a browser-based confirmation after a production login and protected-route test

These checks still require a real Supabase user, a role assignment, and a valid live session in the target project before the final auth and RLS acceptance can be marked as passed.
