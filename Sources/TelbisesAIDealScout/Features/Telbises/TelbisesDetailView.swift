import SwiftUI

struct TelbisesDetailView: View {
    @ObservedObject var viewModel: TelbisesDetailViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                AsyncImage(url: viewModel.product.imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        RoundedRectangle(cornerRadius: 14)
                            .fill(BrandTheme.backgroundSoft)
                            .overlay(Image(systemName: "photo").font(.largeTitle).foregroundStyle(BrandTheme.mutedInk))
                    }
                }
                .frame(height: 260)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(BrandTheme.border, lineWidth: 1)
                )
                .accessibilityHidden(true)

                Text(viewModel.product.title)
                    .font(BrandTheme.font(26, weight: .bold, relativeTo: .title2))
                    .foregroundStyle(BrandTheme.ink)
                    .accessibilityLabel("Product title, \(viewModel.product.title)")

                Text(viewModel.product.description)
                    .font(BrandTheme.font(15, relativeTo: .body))
                    .foregroundStyle(BrandTheme.mutedInk)
                    .accessibilityLabel("Description, \(viewModel.product.description)")

                BrandCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Select Variant")
                            .font(BrandTheme.font(15, weight: .semibold, relativeTo: .headline))
                            .foregroundStyle(BrandTheme.ink)

                        Picker("Variant", selection: $viewModel.selectedVariant) {
                            ForEach(viewModel.availableVariants) { variant in
                                Text(variant.inStock ? variant.title : "\(variant.title) (out of stock)")
                                    .tag(variant)
                            }
                        }
                        .pickerStyle(.segmented)
                        .accessibilityLabel("Select variant")

                        Stepper("Quantity: \(viewModel.quantity)", value: $viewModel.quantity, in: 1...5)
                            .font(BrandTheme.font(14, relativeTo: .body))
                            .accessibilityLabel("Quantity \(viewModel.quantity)")

                        Button("Add to Cart") {
                            viewModel.addToCart()
                        }
                        .buttonStyle(BrandPrimaryButtonStyle())
                        .accessibilityLabel("Add to cart")

                        Button("Checkout on Shopify") {
                            viewModel.showCheckout = true
                        }
                        .buttonStyle(BrandSecondaryButtonStyle())
                        .accessibilityLabel("Checkout on Shopify")
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
        .navigationTitle("Telbises")
        .sheet(isPresented: $viewModel.showCheckout) {
            SafariView(url: viewModel.checkoutURL())
        }
    }
}
