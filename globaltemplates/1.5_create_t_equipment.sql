-- =============================================================
-- R1 Task 1.5: CREATE t_equipment (tenant equipment registry)
-- This table does not exist yet. The PRD said ALTER, but the
-- live DB confirmed it needs to be created.
-- Tenant-scoped: each row belongs to a tenant.
-- =============================================================

CREATE TABLE IF NOT EXISTS public.t_equipment (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id             UUID NOT NULL,

  -- Equipment identity
  name                  VARCHAR(255) NOT NULL,
  asset_tag             VARCHAR(100),            -- tenant's internal asset ID
  serial_number         VARCHAR(255),
  make                  VARCHAR(255),            -- brand / manufacturer
  model                 VARCHAR(255),

  -- Knowledge Tree link
  resource_template_id  UUID REFERENCES public.m_catalog_resource_templates(id),
  variant_id            UUID REFERENCES public.m_equipment_variants(id),
  capacity_value        NUMERIC,                 -- e.g. 2.5
  capacity_unit         VARCHAR(50),             -- e.g. 'TR', 'kW', 'HP'

  -- Location
  location_description  TEXT,                    -- e.g. 'Building A, Floor 3, Server Room'
  floor                 VARCHAR(50),
  zone                  VARCHAR(100),

  -- Dates
  installation_date     DATE,
  warranty_expiry       DATE,

  -- Status
  status                VARCHAR(20) NOT NULL DEFAULT 'active',
                          -- 'active', 'inactive', 'decommissioned'
  is_active             BOOLEAN NOT NULL DEFAULT true,

  -- Metadata
  attributes            JSONB DEFAULT '{}',      -- flexible per-tenant metadata
  created_at            TIMESTAMPTZ DEFAULT now(),
  updated_at            TIMESTAMPTZ DEFAULT now(),
  created_by            UUID,
  updated_by            UUID
);

COMMENT ON TABLE public.t_equipment IS 'Tenant equipment/asset registry. Linked to knowledge tree via variant_id.';

CREATE INDEX idx_t_equipment_tenant ON public.t_equipment(tenant_id, is_active);
CREATE INDEX idx_t_equipment_variant ON public.t_equipment(variant_id);
CREATE INDEX idx_t_equipment_resource ON public.t_equipment(resource_template_id);
CREATE INDEX idx_t_equipment_asset_tag ON public.t_equipment(tenant_id, asset_tag);
