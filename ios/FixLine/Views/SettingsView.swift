import SwiftUI

struct SettingsView: View {
    @Environment(AuthManager.self) private var auth
    @Environment(StoreManager.self) private var store
    @Environment(NetworkMonitor.self) private var network

    @AppStorage("ai.mode") private var aiModeRaw: String = AIMode.auto.rawValue
    @AppStorage("user.role") private var roleRaw: String = UserRole.technician.rawValue

    @State private var showPaywall = false

    private var role: UserRole { UserRole(rawValue: roleRaw) ?? .technician }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if let user = auth.user {
                        accountCard(user: user)
                        subscriptionCard
                        if role == .lead || role == .management {
                            managementCard
                        }
                    }
                    aiCard
                    statusCard
                    aboutCard
                }
                .padding(16)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    // MARK: - Account

    private func accountCard(user: AuthManager.User) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("ACCOUNT")
                .font(.caption.weight(.heavy))
                .tracking(2)
                .foregroundStyle(Theme.textTertiary)

            HStack(spacing: 12) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Theme.primary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(user.name ?? user.email)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Theme.textPrimary)
                    if user.name != nil {
                        Text(user.email)
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                Spacer()
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("ROLE TIER")
                    .font(.caption.weight(.heavy))
                    .tracking(1)
                    .foregroundStyle(Theme.textTertiary)
                Menu {
                    ForEach(UserRole.allCases) { r in
                        Button {
                            Haptics.tap()
                            roleRaw = r.rawValue
                        } label: {
                            Label(r.label, systemImage: r.symbol)
                        }
                    }
                } label: {
                    HStack {
                        Label(role.label, systemImage: role.symbol)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(Theme.onPrimary)
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Theme.onPrimary)
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 44)
                    .background(Theme.primary)
                    .clipShape(.rect(cornerRadius: 10))
                }
                Text(role.description)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }

            Button {
                Haptics.warning()
                Task { await auth.signOut() }
            } label: {
                Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
            }
            .buttonStyle(SecondaryButtonStyle())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    // MARK: - Subscription

    private var subscriptionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SUBSCRIPTION")
                .font(.caption.weight(.heavy))
                .tracking(2)
                .foregroundStyle(Theme.textTertiary)

            HStack {
                Label(store.tier.label + " Plan", systemImage: store.tier.symbol)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                StatusPill(text: store.tier.label, color: store.tier.color, symbol: "checkmark.seal.fill")
            }

            if store.tier == .free {
                Text("Unlock unlimited AI diagnoses, cloud reasoning, and vibration analysis.")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }

            if store.tier != .free {
                Button {
                    Haptics.tap()
                    showPaywall = true
                } label: {
                    Text("Compare Plans")
                }
                .buttonStyle(SecondaryButtonStyle())
            } else {
                Button {
                    Haptics.tap()
                    showPaywall = true
                } label: {
                    Label("Upgrade", systemImage: "bolt.crown.fill")
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    // MARK: - Lead / Management tools

    private var managementCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("LEAD TOOLS")
                .font(.caption.weight(.heavy))
                .tracking(2)
                .foregroundStyle(Theme.textTertiary)
            comingRow("doc.fill", "Manual uploads", "Upload PDFs and documents the AI reads during diagnosis.")
            comingRow("tray.full.fill", "Review unresolved", "See open diagnoses across the crew and close them out.")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func comingRow(_ symbol: String, _ title: String, _ subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.title3.weight(.bold))
                .foregroundStyle(Theme.primary)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.bold)).foregroundStyle(Theme.textPrimary)
                Text(subtitle).font(.caption).foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            StatusPill(text: "Soon", color: Theme.textSecondary)
        }
        .padding(10)
        .background(Theme.surfaceElevated)
        .clipShape(.rect(cornerRadius: 10))
    }

    // MARK: - AI mode

    private var aiCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AI MODE")
                .font(.caption.weight(.heavy))
                .tracking(2)
                .foregroundStyle(Theme.textTertiary)
            VStack(spacing: 8) {
                ForEach(AIMode.allCases, id: \.self) { mode in
                    Button {
                        Haptics.tap()
                        aiModeRaw = mode.rawValue
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(mode.label)
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(Theme.textPrimary)
                                Text(description(for: mode))
                                    .font(.caption)
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            Spacer()
                            if aiModeRaw == mode.rawValue {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(Theme.primary)
                            } else {
                                Image(systemName: "circle")
                                    .font(.title3)
                                    .foregroundStyle(Theme.textTertiary)
                            }
                        }
                        .padding(12)
                        .background(Theme.surfaceElevated)
                        .clipShape(.rect(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func description(for mode: AIMode) -> String {
        switch mode {
        case .auto: return "Cloud when online, on-device when offline."
        case .online: return "Always cloud — best diagnostic quality."
        case .offline: return "Always on-device — works without network."
        }
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("STATUS")
                .font(.caption.weight(.heavy))
                .tracking(2)
                .foregroundStyle(Theme.textTertiary)
            HStack {
                Image(systemName: network.isOnline ? "wifi" : "wifi.slash")
                    .foregroundStyle(network.isOnline ? Theme.success : Theme.danger)
                Text(network.isOnline ? "Online" : "Offline")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                StatusPill(
                    text: network.isOnline ? "Cloud Ready" : "On-Device Only",
                    color: network.isOnline ? Theme.info : Theme.primary
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var aboutCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("FixLine")
                .font(.headline.weight(.heavy))
                .foregroundStyle(Theme.textPrimary)
            Text("Industrial maintenance diagnostic engine. Reduce MTTR. Keep techs safe.")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
            Text("v1.1")
                .font(.caption.monospaced())
                .foregroundStyle(Theme.textTertiary)
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}
