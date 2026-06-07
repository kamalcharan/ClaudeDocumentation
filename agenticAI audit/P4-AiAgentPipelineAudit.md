ContractNest — AI & Agentic Capabilities Audit
Top-line architecture: Two distinct AI subsystems.

Knowledge-Tree generation → direct Anthropic Claude calls from the Express API (3 services, hardcoded provider).
VaNi / BBB directory bot (embeddings, semantic clustering, conversational agent, AI search) → fully offloaded to an external n8n instance (n8n.srv1096269.hstgr.cloud). No LLM/embedding model runs in ContractNest's own code for this path — the API just POSTs to n8n webhooks.
1. LLM Call Inventory
File	Provider	Prompt purpose	ACTIVE_AI_PROVIDER?	Stream/Batch	Error handling / fallback
contractnest-api/src/services/knowledgeTreeGeneratorService.ts	Claude (Anthropic, claude-sonnet-4-6 via KT_LLM_MODEL; api.anthropic.com/v1/messages, anthropic-version: 2023-06-01, prompt-caching beta)	Generation — equipment/variants/spare-parts/checkpoints/service-cycles KT from a service activity	🔴 No (provider hardcoded; only the model is env-driven)	Batched (axios POST)	Yes — throws on missing key, logs API errors, throws on empty response. No provider/model fallback.
contractnest-api/src/services/overlaysGeneratorService.ts	Claude (same config)	Generation — context overlays for resource templates	🔴 No	Batched	Yes — throws on missing key/errors. No fallback.
contractnest-api/src/services/complianceTaggerService.ts	Claude (same config)	Classification — compliance tagging of KT nodes	🔴 No	Batched	Yes — throws on missing key/errors. No fallback.
contractnest-api/src/services/groupsService.ts	n8n (opaque) — axios.post to n8n webhooks GENERATE_EMBEDDING, PROCESS_PROFILE, GENERATE_SEMANTIC_CLUSTERS, AI_SEARCH, AI_AGENT (config/VaNiN8NConfig.ts)	Embedding gen / profile enrichment / clustering / chat agent / search	🔴 No (n8n env test/production, not provider)	Batched (30s timeout)	Yes — try/catch + timeouts; degrades to non-AI path if trigger_embedding fails.
contractnest-edge/supabase/functions/group-discovery/handlers/search.ts	None directly — consumes an embedding passed in from n8n (body.params.embedding) and runs pgvector search	Semantic retrieval	n/a	Batched	Yes (validates embedding presence)
contractnest-api/src/skills/*.md (13 files)	Prompt templates for the Claude services (kt-equipment-generator, kt-variants-generator, kt-checkpoints-generator, kt-spare-parts-generator, kt-service-cycles-generator, kt-service-names-generator, kt-pricing-generator, kt-overlays-generator, kt-compliance-tagger, kt-activity-generator, kt-facility-*)	System prompts	n/a	n/a	n/a
Findings:

⚠️ No ACTIVE_AI_PROVIDER flag exists anywhere. The spec's "LLM-agnostic" target is unmet: text generation is hardwired to Anthropic; reasoning/embeddings are hardwired to n8n.
⚠️ No streaming anywhere — every LLM interaction is a blocking batch POST.
⚠️ No cross-provider fallback / retry-with-different-model. A Claude or n8n outage hard-fails the feature.
2. Agent Pattern Audit
Context passed between multiple LLM calls? 🟡 Partially. knowledgeTreeGeneratorService runs a sequence of Claude calls (full KT, then per-activity via existingKT flag; then variants → spare-parts → checkpoints → service-cycles → overlays → compliance-tagging). But the sequence is driven externally — each step is its own endpoint in routes/knowledgeTreeRoutes.ts (/generate, /generate-variants, /generate-checkpoints, …) triggered by the UI, not by an autonomous in-process orchestrator. There is no agent loop (no plan→act→observe→repeat).
Tool / skill registry? 🟡 Prompt-template registry only. knowledgeTreeGeneratorService.loadSkill(fileName, replacements) reads the 13 src/skills/*.md files and does {{TOKEN}} substitution. This is a prompt registry — not a function-calling / tool-use registry. ⚠️ No executable tools, no tool_use/function-calling schema sent to any model. t_tool_results and t_intent_definitions tables exist as scaffolding (RLS-off, t_tool_results flagged "Sensitive Columns Exposed"; t_intent_definitions referenced only minimally in functions/groups/index.ts).
Memory / conversation history? 🟡 Store exists, feedback is external. t_ai_agent_sessions (122 rows), t_chat_sessions, t_query_cache (semantic cache) persist sessions; chat flow chat/init → chat/intent → chat/session → ai-agent/message (groupsService.ts). But the actual conversational reasoning + history-into-prompt happens inside the n8n group-discovery-agent workflow — opaque to this repo.
Human-in-the-loop approval? 🟢 One real gate. Catalog-studio generates AI content into a test environment (is_live flag on cat_blocks/cat_templates, m_knowledge_tree_snapshots) and requires explicit promotion via promote_catalog_test_to_live / copy_catalog_live_to_test RPCs. AI output is not auto-published — a human promotes test→live. No approval gate exists on the VaNi chat-agent outputs.
3. Async Job Audit
PGMQ: 🟢 Yes. Queue created in jtd-framework/003_setup_pgmq.sql (pgmq.create('jtd_queue')). Live queues: pgmq.q_jtd_queue, pgmq.q_jtd_dlq, with archive tables pgmq.a_jtd_queue / pgmq.a_jtd_dlq (verified live).
Producers: trigger jtd_enqueue_on_insert and the credit-integration path pgmq.send('jtd_queue', …) in jtd-framework/003_jtd_credit_integration.sql:278; scheduled enqueue jtd_enqueue_scheduled.
Consumers: the jtd-worker edge function (functions/jtd-worker) via jtd_read_queue; DLQ tooling admin_list_dlq_messages / admin_requeue_dlq_message / admin_purge_dlq (routes/adminJtdRoutes.ts → admin-jtd-management).
⚠️ PGMQ is used only for JTD notifications — not for AI/agent task orchestration.
Background workers: jtd-worker (with invoke_jtd_worker / test_jtd_worker).
Cron (pg_cron, confirmed live): cron.schedule('expire-no-credits-jtds', …) daily (003_jtd_credit_integration.sql:422); contract auto-expiry invoke_auto_expire_contracts / auto_expire_contracts; cleanup jobs (cleanup_expired_idempotency_keys, cleanup_expired_ai_sessions, cleanup_expired_cache).
Edge functions for async: jtd-worker, payment-webhook are genuinely async; the other ~48 functions are synchronous request/response endpoints proxied by the Express API.
4. Vector / Semantic Search
pgvector: 🟢 Installed (verified live). Vector columns:
t_group_memberships.embedding
t_semantic_clusters.cluster_embedding
t_tenant_smartprofiles.embedding
t_query_cache.query_embedding
Embedding model: ⚠️ Not in the codebase. Embeddings are produced by the external n8n /generate-embedding webhook (groupsService.ts:722, group-discovery/readme.md: "embedding from N8N"). The model is opaque and unversioned in the repo — a reproducibility/lock-in risk (dimension and model can drift outside source control).
Features using semantic search: the BBB / VaNi directory bot — business discovery and member matching. RPCs: vector_search_members, smartprofile_vector_search, vector_search_with_boost, cached_vector_search, smartprofile_unified_search, search_businesses_v2, unified_search, plus a semantic result cache (t_query_cache, cached_discover_search). No other module (contracts, catalog, forms) uses vectors.
5. Gaps vs Agentic Target ⚠️
Missing entirely

⚠️ No provider abstraction — no ACTIVE_AI_PROVIDER; Claude and n8n are both hardwired. Cannot swap to OpenAI/Gemini/Liquid/local without code changes in 3 services + n8n.
⚠️ No tool/function-calling layer — the "skill registry" is prompt templates, not executable tools. No model is given a tool schema; nothing the LLM "decides" can call back into the system.
⚠️ No autonomous orchestration loop — KT generation is a human/UI-sequenced chain of endpoints; the VaNi agent loop lives entirely in n8n. No in-repo planner/executor/observer.
⚠️ No streaming, no cross-provider fallback/retry, no token/cost budgeting, no output guardrails/eval beyond the test→live promotion gate.
⚠️ No agent self-memory feedback in-repo — sessions are stored but the read-back-into-prompt loop is external (n8n).
Scaffolding present but not wired

⚠️ t_tool_results (RLS-off, sensitive, effectively unused) — placeholder for a tool-execution result store.
⚠️ t_intent_definitions — intent registry, only minimally referenced.
⚠️ t_query_cache semantic cache — present; usage limited to discovery search.
⚠️ m_form_template_mappings (from prior audit) — dead table.
⚠️ Conversation/session tables (t_ai_agent_sessions, t_chat_sessions) populated but their intelligence runs outside the codebase.
What's needed for a 4-layer agent stack (Perception → Knowledge → Orchestration → Intelligence)

Layer	Current state	To reach target
Perception	🟡 Inputs exist (chat/intent, WhatsApp via MSG91, website scrape, n8n embeddings) but parsing/embedding are off-platform	Bring embedding generation in-repo with a versioned, pinned model; add a structured intent/normalization layer with t_intent_definitions actually driving routing
Knowledge	🟢/🟡 pgvector store + KT snapshots + catalog	Version embeddings & KT; unify the semantic store across modules (contracts/catalog currently have none); enforce RLS on t_group_memberships/t_business_groups (currently disabled) so retrieval is tenant-safe
Orchestration	🔴 Weak — no agent loop, no tool registry; sequencing is external (n8n + UI)	Add an in-process planner/executor with a tool registry (turn t_tool_results into a real tool-call ledger); use PGMQ (already present) for AI task queues, not just JTD; add HITL approval gates on agent actions
Intelligence	🟡 Claude generation works; reasoning locked to n8n	Introduce the ACTIVE_AI_PROVIDER abstraction with fallback/retry, streaming, function-calling, and eval/guardrails; consolidate the two AI subsystems (Anthropic-in-code vs n8n) under one routed interface
Bottom line: ContractNest has solid Intelligence (Claude generation) and a usable Knowledge layer (pgvector), plus genuine async plumbing (PGMQ + pg_cron + a worker). But it is not an agent stack today: the Orchestration layer is essentially absent (no tool use, no autonomous loop — it's prompt-chaining and an external n8n black box), and the provider lock-in (no ACTIVE_AI_PROVIDER) plus off-repo embedding model are the two biggest blockers to a reproducible, swappable, in-house agentic system. The most leveraged next steps are: (1) the provider abstraction, (2) a real tool registry + executor loop, and (3) pulling embedding generation in-repo with a pinned model.

All findings are from static code inspection plus the earlier live-DB confirmations (pgvector, PGMQ, pg_cron); I made no changes.