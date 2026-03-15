# SmartForm Field Patterns

## Overview

This reference provides domain-specific field patterns for SmartForm generation. When the Template Agent creates a SmartForm for a resource, it MUST use fields specific to that resource's domain — never generic placeholders.

Each pattern below shows the field structure for a specific resource type or industry. The agent should use these as templates and adapt them to the specific resource being templated.

---

## 1. Common Sections (Include in ALL SmartForms)

### Section: Equipment/Resource Identification (ALWAYS first section)

```json
{
  "id": "identification",
  "title": "Equipment Identification",
  "fields": [
    { "id": "asset_id", "type": "text", "label": "[Resource] ID / Tag Number", "required": true },
    { "id": "serial_number", "type": "text", "label": "Serial Number", "required": true },
    { "id": "make_model", "type": "text", "label": "Make & Model", "required": true },
    { "id": "location", "type": "text", "label": "Location / Department", "required": true },
    { "id": "last_service_date", "type": "date", "label": "Last Service Date" }
  ]
}
```

### Section: Sign-Off (ALWAYS last section)

```json
{
  "id": "signoff",
  "title": "Sign-Off & Approval",
  "fields": [
    { "id": "overall_status", "type": "select", "label": "Overall Assessment", "required": true,
      "options": [
        { "label": "Pass — All checks satisfactory", "value": "pass" },
        { "label": "Conditional — Minor issues noted", "value": "conditional" },
        { "label": "Fail — Critical issues found", "value": "fail" }
      ]
    },
    { "id": "remarks", "type": "textarea", "label": "Remarks / Observations" },
    { "id": "next_action", "type": "select", "label": "Recommended Next Action",
      "options": [
        { "label": "No action needed", "value": "none" },
        { "label": "Schedule follow-up", "value": "follow_up" },
        { "label": "Escalate to supervisor", "value": "escalate" },
        { "label": "Part replacement needed", "value": "part_replacement" }
      ]
    },
    { "id": "next_service_date", "type": "date", "label": "Recommended Next Service Date" },
    { "id": "technician_signature", "type": "signature", "label": "Technician Signature", "required": true },
    { "id": "client_signature", "type": "signature", "label": "Client Representative Signature", "required": true }
  ]
}
```

---

## 2. Healthcare Equipment Fields

### Medical Imaging (CT, MRI, X-Ray, Ultrasound, C-Arm)

**Pre-Service:**
- Tube/detector warm-up status
- Last calibration date + certificate reference
- Error log review (any pending errors)
- Patient count since last service
- Room temperature and humidity
- Power supply stability check
- UPS backup status

**During Service:**
- kV accuracy test (at multiple settings)
- mA accuracy test
- Image quality phantom test (spatial resolution, contrast, uniformity)
- Gantry rotation smoothness
- Table movement calibration
- Laser alignment check
- Dose output measurement (mGy)
- DICOM connectivity test
- Software version verification

**Post-Service:**
- All readings within tolerance? (Y/N with values)
- Parts replaced (list with part numbers)
- Calibration certificate generated? (file upload)
- QA phantom images (file upload)
- Radiation survey results
- Next PM due date

### Life Support (Ventilator, Defibrillator, Patient Monitor)

**Pre-Service:**
- Battery charge level (%)
- Self-test result (pass/fail)
- Alarm system functional?
- Last used date
- Accessories condition (cables, sensors, paddles)

**During Service:**
- Flow sensor calibration
- Pressure sensor calibration
- SpO2 sensor accuracy test
- ECG waveform quality test (for monitors)
- Energy delivery test at multiple levels (for defibrillators)
- Leak test (for ventilators) — cmH2O
- Tidal volume accuracy test
- Battery load test duration (minutes)

**Post-Service:**
- Electrical safety test (leakage current — µA)
- All parameters within manufacturer spec?
- Firmware version current?
- Patient-ready status confirmed?

---

## 3. Facility Management Fields

### HVAC System

**Pre-Service:**
- System running hours since last service
- Current room temperature vs setpoint
- Any comfort complaints reported?
- Filter replacement date
- Refrigerant type (R-22, R-410A, R-32)

**During Service:**
- Compressor suction pressure (psi)
- Compressor discharge pressure (psi)
- Superheat temperature (°F/°C)
- Sub-cooling temperature (°F/°C)
- Evaporator coil condition (clean/dirty/damaged)
- Condenser coil condition
- Fan belt tension and condition
- Thermostat calibration check
- Drain pan and drain line clear?
- Electrical connections tightened?
- Refrigerant level (if topped up — quantity in kg)
- Amperage draw vs rated (Amps)

**Post-Service:**
- Temperature differential (supply vs return — °F/°C)
- Airflow measurement (CFM)
- Energy consumption reading (kWh)

### Elevator / Lift

**Pre-Service:**
- Total trips since last service
- Any entrapment incidents?
- Pending complaint log
- Last safety inspection date

**During Service:**
- Door opening/closing speed (seconds)
- Door safety edge response
- Leveling accuracy (mm tolerance)
- Ride quality (vibration level)
- Brake pad thickness (mm)
- Wire rope condition (visual + caliper)
- Guide shoe/roller condition
- Oil level in hydraulic tank (for hydraulic lifts)
- Controller error log download
- Emergency phone test
- Car top / pit inspection
- Safety gear test
- Over-speed governor test
- Buffer condition

**Post-Service:**
- Load test result (at rated capacity)
- Speed test result (m/s)
- All safety devices functional?

### DG Set (Diesel Generator)

**During Service:**
- Engine oil level and condition
- Coolant level and condition
- Fuel filter condition
- Air filter condition
- Battery voltage (V) and specific gravity
- Belt tension and condition
- Exhaust smoke color
- Engine RPM at no-load and full-load
- Frequency output (Hz)
- Voltage output (V) — all phases
- Load bank test result (kW at 25%, 50%, 75%, 100%)
- Auto-start test result (seconds to start)
- Auto-changeover test
- Running hours meter reading

---

## 4. Manufacturing / Pharma Equipment Fields

### Pharma Reactor (Glass-Lined / SS)

**Pre-Service Safety:**
- LOTO confirmed
- Vessel depressurized
- Vessel drained and cleaned
- Gas test / LEL test completed
- Work permit document (file upload)

**Vessel Inspection:**
- Glass lining condition (excellent/good/fair/poor) — only for GL reactors
- Spark test result (kV) — only for GL reactors
- Vessel wall thickness (mm) — for SS reactors
- Vessel pressure (bar)
- Jacket pressure (bar)
- Agitator condition (normal/vibration/seal_leak/not_operational)
- Agitator RPM at rated speed
- Temperature sensor reading (°C)
- Baffle condition (intact/minor_corrosion/major_damage)

**Nozzle & Valve Check:**
- Nozzle count inspected
- Gasket condition (good/worn/leaking)
- Valves checked (bottom_outlet, feed_inlet, vent, sampling, drain)
- Nozzle condition photos (file upload)

**CIP System:**
- CIP functional? (yes/partial/no)
- Last CIP cycle date
- CIP observations (textarea)

**GMP Compliance:**
- All calibration certificates current?
- Expired instruments list (if any)
- Deviation report required?
- Overall readiness (ready/conditional/not_ready)

### Tablet Press Machine

**During Service:**
- Turret RPM check
- Compression force calibration (kN)
- Ejection force calibration
- Weight variation test (mg ± tolerance)
- Hardness test (N)
- Friability test (%)
- Disintegration time test (minutes)
- Punch and die condition (visual)
- Feeder mechanism functionality
- Dust extraction system check
- Force-feeder paddle condition
- Pre-compression roller alignment

### HPLC System

**Calibration Fields:**
- Column ID and type
- Mobile phase composition
- Flow rate accuracy test (mL/min — set vs actual)
- Pressure test at rated flow (bar)
- UV lamp hours
- Baseline noise level (AU)
- Wavelength accuracy test (nm — set vs actual)
- System suitability test (SST):
  - Theoretical plates (N)
  - Tailing factor (T)
  - Resolution (Rs)
  - RSD of peak areas (%)
- Injection repeatability (RSD %)
- Gradient proportioning valve accuracy (%)

### Autoclave / Sterilizer

**During Service:**
- Chamber temperature (°C at multiple points)
- Chamber pressure (bar/kPa)
- Vacuum leak rate test
- Bowie-Dick test result (pass/fail)
- Biological indicator result (file upload)
- Door gasket condition
- Safety valve test
- Drain strainer condition
- Steam quality test (dryness fraction)
- Cycle time accuracy (minutes — set vs actual)
- Print-out/data logger verification

---

## 5. Wellness / Fitness Equipment Fields

### Treadmill / Cardio Equipment

- Belt alignment and tension
- Incline motor calibration
- Speed calibration (set vs actual km/h)
- Heart rate sensor accuracy
- Emergency stop test
- Display/console functionality
- Lubrication applied?
- Roller condition
- Motor temperature (°C)
- Running hours meter

### Multi-Gym / Strength Equipment

- Cable and pulley inspection
- Weight stack alignment
- Upholstery condition
- Frame weld integrity (visual)
- Pin and selector mechanism
- Safety labels present and legible?
- Lubrication points serviced

---

## 6. IT / Technology Equipment Fields

### Server / Network Equipment

- Power supply redundancy test
- Fan speed and noise level (dB)
- Temperature readings (CPU, ambient)
- RAID status and disk health (SMART data)
- Firmware version
- Network interface throughput test (Gbps)
- Error log review (syslog/event viewer)
- UPS switchover test (seconds)
- Backup verification (last successful backup date)
- Security patch status

### Precision AC (Data Center)

- Supply air temperature (°C)
- Return air temperature (°C)
- Humidity level (% RH)
- Compressor run current (Amps)
- Condenser coil pressure
- Refrigerant level
- Glycol level (for glycol-cooled units)
- Under-floor air pressure
- Filter differential pressure
- Alarm history review

---

## 7. Automotive Equipment Fields

### Wheel Alignment Machine

- Calibration verification (camera/laser alignment)
- Turn plate condition
- Clamp condition and calibration
- Software version and database update
- Reference alignment check (known-good vehicle)
- Camera/sensor cleaning
- Level check (machine and turn plates)

### Vehicle Lift

- Hydraulic fluid level and condition
- Lifting speed test (seconds)
- Load capacity test (at rated load)
- Safety lock engagement test
- Arm/pad condition
- Hydraulic seal check (any leaks)
- Equalizer cable condition (for 2-post)
- Control pendant/button test

---

## 8. Field Type Selection Guide

| Data Being Captured | Recommended Field Type | Example |
|--------------------|-----------------------|---------|
| Equipment name, serial, ID | `text` | "Serial Number" |
| Measurement with units | `number` + `unit` | "Pressure" unit="bar" |
| Yes/No question | `radio` (2 options) | "LOTO Confirmed?" |
| Single choice from list | `select` | "Glass Lining Condition" |
| Multiple applicable items | `multi_select` or `checkbox` | "Valves Checked" |
| Condition assessment | `select` (with severity scale) | "Excellent/Good/Fair/Poor" |
| Free-form observation | `textarea` | "Remarks" |
| Date reference | `date` | "Last Calibration Date" |
| Photo/document evidence | `file` | "Nozzle Condition Photos" |
| Authorization | `signature` | "Inspector Signature" |
| Calculated value | `computed` | "Pass Rate" = pass_count / total_count × 100 |
| Score (1-5 stars) | `rating` | "Overall Equipment Condition" |
| Repeating items | `repeater` | "Spare Parts Used" (multiple entries) |

## 9. Visibility Rule Patterns

```json
// Show field only when another field has a specific value
{ "field": "reactor_type", "operator": "equals", "value": "glass_lined" }

// Show field when another field is NOT empty
{ "field": "deviation_required", "operator": "equals", "value": "yes" }

// Show field when a number exceeds threshold
{ "field": "leakage_current", "operator": "greater_than", "value": 100 }

// Compound rule (AND)
{ "operator": "and", "conditions": [
  { "field": "reactor_type", "operator": "equals", "value": "glass_lined" },
  { "field": "overall_status", "operator": "equals", "value": "fail" }
]}
```

## 10. File Upload Validation Patterns

```json
// Photo evidence
{ "accept": ["image/jpeg", "image/png", "image/heic"], "maxSizeMB": 10, "maxFiles": 6 }

// Document upload
{ "accept": ["application/pdf", "image/*"], "maxSizeMB": 15, "maxFiles": 3 }

// Certificate upload
{ "accept": ["application/pdf"], "maxSizeMB": 5, "maxFiles": 1 }

// Video evidence
{ "accept": ["video/mp4", "video/quicktime"], "maxSizeMB": 50, "maxFiles": 2 }
```
