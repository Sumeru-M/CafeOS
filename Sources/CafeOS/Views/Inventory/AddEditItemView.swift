// MARK: - AddEditItemView.swift
// Form for creating or editing an inventory item.

import SwiftUI

enum ItemFormMode {
    case add
    case edit(InventoryItem)
}

struct AddEditItemView: View {
    let mode: ItemFormMode
    @EnvironmentObject var vm: InventoryViewModel
    @Environment(\.dismiss) var dismiss

    // Per-field validation error state
    @State private var nameError:      String? = nil
    @State private var quantityError:  String? = nil
    @State private var thresholdError: String? = nil
    @State private var priceError:     String? = nil

    var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    var originalItem: InventoryItem? {
        if case .edit(let item) = mode { return item }
        return nil
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Category picker
                    categoryPicker
                    // Name field
                    CafeTextField(title: "Item Name", placeholder: "e.g. Whole Milk",
                                 text: $vm.draftItem.name, error: nameError)
                    // Quantity + Unit row
                    HStack(spacing: 12) {
                        CafeTextField(title: "Quantity", placeholder: "0.0",
                                     text: $vm.draftItem.quantity,
                                     keyboardType: .decimalPad, error: quantityError)
                        unitPicker
                    }
                    // Threshold
                    CafeTextField(title: "Reorder Level (alert threshold)",
                                 placeholder: "0.0",
                                 text: $vm.draftItem.threshold,
                                 keyboardType: .decimalPad, error: thresholdError)
                    // Price
                    CafeTextField(title: "Price per unit", placeholder: "0.00",
                                 text: $vm.draftItem.price,
                                 keyboardType: .decimalPad, error: priceError)
                    // Notes
                    VStack(alignment: .leading, spacing: 6) {
                        Text("NOTES")
                            .font(AppFonts.body_(12))
                            .foregroundColor(.secondary)
                            .tracking(0.5)
                        TextField("Optional notes…", text: $vm.draftItem.notes, axis: .vertical)
                            .lineLimit(3...6)
                            .padding(12)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(AppLayout.cardRadius)
                    }

                    // Submit
                    PrimaryButton(
                        title: isEditing ? "Save Changes" : "Add Item",
                        icon: isEditing ? "checkmark.circle" : "plus.circle",
                        isLoading: vm.isSaving,
                        action: submit
                    )
                    .padding(.top, 8)
                }
                .padding(AppLayout.padding)
            }
            .navigationTitle(isEditing ? "Edit Item" : "New Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.cafeCaramel)
                }
            }
        }
        .onAppear {
            if case .edit(let item) = mode {
                vm.populateDraft(from: item)
            }
        }
    }

    // MARK: Sub-views

    private var categoryPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("CATEGORY")
                .font(AppFonts.body_(12))
                .foregroundColor(.secondary)
                .tracking(0.5)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(InventoryCategory.allCases, id: \.self) { cat in
                        Button(action: { vm.draftItem.category = cat }) {
                            HStack(spacing: 6) {
                                Text(cat.icon)
                                Text(cat.rawValue)
                                    .font(AppFonts.body_(14))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(vm.draftItem.category == cat
                                       ? Color.cafeCaramel : Color(.secondarySystemBackground))
                            .foregroundColor(vm.draftItem.category == cat ? .white : .primary)
                            .cornerRadius(20)
                        }
                    }
                }
            }
        }
    }

    private var unitPicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("UNIT")
                .font(AppFonts.body_(12))
                .foregroundColor(.secondary)
                .tracking(0.5)
            Picker("Unit", selection: $vm.draftItem.unit) {
                ForEach(InventoryUnit.allCases, id: \.self) { unit in
                    Text(unit.rawValue).tag(unit)
                }
            }
            .pickerStyle(.menu)
            .padding(10)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(AppLayout.cardRadius)
        }
    }

    // MARK: - Submit

    private func submit() {
        // Validate
        var hasError = false
        nameError = nil; quantityError = nil; thresholdError = nil; priceError = nil

        if vm.draftItem.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            nameError = "Name is required"; hasError = true
        }
        if Double(vm.draftItem.quantity) == nil || Double(vm.draftItem.quantity)! < 0 {
            quantityError = "Enter a valid quantity"; hasError = true
        }
        if Double(vm.draftItem.threshold) == nil || Double(vm.draftItem.threshold)! < 0 {
            thresholdError = "Enter a valid reorder level"; hasError = true
        }
        if Double(vm.draftItem.price) == nil || Double(vm.draftItem.price)! < 0 {
            priceError = "Enter a valid price"; hasError = true
        }
        if hasError { return }

        Task {
            if let original = originalItem {
                await vm.updateItem(original)
            } else {
                await vm.addItem()
            }
            if vm.error == nil { dismiss() }
        }
    }
}
