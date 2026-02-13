HANDOVER DOCUMENT — Session Feb 13, 2026
Branch: claude/init-submodules-Meu76 on kamalcharan/contractnest-combined
Status: P1 ON HOLD. P0.5 is the prerequisite. Do not continue P1 work.

1. P0.5a Work Completed (SEPARATE SESSION — provided by user)
Branch: claude/init-contractnest-repos-bzPCl

DB Migrations (DEPLOYED to live DB)
001 — Added parent_id, level, segment_type columns to m_catalog_industries
002 — Created t_tenant_industry_segments table
003 — Seeded 68 industry rows (21 parents + 47 sub-segments)
Bug Fixes (5 files in MANUAL_COPY_FILES/ALL-INDUSTRY-FIXES/)
#	Bug	Fix	File
1	Industries API returns 400 when limit > 100	Removed hard rejection, let parsePaginationParams() clamp	contractnest-api/src/validators/productMasterdataValidators.ts
2	Page loads slowly	Changed select('*') to select only needed columns	contractnest-edge/supabase/functions/product-masterdata/index.ts
3	Only 50 of 68 industries load	Changed default limit to 100	contractnest-ui/src/hooks/queries/useProductMasterdata.ts
4	IndustrySelector overrides limit to 200	Removed explicit limit, uses hook default	contractnest-ui/src/components/tenantprofile/IndustrySelector.tsx
5	Edit mode shows "not found" for saved industry	Added fallback matching: strips _general/_other/_default suffix	IndustrySelector.tsx
6	Edit mode always starts at Step 1	Auto-advances to last completed step	contractnest-ui/src/hooks/useTenantProfile.ts
7	Race condition: industry not highlighted	Replaced initialResolveDone flag with lastResolvedValue tracking	IndustrySelector.tsx
P0.5a Commits (on other branch)
9ce38be  fix: restore submodule refs to upstream commits
b89b16f  fix: industry edit mode - selection not showing on edit
cee98f2  fix: consolidated ALL industry fixes into one folder
2ff80d5  fix: handle legacy industry slugs (technology_general → technology)

Known Issue
Tenant 70f8eb69-9ccf-4a0c-8177-cb6131934344 has industry_id: "technology_general" in DB. The IndustrySelector self-heals this to "technology" on next save.

2. P1 Work Started But DISCARDED (THIS session)
All of these commits exist on claude/init-submodules-Meu76 but the USER has instructed to DISCARD and NOT continue this work. The architecture was invalidated by two major corrections.

Commits on this branch (P1 — DO NOT CONTINUE)
f4ac380  fix: use valid VaNiLoader size 'sm' instead of unsupported 'xs'
78393c6  chore: update submodule refs for resource types hierarchy changes
3bcade9  feat: make equipment categories DB-driven instead of hardcoded
79a0cc6  fix: move Equipment Registry to standalone page under Operations
93ddda8  feat: add Equipment Registry menu item under Operations sidebar
03c1f89  feat: P1 Equipment Registry UI — pages, hooks, service, types
50d9242  fix: wrap DROP POLICY in DO block to handle missing tables in 037 DOWN
0c67283  fix: revert in-place index.ts edit, add index.ts to MANUAL_COPY_FILES
fe3ea57  chore: update contractnest-api submodule ref — asset registry routes
6814d1e  feat: P1 Equipment & Entity Foundation — DB + Edge + API

Files in MANUAL_COPY_FILES/feature-p1-equipment/ (30 files — ALL INVALID)
Edge — Migrations (numbering will shift):

File	Status
035_seed_resource_templates.sql (+DOWN)	Concept OK but numbering will change
036_cat_asset_types_lov.sql (+DOWN)	Concept OK but numbering will change
037_asset_registry_tables.sql (+DOWN)	INVALID — table was t_tenant_asset_registry, must become t_client_asset_registry with contact_id as required FK
038_asset_id_on_tickets.sql (+DOWN)	Concept OK, must reference corrected table name
039_resource_types_hierarchy.sql (+DOWN)	REMOVE ENTIRELY — subcategories via parent_type_id approach abandoned
Edge — Function:

File	Status
asset-registry/index.ts	INVALID — must be rewritten as client-asset-registry/index.ts with contact_id scoping
API (all need rewrite):

File	Status
assetRegistryController.ts	Rename to clientAssetRegistryController.ts, add contact_id
assetRegistryRoutes.ts	Rename, update paths
assetRegistryService.ts	Rename, update endpoints
assetRegistryTypes.ts	Rename, add contact_id, change resource_type_id → resource_template_id
assetRegistryValidators.ts	Rename, require contact_id
index.ts	Route registration update
UI (mostly REMOVE):

File	Status
pages/equipment-registry/index.tsx	REMOVE — standalone page is wrong. Assets go on Contact Detail → Assets Tab
pages/equipment-registry/EmptyState.tsx	REMOVE
pages/equipment-registry/EquipmentCard.tsx	REMOVE
pages/equipment-registry/EquipmentFormDialog.tsx	Concept reusable but must move to contacts/tabs/AssetFormDialog.tsx
hooks/queries/useAssetRegistry.ts	Rename to useClientAssetRegistry.ts, add contactId param
services/assetRegistryService.ts	Rename, update endpoints
types/assetRegistry.ts	Rename to clientAssetRegistry.ts, add contact_id
services/serviceURLs.ts	Has RESOURCE_TYPES_BY_PARENT helper — REMOVE that addition
utils/constants/industryMenus.ts	Check if still needed
App.tsx	Has route for /equipment-registry — REVERT
3. Why P1 Was Invalidated (Two Architecture Corrections)
Correction 1: Data Ownership
Before (Wrong)	After (Correct)
Assets belong to TENANTS	Assets belong to CLIENTS (contacts)
Table: t_tenant_asset_registry	Table: t_client_asset_registry
No contact_id FK	contact_id is required FK
Standalone Equipment Registry page	Contact Detail Page → Assets Tab
No wizard integration	Contract Wizard gets Asset Selection Step after buyer selection
Correction 2: Missing Prerequisite
Before building the client asset registry, a Tenant Service Profile must exist — capturing what industries, categories, and equipment types the tenant services. This feeds ALL downstream filtering and suggestions.

4. Current State of Migrations
Deployed to Live DB
#	Migration	Status
002–034	Core contracts, events, tickets, evidence, audit, nomenclature	DEPLOYED
P0.5a 001–003	Industry hierarchy + segments	DEPLOYED
In MANUAL_COPY_FILES Only (NOT deployed, ALL INVALID)
#	Migration	Status
035	seed_resource_templates	Concept OK, renumber
036	cat_asset_types_lov	Concept OK, renumber
037	asset_registry_tables	REWRITE (tenant → client)
038	asset_id_on_tickets	Update FK reference
039	resource_types_hierarchy	DELETE
Revised Migration Plan for Next Session
#	Migration	Purpose
035	tenant_service_profile	NEW — business_model on t_tenants + t_tenant_industries + t_tenant_categories + t_tenant_service_items
036	seed_enhanced_resource_templates	Apply 60 enhanced templates to global catalog
037	asset_type_lov	Per-template dropdown subtypes
038	client_asset_registry	CORRECTED — contact_id required FK
039	contract_assets	Linking table for wizard asset picker
040	asset_id_on_tickets	FK on service tickets
5. Issues & Gotchas Encountered
#	Gotcha	Detail
1	VaNiLoader only supports sm/md/lg	size="xs" crashes with Cannot read properties of undefined (reading 'container'). Always use size="sm" minimum.
2	Submodule commits are tricky	Changes inside submodules show as "modified content" in parent. Must commit inside each submodule FIRST, then update parent's submodule pointer.
3	m_catalog_categories.id is VARCHAR(100), NOT UUID	User's schema drafts said UUID. All FKs referencing categories must use VARCHAR(100).
4	m_catalog_resource_templates.id is VARCHAR(100)	Same as above. FKs must match.
5	m_catalog_industries.id is VARCHAR(100)	Same pattern across all catalog tables.
6	Migration numbering has gaps	017, 029, 032 are missing. 016 appears twice. 015 has a BACKUP file. Don't try to fill gaps.
7	Onboarding has NO industry/service capture	6-step onboarding (user-profile, business-profile, data-setup, storage, team, tour) — none capture industry or services.
8	t_tenant_profiles.industry_id	Exists but is single-industry only. Multi-industry requires t_tenant_industries table. Decide whether to deprecate or keep as "primary" fallback.
6. What the Next Session Needs
Documents to Include in Next Session Context
This handover document (copy-paste it)
CLAUDE.md (already in repo root)
The revised P1 plan from this session (the 6-step build order above)
User's architecture correction message (assets belong to clients, three-layer architecture, revised schema)
User's Tenant Service Profile requirement (business model, industries, categories, service items — 4-step setup)
Key Files to Read First
File	Why
contractnest-edge/supabase/Tables/schema.sql	Full DB schema — understand existing tables
contractnest-edge/supabase/scripts/m_catalog_industries_rows.sql	14+47 industries seeded
contractnest-edge/supabase/scripts/m_catalog_categories_rows.sql	~200+ categories seeded
contractnest-ui/src/pages/contacts/view.tsx	Contact 360 page — where Assets tab will go
contractnest-ui/src/components/contracts/ContractWizard/index.tsx	10-step wizard — asset selection step goes here
contractnest-ui/src/pages/settings/	Where Service Profile page will live
contractnest-ui/src/components/tenantprofile/IndustrySelector.tsx	Existing industry selector pattern to follow
Open Questions for Next Session
m_catalog_categories.id is VARCHAR(100) not UUID — confirmed?
Remove standalone Equipment Registry page entirely, or repurpose?
Deprecate t_tenant_profiles.industry_id after t_tenant_industries is live?
Should Tenant Service Profile be accessible from onboarding flow too, or Settings-only?
Build Order for Next Session
P0.5b: Tenant Service Profile (Step 1 from revised plan)
   → Migration 035
   → Edge function
   → API layer
   → Settings UI (4-step wizard)
   → Then signal ready for P1

End of handover. No further commits will be made in this session.