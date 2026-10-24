import WidgetKit
import SwiftUI

// Mirror of the app's FleetSummary — kept identical on purpose (no shared target).
nonisolated struct FleetSummary: Codable {
    var down: [String] = []
    var maintenance: [String] = []
    var running: Int = 0
    var updatedAt: Date = .distantPast
}

nonisolated enum FleetStore {
    static let appGroupID = "group.com.rork.fixline"

    static func loadSummary() -> FleetSummary {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let data = defaults.data(forKey: "fixline.fleet"),
              let summary = try? JSONDecoder().decode(FleetSummary.self, from: data) else {
            return FleetSummary()
        }
        return summary
    }
}

nonisolated struct FleetEntry: TimelineEntry {
    let date: Date
    let summary: FleetSummary
}

nonisolated struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> FleetEntry {
        FleetEntry(date: .now, summary: sampleSummary)
    }

    func getSnapshot(in context: Context, completion: @escaping (FleetEntry) -> Void) {
        completion(FleetEntry(date: .now, summary: FleetStore.loadSummary()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FleetEntry>) -> Void) {
        let entry = FleetEntry(date: .now, summary: FleetStore.loadSummary())
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: .now) ?? .now
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private var sampleSummary: FleetSummary {
        FleetSummary(down: ["Filler #2"], maintenance: ["Labeler"], running: 6, updatedAt: .now)
    }
}

nonisolated enum WidgetPalette {
    static let bg = Color(red: 0.06, green: 0.07, blue: 0.08)
    static let surface = Color(red: 0.14, green: 0.15, blue: 0.17)
    static let primary = Color(red: 1.0, green: 0.84, blue: 0.0)
    static let danger = Color(red: 1.0, green: 0.30, blue: 0.27)
    static let success = Color(red: 0.20, green: 0.85, blue: 0.45)
    static let textSecondary = Color.white.opacity(0.65)
    static let textTertiary = Color.white.opacity(0.40)
}

nonisolated struct WidgetView: View {
    @Environment(\.widgetFamily) private var family
    var entry: Provider.Entry

    var body: some View {
        Group {
            switch family {
            case .systemSmall: small
            case .systemMedium: medium
            case .accessoryCircular: circular
            case .accessoryInline: inline
            case .accessoryRectangular: rectangular
            default: large
            }
        }
        .containerBackground(for: .widget) {
            switch family {
            case .accessoryCircular, .accessoryInline, .accessoryRectangular:
                Color.clear
            default:
                WidgetPalette.bg
            }
        }
    }

    private var downColor: Color {
        entry.summary.down.isEmpty ? WidgetPalette.success : WidgetPalette.danger
    }

    private var circular: some View {
        VStack(spacing: 0) {
            Text("\(entry.summary.down.count)")
                .font(.system(size: 30, weight: .black, design: .rounded).monospacedDigit())
            Text("DOWN")
                .font(.system(size: 9, weight: .heavy))
                .tracking(1)
        }
        .foregroundStyle(downColor)
        .widgetAccentable()
    }

    private var inline: some View {
        Text(entry.summary.down.isEmpty
             ? "FixLine · All lines running"
             : "FixLine · \(entry.summary.down.count) machine\(entry.summary.down.count == 1 ? "" : "s") down")
            .font(.headline.weight(.bold))
            .foregroundStyle(downColor)
            .widgetAccentable()
    }

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: "bolt.gearshape.fill")
                    .font(.caption.weight(.black))
                Text("FixLine")
                    .font(.caption.weight(.heavy))
            }
            .foregroundStyle(WidgetPalette.primary)
            if entry.summary.down.isEmpty {
                Text("All \(entry.summary.running) lines running")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(WidgetPalette.success)
            } else {
                Text(entry.summary.down.prefix(2).joined(separator: ", "))
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(WidgetPalette.danger)
                    .lineLimit(2)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 6) {
            Image(systemName: "bolt.gearshape.fill")
                .font(.system(size: 13, weight: .black))
                .foregroundStyle(WidgetPalette.primary)
            Text("FixLine")
                .font(.caption.weight(.heavy))
                .foregroundStyle(.white)
            Spacer()
        }
    }

    private var small: some View {
        VStack(alignment: .leading, spacing: 4) {
            header
            Spacer()
            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text("\(entry.summary.down.count)")
                    .font(.system(size: 40, weight: .black, design: .rounded))
                    .foregroundStyle(entry.summary.down.isEmpty ? WidgetPalette.success : WidgetPalette.danger)
                Text(entry.summary.down.isEmpty ? "MACHINES DOWN" : "DOWN")
                    .font(.system(size: 11, weight: .heavy))
                    .tracking(1)
                    .foregroundStyle(WidgetPalette.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Text("\(entry.summary.running) running · \(entry.summary.maintenance.count) maint.")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(WidgetPalette.textTertiary)
        }
    }

    private var medium: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                header
                Text("\(entry.summary.running) running")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(WidgetPalette.success)
            }
            if entry.summary.down.isEmpty && entry.summary.maintenance.isEmpty {
                Label("All lines running", systemImage: "checkmark.seal.fill")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(WidgetPalette.success)
            } else {
                ForEach(entry.summary.down.prefix(2), id: \.self) { name in
                    alertRow(name: name, color: WidgetPalette.danger, symbol: "exclamationmark.triangle.fill", label: "DOWN")
                }
                ForEach(entry.summary.maintenance.prefix(mediumSlots - min(entry.summary.down.count, 2)), id: \.self) { name in
                    alertRow(name: name, color: WidgetPalette.primary, symbol: "wrench.fill", label: "MAINT")
                }
            }
            Spacer()
        }
    }

    private var mediumSlots: Int { 3 }

    private var large: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                header
                Text(entry.summary.updatedAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(WidgetPalette.textTertiary)
            }

            HStack(spacing: 8) {
                stat(count: entry.summary.down.count, label: "DOWN", color: WidgetPalette.danger)
                stat(count: entry.summary.maintenance.count, label: "MAINT", color: WidgetPalette.primary)
                stat(count: entry.summary.running, label: "RUN", color: WidgetPalette.success)
            }

            if entry.summary.down.isEmpty && entry.summary.maintenance.isEmpty {
                VStack(spacing: 6) {
                    Spacer()
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 30, weight: .black))
                        .foregroundStyle(WidgetPalette.success)
                    Text("All lines running")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                ForEach(entry.summary.down, id: \.self) { name in
                    alertRow(name: name, color: WidgetPalette.danger, symbol: "exclamationmark.triangle.fill", label: "DOWN")
                }
                ForEach(entry.summary.maintenance, id: \.self) { name in
                    alertRow(name: name, color: WidgetPalette.primary, symbol: "wrench.fill", label: "MAINT")
                }
            }
            Spacer()
        }
    }

    private func stat(count: Int, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(.title3.weight(.black).monospacedDigit())
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 9, weight: .heavy))
                .tracking(1)
                .foregroundStyle(WidgetPalette.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(WidgetPalette.surface)
        .clipShape(.rect(cornerRadius: 8))
    }

    private func alertRow(name: String, color: Color, symbol: String, label: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.caption.weight(.black))
                .foregroundStyle(color)
            Text(name)
                .font(.footnote.weight(.bold))
                .foregroundStyle(.white)
                .lineLimit(1)
            Spacer()
            Text(label)
                .font(.system(size: 9, weight: .heavy))
                .tracking(1)
                .foregroundStyle(color)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(WidgetPalette.surface)
        .clipShape(.rect(cornerRadius: 8))
    }
}

struct FixLineWidget: Widget {
    let kind: String = "FixLineWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            WidgetView(entry: entry)
        }
        .configurationDisplayName("Fleet Status")
        .description("Down machines, maintenance, and running lines at a glance.")
        .supportedFamilies([
            .systemSmall, .systemMedium, .systemLarge,
            .accessoryCircular, .accessoryInline, .accessoryRectangular
        ])
    }
}
