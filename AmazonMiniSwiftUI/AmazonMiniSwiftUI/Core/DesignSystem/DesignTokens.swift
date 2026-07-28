//
//  DesignTokens.swift
//  AmazonMiniSwiftUI
//
//  The app's single source of truth for visual style: brand palette, surface colors,
//  semantic colors, spacing, corner radii, and the type scale. Import nothing but
//  SwiftUI; reference these anywhere via `Color.brandNavy`, `AppSpacing.md`, etc.
//
//  Created by Arpit Parekh on 27/07/26.
//

import SwiftUI

// MARK: - Color tokens

extension Color {
    /// Init from a hex literal, e.g. `Color(hex: 0xFF9900)`.
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: alpha
        )
    }

    // Brand
    static let brandNavy = Color(hex: 0x131921)          // headings / primary text
    static let brandText = Color(hex: 0x0F1111)          // body text
    static let brandSecondary = Color(hex: 0x565959)     // captions / hints
    static let brandOrange = Color(hex: 0xFF9900)        // primary actions / accent
    static let brandOrangePressed = Color(hex: 0xE88B00)

    // Surfaces
    static let surface = Color.white
    static let fieldBackground = Color(hex: 0xF7F7F7)
    static let fieldBorder = Color(hex: 0xD5D9D9)
    static let hairline = Color(hex: 0xE7E7E7)           // thin dividers

    // Semantic
    static let errorRed = Color(hex: 0xB12704)           // Amazon red
    static let successGreen = Color(hex: 0x067D62)
}

// MARK: - Spacing scale

enum AppSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
}

// MARK: - Corner radii

enum AppRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
}

// MARK: - Type scale

// Semantic fonts so every screen uses the same hierarchy. Combine with brand colors:
// `.font(AppFont.title).foregroundStyle(Color.brandNavy)`.
enum AppFont {
    static let largeTitle = Font.system(size: 28, weight: .bold)
    static let title = Font.system(size: 22, weight: .bold)
    static let title2 = Font.system(size: 20, weight: .semibold)
    static let headline = Font.system(size: 17, weight: .semibold)
    static let body = Font.system(size: 16, weight: .regular)
    static let subheadline = Font.system(size: 14, weight: .regular)
    static let footnote = Font.system(size: 13, weight: .regular)
    static let caption = Font.system(size: 12, weight: .regular)
}
