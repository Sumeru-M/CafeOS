// MARK: - AppError.swift
// Unified error type for the entire CafeOS application.

import Foundation

/// All user-facing errors in CafeOS.
/// Every throwing path ultimately wraps its error in `AppError`.
enum AppError: LocalizedError, Equatable {

    // Firebase / Network
    case networkUnavailable
    case firestoreRead(String)
    case firestoreWrite(String)
    case firestoreDelete(String)
    case authFailed(String)

    // Validation
    case emptyItemName
    case invalidQuantity
    case invalidThreshold
    case invalidPrice
    case thresholdExceedsQuantity

    // Job Scraper
    case invalidURL
    case scrapingFailed(String)
    case noContentFound

    // Generic
    case unknown(String)

    // MARK: LocalizedError

    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "No internet connection. Please check your network and try again."
        case .firestoreRead(let detail):
            return "Failed to load data. \(detail)"
        case .firestoreWrite(let detail):
            return "Failed to save changes. \(detail)"
        case .firestoreDelete(let detail):
            return "Failed to delete item. \(detail)"
        case .authFailed(let detail):
            return "Sign-in failed. \(detail)"
        case .emptyItemName:
            return "Item name cannot be empty."
        case .invalidQuantity:
            return "Please enter a valid quantity (≥ 0)."
        case .invalidThreshold:
            return "Please enter a valid reorder level (≥ 0)."
        case .invalidPrice:
            return "Please enter a valid price (≥ 0)."
        case .thresholdExceedsQuantity:
            return "Reorder level cannot exceed current quantity."
        case .invalidURL:
            return "Please enter a valid URL starting with https://."
        case .scrapingFailed(let detail):
            return "Could not extract job description. \(detail)"
        case .noContentFound:
            return "No job description content was found at this URL."
        case .unknown(let detail):
            return "An unexpected error occurred. \(detail)"
        }
    }

    /// Constructs an `AppError` from any arbitrary `Error`.
    static func wrap(_ error: Error) -> AppError {
        if let appError = error as? AppError { return appError }
        return .unknown(error.localizedDescription)
    }
}
