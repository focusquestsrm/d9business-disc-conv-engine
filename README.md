# D9Network Business Discovery & Conversion Engine

This repository holds the ongoing Milestone 1 foundation for the D9Network platform. It delivers a D9Network-styled shell, grouped navigation, protected placeholder routes, and operational platform status views while keeping all future milestone modules explicitly marked as not yet active.

## Current foundation

- D9Network application shell with grouped navigation and professional layout
- Dashboard for platform readiness, milestone tracking, and admin status
- Multi-section shell covering overview, discovery, social engagement, approval, conversion, intelligence, and system functions
- Honest placeholder routes for future Milestone 2 and later modules instead of fake-complete functionality
- Netlify redirect configuration for SPA direct-route support
- Supabase client bootstrap guarded behind environment variables
- Vitest + Testing Library validation for the current shell and placeholder route behavior

## Local development

```bash
npm install
npm run dev
```

## Validation

```bash
npm run test
npm run build
```

## Deployment notes

This project includes a Netlify redirect configuration to ensure route refreshes resolve to the SPA entry point:

- `public/_redirects`
- `netlify.toml`

## Environment variables

Use `.env.example` locally and configure Supabase values before enabling live authentication or service-backed data layers.

## Important guardrails

- This is not claiming Milestone 2 or later social discovery modules as complete.
- Future modules are intentionally marked as not yet active.
- Supabase service-role secrets are never committed and are not exposed to the browser.
