# Phase 1 — task 2 verification

Date: 8 October 2026  
Status: Identity/entitlement code, shared database migration, and access endpoint applied. User completed the signed-in MSG91 OTP journey successfully. No inbound WhatsApp transport was built.

8 October follow-up: the first browser test exposed a missing CORS allowance for `x-client-info` and the app's separate stored Auth session. The Edge function was redeployed with the header allowance; the active UI sends its stored bearer token. The phone journey now uses the MSG91 OTP widget and server-side verification of its access token, not Supabase Auth phone-change OTP.

## Implemented

- One-active-workspace guard at the database membership boundary, so tenant creation, registration, invitations, and admin paths cannot create a second active workspace for an ordinary account. Existing memberships were not removed.
- Explicit exception table for approved multi-workspace administrators. Charan's existing two-workspace access was preserved and recorded as the approved exception; neither membership was altered.
- Workspace and member WhatsApp switches, both default **off**, stored once and displayed in `/settings/users` and `/extend`.
- Personal phone binding from a profile/account number selected in the UI, but **only after MSG91 OTP verification** of that exact international-format number and server-side verification of MSG91's access token. An unverified profile `mobile_number` alone never grants access. Revocation and number changes invalidate eligibility; active bindings must be unique.
- Signed-in `whatsapp-access` Edge endpoint with active membership, Live-tenant, and manage-team checks. Access tables have RLS and no ordinary Data API grants. The endpoint reports effective eligibility only when the workspace and member switches, phone binding, and one-workspace rule all pass.
- Access-change audit rows; no messaging or chat data is sent.

## Checks performed

- Active D: UI checkout production build passed. The older C: workspace copy has unrelated missing-file/build errors and is not the running app.
- Shared database: all workspace/member/phone tables initially empty; switches default off; exactly one explicit exception and one membership guard trigger.
- An attempted second active workspace for an ordinary member was rejected by the guard without changing membership data.
- Trigger moved to an unexposed private schema after discovering that some membership writers run as the authenticated role; the authenticated role cannot execute or access the private function directly.
- New public tables have RLS enabled and no `anon`/`authenticated` SELECT grant.
- Deployed `whatsapp-access` requires JWT; unauthenticated HTTP request returned 401.
- Local app on port 5173 returned HTTP 200. The available browser tab was at `/login`, so no signed-in UI or actual OTP was exercised by the assistant.

## User-confirmed OTP outcome

- The user reported successful MSG91 authentication after resolving provider delivery/configuration issues.
- A read-only database check found one phone binding verified within the last 24 hours and still active. Its account has one active workspace; the workspace switch is on and the member switch remains off.
- The OTP-widget callback and phone binding do **not** prove that the WhatsApp business number can receive messages, send replies, or report delivery. Those are task-3 transport gates.

## User verification (do not enable messaging yet)

1. Sign in to the Live workspace and open `/settings/users`; find **WhatsApp team access**. It should say messaging is not connected and show the workspace switch off. Open `/extend` and confirm the same state appears there, separate from storefront WhatsApp sharing.
2. As a workspace manager, enable then disable the workspace switch in one screen and confirm the other reflects each saved change. Leave it off after testing.
3. Enable then disable a member. Confirm an inactive/suspended user is not offered as an active member. Leave all member permissions off after testing.
4. For your own account only, select your saved international-format phone, complete the MSG91 CAPTCHA if enabled, and request the OTP through a configured channel. Verify the code yourself; the server must validate the widget access token before linking. This journey has now succeeded for one member.
5. Confirm an ordinary user cannot gain a second active workspace. Do not test this by changing a real user's access; use an isolated account when available.

Task 3 remains separate: it needs the MSG91 WhatsApp inbound/outbound webhook and receiving-number proof described in the main spec. The member switch remains off until intentionally enabled for a controlled pilot.

