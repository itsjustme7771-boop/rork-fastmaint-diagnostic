import SwiftUI

struct FaultCodeView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var code: String = ""
    @State private var rawText: String = ""
    @State private var report: DiagnosticReport = .empty
    @State private var isLoading: Bool = false
    @State private var error: String?
    @State private var resolvedMode: AIMode = .auto

    let presets = ["F0006", "F0007", "F0011", "F0030", "PF005", "OC1", "GF1", "OL1"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    inputCard

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(presets, id: \.self) { c in
                                Button {
                                    code = c
                                    Haptics.tap()
                                    Task { await lookup() }
                                } label: {
                                    Text(c)
                                        .font(.caption.monospaced().weight(.bold))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Theme.surfaceElevated)
                                        .foregroundStyle(Theme.primary)
                                        .clipShape(.capsule)
                                        .overlay(Capsule().stroke(Theme.primary.opacity(0.4), lineWidth: 1))
                                }
                            }
                        }
                    }

                    if isLoading {
                        ProgressView().controlSize(.large).tint(Theme.primary)
                            .frame(maxWidth: .infinity).padding(.vertical, 40)
                    } else if let error {
                        Text(error)
                            .foregroundStyle(Theme.danger)
                            .padding()
                            .cardStyle()
                    } else if !report.isEmpty {
                        Text(rawText)
                            .font(.subheadline)
                            .foregroundStyle(Theme.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .cardStyle()
                    }
                }
                .padding(16)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Fault Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Theme.primary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    AIModeBadge(mode: resolvedMode)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ENTER VFD / PLC CODE")
                .font(.caption.weight(.heavy))
                .tracking(2)
                .foregroundStyle(Theme.textTertiary)
            TextField("F0006", text: $code)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .font(.title2.monospaced().weight(.bold))
                .padding(14)
                .background(Theme.surfaceElevated)
                .clipShape(.rect(cornerRadius: 12))
                .foregroundStyle(Theme.textPrimary)
            Button {
                Haptics.tap()
                Task { await lookup() }
            } label: {
                HStack {
                    Image(systemName: "magnifyingglass")
                    Text("Look Up")
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(code.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .cardStyle()
    }

    private func lookup() async {
        let trimmed = code.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        isLoading = true
        error = nil
        do {
            let (text, mode) = try await AIService.shared.lookupFaultCode(trimmed)
            rawText = text
            report = DiagnosticParser.parse(text)
            resolvedMode = mode
        } catch {
            self.error = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
        isLoading = false
    }
}
