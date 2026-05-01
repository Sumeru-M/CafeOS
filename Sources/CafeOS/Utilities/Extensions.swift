// MARK: - Extensions.swift

import SwiftUI

// MARK: - View Extensions

extension View {
    /// Applies a standard card style: rounded corners, shadow, background fill.
    func cardStyle(background: Color = Color(.secondarySystemBackground)) -> some View {
        self
            .background(background)
            .cornerRadius(AppLayout.cardRadius)
            .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
    }

    /// Convenience for conditional modifier application.
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition { transform(self) } else { self }
    }
}

// MARK: - Double Extensions

extension Double {
    /// Formats as currency string: "$12.50"
    var currencyFormatted: String {
        let fmt = NumberFormatter()
        fmt.numberStyle = .currency
        return fmt.string(from: NSNumber(value: self)) ?? "$\(self)"
    }

    /// Rounds to N decimal places.
    func rounded(to places: Int) -> Double {
        let factor = pow(10.0, Double(places))
        return (self * factor).rounded() / factor
    }
}

// MARK: - Date Extensions

extension Date {
    /// Relative time description: "2 hours ago", "Yesterday", "3 days ago".
    var relativeDescription: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }

    /// Short date: "May 1"
    var shortDate: String {
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        fmt.timeStyle = .none
        return fmt.string(from: self)
    }
}

// MARK: - Color Asset Fallback
// When running without an asset catalog, provide sensible fallbacks.

extension Color {
    static var cafeEspresso: Color {
        Color(red: 0.23, green: 0.12, blue: 0.04)
    }
    static var cafeCaramel: Color {
        Color(red: 0.77, green: 0.48, blue: 0.17)
    }
    static var cafeCream: Color {
        Color(red: 0.96, green: 0.94, blue: 0.91)
    }
    static var cafeSage: Color {
        Color(red: 0.48, green: 0.62, blue: 0.49)
    }
}
