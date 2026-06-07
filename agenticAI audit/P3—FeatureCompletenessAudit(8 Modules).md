ContractNest — Feature Completeness Audit (8 Modules)
Architecture (verified): UI → Express API (VITE_API_URL) → Supabase Edge Functions (functions/v1, 50 fns) → Postgres (RPCs/tables). The Express API proxies to edge functions in 46 files (only 4 services hit .rpc directly); a few public UI flows call Supabase REST directly. Tenant isolation is enforced in app/RPC code — the DB connects as service_role and bypasses RLS (see prior RLS audit), which colors the "wired" verdict for every tenant-scoped module.

M1 — Multi-Tenant Auth & Onboarding 🟢
EXISTS IN CODE: yes
FRONTEND ROUTE: /login (pages/auth/LoginPage.tsx), /register (RegisterPage.tsx), /register-invitation (InvitationRegisterPage.tsx), /forgot-password, /reset-password, /select-tenant (SelectTenantPage.tsx), /create-tenant, /onboarding (pages/onboarding/index.tsx + OnboardingContext/OnboardingLayout), /onboarding-pending. Auth state in context/AuthContext.tsx.
BACKEND ENDPOINT: routes/auth.ts — /login, /register, /register-with-invitation, /refresh-token, /signout, GET /user (= "me"), /change-password, /reset-password, /google*; routes/onboardingRoutes.ts — /initialize, /status, /step/complete, /step/skip, /progress, /complete. Edge: auth, onboarding, tenants, create-google.
DB TABLES: t_tenants, t_user_profiles, t_user_tenants, t_user_tenant_roles, t_user_auth_methods, t_user_invitations, t_tenant_onboarding, t_onboarding_step_status (570 rows).
WIRED END-TO-END: 🟢 Yes. Onboarding confirmed at 6 steps (total_steps: 6, seeded user-profile→… in onboarding/index.ts).
CRITICAL GAP: None blocking. Minor: stale AuthContextbak.tsx duplicate; register/login/refresh all present and reachable.
M2 — Global Template Designer 🟡
EXISTS IN CODE: yes (functional) — but not to spec on one point.
FRONTEND ROUTE: /catalog-studio (pages/catalog-studio/{blocks,configure,template,templates-list}.tsx) + rich components/catalog-studio/BlockWizard/*.
BACKEND ENDPOINT: routes/catalogStudioRoutes.ts (240 lines — full block/template CRUD, idempotency-keyed), routes/blockRoutes.ts, routes/knowledgeTreeRoutes.ts (AI generation). Services: catBlocksService, catTemplatesService, knowledgeTreeGeneratorService, overlaysGeneratorService, complianceTaggerService, ktCatBlockMapperService. Edge: cat-blocks, cat-templates, blocks, knowledge-tree.
DB TABLES: m_cat_blocks (45 rows; renamed from cat_blocks via global-templates/000), t_cat_templates (2 rows; renamed from m_cat_templates via templates/005), m_block_*, m_catalog_*, m_knowledge_tree_snapshots, m_equipment_*, m_checkpoint_*, m_service_cycles, m_context_overlays.
WIRED END-TO-END: 🟡 UI→API→edge→DB connected; AI pipeline really calls an LLM.
CRITICAL GAP: 🔴 No LLM-agnostic ACTIVE_AI_PROVIDER flag. The AI pipeline is hardcoded to Anthropic (knowledgeTreeGeneratorService.ts: anthropicKey, callAnthropic, x-api-key, anthropic-version, model claude-sonnet-4-6). Swapping providers requires code changes. ⚠️ Table renames (cat_blocks→m_cat_blocks, m_cat_templates→t_cat_templates) mean the spec's "m_ prefix global tables" naming is now mixed (t_cat_templates is tenant-prefixed but holds template designs).
M3 — Smart Forms / Knowledge Tree 🟡
EXISTS IN CODE: yes (partial wiring on one table)
FRONTEND ROUTE: Admin /admin/smart-forms (SmartFormsAdminPage.tsx), /admin/smart-forms/editor/:id (FormEditorPage.tsx + FieldPalette, MonacoSchemaEditor, LiveFormPreview); tenant …/configure/smart-forms (pages/settings/smart-forms/SmartFormsSelectionPage.tsx) with FormRenderer.tsx. Checklist block type: full wizard at components/catalog-studio/BlockWizard/steps/checklist/* ✅.
BACKEND ENDPOINT: routes/adminFormsRoutes.ts (458 lines → /api/admin/forms), routes/tenantFormsRoutes.ts (166 lines → /api/forms), routes/knowledgeTreeRoutes.ts (/generate-variants, /generate-checkpoints, /generate-spare-parts, /generate-service-cycles, …). Edge: smart-forms, knowledge-tree.
DB TABLES: m_form_templates, t_form_templates, m_form_submissions, m_form_attachments, m_form_tenant_selections, m_form_template_mappings, m_equipment_variants/_checkpoints, kt_*.
WIRED END-TO-END: 🟡 Designer, renderer, submissions, KT generators all connected.
CRITICAL GAP: ⚠️ m_form_template_mappings is dead infrastructure — the table exists (RLS + tenant_id) and m_form_submissions.mapping_id FKs to it, but it is referenced nowhere in API, UI, or edge code. The form-template→resource/variant mapping concept is unimplemented. ⚠️ Duplicate admin tree (pages/admin/smart-forms/smart-forms/… nested copy of itself).
M4 — Contract Journey 🟡
EXISTS IN CODE: yes
FRONTEND ROUTE: /contracts (pages/contracts/index.tsx), /contracts/create/:contractType, /contracts/preview, /contracts/review, /contracts/pdf, /contracts/invite; ContractBuilderContext, components/contracts/*.
BACKEND ENDPOINT: routes/contractRoutes.ts (338 lines — create/get/list/update/updateContractStatus/delete, rate-limited, public CNAK endpoints), routes/contractEventRoutes.ts (155 lines). Edge: contracts, contract-events. RPCs: create_contract_transaction, claim_contract_by_cnak, respond_to_contract, get_contract_by_id.
DB TABLES: t_contracts (16), t_contract_blocks, t_contract_attachments, t_contract_vendors, t_contract_history, t_contract_access (CNAK public-claim), t_contract_events/t_contract_event_audit, t_invoices/t_invoice_receipts, t_contract_payment_requests/_events.
WIRED END-TO-END: 🟡 Full seller→buyer path exists incl. CNAK claim + invoicing.
CRITICAL GAP: ⚠️ Contract status values are case-inconsistent in RPCs ('active'/'draft'/'expired'/'completed'/'cancelled' vs 'Cancelled'/'Completed') — fragile state comparisons. ⚠️ Core contract tables use RLS keyed on app.current_tenant_id, a GUC the app never sets — isolation depends entirely on service_role bypass + app code (see RLS audit). No DB-level guarantee for the "8-step" boundary.
M5 — Service Catalog 🟡
EXISTS IN CODE: partial
FRONTEND ROUTE: /catalog (pages/catalog/index.tsx), /catalog/catalogService-form (catalogService-form.tsx), /catalog/view.
BACKEND ENDPOINT: routes/serviceCatalogRoutes.ts (446 lines — list/get/create/update/delete/patch, history, resources), serviceCatalogController, serviceCatalogService, routes/productConfigRoutes.ts. Edge: service-catalog. RPCs: create_service_catalog_item, update_service_pricing, create_catalog_item_version, get_catalog_item_history, calculate_tiered_price.
DB TABLES: t_catalog_items (0 rows), t_catalog_resources, t_catalog_resource_pricing, t_catalog_service_resources, m_catalog_*. Versioning: t_catalog_items.parent_id self-FK ✅ + create_catalog_item_version RPC. variant_pricing JSONB: exists on m_cat_blocks (catalog-studio), not on t_catalog_items.
WIRED END-TO-END: 🟡 Endpoints + schema + versioning RPC present and reachable.
CRITICAL GAP: 🔴 t_catalog_items has 0 rows in production — the catalog appears unused/superseded by the catalog-studio block model (m_cat_blocks, where variant_pricing actually lives). ⚠️ "Multi-currency" is minimal: a single currency VARCHAR(3) DEFAULT 'INR' column — no FX/multi-currency pricing logic. The spec's variant_pricing JSONB is on a different table than implied.
M6 — BBB Directory Bot 🟡
EXISTS IN CODE: yes (infra complete) — with a tenant-isolation hole
FRONTEND ROUTE: /vani/* (vani/pages/* — ChatPage, JobsList, channels/WhatsApp/Website/ChatBot, WebhookManagement), group/smartprofile admin under VaNi.
BACKEND ENDPOINT: routes/groupsRoutes.ts (~40 endpoints: /ai-search, /ai-agent/message, /chat/*, /smartprofiles/*, /profiles/generate-clusters, /profiles/scrape-website, /tenants/search). Services: groupsService, whatsapp.service (MSG91), config VaNiN8NConfig.ts (n8n). Edge: groups, group-discovery, business-groups.
DB TABLES: t_business_groups (2), t_group_memberships (61, embedding vector), t_semantic_clusters (cluster_embedding), t_tenant_smartprofiles (embedding), t_query_cache (query_embedding), t_ai_agent_sessions, t_chat_sessions. pgvector extension installed ✅.
WIRED END-TO-END: 🟡 WhatsApp (MSG91 control.msg91.com ✅), n8n config ✅, pgvector + 4 embedding columns ✅, vector-search RPCs (vector_search_members, smartprofile_vector_search) ✅.
CRITICAL GAP: 🔴 t_business_groups and t_group_memberships have RLS DISABLED while carrying tenant data + dormant policies (4 and 5 respectively) — the bot's core directory data has no DB-level tenant isolation. ⚠️ Only 2 groups / 61 memberships (early-stage / not production-exercised).
M7 — JTD Notification System 🟢
EXISTS IN CODE: yes
FRONTEND ROUTE: /admin/jtd (pages/admin/jtd/{QueueMonitorPage,TenantOperationsPage,EventExplorerPage,WorkerHealthPage}.tsx); VaNi WebhookManagementPage.tsx.
BACKEND ENDPOINT: routes/jtd.ts (POST /events, GET /events/:id, webhooks /webhooks/gupshup, /webhooks/sendgrid), routes/adminJtdRoutes.ts (/queue/metrics, /worker/health, /actions/purge-dlq). Services: jtdService, adminJtdService. Edge: jtd-worker, admin-jtd-management.
DB TABLES: n_jtd (0 rows), n_jtd_templates/_statuses/_channels/_event_types/_source_types/_status_flows/_history/_tenant_config. PGMQ installed ✅ with q_jtd_queue + q_jtd_dlq (+ archive a_jtd_*); pg_cron ✅.
WIRED END-TO-END: 🟢 Queue, worker, DLQ, admin UI, delivery channels (email/sms/whatsapp.service) all present and connected.
CRITICAL GAP: ⚠️ n_jtd has 0 rows — pipeline built but not yet exercised in production. ⚠️ Channel inconsistency: JTD inbound webhooks handle Gupshup + SendGrid, while the BBB bot (M6) sends via MSG91 — two different WhatsApp providers across the platform.
M8 — Client Asset Registry 🟡
EXISTS IN CODE: yes
FRONTEND ROUTE: /equipment-registry (pages/equipment-registry/index.tsx + EquipmentCard, EquipmentFormDialog) and /entity-registry (pages/entity-registry/index.tsx) — both via useAssetRegistryManager (hooks/queries/useAssetRegistry.ts).
BACKEND ENDPOINT: routes/clientAssetRegistryRoutes.ts (CRUD + /children, /contract-assets), clientAssetRegistryController, clientAssetRegistryService. Edge: client-asset-registry. RPCs: seller_add_equipment_to_contract, buyer_add_equipment_to_contract.
DB TABLES: t_client_asset_registry (30), t_contract_assets (asset↔contract link), t_tenant_asset_registry, plus service-history links t_service_tickets.asset_id + t_service_evidence.asset_id.
WIRED END-TO-END: 🟡 Assets, contract-linking, and service-history FK chain all present and reachable.
CRITICAL GAP: 🔴 Asset tables use RLS keyed on current_setting('app.tenant_id') — a different GUC from the rest of the platform (app.current_tenant_id) and one the app never sets. This is the divergent-isolation source flagged in the RLS audit; only service_role bypass keeps it working, and any future PostgREST/agent path would silently see nothing or everything. ⚠️ Two parallel implementations (assetRegistryService.ts + useAssetRegistry vs clientAssetRegistryService.ts + useClientAssetRegistry) — UI uses the former, leaving the latter pair partly orphaned.
Cross-module summary
Module	Verdict	Headline gap
M1 Auth & Onboarding	🟢	Complete (6-step wizard live)
M2 Template Designer	🟡	🔴 No ACTIVE_AI_PROVIDER — hardcoded Anthropic
M3 Smart Forms / KT	🟡	m_form_template_mappings dead table
M4 Contract Journey	🟡	Status case-inconsistency; RLS GUC unset
M5 Service Catalog	🟡	🔴 t_catalog_items empty; multi-currency = INR default only
M6 BBB Bot	🟡	🔴 group tables RLS disabled
M7 JTD	🟢	Queue live but unused; Gupshup vs MSG91 split
M8 Asset Registry	🟡	🔴 divergent app.tenant_id RLS; duplicate service/hook
Platform-wide 🔴 (also surfaced as a concrete break): the public lead-capture UI (services/public-leads.service.ts) POSTs directly to Supabase REST tables t_lead_capture, t_resource_usage, t_leads_contractnest — none exist (DB has leads / leads_contractnest). The ROI-calculator / resources lead forms silently fail to persist. Spanning M2's hardcoded LLM and the three RLS mechanisms, the biggest agentic-readiness blockers are the AI-provider lock-in and the inconsistent/bypassed tenant isolation rather than missing features — most modules are built; the gaps are wiring-consistency and DB-enforcement.

Want me to turn any single module's gaps into a fix plan (e.g., the lead-table mismatch, the ACTIVE_AI_PROVIDER abstraction, or unifying the RLS GUC)?