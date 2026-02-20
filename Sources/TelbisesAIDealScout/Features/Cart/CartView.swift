import SwiftUI

struct CartView: View {
    @ObservedObject var viewModel: CartViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                if viewModel.items.isEmpty {
                    BrandCard {
                        Text("Your cart is empty.")
                            .font(BrandTheme.font(16, weight: .semibold, relativeTo: .body))
                            .foregroundStyle(BrandTheme.mutedInk)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityLabel("Your cart is empty")
                    }
                } else {
                    ForEach(viewModel.items) { item in
                        BrandCard {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(item.product.title)
                                    .font(BrandTheme.font(17, weight: .semibold, relativeTo: .headline))
                                    .foregroundStyle(BrandTheme.ink)
                                    .accessibilityLabel("Product, \(item.product.title)")
                                Text("Variant: \(item.variant.title)")
                                    .font(BrandTheme.font(14, relativeTo: .subheadline))
                                    .foregroundStyle(BrandTheme.mutedInk)
                                    .accessibilityLabel("Variant \(item.variant.title)")
                                Text("Qty: \(item.quantity)")
                                    .font(BrandTheme.font(12, relativeTo: .caption))
                                    .foregroundStyle(BrandTheme.mutedInk)
                                    .accessibilityLabel("Quantity \(item.quantity)")
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("\(item.product.title), variant \(item.variant.title), quantity \(item.quantity)")
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(
            LinearGradient(
                colors: [BrandTheme.background, BrandTheme.backgroundSoft],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .navigationTitle("Cart")
        .toolbar {
            Button("Clear") {
                viewModel.clear()
            }
            .font(BrandTheme.font(14, weight: .semibold, relativeTo: .body))
            .accessibilityLabel("Clear cart")
        }
    }
}
