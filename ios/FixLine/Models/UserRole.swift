import Foundation

enum UserRole: String, CaseIterable, Codable, Identifiable {
    case technician
    case lead
    case management

    var id: String { rawValue }

    var label: String {
        switch self {
        case .technician: return "Technician"
        case .lead: return "Lead"
        case .management: return "Management"
        }
    }

    var symbol: String {
        switch self {
        case .technician: return "wrench.and.screwdriver.fill"
        case .lead: return "person.2.fill"
        case .management: return "briefcase.fill"
        }
    }

    var description: String {
        switch self {
        case .technician: return "Diagnose equipment, run checks, log fixes."
        case .lead: return "Everything a technician does, plus upload manuals and review unresolved diagnoses."
        case .management: return "Full access — fleet overview, cost tracking, and team settings."
        }
    }
}
