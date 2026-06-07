ContractNest — Database & RLS Audit (Live)
Executive flags
Sev	Finding
🔴	Tenant isolation is implemented 3 incompatible ways — current_setting('app.current_tenant_id'), current_setting('app.tenant_id'), and request.jwt.claims — across different tables.
🔴	Neither app.* GUC is ever set by the app. grep set_config / SET app.* = 0 hits in API and edge. Every GUC-based policy therefore evaluates tenant_id = NULL → deny-all, and only works because…
🔴	…the app connects as service_role (10 API files, 54 edge files) which bypasses RLS entirely. RLS is effectively decorative; isolation lives in app/RPC code. This is the core agentic-readiness risk.
🔴	7 tables have policies defined but RLS DISABLED (policies dormant) — incl. t_group_memberships, t_category_master/details, t_business_groups.
🔴	15 "RLS policy always true" (USING/ WITH CHECK true) granting unrestricted access.
⚠️	34 public tables with RLS disabled, several holding tenant data (m_event_status_config 1,976 rows; m_event_status_transitions 2,888 rows).
⚠️	3 tables RLS-enabled with zero policies = deny-all (kt_compliance_defaults, kt_equipment_meta, t_seed_logs).
⚠️	JSONB ID-bags with no FK (agent-write hazard): t_contracts.selected_tax_rate_ids, t_invoices.block_ids, t_contacts.parent_contact_ids, etc.
⚠️	Duplicate/legacy infrastructure: two audit tables, two idempotency tables, three category systems, three lead tables, a stray backup table with no PK.
Supabase advisor totals: 47 ERROR · 667 WARN · 3 INFO (incl. 232 mutable-search-path functions, 416 SECURITY DEFINER funcs executable by anon/authenticated, 4 SECURITY DEFINER views).

1. Tables Inventory
137 base tables. PK is uuid almost everywhere; exceptions noted. Grouped by domain; tid = has tenant_id column. Row counts are exact where I queried them, else live planner estimate (~), ? = never analyzed.

Tenants / Users / Auth
Table	Rows	PK	RLS	tid	Purpose
t_tenants	~144	uuid	✅	no	Tenant root
t_user_profiles	~88	uuid	✅	no	User profile
t_user_tenants	~92	uuid	✅	yes	User↔tenant link
t_user_tenant_roles	~37	uuid	✅	no	Role assignment
t_role_permissions	?	uuid	✅	yes	Role→permission (role_id→t_category_details ⚠️)
m_permissions	?	uuid	✅	no	Permission catalog
t_user_auth_methods	~70	uuid	✅	no	Auth methods
t_user_invitations	~24	uuid	✅	yes	Invitations
t_invitation_audit_log	~50	uuid	✅	no	Invite audit
Tenant config / onboarding / profile
Table	Rows	PK	RLS	tid	Purpose
t_tenant_profiles	~73	uuid	✅	yes	Profile
t_tenant_onboarding	~120	uuid	✅	yes	Onboarding
t_onboarding_step_status	570	uuid	✅	yes	Step status
t_tenant_served_industries	~35	uuid	✅	yes	Served industries
t_tenant_industry_segments	?	uuid	✅	yes	Industry segments (9 policies, mixed mechanisms)
t_tenant_regions / t_tenant_domains / t_domain_mappings	?	uuid	✅	mixed	Regions/domains
t_tenant_smartprofiles	?	uuid	✅	yes	AI smart profile
t_tenant_files	~35	uuid	✅	yes	File registry
t_tenant_integrations / t_integration_providers / t_integration_types	?	uuid	✅	mixed	Integrations
t_tenant_context	0	text	🔴 off	yes	Tenant context cache (empty, RLS off)
n_tenant_preferences	0	uuid	🔴 off	yes	Prefs (empty, RLS off)
t_system_config	?	text	off	no	Global config (non-tenant)
Contacts / Groups
Table	Rows	PK	RLS	tid	Purpose
t_contacts	~29	uuid	✅	yes	Contacts
t_contact_addresses / t_contact_channels	~16	uuid	✅	no	Contact sub-records
t_business_groups	2	uuid	🔴 off	no	Buying/selling groups (4 dormant policies)
t_group_memberships	61	uuid	🔴 off	yes	Memberships (5 dormant policies)
t_group_activity_logs	?	uuid	✅	yes	Group activity
t_semantic_clusters	~177	uuid	✅	yes	Smartprofile clusters (7 policies)
t_ai_agent_sessions / t_chat_sessions	~122	uuid	✅	yes	AI sessions
t_query_cache / t_tool_results / t_intent_definitions	mixed	uuid	mixed	no	AI cache/tools (t_tool_results RLS off, sensitive ⚠️)
Contracts core
Table	Rows	PK	RLS	tid	Purpose · isolation
t_contracts	~16	uuid	✅	yes	Contracts · app.current_tenant_id
t_contract_blocks	~13	uuid	✅	yes	Blocks · app.current_tenant_id
t_contract_attachments	?	uuid	✅	yes	Attachments · app.current_tenant_id
t_contract_vendors	?	uuid	✅	yes	Vendors · app.current_tenant_id
t_contract_history	~115	uuid	✅	yes	History · app.current_tenant_id
t_contract_access	~12	uuid	✅	yes	CNAK public access · EXISTS
t_contract_events / t_contract_event_audit	~58	uuid	✅	yes	Events · EXISTS
t_service_tickets / t_service_ticket_events / t_service_evidence	?	uuid	✅	mixed	Service execution · EXISTS (t_service_ticket_events no tid)
t_invoices / t_invoice_receipts	~17/15	uuid	✅	yes	Invoicing · EXISTS
t_contract_invoice / t_contract_payment_requests / t_contract_payment_events	?	uuid	✅	yes	Payments (payment_events always-true 🔴)
Assets / Equipment (the divergent mechanism)
Table	Rows	PK	RLS	tid	Purpose · isolation
t_client_asset_registry	~30	uuid	✅	yes	Client assets · 🔴 app.tenant_id
t_contract_assets	?	uuid	✅	yes	Contract↔asset · 🔴 app.tenant_id
t_tenant_asset_registry	?	uuid	✅	yes	Tenant assets · 🔴 app.tenant_id
t_equipment	?	uuid	✅	yes	Equipment · request.jwt.claims
t_custom_checkpoints/_values, t_custom_spare_parts, t_custom_variants, t_cycle_overrides	?	uuid	✅	yes	Per-tenant overrides · jwt.claims
Catalog / Knowledge-tree masters (mostly global, RLS off)
Table	Rows	PK	RLS	tid	Purpose
m_catalog_industries	~75	varchar	off	no	Industry master
m_catalog_categories	~365	varchar	off	no	Category master
m_catalog_category_industry_map	~417	varchar	off	no	Cat↔industry
m_catalog_resource_templates	~240	uuid	off	no	Resource templates
m_catalog_resource_template_industries	~296	uuid	off	no	Template↔industry
m_catalog_resource_types	?	varchar	off	no	Resource types
m_catalog_pricing_templates	?	uuid	off	no	Pricing templates
m_equipment_checkpoints/_variants/_spare_parts, m_checkpoint_values, m_checkpoint_variant_map, m_spare_part_variant_map, m_service_cycles, m_context_overlays	43–808	uuid	✅	no	KT generated masters
kt_compliance_defaults	~34	uuid	🔴 ✅/no-policy	no	Compliance defaults (deny-all)
kt_equipment_meta	?	uuid	🔴 ✅/no-policy	no	Equipment meta (deny-all)
m_knowledge_tree_snapshots	?	uuid	✅	no	KT snapshots
m_facility_hierarchy_templates	?	uuid	✅	no	Facility templates
Catalog-studio / blocks / forms
Table	Rows	PK	RLS	tid	Purpose
m_cat_blocks	~45	uuid	✅	yes	Studio blocks (FK tenant_id→t_tenants)
t_cat_templates	2	uuid	✅	yes	Studio templates
m_block_categories/_masters/_variants	?	uuid	✅	no	Legacy block library
m_form_templates	2	uuid	off	no	Form template master
t_form_templates	?	uuid	✅	yes	Tenant form templates · jwt.claims
m_form_submissions/_attachments/_template_mappings/_tenant_selections	?	uuid	✅	yes	Smart-forms · jwt.claims
t_seed_logs	?	uuid	🔴 ✅/no-policy	yes	Seed log (deny-all)
t_idempotency_keys	121	uuid	🔴 off	yes	Idempotency (RLS off)
api_idempotency	~162	uuid	off	no	⚠️ 2nd idempotency table
Tenant catalog (per-tenant overlay — largely empty)
Table	Rows	PK	RLS	tid	Purpose
t_catalog_items	0	uuid	✅	yes	Service catalog items
t_catalog_resources/_resource_pricing/_service_resources	?	uuid	✅	yes	Catalog resources · jwt.claims
t_catalog_categories	0	uuid	🔴 off	yes	⚠️ Empty + RLS off
t_catalog_industries	0	uuid	🔴 off	yes	⚠️ Empty + RLS off
Category system (three parallel sets ⚠️)
Table	Rows	PK	RLS	tid	Purpose
c_category_master / c_category_details	?	uuid	✅(no tid policy)	no	"c_" category system
m_category_master / m_category_details	7/111	uuid	off	no	"m_" master LOVs
t_category_master	134	uuid	🔴 off	yes	"t_" tenant categories (4 dormant policies)
t_category_details	262	uuid	🔴 off	yes	Tenant LOVs incl. roles (4 dormant policies)
t_category_resources_master	129	uuid	🔴 off	yes	Category↔resource (2 dormant policies)
Event-status config
Table	Rows	PK	RLS	tid	Purpose
m_event_status_config	1,976	uuid	🔴 off	yes	⚠️ Per-tenant status config, RLS off, tenant data
m_event_status_transitions	2,888	uuid	🔴 off	yes	⚠️ Status transitions, RLS off, tenant data
Billing / business-model
Table	Rows	PK	RLS	tid	Purpose
t_bm_pricing_plan	3	uuid	✅	no	Plans (always-true insert/update 🔴)
t_bm_plan_version	5	uuid	✅	no	Plan versions
t_bm_tenant_subscription / _subscription_usage / _invoice	?	uuid	✅	yes	Subscriptions
t_bm_credit_balance / _credit_transaction / _billing_event	?	uuid	✅	yes	Credits/billing
t_bm_topup_pack / _feature_reference / _notification_reference	?	uuid/varchar	✅	no	Reference data
t_bm_product_config	?	uuid	✅	no	Product config
t_bm_product_config_history	?	uuid	⚠️ off	no	Config history (RLS off)
m_products	?	uuid	✅	no	Products (always-true 🔴)
Tax
Table	Rows	PK	RLS	tid	Purpose
t_tax_settings	?	uuid	✅(7 pol)	yes	Tax settings (incl. always-true service-role bypass 🔴)
t_tax_rates	~12	uuid	✅	yes	Rates · jwt.claims
t_tax_info	?	uuid	✅	yes	Tax info
JTD (notification/job framework, n_ prefix)
Table	Rows	PK	RLS	tid	Purpose
n_jtd	0	uuid	✅	yes	Jobs-to-do
n_jtd_history / _status_history	43/0	uuid	✅	no	JTD history
n_jtd_templates / _tenant_config / _tenant_source_config	?	uuid	✅	yes	JTD config
n_jtd_channels/_event_types/_source_types/_statuses/_status_flows	?	varchar/uuid	✅	no	JTD masters
n_customers / n_deliveries / n_templates / n_platform_providers / n_system_actors	?	uuid	mostly off	no	⚠️ Legacy delivery tables (n_customers sensitive, RLS off 🔴)
Leads / campaigns / FamilyKnows (cross-product)
Table	Rows	PK	RLS	tid	Purpose
leads	1	uuid	🔴 off	no	⚠️ Leads (2 dormant policies)
leads_contractnest	5	uuid	🔴 off	no	⚠️ 2nd leads table (2 dormant policies)
t_campaigns / t_campaign_leads	0	uuid	✅	no	Campaigns (always-true policies 🔴)
familyknows_contacts / familyknows_waitlist	?	uuid	✅	no	FamilyKnows (anon always-true insert)
t_audit_logs	~5,304	uuid	✅	yes	Audit log (primary)
t_audit_log	~17	uuid	✅	yes	⚠️ 2nd audit table (near-empty)
t_contacts_classification_backup_20260128	79	none 🔴	off	no	⚠️ Stray backup, no PK, RLS off
2. RLS Audit
2a. The tenant-isolation mechanism split 🔴
Mechanism	# policies	Tables
current_setting('app.current_tenant_id', true)	25	t_contracts, t_contract_blocks, t_contract_attachments, t_contract_vendors, t_contract_history, t_sequence_counters, t_tenant_industry_segments
current_setting('app.tenant_id', true) 🔴	3	t_client_asset_registry (car_tenant_isolation), t_contract_assets (ca_tenant_isolation), t_tenant_asset_registry (tar_tenant_isolation)
request.jwt.claims ->> tenant_id	~20	t_catalog_, t_equipment, t_custom_, t_cycle_overrides, t_form_templates, m_form_*, t_tax_rates
EXISTS-subquery on t_user_tenants / t_group_memberships ("other")	~120	most remaining t_* tables
Why this is critical: the asset-registry trio uses app.tenant_id while the contracts core uses app.current_tenant_id. The application sets neither — set_config/SET app.* appears 0 times across API and edge. So under any non-service-role connection (e.g. a future agent using anon/authenticated PostgREST), current_setting(...) is NULL → tenant_id = NULL → row hidden → silent total denial, and the three app.tenant_id tables and seven app.current_tenant_id tables behave identically broken but were "fixed" in different migrations, so they'll drift apart the moment GUC-setting is introduced. Today it only "works" because the app uses service_role (RLS-bypassing) — confirmed in 10 API + 54 edge files.

2b. Policies defined but RLS DISABLED (dormant — silent exposure) 🔴
leads, leads_contractnest, t_business_groups, t_category_details, t_category_master, t_category_resources_master, t_group_memberships. → Policies exist (giving false confidence) but are inert; tables are fully readable via any RLS-respecting path.

2c. RLS enabled but NO policy (deny-all) ⚠️
kt_compliance_defaults, kt_equipment_meta, t_seed_logs.

2d. "RLS policy always true" (USING/WITH CHECK = true) 🔴 — 15
m_products (super_admins_manage_products ALL), t_bm_pricing_plan (insert+update), t_campaigns (insert/update/delete), t_campaign_leads (insert anon+auth, update, delete), t_contract_payment_events (service insert+update), t_tax_settings (service_role_bypass_rls_tax_settings ALL), familyknows_contacts/familyknows_waitlist (anon insert).

2e. RLS disabled but holds tenant data ⚠️/🔴
m_event_status_config (1,976), m_event_status_transitions (2,888), t_category_master (134), t_category_details (262), t_category_resources_master (129), t_group_memberships (61), t_idempotency_keys (121), t_tenant_context (0), n_tenant_preferences (0), t_catalog_categories (0), t_catalog_industries (0). Plus sensitive non-tenant: n_customers, t_tool_results (advisor: "Sensitive Columns Exposed").

3. Foreign-Key Map
~170 FK constraints — the relational core is well-constrained. Hubs:

t_tenants ← 20+ tables via tenant_id (m_cat_blocks, t_catalog_, t_category_, t_group_, t_user_, t_tax_*, t_sequence_counters, t_audit_logs, …).
t_contracts ← t_contract_blocks/attachments/vendors/events/history/access, t_invoices, t_invoice_receipts, t_contract_payment_requests, t_service_tickets, t_contract_assets.
m_catalog_resource_templates ← equipment/checkpoint/spare-part/variant/form chains (KT graph).
n_jtd ← status/history/templates; t_business_groups ← memberships/activity/sessions/cache.
auth.users ← t_user_*, t_contacts.auth_user_id, t_tenants.created_by, t_audit_logs.user_id.
Notable design choices (not broken, but coupling risks):

⚠️ t_role_permissions.role_id and t_user_tenant_roles.role_id → t_category_details — roles are stored as generic LOV rows; an agent editing t_category_details can mutate the RBAC graph.
Self-refs: m_block_*, m_catalog_industries, t_catalog_items, t_contacts, t_client_asset_registry, t_tenant_asset_registry, m_form_templates, t_form_templates, t_cat_templates.
JSONB columns storing IDs with NO FK (agent-write hazards) 🔴/⚠️:

Table.column	Intended target	Risk
t_contracts.selected_tax_rate_ids	t_tax_rates	🔴 unenforced array; agent can write dangling/cross-tenant rate IDs
t_invoices.block_ids	t_contract_blocks	🔴 unenforced array
t_contracts.evidence_selected_forms	form templates	⚠️ unenforced
t_contracts.asset_summary	denormalized assets	⚠️ can desync from t_contract_assets
t_contacts.parent_contact_ids	t_contacts	⚠️ array variant (scalar parent_contact_id IS FK'd)
t_contract_assets.pricing_override	pricing	⚠️ free-form
m_cat_blocks.knowledge_tree_ref	KT snapshot	⚠️ unenforced
n_jtd_tenant_config.provider_config_refs	providers	⚠️ unenforced
leads_contractnest.contract_data	—	⚠️ blob
4. Empty / Unused Infrastructure
Zero-row tables that appear meant to hold data:

t_catalog_categories (0), t_catalog_industries (0) — per-tenant catalog taxonomy never populated (superseded by m_catalog_* + t_category_*).
t_tenant_context (0) and n_tenant_preferences (0) — RLS off, never used.
t_catalog_items (0), t_campaigns/t_campaign_leads (0), n_jtd/n_jtd_status_history (0).
Legacy delivery tables n_customers, n_deliveries, n_templates, n_platform_providers — never analyzed, effectively dormant.
Duplicate / superseded infrastructure ⚠️:

Two audit tables: t_audit_logs (5,304, active) vs t_audit_log (17, near-dead).
Two idempotency tables: t_idempotency_keys (121) vs api_idempotency (162).
Three category systems: c_category_*, m_category_*, t_category_*.
Three lead stores: leads, leads_contractnest, t_campaign_leads.
Two block systems: m_block_* (legacy) vs m_cat_blocks (studio).
🔴 Stray backup t_contacts_classification_backup_20260128 (79 rows, no PK, RLS off) left in public.
SECURITY DEFINER views (run as owner, bypass caller RLS): v_resource_templates_by_industry, v_onboarding_master_data, v_membership_details, v_cache_analytics.

5. Migration Sequence & RLS-Touching Migrations
Full ordered list was delivered in the prior inventory (124 SQL files; edge contracts/ runs 002→060). The migrations that create or alter RLS — the drift sources — are:

Migration	RLS action	Mechanism introduced
sequence-numbers/001_create_t_sequence_counters.sql	policies on t_sequence_counters	app.current_tenant_id
contracts/037_asset_registry_tables.sql	car/ca/tar policies	🔴 app.tenant_id (the divergent one)
onboarding/005_rls_jwt_tenant_check.sql	rewrites tenant check	🔴 app.tenant_id + JWT
onboarding/004_seed_rls_fixes.sql	seed-time RLS fixes	mixed
jtd-framework/004_rls_policies.sql	n_jtd_* policies	EXISTS/jwt
contracts/045_buyer_rls_and_invoice_cancel_writeoff.sql	buyer access policies	EXISTS
contracts/004,005,011,012,022,023,024,025	ENABLE RLS + policies on contract/invoice/ticket/audit tables	EXISTS
catalog-studio/001,002	cat_blocks / cat_templates policies	mixed
smart-forms/001,002	m_form_* policies	request.jwt.claims
p05a-industry-hierarchy/002, sequence-numbers/...	segment/counter policies	app.current_tenant_id
🔴 Root-cause of inconsistency: contracts/037 and onboarding/005 introduced the app.tenant_id GUC variant, diverging from the app.current_tenant_id convention established in the contracts core and sequence-counters. Combined with the app never calling set_config and connecting as service_role, the database has three nominal isolation schemes, none actually enforcing at the DB layer today.

Agentic-readiness bottom line
For an autonomous agent to safely write to this DB, the database itself cannot currently be trusted as the tenant guardrail: RLS is bypassed (service_role), inconsistent (3 mechanisms), partly dormant (policies w/ RLS off), and partly deny-all (no GUC set / no policy). Add to that ~170 good FKs undermined by JSONB ID-bags that carry tenant-scoped references with no enforcement. The safe path is app/RPC-mediated writes only — direct table writes by an agent would have no reliable isolation or referential safety.

I queried the live DB read-only (SELECTs + advisors); I made no changes. Want me to (a) draft the migration that unifies all policies onto a single app.current_tenant_id (or JWT) mechanism + enables the GUC in the API middleware, or (b) produce a remediation checklist ranked by severity?