-- =============================================================
-- R1 Task 1.4: Create m_service_cycles + m_context_overlays
-- Frequency per checkpoint, with context-aware adjustments.
-- =============================================================

-- Service cycles: how often each checkpoint should be performed
CREATE TABLE IF NOT EXISTS public.m_service_cycles (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  checkpoint_id         UUID NOT NULL REFERENCES public.m_equipment_checkpoints(id) ON DELETE CASCADE,
  frequency_value       INTEGER NOT NULL,        -- e.g. 45, 90, 365, 1000
  frequency_unit        VARCHAR(20) NOT NULL,     -- 'days', 'hours', 'visits'
  varies_by             JSONB DEFAULT '[]',       -- ['climate', 'season', 'industry', 'equipment_age']
  alert_overdue_days    INTEGER,                  -- days after due date to trigger alert (NULL = no alert)
  source                VARCHAR(20) NOT NULL DEFAULT 'ai_researched',
  is_active             BOOLEAN NOT NULL DEFAULT true,
  created_at            TIMESTAMPTZ DEFAULT now(),
  updated_at            TIMESTAMPTZ DEFAULT now()
);

COMMENT ON TABLE public.m_service_cycles IS 'Default frequency per checkpoint with varies-by factors.';

CREATE INDEX idx_cycles_checkpoint ON public.m_service_cycles(checkpoint_id);

-- Context overlays: climate/geography/industry adjustments
CREATE TABLE IF NOT EXISTS public.m_context_overlays (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  resource_template_id  UUID NOT NULL REFERENCES public.m_catalog_resource_templates(id),
  context_type          VARCHAR(50) NOT NULL,
                          -- 'climate', 'geography', 'industry', 'industry_served'
  context_value         VARCHAR(255) NOT NULL,
                          -- e.g. 'hot_humid', 'coastal', 'pharma', 'healthcare'
  adjustments           JSONB NOT NULL DEFAULT '{}',
                          -- {
                          --   "cycle_multiplier": 0.5,        -- halve the cycle (more frequent)
                          --   "add_checkpoints": ["particulate_count"],
                          --   "threshold_adjustments": { "coil_cleaning": { "frequency_value": 60 } },
                          --   "notes": "Coastal salt air requires more frequent coil cleaning"
                          -- }
  priority              INTEGER DEFAULT 0,        -- higher = applied later (overrides lower)
  is_active             BOOLEAN NOT NULL DEFAULT true,
  created_at            TIMESTAMPTZ DEFAULT now(),
  updated_at            TIMESTAMPTZ DEFAULT now()
);

COMMENT ON TABLE public.m_context_overlays IS 'Climate/geography/industry adjustments to knowledge tree defaults.';

CREATE INDEX idx_overlays_resource ON public.m_context_overlays(resource_template_id, is_active);
CREATE INDEX idx_overlays_context ON public.m_context_overlays(context_type, context_value);
