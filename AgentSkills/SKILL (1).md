---
name: contractnest-master-data-agent
description: >
  Seeds industry-specific master data for ContractNest tenants during onboarding. Use this skill
  whenever a tenant selects their industry/target industries and needs pre-populated service categories,
  SLA templates, equipment types, compliance checklists, pricing models, contract terms, and resource
  templates. Also use when adding a new industry vertical to an existing tenant, resetting seed data,
  or generating sample catalog items for demo environments. Triggers on: tenant onboarding, industry
  setup, seed data generation, master data population, catalog seeding, demo data creation,
  ContractNest setup, or any mention of populating a new tenant workspace with domain-specific data.
  Also triggers when adding new resource templates to master data, classifying items as universal vs
  cross-industry vs industry-specific, or linking templates to multiple industries via the junction table.
---

# ContractNest Master Data Agent

## Purpose

This agent is the **foundation layer** (Skill #1) in the ContractNest 5-skill AI pipeline:

```
1. MASTER DATA AGENT (this skill) → Seeds domain data
2. Contract Template Skill         → Generates templates from seed data
3. VaNi Contract Agent             → Operates on live tenant data
4. VaNi Marketing Agent            → Demos with real industry data
5. GeM Marketplace Skill           → Government marketplace integration
```

When a tenant onboards and selects their industry + target industries, this agent:
- Seeds **service categories & sub-categories** into tenant tables
- Creates **SLA templates** (response/resolution times, uptime %)
- Populates **equipment/asset type** definitions with specs
- Sets up **compliance checklists** & regulatory requirements
- Configures **standard pricing models** & rate cards
- Inserts **common contract terms & clauses** (nomenclature-specific)
- Generates **resource templates** using the **normalized junction table architecture**
- Prepares **catalog items** for the service catalog

## How It Works

### Step 1: Read References

Before generating any data, ALWAYS read:
1. `references/schema-reference.md` — Full database schema with table relationships
2. `references/industry-seed-patterns.md` — Industry-specific seed data patterns
3. `references/api-spec.md` — Supabase integration patterns & SQL templates

### Step 2: Identify Tenant Context

Gather from the user or from the database:
- **tenant_id** (UUID) — The tenant being seeded
- **Tenant's own industry** — What the tenant does (e.g., "facility_management")
- **Target industries served** — Who the tenant's customers are (e.g., "healthcare", "real_estate")
- **Contract nomenclatures used** — AMC, CMC, FMC, etc.
- **Onboarding stage** — Fresh setup vs. adding new industry

### Step 3: Generate Seed Data

The agent generates INSERT statements for these tables **in dependency order**:

#### Layer 1: Categories (Foundation)
| Table | Purpose | Source |
|-------|---------|--------|
| `t_category_master` | Category groups | `m_category_master` |
| `t_category_details` | Sub-categories per group | `m_category_details` + industry-specific |
| `t_category_resources_master` | Resource definitions per tenant | **`v_resource_templates_by_industry`** |

#### Layer 2: Catalog (Service Definitions)
| Table | Purpose | Source |
|-------|---------|--------|
| `t_catalog_industries` | Tenant's served industries | `m_catalog_industries` filtered |
| `t_catalog_categories` | Service categories for each industry | `m_catalog_categories` filtered |
| `t_catalog_items` | Actual service items with pricing | Generated from patterns |
| `t_catalog_resources` | Resources (staff, equipment) | From `v_resource_templates_by_industry` |
| `t_catalog_resource_pricing` | Resource rate cards | Industry pricing guidance |
| `t_catalog_service_resources` | Service ↔ resource mappings | Generated |

#### Layer 3: Contract Infrastructure
| Table | Purpose | Source |
|-------|---------|--------|
| `cat_blocks` | Reusable contract blocks | Generated per nomenclature |
| `cat_templates` | Contract templates | Assembled from blocks |
| `m_event_status_config` | Status workflows per event type | System defaults |
| `m_event_status_transitions` | Allowed status transitions | System defaults |

#### Layer 4: Assets & Compliance
| Table | Purpose | Source |
|-------|---------|--------|
| `t_tenant_served_industries` | Industry selections | User input |
| `t_tenant_industry_segments` | Sub-segment selections | User input |
| `t_client_asset_registry` | Sample asset types | Industry patterns |

### Step 4: Execute or Output

Two modes:
1. **Claude Skill Mode** — Generate SQL and execute via Supabase tools
2. **Edge Function Mode** — See `scripts/seed-edge-function.ts` for automated onboarding

## Critical Rules

### Resource Template Architecture (Updated Feb 2026)

Resource templates use a **normalized many-to-many architecture** with scope classification:

```
m_catalog_resource_templates (239 active templates)
  ├── scope: 'universal' (19)    → Auto-included for ALL industries via view
  ├── scope: 'cross_industry' (6) → Linked to multiple industries via junction
  └── scope: 'industry_specific' (214) → Linked to one industry via junction

m_catalog_resource_template_industries (296 junction rows)
  ├── template_id  → FK to resource_templates
  ├── industry_id  → FK to industries
  ├── is_primary   → true if template's "home" industry
  ├── relevance_score → 1-100
  └── industry_specific_attributes → JSONB overrides

v_resource_templates_by_industry (convenience view)
  → UNION of junction-linked + universal items (auto CROSS JOIN)
  → Query: WHERE linked_industry_id = 'healthcare' → returns 39 items
```

**ALWAYS use the view when seeding tenant resources:**
```sql
SELECT * FROM v_resource_templates_by_industry 
WHERE linked_industry_id = ANY($1::varchar[])
ORDER BY relevance_score DESC;
```

**When adding NEW master templates:**
1. Determine scope: universal / cross_industry / industry_specific
2. INSERT into `m_catalog_resource_templates` with scope, industry_id nullable
3. For cross_industry/industry_specific: INSERT junction rows
4. For universal: No junction rows needed (auto-included via view)

### Data Integrity
- Use `gen_random_uuid()` for IDs — never hardcode UUIDs
- Always set `tenant_id` on tenant-scoped records
- Set `is_live = true` and `is_active = true` for seed records
- Set `is_seed = true` on `cat_blocks`
- Prefix convention: `m_` (system) / `t_` (tenant) / `c_` (config) / `cat_` (contract catalog)

### Industry Mapping
- `m_catalog_industries` — 27 top-level + 48 sub-segments
- `m_catalog_categories` — 385 service categories
- `m_catalog_category_industry_map` — 507 cross-industry links
- **`v_resource_templates_by_industry`** — resource templates (use this, NOT the raw table)

### Nomenclature Awareness
Contracts use nomenclatures (AMC, CMC, FMC, etc.) from `m_category_details` under `cat_contract_nomenclature`. Each implies different block structures, pricing models, event types, and SLA requirements. See `references/industry-seed-patterns.md` for nomenclature → block mappings.

### Idempotency
- Check for existing data before inserting
- Use `ON CONFLICT DO NOTHING` where possible
- Never duplicate categories or resources

## Testing

After seeding, verify:
```sql
SELECT cm.category_name, COUNT(cd.id) as detail_count
FROM t_category_master cm
LEFT JOIN t_category_details cd ON cd.category_id = cm.id
WHERE cm.tenant_id = $tenant_id GROUP BY cm.category_name;

SELECT resource_type_id, count(*) FROM t_category_resources_master 
WHERE tenant_id = $tenant_id GROUP BY resource_type_id;

SELECT block_type_id, COUNT(*) FROM cat_blocks 
WHERE tenant_id = $tenant_id GROUP BY block_type_id;
```