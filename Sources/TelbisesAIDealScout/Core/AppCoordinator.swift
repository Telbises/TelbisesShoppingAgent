import Foundation
import AuthenticationServices

@MainActor
final class AppCoordinator: ObservableObject {
    struct AuthSession: Hashable {
        let provider: AuthProvider
        let displayName: String
        let email: String?
    }

    enum AuthProvider: String, Hashable {
        case apple
        case google
        case email
    }

    let services: ServiceContainer
    let cartViewModel: CartViewModel
    let chatViewModel: HomeChatViewModel
    @Published private(set) var authSession: AuthSession?
    @Published var authErrorMessage: String?

    private let sessionStore = AuthSessionStore()

    init() {
        self.services = ServiceContainer()
        self.cartViewModel = CartViewModel(cartService: services.cartService)
        self.chatViewModel = HomeChatViewModel(agent: services.shoppingAgent)
        self.authSession = sessionStore.load()
    }

    var isAuthenticated: Bool {
        authSession != nil
    }

    func signInWithApple(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let credentials = authorization.credential as? ASAuthorizationAppleIDCredential else {
                authErrorMessage = "Apple Sign-In returned invalid credentials."
                return
            }

            let firstName = credentials.fullName?.givenName ?? ""
            let lastName = credentials.fullName?.familyName ?? ""
            let fullName = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespacesAndNewlines)
            let email = credentials.email
            let fallbackName = email?.components(separatedBy: "@").first ?? "Apple User"
            let displayName = fullName.isEmpty ? fallbackName : fullName
            setSession(AuthSession(provider: .apple, displayName: displayName, email: email))
        case .failure(let error):
            authErrorMessage = error.localizedDescription
        }
    }

    func signInWithGoogle() {
        // Extension point: replace with real Google OAuth in a backend-auth flow.
        setSession(AuthSession(provider: .google, displayName: "Google User", email: nil))
    }

    func signInWithEmail(_ email: String) {
        let normalized = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard isValidEmail(normalized) else {
            authErrorMessage = "Enter a valid email address."
            return
        }
        let displayName = normalized.components(separatedBy: "@").first?.capitalized ?? "Email User"
        setSession(AuthSession(provider: .email, displayName: displayName, email: normalized))
    }

    func signOut() {
        authSession = nil
        authErrorMessage = nil
        sessionStore.clear()
    }

    private func setSession(_ session: AuthSession) {
        authSession = session
        authErrorMessage = nil
        sessionStore.save(session)
    }

    private func isValidEmail(_ value: String) -> Bool {
        let pattern = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return value.range(of: pattern, options: .regularExpression) != nil
    }
}

enum AppRoute: Hashable {
    case results(ResultsPayload)
    case telbisesDetail(TelbisesProduct)
    case cart
}

private struct AuthSessionStore {
    private let providerKey = "auth.provider"
    private let displayNameKey = "auth.displayName"
    private let emailKey = "auth.email"
    private let defaults = UserDefaults.standard

    func save(_ session: AppCoordinator.AuthSession) {
        defaults.set(session.provider.rawValue, forKey: providerKey)
        defaults.set(session.displayName, forKey: displayNameKey)
        defaults.set(session.email, forKey: emailKey)
    }

    func load() -> AppCoordinator.AuthSession? {
        guard let providerRaw = defaults.string(forKey: providerKey),
              let provider = AppCoordinator.AuthProvider(rawValue: providerRaw),
              let displayName = defaults.string(forKey: displayNameKey) else {
            return nil
        }
        let email = defaults.string(forKey: emailKey)
        return AppCoordinator.AuthSession(provider: provider, displayName: displayName, email: email)
    }

    func clear() {
        defaults.removeObject(forKey: providerKey)
        defaults.removeObject(forKey: displayNameKey)
        defaults.removeObject(forKey: emailKey)
    }
}
