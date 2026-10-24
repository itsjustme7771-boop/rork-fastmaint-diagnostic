import Foundation
import WidgetKit

nonisolated struct FleetSummary: Codable {
    var down: [String]
    var maintenance: [String]
    var running: Int
    var updatedAt: Date
}

enum FleetSummaryPublisher {
    static let appGroupID = "group.com.rork.fixline"

    static func publish(equipment: [Equipment]) {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return }
        let summary = FleetSummary(
            down: equipment.filter { $0.status == .down }.map(\.name),
            maintenance: equipment.filter { $0.status == .maintenance }.map(\.name),
            running: equipment.filter { $0.status == .running }.count,
            updatedAt: .now
        )
        if let data = try? JSONEncoder().encode(summary) {
            defaults.set(data, forKey: "fixline.fleet")
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
}
