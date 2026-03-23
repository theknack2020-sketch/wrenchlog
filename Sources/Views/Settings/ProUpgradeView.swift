import SwiftUI
import StoreKit

struct ProUpgradeView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var purchasing = false
    @State private var restoring = false
    @State private var error: String?
    @State private var restoreSuccess = false
    private let store = StoreManager.shared

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // MARK: - Header
                        VStack(spacing: 12) {
                            Image(systemName: "wrench.adjustable.fill")
                                .font(.system(size: 56))
                                .foregroundStyle(Color.wrenchAmber)

                            Text("WrenchLog Pro")
                                .font(.title.weight(.bold))

                            Text("Everything you need to keep\nyour vehicles in top shape")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 24)

                        // MARK: - Social Proof
                        HStack(spacing: 6) {
                            ForEach(0..<5) { _ in
                                Image(systemName: "star.fill")
                                    .font(.caption)
                                    .foregroundStyle(.yellow)
                            }
                            Text("Trusted by car enthusiasts")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        // MARK: - Feature Comparison Table
                        VStack(spacing: 0) {
                            // Header row
                            HStack {
                                Text("Feature")
                                    .font(.caption.weight(.semibold))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text("Free")
                                    .font(.caption.weight(.semibold))
                                    .frame(width: 50)
                                Text("Pro")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color.wrenchAmber)
                                    .frame(width: 50)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color(.tertiarySystemGroupedBackground))

                            comparisonRow("Vehicles", free: "1", pro: "∞")
                            comparisonRow("Service Logging", free: true, pro: true)
                            comparisonRow("Fuel Tracking", free: true, pro: true)
                            comparisonRow("Smart Reminders", free: true, pro: true)
                            comparisonRow("Receipt Photos", free: false, pro: true)
                            comparisonRow("PDF Reports", free: false, pro: true)
                            comparisonRow("Cost Analytics", free: false, pro: true)
                            comparisonRow("Custom Categories", free: false, pro: true)
                            comparisonRow("CSV Export", free: false, pro: true)
                        }
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal, 24)

                        // No ads note
                        HStack(spacing: 8) {
                            Image(systemName: "nosign")
                                .font(.caption)
                                .foregroundStyle(Color.wrenchAmber)
                            Text("WrenchLog never shows ads — Free or Pro.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        // MARK: - Products
                        if store.isLoading {
                            ProgressView().padding()
                        } else if let loadErr = store.loadError {
                            VStack(spacing: 8) {
                                Text(loadErr)
                                    .font(.caption)
                                    .foregroundStyle(.red)
                                Button("Retry") {
                                    Task { await store.loadProducts() }
                                }
                                .font(.caption.weight(.medium))
                                .foregroundStyle(Color.wrenchAmber)
                            }
                            .padding()
                        } else {
                            VStack(spacing: 12) {
                                if let lifetime = store.lifetimeProduct {
                                    productButton(
                                        product: lifetime,
                                        label: "Lifetime",
                                        sublabel: "One-time purchase • Yours forever",
                                        recommended: true
                                    )
                                }
                                if let yearly = store.yearlyProduct {
                                    productButton(
                                        product: yearly,
                                        label: "Yearly",
                                        sublabel: "Billed annually",
                                        recommended: false
                                    )
                                }

                                // Savings callout if both tiers exist
                                if let lifetime = store.lifetimeProduct,
                                   let yearly = store.yearlyProduct {
                                    savingsCallout(lifetime: lifetime, yearly: yearly)
                                }
                            }
                            .padding(.horizontal, 24)
                        }

                        // MARK: - Error / Success Feedback
                        if let err = error {
                            Text(err)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .transition(.opacity)
                        }

                        if restoreSuccess {
                            Label("Purchases restored!", systemImage: "checkmark.circle.fill")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.green)
                                .transition(.opacity)
                        }

                        // MARK: - Restore Purchases
                        Button {
                            Task {
                                restoring = true
                                error = nil
                                restoreSuccess = false
                                let success = await store.restorePurchases()
                                restoring = false
                                if success {
                                    withAnimation { restoreSuccess = true }
                                    HapticManager.shared.success()
                                    // Delay dismiss to show success feedback
                                    try? await Task.sleep(for: .seconds(1.2))
                                    dismiss()
                                } else {
                                    HapticManager.shared.warning()
                                    withAnimation {
                                        error = "No previous purchases found. If you believe this is an error, try again or contact support."
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 6) {
                                if restoring {
                                    ProgressView()
                                        .controlSize(.small)
                                }
                                Text("Restore Purchases")
                            }
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .disabled(restoring)

                        // MARK: - Privacy & Terms
                        Text("Your data stays on your device. We don't sell your vehicle information to anyone.")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        VStack(spacing: 4) {
                            Text("Subscriptions auto-renew unless cancelled at least 24 hours before the end of the current period. Payment is charged to your Apple ID account. You can manage or cancel subscriptions anytime in Settings → Apple ID → Subscriptions.")
                                .font(.caption2)
                                .foregroundStyle(.quaternary)
                                .multilineTextAlignment(.center)

                            HStack(spacing: 16) {
                                Link("Privacy Policy", destination: URL(string: "https://theknack2020-sketch.github.io/wrenchlog/privacy/")!)
                                Link("Terms of Use", destination: URL(string: "https://theknack2020-sketch.github.io/wrenchlog/terms/")!)
                            }
                            .font(.caption2)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
            .disabled(purchasing)
        }
    }

    // MARK: - Feature Comparison Row (check/cross)

    private func comparisonRow(_ feature: String, free: Bool, pro: Bool) -> some View {
        HStack {
            Text(feature)
                .font(.caption)
                .frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: free ? "checkmark" : "xmark")
                .font(.caption2.weight(.bold))
                .foregroundStyle(free ? .green : Color(.tertiaryLabel))
                .frame(width: 50)
            Image(systemName: pro ? "checkmark" : "xmark")
                .font(.caption2.weight(.bold))
                .foregroundStyle(pro ? Color.wrenchAmber : Color(.tertiaryLabel))
                .frame(width: 50)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - Feature Comparison Row (text)

    private func comparisonRow(_ feature: String, free: String, pro: String) -> some View {
        HStack {
            Text(feature)
                .font(.caption)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(free)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .frame(width: 50)
            Text(pro)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.wrenchAmber)
                .frame(width: 50)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - Savings Callout

    private func savingsCallout(lifetime: Product, yearly: Product) -> some View {
        let yearlyPrice = Double(truncating: yearly.price as NSDecimalNumber)
        let lifetimePrice = Double(truncating: lifetime.price as NSDecimalNumber)
        // If lifetime costs less than 3 years of yearly, show savings
        let yearsToBreakEven = yearlyPrice > 0 ? lifetimePrice / yearlyPrice : 0.0

        return Group {
            if yearsToBreakEven > 0 && yearsToBreakEven < 5 {
                HStack(spacing: 6) {
                    Image(systemName: "tag.fill")
                        .font(.caption2)
                        .foregroundStyle(Color.wrenchAmber)
                    Text("Lifetime pays for itself in \(String(format: "%.0f", ceil(yearsToBreakEven))) years")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(Color.wrenchAmber.opacity(0.1), in: Capsule())
            }
        }
    }

    // MARK: - Product Button

    private func productButton(product: Product, label: String, sublabel: String, recommended: Bool) -> some View {
        Button {
            Task {
                purchasing = true
                error = nil
                do {
                    let ok = try await store.purchase(product)
                    if ok {
                        HapticManager.shared.celebrate()
                        dismiss()
                    }
                } catch {
                    HapticManager.shared.error()
                    self.error = "Purchase failed. Please try again."
                }
                purchasing = false
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(label).font(.subheadline.weight(.semibold))
                        if recommended {
                            Text("BEST VALUE")
                                .font(.caption2.weight(.bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.wrenchAmber, in: Capsule())
                                .foregroundStyle(.white)
                        }
                    }
                    Text(sublabel).font(.caption).opacity(0.7)
                }
                Spacer()
                Text(product.displayPrice).font(.subheadline.weight(.bold))
            }
            .padding()
            .frame(maxWidth: .infinity)
            .foregroundStyle(recommended ? .white : .primary)
            .background(
                recommended ? AnyShapeStyle(Color.wrenchAmber) : AnyShapeStyle(Color(.tertiarySystemGroupedBackground)),
                in: RoundedRectangle(cornerRadius: 14)
            )
        }
    }
}
