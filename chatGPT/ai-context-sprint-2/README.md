# Shared composer context — Sprint 2
Date: 2026-09-22
Release branch: codex/ai-context-sprint-2
Package: MANUAL_COPY_FILES/ai-context-sprint-2

## Outcome
Refactors the existing VaNi composer. One shared context module, not a third composer, pricing engine, event engine, or database schema.

## Implemented
- Composer routes verify ACTIVE t_user_tenants membership before entitlement or privileged context reads.
- The existing auth middleware merges a profile over auth data. Membership therefore uses the verified profile user_id (auth.users FK), or the verified auth id when no profile was returned.
- Live/Test is explicit. Requests carry the workspace/environment they started in; stale/mismatched requests fail with 409.
- Context supports contract, template and rfq consumers. The RFQ screen is NOT migrated in this release; RFQ context is deliberately refused by contract assembly.
- Explicit Client/Partner/Vendor relationship. Contact search filters by it and selected contacts are re-read before assembly. Both string-array and classification_value object-array classifications are supported.
- Bulk template assignment verifies every selected contact before submission. Unknown or multiple contract classifications are actionable errors, not a Client default.
- Approved keywords and configured tenant persona are facts. Suggested keywords, generated profile persona and semantic clusters remain suggestions. Source availability/revision and unknown fields are exposed separately.
- Only the current tenant's resources, in the selected environment, are loaded. No neighbour-tenant vocabulary borrowing.
- Missing duration, billing mode, instalment count, billing cycle, acceptance and contract start date require confirmation. Empty activities do not become PM + inspection automatically.
- Saved template settings can fill unknowns; explicit request values win. Template ID/revision and illustrative calendar scope travel with the result.
- Currency source is explicit request, template or catalogue. INR in the UI is the application's configured preference, not a tenant-profile fact.
- Existing launcher, single-template path, bulk-template path, onboarding and review/handoff callers migrated.
- UI rejects late results after a workspace/environment/session change; review and wizard handoff check scope again.
- No changed event algorithms, tax algorithms, persistence endpoints, wizard presentation or RFQ UI.

## Cleanup
Removed the composer's duplicate ICP query implementation and private neighbour-profile borrowing.
Removed contract-term normalizer defaults and the quick-parser prepaid/12-instalment defaults.
Removed forced Client relationship in VaNi final submission and legacy list-to-wizard handoff.
Removed ambiguous/unclassified bulk-contact fallback to Client.
The shared module contains context/access/data provenance only. Existing contractComposerService still assembles drafts.

## Verification
- 53 offline regression checks against the actual package source: PASS.
- Existing assembly fixture: 8 service events + 1 upfront payment retained.
- API TypeScript: baseline 0 errors; overlay 0 errors.
- UI TypeScript: baseline 1162 errors; overlay 1162 errors; no new diagnostics.
  This is NOT a claim of a clean repository-wide UI type check.
- Production Vite bundle with virtual overlay: PASS. Static public assets/SEO generation excluded; no deployment.
- Read-only API-configuration check: active membership accepted, non-member denied, all five context sources readable.
  No database writes, no real contract submissions and no LLM calls.
- D: running checkout was not edited. C: unrelated dirty submodules were not edited.
- Existing build warnings remain (old Browserslist data, duplicate key in contract detail, Lottie eval, mixed dynamic/static imports).

## Required rollout
Copy API and UI together. Older UI composer working requests without the context envelope now fail explicitly.
Restart the API and UI after copying. Existing API SUPABASE_SERVICE_ROLE_KEY is required; never put it in UI configuration.
No database migrations, Edge deployment, new dependency install or new subscription entitlement is required.
The health/entitlement endpoints still require authenticated active tenant membership.
The existing subscription gate remains in effect; this context layer does not grant write privileges.

## Contract and template integration boundary
Context verifies scope and contact identity; it is not a substitute for create/update endpoint validation.
User-entered/AI-interpreted terms remain reviewable and require final approval. An LLM interpretation is not an approved tenant fact.
A reusable template has no committed start date; its generated calendar is labelled illustrative.
Bulk relationship ambiguity is intentionally blocked rather than silently choosing Partner/Client.
Signing in again while an AI call is running invalidates that call; reopen VaNi.
The request-local facts cache never crosses a verified request, tenant or environment.

## Deliberately deferred (Sprint 1 audit findings)
- Composer shortlist's strict resource/currency matching and complete block-config carriage.
- Catalogue instance/FlyBy provenance and pricing/event parity issues.
- Shared event-engine consolidation, tax parity, broader send/activation confirmation handling.
- RFQ product-led UX and RFQ-specific context adapter; no third RFQ drafting engine.
These are not claimed fixed by this context release. Test in TEST mode before production use.

## User acceptance checklist
1. In TEST, open Draft with VaNi from /contracts or /ncontracts. Select Partner. Search a known partner: no Client badge/default; review and Edit in wizard retain Partner.
2. Describe a service agreement without term, payment plan or acceptance. Confirm the missing-details form; no one-year/prepaid assumption. Fill fields and continue once.
3. Use a signed-off template in TEST. Saved term/payment/acceptance carry through. Set a real start date for assignment; template ID is retained.
4. Try bulk assignment with Client/Partner contacts. Unclassified or multiply-classified contacts must be explained and blocked, not relabelled.
5. Start a draft then switch workspace or Live/Test. The previous response/draft must not be usable in the new scope.
6. Verify service/event counts, prices, tax and evidence against the selected template/catalogue; this release does not resolve the deferred parity findings.
7. In TEST only, complete one reviewed contract; verify actual relationship, saved dates, status and resulting events. This write-path check was not performed automatically.
8. Open manual creation and resume an existing draft to confirm the non-VaNi wizard still behaves as before.

## Repeatable checks
From contractnest-combined:
node MANUAL_COPY_FILES/ai-context-sprint-2/VERIFY_CONTEXT.cjs .
node --expose-gc MANUAL_COPY_FILES/ai-context-sprint-2/VERIFY_TYPES.cjs .
node --max-old-space-size=6144 MANUAL_COPY_FILES/ai-context-sprint-2/VERIFY_BUILD.cjs .
Optional database reads, using the existing API .env:
node MANUAL_COPY_FILES/ai-context-sprint-2/VERIFY_DATABASE_READS.cjs .

## Manual delivery / rollback
Use COPY_COMMANDS.ps1. It validates every source and destination before writing, backs up existing files under LOCAL_BACKUP, copies the exact listed files, and verifies output hashes.
If preflight reports different local edits, STOP. Do not force-copy; refresh the package from that checkout.
Rollback: copy the backed-up original files to the same relative paths and restart both servers. New context/helper files can remain unused; do not delete unrelated files.
Keep UI/API commits on feature branches until acceptance tests pass. Only then update parent submodule references and merge.
