// MARK: - AuthService.swift
// Firebase Authentication wrapper.
// Supports anonymous sign-in and email/password with anonymous → email upgrade.

import Foundation
import FirebaseAuth
import Combine

/// Wraps Firebase Auth, exposing a clean async interface and a Combine publisher for auth state.
final class AuthService {

    // MARK: Singleton
    static let shared = AuthService()
    private init() {}

    // MARK: Published State

    /// Current Firebase user (nil = not signed in)
    @Published private(set) var currentUser: User?

    private var authStateHandle: AuthStateDidChangeListenerHandle?

    // MARK: Setup

    /// Call from AppState to start listening for auth state changes.
    func startListening() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.currentUser = user
        }
    }

    func stopListening() {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    // MARK: - Sign In

    /// Signs in anonymously. Fast, no credentials required.
    @discardableResult
    func signInAnonymously() async throws -> User {
        do {
            let result = try await Auth.auth().signInAnonymously()
            return result.user
        } catch {
            throw AppError.authFailed(error.localizedDescription)
        }
    }

    /// Signs in with email and password (for returning managers).
    @discardableResult
    func signIn(email: String, password: String) async throws -> User {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            return result.user
        } catch {
            throw AppError.authFailed(error.localizedDescription)
        }
    }

    /// Creates a new account with email and password.
    @discardableResult
    func createAccount(email: String, password: String) async throws -> User {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            return result.user
        } catch {
            throw AppError.authFailed(error.localizedDescription)
        }
    }

    /// Upgrades an anonymous account to email/password.
    /// Preserves all existing data tied to the anonymous UID.
    func linkAnonymousAccount(email: String, password: String) async throws {
        guard let user = Auth.auth().currentUser, user.isAnonymous else {
            throw AppError.authFailed("No anonymous session to upgrade.")
        }
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        do {
            try await user.link(with: credential)
        } catch {
            throw AppError.authFailed(error.localizedDescription)
        }
    }

    // MARK: - Sign Out

    func signOut() throws {
        do {
            try Auth.auth().signOut()
        } catch {
            throw AppError.authFailed(error.localizedDescription)
        }
    }

    // MARK: Helpers

    var isSignedIn: Bool { currentUser != nil }
    var isAnonymous: Bool { currentUser?.isAnonymous ?? false }
    var displayEmail: String { currentUser?.email ?? "Guest" }
}
