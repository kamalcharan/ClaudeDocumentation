# VaNi for ContractNest - Implementation Plan
**Start Date:** February 2026  
**Duration:** 16 weeks  
**Customers:** Home Health, Women's Health, AC Systems

## Executive Summary

Build AI agent system that automatically:
- Extracts commitments from contracts (service schedules, billing terms, SLAs)
- Generates events (appointments, invoices, alerts)  
- Executes actions (calendar creation, invoice generation, notifications)
- Monitors compliance (tracks performance, flags issues)

**Success:** >85% extraction accuracy, 90%+ automation rate, 70%+ time saved

---

## Architecture

```
ContractNest (Existing) 
    ↓ contract uploaded
PostgreSQL Orchestration Layer (New)
    ↓ commitments extracted
VaNi Agents (Python)
    ├── Extraction Agent (Claude LLM + patterns)
    ├── Event Generation Agent (recurring logic)
    ├── Action Execution Agent (API calls)
    ├── Compliance Monitor (performance tracking)
    └── Learning Agent (pattern improvement)
    ↓ actions executed
External Systems (Calendar, QuickBooks, Email)
```

---

## Database Schema (PostgreSQL)

### Core Tables

**contract_commitments** - Extracted from contracts
- commitment_type: scheduled_service | billing_event | emergency_sla | renewal_alert
- commitment_details: JSONB (flexible per domain)
- recurrence_rule: iCalendar format
- extraction_confidence: 0-1 score
- status: active | completed | cancelled

**commitment_events** - Generated from commitments  
- event_type: appointment | billing_trigger | alert | compliance_check
- scheduled_datetime, event_details (JSONB)
- status: pending | scheduled | completed | missed
- parent_event_id: for recurring events

**agent_actions** - Executed actions
- action_type: calendar_create | invoice_generate | notification_send
- target_system: google_calendar | quickbooks | sendgrid
- action_payload, result_data (JSONB)
- status: success | failed | retry

**compliance_tracking** - Performance monitoring
- requirement_type: service_completion | sla_response | documentation  
- due_datetime, actual_completion_datetime
- compliance_status: compliant | late | missing | at_risk
- performance_data (JSONB), penalty_amount

**extraction_patterns** - Pattern library
- pattern_name, applies_to_domains, pattern_definition (JSONB)
- confidence_score, times_used, times_successful
- Created by system, updated by learning

---

## Implementation Phases

### Phase 1: Home Health (Weeks 1-4)

**Week 1: Foundation**
- PostgreSQL schema + seed patterns
- FastAPI framework
- Database connection module

**Week 2: Extraction Agent**  
- PDF/Word text extraction
- Claude API integration
- Pattern-based extraction
- Confidence scoring

**Week 3: Event Generation + Actions**
- Recurring event logic
- Google Calendar integration
- Email notifications (SendGrid)

**Week 4: Testing**
- Process 10 Home Health contracts
- Measure accuracy (target >85%)
- Deploy to staging

**Deliverables:**
✓ 10 contracts processed
✓ Appointments in calendar
✓ Email notifications sent
✓ 3-4 proven patterns

---

### Phase 2: Women's Health (Weeks 5-8)

**Week 5-6: Pattern Expansion**
- Prenatal progressive scheduling
- Insurance billing pattern
- Prior authorization workflow

**Week 7: Accounting Integration**
- QuickBooks API
- Invoice generation
- AR tracking

**Week 8: Testing**
- Process 10 Women's Health contracts
- Validate pattern reuse (60-70%)
- Pattern confidence >0.8

**Deliverables:**
✓ 20 total contracts
✓ Insurance verification automated
✓ Invoices in QuickBooks
✓ Pattern library confidence scores

---

### Phase 3: AC Systems (Weeks 9-12)

**Week 9-10: Cross-Domain**
- HVAC seasonal patterns
- Equipment tracking
- Emergency SLA monitoring

**Week 11: Compliance**
- Compliance monitoring agent
- Performance dashboards
- SLA breach alerts

**Week 12: Testing**
- Process 10 HVAC contracts
- Validate 70-80% auto-config
- Cross-domain pattern validation

**Deliverables:**
✓ 30 total contracts
✓ Works across 3 domains
✓ Compliance monitoring live

---

### Phase 4: Production (Weeks 13-16)

**Week 13: Learning Agent**
- Human feedback loop
- Pattern auto-updates
- Confidence adjustments

**Week 14: Monitoring**
- Prometheus metrics
- Grafana dashboards
- Alert rules

**Week 15: Documentation**
- API docs
- User guides
- Team training

**Week 16: Launch**
- Production deployment
- All 3 customers live
- 24/7 monitoring

---

## Pattern Library (Initial 6 Patterns)

### 1. scheduled_service_recurring
- **Domains:** home_health, womens_health, hvac
- **Keywords:** weekly, monthly, quarterly, visit, appointment, maintenance
- **Extracts:** service_name, frequency, days_of_week, time_window, duration
- **Generates:** Recurring calendar appointments
- **Example:** "Nurse visits every Monday/Wednesday 2-4 PM"

### 2. billing_event_recurring  
- **Domains:** home_health, womens_health, hvac
- **Keywords:** bill, invoice, payment, monthly, per visit, net 30
- **Extracts:** billing_type, amount, frequency, payer_type, payment_terms
- **Generates:** Invoice triggers (per-service, monthly, quarterly)
- **Example:** "Bill $150 per visit, Net 30 to insurance"

### 3. healthcare_insurance_billing
- **Domains:** home_health, womens_health  
- **Keywords:** insurance, medicare, prior authorization, copay, eligibility
- **Extracts:** payer_name, requires_prior_auth, patient_copay
- **Generates:** Eligibility check → Prior auth → Claim submission
- **Example:** "Medicare requires prior auth, $25 copay"

### 4. emergency_sla
- **Domains:** home_health, womens_health, hvac
- **Keywords:** emergency, urgent, 24/7, response time, within X hours
- **Extracts:** response_time_hours, availability, penalty_per_hour
- **Generates:** Real-time SLA monitoring
- **Example:** "4-hour emergency response, $100/hr penalty"

### 5. hvac_seasonal_service
- **Domains:** hvac
- **Keywords:** seasonal, pre-summer, pre-winter, spring, fall tune-up
- **Extracts:** season_trigger, months, equipment_covered
- **Generates:** Seasonal appointments (April-May, October-November)
- **Example:** "Pre-summer AC tune-up in April-May"

### 6. renewal_alert
- **Domains:** home_health, womens_health, hvac
- **Keywords:** renewal, auto-renew, contract term, notice period
- **Extracts:** contract_term_months, auto_renews, notice_period_days
- **Generates:** Alerts at 90/60/30 days before renewal
- **Example:** "12-month term, auto-renews, 30-day notice to cancel"

---

## Agent Components

### 1. Extraction Agent
**Input:** Contract ID from ContractNest  
**Process:**
1. Get contract from ContractNest DB
2. Extract text (PDF/Word)
3. Load patterns for tenant domain
4. Call Claude API with pattern prompts
5. Parse structured output
6. Calculate confidence score
7. Save to contract_commitments table
8. If confidence <0.8 → human review queue

**Output:** Commitments in PostgreSQL

---

### 2. Event Generation Agent
**Input:** Commitment from contract_commitments  
**Process:**
1. Get commitment details
2. Apply pattern rules
3. Generate events based on type:
   - scheduled_service → recurring appointments
   - billing_event → invoice triggers
   - emergency_sla → monitoring rule
   - renewal_alert → reminder alerts
4. Apply recurrence rules (iCalendar RRULE)
5. Save to commitment_events table

**Output:** Events in PostgreSQL

---

### 3. Action Execution Agent
**Input:** Event from commitment_events (when due)  
**Process:**
1. Get event details
2. Execute based on type:
   - appointment → Google Calendar API
   - billing_trigger → QuickBooks API
   - alert → SendGrid email
3. Handle retries (exponential backoff)
4. Log to agent_actions table
5. Update event status

**Output:** API calls + action records

---

### 4. Compliance Monitoring Agent  
**Input:** Completed events + external data  
**Process:**
1. Check at-risk commitments (due soon, not scheduled)
2. Check missed commitments (past due, not completed)
3. Check SLA performance (response time vs requirement)
4. Calculate penalties/credits
5. Save to compliance_tracking table
6. Send alerts for breaches

**Output:** Compliance records + alerts

---

### 5. Learning Agent
**Input:** Human feedback from UI  
**Process:**
1. Compare agent extraction vs human correction
2. Identify pattern failures
3. Update pattern keywords/prompts
4. Adjust confidence scores
5. Mark feedback as applied

**Output:** Updated patterns

---

## Day 1 Build Plan (Tomorrow)

### Morning (4 hours)
```bash
# 1. Create PostgreSQL database
createdb vani_orchestration

# 2. Run schema (provided in full plan)
psql vani_orchestration < schema.sql

# 3. Install dependencies
pip install fastapi uvicorn psycopg2-binary anthropic PyPDF2 python-docx

# 4. Test connection
python test_db_connection.py
```

### Afternoon (4 hours)
```bash
# 5. Create project structure
mkdir -p src/{api,agents,database,patterns,integrations}

# 6. Seed pattern library
python scripts/seed_patterns.py

# 7. Start FastAPI
uvicorn src.api.main:app --reload

# 8. Test health endpoint
curl http://localhost:8000/health
```

**End of Day 1:** PostgreSQL running, patterns loaded, API responding

---

## Tech Stack

**Database:** PostgreSQL 16 (orchestration layer)  
**Backend:** Python 3.11, FastAPI, Celery  
**LLM:** Anthropic Claude Sonnet 4.5  
**Queue:** Redis (Celery backend)  
**Integrations:**
- Google Calendar API
- QuickBooks API  
- SendGrid (email)
- Twilio (SMS)

**Monitoring:** Prometheus, Grafana, Sentry  
**Deployment:** Docker, docker-compose (local), ECS (production)

---

## Success Metrics

### Week 4 (Home Health)
- ✓ 10 contracts → >85% accuracy
- ✓ 90%+ appointments created
- ✓ 0 critical bugs

### Week 8 (Women's Health)  
- ✓ 20 contracts → >85% accuracy
- ✓ Insurance automated
- ✓ Pattern confidence >0.8

### Week 12 (AC Systems)
- ✓ 30 contracts → 70-80% auto-config
- ✓ Compliance monitoring live
- ✓ <5% missed commitments

### Week 16 (Production)
- ✓ All 3 customers live
- ✓ Learning agent improving patterns
- ✓ Foundation for next VaNi clients

---

## Next Steps

**Tomorrow (Day 1):**
1. Setup PostgreSQL + schema
2. Seed pattern library
3. Create FastAPI skeleton
4. Test database connection

**Day 2:**
5. PDF/Word extraction
6. Claude API integration test

**Day 3-4:**
7. Build Extraction Agent
8. Process first sample contract

**Day 5:**
9. Test with 3 Home Health contracts
10. Measure accuracy

**Ready to start building!**

For full technical details, see complete 86KB implementation plan with:
- Complete database schema with all tables/triggers
- Full agent code structure (Python classes)
- Integration API examples (Google Calendar, QuickBooks)
- Day-by-day breakdown for Week 1
- Testing strategy (unit + integration tests)
- Deployment architecture (Docker compose, AWS)