// MARK: - StockInsight.swift
// AI-generated prediction for an inventory item's depletion timeline.

import Foundation

/// Severity level for a stock insight.
enum InsightSeverity: Int, Comparable {
    case ok       = 0
    case warning  = 1
    case critical = 2

    static func < (lhs: InsightSeverity, rhs: InsightSeverity) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var label: String {
        switch self {
        case .ok:       return "OK"
        case .warning:  return "Low Stock"
        case .critical: return "Critical"
        }
    }

    var emoji: String {
        switch self {
        case .ok:       return "✅"
        case .warning:  return "🟡"
        case .critical: return "🔴"
        }
    }

    var colorName: String {
        switch self {
        case .ok:       return "InsightGreen"
        case .warning:  return "InsightAmber"
        case .critical: return "InsightRed"
        }
    }
}

/// The AI-generated prediction for a single inventory item.
struct StockInsight: Identifiable {
    var id: String                          // Same as inventoryItem.id
    var itemName: String
    var category: String
    var currentQuantity: Double
    var unit: String
    var threshold: Double
    var averageDailyUsage: Double           // Units consumed per day (computed)
    var predictedDaysUntilEmpty: Int?       // nil if no trend data or usage == 0
    var severity: InsightSeverity
    var message: String                     // Human-readable insight string
    var confidence: Double                  // 0–1, based on number of snapshots
    var snapshotCount: Int                  // How many data points were used

    /// Formatted string for `averageDailyUsage`.
    var dailyUsageFormatted: String {
        String(format: "%.2f %@/day", averageDailyUsage, unit)
    }
}
