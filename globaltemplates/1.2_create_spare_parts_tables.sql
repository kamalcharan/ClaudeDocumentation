-- =============================================================
-- R1 Task 1.2: Create m_equipment_spare_parts + m_spare_part_variant_map
-- Parts catalog grouped by component type.
-- Junction table maps which parts apply to which variants.
-- =============================================================

-- Spare parts catalog
CREATE TABLE IF NOT EXISTS public.m_equipment_spare_parts (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  resource_template_id  UUID NOT NULL REFERENCES public.m_catalog_resource_templates(id),
  component_group       VARCHAR(100) NOT NULL,
                          -- 'electrical', 'mechanical', 'refrigerant',
                          -- 'filters', 'water_side', 'controls', 'consumables'
  name                  VARCHAR(255) NOT NULL,
  description           TEXT,
  specifications        JSONB DEFAULT '{}',    -- SKU, typical lifespan, etc.
  source                VARCHAR(20) NOT NULL DEFAULT 'ai_researched',
  is_active             BOOLEAN NOT NULL DEFAULT true,
  sort_order            INTEGER DEFAULT 0,
  created_at            TIMESTAMPTZ DEFAULT now(),
  updated_at            TIMESTAMPTZ DEFAULT now()
);

COMMENT ON TABLE public.m_equipment_spare_parts IS 'Spare parts catalog grouped by component type. Populated by Knowledge Tree research.';

CREATE INDEX idx_spare_parts_resource ON public.m_equipment_spare_parts(resource_template_id, is_active);
CREATE INDEX idx_spare_parts_group ON public.m_equipment_spare_parts(component_group);

-- Junction: which parts apply to which variants (the toggle matrix)
CREATE TABLE IF NOT EXISTS public.m_spare_part_variant_map (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  spare_part_id UUID NOT NULL REFERENCES public.m_equipment_spare_parts(id) ON DELETE CASCADE,
  variant_id    UUID NOT NULL REFERENCES public.m_equipment_variants(id) ON DELETE CASCADE,
  is_recommended BOOLEAN NOT NULL DEFAULT true,
  notes         TEXT,
  created_at    TIMESTAMPTZ DEFAULT now(),

  UNIQUE(spare_part_id, variant_id)
);

COMMENT ON TABLE public.m_spare_part_variant_map IS 'Toggle matrix: which spare parts apply to which equipment variants.';

CREATE INDEX idx_spvm_variant ON public.m_spare_part_variant_map(variant_id);
CREATE INDEX idx_spvm_spare_part ON public.m_spare_part_variant_map(spare_part_id);
