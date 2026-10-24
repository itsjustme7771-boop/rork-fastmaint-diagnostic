import SwiftUI
import RevenueCat

struct PaywallView: View {
    @Environment(StoreManager.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    header
                    tierComparison
                    packagesSection
                    legalFootnote
                }
                .padding(16)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("FixLine Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Theme.primary)
                }
            }
            .alert("Purchase error", isPresented: .init(
                get: { store.errorMessage != nil },
                set: { if !$0 { store.errorMessage = nil } }
            )) {
                Button("OK") { store.errorMessage = nil }
            } message: {
                Text(store.errorMessage ?? "")
            }
            .onChange(of: store.tier) { _, newTier in
                if newTier != .free { dismiss() }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        VStack(spacing: 10) {
            Image(systemName: "bolt.crown.fill")
                .font(.system(size: 44, weight: .black))
                .foregroundStyle(Theme.primary)
            Text("Fix faster. Downtime shorter.")
                .font(.title2.weight(.heavy))
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)
            Text("Unlimited AI diagnoses, cloud-powered reasoning, fault-code lookup, vibration analysis, and full history sync.")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
        .frame(maxWidth: .infinity)
    }

    private var tierComparison: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PLANS")
                .font(.caption.weight(.heavy))
                .tracking(2)
                .foregroundStyle(Theme.textTertiary)
            tierRow("starter", "Starter", "$5/mo or $30/yr", "Unlimited AI diagnoses, QR equipment scan, offline mode.", symbol: "bolt.fill")
            tierRow("basic", "Basic", "Team seat", "Everything in Starter plus shared diagnostics across your crew.", symbol: "bolt.badge.checkmark")
            tierRow("advanced", "Advanced", "Team seat", "Adds vibration analysis trending and priority cloud AI.", symbol: "bolt.shield.fill")
            tierRow("premium", "Premium", "Team seat", "Fleet-wide overview, manual uploads, and management dashboard.", symbol: "bolt.crown.fill")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func tierRow(_ id: String, _ name: String, _ price: String, _ detail: String, symbol: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.title3.weight(.bold))
                .foregroundStyle(Theme.primary)
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(name).font(.subheadline.weight(.heavy)).foregroundStyle(Theme.textPrimary)
                    Text(price)
                        .font(.caption.monospaced().weight(.bold))
                        .foregroundStyle(Theme.primary)
                }
                Text(detail).font(.caption).foregroundStyle(Theme.textSecondary)
            }
            Spacer()
        }
        .padding(10)
        .background(Theme.surfaceElevated)
        .clipShape(.rect(cornerRadius: 10))
    }

    private var packagesSection: some View {
        VStack(spacing: 12) {
            if store.isLoading {
                ProgressView()
                    .controlSize(.large)
                    .tint(Theme.primary)
                    .frame(height: 120)
            } else if let packages = store.offerings?.current?.availablePackages, !packages.isEmpty {
                ForEach(packages, id: \.identifier) { package in
                    packageCard(package)
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "wifi.exclamationmark")
                        .font(.title2)
                        .foregroundStyle(Theme.danger)
                    Text("Plans unavailable")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Check your connection and try again.")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                    Button {
                        Task { await store.refresh() }
                    } label: {
                        Text("Retry")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }

            Button("Restore Purchases") {
                Task { await store.restore() }
            }
            .font(.subheadline.weight(.bold))
            .foregroundStyle(Theme.primary)
            .padding(.top, 4)
        }
    }

    private func packageCard(_ package: Package) -> some View {
        let period = packageLabel(package)
        let isAnnual = period.contains("Year")

        return Button {
            Haptics.tap()
            Task { await store.purchase(package: package) }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(period)
                            .font(.headline.weight(.heavy))
                            .foregroundStyle(Theme.textPrimary)
                        if isAnnual {
                            Text("SAVE 50%")
                                .font(.caption2.weight(.black))
                                .foregroundStyle(Theme.onPrimary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Theme.success)
                                .clipShape(.capsule)
                        }
                    }
                    Text("FixLine \(package.storeProduct.localizedTitle)")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Text(package.storeProduct.localizedPriceString)
                    .font(.title3.weight(.black).monospacedDigit())
                    .foregroundStyle(Theme.primary)
            }
            .padding(16)
            .background(Theme.surface)
            .clipShape(.rect(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(isAnnual ? Theme.success.opacity(0.6) : Theme.strokeStrong, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .disabled(store.isPurchasing)
    }

    private func packageLabel(_ package: Package) -> String {
        let id = package.storeProduct.productIdentifier.lowercased()
        if id.contains("year") || id.contains("annual") { return "Yearly" }
        return "Monthly"
    }

    private var legalFootnote: some View {
        Text("Payment is charged to your Apple ID account at confirmation of purchase. Subscriptions renew automatically unless cancelled at least 24 hours before the end of the current period. Manage or cancel anytime in your App Store settings.")
            .font(.caption2)
            .foregroundStyle(Theme.textTertiary)
            .multilineTextAlignment(.center)
            .padding(.bottom, 16)
    }
}
