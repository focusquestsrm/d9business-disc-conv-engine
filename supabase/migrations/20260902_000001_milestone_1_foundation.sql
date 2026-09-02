CREATE EXTENSION IF NOT EXISTS pgcrypto;

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

CREATE TABLE public.staff_profiles (
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

CREATE TABLE public.roles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code text NOT NULL UNIQUE,
  display_name text NOT NULL,
  description text,
  is_system boolean NOT NULL DEFAULT false,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.permissions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code text NOT NULL UNIQUE,
  display_name text NOT NULL,
  description text,
  is_system boolean NOT NULL DEFAULT false,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.user_role_assignments (
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

CREATE TABLE public.role_permissions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  role_id uuid NOT NULL REFERENCES public.roles(id) ON DELETE CASCADE,
  permission_id uuid NOT NULL REFERENCES public.permissions(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (role_id, permission_id)
);

CREATE TABLE public.application_settings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  key text NOT NULL UNIQUE,
  value jsonb NOT NULL,
  description text,
  is_system_default boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.organization_settings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code text NOT NULL UNIQUE,
  name text NOT NULL,
  description text,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.integration_registry (
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

CREATE TABLE public.feature_modules (
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

CREATE TABLE public.audit_events (
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

CREATE TRIGGER set_staff_profiles_updated_at
BEFORE UPDATE ON public.staff_profiles
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER set_roles_updated_at
BEFORE UPDATE ON public.roles
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER set_permissions_updated_at
BEFORE UPDATE ON public.permissions
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER set_user_role_assignments_updated_at
BEFORE UPDATE ON public.user_role_assignments
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER set_role_permissions_updated_at
BEFORE UPDATE ON public.role_permissions
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER set_application_settings_updated_at
BEFORE UPDATE ON public.application_settings
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER set_organization_settings_updated_at
BEFORE UPDATE ON public.organization_settings
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER set_integration_registry_updated_at
BEFORE UPDATE ON public.integration_registry
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER set_feature_modules_updated_at
BEFORE UPDATE ON public.feature_modules
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

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

CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW
EXECUTE FUNCTION public.handle_new_auth_user();

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

CREATE POLICY "Anonymous users cannot read internal platform data"
ON public.staff_profiles
FOR SELECT
USING (false);

CREATE POLICY "Users may read their own profile"
ON public.staff_profiles
FOR SELECT
USING (id = auth.uid());

CREATE POLICY "Platform admins may read all profiles"
ON public.staff_profiles
FOR SELECT
USING (public.current_user_is_platform_admin());

CREATE POLICY "Users may update their own profile"
ON public.staff_profiles
FOR UPDATE
USING (id = auth.uid())
WITH CHECK (id = auth.uid() AND (display_name IS NOT NULL));

CREATE POLICY "Platform admins manage roles"
ON public.roles
FOR ALL
USING (public.current_user_is_platform_admin())
WITH CHECK (public.current_user_is_platform_admin());

CREATE POLICY "Authenticated staff can read role metadata when allowed"
ON public.roles
FOR SELECT
USING (auth.uid() IS NOT NULL AND public.user_has_permission('view_platform'));

CREATE POLICY "Platform admins manage permissions"
ON public.permissions
FOR ALL
USING (public.current_user_is_platform_admin())
WITH CHECK (public.current_user_is_platform_admin());

CREATE POLICY "Authenticated staff can read permission metadata when allowed"
ON public.permissions
FOR SELECT
USING (auth.uid() IS NOT NULL AND public.user_has_permission('view_platform'));

CREATE POLICY "Users can read their own role assignments"
ON public.user_role_assignments
FOR SELECT
USING (user_id = auth.uid() OR public.current_user_is_platform_admin() OR public.user_has_permission('manage_users'));

CREATE POLICY "Only platform admins can manage role assignments"
ON public.user_role_assignments
FOR ALL
USING (public.current_user_is_platform_admin() AND user_id IS DISTINCT FROM auth.uid())
WITH CHECK (public.current_user_is_platform_admin() AND user_id IS DISTINCT FROM auth.uid());

CREATE POLICY "Read role permissions for authenticated users with platform access"
ON public.role_permissions
FOR SELECT
USING (auth.uid() IS NOT NULL AND public.user_has_permission('view_platform'));

CREATE POLICY "Only platform admins can manage role permissions"
ON public.role_permissions
FOR ALL
USING (public.current_user_is_platform_admin())
WITH CHECK (public.current_user_is_platform_admin());

CREATE POLICY "Authenticated users can read application settings with platform access"
ON public.application_settings
FOR SELECT
USING (auth.uid() IS NOT NULL AND public.user_has_permission('view_platform'));

CREATE POLICY "Only platform admins can update application settings"
ON public.application_settings
FOR ALL
USING (public.current_user_is_platform_admin())
WITH CHECK (public.current_user_is_platform_admin());

CREATE POLICY "Authenticated users can read organization settings with platform access"
ON public.organization_settings
FOR SELECT
USING (auth.uid() IS NOT NULL AND public.user_has_permission('view_platform'));

CREATE POLICY "Only authorized admins can manage organization settings"
ON public.organization_settings
FOR ALL
USING (public.current_user_is_platform_admin() OR public.user_has_permission('manage_organization_settings'))
WITH CHECK (public.current_user_is_platform_admin() OR public.user_has_permission('manage_organization_settings'));

CREATE POLICY "Authenticated users with platform access can read integrations"
ON public.integration_registry
FOR SELECT
USING (auth.uid() IS NOT NULL AND public.user_has_permission('view_platform'));

CREATE POLICY "Only authorized admins can manage integrations"
ON public.integration_registry
FOR ALL
USING (public.current_user_is_platform_admin() OR public.user_has_permission('manage_integrations'))
WITH CHECK (public.current_user_is_platform_admin() OR public.user_has_permission('manage_integrations'));

CREATE POLICY "Authenticated users with platform access can read feature modules"
ON public.feature_modules
FOR SELECT
USING (auth.uid() IS NOT NULL AND public.user_has_permission('view_platform'));

CREATE POLICY "Only platform admins can manage feature modules"
ON public.feature_modules
FOR ALL
USING (public.current_user_is_platform_admin())
WITH CHECK (public.current_user_is_platform_admin());

CREATE POLICY "Authenticated users with audit access can read audit events"
ON public.audit_events
FOR SELECT
USING (auth.uid() IS NOT NULL AND public.user_has_permission('view_audit_events'));

CREATE POLICY "No direct audit updates or deletes"
ON public.audit_events
FOR UPDATE
USING (false);

CREATE POLICY "No direct audit deletes"
ON public.audit_events
FOR DELETE
USING (false);

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

CREATE TRIGGER audit_application_settings_changes
AFTER INSERT OR UPDATE ON public.application_settings
FOR EACH ROW
EXECUTE FUNCTION public.audit_config_change();

CREATE TRIGGER audit_organization_settings_changes
AFTER INSERT OR UPDATE ON public.organization_settings
FOR EACH ROW
EXECUTE FUNCTION public.audit_config_change();

CREATE TRIGGER audit_integration_registry_changes
AFTER INSERT OR UPDATE ON public.integration_registry
FOR EACH ROW
EXECUTE FUNCTION public.audit_config_change();

CREATE TRIGGER audit_role_changes
AFTER INSERT OR UPDATE ON public.roles
FOR EACH ROW
EXECUTE FUNCTION public.audit_config_change();

CREATE TRIGGER audit_permission_changes
AFTER INSERT OR UPDATE ON public.permissions
FOR EACH ROW
EXECUTE FUNCTION public.audit_config_change();

CREATE TRIGGER audit_role_permission_changes
AFTER INSERT OR UPDATE ON public.role_permissions
FOR EACH ROW
EXECUTE FUNCTION public.audit_config_change();

CREATE TRIGGER audit_user_role_changes
AFTER INSERT OR UPDATE ON public.user_role_assignments
FOR EACH ROW
EXECUTE FUNCTION public.audit_config_change();
