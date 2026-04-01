-- =============================================================
-- R1 Task 1.8: Create t_form_templates (tenant fork table)
-- Same schema as m_form_templates + tenant_id, copied_from_id,
-- is_forked. Created when tenant clicks "Customize".
-- Master updates do NOT flow to forked copies.
-- =============================================================

CREATE TABLE IF NOT EXISTS public.t_form_templates (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id             UUID NOT NULL,

  -- Fork reference
  copied_from_id        UUID REFERENCES public.m_form_templates(id),
  is_forked             BOOLEAN NOT NULL DEFAULT true,

  -- Same columns as m_form_templates
  name                  VARCHAR(255) NOT NULL,
  description           TEXT,
  category              VARCHAR(100) NOT NULL,
  form_type             VARCHAR(50) NOT NULL,
  tags                  TEXT[] DEFAULT '{}',
  schema                JSONB NOT NULL,
  version               INT NOT NULL DEFAULT 1,
  parent_template_id    UUID REFERENCES public.t_form_templates(id),
  status                VARCHAR(20) NOT NULL DEFAULT 'draft',
  thumbnail_url         TEXT,

  -- Knowledge tree columns (same as m_form_templates additions)
  source                VARCHAR(30) DEFAULT 'tenant_fork',
  source_variant_id     UUID REFERENCES public.m_equipment_variants(id),
  service_activity      VARCHAR(50),
  resource_template_id  UUID REFERENCES public.m_catalog_resource_templates(id),

  -- Audit
  created_by            UUID NOT NULL,
  approved_by           UUID,
  approved_at           TIMESTAMPTZ,
  review_notes          TEXT,
  created_at            TIMESTAMPTZ DEFAULT now(),
  updated_at            TIMESTAMPTZ DEFAULT now()
);

COMMENT ON TABLE public.t_form_templates IS 'Tenant-forked form templates. Created when tenant customizes a master form.';

CREATE INDEX idx_t_form_templates_tenant ON public.t_form_templates(tenant_id);
CREATE INDEX idx_t_form_templates_copied ON public.t_form_templates(copied_from_id);
CREATE INDEX idx_t_form_templates_variant ON public.t_form_templates(source_variant_id);
CREATE INDEX idx_t_form_templates_activity ON public.t_form_templates(service_activity);
