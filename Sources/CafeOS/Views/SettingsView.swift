// MARK: - SettingsView.swift
// Account management and app info.

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var showUpgrade = false

    var body: some View {
        List {
            // Account section
            Section("Account") {
                HStack {
                    Image(systemName: authVM.isAnonymous ? "person.fill.questionmark" : "person.crop.circle.fill")
                        .font(.title2)
                        .foregroundColor(.cafeCaramel)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(authVM.isAnonymous ? "Guest User" : authVM.displayName)
                            .font(AppFonts.heading(15))
                        Text(authVM.isAnonymous ? "Anonymous session" : "Email account")
                            .font(AppFonts.body_(13))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)

                if authVM.isAnonymous {
                    Button(action: { showUpgrade = true }) {
                        Label("Upgrade to Email Account", systemImage: "envelope.badge")
                    }
                    .foregroundColor(.cafeCaramel)
                }

                Button(role: .destructive, action: { authVM.signOut() }) {
                    Label("Sign Out", systemImage: "arrow.right.square")
                }
            }

            // App info
            Section("About") {
                LabeledContent("Version", value: "1.0.0")
                LabeledContent("Build", value: "1")
                LabeledContent("iOS", value: "16.0+")
                LabeledContent("Architecture", value: "MVVM + Firebase")
            }

            // AI feature info
            Section("AI Engine") {
                VStack(alignment: .leading, spacing: 8) {
                    Label("On-Device Linear Regression", systemImage: "brain")
                        .font(AppFonts.heading(14))
                    Text("CaféOS analyses quantity changes over time using least-squares linear regression to predict stock depletion — no external AI API required.")
                        .font(AppFonts.body_(13))
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Settings")
        .sheet(isPresented: $showUpgrade) {
            upgradeSheet
        }
    }

    private var upgradeSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("🔐")
                    .font(.system(size: 60))
                    .padding(.top, 32)
                Text("Upgrade Account")
                    .font(AppFonts.display(24))
                Text("Save your data permanently by linking an email address. Your current inventory data will be preserved.")
                    .font(AppFonts.body_(15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                VStack(spacing: 16) {
                    CafeTextField(title: "Email", placeholder: "you@cafe.com",
                                 text: $authVM.email, keyboardType: .emailAddress)
                    CafeTextField(title: "Password", placeholder: "Choose a password",
                                 text: $authVM.password)
                    PrimaryButton(title: "Link Account", icon: "link",
                                 isLoading: authVM.isLoading) { authVM.upgradeToEmail() }
                }
                .padding(.horizontal, AppLayout.padding)
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { showUpgrade = false }
                        .foregroundColor(.cafeCaramel)
                }
            }
        }
    }
}
