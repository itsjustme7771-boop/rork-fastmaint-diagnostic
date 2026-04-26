import SwiftUI
import SwiftData

struct DiagnosticSessionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @AppStorage("ai.mode") private var aiModeRaw: String = AIMode.auto.rawValue

    let initialSymptom: String
    let equipment: Equipment?

    @State private var symptom: String
    @State private var report: DiagnosticReport = .empty
    @State private var rawText: String = ""
    @State private var isLoading: Bool = false
    @State private var error: String?
    @State private var resolvedMode: AIMode = .auto
    @State private var session: DiagnosticSession?
    @State private var showInputSheet: Bool = false

    init(symptom: String, equipment: Equipment?) {
        self.initialSymptom = symptom
        self.equipment = equipment
        self._symptom = State(initialValue: symptom.hasPrefix("Describe") ? "" : symptom)
    }

    private var aiMode: AIMode { AIMode(rawValue: aiModeRaw) ?? .auto }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                contextHeader
                symptomCard

                if isLoading {
                    loadingView
                } else if let error {
                    errorCard(error)
                } else if !report.isEmpty {
                    HazardStripeBanner(title: "Safety First — Verify Zero Energy")
                    safetySection
                    causesSection
                    quickCheckSection
                    stepsSection
                    feedbackCard
                }
            }
            .padding(16)
            .padding(.bottom, 40)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Diagnosis")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                AIModeBadge(mode: resolvedMode)
            }
            ToolbarItem(placement: .topBarLeading) {
                Button("Close") { dismiss() }
                    .foregroundStyle(Theme.primary)
            }
        }
        .task {
            if !symptom.isEmpty {
                await runDiagnosis()
            }
        }
    }

    private var contextHeader: some View {
        HStack(spacing: 12) {
            if let eq = equipment {
                Image(systemName: eq.kind.symbol)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Theme.primary)
                    .frame(width: 44, height: 44)
                    .background(Theme.surfaceElevated)
                    .clipShape(.rect(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 2) {
                    Text(eq.name)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("\(eq.id) • \(eq.line)")
                        .font(.caption.monospaced())
                        .foregroundStyle(Theme.textSecondary)
                }
            } else {
                Image(systemName: "wrench.and.screwdriver.fill")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Theme.primary)
                    .frame(width: 44, height: 44)
                    .background(Theme.surfaceElevated)
                    .clipShape(.rect(cornerRadius: 10))
                Text("General diagnosis")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Theme.textPrimary)
            }
            Spacer()
        }
    }

    private var symptomCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("ISSUE")
                    .font(.caption.weight(.heavy))
                    .tracking(2)
                    .foregroundStyle(Theme.textTertiary)
                Spacer()
                if !symptom.isEmpty && !isLoading {
                    Button {
                        Haptics.tap()
                        Task { await runDiagnosis() }
                    } label: {
                        Label("Re-run", systemImage: "arrow.clockwise")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Theme.primary)
                    }
                }
            }
            TextField("Describe the fault…", text: $symptom, axis: .vertical)
                .lineLimit(2...5)
                .padding(12)
                .background(Theme.surfaceElevated)
                .clipShape(.rect(cornerRadius: 12))
                .foregroundStyle(Theme.textPrimary)
            if symptom.isEmpty || report.isEmpty {
                Button {
                    Haptics.tap()
                    Task { await runDiagnosis() }
                } label: {
                    HStack {
                        Image(systemName: "stethoscope")
                        Text("Diagnose Now")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(symptom.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
            }
        }
        .cardStyle()
    }

    private var loadingView: some View {
        VStack(spacing: 14) {
            ProgressView()
                .controlSize(.large)
                .tint(Theme.primary)
            Text("Diagnosing…")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .cardStyle()
    }

    private func errorCard(_ msg: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title)
                .foregroundStyle(Theme.danger)
            Text("Diagnosis failed")
                .font(.headline.weight(.bold))
                .foregroundStyle(Theme.textPrimary)
            Text(msg)
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
            Button {
                Task { await runDiagnosis() }
            } label: {
                Text("Try Again")
            }
            .buttonStyle(SecondaryButtonStyle())
        }
        .cardStyle()
    }

    private var safetySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(number: "01", title: "Safety First", symbol: "exclamationmark.shield.fill")
            VStack(alignment: .leading, spacing: 8) {
                ForEach(report.safety, id: \.self) { item in
                    bulletRow(item, color: Theme.danger)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var causesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(number: "02", title: "Top Probable Causes", symbol: "list.number")
            VStack(spacing: 10) {
                ForEach(report.causes) { cause in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(cause.rank)")
                            .font(.title2.weight(.black))
                            .foregroundStyle(Theme.onPrimary)
                            .frame(width: 36, height: 36)
                            .background(Theme.primary)
                            .clipShape(.rect(cornerRadius: 8))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(cause.title)
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(Theme.textPrimary)
                            if !cause.detail.isEmpty {
                                Text(cause.detail)
                                    .font(.subheadline)
                                    .foregroundStyle(Theme.textSecondary)
                            }
                        }
                        Spacer()
                    }
                    .padding(12)
                    .background(Theme.surfaceElevated)
                    .clipShape(.rect(cornerRadius: 12))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var quickCheckSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(number: "03", title: "60-Second Check", symbol: "timer")
            VStack(alignment: .leading, spacing: 8) {
                ForEach(report.quickCheck, id: \.self) { item in
                    bulletRow(item, color: Theme.info)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(number: "04", title: "Step-by-Step", symbol: "arrow.down.right.circle.fill")
            VStack(spacing: 8) {
                ForEach(Array(report.steps.enumerated()), id: \.offset) { idx, step in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(idx + 1)")
                            .font(.subheadline.weight(.black))
                            .foregroundStyle(Theme.primary)
                            .frame(width: 28, height: 28)
                            .background(Theme.primary.opacity(0.16))
                            .clipShape(.circle)
                            .overlay(Circle().stroke(Theme.primary, lineWidth: 1.5))
                        Text(step)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var feedbackCard: some View {
        VStack(spacing: 14) {
            Text("Did this fix the issue?")
                .font(.title3.weight(.heavy))
                .foregroundStyle(Theme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack(spacing: 10) {
                Button {
                    Haptics.success()
                    session?.outcome = .resolved
                    try? modelContext.save()
                    dismiss()
                } label: {
                    Label("Fixed", systemImage: "checkmark.circle.fill")
                }
                .buttonStyle(PrimaryButtonStyle())
                Button {
                    Haptics.warning()
                    session?.outcome = .unresolved
                    try? modelContext.save()
                    showInputSheet = true
                } label: {
                    Label("Not yet", systemImage: "arrow.clockwise")
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
        .cardStyle()
        .sheet(isPresented: $showInputSheet) {
            RefineSheet(symptom: $symptom) {
                showInputSheet = false
                Task { await runDiagnosis() }
            }
            .presentationDetents([.medium])
        }
    }

    private func bulletRow(_ text: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Circle().fill(color).frame(width: 6, height: 6).padding(.top, 8)
            Text(text)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func runDiagnosis() async {
        let trimmed = symptom.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        isLoading = true
        error = nil
        report = .empty
        do {
            let (text, mode) = try await AIService.shared.diagnose(symptom: trimmed, equipment: equipment, mode: aiMode)
            rawText = text
            report = DiagnosticParser.parse(text)
            resolvedMode = mode

            if session == nil {
                let s = DiagnosticSession(symptom: trimmed, rawResponse: text, aiMode: mode, outcome: .open, equipment: equipment)
                modelContext.insert(s)
                session = s
            } else {
                session?.symptom = trimmed
                session?.rawResponse = text
                session?.aiMode = mode
            }
            try? modelContext.save()
            Haptics.tap()
        } catch {
            self.error = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            Haptics.warning()
        }
        isLoading = false
    }
}

private struct RefineSheet: View {
    @Binding var symptom: String
    @State private var plc: String = ""
    @State private var voltage: String = ""
    @State private var fault: String = ""
    let onSubmit: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Provide more data to refine.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                    field("PLC input/output status", text: $plc, placeholder: "e.g. I:0/3 OFF, O:1/2 ON")
                    field("Voltage readings", text: $voltage, placeholder: "L1-L2: 480V, L2-L3: 0V")
                    field("Fault codes", text: $fault, placeholder: "F0006 Overcurrent")
                    Button {
                        var extras: [String] = []
                        if !plc.isEmpty { extras.append("PLC I/O: \(plc)") }
                        if !voltage.isEmpty { extras.append("Voltage: \(voltage)") }
                        if !fault.isEmpty { extras.append("Fault codes: \(fault)") }
                        if !extras.isEmpty {
                            symptom += "\n\nAdditional data — " + extras.joined(separator: " | ")
                        }
                        onSubmit()
                    } label: {
                        Text("Refine Diagnosis")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.top, 4)
                }
                .padding(16)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Refine")
            .navigationBarTitleDisplayMode(.inline)
        }
        .preferredColorScheme(.dark)
    }

    private func field(_ label: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption.weight(.bold))
                .tracking(1)
                .foregroundStyle(Theme.textTertiary)
            TextField(placeholder, text: text, axis: .vertical)
                .lineLimit(1...3)
                .padding(12)
                .background(Theme.surfaceElevated)
                .clipShape(.rect(cornerRadius: 10))
                .foregroundStyle(Theme.textPrimary)
                .font(.subheadline.monospaced())
        }
    }
}

struct SessionRow: View {
    let session: DiagnosticSession
    var hideEquipment: Bool = false

    var outcomeColor: Color {
        switch session.outcome {
        case .resolved: return Theme.success
        case .unresolved: return Theme.danger
        case .open: return Theme.textSecondary
        }
    }

    var outcomeText: String {
        switch session.outcome {
        case .resolved: return "Fixed"
        case .unresolved: return "Open"
        case .open: return "In Progress"
        }
    }

    var outcomeSymbol: String {
        switch session.outcome {
        case .resolved: return "checkmark.circle.fill"
        case .unresolved: return "exclamationmark.circle.fill"
        case .open: return "ellipsis.circle.fill"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Theme.surfaceElevated)
                    .frame(width: 40, height: 40)
                Image(systemName: "stethoscope")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Theme.primary)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(session.symptom)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(2)
                HStack(spacing: 8) {
                    if !hideEquipment, let eq = session.equipment {
                        Text(eq.id)
                            .font(.caption.monospaced().weight(.bold))
                            .foregroundStyle(Theme.primary)
                    }
                    Text(session.createdAt, format: .relative(presentation: .named))
                        .font(.caption)
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            Spacer()
            StatusPill(text: outcomeText, color: outcomeColor, symbol: outcomeSymbol)
        }
        .padding(12)
        .background(Theme.surface)
        .clipShape(.rect(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.stroke, lineWidth: 1))
    }
}

struct SessionReadView: View {
    let session: DiagnosticSession

    var report: DiagnosticReport { DiagnosticParser.parse(session.rawResponse) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        AIModeBadge(mode: session.aiMode)
                        Spacer()
                        Text(session.createdAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Text(session.symptom)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Theme.textPrimary)
                    if let eq = session.equipment {
                        Text("\(eq.name) • \(eq.id)")
                            .font(.caption.monospaced().weight(.bold))
                            .foregroundStyle(Theme.primary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardStyle()

                if !report.isEmpty {
                    HazardStripeBanner(title: "Safety First")
                    Group {
                        bulletCard("01", "Safety First", "exclamationmark.shield.fill", report.safety, color: Theme.danger)
                        bulletCard("03", "60-Second Check", "timer", report.quickCheck, color: Theme.info)
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(number: "02", title: "Top Probable Causes", symbol: "list.number")
                            ForEach(report.causes) { c in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(c.rank). \(c.title)")
                                        .font(.subheadline.weight(.bold))
                                        .foregroundStyle(Theme.textPrimary)
                                    if !c.detail.isEmpty {
                                        Text(c.detail).font(.subheadline).foregroundStyle(Theme.textSecondary)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(10)
                                .background(Theme.surfaceElevated)
                                .clipShape(.rect(cornerRadius: 10))
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .cardStyle()
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(number: "04", title: "Step-by-Step", symbol: "arrow.down.right.circle.fill")
                            ForEach(Array(report.steps.enumerated()), id: \.offset) { idx, s in
                                HStack(alignment: .top, spacing: 10) {
                                    Text("\(idx + 1).")
                                        .font(.subheadline.weight(.heavy))
                                        .foregroundStyle(Theme.primary)
                                    Text(s)
                                        .font(.subheadline)
                                        .foregroundStyle(Theme.textPrimary)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .cardStyle()
                    }
                } else {
                    Text(session.rawResponse)
                        .font(.body)
                        .foregroundStyle(Theme.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .cardStyle()
                }
            }
            .padding(16)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Diagnosis")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func bulletCard(_ num: String, _ title: String, _ symbol: String, _ items: [String], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(number: num, title: title, symbol: symbol)
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 10) {
                    Circle().fill(color).frame(width: 6, height: 6).padding(.top, 8)
                    Text(item)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}
