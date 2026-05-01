// MARK: - ItemRowView.swift
// A single row in the inventory list.

import SwiftUI

struct ItemRowView: View {
    let item: InventoryItem

    var body: some View {
        HStack(spacing: 14) {
            // Category icon
            ZStack {
                Circle()
                    .fill(item.isLowStock ? Color.red.opacity(0.12) : Color.cafeCaramel.opacity(0.12))
                    .frame(width: 44, height: 44)
                Text(item.category.icon)
                    .font(.system(size: 22))
            }

            // Name + stock bar
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(item.name)
                        .font(AppFonts.heading(16))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    if item.isLowStock {
                        Text("LOW")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.red)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.12))
                            .cornerRadius(4)
                    }
                }
                StockLevelBar(fraction: item.stockFraction, isLowStock: item.isLowStock)
                Text("\(item.quantity.rounded(to: 2), specifier: "%.2f") \(item.unit.rawValue) · Threshold: \(item.threshold.rounded(to: 2), specifier: "%.2f")")
                    .font(AppFonts.body_(12))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Price
            VStack(alignment: .trailing, spacing: 4) {
                Text(item.price.currencyFormatted)
                    .font(AppFonts.heading(14))
                    .foregroundColor(.cafeCaramel)
                Text("per \(item.unit.rawValue)")
                    .font(AppFonts.body_(11))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
