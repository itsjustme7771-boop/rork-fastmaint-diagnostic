import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \DiagnosticSession.createdAt, order: .reverse) private var sessions: [DiagnosticSession]
    @State private var filter: SessionOutcome? = nil
    @State private var query: String = ""

    var filtered: [DiagnosticSession] {
        sessions.filter { s in
            (filter == nil || s.outcome == filter) &&
            (query.isEmpty || s.symptom.localizedStandardContains(query)
             || (s.equipment?.name.localizedStandardContains(query) ?? false)
             || (s.equipment?.id.localizedStandardContains(query) ?? false))
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                filterBar
                if filtered.isEmpty {
                    EmptyStateView(symbol: "clock.badge.questionmark",
                                   title: "No diagnoses",
                                   message: "Past diagnostic sessions will show here.")
                        .padding(.top, 40)
                } else {
                    ForEach(filtered) { s in
                        NavigationLink {
                            SessionReadView(session: s)
                        } label: {
                            SessionRow(session: s)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(16)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $query, prompt: "Search diagnoses")
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip("All", active: filter == nil) { filter = nil }
                chip("Fixed", active: filter == .resolved, color: Theme.success) { filter = filter == .resolved ? nil : .resolved }
                chip("Open", active: filter == .unresolved, color: Theme.danger) { filter = filter == .unresolved ? nil : .unresolved }
            }
        }
    }

    private func chip(_ label: String, active: Bool, color: Color = Theme.primary, action: @escaping () -> Void) -> some View {
        Button(action: { Haptics.tap(); action() }) {
            Text(label)
                .font(.subheadline.weight(.bold))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(active ? color : Theme.surface)
                .foregroundStyle(active ? Theme.onPrimary : Theme.textPrimary)
                .clipShape(.capsule)
                .overlay(Capsule().stroke(active ? color : Theme.stroke, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
