import SwiftUI
import SwiftData

struct EquipmentLibraryView: View {
    @Query(sort: \Equipment.name) private var equipment: [Equipment]
    @State private var query: String = ""
    @State private var statusFilter: EquipmentStatus? = nil

    var filtered: [Equipment] {
        equipment.filter { eq in
            (statusFilter == nil || eq.status == statusFilter) &&
            (query.isEmpty
             || eq.name.localizedStandardContains(query)
             || eq.id.localizedStandardContains(query)
             || eq.line.localizedStandardContains(query)
             || eq.manufacturer.localizedStandardContains(query))
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                filterBar
                ForEach(filtered) { eq in
                    NavigationLink(value: eq) {
                        EquipmentRow(equipment: eq)
                    }
                    .buttonStyle(.plain)
                }
                if filtered.isEmpty {
                    EmptyStateView(symbol: "tray", title: "No equipment", message: "Try a different filter or search.")
                        .padding(.top, 40)
                }
            }
            .padding(16)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Equipment")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $query, prompt: "Search by name, ID, line")
        .navigationDestination(for: Equipment.self) { eq in
            EquipmentDetailView(equipment: eq)
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip("All", active: statusFilter == nil) { statusFilter = nil }
                ForEach(EquipmentStatus.allCases, id: \.self) { s in
                    filterChip(s.label, active: statusFilter == s, color: s.color) {
                        statusFilter = (statusFilter == s) ? nil : s
                    }
                }
            }
        }
    }

    private func filterChip(_ label: String, active: Bool, color: Color = Theme.primary, action: @escaping () -> Void) -> some View {
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

struct EquipmentRow: View {
    let equipment: Equipment

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Theme.surfaceElevated)
                    .frame(width: 56, height: 56)
                Image(systemName: equipment.kind.symbol)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Theme.primary)
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(equipment.name)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    StatusPill(text: equipment.status.label, color: equipment.status.color, symbol: equipment.status.symbol)
                }
                HStack(spacing: 8) {
                    Text(equipment.id)
                        .font(.caption.monospaced().weight(.bold))
                        .foregroundStyle(Theme.primary)
                    Text("•")
                        .foregroundStyle(Theme.textTertiary)
                    Text(equipment.line)
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)
                }
            }
            Image(systemName: "chevron.right")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Theme.textTertiary)
        }
        .padding(14)
        .background(Theme.surface)
        .clipShape(.rect(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.stroke, lineWidth: 1))
    }
}
