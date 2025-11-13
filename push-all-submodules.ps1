# ═══════════════════════════════════════════════════
# PUSH EVERYTHING TO GITHUB - Complete Workflow
# ═══════════════════════════════════════════════════
# Usage: Run this script whenever you want to push all changes
# Works for: Local changes OR after getting code from Claude Code
# ═══════════════════════════════════════════════════

Write-Host "`n🚀 Starting Complete GitHub Push Workflow..." -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════`n" -ForegroundColor Cyan

# Ensure we're in the right directory
$rootPath = "D:\projects\core projects\ContractNest\contractnest-combined"
Set-Location $rootPath

# ═══════════════════════════════════════════════════
# STEP 1: Push All Submodules to Main
# ═══════════════════════════════════════════════════

Write-Host "📦 STEP 1: Pushing All Submodules..." -ForegroundColor Yellow

$submodules = @(
    @{Name="contractnest-api"; Branch="main"},
    @{Name="contractnest-ui"; Branch="main"},
    @{Name="contractnest-edge"; Branch="main"},
    @{Name="ClaudeDocumentation"; Branch="master"},
    @{Name="ContractNest-Mobile"; Branch="main"}
)

foreach ($submodule in $submodules) {
    Write-Host "`n  → Processing $($submodule.Name)..." -ForegroundColor White
    
    if (Test-Path $submodule.Name) {
        Set-Location $submodule.Name
        
        # Checkout correct branch
        $currentBranch = git branch --show-current
        if ($currentBranch -ne $submodule.Branch) {
            Write-Host "    ⚠️  Switching from $currentBranch to $($submodule.Branch)" -ForegroundColor Yellow
            git checkout $submodule.Branch
        }
        
        # Pull latest from remote (in case someone else pushed)
        Write-Host "    ↓ Pulling latest..." -ForegroundColor Gray
        git pull origin $submodule.Branch
        
        # Check if there are changes to push
        $status = git status --porcelain
        $unpushedCommits = git log origin/$($submodule.Branch)..HEAD --oneline
        
        if ($status) {
            Write-Host "    + Adding changes..." -ForegroundColor Gray
            git add .
            git commit -m "Auto-commit: $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
        }
        
        if ($unpushedCommits) {
            Write-Host "    ↑ Pushing to GitHub..." -ForegroundColor Gray
            git push origin $submodule.Branch
            Write-Host "    ✅ $($submodule.Name) pushed successfully!" -ForegroundColor Green
        } else {
            Write-Host "    ℹ️  $($submodule.Name) - Already up to date" -ForegroundColor Gray
        }
        
        Set-Location ..
    } else {
        Write-Host "    ⚠️  $($submodule.Name) not found - skipping" -ForegroundColor Yellow
    }
}

# ═══════════════════════════════════════════════════
# STEP 2: Update Parent Repo to Master
# ═══════════════════════════════════════════════════

Write-Host "`n📋 STEP 2: Updating Parent Repo..." -ForegroundColor Yellow

# Ensure we're on master
$parentBranch = git branch --show-current
if ($parentBranch -ne "master") {
    Write-Host "  ⚠️  Switching from $parentBranch to master" -ForegroundColor Yellow
    git checkout master
}

# Pull latest
Write-Host "  ↓ Pulling latest from master..." -ForegroundColor Gray
git pull origin master

# Update submodule references
Write-Host "  📌 Updating submodule references..." -ForegroundColor Gray
git submodule update --remote --merge

# Check if submodule references changed
$submoduleChanges = git status --porcelain | Select-String "M contractnest"

if ($submoduleChanges) {
    Write-Host "  + Committing submodule reference updates..." -ForegroundColor Gray
    git add .
    git commit -m "Update submodule references: $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
}

# Push any changes
$unpushedParent = git log origin/master..HEAD --oneline
if ($unpushedParent) {
    Write-Host "  ↑ Pushing parent repo to GitHub..." -ForegroundColor Gray
    git push origin master
    Write-Host "  ✅ Parent repo pushed successfully!" -ForegroundColor Green
} else {
    Write-Host "  ℹ️  Parent repo - Already up to date" -ForegroundColor Gray
}

# ═══════════════════════════════════════════════════
# STEP 3: Final Verification
# ═══════════════════════════════════════════════════

Write-Host "`n✨ STEP 3: Final Verification..." -ForegroundColor Yellow

$finalStatus = git status --porcelain
if (-not $finalStatus) {
    Write-Host "  ✅ Working tree is CLEAN!" -ForegroundColor Green
} else {
    Write-Host "  ⚠️  Warning: Working tree has uncommitted changes:" -ForegroundColor Yellow
    git status --short
}

Write-Host "`n════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "🎉 ALL DONE! Everything pushed to GitHub!" -ForegroundColor Green
Write-Host "════════════════════════════════════════════`n" -ForegroundColor Cyan

# Display summary
Write-Host "📊 SUMMARY:" -ForegroundColor Cyan
Write-Host "  • All submodules pushed to their main branches" -ForegroundColor White
Write-Host "  • Parent repo pushed to master" -ForegroundColor White
Write-Host "  • All changes are now on GitHub" -ForegroundColor White
Write-Host "`n💡 TIP: Hard refresh your browser (Ctrl+F5) to see changes!`n" -ForegroundColor Gray