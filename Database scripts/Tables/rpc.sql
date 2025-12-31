-- =============================================
-- FUNCTION: get_current_tenant_id
-- =============================================
CREATE OR REPLACE FUNCTION public.get_current_tenant_id()
RETURNS uuid
LANGUAGE plpgsql
STABLE SECURITY DEFINER
AS $function$
BEGIN
    -- Get tenant_id from JWT claims
    RETURN NULLIF(current_setting('request.jwt.claims', true)::json->>'tenant_id', '')::UUID;
EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;
END;
$function$;

-- =============================================
-- FUNCTION: get_user_tenant_ids
-- =============================================
CREATE OR REPLACE FUNCTION public.get_user_tenant_ids()
RETURNS uuid[]
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
BEGIN
  RETURN ARRAY(
    SELECT tenant_id 
    FROM t_user_tenants 
    WHERE user_id = auth.uid() 
    AND status = 'active'
  );
END;
$function$;

-- =============================================
-- FUNCTION: has_tenant_access
-- =============================================
CREATE OR REPLACE FUNCTION public.has_tenant_access(check_tenant_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
BEGIN
  -- Check if user has access to this tenant
  RETURN EXISTS (
    SELECT 1 FROM t_user_tenants
    WHERE user_id = auth.uid()
    AND tenant_id = check_tenant_id
    AND status = 'active'
  );
END;
$function$;

-- =============================================
-- FUNCTION: is_tenant_admin
-- =============================================
CREATE OR REPLACE FUNCTION public.is_tenant_admin(check_tenant_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM t_user_tenants
    WHERE user_id = auth.uid()
    AND tenant_id = check_tenant_id
    AND is_admin = true
    AND status = 'active'
  );
END;
$function$;

-- =============================================
-- FUNCTION: initialize_tenant_onboarding (TRIGGER)
-- =============================================
CREATE OR REPLACE FUNCTION public.initialize_tenant_onboarding()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
BEGIN
    -- Create main onboarding record
    INSERT INTO t_tenant_onboarding (
        tenant_id,
        onboarding_type,
        total_steps,
        step_data
    ) VALUES (
        NEW.id,
        'business',
        6,
        '{}'::jsonb
    );
    
    -- Create individual step records
    INSERT INTO t_onboarding_step_status (tenant_id, step_id, step_sequence, status)
    VALUES 
        (NEW.id, 'user-profile', 1, 'pending'),
        (NEW.id, 'business-profile', 2, 'pending'),
        (NEW.id, 'data-setup', 3, 'pending'),
        (NEW.id, 'storage', 4, 'pending'),
        (NEW.id, 'team', 5, 'pending'),
        (NEW.id, 'tour', 6, 'pending');
    
    RETURN NEW;
END;
$function$;


-- =============================================
-- FUNCTION: has_tenant_role
-- =============================================
CREATE OR REPLACE FUNCTION public.has_tenant_role(check_tenant_id uuid, role_names text[])
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM t_user_tenants ut
    JOIN t_user_tenant_roles utr ON ut.id = utr.user_tenant_id
    JOIN t_category_details cd ON utr.role_id = cd.id
    WHERE ut.user_id = auth.uid()
    AND ut.tenant_id = check_tenant_id
    AND ut.status = 'active'
    AND cd.sub_cat_name = ANY(role_names)
  );
END;
$function$;

