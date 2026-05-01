// MARK: - UsageSnapshot.swift
// A time-stamped record of an item's quantity at a point in time.
// Stored in Firestore at /inventory/{itemId}/history/{snapshotId}

import Foundation
import FirebaseFirestore

/// Records the quantity of an inventory item at a specific moment.
/// Used by `AIInsightService` to compute usage trends.
struct UsageSnapshot: Identifiable, Codable {

    var id: String
    var itemId: String
    var quantity: Double
    var timestamp: Date

    init(
        id: String = UUID().uuidString,
        itemId: String,
        quantity: Double,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.itemId = itemId
        self.quantity = quantity
        self.timestamp = timestamp
    }

    // MARK: Firestore

    var firestoreData: [String: Any] {
        [
            "itemId":    itemId,
            "quantity":  quantity,
            "timestamp": Timestamp(date: timestamp)
        ]
    }

    static func from(snapshot: DocumentSnapshot, itemId: String) -> UsageSnapshot? {
        guard let data = snapshot.data() else { return nil }
        return UsageSnapshot(
            id:        snapshot.documentID,
            itemId:    itemId,
            quantity:  data["quantity"]  as? Double ?? 0,
            timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
        )
    }
}
