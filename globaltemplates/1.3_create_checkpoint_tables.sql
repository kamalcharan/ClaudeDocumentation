-- =============================================================
-- R1 Task 1.3: Create m_equipment_checkpoints + m_checkpoint_values
--              + m_checkpoint_variant_map
-- What to check during service. Two types:
--   CONDITION = qualitative (dropdown with severity)
--   READING   = quantitative (number with unit + thresholds)
-- =============================================================

-- Checkpoints master
CREATE TABLE IF NOT EXISTS public.m_equipment_checkpoints (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  resource_template_id  UUID NOT NULL REFERENCES public.m_catalog_resource_templates(id),
  checkpoint_type       VARCHAR(20) NOT NULL,
                          -- 'condition' | 'reading'
  service_activity      VARCHAR(50) NOT NULL,
                          -- 'pm', 'repair', 'inspection', 'install', 'decommission'
  section_name          VARCHAR(255) NOT NULL,
                          -- Groups into form sections (e.g. 'Filter & Coils', 'Electrical')
  name                  VARCHAR(255) NOT NULL,
  description           TEXT,
  layer                 VARCHAR(20) NOT NULL DEFAULT 'equipment',
                          -- 'base' (all equipment types) | 'equipment' (variant-specific)

  -- Reading-type fields (NULL for condition-type)
  unit                  VARCHAR(50),           -- 'PSI', '°C', 'Amps', 'V', 'Pa', 'pH'
  normal_min            NUMERIC,
  normal_max            NUMERIC,
  amber_threshold       NUMERIC,               -- warning level
  red_threshold         NUMERIC,               -- critical level
  threshold_note        TEXT,                   -- e.g. 'Compare with nameplate'

  source                VARCHAR(20) NOT NULL DEFAULT 'ai_researched',
  is_active             BOOLEAN NOT NULL DEFAULT true,
  sort_order            INTEGER DEFAULT 0,
  created_at            TIMESTAMPTZ DEFAULT now(),
  updated_at            TIMESTAMPTZ DEFAULT now()
);

COMMENT ON TABLE public.m_equipment_checkpoints IS 'Service checkpoints. condition = qualitative dropdown, reading = quantitative with thresholds.';

CREATE INDEX idx_checkpoints_resource ON public.m_equipment_checkpoints(resource_template_id, is_active);
CREATE INDEX idx_checkpoints_activity ON public.m_equipment_checkpoints(service_activity);
CREATE INDEX idx_checkpoints_section ON public.m_equipment_checkpoints(section_name);

-- Valid values for condition-type checkpoints
CREATE TABLE IF NOT EXISTS public.m_checkpoint_values (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  checkpoint_id         UUID NOT NULL REFERENCES public.m_equipment_checkpoints(id) ON DELETE CASCADE,
  label                 VARCHAR(255) NOT NULL,   -- e.g. 'Clean', 'Dusty — cleaned'
  severity              VARCHAR(20) NOT NULL,     -- 'ok', 'attention', 'critical'
  triggers_part_consumption BOOLEAN NOT NULL DEFAULT false,
  requires_photo        BOOLEAN NOT NULL DEFAULT false,
  sort_order            INTEGER DEFAULT 0,
  created_at            TIMESTAMPTZ DEFAULT now()
);

COMMENT ON TABLE public.m_checkpoint_values IS 'Valid dropdown values for condition-type checkpoints with severity levels.';

CREATE INDEX idx_checkpoint_values_checkpoint ON public.m_checkpoint_values(checkpoint_id);

-- Which checkpoints apply to which variants
CREATE TABLE IF NOT EXISTS public.m_checkpoint_variant_map (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  checkpoint_id         UUID NOT NULL REFERENCES public.m_equipment_checkpoints(id) ON DELETE CASCADE,
  variant_id            UUID NOT NULL REFERENCES public.m_equipment_variants(id) ON DELETE CASCADE,
  override_min          NUMERIC,               -- variant-specific threshold override
  override_max          NUMERIC,
  override_amber        NUMERIC,
  override_red          NUMERIC,
  created_at            TIMESTAMPTZ DEFAULT now(),

  UNIQUE(checkpoint_id, variant_id)
);

COMMENT ON TABLE public.m_checkpoint_variant_map IS 'Maps checkpoints to variants with optional threshold overrides.';

CREATE INDEX idx_cvm_variant ON public.m_checkpoint_variant_map(variant_id);
CREATE INDEX idx_cvm_checkpoint ON public.m_checkpoint_variant_map(checkpoint_id);
