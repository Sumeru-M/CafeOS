// MARK: - InventoryViewModel.swift
// Drives all inventory UI — list, add, edit, delete.
// Listens to Firestore in real-time via Combine.

import Foundation
import Combine

@MainActor
final class InventoryViewModel: ObservableObject {

    // MARK: Published State
    @Published var items:       [InventoryItem] = []
    @Published var isLoading    = true
    @Published var error:       AppError?
    @Published var searchText   = ""
    @Published var filterCategory: InventoryCategory? = nil
    @Published var sortOption: SortOption = .name

    // Form state (used by AddEditItemView)
    @Published var draftItem: DraftInventoryItem = DraftInventoryItem()
    @Published var isSaving = false

    enum SortOption: String, CaseIterable {
        case name     = "Name"
        case lowStock = "Low Stock First"
        case category = "Category"
        case updated  = "Last Updated"
    }

    private var cancellables = Set<AnyCancellable>()
    private let firestoreService = FirestoreService.shared

    // MARK: - Computed: Filtered & Sorted List

    var displayedItems: [InventoryItem] {
        var result = items

        // Filter by search
        if !searchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        // Filter by category
        if let cat = filterCategory {
            result = result.filter { $0.category == cat }
        }
        // Sort
        switch sortOption {
        case .name:
            result.sort { $0.name < $1.name }
        case .lowStock:
            result.sort { lhs, rhs in
                if lhs.isLowStock != rhs.isLowStock { return lhs.isLowStock }
                return lhs.name < rhs.name
            }
        case .category:
            result.sort { $0.category.rawValue < $1.category.rawValue }
        case .updated:
            result.sort { $0.lastUpdated > $1.lastUpdated }
        }
        return result
    }

    var lowStockCount: Int { items.filter(\.isLowStock).count }
    var isEmpty: Bool      { items.isEmpty && !isLoading }

    // MARK: - Setup

    init() { startListening() }

    private func startListening() {
        firestoreService.inventoryPublisher()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let err) = completion {
                    self?.error = err
                }
            } receiveValue: { [weak self] items in
                self?.isLoading = false
                self?.items = items
            }
            .store(in: &cancellables)
    }

    // MARK: - CRUD Actions

    func addItem() async {
        guard let item = draftItem.toInventoryItem() else {
            error = draftItem.validationError; return
        }
        isSaving = true
        defer { isSaving = false }
        do {
            try await firestoreService.createItem(item)
            draftItem = DraftInventoryItem()
        } catch let e as AppError { error = e }
        catch { self.error = .wrap(error) }
    }

    func updateItem(_ original: InventoryItem) async {
        guard let updated = draftItem.toInventoryItem(withId: original.id) else {
            error = draftItem.validationError; return
        }
        isSaving = true
        defer { isSaving = false }
        do {
            try await firestoreService.updateItem(updated, previousQuantity: original.quantity)
        } catch let e as AppError { error = e }
        catch { self.error = .wrap(error) }
    }

    func deleteItem(_ item: InventoryItem) async {
        do {
            try await firestoreService.deleteItem(item)
        } catch let e as AppError { error = e }
        catch { self.error = .wrap(error) }
    }

    func populateDraft(from item: InventoryItem) {
        draftItem = DraftInventoryItem(from: item)
    }

    func resetDraft() {
        draftItem = DraftInventoryItem()
    }

    func clearError() { error = nil }
}

// MARK: - DraftInventoryItem
// Mutable form state — validated before conversion to InventoryItem.

struct DraftInventoryItem {
    var name      = ""
    var quantity  = ""
    var unit      = InventoryUnit.units
    var threshold = ""
    var price     = ""
    var category  = InventoryCategory.other
    var notes     = ""

    init() {}

    init(from item: InventoryItem) {
        name      = item.name
        quantity  = String(item.quantity)
        unit      = item.unit
        threshold = String(item.threshold)
        price     = String(item.price)
        category  = item.category
        notes     = item.notes
    }

    var validationError: AppError? {
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return .emptyItemName }
        guard let q = Double(quantity), q >= 0 else { return .invalidQuantity }
        guard let t = Double(threshold), t >= 0 else { return .invalidThreshold }
        guard let p = Double(price), p >= 0 else { return .invalidPrice }
        _ = (q, t, p)
        return nil
    }

    func toInventoryItem(withId id: String = UUID().uuidString) -> InventoryItem? {
        guard validationError == nil,
              let q = Double(quantity),
              let t = Double(threshold),
              let p = Double(price) else { return nil }
        return InventoryItem(
            id: id,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            quantity: q,
            unit: unit,
            threshold: t,
            price: p,
            category: category,
            notes: notes
        )
    }
}
