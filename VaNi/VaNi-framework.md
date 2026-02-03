# VaNi Framework
**Vikuna AI Agent Implementation Framework**  
Version 1.0 | January 2026

---

## Executive Summary

**VaNi (Vikuna AI Agents)** is Vikuna Technologies' proprietary methodology for deploying production-grade AI agent systems in healthcare and life sciences enterprises. Unlike generic AI consulting that relies on interviews and guesswork, VaNi combines process mining, domain expertise, and event-driven architecture to deliver measurable automation outcomes in 4-5 months.

**Core Differentiators:**
- **Process Mining First**: Data-driven discovery using Celonis, not interviews
- **Domain-Native**: 10+ years healthcare/life sciences expertise built into every agent
- **Event-Driven Architecture**: Business process semantics (/domain/function/event/outcome)
- **Honest Timelines**: 4-5 months to production-grade systems, not 30-day marketing claims
- **Compliance Built-In**: HIPAA, GxP, SOX audit trails from day one

---

## Table of Contents

1. [Philosophy & Principles](#philosophy--principles)
2. [The VaNi Approach](#the-vani-approach)
3. [Architecture Framework](#architecture-framework)
4. [Standard Operating Procedures](#standard-operating-procedures)
5. [Domain Patterns](#domain-patterns)
6. [Implementation Playbooks](#implementation-playbooks)
7. [Quality Standards](#quality-standards)
8. [Appendix](#appendix)

---

## Philosophy & Principles

### Core Beliefs

**1. Process Mining Before Building**
- Never guess where to automate—prove it with data
- Celonis process mining reveals actual workflows, not documented ones
- Quantified ROI before writing a single line of code
- Variant analysis shows edge cases that interviews miss

**2. Context Is Everything**
> "An agent without good context is just an expensive random number generator."

Agents need three types of context:
- **Historical**: What happened before this task
- **Domain**: What rules, policies, and patterns apply
- **Operational**: What systems, permissions, and constraints exist

**3. Human-in-the-Loop Is Non-Negotiable**
- Agents handle 70-80% of cases automatically
- Agents route 20-30% exceptions to humans with full context
- Never build agents that replace human judgment—build agents that eliminate friction around judgment

**4. Architecture Matters More Than Models**
- Solo vs parallel vs collaborative agent design determines success
- Event-driven architecture scales better than point-to-point integrations
- Audit trails and observability are features, not afterthoughts

**5. Technology-Agnostic Implementation**
- Pattern works with PostgreSQL or Kafka
- Pattern works with Python or Node.js
- Pattern works with on-prem or cloud
- **What matters**: Semantic structure + audit trail + context preservation

**6. Honest Timelines Build Trust**
- 60-90 days discovery + 45-60 days implementation = **4-5 months realistic**
- Pilots that handle 60% → Production that handles 80% → Scale that handles 90%
- No 30-day marketing claims—real production-grade systems take time

---

## The VaNi Approach

### Five-Phase Methodology

```
Phase 1: Process Intelligence (4-6 weeks)
   ↓
Phase 2: Architecture Design (2-3 weeks)
   ↓
Phase 3: Agent Development (6-8 weeks)
   ↓
Phase 4: Pilot Deployment (3-4 weeks)
   ↓
Phase 5: Production Scale (4-6 weeks)

Total: 19-27 weeks (4.5-6 months)
```

### Phase 1: Process Intelligence (4-6 weeks)

**Objective**: Understand actual workflows with data, not interviews

**Activities:**

1. **Process Mining Execution** (Week 1-2)
   - Extract event logs from source systems (Epic, NetSuite, SAP, etc.)
   - Generate process models using Celonis
   - Identify process variants (how work actually flows)
   - Measure cycle times, bottlenecks, rework loops

2. **Opportunity Identification** (Week 2-3)
   - Rank processes by automation potential:
     - High volume (>100 cases/month)
     - High cycle time (>5 days average)
     - High rework rate (>20% require corrections)
     - Rule-based decisions (80% follow patterns)
   - Quantify ROI for top 5 opportunities
   - Calculate: hours saved × hourly rate × annual volume

3. **Context Mapping** (Week 3-4)
   - Map data sources (where does context come from?)
   - Document decision rules (what policies govern decisions?)
   - Identify exceptions (what cases require human review?)
   - Catalog systems (what APIs/databases needed?)

4. **Stakeholder Validation** (Week 4-6)
   - Present findings to process owners
   - Validate automation opportunities
   - Prioritize based on business value + feasibility
   - Select pilot workflow for Phase 3

**Deliverables:**
- Process mining report with variant analysis
- Top 5 automation opportunities with ROI quantification
- Selected pilot workflow with success criteria
- Technical requirements document

**Success Criteria:**
- ✓ Process mining completed on 3-5 target workflows
- ✓ ROI quantified for top 5 opportunities (>$500K annual value)
- ✓ Stakeholder alignment on pilot selection
- ✓ Technical feasibility confirmed (APIs available, data accessible)

---

### Phase 2: Architecture Design (2-3 weeks)

**Objective**: Design event-driven architecture and agent topology

**Activities:**

1. **Event Schema Design** (Week 1)
   - Define semantic structure: `/domain/function/event/outcome`
   - Map business events to system events
   - Design context payloads (what data flows with each event)
   - Define outcome types (success states + exception states)

2. **Agent Topology** (Week 1-2)
   - Decide: Solo, Parallel, or Collaborative agents?
   - Define agent responsibilities (what each agent does)
   - Design handoff protocols (how context flows between agents)
   - Establish confidence thresholds (when to route to humans)

3. **Integration Architecture** (Week 2)
   - Design API adapters for each source system
   - Define permission controls (RBAC for agent actions)
   - Design state management (active context + historical memory)
   - Plan audit trail structure (compliance requirements)

4. **Technology Selection** (Week 2-3)
   - Select event bus (Kafka, EventBridge, RabbitMQ, webhooks)
   - Select state store (PostgreSQL, MongoDB, Redis)
   - Select agent runtime (Python, Node.js, serverless)
   - Select LLM (Claude, GPT-4, domain-specific fine-tuned model)

**Deliverables:**
- Event schema documentation (all events, contexts, outcomes)
- Agent topology diagram (agents, responsibilities, handoffs)
- Integration architecture diagram (systems, APIs, data flows)
- Technology stack specification

**Success Criteria:**
- ✓ Event schema covers 80% of process variants
- ✓ Agent topology reviewed by technical + business stakeholders
- ✓ Integration feasibility confirmed (API access approved)
- ✓ Technology selections align with client infrastructure

---

### Phase 3: Agent Development (6-8 weeks)

**Objective**: Build production-grade agents with testing and guardrails

**Activities:**

1. **Perception Layer** (Week 1-2)
   - Build API adapters for source systems
   - Implement event listeners
   - Build context retrieval functions
   - Test data extraction independently

2. **Decision Logic** (Week 2-4)
   - Build structured decision trees (80% of cases)
   - Implement LLM reasoning for ambiguous cases
   - Embed domain knowledge (policies, guidelines, past decisions)
   - Build confidence scoring
   - Implement human-in-the-loop routing

3. **Action Interface** (Week 3-5)
   - Build tool functions (one action per tool)
   - Implement permission controls
   - Add audit logging (every action logged with context)
   - Build rollback mechanisms (where possible)
   - Implement rate limiting

4. **Memory & State Management** (Week 4-6)
   - Build context window management
   - Implement external memory (historical state)
   - Build handoff protocols (agent-to-agent context passing)
   - Design memory cleanup (retention policies)

5. **Testing & Guardrails** (Week 5-8)
   - Test with synthetic data
   - Test with anonymized production data
   - Implement guardrails (prohibited actions)
   - Add circuit breakers (failure mode handling)
   - Build monitoring and alerting
   - Conduct security review

**Deliverables:**
- Working agent system (all components integrated)
- Test results (unit tests, integration tests, edge case tests)
- Documentation (architecture, APIs, decision logic)
- Monitoring dashboards

**Success Criteria:**
- ✓ Agent handles 80% of test cases correctly
- ✓ Agent routes edge cases to humans with proper context
- ✓ All actions logged with audit trail
- ✓ Security review passed (no unapproved system access)
- ✓ Performance acceptable (< 30 seconds per decision)

---

### Phase 4: Pilot Deployment (3-4 weeks)

**Objective**: Deploy to production with limited volume, measure results

**Activities:**

1. **Production Deployment** (Week 1)
   - Deploy to production environment
   - Configure monitoring and alerting
   - Set up human review queue
   - Enable 10-20% of production volume

2. **Monitoring & Tuning** (Week 1-3)
   - Monitor agent performance daily
   - Review human escalations
   - Tune decision logic based on feedback
   - Adjust confidence thresholds
   - Document new edge cases

3. **Volume Ramp** (Week 2-4)
   - Increase from 10% → 30% → 50% → 80%
   - Validate accuracy at each step
   - Ensure human review capacity adequate
   - Monitor system performance (latency, errors)

4. **ROI Measurement** (Week 3-4)
   - Measure automation rate (% handled automatically)
   - Measure cycle time reduction
   - Measure error rate reduction
   - Calculate actual cost savings
   - Compare to baseline from Phase 1

**Deliverables:**
- Production deployment complete
- Pilot results report (automation rate, cycle time, ROI)
- Lessons learned document
- Production readiness assessment

**Success Criteria:**
- ✓ Agent handles 60-80% of cases automatically
- ✓ Cycle time reduced by 40-60%
- ✓ Error rate < 5%
- ✓ Human reviewers satisfied with escalation quality
- ✓ No compliance violations or security incidents

---

### Phase 5: Production Scale (4-6 weeks)

**Objective**: Expand coverage, handle edge cases, scale to 100% volume

**Activities:**

1. **Edge Case Handling** (Week 1-3)
   - Analyze escalated cases from pilot
   - Build logic for top edge cases
   - Test new logic
   - Deploy incrementally

2. **Coverage Expansion** (Week 2-4)
   - Increase automation rate from 60-80% → 80-90%
   - Add new tools for additional actions
   - Refine decision logic based on patterns
   - Reduce confidence threshold gradually

3. **Scale to 100%** (Week 3-5)
   - Process all incoming volume
   - Monitor performance at scale
   - Tune infrastructure (add capacity if needed)
   - Ensure human review capacity adequate

4. **Continuous Improvement** (Week 4-6)
   - Establish feedback loop
   - Train process owners on agent monitoring
   - Document runbooks for common issues
   - Plan next workflow expansion

**Deliverables:**
- Production-grade agent system (80-90% automation)
- Operations runbook
- Training materials for process owners
- Expansion roadmap (next workflows to automate)

**Success Criteria:**
- ✓ Agent handles 80-90% of cases automatically
- ✓ Cycle time reduced by 60-80%
- ✓ Process owners can monitor/troubleshoot independently
- ✓ System stable at full production volume
- ✓ Continuous improvement process established

---

## Architecture Framework

### Event-Driven Semantic Structure

```
/domain/function/event/outcome

Components:
├── domain: Business domain (healthcare, finance, legal, operations)
├── function: Business function within domain
├── event: Business event that occurred
└── outcome: Result of agent processing
```

### Reference Architecture

```
┌─────────────────────────────────────────────┐
│         Humans + External Systems            │
│  (Approve exceptions, provide feedback)      │
└─────────────────────────────────────────────┘
                    ↕
┌─────────────────────────────────────────────┐
│           AGENT LAYER                        │
│                                              │
│  ┌──────────────────────────────────────┐  │
│  │  Agent Pool                           │  │
│  │  ├── Solo Agents (complete workflow) │  │
│  │  ├── Parallel Agents (concurrent)    │  │
│  │  └── Collaborative Agents (handoff)  │  │
│  └──────────────────────────────────────┘  │
│                                              │
│  Agent Components:                           │
│  ├── Perception (observe state)             │
│  ├── Decision Logic (choose action)         │
│  ├── Action Interface (execute)             │
│  ├── Memory (context + history)             │
│  └── Confidence Scoring (route exceptions)  │
└─────────────────────────────────────────────┘
                    ↕
┌─────────────────────────────────────────────┐
│      ORCHESTRATION LAYER                     │
│                                              │
│  ┌──────────────────────────────────────┐  │
│  │   Event Bus                           │  │
│  │   /domain/function/event/outcome      │  │
│  │   - Publish business events           │  │
│  │   - Subscribe to relevant events      │  │
│  │   - Route to appropriate agents       │  │
│  └──────────────────────────────────────┘  │
│                                              │
│  ┌──────────────────────────────────────┐  │
│  │   State Management                    │  │
│  │   ├── Active Context (in-memory)     │  │
│  │   ├── Historical State (database)    │  │
│  │   └── Audit Trail (append-only log)  │  │
│  └──────────────────────────────────────┘  │
│                                              │
│  ┌──────────────────────────────────────┐  │
│  │   API Gateway                         │  │
│  │   ├── System Adapters                │  │
│  │   ├── Permission Controls (RBAC)     │  │
│  │   ├── Rate Limiting                  │  │
│  │   └── Audit Logging                  │  │
│  └──────────────────────────────────────┘  │
└─────────────────────────────────────────────┘
                    ↕
┌─────────────────────────────────────────────┐
│       ENTERPRISE SYSTEMS                     │
│  Epic | Cerner | SAP | NetSuite | Workday   │
│  Salesforce | QuickBooks | Custom Systems   │
└─────────────────────────────────────────────┘
```

### Agent Design Patterns

#### Pattern 1: Solo Agent (Complete Workflow)

**When to use:**
- Simple, linear workflow
- Single source of data
- Clear success criteria
- <10 steps in process

**Architecture:**
```
Event → Solo Agent → [Perceive → Decide → Act] → Outcome

Example: Invoice matching
- Perceive: Retrieve invoice, PO, receipt
- Decide: Compare amounts, check tolerances
- Act: Approve or escalate
```

**Advantages:**
- Simple to build and maintain
- All context in one place
- Easy to debug

**Challenges:**
- Context window can fill up on long workflows
- Single point of failure
- Hard to scale to complex processes

#### Pattern 2: Parallel Agents (Concurrent Processing)

**When to use:**
- Independent sub-tasks
- Need for speed (parallel execution)
- Different expertise required
- Results need aggregation

**Architecture:**
```
Event → Routing Agent → [Agent A, Agent B, Agent C] → Aggregator → Outcome

Example: Claim denial analysis
- Agent A: Check clinical documentation
- Agent B: Review payer policy
- Agent C: Analyze historical appeals
- Aggregator: Synthesize and decide
```

**Advantages:**
- Faster (parallel execution)
- Specialized agents for different tasks
- Scalable (add more agents)

**Challenges:**
- Coordination complexity
- Conflict resolution needed
- More moving parts to maintain

#### Pattern 3: Collaborative Agents (Sequential Handoff)

**When to use:**
- Multi-stage workflow
- Clear dependencies between stages
- Different expertise at each stage
- Context needs to flow through stages

**Architecture:**
```
Event → Agent 1 → Agent 2 → Agent 3 → Outcome

Example: Prior authorization
- Agent 1: Triage (classify urgency, check guidelines)
- Agent 2: Clinical Review (assess medical necessity)
- Agent 3: Submission (format and submit to payer)
```

**Advantages:**
- Natural mapping to multi-stage processes
- Clear responsibility boundaries
- Easy to add stages

**Challenges:**
- Context handoff critical
- Failure propagation
- Latency (sequential execution)

### Context Management Patterns

#### Active Context (Working Memory)
```json
{
  "context_id": "ctx-2026-001",
  "workflow_id": "denials-rcm-789",
  "created_at": "2026-01-22T10:30:00Z",
  "active": true,
  "workflow_stage": "appeal-drafting",
  "agent": "rcm-denials-agent",
  
  "business_context": {
    "patient_id": "P123456",
    "claim_id": "CLM-789",
    "denial_code": "CO-16",
    "payer": "UnitedHealthcare",
    "amount": 15240.00
  },
  
  "decisions_made": [
    {
      "step": 1,
      "action": "classified_denial_type",
      "result": "missing_documentation",
      "confidence": 0.91
    },
    {
      "step": 2,
      "action": "retrieved_prior_auth",
      "result": "found_in_epic",
      "confidence": 1.0
    }
  ],
  
  "current_task": {
    "step": 3,
    "action": "drafting_appeal",
    "template": "CO-16-prior-auth-template",
    "status": "in_progress"
  }
}
```

#### External Memory (Long-Term Storage)
```json
{
  "memory_id": "mem-2026-001",
  "workflow_id": "denials-rcm-789",
  "status": "completed",
  "completed_at": "2026-01-22T10:35:00Z",
  
  "summary": {
    "event": "claim-denied",
    "outcome": "appeal-drafted-and-submitted",
    "cycle_time_minutes": 5.2,
    "agent": "rcm-denials-agent",
    "human_involved": false
  },
  
  "full_context": {
    // Complete active context at time of completion
  },
  
  "lessons_learned": {
    "denial_type": "missing_documentation",
    "resolution_method": "retrieved_prior_auth_from_epic",
    "success": true,
    "reusable_pattern": true
  }
}
```

#### Context Handoff (Agent-to-Agent)
```json
{
  "handoff_id": "ho-2026-001",
  "from_agent": "triage-agent",
  "to_agent": "clinical-review-agent",
  "timestamp": "2026-01-22T11:00:00Z",
  
  "inherited_context": {
    // All context from previous agent
    "patient_id": "P789012",
    "request_type": "prior_auth",
    "procedure": "MRI lumbar spine",
    "urgency": "routine"
  },
  
  "handoff_metadata": {
    "reason": "clinical_review_required",
    "triage_result": "meets_basic_criteria",
    "next_action_required": "assess_medical_necessity",
    "confidence": 0.85,
    "flags": ["new_diagnosis", "high_cost_procedure"]
  },
  
  "resources": {
    "clinical_docs": ["office_note_2026-01-20", "xray_report_2026-01-18"],
    "payer_guidelines": "Aetna-MRI-Policy-2026-v2",
    "patient_history": "summary_last_6_months"
  }
}
```

---

## Standard Operating Procedures

### SOP-001: Client Engagement Process

**Objective**: Standardized process from initial contact to signed SOW

**Process:**

1. **Initial Contact** (Day 0)
   - Inbound lead or outbound outreach
   - Qualify: Healthcare/life sciences? $30M+ revenue? Process pain points?
   - If qualified → Schedule discovery call

2. **Discovery Call** (Week 1)
   - Understand business challenges
   - Identify potential automation opportunities
   - Assess tech stack (what systems?)
   - Determine if process mining or direct approach
   - Next step: Process Mining Workshop or Architecture Workshop

3. **Process Mining Workshop** (Week 2-3, Optional but Recommended)
   - 2-week process mining engagement
   - Extract event logs from 3-5 target systems
   - Generate process models
   - Identify top 3 automation opportunities
   - Present ROI analysis
   - **Fee**: $25-50K (credited toward full engagement)

4. **Proposal & SOW** (Week 3-4)
   - Present full VaNi proposal
   - Timeline: 4-5 months
   - Pricing: $150-300K depending on scope
   - Include: Discovery, Design, Development, Pilot, Scale
   - Success metrics defined upfront

5. **Kickoff** (Week 5)
   - Contract signed
   - Team assembled
   - Begin Phase 1 (Process Intelligence)

**Deliverables:**
- Discovery call notes
- Process mining report (if applicable)
- Signed Statement of Work
- Project charter

**Success Criteria:**
- ✓ Clear business case with ROI
- ✓ Technical feasibility confirmed
- ✓ Stakeholder alignment achieved
- ✓ Budget and timeline approved

---

### SOP-002: Process Mining Execution

**Objective**: Extract actionable insights from enterprise systems using Celonis

**Prerequisites:**
- Access to source systems (read-only)
- Event log extraction permissions
- Stakeholder availability for validation

**Process:**

1. **Scope Definition** (Day 1-2)
   - Select 3-5 processes to mine
   - Identify source systems for each process
   - Define success metrics (cycle time, error rate, rework)
   - Set up secure data environment

2. **Data Extraction** (Day 3-7)
   - Configure Celonis extractors
   - Extract event logs from source systems
   - Validate data quality (completeness, accuracy)
   - Anonymize PII if required

3. **Process Model Generation** (Day 8-10)
   - Load data into Celonis
   - Generate process models
   - Identify process variants
   - Calculate performance metrics

4. **Analysis** (Day 11-14)
   - Bottleneck analysis (where do cases get stuck?)
   - Variant analysis (how many different paths?)
   - Rework analysis (what % require corrections?)
   - Conformance checking (documented vs actual)

5. **Opportunity Identification** (Day 15-17)
   - Rank opportunities by:
     - Volume (cases per month)
     - Cycle time (days per case)
     - Rework rate (% requiring manual intervention)
     - Rule-based (% following clear patterns)
   - Calculate ROI for top 5 opportunities
   - Validate with stakeholders

6. **Reporting** (Day 18-20)
   - Prepare executive summary
   - Create detailed findings document
   - Include recommendations with ROI
   - Present to stakeholders

**Deliverables:**
- Process mining dashboard (Celonis)
- Process variant analysis
- Top 5 automation opportunities
- ROI quantification
- Technical requirements document

**Success Criteria:**
- ✓ Event logs extracted successfully
- ✓ Process models validated by process owners
- ✓ At least 3 viable automation opportunities identified
- ✓ ROI >$500K annually for top opportunity

**Tools:**
- Celonis Process Mining
- Database query tools (SQL)
- Data anonymization tools (if required)
- Visualization tools (for presentations)

---

### SOP-003: Agent Development Lifecycle

**Objective**: Build production-grade agents following quality standards

**Prerequisites:**
- Architecture design approved
- Event schema documented
- API access confirmed

**Process:**

1. **Setup** (Day 1-3)
   ```bash
   # Initialize project structure
   mkdir -p vani-agent-{domain}
   cd vani-agent-{domain}
   
   # Create standard directories
   mkdir -p {src,tests,docs,config,logs}
   mkdir -p src/{perception,decision,action,memory}
   
   # Initialize git
   git init
   git remote add origin {repo_url}
   
   # Setup environment
   python -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt
   ```

2. **Perception Layer** (Day 4-10)
   ```python
   # src/perception/event_listener.py
   
   class EventListener:
       """Listen for business events from event bus"""
       
       def __init__(self, event_bus, event_patterns):
           self.event_bus = event_bus
           self.event_patterns = event_patterns
       
       def subscribe(self):
           """Subscribe to relevant event topics"""
           for pattern in self.event_patterns:
               self.event_bus.subscribe(pattern, self.handle_event)
       
       def handle_event(self, event):
           """Process incoming event"""
           # Extract event data
           # Retrieve context
           # Pass to decision layer
   
   # src/perception/context_retriever.py
   
   class ContextRetriever:
       """Retrieve context from source systems"""
       
       def __init__(self, api_adapters):
           self.api_adapters = api_adapters
       
       def retrieve(self, event):
           """Get all relevant context for event"""
           context = {}
           
           # Get context from each source
           for source in self.get_context_sources(event):
               context[source] = self.api_adapters[source].fetch(event)
           
           return context
   ```

3. **Decision Logic** (Day 11-20)
   ```python
   # src/decision/decision_engine.py
   
   class DecisionEngine:
       """Make decisions based on event + context"""
       
       def __init__(self, rules_engine, llm_client, domain_knowledge):
           self.rules = rules_engine
           self.llm = llm_client
           self.knowledge = domain_knowledge
       
       def decide(self, event, context):
           """Determine action to take"""
           
           # Try structured rules first (80% of cases)
           decision = self.rules.evaluate(event, context)
           if decision.confidence > 0.8:
               return decision
           
           # Fall back to LLM for ambiguous cases
           decision = self.llm_reason(event, context)
           
           # If still not confident, route to human
           if decision.confidence < 0.6:
               return self.escalate_to_human(event, context, decision)
           
           return decision
       
       def llm_reason(self, event, context):
           """Use LLM for complex reasoning"""
           prompt = self.build_prompt(event, context)
           response = self.llm.complete(prompt)
           decision = self.parse_response(response)
           return decision
   ```

4. **Action Interface** (Day 21-30)
   ```python
   # src/action/action_executor.py
   
   class ActionExecutor:
       """Execute actions with guardrails"""
       
       def __init__(self, tools, permissions, audit_logger):
           self.tools = tools
           self.permissions = permissions
           self.audit = audit_logger
       
       def execute(self, action, context):
           """Execute action with full logging"""
           
           # Check permissions
           if not self.permissions.allowed(action, context):
               raise PermissionDeniedError(f"Action {action} not allowed")
           
           # Log before execution
           self.audit.log_action_start(action, context)
           
           try:
               # Execute via appropriate tool
               tool = self.tools[action.tool_name]
               result = tool.execute(action.parameters)
               
               # Log success
               self.audit.log_action_success(action, result)
               return result
               
           except Exception as e:
               # Log failure
               self.audit.log_action_failure(action, e)
               raise
   ```

5. **Testing** (Day 31-40)
   ```python
   # tests/test_decision_engine.py
   
   import pytest
   from src.decision.decision_engine import DecisionEngine
   
   def test_invoice_matching_exact():
       """Test exact invoice-PO match"""
       event = create_invoice_event(amount=1000.00)
       context = {
           'po_amount': 1000.00,
           'receipt_amount': 1000.00
       }
       
       decision = engine.decide(event, context)
       
       assert decision.action == 'approve'
       assert decision.confidence > 0.95
   
   def test_invoice_matching_variance():
       """Test invoice-PO match with acceptable variance"""
       event = create_invoice_event(amount=1020.00)
       context = {
           'po_amount': 1000.00,
           'receipt_amount': 1020.00,
           'variance_tolerance': 0.05  # 5%
       }
       
       decision = engine.decide(event, context)
       
       assert decision.action == 'approve'
       assert decision.confidence > 0.80
   
   def test_invoice_matching_exceeds_variance():
       """Test invoice-PO variance exceeds tolerance"""
       event = create_invoice_event(amount=1150.00)
       context = {
           'po_amount': 1000.00,
           'receipt_amount': 1150.00,
           'variance_tolerance': 0.05  # 5%
       }
       
       decision = engine.decide(event, context)
       
       assert decision.action == 'escalate_to_human'
       assert 'variance_exceeds_tolerance' in decision.reason
   ```

6. **Deployment** (Day 41-45)
   ```yaml
   # config/deployment.yaml
   
   agent:
     name: rcm-denials-agent
     version: 1.0.0
     environment: production
     
   event_bus:
     type: kafka
     bootstrap_servers: kafka.internal:9092
     topics:
       - /healthcare/revenue-cycle/claim-denied/*
     
   state_store:
     type: postgresql
     host: db.internal
     database: vani_agents
     
   llm:
     provider: anthropic
     model: claude-sonnet-4-5-20250929
     max_tokens: 4000
     temperature: 0.1
     
   guardrails:
     max_requests_per_minute: 100
     confidence_threshold: 0.6
     prohibited_actions:
       - delete_patient_record
       - modify_financial_transaction
     
   monitoring:
     metrics_endpoint: /metrics
     log_level: INFO
     alert_threshold_error_rate: 0.05
   ```

**Deliverables:**
- Source code (tested and documented)
- Unit tests (>80% coverage)
- Integration tests
- Deployment configuration
- Operations runbook

**Success Criteria:**
- ✓ All tests passing
- ✓ Code review completed
- ✓ Security review passed
- ✓ Documentation complete
- ✓ Monitoring configured

---

### SOP-004: Human-in-the-Loop Review

**Objective**: Route exceptions to humans with full context for quick resolution

**When to Trigger:**
- Agent confidence < threshold (default 0.6)
- Edge case detected
- High-risk action required
- Compliance review needed

**Process:**

1. **Escalation** (Immediate)
   ```python
   def escalate_to_human(event, context, decision):
       """Route to human with full context"""
       
       escalation = {
           'escalation_id': generate_id(),
           'timestamp': now(),
           'priority': calculate_priority(event),
           'agent': AGENT_ID,
           
           'event': event,
           'context': context,
           'agent_reasoning': decision.reasoning,
           'confidence': decision.confidence,
           'recommended_action': decision.action,
           
           'review_required_by': calculate_sla(event.priority),
           'assigned_to': route_to_expert(event, context)
       }
       
       # Publish to human review queue
       publish_event(
           topic='/human-review/escalation/created',
           payload=escalation
       )
       
       # Notify assigned reviewer
       notify(escalation.assigned_to, escalation)
       
       return escalation
   ```

2. **Review Interface** (Human Side)
   - Notification received (email, Slack, in-app)
   - Open review interface
   - See full context (all data the agent had)
   - See agent's reasoning
   - See recommended action
   - Options:
     - Approve agent's recommendation
     - Modify and approve
     - Reject and provide guidance
     - Request more information

3. **Feedback Loop** (Learning)
   ```python
   def process_human_decision(escalation_id, human_decision):
       """Learn from human decision"""
       
       escalation = get_escalation(escalation_id)
       
       # Record human decision
       feedback = {
           'escalation_id': escalation_id,
           'agent_recommendation': escalation.recommended_action,
           'human_decision': human_decision.action,
           'agreement': (escalation.recommended_action == human_decision.action),
           'human_reasoning': human_decision.reasoning,
           'timestamp': now()
       }
       
       # Store for training
       store_feedback(feedback)
       
       # If pattern emerges, update decision logic
       if should_update_logic(feedback):
           update_decision_rules(feedback)
       
       # Complete the workflow
       execute_action(human_decision.action, escalation.context)
   ```

**Deliverables:**
- Escalation with full context
- Human decision with reasoning
- Feedback recorded for learning

**Success Criteria:**
- ✓ Human receives escalation within 1 minute
- ✓ All context available (no need to look up additional info)
- ✓ Recommended action is helpful (>70% human agreement)
- ✓ Feedback loop updates agent logic

**SLA:**
- Critical: 1 hour
- High: 4 hours
- Medium: 24 hours
- Low: 72 hours

---

### SOP-005: Production Monitoring & Alerting

**Objective**: Proactive monitoring to catch issues before they impact business

**Metrics to Monitor:**

1. **Agent Performance**
   - Automation rate (% handled without human)
   - Confidence distribution
   - Average decision time
   - Tool call success rate

2. **Business Outcomes**
   - Cycle time reduction
   - Error rate
   - SLA compliance
   - Cost savings

3. **Technical Health**
   - Event processing latency
   - Queue depth
   - API error rates
   - Resource utilization

**Alerting Rules:**

```yaml
# config/alerts.yaml

alerts:
  - name: automation_rate_drop
    metric: automation_rate
    condition: < 0.70  # Below 70%
    duration: 1h
    severity: warning
    action: notify_team
    
  - name: error_rate_spike
    metric: error_rate
    condition: > 0.05  # Above 5%
    duration: 15m
    severity: critical
    action: page_oncall
    
  - name: processing_latency_high
    metric: p95_latency
    condition: > 60s
    duration: 5m
    severity: warning
    action: notify_team
    
  - name: human_review_queue_backed_up
    metric: queue_depth
    condition: > 100
    duration: 30m
    severity: warning
    action: notify_process_owners
```

**Dashboard:**

```
┌─────────────────────────────────────────────┐
│  VaNi Agent Dashboard - RCM Denials         │
├─────────────────────────────────────────────┤
│                                              │
│  Automation Rate:  78% ↑ (+3% vs last week) │
│  Avg Cycle Time:   4.2 days ↓ (-55% vs base)│
│  Error Rate:       2.1% ↓                    │
│                                              │
├─────────────────────────────────────────────┤
│  Last 24 Hours:                              │
│  ├── Events Processed: 247                   │
│  ├── Auto-Resolved: 193 (78%)               │
│  ├── Escalated: 54 (22%)                    │
│  └── Errors: 5 (2%)                         │
│                                              │
├─────────────────────────────────────────────┤
│  Human Review Queue:                         │
│  ├── Pending: 12 cases                      │
│  ├── Oldest: 3 hours                        │
│  └── SLA Status: ✓ All within SLA           │
│                                              │
├─────────────────────────────────────────────┤
│  Top Escalation Reasons:                     │
│  1. Unusual payer response (23 cases)       │
│  2. Missing clinical documentation (18)     │
│  3. High dollar amount variance (13)        │
└─────────────────────────────────────────────┘
```

**Incident Response:**

1. **Alert Triggered**
   - Notification sent to team
   - On-call engineer investigates

2. **Investigation**
   - Check logs for errors
   - Review recent events
   - Identify root cause

3. **Mitigation**
   - Quick fix if possible
   - Disable agent if critical
   - Route all cases to humans temporarily

4. **Resolution**
   - Deploy fix
   - Validate resolution
   - Re-enable agent
   - Post-mortem review

---

## Domain Patterns

### Healthcare: Revenue Cycle Management

**Common Workflows:**
- Claims submission
- Denials management
- Prior authorization
- Payment posting
- Patient collections

**Example: Denials Management Agent**

```yaml
Event Schema:
/healthcare/revenue-cycle/claim-denied/{outcome}

Outcomes:
├── appeal-drafted-and-submitted
├── auto-corrected-and-resubmitted
├── escalated-to-specialist
├── written-off-per-policy
└── pending-additional-documentation

Context Required:
- Patient demographics (Epic/Cerner)
- Claim details (billing system)
- Clinical documentation (EHR)
- Payer policies (reference database)
- Denial history (data warehouse)

Decision Logic:
1. Classify denial code (CO, PR, OA, etc.)
2. Check if auto-correctable (simple errors)
3. If correctable → Fix and resubmit
4. If requires appeal → Draft appeal
5. If high confidence (>0.8) → Auto-submit
6. If low confidence (<0.6) → Route to specialist

Tools:
- retrieve_clinical_docs(patient_id)
- check_payer_policy(payer, procedure_code)
- draft_appeal(denial_code, clinical_context)
- submit_appeal(payer_portal, appeal_document)
- update_claim_status(claim_id, new_status)
```

**ROI Metrics:**
- Baseline: 45 days average appeal cycle
- Target: 15 days average appeal cycle
- Baseline: 60% overturn rate
- Target: 75% overturn rate
- Annual savings: $800K-$1.2M (per $100M revenue)

### Healthcare: Prior Authorization

**Common Workflows:**
- Prior auth request triage
- Clinical necessity assessment
- Payer submission
- Status tracking
- Peer-to-peer scheduling

**Example: Prior Auth Agent**

```yaml
Event Schema:
/healthcare/prior-auth/request-received/{outcome}

Outcomes:
├── auto-approved-internally
├── auto-submitted-to-payer
├── clinical-review-required
├── denied-not-medically-necessary
└── peer-to-peer-scheduled

Context Required:
- Patient clinical history
- Procedure details (CPT codes)
- Diagnosis codes (ICD-10)
- Payer guidelines
- Prior conservative treatment documentation

Decision Logic:
1. Retrieve payer guidelines for procedure
2. Check medical necessity criteria
3. Review clinical documentation
4. Assess if meets criteria
5. If clearly meets → Auto-submit to payer
6. If borderline → Clinical review required
7. If clearly doesn't meet → Deny with alternative

Tools:
- retrieve_payer_guidelines(payer, cpt_code)
- assess_medical_necessity(clinical_docs, guidelines)
- submit_to_payer(payer_api, prior_auth_request)
- schedule_peer_to_peer(physician, payer_medical_director)
```

**ROI Metrics:**
- Baseline: 72 hours average turnaround
- Target: 24 hours average turnaround
- Baseline: 85% approval rate
- Target: 92% approval rate
- Annual savings: $400K-$600K (per $100M revenue)

### Finance: Accounts Payable

**Common Workflows:**
- Invoice receipt & OCR
- Three-way matching (PO, receipt, invoice)
- Exception handling
- Payment scheduling
- Vendor communication

**Example: AP Automation Agent**

```yaml
Event Schema:
/finance/accounts-payable/invoice-received/{outcome}

Outcomes:
├── three-way-matched-approved
├── price-variance-escalated
├── quantity-variance-escalated
├── duplicate-invoice-rejected
└── payment-scheduled

Context Required:
- Invoice data (OCR extracted)
- Purchase order (ERP)
- Receipt/delivery confirmation (warehouse)
- Vendor master data
- Payment terms

Decision Logic:
1. Extract invoice data via OCR
2. Retrieve matching PO from ERP
3. Retrieve receipt from warehouse system
4. Perform three-way match
5. Check variance tolerance (<2%)
6. If within tolerance → Auto-approve
7. If exceeds tolerance → Escalate with analysis

Tools:
- ocr_extract_invoice(invoice_pdf)
- retrieve_po(po_number, erp_system)
- retrieve_receipt(po_number, wms_system)
- three_way_match(invoice, po, receipt)
- schedule_payment(invoice, payment_date)
- notify_ap_team(escalation_details)
```

**ROI Metrics:**
- Baseline: 7 days average processing time
- Target: 2 days average processing time
- Baseline: 15% touch rate (manual review)
- Target: 5% touch rate
- Annual savings: $300K-$500K (per $1B spend)

---

## Implementation Playbooks

### Playbook 1: Healthcare RCM - Denials Management

**Business Case:**
- Problem: 45-day average denial appeal cycle
- Volume: 500 denials/month
- Current cost: 3 FTE @ $70K = $210K/year
- Opportunity: Automate 70% of appeals

**Phase 1: Process Intelligence** (4 weeks)

Week 1-2: Process Mining
```sql
-- Extract denial events from billing system
SELECT
    claim_id,
    patient_id,
    payer,
    denial_code,
    denial_reason,
    denial_date,
    appeal_submitted_date,
    appeal_resolution_date,
    overturn_success,
    cycle_time_days
FROM claims_denials
WHERE denial_date >= '2025-01-01'
ORDER BY denial_date;
```

Week 2-3: Opportunity Analysis
- 65% of denials are CO-16 (missing info) or CO-197 (precert/auth)
- These have 85% overturn rate when appealed properly
- Average cycle time: 45 days
- 80% of time spent gathering documentation

Week 3-4: ROI Calculation
```
Current State:
- 500 denials/month × 3.5 hours/denial = 1,750 hours/month
- 1,750 hours × $35/hour = $61,250/month
- Annual: $735,000

Target State (70% automation):
- 350 auto-handled × 0.5 agent-hours = 175 hours
- 150 escalated × 3.5 hours = 525 hours
- Total: 700 hours/month = $24,500/month
- Annual: $294,000

Savings: $441,000/year
ROI: 2.2x in Year 1
```

**Phase 2: Architecture Design** (3 weeks)

Event Schema:
```yaml
/healthcare/revenue-cycle/claim-denied/
  ├── appeal-drafted
  ├── appeal-submitted
  ├── escalated-to-specialist
  └── written-off
```

Agent Topology: Collaborative (3 agents)
```
Agent 1: Denial Triage
├── Classify denial code
├── Determine complexity
└── Route to appropriate handler

Agent 2: Documentation Retrieval
├── Fetch clinical notes from EHR
├── Retrieve prior auth from system
├── Get relevant lab results
└── Package for appeal

Agent 3: Appeal Generation
├── Select appropriate template
├── Draft appeal with clinical context
├── If confidence >0.8 → Submit
└── If confidence <0.8 → Route to human
```

**Phase 3: Agent Development** (6 weeks)

Week 1-2: Perception Layer
- Build Epic API adapter
- Build billing system adapter
- Implement denial event listener

Week 3-4: Decision Logic
- Build denial classification rules
- Implement appeal template selector
- Build confidence scoring model

Week 5-6: Action Interface
- Build appeal drafting tool
- Build payer submission tool
- Build escalation routing

**Phase 4: Pilot** (4 weeks)

Week 1: Deploy to 10% of denials (50/month)
Week 2: Monitor and tune (increase to 30%)
Week 3: Validate accuracy (increase to 50%)
Week 4: Measure ROI

Results:
- 72% auto-resolution rate
- 18 days average cycle time (60% reduction)
- 88% overturn rate (improvement from 60%)

**Phase 5: Production Scale** (6 weeks)

Week 1-3: Handle edge cases from pilot
Week 4-5: Scale to 100% volume
Week 6: Continuous improvement

Final Results:
- 78% auto-resolution rate
- 14 days average cycle time (69% reduction)
- $441K annual savings achieved

---

### Playbook 2: Finance - AP Invoice Processing

**Business Case:**
- Problem: 7-day invoice processing cycle
- Volume: 5,000 invoices/month
- Current cost: 8 FTE @ $55K = $440K/year
- Opportunity: Automate 80% of invoices

**Phase 1: Process Intelligence** (4 weeks)

Process Mining Results:
- 72% of invoices are simple three-way matches
- 18% have price variances requiring approval
- 10% have issues (duplicate, no PO, etc.)
- Average time: 7 days (5 days waiting, 2 days working)

ROI Calculation:
```
Current State:
- 5,000 invoices/month × 0.5 hours/invoice = 2,500 hours
- 2,500 hours × $28/hour = $70,000/month
- Annual: $840,000

Target State (80% automation):
- 4,000 auto-processed × 0.05 hours = 200 hours
- 1,000 escalated × 0.5 hours = 500 hours
- Total: 700 hours/month = $19,600/month
- Annual: $235,200

Savings: $604,800/year
ROI: 3.0x in Year 1
```

**Phase 2: Architecture Design** (2 weeks)

Event Schema:
```yaml
/finance/accounts-payable/invoice-received/
  ├── matched-approved
  ├── variance-escalated
  ├── duplicate-rejected
  └── payment-scheduled
```

Agent Topology: Solo Agent (simple linear workflow)

**Phase 3: Agent Development** (5 weeks)

Week 1: OCR + data extraction
Week 2: Three-way matching logic
Week 3: Variance analysis
Week 4: Payment scheduling
Week 5: Testing

**Phase 4: Pilot** (3 weeks)

Deploy to 20% volume → 50% → 80%

Results:
- 82% straight-through processing
- 1.5 days average cycle time (79% reduction)

**Phase 5: Production Scale** (4 weeks)

Final Results:
- 84% automation rate
- 1.2 days average cycle time
- $605K annual savings achieved

---

## Quality Standards

### Code Quality

**Requirements:**
- Test coverage >80%
- No critical security vulnerabilities
- All functions documented
- Type hints (Python) or TypeScript
- Linting passes (pylint, flake8, eslint)

**Review Process:**
- Peer review required
- Security review for production code
- Performance review for high-volume agents

### Agent Performance

**Minimum Standards:**
- Automation rate >70% by end of pilot
- Error rate <5%
- Average confidence >0.75 for auto-handled cases
- Response time <30 seconds per decision

### Compliance

**HIPAA (Healthcare):**
- All PHI encrypted at rest and in transit
- Audit trail for all PHI access
- No PHI in logs (use patient_id only)
- BAA signed with all vendors

**SOX (Finance):**
- All financial transactions logged
- Approval trails maintained
- Changes to decision logic require approval
- Annual audit of agent decisions

**GxP (Life Sciences):**
- Validation documentation required
- Change control process mandatory
- Deviation reporting
- Regular audit trail review

### Documentation

**Required:**
- Architecture decision records (ADRs)
- API documentation
- Runbooks for common issues
- Training materials for process owners
- Disaster recovery procedures

---

## Appendix

### Glossary

**Agent**: Autonomous system that takes actions based on goals

**Context**: Information needed to make informed decisions

**Event**: Something that happened in the business

**Outcome**: Result of agent processing an event

**Perception**: How agent observes the world

**Decision Logic**: How agent chooses actions

**Action Interface**: How agent affects the world

**Human-in-the-Loop**: Pattern where humans review exceptions

**Confidence Score**: Agent's certainty about its decision (0-1)

**Escalation**: Routing case to human for review

**Audit Trail**: Complete log of all actions and decisions

---

### Technology Stack Reference

**Event Bus:**
- Apache Kafka (preferred for high volume)
- AWS EventBridge (serverless)
- RabbitMQ (moderate volume)
- Webhooks (low volume, simple)

**State Store:**
- PostgreSQL (structured data, ACID compliance)
- MongoDB (flexible schema)
- Redis (active context, caching)
- DynamoDB (serverless, AWS-native)

**LLM:**
- Claude Sonnet 4.5 (preferred - excellent reasoning)
- GPT-4 (alternative)
- Fine-tuned domain models (specialized use cases)

**API Gateway:**
- Kong (enterprise)
- AWS API Gateway (serverless)
- nginx (on-prem)

**Monitoring:**
- Datadog (full-stack)
- Prometheus + Grafana (open-source)
- AWS CloudWatch (AWS-native)

**Agent Runtime:**
- Python 3.11+ (preferred - rich ecosystem)
- Node.js (good for high I/O)
- Go (high performance requirements)

---

### Contact & Support

**Vikuna Technologies**  
Founded: 2020  
Headquarters: Hyderabad, India  

**Founder & CEO**: Charan Kamal Bommakanti
- 24+ years IT experience
- 10+ years Healthcare & Life Sciences
- Process Mining Expert (Celonis)
- Fractional CIO/CTO services

**Services:**
- AI Agent Development
- Digital Transformation Consulting
- Process Mining (Celonis)
- Fractional Executive Services

**Products:**
- KewalInvest (Financial portfolio management)
- ContractNest (AI-powered contract management)
- FamilyKnows (Family digital vault)

**Website**: vikuna.tech  
**Email**: charan@vikuna.tech  

---

### Version History

**v1.0 - January 2026**
- Initial VaNi framework release
- Process mining integration
- Event-driven architecture
- Healthcare & Finance playbooks

**Roadmap:**
- v1.1: Additional domain playbooks (legal, operations)
- v1.2: Multi-agent orchestration patterns
- v1.3: Advanced learning loops (reinforcement learning)

---

**End of Document**

---

## Key Differentiators vs Competitors

### vs Varick Agents:
- **Process mining first** (data-driven vs interview-based discovery)
- **Healthcare domain depth** (10+ years vs generic)
- **Honest timelines** (4-5 months vs 30-day marketing claims)
- **Event-driven semantics** (business-native /domain/function/event/outcome)
- **Compliance built-in** (HIPAA, SOX, GxP from day one)

### vs AI SaaS:
- **Custom agents on existing infrastructure** (no migration required)
- **Accumulating capability** (gets smarter over time vs depreciating asset)
- **Process mining ROI proof** (quantified before building)
- **Domain expertise embedded** (healthcare/life sciences specialists)

### vs Traditional Consulting:
- **Working systems in 4-5 months** (vs 18-month discovery)
- **No 200-slide decks** (ship production systems)
- **Process mining foundation** (data-driven recommendations)
- **Continuous improvement** (agents learn and improve)

---

This positions Vikuna as the **enterprise-grade, domain-expert** alternative to fast-talking generalists.