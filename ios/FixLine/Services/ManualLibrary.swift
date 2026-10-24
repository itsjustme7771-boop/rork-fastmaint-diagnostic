import Foundation
import PDFKit

nonisolated struct ManualExcerpt: Sendable {
    let title: String
    let snippet: String
}

nonisolated enum ManualLibrary {
    private static let maxExtractedChars = 400_000

    /// Extract full text from a PDF. Safe to call from a background task.
    static func extractText(from url: URL) -> (text: String, pages: Int) {
        guard let doc = PDFDocument(url: url) else { return ("", 0) }
        var out = ""
        for i in 0..<doc.pageCount {
            if let page = doc.page(at: i), let s = page.string {
                out += s + "\n"
            }
            if out.count > maxExtractedChars { break }
        }
        if out.count > maxExtractedChars {
            out = String(out.prefix(maxExtractedChars))
        }
        return (out, doc.pageCount)
    }

    /// Keyword-scored retrieval over the knowledge base. Returns up to `maxDocs`
    /// excerpts, each capped at `maxCharsPerDoc`, to inject into the AI prompt.
    static func relevantExcerpts(
        for symptom: String,
        equipment: Equipment?,
        docs: [ManualDocument],
        maxDocs: Int = 2,
        maxCharsPerDoc: Int = 2200
    ) -> [ManualExcerpt] {
        let terms = keywords(from: symptom, equipment: equipment)
        guard !terms.isEmpty, !docs.isEmpty else { return [] }

        var scored: [(doc: ManualDocument, score: Int)] = []
        for doc in docs {
            let text = doc.extractedText.lowercased()
            guard !text.isEmpty else { continue }
            var score = 0
            for term in terms {
                score += min(text.components(separatedBy: term).count - 1, 50)
            }
            // Boost manuals tagged or titled for this machine.
            if let eq = equipment {
                let name = eq.name.lowercased()
                if doc.equipmentHint.lowercased().contains(name) || doc.title.lowercased().contains(name) {
                    score += 40
                }
            }
            if score > 0 {
                scored.append((doc, score))
            }
        }

        guard !scored.isEmpty else { return [] }
        scored.sort { $0.score > $1.score }

        return scored.prefix(maxDocs).compactMap { item in
            guard let snippet = snippet(around: terms, in: item.doc.extractedText, maxChars: maxCharsPerDoc) else {
                // No direct term hit (boost-only doc) — take the opening chunk.
                let head = String(item.doc.extractedText.prefix(maxCharsPerDoc))
                return head.isEmpty ? nil : ManualExcerpt(title: item.doc.title, snippet: head)
            }
            return ManualExcerpt(title: item.doc.title, snippet: snippet)
        }
    }

    private static func keywords(from symptom: String, equipment: Equipment?) -> [String] {
        let stopWords: Set<String> = [
            "the", "and", "for", "with", "not", "won", "but", "when", "off", "out",
            "its", "it's", "this", "that", "from", "into", "has", "have", "was",
            "will", "does", "did", "can", "get", "got", "just", "any", "all", "are",
            "after", "keep", "keeps", "very", "them", "then", "than", "over", "under"
        ]
        var raw = symptom.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count >= 3 && !stopWords.contains($0) }
        if let eq = equipment {
            raw.append(eq.name.lowercased())
            raw.append(eq.manufacturer.lowercased())
            raw.append(eq.model.lowercased())
        }
        return Array(Set(raw).prefix(24))
    }

    private static func snippet(around terms: [String], in text: String, maxChars: Int) -> String? {
        let lowered = text.lowercased()
        var bestIdx: Int?
        for term in terms {
            if let r = lowered.range(of: term) {
                let idx = lowered.distance(from: lowered.startIndex, to: r.lowerBound)
                if bestIdx == nil || idx < bestIdx! { bestIdx = idx }
            }
        }
        guard let idx = bestIdx else { return nil }
        let half = maxChars / 2
        let start = text.index(text.startIndex, offsetBy: max(0, idx - half), limitedBy: text.endIndex) ?? text.startIndex
        let end = text.index(start, offsetBy: maxChars, limitedBy: text.endIndex) ?? text.endIndex
        return String(text[start..<end])
    }
}
