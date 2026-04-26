import SwiftUI
import AVFoundation

struct ScannerView: View {
    let onScan: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var manualCode: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                CameraScannerProxy(onScan: { code in
                    Haptics.success()
                    onScan(code)
                })

                VStack {
                    Spacer()
                    targetingFrame
                    Spacer()
                    manualEntry
                }
                .padding(20)
            }
            .navigationTitle("Scan QR")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.bg, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.primary)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var targetingFrame: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .stroke(Theme.primary, lineWidth: 4)
                .frame(width: 260, height: 260)
            ForEach(0..<4) { i in
                Image(systemName: "scope")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Theme.primary)
                    .opacity(0.0001 * Double(i)) // keep stable identity
            }
            // corner brackets
            cornerBracket().rotationEffect(.zero).offset(x: -114, y: -114)
            cornerBracket().rotationEffect(.degrees(90)).offset(x: 114, y: -114)
            cornerBracket().rotationEffect(.degrees(180)).offset(x: 114, y: 114)
            cornerBracket().rotationEffect(.degrees(-90)).offset(x: -114, y: 114)
        }
    }

    private func cornerBracket() -> some View {
        Path { p in
            p.move(to: CGPoint(x: 0, y: 24))
            p.addLine(to: CGPoint(x: 0, y: 0))
            p.addLine(to: CGPoint(x: 24, y: 0))
        }
        .stroke(Theme.primary, style: StrokeStyle(lineWidth: 6, lineCap: .round))
        .frame(width: 24, height: 24)
    }

    private var manualEntry: some View {
        VStack(spacing: 10) {
            Text("Or enter equipment ID")
                .font(.caption.weight(.bold))
                .tracking(1)
                .foregroundStyle(Theme.textSecondary)
            HStack(spacing: 8) {
                TextField("EQ-101", text: $manualCode)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .padding(.horizontal, 14)
                    .frame(height: 52)
                    .background(Theme.surfaceElevated)
                    .clipShape(.rect(cornerRadius: 12))
                    .foregroundStyle(Theme.textPrimary)
                    .font(.body.monospaced())
                Button {
                    let code = manualCode.trimmingCharacters(in: .whitespaces)
                    guard !code.isEmpty else { return }
                    Haptics.success()
                    onScan(code)
                } label: {
                    Image(systemName: "arrow.right")
                        .font(.title3.weight(.bold))
                        .frame(width: 52, height: 52)
                        .foregroundStyle(Theme.onPrimary)
                        .background(Theme.primary)
                        .clipShape(.rect(cornerRadius: 12))
                }
                .disabled(manualCode.isEmpty)
                .opacity(manualCode.isEmpty ? 0.5 : 1)
            }
            HStack(spacing: 6) {
                ForEach(["EQ-101", "EQ-204", "EQ-305"], id: \.self) { code in
                    Button {
                        Haptics.success()
                        onScan(code)
                    } label: {
                        Text(code)
                            .font(.caption.monospaced().weight(.bold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Theme.surfaceElevated)
                            .foregroundStyle(Theme.primary)
                            .clipShape(.capsule)
                    }
                }
            }
        }
        .padding(16)
        .background(Theme.surface.opacity(0.95))
        .clipShape(.rect(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.stroke, lineWidth: 1))
    }
}

struct CameraScannerProxy: View {
    let onScan: (String) -> Void

    var body: some View {
        Group {
            #if targetEnvironment(simulator)
            CameraUnavailablePlaceholder()
            #else
            if AVCaptureDevice.default(for: .video) != nil {
                QRScannerRepresentable(onScan: onScan)
                    .ignoresSafeArea()
            } else {
                CameraUnavailablePlaceholder()
            }
            #endif
        }
    }
}

struct CameraUnavailablePlaceholder: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "camera.fill")
                .font(.system(size: 44))
                .foregroundStyle(Theme.textTertiary)
            Text("Camera Preview")
                .font(.headline.weight(.bold))
                .foregroundStyle(Theme.textPrimary)
            Text("Install on your device via the Rork App\nto scan equipment QR codes.")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bg)
    }
}

#if !targetEnvironment(simulator)
import UIKit

struct QRScannerRepresentable: UIViewControllerRepresentable {
    let onScan: (String) -> Void

    func makeUIViewController(context: Context) -> QRScannerVC {
        let vc = QRScannerVC()
        vc.onScan = { code in
            DispatchQueue.main.async { onScan(code) }
        }
        return vc
    }

    func updateUIViewController(_ uiViewController: QRScannerVC, context: Context) {}
}

final class QRScannerVC: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onScan: ((String) -> Void)?
    private let session = AVCaptureSession()
    private var preview: AVCaptureVideoPreviewLayer?
    private var didScan = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else { return }
        if session.canAddInput(input) { session.addInput(input) }
        let output = AVCaptureMetadataOutput()
        if session.canAddOutput(output) {
            session.addOutput(output)
            output.setMetadataObjectsDelegate(self, queue: .main)
            output.metadataObjectTypes = [.qr, .code128, .code39, .ean13, .pdf417]
        }
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        layer.frame = view.bounds
        view.layer.addSublayer(layer)
        preview = layer
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        preview?.frame = view.bounds
    }

    nonisolated func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        Task { @MainActor in
            guard !self.didScan,
                  let obj = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
                  let value = obj.stringValue else { return }
            self.didScan = true
            self.session.stopRunning()
            self.onScan?(value)
        }
    }
}
#else
struct QRScannerRepresentable: View {
    let onScan: (String) -> Void
    var body: some View { CameraUnavailablePlaceholder() }
}
#endif
