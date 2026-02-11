# ContractNest: Session Handover Document

**Date**: 2026-02-11
**Purpose**: Complete context transfer for new Claude Code session
**What Happened**: Full business domain audit → architecture alignment → implementation planning
**What's Next**: UX journey prototypes (HTML) → then actual implementation

---

## 1. WHAT IS CONTRACTNEST

A multi-tenant, multi-product SaaS platform for **service contract lifecycle management**. Think: a hospital admin managing AMCs for biomedical equipment, a facility manager managing housekeeping contracts for a 50-unit apartment complex, a manufacturing plant managing preventive maintenance contracts for 200 machines.

**Tech Stack**: React/TypeScript + Node.js/Express + Supabase (PostgreSQL) + Deno Edge Functions
**Scale**: 62 tables, 150+ API endpoints, 40+ edge functions, 52+ frontend pages, 11 themes

---

## 2. THE CORE PROBLEM WE SOLVED

The system had complete **ServiceContract workflows** (create, assign, accept, invoice, track, renew) BUT was missing three critical business domain dimensions:

### Problem A: No Equipment-Dependent Contracts
- No `t_equipment` master table (TypeScript interfaces exist but no DB backing)
- Equipment data buried in JSONB inside block configs — not relational, not queryable
- No per-equipment scheduling, no equipment lifecycle tracking
- Contract wizard has NO equipment step (despite `availableBlocks` listing `'equipment'`)

### Problem B: No Entity/Property-Dependent Contracts
- Zero representation of physical spaces (buildings, floors, rooms, gardens, pools)
- No entity hierarchy (Campus → Building → Floor → Room)
- No area-based pricing (₹/sqft)
- Contract wizard doesn't ask "WHERE will service be performed?"

### Problem C: Wrong Nomenclature
- Users think in AMC, CMC, FMC, PMC — the system shows "Service Contract"
- **5 overlapping, inconsistent type systems** across the codebase:
  - UI service-contracts: `'service' | 'partnership'`
  - UI general: `'service' | 'partnership' | 'nda' | 'purchase_order' | 'lease' | 'subscription'`
  - API: `'fixed_price' | 'time_and_materials' | 'retainer' | 'milestone' | 'subscription'`
  - API validator: `'client' | 'vendor' | 'partner' | 'fixed_price' | ...` (merged mess)
  - Wizard: `'client' | 'vendor' | 'partner'`
- These conflate 3 different concepts: relationship perspective, pricing model, document type
- "AMC" appears in 15+ template NAMES but is nowhere in the type system

---

## 3. ARCHITECTURE DECISIONS MADE

### Decision 1: Nomenclature via existing LOV pattern (NOT new table)

**Use `m_category_master` + `m_category_details`** — the existing configurable enum system.

- Add 1 row to `m_category_master`: `cat_contract_nomenclature`
- Add 15 rows to `m_category_details`: AMC, CMC, CAMC, PMC, BMC, FMC, O&M, SLA, Rate Contract, Retainer, Per-Call, Warranty Ext, Manpower, Turnkey, BOT/BOOT
- Rich metadata in `form_settings` JSONB per row:
  ```json
  {
    "short_name": "AMC",
    "full_name": "Annual Maintenance Contract",
    "is_equipment_based": true,
    "is_entity_based": false,
    "typical_duration": "12_months",
    "typical_billing": "quarterly",
    "scope_includes": ["scheduled_visits", "labor", "diagnostics"],
    "industries": ["healthcare", "manufacturing", "real_estate"]
  }
  ```
- Add `nomenclature_id UUID REFERENCES m_category_details(id)` to `t_contracts`

**Why**: Consistent with existing LOV pattern used for billing models, plan features, event statuses. No new CRUD needed. Appears automatically in `/settings/LOV`.

### Decision 2: Equipment/Entity tables — dedicated but WITHIN existing resources route

**Existing infrastructure that was built but never connected:**

| Table | Status | Purpose |
|-------|--------|---------|
| `m_catalog_resource_types` | ✅ Populated | Global types: team_staff, equipment, consumable, asset, partner, facility, vehicle, software |
| `m_catalog_resource_templates` | ⚠️ TABLE EXISTS, ZERO SEED DATA | Industry × resource type templates — THE MISSING BRIDGE |
| `m_catalog_industries` | ✅ Populated | Healthcare, Manufacturing, HVAC, etc. |
| `m_catalog_categories` | ✅ Populated | Biomedical Equipment, Elevator, AC, etc. |
| `m_catalog_category_industry_map` | ✅ Populated | Industry ↔ category mapping |
| `t_category_resources_master` | ✅ Working UI at /settings/configure/resources | Tenant's actual resources (people, equipment) |
| `cat_asset_types` | ❌ DDL DESIGNED BUT NOT IN DB | Residential/commercial/appliance variant types for pricing |

**The root cause of "being lost"**: `m_catalog_resource_templates` was never seeded. This broke the chain from "I'm in Healthcare" → "You probably service MRI Scanners" → "Here's an AMC template."

**Architecture for equipment:**
```
GLOBAL: m_catalog_resource_templates (seed with "MRI Scanner" under Healthcare × Equipment)
  ↓ pre-populates during onboarding
TENANT: t_equipment (dedicated table for seller's actual equipment instances with make/model/serial/warranty)
  ↓ linked during contract creation
CONTRACT: t_contract_equipment (junction — many-to-many, per-equipment coverage terms)
```

**Architecture for entities:**
```
GLOBAL: m_entity_types (or cat_asset_types brought to life)
  ↓ pre-populates during onboarding
TENANT: t_entities (specific instances — "Building A, Floor 3, 5000 sqft")
  ↓ linked during contract creation
CONTRACT: t_contract_entities (junction — per-entity pricing rate/unit)
```

**CRITICAL DISTINCTION**: `cat_asset_types` ≠ `t_entities`
- `cat_asset_types` = pricing variant dimension ("1BHK deep cleaning = ₹2,000")
- `t_entities` = specific instance ("Flat 302, Prestige Towers, owned by Mr. Sharma")
- Both needed. Don't merge.

**UI home**: `/settings/configure/resources` — Equipment tab reads from `t_equipment`, Staff tab stays on `t_catalog_resources`. Same route, different backing tables.

### Decision 3: Contracts are bidirectional (buyer OR seller initiates)

- Seller-initiated (current): Seller picks equipment from THEIR resource master → sends to buyer
- Buyer-initiated (new): Buyer describes THEIR equipment/entities → sends as RFQ → sellers quote
- `t_contracts.record_type` already supports `'rfq'` — same junction tables work for both
- Equipment OWNERSHIP stays with buyer even when seller manages the contract

### Decision 4: Multi-asset contracts with per-asset terms

One contract can cover multiple equipment/entities with DIFFERENT coverage terms:
```
Contract #ABC (AMC overall)
├── MRI #1, MRI #2, MRI #3 → CMC terms (parts included)
├── X-Ray #1, X-Ray #2 → PMC terms (parts excluded)
└── CT Scanner #1 → CMC terms (comprehensive)
```
Handled by `t_contract_equipment.coverage_type` + `service_terms` JSONB per row.

### Decision 5: Type system needs cleanup (5 → 4 orthogonal dimensions)

```
contract_perspective   → 'client' | 'vendor' | 'partner'          (WHO)
document_type          → 'service' | 'nda' | 'purchase_order'     (WHAT legal instrument)
pricing_model          → 'fixed_price' | 'retainer' | 'milestone' (HOW you charge)
nomenclature_id        → FK to m_category_details                  (WHAT KIND — AMC/CMC/FMC)
```

---

## 4. IMPLEMENTATION PHASES

### P0 — Nomenclature Foundation (This Week)
1. Seed `m_category_master` + `m_category_details` with 15 nomenclature types
2. Add `nomenclature_id` column to `t_contracts`
3. Nomenclature picker in contract wizard (card grid)
4. Nomenclature badge on contract cards, detail page, dashboard grouping

### P1 — Equipment Foundation (This Sprint)
- P1a: Seed `m_catalog_resource_templates` with real equipment/entity data per industry
- P1b: Create `cat_asset_types` DDL (from CatalogStudio docs)
- P1c: Enhance `/settings/configure/resources` — pre-suggest from templates based on seller's industry
- P1d: Create `t_equipment`, `t_entities`, `t_contract_equipment`, `t_contract_entities`
- P1e: Equipment/entity selection step in contract wizard

### P2 — Wizard Integration & Execution
- Equipment/entity step in wizard with smart routing (nomenclature drives which step appears)
- Buyer-side equipment/entity registration in CNAK acceptance flow
- RFQ support with equipment/entity lists
- Per-equipment event generation
- `equipment_id` on `t_service_tickets` and `t_service_evidence`

### P3 — Intelligence Layer
- Smart nomenclature suggestions (equipment attached → suggest AMC/CMC)
- Template auto-filtering by nomenclature + industry
- Equipment lifecycle management (warranty notifications, transfer between contracts)
- Entity condition tracking (inspections, condition scores)
- Nomenclature-aware document generation (PDF headers, invoice labels)

### P4 — Compound Returns (becomes "free" after P0-P3)
- Auto-renewal with equipment carryover
- Equipment health scoring from service history
- Cross-contract equipment view ("MRI #1 is under AMC with Vendor A AND insurance with Vendor B")
- Entity-level SLA dashboards
- Pricing intelligence ("Average AMC for Split AC 1.5T in Healthcare = ₹4,500/year")
- Buyer portfolio view ("My 12 ACs, 2 DG Sets → Active: 4 AMCs, 1 FMC")
- Vendor capability matching for RFQs
- Predictive maintenance from service event patterns

---

## 5. CURRENT CONTRACT WIZARD FLOW (what exists today)

| Step # | Step ID | Component | What It Does |
|--------|---------|-----------|-------------|
| 1 | path | PathSelectionStep.tsx | Choose "Service Contract" or "Partnership" |
| 2 | acceptance | AcceptanceMethodStep.tsx | e_signature / auto / manual / in_person |
| 3 | counterparty | BuyerSelectionStep.tsx | Pick buyer contact |
| 4 | details | ContractDetailsStep.tsx | Name, number, description, duration |
| 5 | billingCycle | BillingCycleStep.tsx | Monthly/quarterly/annual + payment terms |
| 6 | blocks | ServiceBlocksStep.tsx | Add service/spare/text/document blocks |
| 7 | billingView | BillingViewStep.tsx | Pricing summary |
| 8 | evidencePolicy | EvidencePolicyStep.tsx | Evidence requirements |
| 9 | events | EventsPreviewStep.tsx | Generated service events preview |
| 10 | review | ReviewSendStep.tsx | Final review + send |

**What needs to change:**
- Step 1 should include nomenclature selection (AMC/CMC/FMC cards)
- New Step 3.5: Equipment selection (if nomenclature is equipment-based)
- New Step 3.5-alt: Entity/property selection (if nomenclature is entity-based)
- Step 6: Equipment FlyBy option should render (currently hidden despite being in availableBlocks)
- Step 7: Pricing should be equipment-aware (₹x per machine) or entity-aware (₹x per sqft)
- Step 9: Events should show per-equipment scheduling

---

## 6. KEY FILES TO REFERENCE

### Database Schema
- `contractnest-edge/supabase/migrations/` — all migration files
- `contractnest-api/contractnest_schema.sql` — consolidated schema

### Contract Wizard
- `contractnest-ui/src/components/contracts/ContractWizard/index.tsx` — wizard orchestrator
- `contractnest-ui/src/pages/contracts/create/steps/` — all step components
- `contractnest-ui/src/utils/constants/service-contracts/contractTypes.ts` — type configs + industry configs

### Catalog & Resources
- `contractnest-ui/src/pages/settings/resources/` — resource management UI
- `contractnest-ui/src/utils/constants/industry-advanced.ts` — industry-specific configurations
- `contractnest-ui/src/pages/catalog-studio/templates-list.tsx` — template data (15+ AMC templates hardcoded)

### Types & Constants
- `contractnest-ui/src/types/service-contracts/contract.ts` — EquipmentDetails, ContractType
- `contractnest-ui/src/types/contracts.ts` — CONTRACT_TYPES, CONTRACT_STATUSES
- `contractnest-api/src/types/catalog.ts` — CatalogItemType, ResourceType
- `contractnest-api/src/types/sevice-contracts/block.ts` — EquipmentBlockConfig

### Nomenclature (15 contract types to implement)
| ID | Short | Full Name | Equipment? | Entity? |
|----|-------|-----------|-----------|---------|
| amc | AMC | Annual Maintenance Contract | ✅ | ❌ |
| cmc | CMC | Comprehensive Maintenance Contract | ✅ | ❌ |
| camc | CAMC | Comprehensive AMC | ✅ | ❌ |
| pmc | PMC | Preventive Maintenance Contract | ✅ | ❌ |
| bmc | BMC | Breakdown Maintenance Contract | ✅ | ❌ |
| fmc | FMC | Facility Management Contract | ❌ | ✅ |
| om | O&M | Operations & Maintenance | ✅ | ✅ |
| sla | SLA | Service Level Agreement | ✅ | ❌ |
| rate_contract | Rate Contract | Rate Contract | ❌ | ❌ |
| retainer | Retainer | Retainer Agreement | ❌ | ❌ |
| per_call | Per-Call | Per-Call / On-Demand | ❌ | ❌ |
| warranty_ext | Warranty Ext | Extended Warranty | ✅ | ❌ |
| manpower | Manpower | Manpower Supply Contract | ❌ | ✅ |
| turnkey | Turnkey | Turnkey Contract | ✅ | ✅ |
| bot_boot | BOT/BOOT | Build-Operate-Transfer | ✅ | ✅ |

---

## 7. DESIGN PRINCIPLES

- **User emotional connection**: Facility managers think in AMC/CMC/FMC, not "service contract type A"
- **Existing patterns first**: Use `m_category_master`/`m_category_details` for nomenclature, not new tables
- **Seed data is king**: `m_catalog_resource_templates` being empty is the root cause of disconnection
- **Bidirectional**: Both buyer and seller can initiate contracts/RFQs
- **Multi-asset per contract**: One AMC can cover 3 MRIs (CMC terms) + 2 X-Rays (PMC terms)
- **Hierarchy**: Equipment can have parent-child. Entities have Campus → Building → Floor → Room.
- **Smart suggestions**: Nomenclature drives which wizard steps appear. Equipment attached → suggest AMC/CMC. Entity attached → suggest FMC/O&M.