-- Safe verification script for local or Supabase review.
-- Run these statements in the SQL editor with the appropriate role context.

SELECT 'anonymous_users_should_not_read_roles' AS check_name,
       COUNT(*) AS rows_returned
FROM public.roles;

SELECT 'authenticated_users_can_read_own_staff_profile' AS check_name,
       COUNT(*) AS rows_returned
FROM public.staff_profiles
WHERE id = auth.uid();

SELECT 'platform_admins_can_manage_role_assignments' AS check_name,
       COUNT(*) AS rows_returned
FROM public.user_role_assignments;

SELECT 'audit_events_are_append_only' AS check_name,
       COUNT(*) AS rows_returned
FROM public.audit_events;

-- Manual policy tests:
-- 1. As anon, verify the public tables return no data.
-- 2. As a regular authenticated user, verify only their own staff profile is readable.
-- 3. As a platform admin, verify role assignment and settings updates work.
-- 4. As a non-admin user, verify update/delete on audit_events is denied.
