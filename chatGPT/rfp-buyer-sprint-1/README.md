# RFP buyer draft release — 2026-09-23

## Scope

Approved reference: `contractnest-rfp-playground.html` in the New project workspace.
Buyer preparation is implemented first on separate routes. Existing RFQs are not migrated.

- Expense menu: **RFP Drafts**, `/requests/rfp`.
- Create: `/requests/rfp/new`; resume: `/requests/rfp/:id`.
- Five sections: need and structured coverage/requirements; questionnaire and evaluation weights; terms/security; intended recipients; document review.
- Single **Save & continue** action, explicit Save draft, standard product loaders/toasts.
- Shared TipTap rich text, SafeHtml, grouped nomenclature masterdata, registry APIs/form, and RFQ ChecklistRow quantity/day-cycle/billing controls.
- Request-only coverage does not create registry entries. Explicit Register & add uses the existing full equipment/facility form, creates one unit, and links it. Registry creation is a separate real write; it is not rolled back when an RFP draft is discarded.
- Existing vendor contacts and email prospects are intended recipients only. Prospects are not silently inserted into Contacts.
- EMD/bid security, declaration, and performance security are participation requirements, not payment collection. No payment confirmation is inferred.

## Persistence and safety

The existing create/update RFQ transaction stores the structured snapshot in `metadata.rfp_buyer_v1` (schema 1). No API/Edge/schema change.
Create uses POST `/api/v2/contracts`; edit uses existing PUT `/api/contracts/:id` with optimistic version. A GET must return the complete matching snapshot before success is shown.
Existing unrelated metadata is retained. Tenant, live/test, draft status, record type, and version are checked. New drafts use a stable creation idempotency key during the mounted session. An uncertain result asks the user to inspect saved drafts before retrying.
New data does not enter the old quote-only wizard: old hub resume and detail rendering recognise the marker and direct to the new buyer flow. Unmarked records follow unchanged logic.

**Sharing is intentionally disabled in this release.** There is no send/award/payment action on the new page. This is a UI release boundary, not a new server-side authorisation rule. Existing API authorisation is unchanged. Before enabling sharing, add server validation and vendor-side support for the questionnaire, attachments, deadline, security requirements, and lifecycle transitions.

## Validation performed

- Production bundle built successfully using the package as a virtual overlay on the live D: UI checkout, without modifying live source.
- Zero new/added TypeScript diagnostics in release files compared with their live baseline. This does not claim the entire legacy repository is type-error-free.
- 15 model/integration checks plus 12 mocked persistence checks passed. Tests include wrong-tenant/environment/type, stale version, partial readback, missing ID, network failure, and workspace change before writing.
- Existing deployed transaction definitions were inspected read-only: create/update/get support metadata. The list omits metadata, so the draft list reads each record's details, ten per page.
- Guarded copy checks all destinations before copying, backs up originals, and verifies delivered hashes.

Not performed: real tenant save, registry creation, invitation, authenticated browser end-to-end test, or pixel-by-pixel visual comparison. Complete the local acceptance checklist before merging. Existing build warnings include bundle size, duplicate buyer_id in legacy code, outdated Browserslist, and mixed dynamic/static imports; these were not changed by this release.

## Acceptance checklist

1. Expense → RFP Drafts → New RFP. Revenue should not offer buyer creation.
2. Agreement label modal retains categories; selecting one updates the badge. No invented selected label/term.
3. Rich text preserves bold, underline, bullets and table content after save/reopen.
4. Add equipment, facility and service coverage; pick a registry item. Names/counts stay linked. A facility is not relabelled equipment.
5. Register & add: inspect the familiar form, cancel without a write; in TEST only, explicitly create one unit and confirm it appears in the registry and request.
6. Create two requirements with different quantities and service-cycle days. Link them to different coverage. Billing cycle must remain separate. Term validation identifies the offending item.
7. Add text/number/document/yes-no questions. Required is distinct from eligibility. Weights must total 100.
8. Terms, currency, response deadline, security/release conditions, exemption, and performance percentage survive reopening. No deposit is collected.
9. Select an existing vendor and a prospect. Reject duplicate email. No invitations and no automatic new Contact.
10. Save & continue once: success toast only after confirmed save; reopen from list and refresh. All sections retain values. Resume a marked draft from old Requests; it opens new RFP UX.
11. Test slow/error responses and two-tab stale edit. No false success or automatic duplicate retry.
12. Switch tenant/live-test: no cross-workspace records. Open an old RFQ and old contract; existing flows remain intact.
13. Review document and mobile layout (390px/768px/desktop). Test keyboard focus and modal Escape. Sharing remains unavailable and clearly labelled.

## Next release

Vendor response: controlled invitations/access, questionnaire answers and evidence upload, structured pricing/cycles, amendments/deadlines, and server-side lifecycle validation. Then evaluation/award and conversion through the existing shared context/contract flow, with field-by-field parity checks. Do not add a competing contract engine or enable legacy quote-only sharing for structured drafts.

## Files

UI: App routes; industryMenus entry; marked-draft guards in contracts/hub and contracts/detail; new rfp/experience/RfpBuyerPage.tsx, model.ts, persistence.ts, rfp-buyer.css.
Documentation: this file. No API, Edge, mobile, or FamilyKnows source changes.
