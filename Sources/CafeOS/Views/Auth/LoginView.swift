// MARK: - LoginView.swift
// Authentication screen with anonymous login and email/password form.

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var showEmailSignIn = false
    @State private var isCreatingAccount = false

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.cafeEspresso, Color(red: 0.15, green: 0.08, blue: 0.02)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Hero section
                VStack(spacing: 16) {
                    Text("☕️")
                        .font(.system(size: 80))
                        .padding(.top, 60)
                    Text("CaféOS")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(.cafeCream)
                    Text("Your digital café manager")
                        .font(AppFonts.body_(17))
                        .foregroundColor(.cafeCream.opacity(0.7))
                }
                .padding(.bottom, 60)

                // Auth card
                VStack(spacing: 20) {
                    if showEmailSignIn {
                        emailForm
                    } else {
                        guestButton
                        divider
                        emailToggleButton
                    }
                }
                .padding(AppLayout.padding)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
                .padding(.horizontal, 24)

                Spacer()

                Text("Café management, simplified.")
                    .font(AppFonts.body_(13))
                    .foregroundColor(.cafeCream.opacity(0.4))
                    .padding(.bottom, 32)
            }

            // Error banner
            if let error = authVM.error {
                VStack {
                    ErrorBannerView(message: error.localizedDescription) {
                        authVM.clearError()
                    }
                    .padding(.top, 60)
                    Spacer()
                }
                .zIndex(10)
            }
        }
        .animation(.spring(response: 0.4), value: showEmailSignIn)
    }

    // MARK: Sub-views

    private var guestButton: some View {
        PrimaryButton(
            title: "Continue as Guest",
            icon: "person.fill",
            isLoading: authVM.isLoading
        ) {
            authVM.continueAsGuest()
        }
    }

    private var divider: some View {
        HStack {
            Rectangle().fill(Color(.separator)).frame(height: 1)
            Text("or").font(AppFonts.body_(13)).foregroundColor(.secondary)
            Rectangle().fill(Color(.separator)).frame(height: 1)
        }
    }

    private var emailToggleButton: some View {
        Button("Sign in with Email") {
            withAnimation { showEmailSignIn = true }
        }
        .font(AppFonts.heading(15))
        .foregroundColor(.cafeCaramel)
    }

    private var emailForm: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: { withAnimation { showEmailSignIn = false } }) {
                    Image(systemName: "arrow.left")
                        .foregroundColor(.cafeCaramel)
                }
                Spacer()
                Text(isCreatingAccount ? "Create Account" : "Sign In")
                    .font(AppFonts.heading(18))
                Spacer()
            }

            CafeTextField(title: "Email", placeholder: "manager@cafe.com",
                         text: $authVM.email, keyboardType: .emailAddress)
            CafeTextField(title: "Password", placeholder: "••••••••",
                         text: $authVM.password)

            if isCreatingAccount {
                PrimaryButton(title: "Create Account", icon: "person.badge.plus",
                             isLoading: authVM.isLoading) { authVM.createAccount() }
            } else {
                PrimaryButton(title: "Sign In", icon: "arrow.right.circle",
                             isLoading: authVM.isLoading) { authVM.signIn() }
            }

            Button(isCreatingAccount ? "Already have an account? Sign In" : "New here? Create account") {
                withAnimation { isCreatingAccount.toggle() }
            }
            .font(AppFonts.body_(14))
            .foregroundColor(.secondary)
        }
    }
}
