-- =============================================
-- SUPABASE MULTI-TENANT SCHEMA MIGRATION
-- Generated: 2025
-- Mode: DROP + CREATE (Destructive)
-- =============================================

-- =============================================
-- DROP TABLES FIRST (CASCADE removes triggers, policies, constraints)
-- =============================================
DROP TABLE IF EXISTS t_tenant_onboarding CASCADE;
DROP TABLE IF EXISTS t_tenant_profiles CASCADE;
DROP TABLE IF EXISTS t_user_tenant_roles CASCADE;
DROP TABLE IF EXISTS t_user_tenants CASCADE;
DROP TABLE IF EXISTS t_user_auth_methods CASCADE;
DROP TABLE IF EXISTS t_user_profiles CASCADE;
DROP TABLE IF EXISTS t_tenants CASCADE;
DROP TABLE IF EXISTS t_category_details CASCADE;
DROP TABLE IF EXISTS t_category_master CASCADE;

-- =============================================
-- DROP FUNCTIONS
-- =============================================
DROP FUNCTION IF EXISTS public.get_current_tenant_id();
DROP FUNCTION IF EXISTS public.get_user_tenant_ids();
DROP FUNCTION IF EXISTS public.has_tenant_access(uuid);
DROP FUNCTION IF EXISTS public.is_tenant_admin(uuid);
DROP FUNCTION IF EXISTS public.has_tenant_role(uuid, text[]);
DROP FUNCTION IF EXISTS public.update_updated_at_column();
DROP FUNCTION IF EXISTS public.ensure_single_primary_auth_method();
DROP FUNCTION IF EXISTS public.initialize_tenant_onboarding();

-- =============================================
-- EXTENSIONS
-- =============================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================
-- CREATE TABLES (in dependency order)
-- =============================================

-- Table: t_category_master
CREATE TABLE t_category_master (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  category_name varchar(100) NOT NULL,
  display_name varchar(100) NOT NULL,
  is_active boolean DEFAULT true,
  description text,
  icon_name varchar(50),
  order_sequence integer,
  tenant_id uuid,
  created_at timestamptz DEFAULT CURRENT_TIMESTAMP,
  is_live boolean DEFAULT true,
  PRIMARY KEY (id)
);

-- Table: t_category_details
CREATE TABLE t_category_details (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  sub_cat_name varchar(100) NOT NULL,
  display_name varchar(100) NOT NULL,
  category_id uuid,
  hexcolor varchar(10),
  icon_name varchar(50),
  tags jsonb,
  tool_tip text,
  is_active boolean DEFAULT true,
  sequence_no integer,
  description text,
  tenant_id uuid,
  is_deletable boolean DEFAULT true,
  form_settings jsonb,
  created_at timestamptz DEFAULT CURRENT_TIMESTAMP,
  is_live boolean DEFAULT true,
  PRIMARY KEY (id)
);

-- Table: t_tenants
CREATE TABLE t_tenants (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  name varchar(100) NOT NULL,
  domain varchar(255),
  workspace_code varchar(20) NOT NULL,
  plan_id uuid,
  status varchar(20) NOT NULL,
  settings jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamptz DEFAULT CURRENT_TIMESTAMP,
  created_by uuid,
  is_admin boolean DEFAULT false,
  storage_path text,
  storage_quota integer NOT NULL DEFAULT 40,
  storage_consumed integer NOT NULL DEFAULT 0,
  storage_provider text NOT NULL DEFAULT 'firebase'::text,
  storage_setup_complete boolean NOT NULL DEFAULT false,
  PRIMARY KEY (id)
);

-- Table: t_user_profiles
CREATE TABLE t_user_profiles (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid,
  first_name varchar(100) NOT NULL,
  last_name varchar(100) NOT NULL,
  email varchar(255) NOT NULL,
  country_code varchar(5),
  mobile_number varchar(15),
  user_code varchar(8) NOT NULL,
  avatar_url varchar(255),
  preferred_theme varchar(50),
  is_dark_mode boolean DEFAULT false,
  preferred_language varchar(10) DEFAULT 'en'::character varying,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamptz DEFAULT CURRENT_TIMESTAMP,
  is_admin boolean DEFAULT false,
  PRIMARY KEY (id)
);

-- Table: t_user_auth_methods
CREATE TABLE t_user_auth_methods (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  auth_type varchar(50) NOT NULL,
  auth_identifier varchar(255) NOT NULL,
  is_primary boolean DEFAULT false,
  is_verified boolean DEFAULT true,
  linked_at timestamptz DEFAULT CURRENT_TIMESTAMP,
  last_used_at timestamptz,
  metadata jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamptz DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id)
);

-- Table: t_user_tenants
CREATE TABLE t_user_tenants (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid,
  tenant_id uuid,
  is_default boolean DEFAULT false,
  status varchar(20) NOT NULL,
  invitation_token varchar(100),
  invitation_expires_at timestamptz,
  created_at timestamptz DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamptz DEFAULT CURRENT_TIMESTAMP,
  is_admin boolean DEFAULT false,
  PRIMARY KEY (id)
);

-- Table: t_user_tenant_roles
CREATE TABLE t_user_tenant_roles (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_tenant_id uuid,
  role_id uuid,
  created_at timestamptz DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamptz DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id)
);

-- Table: t_tenant_profiles
CREATE TABLE t_tenant_profiles (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  tenant_id uuid,
  profile_type varchar(20) NOT NULL,
  business_name varchar(255),
  business_email varchar(255),
  business_phone_country_code varchar(5),
  business_phone varchar(15),
  country_code varchar(5),
  state_code varchar(10),
  address_line1 varchar(255),
  address_line2 varchar(255),
  city varchar(100),
  postal_code varchar(20),
  logo_url varchar(255),
  primary_color varchar(10),
  secondary_color varchar(10),
  created_at timestamptz DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamptz DEFAULT CURRENT_TIMESTAMP,
  industry_id varchar,
  website_url varchar,
  business_type_id varchar,
  business_phone_code varchar(4),
  business_whatsapp_country_code varchar(10),
  business_whatsapp varchar(20),
  short_description varchar(200),
  booking_url varchar(500),
  contact_first_name varchar(100),
  contact_last_name varchar(100),
  PRIMARY KEY (id)
);

-- Table: t_tenant_onboarding
CREATE TABLE t_tenant_onboarding (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL,
  onboarding_type varchar(20) DEFAULT 'business'::character varying,
  current_step integer DEFAULT 1,
  total_steps integer DEFAULT 6,
  completed_steps jsonb DEFAULT '[]'::jsonb,
  skipped_steps jsonb DEFAULT '[]'::jsonb,
  step_data jsonb DEFAULT '{}'::jsonb,
  started_at timestamptz DEFAULT CURRENT_TIMESTAMP,
  completed_at timestamptz,
  is_completed boolean DEFAULT false,
  created_at timestamptz DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamptz DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id)
);

-- =============================================
-- FOREIGN KEY CONSTRAINTS
-- =============================================

-- t_category_details -> t_category_master
ALTER TABLE t_category_details
  ADD CONSTRAINT t_category_details_category_id_fkey 
  FOREIGN KEY (category_id) REFERENCES t_category_master(id);

-- t_user_tenants -> t_tenants
ALTER TABLE t_user_tenants
  ADD CONSTRAINT t_user_tenants_tenant_id_fkey 
  FOREIGN KEY (tenant_id) REFERENCES t_tenants(id);

-- t_user_tenant_roles -> t_user_tenants
ALTER TABLE t_user_tenant_roles
  ADD CONSTRAINT t_user_tenant_roles_user_tenant_id_fkey 
  FOREIGN KEY (user_tenant_id) REFERENCES t_user_tenants(id);

-- t_user_tenant_roles -> t_category_details
ALTER TABLE t_user_tenant_roles
  ADD CONSTRAINT t_user_tenant_roles_role_id_fkey 
  FOREIGN KEY (role_id) REFERENCES t_category_details(id);

-- t_tenant_profiles -> t_tenants
ALTER TABLE t_tenant_profiles
  ADD CONSTRAINT t_tenant_profiles_tenant_id_fkey 
  FOREIGN KEY (tenant_id) REFERENCES t_tenants(id);

-- t_tenant_onboarding -> t_tenants
ALTER TABLE t_tenant_onboarding
  ADD CONSTRAINT t_tenant_onboarding_tenant_id_fkey 
  FOREIGN KEY (tenant_id) REFERENCES t_tenants(id);

-- =============================================
-- CREATE FUNCTIONS
-- =============================================

-- Function: get_current_tenant_id
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

-- Function: get_user_tenant_ids
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

-- Function: has_tenant_access
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

-- Function: is_tenant_admin
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

-- Function: has_tenant_role
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

-- Function: update_updated_at_column (Trigger Function)
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$function$;

-- Function: ensure_single_primary_auth_method (Trigger Function)
CREATE OR REPLACE FUNCTION public.ensure_single_primary_auth_method()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
BEGIN
  IF NEW.is_primary = true THEN
    UPDATE t_user_auth_methods 
    SET is_primary = false 
    WHERE user_id = NEW.user_id 
      AND id != NEW.id;
  END IF;
  RETURN NEW;
END;
$function$;

-- Function: initialize_tenant_onboarding (Trigger Function)
-- NOTE: This function references t_onboarding_step_status table which may need to be created separately
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
    -- NOTE: Requires t_onboarding_step_status table
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
-- CREATE TRIGGERS
-- =============================================

-- Trigger: Initialize tenant onboarding after tenant creation
CREATE TRIGGER after_tenant_created 
  AFTER INSERT ON t_tenants 
  FOR EACH ROW 
  EXECUTE FUNCTION initialize_tenant_onboarding();

-- Trigger: Enforce single primary auth method
CREATE TRIGGER enforce_single_primary_auth_method 
  BEFORE INSERT OR UPDATE ON t_user_auth_methods 
  FOR EACH ROW 
  WHEN (new.is_primary = true) 
  EXECUTE FUNCTION ensure_single_primary_auth_method();

-- Trigger: Auto-update updated_at column
CREATE TRIGGER update_user_auth_methods_updated_at 
  BEFORE UPDATE ON t_user_auth_methods 
  FOR EACH ROW 
  EXECUTE FUNCTION update_updated_at_column();

-- =============================================
-- ENABLE ROW LEVEL SECURITY
-- =============================================
ALTER TABLE t_user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE t_user_auth_methods ENABLE ROW LEVEL SECURITY;
ALTER TABLE t_user_tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE t_user_tenant_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE t_tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE t_tenant_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE t_tenant_onboarding ENABLE ROW LEVEL SECURITY;
ALTER TABLE t_category_master ENABLE ROW LEVEL SECURITY;
ALTER TABLE t_category_details ENABLE ROW LEVEL SECURITY;

-- =============================================
-- RLS POLICIES: t_user_profiles
-- =============================================
CREATE POLICY "superadmin_bypass" ON t_user_profiles
  AS PERMISSIVE FOR ALL TO public
  USING ((auth.jwt() ->> 'role'::text) = 'supabase_admin'::text);

CREATE POLICY "user_profiles_tenant_isolation" ON t_user_profiles
  AS PERMISSIVE FOR SELECT TO authenticated
  USING (
    (user_id = auth.uid()) OR 
    (user_id IN (
      SELECT ut.user_id FROM t_user_tenants ut
      WHERE (ut.tenant_id = get_current_tenant_id()) AND has_tenant_access(ut.tenant_id)
    ))
  );

CREATE POLICY "user_profiles_insert_policy" ON t_user_profiles
  AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK (
    (user_id = auth.uid()) OR 
    (EXISTS (
      SELECT 1 FROM t_user_tenants ut
      WHERE (ut.tenant_id = get_current_tenant_id()) 
        AND (ut.user_id = auth.uid()) 
        AND has_tenant_role(ut.tenant_id, ARRAY['Owner'::text, 'Admin'::text])
    ))
  );

CREATE POLICY "user_profiles_update_policy" ON t_user_profiles
  AS PERMISSIVE FOR UPDATE TO authenticated
  USING (
    (user_id = auth.uid()) OR 
    (user_id IN (
      SELECT ut.user_id FROM t_user_tenants ut
      WHERE (ut.tenant_id = get_current_tenant_id()) 
        AND has_tenant_access(ut.tenant_id) 
        AND has_tenant_role(ut.tenant_id, ARRAY['Owner'::text, 'Admin'::text])
    ))
  );

CREATE POLICY "user_profiles_delete_policy" ON t_user_profiles
  AS PERMISSIVE FOR DELETE TO authenticated
  USING (
    (user_id = auth.uid()) OR 
    (user_id IN (
      SELECT ut.user_id FROM t_user_tenants ut
      WHERE (ut.tenant_id = get_current_tenant_id()) 
        AND has_tenant_access(ut.tenant_id) 
        AND has_tenant_role(ut.tenant_id, ARRAY['Owner'::text, 'Admin'::text])
    ))
  );

-- =============================================
-- RLS POLICIES: t_user_auth_methods
-- =============================================
CREATE POLICY "Service role can manage auth methods" ON t_user_auth_methods
  AS PERMISSIVE FOR ALL TO public
  USING ((auth.jwt() ->> 'role'::text) = 'service_role'::text);

CREATE POLICY "Users can view own auth methods" ON t_user_auth_methods
  AS PERMISSIVE FOR SELECT TO public
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update own auth methods" ON t_user_auth_methods
  AS PERMISSIVE FOR UPDATE TO public
  USING (auth.uid() = user_id);

-- =============================================
-- RLS POLICIES: t_tenants
-- =============================================
CREATE POLICY "tenants_tenant_isolation" ON t_tenants
  AS PERMISSIVE FOR SELECT TO authenticated
  USING (
    (EXISTS (
      SELECT 1 FROM t_user_tenants
      WHERE (t_user_tenants.tenant_id = t_tenants.id) 
        AND (t_user_tenants.user_id = auth.uid()) 
        AND ((t_user_tenants.status)::text = 'active'::text)
    )) OR (created_by = auth.uid())
  );

CREATE POLICY "tenant_creation_during_signup" ON t_tenants
  AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "tenants_insert_policy" ON t_tenants
  AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "tenants_update_policy" ON t_tenants
  AS PERMISSIVE FOR UPDATE TO authenticated
  USING (
    (created_by = auth.uid()) OR 
    (is_admin = true) OR 
    (EXISTS (
      SELECT 1 FROM t_user_tenants
      WHERE (t_user_tenants.tenant_id = t_tenants.id) 
        AND (t_user_tenants.user_id = auth.uid()) 
        AND ((t_user_tenants.status)::text = 'active'::text)
    ))
  );

-- =============================================
-- RLS POLICIES: t_user_tenants
-- =============================================
CREATE POLICY "user_tenants_tenant_isolation" ON t_user_tenants
  AS PERMISSIVE FOR SELECT TO authenticated
  USING (
    (user_id = auth.uid()) OR 
    ((tenant_id = get_current_tenant_id()) AND has_tenant_access(tenant_id))
  );

CREATE POLICY "user_tenants_insert_policy" ON t_user_tenants
  AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK (
    (user_id = auth.uid()) OR 
    (((user_id = auth.uid()) AND (tenant_id = get_current_tenant_id())) OR 
    ((tenant_id = get_current_tenant_id()) 
      AND has_tenant_access(tenant_id) 
      AND has_tenant_role(tenant_id, ARRAY['Owner'::text, 'Admin'::text])))
  );

CREATE POLICY "user_tenants_update_policy" ON t_user_tenants
  AS PERMISSIVE FOR UPDATE TO authenticated
  USING (
    ((user_id = auth.uid()) AND (tenant_id = get_current_tenant_id())) OR 
    ((tenant_id = get_current_tenant_id()) 
      AND has_tenant_access(tenant_id) 
      AND has_tenant_role(tenant_id, ARRAY['Owner'::text, 'Admin'::text]))
  );

CREATE POLICY "user_tenants_delete_policy" ON t_user_tenants
  AS PERMISSIVE FOR DELETE TO authenticated
  USING (
    ((user_id = auth.uid()) AND (tenant_id = get_current_tenant_id())) OR 
    ((tenant_id = get_current_tenant_id()) 
      AND has_tenant_access(tenant_id) 
      AND has_tenant_role(tenant_id, ARRAY['Owner'::text, 'Admin'::text]))
  );

-- =============================================
-- RLS POLICIES: t_user_tenant_roles
-- =============================================
CREATE POLICY "user_tenant_roles_tenant_isolation" ON t_user_tenant_roles
  AS PERMISSIVE FOR SELECT TO authenticated
  USING (
    user_tenant_id IN (
      SELECT t_user_tenants.id FROM t_user_tenants
      WHERE (t_user_tenants.user_id = auth.uid()) OR 
        ((t_user_tenants.tenant_id = get_current_tenant_id()) 
          AND has_tenant_access(t_user_tenants.tenant_id))
    )
  );

CREATE POLICY "user_tenant_roles_insert_policy" ON t_user_tenant_roles
  AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK (
    user_tenant_id IN (
      SELECT ut.id FROM t_user_tenants ut
      WHERE (ut.tenant_id = get_current_tenant_id()) 
        AND has_tenant_access(ut.tenant_id) 
        AND has_tenant_role(ut.tenant_id, ARRAY['Owner'::text, 'Admin'::text])
    )
  );

CREATE POLICY "user_tenant_roles_update_policy" ON t_user_tenant_roles
  AS PERMISSIVE FOR UPDATE TO authenticated
  USING (
    user_tenant_id IN (
      SELECT ut.id FROM t_user_tenants ut
      WHERE (ut.tenant_id = get_current_tenant_id()) 
        AND has_tenant_access(ut.tenant_id) 
        AND has_tenant_role(ut.tenant_id, ARRAY['Owner'::text, 'Admin'::text])
    )
  );

CREATE POLICY "user_tenant_roles_delete_policy" ON t_user_tenant_roles
  AS PERMISSIVE FOR DELETE TO authenticated
  USING (
    user_tenant_id IN (
      SELECT ut.id FROM t_user_tenants ut
      WHERE (ut.tenant_id = get_current_tenant_id()) 
        AND has_tenant_access(ut.tenant_id) 
        AND has_tenant_role(ut.tenant_id, ARRAY['Owner'::text, 'Admin'::text])
    )
  );

-- =============================================
-- RLS POLICIES: t_tenant_profiles
-- =============================================
CREATE POLICY "tenant_profiles_service_role_policy" ON t_tenant_profiles
  AS PERMISSIVE FOR ALL TO service_role
  USING (true)
  WITH CHECK (true);

CREATE POLICY "tenant_profiles_select_policy" ON t_tenant_profiles
  AS PERMISSIVE FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM t_user_tenants ut
      WHERE (ut.user_id = auth.uid()) 
        AND (ut.tenant_id = t_tenant_profiles.tenant_id) 
        AND ((ut.status)::text = 'active'::text)
    )
  );

CREATE POLICY "tenant_profiles_insert_policy" ON t_tenant_profiles
  AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM t_user_tenants ut
      JOIN t_user_tenant_roles utr ON (ut.id = utr.user_tenant_id)
      JOIN t_category_details cd ON (utr.role_id = cd.id)
      WHERE (ut.user_id = auth.uid()) 
        AND (ut.tenant_id = t_tenant_profiles.tenant_id) 
        AND ((ut.status)::text = 'active'::text) 
        AND ((cd.sub_cat_name)::text = ANY (ARRAY['Owner', 'Admin']))
    )
  );

CREATE POLICY "tenant_profiles_update_policy" ON t_tenant_profiles
  AS PERMISSIVE FOR UPDATE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM t_user_tenants ut
      JOIN t_user_tenant_roles utr ON (ut.id = utr.user_tenant_id)
      JOIN t_category_details cd ON (utr.role_id = cd.id)
      WHERE (ut.user_id = auth.uid()) 
        AND (ut.tenant_id = t_tenant_profiles.tenant_id) 
        AND ((ut.status)::text = 'active'::text) 
        AND ((cd.sub_cat_name)::text = ANY (ARRAY['Owner', 'Admin']))
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM t_user_tenants ut
      JOIN t_user_tenant_roles utr ON (ut.id = utr.user_tenant_id)
      JOIN t_category_details cd ON (utr.role_id = cd.id)
      WHERE (ut.user_id = auth.uid()) 
        AND (ut.tenant_id = t_tenant_profiles.tenant_id) 
        AND ((ut.status)::text = 'active'::text) 
        AND ((cd.sub_cat_name)::text = ANY (ARRAY['Owner', 'Admin']))
    )
  );

CREATE POLICY "tenant_profiles_delete_policy" ON t_tenant_profiles
  AS PERMISSIVE FOR DELETE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM t_user_tenants ut
      JOIN t_user_tenant_roles utr ON (ut.id = utr.user_tenant_id)
      JOIN t_category_details cd ON (utr.role_id = cd.id)
      WHERE (ut.user_id = auth.uid()) 
        AND (ut.tenant_id = t_tenant_profiles.tenant_id) 
        AND ((ut.status)::text = 'active'::text) 
        AND ((cd.sub_cat_name)::text = 'Owner'::text)
    )
  );

-- =============================================
-- RLS POLICIES: t_tenant_onboarding
-- =============================================
CREATE POLICY "tenant_onboarding_select" ON t_tenant_onboarding
  AS PERMISSIVE FOR SELECT TO public
  USING (
    tenant_id IN (
      SELECT t_user_tenants.tenant_id FROM t_user_tenants
      WHERE (t_user_tenants.user_id = auth.uid()) 
        AND ((t_user_tenants.status)::text = 'active'::text)
    )
  );

CREATE POLICY "tenant_onboarding_insert" ON t_tenant_onboarding
  AS PERMISSIVE FOR INSERT TO public
  WITH CHECK (
    tenant_id IN (
      SELECT t_user_tenants.tenant_id FROM t_user_tenants
      WHERE (t_user_tenants.user_id = auth.uid()) 
        AND ((t_user_tenants.status)::text = 'active'::text)
    )
  );

CREATE POLICY "tenant_onboarding_update" ON t_tenant_onboarding
  AS PERMISSIVE FOR UPDATE TO public
  USING (
    tenant_id IN (
      SELECT t_user_tenants.tenant_id FROM t_user_tenants
      WHERE (t_user_tenants.user_id = auth.uid()) 
        AND ((t_user_tenants.status)::text = 'active'::text)
    )
  );

-- =============================================
-- RLS POLICIES: t_category_master
-- =============================================
CREATE POLICY "category_master_tenant_isolation" ON t_category_master
  AS PERMISSIVE FOR SELECT TO authenticated
  USING ((tenant_id = get_current_tenant_id()) AND has_tenant_access(tenant_id));

CREATE POLICY "category_master_insert_policy" ON t_category_master
  AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK (
    (tenant_id = get_current_tenant_id()) 
    AND has_tenant_access(tenant_id) 
    AND has_tenant_role(tenant_id, ARRAY['Owner'::text, 'Admin'::text])
  );

CREATE POLICY "category_master_update_policy" ON t_category_master
  AS PERMISSIVE FOR UPDATE TO authenticated
  USING (
    (tenant_id = get_current_tenant_id()) 
    AND has_tenant_access(tenant_id) 
    AND has_tenant_role(tenant_id, ARRAY['Owner'::text, 'Admin'::text])
  );

CREATE POLICY "category_master_delete_policy" ON t_category_master
  AS PERMISSIVE FOR DELETE TO authenticated
  USING (
    (tenant_id = get_current_tenant_id()) 
    AND has_tenant_access(tenant_id) 
    AND has_tenant_role(tenant_id, ARRAY['Owner'::text, 'Admin'::text])
  );

-- =============================================
-- RLS POLICIES: t_category_details
-- =============================================
CREATE POLICY "category_details_tenant_isolation" ON t_category_details
  AS PERMISSIVE FOR SELECT TO authenticated
  USING ((tenant_id = get_current_tenant_id()) AND has_tenant_access(tenant_id));

CREATE POLICY "category_details_insert_policy" ON t_category_details
  AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK (
    (tenant_id = get_current_tenant_id()) 
    AND has_tenant_access(tenant_id) 
    AND has_tenant_role(tenant_id, ARRAY['Owner'::text, 'Admin'::text])
  );

CREATE POLICY "category_details_update_policy" ON t_category_details
  AS PERMISSIVE FOR UPDATE TO authenticated
  USING (
    (tenant_id = get_current_tenant_id()) 
    AND has_tenant_access(tenant_id) 
    AND has_tenant_role(tenant_id, ARRAY['Owner'::text, 'Admin'::text])
  );

CREATE POLICY "category_details_delete_policy" ON t_category_details
  AS PERMISSIVE FOR DELETE TO authenticated
  USING (
    (tenant_id = get_current_tenant_id()) 
    AND has_tenant_access(tenant_id) 
    AND has_tenant_role(tenant_id, ARRAY['Owner'::text, 'Admin'::text]) 
    AND (is_deletable = true)
  );

-- =============================================
-- END OF MIGRATION
-- =============================================