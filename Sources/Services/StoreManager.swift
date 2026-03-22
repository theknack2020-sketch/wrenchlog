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

    private init() {
        Task { await loadProducts() }
        Task { await checkEntitlements() }
        Task { await listenForTransactions() }
    }

    func loadProducts() async {
        do {
            products = try await Product.products(for: [Self.yearlyID, Self.lifetimeID])
        } catch {
            print("[WrenchLog] Failed to load products: \(error)")
        }
        isLoading = false
    }

    func checkEntitlements() async {
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if transaction.productID == Self.lifetimeID || transaction.productID == Self.yearlyID {
                isPro = true
                return
            }
        }
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
            isPro = true
            return true
        case .pending, .userCancelled:
            return false
        @unknown default:
            return false
        }
    }

    func restorePurchases() async {
        try? await AppStore.sync()
        await checkEntitlements()
    }

    var yearlyProduct: Product? { products.first { $0.id == Self.yearlyID } }
    var lifetimeProduct: Product? { products.first { $0.id == Self.lifetimeID } }
}
