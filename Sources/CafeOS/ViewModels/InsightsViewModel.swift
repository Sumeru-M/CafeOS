// MARK: - InsightsViewModel.swift
// Drives the AI insights dashboard.
// Fetches usage history for all items, runs AIInsightService, publishes results.

import Foundation
import Combine

@MainActor
final class InsightsViewModel: ObservableObject {

    @Published var insights: [StockInsight] = []
    @Published var isLoading = false
    @Published var error: AppError?
    @Published var lastRefreshed: Date?

    private let firestoreService = FirestoreService.shared
    private let aiService        = AIInsightService.shared

    // MARK: - Refresh

    func refresh(items: [InventoryItem]) async {
        guard !items.isEmpty else { insights = []; return }
        isLoading = true
        defer { isLoading = false }

        do {
            let histories = await firestoreService.fetchAllHistory(for: items)
            insights      = aiService.generateInsights(for: items, histories: histories)
            lastRefreshed = Date()
        }
    }

    // MARK: - Computed

    var criticalInsights: [StockInsight] { insights.filter { $0.severity == .critical } }
    var warningInsights:  [StockInsight] { insights.filter { $0.severity == .warning  } }
    var okInsights:       [StockInsight] { insights.filter { $0.severity == .ok       } }

    var hasCritical: Bool { !criticalInsights.isEmpty }

    func clearError() { error = nil }
}
