import SwiftUI

enum BrandTheme {
    static let background = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(red: 0.07, green: 0.08, blue: 0.12, alpha: 1) : UIColor(red: 0.97, green: 0.98, blue: 1.0, alpha: 1)
    })
    static let backgroundSoft = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(red: 0.10, green: 0.12, blue: 0.19, alpha: 1) : UIColor(red: 0.93, green: 0.96, blue: 1.0, alpha: 1)
    })
    static let surface = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(red: 0.14, green: 0.16, blue: 0.24, alpha: 0.9) : UIColor.white.withAlphaComponent(0.82)
    })
    static let ink = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(red: 0.96, green: 0.97, blue: 1.0, alpha: 1) : UIColor(red: 0.08, green: 0.12, blue: 0.20, alpha: 1)
    })
    static let mutedInk = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(red: 0.77, green: 0.81, blue: 0.92, alpha: 1) : UIColor(red: 0.25, green: 0.32, blue: 0.46, alpha: 1)
    })
    static let border = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor.white.withAlphaComponent(0.16) : UIColor(red: 0.22, green: 0.30, blue: 0.52, alpha: 0.14)
    })
    static let accentWarm = Color(red: 1.0, green: 0.46, blue: 0.28)
    static let accentMint = Color(red: 0.20, green: 0.84, blue: 0.69)
    static let accentSky = Color(red: 0.30, green: 0.55, blue: 1.0)
    static let accentBubble = Color(red: 0.92, green: 0.40, blue: 0.68)

    static func font(_ size: CGFloat, weight: Font.Weight = .regular, relativeTo style: Font.TextStyle = .body) -> Font {
        let fontName: String
        switch weight {
        case .bold, .heavy, .black:
            fontName = "AvenirNextCondensed-Heavy"
        case .semibold:
            fontName = "AvenirNext-DemiBold"
        case .medium:
            fontName = "AvenirNext-Medium"
        default:
            fontName = "AvenirNext-Regular"
        }
        return Font.custom(fontName, size: size, relativeTo: style)
    }

    static var heroGradient: LinearGradient {
        LinearGradient(
            colors: [accentSky.opacity(0.45), accentMint.opacity(0.35), accentBubble.opacity(0.35)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct BrandPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(BrandTheme.font(15, weight: .semibold, relativeTo: .headline))
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [BrandTheme.accentSky, BrandTheme.accentBubble],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .opacity(configuration.isPressed ? 0.78 : 1.0)
                    )
            )
            .foregroundStyle(Color.white)
            .scaleEffect(configuration.isPressed ? 0.99 : 1.0)
    }
}

struct BrandSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(BrandTheme.font(15, weight: .semibold, relativeTo: .headline))
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(BrandTheme.surface.opacity(0.95))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(BrandTheme.accentSky.opacity(configuration.isPressed ? 0.7 : 0.35), lineWidth: 1)
            )
            .foregroundStyle(BrandTheme.ink)
    }
}

struct BrandCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(BrandTheme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(BrandTheme.border, lineWidth: 1.2)
            )
            .shadow(color: BrandTheme.accentSky.opacity(0.10), radius: 20, x: 0, y: 10)
    }
}
