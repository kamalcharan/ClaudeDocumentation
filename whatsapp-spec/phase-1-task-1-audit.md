# Phase 1 WhatsApp — task 1 audit

Status: Read-only source/database audit complete; provider-account proof outstanding. No implementation or provider configuration changed.  
Date: 8 October 2026

## Scope and provenance

This is task 1 of the phase-one plan. I inspected the active application checkout at `D:\projects\core projects\ContractNest\contractnest-combined`, not just the older writable copy of the repository, and read workspace Supabase metadata and deployed Edge-function names. The proposed specification is `phase-1-internal-workspace-spec.md` in this directory. Provider credentials, MSG91 account configuration, and a real inbound/Flow round trip were not available to this audit. Source presence does not prove production behavior.

## Capability/reuse matrix

| Capability | Existing application path | Revenue / Expense finding | WhatsApp decision |
| --- | --- | --- | --- |
| Contracts | `/ncontracts`; contract list/detail API and `contracts-v2` Edge function | Client and vendor contracts exist; scope must be filtered by relationship and actor | Reuse read model after record-level authorization audit. Approved-template creation is a later, separately confirmed write. Do not route through unstable free-form VaNi drafting. |
| Money | `/money-in`, `/to-pay`; `/api/finance/receivables` and `/payables` | Both perspectives have existing reads | Read-only summary adapter first. Approval, payment, and reminder writes need explicit role checks and idempotency. |
| Appointments/commitments | `/ops/timeboard`, `/ops/services`; `/api/appointments` and contract events | Service scheduling exists; Expense-side incoming commitments need explicit eligibility mapping | Reuse the appointment domain workflow; do not invent a separate WhatsApp appointment state. Structured slot input can become the first Flow only after provider proof. |
| Service tickets and Smart Forms | `/api/service-execution` and existing service/evidence UI | Primarily Revenue execution; incoming vendor-service actions require separate permission review | Read ticket status; use short-lived, scoped web links for full Smart Forms. Starting/completing service is a later controlled write. |
| Leads | `/leads`; `/api/leads` | Revenue capability; no verified Expense equivalent | Revenue read-only pilot only. |
| Group sessions | `/group-sessions`; `/api/group-sessions` dashboard | Revenue capability; no verified Expense equivalent | Revenue read-only pilot only. Attendance is a later controlled write. |

The web client chooses Live/Test with `x-environment`. The WhatsApp server adapter must force Live, regardless of incoming payload or saved chat state. The inspected API routes require bearer authentication and a tenant header; a WhatsApp phone number is not a Supabase bearer token. A trusted actor bridge and record-level permission checks are mandatory before any domain call. Header presence alone is not authorization. This audit does **not** assert that the existing domain/RPC layers lack all access checks; those checks must be verified per command before release.

## Existing WhatsApp/provider pieces

- `/extend` currently offers WhatsApp **sharing of a hosted buy link**. It is not an inbound staff workspace.
- The API outbound sender uses a global `MSG91_WHATSAPP_NUMBER`, not a tenant-selected sender. The JTD worker also uses the global number. Outbound notification/template infrastructure is reusable, but branded tenant-number routing is not present.
- A deployed `msg91-webhook` Edge function exists. Its source handles message delivery/status callbacks; it is not an inbound conversation-command adapter. Its source allows a configured `MSG91_WEBHOOK_SECRET` check, but warns that callbacks are accepted without authentication if that secret is absent. Whether the deployed secret is set is unverified. Do not expose a command path through this callback as-is.
- The generic integrations catalogue has an active platform-managed `contractnest_whatsapp` provider (142 tenant rows, 62 active Live at audit time). `meta_whatsapp` is marked `coming_soon` and has zero tenant connections. Thus a tenant-owned WhatsApp number is a future topology, not a working switch today. No credentials were read.
- Deployed function inventory includes `msg91-webhook` and `jtd-worker`; no confirmed inbound workspace or Flow-completion handler was found in this audit. An external gateway could exist outside the inspected code; absence here is not proof it does not exist.
- Existing n8n usage is for other VaNi/AI work. There is no evidence that core WhatsApp workspace commands already run through n8n. The transactional route should use ContractNest domain services directly.

## Identity and tenancy blockers

The profile table has `mobile_number`, but the inspected profile/membership schema does not contain a verified WhatsApp binding. Among 21 accounts with active membership in the read-only aggregate, 8 lack a profile mobile; none has a confirmed Supabase Auth phone; one normalized profile-mobile value is shared. A typed profile number therefore cannot authorize chat access. Build a verified, unique binding and immediately revocable per-member permission before enabling inbound lookups. Receiving business number and verified sender phone must be resolved together; never infer tenant from message text. Preserve the agreed platform-admin exception to ordinary one-workspace membership, and require explicit audited workspace choice for any ambiguous admin session.

## Provider proof required to close task 1's external gate

8 October account screenshot update: MSG91 Webhook (New) currently lists `BBB` → **On Inbound Report Received** → n8n `/webhook/whatsapp-msg91`, and `VaNi` → **On Inbound Request Received** → n8n `/webhook/group-discovery-agent`. MSG91's current event documentation says **On Outbound Report Received** supplies outbound Sent/Failed/Delivered/Read status; the BBB event name must not be treated as outbound delivery proof merely because older local notes called it a delivery-report webhook. No outbound-report subscription was visible in the screenshot. The actual n8n processing, event filters, receiving-number identity, and callback authentication remain unverified. Preserve both configurations while investigating.

Obtain evidence from the actual MSG91 account/connected WhatsApp business account for:

1. The business number(s), webhook configuration, authenticated inbound message example, and interactive button/list reply payloads.
2. Whether one MSG91 account can onboard and operate separate tenant-owned business numbers, and how a receiving-number identifier maps to each number.
3. Per-number outbound sender selection, approved-template ownership/sending, delivery callbacks, opt-in/opt-out handling, and commercial constraints.
4. Native WhatsApp Flow creation/publication, send, completion callback, and data-exchange endpoint support through this connection. A documentation page alone does not prove account entitlement or working payloads.
5. Secret/signature verification, replay behavior, retry IDs, and failure callbacks. Avoid sharing tokens or customer message bodies in the audit record.

If native Flows are unavailable, the internal pilot may use lists/buttons and scoped web handoff, but it must be described as a limited pilot. Do not build a fake Flow experience or promise tenant self-service number onboarding until these results are known.

## Task-1 decision

**Reusable foundation identified; external provider gate remains unproven.** No production-ready inbound workspace capability can be claimed yet. Task 2 (identity/entitlement) can be designed independently, but per the agreed sequence it will not be started until the user reviews this audit. Provider-specific transport and Flow work should remain blocked until the MSG91 proof above is recorded. No database, code, settings, membership, or message changes were made for this task.

