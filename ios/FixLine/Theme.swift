import SwiftUI

enum Theme {
    static let bg = Color(red: 0.06, green: 0.07, blue: 0.08)
    static let surface = Color(red: 0.10, green: 0.11, blue: 0.13)
    static let surfaceElevated = Color(red: 0.14, green: 0.15, blue: 0.17)
    static let stroke = Color.white.opacity(0.08)
    static let strokeStrong = Color.white.opacity(0.16)

    static let primary = Color(red: 1.0, green: 0.84, blue: 0.0)
    static let primaryDim = Color(red: 0.85, green: 0.71, blue: 0.0)
    static let onPrimary = Color.black

    static let danger = Color(red: 1.0, green: 0.30, blue: 0.27)
    static let success = Color(red: 0.20, green: 0.85, blue: 0.45)
    static let info = Color(red: 0.35, green: 0.70, blue: 1.0)

    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.65)
    static let textTertiary = Color.white.opacity(0.40)
}

extension View {
    func cardStyle(padding: CGFloat = 16) -> some View {
        self
            .padding(padding)
            .background(Theme.surface)
            .clipShape(.rect(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Theme.stroke, lineWidth: 1)
            )
    }
}
