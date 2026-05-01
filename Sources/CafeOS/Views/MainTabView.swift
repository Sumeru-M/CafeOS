// MARK: - MainTabView.swift
// Root navigation after authentication.

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var inventoryVM: InventoryViewModel
    @EnvironmentObject var insightsVM: InsightsViewModel

    var body: some View {
        TabView {
            // Tab 1: Inventory
            NavigationStack {
                InventoryListView()
            }
            .tabItem {
                Label("Inventory", systemImage: "list.bullet.clipboard")
            }
            .badge(inventoryVM.lowStockCount > 0 ? inventoryVM.lowStockCount : 0)

            // Tab 2: Insights
            NavigationStack {
                InsightsDashboardView()
            }
            .tabItem {
                Label("Insights", systemImage: "chart.line.uptrend.xyaxis")
            }
            .badge(insightsVM.hasCritical ? "!" : nil)

            // Tab 3: Job Scraper
            NavigationStack {
                JobScraperView()
            }
            .tabItem {
                Label("Job Lookup", systemImage: "magnifyingglass.circle")
            }

            // Tab 4: Settings
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
        }
        .tint(.cafeCaramel)
    }
}
