# Claude Code Prompt: ContractNest UX Journey — HTML Prototypes

> **Read the handover document (`contractnest-handover.md`) FIRST. It contains the full architectural context, decisions, and implementation phases.**

---

## Your Role

You are a **world-class product designer** who has designed SaaS products used by millions. You think like Stripe's design team — every micro-interaction is intentional, every transition tells a story, every element earns its pixel. You obsess over the moment a user says "oh, this gets me."

You are NOT building safe, generic enterprise UI. You are building something that makes a facility manager at a hospital WANT to use this product instead of their Excel spreadsheet. The bar is: a user should feel smarter after using ContractNest than before.

---

## What To Build

Create **6 interconnected HTML prototype files** — each one a self-contained, interactive journey that demonstrates a specific phase of the ContractNest domain enhancement. Each file should be standalone HTML with embedded CSS and JS (no external dependencies except CDN links for icons/fonts).

**Design language**: Modern, clean, generous whitespace, subtle animations, micro-interactions on hover/click. Think Linear + Notion + Stripe Dashboard aesthetics. Use a cohesive color system — suggest one that works across all 6 files.

**IMPORTANT**: Each prototype must be clearly labeled with which implementation phase (P0/P1/P2/P3/P4) it demonstrates. Show a small floating badge or ribbon on each screen indicating the phase.

---

### FILE 1: `01-nomenclature-picker.html` — **[P0]**

**The Nomenclature Selection Experience**

This is the FIRST thing a user sees when creating a contract. It replaces the current boring "Service Contract / Partnership Agreement" two-card selector.

**Build this flow:**

1. **Opening state**: A card grid showing all 15 nomenclature types, organized in 3 groups:
   - 🔧 **Equipment Contracts**: AMC, CMC, CAMC, PMC, BMC, Warranty Extension
   - 🏢 **Facility & Property Contracts**: FMC, O&M, Manpower
   - 📋 **General Contracts**: SLA, Rate Contract, Retainer, Per-Call, Turnkey, BOT/BOOT

2. **Each card should show**:
   - Icon (relevant to the type)
   - Short name prominently (AMC)
   - Full name below (Annual Maintenance Contract)
   - 1-line description of what's included/excluded
   - A subtle tag showing typical industries (Healthcare, Manufacturing)
   - A visual indicator: equipment-based 🔧 / entity-based 🏢 / general 📋

3. **Interaction**:
   - Hover: Card lifts with shadow, shows expanded description
   - Click: Card expands into a detail panel showing:
     - What's typically included (scheduled visits, labor, parts, etc.)
     - What's typically excluded
     - Typical duration and billing frequency
     - "Best for: [industry list]"
     - A prominent "Select" button
   - Search/filter: A search bar at top that filters cards in real-time ("Type AMC or Annual...")
   - Industry filter: Tabs or chips for "All | Healthcare | Manufacturing | Real Estate | Technology" — clicking an industry highlights recommended types and dims others (don't hide, just visual priority)

4. **Smart suggestion banner**: If the user's industry is known (e.g., Healthcare), show a top banner: "Recommended for Healthcare: AMC, CMC, PMC" with those cards visually promoted (slight scale up, accent border).

5. **After selection**: Show a confirmation strip at bottom: "You selected: **Annual Maintenance Contract (AMC)** — Equipment-based, Quarterly billing typical" with an edit pencil icon.

**Wow factor**: The card grid should feel alive. Smooth staggered entrance animation. Cards should have a subtle gradient that shifts on hover. The industry filter should animate the card reordering. The detail expansion should be a smooth morph, not a modal popup.

---

### FILE 2: `02-equipment-registry.html` — **[P1]**

**The Equipment Registration & Management Experience**

This is what a seller sees at `/settings/configure/resources` → Equipment tab. They're registering equipment they SERVICE (not own).

**Build this flow:**

1. **Empty state** (first-time seller):
   - Beautiful illustration showing equipment icons
   - "Tell us what you service" heading
   - Auto-suggestion based on seller's industry: "As a Healthcare services provider, you likely work with:" followed by suggested equipment types from `m_catalog_resource_templates` (MRI Scanner, CT Scanner, Defibrillator, Ventilator, X-Ray Machine, Autoclave, Patient Monitor)
   - Each suggestion is a chip the seller can click to "Add to my catalog"
   - A "+ Add Custom Equipment Type" option for things not in the global catalog

2. **Populated state** (seller has equipment registered):
   - Left sidebar: Equipment categories as a tree (Medical Imaging > MRI, CT, X-Ray | Life Support > Ventilator, Defibrillator | Sterilization > Autoclave)
   - Main area: Card grid of equipment items within selected category
   - Each card shows: Equipment name, make/model, serial number, location, condition badge (Good/Fair/Poor), warranty status (Active/Expired/N/A), last maintenance date
   - Quick-add button opens a slide-in panel (not modal) from the right

3. **Equipment detail slide-in panel**:
   - Fields: Name*, Make, Model, Serial Number, Asset Tag, Category (from global catalog), Purchase Date, Warranty Expiry, Location, Condition (dropdown with color-coded options), Criticality (Low/Medium/High/Critical with visual weight), Specifications (dynamic key-value pairs based on equipment type — tonnage for AC, kVA for DG, tesla for MRI)
   - Owner section: "Whose equipment is this?" — search existing contacts (buyers/clients)
   - Contract links: "Active contracts covering this equipment" — read-only list showing linked contracts (populated after P1d)

4. **Bulk import**: A drag-and-drop zone for CSV/Excel upload. Show a preview table with column mapping before import.

5. **Equipment group creation**: A "Create Group" action that lets seller select multiple equipment items and group them ("All ACs in Building A", "Radiology Department Equipment"). Visual: dragging equipment cards into a group container.

**Wow factor**: The industry-based suggestions should feel like the system KNOWS the seller's world. The equipment cards should have subtle condition-based coloring (green tint for Good, amber for Fair, red for Poor). The slide-in panel should have smooth spring animation. Warranty expiry should show a countdown badge ("Expires in 43 days" in amber, "Expired 12 days ago" in red).

---

### FILE 3: `03-entity-registry.html` — **[P2]**

**The Property/Entity Registration & Hierarchy Experience**

This is where a seller (or buyer) defines the physical spaces they manage or own.

**Build this flow:**

1. **Entity hierarchy tree** (left panel):
   - Visual tree: Campus → Building → Floor → Wing → Room/Flat/Space
   - Each node shows: Name, type icon, area (if applicable), condition dot
   - Expand/collapse with smooth animation
   - Drag-and-drop reordering within same level
   - Right-click context menu: Add child, Edit, Archive

2. **Entity detail panel** (right panel, when a node is selected):
   - Header: Entity name + type badge + condition score (circular progress: 8.5/10)
   - Details card: Type, parent, code, zone/sector, floor number
   - Dimensions card: Area (sqft), Length × Width × Height, Capacity
   - Specifications: Dynamic key-value (class for clean rooms, pH for pools, soil type for gardens)
   - Photos/documents: Gallery grid of uploaded images
   - Contract coverage: "Currently under FMC Contract #CN-2026-0012" (linked)
   - Inspection history: Mini timeline showing last 5 inspections with condition scores

3. **Visual property map** (innovative — an interactive floor plan feel):
   - For buildings: Show a simplified floor stack visualization (Floor 1, Floor 2, Floor 3 as horizontal layers)
   - Each floor shows rooms/spaces as colored blocks (color = condition score)
   - Click a block to select that entity
   - This doesn't need to be a real floor plan — it's a SCHEMATIC view that gives spatial context

4. **Entity creation wizard** (triggered by "Add Property"):
   - Step 1: Pick type (Building / Floor / Room / Garden / Pool / Clean Room / Parking / etc.) — visual icon grid
   - Step 2: Place in hierarchy (select parent from tree) — or "Top level" for campus/standalone
   - Step 3: Fill details (fields adapt based on type — pool doesn't need floor_number, garden needs soil_type)
   - Step 4: Add photos (optional, drag-drop)

5. **Bulk entity creation**: "I have 120 flats in this building" → enter count + naming pattern (e.g., "Flat {floor}{unit}" → Flat 101, 102, 103...) → auto-generates all entities in hierarchy.

**Wow factor**: The hierarchy tree should feel like Figma's layer panel — responsive, smooth, visually rich. The schematic property map is the differentiator — no competitor shows this. The bulk creation with pattern naming is a power-user delight. Condition scores should use the same circular progress everywhere (consistent visual language).

---

### FILE 4: `04-contract-wizard-enhanced.html` — **[P1 + P2]**

**The Enhanced Contract Creation Wizard**

This shows the COMPLETE enhanced wizard flow with nomenclature, equipment, and entity integration. This is the hero prototype — the one that tells the full story.

**Build this flow as a multi-step wizard:**

**Step 1 — Nomenclature** [P0]:
- Compact version of File 1's nomenclature picker (embedded in wizard)
- User picks AMC → system notes "equipment-based"

**Step 2 — Counterparty** (existing, keep simple):
- Search/select buyer contact
- Quick-add new contact inline

**Step 3 — Contract Details** (existing, enhanced):
- Auto-filled: Contract name suggests "AMC — [Buyer Name] — 2026"
- Duration pre-fills based on nomenclature typical_duration
- Auto-generated contract number

**Step 4 — Equipment / Entity Selection** [P1/P2] ← THE NEW STEP:
- **Dynamic routing**: This step ADAPTS based on nomenclature:
  - AMC/CMC/PMC selected → Shows equipment picker
  - FMC/Manpower selected → Shows entity picker  
  - O&M/Turnkey selected → Shows BOTH equipment + entity tabs
  - SLA/Retainer/Per-Call → Skips this step entirely

- **Equipment picker** (when shown):
  - Left: Tree of seller's equipment categories (from `/settings/configure/resources`)
  - Right: Selectable equipment list within category
  - Each equipment item: checkbox + name + serial + location + condition badge
  - Selected items appear in a "Coverage Summary" strip at bottom
  - Per-equipment coverage type dropdown: "Full (CMC)" / "Preventive Only (PMC)" / "Breakdown Only (BMC)"
  - "Equipment not listed?" → inline add (slide-in, same as File 2's detail panel)
  - "Let buyer add equipment" → toggle that sends equipment registration request to buyer

- **Entity picker** (when shown):
  - Hierarchy tree (from File 3) with checkboxes
  - Select individual rooms, entire floors, or whole buildings
  - Area auto-calculates (sum of selected entities' sqft)
  - Per-entity pricing: "₹5 / sqft / month" auto-computes from area

**Step 5 — Service Blocks** (existing, enhanced):
- FlyBy menu now includes "Equipment" block type
- Service blocks show which equipment/entities they apply to
- "Apply to all equipment" checkbox vs. per-equipment assignment

**Step 6 — Billing** (existing, enhanced):
- Pricing summary shows per-equipment or per-entity breakdown
- For AMC: "3 × MRI Scanner @ ₹1,50,000/year = ₹4,50,000"
- For FMC: "5,000 sqft × ₹5/sqft/month × 12 months = ₹3,00,000"

**Step 7 — Events Preview** (existing, enhanced):
- Timeline shows per-equipment events:
  - "MRI #1 — Q1 PM Visit — Jan 15"
  - "MRI #2 — Q1 PM Visit — Jan 20"
  - "MRI #3 — Q1 PM Visit — Jan 25"
- Color-coded by equipment type

**Step 8 — Review & Send** (existing, enhanced):
- Contract summary prominently shows:
  - Nomenclature badge: "AMC — Annual Maintenance Contract"
  - Equipment schedule table (annexed to contract)
  - Total value breakdown per equipment/entity

**Navigation**: Step indicators at top. Steps that were skipped (due to nomenclature routing) should show as greyed-out/absent (not numbered gaps). Smooth slide transitions between steps.

**Wow factor**: The dynamic step routing is the hero interaction — when user picks "AMC", the wizard morphs to show equipment steps. When they pick "FMC", it morphs to show entity steps. This morph should be animated and feel intelligent, not like a page refresh. The per-equipment event timeline in Step 7 is visually powerful — show it as a Gantt-like horizontal timeline with equipment on the Y-axis and time on the X-axis.

---

### FILE 5: `05-contract-dashboard.html` — **[P0 + P3]**

**The Enhanced Contract Hub / Dashboard**

Shows how nomenclature transforms the contract listing and analytics experience.

**Build this:**

1. **Top stats bar** (enhanced):
   - Current: "Active: 24, Draft: 8, Expired: 3" (just status counts)
   - Enhanced: Nomenclature-grouped donuts/pills:
     - "AMC: 12 | CMC: 5 | FMC: 4 | PMC: 3 | SLA: 2 | Others: 2"
     - Each with its nomenclature color
     - Clicking a pill filters the list below

2. **Contract list** (enhanced cards):
   - Each card now shows:
     - Nomenclature badge (colored chip: "AMC" in blue, "FMC" in green, "CMC" in purple)
     - Equipment/entity count: "3 MRI Scanners" or "5,000 sqft across 3 floors"
     - Contract value with per-unit breakdown
   - Filter sidebar: Add nomenclature filter (multi-select with nomenclature chips)
   - Sort option: "Group by Nomenclature" — groups cards under AMC/CMC/FMC headers

3. **Pipeline view** (Kanban-style):
   - Columns: Draft → Pending → Active → Expiring Soon → Completed
   - Cards show nomenclature badges
   - "Expiring Soon" column is the innovation — shows contracts expiring within 30 days with a renewal CTA

4. **Nomenclature analytics panel** (expandable bottom section):
   - Bar chart: "Contracts by Nomenclature Type" (AMC: 12, CMC: 5, FMC: 4...)
   - Revenue by nomenclature: "AMC contracts: ₹45L | FMC contracts: ₹12L"
   - Equipment coverage: "28 of 35 equipment items covered (80%)" with a progress ring
   - Entity coverage: "42,000 of 50,000 sqft covered (84%)" with a progress ring

5. **Quick actions**:
   - "Create AMC" / "Create FMC" / "Create CMC" quick buttons (pre-select nomenclature in wizard)

**Wow factor**: The nomenclature pills in the stats bar should feel like a dashboard control — clicking them filters AND animates the card list. The Kanban pipeline should have smooth drag (even if non-functional in prototype). The "Expiring Soon" column with renewal CTA is a business value moment — the user sees revenue they're about to lose and can act on it.

---

### FILE 6: `06-buyer-experience.html` — **[P2 + P4]**

**The Buyer's Portal Experience**

What a buyer sees when they receive a contract, register equipment, and track service delivery. This is the "other side" of ContractNest.

**Build this flow:**

1. **Contract received** (via email link / CNAK):
   - Clean landing page showing contract summary
   - Nomenclature displayed prominently: "You've received an Annual Maintenance Contract (AMC)"
   - Equipment schedule visible: "This contract covers: MRI Scanner GE Signa HDxt, MRI Scanner Siemens Magnetom"
   - Or entity schedule: "This contract covers: Building A — Floors 1-5 — 25,000 sqft"

2. **Equipment registration prompt** (if seller toggled "Let buyer add equipment"):
   - Beautiful onboarding-style flow: "Please register your equipment for this contract"
   - Pre-suggested equipment types based on contract nomenclature + industry
   - Simple form: Name, Make, Model, Serial Number, Location
   - Multi-add: "Add another" button for registering multiple items
   - Or bulk: CSV upload option

3. **Buyer dashboard** (after acceptance):
   - "My Portfolio" view:
     - Equipment owned: 12 ACs, 2 DG Sets, 3 Elevators, 5 MRI Scanners
     - Properties managed: Building A (50,000 sqft), Garden (2 acres)
     - Active contracts: 4 AMCs, 1 FMC, 1 SLA — covering 85% of equipment, 92% of property
     - Gap alert: "3 equipment items have NO active maintenance contract" (in amber)
   
4. **Service tracking** (buyer view of ongoing contract):
   - Timeline of upcoming service events PER equipment:
     - "MRI #1 — Next PM Visit: Feb 25" (with countdown)
     - "MRI #2 — Next PM Visit: Mar 2" (with countdown)
   - Evidence gallery: Before/after photos from last service, grouped by equipment
   - SLA compliance meter: "Response Time: 3.2 hrs avg (SLA: 4 hrs) ✅"

5. **Renewal nudge** (P4 — compound return):
   - "Your AMC for 3 MRI Scanners expires in 28 days"
   - "Equipment health summary: MRI #1 — Good, MRI #2 — Fair (2 breakdowns this year), MRI #3 — Good"
   - "Recommendation: Consider upgrading MRI #2 to CMC coverage (parts + labor included)"
   - "Renew" button → pre-fills new contract with same equipment + nomenclature

**Wow factor**: The buyer portfolio view is the killer feature — no competitor shows "85% of your equipment is covered." The gap alert ("3 items have NO contract") is a revenue trigger for the seller. The renewal nudge with equipment health scoring is P4 intelligence made visible. The evidence gallery with before/after per-equipment is trust-building gold.

---

## CROSS-FILE CONSISTENCY

- **Same color palette** across all 6 files. Suggest a system:
  - Primary: Deep blue (trust, professionalism)
  - Equipment accent: Amber/orange
  - Entity accent: Green/teal
  - Nomenclature colors: Each type gets a unique but harmonious color
  - Condition colors: Green (good) → Amber (fair) → Red (poor/critical)

- **Same typography**: Use Inter or DM Sans (clean, modern, great at small sizes)

- **Same component patterns**: Cards, badges, slide-in panels, pill filters should look identical across files

- **Phase badges**: Each file has a floating badge in top-right showing "P0", "P1", "P2", etc. — so stakeholders know what belongs to which implementation phase

- **Navigation between files**: Add a floating "Journey Map" button that shows all 6 files as a flow diagram with the current file highlighted. Clicking another file navigates to it (or shows "View File X" link).

---

## WHAT NOT TO DO

1. **Don't make it look like a wireframe.** This should look like a SHIPPED product. Use real colors, real shadows, real spacing. No grey boxes with labels.
2. **Don't use Lorem Ipsum.** Use real data: "Apollo Hospital", "MRI Scanner GE Signa HDxt", "Dr. Rajesh Kumar", "₹1,50,000/year". Indian context — INR, Indian company names, Indian equipment vendors.
3. **Don't make generic enterprise UI.** No blue-grey everything. This should have personality — subtle gradients, micro-animations, thoughtful hover states.
4. **Don't skip mobile responsiveness.** These prototypes should work on mobile (at least the key flows).
5. **Don't forget the phase labels.** Every screen must clearly show P0/P1/P2/P3/P4 context.