import SwiftUI

struct ResultsView: View {
    @ObservedObject var viewModel: ResultsViewModel
    @State private var selectedTelbisesProduct: TelbisesProduct?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                BrandCard {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("AI Summary")
                                .font(BrandTheme.font(12, weight: .semibold, relativeTo: .caption))
                                .foregroundStyle(BrandTheme.mutedInk)
                            Spacer()
                            Text("Live")
                                .font(BrandTheme.font(11, weight: .semibold, relativeTo: .caption2))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(BrandTheme.accentMint.opacity(0.20)))
                                .foregroundStyle(BrandTheme.ink)
                        }
                        Text(viewModel.payload.response.summary)
                            .font(BrandTheme.font(20, weight: .heavy, relativeTo: .title3))
                            .foregroundStyle(BrandTheme.ink)
                            .accessibilityLabel("Summary, \(viewModel.payload.response.summary)")
                        Text("Transparent score = relevance + price value + shipping + source confidence.")
                            .font(BrandTheme.font(12, relativeTo: .caption))
                            .foregroundStyle(BrandTheme.mutedInk)
                    }
                }
                .padding(.horizontal, 16)

                if !viewModel.payload.response.citations.isEmpty {
                    BrandCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Sources")
                                .font(BrandTheme.font(12, weight: .semibold, relativeTo: .caption))
                                .foregroundStyle(BrandTheme.mutedInk)
                            ForEach(Array(viewModel.payload.response.citations.prefix(5).enumerated()), id: \.element.id) { index, citation in
                                Button {
                                    viewModel.selectedURL = citation.url
                                } label: {
                                    Text("[\(index + 1)] \(citation.source): \(citation.title)")
                                        .font(BrandTheme.font(13, relativeTo: .caption))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(BrandTheme.ink)
                                .accessibilityLabel("Source \(index + 1), \(citation.source), \(citation.title)")
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }

                if let telbises = viewModel.payload.response.telbisesRecommendation {
                    TelbisesCardView(recommendation: telbises) {
                        selectedTelbisesProduct = telbises.product
                    }
                    .padding(.horizontal, 16)
                }

                ForEach(viewModel.payload.response.recommendations) { recommendation in
                    DealCardView(
                        recommendation: recommendation,
                        onViewDeal: { viewModel.openDeal(recommendation.deal) },
                        onToggleFavorite: { viewModel.toggleFavorite(recommendation.deal) },
                        onToggleCompare: { viewModel.toggleCompare(recommendation.deal) },
                        isFavorite: viewModel.isFavorite(recommendation.deal),
                        isCompared: viewModel.isCompared(recommendation.deal)
                    )
                    .padding(.horizontal, 16)
                }
            }
            .padding(.vertical, 10)
        }
        .background(
            ZStack {
                BrandTheme.heroGradient.ignoresSafeArea()
                LinearGradient(
                    colors: [BrandTheme.background.opacity(0.08), BrandTheme.background],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            }
        )
        .navigationTitle("Results")
        .sheet(item: $viewModel.selectedURL) { url in
            SafariView(url: url)
        }
        .sheet(isPresented: $viewModel.isComparePresented) {
            CompareSheetView(recommendations: viewModel.comparedRecommendations) { url in
                viewModel.selectedURL = url
            }
            .presentationDetents([.medium, .large])
        }
        .navigationDestination(item: $selectedTelbisesProduct) { product in
            TelbisesDetailView(viewModel: viewModel.makeTelbisesDetailViewModel(product: product))
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Compare (\(viewModel.comparedDealIDs.count))") {
                    viewModel.isComparePresented = true
                }
                .disabled(viewModel.comparedDealIDs.count < 2)
                .accessibilityLabel("Open compare sheet")
            }
        }
    }
}

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}

private struct CompareSheetView: View {
    let recommendations: [Recommendation]
    let onOpenURL: (URL) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(recommendations) { recommendation in
                        BrandCard {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(recommendation.deal.title)
                                    .font(BrandTheme.font(16, weight: .semibold, relativeTo: .headline))
                                Text("Price: \(formattedPrice(for: recommendation.deal))")
                                    .font(BrandTheme.font(13, relativeTo: .caption))
                                Text("Shipping: \(recommendation.deal.shipping)")
                                    .font(BrandTheme.font(13, relativeTo: .caption))
                                Text("Source: \(recommendation.deal.source)")
                                    .font(BrandTheme.font(13, relativeTo: .caption))
                                Text("Score: \(Int(recommendation.score.totalScore * 100))%")
                                    .font(BrandTheme.font(13, relativeTo: .caption))
                                Button("Open Source") {
                                    onOpenURL(recommendation.deal.dealURL)
                                }
                                .buttonStyle(BrandSecondaryButtonStyle())
                            }
                        }
                    }
                }
                .padding(16)
            }
            .navigationTitle("Compare Deals")
        }
    }

    private func formattedPrice(for deal: Deal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = deal.currency
        return formatter.string(from: deal.price as NSDecimalNumber) ?? "$0"
    }
}
