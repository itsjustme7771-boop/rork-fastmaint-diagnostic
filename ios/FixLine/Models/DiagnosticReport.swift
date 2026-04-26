import Foundation

nonisolated struct DiagnosticReport: Sendable {
    var safety: [String]
    var causes: [Cause]
    var quickCheck: [String]
    var steps: [String]

    nonisolated struct Cause: Sendable, Identifiable {
        let id = UUID()
        var rank: Int
        var title: String
        var detail: String
    }

    static let empty = DiagnosticReport(safety: [], causes: [], quickCheck: [], steps: [])

    var isEmpty: Bool {
        safety.isEmpty && causes.isEmpty && quickCheck.isEmpty && steps.isEmpty
    }
}

nonisolated enum DiagnosticParser {
    static func parse(_ text: String) -> DiagnosticReport {
        var safety: [String] = []
        var causes: [DiagnosticReport.Cause] = []
        var quickCheck: [String] = []
        var steps: [String] = []

        enum Section { case none, safety, causes, check, steps }
        var current: Section = .none
        var causeRank = 0

        let lines = text.components(separatedBy: .newlines)
        for raw in lines {
            let line = raw.trimmingCharacters(in: .whitespaces)
            if line.isEmpty { continue }
            let lower = line.lowercased()

            if lower.contains("safety") && (lower.contains("first") || lower.hasPrefix("1") || lower.hasPrefix("#")) {
                current = .safety; continue
            }
            if (lower.contains("probable") || lower.contains("cause")) && (lower.contains("top") || lower.hasPrefix("2") || lower.hasPrefix("#")) {
                current = .causes; continue
            }
            if lower.contains("60") && lower.contains("check") {
                current = .check; continue
            }
            if (lower.contains("step") && lower.contains("resolution")) || lower.contains("step-by-step") {
                current = .steps; continue
            }
            if lower.hasPrefix("did this fix") { break }

            let cleaned = stripBullet(line)
            guard !cleaned.isEmpty else { continue }

            switch current {
            case .safety:
                safety.append(cleaned)
            case .causes:
                causeRank += 1
                let parts = splitTitleDetail(cleaned)
                causes.append(.init(rank: causeRank, title: parts.0, detail: parts.1))
            case .check:
                quickCheck.append(cleaned)
            case .steps:
                steps.append(cleaned)
            case .none:
                continue
            }
        }
        return DiagnosticReport(safety: safety, causes: causes, quickCheck: quickCheck, steps: steps)
    }

    private static func stripBullet(_ s: String) -> String {
        var t = s
        let prefixes = ["- ", "• ", "* ", "→ ", "▪ "]
        for p in prefixes where t.hasPrefix(p) {
            t = String(t.dropFirst(p.count))
            break
        }
        // Strip leading "1. " / "1) "
        if let firstChar = t.first, firstChar.isNumber {
            if let dot = t.firstIndex(where: { $0 == "." || $0 == ")" }) {
                let prefix = t[..<dot]
                if prefix.allSatisfy(\.isNumber) {
                    let after = t.index(after: dot)
                    t = String(t[after...]).trimmingCharacters(in: .whitespaces)
                }
            }
        }
        // Strip markdown bold
        t = t.replacingOccurrences(of: "**", with: "")
        t = t.replacingOccurrences(of: "##", with: "")
        return t.trimmingCharacters(in: .whitespaces)
    }

    private static func splitTitleDetail(_ s: String) -> (String, String) {
        if let range = s.range(of: " — ") {
            return (String(s[..<range.lowerBound]), String(s[range.upperBound...]))
        }
        if let range = s.range(of: " - ") {
            return (String(s[..<range.lowerBound]), String(s[range.upperBound...]))
        }
        if let range = s.range(of: ": ") {
            return (String(s[..<range.lowerBound]), String(s[range.upperBound...]))
        }
        return (s, "")
    }
}
