#!/usr/bin/env python3
"""
Update Loop.xcodeproj/project.pbxproj to add FoodFinder + LoopInsights + AutoPresets files.

Uses deterministic UUIDs via md5 hash for reproducibility across runs.
Finds parent group UUIDs dynamically by name for portability across Loop versions.

Concept & design by Taylor Patterson. Coded by Claude Code in February 2026.
Copyright (c) 2025-2026 LoopKit Authors. All rights reserved.
"""

import hashlib
import re
import subprocess
from typing import Optional
import sys


def make_uuid(name: str) -> str:
    """Generate a deterministic 24-char hex UUID from a name."""
    return hashlib.md5(f"FeatureInstaller_{name}".encode()).hexdigest()[:24].upper()


# ─── File Manifest ────────────────────────────────────────────────────────────
# Tuples of (relative_path_from_Loop/, filename, parent_group_key)
# parent_group_key maps to a group in the project that this file belongs under.

SOURCE_FILES = [
    # ── GraphDetailView ──
    ("Managers/GraphDetailViewModel.swift",  "GraphDetailViewModel.swift",  "Managers"),
    ("Views/GraphDetailView.swift",          "GraphDetailView.swift",       "Views"),

    # ── AutoPresets — Managers ──
    ("Managers/AutoPresets/AutoPresets_ActivityDetectionManager.swift", "AutoPresets_ActivityDetectionManager.swift", "Managers/AutoPresets"),
    ("Managers/AutoPresets/AutoPresets_Coordinator.swift",             "AutoPresets_Coordinator.swift",             "Managers/AutoPresets"),
    ("Managers/AutoPresets/AutoPresets_Delegate.swift",                "AutoPresets_Delegate.swift",                "Managers/AutoPresets"),
    ("Managers/AutoPresets/AutoPresets_GeofenceManager.swift",         "AutoPresets_GeofenceManager.swift",         "Managers/AutoPresets"),
    ("Managers/AutoPresets/AutoPresets_CalendarManager.swift",        "AutoPresets_CalendarManager.swift",         "Managers/AutoPresets"),
    ("Managers/AutoPresets/AutoPresets_Logger.swift",                  "AutoPresets_Logger.swift",                  "Managers/AutoPresets"),
    ("Managers/AutoPresets/AutoPresets_Storage.swift",                 "AutoPresets_Storage.swift",                 "Managers/AutoPresets"),

    # ── AutoPresets — Models ──
    ("Models/AutoPresets/AutoPresets_Models.swift",                    "AutoPresets_Models.swift",                  "Models/AutoPresets"),
    ("Models/AutoPresets/AutoPresets_RecommendationModels.swift",      "AutoPresets_RecommendationModels.swift",    "Models/AutoPresets"),

    # ── AutoPresets — Services ──
    ("Services/AutoPresets/AutoPresets_AIAdvisor.swift",               "AutoPresets_AIAdvisor.swift",               "Services/AutoPresets"),

    # ── AutoPresets — Resources ──
    ("Resources/AutoPresets/AutoPresets_FeatureFlags.swift",           "AutoPresets_FeatureFlags.swift",            "Resources/AutoPresets"),

    # ── AutoPresets — Views ──
    ("Views/AutoPresets/AutoPresets_AIRecommendationView.swift",      "AutoPresets_AIRecommendationView.swift",    "Views/AutoPresets"),
    ("Views/AutoPresets/AutoPresets_GeofenceSettingsView.swift",       "AutoPresets_GeofenceSettingsView.swift",    "Views/AutoPresets"),
    ("Views/AutoPresets/AutoPresets_CalendarSettingsView.swift",      "AutoPresets_CalendarSettingsView.swift",    "Views/AutoPresets"),
    ("Views/AutoPresets/AutoPresets_SettingsView.swift",               "AutoPresets_SettingsView.swift",            "Views/AutoPresets"),

    # ── FoodFinder — Models ──
    ("Models/FoodFinder/FoodFinder_AnalysisRecord.swift",   "FoodFinder_AnalysisRecord.swift",   "Models/FoodFinder"),
    ("Models/FoodFinder/FoodFinder_InputResults.swift",     "FoodFinder_InputResults.swift",     "Models/FoodFinder"),
    ("Models/FoodFinder/FoodFinder_Models.swift",           "FoodFinder_Models.swift",           "Models/FoodFinder"),

    # ── FoodFinder — Resources ──
    ("Resources/FoodFinder/FoodFinder_FeatureFlags.swift",  "FoodFinder_FeatureFlags.swift",     "Resources/FoodFinder"),

    # ── FoodFinder — Services ──
    ("Services/FoodFinder/FoodFinder_CarbTrackingService.swift", "FoodFinder_CarbTrackingService.swift", "Services/FoodFinder"),
    ("Services/FoodFinder/FoodFinder_AIAnalysis.swift",        "FoodFinder_AIAnalysis.swift",        "Services/FoodFinder"),
    ("Services/FoodFinder/FoodFinder_AIProviderConfig.swift",  "FoodFinder_AIProviderConfig.swift",  "Services/FoodFinder"),
    ("Services/FoodFinder/FoodFinder_AIServiceAdapter.swift",  "FoodFinder_AIServiceAdapter.swift",  "Services/FoodFinder"),
    ("Services/FoodFinder/FoodFinder_AIServiceManager.swift",  "FoodFinder_AIServiceManager.swift",  "Services/FoodFinder"),
    ("Services/FoodFinder/FoodFinder_AnalysisHistoryStore.swift", "FoodFinder_AnalysisHistoryStore.swift", "Services/FoodFinder"),
    ("Services/FoodFinder/FoodFinder_EmojiProvider.swift",     "FoodFinder_EmojiProvider.swift",     "Services/FoodFinder"),
    ("Services/FoodFinder/FoodFinder_ImageDownloader.swift",   "FoodFinder_ImageDownloader.swift",   "Services/FoodFinder"),
    ("Services/FoodFinder/FoodFinder_ImageStore.swift",        "FoodFinder_ImageStore.swift",        "Services/FoodFinder"),
    ("Services/FoodFinder/FoodFinder_LocationService.swift",   "FoodFinder_LocationService.swift",   "Services/FoodFinder"),
    ("Services/FoodFinder/FoodFinder_OpenFoodFactsService.swift", "FoodFinder_OpenFoodFactsService.swift", "Services/FoodFinder"),
    ("Services/FoodFinder/FoodFinder_ScannerService.swift",    "FoodFinder_ScannerService.swift",    "Services/FoodFinder"),
    ("Services/FoodFinder/FoodFinder_SearchRouter.swift",      "FoodFinder_SearchRouter.swift",      "Services/FoodFinder"),
    ("Services/FoodFinder/FoodFinder_SecureStorage.swift",     "FoodFinder_SecureStorage.swift",     "Services/FoodFinder"),
    ("Services/FoodFinder/FoodFinder_VoiceService.swift",      "FoodFinder_VoiceService.swift",      "Services/FoodFinder"),

    # ── FoodFinder — View Models ──
    ("View Models/FoodFinder/FoodFinder_SearchViewModel.swift", "FoodFinder_SearchViewModel.swift",  "View Models/FoodFinder"),

    # ── FoodFinder — Views ──
    ("Views/FoodFinder/FoodFinder_CarbTrackingDashboard.swift", "FoodFinder_CarbTrackingDashboard.swift", "Views/FoodFinder"),
    ("Views/FoodFinder/FoodFinder_AICameraView.swift",      "FoodFinder_AICameraView.swift",      "Views/FoodFinder"),
    ("Views/FoodFinder/FoodFinder_ImageCropView.swift",    "FoodFinder_ImageCropView.swift",    "Views/FoodFinder"),
    ("Views/FoodFinder/FoodFinder_EntryPoint.swift",        "FoodFinder_EntryPoint.swift",        "Views/FoodFinder"),
    ("Views/FoodFinder/FoodFinder_FavoritesHelpers.swift",  "FoodFinder_FavoritesHelpers.swift",  "Views/FoodFinder"),
    ("Views/FoodFinder/FoodFinder_ScannerView.swift",       "FoodFinder_ScannerView.swift",       "Views/FoodFinder"),
    ("Views/FoodFinder/FoodFinder_SearchBar.swift",         "FoodFinder_SearchBar.swift",         "Views/FoodFinder"),
    ("Views/FoodFinder/FoodFinder_SearchResultsView.swift", "FoodFinder_SearchResultsView.swift", "Views/FoodFinder"),
    ("Views/FoodFinder/FoodFinder_SettingsView.swift",      "FoodFinder_SettingsView.swift",      "Views/FoodFinder"),
    ("Views/FoodFinder/FoodFinder_VoiceSearchView.swift",   "FoodFinder_VoiceSearchView.swift",   "Views/FoodFinder"),

    # ── LoopInsights — Managers ──
    ("Managers/LoopInsights/LoopInsights_BackgroundMonitor.swift", "LoopInsights_BackgroundMonitor.swift", "Managers/LoopInsights"),
    ("Managers/LoopInsights/LoopInsights_Coordinator.swift",      "LoopInsights_Coordinator.swift",      "Managers/LoopInsights"),

    # ── LoopInsights — Models ──
    ("Models/LoopInsights/LoopInsights_Models.swift",           "LoopInsights_Models.swift",           "Models/LoopInsights"),
    ("Models/LoopInsights/LoopInsights_MFPModels.swift",        "LoopInsights_MFPModels.swift",        "Models/LoopInsights"),
    ("Models/LoopInsights/LoopInsights_Phase5Models.swift",     "LoopInsights_Phase5Models.swift",     "Models/LoopInsights"),
    ("Models/LoopInsights/LoopInsights_SuggestionRecord.swift", "LoopInsights_SuggestionRecord.swift", "Models/LoopInsights"),

    # ── LoopInsights — Resources ──
    ("Resources/LoopInsights/LoopInsights_FeatureFlags.swift",  "LoopInsights_FeatureFlags.swift",     "Resources/LoopInsights"),

    # ── LoopInsights — Services ──
    ("Services/LoopInsights/LoopInsights_AdvancedAnalyzers.swift",  "LoopInsights_AdvancedAnalyzers.swift",  "Services/LoopInsights"),
    ("Services/LoopInsights/LoopInsights_AIAnalysis.swift",         "LoopInsights_AIAnalysis.swift",         "Services/LoopInsights"),
    ("Services/LoopInsights/LoopInsights_AIServiceAdapter.swift",   "LoopInsights_AIServiceAdapter.swift",   "Services/LoopInsights"),
    ("Services/LoopInsights/LoopInsights_AlcoholTracker.swift",     "LoopInsights_AlcoholTracker.swift",     "Services/LoopInsights"),
    ("Services/LoopInsights/LoopInsights_ChatHistoryStore.swift",  "LoopInsights_ChatHistoryStore.swift",  "Services/LoopInsights"),
    ("Services/LoopInsights/LoopInsights_CaffeineTracker.swift",    "LoopInsights_CaffeineTracker.swift",    "Services/LoopInsights"),
    ("Services/LoopInsights/LoopInsights_VoiceService.swift",       "LoopInsights_VoiceService.swift",       "Services/LoopInsights"),
    ("Services/LoopInsights/LoopInsights_BackfillDetector.swift",  "LoopInsights_BackfillDetector.swift",  "Services/LoopInsights"),
    ("Services/LoopInsights/LoopInsights_BehaviorInsightsAnalyzer.swift", "LoopInsights_BehaviorInsightsAnalyzer.swift", "Services/LoopInsights"),
    ("Services/LoopInsights/LoopInsights_CaregiverDigestService.swift", "LoopInsights_CaregiverDigestService.swift", "Services/LoopInsights"),
    ("Services/LoopInsights/LoopInsights_DataAggregator.swift",     "LoopInsights_DataAggregator.swift",     "Services/LoopInsights"),
    ("Services/LoopInsights/LoopInsights_FoodResponseAnalyzer.swift", "LoopInsights_FoodResponseAnalyzer.swift", "Services/LoopInsights"),
    ("Services/LoopInsights/LoopInsights_GlucoseUnitContext.swift", "LoopInsights_GlucoseUnitContext.swift", "Services/LoopInsights"),
    ("Services/LoopInsights/LoopInsights_GoalStore.swift",          "LoopInsights_GoalStore.swift",          "Services/LoopInsights"),
    ("Services/LoopInsights/LoopInsights_HealthKitManager.swift",   "LoopInsights_HealthKitManager.swift",   "Services/LoopInsights"),
    ("Services/LoopInsights/LoopInsights_NightscoutImporter.swift", "LoopInsights_NightscoutImporter.swift", "Services/LoopInsights"),
    ("Services/LoopInsights/LoopInsights_ReportGenerator.swift",    "LoopInsights_ReportGenerator.swift",    "Services/LoopInsights"),
    ("Services/LoopInsights/LoopInsights_SecureStorage.swift",      "LoopInsights_SecureStorage.swift",      "Services/LoopInsights"),
    ("Services/LoopInsights/LoopInsights_SuggestionStore.swift",    "LoopInsights_SuggestionStore.swift",    "Services/LoopInsights"),
    ("Services/LoopInsights/LoopInsights_TestDataProvider.swift",   "LoopInsights_TestDataProvider.swift",   "Services/LoopInsights"),
    ("Services/LoopInsights/LoopInsights_MealDebriefService.swift",  "LoopInsights_MealDebriefService.swift",  "Services/LoopInsights"),
    ("Services/LoopInsights/LoopInsights_MFPImporter.swift",         "LoopInsights_MFPImporter.swift",         "Services/LoopInsights"),
    ("Services/LoopInsights/LoopInsights_PreMealAdvisorService.swift", "LoopInsights_PreMealAdvisorService.swift", "Services/LoopInsights"),

    # ── LoopInsights — View Models ──
    ("View Models/LoopInsights/LoopInsights_ChatViewModel.swift",      "LoopInsights_ChatViewModel.swift",      "View Models/LoopInsights"),
    ("View Models/LoopInsights/LoopInsights_DashboardViewModel.swift", "LoopInsights_DashboardViewModel.swift", "View Models/LoopInsights"),
    ("View Models/LoopInsights/LoopInsights_MealInsightsViewModel.swift", "LoopInsights_MealInsightsViewModel.swift", "View Models/LoopInsights"),

    # ── LoopInsights — Views ──
    ("Views/LoopInsights/LoopInsights_AGPChartView.swift",         "LoopInsights_AGPChartView.swift",         "Views/LoopInsights"),
    ("Views/LoopInsights/LoopInsights_AlcoholLogView.swift",     "LoopInsights_AlcoholLogView.swift",     "Views/LoopInsights"),
    ("Views/LoopInsights/LoopInsights_BehaviorInsightsView.swift", "LoopInsights_BehaviorInsightsView.swift", "Views/LoopInsights"),
    ("Views/LoopInsights/LoopInsights_CaregiverDigestView.swift", "LoopInsights_CaregiverDigestView.swift", "Views/LoopInsights"),
    ("Views/LoopInsights/LoopInsights_EndoReportView.swift",     "LoopInsights_EndoReportView.swift",     "Views/LoopInsights"),
    ("Views/LoopInsights/LoopInsights_ChatHistoryView.swift",    "LoopInsights_ChatHistoryView.swift",    "Views/LoopInsights"),
    ("Views/LoopInsights/LoopInsights_CaffeineLogView.swift",     "LoopInsights_CaffeineLogView.swift",     "Views/LoopInsights"),
    ("Views/LoopInsights/LoopInsights_ChatView.swift",             "LoopInsights_ChatView.swift",             "Views/LoopInsights"),
    ("Views/LoopInsights/LoopInsights_DashboardView.swift",        "LoopInsights_DashboardView.swift",        "Views/LoopInsights"),
    ("Views/LoopInsights/LoopInsights_GoalsView.swift",            "LoopInsights_GoalsView.swift",            "Views/LoopInsights"),
    ("Views/LoopInsights/LoopInsights_MealInsightsView.swift",     "LoopInsights_MealInsightsView.swift",     "Views/LoopInsights"),
    ("Views/LoopInsights/LoopInsights_MonitorSettingsView.swift",  "LoopInsights_MonitorSettingsView.swift",  "Views/LoopInsights"),
    ("Views/LoopInsights/LoopInsights_SettingsView.swift",         "LoopInsights_SettingsView.swift",         "Views/LoopInsights"),
    ("Views/LoopInsights/LoopInsights_SuggestionDetailView.swift", "LoopInsights_SuggestionDetailView.swift", "Views/LoopInsights"),
    ("Views/LoopInsights/LoopInsights_SuggestionHistoryView.swift", "LoopInsights_SuggestionHistoryView.swift", "Views/LoopInsights"),
    ("Views/LoopInsights/LoopInsights_TrendsInsightsView.swift",   "LoopInsights_TrendsInsightsView.swift",   "Views/LoopInsights"),
    ("Views/LoopInsights/LoopInsights_MealDebriefCard.swift",     "LoopInsights_MealDebriefCard.swift",     "Views/LoopInsights"),
    ("Views/LoopInsights/LoopInsights_PreMealAdvisorCard.swift",  "LoopInsights_PreMealAdvisorCard.swift",  "Views/LoopInsights"),

    # ── LoopInsights — Models ──
    ("Models/LoopInsights/LoopInsights_MealDebriefModels.swift",  "LoopInsights_MealDebriefModels.swift",  "Models/LoopInsights"),

    # ── DataLayer — Managers ──
    ("Managers/DataLayer/DataLayer_Coordinator.swift",             "DataLayer_Coordinator.swift",             "Managers/DataLayer"),

    # ── DataLayer — Models ──
    ("Models/DataLayer/DataLayer_EventModels.swift",               "DataLayer_EventModels.swift",             "Models/DataLayer"),
    ("Models/DataLayer/DataLayer_ConsentModels.swift",             "DataLayer_ConsentModels.swift",           "Models/DataLayer"),

    # ── DataLayer — Resources ──
    ("Resources/DataLayer/DataLayer_FeatureFlags.swift",           "DataLayer_FeatureFlags.swift",            "Resources/DataLayer"),

    # ── DataLayer — Services ──
    ("Services/DataLayer/DataLayer_SecureStorage.swift",           "DataLayer_SecureStorage.swift",           "Services/DataLayer"),
    ("Services/DataLayer/DataLayer_ConsentManager.swift",          "DataLayer_ConsentManager.swift",          "Services/DataLayer"),
    ("Services/DataLayer/DataLayer_EventStore.swift",              "DataLayer_EventStore.swift",              "Services/DataLayer"),
    ("Services/DataLayer/DataLayer_EventCollector.swift",          "DataLayer_EventCollector.swift",          "Services/DataLayer"),
    ("Services/DataLayer/DataLayer_SyncService.swift",             "DataLayer_SyncService.swift",             "Services/DataLayer"),
    ("Services/DataLayer/DataLayer_ReportGenerator.swift",        "DataLayer_ReportGenerator.swift",         "Services/DataLayer"),
    ("Services/DataLayer/DataLayer_ProviderProtocol.swift",       "DataLayer_ProviderProtocol.swift",        "Services/DataLayer"),

    # ── DataLayer — Views ──
    ("Views/DataLayer/DataLayer_ConsentView.swift",                "DataLayer_ConsentView.swift",             "Views/DataLayer"),
    ("Views/DataLayer/DataLayer_DashboardView.swift",              "DataLayer_DashboardView.swift",           "Views/DataLayer"),

    # ── SiteAtlas — Models ──
    ("Models/SiteAtlas/SiteAtlas_Models.swift",                    "SiteAtlas_Models.swift",                  "Models/SiteAtlas"),

    # ── SiteAtlas — Services ──
    ("Services/SiteAtlas/SiteAtlas_Coordinator.swift",             "SiteAtlas_Coordinator.swift",             "Services/SiteAtlas"),
    ("Services/SiteAtlas/SiteAtlas_FeatureFlags.swift",            "SiteAtlas_FeatureFlags.swift",            "Services/SiteAtlas"),
    ("Services/SiteAtlas/SiteAtlas_Storage.swift",                 "SiteAtlas_Storage.swift",                 "Services/SiteAtlas"),

    # ── SiteAtlas — Views ──
    ("Views/SiteAtlas/SiteAtlas_BodyMapView.swift",                "SiteAtlas_BodyMapView.swift",             "Views/SiteAtlas"),
    ("Views/SiteAtlas/SiteAtlas_SettingsView.swift",               "SiteAtlas_SettingsView.swift",            "Views/SiteAtlas"),
    ("Views/SiteAtlas/SiteAtlas_SiteSelectionSheet.swift",         "SiteAtlas_SiteSelectionSheet.swift",      "Views/SiteAtlas"),
]

TEST_FILES = [
    ("FoodFinder/FoodFinder_BarcodeScannerTests.swift",      "FoodFinder_BarcodeScannerTests.swift",      "LoopTests/FoodFinder"),
    ("FoodFinder/FoodFinder_OpenFoodFactsTests.swift",       "FoodFinder_OpenFoodFactsTests.swift",       "LoopTests/FoodFinder"),
    ("FoodFinder/FoodFinder_VoiceSearchTests.swift",         "FoodFinder_VoiceSearchTests.swift",         "LoopTests/FoodFinder"),
    ("LoopInsights/LoopInsights_DataAggregatorTests.swift",  "LoopInsights_DataAggregatorTests.swift",  "LoopTests/LoopInsights"),
    ("LoopInsights/LoopInsights_ModelsTests.swift",          "LoopInsights_ModelsTests.swift",          "LoopTests/LoopInsights"),
    ("LoopInsights/LoopInsights_SuggestionStoreTests.swift", "LoopInsights_SuggestionStoreTests.swift", "LoopTests/LoopInsights"),
]

# ─── Subgroup definitions ────────────────────────────────────────────────────
# (group_key, display_name, path, parent_group_key)
# parent_group_key is the existing group this should be added as a child of.

SUBGROUPS = [
    # Feature subgroups under existing top-level groups
    ("Managers/AutoPresets",    "AutoPresets",   "AutoPresets",   "Managers"),
    ("Models/AutoPresets",      "AutoPresets",   "AutoPresets",   "Models"),
    ("Models/FoodFinder",       "FoodFinder",    "FoodFinder",    "Models"),
    ("Models/LoopInsights",     "LoopInsights",  "LoopInsights",  "Models"),
    ("Views/AutoPresets",       "AutoPresets",   "AutoPresets",   "Views"),
    ("Views/FoodFinder",        "FoodFinder",    "FoodFinder",    "Views"),
    ("Views/LoopInsights",      "LoopInsights",  "LoopInsights",  "Views"),
    ("View Models/FoodFinder",  "FoodFinder",    "FoodFinder",    "View Models"),
    ("View Models/LoopInsights","LoopInsights",  "LoopInsights",  "View Models"),
    ("Managers/LoopInsights",   "LoopInsights",  "LoopInsights",  "Managers"),

    # Services and Resources are new top-level groups under Loop root
    ("Services",                "Services",      "Services",      "Loop"),
    ("Services/AutoPresets",    "AutoPresets",   "AutoPresets",   "Services"),
    ("Services/FoodFinder",     "FoodFinder",    "FoodFinder",    "Services"),
    ("Services/LoopInsights",   "LoopInsights",  "LoopInsights",  "Services"),
    ("Resources",               "Resources",     "Resources",     "Loop"),
    ("Resources/AutoPresets",   "AutoPresets",   "AutoPresets",   "Resources"),
    ("Resources/FoodFinder",    "FoodFinder",    "FoodFinder",    "Resources"),
    ("Resources/LoopInsights",  "LoopInsights",  "LoopInsights",  "Resources"),

    # DataLayer subgroups
    ("Managers/DataLayer",      "DataLayer",     "DataLayer",     "Managers"),
    ("Models/DataLayer",        "DataLayer",     "DataLayer",     "Models"),
    ("Resources/DataLayer",     "DataLayer",     "DataLayer",     "Resources"),
    ("Services/DataLayer",      "DataLayer",     "DataLayer",     "Services"),
    ("Views/DataLayer",         "DataLayer",     "DataLayer",     "Views"),

    # SiteAtlas subgroups
    ("Models/SiteAtlas",        "SiteAtlas",     "SiteAtlas",     "Models"),
    ("Resources/SiteAtlas",     "SiteAtlas",     "SiteAtlas",     "Resources"),
    ("Services/SiteAtlas",      "SiteAtlas",     "SiteAtlas",     "Services"),
    ("Views/SiteAtlas",         "SiteAtlas",     "SiteAtlas",     "Views"),

    # Test subgroups
    ("LoopTests/FoodFinder",    "FoodFinder",    "FoodFinder",    "LoopTests"),
    ("LoopTests/LoopInsights",  "LoopInsights",  "LoopInsights",  "LoopTests"),
]


def fileref_uuid(filename: str) -> str:
    return make_uuid(f"fileref_{filename}")


def buildfile_uuid(filename: str) -> str:
    return make_uuid(f"buildfile_{filename}")


def group_uuid(group_key: str) -> str:
    return make_uuid(f"group_{group_key}")


# ─── pbxproj Parsing Helpers ─────────────────────────────────────────────────

def parse_all_groups(content: str) -> dict[str, dict]:
    """Parse all PBXGroup definitions into a dict of uuid -> {name, path, children_uuids}."""
    group_section_match = re.search(
        r'/\* Begin PBXGroup section \*/\n(.*?)\n/\* End PBXGroup section \*/',
        content, re.DOTALL
    )
    if not group_section_match:
        return {}

    section = group_section_match.group(1)
    groups = {}

    # Match each group definition block individually
    # Some groups (like the root mainGroup) have no /* comment */, so make it optional
    for m in re.finditer(
        r'^\t\t([A-F0-9]{24})\s*(?:/\*[^\n]*?\*/)?\s*= \{\n(.*?)\n\t\t\};',
        section, re.MULTILINE | re.DOTALL
    ):
        uuid = m.group(1)
        body = m.group(2)

        if "isa = PBXGroup" not in body:
            continue

        path_m = re.search(r'path = "(.*?)";|path = ([^;"\s]+);', body)
        name_m = re.search(r'name = "(.*?)";|name = ([^;"\s]+);', body)

        path_val = (path_m.group(1) or path_m.group(2)) if path_m else None
        name_val = (name_m.group(1) or name_m.group(2)) if name_m else None
        display = name_val or path_val or "unknown"

        # Parse children
        children = []
        children_m = re.search(r'children = \(\n(.*?)\n\t\t\t\);', body, re.DOTALL)
        if children_m:
            for c in re.finditer(r'([A-F0-9]{24})', children_m.group(1)):
                children.append(c.group(1))

        groups[uuid] = {
            "name": display,
            "path": path_val,
            "children": children,
        }

    return groups


def find_groups_by_hierarchy(content: str) -> dict[str, str]:
    """Find the correct group UUIDs by walking the PBXProject → mainGroup → Loop hierarchy.

    Returns a dict of logical_name -> UUID for: Loop, Views, Models, View Models, Managers, LoopTests.
    This avoids ambiguity from duplicate group names (e.g. Watch, Widget targets also have Models/Views).
    """
    all_groups = parse_all_groups(content)

    # Step 1: Find the project's mainGroup from PBXProject section
    main_group_match = re.search(r'mainGroup = ([A-F0-9]{24})', content)
    if not main_group_match:
        return {}
    main_group_uuid = main_group_match.group(1)

    # Step 2: The mainGroup's children include "Loop" and "LoopTests" (among others)
    main_group = all_groups.get(main_group_uuid, {})
    result = {}

    for child_uuid in main_group.get("children", []):
        child = all_groups.get(child_uuid, {})
        child_path = child.get("path")
        child_name = child.get("name")

        if child_path == "Loop" or child_name == "Loop":
            result["Loop"] = child_uuid
        elif child_path == "LoopTests" or child_name == "LoopTests":
            result["LoopTests"] = child_uuid

    # Step 3: Walk Loop group's children to find Views, Models, View Models, Managers
    loop_uuid = result.get("Loop")
    if loop_uuid and loop_uuid in all_groups:
        for child_uuid in all_groups[loop_uuid]["children"]:
            child = all_groups.get(child_uuid, {})
            child_path = child.get("path")
            child_name = child.get("name")
            display = child_name or child_path

            if display in ("Views", "Models", "View Models", "Managers", "Services", "Resources"):
                result[display] = child_uuid

    return result


def find_main_sources_phase(content: str) -> Optional[str]:
    """Find the PBXSourcesBuildPhase UUID for the main app target (Loop)."""
    target_section = re.search(
        r'/\* Begin PBXNativeTarget section \*/\n(.*?)\n/\* End PBXNativeTarget section \*/',
        content, re.DOTALL
    )
    if not target_section:
        return None

    # Match the Loop target specifically (not LoopTests, not LoopWidgetExtension, etc.)
    # Use word boundary: "Loop" followed by space and asterisk, not "LoopTests" etc.
    for m in re.finditer(
        r'([A-F0-9]{24}) /\* (Loop[^*]*?)\*/ = \{(.*?)\n\t\t\};',
        target_section.group(1), re.DOTALL
    ):
        target_name = m.group(2).strip()
        if target_name == "Loop":
            phases_match = re.search(r'buildPhases = \(\n(.*?)\n\t\t\t\);', m.group(3), re.DOTALL)
            if phases_match:
                sources_match = re.search(r'([A-F0-9]{24}) /\*[^\n]*?Sources[^\n]*?\*/', phases_match.group(1))
                if sources_match:
                    return sources_match.group(1)
    return None


def find_test_sources_phase(content: str) -> Optional[str]:
    """Find the PBXSourcesBuildPhase UUID for the LoopTests target."""
    target_section = re.search(
        r'/\* Begin PBXNativeTarget section \*/\n(.*?)\n/\* End PBXNativeTarget section \*/',
        content, re.DOTALL
    )
    if not target_section:
        return None

    for m in re.finditer(
        r'([A-F0-9]{24}) /\* (LoopTests[^*]*?)\*/ = \{(.*?)\n\t\t\};',
        target_section.group(1), re.DOTALL
    ):
        target_name = m.group(2).strip()
        if target_name == "LoopTests":
            phases_match = re.search(r'buildPhases = \(\n(.*?)\n\t\t\t\);', m.group(3), re.DOTALL)
            if phases_match:
                sources_match = re.search(r'([A-F0-9]{24}) /\*[^\n]*?Sources[^\n]*?\*/', phases_match.group(1))
                if sources_match:
                    return sources_match.group(1)
    return None


def add_child_to_group(content: str, parent_uuid: str, child_uuid: str, child_name: str) -> str:
    """Add a child reference to an existing PBXGroup's children list."""
    new_child = f"\t\t\t\t{child_uuid} /* {child_name} */,"

    # Use [^\n]*? to prevent cross-line matching (critical lesson from prior work)
    pattern = (
        f"({parent_uuid} /\\*[^\\n]*?\\*/ = \\{{\n"
        f"\\t\\t\\tisa = PBXGroup;\n"
        f"\\t\\t\\tchildren = \\(\n)"
        f"(.*?)"
        f"(\\n\\t\\t\\t\\);)"
    )
    match = re.search(pattern, content, re.DOTALL)
    if match:
        before = match.group(1)
        existing = match.group(2)
        after = match.group(3)
        content = content[:match.start()] + f"{before}{existing}\n{new_child}{after}" + content[match.end():]
    else:
        print(f"  WARNING: Could not find group {parent_uuid} to add child {child_name}")

    return content


def add_to_build_phase(content: str, phase_uuid: str, entries_block: str) -> str:
    """Add entries to a PBXSourcesBuildPhase's files list."""
    pattern = (
        f"({phase_uuid} /\\*[^\\n]*?\\*/ = \\{{\n"
        f"\\t\\t\\tisa = PBXSourcesBuildPhase;\n"
        f"\\t\\t\\tbuildActionMask = \\d+;\n"
        f"\\t\\t\\tfiles = \\(\n)"
        f"(.*?)"
        f"(\\n\\t\\t\\t\\);\\n\\t\\t\\trunOnlyForDeploymentPostprocessing)"
    )
    match = re.search(pattern, content, re.DOTALL)
    if match:
        before = match.group(1)
        existing = match.group(2)
        after = match.group(3)
        content = content[:match.start()] + f"{before}{existing}\n{entries_block}{after}" + content[match.end():]
    else:
        print(f"  WARNING: Could not find build phase {phase_uuid}")

    return content


def build_group_def(uuid: str, name: str, path: str, child_entries: list[tuple[str, str]]) -> str:
    """Build a PBXGroup definition string."""
    children_lines = []
    for child_uuid, child_name in child_entries:
        children_lines.append(f"\t\t\t\t{child_uuid} /* {child_name} */,")
    children_str = "\n".join(children_lines)

    return (
        f"\t\t{uuid} /* {name} */ = {{\n"
        f"\t\t\tisa = PBXGroup;\n"
        f"\t\t\tchildren = (\n"
        f"{children_str}\n"
        f"\t\t\t);\n"
        f"\t\t\tpath = {path};\n"
        f"\t\t\tsourceTree = \"<group>\";\n"
        f"\t\t}};"
    )


# ─── Main ────────────────────────────────────────────────────────────────────

def main():
    if len(sys.argv) < 2:
        print("Usage: update_pbxproj.py <path_to_project.pbxproj>")
        sys.exit(1)

    pbxproj_path = sys.argv[1]

    with open(pbxproj_path, "r") as f:
        content = f.read()

    # ── Discover existing group UUIDs by walking the project hierarchy ──
    print("  Discovering existing group UUIDs...")

    known_groups = find_groups_by_hierarchy(content)
    for name, uuid in sorted(known_groups.items()):
        print(f"    {name}: {uuid}")

    required = ["Loop", "Views", "Models", "View Models", "Managers", "LoopTests"]
    for name in required:
        if name not in known_groups:
            print(f"    WARNING: Could not find group '{name}'")

    main_sources_uuid = find_main_sources_phase(content)
    test_sources_uuid = find_test_sources_phase(content)

    if main_sources_uuid:
        print(f"    Main Sources phase: {main_sources_uuid}")
    else:
        print("    WARNING: Could not find main Sources build phase")

    if test_sources_uuid:
        print(f"    Test Sources phase: {test_sources_uuid}")
    else:
        print("    WARNING: Could not find test Sources build phase")

    # ── Map group_key → UUID (generated or discovered) ──
    group_uuids = {}
    for gkey, gname, gpath, gparent in SUBGROUPS:
        # If this group already exists in the project, use its UUID
        if gkey in known_groups:
            group_uuids[gkey] = known_groups[gkey]
        else:
            group_uuids[gkey] = group_uuid(gkey)

    # Also map parent groups from known_groups
    for name, uuid in known_groups.items():
        if name not in group_uuids:
            group_uuids[name] = uuid

    # =========================================================================
    # 1. Add PBXBuildFile entries
    # =========================================================================
    print("  Adding PBXBuildFile entries...")

    build_entries = []
    for path, name, gkey in SOURCE_FILES:
        bf = buildfile_uuid(name)
        fr = fileref_uuid(name)
        build_entries.append(
            f"\t\t{bf} /* {name} in Sources */ = "
            f"{{isa = PBXBuildFile; fileRef = {fr} /* {name} */; }};"
        )
    for path, name, gkey in TEST_FILES:
        bf = buildfile_uuid(name)
        fr = fileref_uuid(name)
        build_entries.append(
            f"\t\t{bf} /* {name} in Sources */ = "
            f"{{isa = PBXBuildFile; fileRef = {fr} /* {name} */; }};"
        )

    content = content.replace(
        "/* End PBXBuildFile section */",
        "\n".join(build_entries) + "\n/* End PBXBuildFile section */",
    )

    # =========================================================================
    # 2. Add PBXFileReference entries
    # =========================================================================
    print("  Adding PBXFileReference entries...")

    ref_entries = []
    for path, name, gkey in SOURCE_FILES:
        fr = fileref_uuid(name)
        ref_entries.append(
            f"\t\t{fr} /* {name} */ = "
            f"{{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; "
            f"path = {name}; sourceTree = \"<group>\"; }};"
        )
    for path, name, gkey in TEST_FILES:
        fr = fileref_uuid(name)
        ref_entries.append(
            f"\t\t{fr} /* {name} */ = "
            f"{{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; "
            f"path = {name}; sourceTree = \"<group>\"; }};"
        )

    content = content.replace(
        "/* End PBXFileReference section */",
        "\n".join(ref_entries) + "\n/* End PBXFileReference section */",
    )

    # =========================================================================
    # 3. Create PBXGroup entries for new subgroups
    # =========================================================================
    print("  Creating PBXGroup entries...")

    # Build child lists for each group
    group_children: dict[str, list[tuple[str, str]]] = {gkey: [] for gkey, _, _, _ in SUBGROUPS}

    # Add source files to their groups
    for path, name, gkey in SOURCE_FILES:
        fr = fileref_uuid(name)
        group_children.setdefault(gkey, []).append((fr, name))

    for path, name, gkey in TEST_FILES:
        fr = fileref_uuid(name)
        group_children.setdefault(gkey, []).append((fr, name))

    # Add subgroups as children of their parents
    # Also add subgroups as children of parent subgroups
    for gkey, gname, gpath, gparent in SUBGROUPS:
        gu = group_uuids[gkey]
        group_children.setdefault(gparent, []).append((gu, gname))

    # Only create group defs for groups that don't already exist in the project
    new_group_defs = []
    for gkey, gname, gpath, gparent in SUBGROUPS:
        if gkey in known_groups:
            continue  # Already exists, don't re-create
        gu = group_uuids[gkey]
        children = group_children.get(gkey, [])
        new_group_defs.append(build_group_def(gu, gname, gpath, children))

    if new_group_defs:
        groups_block = "\n".join(new_group_defs)
        content = content.replace(
            "/* End PBXGroup section */",
            f"{groups_block}\n/* End PBXGroup section */",
        )

    # =========================================================================
    # 4. Add new subgroups as children of existing parent groups
    # =========================================================================
    print("  Linking subgroups to parent groups...")

    for gkey, gname, gpath, gparent in SUBGROUPS:
        parent_uuid = group_uuids.get(gparent)
        child_uuid = group_uuids[gkey]

        if parent_uuid is None:
            print(f"    WARNING: Parent group '{gparent}' UUID unknown, skipping {gkey}")
            continue

        # Only add if the parent is an existing group (not one we just created)
        # For newly created parent groups, children were already added in step 3
        if gparent in known_groups:
            content = add_child_to_group(content, parent_uuid, child_uuid, gname)

    # =========================================================================
    # 4b. Add files directly to existing parent groups
    # =========================================================================
    # Files whose gkey matches an existing top-level group (e.g. "Managers", "Views")
    # need to be added as children of that group directly — they aren't in a subgroup.
    subgroup_keys = {gkey for gkey, _, _, _ in SUBGROUPS}
    for path, name, gkey in SOURCE_FILES:
        if gkey not in subgroup_keys and gkey in known_groups:
            fr = fileref_uuid(name)
            parent_uuid = known_groups[gkey]
            content = add_child_to_group(content, parent_uuid, fr, name)
            print(f"    Added {name} to existing group '{gkey}'")

    # =========================================================================
    # 5. Add files to PBXSourcesBuildPhase
    # =========================================================================
    print("  Adding files to build phases...")

    if main_sources_uuid:
        main_entries = []
        for path, name, gkey in SOURCE_FILES:
            bf = buildfile_uuid(name)
            main_entries.append(f"\t\t\t\t{bf} /* {name} in Sources */,")
        content = add_to_build_phase(content, main_sources_uuid, "\n".join(main_entries))

    if test_sources_uuid:
        test_entries = []
        for path, name, gkey in TEST_FILES:
            bf = buildfile_uuid(name)
            test_entries.append(f"\t\t\t\t{bf} /* {name} in Sources */,")
        content = add_to_build_phase(content, test_sources_uuid, "\n".join(test_entries))

    # =========================================================================
    # 6. Write output
    # =========================================================================
    with open(pbxproj_path, "w") as f:
        f.write(content)

    print(f"\n  Updated {pbxproj_path}")
    print(f"  Added {len(SOURCE_FILES)} source files")
    print(f"  Added {len(TEST_FILES)} test files")
    print(f"  Created {len(new_group_defs)} new groups")


if __name__ == "__main__":
    main()
