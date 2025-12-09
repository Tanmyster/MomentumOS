import SwiftUI
import StoreKit

// MARK: - Subscription Manager (StoreKit 2)
@MainActor
class SubscriptionManager: NSObject, ObservableObject {
    static let shared = SubscriptionManager()
    
    @Published var isPremium = false
    @Published var subscriptionProduct: Product?
    @Published var isLoadingProducts = false
    @Published var subscriptionStatus: SubscriptionStatus = .free
    @Published var availableProducts: [Product] = []
    
    private var updateListenerTask: Task<Void, Error>?
    
    override init() {
        super.init()
        setupSubscriptionListener()
        loadProducts()
    }
    
    func loadProducts() async {
        isLoadingProducts = true
        defer { isLoadingProducts = false }
        
        do {
            let allProducts = try await Product.products(for: [
                "com.momentumos.premium.monthly",
                "com.momentumos.premium.yearly"
            ])
            
            await MainActor.run {
                self.availableProducts = allProducts
            }
        } catch {
            print("Failed to load products: \(error)")
        }
    }
    
    func purchaseSubscription(_ product: Product) async {
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                
                await MainActor.run {
                    self.isPremium = true
                    self.subscriptionStatus = .premium
                    self.subscriptionProduct = product
                    UserDefaults.standard.set(Date().addingTimeInterval(30*24*60*60), forKey: "momentumOS.premiumExpiry")
                }
            case .userCancelled:
                print("User cancelled purchase")
            case .pending:
                print("Purchase pending")
            @unknown default:
                print("Unknown purchase result")
            }
        } catch {
            print("Purchase failed: \(error)")
        }
    }
    
    func restorePurchases() async {
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                if transaction.isActive {
                    await MainActor.run {
                        self.isPremium = true
                        self.subscriptionStatus = .premium
                    }
                }
                
                await transaction.finish()
            } catch {
                print("Restore failed: \(error)")
            }
        }
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(let unverifiedValue, let signatureError):
            print("Verification failed: \(signatureError)")
            throw SubscriptionError.verificationFailed
        case .verified(let verifiedValue):
            return verifiedValue
        }
    }
    
    private func setupSubscriptionListener() {
        updateListenerTask = detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    
                    await MainActor.run {
                        if transaction.isActive {
                            self.isPremium = true
                            self.subscriptionStatus = .premium
                        } else {
                            self.isPremium = false
                            self.subscriptionStatus = .free
                        }
                    }
                    
                    await transaction.finish()
                } catch {
                    print("Subscription listener error: \(error)")
                }
            }
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
}

enum SubscriptionStatus: String, Codable {
    case free = "free"
    case premium = "premium"
    case trial = "trial"
}

enum SubscriptionError: LocalizedError {
    case verificationFailed
    
    var errorDescription: String? {
        "Transaction verification failed"
    }
}

// MARK: - Paywall View
struct PaywallView: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var selectedProduct: Product?
    @State private var showingPurchaseFlow = false
    
    var body: some View {
        VStack(spacing: MomentumDesignTokens.lg) {
            // Header
            VStack(alignment: .leading, spacing: MomentumDesignTokens.md) {
                Text("Unlock Premium")
                    .momentumTitle()
                
                Text("Get access to AI-powered coaching and advanced insights")
                    .momentumSubtitle()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(MomentumDesignTokens.lg)
            
            // Features
            VStack(alignment: .leading, spacing: MomentumDesignTokens.md) {
                FeatureRow(icon: "sparkles", text: "AI Life Coach")
                FeatureRow(icon: "chart.line.uptrend.xyaxis", text: "Advanced Analytics")
                FeatureRow(icon: "book.fill", text: "Academy Content")
                FeatureRow(icon: "doc.fill", text: "PDF Reports")
                FeatureRow(icon: "person.2.fill", text: "Social Features")
            }
            .padding(MomentumDesignTokens.lg)
            
            Spacer()
            
            // Product Selection
            VStack(spacing: MomentumDesignTokens.md) {
                if subscriptionManager.isLoadingProducts {
                    ProgressView()
                } else {
                    ForEach(subscriptionManager.availableProducts, id: \.id) { product in
                        ProductCard(
                            product: product,
                            isSelected: selectedProduct?.id == product.id,
                            onSelect: { selectedProduct = product }
                        )
                    }
                }
            }
            .padding(MomentumDesignTokens.lg)
            
            // Purchase Button
            if let selectedProduct = selectedProduct {
                Button(action: {
                    Task {
                        await subscriptionManager.purchaseSubscription(selectedProduct)
                    }
                }) {
                    Text("Subscribe Now")
                }
                .momentumButton()
                .padding(MomentumDesignTokens.md)
                
                Button(action: {
                    Task {
                        await subscriptionManager.restorePurchases()
                    }
                }) {
                    Text("Restore Purchases")
                }
                .momentumSecondaryButton()
                .padding(MomentumDesignTokens.md)
            }
        }
    }
}

struct ProductCard: View {
    let product: Product
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: MomentumDesignTokens.sm) {
            HStack {
                VStack(alignment: .leading, spacing: MomentumDesignTokens.xs) {
                    Text(product.displayName)
                        .font(MomentumDesignTokens.bodyMedium)
                        .fontWeight(.semibold)
                    
                    Text(product.description)
                        .font(MomentumDesignTokens.bodySmall)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: MomentumDesignTokens.xs) {
                    Text(product.displayPrice)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(MomentumColors.primary)
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(MomentumColors.success)
                    }
                }
            }
        }
        .padding(MomentumDesignTokens.md)
        .momentumCard()
        .onTapGesture(perform: onSelect)
        .border(isSelected ? MomentumColors.primary : Color.clear, width: 2)
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: MomentumDesignTokens.md) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(MomentumColors.primary)
                .frame(width: 24)
            
            Text(text)
                .font(MomentumDesignTokens.bodyMedium)
            
            Spacer()
        }
    }
}

// MARK: - Premium Feature Lock
struct PremiumFeatureGate<Content: View>: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    
    let content: Content
    let fallbackMessage: String
    
    init(_ fallbackMessage: String = "This feature requires premium", @ViewBuilder content: () -> Content) {
        self.fallbackMessage = fallbackMessage
        self.content = content()
    }
    
    var body: some View {
        if subscriptionManager.isPremium {
            content
        } else {
            VStack(spacing: MomentumDesignTokens.md) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 32))
                    .foregroundColor(MomentumColors.primary)
                
                Text(fallbackMessage)
                    .font(MomentumDesignTokens.bodyMedium)
                    .multilineTextAlignment(.center)
                
                Button(action: {}) {
                    Text("Upgrade to Premium")
                }
                .momentumButton()
            }
            .padding(MomentumDesignTokens.lg)
        }
    }
}
