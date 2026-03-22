import SwiftUI

struct SettingsView: View {
    @State private var distanceUnit = UserSettings.shared.distanceUnit
    @State private var currency = UserSettings.shared.currency
    @State private var showPro = false
    private let store = StoreManager.shared

    var body: some View {
        Form {
            Section("Units") {
                Picker("Distance", selection: $distanceUnit) {
                    Text("Miles").tag(DistanceUnit.miles)
                    Text("Kilometers").tag(DistanceUnit.km)
                }
                .onChange(of: distanceUnit) { _, val in
                    UserSettings.shared.distanceUnit = val
                }

                Picker("Currency", selection: $currency) {
                    Text("$ USD").tag(Currency.usd)
                    Text("€ EUR").tag(Currency.eur)
                    Text("£ GBP").tag(Currency.gbp)
                    Text("₺ TRY").tag(Currency.try_)
                }
                .onChange(of: currency) { _, val in
                    UserSettings.shared.currency = val
                }
            }

            Section("Premium") {
                if store.isPro {
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                        Text("WrenchLog Pro Active")
                            .font(.subheadline.weight(.medium))
                    }
                } else {
                    Button {
                        showPro = true
                    } label: {
                        HStack {
                            Image(systemName: "crown.fill")
                                .foregroundStyle(Color.wrenchAmber)
                            VStack(alignment: .leading) {
                                Text("Upgrade to Pro")
                                    .font(.subheadline.weight(.semibold))
                                Text("Unlimited vehicles, photos, PDF export")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0").foregroundStyle(.secondary)
                }

                Link("Privacy Policy", destination: URL(string: "https://theknack2020-sketch.github.io/wrenchlog/privacy/")!)
                Link("Support", destination: URL(string: "https://theknack2020-sketch.github.io/wrenchlog/support/")!)
                Link("Terms of Use", destination: URL(string: "https://theknack2020-sketch.github.io/wrenchlog/terms/")!)
            }

            Section("More Apps") {
                Link(destination: URL(string: "https://apps.apple.com/app/lumifaste/id6760971357")!) {
                    HStack(spacing: 12) {
                        Image(systemName: "leaf.fill")
                            .foregroundStyle(.purple)
                            .frame(width: 24)
                        VStack(alignment: .leading) {
                            Text("Lumifaste").font(.subheadline.weight(.medium))
                            Text("Intermittent Fasting Tracker").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Settings")
        .sheet(isPresented: $showPro) {
            ProUpgradeView()
        }
    }
}
