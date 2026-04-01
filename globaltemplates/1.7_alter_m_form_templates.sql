-- =============================================================
-- R1 Task 1.7: ALTER m_form_templates
-- Add source, source_variant_id, service_activity columns.
-- m_form_templates exists (2 rows, uses gen_random_uuid()).
-- =============================================================

-- How this form was created
ALTER TABLE public.m_form_templates
  ADD COLUMN IF NOT EXISTS source VARCHAR(30) DEFAULT 'manual';
  -- 'manual' | 'knowledge_tree' | 'tenant_fork'

-- Which variant generated this form (NULL for manually created)
ALTER TABLE public.m_form_templates
  ADD COLUMN IF NOT EXISTS source_variant_id UUID REFERENCES public.m_equipment_variants(id);

-- Which service activity this form covers
ALTER TABLE public.m_form_templates
  ADD COLUMN IF NOT EXISTS service_activity VARCHAR(50);
  -- 'pm', 'repair', 'inspection', 'install', 'decommission'

-- Which resource template this form belongs to (for grouping)
ALTER TABLE public.m_form_templates
  ADD COLUMN IF NOT EXISTS resource_template_id UUID REFERENCES public.m_catalog_resource_templates(id);

COMMENT ON COLUMN public.m_form_templates.source IS 'manual = hand-built, knowledge_tree = auto-composed, tenant_fork = tenant customized copy';
COMMENT ON COLUMN public.m_form_templates.service_activity IS 'pm, repair, inspection, install, decommission';

CREATE INDEX IF NOT EXISTS idx_form_templates_source ON public.m_form_templates(source);
CREATE INDEX IF NOT EXISTS idx_form_templates_variant ON public.m_form_templates(source_variant_id);
CREATE INDEX IF NOT EXISTS idx_form_templates_activity ON public.m_form_templates(service_activity);
CREATE INDEX IF NOT EXISTS idx_form_templates_resource ON public.m_form_templates(resource_template_id);
