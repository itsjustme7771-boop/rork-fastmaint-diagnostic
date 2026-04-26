import SwiftUI

struct SettingsView: View {
    @AppStorage("ai.mode") private var aiModeRaw: String = AIMode.auto.rawValue
    @AppStorage("haptics.enabled") private var hapticsEnabled: Bool = true
    @Environment(NetworkMonitor.self) private var network

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    aiCard
                    statusCard
                    upcomingCard
                    aboutCard
                }
                .padding(16)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Settings")
        }
    }

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

    private var upcomingCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("COMING NEXT")
                .font(.caption.weight(.heavy))
                .tracking(2)
                .foregroundStyle(Theme.textTertiary)
            row("person.crop.circle.badge.checkmark", "Login & user tiers", "Technician / Lead / Management roles.")
            row("creditcard.fill", "Subscription tiers", "Basic $9.99 • Advanced $24.99 • Premium $54.99.")
            row("doc.fill", "Manual uploads", "Leads upload PDFs the AI reads in diagnoses.")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func row(_ symbol: String, _ title: String, _ subtitle: String) -> some View {
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
        }
        .padding(10)
        .background(Theme.surfaceElevated)
        .clipShape(.rect(cornerRadius: 10))
    }

    private var aboutCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("FixLine")
                .font(.headline.weight(.heavy))
                .foregroundStyle(Theme.textPrimary)
            Text("Industrial maintenance diagnostic engine. Reduce MTTR. Keep techs safe.")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
            Text("v1.0")
                .font(.caption.monospaced())
                .foregroundStyle(Theme.textTertiary)
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}
