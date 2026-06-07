ContractNest Architectural Audit Report
Audited by: Claude Code
Date: 2026-05-29
Repo: contractnest (kamalcharan/contractnest-combined)

Executive Summary
ContractNest is a feature-rich, real multi-tenant SaaS — 137 live tables, ~74k LOC backend, ~337k LOC frontend, working contracts/onboarding/JTD subsystems — but it is not production-ready as an autonomous platform. The single biggest gap is tenant isolation: the app runs as Supabase service_role (bypassing RLS), policies use three inconsistent mechanisms, and the tenant GUC is never set — so the database enforces nothing. The single biggest strength is the async + commitment backbone (PGMQ + pg_cron worker + t_contract_events ledger + ~170 enforced FKs), which is genuinely built and only needs to be driven. It is best described as ~75% built scaffolding awaiting its connecting logic, not a finished system.

Codebase Health Score
Dimension	Score	Justification
Code Organisation	7/10	Clean submodule + layered structure (routes/controllers/services), but littered with duplicates (storage copy.ts, AuthContextbak.tsx, *copy.tsx, nested smart-forms/smart-forms).
Data Model Integrity	5/10	~170 FKs solid, but 3 RLS mechanisms, JSONB ID-bags without FKs, duplicate tables (two audit, two idempotency), a stray backup table with no PK.
Feature Completeness	6/10	M1 Auth & M7 JTD strong; M5 catalog empty (0 rows), m_form_template_mappings dead, lead-capture writes to non-existent tables.
AI/Agent Readiness	4/10	Claude generation + pgvector + n8n work, but no provider abstraction, no tool registry, no agent loop, embedding model off-repo.
Multi-Tenant Isolation	3/10	service_role bypasses RLS; GUC never set; dormant policies; tenant tables with RLS off. DB enforces nothing.
Test Coverage	1/10	Zero test files in API, UI, or edge (a test script exists in contractnest-api/package.json but no tests).
Deployment Readiness	4/10	Dockerfiles + docker-compose present for API/UI, but no CI (.github/workflows not found), and the committed schema dump is 5 months stale.
Overall: 4.5/10 — strong bones, unsafe enforcement, untested, and not yet autonomous.

What Is Genuinely Built (Evidence-Based)
Confirmed end-to-end wired (UI → API → edge → DB):

Multi-tenant Auth & 6-step Onboarding — routes/auth.ts, routes/onboardingRoutes.ts, pages/auth/*, pages/onboarding/index.tsx; onboarding seeds via initialize_tenant_onboarding, seedTenantOnIndustryConfirmedService, seed_onboarding_facility_nodes (confirmed total_steps: 6).
Contract creation + commitment materialization — routes/contractRoutes.ts (338 lines), create_contract_transaction (contracts/014) which auto-creates t_contract_events via process_contract_events_from_computed and auto-generates invoices via generate_contract_invoices.
JTD notification system — routes/jtd.ts, routes/adminJtdRoutes.ts, edge jtd-worker, live PGMQ queues pgmq.q_jtd_queue/q_jtd_dlq, live cron jtd-worker-cron (every minute); admin UI pages/admin/jtd/{QueueMonitor,WorkerHealth,EventExplorer,TenantOperations}Page.tsx.
Knowledge-Tree AI generation — services/knowledgeTreeGeneratorService.ts (real Anthropic Claude calls), 13 prompt skills in src/skills/*.md, routes/knowledgeTreeRoutes.ts, with a human test→live gate (promote_catalog_test_to_live, is_live flag).
Semantic search infra — pgvector live; vector columns on t_semantic_clusters, t_tenant_smartprofiles, t_group_memberships, t_query_cache; RPCs vector_search_members, smartprofile_vector_search.
Client Asset Registry — routes/clientAssetRegistryRoutes.ts, pages/equipment-registry/index.tsx + pages/entity-registry/index.tsx via useAssetRegistry, linked to contracts through t_contract_assets.
Auto-expire contracts — live cron auto-expire-contracts-nightly → auto_expire_contracts (contracts/054).
WhatsApp/MSG91 + n8n integration — services/whatsapp.service.ts (MSG91), config/VaNiN8NConfig.ts (n8n embeddings/agent).
What Is Scaffolded But Broken
Feature	Break point
Due-event firing / Service-as-Software loop	Commitment ledger t_contract_events is populated, but no cron scans scheduled_date. Live cron.job has only JTD + auto-expire jobs — no due-event scanner. "Overdue" is read-time only (get_contract_events_date_summary).
Reminder/payment-due notifications	JTD catalog seeds service_reminder/payment_due/payment_overdue/appointment_reminder (jtd-framework/002_seed_jtd_master_data.sql) but nothing enqueues them — only contract status-change enqueues JTDs.
SmartForm dispatch	m_form_template_mappings table exists (with FK from m_form_submissions.mapping_id) but is referenced nowhere in API/UI/edge — no event→form→technician routing.
Renewal	components/services/ServiceRenewalCard.tsx uses mock data (its own comment: "would come from API"); no renewal RPC/endpoint.
Multi-tenant RLS	set_config/SET app.* appears 0 times in API/edge → GUC policies (app.current_tenant_id and the divergent app.tenant_id in contracts/037_asset_registry_tables.sql) evaluate against NULL; only service_role bypass keeps the app working. 7 tables have policies with RLS disabled (t_group_memberships, t_category_*).
Public lead capture	services/public-leads.service.ts POSTs to t_lead_capture, t_resource_usage, t_leads_contractnest — none exist (DB has leads/leads_contractnest). Silent data loss.
AI provider abstraction	Spec calls for ACTIVE_AI_PROVIDER; not found. Hardcoded Anthropic in knowledgeTreeGeneratorService.ts/overlaysGeneratorService.ts/complianceTaggerService.ts.
Service Catalog	t_catalog_items has 0 rows; variant_pricing lives on m_cat_blocks, not catalog items — catalog superseded by catalog-studio.
What Is Missing Entirely (zero code)
Agent orchestration loop — no planner/executor; KT generation is UI-sequenced, VaNi reasoning is an opaque n8n workflow. Not found in-repo.
Tool / function-calling registry — src/skills/ is prompt templates only; no executable tool schema. t_tool_results/t_intent_definitions are unused scaffolding.
Renewal workflow (alert → quote → renewal contract) — no RPC, endpoint, or wired UI.
Field-form auto-dispatch on event — no dispatch code path found.
Cross-provider LLM fallback / streaming / cost budgeting / output guardrails — not found.
Automated tests — zero across all submodules.
CI/CD pipeline — no .github/workflows.
In-repo embedding model — embeddings generated externally by n8n; model/version not found in code.
The 4 Gaps That Block Agentic Transformation
Gap 1 — Tenant isolation is not DB-enforced

Current: service_role bypass; 3 RLS mechanisms; GUC never set; dormant/always-true policies.
Build: Unify all policies on one mechanism (JWT claims preferred), set the tenant GUC in API/edge middleware OR keep app-layer guard but enable+test RLS as defense-in-depth; enable RLS on the 7 dormant-policy tables; fix contracts/037 divergence.
Complexity: L
Gap 2 — The Service-as-Software loop is open (no due-event driver)

Current: t_contract_events ledger + PGMQ + minute-worker + seeded reminder types all exist; nothing connects them.
Build: pg_cron scanner: t_contract_events WHERE scheduled_date <= now()+window AND status='scheduled' → enqueue matching JTD, transition status, spawn create_service_ticket, dispatch mapped SmartForm; sibling job watching t_contracts.end_date for renewal alerts.
Complexity: M
Gap 3 — No LLM-provider abstraction or agent orchestration

Current: Hardcoded Claude (3 services) + opaque n8n; no ACTIVE_AI_PROVIDER, no tool registry, no loop.
Build: A provider-router module (ACTIVE_AI_PROVIDER with Claude/OpenAI/local + fallback/streaming); a real tool registry backed by t_tool_results; a plan→act→observe executor using PGMQ for AI task queues.
Complexity: XL
Gap 4 — Zero tests + no CI on an enforcement-critical system

Current: No tests, no CI; RLS/transaction logic unverifiable.
Build: Vitest (UI) + Jest (API) harness; RLS isolation test suite (cross-tenant read/write must fail); contract-transaction integration tests; a GitHub Actions pipeline.
Complexity: L
Recommended Build Sequence (Next 8 Weeks)
Week 1 — Stop the bleeding (correctness). Fix the lead-table mismatch in services/public-leads.service.ts (point to leads/leads_contractnest); de-duplicate the two jtd-worker crons; remove stray t_contacts_classification_backup_20260128; refresh the stale supabase/migrations/20251229170144_remote_schema.sql.

Week 2 — Tenant isolation, phase 1. Add tenant-GUC set_config in API middleware (middleware/tenantContext.ts) and edge _shared; converge contracts/037 asset policies onto app.current_tenant_id; enable RLS on the 7 dormant tables. (Gap 1)

Week 3 — Test + CI foundation. Stand up Jest (API) / Vitest (UI); write the RLS cross-tenant isolation suite and create_contract_transaction integration test; add .github/workflows/ci.yml. (Gap 4)

Week 4 — Close the service loop, part 1. Build pg_cron scan_due_contract_events(): transition scheduled→overdue/due, enqueue service_reminder/payment_due JTDs. Verify via JTD WorkerHealthPage. (Gap 2)

Week 5 — Close the service loop, part 2. Wire m_form_template_mappings so a due service event auto-creates a t_service_tickets row and dispatches the mapped SmartForm (FormRenderer.tsx) to the assignee. (Gap 2)

Week 6 — Renewal workflow. Add renewal_alert cron on t_contracts.end_date - N; build renewal RPC (quote from expiring contract) and replace mock ServiceRenewalCard.tsx with live data. (Gaps 2/3)

Week 7 — LLM provider abstraction. Introduce ACTIVE_AI_PROVIDER router; refactor knowledgeTreeGeneratorService/overlaysGeneratorService/complianceTaggerService behind it; add fallback + streaming. (Gap 3)

Week 8 — Agent scaffolding. Turn t_tool_results/t_intent_definitions into a live tool registry + execution ledger; build a minimal PGMQ-driven plan→act→observe loop for one use case (e.g., autonomous renewal handling). (Gap 3)

Appendix: File Citation Index
contractnest-api/src/routes/{auth.ts, onboardingRoutes.ts, contractRoutes.ts, jtd.ts, adminJtdRoutes.ts, knowledgeTreeRoutes.ts, clientAssetRegistryRoutes.ts}
contractnest-api/src/services/{knowledgeTreeGeneratorService.ts, overlaysGeneratorService.ts, complianceTaggerService.ts, groupsService.ts, whatsapp.service.ts}
contractnest-api/src/config/VaNiN8NConfig.ts; contractnest-api/src/skills/*.md
contractnest-api/src/middleware/{tenantContext.ts, auth.ts} (GUC not set — confirmed)
contractnest-ui/src/pages/{onboarding/index.tsx, admin/jtd/*, equipment-registry/index.tsx, entity-registry/index.tsx}
contractnest-ui/src/components/contracts/ContractWizard/steps/{EventsPreviewStep.tsx, BillingViewStep.tsx}
contractnest-ui/src/components/services/ServiceRenewalCard.tsx (mock)
contractnest-ui/src/services/public-leads.service.ts (broken table names)
contractnest-edge/supabase/migrations/contracts/{012_contract_events_tables.sql, 013_contract_events_rpc_functions.sql, 014_add_computed_events_to_create_rpc.sql, 037_asset_registry_tables.sql, 054_end_date_prolongation_auto_expire.sql}
contractnest-edge/supabase/migrations/jtd-framework/{002_seed_jtd_master_data.sql, 003_setup_pgmq.sql, 003_jtd_credit_integration.sql, 004_rls_policies.sql}
contractnest-edge/supabase/migrations/catalog-studio/{001_create_cat_blocks.sql, 006_add_is_live_column.sql}
contractnest-edge/supabase/functions/{jtd-worker, group-discovery/handlers/search.ts, service-tickets, smart-forms}
Live DB objects: cron.job (5 jobs), pgmq.q_jtd_queue/q_jtd_dlq, extensions vector/pgmq/pg_cron/pg_trgm
Deployment: contractnest-api/Dockerfile + docker-compose.yml, contractnest-ui/Dockerfile + Docker-compose.yml; CI: not found
Caveat: All scores and findings derive from the 5 prior passes plus this report's test/deploy check. Items marked "not found" were searched for and not located; absence of a file is not proof of absence in a running environment, but no in-repo evidence exists.