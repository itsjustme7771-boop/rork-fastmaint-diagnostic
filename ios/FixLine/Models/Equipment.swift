import Foundation
import SwiftData

nonisolated enum EquipmentStatus: String, Codable, CaseIterable, Sendable {
    case running
    case down
    case maintenance

    var label: String {
        switch self {
        case .running: return "Running"
        case .down: return "Down"
        case .maintenance: return "Maintenance"
        }
    }
}

nonisolated enum EquipmentKind: String, Codable, CaseIterable, Sendable {
    case conveyor, filler, capper, labeler, palletizer, mixer, packer, shrinkWrap

    var label: String {
        switch self {
        case .conveyor: return "Conveyor"
        case .filler: return "Filler"
        case .capper: return "Capper"
        case .labeler: return "Labeler"
        case .palletizer: return "Palletizer"
        case .mixer: return "Mixer"
        case .packer: return "Case Packer"
        case .shrinkWrap: return "Shrink Wrapper"
        }
    }

    var symbol: String {
        switch self {
        case .conveyor: return "arrow.left.and.right.righttriangle.left.righttriangle.right.fill"
        case .filler: return "drop.fill"
        case .capper: return "circle.circle.fill"
        case .labeler: return "tag.fill"
        case .palletizer: return "shippingbox.fill"
        case .mixer: return "tornado"
        case .packer: return "archivebox.fill"
        case .shrinkWrap: return "cube.transparent.fill"
        }
    }
}

@Model
final class Equipment {
    @Attribute(.unique) var id: String
    var name: String
    var kindRaw: String
    var line: String
    var manufacturer: String
    var model: String
    var statusRaw: String
    var lastServiced: Date
    var commonFailures: [String]
    var notes: String

    @Relationship(deleteRule: .cascade, inverse: \DiagnosticSession.equipment)
    var sessions: [DiagnosticSession] = []

    var kind: EquipmentKind {
        get { EquipmentKind(rawValue: kindRaw) ?? .conveyor }
        set { kindRaw = newValue.rawValue }
    }

    var status: EquipmentStatus {
        get { EquipmentStatus(rawValue: statusRaw) ?? .running }
        set { statusRaw = newValue.rawValue }
    }

    init(
        id: String,
        name: String,
        kind: EquipmentKind,
        line: String,
        manufacturer: String,
        model: String,
        status: EquipmentStatus = .running,
        lastServiced: Date = .now,
        commonFailures: [String] = [],
        notes: String = ""
    ) {
        self.id = id
        self.name = name
        self.kindRaw = kind.rawValue
        self.line = line
        self.manufacturer = manufacturer
        self.model = model
        self.statusRaw = status.rawValue
        self.lastServiced = lastServiced
        self.commonFailures = commonFailures
        self.notes = notes
    }
}
