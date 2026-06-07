Top-Level Directories
Path	Type	Purpose
contractnest-api/	Submodule	Backend REST API (Node.js/Express/TypeScript)
contractnest-ui/	Submodule	Frontend web app (React/Vite/TypeScript)
contractnest-edge/	Submodule	Supabase Edge Functions (Deno) + SQL migrations/RPCs
ContractNest-Mobile/	Submodule	Mobile app (React Native / Expo)
FamilyKnows/	Submodule	Separate product — Expo app (src/) + React website (FamilyKnows-Website/)
ClaudeDocumentation/	Submodule	Project documentation (Markdown, 263 files)
supabase/	Local dir	Root Supabase CLI config + 1 remote-schema snapshot migration
scripts/	Local dir	PowerShell git automation (push/pull/tag/merge) + reference/ pattern docs (rls, api, edge, db, scale, correctness)
MANUAL_COPY_FILES/	Local dir	Claude's staging output folder (384 files) — per CLAUDE.md workflow
Manual_Copy/, manual_copy_familyknows/, manual_copy_familknows/	Local dirs	Additional/legacy staging folders (43 / 98 / 2 files)
node_modules/	Local dir	Root deps (only lottie-react)
index.ts (root)	Stray file	1,673-line copy of the groups edge function ("MEGA FILE") sitting in repo root
CLAUDE.md, README.md, package.json	Root files	Session instructions, readme, near-empty manifest
2. Backend — contractnest-api (Express/Node)
Totals: 204 .ts files · ~74,196 LOC · src/ layout: controllers · services · routes · middleware · validators · modules · migrations · seeds · types · config · constants · utils · docs · skills

Route files (37) & endpoint summary
Mounted route modules expose ~210 endpoints. Highlights:

Route file	Notable endpoints
auth.ts	login, register, register-with-invitation, refresh-token, google / google-callback / google-link / google-unlink, change-password, reset-password, verify-password, signout, complete-registration, GET user, PATCH preferences
tenants.ts	GET /, GET /:id, GET check-availability, POST create-from-google, create-google
adminTenantRoutes.ts	list, stats, create, /:id/data-summary, close-account, reset-all-data, reset-test-data
tenantAccountRoutes.ts	data-summary, close-account, reset-all-data, reset-test-data
contactRoutes.ts	CRUD /,/:id, search, duplicates, stats, constants, /:id/cockpit, /:id/invite, PATCH /:id/status
groupsRoutes.ts	~40 endpoints — memberships, smartprofiles, profile clusters, AI search/agent, chat (init/session/intent/activate/end), website scrape, admin stats/activity
contractRoutes.ts, contractEventRoutes.ts, serviceCatalogRoutes.ts, resourcesRoutes.ts, catalogStudioRoutes.ts	health roots (route trees built deeper in services/modules)
serviceExecutionRoutes.ts	tickets CRUD, /:ticketId/evidence, audit
clientAssetRegistryRoutes.ts	CRUD + /children, /contract-assets
businessModelRoutes.ts	plans + plan-versions CRUD, activate, archive, visibility, compare
billingRoutes / paymentGatewayRoutes	create-order, create-link, verify-payment, status
knowledgeTreeRoutes.ts	generate, generate-variants/pricing/overlays/checkpoints/service-names/service-cycles/spare-parts, tag-compliance
seedRoutes / sequenceRoutes / masterDataRoutes / productMasterdataRoutes / taxSettingsRoutes / onboardingRoutes / storage.ts / systemRoutes / auditRoutes / jtd.ts / adminJtdRoutes / adminFIrebaseRoutes / integrationRoutes / blockRoutes / productsRoutes / tenantProfileRoutes / tenantContextRoutes / cardProxyRoutes / fkauthProxy / fkonboardingProxy	masterdata, seeds, sequences, tax, onboarding, storage, system health, audit logs, JTD webhooks (gupshup/sendgrid), FamilyKnows proxies, vCard proxy
Note: storage copy.ts is a duplicate of storage.ts; several route files (billingRoutes, productConfigRoutes, eventStatusConfigRoutes, invitationRoutes, tenantFormsRoutes, adminFormsRoutes, userRoutes) register handlers via sub-routers/non-router.X patterns.

Middleware (13 files)
auth.ts · tenantContext.ts · productContext.ts · requestContext.ts · auditMiddleware.ts · error.ts · validateRequest.ts · contactValidators.ts · fileUpload.ts · maintenance.ts · serviceCatalogAuth.ts · security/hmac.ts · (dir security/)
Roles: authentication, multi-tenant context injection, product-scope context, request correlation, audit logging, central error handler, request validation, file uploads, maintenance gate, catalog-specific auth, HMAC request signing.

Controllers (32) & Services (~45)
Controllers (32): auth, tenant, tenantContext, tenantProfile, user, contact, group, contract, contractEvent, serviceCatalog, serviceExecution, clientAssetRegistry, catalogStudio, block, billing, plan, planVersion, productConfig, productMasterdata, masterdata, resources, knowledgeTree, eventStatusConfig, integration, invitation, jtd, firebase, storage, paymentGateway, onboarding, taxSettings, system.
Services (~45): contractService, contractEventService, serviceCatalogService (+GraphQL), serviceExecutionService, clientAssetRegistryService, catalog (catBlocksService, catTemplatesService, catalogValidationService, complianceTaggerService, ktCatBlockMapperService, knowledgeTreeGeneratorService, overlaysGeneratorService), groups, contact, tenantAccount/Context/Profile, billing, paymentGateway, taxSettings, masterData, productConfig/Masterdata, resource(s), integration, onboarding, audit, storage, businessModel, eventStatusConfig, tenantForms, adminForms, adminTenant, adminJtd/jtd, blockService, plus channel services (email.service, sms.service, whatsapp.service), and seed services (seedSampleContactsService, seedTenantOnIndustryConfirmedService).
3. Frontend — contractnest-ui (React/Vite)
Totals: 892 .ts/.tsx files · ~337,375 LOC · App.tsx declares 188 <Route> elements.

Page-level components (routes)
~76 page files across: auth/ (Login, Register, InvitationRegister, ForgotPassword, ResetPassword, GoogleCallback, CreateTenant, SelectTenant) · Dashboard.tsx · contacts/ · contracts/ · catalog/ · catalog-studio/ (blocks, configure, template, templates-list) · onboarding/ · settings/ · welcome/ · appointments/ · entity-registry/ · equipment-registry/ · admin/ (incl. smart-forms/) · templates/ · ops/ · public/ (LandingPage, VikunaHome, roicalculator, aimaturity, dtreadiness, resources, Playground) · misc/ (NotFound, Error, Maintenance, Unauthorized, NoInternet, SessionConflict, ApiServerDown, BrowserNotSupported, ComingSoon) · vani/pages/ (24 — VaNi sub-app: Jobs, Templates, Channels [WhatsApp/Website/ChatBot], Analytics, AccountsReceivable, BusinessEvents, ProcessRules, ServiceSchedule, Webhooks, Chat, Dashboard).

Several *copy.tsx / numbered duplicates present (view copy.tsx, indexa.tsx, 2create.tsx, useResources1.ts, useServiceCatalogQueries1.ts).

Major shared components
ui/ (37 primitives): Button, Input, Select, Dialog, Table, Tabs, Toast/Toaster/use-toast, Alert, Avatar, Badge, Card, Checkbox, DatePicker, RichTextEditor, LoadingSpinner, ConfirmationDialog, accordion, popover, dropdown-menu, command, scroll-area, etc.
common/: FileUploader, ContactPicker, ThemeSwitcher, ExplainerDrawer, BrowserWarningBanner, ComingSoonWrapper + cards/, loaders/, skeletons/, toast/.
layout/: DashboardLayout, MainLayout, Header, Navbar, Sidebar, TenantSwitcher.
shared/: TabsNavigation. Plus feature dirs: contracts, contacts, catalog, catalog-studio, businessmodel, billing, subscription, onboarding, integrations, service-contracts, services, storage, tenantprofile, users, dashboard, VaNi, TaxSettings, Resources, Analytics, SEO, CRO, ABTest, Performance.
State — Contexts / Providers (no Zustand)
No Zustand stores found. State = React Context + React Query:

Contexts: AuthContext · TenantContext · ThemeContext · MasterDataContext · ContractBuilderContext · ABTestContext · ContextEngine · OnboardingContext · FormEditorContext (admin smart-forms) · model TenantContext.ts. (Plus AuthContextbak.tsx backup.)
Provider: providers/QueryProvider.tsx (React Query). Route tracker: routes/AnalyticsRouteTracker.tsx.
API hooks (React Query)
hooks/queries/ (33): useContractQueries, useContractEventQueries, useServiceCatalogQueries (+1), useBusinessModelQueries, useInvoiceQueries, usePaymentGatewayQueries, useGroupQueries, useResourceQueries, useMasterDataQueries, useEventStatusConfigQueries, useRelationshipQueries, useAssetRegistry, useClientAssetRegistry, useCatBlocks(+Test), useCatTemplates, useBlockTypes, useKnowledgeTree, useOnboarding, useProductMasterdata, useProductsQuery, useServiceExecution, useServices, useServedIndustries, useTemplates/useTemplateCoverage, useNomenclatureTypes, useContactCockpit, useContactsResource, useResources, useResourceTemplates, useTenantContextMaster.
hooks/mutations/ (4): useServiceCatalogMutations, useBulkServiceCatalogMutations, useCatBlocksMutations, useCatTemplatesMutations.
hooks/ root (32): useContacts, useUsers, useBusinessModel, useCatalogItems, useIntegrations, useInvitations, useMasterData, useProductConfig, useResources(+1), useStorageManagement, useTaxRates/useTaxDisplay, useTenantProfile, useTemplateDesigner, useVersionControl, useRazorpayCheckout, useGatewayStatus, useContractHealth/useContractRole, useNeedsAttention, useMaintenanceMode, useSessionConflict, useIdleTimer, useNetworkStatus, useWindowSize, useAnalytics, useSEO, useStructuredData, useCRO, usePerformance. Plus hooks/service-contracts/{blocks,templates} and vani/hooks/useVaNiData.ts.
Adoption: useQuery in 41 files, useMutation in 24 files.
4. Database Layer — Supabase
Migrations (ordered)
contractnest-edge/supabase/migrations/ — 119 .sql total, organized by domain folder:
Folder	#	Range / notes
contracts/	66	002→060 (contract RPCs, invoices/receipts, payment gateway, events, service tickets, evidence, audit log, nomenclature, asset registry, equipment, buyer/seller access, CNAK claim, portfolio views) — incl. several _DOWN rollbacks
jtd-framework/	9	000_cleanup→007 (JTD master tables, seeds, pgmq setup, RLS, message templates)
catalog-studio/	7	cat_blocks, cat_templates, idempotency_keys, seed logs, kt linkage
sequence-numbers/	7	counters, seeds, contact-number trigger
business-model-v2/	5	005→009 (phase-2 RPCs, tenant_context, product config + seeds)
onboarding/	5	003→007 (seed columns, RLS JWT tenant check, facility node seed RPC)
templates/	4	CRUD RPC, copy, versioning, rename m→t
smart-forms/	3	tables, m_form rename, RPC functions
p05a-industry-hierarchy/	3 (+3 nested duplicate)	industry hierarchy alter/seed
admin-jtd-management/	2 · admin-tenant-management/	2
global-templates/	1	rename cat tables
root of migrations/	2	20250501…add_compliance_fields, 20260510…kt_catalog_agent_fields
contractnest-api/src/migrations/ — 4: 001_create_m_products, 002_create_t_tenant_served_industries, 003_seed_le_hvac_resource_templates, 004_create_m_facility_hierarchy_templates.
supabase/migrations/ (root) — 1: 20251229170144_remote_schema.sql (full remote snapshot).
Edge Functions (contractnest-edge/supabase/functions/)
50 function directories · 51 index.ts · 115 .ts total. Functions:
auth · create-google · onboarding · tenants · tenant-account · tenant-context · tenant-profile · tenant-storage · user-management · user-invitations · contacts · groups · group-discovery · business-groups · contracts · contract-events · service-catalog · service-execution · service-tickets · service-evidence · client-asset-registry · cat-blocks · cat-templates · blocks · catalog (smart-forms) · knowledge-tree · plans · plan-versions · product-config · product-masterdata · products · resources · sequences · masterdata · event-status-config · tax-settings · billing · payment-gateway · payment-webhook · integrations · audit-log · jtd-worker · admin-jtd-management · admin-tenant-management · firebase-diagnostic · lead · smart-forms · FKauth · FKonboarding · _shared · utils.

Other SQL assets: RPC/ (catalog, contacts), Tables/ (schema.sql + contacts), scripts/ (8 seed *_rows.sql), Tables/schema.sql.
RLS policies
No separate RLS folder — policies are inline in migrations (CREATE POLICY / ENABLE ROW LEVEL SECURITY found in 22 migration files), notably jtd-framework/004_rls_policies.sql, onboarding/005_rls_jwt_tenant_check.sql, contracts/045_buyer_rls_and_invoice_cancel_writeoff.sql, plus table-creation migrations across contracts, catalog-studio, smart-forms, sequence-numbers, industry-hierarchy. Pattern reference exists at scripts/reference/patterns-rls.md.

5. Submodules — Status
Submodule	Pinned commit	Branch/tag described	Status
contractnest-api	8b12f75	stable-after-p1-20260214-21-g8b12f75	Active, detached at pinned tag baseline
contractnest-ui	f97d8e2	stable-after-p1-20260214-46-gf97d8e2	Active, detached at pinned tag baseline
contractnest-edge	c3dbf9e	stable-after-p1-20260214-36-gc3dbf9e	Active, detached at pinned tag baseline
ContractNest-Mobile	2bfc9e8	stable-after-p1-20260214	Active (lighter, 76 files), detached at tag
FamilyKnows	00f440f	stable-after-p1-20260214	Active, separate product (app + website)
ClaudeDocumentation	d32d5aa	stable-after-p1-20260214-21-gd32d5aa	Active docs (263 files)
Observations (state only): All 6 were uninitialized in the freshly-cloned parent (- status) and required git submodule update --init. Each is pinned by the parent to a detached commit on a stable-after-p1-20260214* baseline tag rather than tracking a branch tip — i.e., a frozen "post-Phase-1" snapshot. None are stale-unfetchable; all clone and check out cleanly.

Headline counts
Layer	Files	~LOC
Backend API (.ts)	204	74,196
Frontend (.ts/.tsx)	892	337,375
Edge functions (.ts)	115	—
Edge dirs	50	—
SQL migrations (edge + api + root)	119 + 4 + 1 = 124	—
API routes / controllers / services / middleware	37 / 32 / ~45 / 13	—
UI pages / contexts / query+mutation hooks	~76 / 10 / 69	—
Submodules	6 (all active, pinned)	—
Inventory complete — no analysis or recommendations included, per scope.