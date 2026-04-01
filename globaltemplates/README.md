# R1: Knowledge Tree Data Model — Migration Files

## Execution Order

Apply these **in order** via the Supabase SQL Editor. Each file is independent but has FK dependencies on previous files.

| # | File | Tables | What it does |
|---|------|--------|-------------|
| 1.1 | `1.1_create_m_equipment_variants.sql` | m_equipment_variants | Equipment sub-types per resource template |
| 1.2 | `1.2_create_spare_parts_tables.sql` | m_equipment_spare_parts, m_spare_part_variant_map | Parts catalog + variant toggle matrix |
| 1.3 | `1.3_create_checkpoint_tables.sql` | m_equipment_checkpoints, m_checkpoint_values, m_checkpoint_variant_map | Service checkpoints (condition + reading) |
| 1.4 | `1.4_create_cycles_and_overlays.sql` | m_service_cycles, m_context_overlays | Frequency cycles + context adjustments |
| 1.5 | `1.5_create_t_equipment.sql` | t_equipment | Tenant equipment registry (NEW table) |
| 1.6 | `1.6_alter_m_cat_blocks.sql` | m_cat_blocks (ALTER) | Add form_template_id, knowledge_tree_ref |
| 1.7 | `1.7_alter_m_form_templates.sql` | m_form_templates (ALTER) | Add source, variant_id, service_activity, resource_template_id |
| 1.8 | `1.8_create_t_form_templates.sql` | t_form_templates | Tenant fork table for customized forms |
| 1.9 | `1.9_create_tenant_override_tables.sql` | 5 tables (t_custom_*) | Tenant overrides for variants, parts, checkpoints, values, cycles |
| 1.10 | `1.10_rls_policies.sql` | All new tables | RLS: authenticated read for m_, JWT tenant isolation for t_ |

## Total New Tables: 16

**Master (8):** m_equipment_variants, m_equipment_spare_parts, m_spare_part_variant_map, m_equipment_checkpoints, m_checkpoint_values, m_checkpoint_variant_map, m_service_cycles, m_context_overlays

**Tenant (8):** t_equipment, t_form_templates, t_custom_variants, t_custom_spare_parts, t_custom_checkpoints, t_custom_checkpoint_values, t_cycle_overrides

**Altered (2):** m_cat_blocks (+2 columns), m_form_templates (+4 columns)

## Verification Queries

Run after all 10 migrations to confirm everything is correct:

```sql
-- 1. Count new tables (should be 16)
SELECT count(*) as new_table_count
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name IN (
  'm_equipment_variants', 'm_equipment_spare_parts', 'm_spare_part_variant_map',
  'm_equipment_checkpoints', 'm_checkpoint_values', 'm_checkpoint_variant_map',
  'm_service_cycles', 'm_context_overlays',
  't_equipment', 't_form_templates',
  't_custom_variants', 't_custom_spare_parts', 't_custom_checkpoints',
  't_custom_checkpoint_values', 't_cycle_overrides'
);

-- 2. Verify new columns on m_cat_blocks
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'm_cat_blocks'
AND column_name IN ('form_template_id', 'knowledge_tree_ref');

-- 3. Verify new columns on m_form_templates
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'm_form_templates'
AND column_name IN ('source', 'source_variant_id', 'service_activity', 'resource_template_id');

-- 4. Verify RLS is enabled on all new tables
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
AND tablename IN (
  'm_equipment_variants', 'm_equipment_spare_parts', 'm_spare_part_variant_map',
  'm_equipment_checkpoints', 'm_checkpoint_values', 'm_checkpoint_variant_map',
  'm_service_cycles', 'm_context_overlays',
  't_equipment', 't_form_templates',
  't_custom_variants', 't_custom_spare_parts', 't_custom_checkpoints',
  't_custom_checkpoint_values', 't_cycle_overrides'
)
ORDER BY tablename;

-- 5. Count RLS policies (should be 23: 16 read/service_role on m_ tables + 7 tenant isolation on t_ tables + 2 admin on t_equipment/t_form_templates)
SELECT count(*) as policy_count
FROM pg_policies
WHERE schemaname = 'public'
AND tablename IN (
  'm_equipment_variants', 'm_equipment_spare_parts', 'm_spare_part_variant_map',
  'm_equipment_checkpoints', 'm_checkpoint_values', 'm_checkpoint_variant_map',
  'm_service_cycles', 'm_context_overlays',
  't_equipment', 't_form_templates',
  't_custom_variants', 't_custom_spare_parts', 't_custom_checkpoints',
  't_custom_checkpoint_values', 't_cycle_overrides'
);

-- 6. Verify FK chain: variant → resource_template
SELECT tc.constraint_name, tc.table_name, kcu.column_name, ccu.table_name AS foreign_table
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage ccu ON tc.constraint_name = ccu.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
AND tc.table_name = 'm_equipment_variants';
```

## Conventions Used (matching live DB)

- **UUID PK**: `gen_random_uuid()` (matching m_form_templates pattern)
- **Timestamps**: `TIMESTAMPTZ DEFAULT now()`
- **Soft delete**: `is_active BOOLEAN NOT NULL DEFAULT true`
- **RLS m_ tables**: `authenticated` SELECT where `is_active = true`, `service_role` full
- **RLS t_ tables**: `tenant_id::text = current_setting('request.jwt.claims', true)::json->>'tenant_id'`
- **t_ prefix**: tenant-owned data (custom variants, equipment, cycle overrides)
