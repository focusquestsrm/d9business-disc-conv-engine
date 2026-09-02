CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS public.roles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code text NOT NULL UNIQUE,
  display_name text NOT NULL,
  description text,
  is_system boolean NOT NULL DEFAULT false,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.permissions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code text NOT NULL UNIQUE,
  display_name text NOT NULL,
  description text,
  is_system boolean NOT NULL DEFAULT false,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.staff_profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name text NOT NULL,
  first_name text,
  last_name text,
  job_title text,
  staff_status text NOT NULL DEFAULT 'pending' CHECK (staff_status IN ('pending', 'active', 'inactive', 'suspended')),
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  last_login_at timestamptz
);

CREATE TABLE IF NOT EXISTS public.user_role_assignments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role_id uuid NOT NULL REFERENCES public.roles(id) ON DELETE CASCADE,
  is_active boolean NOT NULL DEFAULT true,
  assigned_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  assigned_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, role_id)
);

CREATE TABLE IF NOT EXISTS public.role_permissions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  role_id uuid NOT NULL REFERENCES public.roles(id) ON DELETE CASCADE,
  permission_id uuid NOT NULL REFERENCES public.permissions(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (role_id, permission_id)
);

CREATE TABLE IF NOT EXISTS public.application_settings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  key text NOT NULL UNIQUE,
  value jsonb NOT NULL,
  description text,
  is_system_default boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.organization_settings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code text NOT NULL UNIQUE,
  name text NOT NULL,
  description text,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.integration_registry (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code text NOT NULL UNIQUE,
  name text NOT NULL,
  category text,
  status text NOT NULL DEFAULT 'inactive' CHECK (status IN ('inactive', 'configured', 'read_only', 'blocked', 'not_configured')),
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.feature_modules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  module_code text NOT NULL UNIQUE,
  display_name text NOT NULL,
  navigation_group text,
  planned_milestone text NOT NULL,
  activation_status text NOT NULL DEFAULT 'planned' CHECK (activation_status IN ('planned', 'active', 'disabled')),
  required_permission text,
  sort_order integer NOT NULL DEFAULT 0,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.audit_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  action text NOT NULL,
  entity_type text NOT NULL,
  entity_id text,
  previous_values jsonb,
  new_values jsonb,
  source text NOT NULL DEFAULT 'platform',
  reason text,
  correlation_id text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_staff_profiles_status
  ON public.staff_profiles (staff_status, is_active);

CREATE INDEX IF NOT EXISTS idx_user_role_assignments_user
  ON public.user_role_assignments (user_id, is_active);

CREATE INDEX IF NOT EXISTS idx_user_role_assignments_role
  ON public.user_role_assignments (role_id, is_active);

CREATE INDEX IF NOT EXISTS idx_role_permissions_role
  ON public.role_permissions (role_id);

CREATE INDEX IF NOT EXISTS idx_feature_modules_group
  ON public.feature_modules (navigation_group, sort_order);

CREATE INDEX IF NOT EXISTS idx_integration_registry_status
  ON public.integration_registry (status, is_active);

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.current_user_is_platform_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, auth
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.user_role_assignments ura
    JOIN public.roles r ON r.id = ura.role_id
    WHERE ura.user_id = auth.uid()
      AND r.code = 'platform_admin'
      AND ura.is_active = true
  );
$$;

CREATE OR REPLACE FUNCTION public.user_has_permission(permission_code text)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, auth
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.user_role_assignments ura
    JOIN public.role_permissions rp ON rp.role_id = ura.role_id
    JOIN public.permissions p ON p.id = rp.permission_id
    WHERE ura.user_id = auth.uid()
      AND ura.is_active = true
      AND p.code = permission_code
  );
$$;

CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
  INSERT INTO public.staff_profiles (
    id,
    display_name,
    first_name,
    last_name,
    job_title,
    staff_status,
    is_active,
    created_at,
    updated_at,
    last_login_at
  )
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data ->> 'full_name', NEW.email, 'New Staff User'),
    COALESCE(NEW.raw_user_meta_data ->> 'first_name', NULL),
    COALESCE(NEW.raw_user_meta_data ->> 'last_name', NULL),
    COALESCE(NEW.raw_user_meta_data ->> 'job_title', 'Pending assignment'),
    'pending',
    true,
    NOW(),
    NOW(),
    NULL
  )
  ON CONFLICT (id) DO NOTHING;

  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.audit_config_change()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
  IF TG_OP = 'UPDATE' THEN
    INSERT INTO public.audit_events (
      actor_user_id,
      action,
      entity_type,
      entity_id,
      previous_values,
      new_values,
      source,
      reason,
      correlation_id
    )
    VALUES (
      auth.uid(),
      'UPDATE',
      TG_TABLE_NAME,
      NEW.id::text,
      jsonb_build_object('before', row_to_json(OLD)),
      jsonb_build_object('after', row_to_json(NEW)),
      'database_trigger',
      'Privileged configuration update',
      gen_random_uuid()::text
    );
  ELSIF TG_OP = 'INSERT' THEN
    INSERT INTO public.audit_events (
      actor_user_id,
      action,
      entity_type,
      entity_id,
      previous_values,
      new_values,
      source,
      reason,
      correlation_id
    )
    VALUES (
      auth.uid(),
      'INSERT',
      TG_TABLE_NAME,
      NEW.id::text,
      NULL,
      jsonb_build_object('after', row_to_json(NEW)),
      'database_trigger',
      'Privileged configuration insert',
      gen_random_uuid()::text
    );
  END IF;

  RETURN NEW;
END;
$$;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'set_staff_profiles_updated_at' AND tgrelid = 'public.staff_profiles'::regclass) THEN
    EXECUTE 'DROP TRIGGER IF EXISTS set_staff_profiles_updated_at ON public.staff_profiles';
  END IF;
END $$;
CREATE TRIGGER set_staff_profiles_updated_at
BEFORE UPDATE ON public.staff_profiles
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'set_roles_updated_at' AND tgrelid = 'public.roles'::regclass) THEN
    EXECUTE 'DROP TRIGGER IF EXISTS set_roles_updated_at ON public.roles';
  END IF;
END $$;
CREATE TRIGGER set_roles_updated_at
BEFORE UPDATE ON public.roles
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'set_permissions_updated_at' AND tgrelid = 'public.permissions'::regclass) THEN
    EXECUTE 'DROP TRIGGER IF EXISTS set_permissions_updated_at ON public.permissions';
  END IF;
END $$;
CREATE TRIGGER set_permissions_updated_at
BEFORE UPDATE ON public.permissions
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'set_user_role_assignments_updated_at' AND tgrelid = 'public.user_role_assignments'::regclass) THEN
    EXECUTE 'DROP TRIGGER IF EXISTS set_user_role_assignments_updated_at ON public.user_role_assignments';
  END IF;
END $$;
CREATE TRIGGER set_user_role_assignments_updated_at
BEFORE UPDATE ON public.user_role_assignments
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'set_role_permissions_updated_at' AND tgrelid = 'public.role_permissions'::regclass) THEN
    EXECUTE 'DROP TRIGGER IF EXISTS set_role_permissions_updated_at ON public.role_permissions';
  END IF;
END $$;
CREATE TRIGGER set_role_permissions_updated_at
BEFORE UPDATE ON public.role_permissions
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'set_application_settings_updated_at' AND tgrelid = 'public.application_settings'::regclass) THEN
    EXECUTE 'DROP TRIGGER IF EXISTS set_application_settings_updated_at ON public.application_settings';
  END IF;
END $$;
CREATE TRIGGER set_application_settings_updated_at
BEFORE UPDATE ON public.application_settings
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'set_organization_settings_updated_at' AND tgrelid = 'public.organization_settings'::regclass) THEN
    EXECUTE 'DROP TRIGGER IF EXISTS set_organization_settings_updated_at ON public.organization_settings';
  END IF;
END $$;
CREATE TRIGGER set_organization_settings_updated_at
BEFORE UPDATE ON public.organization_settings
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'set_integration_registry_updated_at' AND tgrelid = 'public.integration_registry'::regclass) THEN
    EXECUTE 'DROP TRIGGER IF EXISTS set_integration_registry_updated_at ON public.integration_registry';
  END IF;
END $$;
CREATE TRIGGER set_integration_registry_updated_at
BEFORE UPDATE ON public.integration_registry
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'set_feature_modules_updated_at' AND tgrelid = 'public.feature_modules'::regclass) THEN
    EXECUTE 'DROP TRIGGER IF EXISTS set_feature_modules_updated_at ON public.feature_modules';
  END IF;
END $$;
CREATE TRIGGER set_feature_modules_updated_at
BEFORE UPDATE ON public.feature_modules
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'on_auth_user_created' AND tgrelid = 'auth.users'::regclass) THEN
    EXECUTE 'DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users';
  END IF;
END $$;
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW
EXECUTE FUNCTION public.handle_new_auth_user();

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'audit_application_settings_changes' AND tgrelid = 'public.application_settings'::regclass) THEN
    EXECUTE 'DROP TRIGGER IF EXISTS audit_application_settings_changes ON public.application_settings';
  END IF;
END $$;
CREATE TRIGGER audit_application_settings_changes
AFTER INSERT OR UPDATE ON public.application_settings
FOR EACH ROW
EXECUTE FUNCTION public.audit_config_change();

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'audit_organization_settings_changes' AND tgrelid = 'public.organization_settings'::regclass) THEN
    EXECUTE 'DROP TRIGGER IF EXISTS audit_organization_settings_changes ON public.organization_settings';
  END IF;
END $$;
CREATE TRIGGER audit_organization_settings_changes
AFTER INSERT OR UPDATE ON public.organization_settings
FOR EACH ROW
EXECUTE FUNCTION public.audit_config_change();

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'audit_integration_registry_changes' AND tgrelid = 'public.integration_registry'::regclass) THEN
    EXECUTE 'DROP TRIGGER IF EXISTS audit_integration_registry_changes ON public.integration_registry';
  END IF;
END $$;
CREATE TRIGGER audit_integration_registry_changes
AFTER INSERT OR UPDATE ON public.integration_registry
FOR EACH ROW
EXECUTE FUNCTION public.audit_config_change();

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'audit_role_changes' AND tgrelid = 'public.roles'::regclass) THEN
    EXECUTE 'DROP TRIGGER IF EXISTS audit_role_changes ON public.roles';
  END IF;
END $$;
CREATE TRIGGER audit_role_changes
AFTER INSERT OR UPDATE ON public.roles
FOR EACH ROW
EXECUTE FUNCTION public.audit_config_change();

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'audit_permission_changes' AND tgrelid = 'public.permissions'::regclass) THEN
    EXECUTE 'DROP TRIGGER IF EXISTS audit_permission_changes ON public.permissions';
  END IF;
END $$;
CREATE TRIGGER audit_permission_changes
AFTER INSERT OR UPDATE ON public.permissions
FOR EACH ROW
EXECUTE FUNCTION public.audit_config_change();

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'audit_role_permission_changes' AND tgrelid = 'public.role_permissions'::regclass) THEN
    EXECUTE 'DROP TRIGGER IF EXISTS audit_role_permission_changes ON public.role_permissions';
  END IF;
END $$;
CREATE TRIGGER audit_role_permission_changes
AFTER INSERT OR UPDATE ON public.role_permissions
FOR EACH ROW
EXECUTE FUNCTION public.audit_config_change();

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'audit_user_role_changes' AND tgrelid = 'public.user_role_assignments'::regclass) THEN
    EXECUTE 'DROP TRIGGER IF EXISTS audit_user_role_changes ON public.user_role_assignments';
  END IF;
END $$;
CREATE TRIGGER audit_user_role_changes
AFTER INSERT OR UPDATE ON public.user_role_assignments
FOR EACH ROW
EXECUTE FUNCTION public.audit_config_change();

ALTER TABLE public.staff_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_role_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.role_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.application_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.organization_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.integration_registry ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.feature_modules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_events ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'staff_profiles'
      AND policyname = 'Anonymous users cannot read internal platform data'
  ) THEN
    CREATE POLICY "Anonymous users cannot read internal platform data"
    ON public.staff_profiles
    FOR SELECT
    USING (false);
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'staff_profiles'
      AND policyname = 'Users may read their own profile'
  ) THEN
    CREATE POLICY "Users may read their own profile"
    ON public.staff_profiles
    FOR SELECT
    USING (id = auth.uid());
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'staff_profiles'
      AND policyname = 'Platform admins may read all profiles'
  ) THEN
    CREATE POLICY "Platform admins may read all profiles"
    ON public.staff_profiles
    FOR SELECT
    USING (public.current_user_is_platform_admin());
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'staff_profiles'
      AND policyname = 'Users may update their own profile'
  ) THEN
    CREATE POLICY "Users may update their own profile"
    ON public.staff_profiles
    FOR UPDATE
    USING (id = auth.uid())
    WITH CHECK (id = auth.uid() AND (display_name IS NOT NULL));
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'roles'
      AND policyname = 'Platform admins manage roles'
  ) THEN
    CREATE POLICY "Platform admins manage roles"
    ON public.roles
    FOR ALL
    USING (public.current_user_is_platform_admin())
    WITH CHECK (public.current_user_is_platform_admin());
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'roles'
      AND policyname = 'Authenticated staff can read role metadata when allowed'
  ) THEN
    CREATE POLICY "Authenticated staff can read role metadata when allowed"
    ON public.roles
    FOR SELECT
    USING (auth.uid() IS NOT NULL AND public.user_has_permission('view_platform'));
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'permissions'
      AND policyname = 'Platform admins manage permissions'
  ) THEN
    CREATE POLICY "Platform admins manage permissions"
    ON public.permissions
    FOR ALL
    USING (public.current_user_is_platform_admin())
    WITH CHECK (public.current_user_is_platform_admin());
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'permissions'
      AND policyname = 'Authenticated staff can read permission metadata when allowed'
  ) THEN
    CREATE POLICY "Authenticated staff can read permission metadata when allowed"
    ON public.permissions
    FOR SELECT
    USING (auth.uid() IS NOT NULL AND public.user_has_permission('view_platform'));
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'user_role_assignments'
      AND policyname = 'Users can read their own role assignments'
  ) THEN
    CREATE POLICY "Users can read their own role assignments"
    ON public.user_role_assignments
    FOR SELECT
    USING (user_id = auth.uid() OR public.current_user_is_platform_admin() OR public.user_has_permission('manage_users'));
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'user_role_assignments'
      AND policyname = 'Only platform admins can manage role assignments'
  ) THEN
    CREATE POLICY "Only platform admins can manage role assignments"
    ON public.user_role_assignments
    FOR ALL
    USING (public.current_user_is_platform_admin() AND user_id IS DISTINCT FROM auth.uid())
    WITH CHECK (public.current_user_is_platform_admin() AND user_id IS DISTINCT FROM auth.uid());
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'role_permissions'
      AND policyname = 'Read role permissions for authenticated users with platform access'
  ) THEN
    CREATE POLICY "Read role permissions for authenticated users with platform access"
    ON public.role_permissions
    FOR SELECT
    USING (auth.uid() IS NOT NULL AND public.user_has_permission('view_platform'));
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'role_permissions'
      AND policyname = 'Only platform admins can manage role permissions'
  ) THEN
    CREATE POLICY "Only platform admins can manage role permissions"
    ON public.role_permissions
    FOR ALL
    USING (public.current_user_is_platform_admin())
    WITH CHECK (public.current_user_is_platform_admin());
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'application_settings'
      AND policyname = 'Authenticated users can read application settings with platform access'
  ) THEN
    CREATE POLICY "Authenticated users can read application settings with platform access"
    ON public.application_settings
    FOR SELECT
    USING (auth.uid() IS NOT NULL AND public.user_has_permission('view_platform'));
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'application_settings'
      AND policyname = 'Only platform admins can update application settings'
  ) THEN
    CREATE POLICY "Only platform admins can update application settings"
    ON public.application_settings
    FOR ALL
    USING (public.current_user_is_platform_admin())
    WITH CHECK (public.current_user_is_platform_admin());
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'organization_settings'
      AND policyname = 'Authenticated users can read organization settings with platform access'
  ) THEN
    CREATE POLICY "Authenticated users can read organization settings with platform access"
    ON public.organization_settings
    FOR SELECT
    USING (auth.uid() IS NOT NULL AND public.user_has_permission('view_platform'));
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'organization_settings'
      AND policyname = 'Only authorized admins can manage organization settings'
  ) THEN
    CREATE POLICY "Only authorized admins can manage organization settings"
    ON public.organization_settings
    FOR ALL
    USING (public.current_user_is_platform_admin() OR public.user_has_permission('manage_organization_settings'))
    WITH CHECK (public.current_user_is_platform_admin() OR public.user_has_permission('manage_organization_settings'));
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'integration_registry'
      AND policyname = 'Authenticated users with platform access can read integrations'
  ) THEN
    CREATE POLICY "Authenticated users with platform access can read integrations"
    ON public.integration_registry
    FOR SELECT
    USING (auth.uid() IS NOT NULL AND public.user_has_permission('view_platform'));
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'integration_registry'
      AND policyname = 'Only authorized admins can manage integrations'
  ) THEN
    CREATE POLICY "Only authorized admins can manage integrations"
    ON public.integration_registry
    FOR ALL
    USING (public.current_user_is_platform_admin() OR public.user_has_permission('manage_integrations'))
    WITH CHECK (public.current_user_is_platform_admin() OR public.user_has_permission('manage_integrations'));
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'feature_modules'
      AND policyname = 'Authenticated users with platform access can read feature modules'
  ) THEN
    CREATE POLICY "Authenticated users with platform access can read feature modules"
    ON public.feature_modules
    FOR SELECT
    USING (auth.uid() IS NOT NULL AND public.user_has_permission('view_platform'));
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'feature_modules'
      AND policyname = 'Only platform admins can manage feature modules'
  ) THEN
    CREATE POLICY "Only platform admins can manage feature modules"
    ON public.feature_modules
    FOR ALL
    USING (public.current_user_is_platform_admin())
    WITH CHECK (public.current_user_is_platform_admin());
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'audit_events'
      AND policyname = 'Authenticated users with audit access can read audit events'
  ) THEN
    CREATE POLICY "Authenticated users with audit access can read audit events"
    ON public.audit_events
    FOR SELECT
    USING (auth.uid() IS NOT NULL AND public.user_has_permission('view_audit_events'));
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'audit_events'
      AND policyname = 'No direct audit updates or deletes'
  ) THEN
    CREATE POLICY "No direct audit updates or deletes"
    ON public.audit_events
    FOR UPDATE
    USING (false);
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'audit_events'
      AND policyname = 'No direct audit deletes'
  ) THEN
    CREATE POLICY "No direct audit deletes"
    ON public.audit_events
    FOR DELETE
    USING (false);
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'audit_events'
      AND policyname = 'Only authorized administrators can append audit records'
  ) THEN
    CREATE POLICY "Only authorized administrators can append audit records"
    ON public.audit_events
    FOR INSERT
    WITH CHECK (
      auth.uid() IS NOT NULL AND (
        public.current_user_is_platform_admin()
        OR public.user_has_permission('manage_roles')
        OR public.user_has_permission('manage_application_settings')
        OR public.user_has_permission('manage_organization_settings')
        OR public.user_has_permission('manage_integrations')
        OR public.user_has_permission('manage_users')
      )
    );
  END IF;
END $$;

GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT ON TABLE public.roles, public.permissions, public.role_permissions, public.organization_settings, public.integration_registry, public.feature_modules TO authenticated;
GRANT SELECT ON TABLE public.staff_profiles TO authenticated;
GRANT UPDATE ON TABLE public.staff_profiles TO authenticated;
GRANT INSERT, UPDATE, DELETE ON TABLE public.audit_events TO authenticated;

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.application_settings TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.organization_settings TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.integration_registry TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.feature_modules TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.roles TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.permissions TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.user_role_assignments TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.role_permissions TO authenticated;
