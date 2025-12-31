-- =============================================
-- TABLE: t_user_profiles
-- =============================================
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

-- =============================================
-- TABLE: t_user_auth_methods
-- =============================================
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

-- =============================================
-- TABLE: t_tenants
-- =============================================
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

-- =============================================
-- TABLE: t_user_tenants
-- =============================================
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

-- =============================================
-- TABLE: t_user_tenant_roles
-- =============================================
CREATE TABLE t_user_tenant_roles (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_tenant_id uuid,
  role_id uuid,
  created_at timestamptz DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamptz DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id)
);

-- =============================================
-- TABLE: t_tenant_profiles
-- =============================================
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

-- =============================================
-- TABLE: t_tenant_onboarding
-- =============================================
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
-- TABLE: t_category_master
-- =============================================
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

-- =============================================
-- TABLE: t_category_details
-- =============================================
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

-- Foreign key for category_details -> category_master
ALTER TABLE t_category_details
  ADD CONSTRAINT t_category_details_category_id_fkey 
  FOREIGN KEY (category_id) REFERENCES t_category_master(id);


-- =============================================
-- FOREIGN KEY CONSTRAINTS
-- =============================================

-- t_user_tenants
ALTER TABLE t_user_tenants
  ADD CONSTRAINT t_user_tenants_tenant_id_fkey 
  FOREIGN KEY (tenant_id) REFERENCES t_tenants(id);

-- t_user_tenant_roles
ALTER TABLE t_user_tenant_roles
  ADD CONSTRAINT t_user_tenant_roles_user_tenant_id_fkey 
  FOREIGN KEY (user_tenant_id) REFERENCES t_user_tenants(id);

ALTER TABLE t_user_tenant_roles
  ADD CONSTRAINT t_user_tenant_roles_role_id_fkey 
  FOREIGN KEY (role_id) REFERENCES t_category_details(id);

-- t_tenant_profiles
ALTER TABLE t_tenant_profiles
  ADD CONSTRAINT t_tenant_profiles_tenant_id_fkey 
  FOREIGN KEY (tenant_id) REFERENCES t_tenants(id);

-- t_tenant_onboarding
ALTER TABLE t_tenant_onboarding
  ADD CONSTRAINT t_tenant_onboarding_tenant_id_fkey 
  FOREIGN KEY (tenant_id) REFERENCES t_tenants(id);