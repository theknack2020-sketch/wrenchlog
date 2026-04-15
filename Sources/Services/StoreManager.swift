import Foundation
import OSLog
import StoreKit

@Observable @MainActor
final class StoreManager {
    static let shared = StoreManager()

    static let yearlyID = "com.theknack.wrenchlog.pro.yearly"
    static let lifetimeID = "com.theknack.wrenchlog.pro.lifetime"

    private(set) var isPro = false
    private(set) var products: [Product] = []
    private(set) var isLoading = true
    private(set) var loadError: String?

    private init() {
        Task { await loadProducts() }
        Task { await checkEntitlements() }
        Task { await listenForTransactions() }
    }

    #if DEBUG
        /// Sticky flag that prevents `checkEntitlements()` from overriding `isPro`.
        /// ⚠️ DEBUG-ONLY — never included in Release builds.
        private var screenshotProOverride = false

        /// Override Pro state for App Store screenshot capture.
        /// ⚠️ DEBUG-ONLY — never included in Release builds.
        func setProForScreenshots(_ value: Bool) {
            screenshotProOverride = value
            isPro = value
        }
    #endif

    func loadProducts() async {
        loadError = nil
        do {
            products = try await Product.products(for: [Self.yearlyID, Self.lifetimeID])
            if products.isEmpty {
                loadError = "No products available"
            }
        } catch {
            loadError = "Failed to load products. Check your connection."
            Logger.store.error("Product load failed: \(error)")
        }
        isLoading = false
    }

    func checkEntitlements() async {
        #if DEBUG
            // Screenshot override: skip entitlement check if sticky flag is set
            if screenshotProOverride { return }
        #endif

        var foundPro = false
        for await result in Transaction.currentEntitlements {
            guard case let .verified(transaction) = result else { continue }
            if transaction.productID == Self.lifetimeID || transaction.productID == Self.yearlyID {
                if transaction.revocationDate == nil {
                    foundPro = true
                }
            }
        }
        isPro = foundPro
    }

    private func listenForTransactions() async {
        for await result in Transaction.updates {
            guard case let .verified(transaction) = result else { continue }
            await transaction.finish()
            await checkEntitlements()
        }
    }

    func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()
        switch result {
        case let .success(verification):
            guard case let .verified(transaction) = verification else { return false }
            await transaction.finish()
            await checkEntitlements()
            TelemetryService.purchaseCompleted(product: product.id)
            return true
        case .pending, .userCancelled:
            return false
        @unknown default:
            return false
        }
    }

    func restorePurchases() async -> Bool {
        do {
            try await AppStore.sync()
            await checkEntitlements()
            return isPro
        } catch {
            Logger.store.error("Restore failed: \(error)")
            return false
        }
    }

    var yearlyProduct: Product? {
        products.first { $0.id == Self.yearlyID }
    }

    var lifetimeProduct: Product? {
        products.first { $0.id == Self.lifetimeID }
    }
}
