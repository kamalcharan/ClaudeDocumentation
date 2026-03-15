# Template Generation Rules

## 1. Nomenclature → Block Assembly Map

Each contract nomenclature has a standard block structure. The agent MUST follow these patterns as the baseline, then add resource-specific blocks as needed.

### AMC — Annual Maintenance Contract

**Use when:** Equipment requires regular preventive maintenance with limited breakdown support.

```
REQUIRED BLOCKS (in order):
1. Service Block: "Scheduled PM Visit"
   - frequency: quarterly or monthly (based on resource.maintenance_schedule)
   - pricing: per_visit or fixed_annual
   - evidence: photo=true, signature=true, timestamp=true
   - SmartForm: pre_service (inspection checklist) + post_service (completion report)

2. Service Block: "Breakdown / Emergency Support"
   - frequency: on_demand
   - pricing: per_call or included (config.included_calls per year)
   - evidence: photo=true, signature=true, gps=true
   - SmartForm: post_service (breakdown report)

3. Spare Block: "Parts & Consumables"
   - pricing: excluded (billed separately) OR discount_percent on list price
   - config: { "coverage": "limited", "discount_percent": 10, "exclusions": ["wear_and_tear"] }

4. Billing Block: "Annual Pricing"
   - pricing: fixed_annual
   - config: { "payment_terms": "quarterly_advance", "auto_renewal": true }

OPTIONAL BLOCKS (add based on resource attributes):
5. Service Block: "Calibration Service" — if resource.requires_calibration = true
   - frequency: semi_annual or annual
   - SmartForm: during (calibration log with measurements)

6. Text Block: "Scope of Work"
   - config: { "content_type": "rich_text", "editable": true }

7. Text Block: "Exclusions & Limitations"

8. Checklist Block: "Equipment Covered"
   - config: { "fields": ["equipment_name", "serial_number", "location", "condition"] }

9. Text Block: "Penalty / SLA Terms"
   - config: { "sla_response_hours": 4, "sla_resolution_hours": 24 }
```

**Pricing formula:**
- Base: resource.pricing_guidance.typical_amc_percent_of_cost × estimated_equipment_cost
- If no equipment cost → use resource.pricing_guidance.suggested_hourly_rate × estimated_hours_per_year
- Default tax: 18% GST (INR), configurable per currency

---

### CMC — Comprehensive Maintenance Contract

**Use when:** Equipment requires all-inclusive maintenance with unlimited breakdown support and parts included.

```
REQUIRED BLOCKS:
1. Service Block: "Comprehensive PM Visit" — all-inclusive, scheduled
2. Service Block: "Unlimited Breakdown Support" — no call limit
3. Service Block: "Calibration & Validation" — if applicable
4. Spare Block: "All Parts Included" — coverage=comprehensive, labor+parts
5. Spare Block: "Consumables Included" — replacement items
6. Billing Block: "Fixed Monthly/Quarterly" — no variable component

OPTIONAL BLOCKS:
7. Text Block: "Comprehensive Scope"
8. Text Block: "Force Majeure Exclusions" — minimal exclusions
9. Checklist Block: "Full Equipment Register"
10. Document Block: "Condition Assessment Report"
```

**Pricing:** Typically 1.5-2x AMC price (since parts are included).

---

### CAMC — Comprehensive Annual Maintenance Contract

**Use when:** Government / PSU procurement. Same as CMC but with additional compliance blocks.

```
REQUIRED BLOCKS: Same as CMC, PLUS:
- Text Block: "GeM / GFR Compliance Terms"
- Checklist Block: "Government Compliance Checklist"
- Document Block: "Performance Bank Guarantee"
```

---

### FMC — Facility Management Contract

**Use when:** Managing an entire facility (building, campus, hospital) with multiple service lines.

```
REQUIRED BLOCKS:
1. Service Block: "Housekeeping Services"
   - config: { "coverage": "daily", "staff_count": N, "shifts": ["morning", "evening"] }
   - SmartForm: during (daily inspection checklist)

2. Service Block: "Technical Maintenance"
   - config: { "covers": ["HVAC", "electrical", "plumbing", "fire_safety"] }
   - SmartForm: post_service (maintenance log)

3. Service Block: "Security Services"
   - config: { "deployment": "24x7", "guard_count": N }

4. Service Block: "Landscaping & Pest Control"
   - frequency: weekly (landscaping), quarterly (pest control)

5. Spare Block: "Consumables & Supplies"
   - config: { "includes": ["cleaning_supplies", "toiletries", "stationery"] }

6. Billing Block: "Monthly Fixed + Variable"
   - config: { "fixed_component": 80, "variable_component": 20 }

OPTIONAL BLOCKS:
7. Service Block: "Pantry / Cafeteria Management"
8. Service Block: "Waste Management"
9. Text Block: "Staff Deployment Plan"
10. Text Block: "SLA Matrix" — per service line
11. Text Block: "Penalty Framework"
12. Checklist Block: "Daily Inspection Checklist"
13. Checklist Block: "Monthly Audit Checklist"
14. Document Block: "Staff Deployment Register"
```

---

### Care Plan — Healthcare/Wellness Package

**Use when:** Bundled healthcare or wellness services for patients/clients.

```
REQUIRED BLOCKS:
1. Service Block: "Consultation Sessions"
   - config: { "session_count": N, "session_duration_minutes": 30 }
   - SmartForm: post_service (consultation notes)

2. Service Block: "Therapy / Treatment Sessions"
   - config: { "session_count": N, "type": "physiotherapy|yoga|nutrition" }
   - SmartForm: during (treatment record)

3. Service Block: "Diagnostic Services"
   - config: { "tests_included": ["blood_work", "imaging", "vitals"] }
   - SmartForm: post_service (test results)

4. Billing Block: "Package Pricing"
   - config: { "payment_options": ["full_advance", "emi_monthly", "per_session"] }

OPTIONAL BLOCKS:
5. Spare Block: "Medicines & Consumables"
6. Text Block: "Treatment Protocol"
7. Text Block: "Expected Outcomes & Disclaimers"
8. Checklist Block: "Session Tracker"
9. Document Block: "Medical Reports"
```

---

### SLA — Service Level Agreement

```
REQUIRED BLOCKS:
1. Service Block: "Primary Service Delivery"
   - config: { "priority_levels": {"P1": "2hr", "P2": "4hr", "P3": "8hr", "P4": "24hr"} }

2. Service Block: "Monitoring & Reporting"
   - frequency: monthly
   - SmartForm: during (SLA performance report)

3. Billing Block: "Retainer + Penalty Adjustments"
   - config: { "base_retainer": true, "penalty_deduction": true, "credit_mechanism": true }

4. Text Block: "SLA Definitions & Targets"
5. Text Block: "Penalty & Credit Framework"
6. Text Block: "Governance & Review"
7. Checklist Block: "Monthly SLA Review"
```

---

### Manpower — Staffing Contract

```
REQUIRED BLOCKS:
1. Service Block: "Staff Deployment"
   - config: { "roles": [...], "count_per_role": N, "shifts": [...] }

2. Service Block: "Replacement / Substitute"
   - config: { "replacement_within_hours": 4 }

3. Billing Block: "Per Head Per Month"
   - config: { "includes": ["salary", "pf", "esi", "bonus", "uniform"] }

4. Text Block: "Roles & Responsibilities"
5. Text Block: "Attendance & Leave Policy"
6. Text Block: "Statutory Compliance (PF/ESI/Wages)"
7. Checklist Block: "Monthly Compliance Checklist"
8. Document Block: "Attendance Register"
```

---

### On-Demand / Per-Call / Rate Contract

```
REQUIRED BLOCKS:
1. Service Block: "Service Call"
   - frequency: on_demand
   - pricing: per_call or per_hour
   - SmartForm: post_service (service report)

2. Billing Block: "Per-Call / Per-Hour Billing"
   - config: { "min_billing_hours": 1, "travel_charges": true }

3. Text Block: "Terms of Service"
```

---

### Service Package

```
REQUIRED BLOCKS:
1. Service Block: "Primary Service" (× quantity included in package)
2. Service Block: "Secondary Service" (if bundled)
3. Billing Block: "Package Price"
   - config: { "validity_days": 90, "transferable": false }
4. Text Block: "Package Inclusions & Exclusions"
```

---

## 2. Block Assembly Order

Regardless of nomenclature, blocks MUST be ordered in this sequence:

```
Position 1-N:   Service Blocks (ordered by frequency: scheduled first, then on-demand)
Position N+1-M: Spare / Parts Blocks
Position M+1:   Billing Block (always one, consolidates all pricing)
Position M+2+:  Text Blocks (scope, terms, exclusions, penalties)
Position last-1: Checklist Blocks
Position last:   Document Blocks
```

## 3. Evidence Requirements Matrix

| Block Type | Photo | Video | Signature | GPS | Timestamp |
|-----------|:-----:|:-----:|:---------:|:---:|:---------:|
| PM / Scheduled Service | ✅ | ○ | ✅ | ○ | ✅ |
| Breakdown / Emergency | ✅ | ○ | ✅ | ✅ | ✅ |
| Calibration | ✅ | ○ | ✅ | ○ | ✅ |
| Inspection / Audit | ✅ | ✅ | ✅ | ✅ | ✅ |
| Housekeeping | ✅ | ○ | ○ | ○ | ✅ |
| Security | ○ | ○ | ✅ | ✅ | ✅ |
| Consultation | ○ | ○ | ✅ | ○ | ✅ |
| Parts Replacement | ✅ | ○ | ✅ | ○ | ✅ |

✅ = Required, ○ = Optional (include if resource context warrants it)

## 4. Currency & Tax Configuration

| Currency | Default Tax Rate | Tax Name | Region |
|----------|:---------------:|----------|--------|
| INR | 18% | GST | India |
| USD | 0% | Sales Tax (varies) | USA |
| AED | 5% | VAT | UAE |
| GBP | 20% | VAT | UK |
| EUR | 19% | VAT | EU (DE) |
| SGD | 9% | GST | Singapore |
| SAR | 15% | VAT | Saudi Arabia |

When generating multi-currency templates:
- Base pricing in primary currency (first in array)
- Conversion rates are NOT embedded — tenants handle conversion
- Tax rates are set per currency in the billing block config

## 5. Complexity Classification

| Complexity | Block Count | SmartForm Count | Typical Nomenclatures |
|-----------|:----------:|:--------------:|----------------------|
| Simple | 3-4 | 0-1 | On-Demand, Per-Call, Rate Contract |
| Medium | 5-7 | 2-3 | AMC, Care Plan, Service Package |
| Complex | 8+ | 4+ | CMC, FMC, CAMC, SLA |

## 6. Event Schedule Generation

For each service block with a defined frequency, generate an event schedule entry:

```json
{
  "event_type": "preventive_maintenance",  // Matches m_event_status_config.event_type
  "frequency": "quarterly",
  "description": "Scheduled PM visit — inspect, test, maintain",
  "generates_smartform": true,
  "estimated_duration_hours": 4
}
```

Standard event types: `preventive_maintenance`, `breakdown_call`, `calibration`, `inspection`, `audit`, `consultation`, `service_visit`, `deployment_check`
