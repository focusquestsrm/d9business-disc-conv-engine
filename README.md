# D9Network Business Discovery & Conversion Engine

This repository contains the working Release 1 foundation for the D9Network Business Discovery & Conversion Engine. The project uses React, TypeScript, and Vite to deliver a D9Network-branded dashboard, operational workflow shell, and quick intake experience.

## Current foundation

- Compact D9Network-styled application shell
- Dashboard with operational metrics and work queue summary
- Quick prospect intake form with status-aware workflow routing
- Campaign workspace and queue table views
- Mock data model aligned with the D9 discovery and conversion lifecycle
- Vitest + Testing Library validation for the primary user flow

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

## Environment variables

Use the template in `.env.example` and configure the values locally before connecting to real backend services.

## Notes

This release is intentionally framework-first and client-side. It is prepared for future Supabase, Netlify, and workflow-integration phases described in the project brief.
