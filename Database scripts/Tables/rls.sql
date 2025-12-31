-- =============================================
-- ENABLE RLS ON ALL TABLES
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