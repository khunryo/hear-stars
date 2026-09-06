import SwiftUI

extension Color {
    static let hsNight = Color(red: 2.0 / 255.0, green: 2.0 / 255.0, blue: 3.0 / 255.0)
    static let hsPanel = Color(red: 9.0 / 255.0, green: 9.0 / 255.0, blue: 13.0 / 255.0)
    static let hsText = Color(red: 185.0 / 255.0, green: 178.0 / 255.0, blue: 167.0 / 255.0)
    // Both text-capable secondary colors remain above a 4.5:1 contrast ratio
    // against hsPanel while preserving the low-luminance night palette.
    static let hsSecondary = Color(red: 128.0 / 255.0, green: 121.0 / 255.0, blue: 111.0 / 255.0)
    static let hsGuide = Color(red: 175.0 / 255.0, green: 105.0 / 255.0, blue: 88.0 / 255.0)
    static let hsDiscovery = Color(red: 188.0 / 255.0, green: 134.0 / 255.0, blue: 88.0 / 255.0)
}

struct NightPanel: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.hsPanel.opacity(reduceTransparency ? 1.0 : 0.78))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.hsSecondary.opacity(0.22), lineWidth: 0.75)
                    )
            )
    }
}

extension View {
    func nightPanel() -> some View { modifier(NightPanel()) }
}
