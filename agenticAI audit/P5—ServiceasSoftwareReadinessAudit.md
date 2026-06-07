ContractNest — "Service as Software" Autonomy Audit
Key architectural fact: The data model for autonomous operation largely exists, and the JTD notification catalog even anticipates the full lifecycle (it seeds service_reminder, payment_due, payment_overdue, appointment_reminder types). But the scheduler that connects due commitments to actions is absent. The platform builds the calendar, then stops watching it.

1. Commitment Tracking
Is there a commitment table? 🟢 Yes — t_contract_events. (contracts/012_contract_events_tables.sql)

Stores both service and billing commitments: event_type (service|billing), billing_sub_type (upfront|emi|on_completion|recurring), billing_cycle_label ("EMI 2/5", "Monthly 3/6"), scheduled_date TIMESTAMPTZ, status (scheduled→in_progress→completed/cancelled/overdue).
Comment in the migration: "Created in bulk when contract status → confirmed/accepted." Renewal/expiry dates live on t_contracts (end_date, prolongation_date, computed by trg_compute_contract_dates).
Does the model contain enough to derive commitments? 🟢 Yes — duration/prolongation, billing cycle type, and per-block billing cycles are all present.

Is there code that reads contract terms and produces a forward calendar? 🟡 Yes, but in the wrong place. The forward calendar is computed client-side in the UI (components/contracts/ContractWizard/steps/EventsPreviewStep.tsx, BillingViewStep.tsx, types/contractEvents.ts), passed into create_contract_transaction as a computed_events JSONB payload, then materialized by process_contract_events_from_computed (contracts/014).

⚠️ No backend/agent derives the calendar — if a contract is created via API/agent without the UI pre-computing computed_events, no events are generated. The "intelligence" that turns terms into a schedule is trapped in the React wizard.
2. Service Event Dispatch
Is there a mechanism that fires when an event is due? 🔴 No. I checked the live cron.job table — the only scheduled jobs are:

Job	Schedule	What it does
jtd-worker-cron / invoke-jtd-worker	every minute (⚠️ duplicated — jobid 1 & 3)	Drains the JTD queue (only items already enqueued)
cleanup-tool-results	hourly	GC
expire-no-credits-jtds	daily 02:00	JTD housekeeping
auto-expire-contracts-nightly	daily 18:29	Flips active→expired
There is no job that scans t_contract_events for scheduled_date <= now(). "Overdue" is only ever computed at read time for dashboards (get_contract_events_date_summary buckets into overdue/today/tomorrow) — nothing transitions an event to overdue or fires on due date.

Are SmartForms auto-dispatched to technicians on event fire? 🔴 No. Grep for form dispatch/assignment on events returned nothing. SmartForms (m_form_templates, renderer) are selected/filled manually; there is no event→form→technician routing, and m_form_template_mappings (the table that would link forms to resources) is dead/unreferenced (per prior audit).

Or does a human manually trigger service events? ✅ Human. Service tickets are created only via create_service_ticket, called from the service-tickets/service-execution edge functions in response to user actions — never auto-spawned from a due event.

3. Renewal & Billing Intelligence
Code monitoring expiry? 🟡 Partial. auto_expire_contracts (cron, nightly) scans active contracts past end_date and sets status='expired' + writes a history row. That's it — it does not alert, quote, or notify (contracts/054).

Renewal workflow (alert → quote → renewal contract)? 🔴 Missing. No renewal RPC/endpoint exists. The UI ServiceRenewalCard.tsx is a stub — its own comment says "Mock renewal data - this would come from API" and it renders hardcoded objects. There is no alert, no quote-from-expiring-contract, no renewal-contract creation.

Is billing cycle tracking automated or manual? 🟡 Mixed.

Invoice generation is automated at contract acceptance: create_contract_transaction calls generate_contract_invoices for auto-accept contracts (contracts/014:376).
But recurring billing over time is not driven — billing events sit in t_contract_events as scheduled rows with billing_cycle_label, and nothing fires payment_due when an EMI/monthly date arrives. Payment capture (record_invoice_payment) is manual.
4. Tenant Autonomy Score
Capability	Verdict	Evidence
New tenant onboarding (schema + seed)	🟢 Automated	initialize_tenant_onboarding, seedTenantOnIndustryConfirmedService, seed_onboarding_facility_nodes, seed_sample_contacts auto-provision on the 6-step wizard
Contract creation from template	🔴 Manual	Human-driven ContractWizard; calendar computed client-side, then "send"
Service event scheduling	🟢 Automated	Events bulk-materialized on acceptance via process_contract_events_from_computed (dates are UI-set, but row creation is automatic)
Field form dispatch	⚠️ Missing	No event→form routing; m_form_template_mappings dead
Service completion capture	🔴 Manual	create_service_ticket / create_service_evidence via user action
Invoice generation trigger	🟢 Automated	generate_contract_invoices auto-called at creation (auto-accept)
Renewal alert	⚠️ Missing	No cron/JTD enqueue for expiring contracts; card is mock
Contract renewal	⚠️ Missing	No renewal RPC/endpoint/workflow
Tenant Autonomy Score: 3 / 8 automated (3 automated · 2 manual · 3 missing)
5. The Missing Loop
Current happy path when a contract goes live:

A human builds a contract in the React ContractWizard. The browser computes the forward calendar (service visits + billing cycles) and the user previews/adjusts dates. (manual)
On "send/accept," create_contract_transaction runs one transaction that: generates the sequence number + CNAK, inserts the contract, auto-materializes the calendar into t_contract_events, auto-generates invoices (auto-accept), and enqueues one JTD (e.g., contract_created/contract_signed) to PGMQ. (automatic)
The jtd-worker cron (every minute) drains that queue and sends the creation/signature notification via MSG91/email/SMS. (automatic)
…and then the loop goes silent. The contract now holds a table full of future scheduled service and billing events with exact scheduled_dates — but:
🔴 Nothing scans those dates. No job moves an event to overdue, and none enqueues the service_reminder / payment_due / appointment_reminder JTDs that are already seeded in the catalog.
🔴 When a service visit date arrives, no service ticket is created and no SmartForm is dispatched to a technician. A human must remember, open the app, and create the ticket.
🔴 Service completion is captured only because a human fills it in.
🔴 As end_date approaches, the only thing that ever happens is the nightly job flipping the contract to expired — after it has lapsed. No pre-expiry alert, no renewal quote, no renewal contract.
Exactly where the loop breaks: between commitment storage and commitment action. ContractNest has the commitment ledger (t_contract_events), the dispatch rails (PGMQ + every-minute worker + working notification channels), and even the notification vocabulary (service_reminder, payment_due, payment_overdue, appointment_reminder). What it lacks is the one scheduled scanner that, each day/hour, reads t_contract_events WHERE scheduled_date <= now()+window AND status='scheduled' and (a) enqueues the matching reminder JTD, (b) transitions status, (c) spawns a service ticket, and (d) dispatches the mapped SmartForm — plus a sibling job that watches t_contracts.end_date to fire renewal alerts.

In "Service as Software" terms: perception (the calendar) and actuation (notifications/tickets/forms) both exist; the autonomic nervous system that links them on a timer does not. The platform is event-recording, not event-driving. Closing the loop is a small surface area — essentially 2–3 pg_cron jobs + the form-dispatch wiring — sitting on top of infrastructure that is already 80% built.

(All findings verified against the live database — cron.job, RPC definitions, and migrations; read-only, no changes made. Note the duplicate jtd-worker cron as a minor ops cleanup.)