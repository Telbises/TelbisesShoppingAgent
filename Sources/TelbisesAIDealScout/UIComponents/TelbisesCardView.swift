import SwiftUI

struct TelbisesCardView: View {
    let recommendation: TelbisesRecommendation
    let onView: () -> Void

    var body: some View {
        BrandCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Telbises Official")
                        .font(BrandTheme.font(12, weight: .semibold, relativeTo: .caption))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            LinearGradient(
                                colors: [BrandTheme.accentSky, BrandTheme.accentBubble],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundStyle(Color.white)
                        .clipShape(Capsule())
                        .accessibilityLabel("Telbises pick")

                    Spacer()
                }

                HStack(alignment: .top, spacing: 12) {
                    AsyncImage(url: recommendation.product.imageURL) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()
                        default:
                            RoundedRectangle(cornerRadius: 10)
                                .fill(BrandTheme.backgroundSoft)
                                .overlay(Image(systemName: "photo").font(.title2).foregroundStyle(BrandTheme.mutedInk))
                        }
                    }
                    .frame(width: 96, height: 96)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(BrandTheme.border, lineWidth: 1)
                    )
                    .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(recommendation.product.title)
                            .font(BrandTheme.font(17, weight: .semibold, relativeTo: .headline))
                            .foregroundStyle(BrandTheme.ink)
                            .accessibilityLabel("Telbises product, \(recommendation.product.title)")

                        Text(formattedPrice)
                            .font(BrandTheme.font(14, weight: .medium, relativeTo: .subheadline))
                            .foregroundStyle(BrandTheme.mutedInk)
                            .accessibilityLabel("Price \(formattedPrice)")

                        Text(recommendation.reasoning)
                            .font(BrandTheme.font(13, weight: .regular, relativeTo: .caption))
                            .foregroundStyle(BrandTheme.mutedInk)
                            .accessibilityLabel("Reasoning, \(recommendation.reasoning)")
                    }
                }

                Text(recommendation.disclosure)
                    .font(BrandTheme.font(12, weight: .regular, relativeTo: .caption2))
                    .foregroundStyle(BrandTheme.mutedInk)
                    .accessibilityLabel("Disclosure, \(recommendation.disclosure)")

                Button(action: onView) {
                    Text("View on Telbises")
                }
                .buttonStyle(BrandPrimaryButtonStyle())
                .accessibilityLabel("View on Telbises")
            }
        }
    }

    private var formattedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = recommendation.product.currency
        return formatter.string(from: recommendation.product.price as NSDecimalNumber) ?? "$0"
    }
}
