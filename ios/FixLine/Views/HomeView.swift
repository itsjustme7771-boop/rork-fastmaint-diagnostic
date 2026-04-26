import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Equipment.name) private var equipment: [Equipment]
    @Query(sort: \DiagnosticSession.createdAt, order: .reverse) private var sessions: [DiagnosticSession]

    @State private var showingScanner = false
    @State private var showingFaultCode = false
    @State private var pendingDiagnosis: PendingDiagnosis?

    @Environment(NetworkMonitor.self) private var network

    struct PendingDiagnosis: Identifiable {
        let id = UUID()
        let symptom: String
        let equipment: Equipment?
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    headerCard
                    quickFaultsSection
                    recentEquipmentSection
                    recentSessionsSection
                }
                .padding(16)
                .padding(.bottom, 24)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("FixLine")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingFaultCode = true
                    } label: {
                        Image(systemName: "number.square.fill")
                            .font(.title3)
                            .foregroundStyle(Theme.primary)
                    }
                }
            }
            .sheet(isPresented: $showingScanner) {
                ScannerView { code in
                    showingScanner = false
                    handleScannedCode(code)
                }
            }
            .sheet(isPresented: $showingFaultCode) {
                FaultCodeView()
            }
            .sheet(item: $pendingDiagnosis) { p in
                NavigationStack {
                    DiagnosticSessionView(symptom: p.symptom, equipment: p.equipment)
                }
            }
        }
    }

    private var headerCard: some View {
        VStack(spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("DIAGNOSE")
                        .font(.caption.weight(.heavy))
                        .tracking(2)
                        .foregroundStyle(Theme.textTertiary)
                    Text("Down? Scan it.")
                        .font(.title.weight(.heavy))
                        .foregroundStyle(Theme.textPrimary)
                }
                Spacer()
                AIModeBadge(mode: network.isOnline ? .online : .offline)
            }

            Button {
                Haptics.tap()
                showingScanner = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "qrcode.viewfinder")
                        .font(.title2.weight(.bold))
                    Text("Scan Equipment QR")
                }
            }
            .buttonStyle(PrimaryButtonStyle())

            Button {
                Haptics.tap()
                pendingDiagnosis = .init(symptom: "General fault — describe in chat", equipment: nil)
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "wrench.and.screwdriver.fill")
                    Text("Start without equipment")
                }
            }
            .buttonStyle(SecondaryButtonStyle())
        }
        .cardStyle()
    }

    private var quickFaultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("QUICK FAULTS", symbol: "bolt.fill")
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                ForEach(SeedData.quickFaults) { fault in
                    Button {
                        Haptics.tap()
                        pendingDiagnosis = .init(symptom: fault.prompt, equipment: nil)
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: fault.symbol)
                                .font(.title2.weight(.bold))
                                .foregroundStyle(Theme.primary)
                                .frame(height: 28)
                            Text(fault.label)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Theme.textPrimary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .minimumScaleFactor(0.85)
                        }
                        .frame(maxWidth: .infinity, minHeight: 88)
                        .padding(12)
                        .background(Theme.surface)
                        .clipShape(.rect(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.stroke, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var recentEquipmentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionTitle("EQUIPMENT", symbol: "gearshape.2.fill")
                Spacer()
                NavigationLink {
                    EquipmentLibraryView()
                } label: {
                    Text("All")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Theme.primary)
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(equipment.prefix(6))) { eq in
                        NavigationLink(value: eq) {
                            equipmentChip(eq)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .contentMargins(.horizontal, 0)
            .navigationDestination(for: Equipment.self) { eq in
                EquipmentDetailView(equipment: eq)
            }
        }
    }

    private func equipmentChip(_ eq: Equipment) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: eq.kind.symbol)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Theme.primary)
                Spacer()
                Circle().fill(eq.status.color).frame(width: 8, height: 8)
            }
            Text(eq.name)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1)
            Text(eq.id)
                .font(.caption.monospaced())
                .foregroundStyle(Theme.textTertiary)
            Text(eq.line)
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
                .lineLimit(1)
        }
        .padding(12)
        .frame(width: 170, height: 120, alignment: .topLeading)
        .background(Theme.surface)
        .clipShape(.rect(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.stroke, lineWidth: 1))
    }

    private var recentSessionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionTitle("RECENT DIAGNOSES", symbol: "clock.fill")
                Spacer()
                NavigationLink {
                    HistoryView()
                } label: {
                    Text("All")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Theme.primary)
                }
            }
            if sessions.isEmpty {
                EmptyStateView(
                    symbol: "stethoscope",
                    title: "No diagnoses yet",
                    message: "Scan a machine or tap a quick fault to start."
                )
                .cardStyle()
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(sessions.prefix(4))) { s in
                        NavigationLink {
                            SessionReadView(session: s)
                        } label: {
                            SessionRow(session: s)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func sectionTitle(_ text: String, symbol: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.caption.weight(.bold))
                .foregroundStyle(Theme.primary)
            Text(text)
                .font(.caption.weight(.heavy))
                .tracking(1.5)
                .foregroundStyle(Theme.textSecondary)
        }
    }

    private func handleScannedCode(_ code: String) {
        let trimmed = code.trimmingCharacters(in: .whitespaces).uppercased()
        if let match = equipment.first(where: { $0.id.uppercased() == trimmed || $0.id == code }) {
            pendingDiagnosis = .init(symptom: "Describe the issue with this equipment.", equipment: match)
        } else {
            pendingDiagnosis = .init(symptom: "Equipment scanned: \(code). Describe the issue.", equipment: nil)
        }
    }
}

enum Haptics {
    static func tap() {
        #if canImport(UIKit)
        let g = UIImpactFeedbackGenerator(style: .medium)
        g.impactOccurred()
        #endif
    }
    static func success() {
        #if canImport(UIKit)
        let g = UINotificationFeedbackGenerator()
        g.notificationOccurred(.success)
        #endif
    }
    static func warning() {
        #if canImport(UIKit)
        let g = UINotificationFeedbackGenerator()
        g.notificationOccurred(.warning)
        #endif
    }
}
