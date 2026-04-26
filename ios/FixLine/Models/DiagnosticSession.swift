import Foundation
import SwiftData

nonisolated enum SessionOutcome: String, Codable, Sendable {
    case open
    case resolved
    case unresolved
}

nonisolated enum AIMode: String, Codable, CaseIterable, Sendable {
    case auto
    case online
    case offline

    var label: String {
        switch self {
        case .auto: return "Auto"
        case .online: return "Cloud"
        case .offline: return "On-Device"
        }
    }
}

@Model
final class DiagnosticSession {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var symptom: String
    var rawResponse: String
    var aiModeRaw: String
    var outcomeRaw: String
    var equipment: Equipment?

    var aiMode: AIMode {
        get { AIMode(rawValue: aiModeRaw) ?? .auto }
        set { aiModeRaw = newValue.rawValue }
    }

    var outcome: SessionOutcome {
        get { SessionOutcome(rawValue: outcomeRaw) ?? .open }
        set { outcomeRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        symptom: String,
        rawResponse: String = "",
        aiMode: AIMode = .auto,
        outcome: SessionOutcome = .open,
        equipment: Equipment? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.symptom = symptom
        self.rawResponse = rawResponse
        self.aiModeRaw = aiMode.rawValue
        self.outcomeRaw = outcome.rawValue
        self.equipment = equipment
    }
}
