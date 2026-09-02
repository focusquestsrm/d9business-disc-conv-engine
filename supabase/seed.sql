-- Seed only non-sensitive platform defaults for Milestone 1.
-- No real users, email addresses, business records, or service credentials.

INSERT INTO public.roles (id, code, display_name, description, is_system, is_active)
VALUES
  ('11111111-1111-4111-8111-111111111111', 'platform_admin', 'Platform Administrator', 'Full administrative access for platform configuration and governance.', true, true),
  ('22222222-2222-4222-8222-222222222222', 'product_owner', 'Product Owner', 'Owns roadmap, release priorities, and strategic platform decisions.', true, true),
  ('33333333-3333-4333-8333-333333333333', 'campaign_manager', 'Campaign Manager', 'Owns campaign strategy and operational delivery.', true, true),
  ('44444444-4444-4444-8444-444444444444', 'operator', 'Operator', 'Performs daily operational and intake tasks.', true, true),
  ('55555555-5555-4555-8555-555555555555', 'intern_or_researcher', 'Intern or Researcher', 'Supports research and data gathering with constrained access.', true, true),
  ('66666666-6666-4666-8666-666666666666', 'verification_reviewer', 'Verification Reviewer', 'Reviews D9 verification and approval workflows.', true, true),
  ('77777777-7777-4777-8777-777777777777', 'content_manager', 'Content Manager', 'Owns content, publishing, and engagement review.', true, true),
  ('88888888-8888-4888-8888-888888888888', 'membership_growth_owner', 'Membership or Growth Owner', 'Owns conversion, growth, and membership handoff processes.', true, true),
  ('99999999-9999-4999-8999-999999999999', 'executive_leader', 'Executive or Leader', 'Views strategic reporting and leadership dashboards.', true, true)
ON CONFLICT (code) DO NOTHING;

INSERT INTO public.permissions (id, code, display_name, description, is_system, is_active)
VALUES
  ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'view_platform', 'View the platform', 'Basic access to the platform dashboard and permitted modules.', true, true),
  ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'manage_users', 'Manage users', 'Create, update, and deactivate staff records and assignments.', true, true),
  ('cccccccc-cccc-4ccc-8ccc-cccccccccccc', 'manage_roles', 'Manage roles', 'Create and modify role definitions and assignment rules.', true, true),
  ('dddddddd-dddd-4ddd-8ddd-dddddddddddd', 'manage_application_settings', 'Manage application settings', 'Change application configuration and defaults.', true, true),
  ('eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee', 'manage_organization_settings', 'Manage organization settings', 'Change D9 organization and platform configuration.', true, true),
  ('ffffffff-ffff-4fff-8fff-ffffffffffff', 'manage_integrations', 'Manage integrations', 'Configure third-party integrations and registry settings.', true, true),
  ('12121212-1212-4121-8121-121212121212', 'view_audit_events', 'View audit events', 'Read append-only audit history for privileged actions.', true, true),
  ('13131313-1313-4131-8131-131313131313', 'view_operational_modules', 'View operational modules', 'Access operational discovery and workflow modules.', true, true),
  ('14141414-1414-4141-8141-141414141414', 'view_verification_modules', 'View verification modules', 'Access verification and approval modules.', true, true),
  ('15151515-1515-4151-8151-151515151515', 'view_content_modules', 'View content modules', 'Access social and content workflow modules.', true, true),
  ('16161616-1616-4161-8161-161616161616', 'view_conversion_modules', 'View conversion modules', 'Access conversion and membership lifecycle modules.', true, true),
  ('17171717-1717-4171-8171-171717171717', 'view_executive_reporting', 'View executive reporting', 'Access executive dashboards and attribution reporting.', true, true)
ON CONFLICT (code) DO NOTHING;

INSERT INTO public.role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM public.roles r
JOIN public.permissions p ON p.code IN (
  'view_platform',
  'manage_users',
  'manage_roles',
  'manage_application_settings',
  'manage_organization_settings',
  'manage_integrations',
  'view_audit_events',
  'view_operational_modules',
  'view_verification_modules',
  'view_content_modules',
  'view_conversion_modules',
  'view_executive_reporting'
)
WHERE r.code = 'platform_admin'
ON CONFLICT DO NOTHING;

INSERT INTO public.role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM public.roles r
JOIN public.permissions p ON p.code IN (
  'view_platform',
  'view_operational_modules',
  'view_verification_modules',
  'view_content_modules',
  'view_conversion_modules',
  'view_executive_reporting'
)
WHERE r.code IN ('product_owner', 'campaign_manager', 'operator', 'verification_reviewer', 'content_manager', 'membership_growth_owner', 'executive_leader')
ON CONFLICT DO NOTHING;

INSERT INTO public.role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM public.roles r
JOIN public.permissions p ON p.code IN (
  'view_platform',
  'view_operational_modules'
)
WHERE r.code = 'intern_or_researcher'
ON CONFLICT DO NOTHING;

INSERT INTO public.organization_settings (id, code, name, description, is_active)
VALUES
  ('a1111111-1111-4111-8111-111111111111', 'd9network', 'D9Network', 'Primary operating organization for the D9Network platform.', true),
  ('a2222222-2222-4222-8222-222222222222', 'alpha_phi_alpha', 'Alpha Phi Alpha', 'Alpha Phi Alpha organization configuration.', true),
  ('a3333333-3333-4333-8333-333333333333', 'alpha_kappa_alpha', 'Alpha Kappa Alpha', 'Alpha Kappa Alpha organization configuration.', true),
  ('a4444444-4444-4444-8444-444444444444', 'kappa_alpha_psi', 'Kappa Alpha Psi', 'Kappa Alpha Psi organization configuration.', true),
  ('a5555555-5555-4555-8555-555555555555', 'omega_psi_phi', 'Omega Psi Phi', 'Omega Psi Phi organization configuration.', true),
  ('a6666666-6666-4666-8666-666666666666', 'delta_sigma_theta', 'Delta Sigma Theta', 'Delta Sigma Theta organization configuration.', true),
  ('a7777777-7777-4777-8777-777777777777', 'phi_beta_sigma', 'Phi Beta Sigma', 'Phi Beta Sigma organization configuration.', true),
  ('a8888888-8888-4888-8888-888888888888', 'zeta_phi_beta', 'Zeta Phi Beta', 'Zeta Phi Beta organization configuration.', true),
  ('a9999999-9999-4999-8999-999999999999', 'sigma_gamma_rho', 'Sigma Gamma Rho', 'Sigma Gamma Rho organization configuration.', true),
  ('b1111111-1111-5111-8111-111111111111', 'iota_phi_theta', 'Iota Phi Theta', 'Iota Phi Theta organization configuration.', true)
ON CONFLICT (code) DO NOTHING;

INSERT INTO public.application_settings (id, key, value, description, is_system_default)
VALUES
  ('c1111111-1111-4111-8111-111111111111', 'app_name', '"D9Network"'::jsonb, 'Primary application name.', true),
  ('c2222222-2222-4222-8222-222222222222', 'app_environment', '"development"'::jsonb, 'Current application environment.', true),
  ('c3333333-3333-4333-8333-333333333333', 'platform_milestone', '"Milestone 1"'::jsonb, 'Active platform milestone.', true),
  ('c4444444-4444-4444-8444-444444444444', 'require_staff_profile', 'true'::jsonb, 'Require a staff profile for authenticated users.', true)
ON CONFLICT (key) DO NOTHING;

INSERT INTO public.integration_registry (id, code, name, category, status, metadata, is_active)
VALUES
  ('d1111111-1111-4111-8111-111111111111', 'brilliant_directories', 'Brilliant Directories', 'membership', 'inactive', '{"owner":"Membership","notes":"Read-only integration placeholder."}'::jsonb, true),
  ('d2222222-2222-4222-8222-222222222222', 'd9_intelligence_dashboard', 'D9 Intelligence Dashboard', 'analytics', 'inactive', '{"owner":"Leadership","notes":"Reporting interface placeholder."}'::jsonb, true),
  ('d3333333-3333-4333-8333-333333333333', 'd9_business_growth_marketplace', 'D9Network Business Growth Marketplace', 'growth', 'inactive', '{"owner":"Growth","notes":"Marketplace integration placeholder."}'::jsonb, true),
  ('d4444444-4444-4444-8444-444444444444', 'instagram', 'Instagram', 'social', 'inactive', '{"owner":"Content","notes":"Future publishing integration placeholder."}'::jsonb, true),
  ('d5555555-5555-4555-8555-555555555555', 'facebook', 'Facebook', 'social', 'inactive', '{"owner":"Content","notes":"Future publishing integration placeholder."}'::jsonb, true),
  ('d6666666-6666-4666-8666-666666666666', 'linkedin', 'LinkedIn', 'social', 'inactive', '{"owner":"Growth","notes":"Future networking integration placeholder."}'::jsonb, true),
  ('d7777777-7777-4777-8777-777777777777', 'email_provider', 'Email provider', 'communications', 'inactive', '{"owner":"Platform","notes":"Approved provider adapter placeholder."}'::jsonb, true)
ON CONFLICT (code) DO NOTHING;

INSERT INTO public.feature_modules (id, module_code, display_name, navigation_group, planned_milestone, activation_status, required_permission, sort_order, is_active)
VALUES
  ('e1111111-1111-4111-8111-111111111111', 'dashboard', 'Dashboard', 'Overview', 'Milestone 1', 'active', 'view_platform', 1, true),
  ('e2222222-2222-4222-8222-222222222222', 'users_and_roles', 'Users and Roles', 'System', 'Milestone 1', 'active', 'manage_users', 2, true),
  ('e3333333-3333-4333-8333-333333333333', 'integrations', 'Integrations', 'System', 'Milestone 1', 'active', 'manage_integrations', 3, true),
  ('e4444444-4444-4444-8444-444444444444', 'organization_settings', 'Organization Settings', 'System', 'Milestone 1', 'active', 'manage_organization_settings', 4, true),
  ('e5555555-5555-4555-8555-555555555555', 'audit_log', 'Audit Log', 'System', 'Milestone 1', 'active', 'view_audit_events', 5, true),
  ('e6666666-6666-4666-8666-666666666666', 'prospects', 'Prospects', 'Discovery', 'Milestone 2', 'planned', 'view_operational_modules', 6, true),
  ('e7777777-7777-4777-8777-777777777777', 'businesses', 'Businesses', 'Discovery', 'Milestone 2', 'planned', 'view_operational_modules', 7, true),
  ('e8888888-8888-4888-8888-888888888888', 'campaigns', 'Campaigns', 'Discovery', 'Milestone 2', 'planned', 'view_operational_modules', 8, true),
  ('e9999999-9999-4999-8999-999999999999', 'nominations', 'Nominations', 'Discovery', 'Milestone 2', 'planned', 'view_operational_modules', 9, true),
  ('f1111111-1111-5111-8111-111111111111', 'imports', 'Imports', 'Discovery', 'Milestone 2', 'planned', 'view_operational_modules', 10, true),
  ('f2222222-2222-5222-8222-222222222222', 'd9_verification', 'D9 Verification', 'Review and Approval', 'Milestone 3', 'planned', 'view_verification_modules', 11, true),
  ('f3333333-3333-5333-8333-333333333333', 'consent_review', 'Consent Review', 'Review and Approval', 'Milestone 3', 'planned', 'view_verification_modules', 12, true),
  ('f4444444-4444-5444-8444-444444444444', 'duplicate_review', 'Duplicate Review', 'Review and Approval', 'Milestone 3', 'planned', 'view_verification_modules', 13, true),
  ('f5555555-5555-5555-8555-555555555555', 'social_inbox', 'Social Inbox', 'Social Engagement', 'Milestone 4', 'planned', 'view_content_modules', 14, true),
  ('f6666666-6666-5666-8666-666666666666', 'content_studio', 'Content Studio', 'Social Engagement', 'Milestone 4', 'planned', 'view_content_modules', 15, true),
  ('f7777777-7777-5777-8777-777777777777', 'publishing_calendar', 'Publishing Calendar', 'Social Engagement', 'Milestone 5', 'planned', 'view_content_modules', 16, true),
  ('f8888888-8888-5888-8888-888888888888', 'social_performance', 'Social Performance', 'Social Engagement', 'Milestone 5', 'planned', 'view_content_modules', 17, true),
  ('f9999999-9999-5999-8999-999999999999', 'membership_handoffs', 'Membership Handoffs', 'Conversion and Growth', 'Milestone 6', 'planned', 'view_conversion_modules', 18, true),
  ('91111111-1111-6111-8111-111111111111', 'd9_intelligence_integration', 'D9 Intelligence Integration', 'Intelligence', 'Milestone 6', 'planned', 'view_executive_reporting', 19, true),
  ('92222222-2222-6222-8222-222222222222', 'executive_attribution_reporting', 'Executive Attribution Reporting', 'Intelligence', 'Milestone 7', 'planned', 'view_executive_reporting', 20, true)
ON CONFLICT (module_code) DO NOTHING;
