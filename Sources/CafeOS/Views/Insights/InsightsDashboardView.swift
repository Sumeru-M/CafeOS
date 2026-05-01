// MARK: - InsightsDashboardView.swift
// AI-powered stock insights dashboard.

import SwiftUI

struct InsightsDashboardView: View {
    @EnvironmentObject var inventoryVM: InventoryViewModel
    @EnvironmentObject var insightsVM:  InsightsViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Refresh info
                if let date = insightsVM.lastRefreshed {
                    Text("Updated \(date.relativeDescription)")
                        .font(AppFonts.body_(13))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.horizontal)
                }

                if insightsVM.isLoading {
                    LoadingView(message: "Analysing stock trends…")
                        .frame(height: 200)
                } else if insightsVM.insights.isEmpty {
                    EmptyStateView(
                        icon: "📊",
                        title: "No Insights Yet",
                        subtitle: "Insights appear once you have inventory items with usage history.",
                        actionTitle: "Refresh",
                        action: { Task { await insightsVM.refresh(items: inventoryVM.items) } }
                    )
                } else {
                    insightSections
                }
            }
            .padding(.vertical, AppLayout.padding)
        }
        .navigationTitle("Stock Insights")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { Task { await insightsVM.refresh(items: inventoryVM.items) } }) {
                    Image(systemName: "arrow.clockwise.circle")
                        .foregroundColor(.cafeCaramel)
                }
            }
        }
        .task {
            // Auto-refresh when view appears
            await insightsVM.refresh(items: inventoryVM.items)
        }
        .onChange(of: inventoryVM.items) { items in
            Task { await insightsVM.refresh(items: items) }
        }
    }

    // MARK: - Insight Sections

    private var insightSections: some View {
        VStack(spacing: 24) {
            if !insightsVM.criticalInsights.isEmpty {
                InsightSection(
                    title: "🔴 Critical",
                    insights: insightsVM.criticalInsights
                )
            }
            if !insightsVM.warningInsights.isEmpty {
                InsightSection(
                    title: "🟡 Low Stock",
                    insights: insightsVM.warningInsights
                )
            }
            if !insightsVM.okInsights.isEmpty {
                InsightSection(
                    title: "✅ Looking Good",
                    insights: insightsVM.okInsights
                )
            }
        }
    }
}

// MARK: - InsightSection

struct InsightSection: View {
    let title: String
    let insights: [StockInsight]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(AppFonts.heading(18))
                .padding(.horizontal, AppLayout.padding)

            ForEach(insights) { insight in
                InsightCardView(insight: insight)
                    .padding(.horizontal, AppLayout.padding)
            }
        }
    }
}

// MARK: - InsightCardView

struct InsightCardView: View {
    let insight: StockInsight

    private var borderColor: Color {
        switch insight.severity {
        case .critical: return .red
        case .warning:  return .orange
        case .ok:       return .cafeSage
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(insight.itemName)
                    .font(AppFonts.heading(17))
                Spacer()
                SeverityBadge(severity: insight.severity)
            }

            // AI message
            Text(insight.message)
                .font(AppFonts.body_(14))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Divider()

            // Stats row
            HStack(spacing: 0) {
                InsightStat(label: "Current", value: "\(insight.currentQuantity.rounded(to: 2)) \(insight.unit)")
                Spacer()
                InsightStat(label: "Daily Use", value: insight.averageDailyUsage > 0 ? insight.dailyUsageFormatted : "No data")
                Spacer()
                if let days = insight.predictedDaysUntilEmpty {
                    InsightStat(label: "Days Left", value: "\(days)")
                } else {
                    InsightStat(label: "Days Left", value: "—")
                }
            }

            // Confidence bar
            if insight.snapshotCount > 0 {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Prediction confidence: \(Int(insight.confidence * 100))% (\(insight.snapshotCount) data points)")
                        .font(AppFonts.body_(11))
                        .foregroundColor(.secondary)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3).fill(Color(.systemGray5)).frame(height: 4)
                            RoundedRectangle(cornerRadius: 3).fill(borderColor.opacity(0.7))
                                .frame(width: geo.size.width * insight.confidence, height: 4)
                        }
                    }.frame(height: 4)
                }
            }
        }
        .padding(AppLayout.padding)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(AppLayout.cardRadius)
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cardRadius)
                .stroke(borderColor.opacity(0.3), lineWidth: 1.5)
        )
        .shadow(color: borderColor.opacity(0.08), radius: 6, y: 3)
    }
}

// MARK: - Supporting Views

struct SeverityBadge: View {
    let severity: InsightSeverity
    var body: some View {
        Text(severity.label)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(badgeColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(badgeColor.opacity(0.12))
            .cornerRadius(8)
    }
    private var badgeColor: Color {
        switch severity {
        case .critical: return .red
        case .warning:  return .orange
        case .ok:       return .cafeSage
        }
    }
}

struct InsightStat: View {
    let label: String
    let value: String
    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(AppFonts.heading(14)).foregroundColor(.primary)
            Text(label).font(AppFonts.body_(11)).foregroundColor(.secondary)
        }
    }
}
