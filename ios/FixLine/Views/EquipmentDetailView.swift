import SwiftUI
import SwiftData

struct EquipmentDetailView: View {
    @Bindable var equipment: Equipment
    @State private var showingDiagnosis = false
    @State private var customSymptom: String = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                heroCard
                quickStartCard
                specsCard
                if !equipment.commonFailures.isEmpty {
                    commonFailuresCard
                }
                sessionsCard
            }
            .padding(16)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle(equipment.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingDiagnosis) {
            NavigationStack {
                DiagnosticSessionView(
                    symptom: customSymptom.isEmpty ? "Describe the issue with \(equipment.name)." : customSymptom,
                    equipment: equipment
                )
            }
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: equipment.kind.symbol)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(Theme.primary)
                    .frame(width: 64, height: 64)
                    .background(Theme.surfaceElevated)
                    .clipShape(.rect(cornerRadius: 14))
                VStack(alignment: .leading, spacing: 4) {
                    Text(equipment.id)
                        .font(.caption.monospaced().weight(.heavy))
                        .foregroundStyle(Theme.primary)
                        .tracking(1)
                    Text(equipment.kind.label)
                        .font(.title2.weight(.heavy))
                        .foregroundStyle(Theme.textPrimary)
                    Text(equipment.line)
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
            }
            HStack(spacing: 8) {
                StatusPill(text: equipment.status.label, color: equipment.status.color, symbol: equipment.status.symbol)
                Spacer()
                Text("Serviced \(equipment.lastServiced.formatted(.relative(presentation: .named)))")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .cardStyle()
    }

    private var quickStartCard: some View {
        VStack(spacing: 10) {
            HStack {
                Text("DIAGNOSE")
                    .font(.caption.weight(.heavy))
                    .tracking(2)
                    .foregroundStyle(Theme.textTertiary)
                Spacer()
            }
            TextField("Describe the issue (optional)", text: $customSymptom, axis: .vertical)
                .lineLimit(2...4)
                .padding(12)
                .background(Theme.surfaceElevated)
                .clipShape(.rect(cornerRadius: 12))
                .foregroundStyle(Theme.textPrimary)
            Button {
                Haptics.tap()
                showingDiagnosis = true
            } label: {
                HStack {
                    Image(systemName: "stethoscope")
                    Text("Start Diagnosis")
                }
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .cardStyle()
    }

    private var specsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SPECS")
                .font(.caption.weight(.heavy))
                .tracking(2)
                .foregroundStyle(Theme.textTertiary)
            specRow("Manufacturer", equipment.manufacturer)
            Divider().background(Theme.stroke)
            specRow("Model", equipment.model)
            Divider().background(Theme.stroke)
            specRow("Last serviced", equipment.lastServiced.formatted(date: .abbreviated, time: .omitted))
            if !equipment.notes.isEmpty {
                Divider().background(Theme.stroke)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notes")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Theme.textTertiary)
                    Text(equipment.notes)
                        .font(.subheadline)
                        .foregroundStyle(Theme.textPrimary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func specRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
        }
    }

    private var commonFailuresCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("COMMON FAILURES")
                .font(.caption.weight(.heavy))
                .tracking(2)
                .foregroundStyle(Theme.textTertiary)
            VStack(spacing: 8) {
                ForEach(equipment.commonFailures, id: \.self) { f in
                    Button {
                        Haptics.tap()
                        customSymptom = f
                        showingDiagnosis = true
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "bolt.fill")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Theme.primary)
                            Text(f)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Theme.textPrimary)
                            Spacer()
                            Image(systemName: "arrow.right")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Theme.textTertiary)
                        }
                        .padding(12)
                        .background(Theme.surfaceElevated)
                        .clipShape(.rect(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var sessionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("RECENT DIAGNOSES")
                .font(.caption.weight(.heavy))
                .tracking(2)
                .foregroundStyle(Theme.textTertiary)
            let recent = equipment.sessions.sorted(by: { $0.createdAt > $1.createdAt }).prefix(5)
            if recent.isEmpty {
                Text("No diagnoses yet for this machine.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(recent)) { s in
                        NavigationLink {
                            SessionReadView(session: s)
                        } label: {
                            SessionRow(session: s, hideEquipment: true)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}
