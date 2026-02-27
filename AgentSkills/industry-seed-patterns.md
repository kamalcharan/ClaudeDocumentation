# Industry Seed Patterns

## Table of Contents
1. [Pattern Structure](#pattern-structure)
2. [Healthcare](#healthcare)
3. [Facility Management](#facility-management)
4. [Manufacturing](#manufacturing)
5. [Technology (IT Services)](#technology)
6. [Real Estate & Construction](#real-estate)
7. [Wellness & Fitness](#wellness)
8. [Education](#education)
9. [Hospitality](#hospitality)
10. [Home Services](#home-services)
11. [Energy & Utilities](#energy)
12. [Cross-Industry Patterns](#cross-industry)
13. [Nomenclature → Block Mapping](#nomenclature-block-mapping)

---

## Pattern Structure

Each industry pattern defines:

```json
{
  "industry_id": "healthcare",
  "typical_nomenclatures": ["amc", "cmc", "camc", "care_plan", "service_package"],
  "service_categories": [...],        // → t_catalog_categories / t_catalog_items
  "resource_templates": [...],         // → t_category_resources_master / t_catalog_resources
  "asset_types": [...],                // → t_category_details (cat_asset_types)
  "sla_templates": [...],              // → cat_blocks (service type)
  "compliance_checklists": [...],      // → cat_blocks (checklist type)
  "pricing_models": [...],             // → cat_blocks (billing type)
  "contract_terms": [...],             // → cat_blocks (text type)
  "sample_blocks": [...]               // → cat_blocks (assembled)
}
```

---

## Healthcare

### Typical Nomenclatures
AMC, CMC, CAMC (for equipment), Care Plan (for patient services), Service Package, Consultation, SLA

### Service Categories (from m_catalog_categories)
Already seeded in master: `medical_equipment_amc`, `biomedical_equipment`, `imaging_equipment_amc`, `patient_care_services`, `nursing_services`, `attendant_services`, `diagnostic_services`, `laboratory_services`, `health_screening`, `therapy_rehabilitation`, `dialysis_services`, `chemotherapy_services`, `medical_consultation`, `telemedicine_services`, `emergency_services`, `surgical_services`, `dental_services`, `eye_care_services`, `ayurveda_services`, `pharmacy_services`, `medical_waste_management`, `hospital_housekeeping`, `hospital_laundry`, `sterilization_services`, `hospital_kitchen`

### Resource Templates
**Staff:** Medical Doctor (₹100-250/hr), Registered Nurse (₹50-100/hr), Lab Technician (₹30-60/hr), Radiologist (₹150-300/hr), Pharmacist (₹40-80/hr), Patient Attendant (₹20-35/hr), Physiotherapist (₹60-120/hr), Biomedical Engineer (₹50-100/hr)

**Equipment:** CT Scanner (AMC 8% of cost), MRI Scanner (AMC 8%), Ultrasound (AMC 7%), X-Ray (AMC 6%), Defibrillator (AMC 5%), Ventilator (AMC 10%), Patient Monitor (AMC 6%), Dialysis Machine (AMC 8%), Autoclave (AMC 5%), OT Table (AMC 4%), C-Arm (AMC 7%), Blood Gas Analyzer (AMC 8%)

**Consumables:** Medical Supplies (₹5/unit), Surgical Disposables (₹25/unit), Lab Reagents (₹10/unit)

### Asset Types (to seed in t_category_details under cat_asset_types)
- `medical_ct_scanner` → "CT Scanner" (make: Siemens, GE, Canon)
- `medical_mri` → "MRI Scanner" (make: Siemens, GE, Philips)  
- `medical_ultrasound` → "Ultrasound Machine"
- `medical_xray` → "X-Ray Machine"
- `medical_ventilator` → "Ventilator"
- `medical_dialysis` → "Dialysis Machine"
- `medical_patient_monitor` → "Patient Monitor"
- `medical_defibrillator` → "Defibrillator"
- `medical_autoclave` → "Autoclave / Sterilizer"
- `medical_ot_table` → "OT Table"

### SLA Templates
| Service | Response Time | Resolution Time | Uptime % |
|---------|--------------|-----------------|----------|
| Critical Equipment (ICU/OT) | 2 hours | 8 hours | 99.5% |
| Diagnostic Equipment | 4 hours | 24 hours | 98% |
| General Equipment | 8 hours | 48 hours | 95% |
| Patient Care Services | 15 minutes | 60 minutes | 99% |
| Housekeeping | 30 minutes | 2 hours | 95% |

### Compliance Checklists
- [ ] NABH accreditation requirements met
- [ ] Biomedical waste disposal per BMW Rules 2016
- [ ] Equipment calibration certificates current
- [ ] Fire safety systems functional (per NBC 2016)
- [ ] AERB compliance for radiology equipment
- [ ] Drug license validity (Schedule H/H1)
- [ ] Staff qualification verification
- [ ] Infection control protocols implemented

### Sample Contract Terms (Text Blocks)
- **Warranty Clause:** "All parts replaced under this contract carry a 6-month warranty from date of replacement."
- **Escalation Matrix:** "L1: Service Engineer (2hr) → L2: Senior Engineer (4hr) → L3: OEM Support (8hr)"
- **Penalty Clause:** "For every hour of downtime beyond SLA, a penalty of ₹{amount}/hour shall apply, capped at 10% of quarterly value."
- **Exclusion Clause:** "This contract does not cover damage due to power surges, natural disasters, or unauthorized modifications."

---

## Facility Management

### Typical Nomenclatures
FMC, O&M, Manpower, AMC (for facility equipment), SLA

### Service Categories
`building_maintenance`, `housekeeping`, `security_services`, `pest_control`, `landscaping`, `waste_management`, `fire_safety`, `elevator_maintenance`, `plumbing`, `electrical_maintenance`, `hvac_maintenance`, `parking_management`, `swimming_pool_maintenance`, `generator_maintenance`, `water_treatment`, `facade_cleaning`, `carpet_deep_cleaning`, `fumigation`, `annual_painting`, `waterproofing`

### Resource Templates
**Staff:** Facility Manager (₹50-100/hr), Housekeeping Supervisor (₹20-40/hr), Security Guard (₹15-25/hr), Electrician (₹25-50/hr), Plumber (₹25-50/hr), HVAC Technician (₹30-60/hr), Gardener (₹15-25/hr), Pest Control Operator (₹30-50/hr)

**Equipment:** DG Set (AMC 4%), Elevator (AMC 8%), Fire Pump (AMC 5%), STP/WTP (AMC 6%), HVAC System (AMC 7%), CCTV System (AMC 5%), Access Control (AMC 5%), BMS (AMC 8%)

### Asset Types
- `facility_dg_set` → "DG Set / Generator"
- `facility_elevator` → "Elevator / Lift"
- `facility_fire_pump` → "Fire Pump System"
- `facility_stp` → "STP / ETP"
- `facility_hvac_central` → "Central HVAC Plant"
- `facility_cctv` → "CCTV System"
- `facility_bms` → "Building Management System"
- `facility_transformer` → "Transformer"
- `facility_ug_tank` → "Underground Water Tank"

### SLA Templates
| Service | Response Time | Resolution Time | Uptime % |
|---------|--------------|-----------------|----------|
| Elevator Breakdown | 30 min | 4 hours | 99% |
| DG Set | 15 min | 2 hours | 99.5% |
| Plumbing Emergency | 30 min | 4 hours | - |
| HVAC | 1 hour | 8 hours | 95% |
| Security | Immediate | - | 99.9% |
| Housekeeping | 15 min | 1 hour | 95% |

### Compliance Checklists
- [ ] Fire NOC valid and displayed
- [ ] Lift inspector certification current
- [ ] DG set pollution clearance
- [ ] STP/ETP discharge compliance (CPCB norms)
- [ ] Security guard PSARA license
- [ ] Annual structural audit
- [ ] Electrical safety audit (IS 3043)
- [ ] Water tank cleaning certificate (quarterly)

---

## Manufacturing

### Typical Nomenclatures
AMC, CMC, CAMC, PMC, O&M, Rate Contract, SLA

### Service Categories
`machine_maintenance`, `production_line_support`, `calibration_services`, `cnc_maintenance`, `welding_services`, `quality_testing`, `tool_room_services`, `industrial_cleaning`, `effluent_treatment`, `compressor_maintenance`, `boiler_maintenance`, `conveyor_maintenance`, `crane_maintenance`, `electrical_panel_maintenance`

### Resource Templates
**Staff:** Production Engineer (₹40-80/hr), Maintenance Technician (₹25-50/hr), Quality Inspector (₹30-60/hr), CNC Programmer (₹40-80/hr), Welder (₹25-50/hr), Calibration Technician (₹35-70/hr)

**Equipment:** CNC Machine (AMC 6%), Compressor (AMC 5%), Industrial Boiler (AMC 7%), Hydraulic Press (AMC 5%), Conveyor System (AMC 4%), Crane/Hoist (AMC 5%), Chiller (AMC 6%), PLC/SCADA System (AMC 8%)

### Asset Types
- `mfg_cnc_machine` → "CNC Machine"
- `mfg_compressor` → "Industrial Compressor"
- `mfg_boiler` → "Industrial Boiler"
- `mfg_hydraulic_press` → "Hydraulic Press"
- `mfg_conveyor` → "Conveyor System"
- `mfg_crane` → "Overhead Crane / Hoist"
- `mfg_chiller` → "Industrial Chiller"

---

## Technology

### Typical Nomenclatures
AMC, SLA, Subscription, Retainer, Rate Contract, Project-Based, Consultation

### Service Categories
`it_infrastructure_amc`, `network_management`, `server_maintenance`, `desktop_support`, `cybersecurity_services`, `cloud_management`, `data_backup_recovery`, `cctv_surveillance`, `access_control`, `erp_support`, `software_development`, `app_maintenance`, `database_administration`, `helpdesk_services`, `it_consulting`

### Resource Templates
**Staff:** Solutions Architect (₹100-200/hr), DevOps Engineer (₹60-120/hr), Network Engineer (₹40-80/hr), Desktop Support (₹25-50/hr), Security Analyst (₹50-100/hr), Database Admin (₹50-100/hr), Helpdesk Agent (₹20-40/hr), Project Manager (₹60-120/hr)

**Equipment:** Server (AMC 8%), Firewall (AMC 10%), UPS (AMC 5%), Network Switch (AMC 5%), Storage Array (AMC 8%)

### SLA Templates
| Service | Response Time | Resolution Time | Uptime % |
|---------|--------------|-----------------|----------|
| P1 - Critical (server down) | 15 min | 4 hours | 99.9% |
| P2 - Major (partial outage) | 30 min | 8 hours | 99.5% |
| P3 - Minor (degraded) | 2 hours | 24 hours | 99% |
| P4 - Low (cosmetic) | 8 hours | 72 hours | 95% |

---

## Real Estate

### Typical Nomenclatures
FMC, AMC, Manpower, O&M, Rate Contract, Per-Call

### Service Categories
`property_maintenance`, `society_management`, `common_area_maintenance`, `swimming_pool`, `gym_equipment_maintenance`, `intercom_system`, `cctv_access_control`, `painting_services`, `plumbing_services`, `electrical_services`, `waterproofing`, `pest_control_residential`, `landscaping_gardening`, `elevator_amc`, `dg_set_amc`, `water_treatment`, `annual_maintenance`

### Asset Types
Already seeded: residential_1bhk through residential_penthouse, commercial_office through commercial_basement_parking. Additional:
- `re_clubhouse` → "Clubhouse / Community Hall"
- `re_swimming_pool` → "Swimming Pool"
- `re_gym` → "Gymnasium"
- `re_playground` → "Children's Playground"
- `re_terrace` → "Terrace / Rooftop"
- `re_common_area` → "Common Area / Lobby"

---

## Wellness & Fitness

### Typical Nomenclatures
Service Package, Care Plan, Subscription, Consultation, Per-Call

### Service Categories
`gym_training`, `yoga_classes`, `physiotherapy`, `nutrition_counseling`, `mental_health`, `spa_services`, `ayurveda`, `naturopathy`, `acupuncture`, `chiropractic`, `sports_medicine`, `rehabilitation`, `weight_management`, `prenatal_postnatal`, `geriatric_care`, `corporate_wellness`

### Resource Templates
**Staff:** Certified Trainer (₹30-60/hr), Yoga Instructor (₹30-50/hr), Physiotherapist (₹50-100/hr), Nutritionist (₹40-80/hr), Psychologist (₹60-120/hr), Spa Therapist (₹25-50/hr)

**Equipment:** Treadmill (AMC 5%), CrossTrainer (AMC 5%), Smith Machine (AMC 4%), Spin Bike (AMC 4%)

---

## Education

### Typical Nomenclatures
Service Package, Subscription, Training, Consultation, Project-Based

### Service Categories
`tutoring_services`, `coaching_classes`, `skill_development`, `corporate_training`, `language_courses`, `test_preparation`, `workshop_facilitation`, `curriculum_development`, `e_learning_development`, `assessment_services`, `career_counseling`, `special_education`, `stem_programs`

---

## Hospitality

### Typical Nomenclatures
FMC, AMC, Manpower, Rate Contract, SLA

### Service Categories
`kitchen_equipment_amc`, `laundry_services`, `housekeeping_hospitality`, `restaurant_maintenance`, `hvac_hotel`, `elevator_hotel`, `fire_safety_hotel`, `swimming_pool_hotel`, `pest_control_hotel`, `deep_cleaning`, `facade_cleaning_hotel`, `landscaping_hotel`

---

## Home Services

### Typical Nomenclatures
Per-Call, AMC, Service Package, Subscription

### Service Categories
`ac_service`, `plumbing_home`, `electrical_home`, `painting_home`, `pest_control_home`, `deep_cleaning_home`, `appliance_repair`, `carpentry`, `waterproofing_home`, `interior_design`, `home_automation`, `garden_maintenance`, `water_purifier_amc`

---

## Energy & Utilities

### Typical Nomenclatures
O&M, AMC, CMC, SLA, BOT/BOOT, Turnkey

### Service Categories
`solar_panel_maintenance`, `substation_maintenance`, `power_distribution`, `energy_audit`, `transformer_maintenance`, `ups_maintenance`, `battery_maintenance`, `wind_turbine_maintenance`, `ev_charging_maintenance`

---

## Cross-Industry Patterns

These patterns apply regardless of industry:

### Universal Service Categories
- Housekeeping / Cleaning
- Security Services
- Pest Control
- Fire Safety Maintenance
- DG Set / Power Backup
- UPS Maintenance
- CCTV & Access Control
- IT Infrastructure (desktops, network)
- Annual Painting
- Plumbing
- Electrical

### Universal Compliance
- GST Registration & Filing
- Professional Tax
- PF/ESI for contract labor
- Contract Labour Act compliance
- Minimum Wages Act
- Shop & Establishment Act
- Fire Safety (NBC 2016)
- Environmental clearances (where applicable)

### Universal Billing Blocks
- **Monthly Fixed:** Fixed amount billed monthly
- **Quarterly Advance:** Billed quarterly in advance
- **Per Visit:** Charged per service visit
- **Per Equipment:** Rate per equipment covered
- **EMI:** Total split into equal installments
- **Milestone:** Billed on completion of milestones

---

## Nomenclature → Block Mapping

Each nomenclature has a standard set of blocks:

### AMC (Annual Maintenance Contract)
```
Core Blocks:
├── Service Block: Preventive maintenance visits (quantity, frequency)
├── Service Block: Breakdown support (response SLA)
├── Spare Block: Parts coverage (included/excluded/discount)
└── Billing Block: Annual/quarterly/monthly payment

Content Blocks:
├── Text Block: Scope of work
├── Text Block: Exclusions
├── Text Block: Penalty clauses
├── Checklist Block: Equipment covered (with serial numbers)
└── Document Block: Equipment photos / condition report
```

### CMC (Comprehensive Maintenance Contract)
```
Core Blocks:
├── Service Block: Preventive visits (all-inclusive)
├── Service Block: Breakdown support (unlimited)
├── Spare Block: All parts included
├── Spare Block: Consumables included
└── Billing Block: Fixed monthly/quarterly

Content Blocks:
├── Text Block: Comprehensive scope
├── Text Block: Exclusions (only force majeure)
├── Checklist Block: Full equipment list
└── Document Block: Condition assessment
```

### FMC (Facility Management Contract)
```
Core Blocks:
├── Service Block: Housekeeping (daily/weekly schedule)
├── Service Block: Technical maintenance (HVAC, electrical, plumbing)
├── Service Block: Security (24x7 deployment)
├── Service Block: Landscaping & gardening
├── Service Block: Pest control (quarterly)
├── Spare Block: Consumables (cleaning supplies, etc.)
└── Billing Block: Monthly fixed + variable

Content Blocks:
├── Text Block: Deployment plan (staff count, shifts)
├── Text Block: SLA matrix
├── Text Block: Penalty framework
├── Checklist Block: Daily inspection checklist
├── Checklist Block: Monthly audit checklist
└── Document Block: Staff deployment register
```

### SLA (Service Level Agreement)
```
Core Blocks:
├── Service Block: Primary service (P1/P2/P3/P4 response times)
├── Service Block: Monitoring & reporting
└── Billing Block: Fixed retainer + penalty adjustments

Content Blocks:
├── Text Block: SLA definitions & targets
├── Text Block: Penalty & credit framework
├── Text Block: Reporting & governance
├── Checklist Block: Monthly SLA review checklist
└── Document Block: SLA dashboard template
```

### Manpower (Staffing Contract)
```
Core Blocks:
├── Service Block: Staff deployment (role, count, shift)
├── Service Block: Replacement/substitute provision
└── Billing Block: Per head per month

Content Blocks:
├── Text Block: Roles & responsibilities
├── Text Block: Attendance & leave policy
├── Text Block: Compliance requirements (PF/ESI/Wages)
├── Checklist Block: Monthly compliance checklist
└── Document Block: Deployment & attendance register
```

### Care Plan (Healthcare)
```
Core Blocks:
├── Service Block: Consultation sessions (doctor visits)
├── Service Block: Therapy sessions (physio/OT)
├── Service Block: Diagnostic tests included
├── Spare Block: Medicines/consumables coverage
└── Billing Block: Package price (EMI option)

Content Blocks:
├── Text Block: Treatment protocol
├── Text Block: Expected outcomes
├── Checklist Block: Session tracking
└── Document Block: Medical reports
```
