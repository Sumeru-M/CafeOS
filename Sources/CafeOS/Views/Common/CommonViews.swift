// MARK: - Common Views

import SwiftUI

// MARK: - LoadingView

struct LoadingView: View {
    var message: String = "Loading…"
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.4)
                .tint(.cafeCaramel)
            Text(message)
                .font(AppFonts.body_(14))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

// MARK: - EmptyStateView

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 20) {
            Text(icon)
                .font(.system(size: 64))
            VStack(spacing: 8) {
                Text(title)
                    .font(AppFonts.heading(20))
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(AppFonts.body_(15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            if let title = actionTitle, let action = action {
                Button(action: action) {
                    Text(title)
                        .font(AppFonts.heading(15))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.cafeCaramel)
                        .cornerRadius(AppLayout.cornerRadius)
                }
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - ErrorBannerView

struct ErrorBannerView: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.white)
            Text(message)
                .font(AppFonts.body_(14))
                .foregroundColor(.white)
                .lineLimit(3)
            Spacer()
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .foregroundColor(.white.opacity(0.8))
                    .padding(4)
            }
        }
        .padding(AppLayout.padding)
        .background(Color.red.opacity(0.9))
        .cornerRadius(AppLayout.cardRadius)
        .padding(.horizontal, AppLayout.padding)
        .shadow(color: .red.opacity(0.3), radius: 8, y: 4)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

// MARK: - StockLevelBar

/// Horizontal bar showing stock level relative to threshold.
struct StockLevelBar: View {
    let fraction: Double    // 0...1, current / threshold
    let isLowStock: Bool

    private var barColor: Color {
        if isLowStock          { return .red }
        if fraction < 1.5      { return .orange }
        return .cafeSage
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(height: 6)
                RoundedRectangle(cornerRadius: 4)
                    .fill(barColor)
                    .frame(width: geo.size.width * min(fraction, 1), height: 6)
                    .animation(.spring(response: 0.5), value: fraction)
            }
        }
        .frame(height: 6)
    }
}

// MARK: - CafeTextField

struct CafeTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var error: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(AppFonts.body_(12))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .padding(12)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(AppLayout.cardRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: AppLayout.cardRadius)
                        .stroke(error != nil ? Color.red : Color.clear, lineWidth: 1.5)
                )
            if let error {
                Text(error)
                    .font(AppFonts.body_(12))
                    .foregroundColor(.red)
                    .transition(.opacity)
            }
        }
    }
}

// MARK: - PrimaryButton

struct PrimaryButton: View {
    let title: String
    var icon: String? = nil
    var isLoading: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView().tint(.white)
                } else {
                    if let icon { Image(systemName: icon) }
                    Text(title)
                }
            }
            .font(AppFonts.heading(16))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.cafeCaramel)
            .cornerRadius(AppLayout.cornerRadius)
        }
        .disabled(isLoading)
        .scaleEffect(isLoading ? 0.97 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isLoading)
    }
}
