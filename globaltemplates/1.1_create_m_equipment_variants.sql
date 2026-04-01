-- =============================================================
-- R1 Task 1.1: Create m_equipment_variants
-- Sub-types per equipment category (Split AC, VRF, Chiller, etc.)
-- Linked to m_catalog_resource_templates (240 rows)
-- =============================================================

CREATE TABLE IF NOT EXISTS public.m_equipment_variants (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  resource_template_id  UUID NOT NULL REFERENCES public.m_catalog_resource_templates(id),
  name                  VARCHAR(255) NOT NULL,
  description           TEXT,
  capacity_range        VARCHAR(100),          -- e.g. '0.75–2.5 TR'
  attributes            JSONB DEFAULT '{}',    -- variant-specific metadata
  is_active             BOOLEAN NOT NULL DEFAULT true,
  sort_order            INTEGER DEFAULT 0,
  source                VARCHAR(20) NOT NULL DEFAULT 'ai_researched',
                          -- 'ai_researched' | 'user_contributed'
  created_at            TIMESTAMPTZ DEFAULT now(),
  updated_at            TIMESTAMPTZ DEFAULT now()
);

COMMENT ON TABLE public.m_equipment_variants IS 'Equipment sub-types per resource template. Populated by Knowledge Tree research.';
COMMENT ON COLUMN public.m_equipment_variants.source IS 'ai_researched = VaNi generated, user_contributed = admin added manually';

CREATE INDEX idx_equipment_variants_resource ON public.m_equipment_variants(resource_template_id, is_active);
CREATE INDEX idx_equipment_variants_active ON public.m_equipment_variants(is_active, sort_order);
