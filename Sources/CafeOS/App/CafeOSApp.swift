// MARK: - AppState.swift + CafeOSApp.swift
// App entry point and global session state.

import SwiftUI
import Firebase

// MARK: - AppState

/// Global app state — passed as an environment object through the view hierarchy.
final class AppState: ObservableObject {
    @Published var hasCompletedOnboarding = false
    let authViewModel     = AuthViewModel()
    let inventoryViewModel = InventoryViewModel()
    let insightsViewModel  = InsightsViewModel()

    init() {
        // Start listening for Firebase auth changes
        AuthService.shared.startListening()
    }
}

// MARK: - CafeOSApp

@main
struct CafeOSApp: App {

    @StateObject private var appState = AppState()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(appState.authViewModel)
                .environmentObject(appState.inventoryViewModel)
                .environmentObject(appState.insightsViewModel)
        }
    }
}

// MARK: - RootView

/// Shows LoginView if unauthenticated; otherwise the main tab interface.
struct RootView: View {
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        Group {
            if authVM.isSignedIn {
                MainTabView()
                    .transition(.opacity)
            } else {
                LoginView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authVM.isSignedIn)
    }
}
