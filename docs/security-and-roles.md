# Security and roles

## Planned production model

- Supabase Auth for staff login and session management
- Row-level security for role-scoped record access
- Least-privilege role mapping for Operator, Campaign Manager, Verification Reviewer, Membership Owner, Platform Administrator, and Executive roles
- Consent ledger and suppression enforcement
- Audit logging for administrative actions and workflow history

## Release 1 status

Milestone 1 is accepted for the current release scope. The application shell, live authentication flow, role-based route access, and admin session lifecycle have been validated in the production environment.

## Live verification status

Confirmed live results observed on 2026-09-02:

- the corrected SQL migration, seed, and verification scripts were executed successfully in the live Supabase project
- the Netlify app offers a working live sign-in flow
- `danielle@focusquest.com` authenticated successfully as a platform administrator
- role-based access from `public.user_role_assignments` was loaded and enforced in the browser
- protected admin routes were accessible to the platform-admin account
- signed-out guards redirected unauthenticated users back to the login page
- the forgot-password control is clearly marked as coming soon and is not a broken dead link

The platform foundation and live access controls are accepted for Milestone 1. Remaining limitations are scoped to future milestone functionality and broader operational expansion, not to the current foundation acceptance.
