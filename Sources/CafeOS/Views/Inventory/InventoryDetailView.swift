// MARK: - InventoryDetailView.swift
// Displays full details for a single inventory item.

import SwiftUI

struct InventoryDetailView: View {
    let item: InventoryItem
    @EnvironmentObject var vm: InventoryViewModel
    @State private var showEdit    = false
    @State private var showDelete  = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header card
                headerCard
                // Stats grid
                statsGrid
                // Notes
                if !item.notes.isEmpty { notesCard }
                // Danger zone
                dangerZone
            }
            .padding(AppLayout.padding)
        }
        .navigationTitle(item.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { vm.populateDraft(from: item); showEdit = true }) {
                    Image(systemName: "pencil")
                        .foregroundColor(.cafeCaramel)
                }
            }
        }
        .sheet(isPresented: $showEdit) {
            AddEditItemView(mode: .edit(item))
        }
        .confirmationDialog("Delete \(item.name)?",
                           isPresented: $showDelete,
                           titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                Task {
                    await vm.deleteItem(item)
                    dismiss()
                }
            }
        } message: {
            Text("This will permanently delete this item and all its usage history.")
        }
    }

    // MARK: - Sub-views

    private var headerCard: some View {
        VStack(spacing: 16) {
            Text(item.category.icon)
                .font(.system(size: 56))
            Text(item.name)
                .font(AppFonts.display(24))
            Text(item.category.rawValue)
                .font(AppFonts.body_(15))
                .foregroundColor(.secondary)
            if item.isLowStock {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text("Below reorder level")
                }
                .font(AppFonts.heading(14))
                .foregroundColor(.red)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.red.opacity(0.1))
                .cornerRadius(20)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .cardStyle()
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(icon: "scalemass", label: "Quantity",
                    value: "\(item.quantity.rounded(to: 2)) \(item.unit.rawValue)")
            StatCard(icon: "arrow.triangle.2.circlepath", label: "Reorder At",
                    value: "\(item.threshold.rounded(to: 2)) \(item.unit.rawValue)")
            StatCard(icon: "tag", label: "Unit Price",
                    value: item.price.currencyFormatted)
            StatCard(icon: "clock", label: "Updated",
                    value: item.lastUpdated.relativeDescription)
        }
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Notes", systemImage: "note.text")
                .font(AppFonts.heading(14))
                .foregroundColor(.secondary)
            Text(item.notes)
                .font(AppFonts.body_(15))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppLayout.padding)
        .cardStyle()
    }

    private var dangerZone: some View {
        Button(action: { showDelete = true }) {
            HStack {
                Image(systemName: "trash")
                Text("Delete Item")
            }
            .font(AppFonts.heading(15))
            .foregroundColor(.red)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.red.opacity(0.08))
            .cornerRadius(AppLayout.cornerRadius)
        }
    }
}

// MARK: - StatCard

private struct StatCard: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.cafeCaramel)
            Text(label)
                .font(AppFonts.body_(12))
                .foregroundColor(.secondary)
            Text(value)
                .font(AppFonts.heading(16))
                .foregroundColor(.primary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppLayout.padding)
        .cardStyle()
    }
}
