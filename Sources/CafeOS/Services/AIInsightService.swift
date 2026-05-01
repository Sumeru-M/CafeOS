// MARK: - AIInsightService.swift
// On-device low-stock prediction engine using linear regression.
// Algorithm: load usage history → compute avg daily consumption → predict depletion → classify severity.

import Foundation

final class AIInsightService {

    static let shared = AIInsightService()
    private init() {}

    // MARK: - Public API

    func generateInsights(
        for items: [InventoryItem],
        histories: [String: [UsageSnapshot]]
    ) -> [StockInsight] {
        items
            .compactMap { item in
                let snapshots = histories[item.id] ?? []
                return insight(for: item, snapshots: snapshots)
            }
            .sorted { $0.severity > $1.severity }
    }

    // MARK: - Core Computation

    private func insight(for item: InventoryItem, snapshots: [UsageSnapshot]) -> StockInsight? {
        let (dailyUsage, confidence) = averageDailyUsage(from: snapshots)

        let daysUntilEmpty: Int?
        if dailyUsage > 0 {
            daysUntilEmpty = max(0, Int((item.quantity / dailyUsage).rounded()))
        } else {
            daysUntilEmpty = nil
        }

        let severity = computeSeverity(for: item, daysUntilEmpty: daysUntilEmpty)
        let message  = buildMessage(item: item, daysUntilEmpty: daysUntilEmpty, severity: severity)

        return StockInsight(
            id: item.id,
            itemName: item.name,
            category: item.category.rawValue,
            currentQuantity: item.quantity,
            unit: item.unit.rawValue,
            threshold: item.threshold,
            averageDailyUsage: dailyUsage,
            predictedDaysUntilEmpty: daysUntilEmpty,
            severity: severity,
            message: message,
            confidence: confidence,
            snapshotCount: snapshots.count
        )
    }

    // MARK: - Linear Regression → Daily Consumption Rate

    private func averageDailyUsage(from snapshots: [UsageSnapshot]) -> (rate: Double, confidence: Double) {
        guard snapshots.count >= 2 else { return (0, 0) }

        let ref = snapshots.first!.timestamp
        let pts: [(x: Double, y: Double)] = snapshots.map { s in
            (x: s.timestamp.timeIntervalSince(ref) / 86_400.0, y: s.quantity)
        }

        let n    = Double(pts.count)
        let sumX  = pts.reduce(0) { $0 + $1.x }
        let sumY  = pts.reduce(0) { $0 + $1.y }
        let sumXY = pts.reduce(0) { $0 + $1.x * $1.y }
        let sumXX = pts.reduce(0) { $0 + $1.x * $1.x }

        let denom = n * sumXX - sumX * sumX
        guard abs(denom) > 1e-9 else { return (0, 0) }

        let slope = (n * sumXY - sumX * sumY) / denom
        let consumption = max(0, -slope)
        let confidence  = min(n / 14.0, 1.0)
        return (consumption, confidence)
    }

    // MARK: - Severity Classification

    private func computeSeverity(for item: InventoryItem, daysUntilEmpty: Int?) -> InsightSeverity {
        if item.isLowStock                              { return .critical }
        if let d = daysUntilEmpty, d <= 2              { return .critical }
        if let d = daysUntilEmpty, d <= 5              { return .warning  }
        if item.quantity < item.threshold * 2           { return .warning  }
        return .ok
    }

    // MARK: - Message Builder

    private func buildMessage(
        item: InventoryItem,
        daysUntilEmpty: Int?,
        severity: InsightSeverity
    ) -> String {
        let n = item.name
        if item.isLowStock {
            if let d = daysUntilEmpty, d <= 1 { return "⚠️ \(n) is critically low — restock immediately." }
            return "⚠️ \(n) is below the reorder level. Restock soon."
        }
        if let d = daysUntilEmpty {
            switch d {
            case 0:      return "🔴 \(n) will run out today."
            case 1:      return "🔴 \(n) will run out tomorrow."
            case 2...5:  return "🟡 \(n) will run out in ~\(d) days."
            default:     return "✅ \(n) has ~\(d) days of stock remaining."
            }
        }
        switch severity {
        case .critical: return "⚠️ \(n) is critically low."
        case .warning:  return "🟡 \(n) stock is running low."
        case .ok:       return "✅ \(n) stock levels look good."
        }
    }
}
