import Foundation
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

    func loadProducts() async {
        loadError = nil
        do {
            products = try await Product.products(for: [Self.yearlyID, Self.lifetimeID])
            if products.isEmpty {
                loadError = "No products available"
            }
        } catch {
            loadError = "Failed to load products. Check your connection."
            print("[WrenchLog] Product load error: \(error)")
        }
        isLoading = false
    }

    func checkEntitlements() async {
        var foundPro = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
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
            guard case .verified(let transaction) = result else { continue }
            await transaction.finish()
            await checkEntitlements()
        }
    }

    func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            guard case .verified(let transaction) = verification else { return false }
            await transaction.finish()
            await checkEntitlements()
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
            print("[WrenchLog] Restore error: \(error)")
            return false
        }
    }

    var yearlyProduct: Product? { products.first { $0.id == Self.yearlyID } }
    var lifetimeProduct: Product? { products.first { $0.id == Self.lifetimeID } }
}
