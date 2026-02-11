# ContractNest: Git Workflow & Rollback Strategy

**Principle**: Every phase (P0, P1, P2) gets its own feature branch across ALL submodules. Each phase is a self-contained, rollback-safe unit. You NEVER move to the next phase until the current one is verified, tested, and merged.

---

## 1. THE BRANCH STRATEGY

```
master (current stable state — YOUR BOOKMARK)
  │
  ├── feature/p0-nomenclature          ← Phase 0 work
  │     ├── contractnest-edge: feature/p0-nomenclature
  │     ├── contractnest-api:  feature/p0-nomenclature
  │     ├── contractnest-ui:   feature/p0-nomenclature
  │     └── ClaudeDocumentation: feature/p0-nomenclature
  │
  │   [MERGE TO MASTER ONLY AFTER FULL VERIFICATION]
  │
  ├── feature/p1-equipment              ← Phase 1 work (created AFTER P0 is merged)
  │     ├── contractnest-edge: feature/p1-equipment
  │     ├── contractnest-api:  feature/p1-equipment
  │     ├── contractnest-ui:   feature/p1-equipment
  │     └── ClaudeDocumentation: feature/p1-equipment
  │
  │   [MERGE TO MASTER ONLY AFTER FULL VERIFICATION]
  │
  └── feature/p2-entities               ← Phase 2 work (created AFTER P1 is merged)
```

**Rule**: Same branch name across ALL submodules. This keeps your `push-main.ps1` script working and makes it obvious which repos have pending changes for which phase.

---

## 2. BEFORE YOU START — CREATE YOUR BOOKMARK

Run this ONCE, right now, before any changes begin. This tags your current stable state across ALL repos.

```powershell
# ═══════════════════════════════════════════════════
# BOOKMARK: Tag current stable state in ALL repos
# ═══════════════════════════════════════════════════

cd "D:\projects\core projects\ContractNest\contractnest-combined"

$tagName = "stable-pre-domain-audit-$(Get-Date -Format 'yyyyMMdd')"
$tagMessage = "Stable state before domain enhancement (nomenclature + equipment + entities)"

# Tag each submodule
$submodules = @(
    @{ Name = "contractnest-api"; Branch = "main" },
    @{ Name = "contractnest-ui"; Branch = "main" },
    @{ Name = "contractnest-edge"; Branch = "main" },
    @{ Name = "ClaudeDocumentation"; Branch = "master" }
)

foreach ($sub in $submodules) {
    Write-Host "Tagging $($sub.Name)..." -ForegroundColor Cyan
    Push-Location $sub.Name
    git checkout $sub.Branch
    git pull origin $sub.Branch
    git tag -a $tagName -m $tagMessage
    git push origin $tagName
    Pop-Location
}

# Tag parent repo
Write-Host "Tagging parent repo..." -ForegroundColor Cyan
git tag -a $tagName -m $tagMessage
git push origin $tagName

Write-Host ""
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "  BOOKMARK CREATED: $tagName" -ForegroundColor Green
Write-Host "  To rollback EVERYTHING to this point:" -ForegroundColor Yellow
Write-Host "  .\scripts\rollback-to-tag.ps1 $tagName" -ForegroundColor Yellow
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Green
```

Save this as `scripts\create-bookmark.ps1`.

---

## 3. THE ROLLBACK SCRIPT

If anything goes wrong at any phase, this script rolls ALL repos back to a tagged bookmark.

```powershell
# ═══════════════════════════════════════════════════
# ROLLBACK: Return all repos to a tagged state
# ═══════════════════════════════════════════════════

param(
    [Parameter(Mandatory=$true)]
    [string]$TagName
)

$ROOT_DIR = "D:\projects\core projects\ContractNest\contractnest-combined"
cd $ROOT_DIR

Write-Host ""
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Red
Write-Host "  ROLLBACK TO: $TagName" -ForegroundColor Red
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Red
Write-Host ""

$confirm = Read-Host "  This will DISCARD all changes after $TagName. Continue? (y/N)"
if ($confirm -ne "y" -and $confirm -ne "Y") {
    Write-Host "  Aborted." -ForegroundColor Yellow
    exit 0
}

$submodules = @(
    @{ Name = "contractnest-api"; Branch = "main" },
    @{ Name = "contractnest-ui"; Branch = "main" },
    @{ Name = "contractnest-edge"; Branch = "main" },
    @{ Name = "ClaudeDocumentation"; Branch = "master" }
)

foreach ($sub in $submodules) {
    Write-Host ""
    Write-Host "  Rolling back $($sub.Name)..." -ForegroundColor Yellow
    Push-Location $sub.Name

    # Check if tag exists
    $tagExists = git tag -l $TagName
    if (-not $tagExists) {
        Write-Host "    [WARN] Tag $TagName not found in $($sub.Name) — skipping" -ForegroundColor Red
        Pop-Location
        continue
    }

    git checkout $sub.Branch
    git reset --hard $TagName
    git push origin $sub.Branch --force

    Write-Host "    [OK] $($sub.Name) rolled back to $TagName" -ForegroundColor Green
    Pop-Location
}

# Rollback parent
Write-Host ""
Write-Host "  Rolling back parent repo..." -ForegroundColor Yellow
git checkout master
git reset --hard $TagName
git push origin master --force

Write-Host ""
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "  ROLLBACK COMPLETE" -ForegroundColor Green
Write-Host "  All repos are now at: $TagName" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "  IMPORTANT: If you applied Supabase migrations," -ForegroundColor Yellow
Write-Host "  those CANNOT be auto-rolled back. See Section 6." -ForegroundColor Yellow
```

Save this as `scripts\rollback-to-tag.ps1`.

---

## 4. PHASE-BY-PHASE WORKFLOW

### PHASE 0: Nomenclature (Safest — seed data + 1 column + UI)

**Risk level: LOW** — Additive only. No existing code is modified. No breaking changes.

**What changes:**
```
contractnest-edge:
  └── supabase/migrations/XXX_nomenclature_seed.sql
      - INSERT into m_category_master (1 row)
      - INSERT into m_category_details (21 rows)
      - ALTER TABLE t_contracts ADD COLUMN nomenclature_id UUID

contractnest-api:
  └── src/types/contractTypes.ts (add nomenclature types)
  └── src/validators/contractValidators.ts (accept nomenclature_id)

contractnest-ui:
  └── src/types/service-contracts/contract.ts (add nomenclature types)
  └── src/components/contracts/ContractWizard/ (nomenclature picker step)
  └── src/pages/contracts/hub/ (nomenclature badges + filter)

ClaudeDocumentation:
  └── handover docs + audit results
```

**Workflow:**

```powershell
# ─── Step 1: Create feature branches in ALL affected repos ───
cd "D:\projects\core projects\ContractNest\contractnest-combined"

$branchName = "feature/p0-nomenclature"

foreach ($sub in @("contractnest-edge", "contractnest-api", "contractnest-ui", "ClaudeDocumentation")) {
    Push-Location $sub
    $mainBranch = if ($sub -eq "ClaudeDocumentation") { "master" } else { "main" }
    git checkout $mainBranch
    git pull origin $mainBranch
    git checkout -b $branchName
    git push -u origin $branchName
    Pop-Location
}

# Parent repo
git checkout -b $branchName
git push -u origin $branchName

Write-Host "All repos now on: $branchName" -ForegroundColor Green
```

```powershell
# ─── Step 2: Do the work (Claude Code or manual) ───
# Work happens on feature/p0-nomenclature across all repos
# Commit frequently with descriptive messages
```

```powershell
# ─── Step 3: Test on feature branch ───
# Start dev server from feature branch
cd contractnest-ui
npm run dev
# Test: nomenclature picker appears, badges show, filter works
# Test: existing contracts still work (no regression)
# Test: new contract with nomenclature_id saves correctly
```

```powershell
# ─── Step 4: Create post-P0 bookmark BEFORE merging ───
$p0Tag = "pre-p0-merge-$(Get-Date -Format 'yyyyMMdd-HHmm')"
# Tag current master in all repos (safety net)
foreach ($sub in @("contractnest-edge", "contractnest-api", "contractnest-ui", "ClaudeDocumentation")) {
    Push-Location $sub
    $mainBranch = if ($sub -eq "ClaudeDocumentation") { "master" } else { "main" }
    git checkout $mainBranch
    git tag -a $p0Tag -m "Before P0 nomenclature merge"
    git push origin $p0Tag
    Pop-Location
}
```

```powershell
# ─── Step 5: Merge P0 to master (one repo at a time) ───

# CRITICAL ORDER: Edge FIRST (database), then API, then UI
# Why: UI depends on API types, API depends on DB schema

# 5a: Merge edge (database migration)
cd contractnest-edge
git checkout main
git merge feature/p0-nomenclature --no-ff -m "Merge P0: nomenclature seed + contracts column"
git push origin main
cd ..

# 5b: Apply the Supabase migration
# Go to Supabase dashboard → SQL Editor → run the migration
# OR use: supabase db push (if CLI is set up)
# VERIFY: m_category_details has 21 nomenclature rows
# VERIFY: t_contracts has nomenclature_id column

# 5c: Merge API (types + validators)
cd contractnest-api
git checkout main
git merge feature/p0-nomenclature --no-ff -m "Merge P0: nomenclature types + validation"
git push origin main
cd ..

# 5d: Merge UI (wizard + badges + filter)
cd contractnest-ui
git checkout main
git merge feature/p0-nomenclature --no-ff -m "Merge P0: nomenclature picker + badges + filter"
git push origin main
cd ..

# 5e: Merge docs
cd ClaudeDocumentation
git checkout master
git merge feature/p0-nomenclature --no-ff -m "Merge P0: domain audit + handover docs"
git push origin master
cd ..

# 5f: Update parent
git checkout master
git add contractnest-edge contractnest-api contractnest-ui ClaudeDocumentation
git commit -m "Merge P0: nomenclature system (21 contract types)"
git push origin master
```

```powershell
# ─── Step 6: Post-merge bookmark ───
$p0DoneTag = "stable-after-p0-$(Get-Date -Format 'yyyyMMdd')"
# Tag all repos at this new stable state
# This becomes the rollback point for P1
```

```powershell
# ─── Step 7: Clean up feature branches ───
foreach ($sub in @("contractnest-edge", "contractnest-api", "contractnest-ui", "ClaudeDocumentation")) {
    Push-Location $sub
    git branch -d feature/p0-nomenclature
    git push origin --delete feature/p0-nomenclature
    Pop-Location
}
git branch -d feature/p0-nomenclature
git push origin --delete feature/p0-nomenclature
```

**Rollback P0 (if something breaks after merge):**
```powershell
# Code rollback
.\scripts\rollback-to-tag.ps1 "pre-p0-merge-YYYYMMDD-HHMM"

# Database rollback (MANUAL — Supabase migrations can't auto-rollback)
# Run in Supabase SQL Editor:
#   ALTER TABLE t_contracts DROP COLUMN IF EXISTS nomenclature_id;
#   DELETE FROM m_category_details WHERE category_id = (
#     SELECT id FROM m_category_master WHERE sub_cat_name = 'cat_contract_nomenclature'
#   );
#   DELETE FROM m_category_master WHERE sub_cat_name = 'cat_contract_nomenclature';
```

---

### PHASE 1: Equipment (Medium risk — new tables + junction + wizard step)

**DO NOT START P1 until P0 is merged, tested, and bookmarked.**

**Risk level: MEDIUM** — New tables are additive (safe), but wizard changes touch existing UI flow.

**What changes:**
```
contractnest-edge:
  └── supabase/migrations/XXX_equipment_tables.sql
      - CREATE TABLE t_equipment
      - CREATE TABLE t_contract_equipment
      - CREATE TABLE t_equipment_groups + t_equipment_group_items
      - ALTER TABLE t_service_tickets ADD COLUMN equipment_id
      - ALTER TABLE t_service_evidence ADD COLUMN equipment_id
      - SEED m_catalog_resource_templates (industry × equipment data)

contractnest-api:
  └── src/types/equipment.ts (new)
  └── src/routes/equipment.routes.ts (new)
  └── src/controllers/equipmentController.ts (new)
  └── src/services/equipmentService.ts (new)
  └── Existing contract routes (accept equipment_ids in contract create/update)

contractnest-ui:
  └── src/pages/settings/resources/ (Equipment tab enhancement)
  └── src/components/contracts/ContractWizard/ (equipment picker step)
  └── src/types/equipment.ts (new)
  └── src/hooks/queries/useEquipmentQueries.ts (new)

contractnest-edge:
  └── supabase/functions/equipment/ (new edge function)
```

**Same branch workflow as P0:**
```
Branch: feature/p1-equipment
Merge order: edge → API → UI
Pre-merge bookmark: pre-p1-merge-YYYYMMDD
Post-merge bookmark: stable-after-p1-YYYYMMDD
```

**Rollback P1:**
```sql
-- Database rollback (run in Supabase SQL Editor)
ALTER TABLE t_service_tickets DROP COLUMN IF EXISTS equipment_id;
ALTER TABLE t_service_evidence DROP COLUMN IF EXISTS equipment_id;
DROP TABLE IF EXISTS t_equipment_group_items;
DROP TABLE IF EXISTS t_equipment_groups;
DROP TABLE IF EXISTS t_contract_equipment;
DROP TABLE IF EXISTS t_equipment;
-- Resource templates: DELETE WHERE added in P1 (keep existing rows)
```

---

### PHASE 2: Entities (Medium risk — same pattern as P1)

**DO NOT START P2 until P1 is merged, tested, and bookmarked.**

```
Branch: feature/p2-entities
Merge order: edge → API → UI
Pre-merge bookmark: pre-p2-merge-YYYYMMDD
Post-merge bookmark: stable-after-p2-YYYYMMDD
```

---

## 5. THE MERGE ORDER RULE

**ALWAYS merge in this order:**

```
1. contractnest-edge (database migrations)
     ↓ apply migration to Supabase
     ↓ verify tables/columns exist
2. contractnest-api (types, routes, services)
     ↓ verify API responds correctly
3. contractnest-ui (pages, components, hooks)
     ↓ verify UI works end-to-end
4. ClaudeDocumentation (docs)
5. Parent repo (submodule references)
```

**Why this order:**
- UI depends on API types → API must be merged first
- API depends on DB schema → Edge (migrations) must be merged first
- If you merge UI before API, the UI will call endpoints that don't exist → broken
- If you merge API before Edge, the API will reference columns that don't exist → broken

---

## 6. THE SUPABASE MIGRATION RISK

**This is the ONE thing that can't be auto-rolled back.** Git rollback handles code. Supabase migration rollback needs manual SQL.

**Mitigation strategy:**

For EVERY migration file, write a corresponding DOWN migration:

```
supabase/migrations/
  ├── 20260211_p0_nomenclature_UP.sql     ← Applied by supabase db push
  └── 20260211_p0_nomenclature_DOWN.sql   ← Manual rollback script (kept in repo, never auto-applied)
```

**P0 DOWN migration example:**
```sql
-- 20260211_p0_nomenclature_DOWN.sql
-- RUN THIS MANUALLY IN SUPABASE SQL EDITOR TO ROLLBACK P0

-- Step 1: Remove column from contracts
ALTER TABLE t_contracts DROP COLUMN IF EXISTS nomenclature_id;

-- Step 2: Remove nomenclature details
DELETE FROM m_category_details
WHERE category_id = (
  SELECT id FROM m_category_master
  WHERE sub_cat_name = 'cat_contract_nomenclature'
);

-- Step 3: Remove nomenclature master category
DELETE FROM m_category_master
WHERE sub_cat_name = 'cat_contract_nomenclature';
```

**P1 DOWN migration example:**
```sql
-- 20260212_p1_equipment_DOWN.sql

-- Step 1: Remove columns added to existing tables
ALTER TABLE t_service_tickets DROP COLUMN IF EXISTS equipment_id;
ALTER TABLE t_service_evidence DROP COLUMN IF EXISTS equipment_id;

-- Step 2: Drop junction tables (order matters — children first)
DROP TABLE IF EXISTS t_equipment_group_items;
DROP TABLE IF EXISTS t_equipment_groups;
DROP TABLE IF EXISTS t_contract_equipment;

-- Step 3: Drop equipment master
DROP TABLE IF EXISTS t_equipment;

-- Step 4: Remove seeded resource templates (careful — only remove P1 additions)
-- Use a specific marker or date filter to identify P1 seeds
DELETE FROM m_catalog_resource_templates
WHERE created_at >= '2026-02-12' AND created_at < '2026-02-20';
```

**CRITICAL**: Test DOWN migrations on a Supabase branch (dev environment) BEFORE relying on them for production rollback. You can use `supabase branches` for this if your plan supports it.

---

## 7. BOOKMARK TIMELINE (What Your Tag History Should Look Like)

```
stable-pre-domain-audit-20260211      ← CREATED NOW (current clean state)
  │
  │  [P0 work on feature/p0-nomenclature]
  │
pre-p0-merge-20260212-1430            ← Before merging P0 to master
  │
  │  [Merge P0, apply migration, test]
  │
stable-after-p0-20260212              ← P0 is live and working
  │
  │  [P1 work on feature/p1-equipment]
  │
pre-p1-merge-20260218-1100            ← Before merging P1 to master
  │
  │  [Merge P1, apply migration, test]
  │
stable-after-p1-20260218              ← P1 is live and working
  │
  │  [P2 work on feature/p2-entities]
  │
pre-p2-merge-20260225-0900            ← Before merging P2 to master
  │
  │  [Merge P2, apply migration, test]
  │
stable-after-p2-20260225              ← P2 is live and working
```

At ANY point, you can:
- `.\scripts\rollback-to-tag.ps1 stable-after-p0-20260212` → rolls back to P0 done, P1 undone
- `.\scripts\rollback-to-tag.ps1 stable-pre-domain-audit-20260211` → rolls back EVERYTHING
- Plus manual SQL DOWN migration for any applied database changes

---

## 8. TESTING CHECKLIST PER PHASE

### P0 Testing (Before merging to master)
```
[ ] m_category_master has 'cat_contract_nomenclature' row
[ ] m_category_details has 21 nomenclature rows with correct form_settings
[ ] t_contracts has nomenclature_id column (nullable, no existing data broken)
[ ] Contract wizard shows nomenclature picker as first/early step
[ ] All 21 types display with correct icons, names, descriptions
[ ] Industry filter works (Healthcare shows Care Plan + AMC promoted)
[ ] Selecting nomenclature sets value on contract
[ ] Contract list shows nomenclature badge on cards
[ ] Dashboard groups contracts by nomenclature
[ ] EXISTING contracts (without nomenclature_id) still display correctly
[ ] EXISTING contract creation flow still works if nomenclature is skipped
[ ] No console errors, no broken imports
[ ] Mobile responsive (nomenclature cards)
```

### P1 Testing (Before merging to master)
```
[ ] t_equipment table created with all columns
[ ] t_contract_equipment junction table created
[ ] Equipment CRUD works at /settings/configure/resources
[ ] Industry-based equipment suggestions appear for new tenants
[ ] Equipment picker appears in wizard when equipment-based nomenclature selected
[ ] Equipment picker does NOT appear for service-based nomenclature
[ ] Multiple equipment can be selected per contract
[ ] Per-equipment coverage terms save correctly
[ ] Equipment shows on contract detail page
[ ] equipment_id column exists on t_service_tickets
[ ] EXISTING contracts still work (no regression)
[ ] EXISTING service tickets still work (equipment_id is nullable)
```

### P2 Testing (Before merging to master)
```
[ ] m_entity_types / cat_asset_types created and seeded
[ ] t_entities table with hierarchy (parent_entity_id) works
[ ] Entity tree view renders correctly
[ ] Entity picker appears for entity-based nomenclature
[ ] Entity picker does NOT appear for equipment-only nomenclature
[ ] Per-entity pricing (₹/sqft) calculates correctly
[ ] Entity shows on contract detail page
[ ] EXISTING contracts still work (no regression)
```

---

## 9. CLAUDE CODE SESSION MANAGEMENT

Each Claude Code session should:

1. **START** by reading:
   - `ClaudeDocumentation/contractnest-handover.md`
   - `ClaudeDocumentation/contractnest-handover-addendum.md`
   - This git workflow document

2. **WORK** on exactly ONE phase (P0 OR P1 OR P2)

3. **END** by:
   - Placing all changed files in `MANUAL_COPY_FILES/`
   - Creating `COPY_INSTRUCTIONS.txt` with exact paths
   - Providing the standard commit/push workflow
   - Listing which DOWN migration SQL to keep for rollback

4. **NEVER** mix phases in one session. If P0 is not merged yet, do NOT start P1 code.

---

## 10. QUICK REFERENCE COMMANDS

```powershell
# Create bookmark
.\scripts\create-bookmark.ps1

# Rollback to any bookmark
.\scripts\rollback-to-tag.ps1 "stable-pre-domain-audit-20260211"

# List all bookmarks across repos
cd contractnest-ui; git tag -l "stable-*"; cd ..
cd contractnest-api; git tag -l "stable-*"; cd ..
cd contractnest-edge; git tag -l "stable-*"; cd ..

# Check which branch you're on across all repos
foreach ($sub in @("contractnest-api","contractnest-ui","contractnest-edge","ClaudeDocumentation")) {
    Push-Location $sub
    $branch = git branch --show-current
    Write-Host "$sub : $branch" -ForegroundColor $(if ($branch -eq "main" -or $branch -eq "master") {"Green"} else {"Yellow"})
    Pop-Location
}

# Check for uncommitted changes across all repos
foreach ($sub in @("contractnest-api","contractnest-ui","contractnest-edge","ClaudeDocumentation")) {
    Push-Location $sub
    $status = git status --porcelain
    if ($status) {
        Write-Host "$sub : HAS UNCOMMITTED CHANGES" -ForegroundColor Red
        Write-Host $status -ForegroundColor Gray
    } else {
        Write-Host "$sub : clean" -ForegroundColor Green
    }
    Pop-Location
}
```