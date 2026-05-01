// MARK: - AuthViewModel.swift
// Manages authentication state for the UI.

import Foundation
import Combine
import FirebaseAuth

@MainActor
final class AuthViewModel: ObservableObject {

    // MARK: Published State
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var error: AppError?
    @Published var showEmailForm = false

    // Form fields
    @Published var email    = ""
    @Published var password = ""

    private var cancellables = Set<AnyCancellable>()
    private let auth = AuthService.shared

    init() {
        // Mirror AuthService user into ViewModel
        auth.$currentUser
            .receive(on: DispatchQueue.main)
            .assign(to: &$currentUser)
    }

    // MARK: Computed

    var isSignedIn: Bool    { currentUser != nil }
    var isAnonymous: Bool   { currentUser?.isAnonymous ?? false }
    var displayName: String { currentUser?.email ?? "Guest" }

    // MARK: - Actions

    func continueAsGuest() {
        Task { await performAuth { try await self.auth.signInAnonymously() } }
    }

    func signIn() {
        guard validate() else { return }
        Task { await performAuth { try await self.auth.signIn(email: self.email, password: self.password) } }
    }

    func createAccount() {
        guard validate() else { return }
        Task { await performAuth { try await self.auth.createAccount(email: self.email, password: self.password) } }
    }

    func upgradeToEmail() {
        guard validate() else { return }
        Task {
            isLoading = true
            defer { isLoading = false }
            do {
                try await auth.linkAnonymousAccount(email: email, password: password)
                showEmailForm = false
            } catch let e as AppError {
                error = e
            } catch {
                self.error = .wrap(error)
            }
        }
    }

    func signOut() {
        do { try auth.signOut() }
        catch let e as AppError { error = e }
        catch { self.error = .wrap(error) }
    }

    func clearError() { error = nil }

    // MARK: - Helpers

    private func performAuth(_ block: @escaping () async throws -> Void) async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await block()
            showEmailForm = false
        } catch let e as AppError {
            error = e
        } catch {
            self.error = .wrap(error)
        }
    }

    private func validate() -> Bool {
        guard !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !password.isEmpty else {
            error = .authFailed("Email and password are required.")
            return false
        }
        return true
    }
}
