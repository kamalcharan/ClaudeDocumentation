-- =============================================================
-- R1 Task 1.10: RLS policies for all new tables
--
-- Pattern (verified from live DB):
--   m_ tables: authenticated can SELECT, service_role full access
--   t_ tables: tenant_id isolation via JWT claims
--   m_cat_blocks: hybrid (tenant_id OR is_seed OR admin)
-- =============================================================

-- ─────────────────────────────────────────────
-- MASTER TABLES: read for authenticated, write for service_role
-- ─────────────────────────────────────────────

-- m_equipment_variants
ALTER TABLE public.m_equipment_variants ENABLE ROW LEVEL SECURITY;

CREATE POLICY "m_equipment_variants_read"
  ON public.m_equipment_variants FOR SELECT
  TO authenticated
  USING (is_active = true);

CREATE POLICY "m_equipment_variants_service_role"
  ON public.m_equipment_variants
  TO service_role
  USING (true);

-- m_equipment_spare_parts
ALTER TABLE public.m_equipment_spare_parts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "m_equipment_spare_parts_read"
  ON public.m_equipment_spare_parts FOR SELECT
  TO authenticated
  USING (is_active = true);

CREATE POLICY "m_equipment_spare_parts_service_role"
  ON public.m_equipment_spare_parts
  TO service_role
  USING (true);

-- m_spare_part_variant_map
ALTER TABLE public.m_spare_part_variant_map ENABLE ROW LEVEL SECURITY;

CREATE POLICY "m_spare_part_variant_map_read"
  ON public.m_spare_part_variant_map FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "m_spare_part_variant_map_service_role"
  ON public.m_spare_part_variant_map
  TO service_role
  USING (true);

-- m_equipment_checkpoints
ALTER TABLE public.m_equipment_checkpoints ENABLE ROW LEVEL SECURITY;

CREATE POLICY "m_equipment_checkpoints_read"
  ON public.m_equipment_checkpoints FOR SELECT
  TO authenticated
  USING (is_active = true);

CREATE POLICY "m_equipment_checkpoints_service_role"
  ON public.m_equipment_checkpoints
  TO service_role
  USING (true);

-- m_checkpoint_values
ALTER TABLE public.m_checkpoint_values ENABLE ROW LEVEL SECURITY;

CREATE POLICY "m_checkpoint_values_read"
  ON public.m_checkpoint_values FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "m_checkpoint_values_service_role"
  ON public.m_checkpoint_values
  TO service_role
  USING (true);

-- m_checkpoint_variant_map
ALTER TABLE public.m_checkpoint_variant_map ENABLE ROW LEVEL SECURITY;

CREATE POLICY "m_checkpoint_variant_map_read"
  ON public.m_checkpoint_variant_map FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "m_checkpoint_variant_map_service_role"
  ON public.m_checkpoint_variant_map
  TO service_role
  USING (true);

-- m_service_cycles
ALTER TABLE public.m_service_cycles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "m_service_cycles_read"
  ON public.m_service_cycles FOR SELECT
  TO authenticated
  USING (is_active = true);

CREATE POLICY "m_service_cycles_service_role"
  ON public.m_service_cycles
  TO service_role
  USING (true);

-- m_context_overlays
ALTER TABLE public.m_context_overlays ENABLE ROW LEVEL SECURITY;

CREATE POLICY "m_context_overlays_read"
  ON public.m_context_overlays FOR SELECT
  TO authenticated
  USING (is_active = true);

CREATE POLICY "m_context_overlays_service_role"
  ON public.m_context_overlays
  TO service_role
  USING (true);


-- ─────────────────────────────────────────────
-- TENANT TABLES: isolation via JWT tenant_id claim
-- Pattern matches m_form_tenant_selections (verified)
-- ─────────────────────────────────────────────

-- t_equipment
ALTER TABLE public.t_equipment ENABLE ROW LEVEL SECURITY;

CREATE POLICY "t_equipment_tenant_isolation"
  ON public.t_equipment FOR ALL
  USING (
    tenant_id::text = current_setting('request.jwt.claims', true)::json->>'tenant_id'
  );

CREATE POLICY "t_equipment_admin_access"
  ON public.t_equipment FOR ALL
  USING (
    (auth.jwt()->>'is_admin')::boolean = true
  );

-- t_form_templates (tenant forks)
ALTER TABLE public.t_form_templates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "t_form_templates_tenant_isolation"
  ON public.t_form_templates FOR ALL
  USING (
    tenant_id::text = current_setting('request.jwt.claims', true)::json->>'tenant_id'
  );

CREATE POLICY "t_form_templates_admin_access"
  ON public.t_form_templates FOR ALL
  USING (
    (auth.jwt()->>'is_admin')::boolean = true
  );

-- t_custom_variants
ALTER TABLE public.t_custom_variants ENABLE ROW LEVEL SECURITY;

CREATE POLICY "t_custom_variants_tenant_isolation"
  ON public.t_custom_variants FOR ALL
  USING (
    tenant_id::text = current_setting('request.jwt.claims', true)::json->>'tenant_id'
  );

-- t_custom_spare_parts
ALTER TABLE public.t_custom_spare_parts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "t_custom_spare_parts_tenant_isolation"
  ON public.t_custom_spare_parts FOR ALL
  USING (
    tenant_id::text = current_setting('request.jwt.claims', true)::json->>'tenant_id'
  );

-- t_custom_checkpoints
ALTER TABLE public.t_custom_checkpoints ENABLE ROW LEVEL SECURITY;

CREATE POLICY "t_custom_checkpoints_tenant_isolation"
  ON public.t_custom_checkpoints FOR ALL
  USING (
    tenant_id::text = current_setting('request.jwt.claims', true)::json->>'tenant_id'
  );

-- t_custom_checkpoint_values
ALTER TABLE public.t_custom_checkpoint_values ENABLE ROW LEVEL SECURITY;

CREATE POLICY "t_custom_checkpoint_values_tenant_isolation"
  ON public.t_custom_checkpoint_values FOR ALL
  USING (
    tenant_id::text = current_setting('request.jwt.claims', true)::json->>'tenant_id'
  );

-- t_cycle_overrides
ALTER TABLE public.t_cycle_overrides ENABLE ROW LEVEL SECURITY;

CREATE POLICY "t_cycle_overrides_tenant_isolation"
  ON public.t_cycle_overrides FOR ALL
  USING (
    tenant_id::text = current_setting('request.jwt.claims', true)::json->>'tenant_id'
  );
