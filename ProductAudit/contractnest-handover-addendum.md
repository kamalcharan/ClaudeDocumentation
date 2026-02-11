# ContractNest: Handover Addendum — Service-Based Contract Segment

**Date**: 2026-02-11
**Why This Exists**: The original audit and architecture alignment tilted entirely towards the maintenance/facility management domain (AMC/CMC/FMC). This addendum corrects a critical blind spot — **service-delivery contracts** where there is NO equipment and NO physical entity, only deliverables with quantities and cycles.

---

## THE BLIND SPOT

ContractNest serves (at minimum) four distinct contract paradigms:

| Paradigm | Who Uses It | What's Being Contracted | Example |
|----------|------------|------------------------|---------|
| **Equipment Maintenance** | Hospital biomedical, manufacturing plant, data center | Scheduled servicing of specific machines | "AMC for 3 MRI machines — quarterly PM, parts included" |
| **Facility/Property Management** | Real estate, hospitality, corporate offices | Ongoing maintenance of physical spaces | "FMC for 50,000 sqft office — housekeeping + security + utilities" |
| **Service Delivery** | Wellness clinics, consultants, trainers, IT support | Bundled deliverables/sessions over a period | "Pregnancy Care Package — 4 gynec + 6 diet charts + 20 yoga sessions over 3 months" |
| **Hybrid** | Large enterprises, infrastructure | Combination of equipment + entity + services | "O&M for solar farm — equipment maintenance + site management + performance reporting" |

The original 15 nomenclature types covered paradigms 1, 2, and 4 well. **Paradigm 3 had zero representation.** A wellness practitioner, a corporate trainer, an IT support provider, or a legal consultant would find nothing that describes their contract type.

---

## REAL-WORLD EXAMPLES OF SERVICE-DELIVERY CONTRACTS

These are contracts where the "what" is a set of deliverables/sessions — NOT tied to any equipment or property:

### Healthcare / Wellness
```
PCOD Balance Program — 3 Months — ₹12,000
├── 4 × Gynec Consultation / month (12 total)
├── 2 × Diet Chart / month (6 total)
├── 1 × Nutrition Consultation / month (3 total)
├── 4 × Yoga Session / month (12 total)
└── Billing: 100% advance OR monthly ₹4,000

Gestational Diabetes Management — 6 Months — ₹18,000
├── 2 × Endocrinologist Consultation / month
├── 4 × Diet Chart / month
├── Blood Sugar Monitoring Kit (one-time)
├── 8 × Yoga Session / month
└── Billing: Monthly ₹3,000

Post-Partum Recovery Package — 1 Month — ₹4,800
├── 2 × Diet Chart (total)
├── 4 × Nutrition Consultation (total)
├── 4 × Yoga Session (total)
└── Billing: Prepaid
```

### Professional Services
```
Legal Advisory Retainer — 12 Months — ₹6,00,000
├── 10 hours / month consultation
├── 4 × Contract Review / month
├── Unlimited email queries
├── 1 × Quarterly compliance audit
└── Billing: Monthly ₹50,000

Accounting & Tax — 12 Months — ₹3,60,000
├── Monthly bookkeeping
├── Quarterly GST filing
├── Annual IT return filing
├── 2 × Management report / quarter
└── Billing: Monthly ₹30,000
```

### Training & Education
```
Corporate Leadership Program — 6 Months — ₹8,00,000
├── 8 × Workshop (half-day)
├── 4 × Executive Coaching Session / participant
├── 2 × Assessment (pre + post)
├── 1 × Final Certification
├── Participant limit: 25
└── Billing: 50% advance, 50% on completion

Digital Marketing Bootcamp — 3 Months — ₹1,50,000
├── 12 × Live Session (weekly)
├── 12 × Assignment Review
├── 3 × Project Milestone Review
├── 1 × Certification
└── Billing: Monthly ₹50,000
```

### IT / Tech Support
```
IT Support — Annual — ₹4,80,000
├── Unlimited helpdesk tickets
├── 4-hour response SLA
├── 1 × Monthly server health check
├── 1 × Quarterly security audit
├── 1 × Annual DR drill
└── Billing: Monthly ₹40,000

Website Maintenance — 12 Months — ₹1,80,000
├── 4 × Content updates / month
├── 1 × Security patch / month
├── 1 × Performance report / month
├── 2 hours bug-fix support / month
└── Billing: Monthly ₹15,000
```

### Staffing / Outsourcing
```
Outsourced Reception — 12 Months — ₹4,20,000
├── 1 × Receptionist (Mon-Sat, 9am-6pm)
├── Replacement within 48 hours guarantee
├── Monthly attendance report
├── Uniform provided
└── Billing: Monthly ₹35,000
```

---

## WHAT THE EXISTING SYSTEM ALREADY HANDLES WELL

**The contract wizard Step 6 (Service Blocks) already models this correctly:**

- `t_contract_blocks` with `quantity × unit_price = total_price`
- Cycle-based computation: "Contract is 12 months, cycle is 30 days = 12 occurrences"
- Multiple blocks per contract (Gynec block + Diet Chart block + Yoga block)
- Event generation per block per cycle

**The service catalog (`t_catalog_items`) already supports:**
- Independent services with fixed pricing
- Resource-based services (links to staff/practitioners)
- Service categories (Consultation, Therapy, Training, Assessment)

**So the FUNCTIONALITY exists. What's missing is FRAMING:**
- No nomenclature type that says "Service Package" or "Care Plan"
- No wizard entry point that says "I want to create a wellness package"
- No industry suggestion that says "For Wellness, start with: Care Plan, Subscription"
- The wizard jumps straight to blocks without contextualizing the contract type

---

## ADDITIONAL NOMENCLATURE TYPES TO ADD

Expand from 15 to 21 nomenclature types. The new 6 are service-delivery focused:

| ID | Short Name | Full Name | Description | Equipment? | Entity? | Service? | Typical Industries | Typical Billing | Typical Duration |
|----|-----------|-----------|-------------|-----------|---------|---------|-------------------|----------------|-----------------|
| `service_package` | Service Package | Service Package Agreement | Bundled set of deliverables/sessions over a fixed period. Buyer gets a defined quantity of each service type. | ❌ | ❌ | ✅ | wellness, healthcare, beauty, fitness | prepaid or monthly | 1-12 months |
| `care_plan` | Care Plan | Care Plan Agreement | Healthcare/wellness outcome-oriented contract with a protocol of sessions, assessments, and deliverables. | ❌ | ❌ | ✅ | healthcare, wellness, mental_health, elder_care | monthly or prepaid | 1-12 months |
| `subscription_service` | Subscription | Subscription Service Agreement | Recurring access to a defined scope of services. May include usage limits or be unlimited within scope. | ❌ | ❌ | ✅ | technology, consulting, creative, marketing | monthly or annual | ongoing or 12 months |
| `consultation` | Consultation | Consultation Agreement | Time-banked or session-based professional advisory services. Typically hours/month or sessions/quarter. | ❌ | ❌ | ✅ | legal, finance, management, technology | monthly or retainer | 6-12 months |
| `training_contract` | Training | Training & Development Contract | Structured learning program with workshops, assessments, and certification. Fixed deliverables over a defined timeline. | ❌ | ❌ | ✅ | education, corporate, technology, healthcare | milestone or 50-50 split | 1-6 months |
| `project_service` | Project-Based | Project-Based Service Agreement | One-time deliverable with defined milestones and handover. Transitions may lead to AMC or subscription after delivery. | ❌ | ❌ | ✅ | technology, construction, creative, marketing | milestone | project_based |

---

## SEED DATA FOR `m_category_details` (form_settings JSONB)

```json
// service_package
{
  "short_name": "Service Package",
  "full_name": "Service Package Agreement",
  "description": "Bundled set of deliverables/sessions over a fixed period. Buyer gets a defined quantity of each service type.",
  "is_equipment_based": false,
  "is_entity_based": false,
  "is_service_based": true,
  "wizard_route": "deliverables",
  "typical_duration": "1_to_12_months",
  "typical_billing": "prepaid_or_monthly",
  "scope_includes": ["defined_sessions", "fixed_deliverables", "scheduled_appointments"],
  "scope_excludes": ["unlimited_access", "on_demand"],
  "industries": ["wellness", "healthcare", "beauty", "fitness", "nutrition"],
  "example": "Pregnancy Care — 4 Gynec + 6 Diet Charts + 20 Yoga Sessions over 3 months",
  "icon": "Package"
}

// care_plan
{
  "short_name": "Care Plan",
  "full_name": "Care Plan Agreement",
  "description": "Healthcare/wellness outcome-oriented contract with a protocol of sessions, assessments, and deliverables.",
  "is_equipment_based": false,
  "is_entity_based": false,
  "is_service_based": true,
  "wizard_route": "deliverables",
  "typical_duration": "1_to_12_months",
  "typical_billing": "monthly_or_prepaid",
  "scope_includes": ["protocol_sessions", "assessments", "monitoring", "diet_charts", "therapy"],
  "scope_excludes": ["equipment_servicing"],
  "industries": ["healthcare", "wellness", "mental_health", "elder_care", "rehabilitation"],
  "example": "PCOD Balance Program — 3 months — Gynec + Nutrition + Yoga protocol",
  "icon": "HeartPulse"
}

// subscription_service
{
  "short_name": "Subscription",
  "full_name": "Subscription Service Agreement",
  "description": "Recurring access to a defined scope of services. May include usage limits or be unlimited.",
  "is_equipment_based": false,
  "is_entity_based": false,
  "is_service_based": true,
  "wizard_route": "deliverables",
  "typical_duration": "ongoing_or_12_months",
  "typical_billing": "monthly_or_annual",
  "scope_includes": ["recurring_access", "support_tickets", "periodic_reviews", "updates"],
  "scope_excludes": ["one_time_projects"],
  "industries": ["technology", "consulting", "creative", "marketing", "media"],
  "example": "IT Support — Unlimited tickets + 4hr SLA + Monthly health check",
  "icon": "RefreshCw"
}

// consultation
{
  "short_name": "Consultation",
  "full_name": "Consultation Agreement",
  "description": "Time-banked or session-based professional advisory services.",
  "is_equipment_based": false,
  "is_entity_based": false,
  "is_service_based": true,
  "wizard_route": "deliverables",
  "typical_duration": "6_to_12_months",
  "typical_billing": "monthly_retainer",
  "scope_includes": ["advisory_hours", "reviews", "recommendations", "reports"],
  "scope_excludes": ["implementation", "hands_on_execution"],
  "industries": ["legal", "finance", "management", "technology", "healthcare"],
  "example": "Legal Advisory — 10 hours/month + Quarterly compliance audit",
  "icon": "MessageSquare"
}

// training_contract
{
  "short_name": "Training",
  "full_name": "Training & Development Contract",
  "description": "Structured learning program with workshops, assessments, and certification.",
  "is_equipment_based": false,
  "is_entity_based": false,
  "is_service_based": true,
  "wizard_route": "deliverables",
  "typical_duration": "1_to_6_months",
  "typical_billing": "milestone_or_split",
  "scope_includes": ["workshops", "assessments", "coaching", "certification", "materials"],
  "scope_excludes": ["ongoing_support"],
  "industries": ["education", "corporate", "technology", "healthcare", "manufacturing"],
  "example": "Corporate Leadership Program — 8 Workshops + Coaching + Certification",
  "icon": "GraduationCap"
}

// project_service
{
  "short_name": "Project-Based",
  "full_name": "Project-Based Service Agreement",
  "description": "One-time deliverable with defined milestones and handover. May transition to AMC/subscription post-delivery.",
  "is_equipment_based": false,
  "is_entity_based": false,
  "is_service_based": true,
  "wizard_route": "milestones",
  "typical_duration": "project_based",
  "typical_billing": "milestone",
  "scope_includes": ["design", "development", "testing", "handover", "documentation"],
  "scope_excludes": ["ongoing_maintenance"],
  "industries": ["technology", "construction", "creative", "marketing", "consulting"],
  "example": "Website Redesign — 5 milestones over 3 months → then transitions to Subscription",
  "icon": "Target"
}
```

---

## UPDATED NOMENCLATURE PICKER GROUPS (4 groups, not 3)

```
🔧 Equipment Maintenance Contracts (6)
   AMC, CMC, CAMC, PMC, BMC, Warranty Extension
   → Wizard shows: Equipment Picker step
   → Industries: Healthcare (biomedical), Manufacturing, HVAC, Power, Elevator

🏢 Facility & Property Contracts (3)
   FMC, O&M, Manpower
   → Wizard shows: Entity/Property Picker step
   → Industries: Real Estate, Hospitality, Corporate, Government

💼 Service Delivery Contracts (6) ← NEW GROUP
   Service Package, Care Plan, Subscription, Consultation, Training, Project-Based
   → Wizard shows: Deliverable Builder step (existing service blocks, promoted)
   → Industries: Wellness, Healthcare, Consulting, IT, Legal, Education, Creative

🔀 Flexible / Hybrid Contracts (6)
   SLA, Rate Contract, Retainer, Per-Call, Turnkey, BOT/BOOT
   → Wizard adapts based on what blocks are added
   → Industries: Cross-cutting, any industry
```

Total: **21 nomenclature types** (up from 15)

---

## UPDATED WIZARD ROUTING LOGIC

```
User selects nomenclature → system reads form_settings flags:

IF is_equipment_based = true AND is_entity_based = false:
  → Show Step 4: Equipment Picker
  → Skip Entity Picker
  → Examples: AMC, CMC, PMC, BMC, CAMC, Warranty Ext

IF is_entity_based = true AND is_equipment_based = false:
  → Show Step 4: Entity/Property Picker
  → Skip Equipment Picker
  → Examples: FMC, Manpower

IF is_equipment_based = true AND is_entity_based = true:
  → Show Step 4: Equipment Picker + Entity Picker (tabs or sequential)
  → Examples: O&M, Turnkey, BOT/BOOT

IF is_service_based = true:
  → Skip Equipment Picker
  → Skip Entity Picker
  → Step 4 becomes: Deliverable Builder (enhanced version of existing Step 6)
    - Pre-structured for session/deliverable entry
    - Shows: "What deliverables does this package include?"
    - Entry format: [Service Name] × [Quantity] per [Cycle] for [Duration]
    - Example: "Gynec Consultation × 4 per month for 3 months = 12 total"
  → Examples: Service Package, Care Plan, Subscription, Consultation, Training

IF wizard_route = "milestones":
  → Skip Equipment/Entity Picker
  → Step 4 becomes: Milestone Builder
    - Define project phases with deliverables and payment triggers
  → Examples: Project-Based, Turnkey

IF none of the above (Flexible/Hybrid):
  → Show all options as available but not required
  → User adds what's relevant through blocks
  → Examples: SLA, Rate Contract, Retainer, Per-Call
```

---

## UPDATED SMART SUGGESTION LOGIC

```
INDUSTRY = Healthcare + SEGMENT = Biomedical:
  → Promote: AMC, CMC, PMC
  → Show: Service Package, Care Plan (dimmed, available)

INDUSTRY = Healthcare + SEGMENT = Wellness:
  → Promote: Service Package, Care Plan, Subscription
  → Show: AMC (dimmed — wellness centers have treadmills, therapy machines)

INDUSTRY = Healthcare + SEGMENT = Hospital Administration:
  → Promote: AMC, CMC, FMC, Manpower
  → Show: Care Plan, SLA

INDUSTRY = Real Estate:
  → Promote: FMC, Manpower, O&M
  → Show: AMC (for equipment in buildings — elevators, DG sets, pumps)

INDUSTRY = Technology:
  → Promote: Subscription, SLA, Consultation, Project-Based
  → Show: AMC (for server/network equipment), Retainer

INDUSTRY = Legal / Finance:
  → Promote: Consultation, Retainer
  → Show: Subscription, Training

INDUSTRY = Education / Training:
  → Promote: Training, Project-Based
  → Show: Subscription, Consultation

INDUSTRY = Manufacturing:
  → Promote: AMC, PMC, BMC, Rate Contract
  → Show: Manpower, FMC (for factory premises)

INDUSTRY = Beauty / Salon:
  → Promote: Service Package, Subscription
  → Show: Care Plan (for skin treatment programs)

CROSS-CHECK (what blocks are added):
  → Equipment blocks present → suggest equipment nomenclature
  → Entity blocks present → suggest entity nomenclature
  → Only service deliverable blocks → suggest service nomenclature
  → Mix of types → suggest Hybrid/SLA/O&M
```

---

## IMPACT ON UX PROTOTYPES

### File 01 (Nomenclature Picker) — UPDATE REQUIRED
- Add 4th group "💼 Service Delivery Contracts"
- Add 6 new cards (Service Package, Care Plan, Subscription, Consultation, Training, Project-Based)
- Smart suggestion banner should work for wellness/consulting industries too
- Industry tabs should include: Wellness, Consulting, IT, Legal, Education

### File 04 (Enhanced Wizard) — UPDATE REQUIRED
- Add 3rd routing path: nomenclature is service-based → show Deliverable Builder
- Deliverable Builder is a promoted version of existing service blocks:
  - Clean entry: Service Name × Quantity per Cycle for Duration
  - Auto-total: "12 Gynec + 6 Diet Charts + 12 Yoga = 30 deliverables over 3 months"
  - Auto-event-generation: timeline showing each session/deliverable as a scheduled event
  - Calendar preview: "Feb: 4 Gynec, 2 Diet Chart, 4 Yoga | Mar: 4 Gynec, 2 Diet Chart, 4 Yoga | Apr: ..."

### File 06 (Buyer Experience) — UPDATE REQUIRED
- Buyer dashboard should work for service-delivery contracts too:
  - "My Active Plans: PCOD Balance (3 months), Diabetes Management (6 months)"
  - "Upcoming: Gynec Consultation — Feb 18 | Yoga Session — Feb 20"
  - "Progress: 8 of 30 deliverables completed (27%)" with progress bar
  - "Evidence: Diet Chart #3 uploaded on Feb 10" — deliverable proof

### New File Suggestion: `07-service-package-builder.html` — **[P0 + existing]**
- Dedicated prototype showing the wellness/professional services flow
- A practitioner creating "Pregnancy Care Package":
  1. Picks "Service Package" nomenclature
  2. Adds deliverables: 4 Gynec/month, 2 Diet Charts/month, 4 Yoga/month
  3. Sets duration: 3 months
  4. Sees auto-calculated: 12 + 6 + 12 = 30 total sessions, ₹12,000
  5. Sends to patient
  6. Patient sees: calendar of upcoming sessions, progress tracker, evidence gallery
- This prototype validates that the nomenclature system works for NON-maintenance contracts

---

## KEY ARCHITECTURAL NOTE

**The service-based nomenclature does NOT require new tables.** It uses:
- `m_category_details` (same LOV table, 6 more rows)
- `t_contract_blocks` (existing — quantity × cycle × unit_price)
- `t_contract_events` (existing — auto-generated from block cycles)
- `t_service_tickets` (existing — per-event execution and evidence)

The only change is **routing logic in the wizard** and **framing in the UI**. When a wellness practitioner picks "Care Plan", the wizard should:
1. Skip equipment/entity steps entirely
2. Show the deliverable builder step (which IS the existing service blocks step, just labeled differently and pre-structured for session entry)
3. Show a calendar-style event preview instead of a Gantt chart

This is important: **adding service-based nomenclature is almost zero additional code.** It's mostly seed data + wizard routing + UI labels. The heaviest implementation (P1/P2 equipment and entity tables) is NOT needed for this segment. A wellness practitioner can use ContractNest productively with ONLY P0 shipped.

---

## REVISED NOMENCLATURE COUNT

| Group | Count | Types |
|-------|-------|-------|
| 🔧 Equipment Maintenance | 6 | AMC, CMC, CAMC, PMC, BMC, Warranty Ext |
| 🏢 Facility & Property | 3 | FMC, O&M, Manpower |
| 💼 Service Delivery | 6 | Service Package, Care Plan, Subscription, Consultation, Training, Project-Based |
| 🔀 Flexible / Hybrid | 6 | SLA, Rate Contract, Retainer, Per-Call, Turnkey, BOT/BOOT |
| **Total** | **21** | |

---

## WHY THIS MATTERS FOR GO-TO-MARKET

ContractNest can now credibly serve 4 market segments from Day 1:

1. **Maintenance companies** → AMC/CMC/PMC → equipment contracts
2. **Facility managers** → FMC/O&M/Manpower → property contracts  
3. **Wellness/healthcare practitioners** → Service Package/Care Plan → deliverable contracts
4. **Professional services** → Consultation/Subscription/Retainer → time/session contracts

Segment 3 and 4 are likely **easier to acquire** (smaller businesses, lower decision complexity, faster onboarding) and can use the product with **only P0 shipped** (no equipment or entity tables needed). This makes them ideal early adopter targets while P1/P2 equipment/entity features are built for the enterprise maintenance segment.