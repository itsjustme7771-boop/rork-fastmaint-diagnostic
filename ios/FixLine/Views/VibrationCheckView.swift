import SwiftUI
import CoreMotion

struct VibrationSample: Identifiable {
    let id = UUID()
    let magnitude: Double
}

struct VibrationCheckView: View {
    @State private var analyzer = VibrationAnalyzer()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header
                safetyCard
                liveMeter
                resultCard
                instructionCard
            }
            .padding(16)
            .padding(.bottom, 24)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Vibration Check")
        .navigationBarTitleDisplayMode(.large)
        .onDisappear { analyzer.stopCapture() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("MOTION DIAGNOSTIC")
                        .font(.caption.weight(.heavy))
                        .tracking(2)
                        .foregroundStyle(Theme.textTertiary)
                    Text("Use phone motion to spot abnormal vibration.")
                        .font(.title3.weight(.heavy))
                        .foregroundStyle(Theme.textPrimary)
                }
                Spacer()
                StatusPill(text: analyzer.statusLabel, color: analyzer.statusColor, symbol: analyzer.statusSymbol)
            }

            Button {
                Haptics.tap()
                analyzer.isCapturing ? analyzer.stopCapture() : analyzer.startCapture()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: analyzer.isCapturing ? "stop.fill" : "waveform.path.ecg")
                    Text(analyzer.isCapturing ? "Stop Capture" : "Start 15-Second Capture")
                }
            }
            .font(.headline.weight(.bold))
            .foregroundStyle(analyzer.isCapturing ? Theme.textPrimary : Theme.onPrimary)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 56)
            .background(analyzer.isCapturing ? Theme.surfaceElevated : Theme.primary)
            .clipShape(.rect(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(analyzer.isCapturing ? Theme.strokeStrong : .clear, lineWidth: 1))
        }
        .cardStyle()
    }

    private var safetyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HazardStripeBanner(title: "Safety first")
            Text("Do not place the phone on moving belts, rotating shafts, hot surfaces, or inside guarding. Hold it firmly against a safe frame point. Apply LOTO before opening guards or touching components.")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .cardStyle()
    }

    private var liveMeter: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(number: "LIVE", title: "Vibration Level", symbol: "gyroscope")
            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text(analyzer.currentMagnitude, format: .number.precision(.fractionLength(2)))
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundStyle(Theme.primary)
                Text("g")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Theme.textTertiary)
            }
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.surfaceElevated)
                    Capsule().fill(analyzer.statusColor)
                        .frame(width: proxy.size.width * min(analyzer.currentMagnitude / 2.5, 1))
                }
            }
            .frame(height: 16)
            .overlay(Capsule().stroke(Theme.strokeStrong, lineWidth: 1))

            HStack(spacing: 8) {
                metric("Peak", value: analyzer.peakMagnitude)
                metric("Avg", value: analyzer.averageMagnitude)
                metric("Samples", valueText: "\(analyzer.samples.count)")
            }
        }
        .cardStyle()
    }

    private var resultCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(number: "AI", title: "Likely Pattern", symbol: "brain.head.profile")
            Text(analyzer.diagnosisTitle)
                .font(.headline.weight(.heavy))
                .foregroundStyle(Theme.textPrimary)
            Text(analyzer.diagnosisDetail)
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .cardStyle()
    }

    private var instructionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(number: "STEPS", title: "How to capture", symbol: "hand.raised.fill")
            VStack(alignment: .leading, spacing: 10) {
                step("1", "Hold phone tight against a fixed motor, gearbox, pump, or conveyor frame point.")
                step("2", "Keep hands clear of pinch points, belts, chains, fans, and hot housings.")
                step("3", "Capture at normal running speed, then compare after repair or adjustment.")
                step("4", "If reading is high, check loose mounting, bad bearing, misalignment, imbalance, or belt/chain slap.")
            }
        }
        .cardStyle()
    }

    private func metric(_ label: String, value: Double) -> some View {
        metric(label, valueText: value.formatted(.number.precision(.fractionLength(2))))
    }

    private func metric(_ label: String, valueText: String) -> some View {
        VStack(spacing: 4) {
            Text(valueText)
                .font(.headline.weight(.black).monospacedDigit())
                .foregroundStyle(Theme.textPrimary)
            Text(label)
                .font(.caption.weight(.bold))
                .foregroundStyle(Theme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Theme.surfaceElevated)
        .clipShape(.rect(cornerRadius: 12))
    }

    private func step(_ number: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(number)
                .font(.caption.weight(.black))
                .foregroundStyle(Theme.onPrimary)
                .frame(width: 24, height: 24)
                .background(Theme.primary)
                .clipShape(.circle)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

@Observable
final class VibrationAnalyzer {
    private let motionManager = CMMotionManager()
    private var captureTask: Task<Void, Never>?

    var isCapturing = false
    var currentMagnitude = 0.0
    var peakMagnitude = 0.0
    var averageMagnitude = 0.0
    var samples: [VibrationSample] = []

    var statusLabel: String {
        if !motionManager.isDeviceMotionAvailable { return "No Sensor" }
        if isCapturing { return "Capturing" }
        if peakMagnitude >= 1.2 { return "High" }
        if peakMagnitude >= 0.55 { return "Watch" }
        return "Ready"
    }

    var statusSymbol: String {
        if !motionManager.isDeviceMotionAvailable { return "exclamationmark.triangle.fill" }
        return isCapturing ? "record.circle.fill" : "gyroscope"
    }

    var statusColor: Color {
        if !motionManager.isDeviceMotionAvailable { return Theme.danger }
        if peakMagnitude >= 1.2 { return Theme.danger }
        if peakMagnitude >= 0.55 { return Theme.primary }
        return Theme.success
    }

    var diagnosisTitle: String {
        if !motionManager.isDeviceMotionAvailable { return "Motion sensor unavailable" }
        if samples.isEmpty { return "Ready for baseline capture" }
        if peakMagnitude >= 1.2 { return "Severe vibration — stop and inspect if unsafe" }
        if peakMagnitude >= 0.55 { return "Elevated vibration — likely mechanical looseness or wear" }
        return "Normal / low vibration baseline"
    }

    var diagnosisDetail: String {
        if !motionManager.isDeviceMotionAvailable {
            return "This device does not expose motion data in the current environment. Try on a physical phone for real vibration capture."
        }
        if samples.isEmpty {
            return "Start capture while the machine is running normally. Use this as a quick triage reading, not a replacement for a calibrated vibration analyzer."
        }
        if peakMagnitude >= 1.2 {
            return "Prioritize loose motor mounts, failing bearings, coupling misalignment, damaged sprockets, bent shafts, or major imbalance. Verify guards and LOTO before touching equipment."
        }
        if peakMagnitude >= 0.55 {
            return "Check for loose bolts, belt/chain slap, early bearing noise, soft foot, and frame resonance. Compare this reading after adjustment."
        }
        return "No strong abnormal vibration detected during this capture. If the issue remains, check electrical load, intermittent jams, sensors, and VFD fault history."
    }

    func startCapture() {
        guard motionManager.isDeviceMotionAvailable, !isCapturing else { return }
        samples.removeAll()
        currentMagnitude = 0
        peakMagnitude = 0
        averageMagnitude = 0
        isCapturing = true
        motionManager.deviceMotionUpdateInterval = 1.0 / 30.0
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let acceleration = motion?.userAcceleration else { return }
            let magnitude = sqrt(acceleration.x * acceleration.x + acceleration.y * acceleration.y + acceleration.z * acceleration.z)
            self.currentMagnitude = magnitude
            self.peakMagnitude = max(self.peakMagnitude, magnitude)
            self.samples.append(VibrationSample(magnitude: magnitude))
            if self.samples.count > 450 { self.samples.removeFirst() }
            let total = self.samples.reduce(0.0) { $0 + $1.magnitude }
            self.averageMagnitude = total / Double(max(self.samples.count, 1))
        }
        captureTask?.cancel()
        captureTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(15))
            await MainActor.run { self?.stopCapture() }
        }
    }

    func stopCapture() {
        guard isCapturing else { return }
        isCapturing = false
        motionManager.stopDeviceMotionUpdates()
        captureTask?.cancel()
        captureTask = nil
        Haptics.success()
    }
}
