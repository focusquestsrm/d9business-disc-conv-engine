# Supabase administrator bootstrap

This document provides the safe process for Danielle to become the first administrator for the D9Network platform without hard-coding credentials or identity values.

1. Create the first user in the Supabase Auth dashboard or via `supabase auth` commands.
2. Capture the Auth user UUID from the `auth.users` table.
3. Confirm the related row in `public.staff_profiles` exists.
4. Assign the `platform_admin` role using an approved SQL command such as:

```sql
INSERT INTO public.user_role_assignments (user_id, role_id)
SELECT au.id, r.id
FROM auth.users au
JOIN public.roles r ON r.code = 'platform_admin'
WHERE au.email = 'danielle@your-domain.example';
```

5. Verify the assignment:

```sql
SELECT sp.display_name, r.code
FROM public.staff_profiles sp
JOIN public.user_role_assignments ura ON ura.user_id = sp.id
JOIN public.roles r ON r.id = ura.role_id
WHERE sp.id = '<auth-user-uuid>';
```

6. Log into the application and confirm the administrator access path loads.

Do not seed a real administrator or hard-code Danielle's email, password, or UUID into the repository.
