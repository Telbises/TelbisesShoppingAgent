import SwiftUI
import AuthenticationServices

struct AppRootView: View {
    @StateObject private var coordinator = AppCoordinator()

    var body: some View {
        Group {
            if coordinator.isAuthenticated {
                NavigationStack {
                    HomeChatView(viewModel: coordinator.chatViewModel)
                        .navigationDestination(for: AppRoute.self) { route in
                            switch route {
                            case .results(let payload):
                                ResultsView(viewModel: ResultsViewModel(payload: payload, coordinator: coordinator))
                            case .telbisesDetail(let product):
                                TelbisesDetailView(viewModel: TelbisesDetailViewModel(product: product, coordinator: coordinator))
                            case .cart:
                                CartView(viewModel: coordinator.cartViewModel)
                            }
                        }
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Sign Out") {
                                    coordinator.signOut()
                                }
                                .accessibilityLabel("Sign out")
                            }
                        }
                }
            } else {
                LoginView(coordinator: coordinator)
            }
        }
        .tint(BrandTheme.ink)
    }
}

private struct LoginView: View {
    @ObservedObject var coordinator: AppCoordinator
    @State private var emailAddress = ""

    var body: some View {
        VStack(spacing: 18) {
            Spacer(minLength: 10)
            Text("Welcome to Telbises AI")
                .font(BrandTheme.font(30, weight: .heavy, relativeTo: .largeTitle))
                .foregroundStyle(BrandTheme.ink)
                .multilineTextAlignment(.center)

            Text("Sign in to save favorites, compare picks, and sync your shopping chat.")
                .font(BrandTheme.font(14, relativeTo: .body))
                .foregroundStyle(BrandTheme.mutedInk)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)

            SignInWithAppleButton(
                .continue,
                onRequest: { request in
                    request.requestedScopes = [.fullName, .email]
                },
                onCompletion: { result in
                    coordinator.signInWithApple(result: result)
                }
            )
            .signInWithAppleButtonStyle(.black)
            .frame(height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .padding(.top, 12)
            .accessibilityLabel("Continue with Apple")

            Button {
                coordinator.signInWithGoogle()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "globe")
                    Text("Continue With Google")
                }
                .font(BrandTheme.font(16, weight: .semibold, relativeTo: .headline))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(BrandTheme.border, lineWidth: 1)
                )
                .foregroundStyle(BrandTheme.ink)
            }
            .accessibilityLabel("Continue with Google")

            HStack(spacing: 10) {
                Rectangle()
                    .fill(BrandTheme.border)
                    .frame(height: 1)
                Text("or")
                    .font(BrandTheme.font(12, relativeTo: .caption))
                    .foregroundStyle(BrandTheme.mutedInk)
                Rectangle()
                    .fill(BrandTheme.border)
                    .frame(height: 1)
            }
            .padding(.vertical, 4)

            TextField("Email address", text: $emailAddress)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .autocorrectionDisabled()
                .font(BrandTheme.font(16, relativeTo: .body))
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(BrandTheme.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(BrandTheme.border, lineWidth: 1)
                )
                .accessibilityLabel("Email address")

            Button("Continue With Email") {
                coordinator.signInWithEmail(emailAddress)
            }
            .buttonStyle(BrandPrimaryButtonStyle())
            .disabled(emailAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .accessibilityLabel("Continue with email")

            if let error = coordinator.authErrorMessage {
                Text(error)
                    .font(BrandTheme.font(13, weight: .medium, relativeTo: .subheadline))
                    .foregroundStyle(.red)
                    .accessibilityLabel("Login error, \(error)")
            }

            Text("Google and email login are demo-ready and can be connected to real OAuth/backend auth providers.")
                .font(BrandTheme.font(12, relativeTo: .caption))
                .foregroundStyle(BrandTheme.mutedInk)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(16)
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
    }
}
