# Deployment plan

## Target stack

- Frontend: Netlify
- Backend and storage: Supabase
- Database: PostgreSQL via Supabase
- Edge functions: Supabase Edge Functions or Netlify Functions

## Release 1 deployment status

Actual live results observed on 2026-09-02:

- the user confirmed that the corrected Supabase migration, seed, and verification scripts completed successfully in the target project
- Netlify serves the D9Network shell successfully
- direct route access for `/verification` loads successfully
- local automated test suite passes
- local production build passes
- the remaining check is final browser authentication validation after the Netlify build redeploys with the live environment variables

### Verified in this environment

- app shell loads on Netlify
- `/verification` direct route loads successfully
- local automated test suite passes
- production build passes
- the SQL installation was confirmed as successful by the user in the live Supabase project

### Pending live acceptance

- confirm the browser-safe Netlify variables are live in the deployed project: `VITE_SUPABASE_URL` and `VITE_SUPABASE_PUBLISHABLE_KEY`
- confirm a fresh Netlify deployment is triggered after the repo push
- create a real Supabase Auth user in the target project
- assign a live role in `public.user_role_assignments`
- verify sign-in, sign-out, session persistence, and protected routes in the browser
- confirm console and network requests are clean for auth and route behavior

Milestone 1 is ready for final browser auth and route validation once the redeployed Netlify site reflects the correct production environment variables.
