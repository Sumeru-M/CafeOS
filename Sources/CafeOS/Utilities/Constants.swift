// MARK: - Constants.swift

import SwiftUI

enum AppColors {
    // Primary palette — warm espresso tones
    static let espresso    = Color("Espresso")     // deep brown #3B1F0A
    static let caramel     = Color("Caramel")      // warm amber #C47B2B
    static let cream       = Color("Cream")        // off-white  #F5F0E8
    static let sage        = Color("Sage")         // accent     #7A9E7E
    static let surface     = Color("Surface")      // card bg
    static let background  = Color("AppBackground")

    // Semantic
    static let insightRed   = Color("InsightRed")
    static let insightAmber = Color("InsightAmber")
    static let insightGreen = Color("InsightGreen")
}

enum AppFonts {
    static func display(_ size: CGFloat) -> Font    { .system(size: size, weight: .bold,     design: .rounded) }
    static func heading(_ size: CGFloat) -> Font    { .system(size: size, weight: .semibold, design: .rounded) }
    static func body_(_ size: CGFloat) -> Font      { .system(size: size, weight: .regular,  design: .default) }
    static func mono(_ size: CGFloat) -> Font       { .system(size: size, weight: .regular,  design: .monospaced) }
}

enum AppLayout {
    static let cornerRadius: CGFloat  = 16
    static let cardRadius: CGFloat    = 12
    static let padding: CGFloat       = 16
    static let smallPadding: CGFloat  = 8
}
