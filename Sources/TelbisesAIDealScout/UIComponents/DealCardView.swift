import SwiftUI

struct DealCardView: View {
    let recommendation: Recommendation
    let onViewDeal: () -> Void
    let onToggleFavorite: () -> Void
    let onToggleCompare: () -> Void
    let isFavorite: Bool
    let isCompared: Bool

    var body: some View {
        BrandCard {
            VStack(alignment: .leading, spacing: 12) {
                if recommendation.deal.isSponsored {
                    Text("Sponsored")
                        .font(BrandTheme.font(12, weight: .semibold, relativeTo: .caption))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(BrandTheme.accentWarm.opacity(0.20))
                        .foregroundStyle(BrandTheme.ink)
                        .clipShape(Capsule())
                        .accessibilityLabel("Sponsored deal")
                }

                HStack(alignment: .top, spacing: 12) {
                    AsyncImage(url: recommendation.deal.imageURL) { phase in
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
                        Text(recommendation.deal.title)
                            .font(BrandTheme.font(17, weight: .semibold, relativeTo: .headline))
                            .foregroundStyle(BrandTheme.ink)
                            .accessibilityLabel("Product title, \(recommendation.deal.title)")

                        Text("\(formattedPrice) • \(recommendation.deal.shipping)")
                            .font(BrandTheme.font(14, weight: .medium, relativeTo: .subheadline))
                            .foregroundStyle(BrandTheme.mutedInk)
                            .accessibilityLabel("Price \(formattedPrice). Shipping \(recommendation.deal.shipping)")

                        Text("Source: \(recommendation.deal.source)")
                            .font(BrandTheme.font(12, weight: .regular, relativeTo: .caption))
                            .foregroundStyle(BrandTheme.mutedInk)
                            .accessibilityLabel("Source \(recommendation.deal.source)")
                    }
                }

                Text(recommendation.reasoning)
                    .font(BrandTheme.font(13, weight: .regular, relativeTo: .caption))
                    .foregroundStyle(BrandTheme.mutedInk)
                    .accessibilityLabel("Reasoning, \(recommendation.reasoning)")

                Text("Rank score: \(formattedScore)")
                    .font(BrandTheme.font(12, relativeTo: .caption2))
                    .foregroundStyle(BrandTheme.ink)
                    .accessibilityLabel("Ranking score \(formattedScore)")

                Text(recommendation.score.reasons.joined(separator: " · "))
                    .font(BrandTheme.font(12, relativeTo: .caption2))
                    .foregroundStyle(BrandTheme.mutedInk)
                    .accessibilityLabel("Score explanation, \(recommendation.score.reasons.joined(separator: ", "))")

                Button(action: onViewDeal) {
                    Text("View Deal")
                }
                .buttonStyle(BrandPrimaryButtonStyle())
                .accessibilityLabel("View deal")

                HStack(spacing: 8) {
                    Button(isFavorite ? "Saved" : "Save") {
                        onToggleFavorite()
                    }
                    .buttonStyle(BrandSecondaryButtonStyle())
                    .tint(isFavorite ? BrandTheme.accentBubble : BrandTheme.accentSky)
                    .accessibilityLabel(isFavorite ? "Remove from favorites" : "Save to favorites")

                    Button(isCompared ? "Compared" : "Compare") {
                        onToggleCompare()
                    }
                    .buttonStyle(BrandSecondaryButtonStyle())
                    .tint(isCompared ? BrandTheme.accentMint : BrandTheme.accentSky)
                    .accessibilityLabel(isCompared ? "Remove from compare" : "Add to compare")
                }
            }
        }
    }

    private var formattedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = recommendation.deal.currency
        return formatter.string(from: recommendation.deal.price as NSDecimalNumber) ?? "$0"
    }

    private var formattedScore: String {
        String(format: "%.0f%%", recommendation.score.totalScore * 100)
    }
}
