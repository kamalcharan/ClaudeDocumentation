-- =============================================================
-- R1 Task 1.9: Create tenant override tables
-- t_custom_variants, t_custom_spare_parts, t_custom_checkpoints,
-- t_custom_checkpoint_values, t_cycle_overrides
-- Merged with master data during form composition via UNION.
-- =============================================================

-- Tenant's own variants (beyond what VaNi researched)
CREATE TABLE IF NOT EXISTS public.t_custom_variants (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id             UUID NOT NULL,
  resource_template_id  UUID NOT NULL REFERENCES public.m_catalog_resource_templates(id),
  name                  VARCHAR(255) NOT NULL,
  description           TEXT,
  capacity_range        VARCHAR(100),
  attributes            JSONB DEFAULT '{}',
  is_active             BOOLEAN NOT NULL DEFAULT true,
  sort_order            INTEGER DEFAULT 0,
  created_at            TIMESTAMPTZ DEFAULT now(),
  updated_at            TIMESTAMPTZ DEFAULT now(),
  created_by            UUID
);

CREATE INDEX idx_t_custom_variants_tenant ON public.t_custom_variants(tenant_id, is_active);

-- Tenant's own spare parts
CREATE TABLE IF NOT EXISTS public.t_custom_spare_parts (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id             UUID NOT NULL,
  resource_template_id  UUID NOT NULL REFERENCES public.m_catalog_resource_templates(id),
  component_group       VARCHAR(100) NOT NULL,
  name                  VARCHAR(255) NOT NULL,
  description           TEXT,
  specifications        JSONB DEFAULT '{}',
  is_active             BOOLEAN NOT NULL DEFAULT true,
  sort_order            INTEGER DEFAULT 0,
  created_at            TIMESTAMPTZ DEFAULT now(),
  updated_at            TIMESTAMPTZ DEFAULT now(),
  created_by            UUID
);

CREATE INDEX idx_t_custom_spare_parts_tenant ON public.t_custom_spare_parts(tenant_id, is_active);

-- Tenant's own checkpoints
CREATE TABLE IF NOT EXISTS public.t_custom_checkpoints (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id             UUID NOT NULL,
  resource_template_id  UUID NOT NULL REFERENCES public.m_catalog_resource_templates(id),
  checkpoint_type       VARCHAR(20) NOT NULL,
  service_activity      VARCHAR(50) NOT NULL,
  section_name          VARCHAR(255) NOT NULL,
  name                  VARCHAR(255) NOT NULL,
  description           TEXT,
  layer                 VARCHAR(20) NOT NULL DEFAULT 'equipment',

  -- Reading-type fields
  unit                  VARCHAR(50),
  normal_min            NUMERIC,
  normal_max            NUMERIC,
  amber_threshold       NUMERIC,
  red_threshold         NUMERIC,
  threshold_note        TEXT,

  is_active             BOOLEAN NOT NULL DEFAULT true,
  sort_order            INTEGER DEFAULT 0,
  created_at            TIMESTAMPTZ DEFAULT now(),
  updated_at            TIMESTAMPTZ DEFAULT now(),
  created_by            UUID
);

CREATE INDEX idx_t_custom_checkpoints_tenant ON public.t_custom_checkpoints(tenant_id, is_active);

-- Tenant's own values for their custom condition checkpoints
CREATE TABLE IF NOT EXISTS public.t_custom_checkpoint_values (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id             UUID NOT NULL,
  checkpoint_id         UUID NOT NULL REFERENCES public.t_custom_checkpoints(id) ON DELETE CASCADE,
  label                 VARCHAR(255) NOT NULL,
  severity              VARCHAR(20) NOT NULL,
  triggers_part_consumption BOOLEAN NOT NULL DEFAULT false,
  requires_photo        BOOLEAN NOT NULL DEFAULT false,
  sort_order            INTEGER DEFAULT 0,
  created_at            TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_t_custom_cp_values_tenant ON public.t_custom_checkpoint_values(tenant_id);
CREATE INDEX idx_t_custom_cp_values_cp ON public.t_custom_checkpoint_values(checkpoint_id);

-- Tenant cycle overrides (adjust master cycle frequencies)
CREATE TABLE IF NOT EXISTS public.t_cycle_overrides (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id             UUID NOT NULL,
  cycle_id              UUID NOT NULL REFERENCES public.m_service_cycles(id),
  frequency_value       INTEGER NOT NULL,
  frequency_unit        VARCHAR(20) NOT NULL,
  alert_overdue_days    INTEGER,
  reason                TEXT,
  is_active             BOOLEAN NOT NULL DEFAULT true,
  created_at            TIMESTAMPTZ DEFAULT now(),
  updated_at            TIMESTAMPTZ DEFAULT now(),
  created_by            UUID,

  UNIQUE(tenant_id, cycle_id)
);

CREATE INDEX idx_t_cycle_overrides_tenant ON public.t_cycle_overrides(tenant_id, is_active);
