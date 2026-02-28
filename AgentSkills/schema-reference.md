# ContractNest Database Schema Reference

## Table of Contents
1. [Naming Conventions](#naming-conventions)
2. [System Master Tables (m_*)](#system-master-tables)
3. [Tenant Tables (t_*)](#tenant-tables)
4. [Contract & Catalog Tables (cat_*)](#contract-catalog-tables)
5. [Notification & Workflow Tables (n_*)](#notification-workflow-tables)
6. [Relationships & Data Flow](#relationships)
7. [Key Enumerations](#enumerations)

---

## Naming Conventions

| Prefix | Scope | Write Permission | Examples |
|--------|-------|-----------------|----------|
| `m_` | System-wide master data | Platform admin only* | `m_category_master`, `m_catalog_industries` |
| `t_` | Tenant-scoped data | Tenant users | `t_category_master`, `t_catalog_items` |
| `c_` | Configuration/settings | Admin | `c_category_master`, `c_category_details` |
| `cat_` | Contract catalog (blocks/templates) | Tenant users | `cat_blocks`, `cat_templates` |
| `n_` | Notifications, JTD, workflows | System + tenant | `n_jtd`, `n_jtd_statuses` |

*Exception: `m_event_status_config` and `m_event_status_transitions` have `tenant_id` and are tenant-scoped despite the `m_` prefix.

---

## System Master Tables

### m_category_master (20 rows)
Platform-wide category groups. Tenants get copies in `t_category_master`.

| Column | Type | Key | Description |
|--------|------|-----|-------------|
| id | uuid | PK | `uuid_generate_v4()` |
| category_name | varchar | UNIQUE | Internal name: `cat_block_type`, `cat_contract_nomenclature`, `cat_asset_types` etc. |
| display_name | varchar | | Human label: "Block Types", "Contract Nomenclature" |
| icon_name | varchar | | Lucide icon name |
| sequence_no | integer | | Display order |
| is_active | boolean | | Default true |

**Key categories:**
- `cat_block_type` → Service, Spare, Billing, Text, Video, Image, Checklist, Document
- `cat_contract_nomenclature` → AMC, CMC, CAMC, FMC, O&M, Manpower, SLA, etc. (21 types)
- `cat_asset_types` → Residential (1-4BHK, Villa, Penthouse), Commercial, AC types, Vehicles, IT
- `cat_pricing_mode` → Independent, Resource Based, Variant Based, Multi Resource
- `cat_price_type` → Per Session, Per Hour, Per Day, Per Unit, Fixed
- `cat_block_status`, `cat_template_status`, `cat_evidence_type`, `cat_location_type`, `cat_currency`, `cat_payment_type`
- `service_categories`, `service_statuses`, `billing_frequencies`, `tax_applicability`
- `resource_allocation_types`, `resource_pricing_models`, `resource_types`

### m_category_details (111 rows)
Sub-categories within each master category.

| Column | Type | Key | Description |
|--------|------|-----|-------------|
| id | uuid | PK | |
| category_id | uuid | FK → m_category_master | Parent category |
| sub_cat_name | varchar | | Internal name: `amc`, `cmc`, `per_hour` |
| display_name | varchar | | Human label: "AMC", "Per Hour" |
| description | text | | Tooltip/help text |
| tags | jsonb | | `["equipment", "maintenance", "annual"]` |
| hexcolor | varchar | | Display color |
| icon_name | varchar | | Lucide icon |
| sequence_no | integer | | Display order |
| form_settings | jsonb | | Custom form fields for this sub-category |
| is_deletable | boolean | | Whether tenant can remove |
| requires_human | boolean | | For resource types |

### m_catalog_industries (75 rows)
Hierarchical industry taxonomy. Top-level (level=0) + sub-segments (level=1).

| Column | Type | Key | Description |
|--------|------|-----|-------------|
| id | varchar | PK | Slug: `healthcare`, `facility_management` |
| name | varchar | | Display name: "Healthcare" |
| parent_id | varchar | FK → self | Null for top-level |
| level | integer | | 0 = segment, 1 = sub_segment |
| segment_type | varchar | | `segment` or `sub_segment` |
| icon | varchar | | Lucide icon |
| common_pricing_rules | jsonb | | Industry-standard pricing patterns |
| compliance_requirements | jsonb | | Regulatory requirements |

**Top-level industries (27):** healthcare, wellness, manufacturing, facility_management, technology, education, financial_services, hospitality, retail, automotive, real_estate, telecommunications, logistics, government, nonprofit, agriculture, legal_professional, professional_services, arts_media, energy, spiritual_religious, media, home_services, construction, pharma, aerospace, other

### m_catalog_categories (385 rows)
Service categories mapped to industries.

| Column | Type | Key | Description |
|--------|------|-----|-------------|
| id | varchar | PK | Slug: `medical_equipment_amc` |
| industry_id | varchar | FK → m_catalog_industries | Primary industry |
| name | varchar | | "Medical Equipment AMC" |
| icon | varchar | | Lucide icon |
| default_pricing_model | varchar | | `subscription`, `per_session`, `per_unit`, etc. |
| suggested_duration | integer | | Minutes (e.g., 60 for consultations) |
| common_variants | jsonb | | `["Comprehensive", "Preventive", "Breakdown"]` |
| pricing_rule_templates | jsonb | | Suggested pricing rules |

### m_catalog_category_industry_map (507 rows)
Cross-industry sharing — one category can appear in multiple industries.

| Column | Type | Key | Description |
|--------|------|-----|-------------|
| category_id | varchar | PK, FK → m_catalog_categories | |
| industry_id | varchar | PK, FK → m_catalog_industries | |
| is_primary | boolean | | True if this is the category's home industry |
| display_name | varchar | | Override display name for this industry context |
| display_order | integer | | Sort within this industry |
| customizations | jsonb | | Industry-specific overrides |

### m_catalog_resource_templates (239 active rows)
Resource blueprints. **Normalized with scope classification** — items can belong to multiple industries.

| Column | Type | Key | Description |
|--------|------|-----|-------------|
| id | uuid | PK | |
| industry_id | varchar | FK, **NULLABLE** | Legacy single-industry link (kept for backward compat) |
| resource_type_id | varchar | FK → m_catalog_resource_types | `team_staff`, `equipment`, `consumable`, `asset`, `partner` |
| name | varchar | | "Registered Nurse", "CT Scanner", "Fire Extinguisher" |
| description | text | | |
| sub_category | varchar | | "Diagnostic Imaging", "Fire & Safety", "IT & Computing" |
| default_attributes | jsonb | | `{"certifications": [...], "types": [...]}` |
| pricing_guidance | jsonb | | `{"suggested_hourly_rate": 75, "market_range": {...}}` |
| popularity_score | integer | | 1-100 for sorting |
| is_recommended | boolean | | Show as suggested |
| is_active | boolean | | Soft delete |
| sort_order | integer | | Display ordering |
| **scope** | **varchar(20)** | | **`universal` / `cross_industry` / `industry_specific`** |

**Scope classification:**
- `universal` (19 items) — Every industry needs: Fire Extinguisher, AC, Laptop, CCTV, Security Guard, Housekeeping, Electrician, Plumber, Cleaning Supplies, etc.
- `cross_industry` (6 items) — Multiple industries: Elevator/Lift, HVAC System, DG Set, UPS System, Transformer, STP/WTP
- `industry_specific` (214 items) — Unique to one industry: MRI Scanner (healthcare), Tower Crane (construction), Tractor (agriculture)

### m_catalog_resource_template_industries (296 rows) — NEW
Many-to-many junction linking templates to industries. Eliminates duplication.

| Column | Type | Key | Description |
|--------|------|-----|-------------|
| template_id | uuid | PK, FK → m_catalog_resource_templates | |
| industry_id | varchar | PK, FK → m_catalog_industries | |
| is_primary | boolean | | True = template's "home" industry |
| relevance_score | integer | | 1-100 (how relevant to this industry) |
| industry_specific_attributes | jsonb | | Per-industry overrides (e.g., `{"variant": "Data Center UPS"}`) |
| created_at | timestamptz | | |

**Indexes:** idx_rti_industry, idx_rti_template, idx_rti_primary

### v_resource_templates_by_industry (VIEW) — NEW
Convenience view. **Use this for all resource template queries.**

```sql
-- Returns all templates for an industry:
-- 1. Explicitly linked (cross_industry + industry_specific) via junction
-- 2. Universal items via CROSS JOIN (auto-included)
SELECT * FROM v_resource_templates_by_industry WHERE linked_industry_id = 'healthcare';
-- Returns ~39 rows for healthcare (14 specific + 6 cross-industry + 19 universal)
```

| Column | Source | Description |
|--------|--------|-------------|
| id, name, description, resource_type_id, sub_category | resource_templates | Template data |
| scope | resource_templates | universal/cross_industry/industry_specific |
| linked_industry_id | junction or CROSS JOIN | The industry this row applies to |
| is_primary | junction | Is this the template's home industry? |
| relevance_score | junction | Relevance ranking |
| industry_specific_attributes | junction | Per-industry overrides |

### m_catalog_resource_types (5 rows)
| id (varchar) | name | pricing_model | requires_human | has_capacity |
|------|------|---------------|----------------|--------------|
| team_staff | Team Member | hourly | true | true |
| equipment | Equipments | hourly | false | true |
| consumable | Consumables | per_unit | false | false |
| asset | Entities | hourly | false | true |
| partner | Partners | fixed | true | false |

### m_catalog_pricing_templates (0 rows — to be seeded)
Pricing rule templates per industry/category.

| Column | Type | Description |
|--------|------|-------------|
| id | uuid | PK |
| industry_id | varchar | FK |
| category_id | varchar | FK |
| template_name | varchar | |
| rule_type | varchar | |
| condition_config | jsonb | |
| action_config | jsonb | |
| is_recommended | boolean | |

---

## Tenant Tables

### t_tenants
| Column | Type | Description |
|--------|------|-------------|
| id | uuid | PK |
| name | varchar | Tenant name |
| workspace_code | varchar | URL slug |
| status | varchar | `active`, `setup`, etc. |
| is_test | boolean | Demo/test tenant |
| settings | jsonb | Tenant-level config |

### t_tenant_profiles
| Column | Type | Description |
|--------|------|-------------|
| id | uuid | PK |
| tenant_id | uuid | FK |
| profile_type | varchar | Profile variant |
| business_name | varchar | |
| industry_id | varchar | FK → m_catalog_industries |
| business_type_id | varchar | |

### t_tenant_served_industries (20 rows)
Which industries a tenant serves (their customers' industries).

| Column | Type | Description |
|--------|------|-------------|
| id | uuid | PK |
| tenant_id | uuid | FK |
| industry_id | varchar | FK → m_catalog_industries |
| added_by | uuid | User who added |

### t_tenant_industry_segments (0 rows)
Sub-segments within served industries.

### t_category_master (101 rows)
Tenant's copy of category groups. Mirrors `m_category_master` structure + `tenant_id` + `is_live`.

### t_category_details (201 rows)
Tenant's copy of sub-categories. Mirrors `m_category_details` + `tenant_id` + `is_live`.

### t_category_resources_master (78 rows)
Tenant's resource definitions. **Seeded from `v_resource_templates_by_industry`.**

| Column | Type | Description |
|--------|------|-------------|
| id | uuid | PK |
| tenant_id | uuid | FK |
| resource_type_id | varchar | FK → m_catalog_resource_types |
| name | varchar | |
| display_name | varchar | |
| description | text | |
| sub_category | varchar | |
| tags | jsonb | Includes `{"source": "seed", "default_attributes": {...}}` |
| is_active | boolean | |
| is_live | boolean | |

### t_catalog_industries, t_catalog_categories, t_catalog_items
Tenant-scoped copies of master catalog data. See api-spec.md for seeding templates.

### t_catalog_resources
Tenant's actual resource instances.

| Column | Type | Description |
|--------|------|-------------|
| id | uuid | PK |
| tenant_id | uuid | FK |
| resource_type_id | varchar | FK |
| name | varchar | |
| capacity_per_day / per_hour | integer | |
| working_hours | jsonb | |
| skills | jsonb | |
| hourly_cost / daily_cost | numeric | |

### t_client_asset_registry (10 rows)
Client-owned assets under contracts.

| Column | Type | Description |
|--------|------|-------------|
| id | uuid | PK |
| tenant_id | uuid | FK |
| owner_contact_id | uuid | FK → t_contacts |
| resource_type_id | varchar | FK |
| asset_type_id | uuid | FK → t_category_details |
| name | varchar | |
| code | varchar | Asset code |
| status | varchar | `active`, `inactive`, `decommissioned` |
| make / model / serial_number | varchar | |
| specifications | jsonb | |

---

## Contract & Catalog Tables

### cat_blocks (28 rows)
Reusable contract building blocks.

| Column | Type | Description |
|--------|------|-------------|
| id | uuid | PK |
| tenant_id | uuid | FK |
| block_type_id | uuid | FK → m_category_details (cat_block_type) |
| name | varchar | |
| category | varchar | Block category grouping |
| config | jsonb | Block-specific configuration |
| pricing_mode_id | uuid | FK → m_category_details (cat_pricing_mode) |
| base_price | numeric | |
| price_type_id | uuid | FK → m_category_details (cat_price_type) |
| tax_rate | numeric | Default 18% |
| is_seed | boolean | `true` = system-generated |
| is_live | boolean | Published |

### cat_templates (1 row)
Contract templates assembled from blocks.

### t_contracts (86 rows)
Live contracts with nomenclature, buyer/seller, status, duration, computed events.

### t_contract_blocks (125 rows)
Blocks within a specific contract.

---

## Notification & Workflow Tables

### m_event_status_config (1976 rows)
Status definitions per event type. **Tenant-scoped** despite `m_` prefix.

### m_event_status_transitions (2888 rows)
Allowed transitions between statuses. Also tenant-scoped.

---

## Relationships

```
m_catalog_industries (27 top-level + 48 sub-segments)
  └─→ m_catalog_categories (385 categories)
       └─→ m_catalog_category_industry_map (507 cross-industry links)
  └─→ m_catalog_resource_templates (239 active, scope-classified)
       └─→ m_catalog_resource_template_industries (296 junction rows)
       └─→ v_resource_templates_by_industry (convenience view)
  
  Onboarding copies to:
  
  t_tenant_served_industries (tenant selections)
  t_catalog_industries (tenant copy)
    └─→ t_catalog_categories (tenant copy)
         └─→ t_catalog_items (actual services)
              └─→ t_catalog_service_resources (resource needs)
         └─→ t_catalog_resources (actual resources)
              └─→ t_catalog_resource_pricing (rate cards)

m_category_master → t_category_master (tenant copy)
m_category_details → t_category_details (tenant copy)

cat_blocks (reusable blocks) → cat_templates (assembled templates)
  → t_contracts → t_contract_blocks
```

---

## Enumerations

### Contract Nomenclatures (21 types)
| Code | Name | Tags | Typical Industries |
|------|------|------|-------------------|
| amc | AMC | equipment, maintenance, annual | Healthcare, Manufacturing, IT |
| cmc | CMC | comprehensive, maintenance | Healthcare, Manufacturing |
| camc | CAMC | comprehensive, annual, government | Government, PSU |
| fmc | FMC | facility, management | Real Estate, Commercial |
| om | O&M | operations, infrastructure | Energy, Infrastructure |
| manpower | Manpower | staffing, labor | All |
| sla | SLA | performance, uptime | Technology, Telecom |
| (and 14 more — see industry-seed-patterns.md for full list) |

### Resource Types (5)
team_staff, equipment, consumable, asset, partner

### Resource Template Scopes (3)
universal (19), cross_industry (6), industry_specific (214)