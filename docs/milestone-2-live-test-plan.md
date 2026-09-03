# Milestone 2 live acceptance test plan

## Local-only validation performed

- Full Vitest suite: 26 tests passing
- Production build: successful local TypeScript + Vite build

## Live acceptance still required

1. Apply the Milestone 1 migration in the target Supabase project.
2. Apply the Milestone 2 migration package in order.
3. Run the RLS verification script against the target project.
4. Verify platform_admin role assignment for danielle@focusquest.com.
5. Validate login, session restoration, and route guards.
6. Validate all operational screens against a live, role-aware Supabase session.
7. Check dashboard metrics and counts produced by live queries.
8. Confirm work queue, campaign, nomination, import, and duplicate-review flows through real DB writes.
9. Validate integration health and external-boundary states.
10. Confirm Netlify deployment and browser validation after the project is accepted.

## Explicit non-claim

This repository is not claiming that live Supabase or Netlify acceptance has been completed. The local repository is only ready for that live validation step.
