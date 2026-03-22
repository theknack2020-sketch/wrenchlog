import SwiftUI
import StoreKit

struct ProUpgradeView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var purchasing = false
    @State private var error: String?
    private let store = StoreManager.shared

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
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

                        VStack(alignment: .leading, spacing: 16) {
                            feature(icon: "car.2.fill", title: "Unlimited Vehicles", desc: "Track your whole garage — cars, bikes, trucks")
                            feature(icon: "camera.fill", title: "Photo Attachments", desc: "Snap receipts and attach to service records")
                            feature(icon: "doc.text.fill", title: "PDF Export", desc: "Professional service history for resale value")
                            feature(icon: "chart.bar.fill", title: "Advanced Analytics", desc: "Cost breakdown, trends, spending insights")
                            feature(icon: "tag.fill", title: "Custom Categories", desc: "Create your own service types and categories")
                            feature(icon: "nosign", title: "No Ads — Free or Pro", desc: "WrenchLog never shows ads. Period.")
                        }
                        .padding(.horizontal, 24)

                        // Products
                        if store.isLoading {
                            ProgressView().padding()
                        } else {
                            VStack(spacing: 12) {
                                if let lifetime = store.lifetimeProduct {
                                    productButton(product: lifetime, label: "Lifetime", sublabel: "One-time purchase", recommended: true)
                                }
                                if let yearly = store.yearlyProduct {
                                    productButton(product: yearly, label: "Yearly", sublabel: "Billed annually", recommended: false)
                                }
                            }
                            .padding(.horizontal, 24)
                        }

                        if let err = error {
                            Text(err).font(.caption).foregroundStyle(.red)
                        }

                        Button("Restore Purchases") {
                            Task {
                                await store.restorePurchases()
                                if store.isPro { dismiss() }
                            }
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                        Text("Your data stays on your device. We don't sell your vehicle information to anyone.")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)
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

    private func feature(icon: String, title: String, desc: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.wrenchAmber)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(desc).font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private func productButton(product: Product, label: String, sublabel: String, recommended: Bool) -> some View {
        Button {
            Task {
                purchasing = true
                error = nil
                do {
                    let ok = try await store.purchase(product)
                    if ok { dismiss() }
                } catch {
                    self.error = "Purchase failed"
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
