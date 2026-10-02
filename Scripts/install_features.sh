#!/usr/bin/env bash
# install_features.sh — Install FoodFinder + LoopInsights + AutoPresets into a standard Loop clone
#
# ONE-LINER INSTALL (run from your LoopWorkspace folder):
#   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/LoopPowerPack/LoopWorkspace/feat/installer/Scripts/install_features.sh)"
#
# Or if you already have the scripts locally:
#   ./Scripts/install_features.sh            # Install features
#   ./Scripts/install_features.sh --rollback  # Remove features and restore prior state
#
# Concept & design by Taylor Patterson. Coded by Claude Code in February 2026.
# Copyright (c) 2025-2026 LoopKit Authors. All rights reserved.

set -euo pipefail

# ─── Constants ────────────────────────────────────────────────────────────────

FEATURE_REMOTE="_feature_src"
FEATURE_BRANCH="feat/installer"
FEATURE_LOOP_BRANCH="feat/AllFeatures"
FEATURE_REPO="https://github.com/LoopPowerPack/Loop.git"
FEATURE_WORKSPACE_REPO="https://raw.githubusercontent.com/LoopPowerPack/LoopWorkspace/${FEATURE_BRANCH}"
MARKER_FILE=".feature_install_marker"

# OmniBLE pod-keep-alive: fixes DASH connectivity on iPhone 16/17 with InPlay BLE (Atlas) pods
OMNIBLE_POD_KEEP_ALIVE_SHA="dade6ed309eb72232a187d88179a367e34f800d9"

# Version to stamp after installation
FEATURE_VERSION="3.13.1"
FEATURE_BUILD="58"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ─── New files (don't exist in standard Loop) ────────────────────────────────

NEW_FILES=(
    # Documentation
    "Documentation/FoodFinder/FoodFinder_README.md"
    "Documentation/LoopInsights/LoopInsights_README.md"

    # AutoPresets — Managers
    "Loop/Managers/AutoPresets/AutoPresets_ActivityDetectionManager.swift"
    "Loop/Managers/AutoPresets/AutoPresets_Coordinator.swift"
    "Loop/Managers/AutoPresets/AutoPresets_Delegate.swift"
    "Loop/Managers/AutoPresets/AutoPresets_GeofenceManager.swift"
    "Loop/Managers/AutoPresets/AutoPresets_CalendarManager.swift"
    "Loop/Managers/AutoPresets/AutoPresets_Logger.swift"
    "Loop/Managers/AutoPresets/AutoPresets_Storage.swift"

    # GraphDetailView — Managers
    "Loop/Managers/GraphDetailViewModel.swift"

    # LoopInsights — Managers
    "Loop/Managers/LoopInsights/LoopInsights_BackgroundMonitor.swift"
    "Loop/Managers/LoopInsights/LoopInsights_Coordinator.swift"

    # AutoPresets — Models
    "Loop/Models/AutoPresets/AutoPresets_Models.swift"
    "Loop/Models/AutoPresets/AutoPresets_RecommendationModels.swift"

    # AutoPresets — Services
    "Loop/Services/AutoPresets/AutoPresets_AIAdvisor.swift"

    # FoodFinder — Models
    "Loop/Models/FoodFinder/FoodFinder_AnalysisRecord.swift"
    "Loop/Models/FoodFinder/FoodFinder_InputResults.swift"
    "Loop/Models/FoodFinder/FoodFinder_Models.swift"

    # LoopInsights — Models
    "Loop/Models/LoopInsights/LoopInsights_Models.swift"
    "Loop/Models/LoopInsights/LoopInsights_MFPModels.swift"
    "Loop/Models/LoopInsights/LoopInsights_Phase5Models.swift"
    "Loop/Models/LoopInsights/LoopInsights_SuggestionRecord.swift"

    # FoodFinder — Resources
    "Loop/Resources/FoodFinder/FoodFinder_FeatureFlags.swift"

    # LoopInsights — Resources
    "Loop/Resources/LoopInsights/LoopInsights_FeatureFlags.swift"
    "Loop/Resources/LoopInsights/TestData/tidepool_carb_entries.json"
    "Loop/Resources/LoopInsights/TestData/tidepool_dose_entries.json"
    "Loop/Resources/LoopInsights/TestData/tidepool_glucose_samples.json"
    "Loop/Resources/LoopInsights/TestData/tidepool_therapy_settings.json"

    # FoodFinder — Services
    "Loop/Services/FoodFinder/FoodFinder_CarbTrackingService.swift"
    "Loop/Services/FoodFinder/FoodFinder_AIAnalysis.swift"
    "Loop/Services/FoodFinder/FoodFinder_AIProviderConfig.swift"
    "Loop/Services/FoodFinder/FoodFinder_AIServiceAdapter.swift"
    "Loop/Services/FoodFinder/FoodFinder_AIServiceManager.swift"
    "Loop/Services/FoodFinder/FoodFinder_AnalysisHistoryStore.swift"
    "Loop/Services/FoodFinder/FoodFinder_EmojiProvider.swift"
    "Loop/Services/FoodFinder/FoodFinder_ImageDownloader.swift"
    "Loop/Services/FoodFinder/FoodFinder_ImageStore.swift"
    "Loop/Services/FoodFinder/FoodFinder_LocationService.swift"
    "Loop/Services/FoodFinder/FoodFinder_OpenFoodFactsService.swift"
    "Loop/Services/FoodFinder/FoodFinder_ScannerService.swift"
    "Loop/Services/FoodFinder/FoodFinder_SearchRouter.swift"
    "Loop/Services/FoodFinder/FoodFinder_SecureStorage.swift"
    "Loop/Services/FoodFinder/FoodFinder_VoiceService.swift"

    # LoopInsights — Services
    "Loop/Services/LoopInsights/LoopInsights_AdvancedAnalyzers.swift"
    "Loop/Services/LoopInsights/LoopInsights_AIAnalysis.swift"
    "Loop/Services/LoopInsights/LoopInsights_AIServiceAdapter.swift"
    "Loop/Services/LoopInsights/LoopInsights_AlcoholTracker.swift"
    "Loop/Services/LoopInsights/LoopInsights_ChatHistoryStore.swift"
    "Loop/Services/LoopInsights/LoopInsights_CaffeineTracker.swift"
    "Loop/Services/LoopInsights/LoopInsights_VoiceService.swift"
    "Loop/Services/LoopInsights/LoopInsights_BackfillDetector.swift"
    "Loop/Services/LoopInsights/LoopInsights_BehaviorInsightsAnalyzer.swift"
    "Loop/Services/LoopInsights/LoopInsights_CaregiverDigestService.swift"
    "Loop/Services/LoopInsights/LoopInsights_DataAggregator.swift"
    "Loop/Services/LoopInsights/LoopInsights_FoodResponseAnalyzer.swift"
    "Loop/Services/LoopInsights/LoopInsights_GlucoseUnitContext.swift"
    "Loop/Services/LoopInsights/LoopInsights_GoalStore.swift"
    "Loop/Services/LoopInsights/LoopInsights_HealthKitManager.swift"
    "Loop/Services/LoopInsights/LoopInsights_NightscoutImporter.swift"
    "Loop/Services/LoopInsights/LoopInsights_ReportGenerator.swift"
    "Loop/Services/LoopInsights/LoopInsights_SecureStorage.swift"
    "Loop/Services/LoopInsights/LoopInsights_SuggestionStore.swift"
    "Loop/Services/LoopInsights/LoopInsights_TestDataProvider.swift"
    "Loop/Services/LoopInsights/LoopInsights_MealDebriefService.swift"
    "Loop/Services/LoopInsights/LoopInsights_MFPImporter.swift"
    "Loop/Services/LoopInsights/LoopInsights_PreMealAdvisorService.swift"

    # FoodFinder — View Models
    "Loop/View Models/FoodFinder/FoodFinder_SearchViewModel.swift"

    # LoopInsights — View Models
    "Loop/View Models/LoopInsights/LoopInsights_ChatViewModel.swift"
    "Loop/View Models/LoopInsights/LoopInsights_DashboardViewModel.swift"
    "Loop/View Models/LoopInsights/LoopInsights_MealInsightsViewModel.swift"

    # AutoPresets — Views
    "Loop/Views/AutoPresets/AutoPresets_AIRecommendationView.swift"
    "Loop/Views/AutoPresets/AutoPresets_GeofenceSettingsView.swift"
    "Loop/Views/AutoPresets/AutoPresets_CalendarSettingsView.swift"
    "Loop/Views/AutoPresets/AutoPresets_SettingsView.swift"

    # AutoPresets — Resources
    "Loop/Resources/AutoPresets/AutoPresets_FeatureFlags.swift"

    # GraphDetailView — Views
    "Loop/Views/GraphDetailView.swift"

    # FoodFinder — Views
    "Loop/Views/FoodFinder/FoodFinder_CarbTrackingDashboard.swift"
    "Loop/Views/FoodFinder/FoodFinder_AICameraView.swift"
    "Loop/Views/FoodFinder/FoodFinder_ImageCropView.swift"
    "Loop/Views/FoodFinder/FoodFinder_EntryPoint.swift"
    "Loop/Views/FoodFinder/FoodFinder_FavoritesHelpers.swift"
    "Loop/Views/FoodFinder/FoodFinder_ScannerView.swift"
    "Loop/Views/FoodFinder/FoodFinder_SearchBar.swift"
    "Loop/Views/FoodFinder/FoodFinder_SearchResultsView.swift"
    "Loop/Views/FoodFinder/FoodFinder_SettingsView.swift"
    "Loop/Views/FoodFinder/FoodFinder_VoiceSearchView.swift"

    # LoopInsights — Views
    "Loop/Views/LoopInsights/LoopInsights_AGPChartView.swift"
    "Loop/Views/LoopInsights/LoopInsights_AlcoholLogView.swift"
    "Loop/Views/LoopInsights/LoopInsights_BehaviorInsightsView.swift"
    "Loop/Views/LoopInsights/LoopInsights_CaregiverDigestView.swift"
    "Loop/Views/LoopInsights/LoopInsights_EndoReportView.swift"
    "Loop/Views/LoopInsights/LoopInsights_ChatHistoryView.swift"
    "Loop/Views/LoopInsights/LoopInsights_CaffeineLogView.swift"
    "Loop/Views/LoopInsights/LoopInsights_ChatView.swift"
    "Loop/Views/LoopInsights/LoopInsights_DashboardView.swift"
    "Loop/Views/LoopInsights/LoopInsights_GoalsView.swift"
    "Loop/Views/LoopInsights/LoopInsights_MealInsightsView.swift"
    "Loop/Views/LoopInsights/LoopInsights_MonitorSettingsView.swift"
    "Loop/Views/LoopInsights/LoopInsights_SettingsView.swift"
    "Loop/Views/LoopInsights/LoopInsights_SuggestionDetailView.swift"
    "Loop/Views/LoopInsights/LoopInsights_SuggestionHistoryView.swift"
    "Loop/Views/LoopInsights/LoopInsights_TrendsInsightsView.swift"
    "Loop/Views/LoopInsights/LoopInsights_MealDebriefCard.swift"
    "Loop/Views/LoopInsights/LoopInsights_PreMealAdvisorCard.swift"

    # LoopInsights — Models
    "Loop/Models/LoopInsights/LoopInsights_MealDebriefModels.swift"

    # DataLayer — Managers
    "Loop/Managers/DataLayer/DataLayer_Coordinator.swift"

    # DataLayer — Models
    "Loop/Models/DataLayer/DataLayer_EventModels.swift"
    "Loop/Models/DataLayer/DataLayer_ConsentModels.swift"

    # DataLayer — Resources
    "Loop/Resources/DataLayer/DataLayer_FeatureFlags.swift"

    # DataLayer — Services
    "Loop/Services/DataLayer/DataLayer_SecureStorage.swift"
    "Loop/Services/DataLayer/DataLayer_ConsentManager.swift"
    "Loop/Services/DataLayer/DataLayer_EventStore.swift"
    "Loop/Services/DataLayer/DataLayer_EventCollector.swift"
    "Loop/Services/DataLayer/DataLayer_SyncService.swift"
    "Loop/Services/DataLayer/DataLayer_ReportGenerator.swift"
    "Loop/Services/DataLayer/DataLayer_ProviderProtocol.swift"

    # DataLayer — Views
    "Loop/Views/DataLayer/DataLayer_ConsentView.swift"
    "Loop/Views/DataLayer/DataLayer_DashboardView.swift"

    # SiteAtlas — Documentation
    "Documentation/SiteAtlas/Developer.md"
    "Documentation/SiteAtlas/User.md"

    # SiteAtlas — Models
    "Loop/Models/SiteAtlas/SiteAtlas_Models.swift"

    # SiteAtlas — Services
    "Loop/Services/SiteAtlas/SiteAtlas_Coordinator.swift"
    "Loop/Services/SiteAtlas/SiteAtlas_FeatureFlags.swift"
    "Loop/Services/SiteAtlas/SiteAtlas_Storage.swift"

    # SiteAtlas — Views
    "Loop/Views/SiteAtlas/SiteAtlas_BodyMapView.swift"
    "Loop/Views/SiteAtlas/SiteAtlas_SettingsView.swift"
    "Loop/Views/SiteAtlas/SiteAtlas_SiteSelectionSheet.swift"

    # FoodFinder — Tests
    "LoopTests/FoodFinder/FoodFinder_BarcodeScannerTests.swift"
    "LoopTests/FoodFinder/FoodFinder_OpenFoodFactsTests.swift"
    "LoopTests/FoodFinder/FoodFinder_VoiceSearchTests.swift"

    # LoopInsights — Tests
    "LoopTests/LoopInsights/LoopInsights_DataAggregatorTests.swift"
    "LoopTests/LoopInsights/LoopInsights_ModelsTests.swift"
    "LoopTests/LoopInsights/LoopInsights_SuggestionStoreTests.swift"
)

# Modified files to patch via git diff | git apply --3way
# Excludes: project.pbxproj (handled by Python script), SettingsView.swift (anchor-based),
# LoopDataManager.swift (anchor-based — L&L Customizations modify this file heavily),
# and Localizable.xcstrings (direct checkout — too large for 3-way merge on JSON)
PATCH_FILES=(
    "Loop/View Controllers/InsulinDeliveryTableViewController.swift"
    "Loop/View Controllers/StatusTableViewController.swift"
    "Loop/View Models/AddEditFavoriteFoodViewModel.swift"
    "Loop/View Models/CarbEntryViewModel.swift"
    "Loop/View Models/SettingsViewModel.swift"
    "Loop/Views/AddEditFavoriteFoodView.swift"
    "Loop/Views/CarbEntryView.swift"
    "Loop/Views/FavoriteFoodDetailView.swift"
    "Loop/Views/FavoriteFoodsView.swift"
)

# ─── Helpers ──────────────────────────────────────────────────────────────────

info()    { echo -e "${CYAN}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC}   $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()   { echo -e "${RED}[ERR]${NC}  $*"; }
header()  { echo -e "\n${BOLD}═══ $* ═══${NC}"; }

die() {
    error "$@"
    exit 1
}

# ─── Phase 1: Validation ─────────────────────────────────────────────────────

validate_environment() {
    header "Phase 1: Validating environment"

    # Must run from LoopWorkspace root
    if [[ ! -d "LoopWorkspace.xcworkspace" ]]; then
        die "Must run from LoopWorkspace root directory (LoopWorkspace.xcworkspace not found).
  cd into your LoopWorkspace folder and try again."
    fi
    success "Running from LoopWorkspace root"

    # Loop submodule must exist
    if [[ ! -d "Loop/.git" ]] && [[ ! -f "Loop/.git" ]]; then
        die "Loop submodule not found. Make sure you've cloned with --recurse-submodules."
    fi
    success "Loop submodule exists"

    # python3 available
    if ! command -v python3 &>/dev/null; then
        die "python3 is required but not found. Install Python 3 and try again."
    fi
    success "python3 available ($(python3 --version 2>&1))"

    # Check for existing feature files (idempotency)
    if [[ -f "Loop/${MARKER_FILE}" ]]; then
        die "Features are already installed (marker file found).
  To reinstall, run: ./Scripts/install_features.sh --rollback  first."
    fi

    local sample_files=(
        "Loop/Loop/Views/FoodFinder/FoodFinder_EntryPoint.swift"
        "Loop/Loop/Views/LoopInsights/LoopInsights_DashboardView.swift"
        "Loop/Loop/Views/AutoPresets/AutoPresets_SettingsView.swift"
    )
    for f in "${sample_files[@]}"; do
        if [[ -f "$f" ]]; then
            die "Feature files already exist ($f found).
  To reinstall, run: ./Scripts/install_features.sh --rollback  first."
        fi
    done
    success "No existing feature files found"

    # Verify SettingsView.swift anchors exist
    local settings_file="Loop/Loop/Views/SettingsView.swift"
    if [[ ! -f "$settings_file" ]]; then
        die "SettingsView.swift not found at expected path."
    fi

    if ! grep -q 'Diabetes Treatment' "$settings_file"; then
        die "Anchor not found in SettingsView.swift: Diabetes Treatment
  Your Loop version may be incompatible."
    fi

    if ! grep -q 'private var cgmChoices' "$settings_file"; then
        die "Anchor not found in SettingsView.swift: private var cgmChoices
  Your Loop version may be incompatible."
    fi
    success "SettingsView.swift anchors verified"

    # Detect L&L patches (informational only)
    detect_ll_patches
}

detect_ll_patches() {
    local settings_file="Loop/Loop/Views/SettingsView.swift"
    local found_patches=()

    if grep -q "ProfileManager\|Profiles" "$settings_file" 2>/dev/null; then
        found_patches+=("Profiles")
    fi

    if grep -q "basalLock\|BasalLock\|basal_lock" "Loop/Loop/Managers/LoopDataManager.swift" 2>/dev/null; then
        found_patches+=("Basal Lock")
    fi

    if grep -q "negativeInsulin\|NegativeInsulin\|negative_insulin" "Loop/Loop/Managers/LoopDataManager.swift" 2>/dev/null; then
        found_patches+=("Negative Insulin")
    fi

    local carb_file="Loop/Loop/Views/CarbEntryView.swift"
    if grep -q "futureCarb\|FutureCarb\|future_carb_4h\|absorptionTimeWasEdited" "$carb_file" 2>/dev/null; then
        found_patches+=("Future Carbs 4h")
    fi

    if [[ ${#found_patches[@]} -gt 0 ]]; then
        info "Detected L&L patches: ${found_patches[*]}"
        info "These are compatible — the installer will adapt to them."
    else
        info "No L&L patches detected (standard Loop)."
    fi
}

# ─── Phase 2: Backup ─────────────────────────────────────────────────────────

create_backup() {
    header "Phase 2: Creating backup"

    pushd Loop > /dev/null

    # Stash any uncommitted changes (including L&L patches) as a safety backup,
    # then immediately restore them so L&L patches remain in the working tree
    # during installation. The stash entry stays for rollback.
    local stash_msg="pre-feature-install-$(date +%Y%m%d-%H%M%S)"
    if ! git diff --quiet || ! git diff --cached --quiet; then
        git stash push -m "$stash_msg" --include-untracked
        git stash apply 2>/dev/null
        success "Backed up working tree as: $stash_msg (L&L patches preserved)"
    else
        info "Working tree clean, no stash needed."
    fi

    popd > /dev/null
}

# ─── Phase 3: Fetch Source ────────────────────────────────────────────────────

setup_source_remote() {
    header "Phase 3: Fetching feature source"

    pushd Loop > /dev/null

    # Remove stale remote if it exists
    if git remote | grep -q "^${FEATURE_REMOTE}$"; then
        git remote remove "$FEATURE_REMOTE"
    fi

    git remote add "$FEATURE_REMOTE" "$FEATURE_REPO"
    git fetch "$FEATURE_REMOTE" "$FEATURE_LOOP_BRANCH" --depth=1
    success "Fetched ${FEATURE_LOOP_BRANCH} from ${FEATURE_REPO}"

    # Also fetch dev — our feature branch was based on dev, so we need it as the diff base
    # even when the user cloned main (which is the L&L-compatible path)
    git fetch "$FEATURE_REMOTE" dev --depth=1
    success "Fetched dev ref for diff base"

    popd > /dev/null
}

# ─── Phase 3b: Update OmniBLE to pod-keep-alive ─────────────────────────────

update_omnible() {
    header "Phase 3b: Updating OmniBLE to pod-keep-alive"

    if [[ ! -d "OmniBLE/.git" ]] && [[ ! -f "OmniBLE/.git" ]]; then
        warn "OmniBLE submodule not found — skipping pod-keep-alive update"
        return
    fi

    pushd OmniBLE > /dev/null

    # Fetch the pod-keep-alive branch from upstream
    git fetch origin pod-keep-alive --depth=1 2>/dev/null || {
        warn "Could not fetch pod-keep-alive branch from OmniBLE — skipping"
        popd > /dev/null
        return
    }

    git checkout "$OMNIBLE_POD_KEEP_ALIVE_SHA" 2>/dev/null || {
        warn "Could not checkout OmniBLE pod-keep-alive SHA — skipping"
        popd > /dev/null
        return
    }

    popd > /dev/null
    success "OmniBLE updated to pod-keep-alive (DASH connectivity fix)"
}

# ─── Phase 3c: Bump version ─────────────────────────────────────────────────

bump_version() {
    header "Phase 3c: Setting version to ${FEATURE_VERSION} (${FEATURE_BUILD})"

    if [[ -f "VersionOverride.xcconfig" ]]; then
        sed -i '' "s/LOOP_MARKETING_VERSION = .*/LOOP_MARKETING_VERSION = ${FEATURE_VERSION}/" VersionOverride.xcconfig
        sed -i '' "s/CURRENT_PROJECT_VERSION = .*/CURRENT_PROJECT_VERSION = ${FEATURE_BUILD}/" VersionOverride.xcconfig
        success "Version set to ${FEATURE_VERSION} build ${FEATURE_BUILD}"
    else
        warn "VersionOverride.xcconfig not found — version not updated"
    fi
}

# ─── Phase 4: Install New Files ──────────────────────────────────────────────

install_new_files() {
    header "Phase 4: Installing ${#NEW_FILES[@]} new files"

    pushd Loop > /dev/null

    local installed=0
    local failed=0

    for file in "${NEW_FILES[@]}"; do
        if git checkout "${FEATURE_REMOTE}/${FEATURE_LOOP_BRANCH}" -- "$file" 2>/dev/null; then
            ((installed++))
        else
            warn "Failed to checkout: $file"
            ((failed++))
        fi
    done

    # Localizable.xcstrings: direct checkout instead of 3-way merge
    # (71K-line JSON file — too large for reliable diff/apply)
    # Only replace if the user already has it (dev branch uses xcstrings;
    # main branch uses old-style .strings files and doesn't have xcstrings)
    if [[ -f "Loop/Localizable.xcstrings" ]]; then
        if git checkout "${FEATURE_REMOTE}/${FEATURE_LOOP_BRANCH}" -- "Loop/Localizable.xcstrings" 2>/dev/null; then
            ((installed++))
            success "Replaced Localizable.xcstrings (direct checkout)"
        else
            warn "Failed to checkout Localizable.xcstrings"
            ((failed++))
        fi
    else
        info "Skipping Localizable.xcstrings (not present on this branch — features use NSLocalizedString fallback)"
    fi

    popd > /dev/null

    success "Installed $installed files"
    if [[ $failed -gt 0 ]]; then
        warn "$failed files failed to install"
    fi
}

# ─── Phase 4b: Install SiteAtlas Body Map Assets ─────────────────────────────

install_body_map_assets() {
    header "Phase 4b: Installing SiteAtlas body map assets"

    pushd Loop > /dev/null

    local assets_base="Loop/DerivedAssetsBase.xcassets"

    # Pull the PNGs from the feature branch into a temp location
    local tmp_front tmp_back
    tmp_front=$(mktemp)
    tmp_back=$(mktemp)

    if git show "${FEATURE_REMOTE}/${FEATURE_LOOP_BRANCH}:Loop/Resources/SiteAtlas/BodyMapFront.png" > "$tmp_front" 2>/dev/null && \
       git show "${FEATURE_REMOTE}/${FEATURE_LOOP_BRANCH}:Loop/Resources/SiteAtlas/BodyMapBack.png" > "$tmp_back" 2>/dev/null; then

        # Create imageset directories
        mkdir -p "$assets_base/BodyMapFront.imageset"
        mkdir -p "$assets_base/BodyMapBack.imageset"

        # Copy PNGs
        cp "$tmp_front" "$assets_base/BodyMapFront.imageset/BodyMapFront.png"
        cp "$tmp_back"  "$assets_base/BodyMapBack.imageset/BodyMapBack.png"

        # Write Contents.json for each
        cat > "$assets_base/BodyMapFront.imageset/Contents.json" << 'IMGEOF'
{
  "images" : [
    {
      "filename" : "BodyMapFront.png",
      "idiom" : "universal"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
IMGEOF

        cat > "$assets_base/BodyMapBack.imageset/Contents.json" << 'IMGEOF'
{
  "images" : [
    {
      "filename" : "BodyMapBack.png",
      "idiom" : "universal"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
IMGEOF

        success "Installed BodyMapFront + BodyMapBack imagesets into DerivedAssetsBase.xcassets"
    else
        warn "Could not retrieve body map PNGs from feature branch — SiteAtlas will use fallback icon"
    fi

    rm -f "$tmp_front" "$tmp_back"
    popd > /dev/null
}

# ─── Phase 5: Patch Modified Files ───────────────────────────────────────────

patch_modified_files() {
    header "Phase 5: Patching ${#PATCH_FILES[@]} modified files"

    pushd Loop > /dev/null

    # We need the dev branch as the diff base. feat/AllFeatures was branched from dev,
    # so `git diff dev..feat/AllFeatures` isolates ONLY our feature changes.
    # We fetched dev from our remote in Phase 3, so it's always available —
    # even when the user cloned main (the L&L-compatible path).
    local dev_ref
    dev_ref=$(git rev-parse "${FEATURE_REMOTE}/dev" 2>/dev/null)
    if [[ -z "$dev_ref" ]]; then
        # Fallback to local dev branches
        dev_ref=$(git rev-parse dev 2>/dev/null || git rev-parse origin/dev 2>/dev/null || git rev-parse upstream/dev 2>/dev/null)
    fi
    if [[ -z "$dev_ref" ]]; then
        die "Cannot find dev branch reference. The feature remote fetch may have failed."
    fi

    local patched=0
    local failed=0
    local skipped=0

    for file in "${PATCH_FILES[@]}"; do
        local diff_output
        diff_output=$(git diff "$dev_ref".."${FEATURE_REMOTE}/${FEATURE_LOOP_BRANCH}" -- "$file" 2>/dev/null)

        if [[ -z "$diff_output" ]]; then
            info "No changes for: $file (skipped)"
            ((skipped++))
            continue
        fi

        if echo "$diff_output" | git apply --3way 2>/dev/null; then
            success "Patched: $file"
            ((patched++))
        else
            warn "3-way merge had conflicts for: $file"
            warn "  → Check for conflict markers and resolve manually."
            ((failed++))
        fi
    done

    popd > /dev/null

    info "Patched: $patched, Skipped: $skipped, Conflicts: $failed"
    if [[ $failed -gt 0 ]]; then
        warn "Some files had merge conflicts. Resolve them before building."
    fi
}

# ─── Phase 6: Patch SettingsView.swift (Anchor-Based) ────────────────────────

patch_settings_view() {
    header "Phase 6: Patching SettingsView.swift (anchor-based)"

    local settings_file="Loop/Loop/Views/SettingsView.swift"

    # Use Python for reliable multi-line text insertion
    python3 - "$settings_file" << 'PYTHON_SCRIPT'
import sys

settings_path = sys.argv[1]

with open(settings_path, "r") as f:
    content = f.read()

lines = content.split("\n")

# ─── Anchor 1: Insert feature rows AFTER the Therapy Settings button ───
# We anchor on "Diabetes Treatment" (the Therapy Settings descriptive text) so our
# features appear right after Therapy Settings. If L&L Profiles is installed, it
# inserts before the ForEach — so Profiles ends up BELOW our features.

FEATURE_ROWS = """
            NavigationLink(destination: AutoPresets_SettingsView(dataStoresProvider: viewModel.loopInsightsDataStores)) {
                LargeButton(
                    action: {},
                    includeArrow: false,
                    imageView: AutoPresets_IconView(),
                    label: NSLocalizedString("AutoPresets", comment: "Title text for button to AutoPresets Settings"),
                    descriptiveText: NSLocalizedString("Automate your presets during motion", comment: "Descriptive text for Auto-Apply Presets")
                )
            }

            foodFinderSettingsRow

            loopInsightsSection

            siteAtlasSettingsRow
"""

anchor1 = 'Diabetes Treatment'
anchor1_idx = None
for i, line in enumerate(lines):
    if anchor1 in line:
        anchor1_idx = i
        break

if anchor1_idx is None:
    print(f"ERROR: Anchor 1 not found: {anchor1}", file=sys.stderr)
    sys.exit(1)

# Insert the feature rows AFTER the Therapy Settings descriptive text line
feature_lines = FEATURE_ROWS.rstrip("\n").split("\n")
insert_at = anchor1_idx + 2  # after the NavigationLink closing brace (line after "Diabetes Treatment")
for j, fl in enumerate(feature_lines):
    lines.insert(insert_at + j, fl)
print(f"  Inserted {len(feature_lines)} lines after Therapy Settings (line {anchor1_idx + 1})")

# ─── Anchor 2: Insert computed properties BEFORE "private var cgmChoices:" ───

COMPUTED_PROPS = """
    // FoodFinder — single settings insertion point
    private var foodFinderSettingsRow: some View {
        NavigationLink(destination: AISettingsView()) {
            LargeButton(action: {},
                        includeArrow: false,
                        imageView: Image(systemName: "fork.knife.circle.fill")
                            .foregroundColor(Color(red: 107/255, green: 47/255, blue: 160/255))
                            .font(.system(size: 36)),
                        label: NSLocalizedString("FoodFinder", comment: "Title text for button to FoodFinder Settings"),
                        descriptiveText: NSLocalizedString("AI-powered & barcode food analysis", comment: "Descriptive text for FoodFinder Settings"))
        }
    }

    private var loopInsightsSection: some View {
        Section {
            NavigationLink(destination: LoopInsights_SettingsView(dataStoresProvider: viewModel.loopInsightsDataStores)) {
                LargeButton(action: {},
                            includeArrow: false,
                            imageView: Image(systemName: "brain.head.profile")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .foregroundColor(Color(red: 26/255, green: 138/255, blue: 158/255))
                                .frame(width: 30),
                            label: NSLocalizedString("LoopInsights", comment: "LoopInsights settings button"),
                            descriptiveText: NSLocalizedString("AI-powered therapy settings analysis", comment: "LoopInsights settings descriptive text"))
            }
        }
    }

    private var siteAtlasSettingsRow: some View {
        NavigationLink(destination: SiteAtlas_SettingsView()) {
            LargeButton(action: {},
                        includeArrow: false,
                        imageView: Image(systemName: "mappin.and.ellipse")
                            .foregroundColor(Color(red: 230/255, green: 126/255, blue: 34/255))
                            .font(.system(size: 36)),
                        label: NSLocalizedString("Site Atlas", comment: "Title text for button to Site Atlas Settings"),
                        descriptiveText: NSLocalizedString("Track pump and sensor site rotation", comment: "Descriptive text for Site Atlas"))
        }
    }

"""

anchor2 = "private var cgmChoices:"
anchor2_idx = None
# Re-scan from scratch since lines array was modified
for i, line in enumerate(lines):
    if anchor2 in line:
        anchor2_idx = i
        break

if anchor2_idx is None:
    print(f"ERROR: Anchor 2 not found: {anchor2}", file=sys.stderr)
    sys.exit(1)

prop_lines = COMPUTED_PROPS.rstrip("\n").split("\n")
for j, pl in enumerate(prop_lines):
    lines.insert(anchor2_idx + j, pl)
print(f"  Inserted {len(prop_lines)} lines before cgmChoices anchor (line {anchor2_idx + 1})")

# Write back
with open(settings_path, "w") as f:
    f.write("\n".join(lines))

print("  SettingsView.swift patched successfully.")
PYTHON_SCRIPT

    if [[ $? -eq 0 ]]; then
        success "SettingsView.swift patched with anchor-based insertion"
    else
        error "Failed to patch SettingsView.swift"
        return 1
    fi
}

# ─── Phase 6b: Patch LoopDataManager.swift (Anchor-Based) ────────────────────
#
# L&L Customizations heavily modify LoopDataManager.swift (Negative Insulin Damper,
# function signature changes, etc.), so git apply --3way fails silently.
# Instead, we use anchor-based insertion like SettingsView.swift.

patch_loop_data_manager() {
    header "Phase 6b: Patching LoopDataManager.swift (anchor-based)"

    local ldm_file="Loop/Loop/Managers/LoopDataManager.swift"

    if [[ ! -f "$ldm_file" ]]; then
        die "LoopDataManager.swift not found at: $ldm_file"
    fi

    # Skip if already patched
    if grep -q "AutoPresets_Coordinator" "$ldm_file"; then
        info "LoopDataManager.swift already contains AutoPresets code — skipping."
        return 0
    fi

    python3 - "$ldm_file" << 'PYTHON_SCRIPT'
import sys

ldm_path = sys.argv[1]

with open(ldm_path, "r") as f:
    content = f.read()

lines = content.split("\n")

# ─── Anchor 1: Insert delegate setup after "self.trustedTimeOffset = trustedTimeOffset" ───
# This is in the init method. The delegate line goes right after this assignment,
# before the LiveActivity setup.

DELEGATE_SETUP = """\

        // Set up AutoPresets coordinator delegate
        AutoPresets_Coordinator.shared.delegate = self

        // Initialize SiteAtlas coordinator
        _ = SiteAtlas_Coordinator.shared
"""

anchor1 = "self.trustedTimeOffset = trustedTimeOffset"
anchor1_idx = None
for i, line in enumerate(lines):
    if anchor1 in line:
        anchor1_idx = i
        break

if anchor1_idx is None:
    print(f"ERROR: Anchor not found: {anchor1}", file=sys.stderr)
    sys.exit(1)

delegate_lines = DELEGATE_SETUP.rstrip("\n").split("\n")
insert_at = anchor1_idx + 1
for j, dl in enumerate(delegate_lines):
    lines.insert(insert_at + j, dl)
print(f"  Inserted delegate setup ({len(delegate_lines)} lines) after line {anchor1_idx + 1}")

# ─── Anchor 2: Append AutoPresetsDelegate extension at end of file ───
# We find the very last closing brace of the file and append after it.

DELEGATE_EXTENSION = """
// MARK: - AutoPresets_Delegate

extension LoopDataManager: AutoPresets_Delegate {

    func autoPresets(_ coordinator: AutoPresets_Coordinator,
                     shouldActivatePreset preset: TemporaryScheduleOverridePreset) {
        logger.default("AutoPresets activating preset: %{public}@", preset.name)

        mutateSettings { settings in
            settings.scheduleOverride = preset.createOverride(enactTrigger: .local)
        }
    }

    func autoPresets(_ coordinator: AutoPresets_Coordinator,
                     shouldDeactivatePreset preset: TemporaryScheduleOverridePreset) {
        guard let currentOverride = settings.scheduleOverride,
              case let .preset(currentPreset) = currentOverride.context,
              currentPreset.id == preset.id
        else {
            return
        }

        logger.default("AutoPresets deactivating preset: %{public}@", preset.name)

        mutateSettings { settings in
            settings.scheduleOverride = nil
        }
    }

    func autoPresets(_ coordinator: AutoPresets_Coordinator,
                     shouldCreatePreset preset: TemporaryScheduleOverridePreset) {
        logger.default("AutoPresets creating AI-recommended preset: %{public}@", preset.name)

        mutateSettings { settings in
            settings.overridePresets.append(preset)
        }
    }

    func autoPresetsAvailablePresets(_ coordinator: AutoPresets_Coordinator) -> [TemporaryScheduleOverridePreset] {
        settings.overridePresets
    }

    func autoPresetsCurrentOverride(_ coordinator: AutoPresets_Coordinator) -> TemporaryScheduleOverride? {
        settings.scheduleOverride
    }
}
"""

extension_lines = DELEGATE_EXTENSION.split("\n")
lines.extend(extension_lines)
print(f"  Appended AutoPresets_Delegate extension ({len(extension_lines)} lines) at end of file")

# Write back
with open(ldm_path, "w") as f:
    f.write("\n".join(lines))

print("  LoopDataManager.swift patched successfully.")
PYTHON_SCRIPT

    if [[ $? -eq 0 ]]; then
        success "LoopDataManager.swift patched with AutoPresets delegate"
    else
        error "Failed to patch LoopDataManager.swift"
        return 1
    fi
}

# ─── Phase 7: Update project.pbxproj ─────────────────────────────────────────

update_pbxproj() {
    header "Phase 7: Updating project.pbxproj"

    local pbxproj="Loop/Loop.xcodeproj/project.pbxproj"

    if [[ ! -f "$pbxproj" ]]; then
        die "project.pbxproj not found at: $pbxproj"
    fi

    # Back up pbxproj
    cp "$pbxproj" "${pbxproj}.backup"

    # Find the update script — alongside this script, or in Scripts/, or download it
    local py_script=""
    local script_dir

    # Try 1: alongside this script (normal local run)
    if [[ -n "${BASH_SOURCE[0]:-}" ]] && [[ "${BASH_SOURCE[0]}" != "bash" ]]; then
        script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
        if [[ -f "${script_dir}/update_pbxproj.py" ]]; then
            py_script="${script_dir}/update_pbxproj.py"
        fi
    fi

    # Try 2: in Scripts/ relative to cwd (LoopWorkspace root)
    if [[ -z "$py_script" ]] && [[ -f "Scripts/update_pbxproj.py" ]]; then
        py_script="Scripts/update_pbxproj.py"
    fi

    # Try 3: download from GitHub
    if [[ -z "$py_script" ]]; then
        info "Downloading update_pbxproj.py..."
        mkdir -p Scripts
        if curl -fsSL "${FEATURE_WORKSPACE_REPO}/Scripts/update_pbxproj.py" -o Scripts/update_pbxproj.py; then
            py_script="Scripts/update_pbxproj.py"
            success "Downloaded update_pbxproj.py"
        else
            die "Failed to download update_pbxproj.py from GitHub."
        fi
    fi

    if python3 "$py_script" "$pbxproj"; then
        success "project.pbxproj updated"
    else
        error "Failed to update project.pbxproj — restoring backup"
        cp "${pbxproj}.backup" "$pbxproj"
        return 1
    fi

    # Validate
    if plutil -lint "$pbxproj" > /dev/null 2>&1; then
        success "project.pbxproj passes plutil validation"
        rm -f "${pbxproj}.backup"
    else
        error "project.pbxproj failed plutil validation — restoring backup"
        cp "${pbxproj}.backup" "$pbxproj"
        rm -f "${pbxproj}.backup"
        return 1
    fi
}

# ─── Phase 8: Replace App Icon (PowerPack branding) ─────────────────────────

replace_app_icon() {
    header "Phase 8: Installing Loop AI PowerPack icon"

    # Find the source icon — alongside this script, or download it
    local src_icon=""
    local script_dir

    if [[ -n "${BASH_SOURCE[0]:-}" ]] && [[ "${BASH_SOURCE[0]}" != "bash" ]]; then
        script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
        if [[ -f "${script_dir}/AppIcon-PowerPack.png" ]]; then
            src_icon="${script_dir}/AppIcon-PowerPack.png"
        fi
    fi

    if [[ -z "$src_icon" ]] && [[ -f "Scripts/AppIcon-PowerPack.png" ]]; then
        src_icon="Scripts/AppIcon-PowerPack.png"
    fi

    if [[ -z "$src_icon" ]]; then
        info "Downloading AppIcon-PowerPack.png..."
        mkdir -p Scripts
        if curl -fsSL "${FEATURE_WORKSPACE_REPO}/Scripts/AppIcon-PowerPack.png" -o Scripts/AppIcon-PowerPack.png; then
            src_icon="Scripts/AppIcon-PowerPack.png"
            success "Downloaded PowerPack icon"
        else
            warn "Could not download PowerPack icon — skipping icon replacement"
            return 0
        fi
    fi

    local replaced=0

    # Replace icons in all asset catalogs that have AppIcon.appiconset
    for iconset_dir in \
        "OverrideAssetsLoop.xcassets/AppIcon.appiconset" \
        "OverrideAssetsWatchApp.xcassets/AppIcon.appiconset" \
        "Loop/Loop/DerivedAssets.xcassets/AppIcon.appiconset" \
        "Loop/Loop/DerivedAssetsBase.xcassets/AppIcon.appiconset" \
        "Loop/WatchApp/DerivedAssets.xcassets/AppIcon.appiconset" \
        "Loop/WatchApp/DerivedAssetsBase.xcassets/AppIcon.appiconset"; do

        if [[ ! -d "$iconset_dir" ]]; then
            continue
        fi

        # Replace every PNG in this icon set with a resized version of the PowerPack icon
        for png in "$iconset_dir"/*.png; do
            [[ -f "$png" ]] || continue
            # Read the current dimensions and resize the source to match
            local w h
            w=$(sips -g pixelWidth "$png" 2>/dev/null | tail -1 | awk '{print $2}')
            h=$(sips -g pixelHeight "$png" 2>/dev/null | tail -1 | awk '{print $2}')
            if [[ -n "$w" ]] && [[ -n "$h" ]] && [[ "$w" -gt 0 ]]; then
                sips -z "$h" "$w" "$src_icon" --out "$png" > /dev/null 2>&1
                ((replaced++))
            fi
        done
    done

    if [[ $replaced -gt 0 ]]; then
        success "Replaced $replaced icon files across all asset catalogs"
    else
        warn "No icon files found to replace"
    fi
}

# ─── Phase 8b: Patch LoopKit (Therapy Help → LoopInsights) ───────────────────

patch_loopkit() {
    header "Phase 8b: Patching LoopKit for therapy help integration"

    local dismiss_file="LoopKit/LoopKitUI/Extensions/Environment+Dismiss.swift"
    local therapy_file="LoopKit/LoopKitUI/Views/Settings Editors/TherapySettingsView.swift"

    if [[ ! -f "$dismiss_file" ]]; then
        warn "Environment+Dismiss.swift not found at: $(pwd)/$dismiss_file"
        warn "Skipping LoopKit patch"
        return
    fi

    if [[ ! -f "$therapy_file" ]]; then
        warn "TherapySettingsView.swift not found at: $(pwd)/$therapy_file"
    fi

    # 1. Add TherapyHelpDestination to Environment+Dismiss.swift (if not already present)
    if ! grep -q "TherapyHelpDestination" "$dismiss_file"; then
        cat >> "$dismiss_file" << 'LOOPKIT_EOF'

// MARK: - Therapy Help Destination

public struct TherapyHelpDestination {
    public let view: AnyView?

    public init(_ view: AnyView? = nil) {
        self.view = view
    }

    public static let empty = TherapyHelpDestination()
}

private struct TherapyHelpDestinationKey: EnvironmentKey {
    static let defaultValue = TherapyHelpDestination.empty
}

extension EnvironmentValues {
    public var therapyHelpDestination: TherapyHelpDestination {
        get { self[TherapyHelpDestinationKey.self] }
        set { self[TherapyHelpDestinationKey.self] = newValue }
    }
}
LOOPKIT_EOF
        success "Added TherapyHelpDestination to Environment+Dismiss.swift"
    else
        info "TherapyHelpDestination already present — skipping"
    fi

    # 2. Patch Loop's SettingsView to inject therapyHelpDestination
    local settings_file="Loop/Loop/Views/SettingsView.swift"
    if [[ -f "$settings_file" ]] && ! grep -q "therapyHelpDestination" "$settings_file"; then
        python3 - "$settings_file" << 'PYEOF'
import sys

filepath = sys.argv[1]
with open(filepath, 'r') as f:
    content = f.read()

# Add .environment(\.therapyHelpDestination, ...) after .environment(\.insulinTintColor, ...)
# No feature flag check — Option B always has all features installed
old_line = '.environment(\\.insulinTintColor, self.insulinTintColor)'
new_block = old_line + '''
        .environment(\\.therapyHelpDestination,
                     TherapyHelpDestination(AnyView(LoopInsights_SettingsView(dataStoresProvider: viewModel.loopInsightsDataStores)))
        )'''

if old_line in content:
    content = content.replace(old_line, new_block, 1)
    with open(filepath, 'w') as f:
        f.write(content)
    print("OK: Injected therapyHelpDestination into SettingsView")
else:
    print("FAIL: insulinTintColor line not found in SettingsView")
    sys.exit(1)
PYEOF
        if [[ $? -eq 0 ]]; then
            success "Patched SettingsView.swift with therapy help injection"
        else
            warn "Failed to patch SettingsView.swift therapy help"
        fi
    else
        info "SettingsView therapy help already patched — skipping"
    fi

    # 3. Patch TherapySettingsView to use the environment key
    if [[ -f "$therapy_file" ]] && ! grep -q "therapyHelpDestination" "$therapy_file"; then
        python3 - "$therapy_file" << 'PYEOF'
import sys

filepath = sys.argv[1]
with open(filepath, 'r') as f:
    content = f.read()

# Add environment property after @Environment(\.appName)
old_env = '@Environment(\\.appName) private var appName'
new_env = old_env + '\n    @Environment(\\.therapyHelpDestination) private var therapyHelpDestination'
if old_env in content:
    content = content.replace(old_env, new_env)
    print("  appName environment property: injected OK")
else:
    print("  WARNING: appName environment not found — may already be patched")

# Replace the supportSection to check for injected destination
old_support = '''    private var supportSection: some View {
        Section {
            NavigationLink(destination: DemoPlaceHolderView(appName: appName)) {
                HStack {
                    Text("Get help with Therapy Settings", comment: "Support button for Therapy Settings")
                        .foregroundColor(.primary)
                    Spacer()
                    Disclosure()
                }
            }
        }
        .contentShape(Rectangle())
    }'''

new_support = '''    private var supportSection: some View {
        Section {
            if let destination = therapyHelpDestination.view {
                NavigationLink(destination: destination) {
                    HStack {
                        Text("Get help with Therapy Settings", comment: "Support button for Therapy Settings")
                            .foregroundColor(.primary)
                        Spacer()
                        Disclosure()
                    }
                }
            } else {
                NavigationLink(destination: DemoPlaceHolderView(appName: appName)) {
                    HStack {
                        Text("Get help with Therapy Settings", comment: "Support button for Therapy Settings")
                            .foregroundColor(.primary)
                        Spacer()
                        Disclosure()
                    }
                }
            }
        }
        .contentShape(Rectangle())
    }'''

if old_support in content:
    content = content.replace(old_support, new_support)
    with open(filepath, 'w') as f:
        f.write(content)
    print("OK: supportSection replaced")
else:
    print("FAIL: supportSection pattern not found in file")
    # Show what's actually around supportSection for debugging
    idx = content.find("private var supportSection")
    if idx >= 0:
        print(f"  Found 'supportSection' at offset {idx}")
        print(f"  Context: {repr(content[idx:idx+120])}")
    else:
        print("  'supportSection' not found anywhere in file!")
    sys.exit(1)
PYEOF
        if [[ $? -eq 0 ]]; then
            success "Patched TherapySettingsView.swift for therapy help"
        else
            warn "Failed to patch TherapySettingsView.swift"
        fi
    else
        info "TherapySettingsView already patched or not found — skipping"
    fi
}

# ─── Phase 9: Validate & Cleanup ─────────────────────────────────────────────

validate_installation() {
    header "Phase 9: Validating installation"

    local missing=0

    # Check a representative sample of files
    local check_files=(
        "Loop/Loop/Views/FoodFinder/FoodFinder_EntryPoint.swift"
        "Loop/Loop/Views/LoopInsights/LoopInsights_DashboardView.swift"
        "Loop/Loop/Views/AutoPresets/AutoPresets_SettingsView.swift"
        "Loop/Loop/Managers/AutoPresets/AutoPresets_Coordinator.swift"
        "Loop/Loop/Services/FoodFinder/FoodFinder_AIAnalysis.swift"
        "Loop/Loop/Services/LoopInsights/LoopInsights_DataAggregator.swift"
        "Loop/Loop/Resources/FoodFinder/FoodFinder_FeatureFlags.swift"
        "Loop/Loop/Resources/LoopInsights/LoopInsights_FeatureFlags.swift"
    )

    for f in "${check_files[@]}"; do
        if [[ ! -f "$f" ]]; then
            warn "Missing: $f"
            ((missing++))
        fi
    done

    if [[ $missing -gt 0 ]]; then
        warn "$missing expected files are missing"
    else
        success "All sample files verified"
    fi

    # Verify SettingsView.swift has our insertions
    local settings_file="Loop/Loop/Views/SettingsView.swift"
    if grep -q "foodFinderSettingsRow" "$settings_file"; then
        success "SettingsView.swift contains FoodFinder row"
    else
        warn "SettingsView.swift is missing FoodFinder row"
    fi

    if grep -q "loopInsightsSection" "$settings_file"; then
        success "SettingsView.swift contains LoopInsights section"
    else
        warn "SettingsView.swift is missing LoopInsights section"
    fi

    if grep -q "AutoPresets_SettingsView" "$settings_file"; then
        success "SettingsView.swift contains AutoPresets row"
    else
        warn "SettingsView.swift is missing AutoPresets row"
    fi

    # Write marker file
    echo "installed=$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "Loop/${MARKER_FILE}"
    success "Installation marker written"
}

cleanup() {
    header "Cleanup"

    pushd Loop > /dev/null

    # Remove temp remote
    if git remote | grep -q "^${FEATURE_REMOTE}$"; then
        git remote remove "$FEATURE_REMOTE"
        success "Removed temporary remote: $FEATURE_REMOTE"
    fi

    popd > /dev/null

    echo ""
    echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}${BOLD}  Installation Complete!${NC}"
    echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${BOLD}Next steps:${NC}"
    echo "  1. Open LoopWorkspace.xcworkspace in Xcode"
    echo "  2. Build and run (Cmd+R)"
    echo "  3. In Loop > Settings > Enable AutoPresets / FoodFinder / LoopInsights"
    echo "  4. Enter your AI API key in FoodFinder Settings"
    echo ""
    echo -e "  ${BOLD}To uninstall:${NC}"
    echo "  ./Scripts/install_features.sh --rollback"
    echo ""
}

# ─── Rollback ─────────────────────────────────────────────────────────────────

rollback() {
    header "Rolling back feature installation"

    if [[ ! -d "LoopWorkspace.xcworkspace" ]]; then
        die "Must run from LoopWorkspace root directory."
    fi

    pushd Loop > /dev/null

    # 1. Remove all new feature files
    info "Removing new feature files..."
    local removed=0
    for file in "${NEW_FILES[@]}"; do
        if [[ -f "$file" ]]; then
            rm -f "$file"
            ((removed++))
        fi
    done
    success "Removed $removed feature files"

    # Clean up empty directories
    local feature_dirs=(
        "Loop/Views/FoodFinder" "Loop/Views/LoopInsights" "Loop/Views/AutoPresets"
        "Loop/Models/FoodFinder" "Loop/Models/LoopInsights" "Loop/Models/AutoPresets"
        "Loop/Services/FoodFinder" "Loop/Services/LoopInsights"
        "Loop/Resources/FoodFinder" "Loop/Resources/LoopInsights/TestData" "Loop/Resources/LoopInsights" "Loop/Resources/AutoPresets"
        "Loop/Managers/LoopInsights" "Loop/Managers/AutoPresets"
        "Loop/View Models/FoodFinder" "Loop/View Models/LoopInsights"
        "LoopTests/FoodFinder" "LoopTests/LoopInsights"
        "Documentation/FoodFinder" "Documentation/LoopInsights"
        "Loop/Services" "Loop/Resources"
    )
    for dir in "${feature_dirs[@]}"; do
        if [[ -d "$dir" ]] && [[ -z "$(ls -A "$dir" 2>/dev/null)" ]]; then
            rmdir "$dir" 2>/dev/null || true
        fi
    done
    success "Cleaned up empty directories"

    # 2. Reset all files to HEAD state (unstages new files, restores modified files)
    info "Resetting all files to HEAD..."
    git reset HEAD -- . 2>/dev/null || true
    git checkout HEAD -- . 2>/dev/null || true
    # Remove any remaining untracked feature files
    git clean -fd -- Loop/Views/FoodFinder Loop/Views/LoopInsights Loop/Views/AutoPresets \
        Loop/Models/FoodFinder Loop/Models/LoopInsights Loop/Models/AutoPresets \
        Loop/Services/FoodFinder Loop/Services/LoopInsights \
        Loop/Resources/FoodFinder Loop/Resources/LoopInsights Loop/Resources/AutoPresets \
        Loop/Managers/LoopInsights Loop/Managers/AutoPresets \
        "Loop/View Models/FoodFinder" "Loop/View Models/LoopInsights" \
        LoopTests/FoodFinder LoopTests/LoopInsights \
        Documentation/FoodFinder Documentation/LoopInsights \
        2>/dev/null || true
    success "Reset all files to HEAD"

    # 3. Remove marker
    rm -f "$MARKER_FILE"

    # 4. Pop stash if one exists from our install
    local stash_list
    stash_list=$(git stash list 2>/dev/null || true)
    if echo "$stash_list" | grep -q "pre-feature-install"; then
        info "Found pre-install stash, restoring..."
        git stash pop 2>/dev/null || warn "Stash pop had conflicts — resolve manually."
        success "Restored pre-install state"
    fi

    # 5. Remove temp remote if still present
    if git remote | grep -q "^${FEATURE_REMOTE}$"; then
        git remote remove "$FEATURE_REMOTE"
    fi

    popd > /dev/null

    echo ""
    echo -e "${GREEN}${BOLD}  Rollback complete. Your Loop is back to its previous state.${NC}"
    echo ""
}

# ─── Main ─────────────────────────────────────────────────────────────────────

main() {
    echo -e "${BOLD}"
    echo "╔══════════════════════════════════════════════════════╗"
    echo "║  Loop Feature Installer                              ║"
    echo "║  FoodFinder + LoopInsights + AutoPresets              ║"
    echo "╚══════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    validate_environment
    create_backup
    setup_source_remote
    update_omnible
    bump_version
    install_new_files
    install_body_map_assets
    patch_modified_files
    patch_settings_view
    patch_loop_data_manager
    update_pbxproj
    replace_app_icon
    patch_loopkit
    validate_installation
    cleanup
}

# ─── Entry Point ──────────────────────────────────────────────────────────────

if [[ "${1:-}" == "--rollback" ]]; then
    rollback
else
    main
fi
