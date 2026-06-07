import { useState } from "react";

// ─── ALL DATA FROM CLAUDE CODE AUDIT (P1–P6) ───────────────────────────────

const REAL = {
  meta: {
    auditor: "Claude Code",
    date: "2026-05-29",
    repo: "kamalcharan/contractnest-combined",
    overallScore: 4.5,
    verdict: "Strong bones — unsafe enforcement — untested — not yet autonomous"
  },

  healthScores: [
    { dim: "Code Organisation",      score: 7, note: "Clean submodule+layered structure but littered with duplicates: storage copy.ts, AuthContextbak.tsx, *copy.tsx, nested smart-forms/smart-forms" },
    { dim: "Data Model Integrity",   score: 5, note: "~170 FKs solid, but 3 RLS mechanisms, JSONB ID-bags without FKs, duplicate tables (2 audit, 2 idempotency), a stray backup table with no PK" },
    { dim: "Feature Completeness",   score: 6, note: "M1 Auth & M7 JTD strong; M5 catalog empty (0 rows), m_form_template_mappings dead, lead-capture writes to non-existent tables" },
    { dim: "AI / Agent Readiness",   score: 4, note: "Claude generation + pgvector + n8n work, but no provider abstraction, no tool registry, no agent loop, embedding model off-repo" },
    { dim: "Multi-Tenant Isolation", score: 3, note: "service_role bypasses RLS; GUC never set; dormant policies; tenant tables with RLS off. DB enforces nothing" },
    { dim: "Test Coverage",          score: 1, note: "Zero test files in API, UI, or edge. Test script in package.json but no tests" },
    { dim: "Deployment Readiness",   score: 4, note: "Dockerfiles + docker-compose present for API/UI, but no CI (.github/workflows not found), schema dump is 5 months stale" },
  ],

  inventory: {
    backendFiles: 204,
    backendLOC: 74196,
    frontendFiles: 892,
    frontendLOC: 337375,
    edgeFunctions: 50,
    sqlMigrations: 124,
    apiEndpoints: 210,
    liveDBTables: 137,
    submodules: 6,
    routes: 37,
    controllers: 32,
    services: 45,
    uiRoutes: 188,
    uiPages: 76,
    queryHooks: 69,
    skills: 13,
  },

  modules: [
    {
      id: "M1", name: "Multi-Tenant Auth & Onboarding",
      verdict: "green", verifyStatus: "🟢",
      currentState: "Built & Wired End-to-End",
      evidence: [
        "routes/auth.ts — login/register/refresh/signout/google*",
        "routes/onboardingRoutes.ts — 6 steps: initialize/status/step/complete/progress",
        "initialize_tenant_onboarding + seedTenantOnIndustryConfirmedService confirmed live",
        "t_onboarding_step_status: 570 rows (active usage)"
      ],
      gap: "Minor: stale AuthContextbak.tsx duplicate. No blocking issues.",
      agentImpact: "low"
    },
    {
      id: "M2", name: "Global Template Designer",
      verdict: "yellow", verifyStatus: "🟡",
      currentState: "Functional but hardcoded provider",
      evidence: [
        "routes/catalogStudioRoutes.ts (240 lines — full block/template CRUD)",
        "knowledgeTreeGeneratorService.ts — real Anthropic Claude calls confirmed",
        "13 prompt skills in src/skills/*.md (kt-equipment-generator, kt-variants-generator, etc.)",
        "m_cat_blocks: 45 rows; t_cat_templates: 2 rows",
        "test→live gate via promote_catalog_test_to_live RPC ✅"
      ],
      gap: "🔴 ACTIVE_AI_PROVIDER flag does not exist. Hardcoded to claude-sonnet-4-6 in 3 services. Table rename inconsistency: m_cat_templates renamed to t_cat_templates (tenant-prefix on a global table).",
      agentImpact: "high"
    },
    {
      id: "M3", name: "Smart Forms / Knowledge Tree",
      verdict: "yellow", verifyStatus: "🟡",
      currentState: "Designer + Renderer built; mapping table dead",
      evidence: [
        "routes/adminFormsRoutes.ts (458 lines), routes/tenantFormsRoutes.ts (166 lines)",
        "Admin editor: FieldPalette + MonacoSchemaEditor + LiveFormPreview confirmed",
        "Checklist block type: full wizard at components/catalog-studio/BlockWizard/steps/checklist/* ✅",
        "KT generators: /generate-variants, /generate-checkpoints, /generate-spare-parts wired"
      ],
      gap: "⚠️ m_form_template_mappings is dead infrastructure — table exists with FK from m_form_submissions.mapping_id but referenced NOWHERE in API, UI, or edge. The form-template→resource/variant mapping is unimplemented. Duplicate admin tree (pages/admin/smart-forms/smart-forms/ — nested copy of itself).",
      agentImpact: "high"
    },
    {
      id: "M4", name: "Contract Journey (8-step)",
      verdict: "yellow", verifyStatus: "🟡",
      currentState: "Full seller→buyer path exists; fragile state machine",
      evidence: [
        "routes/contractRoutes.ts (338 lines — create/get/list/update/status/delete)",
        "create_contract_transaction RPC — auto-materializes t_contract_events on acceptance",
        "claim_contract_by_cnak, respond_to_contract RPCs ✅",
        "t_contracts: 16 rows live"
      ],
      gap: "⚠️ Contract status values case-inconsistent in RPCs ('active'/'draft'/'expired' vs 'Cancelled'/'Completed'). ⚠️ RLS GUC app.current_tenant_id never set — isolation relies entirely on service_role bypass. Calendar computed in React wizard, not backend — if contract created via API/agent, no events generated.",
      agentImpact: "critical"
    },
    {
      id: "M5", name: "Service Catalog",
      verdict: "yellow", verifyStatus: "🟡",
      currentState: "Schema + versioning built; catalog superseded by catalog-studio",
      evidence: [
        "routes/serviceCatalogRoutes.ts (446 lines)",
        "create_catalog_item_version RPC + parent_id self-FK for versioning ✅",
        "calculate_tiered_price RPC present"
      ],
      gap: "🔴 t_catalog_items has 0 rows — catalog superseded by catalog-studio block model (m_cat_blocks). variant_pricing JSONB lives on m_cat_blocks, not on t_catalog_items as spec intended. Multi-currency = single currency VARCHAR(3) DEFAULT 'INR' — no FX logic.",
      agentImpact: "medium"
    },
    {
      id: "M6", name: "BBB Directory Bot",
      verdict: "yellow", verifyStatus: "🟡",
      currentState: "Infra complete; RLS disabled on core tables",
      evidence: [
        "pgvector installed ✅; vector columns on t_group_memberships, t_semantic_clusters, t_tenant_smartprofiles, t_query_cache",
        "MSG91 WhatsApp service confirmed (whatsapp.service.ts → control.msg91.com)",
        "n8n config (VaNiN8NConfig.ts) confirmed",
        "RPCs: vector_search_members, smartprofile_vector_search, smartprofile_unified_search ✅",
        "t_group_memberships: 61 rows; t_semantic_clusters: ~177 rows"
      ],
      gap: "🔴 t_business_groups and t_group_memberships have RLS DISABLED while carrying tenant data + dormant policies (4 and 5 respectively). Embedding model is OPAQUE — embeddings generated by external n8n webhook, model/version not in repo (dimension+model can drift outside source control). Only 2 groups / 61 memberships = early stage.",
      agentImpact: "high"
    },
    {
      id: "M7", name: "JTD Notification System",
      verdict: "green", verifyStatus: "🟢",
      currentState: "Built end-to-end; pipeline not yet exercised",
      evidence: [
        "PGMQ: pgmq.q_jtd_queue + pgmq.q_jtd_dlq live (confirmed)",
        "pg_cron: jtd-worker-cron every minute (confirmed — note: duplicated as jobid 1 & 3 ⚠️)",
        "JTD catalog seeded: service_reminder, payment_due, payment_overdue, appointment_reminder",
        "Admin UI: QueueMonitorPage, WorkerHealthPage, EventExplorerPage, TenantOperationsPage",
        "jtd-worker edge function confirmed"
      ],
      gap: "⚠️ n_jtd has 0 rows — pipeline built but never exercised. ⚠️ Duplicate cron job (jobid 1 & 3 both drain queue). ⚠️ JTD uses Gupshup+SendGrid webhooks; BBB bot uses MSG91 — two different WhatsApp providers platform-wide.",
      agentImpact: "medium"
    },
    {
      id: "M8", name: "Client Asset Registry",
      verdict: "yellow", verifyStatus: "🟡",
      currentState: "Built + contract-linked; divergent RLS isolation",
      evidence: [
        "routes/clientAssetRegistryRoutes.ts — CRUD + /children + /contract-assets",
        "t_client_asset_registry: 30 rows; linked via t_contract_assets",
        "Service-history FK: t_service_tickets.asset_id + t_service_evidence.asset_id",
        "pages/equipment-registry/index.tsx + pages/entity-registry/index.tsx"
      ],
      gap: "🔴 Asset tables use app.tenant_id GUC (not app.current_tenant_id like the rest of contracts). GUC never set → silent total denial under any non-service_role connection. ⚠️ Two parallel implementations: assetRegistryService + useAssetRegistry vs clientAssetRegistryService + useClientAssetRegistry — UI uses former, leaving latter pair partly orphaned.",
      agentImpact: "high"
    },
  ],

  rlsFindings: {
    mechanisms: [
      { name: "app.current_tenant_id GUC",    count: 25,  tables: "t_contracts, t_contract_blocks, t_contract_attachments, t_contract_vendors, t_contract_history, t_sequence_counters, t_tenant_industry_segments" },
      { name: "app.tenant_id GUC 🔴 DIVERGENT", count: 3,  tables: "t_client_asset_registry, t_contract_assets, t_tenant_asset_registry" },
      { name: "request.jwt.claims",             count: 20,  tables: "t_catalog_*, t_equipment, t_custom_*, t_form_templates, m_form_*" },
      { name: "EXISTS subquery on t_user_tenants", count: 120, tables: "Most remaining t_* tables" },
    ],
    gucSetCount: 0,
    serviceRoleAPIFiles: 10,
    serviceRoleEdgeFiles: 54,
    dormantPolicyTables: ["t_business_groups","t_group_memberships","t_category_master","t_category_details","t_category_resources_master","leads","leads_contractnest"],
    alwaysTruePolicies: 15,
    denyAllTables: ["kt_compliance_defaults","kt_equipment_meta","t_seed_logs"],
    jsonbIDHazards: [
      { table: "t_contracts.selected_tax_rate_ids", target: "t_tax_rates", risk: "high" },
      { table: "t_invoices.block_ids", target: "t_contract_blocks", risk: "high" },
      { table: "t_contracts.evidence_selected_forms", target: "form templates", risk: "medium" },
      { table: "m_cat_blocks.knowledge_tree_ref", target: "KT snapshot", risk: "medium" },
    ]
  },

  serviceAsSoftware: {
    autonomyScore: 3,
    autonomyTotal: 8,
    capabilities: [
      { cap: "New tenant onboarding",         status: "automated", note: "initialize_tenant_onboarding + seedTenantOnIndustryConfirmedService auto-provision on 6-step wizard" },
      { cap: "Contract creation from template", status: "manual",    note: "Human-driven ContractWizard; calendar computed client-side, then send" },
      { cap: "Service event scheduling",       status: "automated", note: "Events bulk-materialized on acceptance via process_contract_events_from_computed" },
      { cap: "Field form dispatch",            status: "missing",   note: "No event→form routing; m_form_template_mappings dead/unreferenced" },
      { cap: "Service completion capture",     status: "manual",    note: "create_service_ticket via user action only — never auto-spawned" },
      { cap: "Invoice generation trigger",     status: "automated", note: "generate_contract_invoices auto-called at contract creation (auto-accept)" },
      { cap: "Renewal alert",                  status: "missing",   note: "ServiceRenewalCard.tsx is a stub with hardcoded mock data (its own comment says: 'would come from API')" },
      { cap: "Contract renewal",               status: "missing",   note: "No renewal RPC, endpoint, or wired UI found anywhere in codebase" },
    ],
    breakpoint: "Between commitment storage and commitment action. t_contract_events ledger is populated. PGMQ + minute-worker + notification vocabulary all exist. What's missing: one pg_cron scanner that reads t_contract_events WHERE scheduled_date <= now() AND status='scheduled' and (a) enqueues JTD, (b) transitions status, (c) spawns service ticket, (d) dispatches SmartForm.",
    cronJobsLive: [
      { name: "jtd-worker-cron", schedule: "every minute", job: "Drains JTD queue (⚠️ duplicated: jobid 1 & 3)" },
      { name: "cleanup-tool-results", schedule: "hourly", job: "GC" },
      { name: "expire-no-credits-jtds", schedule: "daily 02:00", job: "JTD housekeeping" },
      { name: "auto-expire-contracts-nightly", schedule: "daily 18:29", job: "Flips active→expired" },
    ]
  },

  gaps: [
    {
      n: "GAP 1", title: "Tenant Isolation Is Not DB-Enforced",
      severity: "critical",
      current: "service_role bypass in 10 API + 54 edge files. 3 RLS mechanisms. GUC (set_config) called ZERO times. 7 tables with dormant policies. 15 always-true policies.",
      build: "Unify all policies on one mechanism (JWT claims preferred). Set tenant GUC in middleware/tenantContext.ts + edge _shared. Enable RLS on 7 dormant tables. Fix contracts/037 divergence (app.tenant_id → app.current_tenant_id).",
      complexity: "L",
      blocker: true
    },
    {
      n: "GAP 2", title: "Service-as-Software Loop Is Open",
      severity: "high",
      current: "Commitment ledger (t_contract_events), PGMQ queue, minute-worker, and seeded JTD reminder types all exist. NOTHING connects them. No cron scans scheduled_date. 'Overdue' computed at read-time only.",
      build: "pg_cron scan_due_contract_events(): t_contract_events WHERE scheduled_date <= now()+window AND status='scheduled' → enqueue JTD, transition status, spawn create_service_ticket, dispatch mapped SmartForm. Sibling job watching t_contracts.end_date for renewal alerts.",
      complexity: "M",
      blocker: true
    },
    {
      n: "GAP 3", title: "No LLM Provider Abstraction or Agent Orchestration",
      severity: "high",
      current: "Hardcoded Anthropic in 3 services + n8n black box for embeddings/chat. No ACTIVE_AI_PROVIDER. No tool registry (src/skills/ = prompt templates only). No autonomous loop — KT generation is UI-sequenced. t_tool_results/t_intent_definitions are unused scaffolding.",
      build: "ACTIVE_AI_PROVIDER router module (Claude/OpenAI/local + fallback/streaming). Real tool registry backed by t_tool_results. PGMQ-driven plan→act→observe executor for AI tasks. Pull embedding model in-repo with pinned version.",
      complexity: "XL",
      blocker: false
    },
    {
      n: "GAP 4", title: "Zero Tests + No CI on Enforcement-Critical System",
      severity: "high",
      current: "Zero test files across all submodules (API/UI/edge). Test script in package.json exists but no tests. No .github/workflows found. Schema dump 5 months stale.",
      build: "Vitest (UI) + Jest (API) harness. RLS cross-tenant isolation test suite (cross-tenant read/write must fail). Contract-transaction integration tests. GitHub Actions CI pipeline.",
      complexity: "L",
      blocker: false
    },
  ],

  weekPlan: [
    { week: 1, title: "Stop the bleeding", gap: "correctness", tasks: ["Fix services/public-leads.service.ts → point to leads/leads_contractnest (silent data loss now)", "Remove duplicate jtd-worker cron (jobid 3)", "Remove stray t_contacts_classification_backup_20260128 (no PK, RLS off)", "Refresh supabase/migrations/20251229170144_remote_schema.sql (5 months stale)"] },
    { week: 2, title: "Tenant isolation phase 1", gap: "GAP 1", tasks: ["Add set_config in middleware/tenantContext.ts and edge _shared", "Converge contracts/037 asset policies onto app.current_tenant_id", "Enable RLS on 7 dormant-policy tables (t_business_groups, t_group_memberships, etc.)"] },
    { week: 3, title: "Tests + CI foundation", gap: "GAP 4", tasks: ["Stand up Jest (API) + Vitest (UI)", "Write RLS cross-tenant isolation test suite", "Write create_contract_transaction integration test", "Add .github/workflows/ci.yml"] },
    { week: 4, title: "Close the service loop part 1", gap: "GAP 2", tasks: ["Build pg_cron scan_due_contract_events(): transition scheduled→overdue/due", "Enqueue service_reminder/payment_due JTDs from due events", "Verify via JTD WorkerHealthPage admin UI"] },
    { week: 5, title: "Close the service loop part 2", gap: "GAP 2", tasks: ["Wire m_form_template_mappings so a due service event auto-creates t_service_tickets row", "Dispatch mapped SmartForm (FormRenderer.tsx) to assignee", "Replace mock ServiceRenewalCard.tsx comment with live renewal alert cron"] },
    { week: 6, title: "Renewal workflow", gap: "GAP 2/3", tasks: ["Add renewal_alert cron on t_contracts.end_date - N days", "Build renewal_from_expiring_contract RPC", "Replace mock ServiceRenewalCard.tsx with live data"] },
    { week: 7, title: "LLM provider abstraction", gap: "GAP 3", tasks: ["Introduce ACTIVE_AI_PROVIDER router module", "Refactor knowledgeTreeGeneratorService / overlaysGeneratorService / complianceTaggerService behind it", "Add fallback + streaming support"] },
    { week: 8, title: "Agent scaffolding", gap: "GAP 3", tasks: ["Turn t_tool_results/t_intent_definitions into a live tool registry + execution ledger", "Build minimal PGMQ-driven plan→act→observe loop for one use case (e.g., autonomous renewal)", "Pin embedding model version in-repo"] },
  ],

  advisorStats: { errors: 47, warnings: 667, info: 3, securityDefinerFuncs: 416, mutableSearchPathFuncs: 232 }
};

// ─── COMPONENTS ─────────────────────────────────────────────────────────────

const C = {
  red: "#ef4444", yellow: "#f59e0b", green: "#22c55e",
  blue: "#38bdf8", purple: "#a5b4fc", dim: "#64748b",
  bg: "#070b14", bg2: "#0c1220", bg3: "#101828",
  border: "#1a2540", text: "#e2e8f0", muted: "#94a3b8"
};

const severityColor = { critical: C.red, high: C.yellow, medium: C.blue, low: C.green };
const complexityColor = { S: C.green, M: C.yellow, L: C.yellow, XL: C.red };
const verdictColor = { green: C.green, yellow: C.yellow, red: C.red };
const statusColor = { automated: C.green, manual: C.yellow, missing: C.red };
const statusLabel = { automated: "🟢 AUTOMATED", manual: "🟡 MANUAL", missing: "🔴 MISSING" };

function ScoreBar({ score }) {
  const pct = (score / 10) * 100;
  const col = score >= 7 ? C.green : score >= 5 ? C.yellow : C.red;
  return (
    <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
      <div style={{ flex: 1, height: 6, background: "#1a2540", borderRadius: 3, overflow: "hidden" }}>
        <div style={{ width: `${pct}%`, height: "100%", background: col, borderRadius: 3, transition: "width 0.6s ease" }} />
      </div>
      <span style={{ fontSize: 13, fontWeight: 700, color: col, minWidth: 24 }}>{score}</span>
    </div>
  );
}

function Tag({ children, color, bg }) {
  return (
    <span style={{ fontSize: 10, padding: "2px 8px", borderRadius: 20, color, background: bg || `${color}15`, border: `1px solid ${color}30`, letterSpacing: "0.08em", textTransform: "uppercase", fontWeight: 600 }}>
      {children}
    </span>
  );
}

function Section({ title, color = C.purple, children }) {
  return (
    <div style={{ marginBottom: 32 }}>
      <div style={{ display: "flex", alignItems: "center", gap: 10, marginBottom: 16 }}>
        <div style={{ width: 3, height: 18, background: color, borderRadius: 2 }} />
        <span style={{ fontSize: 11, letterSpacing: "0.25em", color, textTransform: "uppercase", fontWeight: 700 }}>{title}</span>
      </div>
      {children}
    </div>
  );
}

// ─── TABS ───────────────────────────────────────────────────────────────────

function TabOverview() {
  const inv = REAL.inventory;
  return (
    <div>
      {/* Verdict Banner */}
      <div style={{ background: "linear-gradient(135deg, #0f1a2e, #1a0f2e)", border: `1px solid ${C.border}`, borderLeft: `4px solid ${C.yellow}`, borderRadius: 10, padding: 20, marginBottom: 28 }}>
        <div style={{ fontSize: 11, color: C.yellow, letterSpacing: "0.2em", textTransform: "uppercase", marginBottom: 6 }}>Claude Code — Architect Verdict</div>
        <div style={{ fontSize: 15, color: C.text, lineHeight: 1.7 }}>
          <span style={{ color: C.yellow, fontWeight: 700 }}>~75% built scaffolding awaiting connecting logic</span>, not a finished system. The async + commitment backbone (PGMQ + pg_cron + t_contract_events + ~170 FKs) is genuinely built and only needs to be driven. The single biggest gap: <span style={{ color: C.red, fontWeight: 700 }}>tenant isolation — the database enforces nothing</span> (service_role bypasses RLS; GUC never set; 3 inconsistent mechanisms). The single biggest strength: the entire service-delivery plumbing exists — it just has no scheduler watching it.
        </div>
      </div>

      {/* Score Grid */}
      <Section title="Codebase Health Scores">
        <div style={{ background: C.bg2, border: `1px solid ${C.border}`, borderRadius: 10, padding: 20 }}>
          <div style={{ display: "flex", justifyContent: "center", marginBottom: 20 }}>
            <div style={{ textAlign: "center" }}>
              <div style={{ fontSize: 48, fontWeight: 800, color: C.yellow }}>4.5</div>
              <div style={{ fontSize: 11, color: C.dim, letterSpacing: "0.15em", textTransform: "uppercase" }}>Overall / 10</div>
            </div>
          </div>
          {REAL.healthScores.map(h => (
            <div key={h.dim} style={{ marginBottom: 14 }}>
              <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 5 }}>
                <span style={{ fontSize: 12, color: C.text }}>{h.dim}</span>
              </div>
              <ScoreBar score={h.score} />
              <div style={{ fontSize: 11, color: C.dim, marginTop: 4, lineHeight: 1.5 }}>{h.note}</div>
            </div>
          ))}
        </div>
      </Section>

      {/* Inventory Facts */}
      <Section title="What Claude Code Found — Inventory Facts">
        <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(140px, 1fr))", gap: 10 }}>
          {[
            { label: "Live DB Tables", value: inv.liveDBTables, color: C.purple },
            { label: "Backend LOC", value: inv.backendLOC.toLocaleString(), color: C.blue },
            { label: "Frontend LOC", value: inv.frontendLOC.toLocaleString(), color: C.blue },
            { label: "API Endpoints", value: `~${inv.apiEndpoints}`, color: C.green },
            { label: "Edge Functions", value: inv.edgeFunctions, color: C.green },
            { label: "SQL Migrations", value: inv.sqlMigrations, color: C.yellow },
            { label: "UI Routes", value: inv.uiRoutes, color: C.yellow },
            { label: "Query/Mutation Hooks", value: inv.queryHooks, color: C.muted },
            { label: "Prompt Skills", value: inv.skills, color: C.muted },
            { label: "Supabase Advisor ERRORs", value: REAL.advisorStats.errors, color: C.red },
            { label: "Supabase Advisor WARNs", value: REAL.advisorStats.warnings, color: C.yellow },
            { label: "SECURITY DEFINER Funcs", value: REAL.advisorStats.securityDefinerFuncs, color: C.red },
          ].map(s => (
            <div key={s.label} style={{ background: C.bg3, border: `1px solid ${C.border}`, borderRadius: 8, padding: "12px 14px", textAlign: "center" }}>
              <div style={{ fontSize: 20, fontWeight: 800, color: s.color }}>{s.value}</div>
              <div style={{ fontSize: 10, color: C.dim, letterSpacing: "0.08em", textTransform: "uppercase", marginTop: 3, lineHeight: 1.4 }}>{s.label}</div>
            </div>
          ))}
        </div>
      </Section>

      {/* The Real vs Estimate */}
      <Section title="Real Findings vs Prior Estimate" color={C.yellow}>
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 14 }}>
          <div style={{ background: C.bg2, border: `1px solid ${C.border}`, borderRadius: 8, padding: 16 }}>
            <div style={{ fontSize: 11, color: C.dim, marginBottom: 10, letterSpacing: "0.15em", textTransform: "uppercase" }}>What I estimated (claude.ai)</div>
            {[
              "85% ready — Lift-and-Shift Core",
              "3 gaps: RLS bug, KT→Forms wiring, template consolidation",
              "Agent orchestration layer is the new build",
              "Variant_pricing JSONB unused",
              "Checklist block type: 0 rows",
            ].map((t, i) => <div key={i} style={{ fontSize: 12, color: C.muted, marginBottom: 6, paddingLeft: 10, borderLeft: `2px solid ${C.dim}` }}>{t}</div>)}
          </div>
          <div style={{ background: C.bg2, border: `1px solid ${C.border}`, borderRadius: 8, padding: 16 }}>
            <div style={{ fontSize: 11, color: C.yellow, marginBottom: 10, letterSpacing: "0.15em", textTransform: "uppercase" }}>What Claude Code found (real)</div>
            {[
              "75% — lower because test coverage = 0 and RLS = decorative",
              "4 gaps — RLS is far worse (3 mechanisms, GUC=0 calls, service_role bypass in 64 files)",
              "Confirmed: agent loop missing, but PGMQ+worker+JTD catalog already exist",
              "Confirmed: variant_pricing on wrong table (m_cat_blocks not t_catalog_items)",
              "Confirmed: checklist block UI built; m_form_template_mappings dead/unreferenced",
            ].map((t, i) => <div key={i} style={{ fontSize: 12, color: C.text, marginBottom: 6, paddingLeft: 10, borderLeft: `2px solid ${C.yellow}` }}>{t}</div>)}
          </div>
        </div>
      </Section>
    </div>
  );
}

function TabModules() {
  const [open, setOpen] = useState(null);
  return (
    <div>
      <p style={{ color: C.dim, fontSize: 12, marginBottom: 20 }}>All verdicts from Claude Code static analysis + live DB queries. Click to expand evidence + gaps.</p>
      {REAL.modules.map(m => (
        <div key={m.id} onClick={() => setOpen(open === m.id ? null : m.id)} style={{
          background: open === m.id ? C.bg3 : C.bg2, border: `1px solid ${open === m.id ? verdictColor[m.verdict] + "60" : C.border}`,
          borderRadius: 10, marginBottom: 10, cursor: "pointer", overflow: "hidden", transition: "all 0.15s"
        }}>
          <div style={{ display: "flex", alignItems: "center", gap: 12, padding: "14px 18px" }}>
            <span style={{ fontSize: 11, color: C.dim, minWidth: 24 }}>{m.id}</span>
            <span style={{ fontSize: 13, color: C.text, fontWeight: 600, flex: 1 }}>{m.name}</span>
            <Tag color={verdictColor[m.verdict]}>{m.currentState.split(";")[0]}</Tag>
            <Tag color={m.agentImpact === "critical" ? C.red : m.agentImpact === "high" ? C.yellow : m.agentImpact === "medium" ? C.blue : C.dim}>
              Agent: {m.agentImpact}
            </Tag>
            <span style={{ color: C.dim, fontSize: 12 }}>{open === m.id ? "▲" : "▼"}</span>
          </div>
          {open === m.id && (
            <div style={{ padding: "0 18px 18px", borderTop: `1px solid ${C.border}` }}>
              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 16, marginTop: 16 }}>
                <div>
                  <div style={{ fontSize: 10, color: C.green, letterSpacing: "0.15em", textTransform: "uppercase", marginBottom: 8 }}>Evidence (from codebase)</div>
                  {m.evidence.map((e, i) => (
                    <div key={i} style={{ fontSize: 11, color: C.muted, marginBottom: 5, paddingLeft: 10, borderLeft: `2px solid ${C.green}40`, lineHeight: 1.5 }}>
                      <code style={{ color: "#7dd3fc", fontSize: 10 }}>{e}</code>
                    </div>
                  ))}
                </div>
                <div>
                  <div style={{ fontSize: 10, color: C.red, letterSpacing: "0.15em", textTransform: "uppercase", marginBottom: 8 }}>Gaps Found</div>
                  <div style={{ fontSize: 12, color: C.muted, lineHeight: 1.7, borderLeft: `2px solid ${C.red}40`, paddingLeft: 10 }}>
                    {m.gap}
                  </div>
                </div>
              </div>
            </div>
          )}
        </div>
      ))}
    </div>
  );
}

function TabRLS() {
  return (
    <div>
      <div style={{ background: `${C.red}10`, border: `1px solid ${C.red}30`, borderRadius: 10, padding: 20, marginBottom: 24 }}>
        <div style={{ fontSize: 13, fontWeight: 700, color: C.red, marginBottom: 8 }}>🔴 RLS Is Effectively Decorative</div>
        <div style={{ fontSize: 12, color: C.muted, lineHeight: 1.8 }}>
          The app connects as <code style={{ color: C.yellow }}>service_role</code> in <strong style={{ color: C.text }}>10 API files + 54 edge files</strong>, which bypasses RLS entirely. The tenant GUC (<code style={{ color: C.yellow }}>set_config / SET app.*</code>) is called <strong style={{ color: C.red }}>ZERO times</strong> across the entire codebase. Every GUC-based policy evaluates <code>tenant_id = NULL</code>, which would deny all rows — but it never fires because service_role skips it. Supabase advisor: <strong style={{ color: C.red }}>47 ERRORs · 667 WARNs</strong>.
        </div>
      </div>

      <Section title="3 Isolation Mechanisms — None DB-Enforced">
        {REAL.rlsFindings.mechanisms.map(m => (
          <div key={m.name} style={{ background: C.bg2, border: `1px solid ${C.border}`, borderRadius: 8, padding: 14, marginBottom: 10 }}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 6 }}>
              <code style={{ color: m.name.includes("DIVERGENT") ? C.red : C.blue, fontSize: 12 }}>{m.name}</code>
              <Tag color={C.dim}>{m.count} policies</Tag>
            </div>
            <div style={{ fontSize: 11, color: C.dim }}>{m.tables}</div>
          </div>
        ))}
      </Section>

      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 16 }}>
        <Section title="Dormant Policy Tables (RLS off, policies inert)">
          {REAL.rlsFindings.dormantPolicyTables.map(t => (
            <div key={t} style={{ padding: "6px 10px", background: `${C.red}08`, border: `1px solid ${C.red}20`, borderRadius: 6, marginBottom: 6 }}>
              <code style={{ color: C.red, fontSize: 11 }}>{t}</code>
            </div>
          ))}
        </Section>

        <Section title="JSONB ID-Bags Without FK (Agent Write Hazards)">
          {REAL.rlsFindings.jsonbIDHazards.map(h => (
            <div key={h.table} style={{ padding: "8px 10px", background: `${C.yellow}08`, border: `1px solid ${C.yellow}20`, borderRadius: 6, marginBottom: 6 }}>
              <code style={{ color: C.yellow, fontSize: 11, display: "block" }}>{h.table}</code>
              <span style={{ fontSize: 10, color: C.dim }}>→ {h.target}</span>
              <span style={{ float: "right" }}><Tag color={h.risk === "high" ? C.red : C.yellow}>{h.risk}</Tag></span>
            </div>
          ))}
        </Section>
      </div>

      <Section title="Live Cron Jobs (No Due-Event Scanner Exists)" color={C.yellow}>
        <div style={{ overflow: "auto" }}>
          <table style={{ width: "100%", borderCollapse: "collapse", fontSize: 12 }}>
            <thead>
              <tr style={{ borderBottom: `1px solid ${C.border}` }}>
                {["Job Name", "Schedule", "What It Does"].map(h => (
                  <th key={h} style={{ padding: "8px 12px", textAlign: "left", color: C.dim, fontSize: 10, letterSpacing: "0.12em", textTransform: "uppercase" }}>{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {REAL.serviceAsSoftware.cronJobsLive.map(j => (
                <tr key={j.name} style={{ borderBottom: `1px solid ${C.bg3}` }}>
                  <td style={{ padding: "9px 12px" }}><code style={{ color: C.blue, fontSize: 11 }}>{j.name}</code></td>
                  <td style={{ padding: "9px 12px", color: C.muted, fontSize: 11 }}>{j.schedule}</td>
                  <td style={{ padding: "9px 12px", color: C.dim, fontSize: 11 }}>{j.job}</td>
                </tr>
              ))}
              <tr style={{ background: `${C.red}08` }}>
                <td style={{ padding: "9px 12px" }}><code style={{ color: C.red, fontSize: 11 }}>scan_due_contract_events</code></td>
                <td style={{ padding: "9px 12px", color: C.red, fontSize: 11 }}>MISSING</td>
                <td style={{ padding: "9px 12px", color: C.red, fontSize: 11 }}>🔴 This is the missing heartbeat — reads t_contract_events WHERE scheduled_date &lt;= now() AND status='scheduled'</td>
              </tr>
            </tbody>
          </table>
        </div>
      </Section>
    </div>
  );
}

function TabSaaS() {
  const s = REAL.serviceAsSoftware;
  const automated = s.capabilities.filter(c => c.status === "automated").length;
  const manual = s.capabilities.filter(c => c.status === "manual").length;
  const missing = s.capabilities.filter(c => c.status === "missing").length;
  return (
    <div>
      <div style={{ display: "grid", gridTemplateColumns: "1fr 2fr", gap: 20, marginBottom: 28, alignItems: "start" }}>
        <div style={{ background: C.bg2, border: `1px solid ${C.border}`, borderRadius: 10, padding: 20, textAlign: "center" }}>
          <div style={{ fontSize: 11, color: C.dim, letterSpacing: "0.2em", textTransform: "uppercase", marginBottom: 12 }}>Tenant Autonomy Score</div>
          <div style={{ fontSize: 52, fontWeight: 900, color: C.yellow }}>{s.autonomyScore}<span style={{ fontSize: 24, color: C.dim }}>/{s.autonomyTotal}</span></div>
          <div style={{ fontSize: 12, color: C.dim, marginTop: 8 }}>steps automated</div>
          <div style={{ display: "flex", justifyContent: "center", gap: 12, marginTop: 16 }}>
            <div style={{ textAlign: "center" }}><div style={{ fontSize: 18, fontWeight: 700, color: C.green }}>{automated}</div><div style={{ fontSize: 10, color: C.dim }}>auto</div></div>
            <div style={{ textAlign: "center" }}><div style={{ fontSize: 18, fontWeight: 700, color: C.yellow }}>{manual}</div><div style={{ fontSize: 10, color: C.dim }}>manual</div></div>
            <div style={{ textAlign: "center" }}><div style={{ fontSize: 18, fontWeight: 700, color: C.red }}>{missing}</div><div style={{ fontSize: 10, color: C.dim }}>missing</div></div>
          </div>
        </div>
        <div style={{ background: `${C.yellow}08`, border: `1px solid ${C.yellow}25`, borderRadius: 10, padding: 20 }}>
          <div style={{ fontSize: 11, color: C.yellow, letterSpacing: "0.15em", textTransform: "uppercase", marginBottom: 10 }}>Where the loop breaks</div>
          <div style={{ fontSize: 12, color: C.muted, lineHeight: 1.8 }}>{s.breakpoint}</div>
        </div>
      </div>

      <Section title="8-Capability Autonomy Breakdown">
        {s.capabilities.map(c => (
          <div key={c.cap} style={{ display: "flex", alignItems: "flex-start", gap: 14, padding: "12px 16px", background: C.bg2, border: `1px solid ${C.border}`, borderRadius: 8, marginBottom: 8 }}>
            <div style={{ minWidth: 100 }}><Tag color={statusColor[c.status]}>{c.status}</Tag></div>
            <div>
              <div style={{ fontSize: 13, color: C.text, fontWeight: 600 }}>{c.cap}</div>
              <div style={{ fontSize: 11, color: C.dim, marginTop: 3, lineHeight: 1.6 }}>{c.note}</div>
            </div>
          </div>
        ))}
      </Section>
    </div>
  );
}

function TabGaps() {
  return (
    <div>
      {REAL.gaps.map(g => (
        <div key={g.n} style={{ background: C.bg2, border: `1px solid ${g.blocker ? severityColor[g.severity] + "50" : C.border}`, borderRadius: 12, padding: 22, marginBottom: 20 }}>
          <div style={{ display: "flex", alignItems: "center", gap: 12, marginBottom: 14, flexWrap: "wrap" }}>
            <span style={{ fontSize: 11, color: C.dim }}>{g.n}</span>
            <span style={{ fontSize: 14, fontWeight: 700, color: C.text, flex: 1 }}>{g.title}</span>
            <Tag color={severityColor[g.severity]}>{g.severity}</Tag>
            <Tag color={complexityColor[g.complexity]}>effort: {g.complexity}</Tag>
            {g.blocker && <Tag color={C.red} bg="#ef444422">blocks agentic</Tag>}
          </div>
          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 16 }}>
            <div>
              <div style={{ fontSize: 10, color: C.red, letterSpacing: "0.12em", textTransform: "uppercase", marginBottom: 8 }}>Current State (Evidence-Based)</div>
              <div style={{ fontSize: 12, color: C.dim, lineHeight: 1.7, borderLeft: `2px solid ${C.red}40`, paddingLeft: 10 }}>{g.current}</div>
            </div>
            <div>
              <div style={{ fontSize: 10, color: C.green, letterSpacing: "0.12em", textTransform: "uppercase", marginBottom: 8 }}>What to Build</div>
              <div style={{ fontSize: 12, color: C.muted, lineHeight: 1.7, borderLeft: `2px solid ${C.green}40`, paddingLeft: 10 }}>{g.build}</div>
            </div>
          </div>
        </div>
      ))}
    </div>
  );
}

function TabRoadmap() {
  return (
    <div>
      <p style={{ color: C.dim, fontSize: 12, marginBottom: 24 }}>8-week build sequence from P6 Final Report. Each week is concrete — files, tables, and components named.</p>
      {REAL.weekPlan.map(w => (
        <div key={w.week} style={{ display: "flex", gap: 16, marginBottom: 16 }}>
          <div style={{ display: "flex", flexDirection: "column", alignItems: "center" }}>
            <div style={{ width: 36, height: 36, borderRadius: "50%", background: w.week <= 2 ? C.red : w.week <= 4 ? C.yellow : C.purple, display: "flex", alignItems: "center", justifyContent: "center", fontSize: 12, fontWeight: 700, color: "#fff", flexShrink: 0 }}>W{w.week}</div>
            {w.week < 8 && <div style={{ width: 2, flex: 1, background: C.border, margin: "4px 0" }} />}
          </div>
          <div style={{ background: C.bg2, border: `1px solid ${C.border}`, borderRadius: 10, padding: 16, flex: 1, marginBottom: 4 }}>
            <div style={{ display: "flex", alignItems: "center", gap: 10, marginBottom: 10 }}>
              <span style={{ fontSize: 13, fontWeight: 700, color: C.text }}>{w.title}</span>
              <Tag color={C.dim}>{w.gap}</Tag>
            </div>
            {w.tasks.map((t, i) => (
              <div key={i} style={{ display: "flex", gap: 8, marginBottom: 6 }}>
                <span style={{ color: C.dim, fontSize: 11, marginTop: 1 }}>○</span>
                <span style={{ fontSize: 12, color: C.muted, lineHeight: 1.5 }}>
                  {t.includes("/") || t.includes(".ts") || t.includes(".sql") || t.includes("()") ? (
                    <code style={{ color: "#7dd3fc", fontSize: 11 }}>{t}</code>
                  ) : t}
                </span>
              </div>
            ))}
          </div>
        </div>
      ))}
    </div>
  );
}

// ─── MAIN APP ────────────────────────────────────────────────────────────────

const TABS = [
  { id: "overview",  label: "Overview"          },
  { id: "modules",   label: "8 Modules"         },
  { id: "rls",       label: "RLS / DB Safety"   },
  { id: "saas",      label: "SaaS² Readiness"   },
  { id: "gaps",      label: "4 Critical Gaps"   },
  { id: "roadmap",   label: "8-Week Roadmap"    },
];

export default function App() {
  const [tab, setTab] = useState("overview");
  return (
    <div style={{ fontFamily: "'JetBrains Mono', 'Courier New', monospace", background: C.bg, color: C.text, minHeight: "100vh" }}>

      {/* Header */}
      <div style={{ background: "linear-gradient(160deg, #0a1020, #140a28, #0a1830)", borderBottom: `1px solid ${C.border}`, padding: "28px 36px 20px" }}>
        <div style={{ display: "flex", alignItems: "flex-start", justifyContent: "space-between", flexWrap: "wrap", gap: 16 }}>
          <div>
            <div style={{ fontSize: 10, letterSpacing: "0.35em", color: C.purple, marginBottom: 6, textTransform: "uppercase" }}>
              Vikuna Technologies · Claude Code Audit · {REAL.meta.date}
            </div>
            <h1 style={{ fontSize: 26, fontWeight: 800, margin: 0, color: C.text, letterSpacing: "-0.02em" }}>ContractNest</h1>
            <div style={{ fontSize: 12, color: C.dim, marginTop: 4 }}>Real Codebase Audit — kamalcharan/contractnest-combined</div>
          </div>
          <div style={{ display: "flex", gap: 10, flexWrap: "wrap", alignItems: "center" }}>
            {[
              { label: "Overall", value: "4.5/10", color: C.yellow },
              { label: "Tables", value: "137", color: C.blue },
              { label: "Autonomy", value: "3/8", color: C.red },
              { label: "Tests", value: "0", color: C.red },
            ].map(s => (
              <div key={s.label} style={{ background: "rgba(20,30,50,0.8)", border: `1px solid ${C.border}`, borderRadius: 8, padding: "8px 14px", textAlign: "center" }}>
                <div style={{ fontSize: 16, fontWeight: 800, color: s.color }}>{s.value}</div>
                <div style={{ fontSize: 9, color: C.dim, letterSpacing: "0.12em", textTransform: "uppercase" }}>{s.label}</div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Tabs */}
      <div style={{ display: "flex", gap: 1, padding: "0 36px", background: "#08101e", borderBottom: `1px solid ${C.border}`, overflowX: "auto" }}>
        {TABS.map(t => (
          <button key={t.id} onClick={() => setTab(t.id)} style={{
            background: tab === t.id ? "rgba(99,102,241,0.1)" : "transparent",
            border: "none", borderBottom: tab === t.id ? `2px solid ${C.purple}` : "2px solid transparent",
            color: tab === t.id ? C.purple : C.dim,
            padding: "13px 18px", cursor: "pointer", fontSize: 11, letterSpacing: "0.1em",
            textTransform: "uppercase", whiteSpace: "nowrap", transition: "all 0.15s"
          }}>{t.label}</button>
        ))}
      </div>

      {/* Content */}
      <div style={{ padding: "28px 36px", maxWidth: 1100 }}>
        {tab === "overview" && <TabOverview />}
        {tab === "modules"  && <TabModules />}
        {tab === "rls"      && <TabRLS />}
        {tab === "saas"     && <TabSaaS />}
        {tab === "gaps"     && <TabGaps />}
        {tab === "roadmap"  && <TabRoadmap />}
      </div>
    </div>
  );
}