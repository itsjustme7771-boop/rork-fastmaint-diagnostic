import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

nonisolated enum AIServiceError: Error, LocalizedError, Sendable {
    case missingKey
    case badResponse(Int)
    case decoding
    case offlineUnavailable
    case generic(String)

    var errorDescription: String? {
        switch self {
        case .missingKey: return "AI key not configured."
        case .badResponse(let s): return "AI request failed (HTTP \(s))."
        case .decoding: return "Could not decode AI response."
        case .offlineUnavailable: return "On-device AI is not available on this device."
        case .generic(let m): return m
        }
    }
}

nonisolated struct ChatMessage: Codable, Sendable {
    let role: String
    let content: String
}

nonisolated struct ChatRequest: Codable, Sendable {
    let model: String
    let messages: [ChatMessage]
    let temperature: Double
}

nonisolated struct ChatChoice: Codable, Sendable {
    let message: ChatMessage
}

nonisolated struct ChatResponse: Codable, Sendable {
    let choices: [ChatChoice]
}

@MainActor
final class AIService {
    static let shared = AIService()

    private let model = "openai/gpt-5-mini"

    private let systemPrompt = """
    You are an Industrial Maintenance Diagnostic Engine for high-speed manufacturing. You think like an experienced lead maintenance technician on the plant floor. Reduce downtime, prioritize safety, and give actionable steps.

    ALWAYS respond in this exact format and order, using these exact section headers:

    1. SAFETY FIRST
    - List hazards (high voltage, stored air/hydraulic energy, moving parts, heat).
    - State required actions (LOTO, bleed air, verify zero energy state).

    2. TOP 3 PROBABLE CAUSES
    Numbered 1-3, ranked by real-world frequency. Bias heavily toward sensors, electrical (overloads, fuses, power), safety circuits/interlocks, post-sanitation issues (loose wires, misconnected airlines). Format each as: "1. Title — short detail".

    3. 60-SECOND CHECK
    Fast no-tools checks. Use bullets. Visual / Audible / Sensory.

    4. STEP-BY-STEP RESOLUTION
    Numbered, one action per step, imperative verbs, short and direct.

    End with the line: "Did this fix the issue? If not, share PLC I/O status, voltage readings, and any fault codes."

    Be concise, scannable, command-style. No theory.
    """

    func diagnose(symptom: String, equipment: Equipment?, mode: AIMode) async throws -> (String, AIMode) {
        let resolvedMode: AIMode
        switch mode {
        case .auto:
            resolvedMode = NetworkMonitor.shared.isOnline ? .online : .offline
        case .online, .offline:
            resolvedMode = mode
        }

        let userPrompt = buildUserPrompt(symptom: symptom, equipment: equipment)

        if resolvedMode == .offline {
            return (try await diagnoseOnDevice(userPrompt: userPrompt), .offline)
        } else {
            return (try await diagnoseCloud(userPrompt: userPrompt), .online)
        }
    }

    func lookupFaultCode(_ code: String) async throws -> (String, AIMode) {
        let prompt = "Interpret this industrial fault code and provide cause + fix: \"\(code)\". Use the standard SAFETY FIRST / TOP 3 PROBABLE CAUSES / 60-SECOND CHECK / STEP-BY-STEP RESOLUTION format."
        if NetworkMonitor.shared.isOnline {
            return (try await diagnoseCloud(userPrompt: prompt), .online)
        } else {
            return (try await diagnoseOnDevice(userPrompt: prompt), .offline)
        }
    }

    private func buildUserPrompt(symptom: String, equipment: Equipment?) -> String {
        var p = "Issue: \(symptom)\n"
        if let e = equipment {
            p += "Equipment: \(e.name) (\(e.kind.label))\n"
            p += "Line: \(e.line)\n"
            p += "Make/Model: \(e.manufacturer) \(e.model)\n"
            if !e.commonFailures.isEmpty {
                p += "Known common failures: \(e.commonFailures.joined(separator: "; "))\n"
            }
            if !e.notes.isEmpty {
                p += "Tech notes: \(e.notes)\n"
            }
        }
        p += "Respond in the mandatory format."
        return p
    }

    private func diagnoseCloud(userPrompt: String) async throws -> String {
        let key = Config.EXPO_PUBLIC_RORK_TOOLKIT_SECRET_KEY
        let baseURL = ProcessInfo.processInfo.environment["EXPO_PUBLIC_TOOLKIT_URL"] ?? "https://toolkit.rork.com"
        guard !key.isEmpty else { throw AIServiceError.missingKey }

        let url = URL(string: "\(baseURL)/v2/vercel/v1/chat/completions")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 60

        let body = ChatRequest(
            model: model,
            messages: [
                .init(role: "system", content: systemPrompt),
                .init(role: "user", content: userPrompt)
            ],
            temperature: 0.2
        )
        req.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw AIServiceError.decoding }
        guard (200..<300).contains(http.statusCode) else {
            throw AIServiceError.badResponse(http.statusCode)
        }
        let decoded = try JSONDecoder().decode(ChatResponse.self, from: data)
        return decoded.choices.first?.message.content ?? ""
    }

    private func diagnoseOnDevice(userPrompt: String) async throws -> String {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            let model = SystemLanguageModel.default
            guard model.availability == .available else {
                throw AIServiceError.offlineUnavailable
            }
            let session = LanguageModelSession(instructions: systemPrompt)
            let response = try await session.respond(to: userPrompt)
            return response.content
        }
        #endif
        return offlineFallback(for: userPrompt)
    }

    private func offlineFallback(for prompt: String) -> String {
        """
        1. SAFETY FIRST
        - Hazards: high voltage, stored pneumatic/hydraulic energy, moving parts, hot surfaces.
        - Apply LOTO before opening any panel.
        - Bleed air pressure before disconnecting any line.
        - Verify zero energy state with a meter.

        2. TOP 3 PROBABLE CAUSES
        1. Disconnect/E-stop — End-of-line disconnect off or safety circuit not made up.
        2. Overload tripped — Motor overload or thermal protector tripped after recent run.
        3. Sensor/wire issue — Sensor misaligned/dirty or loose wire post-sanitation.

        3. 60-SECOND CHECK
        - Visual: Check disconnect ON, look for loose wires, blocked or misaligned sensors, product jams.
        - Audible: Listen for humming motor, air leaks, contactor chatter.
        - Sensory: Smell for burnt insulation, feel motor for overheating (if safe).

        4. STEP-BY-STEP RESOLUTION
        1. Verify all disconnects are ON, including end-of-line.
        2. Check overloads — reset any that are tripped.
        3. Confirm safety circuit is made up (E-stops, gates, light curtains).
        4. Inspect and clean/realign suspect sensors.
        5. Check PLC input light for the failed sensor signal.
        6. Verify voltage at L1, L2, L3 if motor is dead.
        7. Replace component if confirmed faulty.

        Did this fix the issue? If not, share PLC I/O status, voltage readings, and any fault codes.

        (Offline mode — limited reasoning. Connect to network for richer diagnosis.)
        """
    }
}
