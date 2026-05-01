// MARK: - InventoryItem.swift
// Model representing a single café inventory item.
// Stored in Firestore at /inventory/{itemId}

import Foundation
import FirebaseFirestore

/// Categories for grouping inventory items.
enum InventoryCategory: String, CaseIterable, Codable {
    case dairy      = "Dairy"
    case beverages  = "Beverages"
    case dryGoods   = "Dry Goods"
    case produce    = "Produce"
    case packaging  = "Packaging"
    case other      = "Other"

    var icon: String {
        switch self {
        case .dairy:      return "🥛"
        case .beverages:  return "☕️"
        case .dryGoods:   return "🌾"
        case .produce:    return "🥦"
        case .packaging:  return "📦"
        case .other:      return "🔧"
        }
    }
}

/// Unit of measurement for an inventory item.
enum InventoryUnit: String, CaseIterable, Codable {
    case kg       = "kg"
    case grams    = "g"
    case liters   = "L"
    case ml       = "ml"
    case units    = "units"
    case boxes    = "boxes"
    case bags     = "bags"
}

/// Core data model for a café inventory item.
/// Conforms to `Codable` for Firestore serialisation.
struct InventoryItem: Identifiable, Codable, Equatable {

    // MARK: Stored Properties
    var id: String
    var name: String
    var quantity: Double
    var unit: InventoryUnit
    var threshold: Double       // Reorder/alert level
    var price: Double           // Price per unit (in local currency)
    var category: InventoryCategory
    var notes: String
    var lastUpdated: Date

    // MARK: Computed Properties

    /// True when the current quantity is at or below the alert threshold.
    var isLowStock: Bool {
        quantity <= threshold
    }

    /// Fraction of threshold consumed (used for progress indicators).
    /// Clamped to 0…1.
    var stockFraction: Double {
        guard threshold > 0 else { return 1.0 }
        return min(quantity / threshold, 1.0)
    }

    // MARK: Init

    init(
        id: String = UUID().uuidString,
        name: String,
        quantity: Double,
        unit: InventoryUnit = .units,
        threshold: Double,
        price: Double,
        category: InventoryCategory = .other,
        notes: String = "",
        lastUpdated: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.threshold = threshold
        self.price = price
        self.category = category
        self.notes = notes
        self.lastUpdated = lastUpdated
    }

    // MARK: Firestore Dictionary Conversion

    /// Serialises the item for Firestore. Dates become Timestamps.
    var firestoreData: [String: Any] {
        [
            "name":        name,
            "quantity":    quantity,
            "unit":        unit.rawValue,
            "threshold":   threshold,
            "price":       price,
            "category":    category.rawValue,
            "notes":       notes,
            "lastUpdated": Timestamp(date: lastUpdated)
        ]
    }

    /// Deserialises an `InventoryItem` from a Firestore document snapshot.
    static func from(snapshot: DocumentSnapshot) -> InventoryItem? {
        guard let data = snapshot.data() else { return nil }
        return InventoryItem(
            id:          snapshot.documentID,
            name:        data["name"]      as? String ?? "",
            quantity:    data["quantity"]  as? Double ?? 0,
            unit:        InventoryUnit(rawValue: data["unit"] as? String ?? "") ?? .units,
            threshold:   data["threshold"] as? Double ?? 0,
            price:       data["price"]     as? Double ?? 0,
            category:    InventoryCategory(rawValue: data["category"] as? String ?? "") ?? .other,
            notes:       data["notes"]     as? String ?? "",
            lastUpdated: (data["lastUpdated"] as? Timestamp)?.dateValue() ?? Date()
        )
    }
}

// MARK: - Preview / Mock Data

extension InventoryItem {
    static let previewItems: [InventoryItem] = [
        InventoryItem(id: "1", name: "Whole Milk",    quantity: 3.5,  unit: .liters, threshold: 5,   price: 1.20, category: .dairy,     notes: "Full-fat UHT"),
        InventoryItem(id: "2", name: "Espresso Beans",quantity: 0.8,  unit: .kg,     threshold: 2,   price: 18.0, category: .beverages, notes: "Single origin Ethiopia"),
        InventoryItem(id: "3", name: "Oat Milk",      quantity: 12,   unit: .liters, threshold: 4,   price: 1.80, category: .dairy,     notes: "Barista edition"),
        InventoryItem(id: "4", name: "Brown Sugar",   quantity: 0.5,  unit: .kg,     threshold: 1,   price: 0.90, category: .dryGoods,  notes: ""),
        InventoryItem(id: "5", name: "Paper Cups 8oz",quantity: 200,  unit: .units,  threshold: 100, price: 0.05, category: .packaging, notes: "Compostable"),
        InventoryItem(id: "6", name: "Vanilla Syrup", quantity: 0.3,  unit: .liters, threshold: 0.5, price: 7.50, category: .beverages, notes: "Monin"),
    ]
}
