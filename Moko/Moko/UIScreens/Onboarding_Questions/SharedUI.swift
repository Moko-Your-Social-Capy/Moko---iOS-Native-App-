import SwiftUI

/// Colours from the Done / Reflection Figma screens.
enum RColor {
    static let text    = Color(hex: 0x201A18)
    static let body    = Color(hex: 0x414943)
    static let green   = Color(hex: 0x28523B)
    static let chevron = Color(hex: 0x1B422F)
    static let rust    = Color(hex: 0x9A442D)
    static let mint    = Color(hex: 0xBFEDCF)
    static let peach   = Color(hex: 0xFFDEAB)
}

/// The dark-green capsule button.
struct PillButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Capsule().fill(Color(hex: 0x1F7488)))
        }
        .buttonStyle(MokoPrimaryButtonStyle())
        .shadow(color: Color(hex: 0x1F7488).opacity(0.18), radius: 8, y: 4)
    }
}
