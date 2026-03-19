---
name: contractnest-template-agent
description: >
  Generates complete contract templates (blocks + SmartForm schemas) for ContractNest resources.
  Use this skill when an admin needs to create a global contract template for any equipment, facility,
  or service. The agent classifies the resource, researches industry standards, generates an ordered
  set of contract blocks with pricing and evidence config, and auto-creates SmartForm JSON schemas
  with domain-specific fields (e.g., Pharma Reactor → vessel pressure, agitator RPM, gasket condition).
  Triggers on: template creation, template generation, contract template design, SmartForm generation
  for a resource, "create template for [equipment]", global template builder, AI template agent,
  or any mention of generating blocks and forms for a contract template.
---

# ContractNest Template Agent

## Purpose

This is **Skill #2** in the ContractNest 5-skill AI pipeline:

```
1. Master Data Agent (Skill #1)     → Seeds domain data (industries, resources, categories)
2. TEMPLATE AGENT (this skill)      → Generates templates + SmartForms from resource data
3. VaNi Contract Agent (Skill #3)   → Operates on live tenant data
4. VaNi Marketing Agent (Skill #4)  → Demos with real industry data
5. GeM Marketplace Skill (Skill #5) → Government marketplace integration
```

The Template Agent takes a resource from `m_catalog_resource_templates` (seeded by Skill #1) and produces:
- A complete `cat_templates` record with ordered blocks
- Individual `cat_blocks` records (service, pricing, terms, schedule, etc.)
- `form_templates` records with full JSON schemas (SmartForms) — domain-specific, not generic

## IMPORTANT

> **All database writes, schema changes, and API designs proposed by this skill are PROPOSALS.**
> They must be reviewed and approved by the Product Owner before execution.
> This skill generates output for review — it does NOT auto-execute.

## How It Works

### Step 1: Read References

Before generating anything, ALWAYS read:
1. `references/template-generation-rules.md` — Block assembly rules per nomenclature, SmartForm timing rules, pricing patterns
2. `references/smartform-field-patterns.md` — Domain-specific field patterns per resource type and industry
3. The PRD at `/mnt/user-data/outputs/contractnest-global-designer-prd.md` — For TypeScript interfaces and data model

Also read from Skill #1 (Master Data Agent):
4. `/mnt/skills/user/contractnest-master-data-agent/references/schema-reference.md` — Full database schema
5. `/mnt/skills/user/contractnest-master-data-agent/references/industry-seed-patterns.md` — Industry patterns and nomenclature→block mappings

### Step 2: Identify Generation Context

Gather from the user or from the database:
- **Resource** — Which `m_catalog_resource_templates` record (name, type, sub_category, industry, attributes)
- **Nomenclature** — Which contract type: AMC, CMC, FMC, Care Plan, SLA, etc.
- **Currencies** — Which currencies to support (default: INR)
- **Additional context** — Any user-provided specifics (e.g., "include quarterly calibration", "this is for a GMP facility")

### Step 3: Classify the Resource

Determine the resource's classification to guide template structure:

| Classification | Indicators | Template Characteristics |
|---------------|-----------|------------------------|
| **Equipment** | resource_type_id = 'equipment', has make_examples, requires_calibration | PM visits, breakdown support, spare parts, calibration schedule |
| **Facility** | resource_type_id = 'asset', has area/classification attributes | Multi-service (housekeeping, technical, security), deployment plans |
| **Service** | resource_type_id = 'team_staff' or context is service-oriented | Session-based, consultation, therapy, subscription |
| **Consumable** | resource_type_id = 'consumable' | Supply contracts, per-unit pricing, replenishment schedules |
| **Partner** | resource_type_id = 'partner' | Subcontracting, vendor management, SLA-based |

### Step 4: Research Industry Standards

If web search is available, research:
- Standard maintenance procedures for this specific resource
- Regulatory/compliance requirements (FDA, NABH, ISO, GMP, etc.)
- Typical SLA parameters (response time, resolution time, uptime %)
- Industry-standard pricing models and ranges
- Common checklist items for pre/post service inspections

If web search is NOT available, use the domain knowledge in `references/smartform-field-patterns.md` and the industry seed patterns from Skill #1.

### Step 5: Generate Template Structure

Follow the nomenclature→block mapping rules in `references/template-generation-rules.md`.

Output a JSON object matching the `GeneratedTemplate` interface (see PRD Section 3.3):

```json
{
  "template": {
    "name": "...",
    "description": "...",
    "nomenclature_code": "amc",
    "supported_currencies": ["INR", "USD"],
    "industry_tags": ["pharma"],
    "complexity": "medium",
    "est_duration_minutes": 15,
    "tags": ["equipment", "reactor", "gmp"]
  },
  "blocks": [ ... ],
  "smartForms": [ ... ],
  "eventSchedule": [ ... ],
  "researchContext": "..."
}
```

### Step 6: Generate SmartForms

For each service block that requires data capture, generate a complete SmartForm JSON schema.

**Critical rules for SmartForm generation:**
1. Fields MUST be domain-specific — not generic. "Vessel Pressure (bar)" not "Reading 1"
2. Use correct units of measurement for the industry/resource
3. Include visibility rules where fields depend on other selections
4. Include file upload fields for evidence (photos, documents)
5. Include signature fields for sign-off
6. Match the existing `form_templates.schema` JSONB structure exactly
7. Generated forms start in `draft` status — admin must review and approve
8. Follow the field type registry: text, number, select, multi_select, checkbox, radio, date, time, file, signature, textarea, computed, lookup, repeater, rating

See `references/smartform-field-patterns.md` for domain-specific field examples.

### Step 7: Output for Review

Present the generated template to the admin for review. The output should include:
- Template summary (name, nomenclature, blocks count, forms count)
- Block-by-block breakdown with pricing
- SmartForm field previews (section names + field labels)
- Event schedule summary

The admin can then: Accept, Modify (provide feedback for regeneration), or Reject.

## LLM Provider Configuration

This skill is **LLM-agnostic**. The actual LLM provider is configured in `src/constants/ai-providers.ts`:

```typescript
// Supported providers: claude, openai, gemini, liquidai
// Active provider set via: ACTIVE_AI_PROVIDER env variable
// See PRD Section 3.1 for full provider definitions
```

When this skill is used as a prompt template for the agent pipeline, the system prompt and user prompt are constructed here, but the LLM call goes through the `LLMAdapter` interface which routes to whichever provider is active.

## Critical Rules

### Block Generation Rules
- Always include at least one Service block and one Billing block
- Service blocks MUST have evidence requirements defined (photo, signature, GPS, timestamp)
- Pricing blocks MUST specify currency, tax_rate (default 18% for INR), and price_type
- Block order follows: Service blocks → Spare blocks → Billing → Terms → Schedule → Checklists
- Each block needs: name, display_name, block_type, category, config, pricing_mode, base_price, price_type
- `is_seed = true` for all generated blocks
- `scope = 'global'` for all generated blocks (tenant_id = NULL)

### SmartForm Generation Rules
- Pre-service forms: Safety checks, equipment identification, condition assessment
- During-service forms: Actual work log, measurements, calibration records
- Post-service forms: Completion report, test results, sign-off, next action items
- Every form MUST have an equipment/resource identification section as the first section
- Every form MUST end with a sign-off section (signature + overall assessment)
- File upload fields should specify accepted MIME types and max size
- Computed fields should have valid formulas
- Do NOT generate generic forms — every field must be specific to the resource

### Pricing Rules
- Use pricing_guidance from m_catalog_resource_templates when available
- AMC pricing: typically 5-10% of equipment purchase cost per year
- CMC pricing: typically 8-15% of equipment cost (includes parts)
- Service rates: use suggested_hourly_rate from resource metadata
- Always include tax_rate (18% GST for INR, varies by currency — see PRD Section 9.1)
- Support multiple currencies in the same template

### Nomenclature Awareness
- AMC → Scheduled PM + Breakdown support + Parts (limited) + Annual pricing
- CMC → All-inclusive maintenance + Unlimited breakdown + All parts + Fixed pricing
- CAMC → CMC variant for government/PSU with specific compliance
- FMC → Multi-service facility management + Manpower + Consumables
- Care Plan → Session-based services + Treatment protocol + Package pricing
- SLA → Performance targets + Penalty framework + Monitoring
- See `references/template-generation-rules.md` for complete mapping

## Testing

After generating a template, verify:

```
✓ Template has valid nomenclature_code matching m_category_details
✓ All blocks have valid block_type (service, spare, billing, text, checklist, document)
✓ All blocks have pricing_mode (independent, resource_based, variant_based, multi_resource)
✓ All blocks have price_type (per_session, per_hour, per_day, per_unit, fixed)
✓ SmartForm schemas are valid JSON matching form_templates.schema structure
✓ SmartForm field types are in the supported registry
✓ SmartForm visibility rules reference valid field IDs within the same form
✓ Evidence requirements are defined on all service blocks
✓ At least one currency is specified
✓ Event schedule includes frequency and event_type
```