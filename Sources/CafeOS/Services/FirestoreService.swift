// MARK: - FirestoreService.swift
// Centralised Firestore access layer.
// All reads/writes go through this service — no Firebase imports in ViewModels.

import Foundation
import FirebaseFirestore
import Combine

/// Provides async/await CRUD operations and real-time listeners for Firestore.
final class FirestoreService {

    // MARK: Singleton
    static let shared = FirestoreService()
    private init() {}

    private let db = Firestore.firestore()

    // MARK: Collection References

    private var inventoryRef: CollectionReference {
        db.collection("inventory")
    }

    private func historyRef(for itemId: String) -> CollectionReference {
        inventoryRef.document(itemId).collection("history")
    }

    // MARK: - Real-time Listener

    /// Attaches a real-time snapshot listener to the inventory collection.
    /// Returns an `AnyCancellable` — retain it in the ViewModel to keep listening.
    func inventoryPublisher() -> AnyPublisher<[InventoryItem], AppError> {
        let subject = PassthroughSubject<[InventoryItem], AppError>()

        let listener = inventoryRef
            .order(by: "name")
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    subject.send(completion: .failure(.firestoreRead(error.localizedDescription)))
                    return
                }
                let items = snapshot?.documents.compactMap {
                    InventoryItem.from(snapshot: $0)
                } ?? []
                subject.send(items)
            }

        return subject
            .handleEvents(receiveCancel: { listener.remove() })
            .eraseToAnyPublisher()
    }

    // MARK: - CRUD

    /// Creates a new inventory item in Firestore.
    func createItem(_ item: InventoryItem) async throws {
        do {
            try await inventoryRef.document(item.id).setData(item.firestoreData)
            // Record initial snapshot for AI trend tracking
            try await recordSnapshot(for: item)
        } catch {
            throw AppError.firestoreWrite(error.localizedDescription)
        }
    }

    /// Updates an existing inventory item.
    /// If the quantity changed, a new history snapshot is recorded.
    func updateItem(_ item: InventoryItem, previousQuantity: Double) async throws {
        do {
            try await inventoryRef.document(item.id).updateData(item.firestoreData)
            // Only record history if quantity actually changed
            if item.quantity != previousQuantity {
                try await recordSnapshot(for: item)
            }
        } catch {
            throw AppError.firestoreWrite(error.localizedDescription)
        }
    }

    /// Deletes an inventory item and its entire history subcollection.
    func deleteItem(_ item: InventoryItem) async throws {
        do {
            // Delete history snapshots first
            let snapshots = try await historyRef(for: item.id).getDocuments()
            for doc in snapshots.documents {
                try await doc.reference.delete()
            }
            // Delete the item itself
            try await inventoryRef.document(item.id).delete()
        } catch {
            throw AppError.firestoreDelete(error.localizedDescription)
        }
    }

    // MARK: - Usage History

    /// Writes a new `UsageSnapshot` for an item (triggered on quantity change).
    func recordSnapshot(for item: InventoryItem) async throws {
        let snapshot = UsageSnapshot(itemId: item.id, quantity: item.quantity)
        do {
            try await historyRef(for: item.id)
                .document(snapshot.id)
                .setData(snapshot.firestoreData)
        } catch {
            // Non-fatal — log but don't surface to user
            print("⚠️ FirestoreService: Failed to record snapshot — \(error.localizedDescription)")
        }
    }

    /// Fetches the most recent N usage snapshots for an item, oldest first.
    func fetchHistory(for itemId: String, limit: Int = 14) async throws -> [UsageSnapshot] {
        do {
            let result = try await historyRef(for: itemId)
                .order(by: "timestamp", descending: true)
                .limit(to: limit)
                .getDocuments()

            return result.documents
                .compactMap { UsageSnapshot.from(snapshot: $0, itemId: itemId) }
                .sorted { $0.timestamp < $1.timestamp }     // oldest → newest
        } catch {
            throw AppError.firestoreRead(error.localizedDescription)
        }
    }

    /// Fetches history for all items — used by `AIInsightService` on launch.
    func fetchAllHistory(for items: [InventoryItem]) async -> [String: [UsageSnapshot]] {
        var result: [String: [UsageSnapshot]] = [:]
        await withTaskGroup(of: (String, [UsageSnapshot]).self) { group in
            for item in items {
                group.addTask {
                    let snapshots = (try? await self.fetchHistory(for: item.id)) ?? []
                    return (item.id, snapshots)
                }
            }
            for await (id, snapshots) in group {
                result[id] = snapshots
            }
        }
        return result
    }
}
